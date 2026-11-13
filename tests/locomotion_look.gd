extends Node3D

## LA FILA LOCOMOCIÓN, ESCENA POR ESCENA (con ventana, unos 80 segundos, sin el sandbox): arma cada escena sola (ver
## LocomotionLabArchetype), la deja correr y saca tres capturas; imprime de cada personaje la velocidad máxima, cuánto
## anduvo, si se cayó y si terminó con el cubo en las manos.
##   tools/godot_ventana.sh res://tests/locomotion_look.tscn -- --salida=C:/carpeta [--escena=3] [--j=1] [--u=1] [--caminando]
## Con la variable de entorno LOCO_TRACE, cada medio segundo imprime de cada uno dónde está, a qué velocidad, si va a
## algún lado (M) y si aprieta saltar (J).

const RUN_S := 11.0
var _folder := ""
var _only := -1
var _j := 0
var _u := 0
var _walk := false


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		elif argument.begins_with("--escena="):
			_only = int(argument.trim_prefix("--escena="))
		elif argument.begins_with("--j="):
			_j = int(argument.trim_prefix("--j="))
		elif argument.begins_with("--u="):
			_u = int(argument.trim_prefix("--u="))
		elif argument == "--caminando":
			_walk = true
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 40.0, 0.0)
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
	var eye := Camera3D.new()
	eye.fov = 50.0
	add_child(eye)
	eye.make_current()
	eye.global_position = Vector3(9.0, 5.0, 15.0)
	eye.look_at(Vector3(0.0, 0.6, 0.0))
	if _only == LocomotionLabArchetype.Scene.SLALOM:
		eye.global_position = Vector3(0.0, 6.5, -17.0)
		eye.look_at(Vector3(0.0, 0.0, -1.0))
	for row in LocomotionLabArchetype.catalogue():
		var lab_row := row as LocomotionLabArchetype
		if _only >= 0 and int(lab_row.scene) != _only:
			continue
		lab_row.option_j = _j
		lab_row.option_u = _u
		lab_row.sprint = not _walk
		var holder := Node3D.new()
		add_child(holder)
		var lab := lab_row.build(0, holder) as LocomotionLab
		print("ESCENA %d %s: %s" % [lab_row.scene, lab_row.display_name, lab_row.describe(0)[0]])
		var people: Array[BoneInstantiator] = []
		var start: Array[Vector3] = []
		var top: Array[float] = []
		var fell: Array[bool] = []
		var had: Array[bool] = []
		await get_tree().process_frame
		for child in lab.get_children():
			if child is BoneInstantiator:
				people.append(child)
				start.append((child as BoneInstantiator).char_rigidbody.global_position)
				top.append(0.0)
				fell.append(false)
				had.append(false)
		var elapsed := 0.0
		var shot := 0
		while elapsed < RUN_S:
			await get_tree().physics_frame
			elapsed += get_physics_process_delta_time()
			for i in people.size():
				var bi := people[i]
				if bi._is_ragdolling():
					fell[i] = true
					continue
				had[i] = had[i] or CharacterActions.of(bi).carrying()
				var v := bi.char_rigidbody.get_motion_velocity()
				top[i] = maxf(top[i], Vector2(v.x, v.z).length())
			if OS.has_environment("LOCO_TRACE") and fmod(elapsed, 0.5) < get_physics_process_delta_time():
				var row_txt := PackedStringArray()
				for bi in people:
					var a := CharacterActions.of(bi)
					row_txt.append("%s x%.1f z%.1f v%.1f %s%s" % [bi.name.left(4), bi.char_rigidbody.global_position.x, bi.char_rigidbody.global_position.z,
						Vector2(bi.char_rigidbody.get_motion_velocity().x, bi.char_rigidbody.get_motion_velocity().z).length(),
						"M" if a.moving() else "-", "J" if bi.intent.jump else ""])
				print("t%.1f %s" % [elapsed, " | ".join(row_txt)])
			if shot < 3 and elapsed >= [2.6, 4.2, 7.0][shot]:
				if not _folder.is_empty() and DisplayServer.get_name() != "headless":
					get_viewport().get_texture().get_image().save_png("%s/escena_%d_%d.png" % [_folder, lab_row.scene, shot + 1])
				shot += 1
		for i in people.size():
			var bi := people[i]
			var moved := bi.char_rigidbody.global_position - start[i]
			print("    desde %s hasta %s" % [start[i], bi.char_rigidbody.global_position])
			print("  %s: máx %.1f m/s · anduvo %.1f m · %s · %s" % [bi.name, top[i], Vector2(moved.x, moved.z).length(),
				"SE CAYÓ" if fell[i] else "de pie", "terminó con el cubo" if CharacterActions.of(bi).carrying() else ("lo tuvo" if had[i] else "nunca lo tuvo")])
		holder.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	get_tree().quit()
