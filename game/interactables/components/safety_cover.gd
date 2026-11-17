class_name SafetyCover
extends ActivatableInteractable

## LA TAPA DE UN BOTÓN DE PELIGRO: plástico transparente con bisagra arriba. Con E se abre —gira hacia arriba y
## afuera, dejando el botón a la vista y a mano— y con otra E se cierra. Cerrada tapa el botón: el rayo de
## interacción pega en ella, y el botón mismo no se deja apretar (ver GuardedButton). La arma DangerButtonArchetype.
##
## ⚠ No viaja por la red todavía: cada máquina abre la suya.

## Cuánto gira al abrirse, y qué tan rápido (rad/s).
const OPEN_ANGLE := -1.95
const SPEED := 9.0

var open := false
## Lo que gira: la bisagra. Lo pone el arquetipo.
var hinge: Node3D = null



## Al terminar de abrirse o de cerrarse.
const SOUNDS := {CLICK: &"tapa"}

func sounds() -> Dictionary:
	return SOUNDS

func activate(actor: Node = null) -> void:
	open = not open
	if is_inside_tree():
		play_sound(CLICK)
	super.activate(actor)


func _process(delta: float) -> void:
	if hinge == null:
		return
	var target := OPEN_ANGLE if open else 0.0
	hinge.rotation.x = move_toward(hinge.rotation.x, target, SPEED * delta)
