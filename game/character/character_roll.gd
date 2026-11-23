class_name CharacterRoll
extends RefCounted

## EL ROLL DE LOS PERSONAJES A PIE (22/11/2026; el usuario: «no quiero que los personajes a pie puedan saltar… reemplazaría
## el espacio para salto por un shift, para un roll»). Lo arranca PlayerController, lo lleva la cápsula (`velocity`) y se
## dibuja dando la vuelta al esqueleto de dibujo alrededor de la cadera, hecho un bollo. A los demás les llega por la red.

const TIME := 0.45
const DISTANCE := 3.6
const COOLDOWN := 0.25
## Lo que se achica el cuerpo y lo que baja la cadera en el medio de la vuelta.
const TUCK := 0.58
const DROP := 0.42

var way := Vector3.ZERO
var _left := 0.0
var _wait := 0.0
var _rest := Transform3D.IDENTITY
var _bent := false


func active() -> bool:
	return _left > 0.0


## Arranca hacia `to` (plano). Devuelve si arrancó.
func start(to: Vector3) -> bool:
	var flat := Vector3(to.x, 0.0, to.z)
	if active() or _wait > 0.0 or flat.length() < 0.01:
		return false
	way = flat.normalized()
	_left = TIME
	return true


func stop() -> void:
	_left = 0.0


func step(delta: float) -> void:
	if active():
		_left = maxf(_left - delta, 0.0)
		if _left <= 0.0:
			_wait = COOLDOWN
	else:
		_wait = maxf(_wait - delta, 0.0)


func velocity() -> Vector3:
	return way * (DISTANCE / TIME) if active() else Vector3.ZERO


## Antes de copiar la pose: el esqueleto derecho, porque la copia se mide contra él.
func before_sync(skeleton: Skeleton3D) -> void:
	if _bent:
		skeleton.transform = _rest
		_bent = false


## Después de copiarla: la vuelta entera alrededor de la cadera.
func after_sync(skeleton: Skeleton3D, hip: Vector3) -> void:
	if not active():
		return
	_rest = skeleton.transform
	_bent = true
	var share := 1.0 - _left / TIME
	var eased := share * share * (3.0 - 2.0 * share)
	var bulge := sin(share * PI)
	var size := lerpf(1.0, TUCK, bulge)
	var turn := Basis(Vector3.UP.cross(way).normalized(), eased * TAU).scaled(Vector3.ONE * size)
	var pivot := hip + Vector3.DOWN * DROP * bulge
	var from := skeleton.global_transform
	skeleton.global_transform = Transform3D(turn * from.basis, pivot + turn * (from.origin - hip))
