class_name BaseSlideDoor
extends Node3D

## UNA PUERTA DE DOS HOJAS QUE SE CORREN HACIA LOS COSTADOS, como la compuerta del techo (BaseHatch): para la esclusa
## (BaseAirlock). Parada en el plano XY de su nodo: el hueco, de `width` por `tall`, con el piso en y = 0; cada hoja se
## guarda dentro de la pared, a su costado.

const SLIDE_TIME := 1.2
const COLOR := Color(0.5, 0.52, 0.55)

var is_open := false
var _leaves: Array[AnimatableBody3D] = []
var _closed_x: Array[float] = []
var _open_x: Array[float] = []
var _tween: Tween


func build(width: float, tall: float, thick: float) -> void:
	var half := width * 0.5
	for side: float in [-1.0, 1.0]:
		var leaf := AnimatableBody3D.new()
		leaf.sync_to_physics = false
		leaf.position = Vector3(side * half * 0.5, tall * 0.5, 0.0)
		add_child(leaf)
		Clay.solid(leaf, Vector3(half, tall, thick), Vector3.ZERO, COLOR)
		# una raya amarilla en el borde donde se juntan, para que se lea que es una puerta
		Clay.box(leaf, Vector3(0.12, tall, thick + 0.02), Vector3(-side * (half * 0.5 - 0.06), 0.0, 0.0),
			BaseLayout.STRIPE_COLOR)
		_leaves.append(leaf)
		_closed_x.append(leaf.position.x)
		_open_x.append(leaf.position.x + side * (half - 0.08))


func set_open(value: bool) -> void:
	is_open = value
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in _leaves.size():
		_tween.tween_property(_leaves[i], "position:x", _open_x[i] if value else _closed_x[i], SLIDE_TIME)
