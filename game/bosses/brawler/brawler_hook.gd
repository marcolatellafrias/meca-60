class_name BrawlerHook
extends Node3D

## LA MANO DEL AGARRE (ver BrawlerBrain): un skillshot. Primero EL AVISO, una franja roja angosta en el piso por donde va
## a salir la mano (sigue a la cintura y, al final, se queda quieta y titila: ya apuntó); con el tiro, LA MANO sale
## derecho con su cadena hasta su alcance y vuelve. Si agarró algo, la cabeza lo arrastra con la punta. Sólo se mueve y
## se dibuja: si te toca lo decide la cabeza.

enum State { AIM, OUT, BACK }

## El puño (m) y a qué altura va la cadena (m sobre el piso).
const FIST := 6.0
const HEIGHT := 12.0
const COLOR := Color(0.62, 0.2, 0.18)

var state := State.AIM
## Desde dónde sale (mundo, en el piso), hacia dónde (de costado, largo 1) y por dónde va la punta (m desde `origin`).
var origin := Vector3.ZERO
var way := Vector3.FORWARD
var front := 0.0

var _width := 6.0
var _reach := 85.0
var _speed := 90.0
var _strip: MeshInstance3D = null
var _strip_paint := StandardMaterial3D.new()
var _fist: MeshInstance3D = null
var _chain: MeshInstance3D = null


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
	_strip.position = Vector3(0.0, 0.05, -reach * 0.5)
	add_child(_strip)


## EL AVISO apunta desde `from` hacia `toward` (en el piso). `locked`: ya apuntó (titila rápido).
func aim(from: Vector3, toward: Vector3, locked: bool) -> void:
	origin = Vector3(from.x, 0.0, from.z)
	way = Vector3(toward.x, 0.0, toward.z).normalized()
	global_transform = Transform3D(Basis.looking_at(way, Vector3.UP), origin)
	var beat := 0.035 if locked else 0.012
	_strip_paint.albedo_color.a = (0.35 if locked else 0.22) + 0.15 * sin(Time.get_ticks_msec() * beat)


## SALE LA MANO, a `speed` m/s.
func launch(speed: float) -> void:
	_speed = speed
	state = State.OUT
	_strip.queue_free()
	_strip = null
	_chain = Clay.box(self, Vector3(1.6, 1.6, 1.0), Vector3.ZERO, COLOR.darkened(0.4))
	_fist = Clay.box(self, Vector3.ONE * FIST, Vector3.ZERO, COLOR)
	_place()


## VUELVE (agarró algo o llegó a su alcance).
func reel() -> void:
	state = State.BACK


## Dónde está la punta (mundo, en el piso).
func tip() -> Vector3:
	return origin + way * front


## Si un punto del piso (con su medio ancho, m) está tocando la punta.
func touches(point: Vector3, half: float) -> bool:
	if state != State.OUT:
		return false
	var local := point - origin
	var ahead := way.dot(local)
	var aside := absf(way.cross(Vector3.UP).dot(local))
	return absf(ahead - front) < FIST * 0.5 + half and aside < _width * 0.5 + half


## Si ya volvió (y se va).
func home() -> bool:
	return state == State.BACK and front <= 0.0


func _physics_process(delta: float) -> void:
	match state:
		State.OUT:
			front = minf(front + _speed * delta, _reach)
			if front >= _reach:
				state = State.BACK
		State.BACK:
			front = maxf(front - _speed * 0.6 * delta, 0.0)
			if front <= 0.0:
				queue_free()
		_:
			return
	_place()


func _place() -> void:
	_fist.position = Vector3(0.0, HEIGHT, -front)
	_chain.position = Vector3(0.0, HEIGHT, -front * 0.5)
	_chain.scale = Vector3(1.0, 1.0, maxf(front, 0.01))
