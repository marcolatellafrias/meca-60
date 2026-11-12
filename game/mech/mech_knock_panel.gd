class_name MechKnockPanel
extends TunerPanel

## EL PANEL CHICO DE LA MECA (F2 en sus filas): pegarle arriba sin tirarle bolas, suave y fuerte (ver Mech.knock; el
## usuario: «un botón… que la vuelque, una más suavemente otra más fuerte»), y bajar y subir su ascensor (PelvisLift).
## Actúa sobre las mecas de la parcela donde uno está parado.

const PANEL_WIDTH := 260.0


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	var soft := Button.new()
	soft.text = "Pegarle suave"
	soft.pressed.connect(func() -> void: _each(func(mech: Mech) -> void: mech.knock(false)))
	var strong := Button.new()
	strong.text = "Pegarle fuerte"
	strong.pressed.connect(func() -> void: _each(func(mech: Mech) -> void: mech.knock(true)))
	var ride := Button.new()
	ride.text = "Ascensor: bajar / subir"
	ride.pressed.connect(func() -> void: _each(func(mech: Mech) -> void: mech.cabin.lift.toggle()))
	setup("pegarle", "PEGARLE A LA MECA", [soft, strong, ride] as Array[Button])


func _each(action: Callable) -> void:
	var parcel := sandbox.call("current_parcel") as SandboxParcel if is_instance_valid(sandbox) else null
	if parcel == null:
		return
	for mech: Mech in parcel.find_children("*", "Mech", true, false):
		action.call(mech)
