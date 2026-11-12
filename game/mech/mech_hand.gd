class_name MechHand
extends RefCounted

## LA MANO DE LA MECA, dibujo, definida una sola vez (la usan la meca péndulo y el brazo con músculos). Lo pidió el
## usuario el 12/11/2026: «la muñeca… un poquito más que el diámetro de los cilindros… los dedos… cilíndricos, pero todas
## piezas separadas… le faltan las falanges… el pulgar… en la cara lateral».
## Va en la punta del antebrazo, con su −Z hacia los dedos: la PALMA, apenas más gruesa que un dedo; los cuatro DEDOS al
## frente, uno arriba del otro, cada uno con sus tres FALANGES —cilindros sueltos, cada una un poco más cerrada que la
## anterior, hacia adentro—; y el PULGAR, de dos falanges, en el canto de arriba de la palma.

## El dedo: su radio, y el largo de cada falange, de la palma a la punta.
const FINGER_RADIUS := 0.23
const PHALANGES := [0.62, 0.5, 0.4]
## La palma: apenas más gruesa que un dedo, del alto de los cuatro dedos, y su largo.
const PALM := Vector3(FINGER_RADIUS * 2.0 * 1.3, FINGER_RADIUS * 2.0 * 4.4, 1.5)
## Cuánto se cierra cada falange respecto de la anterior (grados).
const CURL := 14.0


## Arma la mano de `side` (−1 izquierda, 1 derecha) colgada de `parent`, y la devuelve (su origen es la muñeca).
static func build(parent: Node3D, side: float) -> Node3D:
	var hand := Node3D.new()
	hand.name = "Mano"
	parent.add_child(hand)
	var color := Clay.METAL.darkened(0.15)
	Clay.box(hand, PALM, Vector3(0.0, 0.0, -PALM.z * 0.5), MechBody.JOINT_COLOR)
	for finger in 4:
		var knuckle := Vector3(0.0, (finger - 1.5) * FINGER_RADIUS * 2.2, -PALM.z)
		_finger(hand, knuckle, Basis(), PHALANGES, color, -side)
	# El pulgar sale del canto de arriba, hacia adelante y un poco hacia arriba.
	var thumb := Vector3(0.0, PALM.y * 0.5, -PALM.z * 0.35)
	_finger(hand, thumb, Basis(Vector3.RIGHT, deg_to_rad(40.0)), [PHALANGES[0] * 0.9, PHALANGES[1]], color, -side)
	return hand


## El largo de la mano entera, de la muñeca a la punta de los dedos (derechos).
static func length() -> float:
	var total := PALM.z
	for phalanx: float in PHALANGES:
		total += phalanx
	return total


## UN DEDO: una falange tras otra desde `from`, hacia el −Z de `basis`, cada una girada `CURL` más que la anterior
## alrededor del eje vertical de la mano, hacia `inward` (el lado de adentro).
static func _finger(hand: Node3D, from: Vector3, basis: Basis, lengths: Array, color: Color, inward: float) -> void:
	var at := from
	var turn := basis
	for length: float in lengths:
		turn = turn * Basis(Vector3.UP, inward * deg_to_rad(CURL))
		var along := turn * Vector3.FORWARD
		var piece := Clay.cylinder(hand, FINGER_RADIUS, length - 0.06, Vector3.ZERO, color)
		# El cilindro tiene el largo en su Y: se lo acuesta sobre el −Z del dedo.
		piece.transform = Transform3D(turn * Basis(Vector3.RIGHT, -PI * 0.5), at + along * length * 0.5)
		at += along * length
