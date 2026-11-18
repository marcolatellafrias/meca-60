extends Node

## EL MAZAZO DEL PALO, PARA MIRARLO (17/11/2026; ver PoleTip.CHOP): la meca jaula sola, con el palo en el brazo derecho
## (con músculos), tira el mazazo una y otra vez; la cámara, de costado. Con `-- --lento`, a un cuarto de velocidad.
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/mazazo.avi --fixed-fps 30 res://tests/pole_chop_look.tscn

var _mech: CageMech = null
var _eye: Camera3D = null


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--lento"):
		Engine.time_scale = 0.25
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 145.0, 0.0)
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
	_mech = CageMech.new()
	_mech.scripted = true
	_mech.loadout = [ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.CANNON, true),
		ArmLoadout.of(ArmLoadout.Motion.MUSCLE, ArmLoadout.Tip.POLE, true)]
	_mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
	add_child(_mech)
	_mech.label.visible = false
	_eye = Camera3D.new()
	add_child(_eye)
	_eye.make_current()
	_eye.fov = 50.0
	# De costado, del lado del palo (el derecho: +x de la meca, que mira a −z).
	_eye.global_position = Vector3(9.0, 3.5, -3.0)
	_eye.look_at(Vector3(0.0, 3.0, -3.0), Vector3.UP)
	await get_tree().create_timer(1.5).timeout
	for i in 3:
		_mech.arms[1].main_strike()
		while _mech.arms[1].punching != MechArm.Punch.NONE:
			await get_tree().physics_frame
		await get_tree().create_timer(0.4).timeout
	get_tree().quit()
