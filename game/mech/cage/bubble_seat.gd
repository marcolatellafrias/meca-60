class_name BubbleSeat
extends SeatInteractable

## LA SILLA DEL QUE MANEJA LA MECA JAULA: LA DE SIEMPRE (sube y baja con el arquetipo, gira con la mirada hasta su tope,
## recuesta al mirar arriba), sentada en la caja de abajo detrás de la burbuja. Lo único propio: LA CÁMARA DE PRIMERA
## PERSONA va a `eye_point` —el centro de la cápsula facetada (CageCabin.driver_eye)—
## y no a los ojos (16/11/2026, el usuario: «podemos… mover nosotros mismos la cámara… como un offset»; «decido la
## profundidad de los ojos, con una perilla»). Sólo se ven las manos.
## *Antes (el mismo día) fue ReclineSeat: una silla curva fija y después la de siempre inclinada, con los pies por IK a
## una esfera donde iba la persona entera. Se dejó al volver a la burbuja como ventana de la maqueta 166.*

const SEAT_SCENE := "res://game/interactables/activatable/procedural_seat.tscn"

## Los ojos de la primera persona, en el espacio del padre de la silla.
var eye_point := Vector3.ZERO
## LA ALTURA DE LA SILLA (CageShape.seat_height): la pelvis sobre la base, la misma para todos, salvo que a alguno le
## quede más corta que su pierna (`_drop`). *La de siempre sube y baja para que los ojos de cada uno queden a
## `eye_height`; acá los ojos de la cámara ya están fijos.*
var seat_height := 0.42
## Lo que necesita el que está sentado para no meter los pies en el piso: su canilla y del tobillo a la suela.
var _drop := 0.0


func _init() -> void:
	rest_height = 0.42
	seat_area = Vector3(0.48, 1.0, 0.6)
	stand_up_location = Vector2(1.0, 0.0)
	seat_scene = load(SEAT_SCENE) as PackedScene
	# *Hasta el 17/11/2026 tomaba `eye_height` de la cabina cuadrada de la meca grande (CabinGrid.EYE_HEIGHT); acá no se
	# usa: la altura sale de `seat_height` (ver `_height_for`).*


func _height_for(_eye_above_pelvis: float) -> float:
	return maxf(seat_height, _drop)


func _measure_occupant(who: Node) -> void:
	super(who)
	var sizes: SkeletonSizesUtil = who.get("skel_sizes_util") if is_instance_valid(who) else null
	_drop = sizes.lower_leg_size.y + sizes.ankle_height + 0.05 if sizes != null else 0.0


func camera_point() -> Variant:
	var parent := get_parent() as Node3D
	return parent.global_transform * eye_point if parent != null else null
