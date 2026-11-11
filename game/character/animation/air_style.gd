class_name AirStyle
extends RefCounted

## ── EL RAGDOLL EN EL AIRE (04/11/2026, el dios del juego: «si tu personaje está cayendo desde hace cierto tiempo,
## ragdolea en el aire directamente») ──────────────────────────────────────────────────────────────────────────────
## Cayendo más rápido que `ragdoll_speed` m/s, se tira en el aire —por la velocidad de caída y no por el tiempo, así un
## salto muy alto hacia arriba no lo dispara—, con la velocidad que traía y un giro chico al azar (`RAGDOLL_SPIN`), por
## la entrada de todos (RagdollUtil.knock_down). Los dos números son de todos: LocomotionCommon.ragdoll_in_air y
## `ragdoll_speed`, en la pestaña Equilibrio de la F1 de los experimentos.

const RAGDOLL_SPIN := 1.5


## SI SE TIRA EN EL AIRE: cayendo más rápido que `ragdoll_speed`.
static func should_ragdoll(bi: BoneInstantiator) -> bool:
	var common := LocomotionCommon.base()
	return common.ragdoll_in_air and is_instance_valid(bi.char_rigidbody) and not bi.animation_inputs.grounded \
		and bi.char_rigidbody.linear_velocity.y < -common.ragdoll_speed

