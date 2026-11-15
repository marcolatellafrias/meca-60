class_name BallBoss
extends CharacterBody3D

## EL JEFE BOLA (13/11/2026): la bola con cuatro patas. Lo pensó el usuario: «una bola… y que tenga cuatro patas… como
## tentáculos con hélices al final». La maneja su cabeza (BallBrain) o quien lo posee (la O).
## REDISEÑADO EL 15/11/2026: SIN RENDIJA NI CAÑÓN; arriba, UNA CABEZA DE DISCO con el ojo (una tira roja), y ABAJO, ENTRE
## LAS PATAS, EL NÚCLEO, su punto débil (el usuario: «lo único que tiene como armamento son los tentáculos y el ojo… se
## elimina todo lo de la rendija»; «el punto débil sea básicamente ir caminando y sacarle el núcleo que queda como abajo,
## entre las piernas… te la jugás, no tenés que saltar desde ningún lado»). Hecha bola, la cabeza y el núcleo se meten.
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

## LA FORMA SON PERILLAS (BallBossSettings, pestaña Forma; 14/11/2026): el radio, la cabeza, el núcleo y los tentáculos.
## Se arma al nacer y se rearma al guardar el F1 (`rebuild`).

## ── LO QUE SE LE PIDE ──
var move := Vector2.ZERO
var crouch := false
var jump := false
var aim_yaw := 0.0
## Hecha bola (ver BallRoll): mete las patas y rueda. Poseída, Shift lo cambia.
var curl := false
## El barrido con las paletas (de a un toque; ver BallLegs). Poseída, la Q.
var sweep := false

## ── LO QUE MIDE ──
var grounded := false
## Cuánto está agachado (0 a 1) y a qué altura va el centro de la bola.
var crouched := 0.0
var center_height := 20.0
var legs: BallLegs = null
var roll := BallRoll.new()
## LA ARENA (BossArena): el círculo del que no sale. Sin arena, anda por donde sea.
var arena: BossArena = null
## El radio de la bola (m), el de la pestaña Forma cuando se armó.
var radius := 15.0

var _yaw := 0.0
var _yaw_speed := 0.0
var _jump_was := false
var _shift_was := false
var _sweep_was := false
var _was_rolling := false
var _cylinder := CylinderShape3D.new()
var _holder: CollisionShape3D = null
var _ball: AnimatableBody3D = null
var _driving := false
var _chase_yaw := 0.0
var _reach := 16.0
var _shell: MeshInstance3D = null
var _sphere: CollisionShape3D = null
var _head: Node3D = null
var _core: Node3D = null


func _init() -> void:
	# A él no lo ve nadie, y él ve sólo lo fijo del mundo.
	collision_layer = 0
	collision_mask = PhysicsLayers.FIXED
	floor_snap_length = 0.3


func _ready() -> void:
	_measure(BallBossSettings.current)
	_cylinder.radius = _reach
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
	_dress(BallBossSettings.current)
	# PARA LAS MECAS CINEMÁTICAS, LA BOLA ES PARED: ellas chocan sólo con lo fijo del mundo, así que la bola va también en
	# esa capa. No pueden meterse en ella, y si la bola se les mete encima, su motor las saca hacia afuera (el jefe gana:
	# es el doble). Él no se choca con su propia bola.
	PhysicsLayers.mark_fixed(_ball)
	add_collision_exception_with(_ball)
	legs = BallLegs.new()
	add_child(legs)
	legs.place_now(BallBossSettings.current, _ball_place().origin, _yaw, radius)
	add_to_group(SandboxPossession.GROUP)


## LO QUE SALE DE LA FORMA: el radio y el ancho del cilindro contra lo fijo.
func _measure(k: BallBossSettings) -> void:
	radius = k.radius
	_reach = k.radius + k.reach_margin


## LA BOLA DE ARCILLA: una esfera lisa, su esfera para chocar, la cabeza de disco con el ojo y el núcleo de abajo (los
## dos, aparte: no giran con la bola). Rearmándola, saca lo de antes.
func _dress(k: BallBossSettings) -> void:
	for old in [_sphere, _shell, _head, _core]:
		if old != null:
			old.queue_free()
	_sphere = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	_sphere.shape = sphere
	_ball.add_child(_sphere)
	_shell = Clay.sphere(_ball, radius, Vector3.ZERO, Clay.METAL.darkened(0.05))
	(_shell.mesh as SphereMesh).radial_segments = 48
	(_shell.mesh as SphereMesh).rings = 24
	# LA CABEZA: un disco arriba, adelante, con el ojo como una tira roja recortada en su frente (como la Tenaza).
	_head = Node3D.new()
	_head.name = "Disco del ojo"
	_head.top_level = true
	add_child(_head)
	Clay.cylinder(_head, k.head_radius, k.head_height, Vector3.ZERO, Clay.METAL.lightened(0.1))
	Clay.cylinder(_head, k.head_radius + 0.25, 0.6, Vector3.DOWN * k.head_height * 0.5, Clay.DARK)
	var red := BallBoss._glow(Color(1.0, 0.12, 0.08))
	for i in 13:
		var angle := deg_to_rad(-60.0 + i * 10.0)
		var out := Vector3(sin(angle), 0.0, -cos(angle))
		var bit := Clay.box(_head, Vector3(k.head_radius * 2.0 * sin(deg_to_rad(5.0)) + 0.08, k.head_height * 0.28, 0.3),
			out * (k.head_radius - 0.05) + Vector3.UP * k.head_height * 0.08, red.albedo_color)
		bit.basis = Basis.looking_at(out, Vector3.UP)
		bit.material_override = red
	# EL NÚCLEO: abajo, entre las patas, colgado de la bola; brilla.
	_core = Node3D.new()
	_core.name = "Núcleo"
	_core.top_level = true
	add_child(_core)
	var glow := Clay.sphere(_core, k.core_radius, Vector3.ZERO, Color(1.0, 0.5, 0.1))
	glow.material_override = BallBoss._glow(Color(1.0, 0.5, 0.1))
	Clay.cylinder(_core, k.core_radius * 0.5, 4.0, Vector3.UP * (k.core_radius + 1.5), Clay.DARK)
	_place_parts()


## Un material que brilla, de `color` (uno por pieza: nada estático, que al cerrar Godot se caía).
static func _glow(color: Color) -> StandardMaterial3D:
	var made := StandardMaterial3D.new()
	made.albedo_color = color
	made.emission_enabled = true
	made.emission = color
	made.emission_energy_multiplier = 2.2
	return made


## LA CABEZA Y EL NÚCLEO en su lugar: la cabeza arriba y adelante de la bola (asoma al frente, como una cara), mirando
## adonde mira; el núcleo debajo, sin tocar el piso. Hecha bola, los dos se meten adentro.
func _place_parts() -> void:
	if _head == null:
		return
	var k := BallBossSettings.current
	var center := _ball_place().origin
	var tuck := smoothstep(0.0, 0.6, roll.fold)
	var facing := Basis(Vector3.UP, _yaw)
	var top := center + facing * Vector3(0.0, radius * 0.8, -radius * 0.45)
	_head.global_transform = Transform3D(facing, top.lerp(center, tuck))
	_head.visible = tuck < 0.9
	var low := center + Vector3.DOWN * (radius + k.core_radius + 1.0)
	low.y = maxf(low.y, global_position.y + k.core_radius + 0.8)
	_core.global_transform = Transform3D(facing, low.lerp(center, tuck))
	_core.visible = tuck < 0.9


## Dónde está el núcleo (mundo): el punto débil.
func core() -> Vector3:
	return _core.global_position if _core != null else global_position


## LA REARMA con la pestaña Forma de sus perillas, donde está: la bola, el cañón y las patas, y los pies a su lugar.
func rebuild() -> void:
	var k := BallBossSettings.current
	_measure(k)
	_dress(k)
	legs.rebuild(k)
	_fit(k)
	put(Transform3D(Basis(Vector3.UP, _yaw), global_position))


## El ancho del cilindro que choca con lo fijo (m).
func reach() -> float:
	return _reach


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
		aim_yaw -= move.x * deg_to_rad(roll.turn_rate(k)) * delta
	_turn(k, delta, roll.turn_rate(k) if roll.fold > 0.0 else k.turn_speed)
	rotation.y = _yaw
	if arena != null:
		arena.resize(k.arena_radius)
		velocity = arena.keep(global_position, velocity, _cylinder.radius)
	move_and_slide()
	if arena != null:
		global_position = arena.hold(global_position, _cylinder.radius)
	grounded = is_on_floor()
	var flat := get_real_velocity()
	flat.y = 0.0
	if roll.fold > 0.0:
		roll.moved(flat.dot(heading), k)
	roll.turn_ball(flat, radius, delta)
	_ball.global_transform = _ball_place()
	roll.strike(k, get_world_3d().direct_space_state, _ball_place().origin, radius, flat)
	_place_parts()
	if roll.fold <= 0.0:
		legs.step(k, delta, _ball_place().origin, _yaw, flat, grounded, radius)
	else:
		# Al empezar a abrirse, los pies salen hacia su lugar en el piso.
		if _was_rolling and not roll.rolling():
			legs.homes(k, _ball_place().origin, _yaw)
		legs.folded(k, _ball_place().origin, _yaw, radius, roll.fold)
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
	var standing := maxf(lerpf(k.stand_height, k.crouch_height, smoothstep(0.0, 1.0, crouched)), radius)
	var eased := smoothstep(0.0, 1.0, roll.fold)
	center_height = lerpf(standing, radius, eased)
	_cylinder.radius = lerpf(_reach, radius, eased)
	_cylinder.height = center_height + radius
	_holder.position.y = _cylinder.height * 0.5


func _ball_place() -> Transform3D:
	return Transform3D(Basis(roll.spin) * Basis(Vector3.UP, _yaw), global_position + Vector3.UP * center_height)


func _turn(k: BallBossSettings, delta: float, top_speed: float) -> void:
	var error := clampf(wrapf(aim_yaw - _yaw, -PI, PI), -PI * 0.6, PI * 0.6)
	aim_yaw = _yaw + error
	var top := deg_to_rad(top_speed)
	_yaw_speed = move_toward(_yaw_speed, clampf(error * 4.0, -top, top), deg_to_rad(k.turn_accel) * delta)
	_yaw += _yaw_speed * delta


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
	legs.place_now(BallBossSettings.current, _ball_place().origin, _yaw, radius)


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


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if not _driving or motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	aim_yaw -= motion.relative.x * 0.0025 * GameOptions.mouse_sensitivity
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
		"Q: el barrido, las paletas giran y dan la vuelta alrededor",
		"Ctrl se agacha (baja la bola) · espacio salta (sólo para arriba)",
		"Shift: hecha bola (las patas adentro) y otra vez se abre · rodando: W acelera, S frena, A/D y el mouse doblan",
	])


func possess_status() -> String:
	return "%.1f m/s · centro a %.1f m%s · %d pasos%s" % [Vector2(velocity.x, velocity.z).length(),
		center_height, "" if grounded else " · en el aire", legs.steps,
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
	_shift_was = false
	sweep = false


func possess_camera(first: bool, delta: float) -> Transform3D:
	if first:
		var eye := global_position + Vector3.UP * center_height + Basis(Vector3.UP, _yaw) * Vector3(0.0, 0.0, -radius)
		return Transform3D(Basis(Vector3.UP, _yaw), eye)
	_chase_yaw = lerp_angle(_chase_yaw, _yaw, 1.0 - exp(-3.0 * delta))
	var at := global_position + Vector3.UP * center_height * 0.7
	var from := at + Basis(Vector3.UP, _chase_yaw) * Vector3(0.0, 22.0, 75.0)
	return Transform3D(Basis(), from).looking_at(at, Vector3.UP)
