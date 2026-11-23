class_name MechKeyIcon
extends Control

## EL SÍMBOLO DE UN CUADRADO, CON LOS CONTROLES DE CLIC (22/11/2026; el usuario: «que los botones ya no tengan letras… si no
## símbolos con lo que hacen»). Plano y negro, dibujado acá en un cuadrado de `BOX` de lado. Los de los brazos dicen lo que
## lleva esa punta (`of_tip`), y el brazo derecho y el giro a la derecha son el izquierdo en espejo.

enum Kind { NONE, FIST, HEAVY_FIST, POLE, DRILL, SAW, CANNON, SHIELD, MINIGUN, MISSILE, DASH, HOVER, TURN }

const BOX := 56.0
const INK := Color.BLACK

var kind := Kind.NONE
var mirrored := false


## El símbolo fijo de la tecla `slot` (los brazos, según su punta: `of_tip`).
static func of_slot(slot: int) -> Kind:
	match slot:
		MechCrew.LEFT, MechCrew.RIGHT:
			return Kind.TURN
		MechCrew.ARM_LEFT, MechCrew.ARM_RIGHT:
			return Kind.FIST
		MechCrew.MINIGUN:
			return Kind.MINIGUN
		MechCrew.MISSILES:
			return Kind.MISSILE
		MechCrew.DASH:
			return Kind.DASH
		MechCrew.FLY:
			return Kind.HOVER
		MechCrew.SHIELD:
			return Kind.SHIELD
	return Kind.NONE


static func of_tip(tip: ArmTip) -> Kind:
	if tip is HeavyFistTip:
		return Kind.HEAVY_FIST
	if tip is PoleTip:
		return Kind.POLE
	if tip is DrillTip:
		return Kind.DRILL
	if tip is SawTip:
		return Kind.SAW
	if tip is CannonTip:
		return Kind.CANNON
	if tip is ShieldTip:
		return Kind.SHIELD
	return Kind.FIST


func set_kind(fresh: Kind) -> void:
	if fresh != kind:
		kind = fresh
		queue_redraw()


func _draw() -> void:
	if mirrored:
		draw_set_transform(Vector2(BOX, 0.0), 0.0, Vector2(-1.0, 1.0))
	match kind:
		Kind.FIST:
			_fist(1.0)
		Kind.HEAVY_FIST:
			_fist(1.25)
		Kind.POLE:
			draw_line(Vector2(15.0, 42.0), Vector2(41.0, 14.0), INK, 6.0)
			_rect(35.0, 10.0, 9.0, 9.0)
		Kind.DRILL:
			_shape([Vector2(28.0, 8.0), Vector2(39.0, 34.0), Vector2(17.0, 34.0)])
			_rect(21.0, 37.0, 14.0, 8.0)
		Kind.SAW:
			_saw()
		Kind.CANNON:
			_rect(11.0, 21.0, 21.0, 14.0)
			_rect(31.0, 17.0, 5.0, 22.0)
			draw_circle(Vector2(44.0, 28.0), 5.0, INK)
		Kind.SHIELD:
			_shape([Vector2(28.0, 10.0), Vector2(42.0, 16.0), Vector2(42.0, 30.0), Vector2(28.0, 46.0), Vector2(14.0, 30.0),
				Vector2(14.0, 16.0)])
		Kind.MINIGUN:
			_rect(9.0, 12.0, 14.0, 22.0)
			for y: float in [14.0, 21.5, 29.0]:
				_rect(23.0, y, 24.0, 3.0)
			_rect(35.0, 12.0, 3.0, 22.0)
		Kind.MISSILE:
			_shape([Vector2(28.0, 5.0), Vector2(34.0, 15.0), Vector2(34.0, 29.0), Vector2(40.0, 38.0), Vector2(16.0, 38.0),
				Vector2(22.0, 29.0), Vector2(22.0, 15.0)])
		Kind.DASH:
			for x: float in [15.0, 29.0]:
				draw_polyline(PackedVector2Array([Vector2(x, 15.0), Vector2(x + 12.0, 28.0), Vector2(x, 41.0)]), INK, 5.0)
		Kind.HOVER:
			_rect(13.0, 14.0, 30.0, 7.0)
			for x: float in [18.0, 28.0, 38.0]:
				_shape([Vector2(x - 4.0, 25.0), Vector2(x + 4.0, 25.0), Vector2(x, 42.0)])
		Kind.TURN:
			draw_arc(Vector2(28.0, 31.0), 13.0, 0.0, -PI, 20, INK, 4.5)
			_shape([Vector2(8.0, 29.0), Vector2(22.0, 29.0), Vector2(15.0, 40.0)])


func _fist(size: float) -> void:
	var wide := 26.0 * size
	var left := 28.0 - wide * 0.5
	var top := 28.0 - 13.0 * size
	_rect(left, top + 6.0 * size, wide, 15.0 * size)
	for finger in 4:
		_rect(left + finger * wide * 0.25 + 0.5, top, wide * 0.25 - 1.5, 5.0 * size)
	_rect(left - 4.0 * size, top + 9.0 * size, 4.0 * size, 9.0 * size)
	_rect(28.0 - 7.0 * size, top + 22.0 * size, 14.0 * size, 5.0 * size)


func _saw() -> void:
	var middle := Vector2(28.0, 28.0)
	for tooth in 8:
		var angle := TAU * tooth / 8.0
		_shape([middle + Vector2.from_angle(angle - 0.3) * 12.0, middle + Vector2.from_angle(angle) * 20.0,
			middle + Vector2.from_angle(angle + 0.3) * 12.0])
	draw_circle(middle, 13.0, INK)
	draw_circle(middle, 4.0, Color.WHITE)


func _rect(x: float, y: float, wide: float, high: float) -> void:
	draw_rect(Rect2(x, y, wide, high), INK)


func _shape(points: Array[Vector2]) -> void:
	draw_colored_polygon(PackedVector2Array(points), INK)
