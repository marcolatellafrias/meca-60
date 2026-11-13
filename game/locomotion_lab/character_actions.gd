class_name CharacterActions
extends Node

## ── LO QUE UN PERSONAJE HACE POR GUION (13/11/2026) ─────────────────────────────────────────────────────────────────
## Para la fila Locomoción: los seis arquetipos corren, saltan, se caen, llevan, tiran y atajan paquetes solos, para
## mirarlos. El guion NO mueve el cuerpo: aprieta los mismos botones que un jugador (la intención, ver CharacterIntent)
## y el cuerpo hace el resto con su velocidad, su aceleración y su equilibrio. Las manos son las del jugador —un
## controlador de interacción con un ojo en la cabeza (ver `_hands_ready`)—, así que levantar, llevar, tirar y atajar son
## lo mismo que hace uno con el mouse.
##
## Los verbos: `go_to` (caminando o corriendo, y al llegar suelta o frena apretando para atrás), `follow_path`, `stop`, `jump`,
## `jump_over`, `look_at`, `carry`, `throw`, `catch`, `drop`. Simple a propósito: no busca camino ni esquiva nada.
##
## *Viene de ExhibitOperator de character-parametric (1.308 líneas), que además manejaba controles, esquivaba, se destrababa y apretaba teclas en el tiempo. Acá queda lo que se usa para mirar a los personajes moverse.*

## Qué tan rápido gira la mirada (rad/s): la de una persona.
const LOOK_RATE := 2.5
## Cuándo llegó (m, en el plano).
const ARRIVED := 0.3
## Con frenada apretando para atrás, cuándo ya está casi quieto (m/s) y suelta.
const BRAKE_DONE := 0.2
## Atajando, cuánto tarda en apretar agarrar desde que lo tiene en la mira (s): tarde, como una persona.
const CATCH_HAND_S := 0.08
## Levantando: cuánto abajo del pecho tiene que estar para agacharse (m), hasta dónde se acerca (m), lo más que espera
## a que llegue a las manos para pararse (s) y cuánto puede bajar la mirada (rad, la del jugador).
const PICKUP_LOW := 0.25
const PICKUP_CLOSE := 0.4
const PICKUP_LIFT_S := 1.0
const PICKUP_PITCH := 1.2

var bi: BoneInstantiator


## EL DE `who`, creado la primera vez. Desde ahí lo maneja un guion: mira hacia donde el guion le pide.
static func of(who: BoneInstantiator) -> CharacterActions:
	for child in who.get_children():
		if child is CharacterActions:
			return child as CharacterActions
	var actions := CharacterActions.new()
	actions.name = "Acciones"
	actions.bi = who
	who.add_child(actions)
	if not who.kind.looks():
		who.kind.driver = CharacterKind.Driver.SCRIPT
		if is_instance_valid(who.procedural_animator):
			who.refresh_camera_animations()
	return actions


## ── MOVERSE ────────────────────────────────────────────────────────────────────────────────────────────────────────
var _walk_to := Vector3.INF
var _sprint := false
var _brake := false
var _braking := false


## QUE VAYA HASTA `point` (mundo), caminando o corriendo (`sprint`): mira hacia allá y avanza. Suelta a lo que tarda en
## frenar, así se para ahí; con `brake`, al llegar aprieta para atrás hasta quedar casi quieto, como un jugador que frena.
func go_to(point: Vector3, sprint := false, brake := false) -> void:
	_walk_to = point
	_sprint = sprint
	_brake = brake
	_braking = false


## QUE SIGA EL CAMINO `points` (mundo, en orden), con la persecución pura de antes: va hacia un punto `LOOK_AHEAD` más
## adelante sobre el camino, y cerca del final, al final (como `go_to`). Cuánto se ciñe lo decide su cuerpo —su
## aceleración, su frenada, el giro de su mirada—; no ve lo que hay al costado.
func follow_path(points: PackedVector3Array, sprint := false, brake := false) -> void:
	go_to(points[points.size() - 1], sprint, brake)
	_path = points
	_path_at = 0


## Cuánto más adelante sobre el camino va (m).
const LOOK_AHEAD := 2.5
var _path := PackedVector3Array()
var _path_at := 0


func stop() -> void:
	_walk_to = Vector3.INF
	_path = PackedVector3Array()
	_braking = false
	if is_instance_valid(bi):
		bi.intent.move = Vector2.ZERO
		bi.intent.sprint = false


## SI TODAVÍA VA A ALGÚN LADO (o frena).
func moving() -> bool:
	return _walk_to.is_finite() or _braking


func _walk() -> void:
	var rb := bi.char_rigidbody
	if _braking:
		var local_v := rb.global_basis.orthonormalized().inverse() * rb.get_motion_velocity()
		var flat_v := Vector2(local_v.x, local_v.z)
		if flat_v.length() < BRAKE_DONE:
			stop()
			return
		bi.intent.move = -flat_v.normalized()
		bi.intent.sprint = false
		return
	if not _walk_to.is_finite():
		return
	var target := _pursue() if _path.size() >= 2 else _walk_to
	var local := rb.global_basis.orthonormalized().inverse() * (target - rb.global_position)
	var flat := Vector2(local.x, local.z)
	if _path.size() >= 2:
		bi.intent.move = flat.normalized()
		bi.intent.sprint = _sprint
		return
	# LLEGAR SE DECIDE EN EL PISO: en el aire no hay roce y lo que tarda en frenar sale enorme (al saltar una valla daba
	# por llegado cinco metros antes).
	if rb.is_grounded and flat.length() < ARRIVED + rb.stop_distance(_brake):
		var brake := _brake
		stop()
		_braking = brake
		return
	bi.intent.move = flat.normalized()
	bi.intent.sprint = _sprint


## LA PERSECUCIÓN: el punto del camino más cercano (desde el tramo en que va) y de ahí `LOOK_AHEAD` más adelante. Cuando
## lo que queda es menos que eso, suelta el camino y va al final como `go_to`.
func _pursue() -> Vector3:
	var pos := _flat(bi.char_rigidbody.global_position)
	var best_i := _path_at
	var best_t := 0.0
	var best_d := INF
	for i in range(_path_at, mini(_path_at + 8, _path.size() - 1)):
		var a := _flat(_path[i])
		var ab := _flat(_path[i + 1]) - a
		var t := clampf((pos - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var d := (a + ab * t).distance_to(pos)
		if d < best_d:
			best_d = d
			best_i = i
			best_t = t
	_path_at = best_i
	var at := _flat(_path[best_i]).lerp(_flat(_path[best_i + 1]), best_t)
	var left := LOOK_AHEAD
	for i in range(best_i, _path.size() - 1):
		var step := _flat(_path[i + 1]) - at
		if step.length() >= left:
			var ahead := at + step.normalized() * left
			return Vector3(ahead.x, _path[i + 1].y, ahead.y)
		left -= step.length()
		at = _flat(_path[i + 1])
	_path = PackedVector3Array()
	return _walk_to


## ── SALTAR ─────────────────────────────────────────────────────────────────────────────────────────────────────────
## El salto se carga manteniéndolo apretado (ver BoneInstantiator, EL SALTO CARGADO) y sale al soltarlo.
var _jump_left := -1.0
var _jump_over := Vector3.INF
var _jump_held := 0.0


## QUE SALTE YA, cargado `charge` (0 un toque, 1 entero).
func jump(charge := 1.0) -> void:
	var arch := bi.entity_archetype
	_jump_left = clampf(charge, 0.0, 1.0) * (arch.time_to_max_jump if arch != null else 0.3) + 0.02


## QUE SALTE PARA PASAR LO QUE HAY EN `point`: al acercarse, carga a la distancia justa según su velocidad y suelta para
## despegar a la mitad de su vuelo antes. Frenado delante, carga entero y salta ahí.
func jump_over(point: Vector3) -> void:
	_jump_over = point
	_jump_held = 0.0


func _jump_step(delta: float) -> void:
	if _jump_left >= 0.0:
		_jump_left -= delta
		bi.intent.jump = _jump_left > 0.0
		if _jump_left < 0.0:
			bi.intent.jump = false
		return
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
	var standing := speed < 0.5 and d < 1.2
	if d > charge and _jump_held <= 0.0 and not standing:
		return
	if (d <= release and _jump_held > 0.0 and not standing) or _jump_held >= arch.time_to_max_jump:
		bi.intent.jump = false
		_jump_over = Vector3.INF
		_jump_held = 0.0
		return
	bi.intent.jump = true
	_jump_held += delta


## ── MIRAR ──────────────────────────────────────────────────────────────────────────────────────────────────────────
var _gaze: Node3D = null


## QUE MIRE `target` (null: adonde va, o adelante).
func look_at(target: Node3D) -> void:
	_gaze = target


func _look(delta: float) -> void:
	var rb := bi.char_rigidbody
	var want := Vector2(bi.intent.look_yaw, 0.0)
	if _pickup_at.is_finite():
		want = _aim(_pickup_at, PICKUP_PITCH)
	elif is_instance_valid(_gaze):
		want = _aim(_gaze.global_position)
	elif _walk_to.is_finite():
		want.x = CharacterIntent.yaw_of(rb.frame, _walk_to - rb.global_position)
	if _holds() and (_throw_want >= 0.0 or _throw_left >= 0.0):
		want.y = _throw_up
	var step := LOOK_RATE * delta
	bi.intent.look_yaw = rotate_toward(bi.intent.look_yaw, want.x, step)
	bi.intent.look_pitch = move_toward(bi.intent.look_pitch, want.y, step)


## El rumbo y el cabeceo para mirar `point`; hacia abajo, hasta `down` (rad).
func _aim(point: Vector3, down := 0.5) -> Vector2:
	var eye := _eye()
	var rb := bi.char_rigidbody
	var yaw := CharacterIntent.yaw_of(rb.frame, point - eye)
	var local := rb.global_basis.orthonormalized().inverse() * (point - eye)
	return Vector2(yaw, clampf(atan2(local.y, Vector2(local.x, local.z).length()), -down, 0.8))


func _eye() -> Vector3:
	var head := bi.custom_bones_util.head
	return head.global_position if is_instance_valid(head) else bi.char_rigidbody.global_position


static func _flat(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


## ── LAS MANOS: LAS DEL JUGADOR ─────────────────────────────────────────────────────────────────────────────────────
## Agarrar, llevar y tirar los hace el mismo controlador de interacción del jugador, con un ojo en su cabeza que mira
## hacia donde mira su intención en vez de la cámara. El guion sólo aprieta agarrar (`use`) y tirar (`throw`).
var _hands: InteractionController = null
var _eye_node: Node3D = null
## Lo que se le pidió llevar, o null; si en el paso anterior lo tenía en la mano; adónde mira mientras lo levanta (INF:
## no levanta nada); si se agachó para levantarlo; y desde que lo agarró, mientras espera para pararse (s; −1, ya está).
var _carried: GrabbableInteractable = null
var _had_it := false
var _pickup_at := Vector3.INF
var _pickup_crouched := false
var _rise_t := -1.0
## Atajando: quieto, mirándolo, y aprieta tarde (ver CATCH_HAND_S); lo que le falta para apretar (s; −1, no lo vio).
var _catching := false
var _catch_hand := -1.0
## Tirando: cuánto carga (0 a 1; −1, nada), cuánto lleva apretado, hacia arriba (rad), y desde que soltó hasta que sale.
var _throw_want := -1.0
var _throw_held := 0.0
var _throw_up := 0.0
var _throw_left := -1.0
var _was_fallen := false


## QUE LEVANTE Y LLEVE `thing` (un agarrable o el cuerpo que lo lleva), como un jugador: lo mira, se agacha si está
## abajo, se acerca si no llega, y aprieta agarrar cuando lo tiene en la mira y a su alcance. Mientras lo levanta no camina.
func carry(thing: Node) -> void:
	drop()
	_carried = _grabbable_of(thing)


## QUE ATAJE `thing`, que viene volando: no se mueve; lo sigue con la mirada y aprieta agarrar tarde.
func catch(thing: Node) -> void:
	carry(thing)
	_catching = true


## QUE TIRE LO QUE LLEVA hacia adelante, con el pase de pecho del jugador: aprieta tirar el rato que da la carga `charge`
## (0 a 1) y lo suelta; hacia donde mira, levantado `up` rad.
func throw(charge := 1.0, up := 0.0) -> void:
	_throw_want = clampf(charge, 0.05, 1.0)
	_throw_held = 0.0
	_throw_up = up


## SI YA LLEVA LO QUE SE LE PIDIÓ: lo levantó y está parado con él.
func carrying() -> bool:
	return _holds() and _rise_t < 0.0


## SI YA NO TIENE NADA EN LAS MANOS (lo tiró, lo soltó o se le cayó).
func empty_handed() -> bool:
	return not _holds()


func drop() -> void:
	if is_instance_valid(bi):
		bi.intent.use = false
		bi.intent.throw = false
	_carried = null
	_had_it = false
	_pickup_at = Vector3.INF
	_rise_t = -1.0
	_throw_want = -1.0
	_throw_left = -1.0
	_catching = false
	_catch_hand = -1.0
	if _pickup_crouched:
		_pickup_crouched = false
		if is_instance_valid(bi):
			bi.intent.crouch = false


func _holds() -> bool:
	return is_instance_valid(_carried) and _hands != null and _hands.engaged() == _carried.get_parent()


## LEVANTAR Y LLEVAR: verdadero mientras lo está levantando (no camina).
func _carry_step(delta: float) -> bool:
	if _carried == null:
		return false
	if not is_instance_valid(_carried) or not _carried.is_inside_tree():
		drop()
		return false
	var holds := _holds()
	if _had_it and not holds:
		drop()
		return false
	if holds and not _had_it:
		_rise_t = -1.0 if _catching else 0.0
		_catching = false
		_pickup_at = Vector3.INF
	_had_it = holds
	if not holds:
		_pick_up()
		return true
	if _rise_t < 0.0:
		return false
	# YA AGARRADO: quieto hasta que llegó a las manos (o al rato), y se para.
	_rise_t += delta
	if not _carried.cone_point(_hands._hold_key()).is_finite() and _rise_t < PICKUP_LIFT_S:
		bi.intent.move = Vector2.ZERO
		return true
	_rise_t = -1.0
	if _pickup_crouched:
		_pickup_crouched = false
		bi.intent.crouch = false
	return false


func _pick_up() -> void:
	if bi.intent.use:
		bi.intent.use = false
		return
	var body := _carried.get_parent() as Node3D
	var origin := bi.get_interaction_origin()
	var point := _carried.get_nearest_grab_point(origin)
	var at := point.global_position if is_instance_valid(point) else body.global_position
	_pickup_at = at
	var rb := bi.char_rigidbody
	var local := rb.global_basis.orthonormalized().inverse() * (at - rb.global_position)
	var flat := Vector2(local.x, local.z)
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
	if not in_reach and not _pickup_crouched and at.y < origin.y - PICKUP_LOW \
			and flat.length() < bi.skel_sizes_util.interaction_reach:
		_pickup_crouched = true
		bi.intent.crouch = true
	var settled := not _pickup_crouched or bi.crouch_t >= 0.99
	bi.intent.sprint = false
	bi.intent.move = flat.normalized() if not in_reach and settled and flat.length() > PICKUP_CLOSE else Vector2.ZERO
	bi.intent.use = aimed


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


static func _grabbable_of(thing: Node) -> GrabbableInteractable:
	if thing is GrabbableInteractable:
		return thing as GrabbableInteractable
	if thing == null:
		return null
	for child in thing.get_children():
		if child is GrabbableInteractable:
			return child as GrabbableInteractable
	return null


## LAS MANOS, armadas la primera vez y vueltas a atar si cambió el cuerpo. Falso si todavía no tiene cuerpo con brazos.
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


## EL OJO: en la cabeza, hacia donde mira su intención, como la cámara del jugador.
func _place_eye() -> void:
	var rb := bi.char_rigidbody
	var forward := Basis(rb.global_basis.x.normalized(), bi.intent.look_pitch) * -rb.global_basis.z.normalized()
	_eye_node.global_transform = Transform3D(Basis.looking_at(forward, rb.global_basis.y.normalized()), _eye())


## ── CADA PASO ──────────────────────────────────────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not is_instance_valid(bi) or not is_instance_valid(bi.char_rigidbody):
		return
	# AL CAERSE SUELTA TODO, como el jugador: lo que llevaba sigue con la velocidad que tenía.
	var fallen := bi._is_ragdolling()
	var hands := _hands_ready()
	if fallen and not _was_fallen:
		drop()
		stop()
		bi.intent.jump = false
		_jump_left = -1.0
		_jump_over = Vector3.INF
		if hands:
			_hands.stop_all()
	_was_fallen = fallen
	if fallen:
		return
	var lifting := hands and _carry_step(delta)
	_throw_step(delta)
	if not lifting:
		_walk()
	_jump_step(delta)
	_look(delta)
	if hands:
		_place_eye()
		_hands.update(delta)
