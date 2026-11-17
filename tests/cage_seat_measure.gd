extends Node3D

## LOS OJOS SENTADOS DE CADA ARQUETIPO (la jaula, 16/11/2026): cada uno se sienta en la silla de las consolas con la
## mira pedida (`EYE`) e imprime dónde quedan la pelvis, los ojos y lo más bajo de los pies, sobre la base de la silla.
## Un pie bajo cero atraviesa el piso.

const EYE := 1.15
const KINDS := ["fat_man", "kid", "lanky", "buff", "old", "fat_athletic"]


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(40, 1, 40), Vector3(0, -0.5, 0), Color(0.8, 0.8, 0.8))
	add_child(ground)
	var index := 0
	for kind: String in KINDS:
		var x := index * 3.0
		index += 1
		var seat := (load(MechCabin.SEAT_SCENE) as PackedScene).instantiate() as SeatInteractable
		seat.eye_height = EYE
		seat.position = Vector3(x, 0.0, 0.0)
		add_child(seat)
		var bi := (load("res://game/character/player.tscn") as PackedScene).instantiate() as BoneInstantiator
		bi.kind = CharacterKind.npc()
		bi.master_seed = EntityInstantiation.debug_seed(EntityArchetype.Archetype[kind], 0)
		add_child(bi)
		bi.place_at(Vector3(x, 0.0, 1.5), 0.0)
		await get_tree().create_timer(1.0).timeout
		var cb := bi.custom_bones_util
		var standing := cb.head.global_position.y
		bi.intent.seat = seat
		bi._follow_seat()
		await get_tree().create_timer(2.5).timeout
		var feet := minf(cb.left_foot.global_position.y, cb.right_foot.global_position.y)
		print("MEDIDA %s · de pie, cabeza %.2f · sentado %s · silla (pelvis) %.2f · ojos pedidos %.2f, cabeza %.2f · pies más bajos %.2f · ojo sobre pelvis %.2f" % [
			kind, standing, bi.is_seated, seat.height, EYE, cb.head.global_position.y, feet, cb.rest_eye_above_pelvis()])
	get_tree().quit()
