extends Node3D

## EL PANEL DE LA FORMA DE LA CABINA (CabinShapePanel), sin el sandbox: una parcela con la meca, el panel pasa a 2 × 2
## módulos y 2 pisos con «Probar», y se mira que la meca de la parcela se rearmó con esa forma. No guarda nada.
##   tools/godot_ventana.sh res://tests/cabin_shape_check.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -60.0, 0.0)
	add_child(sun)
	var row := SandboxRow.new(SandboxSuper.Id.MECH, "Meca de prueba")
	var parcel := SandboxParcel.new()
	add_child(parcel)
	parcel.setup(MechArchetype.new(Mech.Arms.POSE), row, "", SandboxRow.Build.NEAR, Vector2(120, 120), 0)
	parcel.regenerate(0)
	var eye := Camera3D.new()
	add_child(eye)
	eye.make_current()
	await get_tree().create_timer(2.0).timeout
	print("ANTES: ", _sizes())
	var panel := CabinShapePanel.new()
	add_child(panel)
	panel.setup_panel()
	panel._draft.modules = 2
	panel._draft.floors = 2
	panel._try()
	await get_tree().create_timer(3.0).timeout
	print("DESPUÉS: ", _sizes(), " · ", panel._state.text)
	var mech := _mechs()[0] as Mech
	eye.global_position = mech.global_transform * Vector3(-14, 2, 22)
	eye.look_at(mech.global_position + Vector3(0, -3, 0))
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not _folder.is_empty():
		get_viewport().get_texture().get_image().save_png(_folder + "/forma_panel.png")
	get_tree().quit()


func _mechs() -> Array[Node]:
	return find_children("*", "RigidBody3D", true, false).filter(func(body: Node) -> bool: return body is Mech)


func _sizes() -> Array:
	return _mechs().map(func(body: Node) -> String: return "%.2f m" % (body as Mech).size.x)
