class_name KnobComponent
extends RotatingComponent

## LA PERILLA ES SÓLO DISCRETA, POR CONSTRUCCIÓN (la regla, en docs/technical/panel-pieces.md, «The knob: discrete
## only, by construction»). Nace con sus posiciones —de MIN_POSITIONS a MAX_POSITIONS— y no tiene otra manera de
## existir: `KnobComponent.new()` sin ellas no compila. La ruedita la pasa de una a la siguiente, con un clic (ver
## RotatingComponent._step); el mouse no la gira. Se lee QUÉ POSICIÓN (`selected`, `position_changed`), nunca un ángulo
## suelto, y se elige con `select`: no hay un valor libre que ponerle.
##
## No se arma a mano: la pide RotaryArchetype.knob(rótulos), que le da un ángulo por rótulo y pone la marca de cada uno;
## el tablero (ProceduralDashboard) la crea con la definición de la perilla (ControlArchetype.knob_definition) y se niega
## a armar una perilla sin posiciones válidas.

## Cuántas posiciones puede tener: dos como mínimo —una sola no es un control— y doce como máximo, que es lo que se
## distingue a ojo alrededor de una perilla.
const MIN_POSITIONS := 2
const MAX_POSITIONS := 12

## Pasó a otra posición: su índice en `positions`.
signal position_changed(index: int)

var _selected := -1



## Un tic por posición. No suena como rueda: se pasa de a una.
const KNOB_SOUNDS := {CLICK: &"perilla"}

func sounds() -> Dictionary:
	return KNOB_SOUNDS

## Si `angles` son las posiciones de una perilla posible: de MIN_POSITIONS a MAX_POSITIONS.
static func valid(angles: Array[float]) -> bool:
	return angles.size() >= MIN_POSITIONS and angles.size() <= MAX_POSITIONS


## La perilla con sus posiciones, un ángulo cada una (radianes, alrededor de su eje), en el orden en que la ruedita las
## recorre.
func _init(angles: Array[float]) -> void:
	if not valid(angles):
		push_error("[Perilla] %d posiciones: una perilla tiene de %d a %d (ver RotaryArchetype.knob)."
			% [angles.size(), MIN_POSITIONS, MAX_POSITIONS])
	positions = angles.duplicate()
	input_mode = InputMode.SCROLL


func _ready() -> void:
	super._ready()
	_selected = _index_of(_network_state)


## En qué posición está: su índice en `positions`.
func selected() -> int:
	return _index_of(total_rotation)


## La lleva a la posición `index` (en esta máquina, como la ruedita), con su clic.
func select(index: int) -> void:
	var at: float = positions[clampi(index, 0, positions.size() - 1)]
	if is_equal_approx(total_rotation, at):
		return
	total_rotation = at
	visual_value = at
	_emit_if_changed(at)
	_apply_visual()
	if is_inside_tree():
		play_sound(CLICK)


## El mouse no la gira: sólo la ruedita.
func handle_mouse_motion(_delta: Vector2) -> void:
	pass


## Todo cambio de estado pasa por acá —la ruedita, al soltarla, lo que llega por la red—: si cambió de posición, avisa.
func _emit_if_changed(new_state: float) -> void:
	super(new_state)
	var index := _index_of(_network_state)
	if index != _selected:
		_selected = index
		position_changed.emit(index)


## La posición más cercana a `angle`.
func _index_of(angle: float) -> int:
	var best := 0
	for i in positions.size():
		if absf(positions[i] - angle) < absf(positions[best] - angle):
			best = i
	return best
