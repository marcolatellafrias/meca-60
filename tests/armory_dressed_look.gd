extends Node3D

## LA MECA CON TODO PUESTO, PARA MIRAR (unos 8 segundos, sin el sandbox): una meca parada, vestida con ArmoryParts.dress
## (el puño pesado en el izquierdo, el taladro afuera en el derecho, la ametralladora y el lanzamisiles en la espalda, y
## las placas en los dos tramos de brazos y piernas). Capturas de adelante, de atrás y de costado.
##   tools/godot_ventana.sh res://tests/armory_dressed_look.tscn -- --salida=C:/carpeta [--sin-chanfles] [--alto=5]

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
	# LA VARIANTE (el usuario, 15/11/2026: «sin los chamfers de las cuatro esquinas y con la altura rebajada… a 5 metros»):
	# --sin-chanfles, la caja sin el corte de las esquinas; --alto=5, la altura de la cintura (el «altura» del cartel, de
	# la caja al piso), con muslo y canilla acortados en la misma proporción. Sólo en esta corrida: no se guarda nada.
	var waist := 0.0
	var prefix := "meca_puesta"
	for argument in OS.get_cmdline_user_args():
		if argument == "--sin-chanfles":
			var shape := CabinShape.new()
			if ResourceLoader.exists(CabinGrid.SAVED):
				shape = (load(CabinGrid.SAVED) as CabinShape).duplicate() as CabinShape
			shape.corner_cells = 0
			CabinGrid.apply(shape)
			prefix = "meca_variante"
		elif argument.begins_with("--alto="):
			waist = float(argument.trim_prefix("--alto="))
	if waist > 0.0:
		var fixed := MechBody.ANKLE + MechBody.HIP_DROP
		var legs := (MechBody.WAIST - fixed) / (MechBody.THIGH + MechBody.SHIN)
		var factor := (waist - fixed) / ((MechBody.THIGH + MechBody.SHIN) * legs)
		print("cintura de %.1f a %.1f m: muslo y canilla x %.2f" % [MechBody.WAIST, waist, factor])
		MechBody.THIGH *= factor
		MechBody.SHIN *= factor
		MechBody.WAIST = waist
		prefix = "meca_variante"
	var mech := Mech.new()
	mech.arms_kind = Mech.Arms.POSE
	mech.scripted = true
	mech.position = Vector3(0, Mech.standing_height(), 0)
	add_child(mech)
	var eye := Camera3D.new()
	eye.fov = 50.0
	add_child(eye)
	eye.make_current()
	await get_tree().create_timer(3.0).timeout
	var loadout := BaseState.new().loadout
	loadout["fist_left"] = "heavy_fist"
	loadout["tool_right"] = "drill"
	loadout["back_left"] = "machine_gun"
	loadout["back_right"] = "missile_launcher"
	ArmoryParts.dress(mech, loadout, 1.0)
	await get_tree().create_timer(2.0).timeout
	var center := mech.global_position + Vector3(0, -4.0, 0)
	var forward := -mech.global_basis.z
	var right := mech.global_basis.x
	for shot: Array in [["_1_adelante", forward * 30.0 + right * 12.0 + Vector3(0, 8, 0)],
			["_2_atras", -forward * 30.0 - right * 14.0 + Vector3(0, 14, 0)],
			["_3_costado", right * 32.0 + forward * 4.0 + Vector3(0, 4, 0)]]:
		eye.global_position = center + (shot[1] as Vector3)
		eye.look_at(center)
		await _shot(prefix + str(shot[0]))
	get_tree().quit()


func _shot(file: String) -> void:
	await get_tree().create_timer(0.5).timeout
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/" + file + ".png")
		print("CAPTURA ", _folder + "/" + file + ".png")
