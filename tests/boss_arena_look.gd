extends Node

## LA ARENA DEL JEFE, PARA MIRARLA (un minuto, sin el sandbox): el jefe de prueba hace cada uno de sus ataques contra la
## meca propia quieta (y la sierra tirada dos veces: parada y agachada), y después le sacan la vida. Imprime, por
## ataque, si la agarró (el último golpe que midió su péndulo), lo más que se inclinó y si se cayó. Con ventana,
## capturas numeradas.
##   tools/godot_ventana.sh res://tests/boss_arena_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _mech: Mech = null
var _boss: BossMech = null
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 90)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
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
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	var holder := Node3D.new()
	add_child(holder)
	var arena := BossArenaArchetype.new().build(0, holder)
	_mech = arena.find_children("*", "Mech", true, false)[0] as Mech
	_boss = arena.find_children("*", "BossMech", true, false)[0] as BossMech
	_boss.brain.mode = BossBrain.Mode.STILL
	(arena.find_children("*", "BossHealthBar", true, false)[0] as BossHealthBar).visible = true
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	_mech.keys.driving = true
	await _seconds(2.0)
	_look_from(Vector3(-28.0, 10.0, -30.0), _boss.global_position + Vector3(0, -3, 0))
	await _shot("1. el jefe de prueba: sierra, puño con ametralladora y el ojo", "1_jefe")
	_place_mech(45.0)
	await _attack("pecho", "LÁSER (saltarlo)", "2_laser", 2.2, Vector3(50.0, 40.0, 30.0))
	await _attack("salto", "SALTO Y ONDA AL CAER (saltarla)", "3_onda_salto", 1.55, Vector3(50.0, 30.0, 40.0))
	await _attack("brazo 1 arma", "RÁFAGA (cambiar de rumbo)", "4_rafaga", 1.3, Vector3(40.0, 18.0, 20.0))
	await _attack("brazo 0 mano", "SIERRA TIRADA, parada (agacharse)", "5_sierra_tirada", 1.5, Vector3(45.0, 12.0, 25.0))
	_press(KEY_CTRL, true)
	await _seconds(0.6)
	await _attack("brazo 0 mano", "SIERRA TIRADA, agachada", "", 0.0, Vector3.ZERO)
	_press(KEY_CTRL, false)
	await _seconds(1.0)
	_place_mech(_boss.size.x * 0.5 + BossBrain.half_of(_mech) + _boss.melee_gap())
	await _attack("brazo 0 mano", "SIERRA DE CERCA (te sacude)", "6_sierra_cerca", 1.4, Vector3(-25.0, 14.0, 28.0))
	_place_mech(_boss.size.x * 0.5 + BossBrain.half_of(_mech) + _boss.melee_gap())
	await _attack("brazo 1 mano", "PIÑA DE CERCA", "7_pina", 0.9, Vector3(-25.0, 14.0, 28.0))
	_place_mech(45.0)
	await _attack("brazo 1 mano", "PUÑO AL PISO DE LEJOS (saltar la onda)", "", 0.0, Vector3.ZERO)
	_boss.hurt(60.0)
	_look_from(Vector3(-28.0, 10.0, -30.0), _boss.global_position + Vector3(0, -3, 0))
	await _shot("8. la vida, arriba", "8_vida")
	_boss.hurt(100.0)
	await _seconds(3.0)
	_look_from(Vector3(-28.0, 12.0, -30.0), _boss.global_position + Vector3(0, -6, 0))
	await _shot("9. sin vida: se cae y no se levanta", "9_destruida")
	print("JEFE: rota %s · caídas %d" % [_boss.broken, _boss.falls])
	get_tree().quit()


## La meca propia, quieta a `far` del jefe, mirándolo.
func _place_mech(far: float) -> void:
	var standing := BodySettings.current.hover_height + CabinGrid.HALF_HEIGHT
	_mech.global_transform = Transform3D(Basis(), Vector3(0.0, standing, far))
	_mech.linear_velocity = Vector3.ZERO
	_mech.angular_velocity = Vector3.ZERO
	_mech.aim_yaw = 0.0
	_mech.grounded = false
	_boss.aim_yaw = PI


## Un ataque: lo empieza, saca la captura a los `shot_at` segundos desde `camera` (relativa a la meca) y mide.
func _attack(which: String, title: String, file_name: String, shot_at: float, camera: Vector3) -> void:
	await _seconds(2.5)
	_mech.last_hit = 0.0
	var falls := _mech.falls
	var length := _boss.brain.start(which, _mech)
	var clock := 0.0
	var most := 0.0
	var hardest := 0.0
	var shot := file_name.is_empty()
	while clock < length + 2.5:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		most = maxf(most, _mech.tilt)
		hardest = maxf(hardest, _mech.last_hit)
		if not shot and clock >= shot_at:
			shot = true
			_look_from(camera, (_mech.global_position + _boss.global_position) * 0.5 + Vector3(0, -6, 0))
			await _shot(title, file_name)
	print("%s: golpe más fuerte %.1f m/s · inclinación %.0f° · caídas %d" % [title, hardest, most, _mech.falls - falls])


func _look_from(offset: Vector3, at: Vector3) -> void:
	_eye.global_position = at + offset
	_eye.look_at(at)


func _press(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or file_name.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
