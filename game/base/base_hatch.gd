class_name BaseHatch
extends Node3D

## LA COMPUERTA DEL TECHO, sobre el elevador de la base (ver BaseLayout y docs/technical/sucursal.md): dos hojas que se
## corren hacia los costados, como una puerta de ciencia ficción (el usuario, 15/11/2026: «se abren hacia los
## costados»), cuando empieza una partida. Cada hoja se guarda en su bolsillo, una caja sobre el techo a cada lado.
## Por ahora se abre y se cierra con una tecla de su parcela.

## Lo que tarda en abrirse o cerrarse (s).
const SLIDE_TIME := 4.0
const COLOR := Color(0.5, 0.52, 0.55)
## Lo que el bolsillo sobresale del techo, arriba, y lo que se pasa de la hoja.
const POCKET_RISE := 0.6
const POCKET_SLACK := 0.4

var is_open := false
var _leaves: Array[Node3D] = []
var _closed_x: Array[float] = []
var _open_x: Array[float] = []
var _tween: Tween


## Las dos hojas, cada una de la mitad del cuadrado, y sus dos bolsillos.
func build() -> void:
	var inset := BaseLayout.HATCH_INSET
	var span := BaseLayout.ELEVATOR - inset * 2.0
	var half := span * 0.5
	var y := BaseLayout.height + BaseLayout.ROOF * 0.5
	var middle := BaseLayout.ELEVATOR * 0.5
	var pockets := StaticBody3D.new()
	pockets.name = "Bolsillos"
	PhysicsLayers.mark_fixed(pockets)
	add_child(pockets)
	for side: float in [-1.0, 1.0]:
		var leaf := AnimatableBody3D.new()
		leaf.sync_to_physics = false
		var closed := middle + side * half * 0.5
		var opened := closed + side * (half + POCKET_SLACK)
		leaf.position = BaseLayout.at(closed, middle, y)
		add_child(leaf)
		Clay.solid(leaf, Vector3(half, BaseLayout.ROOF, span), Vector3.ZERO, COLOR)
		# una raya amarilla en el borde donde se juntan, para que se lea que es una compuerta
		Clay.box(leaf, Vector3(0.3, BaseLayout.ROOF + 0.02, span), Vector3(-side * (half * 0.5 - 0.15), 0.0, 0.0),
			BaseLayout.STRIPE_COLOR)
		_leaves.append(leaf)
		_closed_x.append(leaf.position.x)
		_open_x.append(BaseLayout.at(opened, middle).x)
		# el bolsillo: tapa la hoja abierta, apoyado en el techo (del lado de afuera, en la roca)
		var pocket_size := Vector3(half + POCKET_SLACK * 2.0, BaseLayout.ROOF + POCKET_RISE, span + POCKET_SLACK * 2.0)
		var pocket_at := BaseLayout.at(opened, middle, BaseLayout.height + pocket_size.y * 0.5)
		Clay.solid(pockets, pocket_size, pocket_at, BaseLayout.WALL_COLOR)


func set_open(value: bool) -> void:
	is_open = value
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in _leaves.size():
		_tween.tween_property(_leaves[i], "position:x", _open_x[i] if value else _closed_x[i], SLIDE_TIME)


## Para las capturas: abierta de una, sin esperar.
func snap_open() -> void:
	is_open = true
	for i in _leaves.size():
		_leaves[i].position.x = _open_x[i]
