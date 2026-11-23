class_name BossZone
extends Node3D

## UNA ZONA EN EL PISO (17/11/2026): la pieza común de todo ataque «geométrico» de un jefe (el usuario: «otras
## literalmente te marcan una zona en el piso… zonas de ataques con círculos»). Es LA CUENTA de si un punto está adentro
## (`covers`) y, si se quiere, LA MARCA que avisa (opcional: «en juegos como el Dark Souls… todo se guía por
## animaciones… esto sería algo más que podría o no poner»: BossSettings.floor_marks la apaga para todos, `marked` para
## una). No hace daño: el poder que la usa decide cuándo pega.
##   · CÍRCULO (`circle`): un radio. · FRANJA (`strip`): ancho y largo, hacia adelante. · CONO (`cone`): medio ángulo y
##     largo, hacia adelante. · ANILLO (`ring`): un radio y un grosor; puede CRECER solo (`grow`): una onda redonda que se
##     abre, y se va al llegar a su tope.
## `place(origen, hacia)` la pone; `locked` la hace titilar rápido (ya apuntó). Antes cada cosa dibujaba la suya (la
## franja de la onda y la del agarre, el círculo de la piedra, el abanico del lanzallamas).

enum Shape { CIRCLE, STRIP, CONE, RING }

const COLOR := Color(1.0, 0.15, 0.1)

var shape := Shape.CIRCLE
## Lo que mide: el radio (círculo, anillo), el ancho (franja) o el medio ángulo en grados (cono); y el largo (franja,
## cono) o el grosor (anillo).
var size := 10.0
var length := 10.0
## Dónde está (el piso) y hacia dónde mira (de costado, largo 1).
var origin := Vector3.ZERO
var way := Vector3.FORWARD
## Ya apuntó (titila rápido), y si se ve (además de BossSettings.floor_marks).
var locked := false
var marked := true
## EL ANILLO QUE CRECE: a cuántos m/s y hasta qué radio (0, no crece).
var grow_speed := 0.0
var grow_to := 0.0
## DE UNA HABILIDAD DE LA MECA (ver `skill`): su color, y se ve aunque las marcas del jefe estén apagadas.
var tint := COLOR
var always := false

var _mark: MeshInstance3D = null
var _paint := StandardMaterial3D.new()
var _drawn := Vector2(-1.0, -1.0)
var _drawn_shape := -1


static func circle(parent: Node, radius: float) -> BossZone:
	return _make(parent, Shape.CIRCLE, radius, 0.0)


static func strip(parent: Node, width: float, long: float) -> BossZone:
	return _make(parent, Shape.STRIP, width, long)


static func cone(parent: Node, half_angle: float, long: float) -> BossZone:
	return _make(parent, Shape.CONE, half_angle, long)


## Un anillo de `radius` y `thick` de grosor; con `speed` y `top`, crece solo hasta `top` y se va.
static func ring(parent: Node, radius: float, thick: float, speed := 0.0, top := 0.0) -> BossZone:
	var made := _make(parent, Shape.RING, radius, thick)
	made.grow_speed = speed
	made.grow_to = top
	return made


## La marca de una habilidad de la meca (MechSkills): la forma se le pone después.
static func skill(parent: Node, color: Color) -> BossZone:
	var made := _make(parent, Shape.CIRCLE, 1.0, 0.0)
	made.tint = color
	made.always = true
	return made


static func _make(parent: Node, kind: Shape, a: float, b: float) -> BossZone:
	var made := BossZone.new()
	made.name = "Zona"
	made.shape = kind
	made.size = a
	made.length = b
	made.top_level = true
	parent.add_child(made)
	return made


func _ready() -> void:
	_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	_paint.albedo_color = Color(tint, 0.25)
	_mark = MeshInstance3D.new()
	_mark.material_override = _paint
	_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mark)


## LA PONE: en `from` (el piso), mirando hacia `toward` (de costado).
func place(from: Vector3, toward := Vector3.FORWARD) -> void:
	origin = Vector3(from.x, from.y, from.z)
	var flat := Vector3(toward.x, 0.0, toward.z)
	way = flat.normalized() if flat.length() > 0.001 else Vector3.FORWARD
	global_transform = Transform3D(Basis.looking_at(way, Vector3.UP), origin + Vector3.UP * 0.06)


func _process(_delta: float) -> void:
	_mark.visible = marked and (always or BossSettings.current.floor_marks)
	if not _mark.visible:
		return
	if _drawn != Vector2(size, length) or _drawn_shape != int(shape):
		_drawn = Vector2(size, length)
		_drawn_shape = int(shape)
		_mark.mesh = _mesh()
	var beat := 0.035 if locked else 0.012
	_paint.albedo_color = Color(tint, (0.36 if locked else 0.22) + 0.12 * sin(Time.get_ticks_msec() * beat))


func _physics_process(delta: float) -> void:
	if shape == Shape.RING and grow_speed > 0.0:
		size += grow_speed * delta
		if grow_to > 0.0 and size >= grow_to:
			queue_free()


## Si un punto del piso (con su medio ancho, m) está adentro.
func covers(point: Vector3, half := 0.0) -> bool:
	return BossZone.shape_covers(shape, size, length, origin, way, point, half)


## LA CUENTA DE UNA FORMA, sin hacer falta una zona armada (la usan también las habilidades, MechSkills).
static func shape_covers(kind: Shape, a: float, b: float, from: Vector3, ahead_way: Vector3, point: Vector3,
		half := 0.0) -> bool:
	var local := Vector3(point.x - from.x, 0.0, point.z - from.z)
	var far := local.length()
	match kind:
		Shape.CIRCLE:
			return far < a + half
		Shape.RING:
			return absf(far - a) < b * 0.5 + half
		Shape.STRIP:
			var ahead := ahead_way.dot(local)
			var aside := absf(ahead_way.cross(Vector3.UP).dot(local))
			return ahead > -half and ahead < b + half and aside < a * 0.5 + half
		_:
			if far > b + half:
				return false
			if far < 0.01:
				return true
			return rad_to_deg(ahead_way.angle_to(local / far)) < a + rad_to_deg(atan2(half, far))


## La malla chata de su forma, hacia −z.
func _mesh() -> ArrayMesh:
	var points := PackedVector3Array()
	match shape:
		Shape.STRIP:
			var w := size * 0.5
			_quad(points, Vector3(-w, 0, 0), Vector3(w, 0, 0), Vector3(w, 0, -length), Vector3(-w, 0, -length))
		Shape.RING:
			var steps := 48
			for index in steps:
				var a := TAU * index / steps
				var b := TAU * (index + 1) / steps
				var inner := maxf(size - length * 0.5, 0.0)
				var outer := size + length * 0.5
				_quad(points, _around(a, inner), _around(b, inner), _around(b, outer), _around(a, outer))
		_:
			var degrees := 360.0 if shape == Shape.CIRCLE else size * 2.0
			var far := size if shape == Shape.CIRCLE else length
			var steps := 48 if shape == Shape.CIRCLE else 16
			for index in steps:
				var a := deg_to_rad(-degrees * 0.5 + degrees * index / steps)
				var b := deg_to_rad(-degrees * 0.5 + degrees * (index + 1) / steps)
				points.append(Vector3.ZERO)
				points.append(_around(a, far))
				points.append(_around(b, far))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _around(angle: float, far: float) -> Vector3:
	return Vector3(sin(angle), 0.0, -cos(angle)) * far


static func _quad(points: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	points.append_array(PackedVector3Array([a, b, c, a, c, d]))
