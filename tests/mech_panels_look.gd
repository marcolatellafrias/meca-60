extends Node3D

## LOS PANELES DE LA MECA, abiertos de a uno, para mirarlos: el F1 de la discreta y el de la física (pestañas por tema,
## cada una sus perillas) y los F3 de los brazos (discretos y con músculos). Una captura por panel. Unos 10 segundos.
##   tools/godot_ventana.sh res://tests/mech_panels_look.tscn -- --salida=C:/carpeta

func _ready() -> void:
	var folder := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 1000)
	var panels: Array[KnobsPanel] = [MechPanel.new(), MechPanel.new(Mech.Arms.MUSCLE), PoseArmPanel.new(),
		MuscleArmPanel.new()]
	var names := ["1_f1_discreta", "2_f1_fisica", "3_f3_brazos_discretos", "4_f3_brazos_musculos"]
	for i in panels.size():
		var panel := panels[i]
		add_child(panel)
		panel.setup_panel()
		panel.toggle()
		for frame in 10:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if not folder.is_empty():
			get_viewport().get_texture().get_image().save_png("%s/%s.png" % [folder, names[i]])
			print("CAPTURA ", names[i])
		panel.toggle()
		panel.queue_free()
		await get_tree().process_frame
	get_tree().quit()
