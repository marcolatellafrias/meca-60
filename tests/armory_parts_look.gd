extends Node3D

## LOS COMPONENTES DE LA ARMERÍA, PARA MIRAR (unos 4 segundos, sin el sandbox): arma la parcela de las maquetas
## (ArmoryPartsArchetype) y saca una captura de todas y otra de cada una, de cerca.
##   tools/godot_ventana.sh res://tests/armory_parts_look.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0), Color(0.5, 0.48, 0.45))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	ArmoryPartsArchetype.new().build(0, self)
	var eye := Camera3D.new()
	eye.fov = 45.0
	add_child(eye)
	eye.make_current()
	await get_tree().create_timer(1.0).timeout
	eye.global_position = Vector3(-4.0, 26.0, -50.0)
	eye.look_at(Vector3(0.0, 2.0, 0.0))
	await _shot("componentes_0_todos")
	# de cerca, uno por uno y sin carteles: de adelante y un poco de costado, desde arriba
	for sign: Node in get_tree().get_nodes_in_group(ArmoryPartsArchetype.SIGNS):
		(sign as Label3D).visible = false
	var number := 1
	var pieces: Array[Node3D] = []
	for ids: Array in ArmoryPartsArchetype.ROWS:
		for id: String in ids:
			pieces.append(find_child(id, true, false) as Node3D)
	for piece in pieces:
		# sólo ésta a la vista (y su poste, que queda), encuadrada por lo que mide
		for other in pieces:
			other.visible = other == piece
		var bounds := _bounds(piece)
		var center := bounds.get_center()
		eye.global_position = center + Vector3(-0.55, 0.45, -1.0).normalized() * maxf(bounds.size.length() * 1.25, 7.0)
		eye.look_at(center)
		await _shot("componente_%02d_%s" % [number, piece.name])
		number += 1
	get_tree().quit()


func _shot(file: String) -> void:
	await get_tree().create_timer(0.5).timeout
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/" + file + ".png")
		print("CAPTURA ", _folder + "/" + file + ".png")


func _bounds(node: Node3D) -> AABB:
	var total := AABB()
	var first := true
	for mesh: Node in node.find_children("*", "MeshInstance3D", true, false):
		var part := mesh as MeshInstance3D
		if part.mesh == null:
			continue
		var box := part.global_transform * part.get_aabb()
		total = box if first else total.merge(box)
		first = false
	return total
