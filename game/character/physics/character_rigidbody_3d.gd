class_name CharacterRigidBody3D
extends RigidBody3D

var _last_impact_world_dir: Vector3 = Vector3.ZERO

# Creative/debug flight (see PlayerController + character-parametric:docs/technical/characters.md). No noclip: the capsule still collides.
# Teclas y velocidades viven en CreativeFlight, compartidas con el sandbox y el freecam de debug. Es la física
# FREE_FLIGHT de su clase (ver `creative_mode`, más abajo).

## LA ESCALA DE LA VELOCIDAD del arquetipo (ver EntityArchetype.speed): × esto, m/s.
const SPEED_SCALE := 10.0
## Resistencia a voltearse (ragdoll por choque). La firmeza escala con el PESO relativo a este peso de referencia: un
## pesado necesita un golpe mucho más fuerte para inclinarse y caerse que un liviano. Ver character-parametric:docs/technical/characters.md
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

## Grupo de todas las cápsulas de personaje (la usan los paneles para rearmar a todos).
const CHARACTER_GROUP := "character_capsule"
var _capsule_radius: float = 0.5

var _capsule_stand_height: float = 0.0
var _capsule_stand_y_offset: float = 0.0

## ── EL MOVIMIENTO: UNA VELOCIDAD MÁXIMA Y CUÁNTO TARDA EN LLEGAR (17/11/2026) ────────────────────────────────────
## Lo pidió el usuario: «un movimiento puramente cinemático del jugador, sin mecánica de estamina, y solamente con el
## sistema de velocidad máxima y cuánto tiempo tarda en llegar a esa velocidad máxima, que si yo la pongo en cero pasa a
## tener un movimiento instantáneo»; «que la velocidad se vaya ganando solamente por el factor de aceleración… como un
## pseudo sistema de estamina sin otra barra». La velocidad que pide la intención va hacia `top_speed` en la dirección
## que aprieta, y la que tiene la alcanza a ritmo parejo —`top_speed / time_to_top` m/s²—, para arrancar, frenar y
## doblar por igual; con `time_to_top` en 0, al instante. Se escribe la velocidad, no se aplica una fuerza.
## `walk_speed` no mueve nada: es donde la animación pasa de caminar a correr (ver SkeletonSizesUtil).
## *Hasta entonces: fuerzas de aceleración y de frenada aparte, adelante, atrás y de costado, una banda de sprint con la
## shift, a la mitad de ritmo, y una barra de estamina que la cortaba.*
var walk_speed: float = 3.0
var top_speed: float = 6.0
var time_to_top: float = 3.0

## ── DE COSTADO MANDA EL CÓDIGO; PARA ARRIBA, LA FÍSICA (17/11/2026) ──────────────────────────────────────────────
## Lo pidió el usuario: «que la cápsula no la muevan los objetos… lo de costado sólo programático»; «decido yo qué tanto
## me tiro para atrás cuando recibo ese impacto en base a mi peso… con easing». La velocidad horizontal contra el marco
## es la SUYA: lo que camina (`_walk_h`, hacia lo que pide a ritmo parejo, ver EL MOVIMIENTO) más EL RETROCESO
## (`shove`: lo que le suman los golpes con nombre, que se frena al ritmo de su andar). Se escribe en cada paso, y lo
## que el motor le haya cambiado de costado se descarta —las paredes igual frenan: el motor no deja atravesarlas—,
## salvo que lo esté tocando un objeto suelto: eso es un golpe, y entra por `hit` con ese impulso. Para arriba y abajo
## manda la física: la gravedad, el salto, el piso y el aterrizaje medido (el resorte vertical).
## *Hasta entonces la cápsula era un cuerpo más: un paquete la corría, y los golpes de costado se medían por lo que le
## cambiaba la velocidad, con una anotación de cada cambio propio para no confundirlos.*
var _walk_h := Vector3.ZERO
var shove := Vector3.ZERO
var _set_h := Vector3.ZERO




## ── EL RESORTE DE LOS GOLPES ES UNA PIEZA COMÚN (18/11/2026, ver HitSpring) ───────────────────────────────────────
## El de costado (los golpes y la inercia) y el vertical (el aterrizaje) son los de HitSpring, que usan también la meca y
## los jefes. Un golpe es lo que le cambia la velocidad (ver `hit`, LOS GOLPES SON IMPULSOS CON NOMBRE); la INCLINACIÓN es
## el golpe dividido por la firmeza (ver `_firmness`) y tumba en su umbral: un golpe de unos 2,8 m/s de firmeza 1. La
## EXPULSIÓN al caerse es el mismo golpe, en m/s, tal cual (ver RagdollUtil.activate_with_impact). Lo que cambia de un
## personaje a otro es la firmeza y, del arquetipo, la dureza y el amortiguado del resorte (ver `create`).
## `impact_xz`, `impact_y` y `hit_xz` son sus salidas con los nombres de siempre (la red las escribe en un compañero).
var spring := HitSpring.new()
var impact_xz: Vector2:
	get:
		return spring.xz
	set(value):
		spring.set_xz(value)
var impact_y: float:
	get:
		return spring.y
	set(value):
		spring.y = value
var hit_xz: Vector2:
	get:
		return spring.hit_xz
var ragdoll_threshold: float:
	get:
		return spring.threshold
## EL ATERRIZAJE FUERTE, en m/s (del arquetipo, `EntityArchetype.landing_tolerance`): con él frena del todo al caer
## (ver `_brake_on_landing`). Aterrizar no tumba.
var landing_tolerance: float = 9.0

## Estabilidad direccional (de EntityArchetype): multiplican el umbral de impacto según de dónde
## venga el golpe. >1 = más difícil de voltear en esa dirección; <1 = más fácil. Se setean por
## arquetipo en create(). Ver character-parametric:docs/technical/characters.md.
var stability_forward: float = 1.0
var stability_backward: float = 1.0
var stability_sideways: float = 1.0

var velocity_indicator: Vector2 = Vector2.ZERO

signal fall_triggered(world_dir: Vector3)

## (EL RESORTE EN DOS PARTES, los golpes y lo continuo, está en HitSpring: la cámara sigue sólo a los golpes, 02/11/2026,
## el usuario: «el feedback del choque es muy útil para mostrarle al jugador de que un impacto aunque no lo haya hecho
## caer influye en el gameplay».)
## LO QUE TRAE LA RED: un proxy recibe `impact_xz` de su dueño, con la inercia y los golpes adentro (ver
## CharacterNetSync), así que no los calcula de nuevo. Lo prende la red al primer estado.
var impact_synced := false
var _prev_velocity: Vector3 = Vector3.ZERO
var _frame_force: Vector3 = Vector3.ZERO
## El último golpe de costado: su dirección (para dónde cae) y cuánto inclinó (lo muestra el panel de impactos).
var _last_impact_xz_magnitude: float = 0.0
## EL EMPUJÓN QUE NO LE CAMBIÓ LA VELOCIDAD, en m/s y ejes del mundo (lo horizontal): el de un choque de la meca, que a
## la cápsula la lleva el marco entera (ver `crash`). Los demás golpes —medidos, el choque blando entre jugadores, la R—
## ya están en su velocidad. Al caerse sale con su velocidad MÁS esto (ver RagdollUtil.activate_with_impact).
var _last_push := Vector3.ZERO


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
## Adentro de algo que se mueve —la cabina de la meca—, EL MARCO ES ESO: un solo campo, `frame`, y null afuera (el
## mundo). Lo pidió el usuario: «que el personaje tenga claramente una flag que diga si se está moviendo en un
## espacio global o local a un área»; «no haya dos sistemas separados». Se entra y se sale por el volumen de la cabina,
## decidido por un punto —el centro de la cápsula, que cayéndose va con la pelvis— (ver MotionFrame.around); a un
## compañero de red se lo dice su dueño (ver CharacterNetSync).
##
## LA FÍSICA SIGUE EN EL MUNDO: la cápsula que se simula se suma al marco (`join`, sin sentir nada: no se desliza), y el
## marco le suma en cada paso lo que la meca cambió de velocidad en su punto; entrar o salir no toca la velocidad. Lo
## que cambia con el marco es CONTRA QUÉ SE MIDE: caminar y frenar van contra la velocidad del marco en su punto
## (`floor_velocity`), la animación lee la velocidad contra el marco (`get_motion_velocity`), los pies plantados viajan
## con él (ver BoneInstantiator._ride_floor), la mirada va en sus ejes (ver CharacterIntent), y la red manda en él.
##
## Y ADENTRO DEL MARCO EL CUERPO NO SE MIDE: un golpe no es lo que le cambió la velocidad (eso lo hace también la meca),
## sino lo que entra con nombre:
##   · LA INERCIA: la aceleración del marco en su punto, al revés —acelerar tira para atrás, frenar para adelante, la
##     curva para afuera—, corre el punto de equilibrio del mismo resorte de los golpes (`impact_xz`), que se inclina hacia
##     ahí y rebota (ver `_update_frame_lean`). No tumba. Cuánto, lo elige el usuario en el F3 de la meca
##     (`MotionFrame.inertia_felt`).
##   · LOS GOLPES CON NOMBRE: la R, lo que pega en lo que lleva y los choques de la meca, como afuera (ver `hit`).
## Corre también en un compañero de red y en uno de exhibición, que no se simulan: la meca llega por red o es la de la
## escena, así que cada máquina inclina a cada uno sin mandar nada.
var frame: MotionFrame = null
## SENTADO (lo pone la silla con `set_seated`, ver SeatInteractable): no se cae nunca, el resorte tiene tope, y el cuerpo
## no se mide. Sin marco (un banco de la plaza), sin inercia.
var seated := false


## SENTADO TE LLEVA LA SILLA Y NADA MÁS (03/11/2026): la cápsula que se simula queda CONGELADA —sin gravedad ni
## velocidad— y deja de ser miembro físico de su marco, que sigue siendo su `frame` para la inercia y la mirada. Seguía
## suelta, con gravedad y recibiendo lo del marco; la silla le escribía la posición en cada paso, pero la velocidad se
## juntaba entre corrección y corrección y el ente sentado en la silla del piloto se hundía atravesando el asiento (lo
## vio el usuario). Al pararse vuelve al marco con su velocidad: la de la meca en su punto.
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



func get_ground_collision_point() -> Vector3:
	return _ground_ray.get_collision_point()

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
	# EL MARCO SABE QUIÉN LO TIENE, sentado o no: al salir del árbol lo suelta él (ver MotionFrame.holds).
	if is_instance_valid(old):
		old.holds.erase(self)
	if is_instance_valid(new):
		new.holds[self] = true
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


## Cada paso: el marco que le toca por el volumen (ver MotionFrame.around), salvo que se lo diga la red.
func _follow_frame() -> void:
	if kind.driver == CharacterKind.Driver.NETWORK:
		return
	set_frame(MotionFrame.around(global_position, frame))


## ── LOS GOLPES SON IMPULSOS CON NOMBRE (17/11/2026) ──────────────────────────────────────────────────────────────
## Lo pidió el usuario: «el empuje es un impulso, no es una diferencia de velocidad. Y el paquete también podríamos
## pensarlo de la misma manera. Y los ataques del boss»; «si empujás a un compañero se entiende intuitivamente las
## variables como fuerza». Todo lo que golpea de costado llama a `hit` con su impulso (N·s, del mundo): la R (ver
## InteractionController._launch), lo que pega en lo que se lleva (GrabbableInteractable.strike_holder), la red y el
## choque de la meca. El impulso sobre la masa le cambia la velocidad —sale empujado— y, sobre la FIRMEZA (el peso y la
## estabilidad de ese lado, ver `_firmness`), lo inclina con el resorte de costado; si un solo golpe pasa el umbral
## (`ragdoll_threshold`), lo tumba y cae para donde lo empujaron (el ragdoll sale con la velocidad de la cápsula). Así el
## fuerte que empuja al chico lo voltea, y al revés no.
## Lo único que se sigue MIDIENDO es lo que no tiene quien lo nombre: el aterrizaje (el resorte de arriba y abajo: más
## alto, más hundido) y el objeto suelto que le pega (ver `_detect_external_impact`). Chocar contra una pared, contra
## otro personaje o su propio movimiento ya no cuentan, y nada lo tumba de a poco ni al aterrizar.
## *Hasta entonces todo cambio de velocidad que no fuera suyo era un golpe, y lo que se juntaba de a poco también tumbaba.*
func hit(impulse: Vector3) -> void:
	var dv := impulse / maxf(mass, 0.01)
	shove += Vector3(dv.x, 0.0, dv.z)
	_self_dv(Vector3(0.0, dv.y, 0.0))
	_take_hit(dv)


## UN CHOQUE DE LA NAVE que lo lleva (la señal `crashed` de su marco): `dv` es lo que perdió de velocidad la meca (m/s,
## ejes del mundo; hacia adelante, se van para adelante). Entra como un empujón con nombre por `CRASH_SCALE`: la meca
## pierde mucha más velocidad que la que se le pasa a quien va adentro, que se agarra, se apoya y se frena contra lo que
## tiene a mano. Elegido para que el de referencia (firmeza 1,33) parado sólo se incline mucho con un choque suave
## (6 m/s), se caiga desde unos 11 y el medio (14) ya lo tumbe; cada arquetipo, según su firmeza (ver `_firmness`).
## Sentado no se cae nunca. Un compañero de red no: su choque lo mide su dueño y llega adentro de `impact_xz`.
const CRASH_SCALE := 0.35

func crash(dv: Vector3) -> void:
	if not impact_synced:
		_last_push = Vector3(dv.x, 0.0, dv.z) * CRASH_SCALE
		_take_hit(dv * CRASH_SCALE)


func _on_frame_crashed(dv: Vector3) -> void:
	crash(dv)


## LA CAÍDA: un golpe que pasó el umbral (ver `_take_hit`) la deja pedida, y en el paso cae —si su clase se cae
## sola—; el resorte vuelve a cero.
var _fall_in := -1.0


func _count_fall(_delta: float) -> void:
	if _fall_in < 0.0:
		return
	_fall_in = -1.0
	if seated or not kind.can_fall:
		return
	fall_triggered.emit(_last_impact_world_dir)
	spring.reset_xz()


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


## LA CÁPSULA DE QUIEN NO SE SIMULA (ver CharacterKind.simulates): congelada, sin gravedad, la pone quien lo maneja. A un
## compañero de red, KINEMÁTICA y en la capa 1 —se lo choca, lo apunta el rayo de interacción y se lo agarra; la red le
## reescribe el transform en cada cuadro—; a uno de exhibición o una figura, ESTÁTICA y en ninguna capa: se los mira y se
## los atraviesa, y el giro que se les escribe una vez queda escrito (en kinemática el servidor de física le devuelve al
## nodo su propio transform en cada paso: medido, `place_at` con giro 1 rad volvía a 0 a los dos cuadros). Ver
## multiplayer.md (Causa A).
func _freeze_for_driver() -> void:
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
	# SIN FRENO DE AIRE (06/11/2026, el usuario: «sacaría el freno de aire»): Godot le suma a todo cuerpo el de
	# Configuración del proyecto (0,1 por segundo) salvo que se lo reemplace; frena lo que corre y los dejaba en el ~80 %
	# de su tope. Lo que frena a un personaje es su movimiento (ver `_move`).
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

func _physics_process(delta: float) -> void:
	_follow_frame()
	_update_floor()
	# QUIEN NO SE SIMULA (un compañero de red, uno de exhibición, una figura): la cápsula la pone quien lo maneja y no se
	# miden golpes, pero SÍ se actualiza el rayo al piso para que la animación sepa si está apoyado (si no, los pies
	# quedan recogidos y no camina). Ver character-parametric:docs/technical/character-animation.md.
	if not kind.simulates():
		_ground_ray.force_raycast_update()
		is_grounded = _ground_ray.is_colliding()
		# QUIETO EN SU MARCO: al de exhibición y a la figura no los mueve nadie más que lo que los lleva, así que su
		# velocidad es la del marco —contra él, cero—. Con cero en el mundo, la animación lo leía corriendo para atrás a la
		# velocidad de la nave y se tiraba para atrás y al costado todo el vuelo (lo vio el usuario, 03/11/2026). Al
		# compañero de red se la pone la red, y al peatón su camino (ver Pedestrian): pisársela acá le sacaba los pasos a
		# los que se dibujaban después de este paso (05/11/2026, lo vio el usuario en el salón de personas).
		# La inercia del marco y los golpes: sin red, se calculan acá. Un compañero de red los trae de su dueño, adentro de `impact_xz` (ver `impact_synced`).
		if not impact_synced:
			_update_frame_lean(delta)
			if frame != null or impact_xz != Vector2.ZERO:
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

	_move(delta)
	_apply_slope_hold()
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
	# SÓLO LO VERTICAL SE MIDE (ver DE COSTADO MANDA EL CÓDIGO): el aterrizaje.
	_take_hit(Vector3(0.0, impact_dv.y, 0.0))


## SI LO ESTÁ TOCANDO UN OBJETO SUELTO (un paquete, una caja: un cuerpo rígido que no es un personaje ni está quieto):
## sólo entonces lo que el motor le cambió de costado es un golpe (ver DE COSTADO MANDA EL CÓDIGO).
func _struck_by_loose() -> bool:
	for body in get_colliding_bodies():
		var loose := body as RigidBody3D
		if loose != null and not loose.freeze and not (loose is CharacterRigidBody3D):
			return true
	return false


## UN GOLPE de `impact_dv` (m/s, ejes del mundo): con nombre (`hit`, `crash`) o medido (`_detect_external_impact`).
## Sentado no tumba: el resorte lo inclina y vuelve.
func _take_hit(impact_dv: Vector3) -> void:
	if not has_body_physics():
		return
	var local_impact := global_transform.basis.inverse() * impact_dv

	var xz := Vector2(local_impact.x, local_impact.z)
	# SIN UMBRAL QUE LO HAGA TODO O NADA (02/11/2026, el usuario: «la diferencia entre arquetipos se ve en cada
	# golpe, no solo en los grandes»): todo golpe que pase el ruido inclina, dividido por la FIRMEZA —el peso y la
	# estabilidad de ese lado, ver `_firmness`—, y todos caen en el mismo punto (`ragdoll_threshold`). Así INCLINARSE ES
	# ESTAR CERCA DE CAER, igual para todos: un pesado muy inclinado está tan por caerse como un liviano. Antes el peso y
	# la estabilidad eran un umbral: por debajo, nada; por encima, todos se inclinaban igual.
	if xz.length() > spring.noise:
		_last_impact_world_dir = (global_transform.basis * Vector3(local_impact.x, 0.0, local_impact.z)).normalized()
		_last_impact_xz_magnitude = xz.length() * spring.lean_per_ms / _firmness(local_impact)
		# AL RESORTE (ver HitSpring): un golpe que solo pasa el umbral lo tumba en el acto; sentado, nunca.
		if spring.hit(xz, _firmness(local_impact), not seated):
			_fall_in = 0.0

	if LocomotionCommon.base().landing_brake and local_impact.y > spring.land_threshold and not seated:
		_brake_on_landing(local_impact.y)
	if absf(local_impact.y) > spring.land_threshold:
		impact_y_signed = local_impact.y
	spring.land(local_impact.y)

## ── AL ATERRIZAR, FRENA EL CUERPO (04/11/2026, el usuario; LocomotionCommon.landing_brake, de todos) ───────
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
	_walk_h *= 1.0 - share
	shove *= 1.0 - share


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
	var max_vel: float = top_speed
	velocity_indicator = (Vector2(local_vel.x, local_vel.z) / max(max_vel, 0.001)).limit_length(1.0)

## EL RESORTE, UN PASO: lo continuo va hacia la inercia del marco (ver HitSpring).
func _update_impact_pd(delta: float) -> void:
	spring.lean_target = _frame_lean
	spring.update(delta)

## ── MOVIMIENTO DIRECTO (el ente, ver CharacterKind.Motion) ────────────────────────────────────────────────────────
## Para recorrer y probar cómodo: la velocidad que pide es la que tiene, al instante, sin aceleración, frenada ni golpes.
## Camina a `DIRECT_WALK`, corre `DIRECT_SPRINT` veces más, con turbo (dos toques de shift, ver PlayerController) otras
## `DIRECT_TURBO` y con el segundo turbo (tres toques) otras `DIRECT_TURBO` encima; salta a `DIRECT_JUMP` con su propia
## gravedad, `DIRECT_GRAVITY`. Los números del ente del sandbox.
const DIRECT_WALK := 4.5
const DIRECT_SPRINT := 1.8
const DIRECT_TURBO := 4.0
const DIRECT_JUMP := 5.0
const DIRECT_GRAVITY := 18.0


## ── EL MOVIMIENTO DIRECTO NO TIENE CUERPO FÍSICO (07/11/2026, el usuario: «que tanto el salto como el sistema de
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
## ── EL CONTROL EN EL AIRE (05/11/2026, el usuario: «si el jugador puede controlar su personaje mientras esté en
## el aire… da más skill expression»; a prueba, en la parcela «saltos con curva») ─────────────────────────────────────
## Cuánto de la aceleración y la frenada del piso tiene en el aire: 1, lo mismo que en el piso (lo de siempre: dobla en
## seco y se para en el aire); menos, el impulso del salto manda; 0, nada. De todos, también del jugador.
static var air_control := 1.0
const AIR_CONTROLS := [1.0, 0.3, 0.0]


## Lo que valen ahora las fuerzas de caminar y de frenar: todo en el piso, `air_control` en el aire.
func _control_share() -> float:
	return 1.0 if is_grounded else air_control


## ADONDE VA (ver EL MOVIMIENTO, arriba): la velocidad contra el marco va hacia la que pide la intención, a ritmo parejo.
## Sin poder moverse (sentado, levantándose), hacia cero. Es un cambio de velocidad PROPIO (ver `_self_dv`): no es un
## golpe. Con movimiento DIRECTO (el ente), al instante y con sus propias velocidades.
func _move(delta: float) -> void:
	var relative := linear_velocity - floor_velocity
	var horizontal := Vector3(relative.x, 0.0, relative.z)
	var input := intent.move.limit_length(1.0) if input_enabled and intent != null else Vector2.ZERO
	var right := global_transform.basis.x
	var forward := global_transform.basis.z
	right.y = 0.0
	forward.y = 0.0
	var direction := right.normalized() * input.x + forward.normalized() * input.y
	if kind.motion == CharacterKind.Motion.DIRECT:
		var pace := DIRECT_WALK * crouch_speed_factor
		if input != Vector2.ZERO and intent.sprint and crouch_speed_factor >= 1.0:
			pace *= DIRECT_SPRINT * turbo_factor()
		linear_velocity += direction * pace - horizontal
		return
	# QUIETA (sentada, tirada): nada que llevar.
	if freeze:
		_walk_h = Vector3.ZERO
		shove = Vector3.ZERO
		_set_h = Vector3.ZERO
		return
	# LO QUE EL MOTOR LE CAMBIÓ DE COSTADO desde el paso anterior: un golpe si lo tocó un objeto suelto; si no, nada.
	var engine_dv := horizontal - _set_h
	if engine_dv.length() > HIT_NOISE and _struck_by_loose():
		hit(engine_dv * mass)
	var target := direction * minf(top_speed * crouch_speed_factor * carry_speed_factor, speed_cap)
	var share := _control_share()
	var step := INF if time_to_top <= 0.0 else top_speed / time_to_top * carry_speed_factor * share * delta
	_walk_h = _walk_h.move_toward(target, step)
	# EL RETROCESO SE FRENA COMO SU ANDAR: al mismo ritmo parejo que acelera (con `time_to_top` en 0, al instante),
	# la misma curva que tenía cuando era un cuerpo más.
	shove = shove.move_toward(Vector3.ZERO, step)
	_set_h = _walk_h + shove
	linear_velocity = Vector3(floor_velocity.x + _set_h.x, linear_velocity.y, floor_velocity.z + _set_h.z)


## CUÁNTO RECORRE HASTA PARARSE desde la velocidad que lleva (m): frena al mismo ritmo al que acelera, suelte o apriete
## para atrás. Con `time_to_top` en 0, nada.
func stop_distance(_against := false) -> float:
	if time_to_top <= 0.0:
		return 0.0
	var motion := get_motion_velocity()
	var v := Vector2(motion.x, motion.z).length()
	return v * v / (2.0 * maxf(top_speed / time_to_top * carry_speed_factor, 0.01))

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


## LO QUE EL CUERPO SE HACE SOLO NO ES UN GOLPE (05/11/2026, el usuario): un cambio de velocidad que pide él
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

func _apply_creative_fly() -> void:
	linear_velocity = CreativeFlight.velocity(global_transform.basis) * turbo_factor()

## Cuánto multiplica el turbo que pide (ver MOVIMIENTO DIRECTO): 1, `DIRECT_TURBO` o `DIRECT_TURBO` al cuadrado.
func turbo_factor() -> float:
	return pow(DIRECT_TURBO, intent.turbo) if intent != null else 1.0

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
	rb.walk_speed = arch.speed * spec.speed_forw_multiplier * SPEED_SCALE
	rb.top_speed = rb.walk_speed * arch.sprint_multiplier
	rb.time_to_top = arch.time_to_top

	# Resistencia a voltearse: la FIRMEZA (ver `_firmness`) sale del peso —la masa— y de las estabilidades
	# direccionales del arquetipo, según de dónde venga. Así un chico rápido NO tumba a un gordo (el gordo recibe poco Δv
	# por su masa Y es más firme), pero el gordo sí tumba al chico. Ver character-parametric:docs/technical/characters.md.
	rb.stability_forward   = arch.forward_stability
	rb.stability_backward  = arch.backwards_stability
	rb.stability_sideways  = arch.sideways_stability
	# EL RESORTE DE CADA UNO (02/11/2026): qué tan duro se endereza y cuánto rebota, del arquetipo.
	rb.landing_tolerance = arch.landing_tolerance
	rb.spring.stiffness *= arch.stability_spring
	rb.spring.damping   *= arch.stability_damp
	rb.spring.noise = HIT_NOISE
	rb.spring.land_full_speed = LocomotionCommon.LANDING_FULL_SPEED
	rb.spring.land_stiffness = LocomotionCommon.LANDING_SPRING
	rb.spring.land_damping = LocomotionCommon.LANDING_DAMP

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

func reset_impact_state() -> void:
	spring.reset()
	_prev_velocity   = linear_velocity
