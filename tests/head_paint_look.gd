extends Node

## PINTAR UNA CARA EN UNA CABEZA (con ventana, unos 20 segundos; ver HeadPaintArchetype): el jugador frente a la
## cabeza de la parcela «Pintar caras», abre el F1 mirando el frente, pinta dos ojos y una boca desde acá y saca
## capturas; después lo mismo con el octógono con una esquina adelante, y el F2 crea y duplica. Al final borra las
## pinturas que hizo.
##   tools/godot_ventana.sh res://tests/head_paint_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _sandbox: DesignSandbox = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var before := DirAccess.get_files_at(HeadPaintArchetype.FOLDER) if DirAccess.dir_exists_absolute(HeadPaintArchetype.FOLDER) else PackedStringArray()
	_sandbox = (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(_sandbox)
	await get_tree().create_timer(1.5).timeout
	var parcel: SandboxParcel = null
	for node in _sandbox.find_children("*", "SandboxParcel", true, false):
		if (node as SandboxParcel).archetype is HeadPaintArchetype:
			parcel = node
	var row := parcel.archetype as HeadPaintArchetype
	row.new_front_face = true
	_sandbox.local_player.place_at(parcel.global_position + Vector3(0.0, 0.0, 2.2), 0.0)
	await get_tree().create_timer(1.5).timeout
	await _paint_and_shoot("1_lado_adelante")
	row.new_front_face = false
	row._create(parcel)
	await get_tree().create_timer(1.0).timeout
	await _paint_and_shoot("2_esquina_adelante")
	# EL F2: crea y duplica desde sus botones (ver HeadPaintPanel), y la captura con el panel abierto.
	var f2 := InputEventKey.new()
	f2.keycode = KEY_F2
	f2.physical_keycode = KEY_F2
	f2.pressed = true
	Input.parse_input_event(f2)
	await get_tree().create_timer(0.8).timeout
	for entry in _sandbox._tuners:
		if entry["tuner"] is HeadPaintPanel and (entry["tuner"] as HeadPaintPanel).visible:
			var panel := entry["tuner"] as HeadPaintPanel
			panel._act("_create", "creada")
			panel._act("_duplicate", "duplicada")
			await get_tree().create_timer(0.6).timeout
			if not _folder.is_empty():
				get_viewport().get_texture().get_image().save_png("%s/3_panel_f2.png" % _folder)
	print("PINTURAS de la forma 1: %s" % [row.paintings()])
	for file in DirAccess.get_files_at(HeadPaintArchetype.FOLDER):
		if not before.has(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(HeadPaintArchetype.FOLDER + file))
	get_tree().quit()


func _paint_and_shoot(label: String) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_F1
	event.physical_keycode = KEY_F1
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().create_timer(0.8).timeout
	var panel: PixelPaintPanel = null
	for entry in _sandbox._tuners:
		if entry["tuner"] is PixelPaintPanel and (entry["tuner"] as PixelPaintPanel).visible:
			panel = entry["tuner"]
	if panel == null or panel._face == null:
		print("%s: el panel no eligió cara" % label)
		return
	var face := panel._face
	print("%s: cara de %d × %d píxeles" % [label, face.width, face.height])
	var grid := panel.grid
	grid.brush = Color(0.12, 0.1, 0.1)
	var mid := face.width / 2
	for x in [mid - 2, mid + 2]:
		grid._put(clampi(x, 0, face.width - 1), face.height * 2 / 3)
	for x in range(mid - 1, mid + 2):
		grid._put(clampi(x, 0, face.width - 1), face.height / 4)
	grid._finish()
	await get_tree().create_timer(0.6).timeout
	if not _folder.is_empty():
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_folder, label])
	Input.parse_input_event(event)
	await get_tree().create_timer(0.4).timeout
