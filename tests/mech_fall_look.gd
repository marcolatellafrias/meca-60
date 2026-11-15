extends Node

## EL EMPUJÓN Y LA CAÍDA DE LA MECA CINEMÁTICA (con ventana, unos 12 segundos, sin el sandbox ni los jefes): se la empuja
## (BalanceBody.shove), se la derriba (shove con saltito + knock_down), y se la revolea (un arco largo). Capturas de
## cada momento y, tirada, a qué altura queda lo más bajo y lo más alto de cada brazo. Guarda en la carpeta que se le
## pase con --fotos= (si no, en user://).

var _mech: Mech = null
var _folder := "user://"


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--fotos="):
			_folder = argument.trim_prefix("--fotos=")
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	_mech = Mech.new()
	_mech.kinematic = true
	_mech.scripted = true
	_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_mech)
	var eye := Camera3D.new()
	add_child(eye)
	eye.global_transform = Transform3D(Basis(), Vector3(50.0, 14.0, 10.0)).looking_at(Vector3(0.0, 6.0, 8.0), Vector3.UP)
	eye.make_current()
	await _wait(1.0)
	await _shot("0_parada")
	_mech.shove(Vector3.BACK * 10.0, 0.35)
	await _wait(0.2)
	await _shot("1_empujada")
	await _wait(0.8)
	print("empujada 10 m: se corrió %.1f m" % _mech.mover.global_position.z)
	var from := _mech.mover.global_position.z
	_mech.shove(Vector3.BACK * 12.0, 0.5, 3.0)
	_mech.knock_down(Vector3.BACK)
	await _wait(0.25)
	await _shot("2_cayendo")
	await _wait(0.6)
	await _shot("3_tirada")
	_measure()
	print("derribada 12 m: se corrió %.1f m · intocable tirada: %s" % [_mech.mover.global_position.z - from,
		_mech.untouchable()])
	await _wait(1.0)
	await _shot("4_levantandose")
	await _wait(0.8)
	await _shot("5_de_pie")
	print("de pie: %s · inclinación %.0f° · intocable %s" % [_mech.state == BalanceBody.State.STANDING, _mech.tilt,
		_mech.untouchable()])
	from = _mech.mover.global_position.z
	_mech.shove(Vector3.FORWARD * 70.0, 1.3, 25.0)
	await _wait(0.65)
	print("revoleada: a la mitad, el motor a %.1f m de alto" % _mech.mover.global_position.y)
	await _wait(1.5)
	print("revoleada 70 m: se corrió %.1f m, en el piso: %s" % [from - _mech.mover.global_position.z,
		_mech.mover.is_on_floor()])
	get_tree().quit()


func _measure() -> void:
	print("tirada: la caja a %.1f m, inclinada %.0f° · el motor a %.1f m" % [_mech.global_position.y, _mech.tilt,
		_mech.mover.global_position.y])
	for arm: Node3D in _mech.find_children("*", "MechArm", true, false):
		var low := INF
		var high := -INF
		for mesh: Node3D in arm.find_children("*", "MeshInstance3D", true, false):
			if mesh.is_visible_in_tree():
				low = minf(low, mesh.global_position.y)
				high = maxf(high, mesh.global_position.y)
		print("   un brazo: de %.1f a %.1f m" % [low, high])


func _shot(name: String) -> void:
	# De costado, a 30 m del motor, mirando a media altura.
	var at := _mech.mover.global_position
	get_viewport().get_camera_3d().global_transform = Transform3D(Basis(), at + Vector3(30.0, 8.0, 4.0)).looking_at(
		at + Vector3(0.0, 4.0, 0.0), Vector3.UP)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_folder.path_join("caida_%s.png" % name))


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
