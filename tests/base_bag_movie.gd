extends Node3D

## EL VIDEO DE LA BOLSA (BaseBagRig): colgada de su cadena, recibe golpes de distinta fuerza y a distinta altura; una
## cámara fija de costado, con el nombre de cada golpe arriba. Se graba con --write-movie (antes del --):
##   tools/godot_ventana.sh res://tests/base_bag_movie.tscn --write-movie C:/x.avi --fixed-fps 30
## Sin --write-movie, una captura a los 3 s (con --salida=), para mirar la forma.

const CEILING := 8.0
const RADIUS := 0.9
const LOW := 1.0
const HIGH := 4.6
## Los golpes: cuándo (s), qué dice, la fuerza (N·s), a qué altura (partes de la bolsa, 0 abajo) y hacia dónde.
const HITS := [
	[2.0, "1. piña suave, al medio", 600.0, 0.5, Vector3(1, 0, 0)],
	[6.0, "2. piña mediana, al medio", 1500.0, 0.5, Vector3(1, 0, 0)],
	[10.5, "3. mediana, abajo", 1500.0, 0.15, Vector3(1, 0, 0)],
	[15.0, "4. mediana, arriba y de costado", 1500.0, 0.85, Vector3(0, 0, 1)],
	[19.0, "5. tres seguidas", 900.0, 0.5, Vector3(1, 0, 0)],
	[19.35, "5. tres seguidas", 900.0, 0.55, Vector3(1, 0, 0)],
	[19.7, "5. tres seguidas", 900.0, 0.45, Vector3(1, 0, 0)],
	[24.0, "6. fuerte, al medio", 3500.0, 0.5, Vector3(1, 0, 0)],
]
const LENGTH := 30.0

var _rig: BaseBagRig
var _title: Label
var _clock := 0.0
var _next := 0
var _folder := ""
var _shot_done := false


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(60, 1, 60), Vector3(0, -0.5, 0), BaseLayout.FLOOR_COLOR)
	add_child(ground)
	Clay.box(self, Vector3(14, 0.3, 14), Vector3(0, CEILING + 0.15, 0), BaseLayout.WALL_COLOR)
	Clay.box(self, Vector3(14, CEILING, 0.3), Vector3(0, CEILING * 0.5, 5.0), BaseLayout.WALL_COLOR)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, 150.0, 0.0)
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
	_rig = BaseBagRig.new()
	_rig.position = Vector3(0, CEILING, 0)
	add_child(_rig)
	_rig.build(RADIUS, HIGH - LOW, CEILING - BaseBag.PLATE_THICK - HIGH, BaseLayout.BAG_COLOR)
	var eye := Camera3D.new()
	eye.fov = 45.0
	add_child(eye)
	eye.make_current()
	eye.global_position = Vector3(-1.5, 3.4, -10.0)
	eye.look_at(Vector3(0.8, 4.4, 0))
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 18)
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)


func _physics_process(delta: float) -> void:
	_clock += delta
	while _next < HITS.size() and _clock >= float(HITS[_next][0]):
		var hit: Array = HITS[_next]
		var height := LOW + (HIGH - LOW) * float(hit[3])
		var direction: Vector3 = hit[4]
		var at := Vector3(0, height, 0) - direction * RADIUS
		_rig.hit(direction * float(hit[2]), at)
		_flash(at)
		_title.text = "%s · %.0f N·s" % [hit[1], float(hit[2])]
		_next += 1
	if not _shot_done and _clock > 3.0 and not _folder.is_empty():
		_shot_done = true
		get_viewport().get_texture().get_image().save_png(_folder + "/bolsa_fisica.png")
		print("CAPTURA ", _folder + "/bolsa_fisica.png")
	if _clock > LENGTH:
		get_tree().quit()


## Un destello donde pegó: una bola roja que se achica.
func _flash(at: Vector3) -> void:
	var ball := Clay.sphere(self, 0.25, at, Color(0.95, 0.3, 0.2))
	var tween := ball.create_tween()
	tween.tween_property(ball, "scale", Vector3.ONE * 0.05, 0.4)
	tween.tween_callback(ball.queue_free)
