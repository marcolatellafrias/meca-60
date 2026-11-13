class_name BallCannon
extends Node3D

## EL CAÑÓN DEL JEFE BOLA (13/11/2026), PASO 2: corre por la rendija, que da toda la vuelta de adelante, por arriba,
## hacia atrás. Apunta SÓLO PARA ARRIBA Y PARA ABAJO; de costado apunta la bola entera, girando con las patas (el
## usuario: «la rendija es en la otra dirección, si quiere rotar en y, va a usar las piernas»). Todavía no dispara.
##
## Cuelga del centro de la bola y gira sobre el eje de la rendija (su X): a 0° mira adelante, a 90° al cielo y a 180°
## atrás. Va hacia el ángulo pedido con tope de velocidad, y da la vuelta entera si se le pide.

## Exagerado, como de tanque (el usuario: «más exagerado y agregale un cilindro más grande… en la punta así parece más
## un cañón de tanque»). El carro que va metido en la rendija (alto y fondo, m; el ancho es el de la rendija), el caño
## (radio y largo, m) y, en la punta, la boca más gruesa (radio y largo, m), con el hueco bien a la vista.
const CARRIAGE := Vector2(8.0, 4.5)
const BARREL_RADIUS := 2.4
const BARREL_LENGTH := 15.0
const MUZZLE_RADIUS := 3.6
const MUZZLE_LENGTH := 4.0

## Hacia dónde apunta ahora (radianes, sobre la rendija; 0 adelante, positivo para arriba).
var pitch := 0.0


## LO ARMA en la bola de `radius`, con la rendija de `slit` de ancho y `depth` de fondo.
func build(radius: float, slit: float, depth: float) -> void:
	var bottom := radius - depth
	Clay.box(self, Vector3(slit * 0.9, CARRIAGE.x, CARRIAGE.y), Vector3(0.0, 0.0, -(bottom + CARRIAGE.y * 0.5 - 0.3)),
		Clay.DARK.lightened(0.15))
	Clay.cylinder(self, BARREL_RADIUS, BARREL_LENGTH, Vector3(0.0, 0.0, -(bottom + BARREL_LENGTH * 0.5)), Clay.YELLOW,
		Vector3(90.0, 0.0, 0.0))
	var tip := bottom + BARREL_LENGTH
	Clay.cylinder(self, MUZZLE_RADIUS, MUZZLE_LENGTH, Vector3(0.0, 0.0, -(tip - MUZZLE_LENGTH * 0.5)), Clay.YELLOW.darkened(0.15),
		Vector3(90.0, 0.0, 0.0))
	# El hueco, oscuro, para ver adónde mira.
	Clay.cylinder(self, BARREL_RADIUS * 0.8, 0.3, Vector3(0.0, 0.0, -(tip + 0.1)), Clay.DARK.darkened(0.5),
		Vector3(90.0, 0.0, 0.0))


## UN PASO: hacia `aim` (radianes), por el camino más corto, a `speed` grados por segundo como mucho.
func follow(aim: float, speed: float, delta: float) -> void:
	var error := wrapf(aim - pitch, -PI, PI)
	pitch = wrapf(pitch + clampf(error, -deg_to_rad(speed) * delta, deg_to_rad(speed) * delta), -PI, PI)
	rotation = Vector3(pitch, 0.0, 0.0)


## Hacia dónde sale un tiro (mundo): para cuando dispare.
func muzzle() -> Transform3D:
	return global_transform
