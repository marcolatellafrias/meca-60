class_name MechSeat
extends Node3D

## UN PUESTO DE LA MECA: LA SILLA DE CHARACTER-PARAMETRIC (`SeatInteractable`, la de las consolas de la nave de allá:
## E se sienta y se levanta, a la altura de ojos de la nave) y la consola de enfrente con su nivel de equilibrio. El
## puesto dice qué maneja (`station`); las teclas las lee la meca cuando el jugador está sentado en esta silla (ver
## Mech). Se mira con la cabeza del personaje, por la ventana del frente.
##
## EL NIVEL: un disco en la consola con una bolita que se corre hacia donde se inclina la meca; si llega al borde
## rojo, la meca se cae. Está en todos los puestos, porque el equilibrio es de todos.

enum Station { LEGS, ARMS, LOOKOUT }

const NAMES := {Station.LEGS: "Piernas", Station.ARMS: "Brazos", Station.LOOKOUT: "Vigía"}
const CHAIR_SCENE := "res://game/ship/working_seat.tscn"
const GAUGE_RADIUS := 0.16

var station := Station.LEGS
var chair: SeatInteractable = null
var _ball: Node3D = null


func _init(p_station: Station) -> void:
	station = p_station
	name = "Puesto " + str(NAMES[station])


func _ready() -> void:
	chair = (load(CHAIR_SCENE) as PackedScene).instantiate() as SeatInteractable
	chair.name = "Silla"
	chair.eye_height = ShipStyle.current.seat_eye_height
	add_child(chair)
	var console := Clay.box(self, Vector3(1.4, 0.9, 0.5), Vector3(0, 0.45, -0.75), Clay.METAL.darkened(0.2))
	console.name = "Consola"
	var label := Label3D.new()
	label.text = str(NAMES[station]).to_upper()
	label.font_size = 32
	label.pixel_size = 0.0025
	label.position = Vector3(-0.3, 0.91, -0.62)
	label.rotation_degrees.x = -60.0
	label.modulate = Color(0.95, 0.9, 0.7)
	add_child(label)
	Clay.cylinder(self, GAUGE_RADIUS + 0.03, 0.02, Vector3(0.4, 0.91, -0.75), Clay.RED)
	Clay.cylinder(self, GAUGE_RADIUS, 0.03, Vector3(0.4, 0.915, -0.75), Color(0.9, 0.9, 0.85))
	_ball = Clay.sphere(self, 0.03, Vector3(0.4, 0.94, -0.75), Clay.DARK)


## Si `player` está sentado en esta silla.
func holds(player: BoneInstantiator) -> bool:
	return is_instance_valid(player) and player.is_seated and player.current_seat == chair


## La bolita del nivel: `stability` de −1 a 1 por eje (x a la derecha, y adelante); 1 es el borde.
func show_stability(stability: Vector2) -> void:
	var offset := stability.limit_length(1.1) * GAUGE_RADIUS
	_ball.position = Vector3(0.4 + offset.x, 0.94, -0.75 - offset.y)
