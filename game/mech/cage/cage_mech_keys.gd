class_name CageMechKeys
extends ToolMechKeys

## LAS TECLAS DE LA MECA JAULA (CageMech), poseyéndola desde afuera: las de la Meca de tres (las piernas, lo que lleva
## en los brazos, la energía), con la cámara de afuera más cerca: es chica.
## *Hasta el 16/11/2026 tenía las piñas del palo con el clic; pasaron a ToolMechKeys, para cualquier meca con un brazo
## de piñas.*

## La cámara de afuera: atrás y arriba (m), y adónde mira, sobre la caja.
const CHASE := Vector3(0.0, 4.5, 10.0)
const LOOK_UP := 1.0


func camera(first: bool, delta: float) -> Transform3D:
	if first:
		return super(first, delta)
	_chase_yaw = lerp_angle(_chase_yaw, _view_yaw(), 1.0 - exp(-4.0 * delta))
	var from := mech.global_position + Basis(Vector3.UP, _chase_yaw) * CHASE
	return Transform3D(Basis(), from).looking_at(mech.global_position + Vector3(0.0, LOOK_UP, 0.0), Vector3.UP)
