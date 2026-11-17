extends Node

## LA REACCIÓN AL GOLPE (con ventana, unos 10 segundos, sin el sandbox): la meca de tres recibe un golpe que la empuja y
## otro que la derriba (HitReaction); capturas mientras sale para atrás, tirada y levantándose. Guarda en la carpeta
## que se le pase con --fotos= (si no, en user://).

var _mech: Mech = null
var _eye: Camera3D = null
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
	_mech = CageMech.new()
	_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_mech)
	_mech.scripted = true
	Health.attach(_mech, 100.0)
	_eye = Camera3D.new()
	add_child(_eye)
	_eye.global_transform = Transform3D(Basis(), Vector3(45.0, 14.0, 0.0)).looking_at(Vector3(0.0, 7.0, -6.0), Vector3.UP)
	_eye.make_current()
	await _wait(1.0)
	await _shot("0_parada")
	HitReaction.land(_mech, 10.0, "prueba", HitReaction.Kind.PUSH, Vector3.BACK, 10.0, _mech.global_position)
	await _wait(0.05)
	await _shot("1_empujada_blanca")
	await _wait(0.6)
	HitReaction.land(_mech, 10.0, "prueba", HitReaction.Kind.KNOCKDOWN, Vector3.BACK, 12.0, _mech.global_position)
	await _wait(0.25)
	await _shot("2_cayendo")
	await _wait(0.5)
	await _shot("3_tirada")
	_measure()
	await _wait(1.1)
	await _shot("4_levantandose")
	await _wait(1.0)
	await _shot("5_de_pie")
	print("golpes %d, vida %.0f" % [HitReaction.of(_mech).hits, Health.of(_mech).left])
	get_tree().quit()


## Tirada: a qué altura quedan la caja y cada pieza suelta (lo más bajo y lo más alto).
func _measure() -> void:
	var low := INF
	var high := -INF
	var lowest := ""
	for piece: Node3D in _mech.find_children("*", "MeshInstance3D", true, false):
		if not piece.is_visible_in_tree():
			continue
		if piece.global_position.y < low:
			var top := piece.get_parent().get_parent() as Node3D
			lowest = "%s visible %s · %s top_level %s script %s" % [_mech.get_path_to(piece), piece.is_visible_in_tree(),
				top.name, top.top_level, top.get_script().resource_path if top.get_script() else "-"]
		low = minf(low, piece.global_position.y)
		high = maxf(high, piece.global_position.y)
	print("lo más bajo: ", lowest)
	print("tirada: la caja a %.1f m · las mallas de %.1f a %.1f m · el motor a %.1f m" % [_mech.global_position.y, low,
		high, _mech.mover.global_position.y])
	for arm: Node3D in _mech.find_children("*", "MechArm", true, false):
		var top := -INF
		for mesh: Node3D in arm.find_children("*", "MeshInstance3D", true, false):
			if mesh.is_visible_in_tree():
				top = maxf(top, mesh.global_position.y)
		print("   brazo %s: lo más alto a %.1f m" % [arm.get_script().resource_path.get_file(), top])


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_folder.path_join("golpe_%s.png" % name))


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
