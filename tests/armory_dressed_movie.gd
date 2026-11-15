extends Node3D

## EL VIDEO DE LA MECA CON TODO PUESTO (para mandárselo al usuario): la meca de la variante (ver armory_dressed_look:
## los mismos argumentos) camina hasta unas cajas y les pega piñas, con física, y gira. Con --vista=afuera, una cámara
## fija desde afuera, un poco arriba del piso; con --vista=tarima, los ojos del que está en la tarima. Se graba con
## --write-movie (antes del --):
##   tools/godot_ventana.sh res://tests/armory_dressed_movie.tscn --write-movie C:/x.avi --fixed-fps 30 -- --vista=afuera
##   --sin-chanfles --pelvis=36 --cabina=3.5 --sin-marcos --brazos-abajo --parantes --sin-herramienta

const Look := preload("res://tests/armory_dressed_look.gd")
## Lo que dura (s).
const LENGTH := 18.0
## A qué distancia de entre las pilas se para a pegar (m).
const REACH := 12.0

var _mech: Mech = null
var _eye: Camera3D = null
var _inside := false
var _clock := 0.0
var _next_punch := 0.0
var _punches := 0
var _dressed := false
var _args := PackedStringArray()
## Entre las dos pilas, en el piso.
var _target := Vector3.ZERO
var _walking := true


func _ready() -> void:
	_args = OS.get_cmdline_user_args()
	_inside = _args.has("--vista=tarima")
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.5, 0.48, 0.45))
	PhysicsLayers.mark_fixed(ground)
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
	_mech = Look.make_mech(self, _args)
	_eye = Camera3D.new()
	_eye.fov = 70.0 if _inside else 55.0
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	_eye.global_position = Vector3(30.0, 9.0, 10.0)
	_eye.look_at(Vector3(0.0, 6.0, -10.0))


## DOS PILAS DE CAJAS para pegarles, adelante de la meca (donde quedó parada), altas: las piñas van a la altura de los
## hombros. Y la cámara de afuera, fija, de costado a la meca y las pilas, más arriba del piso.
func _crates() -> void:
	var ahead := -_mech.global_basis.z
	ahead.y = 0.0
	ahead = ahead.normalized()
	var right := ahead.cross(Vector3.UP)
	var start := _mech.global_position
	start.y = 0.0
	_target = start + ahead * 24.0
	for side: float in [-1.0, 1.0]:
		for level in 6:
			var crate := RigidBody3D.new()
			crate.mass = 200.0
			crate.position = _target + right * side * 2.6 + Vector3.UP * (1.0 + level * 2.02)
			crate.basis = Basis.looking_at(ahead)
			Clay.solid(crate, Vector3(2.0, 2.0, 2.0), Vector3.ZERO, Color(0.62, 0.5, 0.36).darkened(0.08 * (level % 2)))
			add_child(crate)
	if not _inside:
		var middle := (start + _target) * 0.5
		_eye.global_position = middle + right * 26.0 - ahead * 2.0 + Vector3.UP * 8.0
		_eye.look_at(middle + ahead * 2.0 + Vector3.UP * 6.0)


func _physics_process(delta: float) -> void:
	_clock += delta
	if _clock > 2.0 and not _dressed:
		_dressed = true
		Look.dress_variant(_mech, _args)
		if _mech.label != null:
			_mech.label.visible = false
		_crates()
	# EL GUION: quieta, camina hasta tener las pilas a tiro, pega piñas, gira un poco y sigue pegando.
	_mech.move = Vector2.ZERO
	if not _dressed or _clock < 2.5:
		_follow()
		return
	var flat := _mech.global_position
	flat.y = 0.0
	if _walking:
		_mech.move = Vector2(0.0, 1.0)
		if flat.distance_to(_target) < REACH or _clock > 10.0:
			_walking = false
			_next_punch = _clock + 0.4
	elif _clock > _next_punch:
		var kinds := [MechArm.Punch.STRAIGHT, MechArm.Punch.HOOK, MechArm.Punch.STRAIGHT, MechArm.Punch.UPPERCUT]
		_mech.arms[_punches % 2].punch(kinds[_punches % kinds.size()])
		_punches += 1
		_next_punch = _clock + 0.7
		if _punches == 6:
			_mech.aim_yaw += deg_to_rad(20.0)
		elif _punches == 10:
			_mech.aim_yaw -= deg_to_rad(40.0)
	_follow()


func _follow() -> void:
	if _inside and _mech.cabin != null:
		var seat := _mech.cabin.to_global(_mech.cabin.top_seat() + Vector3(0.0, CabinGrid.EYE_HEIGHT + 0.5, -0.7))
		var ahead := -_mech.global_basis.z
		_eye.global_transform = Transform3D(Basis(), seat).looking_at(seat + ahead * 10.0 + Vector3.DOWN * 2.5, Vector3.UP)
	if _clock > LENGTH:
		get_tree().quit()
