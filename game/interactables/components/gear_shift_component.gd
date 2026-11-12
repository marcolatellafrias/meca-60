class_name GearShiftComponent
extends TwoAxisComponent

## LA PALANCA DE CAMBIOS de un auto manual: CINCO MARCHAS, REVERSA y PUNTO MUERTO, en una H de tres carriles —que
## llena la chapa cuadrada mejor que cuatro—. Es la palanca de dos
## ejes (ver TwoAxisComponent) con GUÍAS: no va a cualquier lado, va por las ranuras de la H.
##
## NO SE INCLINA: SE DESLIZA. La palanca entera va derecha, siempre en el mismo ángulo, y lo que se mueve es su base,
## que recorre la ranura de la chapa: `travel` es cuánto se corre del centro a la punta de una ranura, y coincide
## con la H dibujada (ver GearShiftArchetype).
##
## VA ADONDE SE MIRA (ver PlugComponent): la base persigue el punto de la chapa donde cae el centro de la vista
## —siempre por las guías—, uno a uno. Pero la VISTA VA LENTA (`AIM_SENSITIVITY`): la H es chica, y a la velocidad de
## siempre la palanca se iba demasiado rápido y costaba controlarla. Con el mouse leído aparte de la vista se sentía
## raro; esto es la vista misma, más despacio.
##
##     1   3   5
##     |   |   |
##     +---N---+     ← la barra del medio; PUNTO MUERTO es solo su centro
##     |   |   |
##     2   4   R
##
## Sobre la barra del medio se mueve de costado; desde ella entra en un CARRIL solo estando a la altura de ese
## carril (con un margen generoso, que es leer la intención), y adentro del carril solo va arriba o abajo. Es
## DISCRETA: al soltarla VA A UNA MARCHA o AL PUNTO MUERTO, nunca queda entre medio. Pasada la mitad del carril,
## entra en esa marcha; si no, vuelve al centro —por las guías: primero a la barra, después por ella—. Y va
## DESLIZÁNDOSE (`SETTLE_SPEED`), no de golpe; la marcha cambia al llegar. `gear` es "N", "R" o "1" a "5", y cambia
## con `gear_changed`.
##
## TIENE INERCIA (`INERTIA`, la estándar: ver ControllableInteractable, LA INERCIA): soltada con envión, sigue por las
## guías con la velocidad que llevaba, y recién cuando se apaga decide adónde va. Así se pasa un cambio de un golpe:
## largada a mitad de camino hacia una marcha, entra; y una que entra en su mitad yendo hacia la punta ya es de esa
## marcha, sin esperar a que se apague. Sacada con envión de una marcha, sigue de largo: de la primera, por la barra, a
## la segunda.

signal gear_changed(gear: String)

## Dónde está cada carril (x de la palanca) y qué marcha hay arriba y abajo ("" = no hay).
const LANES: Array[float] = [-1.0, 0.0, 1.0]
const UP: Array[String] = ["1", "3", "5"]
const DOWN: Array[String] = ["2", "4", "R"]
## Qué tan rápido va sola, al soltarla, a la marcha o al centro (unidades del eje por segundo).
const SETTLE_SPEED := 4.0
## Cuánto tarda en apagarse lo que sigue sola al soltarla (s): un envión de una marcha entera por segundo la lleva un
## décimo más.
const INERTIA := 0.3
## Qué tan cerca de un carril hay que estar para entrar, y qué tan ancha es la barra del medio.
const LANE_CATCH := 0.16
const BAR := 0.08

var gear := "N"
## Cuánto se corre la base del centro a la punta de una ranura, en metros. Lo fija el arquetipo.
var travel: float = 0.05


## Lo que había entre donde se miraba y donde estaba la base al agarrarla: agarrarla no la mueve.
var _aim_offset := Vector2.ZERO
## Adónde va sola después de soltarla, y si todavía está yendo.
var _settle_to := Vector2.ZERO
var _settling := false


## Qué fracción de la sensibilidad de siempre tiene la vista mientras se maneja la palanca.
const AIM_SENSITIVITY := 0.25



## Al entrar en un cambio.
const SOUNDS := {CLICK: &"palanca"}

func sounds() -> Dictionary:
	return SOUNDS

func _ready() -> void:
	super._ready()
	auto_return = false
	camera_sensitivity_factor = AIM_SENSITIVITY
	inertia = INERTIA


func start_control() -> void:
	super.start_control()
	_settling = false
	_aim_offset = Vector2.ZERO
	var aim := _aim()
	if aim.is_finite():
		_aim_offset = axis_value - aim


## DONDE SE MIRA, en unidades del eje: el centro de la vista cortado contra la chapa (el plano del cuerpo, que no se
## mueve). Infinito sin vista o mirando de canto.
func _aim() -> Vector2:
	var body := get_parent_node_3d()
	if body == null or not is_instance_valid(grab_view) or not body.is_inside_tree() or travel <= 0.0:
		return Vector2.INF
	var inverse := body.global_transform.affine_inverse()
	var from := inverse * grab_view.global_position
	var dir := inverse.basis * -grab_view.global_basis.z
	if absf(dir.z) < 0.05:
		return Vector2.INF
	var t := -from.z / dir.z
	if t <= 0.0:
		return Vector2.INF
	var hit := from + dir * t
	# −y es arriba (ver TwoAxisComponent).
	return Vector2(hit.x, -hit.y) / travel


func _process(delta: float) -> void:
	if _is_being_controlled:
		var aim := _aim()
		if aim.is_finite():
			_guide(aim + _aim_offset - axis_value)
		_track_motion_2d(axis_value, delta)
	elif coasting():
		# Suelta con envión: sigue por las guías. Entrando en la mitad de una marcha hacia su punta, ya es de esa marcha.
		var before := axis_value
		_guide(_coast_2d(delta))
		if (axis_value.y < -0.5 and coast_velocity.y < 0.0) or (axis_value.y > 0.5 and coast_velocity.y > 0.0):
			_stop_coast()
		else:
			_coasted(not axis_value.is_equal_approx(before))
	elif _settling:
		_settle(delta)


## Sin vista —una prueba—, el mouse empuja la base sobre la chapa.
func handle_mouse_motion(delta: Vector2) -> void:
	if is_instance_valid(grab_view):
		return
	var drag := _drag_world(delta)
	var frame := get_parent_node_3d().global_basis if get_parent_node_3d() != null else global_basis
	_guide(Vector2(_along(drag, frame.x.normalized() * travel), _along(drag, -frame.y.normalized() * travel)))


## MUEVE LA BASE `step` (en unidades del eje), POR LAS GUÍAS: lo que la H no deja, no pasa.
func _guide(step: Vector2) -> void:
	var next := axis_value
	if absf(axis_value.y) <= BAR:
		# EN LA BARRA: de costado libre; para arriba o abajo, solo cerca de un carril, y ahí se alinea con él.
		next.x = clampf(axis_value.x + step.x, -1.0, 1.0)
		var lane := _nearest_lane(next.x)
		if absf(step.y) > absf(step.x) * 0.5 and absf(next.x - LANES[lane]) < LANE_CATCH:
			next.x = LANES[lane]
			next.y = axis_value.y + step.y
		else:
			next.y = 0.0
	else:
		# EN UN CARRIL: solo arriba y abajo, hasta el fondo de su marcha; si no tiene marcha de ese lado, no pasa.
		var lane := _nearest_lane(axis_value.x)
		next.x = LANES[lane]
		next.y = axis_value.y + step.y
	var lane_now := _nearest_lane(next.x)
	# −y es arriba (ver TwoAxisComponent): arriba siempre hay marcha; abajo, solo si el carril la tiene.
	next.y = clampf(next.y, -1.0, 0.0 if DOWN[lane_now].is_empty() else 1.0)
	axis_value = next
	visual_value = axis_value.length()
	state_changed_2d.emit(axis_value)
	_apply_visual()


## Al soltarla, sin envión, decide ya adónde va; con envión, cuando se apague (`_coast_ended`).
func stop_control() -> void:
	_set_gear("N")
	super.stop_control()
	if not coasting():
		_choose_settle()


func _coast_ended() -> void:
	_choose_settle()


## En otra máquina, al soltarla quien la manejaba: si no sigue sola, va adonde fue en la suya.
func _set_coast(coast: Vector2) -> void:
	super._set_coast(coast)
	if coast_velocity.length() < COAST_STOP:
		_choose_settle()


## ADÓNDE VA SOLA: pasada la mitad de un carril, a esa marcha; si no, al centro. Deslizándose (ver `_settle`).
func _choose_settle() -> void:
	var lane := _nearest_lane(axis_value.x)
	if axis_value.y < -0.5:
		_settle_to = Vector2(LANES[lane], -1.0)
	elif axis_value.y > 0.5 and not DOWN[lane].is_empty():
		_settle_to = Vector2(LANES[lane], 1.0)
	else:
		_settle_to = Vector2.ZERO
	_settling = true


## UN PASO HACIA DONDE VA, POR LAS GUÍAS: si tiene que correrse de costado y está en un carril, primero vuelve a la
## barra; de costado solo sobre ella. Al llegar, queda en esa marcha.
func _settle(delta: float) -> void:
	var step := SETTLE_SPEED * delta
	if not is_equal_approx(axis_value.x, _settle_to.x) and not is_zero_approx(axis_value.y):
		axis_value.y = move_toward(axis_value.y, 0.0, step)
	elif not is_equal_approx(axis_value.x, _settle_to.x):
		axis_value.x = move_toward(axis_value.x, _settle_to.x, step)
	else:
		axis_value.y = move_toward(axis_value.y, _settle_to.y, step)
	if axis_value.is_equal_approx(_settle_to):
		axis_value = _settle_to
		_settling = false
		_set_gear(_gear_at(axis_value))
		_came_to_rest()
	visual_value = axis_value.length()
	state_changed_2d.emit(axis_value)
	_apply_visual()


## Lo que llega de quien la maneja manda: lo que estuviera yendo sola acá, se corta.
func apply_sync_state(state: Variant) -> void:
	_settling = false
	super.apply_sync_state(state)
	_set_gear(_gear_at(axis_value))


## Se corre, no se inclina: la base en la ranura, la palanca derecha. −y es arriba (ver TwoAxisComponent).
func _apply_visual() -> void:
	rotation = Vector3.ZERO
	position = Vector3(axis_value.x * travel, -axis_value.y * travel, 0.0)


static func _nearest_lane(x: float) -> int:
	var best := 0
	for i in LANES.size():
		if absf(LANES[i] - x) < absf(LANES[best] - x):
			best = i
	return best


static func _gear_at(at: Vector2) -> String:
	var lane := _nearest_lane(at.x)
	if absf(at.x - LANES[lane]) > 0.01:
		return "N"
	if at.y <= -0.99:
		return UP[lane]
	if at.y >= 0.99 and not DOWN[lane].is_empty():
		return DOWN[lane]
	return "N"


func _set_gear(value: String) -> void:
	if value == gear:
		return
	gear = value
	if is_inside_tree():
		play_sound(CLICK)
	gear_changed.emit(gear)
