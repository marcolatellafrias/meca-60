extends Node

## EL RETROCESO POR GOLPE (con ventana, unos 25 segundos de video): el empujón de la meca cinemática es UNA VELOCIDAD QUE
## SE FRENA SOLA, con la gravedad de siempre (KinematicMover.knock): en el piso se frena enseguida, en el aire casi nada y
## sale en curva, y contra una pared se corta. La jaula recibe golpes del jefe (HitReaction.land): un empujón de 6 m y
## uno de 16, uno que la tira (con saltito), uno en el aire (saltando) y uno contra una pared. Imprime cuánto recorrió,
## lo más alto y cuánto tardó en volver a manejarse. Se graba con --write-movie:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/retroceso.avi --fixed-fps 30 res://tests/knock_back_movie.tscn

var _boss: Brawler = null
var _brain: BrawlerBrain = null
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _wall: StaticBody3D = null


func _ready() -> void:
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
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = false
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	_brain = _boss.get_node("Cabeza") as BrawlerBrain
	_eye = Camera3D.new()
	_eye.fov = 50.0
	add_child(_eye)
	_eye.make_current()
	await _wait(1.0)
	_mech = _brain.target as Mech
	_mech.scripted = true
	_mech.label.visible = false
	_brain._label.visible = false
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, 120.0)))
	await _hit("un empujón de 6 m", 6.0, HitReaction.Kind.PUSH, false, false)
	await _hit("un empujón de 16 m", 16.0, HitReaction.Kind.PUSH, false, false)
	await _hit("la tira: 12 m, con saltito", 12.0, HitReaction.Kind.KNOCKDOWN, false, false)
	await _hit("en el aire, saltando: 12 m", 12.0, HitReaction.Kind.PUSH, true, false)
	await _hit("contra una pared: 16 m", 16.0, HitReaction.Kind.PUSH, false, true)
	get_tree().quit()


## Pone la jaula mirando a +z, le pega (empujada hacia −z) y la sigue con la cámara de costado.
func _hit(label: String, distance: float, kind: HitReaction.Kind, airborne: bool, wall: bool) -> void:
	_title.text = label
	var start := Vector3(0.0, 0.0, 0.0)
	_mech.put(Transform3D(Basis(Vector3.UP, PI), start))
	HitReaction.of(_mech).clear()
	if _wall != null:
		_wall.queue_free()
		_wall = null
	if wall:
		_wall = StaticBody3D.new()
		Clay.solid(_wall, Vector3(12.0, 8.0, 1.0), Vector3(0.0, 4.0, -5.0), Color(0.5, 0.5, 0.55))
		PhysicsLayers.mark_fixed(_wall)
		add_child(_wall)
	await _wait(0.6)
	if airborne:
		_mech.jump = true
		await _wait(0.15)
		_mech.jump = false
	HitReaction.land(_mech, 0.0, "prueba", kind, Vector3.FORWARD, distance, _mech.global_position)
	var top := 0.0
	var back := -1.0
	var clock := 0.0
	var at := _mech.mover.global_position
	while clock < 3.6:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		var now := _mech.mover.global_position
		top = maxf(top, now.y)
		if back < 0.0 and clock > 0.1 and not _mech.mover.pushed() and _mech.state == BalanceBody.State.STANDING:
			back = clock
		at = at.lerp(now, 0.1)
		_look(at + Vector3.UP * 2.5, Vector3(20.0, 6.0, -6.0) + at)
	var gone := _mech.mover.global_position - start
	gone.y = 0.0
	print("%s: recorrió %.1f m · subió hasta %.1f m · se maneja otra vez a los %.2f s" % [label, gone.length(), top,
		back])


func _look(at: Vector3, from: Vector3) -> void:
	_eye.global_transform = Transform3D(Basis(), from).looking_at(at, Vector3.UP)


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
