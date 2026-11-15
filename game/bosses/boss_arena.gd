class_name BossArena
extends RefCounted

## LA ARENA DE LOS JEFES (15/11/2026): UN CÍRCULO conocido de antemano, del que el jefe no sale. Los edificios van afuera.
## El usuario: «un radio central en la que pueden moverse y que no salgan de eso… no debería tener un sistema que lee
## objetos en el momento, sino que tiene ya preplaneado dónde puede y dónde no… de la forma más simple que se pueda».
## Sin rayos ni lecturas del mundo: cuentas con el círculo.
##   · CAMINANDO, el borde lo frena: se desliza por él (`keep`).
##   · Lo que lo haya sacado (un empujón), lo vuelve a poner adentro (`hold`).
##   · Para lo que venga: embistiendo, el borde es una pared contra la que se estrella (`at_edge`); el pinball rebota en él
##     (`bounce`).

## El radio (m).
var radius := 100.0

var _anchor: Node3D = null
var _ring: MeshInstance3D = null


## El círculo de `radius` alrededor de `anchor` (su centro es donde está `anchor`, en el piso).
func _init(anchor: Node3D, size: float) -> void:
	_anchor = anchor
	radius = size


func center() -> Vector3:
	return _anchor.global_position if _anchor != null and is_instance_valid(_anchor) else Vector3.ZERO


## Cuánto está `point` del centro, de costado (m).
func distance(point: Vector3) -> float:
	var flat := point - center()
	flat.y = 0.0
	return flat.length()


## Hacia afuera desde el centro, en `point` (de costado, de largo 1).
func outward(point: Vector3) -> Vector3:
	var flat := point - center()
	flat.y = 0.0
	return flat.normalized() if flat.length_squared() > 0.0001 else Vector3.FORWARD


## Si algo de `margin` de radio en `point` toca el borde.
func at_edge(point: Vector3, margin: float) -> bool:
	return distance(point) >= radius - margin - 0.05


## LA VELOCIDAD `velocity` en `point`, sin lo que lo sacaría del círculo (con `margin`, su radio): en el borde se desliza.
func keep(point: Vector3, velocity: Vector3, margin: float) -> Vector3:
	if not at_edge(point, margin):
		return velocity
	var out := outward(point)
	var away := velocity.dot(out)
	return velocity - out * away if away > 0.0 else velocity


## La posición `point` vuelta adentro del círculo, si se pasó.
func hold(point: Vector3, margin: float) -> Vector3:
	var room := radius - margin
	if distance(point) <= room:
		return point
	var inside := center() + outward(point) * room
	return Vector3(inside.x, point.y, inside.z)


## EL REBOTE en el borde: la velocidad reflejada sobre la dirección al centro (para el pinball).
func bounce(point: Vector3, velocity: Vector3) -> Vector3:
	var out := outward(point)
	return velocity - 2.0 * velocity.dot(out) * out if velocity.dot(out) > 0.0 else velocity


## OTRO RADIO (m): el anillo del piso lo sigue.
func resize(size: float) -> void:
	if is_equal_approx(size, radius):
		return
	radius = size
	if _ring != null and is_instance_valid(_ring):
		var torus := _ring.mesh as TorusMesh
		torus.inner_radius = radius - 0.6
		torus.outer_radius = radius + 0.6


## El anillo en el piso que la marca.
func draw(parent: Node3D) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	ring.name = "Arena"
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.6
	torus.outer_radius = radius + 0.6
	torus.rings = 128
	ring.mesh = torus
	_ring = ring
	ring.scale = Vector3(1.0, 0.15, 1.0)
	ring.material_override = Clay.material(Color(0.95, 0.55, 0.15))
	ring.position = Vector3.UP * 0.05
	parent.add_child(ring)
	return ring
