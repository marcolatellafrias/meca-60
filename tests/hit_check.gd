extends Node3D

## UN GOLPE CON NOMBRE (unos 6 segundos; ver CharacterRigidBody3D.hit): el mismo impulso de costado a cada arquetipo,
## parado. Imprime quién se cae, para dónde y cuánto se inclinó el que no.
##   godot --headless --path . res://tests/hit_check.tscn [-- --impulso=300]

func _ready() -> void:
	var impulse := 300.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--impulso="):
			impulse = float(argument.trim_prefix("--impulso="))
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	add_child(ground)
	var people: Array[BoneInstantiator] = []
	var i := 0
	for archetype: int in PeopleArchetype.ROW_ORDER:
		people.append(PeopleArchetype.spawn(self, archetype as EntityArchetype.Archetype, Vector3(i * 3.0, 0.0, 0.0), 0.0))
		i += 1
	await get_tree().create_timer(1.5).timeout
	var start: Array[Vector3] = []
	for bi in people:
		start.append(bi.char_rigidbody.global_position)
		bi.char_rigidbody.hit(Vector3(0.0, 0.0, impulse))
	var lean: Array[float] = []
	lean.resize(people.size())
	lean.fill(0.0)
	for step in 120:
		await get_tree().physics_frame
		for k in people.size():
			lean[k] = maxf(lean[k], people[k].char_rigidbody.impact_xz.length())
	for k in people.size():
		var bi := people[k]
		var body: Node3D = bi.ragdoll_util._lower_spine_body if bi._is_ragdolling() else bi.char_rigidbody
		var moved := body.global_position - start[k]
		print("%s (%.0f kg): %s · se corrió %.1f m hacia +z, %.1f de costado · inclinación máxima %.2f" % [bi.name,
			bi.char_rigidbody.mass, "SE CAYÓ" if bi._is_ragdolling() else "de pie", moved.z, moved.x, lean[k]])
	get_tree().quit()
