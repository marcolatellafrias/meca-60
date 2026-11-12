class_name HoverKnockPanel
extends TunerPanel

## EL PANEL CHICO DEL CUBO FLOTANTE (F2 en la fila Cubo flotante): dos botones que lo vuelcan sin tirarle bolas, uno
## suave y uno fuerte (ver HoverCube.knock). Actúa sobre el cubo de la parcela donde uno está parado.

const PANEL_WIDTH := 260.0


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	var soft := Button.new()
	soft.text = "Volcarlo suave"
	soft.pressed.connect(func() -> void: _knock(false))
	var strong := Button.new()
	strong.text = "Volcarlo fuerte"
	strong.pressed.connect(func() -> void: _knock(true))
	setup("volcar", "VOLCAR EL CUBO", [soft, strong] as Array[Button])


func _knock(strong: bool) -> void:
	var parcel := sandbox.call("current_parcel") as SandboxParcel if is_instance_valid(sandbox) else null
	if parcel == null:
		return
	for cube: HoverCube in parcel.find_children("*", "HoverCube", true, false):
		cube.knock(strong)
