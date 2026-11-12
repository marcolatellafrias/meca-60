class_name MechLift
extends AnimatableBody3D

## EL MONTACARGAS: una plataforma con jaula que sube del suelo al balcón del piso de abajo de la meca (ver MechTorso),
## más fácil que una escalera colgando de siete metros. Parado encima, E lo manda a la otra punta. La meca lo pone en
## su lugar en cada paso de física (`place`), siguiendo al torso; adentro guarda sólo a qué altura va.

const SIZE := Vector2(2.0, 1.5)
const SPEED := 3.0

## La altura de la plataforma en el espacio del torso: `low` es el suelo (con la meca parada), `high` el balcón.
var low := -7.0
var high := 0.25
var height := -7.0
var _target := -7.0


func _init() -> void:
	name = "Montacargas"
	sync_to_physics = true
	top_level = true


func _ready() -> void:
	Clay.solid(self, Vector3(SIZE.x, 0.15, SIZE.y), Vector3(0, -0.075, 0), Clay.YELLOW.darkened(0.2))
	# La jaula: postes en las esquinas de atrás y una botonera.
	for x: float in [-SIZE.x * 0.5, SIZE.x * 0.5]:
		Clay.box(self, Vector3(0.08, 2.2, 0.08), Vector3(x, 1.1, SIZE.y * 0.5), Clay.DARK)
	Clay.box(self, Vector3(SIZE.x, 0.08, 0.08), Vector3(0, 2.2, SIZE.y * 0.5), Clay.DARK)
	Clay.box(self, Vector3(0.25, 0.35, 0.1), Vector3(SIZE.x * 0.5 - 0.3, 1.1, SIZE.y * 0.5 - 0.05), Clay.RED)
	var label := Label3D.new()
	label.text = "E  sube / baja"
	label.font_size = 40
	label.pixel_size = 0.004
	label.position = Vector3(SIZE.x * 0.5 - 0.3, 1.45, SIZE.y * 0.5 - 0.1)
	label.rotation_degrees.y = 180.0
	add_child(label)


func set_range(p_low: float, p_high: float) -> void:
	low = p_low
	high = p_high
	height = low
	_target = low


## A la otra punta.
func toggle() -> void:
	_target = high if _target <= low + 0.01 else low


## Avanza y se pone en su lugar: `torso` es la transformación del torso; `at` el centro en el plano del torso.
func place(torso: Transform3D, at: Vector2, delta: float) -> void:
	height = move_toward(height, _target, SPEED * delta)
	global_transform = placed(torso, at)


## Dónde va, a su altura de ahora (ver `place`): también antes de nacer, para nacer ahí.
func placed(torso: Transform3D, at: Vector2) -> Transform3D:
	return torso * Transform3D(Basis(), Vector3(at.x, height, at.y))


## Si `point` (en el mundo) está parado sobre la plataforma.
func carries(point: Vector3) -> bool:
	var local := global_transform.affine_inverse() * point
	return absf(local.x) <= SIZE.x * 0.5 + 0.2 and absf(local.z) <= SIZE.y * 0.5 + 0.2 and local.y > -0.5 \
		and local.y < 2.5
