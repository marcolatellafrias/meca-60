extends Node

## LA TRIPULACIÓN CUANDO LA MECA JAULA MUERE (18/11/2026, el usuario: «por ahora vamos a dejar que se queden sentados
## nomás por simplicidad»; y de las sillas: «deberían estar totalmente atornilladas a la meca… en ragdoll»): la meca con
## sus maniquíes y el ente sentados pierde toda la vida de un golpe que la empuja y se desarma (PartsRagdoll.fall_apart).
## Las sillas tienen que irse con el tronco que cae, y cada uno seguir sentado en la suya, sin errores.
## La hoja: antes del golpe y cayendo, de costado.
##   tools/godot_ventana.sh res://tests/crew_death_check.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)

var _mech: CageMech = null
var _folder := ""
var _eye: Camera3D = null
var _shots: Array = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
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
	var spot := _mech.global_position
	await _shot(spot + Vector3(18.0, 2.0, 6.0), spot + Vector3(0.0, -1.0, 5.0))
	var life := Health.attach(_mech, 10.0)
	life.hurt(life.full + 1.0, "prueba", Vector3(0.0, 4.0, 12.0))
	var farthest := {}
	var shot_at := [Engine.physics_ticks_per_second / 3, Engine.physics_ticks_per_second, Engine.physics_ticks_per_second * 3 - 1]
	for i in Engine.physics_ticks_per_second * 3:
		await get_tree().physics_frame
		if i in shot_at:
			await _shot(spot + Vector3(18.0, 2.0, 6.0), spot + Vector3(0.0, -1.0, 5.0))
		for person in crew:
			var seat := person.current_seat as Node3D
			if is_instance_valid(seat):
				farthest[person] = maxf(float(farthest.get(person, 0.0)),
					person.char_rigidbody.global_position.distance_to(seat.global_position))
	print("LA MECA: visible ", _mech.visible, " · procesa ", _mech.process_mode != Node.PROCESS_MODE_DISABLED)
	for person in crew:
		var seat := person.current_seat as Node3D
		var moved: float = person.char_rigidbody.global_position.distance_to(before[person])
		print("  ", "el ente" if person == ente else "un maniquí", ": sentado ", person.is_seated, " · bajó con los restos ",
			snappedf(moved, 0.01), " m · a lo más a ", snappedf(float(farthest.get(person, -1.0)), 0.01),
			" m de su silla · la silla cuelga de ", seat.get_parent().name if is_instance_valid(seat) else "nada")
	_save()
	get_tree().quit()


func _shot(from: Vector3, to: Vector3) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	# El ente se pone su cámara al sentarse: ésta, para la foto.
	_eye.make_current()
	_eye.fov = 55.0
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(VIEW.x / 2, VIEW.y / 2, Image.INTERPOLATE_BILINEAR)
	_shots.append(image)


func _save() -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var sheet := Image.create(first.get_width() * 2, first.get_height() * 2, false, first.get_format())
	for index in _shots.size():
		sheet.blit_rect(_shots[index], Rect2i(Vector2i.ZERO, first.get_size()),
			Vector2i(first.get_width() * (index % 2), first.get_height() * (index / 2)))
	var path := "%s/tripulacion_al_morir.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
