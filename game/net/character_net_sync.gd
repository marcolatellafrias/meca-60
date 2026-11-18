class_name CharacterNetSync
extends Node
## Replicación del estado de animación de un personaje (milestones 2/3 de multiplayer).
##
## Se cuelga como hijo "NetSync" del personaje (un BoneInstantiator) tanto en el jugador local como
## en cada proxy remoto, con el MISMO path en todas las máquinas para que el RPC rutee. Su
## multiplayer_authority es el peer dueño:
##   - En la máquina del dueño: lee la cápsula/controllers y transmite el estado cada tick físico.
##   - En las demás: bufferea (con timestamp local) e interpola, y lo aplica a la cápsula puppet.
##
## Manda pos/velocidad (movimiento) + la mirada (rumbo y cabeceo, ver CharacterIntent) + impacto (stagger) +
## crouch/jump/throw (pose).
## Todo lo que el proxy NO puede derivar solo (grounded/pasos SÍ los deriva local). El agarre (brazos
## a handle points) es aparte. Sin MultiplayerSynchronizer: el remoto interpola, no re-simula.
## Ver character-parametric:docs/conceptual/multiplayer.md y character-parametric:docs/technical/character-animation.md.

## Delay de render para la interpolación (mostramos el pasado reciente).
const INTERP_DELAY_MS := 100.0
## Tope de extrapolación cuando el último estado quedó atrás (paquete perdido/tardío).
const MAX_EXTRAPOLATION_S := 0.15
const BUFFER_MAX := 20

## [{t, pos, yaw, vel, impact_xz, impact_y, crouch, jump, throw_t, throw_push, throw_dir, pitch, ragdoll, floor}]
var _buffer: Array = []

## ── A BORDO ──────────────────────────────────────────────────────────────────────────────────────
## Adentro de algo que se mueve —la meca en vuelo, ver MotionFrame y CharacterRigidBody3D, EL MARCO—, la posición y la
## velocidad viajan EN ESE MARCO, y `floor` dice cuál es (`MotionFrame.id`, el mismo en todas las máquinas; 0 es el
## mundo). La mirada viaja siempre en los ejes del marco, como la guarda la intención. El proxy se dibuja
## INTERP_DELAY_MS en el pasado: en el marco del mundo eso, a 18 m/s, lo dejaba casi dos metros atrás de donde va,
## contra la pared del fondo de la meca. En el marco de la meca el pasado es el mismo lugar, y se pasa al mundo con la
## nave como está AHORA en esta máquina (`_to_world`). EL MARCO DE UN PROXY LO DICE SU DUEÑO, no el volumen de esta
## máquina: en el borde, con la histéresis, podrían no coincidir.
var _frames := {}

func _physics_process(_delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return  # offline: el jugador local simula normal, nada que sincronizar.
	# La autoridad transmite acá. Los proxies NO aplican en este _physics_process: como NetSync es
	# hijo del BoneInstantiator, correría DESPUÉS de su solve y los IK targets quedarían un frame
	# atrás del cuerpo (raycasts/brazos desfasados al girar). Por eso el BoneInstantiator llama a
	# apply_to_puppet() al INICIO de su frame, antes del solve.
	if is_multiplayer_authority():
		_send_state()

# ── Authority: transmitir ─────────────────────────────────────────────────────

func _send_state() -> void:
	var args := state_args()
	if not args.is_empty():
		callv("rpc", [&"_receive_state"] + args)

## LO QUE MANDA EL DUEÑO en cada tick, en el orden de `_receive_state`; vacío si la cápsula no existe todavía.
func state_args() -> Array:
	var rb := _rigidbody()
	if not is_instance_valid(rb):
		return []  # entre respawns la cápsula puede no existir por un frame.
	var bi := get_parent() as BoneInstantiator
	var throw_t := 0.0
	var throw_push := 0.0
	var throw_dir := Vector3.FORWARD
	if is_instance_valid(bi.anim_mod):
		throw_t = bi.anim_mod.throw_t
		throw_push = bi.anim_mod.throw_push_t
		throw_dir = bi.anim_mod.throw_world_dir
	var ragdoll := is_instance_valid(bi.ragdoll_util) and bi.ragdoll_util.is_active
	# Rotación de la pelvis (raíz): es la orientación AUTORITATIVA del ragdoll. El proxy la usa para
	# orientar su ragdoll al activarlo (activate_as_proxy) y para manejar la pelvis kinemática cada frame.
	# Se manda SIEMPRE (no sólo en ragdoll) para que el valor sea continuo en el flanco. La posición ya
	# viaja como rb.global_position (la cápsula sigue a la pelvis via _update_active).
	var ragdoll_rot := bi.ragdoll_util.pelvis_rotation() if is_instance_valid(bi.ragdoll_util) else Quaternion.IDENTITY
	var pos := rb.global_position
	var vel := rb.linear_velocity
	var floor_id := 0
	if is_instance_valid(rb.frame):
		var frame := rb.frame.global_transform
		pos = frame.affine_inverse() * pos
		vel = frame.basis.inverse() * (vel - rb.floor_velocity)
		floor_id = rb.frame.id()
	return [pos, bi.intent.look_yaw, vel, rb.impact_xz, rb.impact_y, bi.crouch_t, bi.jump_squat_t, throw_t, throw_push,
		throw_dir, bi.intent.look_pitch, ragdoll, ragdoll_rot, floor_id]

@rpc("authority", "unreliable_ordered", "call_remote")
func _receive_state(pos: Vector3, yaw: float, vel: Vector3, impact_xz: Vector2, impact_y: float,
		crouch: float, jump: float, throw_t: float, throw_push: float, throw_dir: Vector3,
		pitch: float, ragdoll: bool, ragdoll_rot: Quaternion, floor_id: int) -> void:
	_buffer.append({
		"t": Time.get_ticks_msec(), "pos": pos, "yaw": yaw, "vel": vel,
		"impact_xz": impact_xz, "impact_y": impact_y,
		"crouch": crouch, "jump": jump,
		"throw_t": throw_t, "throw_push": throw_push, "throw_dir": throw_dir,
		"pitch": pitch, "ragdoll": ragdoll, "ragdoll_rot": ragdoll_rot, "floor": floor_id})
	while _buffer.size() > BUFFER_MAX:
		_buffer.pop_front()

# ── Remoto: interpolar y aplicar al puppet ────────────────────────────────────

## Aplica el estado sincronizado (transform + pose) a la cápsula puppet. Lo llama el
## BoneInstantiator al INICIO de su _physics_process, ANTES del solve del esqueleto, para que los
## IK targets (raycasts de pies, brazos, poles) se construyan con el yaw de este frame.
func apply_to_puppet() -> void:
	if is_multiplayer_authority():
		return  # el dueño no es puppet
	if not _pending_grab_path.is_empty() or not _pending_seat_path.is_empty():
		_resolve_pending()  # el objeto referenciado pudo llegar recién ahora (join)
	var rb := _rigidbody()
	var bi := get_parent() as BoneInstantiator
	if not is_instance_valid(rb) or not is_instance_valid(bi) or _buffer.is_empty():
		return

	var s := _sample_at(float(Time.get_ticks_msec()) - INTERP_DELAY_MS)

	# Ragdoll: RAÍZ sincronizada, resto local. El proxy corre su propio ragdoll, pero la PELVIS es
	# kinemática y la manejamos a la pose del dueño (posición = s["pos"], rotación = s["ragdoll_rot"]);
	# los demás huesos simulan local colgados de ella. Así el ragdoll queda en el lugar correcto (no
	# deriva) y con los huesos en su sitio. En la recuperación volvemos al transform normal. Ver
	# characters.md (Causa C).
	rb.set_frame(_frame_of(int(_buffer[_buffer.size() - 1]["floor"])))  # el del dueño (ver A BORDO)
	_drive_proxy_ragdoll(bi, rb, s["ragdoll"], s["ragdoll_rot"])
	if is_instance_valid(bi.ragdoll_util) and bi.ragdoll_util.is_active:
		bi.ragdoll_util.drive_pelvis_to(s["pos"], s["ragdoll_rot"])
		return

	rb.global_position = s["pos"]
	bi.intent.look_yaw = s["yaw"]     # el cuerpo la sigue (ver BoneInstantiator._apply_look)
	bi.intent.look_pitch = s["pitch"]
	rb.puppet_velocity = s["vel"]   # alimenta la animación de caminado
	rb.impact_xz = s["impact_xz"]   # stagger de choques/empujes
	rb.impact_synced = true         # con la inercia del marco adentro: no se calcula de nuevo (ver CharacterRigidBody3D)
	rb.impact_y = s["impact_y"]     # stagger de salto/aterrizaje
	bi.crouch_t = s["crouch"]
	bi.jump_squat_t = s["jump"]
	if is_instance_valid(bi.anim_mod):
		bi.anim_mod.throw_t = s["throw_t"]
		bi.anim_mod.throw_push_t = s["throw_push"]
		bi.anim_mod.throw_world_dir = s["throw_dir"]

## Enciende/apaga el ragdoll LOCAL del proxy según el flag sincronizado (en flancos). El proxy no
## detecta impactos (es puppet), así que su ragdoll solo lo dispara esto. La activación y el apagado
## viven encapsulados en RagdollUtil (activate_as_proxy / deactivate_as_proxy): el yaw autoritativo,
## la siembra de momento, la pelvis kinemática y la restauración del puppet se resuelven ahí adentro.
func _drive_proxy_ragdoll(bi: BoneInstantiator, rb: CharacterRigidBody3D, want: bool, ragdoll_rot: Quaternion) -> void:
	var rd := bi.ragdoll_util
	if not is_instance_valid(rd):
		return
	var root := bi.custom_bones_util.lower_spine
	if want and not rd.is_active:
		rd.activate_as_proxy(rb, root, ragdoll_rot, rb.puppet_velocity)
	elif not want and rd.is_active:
		rd.deactivate_as_proxy(rb, root)

## Estado interpolado al tiempo de render (extrapola con la velocidad si va por delante del buffer), en el marco del
## mundo (ver A BORDO): dos estados en el marco del mismo piso se interpolan ahí y después se pasan al mundo; entre
## marcos distintos —al subirse o bajarse—, ya en el mundo.
func _sample_at(render_t: float) -> Dictionary:
	var newest: Dictionary = _buffer[_buffer.size() - 1]
	if render_t >= float(newest["t"]):
		var ahead: float = min((render_t - float(newest["t"])) / 1000.0, MAX_EXTRAPOLATION_S)
		var s := newest.duplicate()
		s["pos"] = (newest["pos"] as Vector3) + (newest["vel"] as Vector3) * ahead
		return _to_world(s)
	var oldest: Dictionary = _buffer[0]
	if render_t <= float(oldest["t"]):
		return _to_world(oldest)
	for i in range(_buffer.size() - 1):
		var a: Dictionary = _buffer[i]
		var b: Dictionary = _buffer[i + 1]
		if render_t >= float(a["t"]) and render_t <= float(b["t"]):
			var span := float(b["t"]) - float(a["t"])
			var f: float = 0.0 if span <= 0.0 else (render_t - float(a["t"])) / span
			if a["floor"] == b["floor"]:
				return _to_world(_lerp_state(a, b, f))
			return _lerp_state(_to_world(a), _to_world(b), f)
	return _to_world(newest)

## UN ESTADO EN EL MARCO DEL MUNDO: si vino en el de algo que se mueve, con eso como está AHORA en esta máquina (ver A
## BORDO). Si el marco no está acá, queda como vino. La mirada no se toca: va siempre en los ejes del marco.
func _to_world(s: Dictionary) -> Dictionary:
	var frame := _frame_of(int(s["floor"]))
	if frame == null:
		return s
	var out := s.duplicate()
	var axes := frame.global_transform
	var pos: Vector3 = axes * (s["pos"] as Vector3)
	out["pos"] = pos
	out["vel"] = axes.basis * (s["vel"] as Vector3) + frame.velocity_at(pos)
	out["floor"] = 0
	return out

## El marco de id `id` en esta máquina (ver MotionFrame.id), o null (el mundo, o uno que todavía no está acá).
func _frame_of(id: int) -> MotionFrame:
	if id == 0:
		return null
	var cached: Variant = _frames.get(id)
	if is_instance_valid(cached):
		return cached as MotionFrame
	var frame := MotionFrame.by_id(id)
	if frame != null:
		_frames[id] = frame
	return frame

func _lerp_state(a: Dictionary, b: Dictionary, f: float) -> Dictionary:
	return {
		"pos": (a["pos"] as Vector3).lerp(b["pos"], f),
		"yaw": lerp_angle(a["yaw"], b["yaw"], f),
		"vel": (a["vel"] as Vector3).lerp(b["vel"], f),
		"impact_xz": (a["impact_xz"] as Vector2).lerp(b["impact_xz"], f),
		"impact_y": lerpf(a["impact_y"], b["impact_y"], f),
		"crouch": lerpf(a["crouch"], b["crouch"], f),
		"jump": lerpf(a["jump"], b["jump"], f),
		"throw_t": lerpf(a["throw_t"], b["throw_t"], f),
		"throw_push": lerpf(a["throw_push"], b["throw_push"], f),
		"throw_dir": (a["throw_dir"] as Vector3).lerp(b["throw_dir"], f),
		"pitch": lerpf(a["pitch"], b["pitch"], f),
		"ragdoll": a["ragdoll"],  # bool: tomamos el del estado más viejo (mismo delay que la posición)
		"ragdoll_rot": (a["ragdoll_rot"] as Quaternion).slerp(b["ragdoll_rot"], f),
		"floor": a["floor"]}

func _rigidbody() -> CharacterRigidBody3D:
	var bi := get_parent() as BoneInstantiator
	return bi.char_rigidbody if is_instance_valid(bi) else null

# ── Agarre: sincronizar qué objeto agarra cada jugador ────────────────────────
# Solo se sincroniza la REFERENCIA al grabbable (mismo path en todas las máquinas). Los brazos a los
# handle points los arma el proxy local con su propio esqueleto. Ver character-animation.md (bug 3).

## Lo que agarra viaja como LA INTENCIÓN (ver CharacterIntent.grab): el dueño la escribe y la manda, y el proxy la recibe
## en la suya. Path pendiente de resolver (proxy): el objeto puede no existir aún al unirse. Vacío = nada pendiente.
var _pending_grab_path: NodePath = NodePath()

## Lo llama el InteractionController local al agarrar/controlar/soltar (el interactuable o null): se lo cuenta a los
## proxies.
func send_grab(grabbable: Node) -> void:
	if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		_receive_grab.rpc(grabbable.get_path() if is_instance_valid(grabbable) else NodePath())

@rpc("authority", "reliable", "call_remote")
func _receive_grab(path: NodePath) -> void:
	_pending_grab_path = path
	_intent().grab = null
	_resolve_pending()  # resuelve ya si el objeto existe; si no, se reintenta cada frame


func _intent() -> CharacterIntent:
	return (get_parent() as BoneInstantiator).intent

# ── Empuje: aplicar un impulso a un compañero (Causa B) ───────────────────────
# La cápsula del compañero es un proxy congelado en MI máquina, así que el impulso se lo mando a SU
# máquina (donde es dinámica y él es la autoridad), que lo aplica y lo replica de vuelta.

## Empujá a este personaje con un impulso. Lo aplica su dueño (autoridad); si no soy yo, se lo mando.
func push(impulse: Vector3) -> void:
	if not multiplayer.has_multiplayer_peer():
		return  # offline solo existe el jugador local; no hay compañero que empujar
	if is_multiplayer_authority():
		_apply_push(impulse)
	else:
		_receive_push.rpc_id(get_multiplayer_authority(), impulse)

@rpc("any_peer", "reliable")
func _receive_push(impulse: Vector3) -> void:
	if is_multiplayer_authority():
		_apply_push(impulse)

func _apply_push(impulse: Vector3) -> void:
	var rb := _rigidbody()
	if not is_instance_valid(rb) or not rb.kind.simulates():
		return
	var bi := get_parent() as BoneInstantiator
	if is_instance_valid(bi) and is_instance_valid(bi.ragdoll_util) \
			and (bi.ragdoll_util.is_active or bi.ragdoll_util.is_recovering):
		return  # no empujar a un jugador ya caído/levantándose
	rb.hit(impulse)  # un golpe con nombre: lo mueve y lo inclina o lo tumba (ver CharacterRigidBody3D.hit)

# ── Sentado: sincronizar en qué asiento está cada jugador ──────────────────────
# Análogo al grab: solo viaja la REFERENCIA al asiento (mismo path en todas las máquinas, spawn con
# nombre estable). El pose sentado lo arma cada proxy corriendo el mismo _solve_frame con su propio
# esqueleto (sentado solo cambia la raíz y las piernas). Ver character-parametric:docs/technical/character-animation.md.

## El asiento viaja como la intención (ver CharacterIntent.seat): el proxy lo recibe en la suya, y su cuerpo se sienta
## (ver BoneInstantiator._follow_seat). Path pendiente de resolver (proxy): el asiento puede no existir aún al unirse.
var _pending_seat_path: NodePath = NodePath()

## Lo llama el SeatInteractable local al sentarse/pararse (el asiento o null): se lo cuenta a los proxies.
func send_seat(seat: Node) -> void:
	if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		_receive_seat.rpc(seat.get_path() if is_instance_valid(seat) else NodePath())

@rpc("authority", "reliable", "call_remote")
func _receive_seat(path: NodePath) -> void:
	_pending_seat_path = path
	_intent().seat = null
	_resolve_pending()  # resuelve ya si el asiento existe; si no, se reintenta cada frame

## Resuelve los paths pendientes de grab/seat. El estado (grab/seat) puede llegar ANTES de que el
## objeto exista acá: al unirse, el snapshot de objetos (NetSpawner) y el estado del personaje son
## async. Reintentamos cada frame hasta que el nodo aparezca, así el orden deja de importar. Lo llama
## apply_to_puppet mientras haya algo pendiente.
func _resolve_pending() -> void:
	if not _pending_grab_path.is_empty():
		var g := get_node_or_null(_pending_grab_path)
		if is_instance_valid(g):
			_intent().grab = g
			_pending_grab_path = NodePath()
	if not _pending_seat_path.is_empty():
		var st := get_node_or_null(_pending_seat_path)
		if is_instance_valid(st):
			_intent().seat = st
			_pending_seat_path = NodePath()

# ── Seed / aspecto: sincronizar el reseed (respawn con P) ──────────────────────
# El aspecto normalmente sale del seed derivado del steam_id (igual en todas las máquinas, sin
# sincronizar). Pero el reseed local rompe ese supuesto, así que el dueño transmite su seed nuevo.

## Dueño: transmite su seed actual a todos. Se llama al reseedear.
func broadcast_seed() -> void:
	if not multiplayer.has_multiplayer_peer() or not is_multiplayer_authority():
		return
	var bi := get_parent() as BoneInstantiator
	if is_instance_valid(bi):
		_receive_seed.rpc(bi.master_seed)

## Proxy: al crear el proxy (join), le pide al dueño su estado actual que no viaja continuo — el seed
## (por si reseedó antes de que me uniera) y las referencias de sentado/grab (por si ya estaba
## sentado o sosteniendo algo). Lo llama el CharacterSpawner. Las refs se resuelven lazy (ver
## _resolve_pending): el objeto referenciado puede llegar después por el snapshot de NetSpawner.
func request_state_if_proxy() -> void:
	if not multiplayer.has_multiplayer_peer() or is_multiplayer_authority():
		return
	_request_seed.rpc_id(get_multiplayer_authority())
	_request_interaction_state.rpc_id(get_multiplayer_authority())

@rpc("any_peer", "reliable")
func _request_interaction_state() -> void:
	if not is_multiplayer_authority():
		return
	var sender := multiplayer.get_remote_sender_id()
	var intent := _intent()
	_receive_grab.rpc_id(sender, intent.grab.get_path() if is_instance_valid(intent.grab) else NodePath())
	_receive_seat.rpc_id(sender, intent.seat.get_path() if is_instance_valid(intent.seat) else NodePath())

@rpc("any_peer", "reliable")
func _request_seed() -> void:
	if not is_multiplayer_authority():
		return
	var bi := get_parent() as BoneInstantiator
	if is_instance_valid(bi):
		_receive_seed.rpc_id(multiplayer.get_remote_sender_id(), bi.master_seed)

## Proxy: recibe el seed del dueño y reconstruye el esqueleto si cambió.
@rpc("authority", "reliable", "call_remote")
func _receive_seed(seed_value: int) -> void:
	var bi := get_parent() as BoneInstantiator
	if not is_instance_valid(bi) or bi.master_seed == seed_value:
		return
	bi.master_seed = seed_value
	bi.initialize_skeleton()  # reconstruye el aspecto; net_sync sobrevive (es hijo directo del bi)
	apply_to_puppet()         # reposiciona la cápsula nueva ya, evita el flash en el origen
	var spawner := get_tree().get_first_node_in_group("character_spawner") as CharacterSpawner
	if is_instance_valid(spawner):
		spawner.reattach_name_tag(bi, get_multiplayer_authority())  # el tag viejo se fue con la cápsula
