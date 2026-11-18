extends Node

## LA TRIPULACIÓN CUANDO LA MECA JAULA MUERE (18/11/2026, el usuario: «por ahora vamos a dejar que se queden sentados
## nomás por simplicidad»): la meca con sus maniquíes y el ente sentados pierde toda la vida y se desarma
## (PartsRagdoll.fall_apart); cada uno tiene que seguir sentado donde estaba, sin errores.
##   tools/godot_ventana.sh res://tests/crew_death_check.tscn

var _mech: CageMech = null


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var holder := Node3D.new()
	add_child(holder)
	CageMechArchetype.new().build(0, holder)
	for found in holder.find_children("*", "CageMech", true, false):
		if found.arms_kind != Mech.Arms.NONE:
			_mech = found
	await get_tree().create_timer(2.0).timeout
	var cabin := _mech.cabin as CageCabin
	cabin.evict(CageCabin.DRIVER)
	var ente := (load(MechCabin.DUMMY_SCENE) as PackedScene).instantiate() as BoneInstantiator
	ente.kind = CharacterKind.ente()
	holder.add_child(ente)
	_mech.add_collision_exception_with(ente.char_rigidbody)
	var chair := cabin.chairs[CageCabin.DRIVER]
	ente.place_at(chair.global_position + chair.global_basis.z * 0.8, chair.heading())
	await get_tree().create_timer(0.5).timeout
	chair.call("_sit", ente)
	await get_tree().create_timer(1.0).timeout
	var crew: Array[BoneInstantiator] = [ente]
	for dummy in cabin.dummies:
		crew.append(dummy)
	var before := {}
	for person in crew:
		before[person] = person.char_rigidbody.global_position
	var life := Health.new()
	life.name = "Vida"
	_mech.add_child(life)
	life.hurt(life.full + 1.0, "prueba")
	await get_tree().create_timer(3.0).timeout
	print("LA MECA: visible ", _mech.visible, " · procesa ", _mech.process_mode != Node.PROCESS_MODE_DISABLED)
	for person in crew:
		var moved: float = person.char_rigidbody.global_position.distance_to(before[person])
		print("  ", "el ente" if person == ente else "un maniquí", ": sentado ", person.is_seated, " · se corrió ",
			snappedf(moved, 0.01), " m")
	get_tree().quit()
