class_name TerminalScreen
extends CanvasLayer

## LA PANTALLA DE UNA TERMINAL DE LA BASE (ver BaseTerminal): se abre con E frente a la consola y se cierra con E o Esc.
## Mientras está abierta el mouse queda suelto y el personaje no lee teclas (UIState). Cada terminal arma su contenido
## en `build_content`.

const LAYER := "base_terminal"
const BACKGROUND := Color(0.13, 0.14, 0.16, 0.97)
const FRAME := Color(0.36, 0.38, 0.42)
const TEXT := Color(0.88, 0.89, 0.86)
const DIM_TEXT := Color(0.6, 0.62, 0.62)
const ACCENT := Color(0.93, 0.76, 0.25)

## La que está abierta (una sola a la vez).
static var opened: TerminalScreen

var state := BaseState.current
var _root: Control


static func open_screen(screen: TerminalScreen, tree: SceneTree) -> void:
	if is_instance_valid(opened):
		screen.free()
		return
	opened = screen
	tree.root.add_child.call_deferred(screen)
	UIState.open(LAYER)


func _ready() -> void:
	layer = 50
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = Theme.new()
	_root.theme.default_font_size = 16
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", box(BACKGROUND, FRAME, 2, 18))
	center.add_child(frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	frame.add_child(column)
	column.add_child(build_content())
	column.add_child(label("E o Esc: cerrar", 13, DIM_TEXT))
	state.changed.connect(refresh)
	refresh()


func _exit_tree() -> void:
	if state.changed.is_connected(refresh):
		state.changed.disconnect(refresh)


## El contenido de la terminal.
func build_content() -> Control:
	return Control.new()


## Vuelve a llenar lo que cambia con el estado.
func refresh() -> void:
	pass


func close() -> void:
	if opened == self:
		opened = null
	UIState.close(LAYER)
	queue_free()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and (key.keycode == KEY_ESCAPE or key.keycode == KEY_E):
		get_viewport().set_input_as_handled()
		close()


static func box(fill: Color, border: Color, border_width := 1, margin := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(margin)
	return style


static func label(text: String, size := 16, color := TEXT) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result


static func title(text: String) -> Label:
	return label(text, 22, ACCENT)
