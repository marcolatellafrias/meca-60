class_name DamageNumber
extends Label3D

## UN NÚMERO DE DAÑO QUE SUBE Y SE APAGA. Los golpes seguidos (la ametralladora) se suman en el mismo (`add`).

const LIFE := 0.9
const RISE := 1.6
## Hasta cuánto después del último golpe se sigue sumando (s).
const MERGE := 0.3

var amount := 0.0
var _age := 0.0


func _init() -> void:
	top_level = true
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = false
	pixel_size = 0.012
	font_size = 72
	outline_size = 16
	outline_modulate = Color.BLACK
	render_priority = 10


func add(value: float, strong: bool) -> void:
	amount += value
	_age = 0.0
	text = str(roundi(amount)) if amount >= 1.0 else "%.1f" % amount
	modulate = Color(1.0, 0.45, 0.2) if strong else Color.WHITE


## Si todavía se le puede sumar.
func open() -> bool:
	return _age < MERGE


func _process(delta: float) -> void:
	_age += delta
	global_position += Vector3.UP * RISE * delta
	modulate.a = clampf(1.0 - (_age - MERGE) / (LIFE - MERGE), 0.0, 1.0)
	if _age >= LIFE:
		queue_free()
