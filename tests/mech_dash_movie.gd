extends Node

## EL VIDEO DE LOS DASHES (unos 30 s, con la cámara y los cuadrados de la partida): la ráfaga y el propulsor, sin y con
## inercia, yendo y viniendo sobre una grilla de 2 m. No toca lo guardado. Se graba con --write-movie:
##   tools/godot_ventana.sh --resolution 1280x720 --write-movie C:/carpeta/dash.avi --fixed-fps 30 res://tests/mech_dash_movie.tscn

const PEER := 999

var local_player: BoneInstantiator = null
var _mech: CageMech = null
var _crew: MechCrew = null
var _title: Label = null


func _ready() -> void:
	# Esta prueba es de las teclas: no depende de lo que el usuario tenga guardado en el F6.
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	add_to_group("character_spawner")
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(300, 1, 300), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(300, 1, 300), Vector3(0, -0.5, 0), Color(0.62, 0.6, 0.56))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	for i in range(-40, 41):
		Clay.box(ground, Vector3(0.04, 0.01, 160.0), Vector3(i * 2.0, 0.006, 0.0), Color(0.42, 0.41, 0.38))
		Clay.box(ground, Vector3(160.0, 0.01, 0.04), Vector3(0.0, 0.006, i * 2.0), Color(0.42, 0.41, 0.38))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 150.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	_mech = CageMech.new()
	_mech.equipment = CageMechArchetype.ROW
	_mech.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, Mech.standing_height(_mech.cabin_shape), 0.0))
	add_child(_mech)
	add_child(IsoView.new())
	local_player = (load("res://game/character/player.tscn") as PackedScene).instantiate() as BoneInstantiator
	local_player.kind = CharacterKind.player()
	add_child(local_player)
	local_player.place_at(Vector3(0.0, 0.0, 2.4), 0.0)
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(32, 22)
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	_run()


func _run() -> void:
	var saved := DashSettings.current.values()
	await _wait(0.8)
	local_player.player_controller._shown = false
	local_player.player_controller.camera_yaw = 0.0
	await _wait(0.3)
	local_player.intent.activate = true
	await _wait(0.8)
	_crew = _mech.get_node("Tripulacion") as MechCrew
	var knobs := DashSettings.current
	knobs.burst_distance = 7.0
	knobs.burst_time = 0.1
	knobs.burst_cooldown = 0.5
	knobs.thrust_speed = 14.0
	for pair: Array in [[DashSettings.Style.BURST, false, "1 · RÁFAGA, SIN INERCIA"],
			[DashSettings.Style.BURST, true, "2 · RÁFAGA, CON INERCIA"],
			[DashSettings.Style.THRUST, false, "3 · PROPULSOR (mantener), SIN INERCIA"],
			[DashSettings.Style.THRUST, true, "4 · PROPULSOR (mantener), CON INERCIA"]]:
		knobs.style = pair[0]
		knobs.inertia = pair[1]
		_title.text = pair[2]
		_mech.energy.level = 1.0
		_mech.energy.stunned = 0.0
		for way: int in [MechCrew.D, MechCrew.A]:
			await _pass(way, knobs)
	knobs.load_values(saved)
	_crew._store(PEER, 0)
	await _wait(0.3)
	get_tree().quit()


## Camina, hace el dash hacia ahí, sigue caminando y se para.
func _pass(way: int, knobs: DashSettings) -> void:
	_crew._store(PEER, 1 << way)
	await _wait(0.6)
	_crew._store(PEER, (1 << way) | (1 << MechCrew.DASH))
	await _wait(0.9 if knobs.style == DashSettings.Style.THRUST else 0.15)
	_crew._store(PEER, 1 << way)
	await _wait(0.8)
	_crew._store(PEER, 0)
	await _wait(0.6)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
