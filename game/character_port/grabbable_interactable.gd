class_name GrabbableInteractable
extends Interactable

## PIEZA PARA LOS PERSONAJES DE CHARACTER-PARAMETRIC (ver LEEME.md de esta carpeta): allá esto es algo que se agarra con la mano (un paquete);
## acá sólo está lo que los personajes le piden.

const FORCE_PER_STRENGTH := 1600.0

var box_half := Vector3.ZERO


func hold_count() -> int:
	return 0


func total_strength() -> float:
	return 0.0


static func face_of(local: Vector3, half: Vector3) -> Vector3:
	var r := Vector3(absf(local.x) / maxf(half.x, 0.001), absf(local.y) / maxf(half.y, 0.001),
		absf(local.z) / maxf(half.z, 0.001))
	if r.x >= r.y and r.x >= r.z:
		return Vector3(signf(local.x), 0.0, 0.0)
	if r.y >= r.z:
		return Vector3(0.0, signf(local.y), 0.0)
	return Vector3(0.0, 0.0, signf(local.z))


static func load_of(mass: float, strength: float) -> float:
	return mass * 9.8 / maxf(strength * FORCE_PER_STRENGTH, 0.001)
