class_name TwoAxisComponent
extends ControllableInteractable

@export var sensitivity:       float = 0.005
@export var max_angle_degrees: float = 30.0

var axis_value: Vector2 = Vector2.ZERO

signal state_changed_2d(value: Vector2)

func get_sync_state() -> Variant:
	return axis_value

func apply_sync_state(state: Variant) -> void:
	axis_value   = state
	visual_value = axis_value.length()
	_apply_visual()
	state_changed_2d.emit(axis_value)

## LA PUNTA SIGUE AL MOUSE (ver ControllableInteractable, EL MOUSE SE LEE COMO INTENCIÓN): cada eje cuenta lo
## que el arrastre lleva la punta a lo largo del tablero (x) y hacia arriba de él (y, que es valor negativo).
func handle_mouse_motion(delta: Vector2) -> void:
	var drag := _drag_world(delta)
	var reach := (_hand_world() - global_position).length() * deg_to_rad(max_angle_degrees)
	var step := Vector2(_along(drag, global_basis.x.normalized() * reach), _along(drag, -global_basis.y.normalized() * reach))
	axis_value   = (axis_value + step).limit_length(1.0)
	visual_value = axis_value.length()
	state_changed_2d.emit(axis_value)
	_apply_visual()

## LA INERCIA (ver ControllableInteractable): agarrada se mide; suelta, sigue con la velocidad que llevaba hasta
## apagarse. Contra el borde, lo que empuja hacia afuera se pierde y sigue lo que va a lo largo.
func _process(delta: float) -> void:
	if inertia <= 0.0:
		return
	if _is_being_controlled:
		_track_motion_2d(axis_value, delta)
	elif coasting():
		var before := axis_value
		axis_value = (axis_value + _coast_2d(delta)).limit_length(1.0)
		if axis_value.length() > 0.999:
			var out := axis_value.normalized()
			coast_velocity -= out * maxf(coast_velocity.dot(out), 0.0)
		visual_value = axis_value.length()
		state_changed_2d.emit(axis_value)
		_apply_visual()
		_coasted(not axis_value.is_equal_approx(before))


func _do_auto_return(delta: float) -> void:
	axis_value   = axis_value.move_toward(Vector2.ZERO, return_speed * delta)
	visual_value = axis_value.length()
	state_changed_2d.emit(axis_value)
	_apply_visual()

# La palanca sale por +Z, hacia quien la usa. x positivo la inclina hacia +X del tablero; y negativo, hacia +Y
# (hacia arriba del tablero, "adelante"). Antes se inclinaba al revés del mouse.
func _apply_visual() -> void:
	rotation = _rest_rot() + Vector3(
		axis_value.y * deg_to_rad(max_angle_degrees),
		axis_value.x * deg_to_rad(max_angle_degrees),
		0.0
	)

## La mano va en la punta de la palanca (ControlArchetype dibuja la bola ahí).
func _setup_handle_points(size: Vector3) -> void:
	var t       := size.z * 0.5
	var stick_h : float = min(size.x, size.y) * 0.55
	add_handle_point_local(Vector3(0.0, 0.0, t + stick_h))
