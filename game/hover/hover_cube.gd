class_name HoverCube
extends RigidBody3D

## EL CUBO FLOTANTE: un cubo grande (del orden del torso de la meca) que flota sobre el piso como el cuerpo de los
## personajes de character-parametric antes del 13/03/2026 («replaced hover with normal capsule»): un cuerpo físico
## LIBRE, sin nada que lo ate a una postura, sostenido por un RESORTE DE ALTURA (dos rayos hacia el piso) y enderezado
## por un TORQUE. Cualquier golpe lo hunde, lo levanta, lo cabecea y lo hace rebotar solo: el equilibrio no es un número
## que lo inclina, es lo que hacen las fuerzas. Lo pidió el usuario el 11/11/2026, para probar la caída y la
## recuperación aparte de la caminata: «un cubo que haga como hover en el piso… a la más mínima fuerza hace que se baje
## y suba de vuelta, porque es como un resorte libre… cuando se caiga… que lo haga con físicas… y después… mediante unos
## ciertos propulsores que tienen sus paredes se equilibra y se sube».
##
## LOS ESTADOS (los del viejo, con la recuperación por propulsores):
##   FLOTA: el resorte de altura (`height_kp`, `height_kd`, con la gravedad compensada y un tope) y el torque que lo
##     endereza (`upright_kp`, `upright_kd`). Pasado un umbral —muy inclinado, cayendo muy rápido o yendo de costado muy
##     rápido— deja de intentar.
##   TIRADO: nada lo sostiene: cae, rueda y queda donde quede, con física. Quieto `limp_time`, se recupera.
##   SUBE: las toberas de la cara que mira al piso lo despegan y lo llevan a la altura de flotar (sin dejarlo girar).
##   SE ENDEREZA: en el aire, las toberas de los costados lo giran hasta quedar derecho (las de abajo lo sostienen).
##   Derecho y casi sin girar, vuelve a FLOTAR.
## (El usuario eligió el orden: «sube y se endereza en el aire».)
##
## LAS TOBERAS: cuatro por cara, cerca de las esquinas; cada una empuja hacia adentro de su cara, en su lugar (así,
## las de una cara a un lado y las de la opuesta al otro hacen girar). Cada una echa el humo de propulsor de
## character-parametric (ParticleSystems.thruster_smoke) mientras empuja.
##
## Las perillas, en HoverCubeSettings (el panel F1 de su fila).

enum State { HOVER, LIMP, LIFT, RIGHT }

const SIZE := 8.0
const CUBE_MASS := 50000.0
## Las toberas: cuántas por lado de cada cara, y qué tan cerca de las esquinas (parte de la mitad del lado).
const NOZZLE_SPREAD := 0.65
## La parte del lado donde salen los rayos de la cara de abajo (a cada costado).
const RAY_SPREAD := 0.3

var state := State.HOVER
var falls := 0
## Lo que mide, para mirar: la altura de la cara de abajo (o del centro, recuperándose) y la inclinación.
var height := 0.0
var tilt := 0.0

var _clock := 0.0
var _nozzles: Array[Dictionary] = []
var _label: Label3D = null
var _inertia := 1.0


func _init() -> void:
	name = "Cubo"
	mass = CUBE_MASS
	can_sleep = false
	continuous_cd = true
	# Un cubo macizo: I = m·L²/6.
	_inertia = CUBE_MASS * SIZE * SIZE / 6.0


func _ready() -> void:
	Clay.solid(self, Vector3.ONE * SIZE, Vector3.ZERO, Clay.METAL)
	# Una franja en el frente, para leer hacia dónde mira y cuánto gira.
	Clay.box(self, Vector3(SIZE * 0.7, SIZE * 0.12, 0.05), Vector3(0, SIZE * 0.25, -SIZE * 0.5 - 0.03), Clay.YELLOW)
	_build_nozzles()
	_label = Label3D.new()
	_label.top_level = true
	_label.font_size = 64
	_label.pixel_size = 0.02
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.outline_size = 14
	_label.modulate = Color(1.0, 0.95, 0.6)
	add_child(_label)


## CUATRO TOBERAS POR CARA: su lugar en el cubo, hacia dónde echa (afuera de su cara), su malla y su humo.
func _build_nozzles() -> void:
	var half := SIZE * 0.5
	for normal: Vector3 in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		# Dos ejes sobre la cara.
		var u := normal.cross(Vector3.UP if absf(normal.y) < 0.5 else Vector3.RIGHT).normalized()
		var v := normal.cross(u).normalized()
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var at := normal * half + (u * corner.x + v * corner.y) * half * NOZZLE_SPREAD
			var holder := Node3D.new()
			holder.transform = Transform3D(Basis.looking_at(normal, v), at)
			add_child(holder)
			var mouth := Clay.cylinder(holder, 0.45, 0.6, Vector3(0, 0, -0.2), Clay.DARK, Vector3(90, 0, 0))
			var glow := StandardMaterial3D.new()
			glow.albedo_color = Clay.DARK
			glow.emission = Color(1.0, 0.55, 0.15)
			mouth.material_override = glow
			# El humo sale hacia −Z del emisor: hacia afuera de la cara.
			var smoke := ParticleSystems.thruster_smoke(ParticleMeshes.Kind.SPHERE, 4.0)
			smoke.emitting = false
			smoke.position = Vector3(0, 0, -0.5)
			holder.add_child(smoke)
			_nozzles.append({"at": at, "out": normal, "smoke": smoke, "glow": glow, "throttle": 0.0})


func _physics_process(delta: float) -> void:
	var settings := HoverCubeSettings.current
	var up := global_basis.y.normalized()
	tilt = rad_to_deg(up.angle_to(Vector3.UP))
	for nozzle in _nozzles:
		nozzle["throttle"] = 0.0
	match state:
		State.HOVER:
			_hover(settings)
			_stand_upright(settings.upright_kp, settings.upright_kd)
			_check_stop(settings)
		State.LIMP:
			_clock = _clock + delta if linear_velocity.length() < 0.6 and angular_velocity.length() < 0.3 else 0.0
			height = _ground_distance(global_position)
			if _clock >= settings.limp_time:
				state = State.LIFT
				_clock = 0.0
		State.LIFT:
			var reached := _lift(settings)
			_hold_spin()
			if reached:
				state = State.RIGHT
		State.RIGHT:
			_lift(settings)
			_right(settings)
			if tilt <= settings.upright_done and angular_velocity.length() < 0.25:
				state = State.HOVER
	_fire_nozzles(settings)
	_label.global_position = global_position + Vector3(0, SIZE + 2.0, 0)
	_label.text = "%s · altura %.1f m · inclinación %.0f°\ncaídas %d" % [["flota", "TIRADO", "sube", "se endereza"][state],
		height, tilt, falls]


## ── FLOTAR (el viejo de character-parametric) ───────────────────────────────────────────────────────────────────

## EL RESORTE DE ALTURA: dos rayos desde la cara de abajo, hacia abajo del cubo; la altura es la del medio de los que
## tocan. Empuja hacia arriba, en el centro, con la gravedad compensada, el error con tope y la fuerza con tope.
func _hover(settings: HoverCubeSettings) -> void:
	var down := -global_basis.y.normalized()
	var reach := settings.hover_height + settings.max_height_error + 1.0
	var starts: Array[Vector3] = []
	var grounds: Array[Vector3] = []
	for side: float in [-1.0, 1.0]:
		var start := global_transform * Vector3(side * SIZE * RAY_SPREAD, -SIZE * 0.5, 0.0)
		var hit := _ray(start, start + down * reach)
		if not hit.is_empty():
			starts.append(start)
			grounds.append(hit["position"])
	if grounds.is_empty():
		height = reach
		_slide_brake(settings)
		return
	var start_mid := Vector3.ZERO
	var ground_mid := Vector3.ZERO
	for i in grounds.size():
		start_mid += starts[i] / grounds.size()
		ground_mid += grounds[i] / grounds.size()
	height = start_mid.y - ground_mid.y
	var error := clampf(settings.hover_height - height, -settings.max_height_error, settings.max_height_error)
	var accel := settings.height_kp * error - settings.height_kd * linear_velocity.y + _gravity()
	apply_central_force(Vector3.UP * CUBE_MASS * clampf(accel, 0.0, settings.max_up))
	_slide_brake(settings)


func _slide_brake(settings: HoverCubeSettings) -> void:
	var side := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var brake := minf(side.length() / maxf(get_physics_process_delta_time(), 0.0001), settings.slide_brake)
	if side.length() > 0.001:
		apply_central_force(-side.normalized() * brake * CUBE_MASS)


## EL TORQUE QUE LO ENDEREZA: hacia arriba, por lo inclinado, menos lo que gira.
func _stand_upright(kp: float, kd: float) -> void:
	var error_axis := global_basis.y.normalized().cross(Vector3.UP)
	apply_torque((error_axis * kp - angular_velocity * kd) * _inertia)


## DEJAR DE INTENTAR (los umbrales del viejo): muy inclinado, cayendo muy rápido o yendo de costado muy rápido.
func _check_stop(settings: HoverCubeSettings) -> void:
	var side := Vector2(linear_velocity.x, linear_velocity.z).length()
	if tilt > settings.max_tilt or -linear_velocity.y > settings.max_fall_speed or side > settings.max_side_speed:
		state = State.LIMP
		_clock = 0.0
		falls += 1


## ── RECUPERARSE CON LAS TOBERAS ─────────────────────────────────────────────────────────────────────────────────

## SUBIR: las toberas que empujan para arriba (las de la cara que mira al piso) llevan el centro a la altura de flotar,
## con un resorte y la gravedad compensada. Devuelve si ya llegó (cerca y casi quieto).
func _lift(settings: HoverCubeSettings) -> bool:
	var target := settings.hover_height * settings.lift_share + SIZE * 0.5
	height = _ground_distance(global_position)
	var accel := settings.lift_kp * (target - height) - settings.lift_kd * linear_velocity.y + _gravity()
	_push(Vector3.UP * maxf(accel, 0.0) * CUBE_MASS, Vector3.ZERO, settings)
	return height >= target * 0.9 and absf(linear_velocity.y) < 1.0


## Que no gire mientras sube.
func _hold_spin() -> void:
	_push(Vector3.ZERO, -angular_velocity * 2.0 * _inertia, HoverCubeSettings.current)


## ENDEREZARSE: las toberas de los costados lo giran hacia arriba, con un resorte más lento que el de flotar.
func _right(settings: HoverCubeSettings) -> void:
	var error_axis := global_basis.y.normalized().cross(Vector3.UP)
	var angle := global_basis.y.normalized().angle_to(Vector3.UP)
	var axis := error_axis.normalized() if error_axis.length() > 0.0001 else global_basis.x
	# Dado vuelta (el eje se pierde cerca de 180°), gira igual hacia algún lado.
	var torque := (axis * angle * settings.right_kp - angular_velocity * settings.right_kd) * _inertia
	_push(Vector3.ZERO, torque, settings)


## REPARTE ENTRE LAS TOBERAS una fuerza (`force`, en el mundo) y un giro (`torque`): para la fuerza, las que empujan
## para su lado; para el giro, cada una según cuánto gira para el lado pedido. Las toberas sólo empujan (no tiran) y
## tienen tope (`nozzle_push`): lo que no alcanza, no se hace. La fuerza y el giro se suman en el `throttle` de cada una.
func _push(force: Vector3, torque: Vector3, settings: HoverCubeSettings) -> void:
	var most := settings.nozzle_push * CUBE_MASS
	if force.length() > 0.001:
		var lifters: Array[Dictionary] = []
		var share := 0.0
		for nozzle in _nozzles:
			var pushes := -(global_basis * (nozzle["out"] as Vector3))
			var along := pushes.dot(force.normalized())
			if along > 0.7:
				lifters.append(nozzle)
				share += along
		for nozzle in lifters:
			nozzle["throttle"] = clampf(float(nozzle["throttle"]) + force.length() / maxf(share * most, 0.001), 0.0, 1.0)
	if torque.length() > 0.001:
		var wanted := torque.normalized()
		var arms: Array[float] = []
		var total := 0.0
		for nozzle in _nozzles:
			var pushes := -(global_basis * (nozzle["out"] as Vector3)) * most
			var turns := (global_basis * (nozzle["at"] as Vector3)).cross(pushes)
			var useful := maxf(turns.dot(wanted), 0.0)
			arms.append(useful)
			total += useful
		for i in _nozzles.size():
			if arms[i] > 0.0 and total > 0.0:
				_nozzles[i]["throttle"] = clampf(float(_nozzles[i]["throttle"]) + torque.length() / total, 0.0, 1.0)


## Las toberas empujan, en su lugar, y se ven: brillan y echan humo.
func _fire_nozzles(settings: HoverCubeSettings) -> void:
	var most := settings.nozzle_push * CUBE_MASS
	for nozzle in _nozzles:
		var throttle := float(nozzle["throttle"])
		var smoke := nozzle["smoke"] as GPUParticles3D
		var glow := nozzle["glow"] as StandardMaterial3D
		glow.emission_enabled = throttle > 0.02
		glow.emission_energy_multiplier = throttle * 4.0
		smoke.emitting = throttle > 0.05
		if throttle <= 0.0:
			continue
		var at := global_basis * (nozzle["at"] as Vector3)
		apply_force(-(global_basis * (nozzle["out"] as Vector3)) * most * throttle, at)


## ── LAS TRES FUERZAS DE LA BOLA (ver TestBall) ──────────────────────────────────────────────────────────────────────
## Lo que lo inclina el 35 %, el 75 % y el 125 % de donde se deja caer (`max_tilt`), con un golpe de costado en la mitad
## de arriba (a un cuarto del lado sobre el centro: un golpe en el centro lo empuja sin inclinarlo). El giro que le da
## sale del empuje por ese brazo sobre su inercia, y lo que se inclina, del resorte que lo endereza (corrido como lo corre
## la física, ver `_tilt_peak`). La bola no le deja todo su giro (rebota, y parte se va en correrlo): MEDIDO el
## 11/11/2026, un 60 % (`TRANSFER`); por eso los márgenes entre las tres son anchos.
const HIT_ARM := SIZE * 0.25
const TRANSFER := 0.6


static func ball_pushes(speed: float) -> Array[float]:
	var settings := HoverCubeSettings.current
	var inertia := CUBE_MASS * SIZE * SIZE / 6.0
	var per_spin := _tilt_peak(1.0, settings.upright_kp, settings.upright_kd)
	var out: Array[float] = []
	for share: float in [0.35, 0.75, 1.25]:
		var spin := deg_to_rad(settings.max_tilt * share) / maxf(per_spin, 0.0001)
		# El empuje que se queda en el cubo, por su brazo, es su giro: L = I·ω. Y del empuje que llega, se queda esto.
		var kept := inertia * spin / HIT_ARM / TRANSFER
		out.append(TestBall.push_for(CUBE_MASS, kept / CUBE_MASS))
	return out


## La inclinación más alta (rad) del cubo que arranca derecho girando a `spin` rad/s, con el torque que lo endereza.
static func _tilt_peak(spin: float, kp: float, kd: float) -> float:
	var step := 1.0 / 240.0
	var angle := 0.0
	var turning := spin
	var peak := 0.0
	for i in 4800:
		turning += (-angle * kp - turning * kd) * step
		angle += turning * step
		peak = maxf(peak, angle)
		if turning < 0.0:
			break
	return peak


## ── LO QUE MIDE ─────────────────────────────────────────────────────────────────────────────────────────────────

## Cuánto hay de `point` al piso, derecho hacia abajo (o mucho, si no hay piso).
func _ground_distance(point: Vector3) -> float:
	var hit := _ray(point, point + Vector3.DOWN * 200.0)
	return point.y - (hit["position"] as Vector3).y if not hit.is_empty() else 200.0


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	query.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_ray(query)


static func _gravity() -> float:
	return float(ProjectSettings.get_setting("physics/3d/default_gravity"))
