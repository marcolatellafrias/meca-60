extends Node

## LA CABEZA DEL JEFE BOLA (unos 60 s, sin el sandbox): el jefe pelea al cubo cinemático. Los primeros 20 s el cubo se
## queda quieto; después camina en círculo, de costado, y cada tanto hace un dash. Imprime cada ataque que empieza y
## cada vez que le pega; con ventana, capturas numeradas cada 4 s.
##   tools/godot_ventana.sh res://tests/ball_brain_look.tscn -- --salida=C:/carpeta

const STILL := 20.0
const MOVING := 40.0

var _folder := ""
var _boss: BallBoss = null
var _brain: BallBrain = null
var _cube: KinematicPillar = null
var _eye: Camera3D = null
var _title: Label = null
var _shots := 0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
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
	var parent := Node3D.new()
	add_child(parent)
	BallBossArchetype.thinking = true
	var root := BallBossArchetype.new().build(0, parent)
	_boss = root.get_node("Bola") as BallBoss
	_brain = _boss.get_node("Cabeza") as BallBrain
	_cube = root.get_node("Cubo") as KinematicPillar
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var clock := 0.0
	var last_act := -1
	var last_landed := 0
	var next_shot := 2.0
	var acts := {}
	while clock < STILL + MOVING:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		if clock > STILL:
			# En círculo, de costado, mirando al jefe; cada 3 s, un dash para atrás.
			var to_boss := _boss.global_position - _cube.global_position
			_cube.aim_yaw = atan2(-to_boss.x, -to_boss.z)
			_cube.move = Vector2(1.0, 0.0)
			_cube.dash = fmod(clock - STILL, 3.0) < 0.1
			if fmod(clock - STILL, 3.0) < 0.1:
				_cube.move = Vector2(0.4, -1.0)
		if _brain.act != last_act:
			last_act = _brain.act
			if last_act != BallBrain.Act.STALK:
				acts[last_act] = int(acts.get(last_act, 0)) + 1
				print("%5.1f s · %s, a %.0f m" % [clock, BallBrain.ACT_NAMES[last_act], _gap()])
		if _brain.landed != last_landed:
			last_landed = _brain.landed
			print("%5.1f s · le pegó: %s" % [clock, _brain.last_hit])
		if clock >= next_shot:
			next_shot += 4.0
			var middle := (_boss.global_position + _cube.global_position) * 0.5
			var side := (_cube.global_position - _boss.global_position).cross(Vector3.UP).normalized()
			await _shot("%s · %s (cubo %s)" % [_brain.stage, "le pegó %d" % _brain.landed,
				"quieto" if clock < STILL else "moviéndose"], middle + side * 110.0 + Vector3.UP * 60.0, middle)
	var names := []
	for act: int in acts:
		names.append("%s %d" % [BallBrain.ACT_NAMES[act], acts[act]])
	print("en %.0f s: %s · le pegó %d veces" % [STILL + MOVING, ", ".join(names), _brain.landed])
	get_tree().quit()


func _gap() -> float:
	return Vector2(_boss.global_position.x - _cube.global_position.x, _boss.global_position.z - _cube.global_position.z).length()


func _shot(title: String, from: Vector3, at: Vector3) -> void:
	_eye.global_transform = Transform3D(Basis(), from).looking_at(at, Vector3.UP)
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_shots += 1
	_title.text = "%d. %s" % [_shots, title]
	await get_tree().process_frame
	var path := "%s/%02d.png" % [_folder, _shots]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
