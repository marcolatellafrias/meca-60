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
## LOS BRAZOS SON FÍSICOS (12/11/2026; el usuario: «hacer los brazos físicos en la meca péndulo. Así de paso veo cómo
## reaccionan los brazos cuando giro»): dos brazos con músculos (MuscleArm), colgados de sus hombros. Persiguen su
## postura con fuerza tope, así que van atrás cuando la meca gira o se frena, ceden si les pegan, y una piña sacude al
## torso. DOS POSTURAS, con la F: NORMAL (los brazos a los costados, las manos abiertas) y CUBRIÉNDOSE (los puños
## cerrados adelante). Caída, se recogen contra los hombros. LAS PIÑAS, por brazo: clic izquierdo y derecho el directo,
## Q/E el gancho, Z/C el uppercut, 1/3 desde arriba.
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
## LOS BRAZOS: el hombro, en el espacio del cubo (`x` del lado derecho), casi en el medio del costado. *El 12/11/2026
## se probó en el último tercio, hacia atrás: la postura era más natural, pero el brazo alcanzaba 2,6 m menos hacia
## adelante, y el usuario lo volvió («estaban bien los brazos a la mitad, no me gusta el sacrificio en rango»).* Y cuánto
## pesan, en partes de lo que pesa el brazo solo (ver MuscleArm.weight).
const SHOULDER := Vector3(SIZE * 0.5 + 1.0, 1.9, -0.4)
const ARM_WEIGHT := 0.4
## Las teclas de las piñas: para el brazo izquierdo y para el derecho.
const PUNCH_KEYS := {
	KEY_Q: [0, MuscleArm.Punch.HOOK], KEY_E: [1, MuscleArm.Punch.HOOK],
	KEY_Z: [0, MuscleArm.Punch.UPPERCUT], KEY_C: [1, MuscleArm.Punch.UPPERCUT],
	KEY_1: [0, MuscleArm.Punch.HAMMER], KEY_3: [1, MuscleArm.Punch.HAMMER],
}

## Lo cargado del salto y lo que le queda al propulsor (0 a 1), para mirar.
var jump_charge := 0.0
var fuel := 1.0

## El largo del palo de ahora, en partes del entero (agachada, cargando).
var _rod_scale := 1.0
var _space_was := false
## En el aire, el espacio empuja recién cuando se lo vuelve a apretar (el que soltó para saltar no cuenta).
var _thrust_armed := false
## Los dos brazos (el izquierdo y el derecho) y la postura elegida: cubriéndose, o normal.
var arms: Array[MuscleArm] = []
var covering := false
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
	_pose_arms()
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
		"Shift corre (yendo hacia adelante) · Ctrl se agacha",
		"clic izq. / der.: directo · Q / E: gancho · Z / C: uppercut · 1 / 3: desde arriba",
		"F: postura normal / cubriéndose",
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


## ── LOS BRAZOS (físicos: ver MuscleArm) ──────────────────────────────────────────────────────────────────────────

func _build_arms() -> void:
	for side: float in [-1.0, 1.0]:
		var arm := MuscleArm.new()
		arm.side = side
		arm.anchor = self
		arm.shoulder_local = Vector3(side * SHOULDER.x, SHOULDER.y, SHOULDER.z)
		arm.weight = ARM_WEIGHT
		arm.stance = MuscleArm.Stance.NORMAL
		add_child(arm)
		arms.append(arm)


## LA POSTURA DE LOS BRAZOS: la elegida parada; recogidos caída y subiendo (se estiran al enderezarse, con las piernas).
func _pose_arms() -> void:
	var fallen := state == State.LIMP or state == State.LIFT
	for arm in arms:
		arm.stance = MuscleArm.Stance.TUCKED if fallen else (MuscleArm.Stance.COVER if covering else MuscleArm.Stance.NORMAL)


## LAS TECLAS DE LOS BRAZOS, poseída: las piñas de cada uno y la postura.
func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if not driving or state != State.HOVER or not UIState.gameplay_active():
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		arms[0 if click.button_index == MOUSE_BUTTON_LEFT else 1].punch(MuscleArm.Punch.STRAIGHT)
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F:
		covering = not covering
	elif PUNCH_KEYS.has(key.physical_keycode):
		var pick: Array = PUNCH_KEYS[key.physical_keycode]
		arms[int(pick[0])].punch(pick[1] as MuscleArm.Punch)
	else:
		return
	get_viewport().set_input_as_handled()
