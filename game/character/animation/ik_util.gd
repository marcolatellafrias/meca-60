class_name IkUtil

## Velocidad horizontal (m/s) por debajo de la cual se considera que el personaje está quieto: la
## fase de marcha se congela y los pies quedan plantados donde están (sólo se replantan si el cuerpo
## los deja fuera de alcance, p.ej. girando en el lugar o empujado).
const GAIT_MIN_SPEED := 0.15
## Piso de la cadencia (ciclos/s) mientras hay un paso EN CURSO. La fase avanza por distancia
## (v/zancada), así que al frenar se quedaría clavada y el pie en el aire nunca aterrizaría. Con este
## piso un paso ya empezado siempre termina — y como se recalcula con la velocidad EN VIVO cada
## frame, acelerar de golpe a mitad de paso lo acelera también (no hay duración congelada).
## Se apaga solo: cuando el pie aterriza no queda nadie en vuelo y la fase se congela (no marcha en
## el lugar). Ver technical/character-animation.md.
const MIN_SWING_RATE := 1.6
## Paso de asentamiento: al frenar, si un pie quedó desplazado más que esta fracción del alcance, da
## un pasito para meterse bajo la cadera. Es el "último pasito" al detenerse.
const SETTLE_EXCURSION_FRACTION := 0.2
const SETTLE_DURATION := 0.22
## Cuánto más abajo que lo que la pierna llega parada se pisa un escalón, en largos de pierna: lo pone la pelvis (ver UN
## ESCALÓN ABAJO SE PISA).
const STEP_DOWN_SHARE := 0.5

## ── LA MARCHA: POR FASE ───────────────────────────────────────────────────────────────────────────
## Decide CUÁNDO despega un pie y cuánto tarda en aterrizar; todo lo demás —los sondeos del piso, el alcance, el arco,
## la IK, la nivelación del pie, el ajuste de pelvis— es de todos los pasos. Un acumulador de fase manda los dos pies, con
## el derecho medio ciclo desfasado. La alternancia es exacta por construcción y la zancada está atada a lo que avanza el
## cuerpo (`rate = v/S`), así que no hay patinaje: no tiene umbrales, ni cooldown, ni "quién pisa ahora".
##
## Hubo otro, el de DISPARO (el de la build de marzo de 2026, mejorado el 12/10: cada paso un evento que sale cuando el
## cuerpo deja atrás al pie), que la tecla G alternaba con éste. El 18/10/2026 el dios del juego se quedó con éste y se
## borraron el otro y la tecla (ver docs/technical/character-animation.md).

## El estilo de caminar de este cuerpo (ver WalkStyle); sin uno, la base.
var style: WalkStyle = null

func _style() -> WalkStyle:
	return style if style != null else WalkStyle.plain()


## Lo que dura un paso de un pie, en segundos —medio ciclo—; parado, infinito. Lo lee la pelvis (ver
## BoneInstantiator, LA PELVIS, EN DOS CAPAS).
func step_time() -> float:
	return 0.5 / _gait_rate if _gait_rate > 0.001 else INF


class LegData:
	var raycast: RayCast3D
	var raycast_indicator: MeshInstance3D
	var next_target: Node3D
	var current_target: Node3D
	var airborne_target: Node3D
	var pole: Node3D
	var neutral_local: Vector3

var left_leg_raycast: RayCast3D
var right_leg_raycast: RayCast3D
var left_leg_raycast_indicator: MeshInstance3D
var right_leg_raycast_indicator: MeshInstance3D
var left_leg_raycast_indicator_b: MeshInstance3D
var right_leg_raycast_indicator_b: MeshInstance3D
var left_leg_raycast_indicator_c: MeshInstance3D
var right_leg_raycast_indicator_c: MeshInstance3D
var left_leg_pole: Node3D
var right_leg_pole: Node3D
const left_color: Color = Color(1, 0, 0)
const right_color: Color = Color(0, 1, 0)
const raycast_color: Color = Color(0, 0, 1)
const inactive_raycast_color: Color = Color(0.3, 0.3, 0.3)
var left_leg_next_target: Node3D
var right_leg_next_target: Node3D
var left_leg_current_target: Node3D
var right_leg_current_target: Node3D
var left_neutral_local: Vector3
var right_neutral_local: Vector3
var left_leg_airborne_target: Node3D
var right_leg_airborne_target: Node3D
var current_step_left_mesh_instance: MeshInstance3D
var current_step_right_mesh_instance: MeshInstance3D

var left_arm_ik_target: Node3D
var right_arm_ik_target: Node3D
var left_arm_pole: Node3D
var right_arm_pole: Node3D

# ── Estado de la marcha ───────────────────────────────────────────────────────────────────────────
# Un único acumulador de fase manda los dos pies (el derecho va medio ciclo desfasado). Con eso la
# alternancia es exacta por construcción: no hay umbrales, cooldowns ni "quién pisa ahora".
# Ver technical/character-animation.md.

## Fase del ciclo de marcha, 0..1. La pierna izquierda usa esta fase; la derecha, +0.5.
var gait_phase: float = 0.0
## Excursión del pie (A, m), zancada (S, m) y duty de este frame; los copia advance_gait() desde
## SkeletonSizesUtil. El pie pisa en +A y despega en −A; S = 2A/D es lo que avanza el cuerpo por ciclo.
var current_excursion: float = 0.25
## Cuánto se corre adelante donde pisa (ver SkeletonSizesUtil.current_lead).
var current_lead: float = 0.0
var current_stride: float = 0.8
var current_duty: float = 0.62
var _gait_moving: bool = false
var _gait_was_grounded := true
var _gait_speed: float = 0.0
## Cadencia efectiva de este frame (ciclos/s) — la que se usó para avanzar la fase, ya con el piso
## de MIN_SWING_RATE aplicado si hay un paso en curso. La lee la predicción de aterrizaje.
var _gait_rate: float = 0.0


var _left_swinging: bool = false
var _right_swinging: bool = false

var _left_swing_from: Vector3 = Vector3.ZERO
var _right_swing_from: Vector3 = Vector3.ZERO
var _left_was_airborne: bool = false
var _right_was_airborne: bool = false

var _stride_rendered: float = -1.0

var recovery_targets_locked: bool = false

## A QUÉ VELOCIDAD SE MUEVE EL PISO, en m/s y en coordenadas del mundo. **En cero —siempre, en el
## juego— nada de esto existe.**
##
## Es una cinta transportadora. Con ella, un personaje que no se traslada pero declara velocidad camina
## de verdad: el pie apoyado viaja hacia atrás bajo la cadera, que es exactamente lo que es un apoyo.
## Sin ella, un maniquí quieto con velocidad declarada planta los dos pies en el mismo punto ADELANTE de
## la cadera y se queda ahí — los pies no vuelven nunca, porque el cuerpo nunca los deja atrás.
##
## Dos consecuencias, y son todo lo que hace falta:
##
## 1. **Todo punto del mundo que el paso RECUERDA viaja con el piso**: el pie plantado y el punto de
##    despegue del vuelo. Lo que se recalcula cada frame contra la cadera (el aterrizaje, el target
##    aéreo) no se toca, porque ya nace en el lugar correcto.
## 2. **El adelanto del aterrizaje se mide con la velocidad REAL de la cadera en el mundo**, que es la
##    declarada MÁS la del piso. Ese término existe para que el pie caiga donde la cadera va a estar; con
##    el piso yendo justo al revés de la marcha la cadera no va a ninguna parte, las dos se cancelan y no
##    queda nada que predecir. La DIRECCIÓN del paso, en cambio, sigue saliendo de la velocidad
##    declarada: es para dónde el personaje quiere caminar.
##
## EL SIGNO ES EL DEL PISO, no el de la marcha, y el nombre está elegido para que no se confunda: un
## personaje que camina hacia −Z necesita el piso yendo a +Z. El indicador visual del sandbox lee ESTE
## vector tal cual (ver CharacterArchetype.Belt), así que un signo al revés se ve.
##
## Lo usan el maniquí del design sandbox, con su cinta (ver CharacterArchetype.Walker), y quien pisa la nave en vuelo
## (ver BoneInstantiator._ride_floor): ahí el piso es el de la nave.
var ground_velocity := Vector3.ZERO
## LO QUE PASÓ DESDE EL ÚLTIMO SOLVE, para llevar los pies con el piso (ver `_slide_with_ground`), cuando quien lo mueve
## lo sabe mejor que `inputs.delta`: un proxy resuelve a media tasa, y con el delta de un cuadro sus pies viajaban la
## mitad que la nave en vuelo, se quedaban atrás y la pierna terminaba en un punto. 0 = `inputs.delta`, como la cinta.
var ground_step := 0.0
## Los gizmos de marcha (poles, targets, anillos de alcance y zancada, sondeos del raycast) se
## dibujan solo si esto está prendido. Arranca APAGADO: son ayudas de autoría, no del juego.
## Manda CharacterDebugView, global para todos los personajes.
##
## Gatea también la ACTUALIZACIÓN de los indicadores del raycast, no solo su visibilidad: mover tres
## mallas por pierna por frame para nada es gasto puro. Quedan viejos mientras están ocultos y se
## corrigen en el primer frame después de prenderlos.
var gizmos_visible: bool = false

## Prende/apaga TODOS los gizmos de marcha de este personaje. Los nodos contenedores son funcionales
## —son los targets de la IK y los poles de verdad, y el solver los lee—, así que no se tocan: se
## apaga solo lo que DIBUJA, las MeshInstance3D que cuelgan de ellos.
func set_gizmos_visible(value: bool) -> void:
	gizmos_visible = value
	_stride_rendered = -1.0  # forzar redibujo del anillo de zancada al volver a prenderlo
	for holder in [left_leg_pole, right_leg_pole, left_leg_next_target, right_leg_next_target,
			left_leg_current_target, right_leg_current_target,
			left_leg_airborne_target, right_leg_airborne_target,
			left_arm_ik_target, right_arm_ik_target, left_arm_pole, right_arm_pole]:
		if not is_instance_valid(holder):
			continue
		for child in (holder as Node3D).get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).visible = value
	for ind in [left_leg_raycast_indicator, right_leg_raycast_indicator,
			left_leg_raycast_indicator_b, right_leg_raycast_indicator_b,
			left_leg_raycast_indicator_c, right_leg_raycast_indicator_c]:
		if is_instance_valid(ind):
			ind.visible = value

func get_leg_data(left: bool) -> LegData:
	var d := LegData.new()
	d.raycast = left_leg_raycast if left else right_leg_raycast
	d.raycast_indicator = left_leg_raycast_indicator if left else right_leg_raycast_indicator
	d.next_target = left_leg_next_target if left else right_leg_next_target
	d.current_target = left_leg_current_target if left else right_leg_current_target
	d.airborne_target = left_leg_airborne_target if left else right_leg_airborne_target
	d.pole = left_leg_pole if left else right_leg_pole
	d.neutral_local = left_neutral_local if left else right_neutral_local
	return d

static func create(sizes: SkeletonSizesUtil, skeleton: BoneInstantiator) -> IkUtil:
	var new_ik_util = IkUtil.new()
	new_ik_util.left_leg_raycast = create_leg_raycast(true, sizes)
	new_ik_util.right_leg_raycast = create_leg_raycast(false, sizes)
	new_ik_util.left_leg_raycast_indicator = create_leg_raycast_indicator(sizes)
	new_ik_util.left_leg_raycast.add_child(new_ik_util.left_leg_raycast_indicator)
	new_ik_util.right_leg_raycast_indicator = create_leg_raycast_indicator(sizes)
	new_ik_util.right_leg_raycast.add_child(new_ik_util.right_leg_raycast_indicator)

	new_ik_util.left_leg_raycast_indicator_b = create_leg_raycast_indicator(sizes)
	new_ik_util.left_leg_raycast.add_child(new_ik_util.left_leg_raycast_indicator_b)
	new_ik_util.right_leg_raycast_indicator_b = create_leg_raycast_indicator(sizes)
	new_ik_util.right_leg_raycast.add_child(new_ik_util.right_leg_raycast_indicator_b)
	new_ik_util.left_leg_raycast_indicator_c = create_leg_raycast_indicator(sizes)
	new_ik_util.left_leg_raycast.add_child(new_ik_util.left_leg_raycast_indicator_c)
	new_ik_util.right_leg_raycast_indicator_c = create_leg_raycast_indicator(sizes)
	new_ik_util.right_leg_raycast.add_child(new_ik_util.right_leg_raycast_indicator_c)

	new_ik_util.left_leg_pole = create_pole(true, sizes, skeleton.local_targets)
	new_ik_util.right_leg_pole = create_pole(false, sizes, skeleton.local_targets)
	new_ik_util.left_leg_next_target  = IkUtil.create_next_target(-sizes.raycast_stance_offset, left_color,  sizes.raycast_leg_length)
	new_ik_util.right_leg_next_target = IkUtil.create_next_target( sizes.raycast_stance_offset, right_color, sizes.raycast_leg_length)
	new_ik_util.left_neutral_local = new_ik_util.left_leg_raycast.transform.origin
	new_ik_util.right_neutral_local = new_ik_util.right_leg_raycast.transform.origin
	new_ik_util.left_leg_current_target = IkUtil.create_ik_target(true, sizes.foot_reach, new_ik_util)
	new_ik_util.right_leg_current_target = IkUtil.create_ik_target(false, sizes.foot_reach, new_ik_util)
	new_ik_util.left_leg_airborne_target = IkUtil.create_simple_ik_target(true)
	new_ik_util.right_leg_airborne_target = IkUtil.create_simple_ik_target(false)
	new_ik_util.left_arm_ik_target  = IkUtil.create_simple_ik_target(true)
	new_ik_util.right_arm_ik_target = IkUtil.create_simple_ik_target(false)
	new_ik_util.left_arm_pole  = IkUtil.create_simple_ik_target(true)
	new_ik_util.right_arm_pole = IkUtil.create_simple_ik_target(false)
	new_ik_util.current_excursion = sizes.current_excursion
	new_ik_util.current_stride    = sizes.current_stride
	new_ik_util.current_duty      = sizes.current_duty
	return new_ik_util

## Cuánto se corre el pole de rodilla hacia AFUERA, en múltiplos del ancho de cadera. En 0 las rodillas
## apuntan al frente y el pie conserva el ángulo con el que fue modelado.
##
## Ojo: en un IK de dos huesos, "hacia dónde apunta la rodilla" y "cuánto gira la tibia" son EL MISMO
## grado de libertad, y el pie cuelga rígido de la tibia. Así que todo lo que abras acá también abre
## los pies — no se pueden pedir por separado sin darle al pie su propia fuente de orientación.
const KNEE_POLE_SIDE := 1.1

static func create_pole(left: bool, sizes: SkeletonSizesUtil, local_targets: Node3D) -> Node3D:
	var color: Color = left_color if left else right_color
	var horizontal_offset: float = sizes.hips_width * KNEE_POLE_SIDE * (-1.0 if left else 1.0)
	var pole := Node3D.new()
	local_targets.add_child(pole)
	pole.position = Vector3(horizontal_offset, 0, -sizes.pole_distance)
	pole.add_child(DebugUtil.create_debug_sphere(color))
	return pole

static func create_leg_raycast(left: bool, sizes: SkeletonSizesUtil) -> RayCast3D:
	var length := sizes.raycast_leg_length
	var x_offset: float = -sizes.raycast_stance_offset if left else sizes.raycast_stance_offset
	var raycast := RayCast3D.new()
	# LOS PIES APOYAN TAMBIÉN EN LA ESCALERITA DE LA NAVE, que tiene su capa (ver PhysicsLayers.STEP), y en lo del marco
	# (su sombra: ver MotionFrame.LAYER).
	raycast.collision_mask = 1 | PhysicsLayers.STEP | PhysicsLayers.FEET | MotionFrame.LAYER
	raycast.target_position = Vector3(0, -length, 0)
	raycast.translate(Vector3(x_offset, -sizes.raycast_start_y_offset, 0))
	return raycast

static func create_leg_raycast_indicator(sizes: SkeletonSizesUtil) -> MeshInstance3D:
	return DebugUtil.create_debug_line(Color.BLUE, sizes.raycast_leg_length)

static func create_next_target(x_offset: float, color: Color, length: float) -> Node3D:
	var target := Node3D.new()
	target.position = Vector3(x_offset, -length, 0)
	target.add_child(DebugUtil.create_debug_sphere(color))
	return target

static func create_simple_ik_target(left: bool) -> Node3D:
	var color := left_color if left else right_color
	var _ik_target := Node3D.new()
	_ik_target.add_child(DebugUtil.create_debug_cube(color))
	return _ik_target

## El anillo grande es el ALCANCE (techo duro de medio paso); el chico, medio paso de este frame.
static func create_ik_target(left: bool, reach: float, ik_util: IkUtil) -> Node3D:
	var color := left_color if left else right_color
	var _ik_target := Node3D.new()
	_ik_target.add_child(DebugUtil.create_debug_cube(color))
	_ik_target.add_child(DebugUtil.create_debug_ring(color, reach))
	var stride_disc: MeshInstance3D = DebugUtil.create_debug_ring(color, reach * 0.5)
	_ik_target.add_child(stride_disc)
	if left:
		ik_util.current_step_left_mesh_instance = stride_disc
	else:
		ik_util.current_step_right_mesh_instance = stride_disc
	return _ik_target

func solve_two_bone_ik(upper_bone: CustomBone, lower_bone: CustomBone, ik_target: Vector3, pole_target: Vector3) -> void:
	var root_pos: Vector3 = upper_bone.global_position
	var target_pos: Vector3 = ik_target
	var upper_len: float = upper_bone.length
	var lower_len: float = lower_bone.length

	var root_to_target: Vector3 = target_pos - root_pos
	var clamped_len: float = clamp(root_to_target.length(), 0.001, upper_len + lower_len)
	var dir_to_target: Vector3 = root_to_target.normalized()

	var raw_pole := (pole_target - root_pos).normalized()
	var right_vec := dir_to_target.cross(raw_pole)
	if right_vec.length() < 1e-6:
		right_vec = get_orthogonal(dir_to_target)
	var bend_plane_normal := right_vec.normalized()
	var pole_on_plane := (bend_plane_normal.cross(dir_to_target)).normalized()

	var cosA: float = clamp((upper_len*upper_len + clamped_len*clamped_len - lower_len*lower_len) / (2.0 * upper_len * clamped_len), -1.0, 1.0)
	var sinA: float = sqrt(max(0.0, 1.0 - cosA * cosA))
	var knee_pos: Vector3 = root_pos + dir_to_target * (cosA * upper_len) + pole_on_plane * (sinA * upper_len)

	# Se escribe la base LOCAL, nunca `global_transform.basis`. Asignar el global en GDScript reescribe
	# el transform entero —origen incluido—, y Godot recalcula la posición local del hueso contra un
	# padre que acaba de rotar en la línea anterior. El hijo deja de estar en la punta del padre, y como
	# al frame siguiente se lee ese valor ya corrido, el error SE ACUMULA: las juntas se van abriendo
	# solas con el tiempo aunque el personaje esté quieto.
	#
	# Escribiendo la base local, `position` queda intacta en la punta del padre y no hay nada que derive.
	var upper_parent := upper_bone.get_parent() as Node3D
	var upper_global := upper_bone.pose_from_rest_to((knee_pos - root_pos).normalized(), pole_on_plane)
	upper_bone.transform.basis = (upper_parent.global_transform.basis.inverse() * upper_global) if upper_parent else upper_global
	var lower_global := upper_bone.pose_from_rest_to((target_pos - knee_pos).normalized(), pole_on_plane)
	lower_bone.transform.basis = upper_bone.global_transform.basis.inverse() * lower_global


# ── Marcha por fase ───────────────────────────────────────────────────────────────────────────────

## Avanza la fase del ciclo. La cadencia sale sola: si el cuerpo avanza `stride` metros por ciclo y
## va a `speed` m/s, el ciclo dura stride/speed → la fase avanza speed/stride por segundo. Así la
## cadencia se adapta a la velocidad y al tamaño de la pierna sin ningún parámetro extra.
func advance_gait(delta: float, sizes: SkeletonSizesUtil, inputs: AnimationInputs) -> void:
	current_excursion = sizes.current_excursion
	current_lead      = sizes.current_lead
	current_stride    = sizes.current_stride
	current_duty      = sizes.current_duty
	_update_stride_ring()

	_gait_speed = Vector2(inputs.velocity.x, inputs.velocity.z).length()
	# DESPEGANDO, NINGÚN PASO NUEVO (ver BoneInstantiator.taking_off): los dos pies dejan el piso juntos.
	var moving := _gait_speed > GAIT_MIN_SPEED and not inputs.taking_off
	# AL ATERRIZAR, LA MARCHA VUELVE A EMPEZAR (05/11/2026, el dios del juego: «cuando aterrizás… deberían volver a
	# posición neutra y empezar a acelerar de vuelta»): el ciclo seguía corriendo en el aire, y al tocar el piso cada pie
	# retomaba la marcha a mitad de un paso, que terminaba en un cuadro —medido con el flaco y la tele: el pie saltaba
	# 69 cm—. Ahora, al tocar el piso, los pasos en curso se cortan —los dos pies quedan donde caen— y la fase se engancha
	# como al arrancar a caminar: el primero en despegar es el de atrás.
	var landing := inputs.grounded and not _gait_was_grounded
	_gait_was_grounded = inputs.grounded
	if landing:
		for left: bool in [true, false]:
			_set_swinging(left, false)
			_clear_step_data(left_leg_current_target if left else right_leg_current_target)
	if (moving and not _gait_moving) or (landing and moving):
		_sync_phase_to_feet(inputs)
	_gait_moving = moving

	# La fase avanza por DISTANCIA (v/S): así la zancada queda atada a lo que avanza el cuerpo y el
	# pie no patina. El único caso que eso no cubre es frenar con un pie en el aire — ahí entra el
	# piso, que sólo aplica mientras hay un paso comprometido.
	_gait_rate = (_gait_speed / current_stride) if current_stride > 0.001 else 0.0
	if _left_swinging or _right_swinging:
		_gait_rate = max(_gait_rate, MIN_SWING_RATE)
	if _gait_rate > 0.0:
		gait_phase = fposmod(gait_phase + _gait_rate * delta, 1.0)

## Fase de una pierna: la derecha va medio ciclo desfasada de la izquierda.
func _leg_phase(left: bool) -> float:
	return gait_phase if left else fposmod(gait_phase + 0.5, 1.0)

## Al arrancar a caminar, engancha la fase para que el primer pie en despegar sea el que quedó más
## ATRÁS respecto del sentido de marcha. Sin esto el primer paso puede salir con el pie adelantado,
## que se lee como un tropiezo.
func _sync_phase_to_feet(inputs: AnimationInputs) -> void:
	var fwd := Vector3(inputs.velocity.x, 0.0, inputs.velocity.z)
	if fwd.length_squared() < 0.0001:
		return
	fwd = fwd.normalized()
	var l := (left_leg_current_target.global_position - inputs.origin).dot(fwd)
	var r := (right_leg_current_target.global_position - inputs.origin).dot(fwd)
	gait_phase = current_duty if l <= r else fposmod(current_duty - 0.5, 1.0)

func _update_stride_ring() -> void:
	if not gizmos_visible:
		return
	if is_equal_approx(current_excursion, _stride_rendered) or not is_instance_valid(current_step_left_mesh_instance):
		return
	_stride_rendered = current_excursion
	current_step_left_mesh_instance.mesh  = DebugUtil.create_debug_ring_mesh(current_excursion)
	current_step_right_mesh_instance.mesh = DebugUtil.create_debug_ring_mesh(current_excursion)

func _is_swinging(left: bool) -> bool:
	return _left_swinging if left else _right_swinging


## Si esa pierna está EN VUELO. Es la misma pregunta que se hace la nivelación del pie. La usa el test headless para
## medir el patinaje del pie apoyado.
func leg_is_swinging(left: bool) -> bool:
	return _is_swinging(left)

## CUÁNTO VUELA EL PIE `left` ahora, de 0 (apoyado) a 1 (en lo más alto de su arco): lo alto que está sobre donde va a
## aterrizar, en alturas de paso. Lo usa la pelvis que sube al despegar (ver WalkStyle).
func swing_lift(left: bool, sizes: SkeletonSizesUtil) -> float:
	var leg := get_leg_data(left)
	var height := sizes.step_height
	if height <= 0.0001:
		return 0.0
	return clampf((leg.current_target.global_position.y - leg.next_target.global_position.y) / height, 0.0, 1.0)

func _set_swinging(left: bool, value: bool) -> void:
	if left:
		_left_swinging = value
	else:
		_right_swinging = value

## Lleva con el piso los dos puntos del mundo que el paso recuerda. Ver `ground_velocity`.
func _slide_with_ground(left: bool, leg: LegData, delta: float) -> void:
	if ground_velocity == Vector3.ZERO:
		return
	var slide := ground_velocity * delta
	leg.current_target.global_position += slide
	_set_swing_from(left, _swing_from(left) + slide)


func _swing_from(left: bool) -> Vector3:
	return _left_swing_from if left else _right_swing_from

func _set_swing_from(left: bool, value: Vector3) -> void:
	if left:
		_left_swing_from = value
	else:
		_right_swing_from = value

func _was_airborne(left: bool) -> bool:
	return _left_was_airborne if left else _right_was_airborne

func _set_was_airborne(left: bool, value: bool) -> void:
	if left:
		_left_was_airborne = value
	else:
		_right_was_airborne = value


## Resuelve una pierna para este frame: decide dónde va el pie (apoyo / vuelo / aire) y dobla la
## pierna con la IK de dos huesos. Ver technical/character-animation.md.
func update_ik_raycast(
	left: bool, bones: CustomBonesUtil, sizes: SkeletonSizesUtil, inputs: AnimationInputs,
) -> void:
	var leg := get_leg_data(left)
	var higher_leg := bones.left_higher_leg if left else bones.right_higher_leg
	var lower_leg := bones.left_lower_leg if left else bones.right_lower_leg

	if not recovery_targets_locked:
		_update_stepping_foot(leg.current_target)
		_slide_with_ground(left, leg, ground_step if ground_step > 0.0 else inputs.delta)

	# El rayo y el umbral de alcance incluyen la altura del TOBILLO. El hueso del pie no se planta en el
	# piso: se planta `ankle_height` más arriba, porque abajo tiene el pie y el zapato. Sin sumarlo acá,
	# el suelo queda "fuera de alcance" justo esa distancia, el pie se va al target aéreo y el personaje
	# flota sin dar pasos.
	var min_raycast_length: float   = sizes.raycast_leg_length + sizes.ankle_height
	var total_raycast_length: float = min_raycast_length * 1.5
	leg.raycast.target_position.y   = -(total_raycast_length - sizes.raycast_start_y_offset)
	var max_raycast_distance: float       = leg.raycast.target_position.length()
	# UN ESCALÓN ABAJO SE PISA (05/11/2026, el dios del juego: bajando la escalera la pierna «hace como un corte y se
	# teletransporta»): lo que la pierna no llega parada lo pone la pelvis, que baja (ver
	# BoneInstantiator._update_pelvis_drop), hasta `STEP_DOWN_SHARE` de pierna. *Hasta entonces el alcance era el de la
	# pierna parada, medido desde la cadera de AHORA: el punto de aterrizaje, adelante, caía en el escalón de abajo, «no
	# alcanzaba», y el pie se iba al rayo de debajo de la cadera; al cuadro siguiente sí alcanzaba y volvía adelante.
	# Medido en el vuelo del pie: en llano iba debajo de la cadera el 2 % del tiempo; en la escalera, el 35 al 43 %.*
	var leg_reach_raycast_distance: float = sizes.leg_height * (1.0 + STEP_DOWN_SHARE) + sizes.ankle_height \
		- sizes.raycast_start_y_offset

	var indicator_a := left_leg_raycast_indicator   if left else right_leg_raycast_indicator
	var indicator_b := left_leg_raycast_indicator_b if left else right_leg_raycast_indicator_b
	var indicator_c := left_leg_raycast_indicator_c if left else right_leg_raycast_indicator_c

	if gizmos_visible:
		var line_len := total_raycast_length - sizes.raycast_start_y_offset
		for ind in [indicator_a, indicator_b, indicator_c]:
			DebugUtil.update_debug_line_mesh(ind, line_len)

	# ── En el aire: el pie se recoge, no hay marcha ────────────────────────────────────────────────
	if not inputs.grounded:
		if not recovery_targets_locked:
			_set_was_airborne(left, true)
			leg.current_target.global_position = leg.airborne_target.global_position
			_clear_step_data(leg.current_target)
		_set_swinging(left, false)
		indicator_b.visible = false
		indicator_c.visible = false
		solve_two_bone_ik(higher_leg, lower_leg, leg.current_target.global_position, leg.pole.global_position)
		_level_foot(left, bones, inputs)
		return

	indicator_b.visible = gizmos_visible
	indicator_c.visible = gizmos_visible

	var basis_owner := leg.raycast.get_parent() as Node3D
	var ph := _leg_phase(left)
	# Un paso YA EMPEZADO sigue hasta aterrizar aunque el personaje haya frenado (por eso el
	# `or _is_swinging`); pero estando quieto ninguna pierna ARRANCA un paso nuevo (por eso el
	# `_gait_moving`). Sin lo primero, frenar a mitad de vuelo teletransportaba el pie al piso.
	var swinging: bool = ph >= current_duty and (_gait_moving or _is_swinging(left))
	var swing_t := 0.0
	if swinging:
		swing_t = (ph - current_duty) / max(1.0 - current_duty, 0.001)

	# ── Dónde sondear el piso ─────────────────────────────────────────────────────────────────────
	# El pie tiene que aterrizar MEDIO PASO POR DELANTE DE LA CADERA en el momento del aterrizaje —
	# no medio paso por delante de donde está la cadera AHORA. Por eso al punto de colocación se le
	# suma lo que va a avanzar el cuerpo durante lo que queda de vuelo (velocidad × tiempo restante).
	# Ese término es el que evita que el pie caiga siempre debajo del cuerpo, y se auto-corrige solo:
	# cuando swing_t→1 el tiempo restante →0 y el sondeo converge al punto exacto de aterrizaje.
	var local_vel: Vector3 = basis_owner.global_transform.basis.inverse() * Vector3(inputs.velocity.x, 0.0, inputs.velocity.z)
	var v2 := Vector2(local_vel.x, local_vel.z)
	# La velocidad REAL de la cadera en el mundo —la declarada más la del piso—, que es la que vale para
	# predecir el aterrizaje. Sin cinta es la declarada y nada más. Ver `ground_velocity`.
	var hip_world_v2 := v2
	if ground_velocity != Vector3.ZERO:
		var local_ground: Vector3 = basis_owner.global_transform.basis.inverse() \
			* Vector3(ground_velocity.x, 0.0, ground_velocity.z)
		hip_world_v2 = v2 + Vector2(local_ground.x, local_ground.z)
	var speed := v2.length()
	var dir := (v2 / speed) if speed > 0.0001 else Vector2.ZERO

	# Parado, el pie va bajo la cadera y punto: sin marcha no hay adelanto. Además de ser lo correcto,
	# es lo que hace que el paso de asentamiento CIERRE — apunta exactamente a neutral, aterriza con
	# desplazamiento 0 y no se vuelve a disparar, sin depender de cuánta velocidad tenga cada
	# arquetipo cuando cruza GAIT_MIN_SPEED.
	# RECIÉN VUELTO DEL AIRE, también bajo la cadera, sin el adelanto del paso ni lo que el cuerpo va a avanzar hasta
	# terminarlo (05/11/2026): si no, el pie se plantaba donde caería el próximo paso corriendo —medido con el flaco y la
	# tele: 1,4 m de un cuadro a otro—; el paso empieza después, desde ahí.
	var place := (dir * (current_excursion + current_lead)) if _gait_moving and not _was_airborne(left) else Vector2.ZERO
	var weight_z := sizes.axis_weight_forward if v2.y <= 0.0 else sizes.axis_weight_backward
	place = Vector2(place.x * sizes.axis_weight_lateral, place.y * weight_z)

	# Tiempo que falta de vuelo: sale de la CADENCIA EFECTIVA, no de v/S. Con v→0 esa división
	# explotaría; con el rate (que tiene piso) queda finito siempre, y el término `v2 * remaining`
	# se va a cero solo al frenar — o sea que el punto de aterrizaje vuelve solo bajo la cadera.
	var lead := place
	if swinging and _gait_rate > 0.0001 and not _was_airborne(left):
		var remaining_time: float = (1.0 - swing_t) * (1.0 - current_duty) / _gait_rate
		lead += hip_world_v2 * remaining_time

	var probe_local := Vector3(leg.neutral_local.x + lead.x, leg.neutral_local.y, leg.neutral_local.z + lead.y)

	var ground_local: Vector3 = basis_owner.global_transform.affine_inverse() * inputs.ground_point
	# ── UN PIE DELANTE DEL OTRO (03/11/2026, lo pidió el dios del juego) ──────────────────────────────────────────
	# El tercero es la LÍNEA DEL MEDIO, con el mismo adelanto del paso: en un camino más angosto que la estancia, a los
	# costados no hay piso que alcance, y los dos pies van a la línea, uno delante del otro. En piso normal el primero
	# acierta y éste no se tira nunca (cuesta lo mismo que antes).
	var candidate_origins: Array[Vector3] = [
		probe_local,
		leg.neutral_local,
		Vector3(ground_local.x, leg.neutral_local.y, ground_local.z + lead.y),
	]

	# ── Resolver el piso ──────────────────────────────────────────────────────────────────────────
	var original_origin := leg.raycast.transform.origin
	var active_candidate_idx := -1
	var resolved := false
	var landing := Vector3.ZERO
	var out_of_reach := false

	# UN PISO QUE LA PIERNA NO ALCANZA NO CORTA LA BÚSQUEDA (ver UN PIE DELANTE DEL OTRO): se prueba el siguiente, y sólo
	# si ninguno alcanza, el pie se recoge hacia el del primero que tocó algo, como siempre.
	for i in candidate_origins.size():
		leg.raycast.transform.origin = candidate_origins[i]
		leg.raycast.force_raycast_update()
		if not leg.raycast.is_colliding():
			continue

		var collision_point    := leg.raycast.get_collision_point()
		var collision_distance := leg.raycast.global_position.distance_to(collision_point)

		if collision_distance >= leg_reach_raycast_distance:
			if out_of_reach:
				continue
			# El piso está más abajo de lo que la pierna llega (borde, pozo): el pie se va recogiendo.
			var t: float = clamp(
				(collision_distance - leg_reach_raycast_distance) / max(max_raycast_distance - leg_reach_raycast_distance, 0.001),
				0.0, 1.0
			)
			landing = Vector3(
				leg.airborne_target.global_position.x,
				lerpf(collision_point.y, leg.airborne_target.global_position.y, t),
				leg.airborne_target.global_position.z
			)
			out_of_reach = true
			active_candidate_idx = i
			resolved = true
			continue
		# El TOBILLO va arriba del piso, no en el piso: la suela apoya, el tobillo queda donde va.
		landing = collision_point + Vector3.UP * sizes.ankle_height
		out_of_reach = false
		active_candidate_idx = i
		resolved = true
		break

	leg.raycast.transform.origin = original_origin

	if not resolved:
		landing = leg.airborne_target.global_position
		out_of_reach = true

	leg.next_target.global_position = landing

	# ── Colocar el pie ────────────────────────────────────────────────────────────────────────────
	if not recovery_targets_locked:
		if out_of_reach:
			_set_was_airborne(left, true)
			leg.current_target.global_position = landing
			_clear_step_data(leg.current_target)
			_set_swinging(left, false)
		elif _was_airborne(left):
			# Acabamos de reencontrar piso: plantar sin interpolar (si no, el pie "vuela" hasta acá).
			_set_was_airborne(left, false)
			leg.current_target.global_position = landing
			_clear_step_data(leg.current_target)
			_set_swinging(left, false)
		elif swinging:
			if not _is_swinging(left):
				_set_swing_from(left, leg.current_target.global_position)  # despegue
				_set_swinging(left, true)
				_clear_step_data(leg.current_target)
			var eased := ease_in_out(swing_t)
			var arc: float = sizes.step_height \
				* clamp(current_excursion / max(sizes.foot_reach, 0.001), 0.15, 1.0)
			var pos := _swing_from(left).lerp(landing, eased)
			pos.y += sin(eased * PI) * arc
			leg.current_target.global_position = pos
		else:
			if _is_swinging(left):
				leg.current_target.global_position = landing  # aterrizaje exacto
				_set_swinging(left, false)
			elif not _gait_moving and not inputs.taking_off:
				_settle_step_if_needed(left, leg, sizes, basis_owner, landing)
			# APOYO: el pie queda plantado en el mundo. No se toca.

	if gizmos_visible:
		# El raycast vuelve siempre a `original_origin`, así que cada indicador tiene que llevarse a
		# mano al candidato que representa — incluido el A. Antes el A no se movía y quedaba pegado
		# al B (los dos en neutral): justo el sondeo interesante, el de aterrizaje predicho, era el
		# único que no se veía.
		var offset_a := candidate_origins[0] - original_origin
		var offset_b := candidate_origins[1] - original_origin
		var offset_c := candidate_origins[2] - original_origin
		indicator_a.position = Vector3(offset_a.x, indicator_a.position.y, offset_a.z)
		indicator_b.position = Vector3(offset_b.x, indicator_b.position.y, offset_b.z)
		indicator_c.position = Vector3(offset_c.x, indicator_c.position.y, offset_c.z)
		_set_indicator_color(indicator_a, raycast_color if active_candidate_idx == 0 else inactive_raycast_color)
		_set_indicator_color(indicator_b, raycast_color if active_candidate_idx == 1 else inactive_raycast_color)
		_set_indicator_color(indicator_c, raycast_color if active_candidate_idx == 2 else inactive_raycast_color)

	solve_two_bone_ik(higher_leg, lower_leg, leg.current_target.global_position, leg.pole.global_position)
	_level_foot(left, bones, inputs)


## ── EL ÁNGULO DEL PIE, POR ESTADOS (05/11/2026, el dios del juego: «el estilo de esta animación no le tiene miedo a
## estados discretamente distintos… con los pies tocando el piso o no»; «este ángulo debería ser algo absoluto y no
## relativo, porque ahí volvería el tembleque») ─────────────────────────────────────────────────────────────────────
## Tres estados, y el cambio entre uno y otro es de golpe, como el salto:
##   · APOYADO: plano, horizontal, mirando hacia donde mira el cuerpo.
##   · EN VUELO (su paso de la marcha): un solo ángulo, el de la punta, según DÓNDE ESTÁ EL PIE en el paso respecto de la
##     cadera: plano debajo de ella, la punta para abajo hacia atrás —hasta `FLIGHT_BACK` un paso entero atrás— y
##     adelante lo que diga `FLIGHT_FRONT` (0: llega plano, como apoya); más allá, el tope.
##   · EN EL AIRE (saltando, cayendo): la punta `AIR_FOOT_POINT` para abajo.
## ABSOLUTO: respecto del piso y del giro del cuerpo, nunca de la tibia, así que no tiembla con ella. El paso de
## asentamiento, al frenar, va apoyado: es un pasito cerca de la cadera.
##
## *Hasta entonces: apoyado, un blend hacia lo nivelado; en vuelo, el pie «colgaba con la tibia» —o nada: el blend partía
## del ángulo del cuadro anterior, así que una vez nivelado quedaba nivelado, y el de atrás despegaba plano con la tibia
## 50° para atrás—; y la punta del aire entraba y salía en un blend. El 05/11 se probó también que el pie siguiera a la
## tibia, y temblaba.*
const FLIGHT_BACK := deg_to_rad(40.0)
const FLIGHT_FRONT := 0.0  # adelante llega plano, como apoya (06/11/2026, el dios del juego; era 15°)
## Lo que baja la punta del pie en el aire (05/11/2026, el dios del juego: «haría a las poses sentirse menos stiff… que
## estén un poco para abajo… la misma inclinación en todos los arquetipos»).
const AIR_FOOT_POINT := deg_to_rad(20.0)


## EL ÁNGULO DEL PIE `left` (ver EL ÁNGULO DEL PIE, POR ESTADOS). Lo de abajo de por qué hace falta: `solve_two_bone_ik`
## resuelve DOS huesos y el pie cuelga rígido del segundo, así que hereda la inclinación de la tibia —con la pierna
## inclinada mete la punta o el talón en el piso, y el roll del pole lo torcía—; acá se le pone el suyo.
##
## Es HORIZONTAL, no alineado a la normal del piso. En una ciudad plana el resultado es idéntico y no
## tiene ningún caso patológico —rampas, bordes, un rayo que pega raro—. Seguir la normal es aditivo:
## se cambia `Vector3.UP` por la normal guardada del raycast y se le pone un clamp de inclinación.
func _level_foot(left: bool, bones: CustomBonesUtil, inputs: AnimationInputs) -> void:
	var foot: CustomBone = bones.left_foot if left else bones.right_foot
	if not is_instance_valid(foot):
		return
	var yaw: float = inputs.basis.get_euler().y
	var pitch := 0.0
	if not inputs.grounded:
		pitch = -AIR_FOOT_POINT
	elif (_left_swinging if left else _right_swinging):
		pitch = _flight_pitch(left, yaw)
	var level := level_basis(left, yaw)
	if pitch != 0.0:
		level = Basis(Basis(Vector3.UP, yaw) * Vector3.RIGHT, pitch) * level

	# LA BASE NIVELADA ES EL REPOSO DEL HUESO CON EL YAW DEL PERSONAJE ENCIMA, y nada más.
	#
	# ⚠ No re-derivarla con `ReferenceRig._conventional_basis(frente_en_el_mundo)`. Esa función snapea
	# primero al EJE DEL MUNDO más parecido, que es una decisión discreta: para un pie horizontal salta
	# entre ±X y ±Z cada 45° de giro, y cada eje trae su propia convención de roll. Pasarle una dirección
	# que rota con el personaje hace que el roll pegue un salto al cruzar esas fronteras — **la suela
	# quedaba mirando de costado según hacia dónde mirara el personaje**. La función no está mal: está
	# pensada para una dirección de reposo FIJA en el marco del personaje, que es como la usa ReferenceRig.
	#
	# El reposo ya trae el roll correcto por construcción, y el yaw es continuo. Y sale más barato.
	foot.global_basis = level.orthonormalized()


## EL ÁNGULO DE LA PUNTA EN VUELO (rad; negativo, para abajo): dónde está el pie a lo largo del paso, de un paso entero
## atrás de la cadera (`FLIGHT_BACK` para abajo) a un paso entero adelante (`FLIGHT_FRONT`), con topes.
func _flight_pitch(left: bool, yaw: float) -> float:
	var leg := get_leg_data(left)
	var basis_owner := leg.raycast.get_parent() as Node3D
	var under_hip: Vector3 = basis_owner.global_transform * leg.neutral_local
	var along := (leg.current_target.global_position - under_hip).dot(Basis(Vector3.UP, yaw) * Vector3.FORWARD)
	var share := clampf(along / maxf(current_excursion, 0.05), -1.0, 1.0)
	return share * (FLIGHT_FRONT if share > 0.0 else FLIGHT_BACK)


## EL PIE NIVELADO de un personaje que mira con ese giro (`yaw`): el reposo del hueso con el giro encima (ver
## `_level_foot`). Lo usa también el sentado, que no pisa pero tampoco tiene por qué colgar con la tibia.
static func level_basis(left: bool, yaw: float) -> Basis:
	var rest: Basis = ReferenceRig.get_rig().bases.get("left_foot" if left else "right_foot", Basis.IDENTITY)
	return Basis(Vector3.UP, yaw) * rest


## PASO DE ASENTAMIENTO. Al frenar los pies quedan asimétricos (uno adelante, uno atrás) porque el
## ciclo se cortó donde se cortó. Acá el pie más desplazado da un pasito para meterse bajo la cadera
## — es lo que hace cualquiera al detenerse, y de paso cubre girar en el lugar o que te empujen.
##
## Es el único paso que NO manda la fase (quieto no hay ciclo que avanzar). De a uno por vez: el
## guard de `_is_stepping` sobre AMBOS pies impide que se muevan los dos juntos, y el desempate por
## desplazamiento hace que arranque el que más lo necesita.
func _settle_step_if_needed(left: bool, leg: LegData, sizes: SkeletonSizesUtil, basis_owner: Node3D, landing: Vector3) -> void:
	if _is_stepping(left_leg_current_target) or _is_stepping(right_leg_current_target):
		return
	var my_offset := _foot_offset_from_neutral(left, basis_owner)
	if my_offset <= sizes.foot_reach * SETTLE_EXCURSION_FRACTION:
		return
	if my_offset < _foot_offset_from_neutral(not left, basis_owner):
		return  # el otro está peor: que arranque él
	_tween_foot_to(leg.current_target, leg.current_target.global_position, landing, SETTLE_DURATION, sizes.step_height * 0.4)

func _foot_offset_from_neutral(left: bool, basis_owner: Node3D) -> float:
	var other := get_leg_data(left)
	var neutral_world: Vector3 = basis_owner.global_transform * other.neutral_local
	return Vector2(
		other.current_target.global_position.x - neutral_world.x,
		other.current_target.global_position.z - neutral_world.z
	).length()

static func _set_indicator_color(indicator: MeshInstance3D, color: Color) -> void:
	if not indicator.material_override is StandardMaterial3D:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		indicator.material_override = mat
	(indicator.material_override as StandardMaterial3D).albedo_color = color

static func _tween_foot_to(node: Node3D, from_pos: Vector3, to_pos: Vector3, duration: float, step_height: float) -> void:
	if duration <= 0.0 or from_pos.is_equal_approx(to_pos):
		node.global_position = to_pos
		_clear_step_data(node)
		return
	node.set_meta("stepping", true)
	node.set_meta("ik_step_start_time", Time.get_ticks_msec() / 1000.0)
	node.set_meta("ik_step_duration", duration)
	node.set_meta("ik_step_from", from_pos)
	node.set_meta("ik_step_to", to_pos)
	node.set_meta("ik_step_height", step_height)

static func _update_stepping_foot(node: Node3D) -> void:
	if not _is_stepping(node):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var start_time := float(node.get_meta("ik_step_start_time"))
	var duration := float(node.get_meta("ik_step_duration"))
	var from_pos := Vector3(node.get_meta("ik_step_from"))
	var to_pos := Vector3(node.get_meta("ik_step_to"))
	var step_height := float(node.get_meta("ik_step_height"))
	var progress: float = clamp((now - start_time) / duration, 0.0, 1.0)
	var eased := ease_in_out(progress)
	var pos := from_pos.lerp(to_pos, eased)
	pos.y += sin(eased * PI) * step_height
	node.global_position = pos
	if progress >= 1.0:
		node.global_position = to_pos
		_clear_step_data(node)

static func ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

static func _clear_step_data(node: Node3D) -> void:
	node.set_meta("stepping", false)
	node.remove_meta("ik_step_start_time")
	node.remove_meta("ik_step_duration")
	node.remove_meta("ik_step_from")
	node.remove_meta("ik_step_to")
	node.remove_meta("ik_step_height")

static func _is_stepping(n: Node) -> bool:
	return n.has_meta("stepping") and bool(n.get_meta("stepping"))

## Posición del pie cuando el personaje está en el aire: `tuck` m arriba de donde iría parado (lo calcula quien lo
## llama: ver LocomotionCommon.leg_tuck, recogidas al subir y estiradas al caer).
func update_airborne_target(left: bool, tuck: float) -> void:
	var leg := get_leg_data(left)
	leg.airborne_target.transform.origin = Vector3(
		leg.neutral_local.x,
		leg.neutral_local.y - tuck,
		leg.neutral_local.z
	)

static func get_orthogonal(v: Vector3) -> Vector3:
	if abs(v.x) < abs(v.y):
		return Vector3(0, -v.z, v.y).normalized()
	else:
		return Vector3(-v.z, 0, v.x).normalized()

## PLANTA LOS PIES BAJO LA CADERA, en el piso que se le indique, y corta cualquier paso en curso.
##
## Es lo que hay que llamar cuando el personaje CAMBIA DE LUGAR de golpe (un teleport, colocarlo en
## una parcela del sandbox): los targets de los pies viven en el MUNDO, así que si no se los replanta
## quedan donde estaba el cuerpo antes — y el ajuste de pelvis, que mide cadera↔pie, lee un déficit
## enorme y baja la raíz metros para "alcanzarlos". El síntoma es el esqueleto colgando por debajo de
## la cápsula. Ver BoneInstantiator.place_at.
func plant_feet_under_body(local_targets: Node3D, ground_y: float, ankle_height: float) -> void:
	for left in [true, false]:
		var leg := get_leg_data(left)
		var at: Vector3 = local_targets.global_transform * Vector3(leg.neutral_local.x, 0.0, leg.neutral_local.z)
		at.y = ground_y + ankle_height
		leg.current_target.global_position = at
		leg.next_target.global_position = at
		_clear_step_data(leg.current_target)
	gait_phase = 0.0
	_left_swinging = false
	_right_swinging = false
	_left_was_airborne = false
	_right_was_airborne = false


## Planta cada pie donde el raycast dice que va (current_target = next_target) y limpia el paso en
## curso. Se llama al SALIR de la recuperación: durante ella los targets están congelados
## (recovery_targets_locked), y sin esto los pies tienen que "alcanzar" al cuerpo a los pasos —
## lento, y peor en un proxy que corre el solve a media tasa (feet lag por unos segundos).
func reset_step_targets_to_ground() -> void:
	for pair in [[left_leg_current_target, left_leg_next_target], [right_leg_current_target, right_leg_next_target]]:
		var cur: Node3D = pair[0]
		var nxt: Node3D = pair[1]
		if is_instance_valid(cur) and is_instance_valid(nxt):
			cur.global_position = nxt.global_position
			_clear_step_data(cur)
	_left_swinging = false
	_right_swinging = false
	_left_was_airborne = false
	_right_was_airborne = false
