class_name KinematicPillar
extends AnimatableBody3D

## EL CUBO CINEMÁTICO (13/11/2026) — EXPERIMENTO: una caja alargada que llega hasta el piso, cinemática, para probar
## por separado CÓMO SE LLEVA LO CINEMÁTICO CON LO FÍSICO, sin la cabina, el ascensor ni las piernas de la meca. El
## usuario: «un cubo alargado que se mueva con caja en el piso, y así yo pruebo los distintos approaches de interacción
## de cinemático con físico… vamos por partes».
##
## SE MUEVE A MANO: se apoya en el piso, camina, corre, gira (con tope de velocidad y de aceleración), salta y se agacha
## (el alto cambia de a poco). Jolt no lo mueve: cada paso se pone donde calculó (el motor sabe su velocidad).
## LO FIJO (paredes, el piso) SIEMPRE LO FRENA. CON LO SUELTO, cuatro formas (`mode`, la L de la parcela):
##   · JOLT: lo que hace el motor solo. Para él la caja tiene masa infinita.
##   · TOPADORA CON TOPE: lo mismo, pero nada suelto cerca sale hacia afuera más rápido que la caja en ese punto (más
##     `cap_extra`).
##   · ATRAVIESA Y EMPUJA: no choca por el motor con lo suelto cercano; lo que se le mete adentro lo saca ella por la cara
##     más cercana, a la velocidad de la caja (más `ghost_extra`).
##   · PARED: lo suelto lo frena como lo fijo (también al bajar: se apoya encima).

enum Mode { JOLT, CAPPED, GHOST, WALL }

const MODE_NAMES := ["Jolt puro", "topadora con tope", "atraviesa y empuja", "lo suelto lo frena"]
## La caja: ancho, alto y fondo (m).
const SIZE := Vector3(6.0, 18.0, 6.0)
## Cuánto alrededor de la caja se mira lo suelto (m).
const NEAR := 2.0

## ── LO QUE SE LE PIDE ──
var move := Vector2.ZERO
var sprint := false
var crouch := false
var jump := false
var aim_yaw := 0.0
var mode := Mode.JOLT

## ── LO QUE MIDE ──
var velocity := Vector3.ZERO
var grounded := false
## Cuánto está agachado (0 a 1) y su alto de ahora.
var crouched := 0.0
var height := SIZE.y

## Dónde está (el medio de su cara de abajo): lo guarda él, no lo lee del nodo (ver `put`).
var _at := Vector3.ZERO
var _yaw := 0.0
var _yaw_speed := 0.0
var _jump_was := false
var _shape: BoxShape3D = null
var _holder: CollisionShape3D = null
var _look: MeshInstance3D = null
var _near := BoxShape3D.new()
var _ghosted := {}
var _driving := false
var _chase_yaw := 0.0


func _init() -> void:
	sync_to_physics = true


func _ready() -> void:
	_holder = CollisionShape3D.new()
	_shape = BoxShape3D.new()
	_shape.size = SIZE
	_holder.shape = _shape
	_holder.position.y = SIZE.y * 0.5
	add_child(_holder)
	_look = Clay.box(self, Vector3.ONE, Vector3.ZERO, Clay.METAL.darkened(0.1))
	# El frente, para saber hacia dónde mira.
	var front := Clay.box(_look, Vector3(0.6, 0.08, 0.05), Vector3(0.0, 0.42, -0.51), Clay.YELLOW)
	front.name = "Frente"
	_yaw = global_rotation.y
	_at = global_position
	aim_yaw = _yaw
	_resize()
	add_to_group(SandboxPossession.GROUP)


func _physics_process(delta: float) -> void:
	var k := PillarSettings.current
	_read()
	var place := _at
	# AGACHARSE: el alto cambia de a poco (el de abajo queda en el piso). Pararse con algo encima: ver el modo.
	var want := 1.0 if crouch else 0.0
	var next_crouch := move_toward(crouched, want, k.crouch_rate * delta)
	if next_crouch < crouched or not _blocked_growing(k, next_crouch):
		crouched = next_crouch
		_resize()
	# CAMINAR: hacia la velocidad pedida, con tope; en el aire, poco.
	var walk := k.walk_speed * (k.sprint_multiplier if sprint and move.y > 0.0 else 1.0)
	var wanted := Basis(Vector3.UP, _yaw) * Vector3(move.x, 0.0, -move.y).limit_length(1.0) * walk
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var most := (k.walk_accel if wanted.length_squared() > 0.01 else k.walk_brake) * (1.0 if grounded else 0.3)
	flat = flat.move_toward(wanted, most * delta)
	velocity = Vector3(flat.x, velocity.y, flat.z)
	# SALTAR (al apretar) Y CAER.
	var gravity := BalanceBody.gravity()
	if jump and not _jump_was and grounded:
		velocity.y = sqrt(2.0 * gravity * k.air_gravity * k.jump_height)
		grounded = false
	_jump_was = jump
	if not grounded:
		velocity.y -= gravity * k.air_gravity * delta
	# MOVERSE PROBANDO: de costado y, aparte, para arriba o abajo.
	place = _move(place, Vector3(velocity.x, 0.0, velocity.z) * delta)
	var up := _move(place, Vector3.UP * velocity.y * delta)
	if velocity.y < 0.0 and up.y > place.y + velocity.y * delta + 0.0001:
		velocity.y = 0.0
		grounded = true
	place = up
	if grounded:
		# Sigue apoyado si abajo, cerca, hay algo que lo frena; si no, cae.
		var below := _move(place, Vector3.DOWN * 0.1)
		if below.y < place.y - 0.09:
			grounded = false
		velocity.y = minf(velocity.y, 0.0)
	_turn(k, delta, place)
	_at = place
	global_transform = Transform3D(Basis(Vector3.UP, _yaw), place)
	match mode:
		Mode.CAPPED:
			_cap(k)
		Mode.GHOST:
			_ghost(k)
		_:
			_unghost_all()


## LO PONE en `where` (el medio de su cara de abajo), quieto. *Con la física sincronizada, poner su posición desde
## afuera no alcanza: el cuerpo la pisa con la suya (medido: el test lo reiniciaba y seguía donde había quedado).*
func put(where: Transform3D) -> void:
	_at = where.origin
	_yaw = where.basis.get_euler().y
	aim_yaw = _yaw
	_yaw_speed = 0.0
	velocity = Vector3.ZERO
	grounded = false
	global_transform = Transform3D(Basis(Vector3.UP, _yaw), _at)


func _resize() -> void:
	var share := lerpf(1.0, PillarSettings.current.crouch_share, crouched)
	height = SIZE.y * share
	_shape.size = Vector3(SIZE.x, height, SIZE.z)
	_holder.position.y = height * 0.5
	_look.transform = Transform3D(Basis().scaled(Vector3(SIZE.x, height, SIZE.z)), Vector3(0.0, height * 0.5, 0.0))


## Al pararse, si la caja más alta se metería en algo que la frena (lo fijo, o lo suelto en el modo pared).
func _blocked_growing(_k: PillarSettings, next_crouch: float) -> bool:
	var taller := SIZE.y * lerpf(1.0, PillarSettings.current.crouch_share, next_crouch)
	if taller <= height:
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(SIZE.x - 0.1, taller - height, SIZE.z - 0.1)
	query.shape = box
	query.transform = Transform3D(global_basis, global_position + Vector3.UP * (height + (taller - height) * 0.5))
	query.exclude = [get_rid()]
	for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 16):
		if _stops(hit["collider"]):
			return true
	return false


## EL GIRO: hacia `aim_yaw`, con tope de velocidad y de aceleración; si algo que lo frena lo traba, no gira.
func _turn(k: PillarSettings, delta: float, place: Vector3) -> void:
	var error := wrapf(aim_yaw - _yaw, -PI, PI)
	error = clampf(error, -PI * 0.6, PI * 0.6)
	aim_yaw = _yaw + error
	var top := deg_to_rad(k.turn_speed)
	var wanted := clampf(error * 6.0, -top, top)
	_yaw_speed = move_toward(_yaw_speed, wanted, deg_to_rad(k.turn_accel) * delta)
	var next := _yaw + _yaw_speed * delta
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape
	query.transform = Transform3D(Basis(Vector3.UP, next), place + Vector3.UP * (height * 0.5 + 0.05))
	query.exclude = [get_rid()]
	for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 16):
		if _stops(hit["collider"]):
			_yaw_speed = 0.0
			return
	_yaw = next


## Si `other` lo frena: lo fijo siempre; lo suelto, sólo en el modo pared.
func _stops(other: Object) -> bool:
	if other is StaticBody3D and not other is AnimatableBody3D:
		return true
	return mode == Mode.WALL and other is RigidBody3D and not (other as RigidBody3D).freeze


## MOVERSE PROBANDO: `motion` desde `from`; contra lo que lo frena se desliza; lo demás se saltea (lo empuja el motor, o
## él mismo en el modo que atraviesa).
func _move(from: Vector3, motion: Vector3) -> Vector3:
	if motion.length_squared() < 0.00000001:
		return from
	var params := PhysicsTestMotionParameters3D.new()
	params.from = Transform3D(Basis(Vector3.UP, _yaw), from)
	params.motion = motion
	params.margin = 0.02
	var skip: Array[RID] = []
	for attempt in 8:
		params.exclude_bodies = skip
		var result := PhysicsTestMotionResult3D.new()
		if not PhysicsServer3D.body_test_motion(get_rid(), params, result):
			return params.from.origin + params.motion
		if _stops(result.get_collider()):
			var normal := result.get_collision_normal()
			var into := velocity.dot(normal)
			if into < 0.0 and absf(normal.y) < 0.5:
				velocity -= normal * into
			var done := result.get_travel()
			params.from.origin += done
			params.motion = (params.motion - done).slide(normal)
			if params.motion.length_squared() < 0.00000001:
				return params.from.origin
		else:
			skip.append(result.get_collider_rid())
	return params.from.origin


## ── CON LO SUELTO ────────────────────────────────────────────────────────────────────────────────────────────────

## Lo suelto cerca de la caja.
func _loose_near() -> Array[RigidBody3D]:
	_near.size = Vector3(SIZE.x, height, SIZE.z) + Vector3.ONE * NEAR * 2.0
	var out: Array[RigidBody3D] = []
	for body in AreaStrike.loose_in(get_world_3d().direct_space_state, _near,
			Transform3D(global_basis, global_position + Vector3.UP * height * 0.5)):
		if body != self:
			out.append(body)
	return out


## Hacia afuera de la caja, desde `point` (mundo): la cara más cercana (en el mundo), y cuánto adentro está `point`
## agrandando la caja `grow` (negativo: afuera).
func _out_of(point: Vector3, grow: float) -> Array:
	var centre := global_position + Vector3.UP * height * 0.5
	var local := global_basis.inverse() * (point - centre)
	var half := Vector3(SIZE.x, height, SIZE.z) * 0.5 + Vector3.ONE * grow
	var room := half - local.abs()
	var axis := 0 if room.x <= room.y and room.x <= room.z else (1 if room.y <= room.z else 2)
	var out_local := Vector3.ZERO
	out_local[axis] = signf(local[axis]) if absf(local[axis]) > 0.0001 else 1.0
	var inside := minf(room.x, minf(room.y, room.z))
	return [(global_basis * out_local).normalized(), inside]


## La velocidad de la caja en `point` (lo que avanza, lo que gira y, arriba, lo que crece al pararse).
func _speed_at(point: Vector3) -> Vector3:
	var spin := Vector3.UP * _yaw_speed
	return velocity + spin.cross(point - global_position)


## TOPADORA CON TOPE (ver arriba).
func _cap(k: PillarSettings) -> void:
	_unghost_all()
	for body in _loose_near():
		var out: Vector3 = _out_of(body.global_position, 0.0)[0]
		var away := (body.linear_velocity - _speed_at(body.global_position)).dot(out)
		if away > k.cap_extra:
			body.linear_velocity -= out * (away - k.cap_extra)


## ATRAVIESA Y EMPUJA (ver arriba).
func _ghost(k: PillarSettings) -> void:
	var seen := {}
	for body in _loose_near():
		seen[body] = true
		if not _ghosted.has(body):
			add_collision_exception_with(body)
			_ghosted[body] = true
		var size := KinematicPillar.radius_of(body)
		var found := _out_of(body.global_position, size)
		var out: Vector3 = found[0]
		var inside: float = found[1]
		if inside <= 0.0:
			continue
		body.global_position += out * inside
		var push := maxf(_speed_at(body.global_position).dot(out), 0.0) + k.ghost_extra
		var now := body.linear_velocity.dot(out)
		if now < push:
			body.linear_velocity += out * (push - now)
	for body: Variant in _ghosted.keys():
		if not seen.has(body):
			if is_instance_valid(body):
				remove_collision_exception_with(body as PhysicsBody3D)
			_ghosted.erase(body)


func _unghost_all() -> void:
	for body: Variant in _ghosted.keys():
		if is_instance_valid(body):
			remove_collision_exception_with(body as PhysicsBody3D)
	_ghosted.clear()


## Cuánto mide lo suelto, de su centro a su borde, más o menos (m): su caja de choque.
static func radius_of(body: RigidBody3D) -> float:
	var most := 0.3
	for child in body.get_children():
		var holder := child as CollisionShape3D
		if holder != null and holder.shape is BoxShape3D:
			most = maxf(most, ((holder.shape as BoxShape3D).size * 0.5).length() * 0.7)
	return most


## ── POSEERLO (ver SandboxPossession) ─────────────────────────────────────────────────────────────────────────────

func _read() -> void:
	var mine := _driving and UIState.gameplay_active()
	if not mine:
		return
	move = Vector2(MechKeys.axis(KEY_D, KEY_A), MechKeys.axis(KEY_W, KEY_S))
	sprint = Input.is_physical_key_pressed(KEY_SHIFT)
	crouch = Input.is_physical_key_pressed(KEY_CTRL)
	jump = Input.is_physical_key_pressed(KEY_SPACE)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if not _driving or motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	aim_yaw -= motion.relative.x * 0.0025 * GameOptions.mouse_sensitivity
	get_viewport().set_input_as_handled()


func possess_name() -> String:
	return "Cubo cinemático"


func possess_controls() -> PackedStringArray:
	return PackedStringArray([
		"W/S adelante y atrás · A/D de costado · mouse gira (con tope)",
		"Shift corre · Ctrl se agacha (baja de a poco) · espacio salta",
	])


func possess_status() -> String:
	return "con lo suelto: %s · %.1f m/s · alto %.1f m%s" % [MODE_NAMES[mode],
		Vector2(velocity.x, velocity.z).length(), height, "" if grounded else " · en el aire"]


func possess_begin() -> void:
	_driving = true
	_chase_yaw = _yaw


func possess_end() -> void:
	_driving = false
	move = Vector2.ZERO
	sprint = false
	crouch = false
	jump = false


func possess_camera(first: bool, delta: float) -> Transform3D:
	if first:
		return global_transform * Transform3D(Basis(), Vector3(0.0, height + 1.5, 0.0))
	_chase_yaw = lerp_angle(_chase_yaw, _yaw, 1.0 - exp(-4.0 * delta))
	var at := global_position + Vector3.UP * height * 0.6
	var from := at + Basis(Vector3.UP, _chase_yaw) * Vector3(0.0, 12.0, 30.0)
	return Transform3D(Basis(), from).looking_at(at, Vector3.UP)
