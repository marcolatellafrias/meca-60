extends Node3D

## LA MECA DEL VÓRTICE, DE VERDAD (ver VortexCabin): la meca con brazos físicos parada sobre un piso, una persona
## debajo de la boca del vórtice y otra en la planta baja que entra al tubo por la puerta. Imprime cada segundo dónde
## está cada una (en el espacio de la meca) y si la meca sigue parada; con ventana, capturas.
##   tools/godot_ventana.sh res://tests/vortex_mech_check.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -40.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	add_child(world)
	_eye = Camera3D.new()
	add_child(_eye)
	_eye.make_current()
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.MUSCLE
	_mech.cabin_shape = Mech.Cabin.VORTEX
	_mech.scripted = true
	_mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.VORTEX), 0.0)
	add_child(_mech)
	await get_tree().create_timer(1.5).timeout
	var below := PeopleArchetype.spawn(self, EntityArchetype.Archetype.buff, Vector3(0.1, 0.0, 0.0), 0.0)
	var door := VortexCabin.out(VortexCabin.DOOR_AT)
	var inside := PeopleArchetype.spawn(self, EntityArchetype.Archetype.lanky,
		_mech.global_transform * (door * 1.6 + Vector3(0, VortexCabin.ground_floor() + 0.05, 0)), 0.0)
	var shots: Array = []
	for second in 8:
		await get_tree().create_timer(1.0).timeout
		# El de adentro camina hacia la puerta del tubo a partir del segundo 3 (lo empuja hacia el centro).
		if second >= 3 and second < 5:
			inside.char_rigidbody.linear_velocity = _mech.global_basis * (-door * 1.5)
		print("SEG %d · meca a %.2f m (%s) · de abajo %s · de adentro %s" % [second + 1, _mech.global_position.y,
			Mech.State.keys()[_mech.state] if "state" in _mech else "?", _where(below), _where(inside)])
		if second == 1 or second == 6:
			_eye.global_position = Vector3(-20.0, 13.0, -24.0)
			_eye.look_at(Vector3(0.0, 7.0, 0.0))
			shots.append(await _grab())
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		for i in shots.size():
			(shots[i] as Image).save_png("%s/vortice_meca_%d.png" % [_folder, i])
			print("CAPTURA %s/vortice_meca_%d.png" % [_folder, i])
	get_tree().quit()


func _where(person: BoneInstantiator) -> String:
	var local := _mech.to_local(person.char_rigidbody.global_position)
	return "(%.1f, %.1f, %.1f)%s" % [local.x, local.y, local.z, " en el marco" if person.char_rigidbody.frame != null else ""]


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
