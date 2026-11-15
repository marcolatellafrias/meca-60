class_name BrawlerWave
extends Node3D

## LA ONDA DEL GOLPE AL PISO (ver BrawlerBrain): primero EL AVISO, una franja roja en el piso que muestra por dónde va a
## salir (sigue a la cintura); con el golpe, LA ONDA, un lomo de tierra que corre por el piso, derecho, hasta su
## alcance. Sólo se mueve y se dibuja: si te alcanza lo decide la cabeza.

## El alto y el largo del lomo (m).
const RIDGE := Vector2(5.0, 5.0)

## Desde dónde sale (mundo, en el piso) y hacia dónde (de costado, largo 1).
var origin := Vector3.ZERO
var way := Vector3.FORWARD
## Por dónde va el frente del lomo (m desde `origin`), y si ya salió.
var front := 0.0
var launched := false

var _width := 14.0
var _reach := 140.0
var _speed := 45.0
var _strip: MeshInstance3D = null
var _strip_paint := StandardMaterial3D.new()
var _ridge: Node3D = null


## LA ARMA con su ancho y su alcance (m), mostrando el aviso.
func setup(width: float, reach: float) -> void:
	_width = width
	_reach = reach
	_strip_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_strip_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_strip_paint.albedo_color = Color(1.0, 0.15, 0.1, 0.3)
	_strip = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.08, reach)
	_strip.mesh = mesh
	_strip.material_override = _strip_paint
	_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_strip)


## EL AVISO apunta desde `from` hacia `toward` (en el piso).
func aim(from: Vector3, toward: Vector3) -> void:
	origin = Vector3(from.x, 0.0, from.z)
	way = Vector3(toward.x, 0.0, toward.z).normalized()
	global_transform = Transform3D(Basis.looking_at(way, Vector3.UP), origin)
	_strip.position = Vector3(0.0, 0.05, -_reach * 0.5)
	_strip_paint.albedo_color.a = 0.22 + 0.12 * sin(Time.get_ticks_msec() * 0.012)


## SALE LA ONDA, a `speed` m/s: el aviso se apaga y arranca el lomo.
func launch(speed: float) -> void:
	_speed = speed
	launched = true
	_strip.queue_free()
	_strip = null
	_ridge = Node3D.new()
	add_child(_ridge)
	var dirt := Color(0.5, 0.42, 0.33)
	Clay.box(_ridge, Vector3(_width, RIDGE.x, RIDGE.y), Vector3(0.0, RIDGE.x * 0.5 - 0.5, 0.0), dirt)
	Clay.box(_ridge, Vector3(_width * 0.7, RIDGE.x * 0.6, RIDGE.y * 0.8), Vector3(0.0, RIDGE.x + 0.2, 0.3), dirt.darkened(0.2))
	for side: float in [-1.0, 1.0]:
		Clay.box(_ridge, Vector3(2.0, RIDGE.x * 0.6, RIDGE.y * 1.4), Vector3(side * (_width * 0.5 + 0.6), 0.6, 1.0),
			dirt.lightened(0.15))


func _physics_process(delta: float) -> void:
	if not launched:
		return
	front += _speed * delta
	_ridge.position = Vector3(0.0, 0.0, -front)
	# Al final, se hunde y se va.
	if front > _reach:
		_ridge.position.y -= (front - _reach) * 0.6
	if front > _reach + RIDGE.x * 3.0:
		queue_free()


## Si un punto del piso (con su medio ancho, m) está debajo del lomo ahora.
func covers(point: Vector3, half: float) -> bool:
	if not launched or front > _reach:
		return false
	var local := point - origin
	var ahead := way.dot(local)
	var aside := absf(way.cross(Vector3.UP).dot(local))
	return absf(ahead - front) < RIDGE.y * 0.5 + half and aside < _width * 0.5 + half
