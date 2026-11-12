class_name PendulumMech
extends PendulumCube

## LA MECA PÉNDULO: el cubo péndulo (PendulumCube: el torso es un péndulo sobre su apoyo, los pies lo siguen) camino a
## ser la meca. Lo pidió el usuario el 12/11/2026 («vamos a seguir puliendo la del cubo péndulo… que tenga 3 pisos igual
## que los otros… simplemente las puertas… que tenga brazos… saltar… propulsor… se agacha… corre»). En su propia fila; el
## cubo péndulo queda como estaba.
##
## POR DENTRO, TRES PISOS con la proporción del cubo (`_build_cabin`): cada uno con su vidrio y sus parantes al frente,
## su PUERTA atrás (el hueco, sin escalera todavía) y su asiento. La primera persona es la del asiento del medio.
## LOS BRAZOS (`_build_arms`), dibujo, en guardia: el hombro y el codo son ESFERAS, la muñeca un CUBO, y los dedos
## CILINDROS, piezas separadas; el pulgar va en la cara de costado del cubo. No pegan todavía: los brazos con músculos
## son el paso que sigue.
##
## LO QUE HACE, poseída (lo vertical sale del largo del palo del péndulo, `_rod`, como en los personajes sale de su
## resorte de altura):
##   · CORRER (Shift, yendo hacia adelante): hasta `sprint_multiplier` por la velocidad de caminar. Lo de arriba de la
##     caminata es una banda que se gana y se pierde a `sprint_accel` de la aceleración: tarda en llegar y en irse.
##   · AGACHARSE (Ctrl): el palo se acorta (`crouch_rod`), el cuerpo baja y las piernas se doblan solas; camina más lento.
##   · SALTAR (espacio): mantener CARGA —el cuerpo baja, `jump_squat`— y soltar SALTA, de `jump_least` a todo su
##     `jump_height` según lo cargado (se carga altura, no fuerza: la barra es lineal con lo que salta). En el aire va
##     derecha y sin apoyo; cuando la punta del palo vuelve a tocar, aterriza.
##   · EL PROPULSOR (espacio en el aire): las toberas de abajo la empujan para arriba mientras le quede (`thrust_time`);
##     se recarga en el piso.
##
## Las perillas, en PendulumMechSettings (el panel F1 de su fila).

const FLOORS := 3
const FLOOR_HEIGHT := SIZE / FLOORS
## El frente de cada piso: el antepecho y el vidrio; el dintel, lo que queda.
const SILL := 0.75
const GLASS := 1.4
## La puerta de atrás de cada piso.
const DOOR := Vector2(1.1, 2.05)
## LOS BRAZOS: el hombro, en el espacio del cubo (`x` del lado derecho), y el puño en guardia, desde el hombro.
const SHOULDER := Vector3(SIZE * 0.5 + 1.0, 1.9, -0.4)
const GUARD := Vector3(-1.5, -2.6, -6.2)
const ARM_THICKNESS := 1.5
const HAND := 1.9
const FINGER := Vector2(0.24, 1.25)

## Lo cargado del salto y lo que le queda al propulsor (0 a 1), para mirar.
var jump_charge := 0.0
var fuel := 1.0

## El largo del palo de ahora, en partes del entero (agachada, cargando).
var _rod_scale := 1.0
var _space_was := false
## En el aire, el espacio empuja recién cuando se lo vuelve a apretar (el que soltó para saltar no cuenta).
var _thrust_armed := false


func _ready() -> void:
	super()
	name = "Meca péndulo"
	_build_arms()


func tuning() -> HoverCubeSettings:
	return PendulumMechSettings.tuned


## ── LO QUE HACE ──────────────────────────────────────────────────────────────────────────────────────────────────

func _standing(knobs: HoverCubeSettings, delta: float) -> void:
	_abilities(knobs as PendulumMechSettings, delta)
	super(knobs, delta)


## Agacharse, cargar y soltar el salto, y el propulsor: lo que piden las teclas en este paso.
func _abilities(k: PendulumMechSettings, delta: float) -> void:
	var mine := driving and UIState.gameplay_active()
	var space := mine and Input.is_physical_key_pressed(KEY_SPACE)
	var crouching := mine and Input.is_physical_key_pressed(KEY_CTRL)
	if _airborne:
		jump_charge = 0.0
		if not space:
			_thrust_armed = true
		if space and _thrust_armed and fuel > 0.0:
			fuel = maxf(fuel - delta / k.thrust_time, 0.0)
			_push(Vector3.UP * k.thrust * CUBE_MASS, Vector3.ZERO, k)
	else:
		_thrust_armed = false
		fuel = minf(fuel + delta / k.thrust_refill, 1.0)
		if space and not crouching and _grounded:
			jump_charge = minf(jump_charge + delta / k.jump_charge_time, 1.0)
		elif _space_was and jump_charge > 0.0 and _grounded:
			_jump(k)
		else:
			jump_charge = 0.0
	_space_was = space
	var low := k.crouch_rod if crouching and not _airborne else 1.0
	_rod_scale = move_toward(_rod_scale, minf(low, lerpf(1.0, k.jump_squat, jump_charge)), k.rod_rate * delta)


## SALTA: la altura sale de lo cargado, y de ahí la velocidad (v = √(2·g·h)). Es un cambio de velocidad propio y hacia
## arriba: el péndulo no lo lee como un golpe.
func _jump(k: PendulumMechSettings) -> void:
	var rise := lerpf(k.jump_least, 1.0, jump_charge) * k.jump_height
	linear_velocity.y = sqrt(2.0 * _gravity() * rise)
	jump_charge = 0.0
	_airborne = true
	_grounded = false


func _rod(k: PendulumCubeSettings) -> float:
	return super(k) * _rod_scale


## Sin piso bajo el apoyo queda en el aire (un borde): cae derecha y aterriza donde haya piso.
func _no_floor() -> void:
	_airborne = true
	_grounded = false


## CAMINAR, CORRER Y AGACHADA: como el cubo péndulo, con el tope y la aceleración de ahora. En el aire casi no cambia su
## velocidad de costado.
func _drive(k: PendulumCubeSettings, delta: float) -> void:
	var m := k as PendulumMechSettings
	var mine := driving and UIState.gameplay_active()
	var crouching := mine and Input.is_physical_key_pressed(KEY_CTRL) and not _airborne
	var walk := m.walk_speed * (m.crouch_speed if crouching else 1.0)
	var wanted := Vector3.ZERO
	if mine:
		var stick := Vector3(HoverCube._axis(KEY_D, KEY_A), 0.0, -HoverCube._axis(KEY_W, KEY_S))
		var sprinting := Input.is_physical_key_pressed(KEY_SHIFT) and stick.z < 0.0 and not crouching
		wanted = Basis(Vector3.UP, _yaw()) * stick.limit_length(1.0) * walk * (m.sprint_multiplier if sprinting else 1.0)
	_walk = wanted
	var flat := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var most := m.walk_accel if wanted.length_squared() > 0.0001 else m.walk_brake
	# LA BANDA DEL SPRINT: por encima de la caminata, la velocidad se gana y se pierde más despacio.
	if flat.length() > walk:
		most *= m.sprint_accel
	if _airborne:
		most = m.air_accel
	apply_central_force(((wanted - flat) / maxf(delta, 0.0001)).limit_length(most) * CUBE_MASS)


func possess_controls() -> PackedStringArray:
	return PackedStringArray([
		"W/S adelante y atrás · A/D de costado",
		"mouse mira: la cabeza al instante, el torso la alcanza",
		"Shift corre (yendo hacia adelante)",
		"Ctrl se agacha",
		"espacio: mantener carga el salto, soltar salta",
		"espacio en el aire: propulsor",
	])


## El salto cargándose y el propulsor, para el cartel de poseer.
func possess_status() -> String:
	var parts := PackedStringArray()
	if jump_charge > 0.0:
		parts.append("salto %s %d %%" % [_bar(jump_charge), roundi(jump_charge * 100.0)])
	parts.append("propulsor %s %d %%" % [_bar(fuel), roundi(fuel * 100.0)])
	return "   ".join(parts)


static func _bar(share: float) -> String:
	var full := roundi(clampf(share, 0.0, 1.0) * 10.0)
	return "█".repeat(full) + "░".repeat(10 - full)


## ── POR DENTRO: TRES PISOS ───────────────────────────────────────────────────────────────────────────────────────

## El piso `index` (0 el de abajo), en el espacio del cubo.
static func floor_y(index: int) -> float:
	return -SIZE * 0.5 + index * FLOOR_HEIGHT


func _seat() -> Vector3:
	return Vector3(0.0, floor_y(1), -SIZE * 0.5 + 1.6)


## Tres pisos como los de la meca de pelea (MechTorso), con la proporción del cubo: las losas, los costados, al frente
## el antepecho, el vidrio con sus parantes y el dintel, atrás la pared con su puerta, y un asiento con su consola. Es
## dibujo: de afuera lo tapa la caja, y el vidrio y las puertas se dibujan también por fuera.
func _build_cabin() -> void:
	var metal := Clay.METAL.darkened(0.08)
	var half := SIZE * 0.5 - 0.08
	var wall_h := FLOOR_HEIGHT - 0.12
	var lintel := wall_h - SILL - GLASS
	for index in FLOORS + 1:
		Clay.box(_look, Vector3(SIZE - 0.1, 0.12, SIZE - 0.1), Vector3(0, floor_y(index), 0), metal.darkened(0.15))
	for index in FLOORS:
		var base := floor_y(index) + 0.06
		var mid := base + wall_h * 0.5
		var glass_mid := base + SILL + GLASS * 0.5
		for side: float in [-1.0, 1.0]:
			Clay.box(_look, Vector3(0.1, wall_h, SIZE - 0.1), Vector3(side * half, mid, 0), metal)
		# El frente.
		Clay.box(_look, Vector3(SIZE - 0.1, SILL, 0.1), Vector3(0, base + SILL * 0.5, -half), metal)
		Clay.box(_look, Vector3(SIZE - 0.1, lintel, 0.1), Vector3(0, base + wall_h - lintel * 0.5, -half), metal)
		for post_x: float in [-half + 0.1, -1.6, 1.6, half - 0.1]:
			Clay.box(_look, Vector3(0.2, GLASS, 0.2), Vector3(post_x, glass_mid, -half), metal.darkened(0.2))
		Clay.box(_look, Vector3(SIZE - 0.4, GLASS, 0.04), Vector3(0, glass_mid, -half - 0.04), Clay.GLASS)
		Clay.box(_look, Vector3(SIZE - 0.4, GLASS, 0.04), Vector3(0, glass_mid, -SIZE * 0.5 - 0.03), Clay.GLASS)
		for post_x: float in [-1.6, 1.6]:
			Clay.box(_look, Vector3(0.2, GLASS, 0.06), Vector3(post_x, glass_mid, -SIZE * 0.5 - 0.05), metal.darkened(0.2))
		# Atrás: la pared a los costados y arriba de la puerta; por fuera, la puerta marcada.
		var beside := (SIZE - 0.1 - DOOR.x) * 0.5
		for side: float in [-1.0, 1.0]:
			Clay.box(_look, Vector3(beside, wall_h, 0.1), Vector3(side * (DOOR.x + beside) * 0.5, mid, half), metal)
		Clay.box(_look, Vector3(DOOR.x, wall_h - DOOR.y, 0.1), Vector3(0, base + DOOR.y + (wall_h - DOOR.y) * 0.5, half), metal)
		Clay.box(_look, Vector3(DOOR.x, DOOR.y, 0.06), Vector3(0, base + DOOR.y * 0.5, SIZE * 0.5 + 0.03), Clay.DARK)
		Clay.box(_look, Vector3(DOOR.x + 0.3, DOOR.y + 0.15, 0.04), Vector3(0, base + DOOR.y * 0.5 + 0.075, SIZE * 0.5 + 0.02),
			metal.darkened(0.3))
		# El asiento y su consola.
		var seat := Vector3(0.0, base, -SIZE * 0.5 + 1.6)
		Clay.box(_look, Vector3(0.6, 0.5, 0.6), seat + Vector3(0, 0.25, 0), Clay.DARK)
		Clay.box(_look, Vector3(0.6, 0.7, 0.12), seat + Vector3(0, 0.85, 0.3), Clay.DARK)
		Clay.box(_look, Vector3(1.4, 0.8, 0.5), seat + Vector3(0, 0.4, -0.95), metal.darkened(0.25))


## ── LOS BRAZOS (dibujo, en guardia) ──────────────────────────────────────────────────────────────────────────────

## Cada brazo: la esfera del hombro, el brazo, la esfera del codo, el antebrazo, el cubo de la muñeca y los dedos
## —cuatro cilindros al frente del cubo, uno al lado del otro, y el pulgar en su cara de costado, la de adentro—. Los
## largos y la postura son los del cuerpo de la meca (MechBody.arm).
func _build_arms() -> void:
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector3(side * SHOULDER.x, SHOULDER.y, SHOULDER.z)
		var fist := shoulder + Vector3(side * GUARD.x, GUARD.y, GUARD.z)
		var arm := MechBody.arm(shoulder, fist, side, Basis())
		var upper: Transform3D = arm["upper"]
		var forearm: Transform3D = arm["forearm"]
		Clay.sphere(_look, ARM_THICKNESS * 0.78, shoulder, MechBody.JOINT_COLOR)
		Clay.box(_look, Vector3(ARM_THICKNESS, ARM_THICKNESS, MechBody.UPPER_ARM), Vector3.ZERO,
			Clay.METAL.darkened(0.1)).transform = upper
		Clay.sphere(_look, ARM_THICKNESS * 0.66, arm["elbow"], MechBody.JOINT_COLOR)
		Clay.box(_look, Vector3(ARM_THICKNESS * 0.88, ARM_THICKNESS * 0.88, MechBody.FOREARM), Vector3.ZERO,
			Clay.METAL.darkened(0.2)).transform = forearm
		# La muñeca: un cubo en la punta del antebrazo, con su orientación.
		var hand := Node3D.new()
		hand.transform = Transform3D(forearm.basis, arm["wrist"] as Vector3)
		_look.add_child(hand)
		Clay.box(hand, Vector3.ONE * HAND, Vector3.ZERO, MechBody.JOINT_COLOR)
		# Los dedos salen de la cara del frente (−Z), uno al lado del otro a lo alto.
		for finger in 4:
			var y := (finger - 1.5) * HAND * 0.25
			Clay.cylinder(hand, FINGER.x, FINGER.y, Vector3(0.0, y, -HAND * 0.5 - FINGER.y * 0.5 - 0.06),
				Clay.METAL.darkened(0.15), Vector3(90, 0, 0))
		# El pulgar, en la cara de costado de adentro, apuntando adelante.
		Clay.cylinder(hand, FINGER.x * 1.1, FINGER.y * 0.8, Vector3(-side * (HAND * 0.5 + FINGER.x * 1.1 + 0.05), HAND * 0.2,
			-HAND * 0.25), Clay.METAL.darkened(0.15), Vector3(90, 0, 0))
