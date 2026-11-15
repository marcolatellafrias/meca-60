extends Node3D

## LA MECA CON TODO PUESTO, PARA MIRAR (unos 8 segundos, sin el sandbox): una meca parada, vestida con ArmoryParts.dress
## (el puño pesado en el izquierdo, el taladro afuera en el derecho, la ametralladora y el lanzamisiles en la espalda, y
## las placas en los dos tramos de brazos y piernas). Capturas de adelante, de atrás y de costado.
##   tools/godot_ventana.sh res://tests/armory_dressed_look.tscn -- --salida=C:/carpeta [--sin-chanfles] [--alto=5] [--pelvis=40] [--cabina=3.5] [--sin-marcos] [--brazos-abajo] [--parantes]

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
	var args := OS.get_cmdline_user_args()
	var mech := make_mech(self, args)
	var prefix := "meca_variante" if args.size() > 1 else "meca_puesta"
	var eye := Camera3D.new()
	eye.fov = 50.0
	add_child(eye)
	eye.make_current()
	await get_tree().create_timer(3.0).timeout
	dress_variant(mech, args)
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


## LA MECA DE LA VARIANTE, armada en `parent` y sin vestir (ver los argumentos arriba). La usa también el video
## (tests/armory_dressed_movie.gd).
static func make_mech(parent: Node, args: PackedStringArray) -> Mech:
	# LA VARIANTE (el usuario, 15/11/2026: «sin los chamfers de las cuatro esquinas y con la altura rebajada… a 5 metros»):
	# --sin-chanfles, la caja sin el corte de las esquinas; --alto=5, la altura de la cintura (el «altura» del cartel, de
	# la caja al piso), con muslo y canilla acortados en la misma proporción. Sólo en esta corrida: no se guarda nada.
	# --pelvis=40: el alto de la pelvis de abajo, en celdas chicas (el usuario: «que la base sea un poco más alta… la
	# segunda pelvis»).
	var waist := 0.0
	var shape := CabinShape.new()
	if ResourceLoader.exists(CabinGrid.SAVED):
		shape = (load(CabinGrid.SAVED) as CabinShape).duplicate() as CabinShape
	var reshaped := false
	for argument in args:
		if argument == "--sin-chanfles":
			shape.corner_cells = 0
			reshaped = true
		elif argument.begins_with("--pelvis="):
			shape.base_cells = int(argument.trim_prefix("--pelvis="))
			reshaped = true
		elif argument.begins_with("--cabina="):
			# el alto de la cabina, del piso de abajo al techo de arriba, sin la pelvis (m); el corte del frente queda
			# igual, en celdas de trama: el mismo ángulo
			var cabin := float(argument.trim_prefix("--cabina="))
			shape.height_cells = roundi((cabin - CabinGrid.SLAB * 2.0) / CabinGrid.CELL)
			reshaped = true
		elif argument == "--sin-marcos":
			shape.frame_kind = 0
			reshaped = true
		elif argument.begins_with("--alto="):
			waist = float(argument.trim_prefix("--alto="))
	if reshaped:
		print("pelvis de abajo: %d celdas (%.2f m) · cabina: %d celdas libres (%.2f m con piso y techo)" % [shape.base_cells,
			shape.base_cells * CabinGrid.CELL, shape.height_cells, shape.height_cells * CabinGrid.CELL + CabinGrid.SLAB * 2.0])
		CabinGrid.apply(shape)
	if waist > 0.0:
		var fixed := MechBody.current.ANKLE + MechBody.current.HIP_DROP
		var legs := (MechBody.current.WAIST - fixed) / (MechBody.current.THIGH + MechBody.current.SHIN)
		var factor := (waist - fixed) / ((MechBody.current.THIGH + MechBody.current.SHIN) * legs)
		print("cintura de %.1f a %.1f m: muslo y canilla x %.2f" % [MechBody.current.WAIST, waist, factor])
		MechBody.current.THIGH *= factor
		MechBody.current.SHIN *= factor
		MechBody.current.WAIST = waist
	var mech := Mech.new()
	mech.arms_kind = Mech.Arms.POSE
	mech.scripted = true
	mech.position = Vector3(0, Mech.standing_height(), 0)
	parent.add_child(mech)
	return mech


## LA VISTE: lo de la armería, y los hombros abajo y los parantes si los argumentos lo piden.
static func dress_variant(mech: Mech, args: PackedStringArray) -> void:
	var loadout := BaseState.new().loadout
	loadout["fist_left"] = "heavy_fist"
	loadout["tool_right"] = "drill"
	loadout["back_left"] = "machine_gun"
	loadout["back_right"] = "missile_launcher"
	# --brazos-abajo: los hombros a la altura de la pelvis de abajo, sólo para la foto (la meca no tiene cómo ponerlos
	# ahí: el usuario, 15/11/2026, «ponelos nomás para la foto»)
	# (el usuario, después: «subiría un poco más los brazos»: a la altura del piso de la cabina, arriba de la pelvis)
	if args.has("--brazos-abajo"):
		for arm in mech.arms:
			arm.shoulder_local.y = -CabinGrid.HALF_HEIGHT + CabinGrid.BASE + CabinGrid.SLAB
	# --parantes: sin los marcos de la cabina, sólo dos parantes en L, finos, en las dos esquinas del frente, del piso
	# y por el corte de arriba hasta el techo (el usuario: «los únicos parantes… los dos verticales de… las dos esquinas…
	# cada parante tendría dos lados… que no sean tan gruesos»)
	if args.has("--parantes"):
		var bottom := -CabinGrid.HALF_HEIGHT + CabinGrid.BASE
		var top := CabinGrid.HALF_HEIGHT - CabinGrid.CHAMFER * CabinGrid.TRAMA
		var tall := top - bottom
		var half := CabinGrid.HALF
		var wing := 0.2
		var thin := 0.05
		# y el tramo del corte, a 45°, que sube del parante hasta el techo de atrás (el usuario: «te faltó la del
		# chamfer, la que conecta con la parte de atrás»)
		var cut := CabinGrid.CHAMFER * CabinGrid.TRAMA
		var stretches: Array[Transform3D] = [Transform3D(Basis(), Vector3(0, bottom + tall * 0.5, -half))]
		var lengths: Array[float] = [tall]
		if cut > 0.0:
			stretches.append(Transform3D(Basis(Vector3.RIGHT, PI * 0.25), Vector3(0, top + cut * 0.5, -half + cut * 0.5)))
			lengths.append(cut * sqrt(2.0))
		# y el tercero, por la arista de arriba, del corte hasta donde termina el vidrio del techo (el usuario: «te falta
		# el otro tramo. Eran tres»)
		var roof := CabinGrid.ROOF_GLASS * CabinGrid.TRAMA
		if roof > cut:
			stretches.append(Transform3D(Basis(Vector3.RIGHT, PI * 0.5),
				Vector3(0, CabinGrid.HALF_HEIGHT, -half + (cut + roof) * 0.5)))
			lengths.append(roof - cut)
		for side: float in [-1.0, 1.0]:
			for i in stretches.size():
				var post := Node3D.new()
				post.transform = stretches[i]
				mech.add_child(post)
				Clay.box(post, Vector3(wing, lengths[i], thin), Vector3(side * (half + thin - wing * 0.5), 0, -thin * 0.5),
					Clay.DARK)
				Clay.box(post, Vector3(thin, lengths[i], wing), Vector3(side * (half + thin * 0.5), 0, -thin + wing * 0.5),
					Clay.DARK)
	# --sin-herramienta: la herramienta adentro y los dos puños afuera (para pegar piñas en el video)
	ArmoryParts.dress(mech, loadout, 0.0 if args.has("--sin-herramienta") else 1.0)
