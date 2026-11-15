class_name BaseHatch
extends Node3D

## LA COMPUERTA DEL TECHO, sobre el elevador de la base (ver BaseLayout y docs/technical/sucursal.md): dos hojas que se
## abren hacia arriba, cada una sobre su bisagra en un borde del cuadrado del elevador, cuando empieza una partida. Por
## ahora se abre y se cierra con una tecla de su parcela.

## Lo que tarda en abrirse o cerrarse (s).
const SWING_TIME := 4.0
## Cuánto se levanta cada hoja (grados): un poco más que vertical, para que no estorbe a la meca.
const OPEN_ANGLE := 100.0
const COLOR := Color(0.5, 0.52, 0.55)

var is_open := false
var _hinges: Array[Node3D] = []
var _tween: Tween


## Las dos hojas, cada una de la mitad del cuadrado, colgadas de su bisagra.
func build() -> void:
	var inset := BaseLayout.HATCH_INSET
	var span := BaseLayout.ELEVATOR - inset * 2.0
	var half := span * 0.5
	var y := BaseLayout.HEIGHT + BaseLayout.ROOF * 0.5
	for side: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		var edge_x := inset if side < 0.0 else BaseLayout.ELEVATOR - inset
		hinge.position = BaseLayout.at(edge_x, BaseLayout.ELEVATOR * 0.5, y)
		add_child(hinge)
		var leaf := AnimatableBody3D.new()
		leaf.sync_to_physics = false
		hinge.add_child(leaf)
		Clay.solid(leaf, Vector3(half, BaseLayout.ROOF, span), Vector3(-side * half * 0.5, 0.0, 0.0), COLOR)
		# una raya amarilla donde se juntan, para que se lea que es una compuerta
		Clay.box(leaf, Vector3(0.3, BaseLayout.ROOF + 0.02, span), Vector3(-side * (half - 0.15), 0.0, 0.0),
			BaseLayout.STRIPE_COLOR)
		_hinges.append(hinge)


func set_open(value: bool) -> void:
	is_open = value
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in _hinges.size():
		var side := -1.0 if i == 0 else 1.0
		var angle := deg_to_rad(OPEN_ANGLE) * -side if value else 0.0
		_tween.tween_property(_hinges[i], "rotation:z", angle, SWING_TIME)


## Para las capturas: abierta de una, sin esperar.
func snap_open() -> void:
	is_open = true
	for i in _hinges.size():
		_hinges[i].rotation.z = deg_to_rad(OPEN_ANGLE) * (1.0 if i == 0 else -1.0)
