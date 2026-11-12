class_name BalanceCube
extends HoverCube

## EL CUBO CON EQUILIBRIO: el cubo flotante (HoverCube: flota, cae con física y se recupera con las toberas) con LA
## LÍNEA DE EQUILIBRIO en vez del torque, como el sistema de los personajes de character-parametric. Lo pidió el usuario
## el 11/11/2026, bifurcando el cubo: «el impulso… me llegó un impulso de tal lado, bueno, entonces mi cuerpo se mueve
## hacia el otro lado como recibiendo ese impulso. Y aparte, ese impulso me hace inclinarme… si recibo un impulso en el
## torso, automáticamente me hace inclinar, no importa a qué altura… un cubo que tiene unas piernas invisibles y que se
## lo empuja por un lado y como que se tropieza y se va para ese lado del impulso y se cae».
##
## PARADO, el cuerpo no gira (sus giros están trabados). Dos cosas aparte:
##   · EL IMPULSO LO CORRE: un golpe le cambia la velocidad y el cuerpo sale para ese lado (lo frena el freno de costado
##     del cubo flotante).
##   · LA LÍNEA DE EQUILIBRIO (`lean`): ese mismo golpe —medido como lo que cambió la velocidad sin que él lo pidiera,
##     a cualquier altura— le suma a la velocidad de la inclinación; un resorte la devuelve. Se ve inclinando el DIBUJO
##     sobre el canto de abajo (el cuerpo sigue derecho).
## AL PASAR `fall_at`, TROPIEZA: el cuerpo toma la inclinación del dibujo (girando sobre ese mismo canto) y queda
## suelto, con UN giro de una vez: el justo para que su BASE QUEDE QUIETA en ese instante —como si los pies se trabaran—
## (ω = arriba × v / h), más lo que se venía inclinando. Desde ahí, todo es física: la base roza el piso, la parte de
## arriba sigue con el impulso y cae para ese lado. Después se recupera como el cubo flotante y, derecho otra vez, vuelve
## a la línea.
##
## Las perillas: BalanceCubeSettings (la línea, el tropezar) y `hover_knobs` (flotar, caído, recuperarse), en el panel
## F1 de su fila.

const HIT_NOISE := 0.3

## Lo de flotar y recuperarse, en su propia copia (ver HoverCubeSettings), con más freno de giro caído que el flotante:
## tropieza, cae de costado y se queda (no se pone a rodar).
static var hover_knobs := BalanceCube._own_knobs()


static func _own_knobs() -> HoverCubeSettings:
	var knobs := HoverCubeSettings.new()
	knobs.ground_spin_damp = 2.5
	return knobs

## La inclinación (x a la derecha, y adelante, en el espacio del cubo) y el último golpe (m/s), para mirar.
var lean := Vector2.ZERO
var last_hit := 0.0

var _lean_speed := Vector2.ZERO
var _velocity_after := Vector3.ZERO


func _ready() -> void:
	super()
	name = "Cubo con equilibrio"
	_lock(true)


func tuning() -> HoverCubeSettings:
	return hover_knobs


## Los giros del cuerpo, trabados (parado) o sueltos (caído y recuperándose).
func _lock(on: bool) -> void:
	axis_lock_angular_x = on
	axis_lock_angular_y = on
	axis_lock_angular_z = on


func _standing(knobs: HoverCubeSettings, delta: float) -> void:
	var line := BalanceCubeSettings.current
	_measure_hit(line)
	_hover(knobs)
	_spring(line, delta)
	_look.transform = _leaning(line)
	tilt = rad_to_deg(lean.length() * deg_to_rad(line.lean_angle))
	_velocity_after = linear_velocity
	if lean.length() >= line.fall_at:
		_trip(line)


## EL GOLPE: lo que cambió la velocidad de costado desde el paso anterior sin que él lo pidiera (su freno es muy poco por
## paso para contar).
func _measure_hit(line: BalanceCubeSettings) -> void:
	var change := linear_velocity - _velocity_after
	var flat := Vector3(change.x, 0.0, change.z)
	if flat.length() <= HIT_NOISE:
		return
	last_hit = flat.length()
	var local := global_basis.inverse() * flat
	_lean_speed += Vector2(local.x, -local.z) * line.lean_per_ms * line.push_rate


func _spring(line: BalanceCubeSettings, delta: float) -> void:
	_lean_speed += (-lean * line.stiffness - _lean_speed * line.damping) * delta
	lean += _lean_speed * delta


## El dibujo inclinado sobre el canto de abajo hacia donde se inclina (ver MechBody.tilt).
func _leaning(line: BalanceCubeSettings) -> Transform3D:
	var pivot := Vector3(0.0, -SIZE * 0.5, 0.0)
	var turn := MechBody.tilt(lean * deg_to_rad(line.lean_angle))
	return Transform3D(Basis(), pivot) * Transform3D(turn, Vector3.ZERO) * Transform3D(Basis(), -pivot)


## TROPIEZA (ver arriba): el cuerpo toma la inclinación del dibujo, queda suelto y recibe el giro de los pies trabados.
func _trip(line: BalanceCubeSettings) -> void:
	var turn := MechBody.tilt(lean * deg_to_rad(line.lean_angle))
	var base := global_transform * Vector3(0.0, -SIZE * 0.5, 0.0)
	var leaned := global_basis * turn
	var direction := global_basis * Vector3(lean.x, 0.0, -lean.y).normalized()
	var tipping := maxf(_lean_speed.dot(lean.normalized()), 0.0) * deg_to_rad(line.lean_angle)
	_lock(false)
	global_transform = Transform3D(leaned, base + leaned * Vector3(0.0, SIZE * 0.5, 0.0))
	_look.transform = Transform3D()
	var side := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	angular_velocity = Vector3.UP.cross(side) / (SIZE * 0.5) * line.base_grip \
		+ Vector3.UP.cross(direction) * tipping * line.tip_carry
	lean = Vector2.ZERO
	_lean_speed = Vector2.ZERO
	_fall()


## DERECHO OTRA VEZ: trabado, mirando hacia donde miraba, y la línea en cero.
func _recovered() -> void:
	var forward := -global_basis.z
	forward.y = 0.0
	var yaw := atan2(-forward.x, -forward.z) if forward.length_squared() > 0.01 else global_rotation.y
	global_basis = Basis(Vector3.UP, yaw)
	angular_velocity = Vector3.ZERO
	_lock(true)
	lean = Vector2.ZERO
	_lean_speed = Vector2.ZERO
	_velocity_after = linear_velocity


## VOLCARLO (el panel chico, F2): un empujón de costado, como un golpe —lo mide la línea—: SUAVE, apenas pasado su
## caerse; FUERTE, mucho más.
func knock(strong: bool) -> void:
	if state != State.HOVER:
		return
	var side := global_basis.x
	side.y = 0.0
	linear_velocity += side.normalized() * BalanceCube.delta_v_for_lean(
		BalanceCubeSettings.current.fall_at * (2.5 if strong else 1.2))


## ── CUÁNTO HAY QUE EMPUJARLO ─────────────────────────────────────────────────────────────────────────────────────
## El cambio de velocidad (m/s) que lo lleva a la inclinación `target`: el golpe suma a la velocidad de la inclinación,
## y la inclinación más alta del resorte por unidad se calcula paso a paso (como la corre `_spring`).
static func delta_v_for_lean(target: float) -> float:
	var line := BalanceCubeSettings.current
	var step := 1.0 / 240.0
	var lean_now := 0.0
	var speed_now := 1.0
	var peak := 0.0
	for i in 2400:
		speed_now += (-lean_now * line.stiffness - speed_now * line.damping) * step
		lean_now += speed_now * step
		peak = maxf(peak, lean_now)
		if speed_now < 0.0:
			break
	return target / maxf(peak * line.lean_per_ms * line.push_rate, 0.0001)
