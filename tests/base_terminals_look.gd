extends Node3D

## LAS TERMINALES DE LA BASE, PARA MIRAR (unos 5 segundos, sin el sandbox): abre la armería con unas compras hechas y
## una cosa con el mouse encima, y después los contratos con uno firmado. Saca una captura de cada una.
##   tools/godot_ventana.sh res://tests/base_terminals_look.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var state := BaseState.current
	state.buy("drill")
	state.buy_into("circular_saw", "arm_right")
	state.buy_into("machine_gun", "back_left")
	state.buy("plate_leg")
	state.unequip("plate_arm_left")
	var armory := ArmoryScreen.new()
	TerminalScreen.open_screen(armory, get_tree())
	await get_tree().create_timer(1.0).timeout
	# lo que dice con el mouse encima de la sierra (puesto a mano: la captura no mueve el mouse)
	var cell: ArmoryCell = armory._shop_cells[4]
	var tip := armory.tooltip_for(cell)
	armory.add_child(tip)
	tip.position = cell.global_position + Vector2(cell.size.x * 0.6, cell.size.y * 0.7)
	await _shot("terminal_armeria")
	armory.close()
	state.sign_contract(2)
	var contracts := ContractsScreen.new()
	TerminalScreen.open_screen(contracts, get_tree())
	await get_tree().create_timer(1.0).timeout
	await _shot("terminal_contratos")
	get_tree().quit()


func _shot(file: String) -> void:
	await get_tree().create_timer(0.5).timeout
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/" + file + ".png")
		print("CAPTURA ", _folder + "/" + file + ".png")
