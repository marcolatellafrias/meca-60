extends Node3D

## REARMAR UNA MECA CON GENTE ADENTRO (16/11/2026; el usuario: «Invalid type in function 'world_yaw'… previously freed»
## al cambiar una perilla del F2 de la meca jaula poseyendo al maniquí de adentro): arma la jaula, se queda con su
## maniquí de la silla del que maneja como si siguiera vivo (fuera de la lista de la cabina), la rearma
## (Mech.rebuild_all) y mira que ningún personaje quede con un marco liberado.


func _ready() -> void:
	MechCabin.dummies_on = true
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var holder := Node3D.new()
	add_child(holder)
	CageMechArchetype.new().build(0, holder)
	await get_tree().create_timer(2.0).timeout
	var mech: CageMech = holder.find_children("*", "CageMech", true, false)[0]
	var kept: BoneInstantiator = null
	for dummy in mech.cabin.dummies:
		if is_instance_valid(dummy) and dummy.intent.seat == mech.cabin.chairs[CageCabin.DRIVER]:
			kept = dummy
	mech.cabin.dummies.erase(kept)
	print("ANTES: marco del maniquí ", kept.char_rigidbody.frame)
	Mech.rebuild_all(get_tree())
	for i in 10:
		await get_tree().physics_frame
	var bad := 0
	for found in get_tree().root.find_children("*", "CharacterRigidBody3D", true, false):
		var rb := found as CharacterRigidBody3D
		if rb.frame != null and not is_instance_valid(rb.frame):
			bad += 1
	print("DESPUÉS: marco del maniquí ", kept.char_rigidbody.frame, " · personajes con un marco liberado: ", bad)
	print("RUMBO ", CharacterIntent.world_yaw(kept.char_rigidbody.frame, kept.intent.look_yaw))
	get_tree().quit()
