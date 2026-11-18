class_name RagdollBlend
extends RefCounted

## ── LA VUELTA DEL RAGDOLL, LA MEZCLA, COMÚN A LOS PERSONAJES Y A LA MECA (18/11/2026; módulo Jefes, con Personajes) ──
## El usuario: «la capacidad de recuperarse… así cuando la queramos usar ya está lista y hay unificación de código».
## Al levantarse, cada pedazo del ragdoll (un cuerpo) va de DONDE QUEDÓ TIRADO a LA POSE ANIMADA DE SU HUESO:
##   · LA RAÍZ (la pelvis de un personaje, el tronco de la meca): su lugar (`position`, que puede decir quien la usa:
##     el personaje la sube desde el piso) y su giro, mezclados.
##   · CADA OTRO HUESO, colgando de su padre: SU GIRO RELATIVO AL PADRE se mezcla (del que tenía tirado al de la pose)
##     y su lugar es el del hueso animado respecto del padre, sobre el cuerpo del padre. Así nunca se separa de él.
##   · LAS ROTACIONES SE MEZCLAN SIN ESCALA (`blend`): de cada base sólo su giro.
## Lo usan RagdollUtil (los personajes: ver _update_recovery, que le suma sus piernas por IK) y PartsRagdoll (la meca).
## *Hasta ese día vivía adentro de RagdollUtil._update_recovery.*


## LA MEZCLA DE DOS GIROS en `t` (0 a 1), tomando de cada base sólo su giro. Las bases que se mezclan son de huesos (que
## pueden traer escala) y de cuerpos compuestos cuadro a cuadro (que se desvían de una rotación pura de a poco);
## `Basis.slerp` exige rotaciones puras y con cualquiera de las dos daba cientos de errores «must be normalized» al
## levantarse. El resultado nunca trae escala ni desvío.
static func blend(from: Basis, to: Basis, t: float) -> Basis:
	return Basis(from.get_rotation_quaternion().slerp(to.get_rotation_quaternion(), t))


## LA RAÍZ: el cuerpo `body` en `position` (la decide quien la usa) y con el giro de `start` (como quedó tirado) mezclado
## hacia el de su hueso `bone` en `t`.
static func place_root(body: Node3D, bone: Node3D, start: Transform3D, position: Vector3, t: float) -> void:
	body.global_position = position
	body.global_basis = blend(start.basis, bone.global_transform.basis, t)


## UN HUESO QUE CUELGA DE OTRO: el cuerpo `body` gira como su hueso `bone` respecto del padre (`parent_bone`, con su
## cuerpo `parent_body`), mezclado en `t` desde como quedó tirado (`start`, y su padre `parent_start`), y va donde está
## el hueso respecto del padre, sobre el cuerpo del padre.
static func place_child(body: Node3D, bone: Node3D, parent_body: Node3D, parent_bone: Node3D, start: Transform3D,
		parent_start: Transform3D, t: float) -> void:
	var local_start_basis: Basis = parent_start.basis.inverse() * start.basis
	var local_target_basis: Basis = parent_bone.global_transform.basis.inverse() * bone.global_transform.basis
	body.global_basis = parent_body.global_basis * blend(local_start_basis, local_target_basis, t)
	var local_anim_pos: Vector3 = parent_bone.to_local(bone.global_position)
	body.global_position = parent_body.to_global(local_anim_pos)


## UN HUESO SIN PADRE CON CUERPO: gira hacia su hueso, mezclado en `t` desde `start`, y va donde está su hueso respecto
## de la raíz, sobre el cuerpo de la raíz (si hay).
static func place_loose(body: Node3D, bone: Node3D, root_body: Node3D, root_bone: Node3D, start: Transform3D,
		t: float) -> void:
	body.global_basis = blend(start.basis, bone.global_transform.basis, t)
	if is_instance_valid(root_body) and is_instance_valid(root_bone):
		var local_anim_pos: Vector3 = root_bone.to_local(bone.global_position)
		body.global_position = root_body.to_global(local_anim_pos)
