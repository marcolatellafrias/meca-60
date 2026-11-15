class_name ContractsScreen
extends TerminalScreen

## LA CONSOLA DE CONTRATOS (ver docs/conceptual/contratos.md y docs/technical/sucursal.md): a la izquierda los contratos
## (el jefe, la dificultad y la paga), a la derecha el elegido. «Firmar» lo deja firmado; «Salir a la arena», con uno
## firmado, abre la compuerta del techo (por ahora no hay arena detrás: es lo que pasa al empezar una partida).

## Lo que hace «Salir a la arena» (la terminal le pasa abrir la compuerta).
var on_launch := Callable()
var _chosen := 0
var _cards: Array[Button] = []
var _detail: VBoxContainer
var _sign: Button
var _launch: Button
var _signed: Label


func build_content() -> Control:
	if state.contract >= 0:
		_chosen = state.contract
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.add_child(TerminalScreen.title("CONTRATOS"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.custom_minimum_size.x = 330
	row.add_child(list)
	for i in ContractsCatalog.CONTRACTS.size():
		var contract: Dictionary = ContractsCatalog.CONTRACTS[i]
		var card := Button.new()
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.text = "%s   %s   $%d" % [ContractsCatalog.stars_text(contract.stars), contract.boss, contract.pay]
		card.custom_minimum_size.y = 44
		card.toggle_mode = true
		card.pressed.connect(_choose.bind(i))
		list.add_child(card)
		_cards.append(card)
	var side := PanelContainer.new()
	side.add_theme_stylebox_override("panel", TerminalScreen.box(Color(0.1, 0.11, 0.12), TerminalScreen.FRAME, 1, 14))
	side.custom_minimum_size = Vector2(420, 300)
	row.add_child(side)
	var side_column := VBoxContainer.new()
	side_column.add_theme_constant_override("separation", 10)
	side.add_child(side_column)
	_detail = VBoxContainer.new()
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_column.add_child(_detail)
	_signed = TerminalScreen.label("", 15, Color(0.6, 0.8, 0.65))
	side_column.add_child(_signed)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	side_column.add_child(buttons)
	_sign = Button.new()
	_sign.text = "Firmar el contrato"
	_sign.custom_minimum_size = Vector2(180, 40)
	_sign.pressed.connect(func() -> void: state.sign_contract(_chosen))
	buttons.add_child(_sign)
	_launch = Button.new()
	_launch.text = "Salir a la arena"
	_launch.custom_minimum_size = Vector2(180, 40)
	_launch.pressed.connect(_go)
	buttons.add_child(_launch)
	return column


func _choose(index: int) -> void:
	_chosen = index
	refresh()


func refresh() -> void:
	for i in _cards.size():
		_cards[i].set_pressed_no_signal(i == _chosen)
	for child in _detail.get_children():
		child.queue_free()
	var contract: Dictionary = ContractsCatalog.CONTRACTS[_chosen]
	_detail.add_child(TerminalScreen.label(contract.boss, 20, TerminalScreen.ACCENT))
	_detail.add_child(TerminalScreen.label("Dificultad  " + ContractsCatalog.stars_text(contract.stars), 15))
	_detail.add_child(TerminalScreen.label("Paga  $%d" % int(contract.pay), 15))
	var affixes: Array = contract.affixes
	var affix_text := "sin afijos" if affixes.is_empty() else ", ".join(PackedStringArray(affixes))
	_detail.add_child(TerminalScreen.label("Afijos: " + affix_text, 14, TerminalScreen.DIM_TEXT))
	var text := TerminalScreen.label(contract.text, 14)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 380
	_detail.add_child(text)
	if state.contract >= 0:
		_signed.text = "Firmado: " + str(ContractsCatalog.CONTRACTS[state.contract].boss)
	else:
		_signed.text = "Ningún contrato firmado."
	_sign.disabled = state.contract == _chosen
	_launch.disabled = state.contract < 0


func _go() -> void:
	if on_launch.is_valid():
		on_launch.call()
	close()
