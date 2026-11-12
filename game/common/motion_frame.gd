class_name MotionFrame
extends Node3D

## EL MARCO: lo que se mueve y lleva cosas adentro —la nave; mañana un auto o un ascensor—. Lo pidió el dios del juego
## (03/11/2026): «que el personaje tenga claramente una flag que diga si se está moviendo en un espacio global o local a
## un área»; «no haya dos sistemas separados». Cada cuerpo que puede ir adentro de algo tiene UN marco: ninguno (el
## mundo, global) o éste (local). *Hasta el 03/11/2026 la idea estaba en siete lugares, cada uno a su manera: la silla,
## el parado de exhibición, el piso que se mueve, el meta de la altura del piso, la bodega, el freno del agarre y un piso
## invisible para los ragdolls; y la aceleración de la nave se medía en tres.*
##
## LAS REGLAS, UNA SOLA VEZ:
##   · QUIÉN ESTÁ ADENTRO lo dice EL VOLUMEN (`add_volume`): la cabina, y la rampa mientras está abierta. Lo decide UN
##     punto del cuerpo (el centro de la cápsula, la pelvis del ragdoll) con `MARGIN` de histéresis: para entrar hay que
##     pasar ese tanto adentro, para salir ese tanto afuera (`around`). Así, parado en el umbral no cambia a cada paso.
##     Lo corre sólo quien simula: un proxy toma el marco que le manda su dueño por la red (`id`).
##   · LA FÍSICA SIGUE EN EL MUNDO. En cada paso, después de que la nave se movió y antes del solver, el marco le suma a
##     cada miembro lo que cambió la velocidad de la nave en su punto, menos lo que el miembro "siente" (`felt`): el
##     jugador no siente nada (se inclina, ver CharacterRigidBody3D); el ragdoll y las cajas, la perilla del F3
##     (`inertia_felt`). Si la nave salta de golpe (reaparece), los lleva con ella. Entrar o salir no toca la velocidad
##     —ya es del mundo—: sólo cambia contra qué se mide caminar, frenar, la red y el agarre.
##   · ADENTRO SE CHOCA SÓLO CON LO DEL MARCO: su SOMBRA (`cast_shadow`: una copia de las formas de choque de la nave
##     que el motor de física mueve sabiendo su velocidad) y los otros que van adentro, en `LAYER`. Lo de afuera —la
##     calle, el casco movido a mano en las maquetas— no se ve. Es lo que hacía el ente con su capa de viajar,
##     generalizado. *Medido el 03/11/2026: un casco cinemático movido a mano deja que lo de encima se deslice de a poco,
##     y sus piezas fijas no llevan nada; la sombra sincronizada sí.*
##   · LOS CHOQUES DE LA NAVE se avisan una vez (`crash` → `crashed`); cada miembro decide qué le hacen.
##
## Uso: un MotionFrame colgado del cuerpo de lo que se mueve (ver ShipKits.build), con sus volúmenes, su piso y su
## sombra. Quien va adentro: `MotionFrame.around(punto, actual)` para saber en cuál está, `join`/`leave` al cambiar.

const GROUP := &"motion_frames"
## La histéresis del volumen (m): ver QUIÉN ESTÁ ADENTRO.
const MARGIN := 0.2
## Un movimiento de más de esto en un paso es un salto (una reaparición), no velocidad (m).
const JUMP_M := 3.0
## La capa de lo de adentro (la 21, la del viejo piso de la cabina): la sombra y los miembros sólidos.
const LAYER := 1 << 20
## EL RAGDOLL DE EXHIBICIÓN: en su capa, que no mira nadie (ni lo agarran ni lo empujan), y mirando lo del marco.
const EXHIBIT_RAGDOLL_LAYER := 1 << 21
const EXHIBIT_RAGDOLL_MASK := LAYER
## `felt` de quien siente lo que diga la perilla, en vivo.
const FELT_KNOB := -1.0
## La aceleración que se lee (la inclinación, las cajas) se sigue suave (1/s) y con tope (m/s²): la del marco sale de
## diferencias y tiembla; los golpes no van por acá sino por `crashed`.
const ACCEL_FOLLOW := 12.0
const MAX_ACCEL := 60.0

## LA PERILLA DE INERCIA, de 0 a 1, para todos: cuánto de lo que acelera la nave se siente (inclina torsos, desliza
## ragdolls y cajas). La elige el dios del juego en el F3 de la nave (ShipFlatPanel), que la guarda (ver ShipKits).
static var inertia_felt := 1.0

## La altura del piso, en el marco (la de ShipGrid.floor_y en la nave).
var floor_height := 0.0

## UN CHOQUE de lo que se mueve: `dv`, lo que perdió de velocidad (m/s, ejes del mundo; hacia adelante, se van para
## adelante). Lo emite `crash`.
signal crashed(dv: Vector3)

var _volumes: Array = []
var _members := {}
var _applied := {}
var _layers := {}
var _loose := {}
## Lo que perdió de golpe en los choques avisados desde el último paso (ver `crash`).
var _crash_dv := Vector3.ZERO
static var _frame_of := {}

var _prev := Transform3D()
var _velocity := Vector3.ZERO
var _spin := Vector3.ZERO
var _accel := Vector3.ZERO
var _spin_accel := Vector3.ZERO
var _steps := 0
var _shadow: AnimatableBody3D = null
## La sombra de los escalones: lo que adentro ven sólo los pies (ver `cast_shadow`).
var _shadow_feet: AnimatableBody3D = null
var _shadow_sources: Array = []
var _shadow_wait := 0
## Cada cuántos pasos se mira si alguna forma de la nave se movió (ver `_place_shadow`): 60 veces por segundo.
const SHADOW_CHECK_STEPS := 4


func _init() -> void:
	name = "Marco"
	add_to_group(GROUP)
	process_physics_priority = 1000


func _ready() -> void:
	_prev = global_transform


## UN VOLUMEN del marco, en sus coordenadas; con `active`, cuenta sólo mientras devuelva true (la rampa abierta).
func add_volume(box: AABB, active := Callable()) -> void:
	_volumes.append([box, active])


## Si `point` (mundo) está adentro de algún volumen, agrandado `margin` (achicado, si es negativo).
func contains(point: Vector3, margin := 0.0) -> bool:
	var local := global_transform.affine_inverse() * point
	for volume: Array in _volumes:
		var active: Callable = volume[1]
		if active.is_valid() and not bool(active.call()):
			continue
		if (volume[0] as AABB).grow(margin).has_point(local):
			return true
	return false


## EN QUÉ MARCO ESTÁ `point`, si hoy estaba en `current` (o en ninguno, o en uno que ya no existe): con la histéresis de
## QUIÉN ESTÁ ADENTRO. Nunca uno que se está yendo (ver `is_leaving`).
static func around(point: Vector3, current: Object) -> MotionFrame:
	var here := current as MotionFrame if is_instance_valid(current) else null
	if here != null and not here.is_leaving() and here.contains(point, MARGIN):
		return here
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(GROUP):
		var frame := node as MotionFrame
		if frame != null and frame != here and not frame.is_leaving() and frame.contains(point, -MARGIN):
			return frame
	return null


## SI SE ESTÁ YENDO: él o algo de arriba suyo se va a borrar al terminar el cuadro. *Al cambiar la nave en el F3, la
## nueva se arma en el mismo cuadro y en el mismo lugar que la vieja, que todavía no se borró: los que se paraban en la
## nueva elegían el marco de la vieja y quedaban apuntando a algo borrado (03/11/2026, el toggle de los parados).*
func is_leaving() -> bool:
	var up: Node = self
	while up != null:
		if up.is_queued_for_deletion():
			return true
		up = up.get_parent()
	return false


## El marco del que `body` es miembro, o null (global).
static func frame_of(body: Object) -> MotionFrame:
	if body == null:
		return null
	var frame: Variant = _frame_of.get(body.get_instance_id())
	return frame as MotionFrame if is_instance_valid(frame) else null


## EL NOMBRE PARA LA RED: el mismo en todas las máquinas (el camino del nodo); 0 es ninguno.
func id() -> int:
	return str(get_path()).hash()


## El marco de id `frame_id` en esta máquina (ver `id`), o null.
static func by_id(frame_id: int) -> MotionFrame:
	if frame_id == 0:
		return null
	var tree := Engine.get_main_loop() as SceneTree
	for node in tree.get_nodes_in_group(GROUP) if tree != null else []:
		if node is MotionFrame and (node as MotionFrame).id() == frame_id:
			return node
	return null


# ── CÓMO SE MUEVE ─────────────────────────────────────────────────────────────────────────────────────────────────

## La velocidad del marco en `point` (mundo).
func velocity_at(point: Vector3) -> Vector3:
	return _velocity + _spin.cross(point - global_position)


## Su giro (rad/s, ejes del mundo).
func spin() -> Vector3:
	return _spin


## SU ACELERACIÓN EN `point`, suave y con tope (ver ACCEL_FOLLOW), CON EL GIRO ADENTRO: acelerar, frenar y la curva, que
## tira para afuera. Lo que se siente es esto al revés.
func acceleration_at(point: Vector3) -> Vector3:
	var r := point - global_position
	return _accel + _spin_accel.cross(r) + _spin.cross(_spin.cross(r))


# ── LOS DE ADENTRO ────────────────────────────────────────────────────────────────────────────────────────────────

## `body` PASA A IR ADENTRO: lo lleva el marco y siente `felt` (0 nada, 1 todo; `FELT_KNOB`, la perilla). Sólido
## (`solid`), los otros de adentro chocan con él; si no (un ragdoll), él choca con lo del marco pero nadie con él.
## Deja de chocar con lo de afuera. Si estaba en otro marco, sale de ése. Con `keeps_momentum` (lo suelto: un ragdoll,
## una caja) EN UN CHOQUE CONSERVA SU VELOCIDAD —la nave se frena y él no, y se va solo hacia la trompa—; sin eso (una
## cápsula, que no se suelta), lo sigue llevando entero y el choque le llega como empujón (ver `crashed`).
func join(body: CollisionObject3D, felt := 0.0, solid := true, keeps_momentum := false) -> void:
	var before := frame_of(body)
	if keeps_momentum:
		_loose[body] = true
	else:
		_loose.erase(body)
	if before == self:
		_members[body] = felt
		return
	if before != null:
		before.leave(body)
	_members[body] = felt
	_applied[body] = Vector3.ZERO
	_layers[body] = [body.collision_layer, body.collision_mask]
	_frame_of[body.get_instance_id()] = self
	if solid:
		body.collision_layer |= LAYER
	body.collision_mask = LAYER


## `body` SALE: vuelve a chocar con lo de afuera, y deja de llevarlo.
func leave(body: CollisionObject3D) -> void:
	if not _members.has(body):
		return
	if is_instance_valid(body):
		var layers: Array = _layers[body]
		body.collision_layer = layers[0]
		body.collision_mask = layers[1]
		_frame_of.erase(body.get_instance_id())
	_members.erase(body)
	_applied.erase(body)
	_layers.erase(body)
	_loose.erase(body)


## Lo que el marco le sumó a la velocidad de `body` en el último paso (para que no se lea como un golpe).
func applied_dv(body: Object) -> Vector3:
	return _applied.get(body, Vector3.ZERO)


## UN CHOQUE (ver `crashed`): `dv`, lo que perdió de velocidad lo que se mueve de golpe (m/s, mundo). UN CHOQUE ES SÓLO
## UN EMPUJÓN (el dios del juego, 03/11/2026): ese salto no entra en la aceleración (no inclina por inercia: ya inclina
## como golpe) ni se les resta a los sueltos (`keeps_momentum`), que siguen con lo que traían. *Hasta el 03/11/2026 se
## contaba dos veces: como golpe y como una aceleración enorme, recortada y suavizada.*
func crash(dv: Vector3) -> void:
	_crash_dv += dv
	crashed.emit(dv)


# ── LA SOMBRA ─────────────────────────────────────────────────────────────────────────────────────────────────────

## LA SOMBRA DE `root`: un cuerpo que el motor de física mueve con el marco, sabiendo su velocidad, con una copia de
## cada forma de choque sólida de `root` (lo que chocan los jugadores: capa 1), en `LAYER`. Cada paso copia otra vez
## dónde está cada forma, así las compuertas y las sillas que giran también valen. Se vuelve a llamar si se agregan
## piezas. Lo que cuelga de algo de `leave_out` no entra (las sillas, ver ShipKits.chairs_collide): lo de adentro las
## atraviesa, pero siguen estando para el rayo con que se apunta.
## LAS ESCALERAS (ver Stairs, 13/11/2026): la RAMPA de la cápsula (capa Rampa) entra en la sombra de siempre, que es la
## que ven la cápsula y su rayo de piso; los ESCALONES (capa Escalones) van a una segunda sombra en la capa Escalones,
## que ven sólo los rayos de los pies y el ragdoll. Los pies igual ven la de siempre, pero pisan los escalones antes:
## la rampa pasa por debajo, por sus rincones de abajo.
func cast_shadow(root: Node3D, leave_out: Array = []) -> void:
	for old: AnimatableBody3D in [_shadow, _shadow_feet]:
		if is_instance_valid(old):
			old.queue_free()
	_shadow_sources.clear()
	_shadow = _shadow_body("sombra", LAYER)
	_shadow_feet = _shadow_body("sombra de los escalones", PhysicsLayers.FEET)
	var seen := 1 | PhysicsLayers.RAMP | PhysicsLayers.FEET
	for node in root.find_children("*", "CollisionShape3D", true, false):
		var source := node as CollisionShape3D
		var owner_body := source.get_parent() as PhysicsBody3D
		if source.shape == null or owner_body == null or owner_body == _shadow or owner_body == _shadow_feet 				or not owner_body.collision_layer & seen:
			continue
		# Lo suelto que va adentro (una caja, un cuerpo) no es la nave: se mueve solo, y es miembro.
		if _members.has(owner_body) or owner_body != root and owner_body is RigidBody3D and not owner_body.freeze:
			continue
		if leave_out.any(func(out: Variant) -> bool: return is_instance_valid(out) and (out as Node).is_ancestor_of(source)):
			continue
		var copy := CollisionShape3D.new()
		copy.shape = source.shape
		var only_feet := owner_body.collision_layer & PhysicsLayers.FEET and not owner_body.collision_layer & (1 | PhysicsLayers.RAMP)
		(_shadow_feet if only_feet else _shadow).add_child(copy)
		_shadow_sources.append([source, copy])
	_place_shadow(true)


func _shadow_body(label: String, layer: int) -> AnimatableBody3D:
	var body := AnimatableBody3D.new()
	body.name = label
	body.sync_to_physics = true
	body.top_level = true
	body.collision_layer = layer
	body.collision_mask = 0
	add_child(body)
	body.global_transform = global_transform
	return body


## LA SOMBRA SIGUE AL MARCO en cada paso (el cuerpo entero, que el motor mueve sabiendo su velocidad), y sus formas a
## las de la nave CADA `SHADOW_CHECK_STEPS` PASOS Y SÓLO LAS QUE SE MOVIERON (una compuerta, una silla que gira): a cada
## forma que se le toca el lugar, el motor rearma la sombra entera. *El 03/11/2026 se reubicaban las 218 en cada paso:
## el paso de física pasó de 1,8 a 15 ms y la maqueta se arrastraba (lo vio el dios del juego).*
func _place_shadow(all := false) -> void:
	_shadow.global_transform = global_transform
	_shadow_feet.global_transform = global_transform
	_shadow_wait -= 1
	if not all and _shadow_wait > 0:
		return
	_shadow_wait = SHADOW_CHECK_STEPS
	var inverse := global_transform.affine_inverse()
	for pair: Array in _shadow_sources:
		var source: CollisionShape3D = pair[0]
		var copy: CollisionShape3D = pair[1]
		if not is_instance_valid(source):
			if not copy.disabled:
				copy.disabled = true
			continue
		var place := inverse * source.global_transform
		if all or not place.is_equal_approx(copy.transform):
			copy.transform = place
		if copy.disabled != source.disabled:
			copy.disabled = source.disabled


# ── CADA PASO ─────────────────────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return
	var now := global_transform
	# EL PRIMER PASO SÓLO MIRA DÓNDE ESTÁ: lo que se mueve suele armarse en un lugar y llevarse a otro (la nave se arma
	# en el origen, ver ShipKits.build), y ese traslado no es un salto. *Hasta el 03/11/2026 sí: se llevaba 64 m a los
	# que ya estaban adentro, y los dejaba afuera.*
	if _steps == 0:
		_prev = now
		_steps = 1
		return
	var moved := now.origin - _prev.origin
	var jump := moved.length() > JUMP_M
	var velocity_before := _velocity
	var spin_before := _spin
	if jump:
		_carry_jump(now * _prev.affine_inverse())
	else:
		_velocity = moved / delta
		var turn := (now.basis.orthonormalized() * _prev.basis.orthonormalized().inverse()).get_rotation_quaternion()
		# El giro del paso: con giros chicos (uno de 240 por segundo) `get_axis` devuelve el eje sin normalizar —medido, el
		# giro salía 500 veces más chico—; con las partes del cuaternión, 2·(x, y, z) ≈ eje·ángulo, sin eso.
		_spin = Vector3(turn.x, turn.y, turn.z) * (2.0 * signf(turn.w)) / delta
		if _steps > 1:
			var follow := 1.0 - exp(-ACCEL_FOLLOW * delta)
			# Sin el salto del choque (ver `crash`): como si ya hubiera tenido la velocidad de después.
			var steady_before := velocity_before - _crash_dv
			_accel = _accel.lerp(((_velocity - steady_before) / delta).limit_length(MAX_ACCEL), follow)
			_spin_accel = _spin_accel.lerp((_spin - spin_before) / delta, follow)
		if _steps > 0:
			_carry(velocity_before, spin_before, _prev, delta)
	_crash_dv = Vector3.ZERO
	_steps += 1
	_prev = now
	if is_instance_valid(_shadow):
		_place_shadow()


## LOS LLEVA: a cada miembro, lo que cambió la velocidad de la nave en su punto (y su giro), menos lo que siente.
## Y EL FRENO DEL AIRE, CONTRA EL MARCO: el `linear_damp` / `angular_damp` de un cuerpo lo frena contra el mundo, pero el
## aire de la cabina viaja con ella; se le devuelve lo que el freno le va a sacar de la velocidad del marco. *Hasta el
## 03/11/2026 no: los huesos del ragdoll (freno 0,5) se atrasaban contra la nave en proporción a su velocidad —a 23 m/s,
## 11 m/s² hacia la cola—, y caían para atrás en vez de salir hacia el golpe (medido).*
func _carry(velocity_before: Vector3, spin_before: Vector3, before: Transform3D, delta: float) -> void:
	for body: Variant in _members.keys():
		if not is_instance_valid(body):
			_members.erase(body)
			_applied.erase(body)
			_layers.erase(body)
			_loose.erase(body)
			continue
		var rigid := body as RigidBody3D
		if rigid == null or rigid.freeze:
			_applied[body] = Vector3.ZERO
			continue
		var felt: float = _members[body]
		if felt < 0.0:
			felt = inertia_felt
		var carried := 1.0 - clampf(felt, 0.0, 1.0)
		var point := rigid.global_position
		var then := before * (global_transform.affine_inverse() * point)
		var dv := (velocity_at(point) - (velocity_before + spin_before.cross(then - before.origin))) * carried
		# LO SUELTO CONSERVA LO QUE TRAÍA EN UN CHOQUE (ver `crash`): no se le resta lo que perdió la nave.
		if _loose.has(body):
			dv += _crash_dv * carried
		dv += velocity_at(point) * _undamp(rigid.linear_damp, delta)
		rigid.linear_velocity += dv
		rigid.angular_velocity += (_spin - spin_before) * carried + _spin * _undamp(rigid.angular_damp, delta)
		_applied[body] = dv


## UN SALTO (una reaparición): los de adentro van con la nave, con su velocidad girada igual.
func _carry_jump(step: Transform3D) -> void:
	for body: Variant in _members.keys():
		# Lo borrado se va, como en `_carry` (en la meca, 11/11/2026: el ente que se borra al abrir la sesión de red).
		if not is_instance_valid(body):
			_members.erase(body)
			_applied.erase(body)
			_layers.erase(body)
			_loose.erase(body)
			continue
		var rigid := body as RigidBody3D
		if rigid == null:
			continue
		rigid.global_transform = step * rigid.global_transform
		rigid.linear_velocity = step.basis * rigid.linear_velocity
		_applied[body] = Vector3.ZERO


## Lo que hay que sumarle a una velocidad para que, después del freno `damp` de un paso `delta`, quede la misma.
static func _undamp(damp: float, delta: float) -> float:
	var kept := 1.0 - damp * delta
	return (1.0 - kept) / kept if damp > 0.0 and kept > 0.0 else 0.0
