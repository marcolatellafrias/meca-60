class_name PixelPaintPanel
extends TunerPanel

## EL PANEL PLANO DE PINTAR (F1 en la fila «Píxeles»; el usuario eligió el panel plano el 13/11/2026): al abrirse elige
## la cara que mira el jugador (el centro de la pantalla) y la muestra aplanada y grande (PixelGrid), como un editor de
## pixel art. Con el panel abierto el mouse está suelto: **un clic en otra cara del modelo** la elige. La cara elegida
## se marca en el modelo con su contorno. Se guarda solo al terminar cada trazo.

const PANEL_WIDTH := 560.0
## LA PALETA, chica y tranquila (down to earth): los colores de los recursos y unos neutros.
const PALETTE: Array[Color] = [
	Color(0.09, 0.085, 0.08), Color(0.2, 0.2, 0.21), Color(0.46, 0.46, 0.47), Color(0.72, 0.69, 0.62),
	Color(0.8, 0.75, 0.62), Color(0.38, 0.39, 0.32), Color(0.29, 0.3, 0.24), Color(0.47, 0.4, 0.27),
	Color(0.72, 0.6, 0.25), Color(0.4, 0.21, 0.17), Color(0.6, 0.22, 0.17), Color(0.33, 0.37, 0.42),
]

var grid: PixelGrid = null
var _info: Label = null
var _model: PixelModel = null
var _face: PixelFace = null
var _outline: MeshInstance3D = null


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	grid = PixelGrid.new()
	grid.painted.connect(_on_painted)
	var fill := TunerPanel.new_button("Rellenar la cara con el color", func() -> void: grid.fill())
	var undo := TunerPanel.new_button("Deshacer el último trazo", func() -> void: grid.undo())
	setup("pixeles", "PINTAR CON PÍXELES", [fill, undo] as Array[Button])
	# La grilla y la paleta se montan una vez, arriba del scroll: lo que devuelve `sections()` se libera en cada rearmado.
	var editor := VBoxContainer.new()
	_info = state_label(editor)
	var swatches := HFlowContainer.new()
	for color in PALETTE:
		swatches.add_child(_swatch(color, false))
	swatches.add_child(_swatch(Color(0.5, 0.5, 0.5), true))
	editor.add_child(swatches)
	var help := Label.new()
	help.text = "clic izquierdo pinta · clic derecho toma el color · × borra (vuelve al material) · clic en el modelo elige otra cara"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	editor.add_child(help)
	editor.add_child(grid)
	var column := _copy_button.get_parent()
	column.add_child(editor)
	column.move_child(editor, _copy_button.get_index() + 1)
	_copy_button.visible = false


func _opened() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var centre := get_viewport().get_visible_rect().size * 0.5
	_choose(camera.project_ray_origin(centre), camera.project_ray_normal(centre))


## Con el panel abierto, un clic en el mundo (fuera del panel) elige otra cara.
func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if not visible or click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var camera := get_viewport().get_camera_3d()
	if camera != null and _choose(camera.project_ray_origin(click.position), camera.project_ray_normal(click.position)):
		get_viewport().set_input_as_handled()


## Elige la cara más cercana que toca el rayo entre los modelos de la parcela. Devuelve si encontró una.
func _choose(from: Vector3, direction: Vector3) -> bool:
	var best := INF
	var found := {}
	var owner_model: PixelModel = null
	for model: PixelModel in _models():
		var hit := model.pick(from, direction)
		if hit.is_empty():
			continue
		var face := hit["face"] as PixelFace
		var distance := from.distance_to(model.to_global(face.centre(hit["x"], hit["y"], model.pixel)))
		if distance < best:
			best = distance
			found = hit
			owner_model = model
	if owner_model == null:
		_show(null, null)
		return false
	_show(owner_model, found["face"] as PixelFace)
	return true


func select(model: PixelModel, face: PixelFace) -> void:
	_show(model, face)


func _show(model: PixelModel, face: PixelFace) -> void:
	_model = model
	_face = face
	grid.edit(model, face)
	if is_instance_valid(_outline):
		_outline.queue_free()
	_outline = null
	if face != null:
		_outline = _draw_outline(model, face)
	_update_info()


func _on_painted() -> void:
	_update_info()


func _update_info() -> void:
	if _info == null:
		return
	if _face == null:
		_info.text = "Mirá una cara de un modelo de la fila y apretá F1 (o hacé clic en ella)."
		return
	var kept := _model.matched()
	_info.text = "«%s»: %d caras · cara de %d × %d píxeles · atlas de %d · pintados %d (guardados %d; los que sobran son de otra versión)" \
		% [_model.paint_name, _model.faces.size(), _face.width, _face.height, _model.atlas_side, kept.x, kept.y]


func _models() -> Array[PixelModel]:
	var out: Array[PixelModel] = []
	var parcel := sandbox.call("current_parcel") as SandboxParcel if is_instance_valid(sandbox) else null
	var where: Node = parcel if parcel != null else get_tree().current_scene
	for model: PixelModel in where.find_children("*", "PixelModel", true, false):
		out.append(model)
	return out


func _swatch(color: Color, eraser: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(36, 30)
	button.focus_mode = Control.FOCUS_NONE
	button.text = "×" if eraser else ""
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color.WHITE
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.pressed.connect(func() -> void:
		grid.brush = color
		grid.erasing = eraser)
	return button


## EL CONTORNO DE LA CARA ELEGIDA, en el modelo: líneas apenas hacia afuera de la cara.
static func _draw_outline(model: PixelModel, face: PixelFace) -> MeshInstance3D:
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for point in face.outline:
		lines.surface_add_vertex(point + face.normal * 0.004)
	lines.surface_end()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.85, 0.3)
	material.no_depth_test = true
	var made := MeshInstance3D.new()
	made.mesh = lines
	made.material_override = material
	model.add_child(made)
	return made
