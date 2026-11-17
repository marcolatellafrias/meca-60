extends Node

## EL PANEL DE EQUIPAMIENTO, PARA PROBARLO (unos 8 segundos, sin el sandbox; no escribe ningún archivo): la parcela de la
## meca jaula y su panel (EquipmentPanel) abierto. Cambia el borrador (a la izquierda la sierra, discreta y sin placa; a
## la derecha el taladro, con músculos), lo aplica como «Guardar» pero sin escribir el archivo (copia el borrador a lo
## guardado y rearma las mecas) y mira que la meca nueva lleve eso. Imprime las puntas antes y después; con ventana, dos
## fotos: el panel con la meca de antes y la meca rearmada.
##   tools/godot_ventana.sh res://tests/equipment_check.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)

var _folder := ""
var _eye: Camera3D = null
var _shots: Array = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
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
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var archetype := CageMechArchetype.new()
	var holder := Node3D.new()
	add_child(holder)
	archetype.build(0, holder)
	var panel := EquipmentPanel.new(archetype)
	add_child(panel)
	panel.side = TunerPanel.SIDE_LEFT
	panel.setup_panel()
	await get_tree().create_timer(2.0).timeout
	print("ANTES ", _tips())
	var draft := panel.draft() as MechLoadout
	draft.left_motion = ArmLoadout.Motion.POSE
	draft.left_tip = ArmLoadout.Tip.SAW
	draft.left_plate = false
	draft.right_motion = ArmLoadout.Motion.MUSCLE
	draft.right_tip = ArmLoadout.Tip.DRILL
	panel.rebuild()
	panel.visible = true
	await _shot()
	# «Guardar», sin el archivo: el borrador a lo guardado, y rearmar.
	KnobsFile.copy(panel.knobs(), draft)
	panel.applied()
	await get_tree().create_timer(2.0).timeout
	panel.visible = false
	print("DESPUÉS ", _tips())
	await _shot()
	_save()
	get_tree().quit()


func _mech() -> CageMech:
	for found in find_children("*", "CageMech", true, false):
		if not found.is_queued_for_deletion():
			return found
	return null


## Las puntas de la meca: de cada brazo, su clase, cómo se mueve y si lleva placa.
func _tips() -> String:
	var mech := _mech()
	var out := PackedStringArray()
	for arm in mech.arms:
		out.append("%s %s %s%s" % ["izq." if arm.side < 0.0 else "der.", arm.tip.get_script().get_global_name(),
			"con músculos" if arm is MuscleArm else "discreto", " con placa" if arm.plated else ""])
	return " · ".join(out)


func _shot() -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var mech := _mech()
	var at := mech.global_position
	var forward := -mech.global_basis.z
	var right := mech.global_basis.x
	_eye.fov = 50.0
	_eye.global_position = at + forward * 8.0 + right * 2.0 + Vector3.UP * 1.0
	_eye.look_at(at + Vector3.DOWN * 0.4 - right * 1.5, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_shots.append(get_viewport().get_texture().get_image())


func _save() -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var sheet := Image.create(first.get_width() * 2, first.get_height(), false, first.get_format())
	for index in _shots.size():
		var shot: Image = _shots[index]
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(first.get_width() * index, 0))
	sheet.resize(first.get_width(), first.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	var path := "%s/equipamiento.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
