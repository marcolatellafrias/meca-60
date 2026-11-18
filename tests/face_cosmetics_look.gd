extends Node3D

## LOS COSMÉTICOS DE LA CARA EN TODAS LAS CABEZAS (con ventana, unos segundos): las formas de HeadForms en dos filas,
## de tres cuartos de frente, con las marcas de ojos y boca y cada bigote y cejas (ver FaceCosmetic). Una captura por
## combinación, numeradas.
##   tools/godot_ventana.sh res://tests/face_cosmetics_look.tscn -- --salida=C:/carpeta

const PER_ROW := 5
const GAP := 0.42
const ROW_GAP := 0.42

var _heads: Array[MeshInstance3D] = []


func _ready() -> void:
	var folder := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			folder = argument.trim_prefix("--salida=")
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, 160.0, 0.0)
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.82, 0.86, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.86)
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	var total := HeadForms.count()
	for slot in total:
		var head := MeshInstance3D.new()
		head.mesh = HeadForms.form_for(slot).build_mesh()
		head.material_override = HeadFormsArchetype._matte(HeadFormsArchetype.SKIN)
		var col := slot % PER_ROW
		var row := slot / PER_ROW
		head.position = Vector3(((PER_ROW - 1) * 0.5 - col) * GAP, -row * ROW_GAP, 0.0)
		add_child(head)
		var tag := Label3D.new()
		tag.text = str(slot + 1)
		tag.font_size = 24
		tag.pixel_size = 0.001
		tag.position = Vector3(0.0, 0.29, 0.0)
		tag.rotation_degrees.y = 180.0
		head.add_child(tag)
		_heads.append(head)
	var eye := Camera3D.new()
	eye.fov = 30.0
	add_child(eye)
	eye.make_current()
	eye.global_position = Vector3(-0.8, 0.25, -2.5)
	eye.look_at(Vector3(0.0, -0.08, 0.0))
	var mustaches := FaceCosmetics.mustaches()
	var brows := FaceCosmetics.brows()
	var combos: Array = [[-1, -1, true]]
	for i in maxi(mustaches.size(), brows.size()):
		combos.append([mini(i, mustaches.size() - 1), mini(i, brows.size() - 1), false])
	for n in combos.size():
		var combo: Array = combos[n]
		_wear(FaceCosmetics.eye_mark() if combo[2] else null, FaceCosmetics.mouth_mark() if combo[2] else null,
			mustaches[combo[0]] if combo[0] >= 0 else null, brows[combo[1]] if combo[1] >= 0 else null)
		for i in 6:
			await get_tree().process_frame
		if not folder.is_empty():
			get_viewport().get_texture().get_image().save_png("%s/cosmeticos_%d.png" % [folder, n + 1])
	get_tree().quit()


func _wear(a: FaceCosmetic, b: FaceCosmetic, c: FaceCosmetic, d: FaceCosmetic) -> void:
	for slot in _heads.size():
		var head := _heads[slot]
		for child in head.get_children():
			if child is MeshInstance3D:
				child.queue_free()
		for cosmetic in [a, b, c, d]:
			if cosmetic == null:
				continue
			var worn := MeshInstance3D.new()
			worn.mesh = (cosmetic as FaceCosmetic).build_mesh(HeadForms.form_for(slot))
			head.add_child(worn)
