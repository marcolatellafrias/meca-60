class_name AttackPanel
extends TunerPanel

## EL PANEL CHICO DE LA ARENA DE ESQUIVAR (F3 en su fila; el usuario: «con un toggle de panel chico pueda togglear entre
## distintas acciones de esta meca enemiga»): qué ataque tira la torre (ver MissileTurret), uno o todos de a uno, y
## apagarla. Actúa sobre la torre de la parcela donde uno está parado.

const PANEL_WIDTH := 280.0


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	var buttons: Array[Button] = []
	for index in MissileTurret.NAMES.size():
		var button := Button.new()
		button.text = "%d. %s" % [index + 1, MissileTurret.NAMES[index]]
		button.pressed.connect(func() -> void:
			_each(func(turret: MissileTurret) -> void: turret.choose(index as MissileTurret.Attack)))
		buttons.append(button)
	var off := Button.new()
	off.text = "Apagar / prender la torre"
	off.pressed.connect(func() -> void: _each(func(turret: MissileTurret) -> void: turret.firing = not turret.firing))
	buttons.append(off)
	setup("ataques", "LA TORRE: QUÉ TIRA", buttons)


func _each(action: Callable) -> void:
	var parcel := sandbox.call("current_parcel") as SandboxParcel if is_instance_valid(sandbox) else null
	if parcel == null:
		return
	for turret: MissileTurret in parcel.find_children("*", "MissileTurret", true, false):
		action.call(turret)
