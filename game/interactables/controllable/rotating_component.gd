class_name RotatingComponent
extends ControllableInteractable

## Cómo se gira. Con la ruedita suma vueltas sin fin, como una válvula. Arrastrando el mouse de costado
## se gira como un volante. MIRANDO (LOOK), el volante: lo que se mira a la derecha o a la izquierda de su centro.
enum InputMode { SCROLL, MOUSE_HORIZONTAL, LOOK }

@export var input_mode:          InputMode = InputMode.SCROLL
@export var sensitivity:         float   = 0.05
## Tope de giro para cada lado, en radianes; 0 = sin tope. Con tope y el mouse es el volante del
## Cybertruck: a fondo sin llegar a dar una vuelta.
@export var max_rotation:        float   = 0.0
## Con tope, si va sólo de cero para arriba: una válvula, que no cierra más que cerrada (ver PipeNetwork).
@export var one_way:             bool    = false
@export var rotation_axis_local: Vector3 = Vector3.UP
@export var height_offset:       float   = 0.0

# 1.0 = handles exactly on the disc circumference; lower values pull them inward.
@export var handle_radius_factor: float = 0.97

## ── EL VOLANTE SE GIRA MIRANDO (29/10/2026, el usuario) ────────────────────────────────────────────────────
## «Yo debería mirar a la derecha y que el volante gire a la derecha… si miro al centro, no importa de qué ángulo estaba,
## siempre voy a volver al punto medio». Con `InputMode.LOOK`, mientras se lo agarra el giro ES el ángulo de costado
## entre adonde mira quien lo maneja y el centro del volante, por `look_gain`: mirar al centro lo endereza; mirar a la
## derecha lo gira a la derecha (horario visto de frente, valor que baja). No depende de dónde se lo agarró ni de la
## distancia. *Se giraba empujando el aro por el punto agarrado, proyectado en la vista: agarrado de abajo iba al revés,
## y de frente rendía distinto que de costado.*
## Cuánto gira el volante por cada grado que se mira de costado.
@export var look_gain: float = 3.0

var total_rotation: float = 0.0

## ── SE INCLINA HACIA QUIEN SE SIENTA (el volante) ────────────────────────────────────────────────
## Con `stretch_max` > 0 tiene un fuelle en vez de eje (`bellows`, lo pone ControlArchetype.dress) y, cuando alguien se
## sienta en la silla de su puesto (ver SeatInteractable.station), se INCLINA desde su base para que su eje apunte a la
## punta del pecho de quien se sentó —de donde salen los brazos—, hasta `TILT_MAX`; el fuelle se curva con él. Al
## levantarse, vuelve. Lo decidió el usuario (11/10/2026): un ajuste de ángulo, no de largo —antes se estiraba
## hacia adelante al agarrarlo, y eso nunca fue lo pensado—, y guiado por los brazos y no por la cara, porque se maneja
## mirando al parabrisas y no al volante. La punta del pecho sale del asiento y no de los huesos, así que respirar no lo
## mueve. Parado, nadie lo ajusta.
@export var stretch_max: float = 0.0
var bellows: BellowsSleeve = null
## Hasta cuánto se inclina, y qué tan rápido.
const TILT_MAX := deg_to_rad(35.0)
const TILT_SPEED := 1.5
var _sitter: Node = null
var _tilt := 0.0
## Alrededor de qué se inclina, en el marco del cuerpo: perpendicular a su eje (+Z) y a quien se sentó.
var _tilt_axis := Vector3.RIGHT



## UN TIC POR PASO DE LA RUEDITA, y al girarla, UN LOOP PARA CADA LADO (ver SoundEntity.move_sound). Y GIRANDO SOLA
## —la inercia, un reloj—, otro.
const SOUNDS := {
	CLICK: &"perilla",
	MOVE_UP: &"rueda_derecha",
	MOVE_DOWN: &"rueda_izquierda",
	MOVE_SELF: &"rueda_sola",
}

func sounds() -> Dictionary:
	return SOUNDS

## UNA MANO SI EL ARO ES CHICO —una perilla, una válvula chica—, DOS SI ES GRANDE —el volante, una válvula grande—
## (lo decidió el usuario, 11/10/2026): por el radio de sus puntos. Medidos: volante y rueda 0,25 m, válvula
## grande 0,14, perilla 0,06, válvula chica 0,03.
const TWO_HANDS_RADIUS := 0.1

## Se empuña: el puño alrededor del aro (ver Interactable.Grip.WRAP; lo pidió el usuario, 29/10/2026: «la valve y
## el volante deberían ir con pose de puño también… orientado de otra manera, entonces parecerá que lo está agarrando»).
func grip_kind() -> Grip:
	return Grip.WRAP


func hands() -> int:
	if handle_points.size() <= 1:
		return 1
	var radius := 0.0
	for point in handle_points:
		if is_instance_valid(point):
			radius = maxf(radius, Vector2(point.position.x, point.position.y).length())
	return 2 if radius >= TWO_HANDS_RADIUS else 1


func fit_to_seat(sitter: Node) -> void:
	if stretch_max > 0.0:
		_sitter = sitter


func leave_seat() -> void:
	_sitter = null


func _process(delta: float) -> void:
	# LA INERCIA (ver ControllableInteractable): agarrado se mide; suelto, sigue girando hasta apagarse. Contra un tope,
	# se frena.
	if _is_being_controlled and input_mode == InputMode.SCROLL and inertia > 0.0:
		# Agarrada y con la ruedita suave: va con los empujones que le dio (ver `handle_scroll`).
		if coast_velocity.length() >= COAST_STOP:
			var pushed := total_rotation
			_turn(_coast(delta))
			_coasted(not is_equal_approx(pushed, total_rotation))
	elif _is_being_controlled:
		if input_mode == InputMode.LOOK:
			_look()
		_track_motion(total_rotation, delta)
	elif coasting():
		var before := total_rotation
		_turn(_coast(delta))
		_coasted(not is_equal_approx(before, total_rotation))
	if stretch_max > 0.0:
		_fit(delta)


## LA INCLINACIÓN hacia quien está sentado (ver SE INCLINA HACIA QUIEN SE SIENTA): el giro alrededor de la base que lleva
## el eje (+Z del cuerpo) hacia la punta de su pecho. Sin nadie, vuelve a cero por el mismo eje.
func _fit(delta: float) -> void:
	var body := get_parent_node_3d()
	var target := 0.0
	if body != null and is_instance_valid(_sitter) and _sitter.has_method("get_interaction_origin"):
		var to := body.global_basis.orthonormalized().inverse() \
			* ((_sitter.call("get_interaction_origin") as Vector3) - body.global_position)
		var turn := Vector3.BACK.cross(to.normalized())
		if turn.length_squared() > 1e-6:
			_tilt_axis = turn.normalized()
			target = minf(Vector3.BACK.angle_to(to), TILT_MAX)
	if is_equal_approx(_tilt, target):
		return
	_tilt = move_toward(_tilt, target, TILT_SPEED * delta)
	_apply_visual()
	if bellows != null:
		# El fuelle se dobla alrededor de su X: se lo gira sobre su eje para que esa X sea la de la inclinación, y su
		# punta cae donde el volante girado como un bloque (ver BellowsSleeve.pose).
		bellows.rotation.z = atan2(_tilt_axis.y, _tilt_axis.x)
		bellows.pose(_tilt, height_offset)

## Nace en su reposo: el giro acumulado arranca donde lo pone la base (ver ControllableInteractable._ready).
func _ready() -> void:
	super._ready()
	total_rotation = visual_value

func apply_sync_state(state: Variant) -> void:
	total_rotation = state  # el visual y el control local leen de acá
	super(state)

func handle_scroll(delta: float) -> void:
	if input_mode != InputMode.SCROLL:
		return
	if positions.size() > 0:
		_step(-signf(delta))
		return
	# CON INERCIA, LA RUEDITA ES SUAVE (la válvula grande): la muesca no salta, le da un empujón —la velocidad que,
	# apagándose con la inercia, recorre lo mismo que el salto— y sigue girando sola hasta frenarse.
	if inertia > 0.0:
		coast_velocity.x += delta * sensitivity * 3.0 / inertia
		return
	_turn(delta * sensitivity)


## A DIENTES: con posiciones (una perilla, ver RotaryArchetype), cada vuelta de la ruedita lo lleva a la siguiente —para
## arriba, a la de después en la lista; para abajo, a la de antes—, con un clic. En las puntas, no pasa.
func _step(direction: float) -> void:
	var here := 0
	for i in positions.size():
		if absf(positions[i] - total_rotation) < absf(positions[here] - total_rotation):
			here = i
	var next := clampi(here + int(direction), 0, positions.size() - 1)
	if next == here and is_equal_approx(total_rotation, positions[here]):
		return
	total_rotation = positions[next]
	visual_value = total_rotation
	_emit_if_changed(total_rotation)
	_apply_visual()
	if is_inside_tree():
		play_sound(CLICK)

## COMO UN VOLANTE: la mano empuja el aro por donde lo agarró, y el aro gira lo que la mano se mueve a lo largo
## de él (ver ControllableInteractable, EL MOUSE SE LEE COMO INTENCIÓN). Agarrado arriba, a la derecha es
## horario; agarrado del costado izquierdo, ARRIBA es horario. La mano se DESLIZA por el aro: cuenta el punto
## donde se lo agarró, no el que se va con el giro, así que se puede seguir empujando para el mismo lado.
## Horario visto de frente (con el eje hacia quien mira, BACK) es valor que baja.
func handle_mouse_motion(delta: Vector2) -> void:
	if input_mode == InputMode.LOOK:
		_look()
		return
	if input_mode != InputMode.MOUSE_HORIZONTAL:
		return
	var axis := (global_basis * rotation_axis_local).normalized()
	var hand := get_parent_node_3d().to_global(_grab_local) if get_parent_node_3d() != null else _hand_world()
	var radius := hand - global_position
	radius -= axis * radius.dot(axis)
	if radius.length() < 0.01:
		radius = global_basis.y.normalized() * 0.1
	_turn(_along(_drag_world(delta), axis.cross(radius)))


## EL GIRO POR LA MIRADA (ver `look_gain`): el ángulo de costado —alrededor del arriba del mundo— de la dirección al
## centro a la de la mirada. Sin cámara, nada.
func _look() -> void:
	if not is_instance_valid(grab_view):
		return
	var looking := -grab_view.global_basis.z
	var to_centre := global_position - grab_view.global_position
	looking.y = 0.0
	to_centre.y = 0.0
	if looking.length_squared() < 1e-8 or to_centre.length_squared() < 1e-8:
		return
	var side := to_centre.normalized().signed_angle_to(looking.normalized(), Vector3.UP)
	_turn(side * look_gain - total_rotation)


## Dónde agarró la mano, en el espacio del cuerpo del control, que no gira.
var _grab_local := Vector3.ZERO


func start_control() -> void:
	super.start_control()
	var body := get_parent_node_3d()
	if body != null:
		_grab_local = body.to_local(_hand_world())

func _turn(amount: float) -> void:
	total_rotation += amount
	if max_rotation > 0.0:
		total_rotation = clampf(total_rotation, 0.0 if one_way else -max_rotation, max_rotation)
	visual_value = total_rotation
	_emit_if_changed(total_rotation)
	_apply_visual()

func _do_auto_return(delta: float) -> void:
	total_rotation = move_toward(total_rotation, 0.0, return_speed * delta)
	visual_value   = total_rotation
	_emit_if_changed(total_rotation)
	_apply_visual()

func _apply_visual() -> void:
	var spin := Basis.from_euler(_rest_rot() + rotation_axis_local * visual_value)
	transform.basis = Basis(_tilt_axis, _tilt) * spin if _tilt != 0.0 else spin

func mesh_offset() -> Vector3:
	return Vector3(0.0, 0.0, height_offset)

func _setup_handle_points(size: Vector3) -> void:
	var disc_radius  : float = min(size.x, size.y) * 0.42
	var radius       : float = disc_radius * clamp(handle_radius_factor, 0.0, 1.0)
	var handle_count : int   = clamp(int((radius * TAU) / 0.1), 3, 8)
	for i in handle_count:
		var angle := (TAU / handle_count) * i
		# LA BARRA DEL PUNTO ES EL ARO: el puño lo envuelve.
		add_handle_point_local(Vector3(cos(angle) * radius, sin(angle) * radius, height_offset),
			Vector3(-sin(angle), cos(angle), 0.0))
