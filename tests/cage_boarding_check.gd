extends Node

## SUBIRSE A LA MECA JAULA CON LA E (CageBoarding), en el sandbox entero: el jugador se sube (va al puesto del que
## maneja y su maniquí se va), pasa con el 2 al de los brazos (vuelve el maniquí de abajo), con el 3 al del artillero, y
## se para. Imprime dónde está y cuántos maniquíes hay en cada paso.

func _ready() -> void:
	MechCabin.dummies_on = true
	add_child((load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate())
	await get_tree().create_timer(8.0, true, false, true).timeout
	var mech := get_tree().root.find_children("*", "CageMech", true, false)[0] as CageMech
	var cabin := mech.cabin as CageCabin
	var boarding := mech.find_children("*", "CageBoarding", true, false)[0] as CageBoarding
	var player := DesignSandbox.player_of(get_tree())
	_report("ANTES", player, cabin)
	boarding.activate(player)
	await _wait()
	_report("E", player, cabin)
	for key: Key in [KEY_2, KEY_3, KEY_1]:
		var press := InputEventKey.new()
		press.physical_keycode = key
		press.pressed = true
		boarding._unhandled_key_input(press)
		await _wait()
		_report(OS.get_keycode_string(key), player, cabin)
	(player.current_seat as SeatInteractable).activate(player)
	await _wait()
	_report("E DE NUEVO (se para)", player, cabin)
	get_tree().quit()


func _wait() -> void:
	await get_tree().create_timer(1.0, true, false, true).timeout


func _report(step: String, player: BoneInstantiator, cabin: CageCabin) -> void:
	var where := "parado"
	if player.is_seated:
		where = "en %s" % (player.current_seat as Node).name
	var alive := 0
	for dummy in cabin.dummies:
		alive += 1 if is_instance_valid(dummy) else 0
	print("SUBIRSE %s · el jugador %s · maniquíes %d" % [step, where, alive])
