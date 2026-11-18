extends Node

## LA TORRETA DEL ARTILLERO, ANDANDO (18/11/2026; ver GunnerTurret): la meca jaula de 3 con su maniquí en la silla del
## artillero; el yugo apunta (lo que pide cada paso mientras se lo agarra: GunnerTurret.aim) a la izquierda, a la
## derecha, arriba, y lo suelta: la torreta persigue con su resorte y queda donde quedó. Mitad del video de afuera,
## mitad desde los ojos del artillero. Imprime hacia dónde quedó. Se graba con:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/torreta.avi --fixed-fps 30 res://tests/gunner_turret_movie.tscn

## Lo que pide el yugo: desde cuándo (s), hacia dónde (grados: giro respecto del frente de la meca, inclinación) y su
## nombre; sin pedir (null), suelto.
const STEPS := [
	[0.0, null, "quieta"],
	[1.0, Vector2(80.0, 0.0), "agarrado: a la izquierda"],
	[3.0, Vector2(-100.0, 5.0), "a la derecha"],
	[5.5, Vector2(0.0, 30.0), "al frente y arriba"],
	[7.5, null, "suelto: queda donde quedó"],
	[9.0, Vector2(40.0, -8.0), "agarrado otra vez: un poco a la izquierda y abajo"],
	[11.0, null, ""],
]

var _mech: CageMech = null
var _turret: GunnerTurret = null
var _eye: Camera3D = null
var _title: Label = null
var _clock := 0.0
var _started := false


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	for k in 8:
		var angle := TAU * k / 8.0
		Clay.box(ground, Vector3(2.0, 4.0, 2.0), Vector3(sin(angle) * 30.0, 2.0, -cos(angle) * 30.0), Color(0.6, 0.35, 0.3))
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
	_eye = Camera3D.new()
	_eye.near = 0.02
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 10)
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	_mech = CageMech.new()
	_mech.scripted = true
	_mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
	add_child(_mech)
	await get_tree().create_timer(2.0).timeout
	for found in get_tree().root.find_children("*", "Label3D", true, false):
		(found as Label3D).visible = false
	_turret = (_mech.cabin as CageCabin).turret
	if _turret == null:
		print("SIN TORRETA (¿la meca es de menos de 3?)")
		get_tree().quit()
		return
	_started = true


func _physics_process(delta: float) -> void:
	if not _started:
		return
	_clock += delta
	var now := 0
	for index in STEPS.size():
		if _clock >= float(STEPS[index][0]):
			now = index
	if String(STEPS[now][2]) == "":
		print("quedó: giro %.0f°, inclinación %.0f°" % [rad_to_deg(_turret.yaw), rad_to_deg(_turret.pitch)])
		get_tree().quit()
		return
	var wanted: Variant = STEPS[now][1]
	if wanted != null:
		var front := _mech.global_basis * Vector3.FORWARD
		var mech_yaw := atan2(-front.x, -front.z)
		_turret.aim(mech_yaw + deg_to_rad((wanted as Vector2).x), deg_to_rad((wanted as Vector2).y))
	var inside := _clock > 5.5
	_title.text = "%s · %s" % [STEPS[now][2], "desde sus ojos" if inside else "de afuera"]
	var seat := _turret.frame.global_transform
	if inside:
		var eye := seat * Vector3(0.0, 1.15, 0.02)
		_eye.fov = 80.0
		_eye.global_position = eye
		_eye.look_at(eye + seat.basis * Vector3(0.0, -0.3, -3.0), Vector3.UP)
	else:
		var at := _turret.global_position + Vector3(0.0, 0.7, 0.0)
		_eye.fov = 55.0
		_eye.global_position = at + _mech.global_basis * Vector3(2.0, 1.2, 2.4)
		_eye.look_at(at, Vector3.UP)
