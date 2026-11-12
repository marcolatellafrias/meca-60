extends Node3D

## LOS SEIS ARQUETIPOS, PARA MIRAR (unos 12 segundos, sin el sandbox): los para en fila sobre un piso, con su aspecto
## guardado, e imprime de cada uno su peso y su alto. Con ventana, una captura de frente y las cabezas de cerca. Después
## los hace caminar 3 segundos y frenar, e imprime cuánto anduvo cada uno y si quedó de pie (con ventana, una captura
## caminando).
##   tools/godot_ventana.sh res://tests/people_look.tscn -- --salida=C:/carpeta
## `--cabezas=0.29,0.28,…` prueba otros altos de cabeza (en metros, en el orden de la fila) sin guardarlos.

var _folder := ""
var _heads := PackedFloat64Array()


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		elif argument.begins_with("--cabezas="):
			_heads = argument.trim_prefix("--cabezas=").split_floats(",")
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	var rows := PeopleArchetype.catalogue()
	var people: Array[BoneInstantiator] = []
	for index in rows.size():
		var row := rows[index] as PeopleArchetype
		if index < _heads.size():
			var shape := (BlockShapes.for_archetype(row.archetype) if BlockShapes.for_archetype(row.archetype) != null
				else BlockShape.factory(row.archetype)).copy()
			shape.head_height = _heads[index]
			BlockShapes.set_for(row.archetype, shape)
		# Mirando a la cámara (+Z).
		people.append(PeopleArchetype.spawn(self, row.archetype, Vector3((index - (rows.size() - 1) * 0.5) * 1.3, 0.0, 0.0), PI))
	var eye := Camera3D.new()
	eye.fov = 40.0
	add_child(eye)
	eye.make_current()
	eye.global_position = Vector3(0.0, 1.4, 6.5)
	eye.look_at(Vector3(0.0, 1.1, 0.0))
	await get_tree().create_timer(2.5).timeout
	for bi in people:
		var arch := bi.entity_archetype
		print("PERSONA %s: %.0f kg · fuerza %.2f · de pie %s · cabeza a %.2f m" % [bi.name, arch.weight, arch.strength,
			not bi.ragdoll_util.is_active, bi.char_rigidbody.global_position.y])
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/personas.png")
		print("CAPTURA ", _folder + "/personas.png")
		# Y LAS CABEZAS DE CERCA, de tres cuartos: las aristas de sus loop cuts.
		for index in people.size():
			var head := _head_of(people[index])
			eye.global_position = head + Vector3(0.35, 0.05, 0.6)
			eye.look_at(head)
			await get_tree().process_frame
			await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(_folder + "/cabeza_%d.png" % (index + 1))
		print("CAPTURA cabezas")
		eye.global_position = Vector3(0.0, 1.4, 6.5)
		eye.look_at(Vector3(0.0, 1.1, 0.0))
	# A CAMINAR: hacia la cámara, tres segundos, y frenar.
	var start: Array[Vector3] = []
	for bi in people:
		start.append(bi.char_rigidbody.global_position)
		bi.intent.move = Vector2(0.0, 1.0)
	await get_tree().create_timer(1.5).timeout
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/caminando.png")
	await get_tree().create_timer(1.5).timeout
	for bi in people:
		bi.intent.move = Vector2.ZERO
	await get_tree().create_timer(2.0).timeout
	for index in people.size():
		var bi := people[index]
		var moved := bi.char_rigidbody.global_position - start[index]
		print("CAMINÓ %s: %.2f m · de pie %s" % [bi.name, Vector2(moved.x, moved.z).length(), not bi.ragdoll_util.is_active])
	get_tree().quit()


## El medio de la cabeza: el hueso `head` del esqueleto, un poco arriba (su origen es el atlas).
func _head_of(bi: BoneInstantiator) -> Vector3:
	for skeleton: Skeleton3D in bi.find_children("*", "Skeleton3D", true, false):
		var bone := skeleton.find_bone("head")
		if bone >= 0:
			return skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin + Vector3(0.0, 0.1, 0.0)
	return bi.char_rigidbody.global_position + Vector3(0.0, 0.62, 0.0)
