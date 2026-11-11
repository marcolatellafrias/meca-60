class_name CharacterGetUp
extends Node

## QUE UNA PERSONA DE CHARACTER-PARAMETRIC SE LEVANTE SOLA al caerse. Allá eso lo hace el guion de exhibición
## (`ExhibitOperator.get_up`, la parcela «Levantarse»), que acá no está: es la misma regla, sola. Cuando lo caído quedó
## quieto —su cadera a menos de `REST_SPEED`— el `time_to_standup` de su arquetipo, se levanta con la recuperación de
## siempre (`RagdollUtil.deactivate`).

const REST_SPEED := 0.4

var bi: BoneInstantiator = null
var _rest := 0.0


func _physics_process(delta: float) -> void:
	if not is_instance_valid(bi) or not is_instance_valid(bi.ragdoll_util) or not bi.ragdoll_util.is_active:
		_rest = 0.0
		return
	var hips := bi.ragdoll_util._bodies.get(bi.custom_bones_util.lower_spine) as RigidBody3D
	if not is_instance_valid(hips):
		return
	_rest = _rest + delta if hips.linear_velocity.length() < REST_SPEED else 0.0
	var arch := bi.entity_archetype
	if arch != null and _rest >= arch.time_to_standup:
		_rest = 0.0
		bi.ragdoll_util.deactivate(bi.char_rigidbody, bi.custom_bones_util.lower_spine)
