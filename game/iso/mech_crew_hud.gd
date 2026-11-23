class_name MechCrewHud
extends CanvasLayer

## LOS CUADRADOS DE LAS TECLAS DE LA MECA (22/11/2026; el usuario: «cuadrados blancos, cuadrados planos, sin border
## radius… con algún símbolo, alguna letra, y que si vos lo apretás se pone de un color, y que si apretás la tecla Alt…
## te figura el mouse… lo pasás por encima de estos cuadrados, te dice qué hace cada uno»). Se ven yendo arriba.

const SIDE := 56.0
const GAP := 6.0
const MARGIN := 24.0
const IDLE := Color.WHITE
const WORKING := Color(0.25, 0.7, 1.0)
const LOCKED := Color(0.95, 0.25, 0.2)

var crew: MechCrew = null
## El tablero con todos los cuadrados (MechCursors mide contra él).
var board: Control = null

## LAS BARRITAS arriba de un cuadrado: la carga de cada brazo y el calor de la ametralladora.
const SMALL_BAR := 6.0
const AMMO_BACK := Color(0.28, 0.28, 0.3)
const AMMO_TAG := Color(0.45, 0.46, 0.48)
## Va abajo de la letra de la tecla, sin taparla.
const AMMO_TAG_HIGH := 15.0
const STICK_KNOB := 30.0
const STICK_DEAD := 0.16
## CON CLIC NO HAY BARRA ESPACIADORA: las habilidades van en una sola fila y el tablero queda de dos.
const CLICK_CELLS := {
	MechCrew.MINIGUN: Vector2i(6, 1), MechCrew.MISSILES: Vector2i(7, 1), MechCrew.SHIELD: Vector2i(8, 1),
	MechCrew.FLY: Vector2i(0, 1),
}

var _squares: Array[ColorRect] = []
## La barrita de cada tecla que la tiene (tecla → su relleno), y los cuadrados de munición (arma → {fill, count}).
var _small_bars := {}
## La carga de cada brazo, por segmentos.
var _arm_bars: Array[MechChargeBar] = []
var _ammo := {}
var _tip: Label = null
var _peeking := false
var _hovered := -1
## LA PALANCA de los controles de clic (en lugar de WASD).
var _stick_box: ColorRect = null
var _stick_knob: ColorRect = null
var _stick_held := false
## LO QUE CAMBIA EL TABLERO CON CLIC: la letra o el símbolo de cada tecla, y el dibujo de la barra espaciadora.
var _letters: Array[Label] = []
var _icons: Array[MechKeyIcon] = []
var _space_bars: Array[ColorRect] = []
var _laid_click := false


func _ready() -> void:
	layer = 30
	var columns := 11
	var rows := 3
	var whole := Vector2(columns, rows) * SIDE + Vector2(columns - 1, rows - 1) * GAP
	var root := Control.new()
	board = root
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.anchor_left = 0.5
	root.anchor_right = 0.5
	root.anchor_top = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = -whole.x * 0.5
	root.offset_right = whole.x * 0.5
	root.offset_top = -whole.y - MARGIN
	root.offset_bottom = -MARGIN
	add_child(root)
	for slot in MechCrew.SLOTS.size():
		_squares.append(_square(root, slot))
	_stick_panel(root)
	_arm_bars = [_charge_bar(root, MechCrew.ARM_LEFT), _charge_bar(root, MechCrew.ARM_RIGHT)]
	_small_bars[MechCrew.MINIGUN] = _small_bar(root, MechCrew.MINIGUN, true)
	_ammo[GunnerWeapons.Weapon.MINIGUN] = _ammo_square(root, MechCrew.MINIGUN)
	_ammo[GunnerWeapons.Weapon.MISSILES] = _ammo_square(root, MechCrew.MISSILES)
	_tip = Label.new()
	var back := StyleBoxFlat.new()
	back.bg_color = IDLE
	back.set_content_margin_all(8.0)
	_tip.add_theme_stylebox_override("normal", back)
	_tip.add_theme_color_override("font_color", Color.BLACK)
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.visible = false
	root.add_child(_tip)
	visible = false


## LA PALANCA: un cuadrado con su perilla, en el lugar de WASD. Se queda donde la dejás; cerca del medio, frena.
func _stick_panel(root: Control) -> void:
	var side := SIDE * 2.0 + GAP
	_stick_box = ColorRect.new()
	_stick_box.color = IDLE
	_stick_box.position = Vector2(SIDE + GAP, 0.0)
	_stick_box.size = Vector2(side, side)
	_stick_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_stick_box.gui_input.connect(_stick_input)
	root.add_child(_stick_box)
	for bar: Rect2 in [Rect2(side * 0.5 - 1.0, 8.0, 2.0, side - 16.0), Rect2(8.0, side * 0.5 - 1.0, side - 16.0, 2.0)]:
		var line := ColorRect.new()
		line.color = Color(0.0, 0.0, 0.0, 0.25)
		line.position = bar.position
		line.size = bar.size
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stick_box.add_child(line)
	_stick_knob = ColorRect.new()
	_stick_knob.color = Color.BLACK
	_stick_knob.size = Vector2.ONE * STICK_KNOB
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_box.add_child(_stick_knob)


func _stick_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_stick_held = true
			crew.push_stick(_stick_value(button.position))
			crew.hold_stick(true)
		elif _stick_held:
			_stick_held = false
			crew.push_stick(_stick_value(button.position))
			crew.hold_stick(false)
	elif event is InputEventMouseMotion and _stick_held:
		crew.push_stick(_stick_value((event as InputEventMouseMotion).position))


## El punto del cuadrado como palanca (x a la derecha, y arriba, hasta 1).
func _stick_value(at: Vector2) -> Vector2:
	var half := _stick_box.size * 0.5
	var value := ((at - half) / (half - Vector2.ONE * STICK_KNOB * 0.5)).limit_length(1.0)
	return Vector2.ZERO if value.length() < STICK_DEAD else Vector2(value.x, -value.y)


## LA BARRITA DE CARGA de un brazo, justo arriba de su cuadrado.
func _charge_bar(root: Control, slot: int) -> MechChargeBar:
	var bar := MechChargeBar.new()
	bar.position = _squares[slot].position + Vector2(0.0, -SMALL_BAR - 2.0)
	bar.size = Vector2(SIDE, SMALL_BAR)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	return bar


## UNA BARRITA justo arriba del cuadrado de `slot` (o abajo, con `below`). Devuelve su relleno.
func _small_bar(root: Control, slot: int, below := false) -> ColorRect:
	var square := _squares[slot]
	var back := ColorRect.new()
	back.color = Color(0.0, 0.0, 0.0, 0.55)
	back.position = square.position + Vector2(0.0, square.size.y + 2.0 if below else -SMALL_BAR - 2.0)
	back.size = Vector2(square.size.x, SMALL_BAR)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(back)
	var fill := ColorRect.new()
	fill.color = IDLE
	fill.size = Vector2(0.0, SMALL_BAR)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(fill)
	return fill


## LA MUNICIÓN, EN LA ESQUINA DE LA TECLA DE SU ARMA: un número sobre gris y, recargando, se llena hacia arriba.
func _ammo_square(_root: Control, slot: int) -> Dictionary:
	var key := _squares[slot]
	# UNA ETIQUETA GRIS, PEGADA A LA TECLA PERO APARTE (el usuario: «que se note que no son interactuables»).
	var back := ColorRect.new()
	back.color = AMMO_TAG
	back.size = Vector2(34.0 if slot == MechCrew.MINIGUN else key.size.x, AMMO_TAG_HIGH)
	back.position = key.size - back.size
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key.add_child(back)
	var fill := ColorRect.new()
	fill.color = AMMO_BACK
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(fill)
	var count := Label.new()
	count.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	count.add_theme_font_size_override("font_size", 11)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.add_child(count)
	return {"fill": fill, "count": count, "back": back}


func _show_ammo(weapons: GunnerWeapons, weapon: GunnerWeapons.Weapon, left: int) -> void:
	var parts: Dictionary = _ammo[weapon]
	var share := weapons.reload_share(weapon)
	var fill := parts["fill"] as ColorRect
	var back := parts["back"] as ColorRect
	fill.visible = float(weapons.reload_left[weapon]) > 0.0
	fill.size = Vector2(back.size.x, back.size.y * share)
	fill.position = Vector2(0.0, back.size.y * (1.0 - share))
	(parts["count"] as Label).text = str(left)
	# DE QUÉ COLOR ES LO CARGADO (SupplyKinds): gris, la común.
	back.color = SupplyKinds.tag_color(weapons.bullet_kind if weapon == GunnerWeapons.Weapon.MINIGUN else weapons.missile_kind)


## EL DIBUJO DE LA BARRA ESPACIADORA: el corchete acostado de los teclados.
func _space_icon(square: ColorRect) -> void:
	var wide := square.size.x * 0.46
	var left := (square.size.x - wide) * 0.5
	var low := SIDE * 0.62
	for piece: Rect2 in [Rect2(left, low, wide, 4.0), Rect2(left, low - 10.0, 4.0, 14.0),
			Rect2(left + wide - 4.0, low - 10.0, 4.0, 14.0)]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = piece.position
		bar.size = piece.size
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		square.add_child(bar)
		_space_bars.append(bar)


func _square(root: Control, slot: int) -> ColorRect:
	var entry: Dictionary = MechCrew.SLOTS[slot]
	var cell: Vector2i = entry["cell"]
	var square := ColorRect.new()
	square.color = IDLE
	var span: int = entry.get("span", 1)
	square.size = Vector2(SIDE * span + GAP * (span - 1), SIDE)
	square.position = Vector2(cell) * (SIDE + GAP)
	square.mouse_filter = Control.MOUSE_FILTER_STOP
	square.gui_input.connect(_square_input.bind(slot))
	square.mouse_entered.connect(func() -> void: _hovered = slot)
	square.mouse_exited.connect(func() -> void:
		if _hovered == slot:
			_hovered = -1)
	root.add_child(square)
	var letter := Label.new()
	letter.text = entry["text"]
	letter.add_theme_color_override("font_color", Color.BLACK)
	letter.add_theme_font_size_override("font_size", 24)
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letter.set_anchors_preset(Control.PRESET_FULL_RECT)
	square.add_child(letter)
	_letters.append(letter)
	var icon := MechKeyIcon.new()
	icon.kind = MechKeyIcon.of_slot(slot)
	icon.mirrored = slot == MechCrew.ARM_RIGHT or slot == MechCrew.RIGHT
	icon.size = Vector2.ONE * SIDE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.visible = false
	square.add_child(icon)
	_icons.append(icon)
	if slot == MechCrew.MINIGUN:
		_space_icon(square)
	return square


## CON LOS CONTROLES DE CLIC, el cuadrado se aprieta.
func _square_input(event: InputEvent, slot: int) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and crew.clicking():
		crew.click_square(slot, button.pressed)


func _exit_tree() -> void:
	_peek(false)


func _process(_delta: float) -> void:
	var aboard := crew.local_aboard()
	visible = aboard
	_peek(aboard and Input.is_physical_key_pressed(KEY_ALT))
	if not aboard:
		return
	for slot in _squares.size():
		var count := crew.counts[slot]
		_squares[slot].color = IDLE if count == 0 else (WORKING if count == 1 else LOCKED)
	_squares[MechCrew.FLY].visible = DashSettings.current.style == DashSettings.Style.BOTH
	_show_click_controls()
	for index in _arm_bars.size():
		_arm_bars[index].show_charge(crew.arm_marks(index), crew.arm_charge(index))
	var weapons := crew.mech.guns.weapons
	var heat := _small_bars[MechCrew.MINIGUN] as ColorRect
	heat.size.x = SIDE * weapons.heat
	heat.color = LOCKED if weapons.jammed else IDLE
	_show_ammo(weapons, GunnerWeapons.Weapon.MINIGUN, weapons.belt)
	_show_ammo(weapons, GunnerWeapons.Weapon.MISSILES, weapons.tubes)
	_tip.visible = _peeking and _hovered >= 0
	if _tip.visible:
		_tip.text = MechCrew.tip_of(_hovered)
		_tip.size = Vector2.ZERO
		_tip.position = _squares[_hovered].position + Vector2(0.0, -_tip.get_combined_minimum_size().y - GAP)


## LO QUE CAMBIA CON CLIC: la palanca en lugar de WASD, el giro que queda prendido y de quién es cada arma.
func _show_click_controls() -> void:
	var clicking := crew.clicking()
	_lay_out(clicking)
	_stick_box.visible = clicking
	for slot: int in [MechCrew.W, MechCrew.A, MechCrew.S, MechCrew.D]:
		_squares[slot].visible = not clicking
	if not clicking:
		return
	var grabbed := crew.counts[MechCrew.W]
	_stick_box.color = IDLE if grabbed == 0 else (WORKING if grabbed == 1 else LOCKED)
	var shown := Vector2(crew.stick.x, -crew.stick.y)
	var travel := _stick_box.size * 0.5 - Vector2.ONE * STICK_KNOB * 0.5
	_stick_knob.position = _stick_box.size * 0.5 + shown * travel - Vector2.ONE * STICK_KNOB * 0.5
	_squares[MechCrew.LEFT].color = WORKING if crew.turning > 0 else IDLE
	_squares[MechCrew.RIGHT].color = WORKING if crew.turning < 0 else IDLE
	_show_taken(MechCrew.MINIGUN, crew.gun_taker)
	_show_taken(MechCrew.MISSILES, crew.missile_taker)
	_squares[MechCrew.SHIELD].color = WORKING if crew.shield_by != 0 else IDLE
	for index in mini(crew.mech.arms.size(), 2):
		var tip := crew.mech.arms[index].tip
		_icons[MechCrew.ARM_LEFT + index].set_kind(MechKeyIcon.of_tip(tip) if tip != null else MechKeyIcon.Kind.FIST)


## EL TABLERO DE CADA MODO: con clic, símbolos, la ametralladora como un cuadrado más y dos filas.
func _lay_out(clicking: bool) -> void:
	if clicking == _laid_click:
		return
	_laid_click = clicking
	var rows := 2 if clicking else 3
	board.offset_top = -(rows * SIDE + (rows - 1) * GAP) - MARGIN
	for slot in _squares.size():
		var entry: Dictionary = MechCrew.SLOTS[slot]
		var cell: Vector2i = CLICK_CELLS.get(slot, entry["cell"]) if clicking else entry["cell"]
		var span: int = 1 if clicking else entry.get("span", 1)
		_squares[slot].position = Vector2(cell) * (SIDE + GAP)
		_squares[slot].size = Vector2(SIDE * span + GAP * (span - 1), SIDE)
		_letters[slot].visible = not clicking
		_icons[slot].visible = clicking
	for bar in _space_bars:
		bar.visible = not clicking
	var gun := _squares[MechCrew.MINIGUN]
	var tag := (_ammo[GunnerWeapons.Weapon.MINIGUN] as Dictionary)["back"] as ColorRect
	tag.position = gun.size - tag.size
	var heat := (_small_bars[MechCrew.MINIGUN] as ColorRect).get_parent() as ColorRect
	heat.size.x = gun.size.x
	heat.position = gun.position + Vector2(0.0, -SMALL_BAR - 2.0 if clicking else gun.size.y + 2.0)


func _show_taken(slot: int, taker: int) -> void:
	if taker != 0:
		_squares[slot].color = WORKING if taker == multiplayer.get_unique_id() else LOCKED


## ALT: el mouse aparece mientras se mantiene (ver UIState.peek_mouse). Sólo al cambiar: hay una por meca.
func _peek(on: bool) -> void:
	if on == _peeking:
		return
	_peeking = on
	UIState.peek_mouse(on)
