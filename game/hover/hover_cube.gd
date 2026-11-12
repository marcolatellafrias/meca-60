class_name HoverCube
extends RigidBody3D

## EL CUBO: un cubo grande (del orden del torso de la meca) para probar el equilibrio, la caída y la recuperación aparte
## de la caminata. Lo pidió el usuario el 11/11/2026 («un cubo que haga como hover en el piso… cuando se caiga… que lo
## haga con físicas y… mediante unos ciertos propulsores… se equilibra y se sube»), y el 12/11/2026 quedó en uno solo:
## el de la línea de equilibrio, con el resorte vertical («no me gusta de que la rotación en el eje Y global se pueda
## modificar con impactos… lo que sí puede llegar a funcionar es esto de la verticalidad… un poco más como resorte
## vertical»). *El cubo que se enderezaba con un torque libre se borró ese día: se torcía con cualquier golpe.*
##
## PARADO, FÍSICO DONDE SUMA Y CONTROLADO DONDE IMPORTA:
##   · FLOTA CON UN RESORTE VERTICAL, el del cuerpo de los personajes de character-parametric antes del 13/03/2026 (dos
##     rayos al piso, la gravedad compensada, el error y la fuerza con tope): cualquier golpe de arriba o de abajo lo
##     hunde y rebota solo.
##   · NO GIRA: sus giros están trabados. Un golpe nunca le cambia hacia dónde mira.
##   · DOS VELOCIDADES DE COSTADO, APARTE: la PROPIA (la que pide el que lo maneja, con la O: arranca con `walk_accel`
##     y, al soltar, frena con `walk_brake`, de a poco) y la del RETROCESO (la que le dejan los golpes, que frena
##     `knock_brake`). Así un golpe puede correrlo mucho sin que manejarlo se vuelva resbaloso, y al revés (lo pidió el
##     usuario el 12/11/2026: «no quiero que al soltar W frenes en seco, pero sí quiero tener dos perillas»).
##   · LA LÍNEA DE EQUILIBRIO (`lean`): ese mismo golpe —medido como lo que cambió la velocidad sin que él lo pidiera—
##     le suma a la velocidad de la inclinación (`lean_per_ms` × `push_rate`); un resorte la devuelve (`stiffness`,
##     `damping`). Golpes seguidos se suman. Se ve inclinando el DIBUJO sobre el canto de abajo.
##   · CONTRA QUÉ Y DÓNDE (el 12/11/2026, el usuario: «es muy distinta la diferencia de velocidad cuando… es un impacto a
##     cuando… se frenó por una pared… apenas la golpea, se voltea»): el golpe se mide igual, pero mira los CONTACTOS de
##     la física de ese paso. Contra algo FIJO (una pared, un edificio) sólo frena: inclina por `fixed_lean` y no lo
##     corre de más. Contra algo QUE SE MUEVE (la bola, otro cuerpo) es un golpe entero: lo corre por `knock_gain` y lo
##     inclina según la ALTURA del contacto sobre el piso (`height_weight`: arriba vuelca más que abajo; a la altura del
##     centro, como siempre). Sin contacto (el F2) es un golpe entero en el centro.
## AL PASAR `fall_at`, TROPIEZA: el cuerpo toma la inclinación del dibujo (girando sobre ese mismo canto) y queda suelto,
## con UN giro de una vez: el justo para que su BASE QUEDE QUIETA en ese instante —como si los pies se trabaran— (ω =
## arriba × v / h, por `base_grip`), más lo que se venía inclinando (`tip_carry`). Desde ahí todo es física: cae para el
## lado del golpe (y ahí sí puede girar).
## CAÍDO: un poco más pesado (`fall_gravity`) y con freno de giro (`ground_spin_damp`), poco, para no perder la física.
## Apenas deja de caer y de rodar rápido, SE RECUPERA con sus toberas (cuatro por cara; cada una empuja hacia adentro de
## su cara, en su lugar, y echa el humo de propulsor de character-parametric), SUBIENDO Y ENDEREZÁNDOSE A LA VEZ: las de
## la cara que mira al piso lo suben y las de los costados lo enderezan TANTO COMO EL LUGAR LE DEJA —mira cuánto baja su
## punto más bajo, tal como está girado, y gira sólo con lo que le sobra de altura (ver `_right_as_room_allows`)—. Lo
## pidió el usuario el 12/11/2026 («primero se levanta y después se endereza… prefiero… algo un poco más continuo»).
## *Antes subía hasta poder girar entero (la esfera que lo contiene) y recién ahí se enderezaba.* Derecho otra vez, se
## traba y vuelve a la línea, mirando hacia donde miraba.
##
## Las perillas, en HoverCubeSettings (el panel F1 de su fila); el F2 lo vuelca (`knock`).

enum State { HOVER, LIMP, LIFT, RIGHT }

const SIZE := 8.0
const CUBE_MASS := 50000.0
## Las toberas: qué tan cerca de las esquinas (parte de la mitad del lado).
const NOZZLE_SPREAD := 0.65
## La parte del lado donde salen los rayos de la cara de abajo (a cada costado).
const RAY_SPREAD := 0.3
## ENDEREZARSE SEGÚN EL LUGAR: lo que tiene que sobrar entre su punto más bajo y el piso para empezar a girar (m), y en
## cuántos metros más gira con todo.
const RIGHT_ROOM := 0.3
const RIGHT_BAND := 1.0
## Con menos inclinación que esto ya es el final de enderezarse (`State.RIGHT`: las piernas, quien las tenga, se
## estiran).
const LAST_STRETCH := 45.0
## Un cambio de velocidad de costado más chico que esto no es un golpe (m/s).
const HIT_NOISE := 0.3
## Volcarlo (el F2): cuánto más allá de su caerse lo lleva el empujón, suave y fuerte.
const KNOCK_SOFT := 1.2
const KNOCK_STRONG := 2.5

var state := State.HOVER
var falls := 0
## Lo que mide, para mirar: la altura de la cara de abajo (o del centro, recuperándose), la inclinación (grados), la línea
## (x a la derecha, y adelante, en el espacio del cubo) y el último golpe (m/s).
var height := 0.0
var tilt := 0.0
var lean := Vector2.ZERO
var last_hit := 0.0
## Contra qué fue el último golpe: "fijo", "golpe" o "empujón" (sin contacto), para mirar.
var last_hit_kind := ""

var _lean_speed := Vector2.ZERO
var _velocity_after := Vector3.ZERO
## La velocidad de costado propia y la del retroceso (ver arriba); parado, la del cuerpo es su suma.
var _walk := Vector3.ZERO
var _knock := Vector3.ZERO
## MANEJARLO DESDE AFUERA (la O de su fila): W/S adelante y atrás, A/D gira; la cámara lo sigue de atrás.
var driving := false
var _camera: Camera3D = null
var _chase_yaw := 0.0
var _shape: CollisionShape3D = null
var _clock := 0.0
var _nozzles: Array[Dictionary] = []
var _label: Label3D = null
var _inertia := 1.0
## El dibujo: se inclina con la línea sin girar el cuerpo.
var _look: Node3D = null


func _init() -> void:
	name = "Cubo"
	mass = CUBE_MASS
	can_sleep = false
	continuous_cd = true
	# Para saber contra qué choca (ver `_touch`).
	contact_monitor = true
	max_contacts_reported = 8
	# Un cubo macizo: I = m·L²/6.
	_inertia = CUBE_MASS * SIZE * SIZE / 6.0


func _ready() -> void:
	_look = Node3D.new()
	_look.name = "Dibujo"
	add_child(_look)
	_shape = Clay.shape_box(self, Vector3.ONE * SIZE, Vector3.ZERO)
	Clay.box(_look, Vector3.ONE * SIZE, Vector3.ZERO, Clay.METAL)
	# Una franja en el frente, para leer hacia dónde mira y cuánto se inclina.
	Clay.box(_look, Vector3(SIZE * 0.7, SIZE * 0.12, 0.05), Vector3(0, SIZE * 0.25, -SIZE * 0.5 - 0.03), Clay.YELLOW)
	_build_nozzles()
	_label = Label3D.new()
	_label.top_level = true
	_label.font_size = 64
	_label.pixel_size = 0.02
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.outline_size = 14
	_label.modulate = Color(1.0, 0.95, 0.6)
	add_child(_label)
	_camera = Camera3D.new()
	_camera.name = "Cámara de afuera"
	_camera.top_level = true
	_camera.far = 2000.0
	add_child(_camera)
	_lock(true)


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
			_look.add_child(holder)
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


## Sus giros, trabados (parado) o sueltos (caído y recuperándose).
func _lock(on: bool) -> void:
	axis_lock_angular_x = on
	axis_lock_angular_y = on
	axis_lock_angular_z = on


func _physics_process(delta: float) -> void:
	var knobs := tuning()
	for nozzle in _nozzles:
		nozzle["throttle"] = 0.0
	gravity_scale = knobs.fall_gravity if state == State.LIMP else 1.0
	angular_damp = knobs.ground_spin_damp if state == State.LIMP else 0.0
	if state != State.HOVER:
		tilt = rad_to_deg(global_basis.y.normalized().angle_to(Vector3.UP))
	match state:
		State.HOVER:
			_standing(knobs, delta)
		State.LIMP:
			var settled := linear_velocity.length() < knobs.settle_speed and angular_velocity.length() < knobs.settle_spin
			_clock = _clock + delta if settled else 0.0
			height = _ground_distance(global_position)
			if _clock >= knobs.limp_time:
				state = State.LIFT
				_clock = 0.0
		State.LIFT:
			_lift(knobs)
			_right_as_room_allows(knobs)
			if tilt <= LAST_STRETCH:
				state = State.RIGHT
		State.RIGHT:
			_lift(knobs)
			_right_as_room_allows(knobs)
			if tilt <= knobs.upright_done and angular_velocity.length() < 0.4:
				_recovered()
	_fire_nozzles(knobs)
	_place_camera(delta)
	_label.global_position = global_position + Vector3(0, SIZE + 2.0, 0)
	_label.text = "%s · altura %.1f m · inclinación %.0f°\núltimo golpe %.1f m/s %s · caídas %d" % [
		["parado", "TIRADO", "sube", "se endereza"][state], height, tilt, last_hit, last_hit_kind, falls]


## ── PARADO ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _standing(knobs: HoverCubeSettings, delta: float) -> void:
	_measure_hit(knobs)
	_move(knobs, delta)
	_hover(knobs)
	_lean_speed += (-lean * knobs.stiffness - _lean_speed * knobs.damping) * delta
	lean += _lean_speed * delta
	_look.transform = _leaning(knobs)
	tilt = rad_to_deg(lean.length() * deg_to_rad(knobs.lean_angle))
	_velocity_after = linear_velocity
	if lean.length() >= knobs.fall_at:
		_trip(knobs)


## EL GOLPE: lo que cambió la velocidad de costado desde el paso anterior sin que él lo pidiera (su freno es muy poco por
## paso para contar), a la velocidad de la inclinación. Lo que va contra su propio avance (chocar caminando, empujar una
## pared) sale de la velocidad propia y no queda como retroceso: si no, al soltar W la pared lo despediría para atrás.
func _measure_hit(knobs: HoverCubeSettings) -> void:
	var change := linear_velocity - _velocity_after
	var flat := Vector3(change.x, 0.0, change.z)
	var rest := flat
	if _walk.length_squared() > 0.0001:
		var heading := _walk.normalized()
		var taken := maxf(flat.dot(heading), -_walk.length())
		if taken < 0.0:
			_walk += heading * taken
			rest -= heading * taken
	if flat.length() <= HIT_NOISE:
		return
	last_hit = flat.length()
	var touch := _touch()
	var weight := 1.0
	# Algo fijo sólo FRENA: si el cambio no va contra cómo se movía (un empujón estando apoyado en una pared), es golpe.
	var before := Vector3(_velocity_after.x, 0.0, _velocity_after.z)
	if bool(touch["fixed"]) and flat.dot(before) < 0.0:
		last_hit_kind = "fijo"
		weight = knobs.fixed_lean
		_knock += rest
	else:
		last_hit_kind = "golpe" if touch["at"] != null else "empujón"
		_knock += rest * knobs.knock_gain
		if touch["at"] != null:
			var ground := global_position.y - SIZE * 0.5 - height
			var centre := maxf(global_position.y - ground, 0.1)
			var above := maxf((touch["at"] as Vector3).y - ground, 0.0)
			weight = lerpf(1.0, above / centre, knobs.height_weight)
	var local := global_basis.inverse() * flat
	_lean_speed += Vector2(local.x, -local.z) * knobs.lean_per_ms * knobs.push_rate * weight


## CONTRA QUÉ CHOCÓ en el último paso de la física: `at`, el punto del contacto con algo que se mueve (o null), y
## `fixed`, si sólo tocó cosas fijas. Fijo es lo estático (una pared, un edificio, el piso) o un cuerpo congelado; lo
## demás (la bola, un cuerpo suelto, un personaje) se mueve.
func _touch() -> Dictionary:
	var physics := PhysicsServer3D.body_get_direct_state(get_rid())
	var fixed := false
	if physics == null:
		return {"fixed": false, "at": null}
	for i in physics.get_contact_count():
		var other := physics.get_contact_collider_object(i)
		var still := (other is StaticBody3D and not other is AnimatableBody3D) \
			or (other is RigidBody3D and (other as RigidBody3D).freeze)
		if still:
			fixed = true
		else:
			return {"fixed": false, "at": physics.get_contact_local_position(i)}
	return {"fixed": fixed, "at": null}


## EL RESORTE VERTICAL: dos rayos desde la cara de abajo; la altura es la del medio de los que tocan. Empuja hacia
## arriba, en el centro, con la gravedad compensada, el error con tope y la fuerza con tope. (Lo de costado, en `_move`.)
func _hover(knobs: HoverCubeSettings) -> void:
	var reach := knobs.hover_height + knobs.max_height_error + 1.0
	var starts: Array[Vector3] = []
	var grounds: Array[Vector3] = []
	for side: float in [-1.0, 1.0]:
		var start := global_transform * Vector3(side * SIZE * RAY_SPREAD, -SIZE * 0.5, 0.0)
		var hit := _ray(start, start + Vector3.DOWN * reach)
		if not hit.is_empty():
			starts.append(start)
			grounds.append(hit["position"])
	if grounds.is_empty():
		height = reach
		return
	var start_mid := Vector3.ZERO
	var ground_mid := Vector3.ZERO
	for i in grounds.size():
		start_mid += starts[i] / grounds.size()
		ground_mid += grounds[i] / grounds.size()
	height = start_mid.y - ground_mid.y
	var error := clampf(knobs.hover_height - height, -knobs.max_height_error, knobs.max_height_error)
	var accel := knobs.height_kp * error - knobs.height_kd * linear_velocity.y + _gravity()
	apply_central_force(Vector3.UP * CUBE_MASS * clampf(accel, 0.0, knobs.max_up))


## LAS DOS VELOCIDADES DE COSTADO: la propia va hacia la pedida (arranca con `walk_accel`, frena con `walk_brake`), el
## retroceso se apaga con `knock_brake`, y el cuerpo va con las dos sumadas. Manejándolo, A/D lo gira (sus giros están
## trabados para la física, no para él).
func _move(knobs: HoverCubeSettings, delta: float) -> void:
	var wanted := Vector3.ZERO
	if driving and UIState.gameplay_active():
		var yaw := global_rotation.y + HoverCube._axis(KEY_A, KEY_D) * deg_to_rad(knobs.turn_speed) * delta
		global_basis = Basis(Vector3.UP, yaw)
		wanted = -global_basis.z * HoverCube._axis(KEY_W, KEY_S) * knobs.walk_speed
	var rate := knobs.walk_accel if wanted.length_squared() > 0.0001 else knobs.walk_brake
	_walk = _walk.move_toward(wanted, rate * delta)
	_knock = _knock.move_toward(Vector3.ZERO, knobs.knock_brake * delta)
	var side := _walk + _knock
	linear_velocity = Vector3(side.x, linear_velocity.y, side.z)


## El dibujo inclinado sobre el canto de abajo hacia donde se inclina (ver MechBody.tilt).
func _leaning(knobs: HoverCubeSettings) -> Transform3D:
	var pivot := Vector3(0.0, -SIZE * 0.5, 0.0)
	var turn := MechBody.tilt(lean * deg_to_rad(knobs.lean_angle))
	return Transform3D(Basis(), pivot) * Transform3D(turn, Vector3.ZERO) * Transform3D(Basis(), -pivot)


## ── TROPEZAR Y CAER ─────────────────────────────────────────────────────────────────────────────────────────────

## TROPIEZA (ver arriba): el cuerpo toma la inclinación del dibujo, queda suelto y recibe el giro de los pies trabados.
func _trip(knobs: HoverCubeSettings) -> void:
	var turn := MechBody.tilt(lean * deg_to_rad(knobs.lean_angle))
	var base := global_transform * Vector3(0.0, -SIZE * 0.5, 0.0)
	var leaned := global_basis * turn
	var direction := global_basis * Vector3(lean.x, 0.0, -lean.y).normalized()
	var tipping := maxf(_lean_speed.dot(lean.normalized()), 0.0) * deg_to_rad(knobs.lean_angle)
	_lock(false)
	global_transform = Transform3D(leaned, base + leaned * Vector3(0.0, SIZE * 0.5, 0.0))
	_look.transform = Transform3D()
	# Cae con su velocidad de la física: el retroceso de más (`knock_gain`) es para verlo correrse parado, no para que
	# salga despedido al caer.
	var side := _walk + _knock / maxf(knobs.knock_gain, 1.0)
	linear_velocity = Vector3(side.x, linear_velocity.y, side.z)
	angular_velocity = Vector3.UP.cross(side) / (SIZE * 0.5) * knobs.base_grip \
		+ Vector3.UP.cross(direction) * tipping * knobs.tip_carry
	lean = Vector2.ZERO
	_lean_speed = Vector2.ZERO
	_walk = Vector3.ZERO
	_knock = Vector3.ZERO
	state = State.LIMP
	_clock = 0.0
	falls += 1


## ── RECUPERARSE CON LAS TOBERAS ─────────────────────────────────────────────────────────────────────────────────

## SUBIR: las toberas que empujan para arriba (las de la cara que mira al piso) llevan el centro a la altura de flotar,
## con un resorte y la gravedad compensada.
func _lift(knobs: HoverCubeSettings) -> void:
	var target := knobs.hover_height * knobs.lift_share + SIZE * 0.5
	height = _ground_distance(global_position)
	var accel := knobs.lift_kp * (target - height) - knobs.lift_kd * linear_velocity.y + _gravity()
	_push(Vector3.UP * maxf(accel, 0.0) * CUBE_MASS, Vector3.ZERO, knobs)


## ENDEREZARSE TANTO COMO EL LUGAR LE DEJA: su punto más bajo está, debajo del centro, a medio lado por la suma de lo
## que «abajo» tiene de cada eje del cubo (4 m apoyado en una cara, 5,7 en un canto, 6,9 en una punta). Con lo que le
## sobra de altura sobre eso gira (`RIGHT_ROOM`, `RIGHT_BAND`); con lo que no, frena el giro. Girar lo lleva a un canto
## o a una punta, que bajan más: se regula solo, y sube y se endereza de corrido.
func _right_as_room_allows(knobs: HoverCubeSettings) -> void:
	var down := global_basis.inverse() * Vector3.DOWN
	var lowest := SIZE * 0.5 * (absf(down.x) + absf(down.y) + absf(down.z))
	var room := clampf((height - lowest - RIGHT_ROOM) / RIGHT_BAND, 0.0, 1.0)
	_right(knobs, room)
	_push(Vector3.ZERO, -angular_velocity * 2.0 * _inertia * (1.0 - room), knobs)


## ENDEREZARSE: las toberas de los costados lo giran hacia arriba, con `share` de su fuerza.
func _right(knobs: HoverCubeSettings, share: float) -> void:
	var error_axis := global_basis.y.normalized().cross(Vector3.UP)
	var angle := global_basis.y.normalized().angle_to(Vector3.UP)
	# Dado vuelta (el eje se pierde cerca de 180°), gira igual hacia algún lado.
	var axis := error_axis.normalized() if error_axis.length() > 0.0001 else global_basis.x
	var torque := (axis * angle * knobs.right_kp - angular_velocity * knobs.right_kd) * _inertia * share
	_push(Vector3.ZERO, torque, knobs)


## DERECHO OTRA VEZ: trabado, mirando hacia donde miraba, y la línea en cero.
func _recovered() -> void:
	var forward := -global_basis.z
	forward.y = 0.0
	var yaw := atan2(-forward.x, -forward.z) if forward.length_squared() > 0.01 else global_rotation.y
	global_basis = Basis(Vector3.UP, yaw)
	angular_velocity = Vector3.ZERO
	_lock(true)
	lean = Vector2.ZERO
	_lean_speed = Vector2.ZERO
	_velocity_after = linear_velocity
	# Lo que le quede de velocidad de costado, como retroceso: se apaga solo.
	_walk = Vector3.ZERO
	_knock = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	state = State.HOVER


## REPARTE ENTRE LAS TOBERAS una fuerza (`force`, en el mundo) y un giro (`torque`): para la fuerza, las que empujan
## para su lado; para el giro, cada una según cuánto gira para el lado pedido. Las toberas sólo empujan (no tiran) y
## tienen tope (`nozzle_push`): lo que no alcanza, no se hace. La fuerza y el giro se suman en el `throttle` de cada una.
func _push(force: Vector3, torque: Vector3, knobs: HoverCubeSettings) -> void:
	var most := knobs.nozzle_push * CUBE_MASS
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
func _fire_nozzles(knobs: HoverCubeSettings) -> void:
	var most := knobs.nozzle_push * CUBE_MASS
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


## ── VOLCARLO (el panel chico, F2; el usuario: «un botón… que la vuelque, una más suavemente otra más fuerte») ─────
## Un empujón de costado, como un golpe —lo mide la línea—: SUAVE, apenas pasado su caerse; FUERTE, mucho más.
func knock(strong: bool) -> void:
	if state != State.HOVER:
		return
	var side := global_basis.x
	side.y = 0.0
	linear_velocity += side.normalized() * HoverCube.delta_v_for_lean(
		tuning().fall_at * (KNOCK_STRONG if strong else KNOCK_SOFT), tuning())


## ── CUÁNTO HAY QUE EMPUJARLO ─────────────────────────────────────────────────────────────────────────────────────
## El cambio de velocidad (m/s) que lo lleva a la inclinación `target`: el golpe suma a la velocidad de la inclinación,
## y la inclinación más alta del resorte por unidad se calcula paso a paso (como la corre `_standing`).
static func delta_v_for_lean(target: float, knobs: HoverCubeSettings) -> float:
	var step := 1.0 / 240.0
	var lean_now := 0.0
	var speed_now := 1.0
	var peak := 0.0
	for i in 2400:
		speed_now += (-lean_now * knobs.stiffness - speed_now * knobs.damping) * step
		lean_now += speed_now * step
		peak = maxf(peak, lean_now)
		if speed_now < 0.0:
			break
	return target / maxf(peak * knobs.lean_per_ms * knobs.push_rate, 0.0001)


## ── MANEJARLO DESDE AFUERA (como la meca, ver Mech.toggle_outside) ─────────────────────────────────────────────
## El jugador se apaga mientras tanto (ni se ve ni lee teclas) y queda donde estaba. O o E vuelve.
func toggle_drive() -> void:
	if driving:
		_leave_drive()
		return
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	driving = true
	add_to_group("driving")
	player.set_active(false)
	_chase_yaw = _view_yaw()
	_camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _leave_drive() -> void:
	driving = false
	remove_from_group("driving")
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	player.set_active(true)
	if is_instance_valid(player.player_camera):
		player.player_camera.make_current()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if driving and key != null and key.pressed and not key.echo and key.physical_keycode == KEY_E:
		_leave_drive()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if driving:
		_leave_drive()


## La cámara, atrás y arriba, siguiéndolo con un poco de atraso.
func _place_camera(delta: float) -> void:
	if not driving:
		return
	_chase_yaw = lerp_angle(_chase_yaw, _view_yaw(), 1.0 - exp(-4.0 * delta))
	var behind := Basis(Vector3.UP, _chase_yaw) * Vector3(0.0, 14.0, 34.0)
	_camera.global_position = global_position + behind
	_camera.look_at(global_position + Vector3(0.0, 2.0, 0.0), Vector3.UP)


## Hacia dónde mira la cámara de afuera: hacia donde mira el cubo (de costado o dado vuelta, hacia donde miraba).
func _view_yaw() -> float:
	var forward := -global_basis.z
	forward.y = 0.0
	return atan2(-forward.x, -forward.z) if forward.length_squared() > 0.01 else _chase_yaw


## SUS PERILLAS: las de todos los cubos (un cubo distinto, como el de piernas, tiene las suyas).
func tuning() -> HoverCubeSettings:
	return HoverCubeSettings.current


static func _axis(positive: Key, negative: Key) -> float:
	return (1.0 if Input.is_physical_key_pressed(positive) else 0.0) - (1.0 if Input.is_physical_key_pressed(negative) else 0.0)


## ── LO QUE MIDE ──────────────────────────────────────────────────────────────────────────────────────────────────

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
