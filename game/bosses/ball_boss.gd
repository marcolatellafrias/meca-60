class_name BallBoss
extends CharacterBody3D

## EL JEFE BOLA (13/11/2026), PASO 1: la bola con su rendija y las cuatro patas, para ver la forma, cómo camina, cómo
## choca y cómo se mueve. Lo pensó el usuario: «una bola con una rendija en el medio que le da toda la vuelta y ahí tiene
## un cañón que puede girar toda la circunferencia, y que tenga cuatro patas… como tentáculos con hélices al final»;
## «vamos a ir agregando cosas de a poco… empezar con la bola y las piernas solamente». Por ahora sin cañón, sin dash ni
## vuelo, y lo maneja quien lo posee (la O): la computadora, después.
##
## SE MUEVE COMO LA MECA SIMPLIFICADA (ver KinematicMover): el controlador de personaje del motor, con un cilindro que mira
## sólo lo fijo del mundo (PhysicsLayers.FIXED), del piso a lo alto de la bola. Contra lo suelto y los personajes, la
## bola (un AnimatableBody3D que lo sigue). Movimiento discreto, en metros y segundos (BallBossSettings).
##   · MOVERSE: una velocidad y el tiempo para llegar a ella. En el aire no se mueve de costado.
##   · GIRAR: con tope de velocidad y de aceleración.
##   · SALTAR (espacio): sólo para arriba.
##   · HECHA BOLA (Shift, ver BallRoll): mete las patas, baja y rueda; dobla y pega al tocar.
##   · EL BARRIDO (Q, ver BallLegs): las paletas giran como hélices y dan la vuelta alrededor; mientras, no camina.
##   · AGACHARSE (Ctrl): SÓLO BAJA LA BOLA; los tentáculos se doblan solos (el usuario: «lo único que hace en realidad es
##     bajar la bola, porque el IK de los tentáculos es como que actúa solo»).
## Es MÁS DEL DOBLE DE LA MECA («quiero que sea más grande que la meca… por lo menos el doble»): la bola mide 30 m y su
## techo queda a 35 m (el cubo de la meca, 18 m). Las patas son gruesas y cortas, para que vaya cerca del piso.
##
## LA RENDIJA VA DE ARRIBA A ABAJO, de adelante hacia atrás por arriba: el cañón va a subir y bajar por ella (adelante, al
## cielo). Para apuntar de costado gira la bola entera, con las patas (el usuario: «la rendija es en la otra dirección, si
## quiere rotar en y, va a usar las piernas»).

## El radio de la bola (m).
const RADIUS := 15.0
## Ancha y poco hundida (el usuario: «la rendija más gruesa y menos indentada»).
const SLIT_DEPTH := 0.6
## EL CASCO LOW POLY (BallShell): franjas de polo a polo, cuántas del medio son la rendija, y caras alrededor. El ancho de
## la rendija sale de ahí (2·radio·sen de media rendija).
const SHELL_BANDS := 16
const SLIT_BANDS := 2
const SHELL_SIDES := 18
const SLIT := 2.0 * RADIUS * 0.19509
## El cilindro contra lo fijo: un poco más ancho que la bola (m).
const REACH := 16.0

## ── LO QUE SE LE PIDE ──
var move := Vector2.ZERO
var crouch := false
var jump := false
var aim_yaw := 0.0
## Hacia dónde apunta el cañón por la rendija (radianes: 0 adelante, positivo para arriba, da la vuelta entera).
var aim_pitch := 0.0
## Los tiros (de a un toque): el simple, derecho adonde apunta, y los del cielo, uno tras otro (ver BallCannon).
var fire := false
## Hecha bola (ver BallRoll): mete las patas y rueda. Poseída, Shift lo cambia.
var curl := false
## El barrido con las paletas (de a un toque; ver BallLegs). Poseída, la Q.
var sweep := false
var barrage := false

## ── LO QUE MIDE ──
var grounded := false
## Cuánto está agachado (0 a 1) y a qué altura va el centro de la bola.
var crouched := 0.0
var center_height := 20.0
var legs: BallLegs = null
var cannon: BallCannon = null
var roll := BallRoll.new()

var _yaw := 0.0
var _yaw_speed := 0.0
var _jump_was := false
var _fire_was := false
var _shift_was := false
var _sweep_was := false
var _was_rolling := false
var _barrage_was := false
var _cylinder := CylinderShape3D.new()
var _holder: CollisionShape3D = null
var _ball: AnimatableBody3D = null
var _driving := false
var _chase_yaw := 0.0


func _init() -> void:
	# A él no lo ve nadie, y él ve sólo lo fijo del mundo.
	collision_layer = 0
	collision_mask = PhysicsLayers.FIXED
	floor_snap_length = 0.3


func _ready() -> void:
	_cylinder.radius = REACH
	_holder = CollisionShape3D.new()
	_holder.shape = _cylinder
	add_child(_holder)
	_yaw = global_rotation.y
	aim_yaw = _yaw
	_fit(BallBossSettings.current)
	# LA BOLA: la que se ve y la que empuja lo suelto. Nace ya en su lugar (ver PillarFeet: un cuerpo entra a la física
	# donde está al agregarlo al árbol).
	_ball = AnimatableBody3D.new()
	_ball.name = "Bola"
	_ball.top_level = true
	_ball.sync_to_physics = false
	_ball.transform = _ball_place()
	add_child(_ball)
	_ball.sync_to_physics = true
	_dress(_ball)
	# PARA LAS MECAS CINEMÁTICAS, LA BOLA ES PARED: ellas chocan sólo con lo fijo del mundo, así que la bola va también en
	# esa capa. No pueden meterse en ella, y si la bola se les mete encima, su motor las saca hacia afuera (el jefe gana:
	# es el doble). Él no se choca con su propia bola.
	PhysicsLayers.mark_fixed(_ball)
	add_collision_exception_with(_ball)
	cannon = BallCannon.new()
	cannon.name = "Cañón"
	_ball.add_child(cannon)
	cannon.build(RADIUS, SLIT, SLIT_DEPTH)
	legs = BallLegs.new()
	add_child(legs)
	legs.place_now(BallBossSettings.current, _ball_place().origin, _yaw, RADIUS)
	add_to_group(SandboxPossession.GROUP)


## LA BOLA DE ARCILLA: dos medias esferas, la izquierda y la derecha, separadas por la rendija, que le da toda la vuelta
## de arriba a abajo, con su fondo oscuro. El cañón (BallCannon) va metido en ella.
static func _dress(ball: AnimatableBody3D) -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	shape.shape = sphere
	ball.add_child(shape)
	var shell := MeshInstance3D.new()
	shell.mesh = BallShell.mesh(RADIUS, SHELL_BANDS, SLIT_BANDS, SHELL_SIDES, SLIT_DEPTH)
	shell.set_surface_override_material(0, Clay.material(Clay.METAL.darkened(0.05)))
	shell.set_surface_override_material(1, Clay.material(Clay.DARK.darkened(0.4)))
	ball.add_child(shell)


func _physics_process(delta: float) -> void:
	var k := BallBossSettings.current
	_read()
	crouched = move_toward(crouched, 1.0 if crouch else 0.0, k.crouch_rate * delta)
	grounded = is_on_floor()
	var heading := Basis(Vector3.UP, _yaw) * Vector3.FORWARD
	var rolled := roll.step(k, delta, curl, move.y, heading)
	_fit(k)
	if sweep and not _sweep_was and roll.fold <= 0.0 and grounded:
		legs.sweep()
	_sweep_was = sweep
	var flat_now := rolled if roll.fold > 0.0 else _walk(k, delta)
	if legs.sweeping:
		flat_now = Vector3.ZERO
	velocity = Vector3(flat_now.x, _rise(k, delta), flat_now.z)
	_jump_was = jump
	if roll.rolling():
		# Rodando, A/D doblan (y el mouse, como siempre).
		aim_yaw -= move.x * deg_to_rad(k.roll_turn) * delta
	_turn(k, delta, k.roll_turn if roll.fold > 0.0 else k.turn_speed)
	rotation.y = _yaw
	move_and_slide()
	grounded = is_on_floor()
	var flat := get_real_velocity()
	flat.y = 0.0
	roll.turn_ball(flat, RADIUS, delta)
	_ball.global_transform = _ball_place()
	roll.strike(k, get_world_3d().direct_space_state, _ball_place().origin, RADIUS, flat)
	cannon.step(k, aim_pitch, delta, roll.fold)
	if fire and not _fire_was and roll.fold <= 0.0:
		cannon.shoot(k)
	if barrage and not _barrage_was and roll.fold <= 0.0:
		cannon.barrage(k, _barrage_targets(k))
	_fire_was = fire
	_barrage_was = barrage
	if roll.fold <= 0.0:
		legs.step(k, delta, _ball_place().origin, _yaw, flat, grounded, RADIUS)
	else:
		# Al empezar a abrirse, los pies salen hacia su lugar en el piso.
		if _was_rolling and not roll.rolling():
			legs.homes(k, _ball_place().origin, _yaw)
		legs.folded(k, _ball_place().origin, _yaw, RADIUS, roll.fold)
	_was_rolling = roll.rolling()


func _walk(k: BallBossSettings, delta: float) -> Vector3:
	if not grounded:
		return Vector3.ZERO
	var wanted := Basis(Vector3.UP, _yaw) * Vector3(move.x, 0.0, -move.y).limit_length(1.0) * k.walk_speed
	if k.reach_time <= 0.0:
		return wanted
	return Vector3(velocity.x, 0.0, velocity.z).move_toward(wanted, k.walk_speed / k.reach_time * delta)


## EL SALTO: sube `jump_height` en `jump_time` (g = 2·h / t², y sale a v = 2·h / t). Devuelve la velocidad para arriba.
func _rise(k: BallBossSettings, delta: float) -> float:
	if grounded:
		if jump and not _jump_was:
			return 2.0 * k.jump_height / k.jump_time
		return 0.0
	return velocity.y - 2.0 * k.jump_height / (k.jump_time * k.jump_time) * delta


## La altura del centro (parado, agachado o hecha bola) y el cilindro, del piso a lo alto de la bola: hecha bola, del
## ancho de la bola.
func _fit(k: BallBossSettings) -> void:
	var standing := lerpf(k.stand_height, k.crouch_height, smoothstep(0.0, 1.0, crouched))
	var eased := smoothstep(0.0, 1.0, roll.fold)
	center_height = lerpf(standing, RADIUS, eased)
	_cylinder.radius = lerpf(REACH, RADIUS, eased)
	_cylinder.height = center_height + RADIUS
	_holder.position.y = _cylinder.height * 0.5


func _ball_place() -> Transform3D:
	return Transform3D(Basis(roll.spin) * Basis(Vector3.UP, _yaw), global_position + Vector3.UP * center_height)


func _turn(k: BallBossSettings, delta: float, top_speed: float) -> void:
	var error := clampf(wrapf(aim_yaw - _yaw, -PI, PI), -PI * 0.6, PI * 0.6)
	aim_yaw = _yaw + error
	var top := deg_to_rad(top_speed)
	_yaw_speed = move_toward(_yaw_speed, clampf(error * 4.0, -top, top), deg_to_rad(k.turn_accel) * delta)
	_yaw += _yaw_speed * delta


## DÓNDE CAEN LOS DEL CIELO: en fila hacia adelante, en el piso. *Cuando la maneje la computadora: al jugador y adonde
## va.*
func _barrage_targets(k: BallBossSettings) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var ahead := Basis(Vector3.UP, _yaw) * Vector3.FORWARD
	for i in k.barrage_count:
		var point := global_position + ahead * (k.barrage_distance + i * k.barrage_spacing)
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 100.0, point + Vector3.DOWN * 100.0,
			PhysicsLayers.FIXED)
		ray.exclude = [_ball.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		out.append(hit["position"] if not hit.is_empty() else point)
	return out


## LA PONE en `where` (el punto del piso debajo de su centro), quieta, con los pies en su lugar.
func put(where: Transform3D) -> void:
	global_position = where.origin
	_yaw = where.basis.get_euler().y
	rotation.y = _yaw
	aim_yaw = _yaw
	_yaw_speed = 0.0
	velocity = Vector3.ZERO
	grounded = false
	_ball.sync_to_physics = false
	_ball.global_transform = _ball_place()
	_ball.sync_to_physics = true
	legs.place_now(BallBossSettings.current, _ball_place().origin, _yaw, RADIUS)


## ── POSEERLA (ver SandboxPossession) ─────────────────────────────────────────────────────────────────────────────

func _read() -> void:
	if not (_driving and UIState.gameplay_active()):
		return
	move = Vector2(MechKeys.axis(KEY_D, KEY_A), MechKeys.axis(KEY_W, KEY_S))
	crouch = Input.is_physical_key_pressed(KEY_CTRL)
	jump = Input.is_physical_key_pressed(KEY_SPACE)
	sweep = Input.is_physical_key_pressed(KEY_Q)
	var shift := Input.is_physical_key_pressed(KEY_SHIFT)
	if shift and not _shift_was:
		curl = not curl
	_shift_was = shift
	var aiming := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	fire = aiming and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	barrage = aiming and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if not _driving or motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	aim_yaw -= motion.relative.x * 0.0025 * GameOptions.mouse_sensitivity
	aim_pitch = wrapf(aim_pitch - motion.relative.y * 0.0025 * GameOptions.mouse_sensitivity, -PI, PI)
	get_viewport().set_input_as_handled()


## La bola (el cuerpo que se ve y choca): los rayos a lo fijo la saltean, porque también está en esa capa.
func ball() -> AnimatableBody3D:
	return _ball


## Si alguien la posee (entonces su cabeza, BallBrain, no hace nada).
func driven() -> bool:
	return _driving


func possess_name() -> String:
	return "Jefe bola"


func possess_controls() -> PackedStringArray:
	return PackedStringArray([
		"W/S adelante y atrás · A/D de costado · mouse gira (con tope)",
		"mouse arriba y abajo: el cañón corre por la rendija (da la vuelta entera)",
		"clic izquierdo: el tiro simple, adonde apunta · clic derecho: misiles del cielo, uno tras otro",
		"Q: el barrido, las paletas giran y dan la vuelta alrededor",
		"Ctrl se agacha (baja la bola) · espacio salta (sólo para arriba)",
		"Shift: hecha bola (las patas adentro) y otra vez se abre · rodando: W acelera, S frena, A/D y el mouse doblan",
	])


func possess_status() -> String:
	return "%.1f m/s · centro a %.1f m%s · %d pasos · cañón a %.0f°%s" % [Vector2(velocity.x, velocity.z).length(),
		center_height, "" if grounded else " · en el aire", legs.steps, rad_to_deg(cannon.pitch),
		(" · hecha bola, pegó %d" % roll.hits) if roll.fold > 0.0 else (" · barrido, pegó %d" % legs.sweep_hits
		if legs.sweeping else "")]


func possess_begin() -> void:
	_driving = true
	_chase_yaw = _yaw


func possess_end() -> void:
	_driving = false
	move = Vector2.ZERO
	crouch = false
	jump = false
	fire = false
	barrage = false
	_shift_was = false
	sweep = false


func possess_camera(first: bool, delta: float) -> Transform3D:
	if first:
		var eye := global_position + Vector3.UP * center_height + Basis(Vector3.UP, _yaw) * Vector3(0.0, 0.0, -RADIUS)
		return Transform3D(Basis(Vector3.UP, _yaw), eye)
	_chase_yaw = lerp_angle(_chase_yaw, _yaw, 1.0 - exp(-3.0 * delta))
	var at := global_position + Vector3.UP * center_height * 0.7
	var from := at + Basis(Vector3.UP, _chase_yaw) * Vector3(0.0, 22.0, 75.0)
	return Transform3D(Basis(), from).looking_at(at, Vector3.UP)
