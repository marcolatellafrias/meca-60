class_name PhysicalCube
extends HoverCube

## EL CUBO FÍSICO: el cubo (HoverCube: las toberas, caer, recuperarse, manejarlo con la O) SIN LA LÍNEA DE EQUILIBRIO:
## parado, su inclinación es la del cuerpo de verdad. Para comparar con la línea; lo pidió el usuario el 12/11/2026
## («tal vez el approach debería ser más físico y… limitar algunas cosas, como… que no rote en Y global por temas de
## gameplay… vamos a poder tal vez tener un mayor rango de situaciones cubiertas, aunque tal vez no convenga»).
##
## PARADO:
##   · GIRA DE COSTADO Y DE FRENTE con la física; EN Y NO (trabado): un golpe nunca le cambia hacia dónde mira.
##   · FLOTA CON UN RESORTE EN CADA ESQUINA de abajo (las perillas de flotar, por esquina): inclinado, las esquinas de
##     abajo empujan más y lo enderezan, como un cuerpo sobre cuatro amortiguadores (`corner_spread`: más juntas, más
##     se ladea).
##   · LOS PIES (`grip_*`): agarran el piso más abajo que el cubo y llevan la base hacia la velocidad pedida (quieto,
##     cero). Un golpe corre el cuerpo y los pies frenan la base: el cubo VUELCA hacia el golpe, más cuanto más arriba
##     pegó. Lo que pide el que lo maneja lo empuja desde el centro: arrancar y frenar no lo cabecean.
##   · UN TORQUE CHICO que lo endereza (`upright_*`), además de las esquinas.
## Pasado `fall_tilt`, SE CAE: suelto del todo, como el cubo. Después se recupera igual.
##
## Las perillas, en PhysicalCubeSettings (el panel F1 de su fila); el F2 lo empuja arriba (suave o fuerte).


func _ready() -> void:
	super()
	name = "Cubo físico"


func tuning() -> HoverCubeSettings:
	return PhysicalCubeSettings.shared


## Parado sólo se traba el giro en Y; caído, nada.
func _lock(on: bool) -> void:
	axis_lock_angular_x = false
	axis_lock_angular_y = on
	axis_lock_angular_z = false


func _standing(knobs: HoverCubeSettings, delta: float) -> void:
	var k := knobs as PhysicalCubeSettings
	tilt = rad_to_deg(global_basis.y.normalized().angle_to(Vector3.UP))
	if tilt > k.fall_tilt:
		_fall_down()
		return
	_note_hit()
	_drive(k, delta)
	_corners(k)
	_feet(k)
	_upright(k)
	_velocity_after = linear_velocity


## Para mirar: el último golpe (lo que cambió la velocidad de costado) y contra qué.
func _note_hit() -> void:
	var change := linear_velocity - _velocity_after
	var flat := Vector3(change.x, 0.0, change.z)
	if flat.length() <= HIT_NOISE:
		return
	last_hit = flat.length()
	var touch := _touch()
	last_hit_kind = "fijo" if bool(touch["fixed"]) else ("golpe" if touch["at"] != null else "empujón")


## MANEJARLO: A/D lo gira (en Y, que la física no toca) y W/S pide una velocidad, a la que llega con `walk_accel` y
## frena con `walk_brake`; la llevan los pies.
func _drive(k: PhysicalCubeSettings, delta: float) -> void:
	var wanted := Vector3.ZERO
	if driving and UIState.gameplay_active():
		var turn := HoverCube._axis(KEY_A, KEY_D) * deg_to_rad(k.turn_speed) * delta
		if turn != 0.0:
			global_basis = Basis(Vector3.UP, turn) * global_basis
		var forward := -global_basis.z
		forward.y = 0.0
		wanted = forward.normalized() * HoverCube._axis(KEY_W, KEY_S) * k.walk_speed
	var rate := k.walk_accel if wanted.length_squared() > 0.0001 else k.walk_brake
	var before := _walk
	_walk = _walk.move_toward(wanted, rate * delta)
	# Lo que pide él lo empuja desde el centro (como quien se inclina para arrancar): los pies sólo frenan lo que no
	# pidió, y arrancar o frenar no lo cabecea.
	apply_central_force((_walk - before) / maxf(delta, 0.0001) * CUBE_MASS)


## LAS CUATRO ESQUINAS: cada una, un resorte al piso (el de flotar, con un cuarto del peso).
func _corners(k: PhysicalCubeSettings) -> void:
	var reach := k.hover_height + k.max_height_error + 3.0
	var spread := SIZE * 0.5 * k.corner_spread
	var heights := 0.0
	var touching := 0
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var point := global_transform * Vector3(corner.x * spread, -SIZE * 0.5, corner.y * spread)
		var hit := _ray(point, point + Vector3.DOWN * reach)
		if hit.is_empty():
			continue
		var gap := point.y - (hit["position"] as Vector3).y
		heights += gap
		touching += 1
		var arm := point - global_position
		var speed := (linear_velocity + angular_velocity.cross(arm)).y
		var error := clampf(k.hover_height - gap, -k.max_height_error, k.max_height_error)
		var accel := k.height_kp * error - k.height_kd * speed + _gravity()
		apply_force(Vector3.UP * CUBE_MASS * 0.25 * clampf(accel, 0.0, k.max_up), arm)
	height = heights / touching if touching > 0 else reach


## LOS PIES: abajo del cubo (`grip_depth` hacia el piso), llevan la base hacia la velocidad pedida.
func _feet(k: PhysicalCubeSettings) -> void:
	var below := SIZE * 0.5 + height * k.grip_depth
	var arm := -Vector3.UP * below
	var base := linear_velocity + angular_velocity.cross(arm)
	var off := Vector3(base.x - _walk.x, 0.0, base.z - _walk.z)
	var accel := (-off * k.grip_rate).limit_length(k.grip_max)
	apply_force(accel * CUBE_MASS, arm)


## Un torque chico hacia derecho, con freno (sin el giro en Y, que está trabado).
func _upright(k: PhysicalCubeSettings) -> void:
	var up := global_basis.y.normalized()
	var axis := up.cross(Vector3.UP)
	var angle := up.angle_to(Vector3.UP)
	var spin := Vector3(angular_velocity.x, 0.0, angular_velocity.z)
	var turn := (axis.normalized() * angle if axis.length() > 0.0001 else Vector3.ZERO) * k.upright_kp
	apply_torque((turn - spin * k.upright_kd) * _inertia)


## SE CAE: suelto del todo; después, como el cubo.
func _fall_down() -> void:
	_lock(false)
	state = State.LIMP
	_clock = 0.0
	_walk = Vector3.ZERO
	falls += 1


## EL F2: un empujón de costado ARRIBA (como un golpe alto), suave o fuerte.
func knock(strong: bool) -> void:
	if state != State.HOVER:
		return
	var k := tuning() as PhysicalCubeSettings
	var side := global_basis.x
	side.y = 0.0
	apply_impulse(side.normalized() * CUBE_MASS * (k.knock_strong if strong else k.knock_soft),
		global_basis * Vector3(0.0, SIZE * 0.5, 0.0))
