class_name BrawlerRock
extends Node3D

## LA PIEDRA QUE ARRANCA DEL PISO (ver BrawlerBrain): un pedazo de piso que el Luchador saca con las dos manos, levanta
## sobre la cabeza y te tira en arco. Deja EL POZO donde la sacó. Mientras la levanta, EL AVISO: un círculo rojo en el
## piso que te sigue; al tirarla, el círculo se queda quieto donde estabas y la piedra cae ahí. Si no le pegó a nadie,
## queda en el piso un rato, sin chocar con nada (el usuario: «que no tenga colisión, porque
## hace que ella misma se choque contra ella»), y se hunde. Sólo se mueve y se dibuja: si te
## alcanza lo decide la cabeza.

enum State { HELD, FLYING, LANDED }

## Lo que mide la piedra (m: ancho, alto, largo).
const SIZE := Vector3(18.0, 7.0, 14.0)
const DIRT := Color(0.5, 0.42, 0.33)

var state := State.HELD
## Dónde cae (mundo, en el piso) y el radio del golpe (m).
var spot := Vector3.ZERO
var radius := 18.0
## Recién cayó (la cabeza lo mira una vez y lo apaga).
var just_landed := false

var _rock: Node3D = null
var _zone: BossZone = null
var _hole: Node3D = null
var _from := Vector3.ZERO
var _arc := 30.0
var _flight := 1.4
var _clock := 0.0
var _stay := 6.0
var _spin := Vector3.ZERO


## LA ARMA: el pozo en `dig` (el piso, mundo, girado hacia `facing` en radianes) y la piedra todavía adentro.
func setup(dig: Vector3, facing: float, hit_radius: float) -> void:
	radius = hit_radius
	_hole = Node3D.new()
	_hole.name = "Pozo"
	_hole.top_level = true
	add_child(_hole)
	_hole.global_transform = Transform3D(Basis(Vector3.UP, facing), Vector3(dig.x, 0.0, dig.z))
	Clay.box(_hole, Vector3(SIZE.x, 0.06, SIZE.z), Vector3(0.0, 0.03, 0.0), Color(0.22, 0.18, 0.15))
	for side: float in [-1.0, 1.0]:
		Clay.box(_hole, Vector3(SIZE.x + 2.0, 0.7, 1.2), Vector3(0.0, 0.2, side * (SIZE.z * 0.5 + 0.5)), DIRT.lightened(0.1))
		Clay.box(_hole, Vector3(1.2, 0.7, SIZE.z), Vector3(side * (SIZE.x * 0.5 + 0.5), 0.2, 0.0), DIRT.lightened(0.1))
	_rock = Node3D.new()
	_rock.name = "Piedra"
	_rock.top_level = true
	add_child(_rock)
	Clay.box(_rock, SIZE, Vector3.ZERO, DIRT)
	Clay.box(_rock, Vector3(SIZE.x * 0.7, 1.4, SIZE.z * 0.6), Vector3(0.8, SIZE.y * 0.5 + 0.5, -0.5), DIRT.darkened(0.2))
	Clay.box(_rock, Vector3(3.0, 2.5, 3.0), Vector3(-SIZE.x * 0.5, -1.0, SIZE.z * 0.3), DIRT.darkened(0.1))
	Clay.box(_rock, Vector3(SIZE.x * 0.9, 0.3, SIZE.z * 0.9), Vector3(0.0, SIZE.y * 0.5 + 0.1, 0.0),
		Color(0.45, 0.5, 0.35))
	_rock.global_transform = Transform3D(Basis(Vector3.UP, facing), Vector3(dig.x, -SIZE.y * 0.5, dig.z))
	_zone = BossZone.circle(self, radius)
	_zone.marked = false


## EN LAS MANOS: la piedra va a `at` (mundo) y el aviso, si ya apunta, a `aim` (el piso).
func hold(at: Vector3, facing: float, aim: Variant) -> void:
	_rock.global_transform = Transform3D(Basis(Vector3.UP, facing), at)
	if aim is Vector3:
		_zone.marked = true
		_zone.place(Vector3(aim.x, 0.0, aim.z))


## Dónde está la piedra (mundo).
func held_at() -> Vector3:
	return _rock.global_position


## LA TIRA hacia `target` (el piso): cae ahí en `flight` segundos, subiendo `arc` metros sobre la recta.
func throw(target: Vector3, flight: float, arc: float, stay: float) -> void:
	state = State.FLYING
	spot = Vector3(target.x, 0.0, target.z)
	_from = _rock.global_position
	_flight = maxf(flight, 0.1)
	_arc = arc
	_stay = stay
	_clock = 0.0
	_spin = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 2.5
	_zone.marked = true
	_zone.locked = true
	_zone.place(spot)


## Si un punto del piso (con su medio ancho, m) cae dentro del golpe.
func covers(point: Vector3, half: float) -> bool:
	return _zone.covers(point, half)


## Le pegó a alguien: se rompe (no se queda, se hunde ya).
func shatter() -> void:
	_stay = 0.0


func _physics_process(delta: float) -> void:
	_clock += delta
	match state:
		State.HELD:
			pass
		State.FLYING:
			var t := minf(_clock / _flight, 1.0)
			var at := _from.lerp(spot + Vector3.UP * SIZE.y * 0.5, t) + Vector3.UP * _arc * 4.0 * t * (1.0 - t)
			_rock.global_position = at
			_rock.rotate_object_local(_spin.normalized() if _spin != Vector3.ZERO else Vector3.UP, _spin.length() * delta)
			if t >= 1.0:
				state = State.LANDED
				just_landed = true
				_clock = 0.0
				_zone.marked = false
				_rock.global_transform = Transform3D(Basis(Vector3.UP, randf() * TAU), spot + Vector3.UP * SIZE.y * 0.4)
				# AL CAER: tierra para todos lados, a la medida del golpe, y el ruido.
				BossBursts.dirt(get_parent(), spot, radius / 6.0)
				BossSounds.play(BossSounds.Kind.KNOCKDOWN, spot, get_parent(), 4.0)
		State.LANDED:
			if _clock > _stay:
				_rock.global_position.y -= delta * 3.0
				_hole.global_position.y -= delta * 0.3
				if _rock.global_position.y < -SIZE.y:
					queue_free()
