class_name MechSeat
extends Node3D

## UN PUESTO DE LA MECA: la silla, la consola de enfrente con su nivel de equilibrio y la cámara del que se sienta,
## que mira por la ventana del frente. El puesto dice qué maneja (`station`); las teclas las lee la meca (ver Mech).
##
## EL NIVEL: un disco en la consola con una bolita que se corre hacia donde se inclina la meca; si llega al borde
## rojo, la meca se cae. Está en todos los puestos, porque el equilibrio es de todos.

enum Station { LEGS, ARMS, LOOKOUT }

const NAMES := {Station.LEGS: "Piernas", Station.ARMS: "Brazos", Station.LOOKOUT: "Vigía"}
## A qué altura del piso están los ojos del que se sienta, y cuánto puede girar la cabeza.
const EYE := 1.3
const LOOK_YAW := deg_to_rad(80.0)
const LOOK_PITCH := deg_to_rad(55.0)
const GAUGE_RADIUS := 0.16

var station := Station.LEGS
var camera: Camera3D = null
var _ball: Node3D = null
var _yaw := 0.0
var _pitch := 0.0


func _init(p_station: Station) -> void:
	station = p_station
	name = "Puesto " + str(NAMES[station])


func _ready() -> void:
	# La silla y la consola con el nivel.
	Clay.box(self, Vector3(0.6, 0.1, 0.6), Vector3(0, 0.45, 0), Clay.DARK)
	Clay.box(self, Vector3(0.6, 0.7, 0.1), Vector3(0, 0.85, 0.3), Clay.DARK)
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
	camera = Camera3D.new()
	camera.name = "Ojos"
	camera.position = Vector3(0, EYE, -0.1)
	camera.fov = GameOptions.field_of_view
	camera.near = 0.05
	camera.far = 2000.0
	add_child(camera)


## La bolita del nivel: `stability` de −1 a 1 por eje (x a la derecha, y adelante); 1 es el borde.
func show_stability(stability: Vector2) -> void:
	var offset := stability.limit_length(1.1) * GAUGE_RADIUS
	_ball.position = Vector3(0.4 + offset.x, 0.94, -0.75 - offset.y)


## Girar la cabeza sentado, con límites.
func look(relative: Vector2) -> void:
	var sensitivity := 0.0025 * GameOptions.mouse_sensitivity
	_yaw = clampf(_yaw - relative.x * sensitivity, -LOOK_YAW, LOOK_YAW)
	_pitch = clampf(_pitch - relative.y * sensitivity, -LOOK_PITCH, LOOK_PITCH)
	camera.rotation = Vector3(_pitch, _yaw, 0.0)


func reset_look() -> void:
	_yaw = 0.0
	_pitch = 0.0
	camera.rotation = Vector3.ZERO
