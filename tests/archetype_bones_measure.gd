extends Node3D

## LOS HUESOS DE CADA ARQUETIPO (16/11/2026, para la pose recostada de la meca jaula: «¿esto funciona con todos los
## arquetipos?»): imprime, de cada uno, la columna hasta los ojos, el muslo, la canilla, la altura del tobillo a la suela
## y el pie, en metros.

const KINDS := ["fat_man", "kid", "lanky", "buff", "old", "fat_athletic"]


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(40, 1, 40), Vector3(0, -0.5, 0), Color(0.8, 0.8, 0.8))
	add_child(ground)
	var index := 0
	for kind: String in KINDS:
		var bi := (load("res://game/character/player.tscn") as PackedScene).instantiate() as BoneInstantiator
		bi.kind = CharacterKind.npc()
		bi.master_seed = EntityInstantiation.debug_seed(EntityArchetype.Archetype[kind], 0)
		add_child(bi)
		bi.place_at(Vector3(index * 3.0, 0.0, 0.0), 0.0)
		index += 1
		await get_tree().create_timer(0.6).timeout
		var cb := bi.custom_bones_util
		var spine := cb.lower_spine.length + cb.higher_spine.length + cb.chest.length
		print("HUESOS %s · columna %.2f · cuello %.2f · cabeza %.2f · ojos sobre la pelvis %.2f · muslo %.2f · canilla %.2f · pie %.2f · tobillo %.2f" % [
			kind, spine, cb.neck.length, cb.head.length, cb.rest_eye_above_pelvis(), cb.left_higher_leg.length,
			cb.left_lower_leg.length, cb.left_foot.length, cb.left_foot.global_position.y])
	get_tree().quit()
