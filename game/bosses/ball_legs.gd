class_name BallLegs
extends Node3D

## LAS CUATRO PATAS DEL JEFE BOLA (13/11/2026): dónde apoya cada pie y cuándo da un paso. Cada pata es un Tentacle, que
## se dobla solo (su IK): acá sólo se decide dónde va la punta.
##   · CADA PIE TIENE SU LUGAR: en diagonal, a `spread` del centro, girado con la bola, y un poco adelantado si camina.
##     El piso se busca con un rayo a lo fijo del mundo (PhysicsLayers.FIXED): sobre un edificio, pisa el techo.
##   · LOS PASOS VAN DE A DOS, EN DIAGONAL: cuando un pie quedó a más de `step_radius` de su lugar, sale con el de la
##     diagonal, en arco. El resto queda plantado: no se arrastra.
##   · EN EL AIRE cuelgan debajo de la bola; al caer, apoyan donde estén y los pasos los acomodan.

## Dónde salen de la bola: en diagonal (la pata 0 adelante a la derecha, y de ahí a la vuelta) y cuánto debajo del
## ecuador (grados).
const ROOT_LATITUDE := -22.0
## En el aire, a qué velocidad van las puntas a colgar (m/s).
const DANGLE := 25.0

var tentacles: Array[Tentacle] = []
## Cuántos pasos dio (para mirar).
var steps := 0

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


## Hacia dónde sale la pata `i` de la bola (en el espacio de la bola, sin girar).
static func direction(i: int) -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, -PI * 0.25 - i * PI * 0.5)


## LOS PONE en su lugar, sin pasos: al armarlo y cada vez que a la bola se la pone en otro lado.
func place_now(k: BallBossSettings, center: Vector3, yaw: float, radius: float) -> void:
	_swinging = -1
	for i in 4:
		var foot := _feet[i]
		foot["at"] = _ground(_home(k, center, yaw, i, Vector3.ZERO), center.y)
		foot["yaw"] = yaw
		foot["planted"] = true
	_draw(k, center, yaw, radius)


## UN PASO DE LA FÍSICA: `center` es el centro de la bola, `yaw` hacia dónde mira, `flat` su velocidad de costado.
func step(k: BallBossSettings, delta: float, center: Vector3, yaw: float, flat: Vector3, grounded: bool,
		radius: float) -> void:
	_space = get_world_3d().direct_space_state
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


func _draw(k: BallBossSettings, center: Vector3, yaw: float, radius: float) -> void:
	var lat := deg_to_rad(ROOT_LATITUDE)
	for i in 4:
		var side := Basis(Vector3.UP, yaw) * BallLegs.direction(i)
		var normal := side * cos(lat) + Vector3.UP * sin(lat)
		# Sale de la bola hacia afuera y un poco para arriba: así se arquea como una pata, no cuelga.
		var out := (side + Vector3.UP * 0.5).normalized()
		tentacles[i].pose(center + normal * radius * 0.92, out, _feet[i]["at"], float(_feet[i]["yaw"]),
			k.tentacle_length)
