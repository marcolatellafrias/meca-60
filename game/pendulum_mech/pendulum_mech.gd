class_name PendulumMech
extends PendulumCube

## LA MECA PÉNDULO: el cubo péndulo (PendulumCube: el torso es un péndulo sobre su apoyo, los pies lo siguen) camino a
## ser la meca. Lo pidió el usuario el 12/11/2026 («vamos a seguir puliendo la del cubo péndulo… que tenga 3 pisos igual
## que los otros… simplemente las puertas… que tenga brazos… saltar… propulsor… se agacha… corre»). En su propia fila; el
## cubo péndulo queda como estaba.
##
## SE ARMA CON PAREDES DE VERDAD, no con una caja pintada (`_build_cabin`): TRES PISOS con la proporción del cubo, cada
## uno con su vidrio y sus parantes al frente —un hueco con un vidrio: se ve para adentro y para afuera—, el HUECO DE LA
## PUERTA atrás (sin escalera todavía) y su asiento. La primera persona es la del asiento del medio.
## ADENTRO SE CAMINA (12/11/2026; el usuario: «falta colisiones entre los pisos»; «sí, con el marco»), como en la meca de
## pelea: es un MARCO (MotionFrame, de character-parametric). Sus losas y paredes tienen forma de choque, pero NO CHOCAN
## CON EL MUNDO: lo de afuera —el piso, las bolas, las paredes— lo sigue recibiendo la caja de siempre, 1:1. Son las
## formas de `_interior`, de las que el marco hace su SOMBRA: el que entra al volumen (el cubo) pasa a ir en el marco,
## que lo lleva con la meca, y adentro choca sólo con esa sombra. Y la caja de afuera deja de chocar con él (`_ride`).
## Todavía no hay escalera: la U del sandbox lo sube (`board`), o el ente entra volando.
## LOS BRAZOS (`_build_arms`), dibujo: el hombro y el codo son ESFERAS, la muñeca una PALMA apenas más gruesa que un
## dedo, y los dedos, con sus FALANGES, cilindros; todas piezas separadas; el pulgar va en el canto de arriba de la palma.
## Parada van en guardia; AL CAER SE RECOGEN A LOS COSTADOS de la caja, y se estiran al enderezarse, con las piernas
## (`_place_arms`). No pegan todavía: los brazos con músculos son el paso que sigue.
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
## LA MANO: el dedo (radio, y el largo de cada falange, de la palma a la punta) y la palma (apenas más gruesa que un
## dedo, del alto de los cuatro dedos, y su largo).
const FINGER_RADIUS := 0.23
const PHALANGES := [0.62, 0.5, 0.4]
const PALM := Vector3(FINGER_RADIUS * 2.0 * 1.3, FINGER_RADIUS * 2.0 * 4.4, 1.5)

## Lo cargado del salto y lo que le queda al propulsor (0 a 1), para mirar.
var jump_charge := 0.0
var fuel := 1.0

## El largo del palo de ahora, en partes del entero (agachada, cargando).
var _rod_scale := 1.0
var _space_was := false
## En el aire, el espacio empuja recién cuando se lo vuelve a apretar (el que soltó para saltar no cuenta).
var _thrust_armed := false
## Las piezas de cada brazo (el izquierdo y el derecho): `shoulder`, `upper`, `elbow`, `forearm`, `hand`.
var _arms: Array[Dictionary] = []
## EL MARCO: lleva a los que van adentro (ver arriba). `_interior`, las formas de sus losas y paredes (no chocan con
## nada: son de donde el marco copia su sombra); `_riders`, los que hoy van adentro y la caja de afuera no ve.
var frame: MotionFrame = null
var _interior: StaticBody3D = null
var _riders := {}


func _ready() -> void:
	super()
	name = "Meca péndulo"
	_build_arms()
	_build_frame()


func tuning() -> HoverCubeSettings:
	return PendulumMechSettings.tuned


func _physics_process(delta: float) -> void:
	super(delta)
	_place_arms()
	_ride()


## ── ADENTRO: EL MARCO ────────────────────────────────────────────────────────────────────────────────────────────

## El marco, con el cubo de volumen, y su sombra: la copia de las formas de `_interior`. El marco copia las de un
## cuerpo de la capa 1; `_interior` lo es sólo mientras se copia, y después no choca con nada.
func _build_frame() -> void:
	frame = MotionFrame.new()
	add_child(frame)
	frame.floor_height = floor_y(0) + SLAB * 0.5
	frame.add_volume(AABB(Vector3.ONE * -SIZE * 0.5, Vector3.ONE * SIZE))
	_interior.collision_layer = 1
	frame.cast_shadow(_interior)
	_interior.collision_layer = 0
	_interior.collision_mask = 0


## LA CAJA DE AFUERA NO CHOCA CON LOS QUE VAN ADENTRO: ellos ya dejaron de mirar al mundo (ver MotionFrame.join), pero
## la caja los seguía viendo, y es maciza. Se mira quién va en el marco en cada paso.
func _ride() -> void:
	var inside := {}
	for body: Variant in frame._members.keys():
		if is_instance_valid(body) and body is PhysicsBody3D:
			inside[body] = true
			if not _riders.has(body):
				add_collision_exception_with(body as PhysicsBody3D)
	for body: Variant in _riders.keys():
		if not inside.has(body) and is_instance_valid(body):
			remove_collision_exception_with(body as PhysicsBody3D)
	_riders = inside


## SUBE AL JUGADOR (la U del sandbox): al piso del medio, detrás del asiento, mirando al frente.
func board() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if driving:
		SandboxPossession.of(get_tree()).release()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	player.place_at(global_transform * (Vector3(0.0, floor_y(1) + SLAB * 0.5 + 0.05, -SIZE * 0.5 + 3.2)), _yaw())


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


## ── POR DENTRO Y POR FUERA: TRES PISOS ───────────────────────────────────────────────────────────────────────────

## El piso `index` (0 el de abajo), en el espacio del cubo.
static func floor_y(index: int) -> float:
	return -SIZE * 0.5 + index * FLOOR_HEIGHT


func _seat() -> Vector3:
	return Vector3(0.0, floor_y(1) + SLAB * 0.5, -SIZE * 0.5 + 1.6)


## No hay caja pintada ni franja: lo de afuera son sus paredes (ver `_build_cabin`).
func _build_shell() -> void:
	pass


const SLAB := 0.2
const WALL := 0.2

## Tres pisos como los de la meca de pelea (MechTorso), con la proporción del cubo: las losas, los costados, al frente
## el antepecho, el HUECO con su vidrio y sus parantes y el dintel, atrás la pared con el HUECO de la puerta, y un
## asiento con su consola. Las paredes son lo que se ve de afuera y de adentro: por los huecos se ve del otro lado.
func _build_cabin() -> void:
	_interior = StaticBody3D.new()
	_interior.name = "Interior"
	_interior.collision_layer = 0
	_interior.collision_mask = 0
	add_child(_interior)
	var metal := Clay.METAL
	var half := SIZE * 0.5 - WALL * 0.5
	for index in FLOORS + 1:
		var y := clampf(floor_y(index), -half, half)
		_solid(Vector3(SIZE, SLAB, SIZE), Vector3(0, y, 0), metal.darkened(0.12))
	for index in FLOORS:
		var base := floor_y(index) + SLAB * 0.5
		var wall_h := FLOOR_HEIGHT - SLAB
		var mid := base + wall_h * 0.5
		var glass_mid := base + SILL + GLASS * 0.5
		var lintel := wall_h - SILL - GLASS
		for side: float in [-1.0, 1.0]:
			_solid(Vector3(WALL, wall_h, SIZE - WALL * 2.0), Vector3(side * half, mid, 0), metal)
		# El frente: el antepecho, el dintel, los parantes y UN vidrio en el hueco.
		_solid(Vector3(SIZE, SILL, WALL), Vector3(0, base + SILL * 0.5, -half), metal)
		_solid(Vector3(SIZE, lintel, WALL), Vector3(0, base + wall_h - lintel * 0.5, -half), metal)
		# El vidrio no se atraviesa.
		Clay.shape_box(_interior, Vector3(SIZE, GLASS, WALL * 0.5), Vector3(0, glass_mid, -half))
		for post_x: float in [-half, -1.6, 1.6, half]:
			Clay.box(_look, Vector3(WALL, GLASS, WALL), Vector3(post_x, glass_mid, -half), metal.darkened(0.2))
		Clay.box(_look, Vector3(SIZE - WALL * 2.0, GLASS, 0.04), Vector3(0, glass_mid, -half), Clay.GLASS)
		# Atrás: la pared a los costados y arriba del hueco de la puerta.
		var beside := (SIZE - DOOR.x) * 0.5
		for side: float in [-1.0, 1.0]:
			_solid(Vector3(beside, wall_h, WALL), Vector3(side * (DOOR.x + beside) * 0.5, mid, half), metal)
		_solid(Vector3(DOOR.x, wall_h - DOOR.y, WALL), Vector3(0, base + DOOR.y + (wall_h - DOOR.y) * 0.5, half), metal)
		# El asiento y su consola.
		var seat := Vector3(0.0, base, -SIZE * 0.5 + 1.6)
		Clay.box(_look, Vector3(0.6, 0.5, 0.6), seat + Vector3(0, 0.25, 0), Clay.DARK)
		Clay.box(_look, Vector3(0.6, 0.7, 0.12), seat + Vector3(0, 0.85, 0.3), Clay.DARK)
		_solid(Vector3(1.4, 0.8, 0.5), seat + Vector3(0, 0.4, -0.95), metal.darkened(0.25))


## Una pieza de la cabina que se ve y que, adentro, se choca (ver EL MARCO).
func _solid(size: Vector3, at: Vector3, color: Color) -> void:
	Clay.box(_look, size, at, color)
	Clay.shape_box(_interior, size, at)


## ── LOS BRAZOS (dibujo) ──────────────────────────────────────────────────────────────────────────────────────────

## Las piezas de cada brazo, sueltas (las ubica `_place_arms`): la esfera del hombro, el brazo, la esfera del codo, el
## antebrazo y la mano.
func _build_arms() -> void:
	for side: float in [-1.0, 1.0]:
		var upper := Clay.box(_look, Vector3(ARM_THICKNESS, ARM_THICKNESS, MechBody.UPPER_ARM), Vector3.ZERO,
			Clay.METAL.darkened(0.1))
		var forearm := Clay.box(_look, Vector3(ARM_THICKNESS * 0.88, ARM_THICKNESS * 0.88, MechBody.FOREARM), Vector3.ZERO,
			Clay.METAL.darkened(0.2))
		_arms.append({
			"shoulder": Clay.sphere(_look, ARM_THICKNESS * 0.78, Vector3.ZERO, MechBody.JOINT_COLOR),
			"upper": upper,
			"elbow": Clay.sphere(_look, ARM_THICKNESS * 0.66, Vector3.ZERO, MechBody.JOINT_COLOR),
			"forearm": forearm,
			"hand": _build_hand(side),
		})
	_place_arms()


## LA MANO, en la punta del antebrazo (su −Z va hacia los dedos): la PALMA, apenas más gruesa que un dedo; los cuatro
## DEDOS al frente, uno arriba del otro, cada uno con sus tres FALANGES —cilindros sueltos, cada una un poco más cerrada
## que la anterior, hacia adentro—; y el PULGAR, de dos falanges, en el canto de arriba de la palma.
func _build_hand(side: float) -> Node3D:
	var hand := Node3D.new()
	_look.add_child(hand)
	var color := Clay.METAL.darkened(0.15)
	Clay.box(hand, PALM, Vector3(0.0, 0.0, -PALM.z * 0.5), MechBody.JOINT_COLOR)
	for finger in 4:
		var knuckle := Vector3(0.0, (finger - 1.5) * FINGER_RADIUS * 2.2, -PALM.z)
		_build_finger(hand, knuckle, Basis(), PHALANGES, color, -side)
	# El pulgar sale del canto de arriba, hacia adelante y un poco hacia arriba.
	var thumb := Vector3(0.0, PALM.y * 0.5, -PALM.z * 0.35)
	_build_finger(hand, thumb, Basis(Vector3.RIGHT, deg_to_rad(40.0)), [PHALANGES[0] * 0.9, PHALANGES[1]], color, -side)
	return hand


## UN DEDO: una falange tras otra desde `from`, hacia el −Z de `basis`, cada una girada `CURL` más que la anterior
## alrededor del eje vertical de la mano, hacia `inward` (el lado de adentro).
func _build_finger(hand: Node3D, from: Vector3, basis: Basis, lengths: Array, color: Color, inward: float) -> void:
	var at := from
	var turn := basis
	for length: float in lengths:
		turn = turn * Basis(Vector3.UP, inward * deg_to_rad(14.0))
		var along := turn * Vector3.FORWARD
		var piece := Clay.cylinder(hand, FINGER_RADIUS, length - 0.06, Vector3.ZERO, color)
		# El cilindro tiene el largo en su Y: se lo acuesta sobre el −Z del dedo.
		piece.transform = Transform3D(turn * Basis(Vector3.RIGHT, -PI * 0.5), at + along * length * 0.5)
		at += along * length


## UBICA LOS BRAZOS, en el espacio del cubo: en guardia parada, y RECOGIDOS A LOS COSTADOS caída (con la misma medida
## que las piernas, `_tuck`: se recogen al caer y se estiran al enderezarse).
func _place_arms() -> void:
	var share := smoothstep(0.0, 1.0, _tuck)
	for index in _arms.size():
		var side := -1.0 if index == 0 else 1.0
		var shoulder := Vector3(side * SHOULDER.x, SHOULDER.y, SHOULDER.z)
		var pose := MechBody.arm(shoulder, shoulder + Vector3(side * GUARD.x, GUARD.y, GUARD.z), side, Basis())
		if share > 0.001:
			pose = _blend_arm(pose, _tucked_arm(shoulder), share)
		var arm := _arms[index]
		var forearm: Transform3D = pose["forearm"]
		(arm["shoulder"] as Node3D).position = shoulder
		(arm["upper"] as Node3D).transform = pose["upper"]
		(arm["elbow"] as Node3D).position = pose["elbow"]
		(arm["forearm"] as Node3D).transform = forearm
		(arm["hand"] as Node3D).transform = Transform3D(forearm.basis, pose["wrist"] as Vector3)


## EL BRAZO RECOGIDO: pegado al costado de la caja, el brazo derecho hacia abajo y el antebrazo de vuelta hacia arriba,
## apenas adelante, con la mano a la altura del hombro.
func _tucked_arm(shoulder: Vector3) -> Dictionary:
	var elbow := shoulder + Vector3(0.0, -MechBody.UPPER_ARM, 0.4)
	var wrist := elbow + Vector3(0.0, 0.97, -0.24).normalized() * MechBody.FOREARM
	return {
		"upper": MechBody.segment(shoulder, elbow, Vector3.FORWARD),
		"forearm": MechBody.segment(elbow, wrist, Vector3.FORWARD),
		"elbow": elbow,
		"wrist": wrist,
	}


static func _blend_arm(from: Dictionary, to: Dictionary, share: float) -> Dictionary:
	return {
		"upper": (from["upper"] as Transform3D).interpolate_with(to["upper"], share),
		"forearm": (from["forearm"] as Transform3D).interpolate_with(to["forearm"], share),
		"elbow": (from["elbow"] as Vector3).lerp(to["elbow"], share),
		"wrist": (from["wrist"] as Vector3).lerp(to["wrist"], share),
	}
