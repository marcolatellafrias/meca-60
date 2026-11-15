class_name ArmoryScreen
extends TerminalScreen

## LA ARMERÍA (ver docs/technical/sucursal.md): a la izquierda la tienda, al medio la meca dibujada con sus huecos, a la
## derecha el depósito de la sucursal y la plata. Se compra arrastrando de la tienda a un hueco o al depósito (o con
## doble clic, al depósito); se pone arrastrando del depósito a un hueco, y se saca arrastrando del hueco al depósito.
## Con el mouse encima de cualquier cosa, lo que es y cuánto cuesta.

## Dónde va cada hueco sobre el dibujo (su centro), vista de atrás: el brazo izquierdo a la izquierda.
const SLOT_AT := {
	"back_left": Vector2(118, 40), "back_right": Vector2(302, 40),
	"plate_hull": Vector2(210, 140),
	"plate_arm_left": Vector2(66, 160), "plate_arm_right": Vector2(354, 160),
	"tool_left": Vector2(66, 240), "tool_right": Vector2(354, 240),
	"fist_left": Vector2(66, 320), "fist_right": Vector2(354, 320),
	"plate_leg_left": Vector2(150, 360), "plate_leg_right": Vector2(270, 360),
}
const SLOT_NAMES := {
	"back_left": "espalda izq.", "back_right": "espalda der.", "plate_hull": "casco",
	"plate_arm_left": "brazo izq.", "plate_arm_right": "brazo der.",
	"tool_left": "herramienta izq.", "tool_right": "herramienta der.",
	"fist_left": "puño izq.", "fist_right": "puño der.",
	"plate_leg_left": "pierna izq.", "plate_leg_right": "pierna der.",
}
const DRAWING_SIZE := Vector2(420, 440)
const SHOP_ORDER := [ArmoryCatalog.Kind.FIST, ArmoryCatalog.Kind.ARM_TOOL, ArmoryCatalog.Kind.BACK, ArmoryCatalog.Kind.PLATE_HULL]
const SHOP_HEADINGS := {
	ArmoryCatalog.Kind.FIST: "PUÑOS", ArmoryCatalog.Kind.ARM_TOOL: "HERRAMIENTAS DEL PUÑO", ArmoryCatalog.Kind.BACK: "ARMAS DE ESPALDA",
	ArmoryCatalog.Kind.PLATE_HULL: "PLACAS DEL ACORAZADO",
}

var _money: Label
var _shop_cells: Array[ArmoryCell] = []
var _slot_cells: Array[ArmoryCell] = []
var _depot_grid: GridContainer


func build_content() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	var header := HBoxContainer.new()
	header.add_child(TerminalScreen.title("ARMERÍA"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_money = TerminalScreen.label("", 20, TerminalScreen.ACCENT)
	header.add_child(_money)
	column.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_shop())
	row.add_child(_mech())
	row.add_child(_depot())
	column.add_child(row)
	column.add_child(TerminalScreen.label(
		"Arrastrá de la tienda a un hueco o al depósito para comprar (doble clic: al depósito). Del depósito a un hueco "
		+ "para ponerlo; del hueco al depósito para sacarlo.", 13, TerminalScreen.DIM_TEXT))
	return column


func _section(text: String, body: Control) -> Control:
	var column := VBoxContainer.new()
	column.add_child(TerminalScreen.label(text, 15, TerminalScreen.DIM_TEXT))
	column.add_child(body)
	return column


func _shop() -> Control:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	for kind: int in SHOP_ORDER:
		var grid := GridContainer.new()
		grid.columns = 3
		for entry: Dictionary in ArmoryCatalog.ITEMS:
			var same: bool = int(entry.kind) == kind or (kind == ArmoryCatalog.Kind.PLATE_HULL
				and str(entry.id).begins_with("plate_"))
			if not same:
				continue
			var cell := ArmoryCell.new().setup(self, ArmoryCell.Role.SHOP)
			cell.id = entry.id
			grid.add_child(cell)
			_shop_cells.append(cell)
		list.add_child(_section(SHOP_HEADINGS[kind], grid))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(ArmoryCell.SIZE.x * 3 + 24, DRAWING_SIZE.y + 30)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(list)
	return _section("TIENDA", scroll)


func _mech() -> Control:
	var drawing := MechDrawing.new()
	drawing.custom_minimum_size = DRAWING_SIZE
	for slot: String in SLOT_AT:
		var cell := ArmoryCell.new().setup(self, ArmoryCell.Role.SLOT)
		cell.slot = slot
		cell.position = SLOT_AT[slot] - ArmoryCell.SIZE * 0.5
		cell.size = ArmoryCell.SIZE
		drawing.add_child(cell)
		_slot_cells.append(cell)
	return _section("LA MECA (vista de atrás)", drawing)


func _depot() -> Control:
	var zone := PanelContainer.new()
	zone.add_theme_stylebox_override("panel", TerminalScreen.box(Color(0.1, 0.11, 0.12), TerminalScreen.FRAME, 1, 6))
	zone.custom_minimum_size = Vector2(ArmoryCell.SIZE.x * 2 + 26, DRAWING_SIZE.y + 30)
	zone.set_drag_forwarding(Callable(), _zone_can_drop, _zone_drop)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	zone.add_child(scroll)
	_depot_grid = GridContainer.new()
	_depot_grid.columns = 2
	scroll.add_child(_depot_grid)
	return _section("DEPÓSITO DE LA SUCURSAL", zone)


func refresh() -> void:
	_money.text = "Plata de la tripulación: $%d" % state.money
	for cell in _shop_cells:
		var price := int(ArmoryCatalog.item(cell.id).price)
		var sub := "$%d" % price if state.in_stock(cell.id) else "vendido"
		cell.show_item(cell.id, sub, state.can_buy(cell.id))
	for cell in _slot_cells:
		var empty := "sólo el puño" if cell.slot.begins_with("tool_") else "vacío"
		cell.show_item(state.loadout[cell.slot], SLOT_NAMES[cell.slot], true, empty)
	for child in _depot_grid.get_children():
		child.queue_free()
	for i in state.depot.size():
		var cell := ArmoryCell.new().setup(self, ArmoryCell.Role.DEPOT)
		cell.index = i
		_depot_grid.add_child(cell)
		cell.show_item(state.depot[i], str(ArmoryCatalog.KIND_NAMES[ArmoryCatalog.item(state.depot[i]).kind]))


## ── SOLTAR ──────────────────────────────────────────────────────────────────────────────────────────────────────

func can_drop(target: ArmoryCell, data: Dictionary) -> bool:
	if target.role == ArmoryCell.Role.SHOP:
		return false
	if target.role == ArmoryCell.Role.DEPOT:
		return _zone_can_drop(Vector2.ZERO, data)
	match int(data.role):
		ArmoryCell.Role.SHOP:
			return state.fits(data.id, target.slot) and state.can_buy(data.id)
		ArmoryCell.Role.DEPOT, ArmoryCell.Role.SLOT:
			return state.fits(data.id, target.slot) and data.slot != target.slot
	return false


func drop(target: ArmoryCell, data: Dictionary) -> void:
	if target.role == ArmoryCell.Role.DEPOT:
		_zone_drop(Vector2.ZERO, data)
		return
	match int(data.role):
		ArmoryCell.Role.SHOP:
			state.buy_into(data.id, target.slot)
		ArmoryCell.Role.DEPOT:
			state.equip_from_depot(int(data.index), target.slot)
		ArmoryCell.Role.SLOT:
			state.swap_slots(data.slot, target.slot)


## Al depósito: lo de la tienda se compra; lo de un hueco se saca.
func _zone_can_drop(_at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.get("armory", false)):
		return false
	match int(data.role):
		ArmoryCell.Role.SHOP:
			return state.can_buy(data.id)
		ArmoryCell.Role.SLOT:
			return state.removable(data.slot)
	return false


func _zone_drop(_at: Vector2, data: Variant) -> void:
	match int(data.role):
		ArmoryCell.Role.SHOP:
			state.buy(data.id)
		ArmoryCell.Role.SLOT:
			state.unequip(data.slot)


func double_clicked(cell: ArmoryCell) -> void:
	if cell.role == ArmoryCell.Role.SHOP:
		state.buy(cell.id)


## ── LO QUE DICE CON EL MOUSE ENCIMA ────────────────────────────────────────────────────────────────────────────

func tooltip_for(cell: ArmoryCell) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", TerminalScreen.box(Color(0.08, 0.09, 0.1), TerminalScreen.ACCENT, 1, 10))
	var column := VBoxContainer.new()
	panel.add_child(column)
	if cell.id == "":
		column.add_child(TerminalScreen.label(SLOT_NAMES[cell.slot].capitalize(), 16, TerminalScreen.ACCENT))
		var kind: int = BaseState.SLOTS[cell.slot]
		var hint := "Acá va: %s." % ArmoryCatalog.KIND_NAMES[kind]
		if cell.slot.begins_with("tool_"):
			hint += " Se le agrega al puño; sin herramienta, el brazo pega sólo con el puño."
		column.add_child(TerminalScreen.label(hint, 14))
		return panel
	var entry := ArmoryCatalog.item(cell.id)
	column.add_child(TerminalScreen.label(entry.name, 17, TerminalScreen.ACCENT))
	column.add_child(TerminalScreen.label(str(ArmoryCatalog.KIND_NAMES[entry.kind]), 13, TerminalScreen.DIM_TEXT))
	var text := TerminalScreen.label(entry.text, 14)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 260
	column.add_child(text)
	column.add_child(TerminalScreen.label(entry.stats, 14, Color(0.6, 0.8, 0.65)))
	if cell.role == ArmoryCell.Role.SHOP:
		var price := "$%d" % int(entry.price)
		if not state.in_stock(cell.id):
			price = "Vendido: hay uno solo de cada uno."
		elif state.money < int(entry.price):
			price += " · no alcanza la plata"
		column.add_child(TerminalScreen.label(price, 15, TerminalScreen.ACCENT))
	return panel
