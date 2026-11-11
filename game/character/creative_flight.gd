class_name CreativeFlight
extends RefCounted

## EL VUELO CREATIVO, ESCRITO UNA SOLA VEZ. Lo usan el personaje del juego (CharacterRigidBody3D en creative),
## el ente del design sandbox y el freecam de debug: mismas teclas, mismas velocidades, misma lectura del
## input. Acá no hay cuerpo: solo qué pide el jugador y qué velocidad sale de eso; cada cuerpo la aplica como
## pueda (un RigidBody la pone en `linear_velocity`, un CharacterBody en `velocity`).
##
## Las teclas son las del mapa de input del proyecto: `move_*` para el plano, `jump` (espacio) para subir,
## CTRL para bajar, `sprint` (shift) para ir al doble. `TOGGLE_KEY` (V) prende y apaga el modo.

const SPEED := 12.0
const SPRINT_MULTIPLIER := 2.0
const TOGGLE_KEY := KEY_V


## Si este evento es la tecla de alternar el modo, recién apretada.
static func toggled(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key := event as InputEventKey
	return key.pressed and not key.echo and key.keycode == TOGGLE_KEY


## Lo que pide el jugador en el plano, `(izquierda-derecha, adelante-atrás)` en -1..1 por eje: `y` positivo
## es atrás, como el `z` local de un cuerpo. Sin limitar: en diagonal sale más largo, y así fue siempre.
static func planar_input() -> Vector2:
	return Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_forward", "move_backward"))


## Subir (+1) o bajar (-1).
static func vertical_input() -> float:
	var vertical := 0.0
	if Input.is_action_pressed("jump"):
		vertical += 1.0
	if Input.is_physical_key_pressed(KEY_CTRL):
		vertical -= 1.0
	return vertical


static func sprinting() -> bool:
	return Input.is_action_pressed("sprint")


## La velocidad de vuelo de este frame para un cuerpo con esa base: en el plano según la base aplanada
## (el `right` y el `forward` del cuerpo, sin la mirada hacia arriba o abajo), y vertical con subir/bajar,
## las dos a `SPEED` (o el doble al sprintar).
static func velocity(basis: Basis) -> Vector3:
	var right := basis.x
	var forward := basis.z
	right.y = 0.0
	forward.y = 0.0
	right = right.normalized()
	forward = forward.normalized()
	var input := planar_input()
	var dir := right * input.x + forward * input.y
	var speed := SPEED
	if sprinting():
		speed *= SPRINT_MULTIPLIER
	return dir * speed + Vector3.UP * vertical_input() * speed
