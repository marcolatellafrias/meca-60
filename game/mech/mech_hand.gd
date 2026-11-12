class_name MechHand
extends Node3D

## LA MANO DE LA MECA, dibujo, definida una sola vez (la usan la meca y el brazo con músculos). Lo pidió el
## usuario el 12/11/2026: «la muñeca… un poquito más que el diámetro de los cilindros… los dedos… cilíndricos, pero todas
## piezas separadas… le faltan las falanges… el pulgar… en la cara lateral».
## Va en la punta del antebrazo, con su −Z hacia los dedos: la PALMA, apenas más gruesa que un dedo; los cuatro DEDOS al
## frente, uno arriba del otro, cada uno con sus tres FALANGES —cilindros sueltos—; y el PULGAR, de dos falanges, en el
## canto de arriba de la palma.
##
## DOS POSTURAS (el usuario: «una segunda postura de manos que sea con el puño cerrado, para cuando haga cosas discretas
## como los ganchos… con una animación breve»): ABIERTA, con cada falange apenas más cerrada que la anterior, y EL PUÑO,
## con las falanges dobladas sobre la palma y el pulgar encima. Se pide con `fist`; pasa de una a otra en `CLOSE_TIME`,
## con easing.
##
## ES UNA MANO IZQUIERDA O UNA DERECHA (`side`, −1 o 1), UNA EL ESPEJO DE LA OTRA. En sus ejes: los dedos hacia −Z, EL
## PULGAR HACIA +Y, y LA PALMA MIRA HACIA −side·X (para ahí cierran los dedos). Quien la monta la gira para que el pulgar
## y la palma queden donde van en un cuerpo (ver MuscleArm, LA MANO). *Dos veces estuvo mal (12/11/2026, «tiene las manos
## invertidas»; «los pulgares, los dos apuntan para el mismo lado… no es la primera vez que pasa»): el lado se elegía a
## ojo con un signo suelto, el mismo para los dos brazos, y la mano copiaba los ejes del antebrazo, que no son espejo
## entre un brazo y el otro.*

## El dedo: su radio, y el largo de cada falange, de la palma a la punta.
const FINGER_RADIUS := 0.23
const PHALANGES := [0.62, 0.5, 0.4]
## La palma: apenas más gruesa que un dedo, del alto de los cuatro dedos, y su largo.
const PALM := Vector3(FINGER_RADIUS * 2.0 * 1.3, FINGER_RADIUS * 2.0 * 4.4, 1.5)
## Cuánto se cierra cada falange respecto de la anterior (grados): abierta y en puño.
const OPEN_CURL := 24.0
const FIST_CURL := 84.0
## El pulgar: cuánto sale hacia arriba (grados) y cuánto cierra cada falange, abierta y en puño.
const THUMB_RISE := Vector2(40.0, 8.0)
const THUMB_CURL := Vector2(20.0, 58.0)
## En cuánto pasa de una postura a la otra (s).
const CLOSE_TIME := 0.16

## La postura pedida: el puño, o abierta.
var fist := false

var _side := 1.0
var _closed := 0.0
var _shown := -1.0
## Cada dedo: de dónde sale (`from`), sus falanges (`pieces`, con su largo en `lengths`) y si es el pulgar (`thumb`).
var _fingers: Array[Dictionary] = []


## Arma la mano colgada de `parent` y la devuelve (su origen es la muñeca). `side`: la izquierda (−1) o la derecha (1).
static func build(parent: Node3D, side: float) -> MechHand:
	var hand := MechHand.new()
	hand.name = "Mano"
	hand._side = signf(side)
	parent.add_child(hand)
	return hand


func _ready() -> void:
	var color := Clay.METAL.darkened(0.15)
	Clay.box(self, PALM, Vector3(0.0, 0.0, -PALM.z * 0.5), MechBody.JOINT_COLOR)
	for finger in 4:
		_add_finger(Vector3(0.0, (finger - 1.5) * FINGER_RADIUS * 2.2, -PALM.z), PHALANGES, false, color)
	# El pulgar sale del canto de arriba de la palma.
	_add_finger(Vector3(0.0, PALM.y * 0.5, -PALM.z * 0.35), [PHALANGES[0] * 0.9, PHALANGES[1]], true, color)
	_place(0.0)


func _add_finger(from: Vector3, lengths: Array, thumb: bool, color: Color) -> void:
	var pieces: Array[MeshInstance3D] = []
	for length: float in lengths:
		pieces.append(Clay.cylinder(self, FINGER_RADIUS, length - 0.06, Vector3.ZERO, color))
	_fingers.append({"from": from, "lengths": lengths, "pieces": pieces, "thumb": thumb})


## El largo de la mano entera, de la muñeca a la punta de los dedos (derechos).
static func length() -> float:
	var total := PALM.z
	for phalanx: float in PHALANGES:
		total += phalanx
	return total


func _process(delta: float) -> void:
	_closed = move_toward(_closed, 1.0 if fist else 0.0, delta / CLOSE_TIME)
	_place(smoothstep(0.0, 1.0, _closed))


## PONE LOS DEDOS con la mano cerrada `share` (0 abierta, 1 el puño): cada falange sale de la punta de la anterior, hacia
## el −Z del dedo, girada un poco más alrededor del eje vertical de la mano, hacia el lado que cierra.
func _place(share: float) -> void:
	if is_equal_approx(share, _shown):
		return
	_shown = share
	for finger: Dictionary in _fingers:
		var thumb := bool(finger["thumb"])
		var curl := deg_to_rad(lerpf(THUMB_CURL.x, THUMB_CURL.y, share) if thumb else lerpf(OPEN_CURL, FIST_CURL, share))
		var turn := Basis(Vector3.RIGHT, deg_to_rad(lerpf(THUMB_RISE.x, THUMB_RISE.y, share))) if thumb else Basis()
		var at: Vector3 = finger["from"]
		var lengths: Array = finger["lengths"]
		var pieces: Array = finger["pieces"]
		for index in pieces.size():
			# Girar sobre +Y lleva el −Z hacia −X: la derecha (side 1) cierra hacia −X, su palma.
			turn = turn * Basis(Vector3.UP, _side * curl)
			var along := turn * Vector3.FORWARD
			var length := float(lengths[index])
			# El cilindro tiene el largo en su Y: se lo acuesta sobre el −Z del dedo.
			(pieces[index] as MeshInstance3D).transform = Transform3D(turn * Basis(Vector3.RIGHT, -PI * 0.5),
				at + along * length * 0.5)
			at += along * length
