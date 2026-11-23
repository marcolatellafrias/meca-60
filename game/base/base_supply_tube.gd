class_name BaseSupplyTube
extends Node3D

## UN TUBO DE PAQUETES EN LA PARED (22/11/2026; el usuario: «como un tubo que tira unos paquetes al piso, como los paquetes de
## Portal… pero mucho más simple»): un hueco cuadrado con su marco, y abajo un cuadrado pintado donde cae el paquete. El de
## munición tiene un botón al lado que cambia lo que sale, y un cartel que lo dice. Es sólo lo que se ve: los paquetes los
## maneja BaseSupplies. Su frente es +Z.

const GROUP := "base_supply_tubes"
const HOLE := 1.05
const FRAME := 0.2
## Lo que sale de la pared: con esta cámara la pared se ve de canto, y la boca tiene que leerse desde arriba.
const DEEP := 0.85
const MOUTH_Y := 2.3
const PAD_AT := 1.75
const PAD := 1.3
## Del lado de lejos del ascensor: la E no tiene que encontrar su botón a través de la pared.
const BUTTON_AT := Vector3(-1.55, 0.0, 0.55)
const METAL := Color(0.36, 0.39, 0.43)
const DARK := Color(0.07, 0.07, 0.08)

## Cuál es (0 munición, 1 reparación), lo que puede tirar y cuál está elegido.
var slot := 0
var kinds: Array[int] = []
var index := 0
var _type: Label3D = null


func _ready() -> void:
	add_to_group(GROUP)


func build(which: int, title: String, can_drop: Array[int]) -> void:
	slot = which
	kinds = can_drop
	var y := MOUTH_Y
	var outer := HOLE + FRAME * 2.0
	Clay.box(self, Vector3(outer, outer, DEEP), Vector3(0.0, y, DEEP * 0.5 - 0.1), METAL)
	Clay.box(self, Vector3(HOLE, HOLE, 0.02), Vector3(0.0, y, DEEP - 0.09), DARK)
	Clay.box(self, Vector3(outer + 0.12, 0.1, DEEP + 0.16), Vector3(0.0, y - outer * 0.5, DEEP * 0.5 - 0.02), METAL.darkened(0.2))
	var border := PAD
	var line := 0.09
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(border, 0.02, line), Vector3(0.0, 0.02, PAD_AT + side * border * 0.5), BaseLayout.STRIPE_COLOR)
		Clay.box(self, Vector3(line, 0.02, border), Vector3(side * border * 0.5, 0.02, PAD_AT), BaseLayout.STRIPE_COLOR)
	_label(title, Vector3(0.0, y + outer * 0.5 + 0.35, DEEP + 0.2), 54)
	_type = _label("", Vector3(0.0, 0.25, PAD_AT + PAD * 0.5 + 0.5), 34)
	if kinds.size() > 1:
		_button()
	show_kind()


## Lo que sale ahora.
func kind() -> int:
	return kinds[index]


func show_kind() -> void:
	if _type != null:
		_type.text = SupplyKinds.title(kind())
		_type.modulate = SupplyKinds.tag_color(kind()).lightened(0.25)


## De dónde sale el paquete y dónde cae (el piso).
func mouth() -> Vector3:
	return to_global(Vector3(0.0, MOUTH_Y, DEEP + 0.3))


func pad() -> Vector3:
	return to_global(Vector3(0.0, 0.0, PAD_AT))


func _button() -> void:
	var post := StaticBody3D.new()
	post.name = "Selector"
	post.position = BUTTON_AT
	add_child(post)
	Clay.solid(post, Vector3(0.55, 1.05, 0.55), Vector3(0.0, 0.525, 0.0), METAL)
	Clay.box(post, Vector3(0.34, 0.08, 0.34), Vector3(0.0, 1.09, 0.0), BaseLayout.STRIPE_COLOR)
	var use := BaseTubeButton.new()
	use.tube = self
	use.position = Vector3(0.0, 0.9, 0.0)
	post.add_child(use)
	var sign := _label("CAMBIAR", Vector3(0.0, 1.45, 0.0), 30)
	sign.reparent(post, false)


func _label(text: String, at: Vector3, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 10
	label.no_depth_test = true
	label.position = at
	add_child(label)
	return label
