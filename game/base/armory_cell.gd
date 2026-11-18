class_name ArmoryCell
extends Control

## UNA CASILLA DE LA ARMERÍA (ver ArmoryScreen): una cosa de la tienda, del depósito, o un hueco de la meca. Se arrastra
## y se suelta (lo que pasa al soltar lo decide la pantalla), y con el mouse encima muestra lo que es.
## EN EL ESTILO MONOCROMO (Mono): un recuadro fino con su ícono de un bit; en la tienda, abajo el nombre y el precio; con
## el mouse encima, invertida; lo que no se puede (vendido, o no alcanza la plata), tramado; un hueco vacío, con una
## trama suave. Los huecos y el depósito, sólo con el ícono (el usuario: sin nombres).

enum Role { SHOP, DEPOT, SLOT }

const SHOP_SIZE := Vector2(122, 130)
const SLOT_SIZE := Vector2(68, 68)
const DEPOT_SIZE := Vector2(76, 76)
## El alto de los nombres de la tienda: más chico que el del texto, para que entre «ametralladora».
const NAME_HEIGHT := 9.0

var role := Role.SHOP
## La cosa (vacío en un hueco libre).
var id := ""
## En el depósito, su lugar; en un hueco, cuál.
var index := -1
var slot := ""
var screen: ArmoryScreen
var _sub := ""
var _available := true
var _hover := false


func setup(p_screen: ArmoryScreen, p_role: Role) -> ArmoryCell:
	screen = p_screen
	role = p_role
	custom_minimum_size = {Role.SHOP: SHOP_SIZE, Role.SLOT: SLOT_SIZE, Role.DEPOT: DEPOT_SIZE}[role]
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	Mono.prepare(self)
	mouse_entered.connect(func() -> void: _hover = true; queue_redraw())
	mouse_exited.connect(func() -> void: _hover = false; queue_redraw())
	return self


## Lo que muestra: el ícono y, en la tienda, el nombre y abajo el precio (o «vendido»).
func show_item(p_id: String, sub := "", available := true) -> void:
	id = p_id
	_sub = sub
	_available = available
	tooltip_text = " " if id != "" or role == Role.SLOT else ""
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var full := _hover and _available and id != ""
	if full:
		draw_rect(rect, Mono.GREEN)
	elif id == "":
		Mono.dots(self, rect.grow(-4.0), Mono.FAINT)
		Mono.frame(self, rect)
	else:
		draw_rect(rect, Mono.BLACK)
		Mono.frame(self, rect, 2.0 if _hover else 1.0)
	var ink := Mono.BLACK if full else Mono.GREEN
	if id == "":
		return
	var scale := 3.0
	var icon_at := Vector2((size.x - MonoIcons.SIZE * scale) * 0.5, 12.0 if role == Role.SHOP else
		(size.y - MonoIcons.SIZE * scale) * 0.5)
	Mono.icon(self, id, icon_at, scale, ink)
	if role == Role.SHOP:
		var name_text: String = ArmoryCatalog.item(id).name
		var lines := Mono.wrap(name_text.to_upper(), size.x - 10.0, NAME_HEIGHT)
		for k in mini(lines.size(), 2):
			Mono.text(self, Vector2(size.x * 0.5, 68.0 + k * 16.0), lines[k], NAME_HEIGHT, ink, HORIZONTAL_ALIGNMENT_CENTER)
		Mono.text(self, Vector2(size.x * 0.5, size.y - 22.0), _sub, Mono.SMALL, ink, HORIZONTAL_ALIGNMENT_CENTER)
	if not _available:
		Mono.dots(self, rect.grow(-2.0), Mono.HALF, Mono.BLACK)


func _make_custom_tooltip(_for_text: String) -> Object:
	return screen.tooltip_for(self)


func _get_drag_data(_at: Vector2) -> Variant:
	if id == "" or (role == Role.SHOP and not screen.state.in_stock(id)):
		return null
	var preview := ArmoryCell.new().setup(screen, Role.DEPOT)
	preview.show_item(id)
	preview.modulate.a = 0.85
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
