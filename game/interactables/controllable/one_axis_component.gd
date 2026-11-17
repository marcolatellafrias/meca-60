class_name OneAxisComponent
extends ControllableInteractable

## LA PALANCA: dos brazos que salen de un eje en el tablero y una empuñadura entre ellos, como las palancas de
## siempre. Gira sobre su eje X y VA DE PUNTA A PUNTA DE SUS CELDAS: la empuñadura recorre todo el alto, de un
## borde al otro, casi acostada contra el tablero en cada extremo. El recorrido y el largo no se eligen: salen
## del tamaño (`fit`), así que una palanca más chica es también más corta.
##
## El valor va de `min_value` a `max_value`; en el mínimo la empuñadura está arriba y en el máximo, abajo.
## Se maneja ARRASTRANDO LA EMPUÑADURA: el mouse se lee como adónde se la quiere llevar (ver
## ControllableInteractable, EL MOUSE SE LEE COMO INTENCIÓN).

## Se empuña: el puño alrededor del mango, los nudillos a lo largo de su barra (ver Interactable.Grip.WRAP; la categoría
## de empuñar una barra que se mueve, 29/10/2026).
func grip_kind() -> Grip:
	return Grip.WRAP

## A cuántos grados del tablero queda la palanca en cada extremo, medido desde la normal: 75 deja la
## empuñadura a 15° del tablero, que se ve acostada sin meterse en él.
const SWEEP_HALF_DEG := 75.0

@export var sensitivity:         float     = 0.005
@export var min_value:           float     = 0.0
@export var max_value:           float     = 1.0
@export var rotation_axis_local: Vector3   = Vector3.RIGHT
@export var max_angle_degrees:   float     = 45.0

## El largo del brazo, del eje a la empuñadura, en metros. Lo fija `fit`.
var arm_length: float = 0.1

## AL CORRERSE, EL ROCE, con CONTINUIDAD (`resume`, ver SoundEntity): la palanca que se mueve de a poco suena como un
## solo recorrido, y más fuerte cuanto más rápido (a pleno, a medio recorrido por segundo). Las que la heredan y suenan
## además al llegar al fondo (PullLever) lo repiten en su `SOUNDS`.
const SLIDE := {"keys": &"palanca_corre", "resume": true, "speed": 0.5}
const SOUNDS := {MOVE: SLIDE}

func sounds() -> Dictionary:
	return SOUNDS


## EL LARGO DEL BRAZO de una palanca de `size` (la caja del control): el que lleva la empuñadura justo al borde
## de sus celdas cuando está a SWEEP_HALF_DEG de la normal.
static func arm_for(size: Vector3) -> float:
	return (size.y * 0.5 - grip_radius(size)) / sin(deg_to_rad(SWEEP_HALF_DEG))


## El radio de la empuñadura.
static func grip_radius(size: Vector3) -> float:
	return clampf(minf(size.x, size.y) * 0.08, 0.007, 0.016)


func handle_mouse_motion(delta: Vector2) -> void:
	var span := max_value - min_value
	if span <= 0.0:
		return
	# Cómo se mueve la empuñadura por unidad de valor: tangente a su arco, del largo del brazo.
	var axis := (global_basis * rotation_axis_local).normalized()
	var arm := _hand_world() - global_position
	var tangent := axis.cross(arm) * deg_to_rad(max_angle_degrees) / span
	visual_value = clampf(visual_value + _along(_drag_world(delta), tangent), min_value, max_value)
	if positions.is_empty():
		_emit_if_changed(visual_value)
	_apply_visual()


## LA INERCIA (ver ControllableInteractable): agarrada se mide; suelta, sigue con la velocidad que llevaba hasta
## apagarse o llegar a una punta.
func _process(delta: float) -> void:
	if inertia <= 0.0:
		return
	if _is_being_controlled:
		_track_motion(visual_value, delta)
	elif coasting():
		var before := visual_value
		visual_value = clampf(visual_value + _coast(delta), min_value, max_value)
		if positions.is_empty():
			_emit_if_changed(visual_value)
		_apply_visual()
		_coasted(not is_equal_approx(before, visual_value))


func _do_auto_return(delta: float) -> void:
	visual_value = move_toward(visual_value, default_value, return_speed * delta)
	_emit_if_changed(visual_value)
	_apply_visual()


func _apply_visual() -> void:
	var t := inverse_lerp(min_value, max_value, visual_value)
	rotation = _rest_rot() + rotation_axis_local * deg_to_rad(lerpf(0.0, max_angle_degrees, t))


## El recorrido y el largo salen del tamaño: de SWEEP_HALF_DEG hacia arriba a SWEEP_HALF_DEG hacia abajo.
func _setup_handle_points(size: Vector3) -> void:
	arm_length = arm_for(size)
	max_angle_degrees = SWEEP_HALF_DEG * 2.0
	rest_rotation_deg = Vector3(-SWEEP_HALF_DEG, 0.0, 0.0)
	# EL MANGO VA ATRAVESADO, paralelo al eje de giro: esa es la barra que se envuelve, no el palo. Tomando el palo, la
	# palanca se agarraba al revés (lo vio el usuario).
	add_handle_point_local(Vector3(0.0, 0.0, arm_length), rotation_axis_local)
	_apply_visual()
