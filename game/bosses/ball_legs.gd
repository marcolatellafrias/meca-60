class_name BallLegs
extends Node3D

## LAS CUATRO PATAS DEL JEFE BOLA (13/11/2026): dónde apoya cada pie y cuándo da un paso. Cada pata es un Tentacle, que
## se dobla solo (su IK): acá sólo se decide dónde va la punta.
##   · CADA PIE TIENE SU LUGAR: en diagonal, a `spread` del centro, girado con la bola, y un poco adelantado si camina.
##     El piso se busca con un rayo a lo fijo del mundo (PhysicsLayers.FIXED): sobre un edificio, pisa el techo.
##   · LOS PASOS VAN DE A DOS, EN DIAGONAL: cuando un pie quedó a más de `step_radius` de su lugar, sale con el de la
##     diagonal, en arco. El resto queda plantado: no se arrastra.
##   · EN EL AIRE cuelgan debajo de la bola; al caer, apoyan donde estén y los pasos los acomodan.
##   · HECHA BOLA (`fold`, ver BallRoll) se meten adentro: la punta va hacia el centro y el tentáculo se acorta.
##   · EL BARRIDO (`sweep`; el usuario: «barrido», con la Q): los cuatro pies se levantan, las paletas giran como
##     hélices y dan la vuelta alrededor de la bola, lejos y bajo; lo suelto que tocan sale despedido de costado (sin
##     vida: todo es equilibrio; ver BalanceBody.hit). Después bajan donde quedaron y los pasos los acomodan.

## Dónde salen de la bola: en diagonal (la pata 0 adelante a la derecha, y de ahí a la vuelta) y cuánto debajo del
## ecuador (grados).
const ROOT_LATITUDE := -22.0
## En el aire, a qué velocidad van las puntas a colgar (m/s).
const DANGLE := 25.0
## EL BARRIDO: qué parte del tiempo tarda en levantar y en bajar los pies, a cuánto de un pie pega (m: lo que miden las
## paletas) y a qué velocidad giran las hélices (vueltas por segundo).
const SWEEP_LIFT := 0.15
const SWEEP_TOUCH := 8.0
const PROPELLER := 4.0

var tentacles: Array[Tentacle] = []
## Cuántos pasos dio (para mirar).
var steps := 0
## Si está barriendo, y cuántas veces pegó barriendo (para mirar).
var sweeping := false
var sweep_hits := 0

var _sweep_clock := 0.0
var _sweep_from: Array[Vector3] = []
var _sweep_hit := {}

var _feet: Array[Dictionary] = []
var _swinging := -1
var _clock := 0.0
var _space: PhysicsDirectSpaceState3D = null


func _ready() -> void:
	top_level = true
	global_transform = Transform3D()
	for i in 4:
		var tentacle := Tentacle.new()
		tentacle.name = "Tentáculo %d" % i
		add_child(tentacle)
		tentacles.append(tentacle)
		_feet.append({"at": Vector3.ZERO, "from": Vector3.ZERO, "yaw": 0.0, "planted": true})


## LAS REARMA con las medidas de `k` (la pestaña Forma).
func rebuild(k: BallBossSettings) -> void:
	for tentacle in tentacles:
		tentacle.build(k)


## Hacia dónde sale la pata `i` de la bola (en el espacio de la bola, sin girar).
static func direction(i: int) -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, -PI * 0.25 - i * PI * 0.5)


## LOS PONE en su lugar, sin pasos: al armarlo y cada vez que a la bola se la pone en otro lado.
func place_now(k: BallBossSettings, center: Vector3, yaw: float, radius: float) -> void:
	homes(k, center, yaw)
	_draw(k, center, yaw, radius)


## Cada pie a su lugar en el piso, sin dibujarlos: también al empezar a abrirse, para que salgan hacia ahí.
func homes(k: BallBossSettings, center: Vector3, yaw: float) -> void:
	_swinging = -1
	for i in 4:
		var foot := _feet[i]
		foot["at"] = _ground(_home(k, center, yaw, i, Vector3.ZERO), center.y)
		foot["yaw"] = yaw
		foot["planted"] = true


## PLEGÁNDOSE O ABRIÉNDOSE (`fold`, 0 a 1): los pies quedan donde están y los tentáculos se meten en la bola.
func folded(k: BallBossSettings, center: Vector3, yaw: float, radius: float, fold: float) -> void:
	_draw(k, center, yaw, radius, fold)


## EMPIEZA EL BARRIDO (si no está barriendo ya). Devuelve si empezó.
func sweep() -> bool:
	if sweeping:
		return false
	sweeping = true
	_sweep_clock = 0.0
	_swinging = -1
	_sweep_hit.clear()
	_sweep_from.clear()
	for foot in _feet:
		_sweep_from.append(foot["at"])
	return true


## UN PASO DE LA FÍSICA: `center` es el centro de la bola, `yaw` hacia dónde mira, `flat` su velocidad de costado.
func step(k: BallBossSettings, delta: float, center: Vector3, yaw: float, flat: Vector3, grounded: bool,
		radius: float) -> void:
	_space = get_world_3d().direct_space_state
	if sweeping:
		_sweep_step(k, delta, center, yaw, radius)
		return
	if not grounded:
		_swinging = -1
		for i in 4:
			var foot := _feet[i]
			var hang := center + Basis(Vector3.UP, yaw) * BallLegs.direction(i) * k.spread * 0.6 \
				+ Vector3.DOWN * k.tentacle_length * 0.6
			foot["at"] = (foot["at"] as Vector3).move_toward(hang, DANGLE * delta)
			foot["planted"] = false
		_draw(k, center, yaw, radius)
		return
	for i in 4:
		var foot := _feet[i]
		if not foot["planted"] and _swinging != i and _swinging != (i + 2) % 4:
			# Recién caído: apoya donde está.
			foot["at"] = _ground(foot["at"], center.y)
			foot["planted"] = true
	if _swinging >= 0:
		_clock += delta
		var share := clampf(_clock / maxf(k.step_time, 0.05), 0.0, 1.0)
		var eased := smoothstep(0.0, 1.0, share)
		for i in [_swinging, (_swinging + 2) % 4]:
			var foot := _feet[i]
			var target := _ground(_home(k, center, yaw, i, flat), center.y)
			var from: Vector3 = foot["from"]
			foot["at"] = from.lerp(target, eased) + Vector3.UP * sin(share * PI) * k.step_lift
			foot["yaw"] = lerp_angle(float(foot["yaw"]), yaw, eased)
			if share >= 1.0:
				foot["at"] = target
		if share >= 1.0:
			_swinging = -1
	else:
		# EL QUE QUEDÓ MÁS LEJOS de su lugar sale, con el de su diagonal.
		var worst := -1
		var worst_gap := k.step_radius
		for i in 4:
			var home := _home(k, center, yaw, i, Vector3.ZERO)
			var at: Vector3 = _feet[i]["at"]
			var gap := Vector2(home.x - at.x, home.z - at.z).length()
			if gap > worst_gap:
				worst_gap = gap
				worst = i
		if worst >= 0:
			_swinging = worst % 2
			_clock = 0.0
			steps += 1
			for i in [_swinging, _swinging + 2]:
				_feet[i]["from"] = _feet[i]["at"]
	_draw(k, center, yaw, radius)


## UN PASO DEL BARRIDO: suben (`SWEEP_LIFT` del tiempo), dan `sweep_turns` vueltas a `sweep_reach` del centro y a
## `sweep_height` del piso, y bajan donde quedaron. Las hélices giran mientras tanto.
func _sweep_step(k: BallBossSettings, delta: float, center: Vector3, yaw: float, radius: float) -> void:
	_sweep_clock += delta
	var share := clampf(_sweep_clock / maxf(k.sweep_time, 0.1), 0.0, 1.0)
	var angle := smoothstep(SWEEP_LIFT, 1.0 - SWEEP_LIFT, share) * TAU * k.sweep_turns
	var up := smoothstep(0.0, SWEEP_LIFT, share)
	var down := smoothstep(1.0 - SWEEP_LIFT, 1.0, share)
	var spinning := sin(share * PI)
	var hitting := share > SWEEP_LIFT * 0.5 and share < 1.0 - SWEEP_LIFT * 0.5
	for i in 4:
		var foot := _feet[i]
		var way := Basis(Vector3.UP, yaw + angle) * BallLegs.direction(i)
		var circle := center + way * k.sweep_reach
		circle.y = _sweep_from[i].y + k.sweep_height
		var at := _sweep_from[i].lerp(circle, up)
		if down > 0.0:
			at = circle.lerp(_ground(circle, center.y), down)
		foot["at"] = at
		foot["planted"] = false
		tentacles[i].rotor.rotation.y += TAU * PROPELLER * spinning * delta
		if hitting:
			# De costado: hacia donde va la paleta, y un poco hacia afuera.
			var along := Vector3.UP.cross(way) * signf(k.sweep_turns)
			_sweep_touch(k, at, (along * 0.7 + way * 0.3).normalized())
	if share >= 1.0:
		sweeping = false
		for foot in _feet:
			foot["at"] = _ground(foot["at"], center.y)
			foot["planted"] = true
	_draw(k, center, yaw, radius)


## LO QUE TOCA UNA PALETA en `at`, sale despedido hacia `way`. A cada cosa, una vez por barrido.
func _sweep_touch(k: BallBossSettings, at: Vector3, way: Vector3) -> void:
	var sphere := SphereShape3D.new()
	sphere.radius = SWEEP_TOUCH
	for body in AreaStrike.loose_in(_space, sphere, Transform3D(Basis(), at)):
		var id := body.get_instance_id()
		if _sweep_hit.has(id):
			continue
		_sweep_hit[id] = true
		BalanceBody.hit(body, (way + Vector3.UP * 0.25).normalized() * k.sweep_push * body.mass)
		sweep_hits += 1


## El lugar del pie `i` (en el piso, todavía sin buscarlo): adelantado por `flat` para que llegue antes que la bola.
func _home(k: BallBossSettings, center: Vector3, yaw: float, i: int, flat: Vector3) -> Vector3:
	var home := center + Basis(Vector3.UP, yaw) * BallLegs.direction(i) * k.spread + flat * k.step_time
	home.y = center.y
	return home


## EL PISO debajo de `point`: un rayo a lo fijo del mundo desde la altura del centro. Sin piso, queda donde estaba.
func _ground(point: Vector3, from_y: float) -> Vector3:
	if _space == null:
		_space = get_world_3d().direct_space_state
	var top := Vector3(point.x, from_y, point.z)
	var ray := PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 200.0, PhysicsLayers.FIXED)
	var hit := _space.intersect_ray(ray)
	if hit.is_empty():
		return point
	return hit["position"]


func _draw(k: BallBossSettings, center: Vector3, yaw: float, radius: float, fold := 0.0) -> void:
	var lat := deg_to_rad(ROOT_LATITUDE)
	var eased := smoothstep(0.0, 1.0, fold)
	for i in 4:
		var side := Basis(Vector3.UP, yaw) * BallLegs.direction(i)
		var normal := side * cos(lat) + Vector3.UP * sin(lat)
		var root := center + normal * radius * 0.92
		# Sale de la bola hacia afuera y un poco para arriba: así se arquea como una pata, no cuelga.
		var out := (side + Vector3.UP * 0.5).normalized()
		# Plegándose, la punta va hacia adentro de la bola y el tentáculo se acorta con ella.
		var tip: Vector3 = (_feet[i]["at"] as Vector3).lerp(center + normal * radius * 0.4, eased)
		tentacles[i].visible = eased < 0.97
		tentacles[i].pose(root, out, tip, float(_feet[i]["yaw"]),
			lerpf(k.tentacle_length, radius * 0.4, eased))
