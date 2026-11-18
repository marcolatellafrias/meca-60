class_name ArmoryScreen
extends TerminalScreen

## LA ARMERÍA (ver docs/technical/sucursal.md y docs/conceptual/interfaz.md): a la izquierda la tienda, al medio la meca
## dibujada con sus huecos, a la derecha el depósito de la sucursal. Se compra arrastrando de la tienda a un hueco o al
## depósito (o con doble clic, al depósito); se pone arrastrando del depósito a un hueco, y se saca arrastrando del hueco
## al depósito. Con el mouse encima de cualquier cosa, el cartel con lo que es y cuánto cuesta.
## En el estilo monocromo (Mono; la variante B de las maquetas, sin nombres en los huecos ni en el depósito).

## Dónde va cada hueco sobre el dibujo (su centro), vista de atrás: el brazo izquierdo a la izquierda.
const SLOT_AT := {
	"back_left": Vector2(130, 50), "back_right": Vector2(270, 50),
	"plate_arm_left": Vector2(40, 170), "plate_arm_right": Vector2(360, 170),
	"tool_left": Vector2(40, 255), "tool_right": Vector2(360, 255),
	"fist_left": Vector2(40, 340), "fist_right": Vector2(360, 340),
	"plate_leg_left": Vector2(160, 530), "plate_leg_right": Vector2(240, 530),
}
const SLOT_NAMES := {
	"back_left": "LA ESPALDA, A LA IZQUIERDA", "back_right": "LA ESPALDA, A LA DERECHA",
	"plate_arm_left": "LA PLACA DEL BRAZO IZQUIERDO", "plate_arm_right": "LA PLACA DEL BRAZO DERECHO",
	"tool_left": "LA HERRAMIENTA DEL PUÑO IZQUIERDO", "tool_right": "LA HERRAMIENTA DEL PUÑO DERECHO",
	"fist_left": "EL PUÑO IZQUIERDO", "fist_right": "EL PUÑO DERECHO",
	"plate_leg_left": "LA PLACA DE LA PIERNA IZQUIERDA", "plate_leg_right": "LA PLACA DE LA PIERNA DERECHA",
}
const DRAWING_SIZE := Vector2(400, 570)

var _shop_cells: Array[ArmoryCell] = []
var _slot_cells: Array[ArmoryCell] = []
var _depot_grid: GridContainer


func title() -> String:
	return "ARMERÍA"


func build_content() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	row.add_child(_shop())
	row.add_child(_mech())
	row.add_child(_depot())
	return row


func _section(text: String, body: Control) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.add_child(MonoText.make(text))
	column.add_child(body)
	return column


func _shop() -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for entry: Dictionary in ArmoryCatalog.ITEMS:
		var cell := ArmoryCell.new().setup(self, ArmoryCell.Role.SHOP)
		cell.id = entry.id
		grid.add_child(cell)
		_shop_cells.append(cell)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(ArmoryCell.SHOP_SIZE.x * 3 + 24, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(grid)
	return _section("TIENDA", scroll)


func _mech() -> Control:
	var drawing := MechDrawing.new()
	drawing.custom_minimum_size = DRAWING_SIZE
	for slot: String in SLOT_AT:
		var cell := ArmoryCell.new().setup(self, ArmoryCell.Role.SLOT)
		cell.slot = slot
		cell.position = SLOT_AT[slot] - ArmoryCell.SLOT_SIZE * 0.5
		drawing.add_child(cell)
		_slot_cells.append(cell)
	return _section("LA MECA", drawing)


func _depot() -> Control:
	var zone := _DepotZone.new()
	zone.custom_minimum_size = Vector2(ArmoryCell.DEPOT_SIZE.x * 4 + 50, 110)
	zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone.set_drag_forwarding(Callable(), _zone_can_drop, _zone_drop)
	_depot_grid = GridContainer.new()
	_depot_grid.columns = 4
	_depot_grid.add_theme_constant_override("h_separation", 10)
	_depot_grid.add_theme_constant_override("v_separation", 10)
	_depot_grid.position = Vector2(16, 16)
	_depot_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	zone.add_child(_depot_grid)
	_depot_grid.resized.connect(func() -> void:
		zone.custom_minimum_size.y = maxf(110.0, _depot_grid.size.y + 32.0))
	var section := _section("DEPÓSITO", zone)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return section


## EL RECUADRO DEL DEPÓSITO: un borde fino (se le suelta encima lo que se compra o se saca).
class _DepotZone extends Control:
	func _draw() -> void:
		Mono.frame(self, Rect2(Vector2.ZERO, size))


func refresh() -> void:
	for cell in _shop_cells:
		var sold := not state.in_stock(cell.id)
		cell.show_item(cell.id, "VENDIDO" if sold else str(int(ArmoryCatalog.item(cell.id).price)), state.can_buy(cell.id))
	for cell in _slot_cells:
		cell.show_item(state.loadout[cell.slot])
	for child in _depot_grid.get_children():
		child.queue_free()
	for i in state.depot.size():
		var cell := ArmoryCell.new().setup(self, ArmoryCell.Role.DEPOT)
		cell.index = i
		_depot_grid.add_child(cell)
		cell.show_item(state.depot[i])


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
	if cell.id == "":
		var kind: int = BaseState.SLOTS[cell.slot]
		var lines := [[SLOT_NAMES[cell.slot], Mono.TEXT],
			["ACÁ VA: " + str(ArmoryCatalog.KIND_NAMES[kind]).to_upper() + ".", Mono.SMALL]]
		if cell.slot.begins_with("tool_"):
			lines.append(["SIN HERRAMIENTA, EL BRAZO PEGA SÓLO CON EL PUÑO.", Mono.SMALL])
		return MonoTooltip.make(lines)
	var entry := ArmoryCatalog.item(cell.id)
	var lines := [[str(entry.name).to_upper(), Mono.TEXT], [str(ArmoryCatalog.KIND_NAMES[entry.kind]).to_upper(), Mono.SMALL],
		[str(entry.text).to_upper(), Mono.SMALL], [str(entry.stats).to_upper(), Mono.SMALL]]
	if cell.role == ArmoryCell.Role.SHOP:
		if not state.in_stock(cell.id):
			lines.append(["VENDIDO: HAY UNO SOLO DE CADA UNO.", Mono.SMALL])
		elif state.money < int(entry.price):
			lines.append(["%d · NO ALCANZA LA PLATA" % int(entry.price), Mono.TEXT])
		else:
			lines.append(["%d" % int(entry.price), Mono.TEXT])
	return MonoTooltip.make(lines)
