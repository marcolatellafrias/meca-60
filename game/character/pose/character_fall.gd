class_name CharacterFall
extends RefCounted

## CAERSE: el ragdoll —armarlo, tirarse en el aire, el golpe que lo tumba— y que lo lleve el marco. Una pieza de
## BoneInstantiator (ver su comentario): se partió el 13/11/2026; el estado público sigue en el personaje (`bi`).

var bi: BoneInstantiator = null


func _init(owner: BoneInstantiator) -> void:
	bi = owner


## EL RAGDOLL EN EL AIRE (ver AirStyle): cayendo más rápido que lo pedido, se tira en el aire con la velocidad que traía
## y un giro chico al azar, por la entrada de todos (RagdollUtil.knock_down). Sólo quien se simula acá.
func maybe_ragdoll_in_air() -> void:
	if not bi.kind.simulates() or bi.is_seated or not is_instance_valid(bi.ragdoll_util) or bi.ragdoll_util.is_active \
			or bi.ragdoll_util.is_recovering or not AirStyle.should_ragdoll(bi):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = bi.master_seed + Engine.get_physics_frames()
	var axis := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
	var spin := axis.normalized() * AirStyle.RAGDOLL_SPIN if axis.length_squared() > 0.0001 else Vector3.ZERO
	bi.ragdoll_util.knock_down(bi.char_rigidbody, bi.custom_bones_util.lower_spine, Vector3.ZERO, spin)


func on_fall_triggered(world_dir: Vector3) -> void:
	if bi.is_seated:
		return
	if not bi.kind.simulates() and not is_instance_valid(bi.ragdoll_util):
		return
	# No re-disparar si ya estoy ragdolleando NI levantándome: un impacto espurio durante la
	# recuperación (p.ej. la cápsula asentándose) reiniciaría el ragdoll a mitad de camino y dejaría
	# los huesos desarmados. Ver character-parametric:docs/technical/characters.md.
	if not is_instance_valid(bi.ragdoll_util) or bi.ragdoll_util.is_active or bi.ragdoll_util.is_recovering:
		return
	bi.ragdoll_util.activate_with_impact(bi.char_rigidbody, bi.custom_bones_util.lower_spine, world_dir)
	if not bi.kind.simulates():
		# LOS HUESOS ARRANCAN CON LA VELOCIDAD DEL MARCO en su punto, y el golpe encima: la cápsula de quien no se simula
		# está congelada y no tiene velocidad que pasarles, así que arrancaban quietos en el mundo y la meca se les iba
		# —salían volando para atrás, lo vio la meca—.
		var frame := bi.char_rigidbody.frame
		if is_instance_valid(frame):
			for body: RigidBody3D in bi.ragdoll_util._bodies.values():
				if is_instance_valid(body):
					body.linear_velocity += frame.velocity_at(body.global_position)


## LOS 19 CUERPOS DEL RAGDOLL, uno por hueso. VAN EN EL MUNDO, no colgados del personaje: si el personaje cuelga de algo
## que se mueve a mano —la meca de las maquetas—, un cuerpo rígido que cuelga de eso se teletransporta con él en cada
## paso; iba con la meca dos veces —por su velocidad y por el arrastre— y, como un teletransporte no choca, atravesaba el
## piso y las paredes (02/11/2026). Lo lleva el marco (ver RagdollUtil.follow_frame); con la detección continua, rápidos
## y finos no cruzan el piso.
func make_ragdoll() -> void:
	bi.ragdoll_util = RagdollUtil.create(bi.custom_bones_util, bi.skel_rigidbodies, bi.joints)
	bi.ragdoll_util.ik_util = bi.ik_util  # para que el IK de recuperación use el mismo pole que la locomoción
	# Los cuerpos del ragdoll dejan de ser lo visible: quedan invisibles y el cuerpo los sigue vía
	# _sync_body_visual. Solo se muestran si no hay cuerpo que dibujar.
	bi.ragdoll_util.show_bodies = not is_instance_valid(bi.body_visual)
	bi.skel_rigidbodies.top_level = true
	bi.joints.top_level = true
	for body: RigidBody3D in bi.ragdoll_util._bodies.values():
		if is_instance_valid(body):
			body.collision_layer = bi.ragdoll_util.layer
			body.collision_mask = bi.ragdoll_util.mask | SandboxParcel.bound_mask(bi)
			body.continuous_cd = true


## Tirado, el ragdoll va en el marco de la cápsula, que va con la pelvis (ver RagdollUtil.follow_frame).
func follow_ragdoll_frame() -> void:
	if is_instance_valid(bi.ragdoll_util) and bi.ragdoll_util.is_active and is_instance_valid(bi.char_rigidbody):
		bi.ragdoll_util.follow_frame(bi.char_rigidbody.frame)
