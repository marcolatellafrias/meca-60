class_name CharacterRigidBody3D
extends RigidBody3D

var _last_impact_world_dir: Vector3 = Vector3.ZERO

var can_sprint: bool = true

# Creative/debug flight (see PlayerController + technical/characters.md). No noclip: the capsule still collides.
# Teclas y velocidades viven en CreativeFlight, compartidas con el sandbox y el freecam de debug. Es la física
# FREE_FLIGHT de su clase (ver `creative_mode`, más abajo).

## Las tres escalas globales que convierten los stats del arquetipo en física. Mueven a TODOS los
## personajes a la vez; los arquetipos solo eligen su lugar relativo dentro de eso.
##
## ⚠ ESTAS TRES DEFINEN LA CAMINATA Y ESTÁN APROBADAS. La inercia tipo carreras vive en el SPRINT
## (ver SPRINT_ACCEL), no acá. Hubo un intento de meterla bajando `ACCEL_SCALE` a 3.5, y el efecto
## fue el equivocado: enlenteció el andar normal, que es el 90% del juego.
const SPEED_SCALE := 10.0
## LA FRENADA ACTÚA SÓLO AL SOLTAR (06/11/2026, lo encontró el dios del juego: «aún el Fat Man… se frena ahí nomás»):
## hasta entonces `_apply_braking_force` corría en todo momento, también empujando, y le comía a todos el 37,5 % de la
## aceleración caminando y el 75 % en la banda del sprint. Al sacarla, la escala baja de 10 a 6,25 —el 62,5 % que quedaba—
## y la frenada sube de 0,375 a 0,6 de la aceleración: arrancar a caminar y frenar soltando desde la caminata dan lo
## mismo que antes, y el número de la aceleración ahora dice lo que hace (× su escala = m/s²).
const ACCEL_SCALE := 6.25
const BRAKE_FACTOR := 0.6

## ── LA BANDA DE SPRINT, LINEAL (06/11/2026, el dios del juego: «no me gusta esa forma de funcionar del sprint, me lo
## imagino más lineal») ────────────────────────────────────────────────────────────────────────────────────────────────
## Multiplicador de aceleración ENTRE LA CAMINATA Y EL TOPE del sprint, el mismo en toda la banda: por debajo de la
## velocidad de caminata acelera igual que caminando, y de ahí al tope sube a ritmo parejo, con esta fracción. Así el
## sprint es una banda que hay que GANAR —la velocidad extra tarda en llegar— y llega de verdad al tope.
##
## *Hasta entonces caía de 1 en la caminata a 0,25 en el tope (`SPRINT_TOP_ACCEL`): con el freno de aire de Godot (ver
## `_ready`) nadie pasaba del ~80 % de su tope. 0,5 tarda lo mismo de la caminata al tope que aquella curva sin freno.*
## *Y antes de eso el sprint MULTIPLICABA la aceleración por `sprint_multiplier`: cuanto más rápido podías ir, más rápido
## llegabas, y el tope alto no se sentía.*
##
## Por debajo de la caminata es 1, a propósito: arrancando de cero con sprint apretado la aceleración es la misma que
## caminando, nunca peor. Apretar sprint jamás te frena.
const SPRINT_ACCEL := 0.5

## Resistencia a voltearse (ragdoll por choque). La firmeza escala con el PESO relativo a este peso de referencia: un
## pesado necesita un golpe mucho más fuerte para inclinarse y caerse que un liviano. Ver technical/characters.md
## (topple resistance) y `_firmness`.
const REFERENCE_WEIGHT := 60.0
## Lo que no es un golpe: el cambio de velocidad que no se explica por fuerzas propias y queda abajo de esto (m/s) es
## ruido de contacto, igual para todos.
const HIT_NOISE := 0.3

@export var show_mesh := false

## QUÉ CLASE DE PERSONAJE ES y QUÉ QUIERE HACER: los mismos objetos que su BoneInstantiator (ver CharacterKind,
## CharacterIntent), puestos en `create`.
var kind: CharacterKind
var intent: CharacterIntent
## SI AHORA ACEPTA LO QUE PIDE LA INTENCIÓN para moverse: lo apagan el ragdoll y la silla, y lo vuelven a prender. Es
## estado del momento, no la clase de personaje (era `is_active`, que se confundía con el del BoneInstantiator).
var input_enabled: bool = false
var is_grounded: bool = false
var collider: CollisionShape3D
var mesh_instance: MeshInstance3D
var _ground_ray: RayCast3D

## LA VELOCIDAD DE QUIEN NO SE SIMULA (ver CharacterKind.simulates): la red o el guion lo ponen, así que su cápsula está
## congelada y su `linear_velocity` es 0. La animación lee esto.
var puppet_velocity: Vector3 = Vector3.ZERO

## Grupo de todas las cápsulas de personaje, para la colisión blanda jugador-jugador. Ver characters.md.
const CHARACTER_GROUP := "character_capsule"
var _capsule_radius: float = 0.5
var _player_excepted: Array = []  # jugadores con los que ya NO chocamos rígido (excepción permanente)
var _player_contacts: Array = []  # choques ya resueltos este contacto (para eyectar una vez, no por frame)

var _capsule_stand_height: float = 0.0
var _capsule_stand_y_offset: float = 0.0

var accel_forward: float = 4.0
var accel_back: float = 4.0
var accel_side: float = 4.0

var brake_forward: float = 1.0
var brake_back: float = 1.0
var brake_side: float = 1.0

var max_speed_forward: float = 10.0
var max_speed_back: float = 10.0
var max_speed_side: float = 10.0

var sprint_multiplier: float = 2.0

var impact_stiffness: float = 25.0
var impact_damping: float = 6.0
## ── EL GOLPE ES UNA CANTIDAD EN M/S (03/11/2026) ──────────────────────────────────────────────────────────────────
## Un golpe es lo que le cambió la velocidad (medido, o con nombre: ver `push`). La INCLINACIÓN es el golpe dividido por
## la firmeza (ver `_firmness`) por `LEAN_PER_MS`, y tumba al llegar a `ragdoll_threshold`: un golpe de unos 2,8 m/s de
## firmeza 1 (0,85 / 0,3). La EXPULSIÓN al caerse es el mismo golpe, en m/s, tal cual (ver RagdollUtil.activate_with_impact).
## Sin perillas por personaje: lo que cambia de uno a otro es la firmeza.
const LEAN_PER_MS := 0.3
## EL GOLPE VERTICAL QUE LO TUMBA AL ATERRIZAR, en m/s, con UMBRAL PROPIO, distinto del de los golpes de costado y de su
## arquetipo (`EntityArchetype.landing_tolerance`; lo pidió el dios del juego, 03/11/2026: «que no sea frustrante»). Por
## debajo, el rebote de siempre (`impact_y`) y sigue corriendo. Cae en el acto, como un golpe seco.
var landing_tolerance: float = 9.0
var impact_y_threshold: float = 2.0

var ragdoll_threshold: float = 0.85
## ── EL EBRIO: EL EQUILIBRIO QUE DERIVA Y SE CORRIGE DE GOLPE ──────────────────────────────────────
## Lo pidió el dios del juego (12/10/2026): «el torso hace movimientos suaves y drifting, y cada tanto se corrige
## rápidamente y medio que rebota un poquito», y que sea el controlador PD del equilibrio —`impact_xz`, el que suma los
## golpes y tumba al pasar `ragdoll_threshold`—, porque tiene impacto en el juego. La DERIVA (`balance_drift`, en
## 1/s²) empuja el equilibrio despacio en una dirección que cambia sola; cuando se va más allá de `balance_correct_at`
## (en fracción del umbral de caída) se CORRIGE DE GOLPE —el resorte, `BALANCE_CORRECT_BOOST` veces más duro por
## `BALANCE_CORRECT_TIME`— y con poco amortiguamiento rebota un poquito. La deriva sola no tumba: un golpe con el cuerpo
## ya corrido sí, más fácil. Lo ponen los modificadores (ver WalkModifier, «Ebrio»); 0, nada.
var balance_drift: float = 0.0
var balance_correct_at: float = 0.0
const BALANCE_CORRECT_BOOST := 10.0
const BALANCE_CORRECT_TIME := 0.25
var _drift_clock: float = randf() * 100.0
var _correcting: float = 0.0

## Estabilidad direccional (de EntityArchetype): multiplican el umbral de impacto según de dónde
## venga el golpe. >1 = más difícil de voltear en esa dirección; <1 = más fácil. Se setean por
## arquetipo en create(). Ver technical/characters.md.
var stability_forward: float = 1.0
var stability_backward: float = 1.0
var stability_sideways: float = 1.0

var velocity_indicator: Vector2 = Vector2.ZERO
var impact_xz: Vector2 = Vector2.ZERO
var impact_y: float = 0.0

signal fall_triggered(world_dir: Vector3)
## CADA GOLPE FUERTE que mide `_detect_external_impact`: cuánto le cambió la velocidad sin que él lo pidiera, en m/s
## —caer, chocar contra una pared, que lo lleve puesto un auto, un empujón—. Lo escucha la salud (ver CrewHealth).
## Lo de todos los días, saltar y caer de pie, queda abajo de `IMPACT_SIGNAL_MIN` y no se avisa.
signal impact_taken(speed: float)
const IMPACT_SIGNAL_MIN := 4.0

var _impact_xz_vel: Vector2 = Vector2.ZERO
## ── EL RESORTE EN DOS PARTES (02/11/2026) ─────────────────────────────────────────────────────────────────────────
## `impact_xz` —lo que inclina el cuerpo y lo que tumba— es la suma de DOS resortes iguales: el de los GOLPES
## (`hit_xz`: los empujones medidos o con nombre, de reposo cero) y el de lo CONTINUO (`_lean_xz`: la inercia del marco,
## que le corre el reposo, y la deriva del ebrio). Se separan porque la cámara sigue sólo al de los golpes (ver
## PlayerController._place_camera_at_head): un golpe se tiene que sentir aunque no tumbe, y que la inercia moviera la
## vista todo el viaje marearía (02/11/2026, el dios del juego: «el feedback del choque es muy útil para mostrarle al
## jugador de que un impacto aunque no lo haya hecho caer influye en el gameplay»).
var hit_xz: Vector2 = Vector2.ZERO
var _hit_vel: Vector2 = Vector2.ZERO
var _lean_xz: Vector2 = Vector2.ZERO
## LO QUE TRAE LA RED: un proxy recibe `impact_xz` de su dueño, con la inercia y los golpes adentro (ver
## CharacterNetSync), así que no los calcula de nuevo. Lo prende la red al primer estado.
var impact_synced := false
var _impact_y_vel: float = 0.0
var _prev_velocity: Vector3 = Vector3.ZERO
var _frame_force: Vector3 = Vector3.ZERO
var _last_impact_xz_magnitude: float = 0.0
## EL EMPUJÓN QUE NO LE CAMBIÓ LA VELOCIDAD, en m/s y ejes del mundo (lo horizontal): el de un choque de la nave, que a
## la cápsula la lleva el marco entera (ver `crash`). Los demás golpes —medidos, el choque blando entre jugadores, la R—
## ya están en su velocidad. Al caerse sale con su velocidad MÁS esto (ver RagdollUtil.activate_with_impact).
var _last_push := Vector3.ZERO

var is_snapshot_active: bool = true
var _ext_ragdoll_state: int = 0
var _snapshot_capture_count: int = 0
var _snapshot_flag_at_capture: bool = false
var _snapshot_ragdoll_at_capture: int = 0
var _snapshot_acc_before: float = 0.0
var _snapshot_acc_after: float = 0.0

## Volando libre (ver CharacterKind.Physics.FREE_FLIGHT): el modo creativo del jugador y el ente que vuela.
var creative_mode: bool:
	get:
		return kind != null and kind.physics == CharacterKind.Physics.FREE_FLIGHT

var crouch_speed_factor: float = 1.0
## Lo que lleva agarrado la frena: el peso divide la velocidad, la de caminar y la del sprint. Lo pone
## InteractionController mientras agarra (ver GrabbableInteractable.carry_speed_factor).
var carry_speed_factor: float = 1.0
## UN TOPE DE VELOCIDAD PEDIDO (m/s), por encima de todo lo demás: lo usa el guion de los dummies para que dos que llevan
## algo juntos vayan al mismo paso (ver ExhibitOperator.pace). Sin tope, INF.
var speed_cap: float = INF

var impact_y_signed: float = 0.0

## ── EL MARCO (03/11/2026, ver MotionFrame) ─────────────────────────────────────────────────────────────────────────
## Adentro de algo que se mueve —la cabina de la nave—, EL MARCO ES ESO: un solo campo, `frame`, y null afuera (el
## mundo). Lo pidió el dios del juego: «que el personaje tenga claramente una flag que diga si se está moviendo en un
## espacio global o local a un área»; «no haya dos sistemas separados». Se entra y se sale por el volumen de la cabina,
## decidido por un punto —el centro de la cápsula, que cayéndose va con la pelvis— (ver MotionFrame.around); a un
## compañero de red se lo dice su dueño (ver CharacterNetSync).
##
## LA FÍSICA SIGUE EN EL MUNDO: la cápsula que se simula se suma al marco (`join`, sin sentir nada: no se desliza), y el
## marco le suma en cada paso lo que la nave cambió de velocidad en su punto; entrar o salir no toca la velocidad. Lo
## que cambia con el marco es CONTRA QUÉ SE MIDE: caminar y frenar van contra la velocidad del marco en su punto
## (`floor_velocity`), la animación lee la velocidad contra el marco (`get_motion_velocity`), los pies plantados viajan
## con él (ver BoneInstantiator._ride_floor), la mirada va en sus ejes (ver CharacterIntent), y la red manda en él.
##
## Y ADENTRO DEL MARCO EL CUERPO NO SE MIDE: un golpe no es lo que le cambió la velocidad (eso lo hace también la nave),
## sino lo que entra con nombre:
##   · LA INERCIA: la aceleración del marco en su punto, al revés —acelerar tira para atrás, frenar para adelante, la
##     curva para afuera—, corre el punto de equilibrio del mismo resorte de los golpes (`impact_xz`), que se inclina hacia
##     ahí y rebota (ver `_update_frame_lean`). No tumba. Cuánto, lo elige el dios del juego en el F3 de la nave
##     (`MotionFrame.inertia_felt`).
##   · LOS EMPUJONES CON NOMBRE: el choque blando entre jugadores, el empujón con R y los choques de la nave entran por
##     `push`, como un golpe, y ésos sí pueden tumbarlo si está parado.
## Corre también en un compañero de red y en uno de exhibición, que no se simulan: la nave llega por red o es la de la
## escena, así que cada máquina inclina a cada uno sin mandar nada.
var frame: MotionFrame = null
## SENTADO (lo pone la silla con `set_seated`, ver SeatInteractable): no se cae nunca, el resorte tiene tope, y el cuerpo
## no se mide. Sin marco (un banco de la plaza), sin inercia.
var seated := false


## SENTADO TE LLEVA LA SILLA Y NADA MÁS (03/11/2026): la cápsula que se simula queda CONGELADA —sin gravedad ni
## velocidad— y deja de ser miembro físico de su marco, que sigue siendo su `frame` para la inercia y la mirada. Seguía
## suelta, con gravedad y recibiendo lo del marco; la silla le escribía la posición en cada paso, pero la velocidad se
## juntaba entre corrección y corrección y el ente sentado en la silla del piloto se hundía atravesando el asiento (lo
## vio el dios del juego). Al pararse vuelve al marco con su velocidad: la de la nave en su punto.
func set_seated(on: bool) -> void:
	if on == seated:
		return
	seated = on
	if not kind.simulates():
		return
	if on:
		if is_instance_valid(frame):
			frame.leave(self)
		linear_velocity = Vector3.ZERO
		freeze = true
	else:
		freeze = false
		linear_velocity = floor_velocity
		if is_instance_valid(frame):
			frame.join(self, 0.0)
		_prev_velocity = linear_velocity
## La velocidad del marco en el punto de la cápsula, o cero afuera: contra esto se camina y se frena.
var floor_velocity := Vector3.ZERO
## Cuánto inclina la inercia: el punto de equilibrio, en la unidad de `impact_xz`, por cada g de aceleración del marco; y
## su tope, lejos del umbral de caída (`ragdoll_threshold`).
const FRAME_LEAN_PER_G := 0.6
const FRAME_LEAN_MAX := 0.45
## Qué tan rápido sigue la aceleración del marco (1/s): suaviza lo que tiembla de un paso a otro.
const FRAME_ACCEL_FOLLOW := 12.0
var _frame_lean := Vector2.ZERO
var _frame_accel := Vector3.ZERO



## ── EL PISO LO DICE QUIEN LO MANEJA (05/11/2026, el dios del juego: «un sustituto de piso… que sería el path predefinido
## con el nivel de suelo que ya lo sabemos») ──────────────────────────────────────────────────────────────────────
## Un peatón en su camino nunca deja el nivel del piso, y su camino sabe a qué altura está: con `ground_by_driver`, el
## rayo al piso se apaga y el piso es `driver_ground`, que quien lo maneja escribe al ponerlo (ver
## BoneInstantiator.puppeteer); INF, en el aire. Sin eso, el rayo, como siempre.
var ground_by_driver := false:
	set(on):
		ground_by_driver = on
		if is_instance_valid(_ground_ray):
			_ground_ray.enabled = not on
var driver_ground := Vector3.INF


func get_ground_collision_point() -> Vector3:
	return driver_ground if ground_by_driver else _ground_ray.get_collision_point()

## Velocidad que maneja la animación: la real si se simula, o la que puso quien lo maneja; las dos, contra el marco.
func get_motion_velocity() -> Vector3:
	return (linear_velocity if kind.simulates() else puppet_velocity) - floor_velocity


## PASA A `new` (null: el mundo). La cápsula que se simula se suma al marco nuevo sin sentir nada (no se desliza); la
## velocidad no se toca (ya es del mundo), pero el paso del cambio no se mide como golpe.
func set_frame(new: MotionFrame) -> void:
	if new == frame:
		return
	var old := frame
	if kind.simulates() and not seated:
		if is_instance_valid(old):
			old.leave(self)
		if is_instance_valid(new):
			new.join(self, 0.0)
	# Y LOS CHOQUES DE LA NAVE le llegan por su marco (ver `crash`).
	if is_instance_valid(old) and old.crashed.is_connected(_on_frame_crashed):
		old.crashed.disconnect(_on_frame_crashed)
	if is_instance_valid(new):
		new.crashed.connect(_on_frame_crashed)
	# SU RUMBO SE GUARDA EN LOS EJES DEL MARCO (ver CharacterIntent.look_yaw): al cambiar de marco se lo pasa a los
	# ejes del nuevo, para que siga mirando al mismo lado del mundo. *En la meca (12/11/2026): al entrar volando a una
	# meca girada, la mirada saltaba lo que la meca estaba girada («es como que me teletransporto»).* A un proxy no:
	# su rumbo ya viene de la red en los ejes del marco que le mandan.
	if intent != null and kind.driver != CharacterKind.Driver.NETWORK:
		var heading := CharacterIntent.world_yaw(old if is_instance_valid(old) else null, intent.look_yaw)
		intent.look_yaw = CharacterIntent.yaw_of(new if is_instance_valid(new) else null,
			Basis(Vector3.UP, heading) * Vector3.FORWARD)
	frame = new
	_frame_accel = Vector3.ZERO
	_prev_velocity = linear_velocity


## LO PONE EN `at`, girado `yaw` en el mundo (lo usa la silla al pararlo, diferido).
func move_to(at: Vector3, yaw: float) -> void:
	global_position = at
	global_rotation = Vector3(0.0, yaw, 0.0)


## Cada paso: el marco que le toca por el volumen (ver MotionFrame.around), salvo que vaya fijo en uno (`ride`) o que se
## lo diga la red.
func _follow_frame() -> void:
	if _riding or kind.driver == CharacterKind.Driver.NETWORK:
		return
	set_frame(MotionFrame.around(global_position, frame))


## ── PARADO DE EXHIBICIÓN A BORDO (02/11/2026, ver DisplayCharacter.stand y BoneInstantiator, PLANTADO EN LA NAVE) ──
## Uno que no se simula no lo lleva nada. Parado a bordo, SU CÁPSULA VA FIJA EN SU PUNTO DEL MARCO, derecha con el marco
## y girada lo que diga su intención; no la mueve ni la inercia ni el ángulo de la nave, y los pies van clavados al piso.
## La inercia y los golpes la inclinan desde la base de la columna, como sentado.
## *Hasta el 02/11/2026 iba derecho en el mundo con los pies plantados por el rayo de siempre: atravesaba el piso a la
## altura del pecho y daba pasos en el aire (lo vio el dios del juego).*
var _riding := false
var _ride_point := Vector3.ZERO


## QUE VIAJE FIJO EN SU MARCO desde donde está ahora (`on`), o que lo suelte. Su rumbo pasa a su intención.
func ride(on: bool) -> void:
	_riding = false
	if on:
		set_frame(MotionFrame.around(global_position, frame))
	_riding = on and is_instance_valid(frame)
	if _riding:
		_ride_point = frame.global_transform.affine_inverse() * global_position
		if intent != null:
			intent.look_yaw = CharacterIntent.yaw_of(frame, -global_basis.z)


func _carry_ride() -> void:
	var axes := frame.global_transform.orthonormalized()
	global_transform = Transform3D(axes.basis * Basis(Vector3.UP, intent.look_yaw if intent != null else 0.0),
		axes * _ride_point)


## UN EMPUJÓN CON NOMBRE: `dv`, cuánto le cambia la velocidad, en m/s y ejes del mundo. Va al resorte como un golpe
## medido; afuera lo mide el cuerpo solo, así que esto sólo hace falta adentro del marco o sentado (ver EL MARCO).
## UN GOLPE QUE LLEGA POR LO QUE LLEVA (ver GrabbableInteractable, LOS GOLPES A LO QUE SE LLEVA): como cualquier
## golpe, lo inclina y le resta equilibrio; `dv` en m/s, del mundo.
func strike(dv: Vector3) -> void:
	_take_hit(dv)


func push(dv: Vector3) -> void:
	if frame != null or seated:
		_take_hit(dv)


## UN CHOQUE DE LA NAVE que lo lleva (la señal `crashed` de su marco): `dv` es lo que perdió de velocidad la nave (m/s,
## ejes del mundo; hacia adelante, se van para adelante). Entra como un empujón con nombre por `CRASH_SCALE`: la nave
## pierde mucha más velocidad que la que se le pasa a quien va adentro, que se agarra, se apoya y se frena contra lo que
## tiene a mano. Elegido para que el de referencia (firmeza 1,33) parado sólo se incline mucho con un choque suave
## (6 m/s), se caiga desde unos 11 y el medio (14) ya lo tumbe; cada arquetipo, según su firmeza (ver `_firmness`).
## Sentado no se cae nunca. Un compañero de red no: su choque lo mide su dueño y llega adentro de `impact_xz`.
const CRASH_SCALE := 0.35

func crash(dv: Vector3) -> void:
	if not impact_synced:
		_last_push = Vector3(dv.x, 0.0, dv.z) * CRASH_SCALE
		push(dv * CRASH_SCALE)


func _on_frame_crashed(dv: Vector3) -> void:
	crash(dv)


## ── LA CAÍDA, CON AVISO (02/11/2026) ──────────────────────────────────────────────────────────────────────────────
## Lo que se junta hasta pasar el umbral —la inercia, varios empujoncitos— inclina primero —el resorte ya lo está
## llevando— y la caída llega `FALL_WARNING` después, en la dirección del golpe. UN GOLPE SECO que solo ya pasa el umbral
## tumba en el acto, sin resorte ni aviso (03/11/2026, ver `_take_hit`). Y LA INCLINACIÓN DEL MARCO SUMA: con la nave cabeceada
## o ladeada más de `TILT_EASY`, el umbral baja a `TILT_FALL` (no tumba sola: sólo hace que un golpe tumbe antes). Lo
## pidió el dios del juego por la nave.
const FALL_WARNING := 0.15
const TILT_EASY := deg_to_rad(20.0)
const TILT_FALL := 2.0 / 3.0
var _fall_in := -1.0


func _tilt_factor() -> float:
	if frame == null:
		return 1.0
	return TILT_FALL if frame.global_basis.y.normalized().angle_to(Vector3.UP) > TILT_EASY else 1.0


## La caída que se avisó: cuando se cumple, cae (si su clase se cae sola), y el resorte vuelve a cero.
func _count_fall(delta: float) -> void:
	if _fall_in < 0.0:
		return
	_fall_in -= delta
	if _fall_in > 0.0:
		return
	_fall_in = -1.0
	if seated or not kind.can_fall:
		return
	fall_triggered.emit(_last_impact_world_dir)
	impact_xz = Vector2.ZERO
	_impact_xz_vel = Vector2.ZERO
	hit_xz = Vector2.ZERO
	_hit_vel = Vector2.ZERO
	_lean_xz = Vector2.ZERO


## LA INERCIA (ver EL MARCO): la aceleración del marco en su punto —la mide el marco, con el giro adentro, así la curva
## tira para afuera—, al revés y en ejes de la cápsula, es el punto de equilibrio del resorte.
func _update_frame_lean(delta: float) -> void:
	if frame == null or delta <= 0.0:
		_frame_accel = Vector3.ZERO
		_frame_lean = Vector2.ZERO
		return
	_frame_accel = _frame_accel.lerp(frame.acceleration_at(global_position), 1.0 - exp(-FRAME_ACCEL_FOLLOW * delta))
	var felt := global_basis.inverse() * -_frame_accel
	var lean_scale := clampf(MotionFrame.inertia_felt, 0.0, 1.0)
	# Por la misma firmeza que los golpes (ver `_firmness`): el más firme se inclina menos.
	_frame_lean = (Vector2(felt.x, felt.z) * FRAME_LEAN_PER_G / 9.8 / _firmness(felt)).limit_length(FRAME_LEAN_MAX) \
		* lean_scale


## LA VELOCIDAD DEL MARCO en su punto, contra la que camina y frena (ver EL MARCO).
func _update_floor() -> void:
	floor_velocity = frame.velocity_at(global_position) if frame != null else Vector3.ZERO


## ── DE SU CAMINO A SIMULARSE, Y DE VUELTA (06/11/2026, el dios del juego: el peatón «golpeado… se vuelve físico al
## desviarse de su path y después intenta retomarlo», como el auto) ─────────────────────────────────────────────────
## `set_simulated(true)`: la cápsula que ponía su camino (FOLLOWS_DRIVER) pasa a simularse como la de cualquiera —con su
## gravedad, sus capas de siempre, sus golpes y su caída—, con `velocity` (la que traía por su camino; lo que se le sume
## después cuenta como golpe, ver `_detect_external_impact`). `set_simulated(false)`: vuelve a ponerla su camino. Lo usa
## el peatón (ver Pedestrian, GOLPEADO).
var _simulated_saved := false
var _simulated_layer := 1
var _simulated_mask := 1


func set_simulated(on: bool, velocity := Vector3.ZERO) -> void:
	if on == kind.simulates():
		return
	if on:
		kind.physics = CharacterKind.Physics.SIMULATED
		kind.can_fall = true
		ground_by_driver = false
		collision_layer = _simulated_layer
		collision_mask = _simulated_mask | SandboxParcel.bound_mask(self)
		gravity_scale = _gravity_scale()
		freeze = false
		input_enabled = true
		linear_velocity = velocity
		_prev_velocity = velocity
		reset_impact_state()
	else:
		kind.physics = CharacterKind.Physics.FOLLOWS_DRIVER
		kind.can_fall = false
		input_enabled = false
		linear_velocity = Vector3.ZERO
		_freeze_for_driver()


## LA CÁPSULA DE QUIEN NO SE SIMULA (ver CharacterKind.simulates): congelada, sin gravedad, la pone quien lo maneja. A un
## compañero de red, KINEMÁTICA y en la capa 1 —se lo choca, lo apunta el rayo de interacción y se lo agarra; la red le
## reescribe el transform en cada cuadro—; a uno de exhibición o una figura, ESTÁTICA y en ninguna capa: se los mira y se
## los atraviesa, y el giro que se les escribe una vez queda escrito (en kinemática el servidor de física le devuelve al
## nodo su propio transform en cada paso: medido, `place_at` con giro 1 rad volvía a 0 a los dos cuadros). Ver
## multiplayer.md (Causa A).
func _freeze_for_driver() -> void:
	if not _simulated_saved:
		_simulated_saved = true
		_simulated_layer = collision_layer
		_simulated_mask = collision_mask
	freeze = true
	gravity_scale = 0.0
	collision_mask = 0
	if kind.is_touchable():
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		collision_layer = 1
	else:
		freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		collision_layer = 0

func _ready() -> void:
	# SIN FRENO DE AIRE (06/11/2026, el dios del juego: «sacaría el freno de aire»): Godot le suma a todo cuerpo el de
	# Configuración del proyecto (0,1 por segundo) salvo que se lo reemplace; frena lo que corre y los dejaba en el ~80 %
	# de su tope. Lo que frena a un personaje es su frenada (ver `_apply_braking_force`).
	linear_damp = 0.0
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	var physics_mat := PhysicsMaterial.new()
	physics_mat.friction = 0.0
	physics_mat.bounce = 0.0
	physics_mat.absorbent = true
	physics_material_override = physics_mat
	can_sleep = false
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	mesh_instance.visible = show_mesh
	contact_monitor = true
	max_contacts_reported = 4
	axis_lock_angular_y = true
	add_to_group(CHARACTER_GROUP)

## Colisión BLANDA jugador-jugador. Los jugadores NO se bloquean rígido entre sí (nos atravesamos):
## el solver no sirve acá — el otro es un puppet KINEMÁTICO (una pared en su posición VIEJA por el
## delay de red), que frena al que corre sin respetar masas. En su lugar resolvemos la colisión a
## mano por momento: cuando me acerco a otro y nos tocamos, me eyecto ALEJÁNDOME ∝ mi velocidad de
## acercamiento · masa_del_otro/(mi+suya) — el liviano sale volando (y se cae si supera su umbral, lo
## mide _detect_external_impact), el pesado apenas se frena y sigue de largo. Una sola vez por choque
## (si no, cada frame de solape lo frenaría). Cada máquina lo hace para SU jugador local → simétrico.
## Ver technical/characters.md.
func _resolve_player_collisions() -> void:
	if collider == null or collider.disabled:
		return  # yo estoy ragdolleando / sin colisión
	_player_excepted = _player_excepted.filter(func(b): return is_instance_valid(b))
	_player_contacts = _player_contacts.filter(func(b): return is_instance_valid(b))
	for node in get_tree().get_nodes_in_group(CHARACTER_GROUP):
		var other := node as CharacterRigidBody3D
		if other == null or other == self:
			continue
		if not _player_excepted.has(other):
			add_collision_exception_with(other)  # nunca bloquear rígido entre jugadores
			_player_excepted.append(other)
		if other.collider == null or other.collider.disabled:
			continue  # el otro ragdollea / sin colisión
		var to_other := other.global_position - global_position
		var normal := Vector3(to_other.x, 0.0, to_other.z)
		var dist := normal.length()
		if dist < 0.001:
			continue
		normal /= dist
		if dist > _capsule_radius + other._capsule_radius:
			_player_contacts.erase(other)  # separados → el choque se puede re-armar
			continue
		if _player_contacts.has(other):
			continue  # ya resolví este choque
		var v_closing := (_prev_velocity - other.get_motion_velocity()).dot(normal)
		if v_closing <= 0.0:
			continue  # no me estoy acercando a este
		_player_contacts.append(other)
		var mass_frac := other.mass / (mass + other.mass)
		linear_velocity += -normal * v_closing * mass_frac
		push(-normal * v_closing * mass_frac)  # adentro del marco no se mide: va con nombre (ver EL MARCO)



func _physics_process(delta: float) -> void:
	_follow_frame()
	_update_floor()
	# QUIEN NO SE SIMULA (un compañero de red, uno de exhibición, una figura): la cápsula la pone quien lo maneja y no se
	# miden golpes, pero SÍ se actualiza el rayo al piso para que la animación sepa si está apoyado (si no, los pies
	# quedan recogidos y no camina). Ver technical/character-animation.md.
	if not kind.simulates():
		if _riding and _ext_ragdoll_state == 0:
			# A BORDO NO HAY PISO QUE LEER (ver PARADO DE EXHIBICIÓN A BORDO): va fijo en su marco, apoyado y quieto
			# contra él. Ni rayo ni velocidad del casco, que en las maquetas se mueve a mano. Cayéndose, la cápsula va
			# con la pelvis del ragdoll (ver RagdollUtil._update_active).
			_carry_ride()
			is_grounded = true
		elif ground_by_driver:
			is_grounded = driver_ground.is_finite()
		elif not _riding:
			_ground_ray.force_raycast_update()
			is_grounded = _ground_ray.is_colliding()
		# QUIETO EN SU MARCO: al de exhibición y a la figura no los mueve nadie más que lo que los lleva, así que su
		# velocidad es la del marco —contra él, cero—. Con cero en el mundo, la animación lo leía corriendo para atrás a la
		# velocidad de la nave y se tiraba para atrás y al costado todo el vuelo (lo vio el dios del juego, 03/11/2026). Al
		# compañero de red se la pone la red, y al peatón su camino (ver Pedestrian): pisársela acá le sacaba los pasos a
		# los que se dibujaban después de este paso (05/11/2026, lo vio el dios del juego en el salón de personas).
		if kind.is_exhibit():
			puppet_velocity = floor_velocity
		# El ebrio se balancea también en el sandbox, y la inercia del marco inclina al de exhibición (ver EL MARCO): sin
		# red, se calculan acá. Un compañero de red los trae de su dueño, adentro de `impact_xz` (ver `impact_synced`).
		if not impact_synced:
			_update_frame_lean(delta)
			if balance_drift > 0.0 or frame != null or impact_xz != Vector2.ZERO:
				_update_impact_pd(delta)
			_count_fall(delta)
		return

	if creative_mode:
		# El vuelo libre lee el teclado directo (ver CreativeFlight): quieto mientras haya un menú abierto.
		if UIState.gameplay_active():
			_apply_creative_fly()
		else:
			linear_velocity = Vector3.ZERO
		# EL ENTE VUELA SIN CHOCAR (NOCLIP): se escribe la posición, para meterse adentro de una pieza y mirarla por
		# dentro, que es para lo que está el sandbox. El jugador del juego sí choca: ahí volar es moverse, y atravesar el
		# piso es caerse de la ciudad.
		if kind.motion == CharacterKind.Motion.DIRECT:
			global_position += linear_velocity * delta
			linear_velocity = Vector3.ZERO
		_ground_ray.force_raycast_update()
		is_grounded = _ground_ray.is_colliding()
		_prev_velocity = linear_velocity
		return

	_frame_force = Vector3.ZERO

	if input_enabled:
		_apply_movement_force()
	_apply_slope_hold()
	# Sólo soltando (ver ACCEL_SCALE): empujando, lo que frena es lo de `_apply_movement_force`.
	var pushing := input_enabled and intent != null and intent.move != Vector2.ZERO
	if kind.motion == CharacterKind.Motion.PHYSICAL and not pushing:
		_apply_braking_force()

	_resolve_player_collisions()  # colisión blanda contra otros jugadores (setea velocidad, antes de medir el impacto)
	_update_velocity_indicator()
	# Adentro del marco el cuerpo no se mide: lo inclina la inercia y lo golpean los empujones con nombre (EL MARCO).
	# Sin cuerpo físico (ver `has_body_physics`), nada de esto.
	if has_body_physics():
		_update_frame_lean(delta)
		if frame == null and not seated:
			_detect_external_impact(delta)
		_update_impact_pd(delta)
		_count_fall(delta)

	_ground_ray.force_raycast_update()
	is_grounded = _ground_ray.is_colliding()
	var mat := mesh_instance.material_override as StandardMaterial3D
	mat.albedo_color = Color(1, 1, 1, 0.2) if is_grounded else Color(1, 0.5, 0, 0.2)

	_prev_velocity = linear_velocity

func _detect_external_impact(delta: float) -> void:
	var gravity := get_gravity()
	var expected_dv := (_frame_force / mass + gravity) * delta
	var actual_dv   := linear_velocity - _prev_velocity
	var impact_dv   := actual_dv - expected_dv
	# La eyección jugador-jugador (_resolve_player_collisions) ya modificó linear_velocity ANTES de este
	# frame, así que entra acá como un impacto normal: al liviano lo tumba, al pesado no le llega al
	# umbral. Mundo/autos entran igual (medidos). No hay nada especial que hacer con jugadores acá.
	_take_hit(impact_dv)


## UN GOLPE de `impact_dv` (m/s, ejes del mundo): medido por el cuerpo (`_detect_external_impact`) o con nombre
## (`push`, ver EL MARCO). Sentado no tumba: el resorte lo inclina y vuelve.
func _take_hit(impact_dv: Vector3) -> void:
	if not has_body_physics():
		return
	if impact_dv.length() > IMPACT_SIGNAL_MIN:
		impact_taken.emit(impact_dv.length())
	var local_impact := global_transform.basis.inverse() * impact_dv

	var xz := Vector2(local_impact.x, local_impact.z)
	# SIN UMBRAL QUE LO HAGA TODO O NADA (02/11/2026, el dios del juego: «la diferencia entre arquetipos se ve en cada
	# golpe, no solo en los grandes»): todo golpe que pase el ruido inclina, dividido por la FIRMEZA —el peso y la
	# estabilidad de ese lado, ver `_firmness`—, y todos caen en el mismo punto (`ragdoll_threshold`). Así INCLINARSE ES
	# ESTAR CERCA DE CAER, igual para todos: un pesado muy inclinado está tan por caerse como un liviano. Antes el peso y
	# la estabilidad eran un umbral: por debajo, nada; por encima, todos se inclinaban igual.
	if xz.length() > HIT_NOISE:
		var impact_dir_world := (global_transform.basis * Vector3(local_impact.x, 0.0, local_impact.z)).normalized()

		if is_snapshot_active:
			_last_impact_world_dir = impact_dir_world
			_last_impact_xz_magnitude = xz.length() * LEAN_PER_MS / _firmness(local_impact)
			_snapshot_flag_at_capture = is_snapshot_active
			_snapshot_ragdoll_at_capture = _ext_ragdoll_state
			_snapshot_acc_before = impact_xz.length()
			_snapshot_capture_count += 1
		# AL RESORTE DE LOS GOLPES (ver EL RESORTE EN DOS PARTES); lo que cuenta para tumbar es la suma.
		hit_xz = (hit_xz + xz * LEAN_PER_MS / _firmness(local_impact)).limit_length(1.0)
		_hit_vel = Vector2.ZERO
		impact_xz = hit_xz + _lean_xz

		var fall_at := ragdoll_threshold * _tilt_factor()
		if impact_xz.length() >= fall_at and seated:
			hit_xz = impact_xz.limit_length(fall_at * 0.95) - _lean_xz
			impact_xz = hit_xz + _lean_xz
		elif xz.length() * LEAN_PER_MS / _firmness(local_impact) >= fall_at:
			# UN GOLPE SECO QUE SOLO YA TUMBA, CAE EN EL ACTO: sin resorte ni aviso (el dios del juego, 03/11/2026: «caída
			# repentina»). El aviso queda para lo que se junta de a poco.
			_snapshot_acc_after = impact_xz.length()
			_fall_in = 0.0
		elif impact_xz.length() >= fall_at and _fall_in < 0.0:
			_snapshot_acc_after = impact_xz.length()
			# CON AVISO (ver LA CAÍDA, CON AVISO): lo que se juntó —la inercia, varios empujoncitos— primero se ve.
			_fall_in = FALL_WARNING

	if LocomotionCommon.base().landing_brake and local_impact.y > impact_y_threshold and not seated:
		_brake_on_landing(local_impact.y)
	if local_impact.y > landing_tolerance and not seated:
		if _last_impact_world_dir == Vector3.ZERO:
			_last_impact_world_dir = -global_basis.z
		_fall_in = 0.0
	if abs(local_impact.y) > impact_y_threshold:
		impact_y_signed = local_impact.y  # agregá esta línea
		# Se hunde del todo a la velocidad de LocomotionCommon (ver Aterrizaje); es de todos.
		impact_y = clampf(impact_y + local_impact.y / LocomotionCommon.LANDING_FULL_SPEED, -1.0, 1.0)
		_impact_y_vel = 0.0

## ── AL ATERRIZAR, FRENA EL CUERPO (04/11/2026, el dios del juego; LocomotionCommon.landing_brake, de todos) ───────
## Prendido, el golpe de aterrizar le saca velocidad horizontal según qué tan fuerte cayó: `hard` (m/s, lo que el piso le
## sacó de golpe para abajo) contra el aterrizaje que lo tumba (`landing_tolerance`), hasta `LANDING_BRAKE_MAX` de lo que
## traía. Se le saca a la velocidad ahí mismo y también a la que el detector recuerda (`_prev_velocity`), así no la lee
## como un golpe: lo que el cuerpo se hace solo no lo inclina. Los pasos re-aceleran solos con el cuerpo. *Hasta el
## 05/11/2026 era una fuerza anotada en `_frame_force`, pero se anotaba en un cuadro y actuaba en el siguiente, que ya
## no la tenía anotada: el detector la leía como un golpe de frente y lo echaba para atrás al aterrizar (medido: 0,47 de
## inclinación; con el freno apagado, 0).*
const LANDING_BRAKE_MAX := 0.7

func _brake_on_landing(hard: float) -> void:
	var share := clampf(hard / maxf(landing_tolerance, 0.01), 0.0, 1.0) * LANDING_BRAKE_MAX
	var relative := linear_velocity - (frame.velocity_at(global_position) if frame != null else Vector3.ZERO)
	relative.y = 0.0
	_self_dv(-relative * share)


## LA FIRMEZA en la dirección de `local` (ejes de la cápsula): el peso respecto del de referencia por la estabilidad de
## ese lado. 1 es el de referencia; 2, hace falta el doble para inclinarlo lo mismo. Divide los golpes y la inercia.
func _firmness(local: Vector3) -> float:
	return maxf(mass / REFERENCE_WEIGHT * _directional_stability(local), 0.05)

## Estabilidad en la dirección del impacto (mezcla lateral / adelante / atrás según el vector local).
## En Godot -z es el frente, así que z<0 = empujado hacia adelante. Multiplica el umbral de caída:
## >1 cuesta más voltearte por ahí, <1 menos.
func _directional_stability(local_impact: Vector3) -> float:
	var ax := absf(local_impact.x)
	var az := absf(local_impact.z)
	var total := ax + az
	if total < 0.001:
		return stability_sideways
	var side_frac := ax / total
	var z_stab := stability_forward if local_impact.z < 0.0 else stability_backward
	return stability_sideways * side_frac + z_stab * (1.0 - side_frac)

func _update_velocity_indicator() -> void:
	var local_vel := global_transform.basis.inverse() * linear_velocity
	var max_vel: float = max(max_speed_forward, max_speed_side) * sprint_multiplier
	velocity_indicator = (Vector2(local_vel.x, local_vel.z) / max(max_vel, 0.001)).limit_length(1.0)

func _update_impact_pd(delta: float) -> void:
	var stiffness := impact_stiffness
	if balance_drift > 0.0:
		# LA DERIVA (ver EL EBRIO): una dirección que gira sola, de dos ritmos que no coinciden.
		_drift_clock += delta
		var wander := Vector2(sin(_drift_clock * 0.7) + 0.6 * sin(_drift_clock * 1.73 + 1.3),
			cos(_drift_clock * 0.53) + 0.5 * sin(_drift_clock * 1.21 + 0.4))
		_impact_xz_vel += wander * balance_drift * delta
		if balance_correct_at > 0.0 and impact_xz.length() > balance_correct_at * ragdoll_threshold:
			_correcting = BALANCE_CORRECT_TIME
	if _correcting > 0.0:
		_correcting -= delta
		stiffness *= BALANCE_CORRECT_BOOST
	# LOS DOS RESORTES (ver EL RESORTE EN DOS PARTES): el continuo va hacia la inercia del marco; el de los golpes, a cero.
	var lean_acc := -(_lean_xz - _frame_lean) * stiffness - _impact_xz_vel * impact_damping
	_impact_xz_vel += lean_acc * delta
	_lean_xz += _impact_xz_vel * delta
	var hit_acc := -hit_xz * stiffness - _hit_vel * impact_damping
	_hit_vel += hit_acc * delta
	hit_xz += _hit_vel * delta
	impact_xz = hit_xz + _lean_xz

	var y_acc := -impact_y * LocomotionCommon.LANDING_SPRING - _impact_y_vel * LocomotionCommon.LANDING_DAMP
	_impact_y_vel += y_acc * delta
	impact_y += _impact_y_vel * delta

## ── MOVIMIENTO DIRECTO (el ente, ver CharacterKind.Motion) ────────────────────────────────────────────────────────
## Para recorrer y probar cómodo: la velocidad que pide es la que tiene, al instante, sin aceleración, frenada ni golpes.
## Camina a `DIRECT_WALK`, corre `DIRECT_SPRINT` veces más y con turbo (dos toques de shift, ver PlayerController) otras
## `DIRECT_TURBO`; salta a `DIRECT_JUMP` con su propia gravedad, `DIRECT_GRAVITY`. Los números del ente del sandbox.
const DIRECT_WALK := 4.5
const DIRECT_SPRINT := 1.8
const DIRECT_TURBO := 4.0
const DIRECT_JUMP := 5.0
const DIRECT_GRAVITY := 18.0


## ── EL MOVIMIENTO DIRECTO NO TIENE CUERPO FÍSICO (07/11/2026, el dios del juego: «que tanto el salto como el sistema de
## golpes y todo eso sea como un simulador físico del personaje que se pueda apagar con una flag»; «sí» a que la flag
## sea la del movimiento directo) ──────────────────────────────────────────────────────────────────────────────────
## Con `Motion.DIRECT` (el ente) no se miden golpes, no hay empujones con nombre ni aterrizajes que lo inclinen, no lo
## inclina la inercia de un marco y no se cae: el cuerpo no se entera de nada. Con `PHYSICAL` (el cuerpo de la B, el
## jugador del juego), todo. *Hasta entonces el ente medía golpes como cualquiera, y como su velocidad cambia al
## instante, arrancar a caminar contaba como un empujón al máximo: el cuerpo invisible se doblaba y la cámara bajaba de
## 79 a 40 cm sobre la cápsula.*
func has_body_physics() -> bool:
	return kind == null or kind.motion != CharacterKind.Motion.DIRECT


func _gravity_scale() -> float:
	if kind != null and kind.motion == CharacterKind.Motion.DIRECT:
		return DIRECT_GRAVITY / maxf(float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)), 0.01)
	return 1.0


## SALTA YA, con movimiento directo: la velocidad de salto, sin carga (ver PlayerController).
func jump_direct() -> void:
	if not is_grounded:
		return
	var up := Vector3.UP
	_self_dv(up * (DIRECT_JUMP - (linear_velocity - floor_velocity).dot(up)))


## ADONDE VA, lo que pide la intención (ver CharacterIntent.move), contra el marco. Con movimiento DIRECTO (ver arriba)
## la velocidad que pide es la que tiene, al instante: sin aceleración ni frenada.
## ── EL CONTROL EN EL AIRE (05/11/2026, el dios del juego: «si el jugador puede controlar su personaje mientras esté en
## el aire… da más skill expression»; a prueba, en la parcela «saltos con curva») ─────────────────────────────────────
## Cuánto de la aceleración y la frenada del piso tiene en el aire: 1, lo mismo que en el piso (lo de siempre: dobla en
## seco y se para en el aire); menos, el impulso del salto manda; 0, nada. De todos, también del jugador.
static var air_control := 1.0
const AIR_CONTROLS := [1.0, 0.3, 0.0]


## Lo que valen ahora las fuerzas de caminar y de frenar: todo en el piso, `air_control` en el aire.
func _control_share() -> float:
	return 1.0 if is_grounded else air_control


func _apply_movement_force() -> void:
	var relative := linear_velocity - floor_velocity
	var horizontal_vel := Vector3(relative.x, 0.0, relative.z)

	var input := intent.move.limit_length(1.0) if intent != null else Vector2.ZERO

	if input == Vector2.ZERO:
		if kind.motion == CharacterKind.Motion.DIRECT:
			linear_velocity -= horizontal_vel
		return

	var right := global_transform.basis.x
	var forward := global_transform.basis.z
	right.y = 0.0
	forward.y = 0.0
	right = right.normalized()
	forward = forward.normalized()

	var forward_component: float = input.y
	var side_component: float = input.x
	var is_sprinting := intent.sprint and forward_component < 0.0 and can_sprint

	var abs_fwd: float = abs(forward_component)
	var abs_side: float = abs(side_component)
	var total_input: float = abs_fwd + abs_side

	var fwd_max: float = max_speed_back if forward_component >= 0.0 else max_speed_forward
	var effective_max: float = (fwd_max * abs_fwd + max_speed_side * abs_side) / max(total_input, 0.001)
	if is_sprinting:
		effective_max *= sprint_multiplier
	effective_max *= crouch_speed_factor * carry_speed_factor
	effective_max = minf(effective_max, speed_cap)

	var fwd_accel: float = accel_back if forward_component >= 0.0 else accel_forward
	# LO QUE LLEVA PESA TAMBIÉN AL ARRANCAR Y AL FRENAR (03/11/2026, lo pidió el dios del juego): la aceleración y la
	# frenada van por lo mismo que la velocidad máxima (ver GrabbableInteractable.carry_speed_factor).
	var current_accel: float = (fwd_accel * abs_fwd + accel_side * abs_side) / max(total_input, 0.001) \
		* carry_speed_factor

	var direction := (right * side_component + forward * forward_component).normalized()
	if kind.motion == CharacterKind.Motion.DIRECT:
		var pace := DIRECT_WALK * crouch_speed_factor
		if intent.sprint and crouch_speed_factor >= 1.0:
			pace *= DIRECT_SPRINT * (DIRECT_TURBO if intent.turbo else 1.0)
		linear_velocity += direction * pace * minf(total_input, 1.0) - horizontal_vel
		return
	var is_changing_direction := horizontal_vel.dot(direction) < 0.0
	var effective_accel := current_accel
	if is_sprinting and not is_changing_direction:
		# `effective_max` ya trae el sprint y el crouch; dividir por el multiplicador devuelve el tope de
		# caminata con las mismas correcciones aplicadas.
		var walk_max: float = effective_max / maxf(sprint_multiplier, 0.001)
		if horizontal_vel.length() > walk_max:
			effective_accel = current_accel * SPRINT_ACCEL
	# APRETAR PARA ATRÁS EN LA BANDA DEL SPRINT pierde la velocidad al ritmo en que se ganó (ver `_band`).
	elif is_changing_direction:
		effective_accel = current_accel * _band(horizontal_vel.length())

	var share := _control_share()
	if share <= 0.0:
		return
	if horizontal_vel.length() < effective_max or is_changing_direction:
		var force := direction * effective_accel * share
		apply_central_force(force)
		_frame_force += force
	# MÁS RÁPIDO QUE SU TOPE DE AHORA —soltó el sprint con la W apretada, se agachó, levantó algo—: lo que sobra se frena
	# como soltando (ver `_apply_braking_force`). Antes lo hacía la frenada prendida siempre.
	elif horizontal_vel.length() > effective_max + 0.05:
		var over_force := -horizontal_vel.normalized() * brake_forward * _band(horizontal_vel.length()) \
			* carry_speed_factor * share
		apply_central_force(over_force)
		_frame_force += over_force

	var opposing_vel: Vector3 = horizontal_vel - direction * max(0.0, horizontal_vel.dot(direction))
	if opposing_vel.length() > 0.0:
		var local_opp: Vector3 = global_transform.basis.inverse() * opposing_vel
		var brake_opp: float = (brake_side * abs(local_opp.x) + brake_forward * abs(local_opp.z)) / max(abs(local_opp.x) + abs(local_opp.z), 0.001)
		var brake_force := -opposing_vel.normalized() * brake_opp * _band(horizontal_vel.length()) \
			* carry_speed_factor * share
		apply_central_force(brake_force)
		_frame_force += brake_force


## ── LA BANDA DEL SPRINT VALE PARA LOS DOS LADOS (06/11/2026, el dios del juego: «que la aceleración funcione en ambos
## lados… qué tanto puedes acelerar, pero qué tanto puedes desacelerar también») ────────────────────────────────────────
## Más rápido que su caminata, todo lo que le cambia la velocidad —empujar, apretar para atrás, soltar— va a
## `SPRINT_ACCEL` de lo de siempre: la velocidad del sprint se pierde al ritmo en que se gana. Hasta la caminata, entero.
func _band(speed: float) -> float:
	return SPRINT_ACCEL if speed > max_speed_forward * crouch_speed_factor * carry_speed_factor else 1.0


## CUÁNTO RECORRE HASTA PARARSE desde la velocidad que lleva (m): soltando todo, o con `against`, apretando para atrás
## (su aceleración más la frenada). Con la banda del sprint (ver `_band`): lo de arriba de la caminata frena a menos.
func stop_distance(against := false) -> float:
	var motion := get_motion_velocity()
	var v := Vector2(motion.x, motion.z).length()
	var brake := minf(brake_forward, minf(brake_back, brake_side))
	if against:
		brake += minf(accel_back, accel_forward)
	var low := maxf(brake * carry_speed_factor / maxf(mass, 0.01), 0.01)
	var walk := max_speed_forward * crouch_speed_factor * carry_speed_factor
	if v <= walk:
		return v * v / (2.0 * low)
	return walk * walk / (2.0 * low) + (v * v - walk * walk) / (2.0 * low * SPRINT_ACCEL)

## EN UNA PENDIENTE CAMINABLE NO SE RESBALA. La cápsula tiene fricción 0 y la fuerza de caminar es
## horizontal: sobre cualquier rampa la gravedad la arrastra y ninguna fuerza razonable la sube más de unos
## grados. Mientras pisa suelo con pendiente de hasta `max_walkable_slope_deg`, se cancela la componente de
## la gravedad A LO LARGO del suelo: la rampa se camina —y se queda parado en ella— como un piso. Más
## empinada que eso, resbala: no es transitable, y de ahí sale la pendiente de las rampas de la ciudad (ver
## RoutePlanner.FLIGHT_SLOPE_DEG). En suelo plano no hace nada. Entra en `_frame_force` como toda fuerza
## propia, para que el detector de impactos no la lea como un golpe.
@export_range(0.0, 60.0, 1.0) var max_walkable_slope_deg := 35.0

func _apply_slope_hold() -> void:
	if not is_grounded or _ground_ray == null or not _ground_ray.is_colliding():
		return
	var n := _ground_ray.get_collision_normal()
	if n.y <= 0.0 or n.y >= 0.9999:
		return
	if rad_to_deg(acos(clampf(n.y, -1.0, 1.0))) > max_walkable_slope_deg:
		return
	var g := get_gravity()
	var along := g - n * g.dot(n)
	if along.length_squared() <= 0.0:
		return
	var force := -along * mass
	apply_central_force(force)
	_frame_force += force


## Salta pidiendo ALTURA, no fuerza: el archetype declara cuántos metros sube el apex
## (`jump_height`) y acá se despeja el impulso contra la gravedad real (v = √(2·g·h), impulso = m·v).
## Así el número del archetype se lee en metros y no depende de la masa ni de la gravedad del proyecto.
## Es un cambio de velocidad PROPIO (ver `_self_dv`): saltar no es un golpe. *Hasta el 05/11/2026 era un impulso, y el
## detector lo leía como un golpe de abajo: al despegar hacía la animación de aterrizar y disparaba el freno de aterrizaje,
## que encima lo inclinaba para atrás.*
func jump_to_height(height: float) -> void:
	if height <= 0.0:
		return
	var g := maxf(get_gravity().length(), 0.01)
	_self_dv(Vector3.UP * sqrt(2.0 * g * height))


## LO QUE EL CUERPO SE HACE SOLO NO ES UN GOLPE (05/11/2026, el dios del juego): un cambio de velocidad que pide él
## —saltar, frenar al aterrizar— va a la velocidad ahí mismo y también a la que el detector recuerda (`_prev_velocity`),
## así `_detect_external_impact` no lo ve, sea cual sea el orden de los procesos.
func _self_dv(dv: Vector3) -> void:
	linear_velocity += dv
	_prev_velocity += dv

## VUELA LIBRE o vuelve a su física simulada (ver CharacterKind.Physics). El ente, sin chocar (ver NOCLIP).
func set_creative_mode(enabled: bool) -> void:
	kind.physics = CharacterKind.Physics.FREE_FLIGHT if enabled else CharacterKind.Physics.SIMULATED
	if kind.motion == CharacterKind.Motion.DIRECT and is_instance_valid(collider):
		collider.disabled = enabled
	if enabled:
		gravity_scale    = 0.0
		linear_velocity  = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		reset_impact_state()
	else:
		gravity_scale      = _gravity_scale()
		linear_velocity    = Vector3.ZERO
		_prev_velocity     = Vector3.ZERO
		is_snapshot_active = true

func _apply_creative_fly() -> void:
	linear_velocity = CreativeFlight.velocity(global_transform.basis) \
		* (DIRECT_TURBO if intent != null and intent.turbo else 1.0)

const CROUCH_CAPSULE := 0.42

func set_crouched(crouched: bool) -> void:
	var shape := collider.shape as CapsuleShape3D
	# Agachado, `CROUCH_CAPSULE` de su alto (ver AnimationModifiers, LA AGACHADA), y nunca menos que sus dos tapas.
	var target_height := maxf(_capsule_stand_height * CROUCH_CAPSULE, (collider.shape as CapsuleShape3D).radius * 2.0 + 0.05) 		if crouched else _capsule_stand_height
	shape.height = target_height
	var height_diff := _capsule_stand_height - target_height
	collider.position.y = _capsule_stand_y_offset - height_diff * 0.5
	mesh_instance.position.y = collider.position.y
	_ground_ray.position.y = collider.position.y - target_height / 2.0 + (collider.shape as CapsuleShape3D).radius

static func create(root_size: Vector3, distance_from_ground: float, leg_height: float, kind_: CharacterKind,
		intent_: CharacterIntent, inst: EntityInstantiation) -> CharacterRigidBody3D:
	var rb := CharacterRigidBody3D.new()
	rb.kind = kind_
	rb.intent = intent_

	var arch := inst.arch_final
	var spec := inst.spec
	rb.mass = arch.weight
	rb.sprint_multiplier = arch.sprint_multiplier

	# Resistencia a voltearse: la FIRMEZA (ver `_firmness`) sale del peso —la masa— y de las estabilidades
	# direccionales del arquetipo, según de dónde venga. Así un chico rápido NO tumba a un gordo (el gordo recibe poco Δv
	# por su masa Y es más firme), pero el gordo sí tumba al chico. Ver technical/characters.md.
	rb.stability_forward   = arch.forward_stability
	rb.stability_backward  = arch.backwards_stability
	rb.stability_sideways  = arch.sideways_stability
	# EL RESORTE DE CADA UNO (02/11/2026): qué tan duro se endereza y cuánto rebota, del arquetipo.
	rb.landing_tolerance = arch.landing_tolerance
	rb.impact_stiffness *= arch.stability_spring
	rb.impact_damping   *= arch.stability_damp

	rb.max_speed_forward = arch.speed * spec.speed_forw_multiplier * SPEED_SCALE
	rb.max_speed_back    = arch.speed * arch.back_speed_factor    * spec.speed_back_multiplier  * SPEED_SCALE
	rb.max_speed_side    = arch.speed * arch.lateral_speed_factor * spec.speed_side_multiplier  * SPEED_SCALE

	rb.accel_forward = arch.weight * arch.acceleration * spec.acceleration_multiplier * ACCEL_SCALE
	rb.accel_back    = arch.weight * arch.acceleration * arch.back_speed_factor    * spec.acceleration_multiplier * ACCEL_SCALE
	rb.accel_side    = arch.weight * arch.acceleration * arch.lateral_speed_factor * spec.acceleration_multiplier * ACCEL_SCALE

	rb.brake_forward = rb.accel_forward * BRAKE_FACTOR
	rb.brake_back    = rb.accel_back    * BRAKE_FACTOR
	rb.brake_side    = rb.accel_side    * BRAKE_FACTOR

	var y_offset := root_size.y / 2.0 - (leg_height - distance_from_ground)

	rb._capsule_stand_height = root_size.y
	rb._capsule_stand_y_offset = y_offset

	var new_mesh_instance := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.height = root_size.y
	capsule_mesh.radius = root_size.x * 0.5
	new_mesh_instance.mesh = capsule_mesh
	new_mesh_instance.position = Vector3(0.0, y_offset, 0.0)
	var material := StandardMaterial3D.new()
	# AMARILLA Y SEMITRANSPARENTE: es la que choca.
	material.albedo_color = Color(1.0, 0.85, 0.1, 0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true
	new_mesh_instance.material_override = material

	var new_collision_shape := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.height = root_size.y
	capsule_shape.radius = root_size.x * 0.5
	new_collision_shape.shape = capsule_shape
	new_collision_shape.position = Vector3(0.0, y_offset, 0.0)

	var radius := root_size.x * 0.5
	var ground_ray := RayCast3D.new()
	# EL PISO Y LA ESCALERITA DE LA NAVE, que tiene su capa (ver PhysicsLayers.STEP).
	ground_ray.collision_mask = 1 | PhysicsLayers.STEP | PhysicsLayers.RAMP | MotionFrame.LAYER
	ground_ray.position = Vector3(0, y_offset - root_size.y / 2.0 + radius, 0)
	ground_ray.target_position = Vector3(0, -(radius + 0.12), 0)
	ground_ray.add_exception(rb)
	
	rb.add_child(new_mesh_instance)
	rb.add_child(new_collision_shape)
	rb.add_child(ground_ray)
	# LA CÁPSULA PISA LA ESCALERITA DE LA NAVE, que nada más ve (ver PhysicsLayers.STEP). Un proxy de red pone su
	# máscara en cero (ver `_freeze_for_driver`).
	rb.collision_mask |= PhysicsLayers.STEP | PhysicsLayers.RAMP
	rb.collider = new_collision_shape
	rb.mesh_instance = new_mesh_instance
	rb._ground_ray = ground_ray
	rb.input_enabled = kind_.simulates()
	rb._capsule_radius = radius
	if not kind_.simulates():
		rb._freeze_for_driver()  # antes de add_child: no simula ni un frame
	rb.gravity_scale = 0.0 if kind_.physics == CharacterKind.Physics.FREE_FLIGHT else rb._gravity_scale()
	if kind_.physics == CharacterKind.Physics.FREE_FLIGHT and kind_.motion == CharacterKind.Motion.DIRECT:
		new_collision_shape.disabled = true
	return rb

## Reubica la cápsula en el XZ dado y baja el Y hasta apoyar los pies en el piso (raycast hacia
## abajo, solo mundo). Se usa al pararse de un ragdoll: el cuerpo quedó tirado con la pelvis a ras
## del piso; descongelar la cápsula ahí la dejaría enterrada y Jolt la eyectaría por el aire.
## exclude = RIDs a ignorar. Devuelve true si encontró piso (si no, solo alinea el XZ).
func snap_feet_to_ground(xz: Vector3, exclude: Array[RID] = []) -> bool:
	var shape := collider.shape as CapsuleShape3D
	var feet_offset := collider.position.y - shape.height / 2.0  # pies respecto al origen del cuerpo
	var from := Vector3(xz.x, xz.y + 2.0, xz.z)
	var to   := Vector3(xz.x, xz.y - 3.0, xz.z)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 | MotionFrame.LAYER  # el mundo y lo del marco (la capa 2 es el ragdoll)
	var ex: Array[RID] = [get_rid()]
	ex.append_array(exclude)
	query.exclude = ex
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = Vector3(xz.x, global_position.y, xz.z)
		return false
	global_position = Vector3(xz.x, (hit["position"] as Vector3).y - feet_offset, xz.z)
	return true

func _apply_braking_force() -> void:
	var relative := linear_velocity - floor_velocity
	var horizontal_vel := Vector3(relative.x, 0.0, relative.z)
	if horizontal_vel.length() > 0.0:
		var local_vel := global_transform.basis.inverse() * horizontal_vel
		var is_moving_back := local_vel.z < 0.0
		var brake_fwd := brake_back if is_moving_back else brake_forward
		var brake_blend : float = (brake_fwd * abs(local_vel.z) + brake_side * abs(local_vel.x)) / max(abs(local_vel.z) + abs(local_vel.x), 0.001)
		var brake_force := -horizontal_vel.normalized() * brake_blend * _band(horizontal_vel.length()) * _control_share()
		apply_central_force(brake_force)
		_frame_force += brake_force
		
func reset_impact_state() -> void:
	impact_xz        = Vector2.ZERO
	_impact_xz_vel   = Vector2.ZERO
	hit_xz           = Vector2.ZERO
	_hit_vel         = Vector2.ZERO
	_lean_xz         = Vector2.ZERO
	impact_y         = 0.0
	_impact_y_vel    = 0.0
	_prev_velocity   = linear_velocity
	is_snapshot_active = false
