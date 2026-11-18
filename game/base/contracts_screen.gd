class_name ContractsScreen
extends TerminalScreen

## LA CONSOLA DE CONTRATOS (ver docs/conceptual/contratos.md y docs/technical/sucursal.md): a la izquierda los contratos
## (la dificultad, el jefe, la paga y los afijos), a la derecha el elegido. «Firmar» lo deja firmado; «Salir a la
## arena», con uno firmado, abre la compuerta del techo (por ahora no hay arena detrás: es lo que pasa al empezar una
## partida). En el estilo monocromo (Mono): el elegido, invertido; el lugar del jefe en 3D, tramado.

## Lo que hace «Salir a la arena» (la terminal le pasa abrir la compuerta).
var on_launch := Callable()
var _chosen := 0
var _rows: Array[_Row] = []
var _detail: VBoxContainer
var _sign: MonoButton
var _launch: MonoButton
var _signed: MonoText


func title() -> String:
	return "CONTRATOS"


func build_content() -> Control:
	if state.contract >= 0:
		_chosen = state.contract
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	list.custom_minimum_size.x = 570
	row.add_child(list)
	for i in ContractsCatalog.CONTRACTS.size():
		var line := _Row.new()
		line.contract = ContractsCatalog.CONTRACTS[i]
		line.custom_minimum_size = Vector2(570, 70)
		line.chosen.connect(_choose.bind(i))
		list.add_child(line)
		_rows.append(line)
	var side := _Side.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(side)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 20
	column.offset_top = 20
	column.offset_right = -20
	column.offset_bottom = -20
	column.add_theme_constant_override("separation", 14)
	side.add_child(column)
	var boss := _BossView.new()
	boss.custom_minimum_size = Vector2(0, 200)
	column.add_child(boss)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 10)
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_detail)
	_signed = MonoText.make("", Mono.SMALL)
	column.add_child(_signed)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)
	_launch = MonoButton.make("SALIR A LA ARENA", Vector2(230, 46))
	_launch.pressed.connect(_go)
	buttons.add_child(_launch)
	_sign = MonoButton.make("FIRMAR", Vector2(200, 46), true)
	_sign.pressed.connect(func() -> void: state.sign_contract(_chosen))
	buttons.add_child(_sign)
	return row


func _choose(index: int) -> void:
	_chosen = index
	refresh()


func refresh() -> void:
	for i in _rows.size():
		_rows[i].selected = i == _chosen
	for child in _detail.get_children():
		child.queue_free()
	var contract: Dictionary = ContractsCatalog.CONTRACTS[_chosen]
	_detail.add_child(MonoText.make(str(contract.boss).to_upper(), Mono.TITLE))
	var affixes: Array = contract.affixes
	var affix_text := "SIN AFIJOS" if affixes.is_empty() else ", ".join(PackedStringArray(affixes)).to_upper()
	for pair: Array in [["DIFICULTAD", "%d/5" % int(contract.stars)], ["PAGA", str(int(contract.pay))],
			["AFIJOS", affix_text]]:
		var line := HBoxContainer.new()
		var key := MonoText.make(pair[0], Mono.SMALL)
		key.custom_minimum_size.x = 170
		line.add_child(key)
		line.add_child(MonoText.make(pair[1]))
		_detail.add_child(line)
	var text := MonoText.make(str(contract.text).to_upper(), Mono.SMALL)
	text.wrap_width = 520
	_detail.add_child(text)
	if state.contract >= 0:
		_signed.words = "FIRMADO: " + str(ContractsCatalog.CONTRACTS[state.contract].boss).to_upper()
	else:
		_signed.words = "NINGÚN CONTRATO FIRMADO."
	_sign.disabled = state.contract == _chosen
	_launch.disabled = state.contract < 0


func _go() -> void:
	if on_launch.is_valid():
		on_launch.call()
	close()


## UN CONTRATO DE LA LISTA: la dificultad, el jefe y la paga; abajo los afijos. Elegido o con el mouse encima, invertido.
class _Row extends Control:
	signal chosen()
	var contract := {}
	var selected := false:
		set(value):
			selected = value
			queue_redraw()
	var _hover := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func() -> void: _hover = true; queue_redraw())
		mouse_exited.connect(func() -> void: _hover = false; queue_redraw())

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var full := selected or _hover
		if full:
			draw_rect(rect, Mono.GREEN)
		else:
			Mono.frame(self, rect)
		var ink := Mono.BLACK if full else Mono.GREEN
		Mono.text(self, Vector2(16, 14), "%d/5   %s" % [int(contract.stars), str(contract.boss).to_upper()], Mono.TEXT, ink)
		Mono.text(self, Vector2(size.x - 16, 14), str(int(contract.pay)), Mono.TEXT, ink, HORIZONTAL_ALIGNMENT_RIGHT)
		var affixes: Array = contract.affixes
		var affix_text := "SIN AFIJOS" if affixes.is_empty() else " · ".join(PackedStringArray(affixes)).to_upper()
		Mono.text(self, Vector2(16, 44), affix_text, Mono.SMALL, ink)

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			chosen.emit()


## EL PANEL DEL ELEGIDO: un borde fino.
class _Side extends Control:
	func _draw() -> void:
		Mono.frame(self, Rect2(Vector2.ZERO, size))


## EL LUGAR DEL JEFE EN 3D (todavía no hay): tramado, con su leyenda.
class _BossView extends Control:
	func _init() -> void:
		Mono.prepare(self)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		Mono.dots(self, rect, Mono.FAINT)
		Mono.frame(self, rect)
		var label := "EL JEFE, EN 3D"
		var w := Mono.measure(label, Mono.SMALL) + 24.0
		draw_rect(Rect2(size * 0.5 - Vector2(w * 0.5, 16), Vector2(w, 32)), Mono.BLACK)
		Mono.text(self, Vector2(size.x * 0.5, size.y * 0.5 - Mono.SMALL * 0.5), label, Mono.SMALL, Mono.GREEN,
			HORIZONTAL_ALIGNMENT_CENTER)
