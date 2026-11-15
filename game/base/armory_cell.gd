class_name ArmoryCell
extends PanelContainer

## UNA CASILLA DE LA ARMERÍA (ver ArmoryScreen): una cosa de la tienda, del depósito, o un hueco de la meca. Se arrastra
## y se suelta (lo que pasa al soltar lo decide la pantalla), y con el mouse encima muestra lo que es.

enum Role { SHOP, DEPOT, SLOT }

const SIZE := Vector2(106, 58)

var role := Role.SHOP
## La cosa (vacío en un hueco libre).
var id := ""
## En el depósito, su lugar; en un hueco, cuál.
var index := -1
var slot := ""
var screen: ArmoryScreen
var _name: Label
var _sub: Label


func setup(p_screen: ArmoryScreen, p_role: Role) -> ArmoryCell:
	screen = p_screen
	role = p_role
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_name = TerminalScreen.label("", 14)
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_name)
	_sub = TerminalScreen.label("", 12, TerminalScreen.DIM_TEXT)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_sub)
	return self


## Lo que muestra: su nombre y, abajo, el precio (en la tienda) o qué hueco es.
func show_item(p_id: String, sub: String, available := true, empty_text := "") -> void:
	id = p_id
	var entry := ArmoryCatalog.item(id)
	var tint: Color = ArmoryCatalog.KIND_COLORS.get(entry.get("kind", -1), TerminalScreen.FRAME)
	if id == "":
		_name.text = empty_text
		_name.add_theme_color_override("font_color", TerminalScreen.DIM_TEXT)
		add_theme_stylebox_override("panel", TerminalScreen.box(Color(0.1, 0.11, 0.12), TerminalScreen.FRAME, 1, 4))
	else:
		_name.text = entry.name
		_name.add_theme_color_override("font_color", TerminalScreen.TEXT)
		add_theme_stylebox_override("panel", TerminalScreen.box(tint.darkened(0.72), tint, 2, 4))
	_sub.text = sub
	modulate.a = 1.0 if available else 0.4
	tooltip_text = " " if id != "" or role == Role.SLOT else ""


func _make_custom_tooltip(_for_text: String) -> Object:
	return screen.tooltip_for(self)


func _get_drag_data(_at: Vector2) -> Variant:
	if id == "" or (role == Role.SHOP and not screen.state.in_stock(id)):
		return null
	var preview := PanelContainer.new()
	var tint: Color = ArmoryCatalog.KIND_COLORS[ArmoryCatalog.item(id).kind]
	preview.add_theme_stylebox_override("panel", TerminalScreen.box(tint.darkened(0.6), tint, 2, 6))
	preview.add_child(TerminalScreen.label(ArmoryCatalog.item(id).name, 14))
	set_drag_preview(preview)
	return {"armory": true, "role": role, "id": id, "index": index, "slot": slot}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("armory", false) and screen.can_drop(self, data)


func _drop_data(_at: Vector2, data: Variant) -> void:
	screen.drop(self, data)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.double_click and click.button_index == MOUSE_BUTTON_LEFT:
		screen.double_clicked(self)
