class_name Stairs
extends RefCounted

## TODA ESCALERA SE ARMA CON ESTO (13/11/2026; ver docs/escaleras.md). El usuario: «las escaleras… para que funcionen
## bien con los personajes actuales… tienen dos zonas, actúa como rampa para la cápsula, pero para los pies actúa como
## escalones… siempre que se usen escaleras tienen que ser de esta forma». Es la escalera de «bajar la escalera» del
## laboratorio de locomoción de character-parametric, en su versión de escalones de 15 cm.
##
## DOS CUERPOS POR TRAMO:
##   · LOS ESCALONES, los que se ven: cajas de `RISE` de alto y `TREAD` de pisada, en la capa Escalones
##     (PhysicsLayers.FEET): los ven SÓLO los rayos de los pies y el ragdoll. Los pies pisan cada escalón.
##   · LA RAMPA, invisible, en la capa Rampa (PhysicsLayers.RAMP): la ven SÓLO la cápsula y su rayo de piso. Pasa por los
##     RINCONES DE ABAJO de cada escalón, así TODA PISADA QUEDA ENTRE 0 Y UN ESCALÓN POR ENCIMA DE LA CÁPSULA: la pierna
##     la alcanza doblándose, nunca le falta largo. *En el laboratorio, con la rampa por los bordes de arriba, algún pie
##     quedaba fuera de alcance el 90 % del tiempo.*
## LOS DESCANSOS igual: el piso de los pies a su altura y, debajo, el de la cápsula UN ESCALÓN MÁS ABAJO. La rampa de cada
## tramo se estira un escalón para atrás y para adelante, hasta el piso de la cápsula de los descansos de sus puntas; y
## el que da a un piso común (un techo, la calle) sube ese escalón en su ancho, para empalmar sin escalón.
##
## Nada más que los personajes pisa una escalera: ni la meca ni los objetos sueltos la ven.

## El alto de un escalón (m): el de una escalera de verdad. Un tramo lo ajusta un pelo para cerrar justo en su altura.
const RISE := 0.15
## La pisada (m): 31,5 cm, ocho celdas de la grilla de la cabina, para que las escaleras de la meca y las del mundo sean
## iguales (lo acordó la sesión del interior, 13/11/2026). *El laboratorio usaba 50 cm; con eso un piso de 3 m pide un
## tramo de 10 m, que no entra en una fachada.*
const TREAD := CabinGrid.CELL * 8
## El grosor de las tablas invisibles de la cápsula.
const PLANK := 0.1


## CUÁNTOS ESCALONES lleva un tramo que sube `height`.
static func steps_for(height: float) -> int:
	return maxi(1, roundi(height / RISE))


## LO LARGO DE UN TRAMO que sube `height` (en planta).
static func run_for(height: float) -> float:
	return steps_for(height) * TREAD


## UN TRAMO que arranca en `start` (el piso de abajo, donde empieza el primer escalón) y sube `height` hacia `toward`
## (horizontal), de `width` de ancho. Cuelga sus dos cuerpos de `parent`.
static func flight(parent: Node3D, start: Vector3, toward: Vector3, height: float, width: float, color: Color) -> void:
	var count := steps_for(height)
	var rise := height / count
	var basis := Basis.looking_at(toward.normalized(), Vector3.UP)
	var feet := _body(parent, PhysicsLayers.FEET, "Escalones")
	for i in count:
		Clay.solid(feet, Vector3(width, rise, TREAD), start + basis * Vector3(0, rise * (i + 0.5), -TREAD * (i + 0.5)),
			color, basis)
	# La rampa por los rincones de abajo: del escalón de antes del primero (un escalón abajo del piso de arranque) al
	# rincón del último (un escalón abajo de la llegada).
	# Y un pedazo plano arriba del último, hasta el descanso.
	var low := start + basis * Vector3(0, -rise, TREAD)
	var high := start + basis * Vector3(0, height - rise, -TREAD * (count - 1))
	var capsule := _body(parent, PhysicsLayers.RAMP, "Rampa")
	ramp_plank(capsule, low, high, width)
	ramp_plank(capsule, high, start + basis * Vector3(0, height - rise, -TREAD * (count + 1)), width)


## UN DESCANSO: el piso de los pies, de `size` (ancho en X local, largo en Z local), con su cara de arriba en `top` y
## girado `yaw`; y debajo, el de la cápsula, un escalón más abajo. Con `rise_toward` (horizontal, no cero), la tabla de
## la cápsula sube ese escalón hacia ese lado: para el descanso que da a un piso común.
static func landing(parent: Node3D, top: Vector3, size: Vector2, yaw: float, color: Color,
		rise_toward := Vector3.ZERO) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var feet := _body(parent, PhysicsLayers.FEET, "Descanso")
	Clay.solid(feet, Vector3(size.x, 0.3, size.y), top - Vector3.UP * 0.15, color, basis)
	var capsule := _body(parent, PhysicsLayers.RAMP, "DescansoRampa")
	if rise_toward == Vector3.ZERO:
		var plank_top := top - Vector3.UP * RISE
		Clay.shape_box(capsule, Vector3(size.x, PLANK, size.y), plank_top - Vector3.UP * PLANK * 0.5, basis)
		return
	var across := rise_toward.normalized()
	var sideways := across.cross(Vector3.UP)
	var half_x := basis * Vector3(size.x * 0.5, 0, 0)
	var half_z := basis * Vector3(0, 0, size.y * 0.5)
	var reach := absf(half_x.dot(across)) + absf(half_z.dot(across))
	var wide := (absf(half_x.dot(sideways)) + absf(half_z.dot(sideways))) * 2.0
	ramp_plank(capsule, top - across * reach - Vector3.UP * RISE, top + across * reach, wide)


## Una tabla de la cápsula de `from` a `to` (las dos puntas de su cara de arriba), de `width` de ancho.
static func ramp_plank(body: StaticBody3D, from: Vector3, to: Vector3, width: float) -> void:
	var along := to - from
	var basis := Basis.looking_at(along.normalized(), Vector3.UP)
	Clay.shape_box(body, Vector3(width, PLANK, along.length()), (from + to) * 0.5 - basis.y * PLANK * 0.5, basis)


static func _body(parent: Node3D, layer: int, label: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = layer
	body.collision_mask = 0
	parent.add_child(body)
	return body
