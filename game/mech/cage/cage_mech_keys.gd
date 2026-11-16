class_name CageMechKeys
extends ToolMechKeys

## LAS TECLAS DE LA MECA JAULA (CageMech), poseyéndola desde afuera: las de la Meca de tres (las piernas, el cañón, la
## energía) y, en lugar del taladro, EL PALO del brazo derecho (físico): clic izquierdo, un directo; clic derecho, un
## gancho. La cámara de afuera, más cerca: es chica.

## La cámara de afuera: atrás y arriba (m), y adónde mira, sobre la caja.
const CHASE := Vector3(0.0, 4.5, 10.0)
const LOOK_UP := 1.0


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if driving and click != null and click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var cage := mech as CageMech
		if click.pressed and UIState.gameplay_active() and cage.energy.able():
			cage.pole.punch(MechArm.Punch.STRAIGHT if click.button_index == MOUSE_BUTTON_LEFT else MechArm.Punch.HOOK)
		get_viewport().set_input_as_handled()
		return
	super(event)


func camera(first: bool, delta: float) -> Transform3D:
	if first:
		return super(first, delta)
	_chase_yaw = lerp_angle(_chase_yaw, _view_yaw(), 1.0 - exp(-4.0 * delta))
	var from := mech.global_position + Basis(Vector3.UP, _chase_yaw) * CHASE
	return Transform3D(Basis(), from).looking_at(mech.global_position + Vector3(0.0, LOOK_UP, 0.0), Vector3.UP)


func controls() -> PackedStringArray:
	return PackedStringArray([
		"PIERNAS: WASD · mouse gira · Shift+dirección dash · espacio salta, y en el aire levita · Ctrl se agacha",
		"PALO (der., físico): clic izquierdo directo · clic derecho gancho",
		"CAÑÓN (izq.): flechas la palanca · 1 simple, 2 ráfaga, 3 barrido, 4 súper · F el gatillo",
		"todo gasta la energía común; vacía, la meca queda aturdida",
	])
