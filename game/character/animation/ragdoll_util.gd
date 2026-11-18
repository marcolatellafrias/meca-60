class_name RagdollUtil
extends RefCounted

const RAGDOLL_LAYER := 2
const RAGDOLL_MASK  := 1 | PhysicsLayers.FEET
## LA CAPA DE SUS HUESOS Y LO QUE MIRAN: los de siempre, salvo el de exhibición a bordo (ver BoneInstantiator, EL
## RAGDOLL DE EXHIBICIÓN A BORDO), que va en una capa que nadie mira y mira sólo el piso de la cabina y las cajas.
var layer := RAGDOLL_LAYER
var mask := RAGDOLL_MASK

var is_active: bool = false
var is_recovering: bool = false
var recovery_duration: float = 0.8
var debug_ragdoll_color: bool = false

var trip_force_multiplier: float = 1.0
var trip_twist_multiplier: float = 0.5

## (La exageración de la caída es de todos: LocomotionCommon.impact_fall_linear.)

# ── Recuperación (levantarse): ilusión de empujar el cuerpo hacia arriba con las piernas ──────────
## Si true, durante la recuperación las piernas se resuelven por IK (pies plantados en el piso) y la
## pelvis sube de a poco: los pies quedan fijos mientras la cadera sube → las piernas se estiran de
## cuclillas a parado, como si empujaran. El torso para arriba mantiene el blend normal.
var recovery_leg_ik: bool = true
## Altura de la pelvis sobre el piso al ARRANCAR la recuperación (t=0). Bien bajo = arranca agachado.
var recovery_rise_start_height: float = 0.15
## Fracción de la recuperación en la que los pies terminan de plantarse bajo la cadera (0..1).
var recovery_plant_fraction: float = 0.45

var _recovery_timer: float = 0.0
var _skeleton_root: CustomBone = null
var _recovery_start_transforms: Dictionary = {}

var head_body: RigidBody3D = null

var _skel_rb_node: Node3D
var _joints_node: Node3D
var _bones_util: CustomBonesUtil
## Referencia al IkUtil del mismo personaje: la usa el IK de recuperación para tomar el MISMO pole de
## rodilla que la locomoción, y que la pierna no pegue un salto de flexión al terminar de levantarse.
var ik_util: IkUtil = null
var _bodies: Dictionary = {}
var _ragdoll_rids: Array[RID] = []
var _joints: Array[Generic6DOFJoint3D] = []
var _pending_bodies: Array[RigidBody3D] = []
var _char_rid: RID
var _char_rb: CharacterRigidBody3D = null
var _recovering_char_rb: CharacterRigidBody3D = null
var _lower_spine_body: RigidBody3D = null

## POSE RELAJADA: la base global de cada hueso en el REPOSO CONGELADO del personaje (`rest_transform`, ver
## CustomBonesUtil.freeze_rest) —la pose en la que se para, con los brazos abajo—, compuesta por la cadena.
##
## Los resortes de las juntas tiran hacia acá. Antes se leía `bone.rest_rotation`, y eso se rompió en
## silencio cuando el reposo pasó a salir del modelo: el rest del brazo es la T-pose, así que al
## ragdollear los brazos se abrían en cruz — `rest_rotation` contesta "cuáles son los ejes de este hueso",
## no "qué pose sostiene el personaje". Después fue una FOTO de `global_transform` al crear el ragdoll, que
## llegó a derivar 8,9° entre respawns mientras el reposo del brazo heredaba historia; derivada del reposo
## congelado no depende de qué pase entre `freeze_rest()` y esta llamada. Al cambiarla (11/10/2026) se
## midió que da lo mismo que la foto: ≤0,04°, el ruido de la medida. Ver character-parametric:docs/technical/character-animation.md.
var _relaxed_basis: Dictionary = {}

var _parent_bone: Dictionary = {}
var _ordered_bones: Array[CustomBone] = []

var _momentum_dir: Vector3 = Vector3.ZERO

static func create(bones_util: CustomBonesUtil, skel_rb_node: Node3D, joints_node: Node3D) -> RagdollUtil:
	var ru := RagdollUtil.new()
	ru._skel_rb_node = skel_rb_node
	ru._joints_node  = joints_node
	ru._bones_util   = bones_util
	ru._build_bodies(bones_util)
	ru._set_in_world(false)
	return ru


## ── DE PIE, LOS HUESOS NO ESTÁN EN LA FÍSICA (17/11/2026) ─────────────────────────────────────────────────────────
## Los cuerpos existen siempre (la red, el dibujo y el levantarse los leen), pero sólo entran a la física al tumbarlo
## (`activate`) y salen al terminar de levantarse (`_finish_recovery`): de pie no hacen nada y el motor los recorría en
## cada paso —con la fila Locomoción entera, 846 cuerpos, unos 13 ms por cuadro—. Fuera de la física quiere decir
## apagados (un cuerpo apagado sale del mundo de física; ver CollisionObject3D.disable_mode).
func _set_in_world(on: bool) -> void:
	for body: RigidBody3D in _bodies.values():
		if is_instance_valid(body):
			body.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED

func _build_bodies(bu: CustomBonesUtil) -> void:
	var all_bones: Array = [
		bu.lower_spine, bu.higher_spine, bu.chest,
		bu.left_hip, bu.right_hip,
		bu.left_higher_leg, bu.left_lower_leg,
		bu.right_higher_leg, bu.right_lower_leg,
		bu.right_foot, bu.left_foot,
		bu.neck, bu.head,
		bu.left_shoulder, bu.right_shoulder,
		bu.right_upper_arm, bu.right_lower_arm,
		bu.left_upper_arm, bu.left_lower_arm,
	]
	for bone in all_bones:
		if not is_instance_valid(bone):
			continue
		_relaxed_basis[bone] = _rest_global_basis(bone)
		var rb := _make_body(bone)
		_bodies[bone] = rb
		_skel_rb_node.add_child(rb)
		_ragdoll_rids.append(rb.get_rid())

	_lower_spine_body = _bodies.get(bu.lower_spine, null)
	head_body         = _bodies.get(bu.head, null)

## La base global de un hueso en el reposo congelado: la de su padre en reposo por su `rest_transform`. La
## raíz cuelga de un nodo que no es hueso, y ahí vale su base de ahora (las juntas usan bases RELATIVAS,
## así que dónde esté parado el personaje se cancela). Un rig sin congelar (`rest_length` en 0) no tiene
## reposo que leer, y se queda con la foto.
func _rest_global_basis(bone: CustomBone) -> Basis:
	if bone.rest_length <= 0.0:
		return bone.global_transform.basis
	var parent := bone.get_parent() as Node3D
	var up := Basis.IDENTITY
	if parent is CustomBone:
		var pb := parent as CustomBone
		up = (_relaxed_basis[pb] as Basis) if _relaxed_basis.has(pb) else _rest_global_basis(pb)
	elif parent != null:
		up = parent.global_transform.basis
	return up * bone.rest_transform.basis

func _make_body(bone: CustomBone) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.freeze_mode     = RigidBody3D.FREEZE_MODE_KINEMATIC
	rb.freeze          = true
	rb.collision_layer = layer
	rb.collision_mask  = mask
	rb.can_sleep       = false
	rb.mass            = 1.0
	rb.linear_damp     = 0.5
	rb.angular_damp    = 1.0
	rb.global_transform = bone.global_transform

	var d := bone.capsule_dimensions
	var caps := CapsuleShape3D.new()
	caps.radius = min(d.x, d.z) * 0.5  # el ancho de su caja o su miembro (ver SkeletonSizesUtil, LOS HUESOS)
	caps.height = max(d.y, caps.radius * 2.1)

	var shape := CollisionShape3D.new()
	shape.shape    = caps
	shape.position = Vector3(0.0, d.y * 0.5, 0.0)
	rb.add_child(shape)

	return rb

func _build_joints() -> void:
	# Primero, SIEMPRE: poner los cuerpos en los huesos. Cada joint captura la posición relativa de su
	# par de huesos en ESTE instante y la fija rígido, así que los cuerpos tienen que reflejar la pose
	# actual del esqueleto antes de armarlas. En un proxy el solve corre a media tasa (los cuerpos van
	# 1-2 frames atrás de los huesos), y sin este sync la junta congelaría el brazo/pie en su lugar viejo
	# → pegado pero corrido del hombro/tobillo. Al ser la primera línea, armar juntas desde una pose vieja
	# es imposible por construcción. Ver character-parametric:docs/technical/character-animation.md (solve a media tasa).
	sync_to_bones()
	_parent_bone.clear()
	var bu := _bones_util

	var pairs: Array = [
		[bu.lower_spine,  bu.higher_spine,     55.0, 6.0, -20.0, 20.0, -30.0, 30.0, -20.0, 20.0],
		[bu.higher_spine,  bu.chest,           50.0, 6.0, -20.0, 20.0, -25.0, 25.0, -20.0, 20.0],
		[bu.lower_spine,  bu.left_hip,        40.0, 5.0, -30.0, 30.0, -40.0, 40.0, -30.0, 30.0],
		[bu.lower_spine,  bu.right_hip,       40.0, 5.0, -30.0, 30.0, -40.0, 40.0, -30.0, 30.0],
		[bu.left_hip,     bu.left_higher_leg,  35.0, 5.0, -40.0, 40.0, -80.0, 40.0, -30.0, 30.0],
		[bu.right_hip,    bu.right_higher_leg, 35.0, 5.0, -40.0, 40.0, -80.0, 40.0, -30.0, 30.0],
		[bu.left_higher_leg,  bu.left_lower_leg,  25.0, 4.0, -10.0, 10.0,   0.0, 130.0, -10.0, 10.0],
		[bu.right_higher_leg, bu.right_lower_leg, 25.0, 4.0, -10.0, 10.0,   0.0, 130.0, -10.0, 10.0],
		[bu.left_lower_leg,  bu.left_foot,  10.0, 3.0, -20.0, 20.0, -30.0, 30.0, -15.0, 15.0],
		[bu.right_lower_leg, bu.right_foot, 10.0, 3.0, -20.0, 20.0, -30.0, 30.0, -15.0, 15.0],
		[bu.chest, bu.left_shoulder,  35.0, 5.0, -50.0, 50.0, -60.0, 60.0, -40.0, 40.0],
		[bu.chest, bu.right_shoulder, 35.0, 5.0, -50.0, 50.0, -60.0, 60.0, -40.0, 40.0],
		[bu.left_shoulder,  bu.left_upper_arm,  25.0, 4.0, -70.0, 70.0, -70.0, 70.0, -70.0, 70.0],
		[bu.right_shoulder, bu.right_upper_arm, 25.0, 4.0, -70.0, 70.0, -70.0, 70.0, -70.0, 70.0],
		[bu.left_upper_arm,  bu.left_lower_arm,  15.0, 3.0, -10.0, 10.0,   0.0, 140.0, -10.0, 10.0],
		[bu.right_upper_arm, bu.right_lower_arm, 15.0, 3.0, -10.0, 10.0,   0.0, 140.0, -10.0, 10.0],
	]

	if is_instance_valid(bu.neck):
		pairs.append([bu.chest, bu.neck, 50.0, 6.0, -35.0, 35.0, -40.0, 40.0, -30.0, 30.0])
		pairs.append([bu.neck,  bu.head, 45.0, 6.0, -25.0, 25.0, -30.0, 30.0, -20.0, 20.0])
	else:
		pairs.append([bu.chest, bu.head, 45.0, 6.0, -35.0, 35.0, -40.0, 40.0, -30.0, 30.0])

	for pair in pairs:
		var pa: CustomBone = pair[0]
		var ch: CustomBone = pair[1]
		if not is_instance_valid(pa) or not is_instance_valid(ch):
			continue
		if not _bodies.has(pa) or not _bodies.has(ch):
			continue
		_parent_bone[ch] = pa
		_create_joint(
			_bodies[pa], _bodies[ch], ch.global_position, pa, ch,
			pair[2], pair[3],
			deg_to_rad(pair[4]), deg_to_rad(pair[5]),
			deg_to_rad(pair[6]), deg_to_rad(pair[7]),
			deg_to_rad(pair[8]), deg_to_rad(pair[9])
		)

func _create_joint(
		body_a: RigidBody3D, body_b: RigidBody3D, anchor: Vector3,
		bone_a: CustomBone, bone_b: CustomBone,
		stiffness: float, damping: float,
		xl: float, xh: float,
		yl: float, yh: float,
		zl: float, zh: float) -> void:

	var j := Generic6DOFJoint3D.new()
	_joints_node.add_child(j)
	j.global_position = anchor
	j.node_a = j.get_path_to(body_a)
	j.node_b = j.get_path_to(body_b)

	var LL   := Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT
	var LU   := Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT
	var AL   := Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT
	var AU   := Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT
	var LF   := Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT
	var AF   := Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT
	var ASF  := Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING
	var ASST := Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS
	var ASSD := Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING
	var AEQ  := Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT

	j.set_flag_x(LF, true); j.set_flag_y(LF, true); j.set_flag_z(LF, true)
	j.set_param_x(LL, 0.0); j.set_param_x(LU, 0.0)
	j.set_param_y(LL, 0.0); j.set_param_y(LU, 0.0)
	j.set_param_z(LL, 0.0); j.set_param_z(LU, 0.0)

	j.set_flag_x(AF, true); j.set_flag_y(AF, true); j.set_flag_z(AF, true)
	j.set_param_x(AL, xl); j.set_param_x(AU, xh)
	j.set_param_y(AL, yl); j.set_param_y(AU, yh)
	j.set_param_z(AL, zl); j.set_param_z(AU, zh)

	var relaxed_a: Basis = _relaxed_basis.get(bone_a, Basis.from_euler(bone_a.rest_rotation))
	var relaxed_b: Basis = _relaxed_basis.get(bone_b, Basis.from_euler(bone_b.rest_rotation))
	var rest_relative := relaxed_a.inverse() * relaxed_b
	var anim_relative := body_a.global_basis.inverse() * body_b.global_basis
	var offset_quat   := anim_relative.get_rotation_quaternion().inverse() \
						* rest_relative.get_rotation_quaternion()
	var offset_euler  := offset_quat.get_euler()

	j.set_flag_x(ASF, true); j.set_flag_y(ASF, true); j.set_flag_z(ASF, true)
	j.set_param_x(ASST, stiffness); j.set_param_y(ASST, stiffness); j.set_param_z(ASST, stiffness)
	j.set_param_x(ASSD, damping);   j.set_param_y(ASSD, damping);   j.set_param_z(ASSD, damping)
	j.set_param_x(AEQ, offset_euler.x)
	j.set_param_y(AEQ, offset_euler.y)
	j.set_param_z(AEQ, offset_euler.z)

	_joints.append(j)

func sync_to_bones() -> void:
	for bone in _bodies:
		var rb: RigidBody3D = _bodies[bone]
		if is_instance_valid(rb) and is_instance_valid(bone):
			rb.global_transform = bone.global_transform

# Camera is no longer managed here — PlayerController owns it entirely.
## Prende el ragdoll desde la pose de ahora, con la velocidad de la cápsula. `trip`: con el tropezón de la caída a mano
## (la G), que tira el torso para adelante y las piernas para atrás; la caída por un golpe no lo lleva (ver
## `activate_with_impact`).
func activate(char_rb: CharacterRigidBody3D, skeleton_root: CustomBone, trip := true) -> void:
	if is_recovering:
		is_recovering       = false
		_recovery_timer     = 0.0
		_recovering_char_rb = null
		_recovery_start_transforms.clear()

	_set_in_world(true)
	is_active      = true
	_char_rid      = char_rb.get_rid()
	_char_rb       = char_rb
	_skeleton_root = skeleton_root

	char_rb.input_enabled     = false
	char_rb.collider.disabled = true
	char_rb.freeze_mode       = RigidBody3D.FREEZE_MODE_STATIC
	char_rb.freeze            = true

	if is_instance_valid(skeleton_root):
		skeleton_root.visible = false

	_set_meshes_visible(true)
	_build_joints()  # arma las juntas desde la pose actual (sync_to_bones corre adentro, primera línea)

	var space: PhysicsDirectSpaceState3D = _skel_rb_node.get_world_3d().direct_space_state
	var exclude: Array[RID]              = _make_exclude()
	_pending_bodies.clear()

	for bone: CustomBone in _bodies:
		var rb: RigidBody3D = _bodies[bone]
		if not is_instance_valid(rb):
			continue
		rb.collision_layer  = layer
		rb.collision_mask   = mask
		rb.linear_velocity  = char_rb.linear_velocity
		rb.angular_velocity = Vector3.ZERO
		rb.freeze           = false

		if _is_overlapping(rb, space, exclude):
			rb.collision_layer = 0
			rb.collision_mask  = 0
			if debug_ragdoll_color:
				_set_body_mesh_color(rb, Color.RED)
			else:
				_clear_body_mesh_color(rb)
			_pending_bodies.append(rb)
		else:
			if debug_ragdoll_color:
				_set_body_mesh_color(rb, Color.GREEN)
			else:
				_clear_body_mesh_color(rb)

	if trip and is_instance_valid(_lower_spine_body):
		var vel: Vector3     = char_rb.get_motion_velocity()  # contra su marco
		var speed: float     = max(vel.length(), 3.0)
		# Dirección de la caída. Si venimos de un impacto/empujón, _momentum_dir ya trae la dirección
		# real (la del empujón) — es más confiable que linear_velocity, que a veces todavía no integró
		# el impulso y deja al personaje cayendo hacia su propio frente (o en el lugar). Sin impacto
		# (ragdoll manual con G), _momentum_dir está en cero → usamos velocidad o el frente.
		var forward: Vector3
		if _momentum_dir.length() > 0.01:
			forward = _momentum_dir.normalized()
		elif vel.length() > 0.1:
			forward = vel.normalized()
		else:
			forward = -char_rb.global_basis.z

		var base_y: float = _lower_spine_body.global_position.y
		var top_y: float  = head_body.global_position.y if is_instance_valid(head_body) else base_y + 1.5

		var upper_bones: Array = [
			_bodies.get(_bones_util.lower_spine,    null),
			_bodies.get(_bones_util.higher_spine,    null),
			_bodies.get(_bones_util.chest,          null),
			_bodies.get(_bones_util.left_shoulder,  null),
			_bodies.get(_bones_util.right_shoulder, null),
			_bodies.get(_bones_util.left_upper_arm, null),
			_bodies.get(_bones_util.right_upper_arm,null),
			_bodies.get(_bones_util.neck,           null),
			_bodies.get(_bones_util.head,           null),
		]

		for rb: RigidBody3D in upper_bones:
			if not is_instance_valid(rb):
				continue
			var height_t: float  = clamp((rb.global_position.y - base_y) / max(top_y - base_y, 0.001), 0.0, 1.0)
			var impulse: Vector3 = (forward + Vector3.UP * height_t * 0.5).normalized() * speed * trip_force_multiplier * (0.3 + height_t * 0.7)
			rb.linear_velocity += impulse / rb.mass  # velocidad, no impulso: ver `activate_with_impact`

		var lower_bones: Array = [
			_bodies.get(_bones_util.left_hip,         null),
			_bodies.get(_bones_util.right_hip,        null),
			_bodies.get(_bones_util.left_higher_leg,   null),
			_bodies.get(_bones_util.right_higher_leg,  null),
			_bodies.get(_bones_util.left_lower_leg,   null),
			_bodies.get(_bones_util.right_lower_leg,  null),
		]

		for rb: RigidBody3D in lower_bones:
			if not is_instance_valid(rb):
				continue
			var height_t: float  = clamp((rb.global_position.y - base_y) / max(top_y - base_y, 0.001), 0.0, 1.0)
			var impulse: Vector3 = (-forward - Vector3.UP * 0.3).normalized() * speed * trip_force_multiplier * (0.3 + (1.0 - height_t) * 0.7)
			rb.linear_velocity += impulse / rb.mass  # velocidad, no impulso: ver `activate_with_impact`

		var trip_axis: Vector3   = forward.cross(Vector3.UP).normalized()
		var trip_torque: Vector3 = trip_axis * speed * trip_twist_multiplier
		_lower_spine_body.apply_torque_impulse(trip_torque)

	follow_frame(char_rb.frame)


## ── TIRADO, EN EL MARCO DEL PERSONAJE (03/11/2026, ver MotionFrame) ─────────────────────────────────────────────────
## Mientras está activo, sus huesos van en el marco del personaje —la cápsula va con la pelvis, así que el marco sale de
## ahí, y cambia con él (ver BoneInstantiator)—, SIN INERCIA: la meca los lleva enteros, y sólo los mueve su caída —el
## empujón del golpe, ver `activate_with_impact`— y lo que chocan (el usuario, 03/11/2026). No son sólidos para
## los demás de adentro. Afuera, como siempre. Se sale antes de apagarlo, así lo que el marco les cambió a las capas no
## pisa lo de la recuperación.
var _frame: MotionFrame = null


func follow_frame(frame: MotionFrame) -> void:
	if frame == _frame:
		return
	for body: RigidBody3D in _bodies.values():
		if not is_instance_valid(body):
			continue
		if is_instance_valid(_frame):
			_frame.leave(body)
		if is_instance_valid(frame):
			frame.join(body, 0.0, false, true)  # sin inercia, y un choque de la meca no se los lleva: siguen solos
	_frame = frame

## ── TIRAR AL PISO, LA ENTRADA DE TODOS (04/11/2026, el usuario: «una API de ragdoll bastante sólida y simple,
## así después puedo probar con estas cosas más tarde») ──────────────────────────────────────────────────────────────
## Arma el ragdoll —los huesos con la velocidad que traía la cápsula, ver `activate`—, le suma `push` (m/s, a todo el
## cuerpo) y lo hace girar entero a `spin` (rad/s, en el mundo: cada hueso con la velocidad de ese giro en su punto,
## alrededor de la cadera). Es por donde entran el golpe (`activate_with_impact`) y el ragdoll en el aire (ver
## AirStyle); lo que venga después —con qué se tira, cómo se resisten las juntas— se prueba acá.
func knock_down(char_rb: CharacterRigidBody3D, skeleton_root: CustomBone, push := Vector3.ZERO, spin := Vector3.ZERO) -> void:
	activate(char_rb, skeleton_root, false)
	var center := _lower_spine_body.global_position if is_instance_valid(_lower_spine_body) else char_rb.global_position
	for bone: CustomBone in _bodies:
		var rb: RigidBody3D = _bodies[bone]
		if not is_instance_valid(rb):
			continue
		# LA VELOCIDAD, ESCRITA, no un impulso: un cuerpo recién descongelado en este paso perdía el impulso.
		rb.linear_velocity += push + spin.cross(rb.global_position - center)
		rb.angular_velocity = spin


func activate_with_impact(
	char_rb: CharacterRigidBody3D,
	skeleton_root: CustomBone,
	world_dir: Vector3
) -> void:
	# ── LA CAÍDA, UNA REGLA (03/11/2026, el usuario) ──────────────────────────────────────────────────────────
	# AL CAER, EL CUERPO SALE CON LA VELOCIDAD QUE TRAÍA CONTRA LO QUE LO SOSTIENE, MÁS EL EMPUJÓN QUE RECIBIÓ (en m/s),
	# sin casos especiales —el empujón que le cambió la velocidad ya viene en ella; el de un choque de la meca, que no,
	# en CharacterRigidBody3D._last_push—: el nene que empuja el gordo sale con el empujón; el que corre
	# y se pega en la cabeza sigue adelante por su velocidad; el del choque de la meca sale hacia la trompa. Los huesos
	# arrancan con la velocidad de la cápsula (ver `activate`), que adentro de la meca ya es la de la meca más la suya; acá
	# se les suma el empujón, por la exageración (`impact_fall_linear`). Sin el tropezón de la caída a mano.
	# *Hasta el 03/11/2026: el máximo entre la velocidad y la inclinación del golpe ×2, que no es una velocidad, más un
	# tropezón de al menos 3 m/s.*
	_momentum_dir = world_dir
	var push := char_rb._last_push * LocomotionCommon.base().impact_fall_linear
	char_rb._last_push = Vector3.ZERO
	knock_down(char_rb, skeleton_root, push)


func deactivate(char_rb: CharacterRigidBody3D, skeleton_root: CustomBone) -> void:
	follow_frame(null)
	is_active            = false
	is_recovering        = true
	_recovery_timer      = recovery_duration
	_skeleton_root       = skeleton_root
	_char_rb             = null
	_recovering_char_rb  = char_rb
	_pending_bodies.clear()
	_clear_joints()

	_recovery_start_transforms.clear()
	for bone: CustomBone in _bodies:
		var rb: RigidBody3D = _bodies[bone]
		if is_instance_valid(rb):
			_recovery_start_transforms[bone] = rb.global_transform
			rb.freeze          = true
			rb.collision_layer = 0
			rb.collision_mask  = 0

	_ordered_bones.clear()
	var root_bone: CustomBone = _bones_util.lower_spine
	var queue: Array[CustomBone] = [root_bone]
	var visited: Dictionary = {}
	while not queue.is_empty():
		var current: CustomBone = queue.pop_front()
		if visited.has(current):
			continue
		visited[current] = true
		_ordered_bones.append(current)
		for child_bone: CustomBone in _parent_bone:
			if _parent_bone[child_bone] == current and _bodies.has(child_bone):
				queue.append(child_bone)

	# Te parás donde quedó tu cuerpo, apoyando los pies en el piso (ground-snap en el XZ de la pelvis).
	# La cápsula queda CONGELADA (estática, como en el ragdoll) durante toda la recuperación: antes se
	# descongelaba acá y, si el ground-snap fallaba, Jolt la eyectaba por el aire → ese impacto
	# re-disparaba el ragdoll a mitad de recuperación y los huesos quedaban desarmados. Frozen no se
	# puede eyectar; el esqueleto (hijo de la cápsula) queda quieto y el blend converge limpio. La
	# descongela _finish_recovery al terminar. Ver character-parametric:docs/technical/characters.md.
	if is_instance_valid(_lower_spine_body):
		char_rb.snap_feet_to_ground(_lower_spine_body.global_position, _ragdoll_rids)
	char_rb.linear_velocity   = Vector3.ZERO
	char_rb.angular_velocity  = Vector3.ZERO
	char_rb.collider.disabled = false
	char_rb.input_enabled     = false
	_momentum_dir             = Vector3.ZERO  # el próximo ragdoll (p.ej. manual) arranca sin dirección heredada

	if is_instance_valid(_skeleton_root):
		_skeleton_root.visible = false

## Semilla de velocidad para el ragdoll PROXY: arrancar con el momento del dueño (su velocidad de
## caída), si no el proxy cae de CERO (cápsula puppet congelada) mientras el dueño sale volando →
## el ragdoll queda "offseteado" del lugar donde debería. Los huesos siguen conectados; sólo iguala
## el impulso inicial. Ver character-parametric:docs/technical/characters.md.
func seed_velocity(vel: Vector3) -> void:
	for bone in _bodies:
		var rb: RigidBody3D = _bodies[bone]
		if is_instance_valid(rb):
			rb.linear_velocity = vel

## Encendido del ragdoll en un PROXY: una sola entrada que lo deja listo para que la red lo maneje.
## Orienta el esqueleto al yaw AUTORITATIVO (el de la pelvis del dueño, `pelvis_world_rot`) ANTES de
## armarlo: el ragdoll se arma desde la pose local (los huesos cuelgan de la cápsula) y en el flanco la
## cápsula del proxy trae yaw≈0 (el dueño manda rb.rotation.y≈0 al ragdollear), así que sin esto se
## armaría mirando al norte y la pelvis kinemática pegaría un giro instantáneo a la dirección real.
## Después siembra el momento del dueño y fija la pelvis kinemática (la maneja la red; el resto simula
## local). El yaw del ragdoll sale SIEMPRE de acá, nunca de la cápsula del proxy. Ver characters.md.
func activate_as_proxy(char_rb: CharacterRigidBody3D, skeleton_root: CustomBone,
		pelvis_world_rot: Quaternion, seed_vel: Vector3) -> void:
	char_rb.rotation.y = Basis(pelvis_world_rot).get_euler().y
	activate(char_rb, skeleton_root)
	seed_velocity(seed_vel)
	set_pelvis_kinematic(true)

## Apagado del ragdoll en un PROXY: arranca la recuperación local y restaura el estado puppet
## (deactivate des-congela la cápsula; el proxy tiene que volver a ser kinemático sin gravedad).
func deactivate_as_proxy(char_rb: CharacterRigidBody3D, skeleton_root: CustomBone) -> void:
	deactivate(char_rb, skeleton_root)
	char_rb._freeze_for_driver()

# ── Replicación proxy: raíz sincronizada, resto local ─────────────────────────
## En el PROXY la pelvis (raíz) es KINEMÁTICA: la maneja la red. Los demás cuerpos quedan dinámicos y
## simulan LOCAL colgados de ella por las joints. La pelvis kinemática es un ancla de masa infinita:
## se mueve donde se le dice y, al moverse suave (interp), arrastra a las caderas por las joints sin
## reventarlas (siempre que las joints se hayan armado bien — ver el sync_to_bones antes de _build_joints).
## La rotación que manejamos es la AUTORITATIVA del dueño (world_rot = s["ragdoll_rot"]), directa y absoluta.
## Para que el arranque sea seamless, el proxy orienta su esqueleto a ese mismo yaw ANTES de activate
## (ver CharacterNetSync._drive_proxy_ragdoll): así la pose con la que se arman las joints ya mira igual
## que el dueño y no hay giro instantáneo. (La cápsula del proxy no es fuente confiable de yaw en el
## flanco del ragdoll — el dueño manda yaw≈0 ahí —, por eso el ragdoll se orienta desde ragdoll_rot.)

func set_pelvis_kinematic(enabled: bool) -> void:
	if not is_instance_valid(_lower_spine_body):
		return
	_lower_spine_body.freeze = enabled  # freeze_mode ya es KINEMATIC (de _make_body); activate lo puso dynamic

## Rotación actual de la pelvis (para que el dueño la sincronice). La POSICIÓN ya viaja como la cápsula
## (que en ragdoll sigue a la pelvis via _update_active).
func pelvis_rotation() -> Quaternion:
	if is_instance_valid(_lower_spine_body):
		return _lower_spine_body.global_transform.basis.get_rotation_quaternion()
	return Quaternion.IDENTITY

## Proxy: pone la pelvis kinemática en la posición y rotación autoritativas del dueño (directo, sin offset).
func drive_pelvis_to(world_pos: Vector3, world_rot: Quaternion) -> void:
	if not is_instance_valid(_lower_spine_body):
		return
	_lower_spine_body.global_transform = Transform3D(Basis(world_rot), world_pos)

func update(delta: float) -> void:
	if is_active:
		_update_active(delta)
	elif is_recovering:
		_update_recovery(delta)
	if debug_ragdoll_color:
		_show_collision_state()


## ── LOS HUESOS, EN VERDE O ROJO (03/11/2026, lo pidió el usuario) ────────────────────────────────────────────
## Con `debug_ragdoll_color`, cada cuerpo del ragdoll se ve —a través del cuerpo dibujado, medio transparente— en VERDE si
## su colisión está prendida y en ROJO si está apagada: al caer, el hueso que nace adentro de otra superficie espera sin
## chocar hasta salir (`_pending_bodies`), y en la recuperación están todos sin chocar. Siempre, no sólo tirado.
const DEBUG_ON := Color(0.15, 0.9, 0.25, 0.55)
const DEBUG_OFF := Color(0.95, 0.15, 0.1, 0.55)
static var _debug_on_mat: StandardMaterial3D = null
static var _debug_off_mat: StandardMaterial3D = null


## Los cuerpos no tienen malla: cada uno lleva, sólo con la vista prendida, una cápsula del tamaño de su forma de choque.
const DEBUG_MESH := "ChoqueDelHueso"


func _show_collision_state() -> void:
	for bone in _bodies:
		var rb: RigidBody3D = _bodies[bone]
		if not is_instance_valid(rb):
			continue
		var view := rb.get_node_or_null(DEBUG_MESH) as MeshInstance3D
		if view == null:
			view = _debug_mesh_for(rb)
			if view == null:
				continue
		var mat := _debug_material(rb.collision_layer != 0 and rb.collision_mask != 0)
		view.visible = true
		if view.material_override != mat:
			view.material_override = mat


static func _debug_mesh_for(rb: RigidBody3D) -> MeshInstance3D:
	for child in rb.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is CapsuleShape3D:
			var caps := (child as CollisionShape3D).shape as CapsuleShape3D
			var mesh := CapsuleMesh.new()
			mesh.radius = caps.radius
			mesh.height = caps.height
			mesh.radial_segments = 12
			mesh.rings = 4
			var view := MeshInstance3D.new()
			view.name = DEBUG_MESH
			view.mesh = mesh
			view.transform = (child as CollisionShape3D).transform
			view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			rb.add_child(view)
			return view
	return null


static func _debug_material(on: bool) -> StandardMaterial3D:
	if _debug_on_mat == null:
		for pair in [[true, DEBUG_ON], [false, DEBUG_OFF]]:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = pair[1]
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.no_depth_test = true
			if pair[0]:
				_debug_on_mat = mat
			else:
				_debug_off_mat = mat
	return _debug_on_mat if on else _debug_off_mat


## Apagado el modo, los cuerpos vuelven a su color y a esconderse si los dibuja el cuerpo (ver `show_bodies`).
func clear_debug_colors() -> void:
	for bone in _bodies:
		var rb: RigidBody3D = _bodies[bone]
		if is_instance_valid(rb) and rb.has_node(DEBUG_MESH):
			rb.get_node(DEBUG_MESH).queue_free()


func _update_active(_delta: float) -> void:
	if is_instance_valid(_char_rb) and is_instance_valid(_lower_spine_body):
		_char_rb.global_position = _lower_spine_body.global_position

	if _pending_bodies.is_empty():
		return
	var space   := _skel_rb_node.get_world_3d().direct_space_state
	var exclude := _make_exclude()
	var still_pending: Array[RigidBody3D] = []
	for rb in _pending_bodies:
		if not is_instance_valid(rb):
			continue
		if _is_overlapping(rb, space, exclude):
			still_pending.append(rb)
		else:
			rb.collision_layer = layer
			rb.collision_mask  = mask
			if debug_ragdoll_color:
				_set_body_mesh_color(rb, Color.GREEN)
			else:
				_clear_body_mesh_color(rb)
	_pending_bodies = still_pending

## LA MEZCLA DE LA RECUPERACIÓN, SÓLO ROTACIONES: común con la meca (ver RagdollBlend.blend).
static func _blend(from: Basis, to: Basis, t: float) -> Basis:
	return RagdollBlend.blend(from, to, t)


## LA VUELTA: la mezcla de cada cuerpo hacia su hueso es COMÚN con la meca (RagdollBlend, 18/11/2026, módulo Jefes);
## lo de los personajes es lo de arriba (la pelvis que sube desde el piso) y las piernas por IK.
func _update_recovery(delta: float) -> void:
	_recovery_timer -= delta
	var t: float        = 1.0 - clamp(_recovery_timer / recovery_duration, 0.0, 1.0)
	var t_eased: float  = t * t * (3.0 - 2.0 * t)

	var root_bone: CustomBone  = _bones_util.lower_spine
	var root_body: RigidBody3D = _lower_spine_body

	# ¿Podemos hacer el IK de piernas (pies plantados + cadera que sube)? Necesitamos raíz válida y
	# encontrar el piso bajo la pelvis. Si no, caemos al blend uniforme de siempre.
	var do_leg_ik := recovery_leg_ik and is_instance_valid(root_body) and is_instance_valid(root_bone)
	var floor_y := 0.0
	if do_leg_ik:
		var fy := _recovery_floor_y(root_bone.global_position)
		if is_inf(fy):
			do_leg_ik = false
		else:
			floor_y = fy

	if is_instance_valid(root_body) and is_instance_valid(root_bone):
		var start: Transform3D = _recovery_start_transforms.get(root_bone, root_body.global_transform)
		var pos := start.origin.lerp(root_bone.global_position, t_eased)
		if do_leg_ik:
			# La pelvis NO interpola su Y a la pose parado: arranca apenas sobre el piso y sube a su Y
			# final a lo largo de la recuperación. Con los pies plantados, esto estira las piernas.
			var start_y := floor_y + recovery_rise_start_height
			pos.y = lerpf(start_y, root_bone.global_position.y, t_eased)
		RagdollBlend.place_root(root_body, root_bone, start, pos, t_eased)

	for bone: CustomBone in _ordered_bones:
		if bone == root_bone:
			continue
		if do_leg_ik and _is_recovery_leg_bone(bone):
			continue  # las piernas las maneja el IK abajo, no el blend uniforme
		var rb: RigidBody3D = _bodies.get(bone, null)
		if not is_instance_valid(rb) or not is_instance_valid(bone):
			continue

		var parent_bone: CustomBone  = _parent_bone.get(bone, null)
		var parent_rb: RigidBody3D   = _bodies.get(parent_bone, null) if is_instance_valid(parent_bone) else null

		var start: Transform3D = _recovery_start_transforms.get(bone, rb.global_transform)

		if is_instance_valid(parent_rb) and is_instance_valid(parent_bone):
			var parent_start: Transform3D = _recovery_start_transforms.get(parent_bone, parent_rb.global_transform)
			RagdollBlend.place_child(rb, bone, parent_rb, parent_bone, start, parent_start, t_eased)
		else:
			RagdollBlend.place_loose(rb, bone, root_body, root_bone, start, t_eased)

	if do_leg_ik:
		_solve_recovery_leg(true,  root_body, root_bone, floor_y, t)
		_solve_recovery_leg(false, root_body, root_bone, floor_y, t)

	if _recovery_timer <= 0.0:
		_finish_recovery()

## Bones de pierna que resuelve el IK de recuperación (los hips quedan en el blend normal, cerca de
## la pelvis). higher_leg → lower_leg → feet, ambos lados.
func _is_recovery_leg_bone(bone: CustomBone) -> bool:
	return bone == _bones_util.left_higher_leg  or bone == _bones_util.left_lower_leg  or bone == _bones_util.left_foot \
		or bone == _bones_util.right_higher_leg or bone == _bones_util.right_lower_leg or bone == _bones_util.right_foot

## Piso bajo world_pos (raycast hacia abajo, solo mundo). INF si no hay.
func _recovery_floor_y(world_pos: Vector3) -> float:
	if not is_instance_valid(_skel_rb_node):
		return INF
	var from := world_pos + Vector3.UP * 2.0
	var to   := world_pos - Vector3.UP * 3.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 | MotionFrame.LAYER  # mundo y lo del marco (la capa 2 es el propio ragdoll)
	query.exclude = _make_exclude()
	var hit := _skel_rb_node.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return INF
	return (hit["position"] as Vector3).y

## IK de 2 huesos para una pierna durante la recuperación. Ancla la cadera a la pelvis (que sube) y
## planta el pie en el piso; el pie interpola desde donde quedó tirado hasta bajo la cadera al
## principio de la recuperación (para no dar un salto). Misma matemática que IkUtil.solve_two_bone_ik,
## pero aplicada a los CUERPOS del ragdoll (que es lo visible), con la convención cuerpo≡hueso.
func _solve_recovery_leg(left: bool, root_body: RigidBody3D, root_bone: CustomBone, floor_y: float, t: float) -> void:
	var upper_bone: CustomBone = _bones_util.left_higher_leg  if left else _bones_util.right_higher_leg
	var lower_bone: CustomBone = _bones_util.left_lower_leg  if left else _bones_util.right_lower_leg
	var foot_bone:  CustomBone = _bones_util.left_foot if left else _bones_util.right_foot
	var upper_body: RigidBody3D = _bodies.get(upper_bone, null)
	var lower_body: RigidBody3D = _bodies.get(lower_bone, null)
	var foot_body:  RigidBody3D = _bodies.get(foot_bone,  null)
	if not (is_instance_valid(upper_body) and is_instance_valid(lower_body) \
			and is_instance_valid(upper_bone) and is_instance_valid(lower_bone)):
		return

	# Cadera relativa a la pelvis que sube (offset de la pose parada, aplicado sobre el root_body).
	var hip_world := root_body.to_global(root_bone.to_local(upper_bone.global_position))

	# Objetivo del IK: leg.NEXT_target — el punto de piso vivo bajo el stance neutral, recalculado cada
	# frame incluso en recuperación. NO current_target: durante la recuperación (recovery_targets_locked)
	# el sistema de pasos está apagado y current_target queda CONGELADO donde estaba antes de caer (puede
	# quedar a metros → la pierna se estira derecha). next_target sigue vivo bajo la cápsula ya apoyada,
	# así que es el "dónde va el pie parado" correcto. Ver character-parametric:docs/technical/character-animation.md.
	var plant_t: float = smoothstep(0.0, 1.0, clamp(t / max(recovery_plant_fraction, 0.001), 0.0, 1.0))
	var ankle_target := Vector3(hip_world.x, floor_y, hip_world.z)  # fallback: bajo la cadera, en el piso
	if is_instance_valid(ik_util):
		var nt: Node3D = ik_util.left_leg_next_target if left else ik_util.right_leg_next_target
		if is_instance_valid(nt):
			ankle_target = nt.global_position
	elif is_instance_valid(foot_bone):
		ankle_target = foot_bone.global_position
	var foot_world := ankle_target
	if is_instance_valid(foot_body) and is_instance_valid(foot_bone):
		var foot_start := _recovery_start_transforms.get(foot_bone, foot_body.global_transform) as Transform3D
		foot_world = foot_start.origin.lerp(ankle_target, plant_t)

	# IK de 2 huesos (ley de cosenos). El pole (hacia dónde flexiona la rodilla) es el MISMO nodo que
	# usa la locomoción, así la flexión coincide con la pose parada y no hay salto al terminar. Si no
	# hay ik_util, caemos al frente parado.
	var pole_world := hip_world - root_bone.global_transform.basis.z
	if is_instance_valid(ik_util):
		var pole_node: Node3D = ik_util.left_leg_pole if left else ik_util.right_leg_pole
		if is_instance_valid(pole_node):
			pole_world = pole_node.global_position
	var upper_len: float = upper_bone.length
	var lower_len: float = lower_bone.length
	var root_to_target := foot_world - hip_world
	var reach: float = clamp(root_to_target.length(), 0.001, upper_len + lower_len)
	var dir := root_to_target.normalized()
	var right_vec := dir.cross((pole_world - hip_world).normalized())
	if right_vec.length() < 1e-6:
		right_vec = IkUtil.get_orthogonal(dir)
	var bend_plane_normal := right_vec.normalized()
	var pole_on_plane := bend_plane_normal.cross(dir).normalized()
	var cosA: float = clamp((upper_len * upper_len + reach * reach - lower_len * lower_len) / (2.0 * upper_len * reach), -1.0, 1.0)
	var sinA: float = sqrt(max(0.0, 1.0 - cosA * cosA))
	var knee := hip_world + dir * (cosA * upper_len) + pole_on_plane * (sinA * upper_len)

	# Aplicar a los cuerpos (convención cuerpo≡hueso: global_position = junta proximal, base con
	# pose_from_rest_to — igual que solve_two_bone_ik, que usa upper_bone para ambos segmentos).
	upper_body.global_position = hip_world
	upper_body.global_basis    = upper_bone.pose_from_rest_to((knee - hip_world).normalized(), pole_on_plane)
	lower_body.global_position = knee
	lower_body.global_basis    = upper_bone.pose_from_rest_to((foot_world - knee).normalized(), pole_on_plane)
	# El pie va SIEMPRE colgado rígido de la tibia (nunca se interpola su posición suelta → nada de
	# flips). Lo que interpolamos es su ÁNGULO relativo a la tibia: arranca en el que tenía tirado
	# (para no pegar un salto al apretar G) y va al de la pose base (~90°). Al terminar coincide con la
	# pose parada (incluido que "clave" en el piso igual que parado; eso es de la pose base).
	if is_instance_valid(foot_body) and is_instance_valid(foot_bone) and is_instance_valid(lower_bone):
		var rest_foot_local := lower_bone.global_transform.affine_inverse() * foot_bone.global_transform
		var fallen_lower := _recovery_start_transforms.get(lower_bone, lower_body.global_transform) as Transform3D
		var fallen_foot  := _recovery_start_transforms.get(foot_bone,  foot_body.global_transform)  as Transform3D
		var fallen_foot_local := fallen_lower.affine_inverse() * fallen_foot
		var foot_local := fallen_foot_local.interpolate_with(rest_foot_local, plant_t)
		foot_body.global_transform = lower_body.global_transform * foot_local
	elif is_instance_valid(foot_body):
		foot_body.global_position = foot_world
		foot_body.global_basis    = lower_body.global_basis

func _finish_recovery() -> void:
	is_recovering = false
	_recovery_start_transforms.clear()
	_set_meshes_visible(false)
	for bone: CustomBone in _bodies:
		var rb: RigidBody3D = _bodies[bone]
		if is_instance_valid(rb) and is_instance_valid(bone):
			rb.global_transform = bone.global_transform
			rb.collision_layer  = layer
			rb.collision_mask   = mask
	if is_instance_valid(_skeleton_root):
		_skeleton_root.visible = true
	_skeleton_root = null

	if is_instance_valid(_recovering_char_rb):
		_recovering_char_rb.input_enabled = _recovering_char_rb.kind.simulates()
		# Descongelamos ACÁ (no en deactivate): la cápsula estuvo estática toda la recuperación, apoyada
		# en el piso, así no la eyecta la física a mitad de blend. Sólo si se simula (no un proxy, que
		# debe seguir kinemático manejado por la red).
		if _recovering_char_rb.kind.simulates():
			_recovering_char_rb.freeze = false

	_recovering_char_rb = null
	_set_in_world(false)

func cleanup() -> void:
	follow_frame(null)
	is_recovering   = false
	_recovery_timer = 0.0
	_recovery_start_transforms.clear()
	_clear_joints()
	for bone in _bodies:
		var rb: RigidBody3D = _bodies[bone]
		if is_instance_valid(rb):
			rb.queue_free()
	_bodies.clear()
	_relaxed_basis.clear()
	_ragdoll_rids.clear()
	head_body           = null
	_lower_spine_body   = null
	_char_rb            = null
	_recovering_char_rb = null
	_skeleton_root      = null

func _clear_joints() -> void:
	for j in _joints:
		if is_instance_valid(j):
			j.queue_free()
	_joints.clear()

## Los cuerpos del ragdoll (cajas con la forma del hueso) son lo VISIBLE mientras se ragdollea.
## Con un cuerpo visible puesto (ver CharacterBodyVisual) dejan de serlo: se quedan invisibles siempre y
## el cuerpo los lee a ellos, así es lo único que se ve en los dos estados. Lo apaga BoneInstantiator.
var show_bodies: bool = true

## Los RigidBody3D por hueso (CustomBone → RigidBody3D), con la convención cuerpo≡hueso: el transform
## global del cuerpo es el del hueso. Por eso el cuerpo visible puede leerlos en lugar de los huesos.
func get_bodies() -> Dictionary:
	return _bodies

func _set_meshes_visible(value: bool) -> void:
	var visible_value := value and show_bodies
	for bone in _bodies:
		var rb: RigidBody3D = _bodies[bone]
		if not is_instance_valid(rb):
			continue
		for child in rb.get_children():
			if child is MeshInstance3D and child.name != DEBUG_MESH:
				child.visible = visible_value

func _set_body_mesh_color(rb: RigidBody3D, color: Color) -> void:
	for child in rb.get_children():
		if child is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			child.material_override = mat
			break

func _clear_body_mesh_color(rb: RigidBody3D) -> void:
	var original_bone: CustomBone = null
	for bone in _bodies:
		if _bodies[bone] == rb:
			original_bone = bone
			break
	for child in rb.get_children():
		if child is MeshInstance3D:
			if is_instance_valid(original_bone):
				for bone_child in original_bone.get_children():
					if bone_child is MeshInstance3D:
						child.material_override = bone_child.material_override
						break
			else:
				child.material_override = null
			break

func _make_exclude() -> Array[RID]:
	var arr: Array[RID] = []
	for rid in _ragdoll_rids:
		arr.append(rid)
	if _char_rid.is_valid():
		arr.append(_char_rid)
	return arr

func _is_overlapping(rb: RigidBody3D, space: PhysicsDirectSpaceState3D, exclude: Array[RID]) -> bool:
	var shape_node := rb.get_child(0) as CollisionShape3D
	if not shape_node or not shape_node.shape:
		return false
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape          = shape_node.shape
	params.transform      = rb.global_transform * shape_node.transform
	params.exclude        = exclude
	params.collision_mask = mask
	return not space.intersect_shape(params, 1).is_empty()
