extends Node

## LAS TECLAS F DE LA PARTIDA (con ventana, unos 12 s): F1 abre el equipo y F2 los contratos; cambiar el equipo cambia los
## brazos de la meca en vivo, en su lugar, también con alguien arriba; después de arrancar el ascensor no abren. No escribe
## el archivo guardado del equipo. Termina con PANELES OK o PANELES MAL.

var _bad := 0


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	SessionManager.host()
	var world := (load("res://game/base/base_world.tscn") as PackedScene).instantiate() as BaseWorld
	add_child(world)
	_run(world)


func _run(world: BaseWorld) -> void:
	await _wait(2.5)
	var panels := world.get_node("PanelesF") as BasePanels
	var player := DesignSandbox.player_of(get_tree())
	player.player_controller._shown = false
	await _key(KEY_F1)
	_check("F1 abre el equipo", panels.equipment.visible and not UIState.gameplay_active())
	await _key(KEY_F2)
	_check("con el equipo abierto, F2 no abre otra encima", TerminalScreen.opened == null)
	await _key(KEY_F1)
	_check("F1 lo cierra", not panels.equipment.visible and UIState.gameplay_active())
	await _key(KEY_F2)
	_check("F2 abre los contratos", TerminalScreen.opened is ContractsScreen)
	await _key(KEY_F1)
	_check("con los contratos abiertos, F1 no abre", not panels.equipment.visible)
	await _key(KEY_F2)
	_check("F2 los cierra", TerminalScreen.opened == null and UIState.gameplay_active())
	var base := world.get_node("Base") as Node3D
	var sync := world.get_node(BaseSync.NAME) as BaseSync
	var before := base.get_node("Meca jaula") as CageMech
	var spot := before.mover.global_position
	print("antes: ", _tips(before))
	sync._equip([ArmLoadout.Tip.DRILL, true, ArmLoadout.Tip.SHIELD, false])
	await _wait(0.8)
	var after := base.get_node("Meca jaula") as CageMech
	print("después: ", _tips(after), " · se corrió %.2f m" % spot.distance_to(after.mover.global_position))
	_check("el brazo izquierdo cambió", after.arms[0].tip is DrillTip)
	_check("el brazo derecho cambió", after.arms[1].tip is ShieldTip)
	_check("sigue en su lugar", spot.distance_to(after.mover.global_position) < 0.3)
	player.place_at(after.mover.global_position + Vector3(2.4, 0.1, 0.0), PI * 0.5)
	player.player_controller.camera_yaw = PI * 0.5
	await _wait(0.5)
	player.intent.activate = true
	await _wait(0.8)
	_check("subido", player.is_seated)
	sync._equip([ArmLoadout.Tip.SAW, false, ArmLoadout.Tip.CANNON, false])
	await _wait(1.0)
	var third := base.get_node("Meca jaula") as CageMech
	print("con alguien arriba: ", _tips(third), " · sentado ", player.is_seated, " · en la silla nueva ",
		third.cabin.chairs.has(player.current_seat), " · altura ", player.char_rigidbody.global_position.y)
	_check("con alguien arriba también cambia", third.arms[0].tip is SawTip and third.arms[1].tip is CannonTip)
	_check("el de arriba no queda en una silla borrada", not player.is_seated or third.cabin.chairs.has(player.current_seat))
	BaseState.current.contract = 0
	var elevator := base.find_child("Ascensor", true, false) as BaseElevator
	elevator.launch()
	await _wait(0.4)
	await _key(KEY_F1)
	_check("después de arrancar, F1 no abre", not panels.equipment.visible)
	await _key(KEY_F2)
	_check("después de arrancar, F2 no abre", TerminalScreen.opened == null)
	print("PANELES OK" if _bad == 0 else "PANELES MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _tips(mech: CageMech) -> String:
	return "%s / %s" % [mech.arms[0].tip.get_script().get_global_name(), mech.arms[1].tip.get_script().get_global_name()]


func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await _wait(0.1)


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
