extends Node3D

## SENTARSE (ver CharacterSeating): un personaje de la calle se sienta en la silla de las consolas y se para. Imprime si
## quedó sentado, dónde quedaron sus pies respecto de la silla, y si al pararse quedó de pie.

func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(20, 1, 20), Vector3(0, -0.5, 0), Color(0.8, 0.8, 0.8))
	add_child(ground)
	var seat := (load("res://game/interactables/activatable/working_seat.tscn") as PackedScene).instantiate() as Node3D
	add_child(seat)
	var bi := (load("res://game/character/player.tscn") as PackedScene).instantiate() as BoneInstantiator
	bi.kind = CharacterKind.npc()
	bi.master_seed = EntityInstantiation.debug_seed(EntityArchetype.Archetype.fat_athletic, 0)
	add_child(bi)
	bi.place_at(Vector3(0.0, 0.0, 1.5), 0.0)
	await get_tree().create_timer(1.0).timeout
	bi.intent.seat = seat
	bi._follow_seat()
	await get_tree().create_timer(2.0).timeout
	var cb := bi.custom_bones_util
	var to_seat := seat.global_transform.affine_inverse()
	print("SENTADO: %s · pie izq %s · pie der %s · pelvis %s" % [bi.is_seated,
		(to_seat * cb.left_foot.global_position).snapped(Vector3.ONE * 0.01),
		(to_seat * cb.right_foot.global_position).snapped(Vector3.ONE * 0.01),
		(to_seat * cb.lower_spine.global_position).snapped(Vector3.ONE * 0.01)])
	bi.intent.seat = null
	bi._follow_seat()
	await get_tree().create_timer(2.0).timeout
	print("PARADO: sentado %s · de pie %s" % [bi.is_seated, not bi.ragdoll_util.is_active if is_instance_valid(bi.ragdoll_util) else true])
	get_tree().quit()
