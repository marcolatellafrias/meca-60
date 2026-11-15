class_name HitReaction
extends Node

## LO QUE LE HACE UN GOLPE DE UN JEFE A QUIEN RECIBE (15/11/2026), como en los jefes de Souls: el daño lo decide la
## cabeza del jefe (sus zonas de golpe, ver docs/technical/pelea-jefes.md) y acá pasa lo que se ve. Se cuelga solo
## («Reacción») de quien recibe la primera vez. El usuario: «la mecha se hace hacia atrás… pero que sea algo cinemático…
## con un indicador que muestre cuando le pegan un golpe, como que se vuelve blanca por un segundo… una partícula… una
## audio cue… el estado de la nave que se cae y se levanta, que también tiene que ser cinemático… una animación bien
## simple».
##   · SIEMPRE: SE PONE BLANCA un momento (un material encima de todas sus mallas), CHISPAS donde pegó y un SONIDO
##     (BossSounds).
##   · LA REACCIÓN (`Kind`), según el ataque: AGUANTA (no se mueve); EMPUJADA, se corre tantos metros, parada, en un
##     momento; DERRIBADA, sale para atrás con un saltito y cae de espaldas, queda TIRADA y SE LEVANTA (mientras, no se
##     le puede pegar ni se maneja). Y las del agarre: AGARRADA (la lleva el jefe) y REVOLEADA (vuela en arco y, al caer,
##     derribada).
##   · A LA MECA CINEMÁTICA LA MUEVE ESTO, no la física: corre después de ella en cada paso, la vuelve a donde estaba y
##     la mueve por su motor con choque (no atraviesa edificios), y la inclina para caerse. A la física (y a lo demás) le
##     da un impulso: se cae con su física.
## *Es una puerta provisoria del módulo Jefes: «qué le hace un golpe» a la cinemática es del módulo Meca (ver
## BalanceBody.push_impulse); cuando lo decida, esto le pasa la posta.*

enum Kind { FLINCH, PUSH, KNOCKDOWN }
enum State { FREE, PUSHED, FALLING, DOWN, RISING, HELD, FLYING }

const NODE_NAME := "Reacción"
## El destello (s), empujada (s), derribada: cuánto tarda en caer (s), el saltito (m), cuánto queda tirada y cuánto
## tarda en levantarse (s), y cuánto se inclina (°).
const FLASH_TIME := 0.3
const PUSH_TIME := 0.35
const FALL_TIME := 0.5
const FALL_HOP := 3.0
const DOWN_TIME := 1.1
const RISE_TIME := 0.8
const LIE := 78.0
## Lo que se corre la física por cada metro de empuje (m/s).
const PHYSICAL_SPEED := 1.2

var state := State.FREE
## Cuántos golpes recibió (para mirar).
var hits := 0

var _target: Node3D = null
var _body: BalanceBody = null
var _clock := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _arc := 0.0
var _time := 0.0
var _away := Vector3.BACK
var _yaw := 0.0
var _at := Vector3.ZERO
var _land_damage := 0.0
var _land_what := ""
var _flash := 0.0
var _last := Vector3.ZERO
var _hold := Vector3.ZERO
var _painted: Array[MeshInstance3D] = []
var _white := StandardMaterial3D.new()


## La reacción de `node` (se cuelga la primera vez).
static func of(node: Node3D) -> HitReaction:
	var found := node.get_node_or_null(NODE_NAME) as HitReaction
	if found == null:
		found = HitReaction.new()
		found.name = NODE_NAME
		node.add_child(found)
	return found


## UN GOLPE A `target`: le saca `damage` por `what` y reacciona con `kind`, empujado `distance` m hacia `away` (de
## costado); `at`, dónde pegó (las chispas). Si no se le puede pegar (tirada, agarrada), nada: devuelve false.
static func land(target: Node3D, damage: float, what: String, kind: Kind, away: Vector3, distance: float,
		at: Vector3) -> bool:
	var reaction := of(target)
	if reaction.untouchable():
		return false
	var health := Health.of(target)
	if health != null:
		health.hurt(damage, what)
	reaction.react(kind, away, distance, at)
	return true


func _ready() -> void:
	_target = get_parent() as Node3D
	_body = _target as BalanceBody
	# Después de que ella se movió en el paso (ver arriba).
	process_physics_priority = 50
	_white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_white.albedo_color = Color(1, 1, 1, 0)


## Si ahora no se le puede pegar: tirada, agarrada, volando, o EN EL DASH (intocable un momento, como la rodada de
## Souls: lo dice el cuerpo, BalanceBody.untouchable, del módulo Meca).
func untouchable() -> bool:
	return down() or (_body != null and _body.untouchable())


## Si está tirada, agarrada o volando (el jefe no la frena: pasa).
func down() -> bool:
	return state in [State.FALLING, State.DOWN, State.RISING, State.HELD, State.FLYING]


## Si la está moviendo esto (no se maneja).
func busy() -> bool:
	return state != State.FREE


## LO QUE SE VE Y SE OYE, y la reacción.
func react(kind: Kind, away: Vector3, distance: float, at: Vector3) -> void:
	hits += 1
	_at = at
	show_hit(at, kind == Kind.KNOCKDOWN)
	_away = Vector3(away.x, 0.0, away.z).normalized()
	if _away == Vector3.ZERO:
		_away = Vector3.BACK
	if kind == Kind.FLINCH:
		return
	if not _kinematic():
		if _body != null:
			var lift := 0.45 if kind == Kind.KNOCKDOWN else 0.15
			BalanceBody.hit(_body, (_away + Vector3.UP * lift).normalized() * distance * PHYSICAL_SPEED * _body.mass)
		return
	_from = _ground()
	_last = _from
	_to = _floor(_from + _away * distance)
	_yaw = _body.mover.rotation.y
	_clock = 0.0
	if kind == Kind.PUSH:
		state = State.PUSHED
		_time = PUSH_TIME
		_arc = 0.0
	else:
		state = State.FALLING
		_time = FALL_TIME
		_arc = FALL_HOP


## Sólo lo que se ve y se oye (también para el jefe cuando le pegan).
func show_hit(at: Vector3, heavy: bool) -> void:
	_flash = FLASH_TIME
	_paint(true)
	_sparks(at, heavy)
	BossSounds.play(BossSounds.Kind.KNOCKDOWN if heavy else BossSounds.Kind.HIT, at, _target)


## AGARRADA: la lleva quien la agarró (`hold_at` en cada paso).
func grab(at: Vector3) -> void:
	hits += 1
	show_hit(at, false)
	BossSounds.play(BossSounds.Kind.GRAB, at, _target)
	if not _kinematic():
		return
	state = State.HELD
	_yaw = _body.mover.rotation.y
	_hold = _ground()


## AGARRADA, va a `at` (el piso debajo de sus pies; la pone ahí en su paso, después de que ella se movió).
func hold_at(at: Vector3) -> void:
	_hold = at


## REVOLEADA: de donde está, vuela en arco hasta `to` (el piso) en `time` s, subiendo `arc` m; al caer le saca
## `damage` por `what` y queda derribada.
func fling(to: Vector3, arc: float, time: float, damage: float, what: String) -> void:
	if not _kinematic():
		state = State.FREE
		return
	state = State.FLYING
	_from = _ground()
	_last = _from
	_to = _floor(to)
	_away = Vector3(_to.x - _from.x, 0.0, _to.z - _from.z).normalized()
	_arc = arc
	_time = maxf(time, 0.1)
	_clock = 0.0
	_land_damage = damage
	_land_what = what


## Suelta todo (para las pruebas).
func clear() -> void:
	state = State.FREE
	_flash = 0.0
	_paint(false)


func _physics_process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		_white.albedo_color.a = 0.85 * clampf(_flash / FLASH_TIME, 0.0, 1.0)
		if _flash <= 0.0:
			_paint(false)
	if state == State.FREE or not _kinematic():
		return
	if state == State.HELD:
		_body.put(Transform3D(Basis(Vector3.UP, _yaw), _hold))
		return
	_clock += delta
	var t := clampf(_clock / _time, 0.0, 1.0)
	match state:
		State.PUSHED:
			_slide(_from.lerp(_to, 1.0 - (1.0 - t) * (1.0 - t)))
			if t >= 1.0:
				state = State.FREE
		State.FALLING:
			_slide(_from.lerp(_to, 1.0 - (1.0 - t) * (1.0 - t)) + Vector3.UP * _arc * 4.0 * t * (1.0 - t))
			_lean(LIE * t * t)
			if t >= 1.0:
				BossSounds.play(BossSounds.Kind.LAND, _ground(), _target)
				_next(State.DOWN)
		State.DOWN:
			_slide(_last)
			_lean(LIE)
			if _clock >= DOWN_TIME:
				_next(State.RISING)
		State.RISING:
			_slide(_last)
			var up := clampf(_clock / RISE_TIME, 0.0, 1.0)
			_lean(LIE * (1.0 - up * up * (3.0 - 2.0 * up)))
			if up >= 1.0:
				state = State.FREE
		State.FLYING:
			_slide(_from.lerp(_to, t) + Vector3.UP * _arc * 4.0 * t * (1.0 - t))
			_lean(LIE * 0.5 * sin(t * PI))
			if t >= 1.0:
				var health := Health.of(_target)
				if health != null:
					health.hurt(_land_damage, _land_what)
				show_hit(_ground() + Vector3.UP * 4.0, true)
				_from = _ground()
				_last = _from
				_to = _floor(_from + _away * 6.0)
				_arc = 1.5
				_time = FALL_TIME * 0.6
				_clock = 0.0
				state = State.FALLING
				# Al caer de un vuelo ya está casi tirada.
				_lean(LIE * 0.5)


func _next(next: State) -> void:
	state = next
	_clock = 0.0
	_from = _ground()
	_last = _from


## LA LLEVA a `point` (el piso debajo de sus pies) por su motor, con choque contra lo fijo: vuelve a donde estaba
## (deshace lo que caminó en este paso) y se corre desde ahí.
func _slide(point: Vector3) -> void:
	var mover := _body.mover
	# De costado, por su motor, con choque contra lo fijo; la altura, la del camino (el saltito, el vuelo).
	mover.global_position = Vector3(_last.x, maxf(_last.y, point.y), _last.z)
	mover.move_and_collide(Vector3(point.x - _last.x, 0.0, point.z - _last.z))
	_last = Vector3(mover.global_position.x, point.y, mover.global_position.z)
	_body.put(Transform3D(Basis(Vector3.UP, _yaw), _last))



## LA INCLINA `degrees` para el lado de `_away` (cae de espaldas al golpe), sobre el piso de sus pies: ENTERA, la caja
## y las piezas sueltas de las piernas (`top_level`: la pelvis, cada pierna, los pies con choque), que su paso pone
## aparte en el mundo. *Antes se inclinaba sólo la caja: el torso se salía de las piernas, que quedaban paradas.*
func _lean(degrees: float) -> void:
	var axis := Vector3.UP.cross(_away).normalized()
	if axis == Vector3.ZERO:
		return
	var pivot := _body.mover.global_position
	var tilt := Transform3D(Basis(axis, deg_to_rad(degrees)), Vector3.ZERO)
	var turn := Transform3D(Basis(), pivot) * tilt * Transform3D(Basis(), -pivot)
	_body.global_transform = turn * _body.global_transform
	# Las piernas (la pelvis, cada pierna, los pies con choque): las pone su paso desde el piso. Los brazos no: se
	# ponen solos desde la caja, ya inclinada.
	for piece: Node3D in _body.find_children("*", "Node3D", true, false):
		if piece.top_level and (piece is MechLeg or piece is StompFeet or piece.get_parent() is BodyLegs):
			piece.global_transform = turn * piece.global_transform


## El piso debajo de `point` (lo fijo); si no hay, el mismo punto.
func _floor(point: Vector3) -> Vector3:
	var from := point + Vector3.UP * 2.0
	var ray := PhysicsRayQueryParameters3D.create(from, point + Vector3.DOWN * 80.0, PhysicsLayers.FIXED)
	# Sin sus propias piezas (la caja, los pies con choque).
	var own: Array[RID] = []
	for piece: CollisionObject3D in _target.find_children("*", "CollisionObject3D", true, false):
		own.append(piece.get_rid())
	if _target is CollisionObject3D:
		own.append((_target as CollisionObject3D).get_rid())
	ray.exclude = own
	var hit := _target.get_world_3d().direct_space_state.intersect_ray(ray)
	return hit["position"] if not hit.is_empty() else point


func _ground() -> Vector3:
	return _body.mover.global_position if _kinematic() else _target.global_position


func _kinematic() -> bool:
	return _body != null and _body.mover != null


## SE PONE BLANCA (o vuelve): el material encima de todas sus mallas (las que no tenían otro).
func _paint(on: bool) -> void:
	if not on:
		for mesh in _painted:
			if is_instance_valid(mesh) and mesh.material_overlay == _white:
				mesh.material_overlay = null
		_painted.clear()
		return
	_white.albedo_color.a = 0.85
	if not _painted.is_empty():
		return
	for mesh: MeshInstance3D in _target.find_children("*", "MeshInstance3D", true, false):
		if mesh.material_overlay == null and mesh.visible:
			mesh.material_overlay = _white
			_painted.append(mesh)


## CHISPAS en `at`: cuadraditos blancos y naranjas que saltan y caen (más, si es fuerte).
func _sparks(at: Vector3, heavy: bool) -> void:
	var world := _target.get_parent()
	if world == null:
		return
	var sparks := CPUParticles3D.new()
	sparks.name = "Chispas"
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * (0.9 if heavy else 0.6)
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.vertex_color_use_as_albedo = true
	cube.material = paint
	sparks.mesh = cube
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 60 if heavy else 35
	sparks.lifetime = 0.7
	sparks.direction = Vector3.UP
	sparks.spread = 180.0
	sparks.initial_velocity_min = 14.0
	sparks.initial_velocity_max = 34.0 if heavy else 26.0
	sparks.gravity = Vector3(0.0, -40.0, 0.0)
	sparks.scale_amount_min = 0.6
	sparks.scale_amount_max = 1.4
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 0.9))
	ramp.set_color(1, Color(1.0, 0.45, 0.1))
	sparks.color_ramp = ramp
	world.add_child(sparks)
	sparks.global_position = at
	sparks.emitting = true
	world.get_tree().create_timer(1.5).timeout.connect(sparks.queue_free)
