class_name KeyComponent
extends TouchComponent

## UNA TECLA QUE SE SIENTE: un botón momentáneo (ver TouchComponent) con el recorrido y el andar de una tecla de
## máquina. Se HUNDE casi la mitad de su alto —un botón común baja un quinto—, baja de golpe y vuelve con un
## rebote corto, y suena al bajar y otra vez al subir. Lo que se mueve es la tecla entera, con su
## carácter. La usa KeyArchetype.

## Qué fracción de su alto baja al apretarla.
const KEY_TRAVEL := 0.45
## Qué tan rápido llega abajo y qué tan rápido vuelve (1/s); al volver se pasa un poco y se acomoda.
const DOWN_RATE := 30.0
const UP_STIFFNESS := 900.0
const UP_DAMPING := 28.0

var _depth: float = 0.0
var _speed: float = 0.0

## LA LUZ ADENTRO, en una tecla con luz (ver KeyArchetype): el material de la tecla y el color del plástico. Se prende
## mientras está hundida —la que se traba, mientras está trabada—, salvo que quien la usa la maneje (`set_light`), y
## entonces es un indicador que además se aprieta.
const LIGHT_ENERGY := 1.6
var light_material: StandardMaterial3D = null
var light_color := Color.WHITE
var _light_driven := false
var _light_on := false


## La prende o la apaga quien la usa; desde ahí la luz ya no sigue a la tecla.
func set_light(on: bool) -> void:
	_light_driven = true
	_glow(on)


func _glow(on: bool) -> void:
	if light_material == null or on == _light_on and light_material.emission_enabled == on:
		return
	_light_on = on
	light_material.emission_enabled = on
	light_material.emission = light_color
	light_material.emission_energy_multiplier = LIGHT_ENERGY


func _setup_handle_points(size: Vector3) -> void:
	super._setup_handle_points(size)
	_travel = size.z * KEY_TRAVEL


## No salta a su lugar: lo persigue en `_process`.
func _apply_visual() -> void:
	pass


func _process(delta: float) -> void:
	var target := _travel if is_pressed else 0.0
	if is_pressed:
		# Bajando: de golpe, hasta el fondo.
		_depth = move_toward(_depth, target, DOWN_RATE * _travel * delta)
		_speed = 0.0
	else:
		# Subiendo: un resorte apenas subamortiguado, que se pasa un pelo y vuelve.
		_speed += (UP_STIFFNESS * (target - _depth) - UP_DAMPING * _speed) * delta
		_depth += _speed * delta
	position = Vector3(0.0, 0.0, -_depth)
	if not _light_driven:
		_glow(is_pressed)
