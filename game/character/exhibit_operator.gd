class_name ExhibitOperator
extends Node

## ── UN PERSONAJE DE EXHIBICIÓN QUE USA CONTROLES COMO UN JUGADOR (02/11/2026; continuo desde el 03/11/2026) ───────────
## Lo pidió el dios del juego: «quisiera simular todo. El personaje viendo un objeto, moviéndolo y volviendo el volante»;
## los controles no se mueven solos. Quien maneja la simulación (el piloto automático de la nave, ver ShipAutoFlight) no
## escribe en los controles: le PIDE a este personaje un valor por control (`want`), y él hace lo que haría un jugador,
## escribiendo la intención común (ver CharacterIntent) —adónde mira, qué agarra—, la misma a la que el jugador llega con
## su rayo y su clic. El guion no emula teclas ni clics.
##
## TODO ES CONTINUO, sin pasos ni esperas (el dios del juego, 03/11/2026): LA ATENCIÓN va hacia lo que importa a un ritmo
## de giro natural (`LOOK_RATE`), y LA MANO SALE cuando lo que va a agarrar ya está a la vista (`IN_VIEW`), no cuando la
## mirada llegó exacto; con la mano puesta, lo mueve hacia lo pedido a ritmo de persona (`apply_sync_state`, como la
## red) y, llegado, lo suelta. Agarrar el volante y levantar la vista al horizonte es una sola acción suave.
##
## EL QUE MANEJA (el volante y los mandos de dos ejes, ver `_drives`) no lo suelta: con la mano puesta mira adelante, y
## con el volante, para el lado al que dobla —el rumbo es el frente de la silla más lo que está doblado por
## `DRIVE_LOOK`, el cabeceo el horizonte— (el dios del juego: «mirar izquierda, mirar derecha… y hacia el horizonte»).
## Sólo lo suelta para ir a otro control que esté lejos de lo pedido, y vuelve; sin nada que corregir, descansa con las
## manos en él. Una cosa a la vez: dos controles distintos no se mueven juntos (el dios del juego: «no tengo problema
## porque siempre tenemos el safeguard de reiniciar la simulación»).

## Qué tan rápido gira la atención (rad/s): la de una persona, no la de un servo.
const LOOK_RATE := 2.5
## Cuánto puede faltarle a la mirada para que la mano ya salga (rad): a la vista, no exacto.
const IN_VIEW := 0.5
## Cuánto de la mano tiene que haber llegado para empezar a mover (el peso del brazo, ver ArmsController.hand_on).
const HANDS_ON := 0.85
## A qué ritmo mueve lo que agarró, en unidades de su valor por segundo: los que giran (rad), y los demás.
const TURN_RATE := 6.0
const MOVE_RATE := 3.0
## Qué diferencia entre lo pedido y lo que marca ya vale la pena ir a corregir; y, con el volante en la mano, cuánta lejos
## tiene que estar otro control para soltarlo e ir.
const WORTH := 0.03
const WORTH_LEAVING_THE_WHEEL := 0.15
## Con el volante a fondo, cuánto mira para ese lado (rad).
const DRIVE_LOOK := 0.6

## *Hasta el 06/11/2026 tenía una PERICIA —un tiempo de reacción al azar, un error al calcular los saltos, al atajar y
## al girar con lo que lleva—: el dios del juego la sacó («borra todo el código de eso de habilidad… así simplificamos»).
## Decide cada cuadro.*
var _rng := RandomNumberGenerator.new()


## El azar de este personaje, desde `value`.
func seed_with(value: int) -> void:
	_rng.seed = value


var bi: BoneInstantiator
## Lo pedido por control: ControllableInteractable → valor (float, o Vector2 en los de dos ejes).
var _wanted := {}
## El control que está usando —yendo a él, con la mano o moviéndolo—, o null.
var _control: ControllableInteractable = null
## Lo que mira cuando no usa nada (`look_at`), o null: adelante.
var _gaze: Node3D = null


## EL DE `who`, creado la primera vez. Lo maneja un guion (ver CharacterKind.Driver.SCRIPT): si no tenía quien lo
## manejara, desde ahora mira con la cabeza lo que este guion le pida.
static func of(who: BoneInstantiator) -> ExhibitOperator:
	for child in who.get_children():
		if child is ExhibitOperator:
			return child as ExhibitOperator
	var op := ExhibitOperator.new()
	op.name = "Operador"
	op.bi = who
	who.add_child(op)
	if not who.kind.looks():
		who.kind.driver = CharacterKind.Driver.SCRIPT
		if is_instance_valid(who.procedural_animator):
			who.refresh_camera_animations()
	return op


## ── LOS VERBOS DEL GUION ───────────────────────────────────────────────────────────────────────────────────────────

## QUE MIRE `target` (un nodo; null, adelante) cuando no está usando nada: el cuerpo entero, como un jugador.
func look_at(target: Node3D) -> void:
	_gaze = target


## QUE USE `thing`: una silla, se sienta (null o la misma, se para); un control, lo va a buscar y lo agarra sin moverlo
## (para moverlo, `want`).
func interact(thing: Node) -> void:
	if thing is SeatInteractable or thing == null:
		bi.intent.seat = null if thing == null or thing == bi.intent.seat else thing
	elif thing is ControllableInteractable:
		want(thing as ControllableInteractable, (thing as ControllableInteractable).get_sync_state())


## QUE VAYA HASTA `point` (mundo), caminando o, con `sprint`, corriendo: mira hacia allá y avanza, con la velocidad y la
## aceleración de su cuerpo como cualquiera, y se para al llegar (a `ARRIVED`). Sirve para cualquiera que se simule —un
## `CharacterKind.npc()` también: el guion pasa a manejarlo—. `stop_moving` lo para antes.
##
## CÓMO FRENA PARA PARARSE AHÍ (06/11/2026): soltando todo, o con `against`, apretando para atrás (ver FRENAR APRETANDO
## PARA ATRÁS); en los dos suelta —o aprieta— a la distancia que le hace falta. IR ES IR A UN LUGAR: lo que no tiene meta
## —empujar en una dirección hasta que algo lo pare, como correr contra una pared— son teclas (ver `press`).
func move_towards(point: Vector3, sprint := false, against := false) -> void:
	_path = PackedVector3Array()
	_walk_to = point
	_braking = false
	_walk_sprint = sprint
	_brake_against = against
	_arrive = true


## QUE SE AGACHE (`on`) o se pare: aprieta agacharse como el jugador (ver CharacterIntent.crouch); el cuerpo hace el resto.
func crouch(on: bool) -> void:
	if is_instance_valid(bi):
		bi.intent.crouch = on


## QUE NO PASE DE `speed` (m/s; INF, sin tope): dos que llevan algo juntos van al mismo paso, aunque uno vaya de espaldas.
func pace(speed: float) -> void:
	bi.char_rigidbody.speed_cap = speed


func stop_moving() -> void:
	_braking = false
	_brake_against = false
	_walk_to = Vector3.INF
	_path = PackedVector3Array()
	bi.intent.move = Vector2.ZERO
	bi.intent.sprint = false


## Cuándo llegó (m, en el plano).
const ARRIVED := 0.3
var _walk_to := Vector3.INF
var _walk_sprint := false
## Si al llegar a `_walk_to` se para (un punto) o sigue (el punto que persigue sobre un camino).
var _arrive := true


## QUE SIGA EL CAMINO `points` (puntos del mundo en orden, o una Curve3D en el mundo), caminando o con `sprint`: mira y va
## hacia un punto `LOOK_AHEAD` más adelante sobre el camino —persecución pura—, y al final se para. Cuánto se ciñe lo
## decide su cuerpo: su aceleración, su frenada y el giro de su mirada a su ritmo (`LOOK_RATE`), como un jugador.
##
## CORRER EN LAS RECTAS (`on_straights`, 04/11/2026, el dios del juego: «que el personaje pueda sprintear o dejar de
## sprintear, así esquiva con más efectividad»): corre mientras lo que el camino dobla de acá a lo que tarda en frenar
## (más `BEND_LOOK`) no pase de `SPRINT_BEND`; si dobla más, camina, como un jugador que suelta el sprint antes de la curva.
func follow_path(points: Variant, sprint := false, on_straights := false, ahead := LOOK_AHEAD) -> void:
	var pts: PackedVector3Array = (points as Curve3D).get_baked_points() if points is Curve3D else points
	stop_moving()
	_sprint_on_straights = on_straights
	if pts.size() == 1:
		move_towards(pts[0], sprint)
		return
	_path = pts
	_path_at = 0
	_walk_sprint = sprint
	_look_ahead = ahead


## Cuánto mira adelante en este camino (`ahead` de `follow_path`): sobre un caño, poco, para no cortar las esquinas.
var _look_ahead := LOOK_AHEAD


## Cuánto puede doblar adelante el camino y seguir corriendo (rad), y cuánto más allá de lo que tarda en frenar mira (m).
const SPRINT_BEND := 0.6
const BEND_LOOK := 2.0
var _sprint_on_straights := false


## SI SE ESTÁ MOVIENDO POR SU GUION: va a un punto o sigue un camino.
func moving() -> bool:
	return not _path.is_empty() or _walk_to.is_finite()


## SI YA LLEVA LO QUE SE LE PIDIÓ (ver `carry`): lo levantó y ya está parado con él.
func carrying() -> bool:
	return _holds() and _rise_t < 0.0


## QUE ESQUIVE `things` ([nodo, radio], un personaje o cualquier cosa) yendo adonde va (`move_towards`), como un jugador
## que ve lo que tiene adelante: lo más cercano que le quede en el camino dentro de `AVOID_LOOK` m lo rodea por el lado
## en que ya está, a su radio más el propio más `AVOID_GAP`. Con poca pericia lo ve tarde: decide cada tanto (ver LA
## PERICIA). Vacío, no esquiva.
func avoid(things: Array, lane := Transform3D(), lane_half := INF) -> void:
	_avoid = things
	_lane = lane
	_lane_half = lane_half


## UN PASILLO (opcional): sus ejes (x de costado) y su medio ancho. Al rodear algo, el lado que deja el desvío dentro.
var _lane := Transform3D()
var _lane_half := INF


const AVOID_LOOK := 5.0
## Corriendo, mira lo que tardaría en llegar en tantos segundos (para que le dé el tiempo de hacerse a un lado).
const AVOID_AHEAD_S := 1.4
const AVOID_GAP := 0.5
const OWN_RADIUS := 0.35
var _avoid: Array = []
## Hacia dónde va este rato: `_walk_to`, o el desvío para rodear algo.
var _steer_to := Vector3.INF


## El desvío para ir a `to` sin chocar con lo de `_avoid`, o `to`.
func _detour(to: Vector3) -> Vector3:
	var pos := _flat(bi.char_rigidbody.global_position)
	var toward := _flat(to) - pos
	var far := toward.length()
	if far < 0.01:
		return to
	var dir := toward / far
	var left := Vector2(-dir.y, dir.x)
	var v := bi.char_rigidbody.get_motion_velocity()
	var best_t := minf(maxf(AVOID_LOOK, Vector2(v.x, v.z).length() * AVOID_AHEAD_S), far)
	var best := Vector2.INF
	var best_r := 0.0
	for each: Array in _avoid:
		var node := each[0] as Node3D
		if not is_instance_valid(node):
			continue
		var at := _flat((node as BoneInstantiator).char_rigidbody.global_position if node is BoneInstantiator
			else node.global_position)
		var rel := at - pos
		var t := rel.dot(dir)
		var room := float(each[1]) + OWN_RADIUS + AVOID_GAP
		if t <= 0.0 or t >= best_t or absf(rel.dot(left)) >= room:
			continue
		best_t = t
		best = at
		best_r = room
	if not best.is_finite():
		return to
	var side := 1.0 if (best - pos).dot(left) < 0.0 else -1.0
	var around := best + left * side * best_r
	# EN UN PASILLO, si por ese lado se sale, por el otro.
	if is_finite(_lane_half):
		var inside := func(p: Vector2) -> bool:
			return absf((_lane.affine_inverse() * Vector3(p.x, 0.0, p.y)).x) <= _lane_half - OWN_RADIUS
		if not inside.call(around):
			around = best - left * side * best_r
	return Vector3(around.x, to.y, around.y)


## ── SORTEAR LO QUE HAY ADELANTE, COMO UN JUGADOR (04/11/2026, el dios del juego: «darle la capacidad al personaje que
## se pueda agachar para hacer traversal y también de saltar») ────────────────────────────────────────────────────
## Con `traverse(true)`, cada vez que decide (ver LA PERICIA), parado en el piso, mira adelante —hacia donde va— con
## rayos, como ojos:
##   · ALGO BAJO ADELANTE —un escalón, una valla—: lo que corta un rayo a `STEP_WALK` m de sus pies. Si su tope queda a
##     menos de su salto (`jump_height` de su arquetipo), lo salta (`jump_at`); si no, es una pared.
##   · UN HUECO: el piso que se termina adelante —para abajo no hay nada a `DROP_OK` de sus pies—: si encuentra el otro
##     lado antes de `GAP_MAX`, salta al medio; si no, se frena en el borde. Lo que baja menos de `DROP_OK`, lo baja
##     caminando.
##   · ALGO A LA ALTURA DE LA CABEZA: un rayo a la altura de su cabeza corta y uno a la de agachado no: se agacha, y se
##     para cuando arriba suyo ya no hay nada.
## Lo que se sube caminando lo decide la cápsula, no esto.
func traverse(on: bool) -> void:
	_traverse = on


## Lo que la cápsula sube caminando, medido el 04/11/2026: el gordo 15 cm, el flaco alto 10, el kid ni 10 (contra un
## escalón más alto se frena y se cae). Más de esto, lo salta: en el juego un escalón nunca se sube caminando, siempre se
## salta (el dios del juego, 04/11/2026).
const STEP_WALK := 0.08
## Las alturas (fracciones de su alto) donde algo lo obliga a agacharse, y la de agachado, que tiene que quedar libre.
const DUCK_RAYS := [0.99, 0.9, 0.8, 0.7, 0.62]
const DUCK_CLEAR := 0.5
const DROP_OK := 1.5
const GAP_MAX := 3.5
const GAP_STEP := 0.2
var _traverse := false
var _ducking := false


func _sense_ahead() -> void:
	var rb := bi.char_rigidbody
	if not _traverse or not rb.is_grounded or _jump_over.is_finite() or not _walk_to.is_finite():
		return
	var space := rb.get_world_3d().direct_space_state
	var pos := rb.global_position
	var feet := _floor_below(space, pos, 3.0)
	if not is_finite(feet):
		return
	var toward := (_steer_to if _steer_to.is_finite() else _walk_to) - pos
	toward.y = 0.0
	if toward.length() < 0.1:
		return
	var dir := toward.normalized()
	var v := rb.get_motion_velocity()
	var speed := Vector2(v.x, v.z).length()
	var look := _look_need(speed)
	var s := bi.skel_sizes_util
	var tall := s.leg_height + s.torso_height + s.head_height
	# AGACHARSE: algo entre la altura de agachado y la de su cabeza (`DUCK_RAYS`, fracciones de su alto; uno solo a la
	# altura de la cabeza pasaba por arriba de una viga que le pegaba en la frente) y nada más abajo.
	var duck_look := 0.6 + speed * 0.35
	var up_high := false
	for share: float in DUCK_RAYS:
		var at := Vector3(pos.x, feet + tall * share, pos.z)
		if _ray(space, at, at + dir * duck_look):
			up_high = true
			break
	var low := Vector3(pos.x, feet + tall * DUCK_CLEAR, pos.z)
	if up_high and not _ray(space, low, low + dir * duck_look):
		if not _ducking:
			_ducking = true
			crouch(true)
	elif _ducking and not up_high and not _ray(space, low, Vector3(pos.x, feet + tall, pos.z)):
		_ducking = false
		crouch(false)
	if _ducking:
		return
	# ALGO BAJO ADELANTE.
	var knee := Vector3(pos.x, feet + STEP_WALK, pos.z)
	var hit := _ray_hit(space, knee, knee + dir * look)
	# LO QUE ESTÁ EN LA LISTA DE ESQUIVAR SE RODEA, NO SE SALTA (05/11/2026, el dios del juego: en «rodear» saltaba lo que
	# rozaba): de eso se ocupa el desvío (ver `avoid`).
	if not hit.is_empty() and _avoids(hit.collider):
		return
	if not hit.is_empty():
		var at: Vector3 = hit.position
		var top := _floor_below(space, Vector3(at.x, feet + 3.0, at.z) + dir * 0.12, 3.5)
		var arch := bi.entity_archetype
		if is_finite(top) and arch != null and top - feet <= arch.jump_height:
			jump_at(Vector3(at.x, feet, at.z))
		return
	# UN HUECO.
	var d := 0.4
	while d <= look:
		var p := pos + dir * d
		var below := _floor_below(space, Vector3(p.x, feet + 0.5, p.z), 0.5 + DROP_OK)
		if not is_finite(below):
			var far := d
			while far <= d + GAP_MAX:
				var q := pos + dir * far
				var other := _floor_below(space, Vector3(q.x, feet + 0.5, q.z), 0.5 + DROP_OK)
				if is_finite(other):
					var middle := pos + dir * ((d + far) * 0.5)
					jump_at(Vector3(middle.x, feet, middle.z))
					return
				far += GAP_STEP
			stop_moving()
			return
		d += GAP_STEP


## HASTA DÓNDE MIRA ADELANTE (m; 05/11/2026): lo que corre mientras carga el salto entero, lo suelta y vuela hasta su
## cima —con un margen por si todavía acelera—, más su cuerpo. *Hasta entonces de 1 a 3,5 m según la velocidad, y a
## veces veía el escalón tarde —medido en «subir y bajar»: a 1,7 m, cuando le hacían falta 2,4— y se lo comía.*
func _look_need(speed: float) -> float:
	var arch := bi.entity_archetype
	if arch == null:
		return 2.0
	var air := sqrt(2.0 * arch.jump_height / 9.8)
	return (speed * 1.25 + 0.5) * (arch.time_to_max_jump + BoneInstantiator.JUMP_RELEASE_S + air) + OWN_RADIUS + 0.3


## Si `thing` (o algo de lo que es parte) está en la lista de esquivar.
func _avoids(thing: Object) -> bool:
	for each: Array in _avoid:
		var node := each[0] as Node
		if is_instance_valid(node) and thing is Node and (node == thing or node.is_ancestor_of(thing as Node)
				or (node is BoneInstantiator and (node as BoneInstantiator).char_rigidbody == thing)):
			return true
	return false


## La altura del piso debajo de `from`, hasta `depth` m; INF si no hay.
func _floor_below(space: PhysicsDirectSpaceState3D, from: Vector3, depth: float) -> float:
	var hit := _ray_hit(space, from, from + Vector3.DOWN * depth)
	return (hit.position as Vector3).y if not hit.is_empty() else INF


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	return not _ray_hit(space, from, to).is_empty()


## Lo que corta de `from` a `to` lo que pisa el mundo, sin él mismo ni lo que lleva, NI LOS PERSONAJES (06/11/2026): a la
## gente la esquiva (ver `avoid`), no la salta ni se agacha por ella. *Hasta entonces la cápsula de un peatón en su camino
## era, para estos rayos, un obstáculo bajo.*
func _ray_hit(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var excludes: Array[RID] = [bi.char_rigidbody.get_rid()]
	for node in bi.get_tree().get_nodes_in_group(CharacterRigidBody3D.CHARACTER_GROUP):
		excludes.append((node as CollisionObject3D).get_rid())
	if is_instance_valid(bi.ragdoll_util):
		for rid in bi.ragdoll_util._ragdoll_rids:
			excludes.append(rid)
	if is_instance_valid(_carried) and _carried.get_parent() is CollisionObject3D:
		excludes.append((_carried.get_parent() as CollisionObject3D).get_rid())
	query.exclude = excludes
	return space.intersect_ray(query)


## Cuánto más adelante sobre el camino mira y va (m).
const LOOK_AHEAD := 2.5
var _path := PackedVector3Array()
var _path_at := 0


## QUE SALTE PARA PASAR LO QUE HAY EN `point` (un obstáculo del mundo), como un jugador: al acercarse, a la distancia
## justa según su velocidad, mantiene el salto para cargarlo (`intent.jump`) y lo suelta para despegar a la mitad de su
## vuelo antes del obstáculo. Quieto, carga entero y salta ahí.
func jump_at(point: Vector3) -> void:
	_jump_over = point
	_jump_held = 0.0


## LAS TECLAS EN EL TIEMPO (05/11/2026, el dios del juego: «un solo sistema para todo lo de locomoción de dummies»): lo
## que una parcela de prueba quiere ver exacto —saltar todos a la vez, doblar en el aire, mirar a los costados con lo que
## lleva— se lo pide como lo haría un jugador apretando teclas: una lista de tramos, cada uno un Dictionary con cuánto
## dura (`s`) y lo que aprieta mientras: `jump`, `move` (como la intención: (0, −1) es la W), `sprint` y `turn` (rad/s
## que gira la mirada). Con `loop`, vuelve a empezar. Mientras
## suena, la mirada y las teclas son suyas; si está levantando algo, espera a tenerlo (y la mirada es del agarre).
## LA ÚNICA EXCEPCIÓN, `launch` (m/s; 05/11/2026, el dios del juego eligió «salida a 4 m/s»): al empezar ese tramo le da
## al cuerpo esa velocidad hacia adelante, la misma para todos —así en caer en loop salen iguales, aunque cada arquetipo
## acelere distinto—. Es una prueba de animación, no de cómo se juega: ningún jugador puede hacerlo. *Hasta entonces eran tres verbos a
## medida —`leap`, `air_turn` y `spin`—, y el salto escribía la velocidad del cuerpo.*
func press(keys: Array, loop := false) -> void:
	stop_moving()
	_keys = keys
	_keys_loop = loop
	_key_i = -1
	_next_key()


var _keys: Array = []
var _keys_loop := false
var _key_i := -1
var _key_left := 0.0
var _key_turn := 0.0


func _next_key() -> void:
	_key_i += 1
	if _key_i >= _keys.size():
		if not _keys_loop or _keys.is_empty():
			_keys = []
			bi.intent.jump = false
			bi.intent.move = Vector2.ZERO
			bi.intent.sprint = false
			return
		_key_i = 0
	var k: Dictionary = _keys[_key_i]
	_key_left = float(k.get("s", 0.0))
	if k.has("launch"):
		var rb := bi.char_rigidbody
		var forward := -rb.global_basis.z.normalized() * float(k["launch"])
		rb._self_dv(Vector3(forward.x, 0.0, forward.z) - Vector3(rb.linear_velocity.x, 0.0, rb.linear_velocity.z))
	_key_turn = float(k.get("turn", 0.0))


## Un paso de las teclas; true si suenan (la mirada es suya este cuadro).
func _keys_step(delta: float) -> bool:
	if _keys.is_empty():
		return false
	if _carried != null and not carrying():
		return false  # levantándolo, la mirada es del agarre
	var k: Dictionary = _keys[_key_i]
	bi.intent.jump = bool(k.get("jump", false))
	bi.intent.move = k.get("move", Vector2.ZERO)
	bi.intent.sprint = bool(k.get("sprint", false))
	bi.intent.look_yaw = wrapf(bi.intent.look_yaw + _key_turn * delta, -PI, PI)
	_key_left -= delta
	if _key_left <= 0.0:
		_next_key()
	return true


var _jump_over := Vector3.INF
var _jump_held := 0.0


## ── LAS MANOS: LOS BOTONES DEL JUGADOR (05/11/2026, el dios del juego: «un solo sistema… para atajar, para mover, para
## todo»; «el dummy es un jugador sin teclado») ──────────────────────────────────────────────────────────────────────
## Agarrar, llevar, girar lo que lleva, tirar y empujar los hace EL MISMO CONTROLADOR DE INTERACCIÓN DEL JUGADOR (ver
## InteractionController), con un OJO en su cabeza que mira hacia donde mira su intención (`_place_eye`) en vez de la
## cámara. El guion sólo aprieta los botones de la intención (ver CharacterIntent, LAS MANOS) y decide qué agarrar,
## cuándo tirar y hacia dónde. *Hasta entonces tenía su propia copia de agarrar, llevar, empujar y tirar.*
var _hands: InteractionController = null
var _eye_node: Node3D = null


## QUE AGARRE Y LLEVE `thing` (un agarrable —GrabbableInteractable— o el cuerpo que lo lleva, como una caja de la
## bodega), como el jugador: con su fuerza, y lo frena lo que pesa. Dos que llevan lo mismo son dos manos en el mismo
## solver: el paquete alargado entre dos. `drop` lo suelta.
##
## LO LEVANTA COMO UN JUGADOR (04/11/2026, el dios del juego: «los jugadores tienen que mirar un objeto para agarrarlo, no
## solamente interactuar con él»; «se tengan que agachar y agarrarlos después»; el mismo en todas las parcelas): mientras
## lo levanta no sigue su camino. Lo MIRA —el punto de agarre más cercano a su pecho— y aprieta agarrar cuando lo tiene
## en la mira y a su alcance: lo que su controlador marca, como al jugador (ver InteractionDetector). Si no llega y está
## abajo, se agacha; si así tampoco, se acerca. Ya agarrado, espera que el paquete llegue adonde lo quiere y se para;
## recién ahí sigue.
##
## SI SE LE CAE, LO VUELVE A LEVANTAR (04/11/2026, el dios del juego: «que intenten llegar al final con todos los recursos
## que tengan… que se agachen, agarren el paquete y sigan»; «solamente si se puede de una forma muy simple»): recuerda
## lo que se le pidió llevar (`_keep`), y si se le escapó —del alcance, del cono, o al caerse— y no lo soltó a propósito
## (`drop`, o tirándolo), cuando el paquete queda quieto y él de pie, a los `REGRAB_S` lo vuelve a levantar igual que la
## primera vez: derecho hacia él, sin buscar camino (si algo lo tapa, puede no llegar). Sólo si se lo pide `regrab` (los
## pasillos): en las otras parcelas lo que se cae, se queda.
var regrab := false

func carry(thing: Node) -> void:
	drop()
	_carried = _grabbable_of(thing)
	_keep = _carried if regrab else null


## QUE SE LEVANTE SOLO al caerse (`on`): cuando lo caído quedó quieto —su cadera a menos de `REST_SPEED`— el
## `time_to_standup` de su arquetipo, se levanta con la recuperación de siempre (RagdollUtil.deactivate, la de la G). SÓLO
## LO PIDE LA PARCELA «LEVANTARSE» (04/11/2026, el dios del juego: «no se levantan después de caerse porque yo lo quise…
## probemos lo de levantarse en una parcela aparte»): en el juego y en las demás parcelas nadie se levanta solo.
func get_up(on: bool) -> void:
	_get_up = on
	_rest_t = 0.0


const REST_SPEED := 0.4
var _get_up := false
var _rest_t := 0.0


func _get_up_step(delta: float) -> void:
	if not _get_up or not is_instance_valid(bi.ragdoll_util) or not bi.ragdoll_util.is_active:
		_rest_t = 0.0
		return
	var hips := bi.ragdoll_util._bodies.get(bi.custom_bones_util.lower_spine) as RigidBody3D
	if not is_instance_valid(hips):
		return
	_rest_t = _rest_t + delta if hips.linear_velocity.length() < REST_SPEED else 0.0
	var arch := bi.entity_archetype
	if arch != null and _rest_t >= arch.time_to_standup:
		_rest_t = 0.0
		bi.ragdoll_util.deactivate(bi.char_rigidbody, bi.custom_bones_util.lower_spine)


## QUE GIRE LO QUE LLEVA HACIA OTRA CARA, una al azar —un cuarto de vuelta para un costado o el otro, media vuelta, o un
## cuarto para arriba o para abajo—, a `TURN_PACE` rad/s: aprieta el clic derecho y mueve el mouse, como un jugador (ver
## GrabbableInteractable, GIRAR LO QUE SE LLEVA), y ahí lo deja (04/11/2026, el dios del juego: «que sea con un trigger
## y que cada trigger haga que lo giren hacia una cara aleatoria… en vez de que estén girando todo el tiempo»).
func turn_to_another_face() -> void:
	var ways := [Vector2(PI * 0.5, 0.0), Vector2(-PI * 0.5, 0.0), Vector2(PI, 0.0), Vector2(0.0, PI * 0.5),
		Vector2(0.0, -PI * 0.5)]
	_turn_goal += ways[_rng.randi_range(0, ways.size() - 1)]


## A qué ritmo gira el paquete (rad/s): el de una mano con el mouse, no el de un servo. (De 0,7 a 1,6 el 04/11/2026: media
## vuelta tardaba 4,5 s.)
const TURN_PACE := 1.6
var _turn_goal := Vector2.ZERO
var _turned := Vector2.ZERO


## Un paso del giro: con el clic derecho apretado, el mouse que corresponde a `TURN_PACE` (ver
## InteractionController.GRAB_TURN_PER_PX).
func _turn_step(delta: float) -> void:
	var turning := _rise_t < 0.0 and _turned != _turn_goal
	bi.intent.turn_held = turning
	if not turning:
		return
	var next := _turned.move_toward(_turn_goal, TURN_PACE * delta)
	bi.intent.hand_motion += (next - _turned) / InteractionController.GRAB_TURN_PER_PX
	_turned = next


## QUE ATAJE `thing`, algo que viene volando (04/11/2026, el dios del juego: «una parcela de personas que agarran
## paquetes… a distintas velocidades, a distintos ángulos»): no se mueve ni se agacha; lo sigue con la mirada y, cuando
## lo tiene en la mira y a su alcance, APRIETA AGARRAR TARDE (el dios del juego: «más impreciso, más humano… mirándola y
## agarrándola»): `CATCH_HAND_S` después. Si cuando
## aprieta el paquete ya no está en la mira, no lo agarró y vuelve a intentar; si pasa de largo, le pega como cualquier
## cosa.
func catch(thing: Node) -> void:
	carry(thing)
	_catching = true


var _catching := false
const CATCH_HAND_S := 0.08
## Lo que le falta para apretar agarrar (s); −1, todavía no lo vio.
var _catch_hand := -1.0


## QUE EMPUJE lo que tenga adelante, con las manos vacías, como el jugador con la R (ver InteractionController, EL
## EMPUJÓN): aprieta tirar el rato que da la carga `charge` (0 a 1) —con la caja dibujada en el piso— y lo suelta.
func push(charge := 1.0) -> void:
	_push_want = clampf(charge, 0.05, 1.0)
	_push_held = 0.0


var _push_want := -1.0
var _push_held := 0.0


func _push_step(delta: float) -> void:
	if _push_want < 0.0 or _carried != null or bi._is_ragdolling():
		return
	bi.intent.throw = true
	_push_held += delta
	if _push_held >= _push_want * LocomotionCommon.base().throw_charge_s:
		bi.intent.throw = false
		_push_want = -1.0


## QUE TIRE LO QUE LLEVA hacia adelante, con el pase de pecho del jugador (ver LocomotionCommon, TIRAR): aprieta tirar el rato
## que da la carga `charge` (0 a 1) y lo suelta. Si todavía lo está levantando, tira cuando ya lo lleva. Hacia donde
## mira, levantado `up` rad sobre el horizonte: lo que lleva sube con la mirada.
func throw(charge := 1.0, up := 0.0) -> void:
	_throw_want = clampf(charge, 0.05, 1.0)
	_throw_held = 0.0
	_throw_up = up


var _throw_up := 0.0
var _throw_want := -1.0
var _throw_held := 0.0
## Desde que soltó el tiro hasta que el paquete sale (s): mientras, sigue mirando hacia donde tira. −1, nada.
var _throw_left := -1.0


func _throw_step(delta: float) -> void:
	if _throw_left >= 0.0:
		_throw_left -= delta
	if _throw_want < 0.0 or not carrying():
		return
	bi.intent.throw = true
	_throw_held += delta
	if _throw_held >= _throw_want * LocomotionCommon.base().throw_charge_s:
		bi.intent.throw = false
		_throw_want = -1.0
		_throw_left = LocomotionCommon.base().throw_push_s
		_keep = null  # lo tiró a propósito: no lo vuelve a levantar


func drop() -> void:
	_keep = null
	_let_slip()


const REGRAB_S := 0.4
const REGRAB_STILL := 0.6
var _keep: GrabbableInteractable = null
var _regrab_t := 0.0


func _regrab_step(delta: float) -> void:
	if not is_instance_valid(_keep) or _carried != null or bi._is_ragdolling():
		_regrab_t = 0.0
		return
	var body := _keep.get_parent() as RigidBody3D
	if not is_instance_valid(body) or body.linear_velocity.length() > REGRAB_STILL:
		_regrab_t = 0.0
		return
	_regrab_t += delta
	if _regrab_t >= REGRAB_S:
		_regrab_t = 0.0
		_carried = _keep


## Se le escapa lo que lleva, o lo suelta (sin olvidar que lo quiere llevar, ver `carry`): suelta los botones de las manos,
## y su controlador lo suelta.
func _let_slip() -> void:
	if is_instance_valid(bi):
		bi.intent.use = false
		bi.intent.throw = false
		bi.intent.turn_held = false
	_carried = null
	_had_it = false
	_pickup_at = Vector3.INF
	_rise_t = -1.0
	_throw_want = -1.0
	_throw_left = -1.0
	_turned = Vector2.ZERO
	_turn_goal = Vector2.ZERO
	_catching = false
	_catch_hand = -1.0
	if _pickup_crouched:
		_pickup_crouched = false
		crouch(false)


## Cuánto abajo de la punta del pecho tiene que estar lo que no alcanza para agacharse (m).
const PICKUP_LOW := 0.25
## Hasta dónde se acerca a lo que va a levantar (m, del eje de la cápsula al punto, en el plano).
const PICKUP_CLOSE := 0.4
## Lo más que espera, ya agarrado, a que llegue para pararse (s).
const PICKUP_LIFT_S := 1.0
## Cuánto puede bajar la mirada para verlo: la del jugador (ver PlayerController, ±1,2).
const PICKUP_PITCH := 1.2
## Adónde mira mientras lo levanta (INF: no está levantando nada).
var _pickup_at := Vector3.INF
var _pickup_crouched := false
## Desde que lo agarró, mientras espera para pararse (s); −1, ya está.
var _rise_t := -1.0

var _was_fallen := false
## Lo que se le pidió llevar (ver `carry`), o null; y si en el paso anterior lo tenía en la mano.
var _carried: GrabbableInteractable = null
var _had_it := false


## QUE `control` QUEDE EN `value`: lo va a buscar si hace falta. Se puede pedir cada cuadro.
func want(control: ControllableInteractable, value: Variant) -> void:
	if is_instance_valid(control):
		_wanted[control] = value


## Lo que marca `control` ahora: lo que la mano ya hizo, no lo pedido.
func value_of(control: ControllableInteractable) -> Variant:
	return control.get_sync_state()


## Si tiene `control` en la mano.
func is_holding(control: ControllableInteractable) -> bool:
	return control == _control and _hand_on()


## Suelta lo que tenga y vuelve a mirar adelante; olvida lo pedido, y se para.
func stop() -> void:
	_wanted.clear()
	_let_go()
	drop()
	stop_moving()
	_jump_over = Vector3.INF
	_keys = []
	bi.intent.jump = false


## ── CADA PASO ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not is_instance_valid(bi) or not is_instance_valid(bi.char_rigidbody):
		return
	if _control != null and not is_instance_valid(_control):
		_let_go()
	# AL CAERSE, SUELTA TODO, como el jugador (ver PlayerController, `interaction_controller.stop_all` al entrar al
	# ragdoll; 04/11/2026, el dios del juego): lo que llevaba sigue con la velocidad que tenía. *Hasta entonces el guion no
	# soltaba, y la caja seguía tirando hacia el pecho del caído.*
	_get_up_step(delta)
	var fallen := bi._is_ragdolling()
	var hands := _hands_ready()
	if fallen and not _was_fallen:
		_let_slip()
		_let_go()
		_push_held = 0.0
		if hands:
			_hands.stop_all()
	_was_fallen = fallen
	_regrab_step(delta)
	var lifting := hands and _carry_step(delta)
	_throw_step(delta)
	_push_step(delta)
	if _carried == null and (_control == null or _should_switch()):
		_switch_to(_pick())
	if not lifting:
		_pursue()
		_walk()
		_sense_ahead()
	_jump_step(delta)
	if not _keys_step(delta):
		_look(delta)
	# LAS MANOS, con lo que apretó este paso (ver LAS MANOS).
	if hands:
		_place_eye()
		_hands.update(delta)
	if _control == null or _carried != null:
		return
	# LA MANO SALE CUANDO YA ESTÁ A LA VISTA.
	if bi.intent.grab != _control and _gaze_left(_point_of(_control)) < IN_VIEW:
		bi.intent.grab = _control
	if not _hand_on():
		return
	var there := _move(_control, delta)
	if there and not _drives(_control):
		_let_go()


## LA ATENCIÓN, hacia lo que importa, a LOOK_RATE: con la mano en lo que maneja, adelante (doblando, hacia la curva); si
## va a un control, al control; si no, a lo que se le pidió mirar, o adelante.
func _look(delta: float) -> void:
	var step := LOOK_RATE * delta
	var want_yaw := _ahead_yaw()
	var want_pitch := 0.0
	if _control != null and _drives(_control) and _hand_on():
		want_yaw += _drive_turn(_control)
	elif _control != null:
		var aim := _aim(_point_of(_control))
		want_yaw = aim.x
		want_pitch = aim.y
	elif _pickup_at.is_finite():
		var aim := _aim(_pickup_at, PICKUP_PITCH)
		want_yaw = aim.x
		want_pitch = aim.y
	elif is_instance_valid(_gaze):
		# LA MIRADA PEDIDA GANA SOBRE LA DE CAMINAR (03/11/2026): así se camina de espaldas o de costado mirando lo que
		# se lleva entre dos (ver LocomotionLabArchetype, de a dos).
		var aim := _aim(_gaze.global_position)
		want_yaw = aim.x
		want_pitch = aim.y
	elif _walk_to.is_finite():
		var toward := _steer_to if _steer_to.is_finite() and not _avoid.is_empty() else _walk_to
		want_yaw = CharacterIntent.yaw_of(bi.char_rigidbody.frame, toward - bi.char_rigidbody.global_position)
	# TIRANDO, mira hacia donde tira (ver `throw`).
	if carrying() and (_throw_want >= 0.0 or _throw_left >= 0.0):
		want_pitch = _throw_up
	_look_want = Vector2(want_yaw, want_pitch)
	bi.intent.look_yaw = rotate_toward(bi.intent.look_yaw, want_yaw, step)
	bi.intent.look_pitch = move_toward(bi.intent.look_pitch, want_pitch, step)


## Lo último que decidió mirar: rumbo y cabeceo.
var _look_want := Vector2(INF, INF)


## EL PASO HACIA DONDE VA (ver `move_towards`): en los ejes de la cápsula, así va derecho aunque la mirada todavía esté
## girando. Suelta cuando lo que le queda es lo que tarda en frenar con su propia frenada, así se para ahí y no se pasa
## (medido: corriendo a 3,5 m/s, soltar al llegar lo dejaba 5 m más allá).
func _walk() -> void:
	if _braking:
		_brake_step()
		return
	if not _walk_to.is_finite():
		return
	if _unstick():
		return
	var rb := bi.char_rigidbody
	var local := rb.global_basis.orthonormalized().inverse() * (_walk_to - rb.global_position)
	var flat := Vector2(local.x, local.z)
	if _arrive and flat.length() < ARRIVED + _stop_distance():
		var against := _brake_against
		stop_moving()
		if against:
			_braking = true
			_brake_step()
		return
	_steer_to = _detour(_walk_to) if not _avoid.is_empty() else _walk_to
	if _traverse:
		_steer_to = _feel_around(_steer_to)
	if _steer_to != _walk_to:
		var around := rb.global_basis.orthonormalized().inverse() * (_steer_to - rb.global_position)
		flat = Vector2(around.x, around.z)
	bi.intent.move = flat.normalized()
	bi.intent.sprint = _walk_sprint


## ── RODEAR LO QUE VE (06/11/2026, el dios del juego: «por física, como proponés»): sorteando (`traverse`), si algo fijo le
## tapa el camino a la altura de la CINTURA —un rayo al medio y uno a cada costado de su cuerpo, `AROUND_LOOK` adelante—,
## prueba direcciones a los costados (`AROUND_ANGLES`) y va por la primera libre, empezando por el lado por el que ya venía
## rodeando (así no duda). Lo más bajo que la cintura lo salta o lo pasa agachado (ver `_sense_ahead`); si no hay por dónde
## rodear, sigue derecho y que el cuerpo resuelva. Lo ve por física, como un jugador: lo que tiene colisión.
const AROUND_WAIST := 0.45
const AROUND_LOOK := 2.5
const AROUND_ANGLES := [20.0, 40.0, 60.0, 80.0]
var _around_side := 1.0


func _feel_around(target: Vector3) -> Vector3:
	var rb := bi.char_rigidbody
	if not rb.is_grounded or bi.skel_sizes_util == null:
		return target
	var space := rb.get_world_3d().direct_space_state
	var pos := rb.global_position
	var feet := _floor_below(space, pos, 3.0)
	if not is_finite(feet):
		return target
	var toward := target - pos
	toward.y = 0.0
	if toward.length() < 0.3:
		return target
	var dir := toward.normalized()
	var s := bi.skel_sizes_util
	var waist := Vector3(pos.x, feet + (s.leg_height + s.torso_height + s.head_height) * AROUND_WAIST, pos.z)
	var look := minf(AROUND_LOOK, toward.length())
	if _band_clear(space, waist, dir, look, rb._capsule_radius):
		return target
	for angle: float in AROUND_ANGLES:
		for side: float in [_around_side, -_around_side]:
			var d := dir.rotated(Vector3.UP, deg_to_rad(angle) * side)
			if _band_clear(space, waist, d, look, rb._capsule_radius):
				_around_side = side
				return pos + d * look
	return target


## Libre de `from` hacia `d`, `look` m: al medio y a cada costado de su cuerpo (`radius`).
func _band_clear(space: PhysicsDirectSpaceState3D, from: Vector3, d: Vector3, look: float, radius: float) -> bool:
	var across := d.cross(Vector3.UP).normalized() * radius
	for offset: Vector3 in [Vector3.ZERO, across, -across]:
		if _ray(space, from + offset, from + offset + d * look):
			return false
	return true


## SI SE TRABÓ, UN PASO AL COSTADO (04/11/2026, el dios del juego: «que intenten llegar al final con todos los recursos»):
## si quiere avanzar y lleva `STUCK_S` sin moverse (de pie, sin levantar nada), camina `UNSTICK_M` hacia un costado al
## azar durante `UNSTICK_S` y vuelve a lo suyo. Simple: no busca camino. Verdadero mientras se destraba.
const STUCK_S := 1.5
const UNSTICK_S := 0.7
const UNSTICK_M := 1.2
var _stuck_t := 0.0
var _unstick_left := 0.0
var _unstick_dir := Vector2.ZERO


func _unstick() -> bool:
	var rb := bi.char_rigidbody
	if _unstick_left > 0.0:
		_unstick_left -= get_physics_process_delta_time()
		bi.intent.move = _unstick_dir
		bi.intent.sprint = false
		return true
	var v := rb.get_motion_velocity()
	if bi._is_ragdolling() or bi.intent.move == Vector2.ZERO or Vector2(v.x, v.z).length() > 0.25 or _jump_over.is_finite():
		_stuck_t = 0.0
		return false
	_stuck_t += get_physics_process_delta_time()
	if _stuck_t < STUCK_S:
		return false
	_stuck_t = 0.0
	_unstick_left = UNSTICK_S
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	_unstick_dir = Vector2(side, 0.3).normalized()
	bi.intent.move = _unstick_dir
	return true


## Lo que tarda en frenar, a la velocidad que lleva, con la frenada más débil de las tres (después de una curva la
## velocidad no va por donde mira, y frena de costado).
func _stop_distance() -> float:
	# Lo calcula el cuerpo, con su banda del sprint (ver CharacterRigidBody3D.stop_distance); apretando para atrás frena
	# con la aceleración hacia atrás más la frenada, así que suelta más tarde.
	return bi.char_rigidbody.stop_distance(_brake_against)


## ── FRENAR APRETANDO PARA ATRÁS (06/11/2026, el dios del juego: «uno que simplemente deje de caminar y deje de sprintear,
## y otro que apriete como la S… para ir frenando… eso es una mecánica del juego») ───────────────────────────────────────
## Pedido con la meta (`move_towards`, `against`): al llegar no suelta, aprieta en contra de hacia donde va —la S si va
## derecho— hasta quedar casi quieto (`BRAKE_DONE`), y ahí suelta, como un jugador que no quiere salir para atrás. Sin
## él, suelta todo y lo frena su frenada sola.
var _brake_against := false
const BRAKE_DONE := 0.2
var _braking := false


func _brake_step() -> void:
	var rb := bi.char_rigidbody
	var motion := rb.get_motion_velocity()
	var local := rb.global_basis.orthonormalized().inverse() * motion
	var flat := Vector2(local.x, local.z)
	if flat.length() < BRAKE_DONE:
		_braking = false
		stop_moving()
		return
	bi.intent.move = -flat.normalized()
	bi.intent.sprint = false


## LA PERSECUCIÓN DEL CAMINO (ver `follow_path`): el punto del camino más cercano, desde el tramo en que va, y de ahí
## `LOOK_AHEAD` más adelante, que pasa a ser adonde va sin pararse; cerca del final, el final, y ahí se para.
func _pursue() -> void:
	if _path.size() < 2:
		return
	var pos := bi.char_rigidbody.global_position
	var best_i := _path_at
	var best_t := 0.0
	var best_d := INF
	for i in range(_path_at, mini(_path_at + 8, _path.size() - 1)):
		var a := _flat(_path[i])
		var ab := _flat(_path[i + 1]) - a
		var t := clampf((_flat(pos) - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var d := (a + ab * t).distance_to(_flat(pos))
		if d < best_d:
			best_d = d
			best_i = i
			best_t = t
	_path_at = best_i
	var at := _path[best_i].lerp(_path[best_i + 1], best_t)
	if _sprint_on_straights:
		_walk_sprint = _bend_ahead(best_i, at, BEND_LOOK + _stop_distance()) < SPRINT_BEND
	# CERCA DEL FINAL —lo que le queda es lo que tarda en frenar—: va al final y se para ahí.
	var remaining := _flat(_path[best_i + 1]).distance_to(_flat(at))
	for j in range(best_i + 1, _path.size() - 1):
		remaining += _flat(_path[j + 1]).distance_to(_flat(_path[j]))
	if remaining <= maxf(_look_ahead, ARRIVED + _stop_distance()):
		_walk_to = _path[_path.size() - 1]
		_arrive = true
		_path = PackedVector3Array()
		return
	var left := _look_ahead
	var i := best_i
	while i < _path.size() - 1:
		var step := _flat(_path[i + 1]) - _flat(at)
		if step.length() >= left:
			var ahead := _flat(at) + step.normalized() * left
			_walk_to = Vector3(ahead.x, at.y, ahead.y)
			_arrive = false
			return
		left -= step.length()
		at = _path[i + 1]
		i += 1
	# Cerca del final: va al final y se para ahí.
	_walk_to = _path[_path.size() - 1]
	_arrive = true
	_path = PackedVector3Array()


## Lo más que dobla el camino, desde `at` (sobre el tramo `from`) hasta `ahead` m más adelante, contra el rumbo de ese
## tramo (rad).
func _bend_ahead(from: int, at: Vector3, ahead: float) -> float:
	var heading := _flat(_path[from + 1]) - _flat(_path[from])
	if heading.length_squared() < 0.000001:
		return 0.0
	var most := 0.0
	var left := ahead - _flat(_path[from + 1]).distance_to(_flat(at))
	var i := from + 1
	while left > 0.0 and i < _path.size() - 1:
		var step := _flat(_path[i + 1]) - _flat(_path[i])
		if step.length_squared() > 0.000001:
			most = maxf(most, absf(heading.angle_to(step)))
		left -= step.length()
		i += 1
	return most


static func _flat(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


## EL SALTO SOBRE UN OBSTÁCULO (ver `jump_at`): despega a la mitad de su vuelo antes —su vuelo dura
## 2·√(2·alto/g) a la velocidad que lleva— y empieza a cargar lo que tarda en cargar entero antes de eso. Suelta lo que
## tarda en salir el salto antes del despegue (BoneInstantiator.JUMP_RELEASE_S: el salto sale al terminar de soltar la
## carga; 05/11/2026, el dios del juego: «ahora siempre saltan más tarde porque no están considerando ese tiempo»).
func _jump_step(delta: float) -> void:
	if not _jump_over.is_finite():
		return
	var rb := bi.char_rigidbody
	var arch := bi.entity_archetype
	if arch == null:
		return
	var speed := Vector2(rb.get_motion_velocity().x, rb.get_motion_velocity().z).length()
	var air := 2.0 * sqrt(2.0 * arch.jump_height / maxf(rb.get_gravity().length(), 0.01))
	var release := speed * maxf(air * 0.5 + BoneInstantiator.JUMP_RELEASE_S, 0.0)
	var charge := release + speed * arch.time_to_max_jump
	var d := _flat(_jump_over).distance_to(_flat(rb.global_position))
	# FRENADO DELANTE (contra un escalón): carga en el lugar y salta. *Si no, a velocidad cero la distancia para despegar
	# daba cero y no saltaba nunca: se quedaba empujando el escalón.*
	var standing := speed < 0.5 and d < 1.2
	if d > charge and _jump_held <= 0.0 and not standing:
		return
	if (d <= release and _jump_held > 0.0 and not standing) or _jump_held >= arch.time_to_max_jump:
		bi.intent.jump = false  # suelta: salta lo cargado (ver BoneInstantiator, EL SALTO CARGADO)
		_jump_over = Vector3.INF
		_jump_held = 0.0
		return
	bi.intent.jump = true
	_jump_held += delta


## LLEVAR (ver `carry`): primero lo levanta (`_pick_up`); ya en la mano lo lleva su controlador, como al jugador. Si se le
## escapa (del alcance o del cono, ver InteractionController._update_hold), suelta los botones. Verdadero mientras lo está
## levantando: no camina.
func _carry_step(delta: float) -> bool:
	if _carried == null:
		return false
	if not is_instance_valid(_carried) or not _carried.is_inside_tree():
		drop()
		return false
	var holds := _holds()
	if _had_it and not holds:
		_let_slip()
		return false
	if holds and not _had_it:
		_rise_t = -1.0 if _catching else 0.0
		_catching = false
		_pickup_at = Vector3.INF
	_had_it = holds
	if not holds:
		_pick_up()
		return true
	_turn_step(delta)
	# YA AGARRADO, se para cuando el paquete llegó adonde lo quiere (o al rato); hasta entonces, quieto.
	if _rise_t < 0.0:
		return false
	_rise_t += delta
	if not _carried.cone_point(_hands._hold_key()).is_finite() and _rise_t < PICKUP_LIFT_S:
		bi.intent.move = Vector2.ZERO
		return true
	_rise_t = -1.0
	if _pickup_crouched:
		_pickup_crouched = false
		crouch(false)
	return false


## Si su controlador tiene en la mano lo que se le pidió llevar.
func _holds() -> bool:
	return is_instance_valid(_carried) and is_instance_valid(_hands) and _hands.engaged() == _carried.get_parent()


## LEVANTARLO (ver `carry`): lo mira, se agacha si está abajo y no llega, se acerca si así tampoco, y aprieta agarrar
## cuando lo tiene en la mira y a su alcance. Si apretó y no lo agarró, suelta el botón y vuelve a probar. Atajando (ver
## `catch`), quieto, mirándolo: aprieta tarde, y agarra si sigue en la mira.
func _pick_up() -> void:
	if bi.intent.use:
		bi.intent.use = false
		return
	var body := _carried.get_parent() as RigidBody3D
	var origin := bi.get_interaction_origin()
	var point := _carried.get_nearest_grab_point(origin)
	var at := point.global_position if is_instance_valid(point) else body.global_position
	_pickup_at = at
	var rb := bi.char_rigidbody
	var local := rb.global_basis.orthonormalized().inverse() * (at - rb.global_position)
	var flat := Vector2(local.x, local.z)
	var reach: float = bi.skel_sizes_util.interaction_reach
	var in_reach := origin.distance_to(at) <= _hands.interact_dist_max
	var aimed := in_reach and _hands.engaged() == null and _hands.detector.get_hovered() == _carried
	if _catching:
		bi.intent.move = Vector2.ZERO
		if _catch_hand < 0.0:
			if aimed:
				_catch_hand = CATCH_HAND_S
			return
		_catch_hand -= get_physics_process_delta_time()
		if _catch_hand > 0.0:
			return
		_catch_hand = -1.0
		bi.intent.use = aimed
		return
	if not in_reach and not _pickup_crouched and at.y < origin.y - PICKUP_LOW and flat.length() < reach:
		_pickup_crouched = true
		crouch(true)
	var settled := not _pickup_crouched or bi.crouch_t >= 0.99
	bi.intent.sprint = false
	bi.intent.move = flat.normalized() if not in_reach and settled and flat.length() > PICKUP_CLOSE else Vector2.ZERO
	bi.intent.use = aimed


## LAS MANOS DEL JUGADOR PARA ESTE (ver LAS MANOS): armadas la primera vez, y vueltas a atar si cambió el cuerpo. False si
## todavía no tiene cuerpo con brazos.
func _hands_ready() -> bool:
	var rb := bi.char_rigidbody
	if not is_instance_valid(rb) or not is_instance_valid(bi.arms_controller) or bi.skel_sizes_util == null:
		return false
	var reach: float = bi.skel_sizes_util.interaction_reach
	if _hands == null:
		_eye_node = Node3D.new()
		_eye_node.name = "Ojo"
		add_child(_eye_node)
		_hands = InteractionController.new()
		_hands.name = "Manos"
		_hands.show_grab_curve = false
		_hands.hand_key = bi.get_instance_id()
		add_child(_hands)
		_place_eye()
		_hands.setup(rb, _eye_node, bi.arms_controller, bi.anim_mod, reach, bi.entity_instantiation, bi)
	elif _hands.char_rigidbody != rb or _hands.arms_controller != bi.arms_controller or _hands.anim_mod != bi.anim_mod:
		_hands.stop_all()
		_hands.rebind(rb, _eye_node, bi.arms_controller, bi.anim_mod, reach, bi.entity_instantiation, bi)
	return true


## EL OJO (ver LAS MANOS): en la cabeza, hacia donde mira su intención —el frente de la cápsula, levantado lo que
## cabecea—, como la cámara del jugador.
func _place_eye() -> void:
	var rb := bi.char_rigidbody
	var forward := Basis(rb.global_basis.x.normalized(), bi.intent.look_pitch) * -rb.global_basis.z.normalized()
	_eye_node.global_transform = Transform3D(Basis.looking_at(forward, rb.global_basis.y.normalized()), _eye())


static func _grabbable_of(thing: Node) -> GrabbableInteractable:
	if thing is GrabbableInteractable:
		return thing as GrabbableInteractable
	if thing == null:
		return null
	for child in thing.get_children():
		if child is GrabbableInteractable:
			return child as GrabbableInteractable
	return null


## El rumbo y el cabeceo, en los ejes de su marco, para mirar `point`; hacia abajo, hasta `down` (rad).
func _aim(point: Vector3, down := 0.5) -> Vector2:
	var eye := _eye()
	var rb := bi.char_rigidbody
	var yaw := CharacterIntent.yaw_of(rb.frame, point - eye)
	var local := rb.global_basis.orthonormalized().inverse() * (point - eye)
	return Vector2(yaw, clampf(atan2(local.y, Vector2(local.x, local.z).length()), -down, 0.8))


## Cuánto le falta a la mirada para tener `point` de frente (rad).
func _gaze_left(point: Vector3) -> float:
	var aim := _aim(point)
	return maxf(absf(angle_difference(bi.intent.look_yaw, aim.x)), absf(aim.y - bi.intent.look_pitch))


## Adelante: sentado, el frente de la silla; parado, para donde ya mira.
func _ahead_yaw() -> float:
	if bi.is_seated and is_instance_valid(bi.current_seat):
		return CharacterIntent.yaw_of(bi.char_rigidbody.frame, -(bi.current_seat as Node3D).global_basis.z)
	return bi.intent.look_yaw


## Con el volante: cuánto mira para el lado al que está doblado. Los de dos ejes, al frente.
func _drive_turn(control: ControllableInteractable) -> float:
	var wheel := control as RotatingComponent
	if wheel == null:
		return 0.0
	var full := wheel.max_rotation if wheel.max_rotation > 0.0 else PI
	return clampf(wheel.total_rotation / full, -1.0, 1.0) * DRIVE_LOOK


func _hand_on() -> bool:
	return bi.intent.grab == _control and is_instance_valid(bi.arms_controller) \
		and bi.arms_controller.hand_on() >= HANDS_ON


## ── QUÉ USA ────────────────────────────────────────────────────────────────────────────────────────────────────────

## El que va a buscar: el que está más lejos de lo pedido, si vale la pena; sin nada que corregir, lo que maneja.
func _pick() -> ControllableInteractable:
	var best: ControllableInteractable = null
	var gap := WORTH
	for key: Variant in _wanted.keys():
		if not is_instance_valid(key):
			_wanted.erase(key)
			continue
		var control := key as ControllableInteractable
		var off := _gap(control)
		if off > gap:
			gap = off
			best = control
	if best == null:
		for key: Variant in _wanted.keys():
			if is_instance_valid(key) and _drives(key as ControllableInteractable):
				return key as ControllableInteractable
	return best


## Con lo que maneja en la mano, si otro control quedó lejos de lo pedido: lo suelta para ir.
func _should_switch() -> bool:
	if not _drives(_control):
		return false
	for key: Variant in _wanted.keys():
		if key != _control and is_instance_valid(key) and _gap(key as ControllableInteractable) > WORTH_LEAVING_THE_WHEEL:
			return true
	return false


func _switch_to(control: ControllableInteractable) -> void:
	if control == _control:
		return
	_let_go()
	_control = control


## Al soltar, el control vuelve a ser suyo: sin `_remote_controlled` recupera lo que hace solo —el volante vuelve al
## centro— (ver ControllableInteractable._physics_process).
func _let_go() -> void:
	bi.intent.grab = null
	if is_instance_valid(_control):
		_control._remote_controlled = false
	_control = null


## Un paso de la mano hacia lo pedido; true si ya llegó.
func _move(control: ControllableInteractable, delta: float) -> bool:
	if not _wanted.has(control):
		return true
	var now: Variant = control.get_sync_state()
	var goal: Variant = _wanted[control]
	var rate := (TURN_RATE if control is RotatingComponent else MOVE_RATE) * delta
	var next: Variant = goal
	if now is float and goal is float:
		next = move_toward(now, goal, rate)
	elif now is Vector2 and goal is Vector2:
		next = (now as Vector2).move_toward(goal, rate)
	if next != now:
		control._remote_controlled = true
		control.apply_sync_state(next)
	return _gap(control) <= WORTH * 0.5


func _gap(control: ControllableInteractable) -> float:
	var now: Variant = control.get_sync_state()
	var goal: Variant = _wanted.get(control, now)
	if now is float and goal is float:
		return absf(float(goal) - float(now))
	if now is Vector2 and goal is Vector2:
		return (goal as Vector2).distance_to(now)
	return 0.0 if now == goal else 1.0


func _eye() -> Vector3:
	var head := bi.custom_bones_util.head
	return head.global_position if is_instance_valid(head) else bi.char_rigidbody.global_position


func _point_of(control: ControllableInteractable) -> Vector3:
	var handle := control.get_nearest_handle_point(_eye())
	return handle.global_position if is_instance_valid(handle) else control.global_position


## Lo que se maneja mirando adelante: el volante (la rueda que no va con la ruedita) y los mandos de dos ejes. La palanca
## de cambios no: se usa mirándola.
static func _drives(control: ControllableInteractable) -> bool:
	if control is GearShiftComponent:
		return false
	if control is TwoAxisComponent:
		return true
	return control is RotatingComponent \
		and (control as RotatingComponent).input_mode != RotatingComponent.InputMode.SCROLL
