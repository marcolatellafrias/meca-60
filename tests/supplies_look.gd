extends Node3D

## LOS RECURSOS DE LA MECA, PARA MIRAR (unos 5 segundos, sin el sandbox): arma el lote de la fila Recursos sobre un piso,
## imprime de cada cubo suelto su tamaño, su peso y sus puntos de agarre (tienen que ser seis, uno por cara), y saca una
## captura.
##   tools/godot_ventana.sh res://tests/supplies_look.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	var lot := ObjectLotArchetype.new().build(0, self)
	# Una persona de 1,8 m, para la escala.
	Clay.box(self, Vector3(0.5, 1.8, 0.3), Vector3(-4.2, 0.9, 0.0), Color(0.95, 0.5, 0.1))
	for body: RigidBody3D in lot.find_children("*", "RigidBody3D", true, false):
		var grab := body.get_node_or_null("Grabbable") as GrabbableInteractable
		if grab == null:
			continue
		var box := (body.find_children("*", "CollisionShape3D", false, false)[0] as CollisionShape3D).shape as BoxShape3D
		print("RECURSO %s: caja %.2f × %.2f × %.2f m · %.0f kg · puntos de agarre %d" % [body.name, box.size.x, box.size.y,
			box.size.z, body.mass, grab.grab_points.size()])
	var eye := Camera3D.new()
	eye.fov = 40.0
	add_child(eye)
	eye.make_current()
	eye.global_position = Vector3(1.5, 2.6, 7.0)
	eye.look_at(Vector3(0.0, 0.6, -0.6))
	await get_tree().create_timer(2.0).timeout
	for body: RigidBody3D in lot.find_children("*", "RigidBody3D", true, false):
		if body.has_node("Grabbable"):
			print("QUIETO %s: a %.2f m del piso su centro · se movió %.2f m/s" % [body.name, body.global_position.y,
				body.linear_velocity.length()])
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/recursos.png")
		print("CAPTURA ", _folder + "/recursos.png")
	get_tree().quit()
