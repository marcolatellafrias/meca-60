class_name GrabbableInteractable
extends Interactable
## Los puntos de agarre del cuerpo que cuelga de este nodo, y el SOLVER del agarre: acá se juntan
## todas las manos que lo sostienen y se resuelve una sola vez, en vez de que cada agarrador aplique
## su propia fuerza por su cuenta.
##
## El modelo prioriza ESTABILIDAD sobre realismo (ver character-parametric:docs/conceptual/multiplayer.md, "Grab rework"), y
## son dos sistemas de segundo orden DESACOPLADOS, ambos críticamente amortiguados:
##
## - **Posición**: la fuerza va siempre al centro del cuerpo (`apply_central_force`), nunca al grab
##   point. Aplicarla off-center acopla traslación y rotación en un lazo realimentado (la fuerza
##   rota el cuerpo → el grab point se mueve → cambia la fuerza) y ese lazo es el que hacía oscilar
##   la caja larga para siempre. Cada mano implica una posición del cuerpo (su target menos su
##   offset rotado); el objetivo es el promedio.
## - **Orientación**: explícita, no emergente, y siempre la MISMA restricción: alinear un eje del
##   cuerpo con un eje que definen los agarres. Con dos o más manos, el eje entre los dos grab
##   points más separados se alinea con el eje entre sus targets. Con una sola mano, el eje
##   centro→grab point se alinea apuntando de vuelta al pecho del agarrador: **lo que agarraste es
##   lo que te queda de frente**, y el resto del objeto se extiende para el otro lado. Agarrar una
##   caja larga de la punta la deja apuntando en tu dirección de vista; agarrarla del medio la deja
##   de costado. Así el grab point importa también con un solo agarrador, y sin caso especial.
##
## Por eso dos agarradores dejan de ser un problema: sobre la posición son dos resortes tirando de
## UN punto, y un punto no tiene orientación que sobre-determinar.
##
## ── LA CAJA SE AGARRA POR UNA CARA, Y QUEDA DERECHA (03/11/2026, lo pidió el usuario) ─────────────────────
## «Siempre las agarran como en un ángulo… no de una forma satisfactoria, como en la vida real, con las dos manos, desde
## sus dos costados». Los puntos de agarre estaban ADENTRO de la caja (uno por octavo en la grande), y con una mano lo que
## apuntaba al pecho era la línea del centro a ese punto: una diagonal, así que la caja mostraba una esquina. Ahora, en lo
## que sale de celdas (`setup_from_cells`, una caja: `box_half`), los puntos van EN LAS CARAS, en la misma grilla que los
## de las manos, y la restricción es la misma de siempre con dos cambios: lo que apunta al pecho es LA CARA del punto
## (`face_of`), no la línea al centro; y la caja QUEDA DERECHA —el eje suyo que más mira arriba, arriba—: con una mano,
## de frente y derecha; con dos, el eje entre las manos como siempre, y el giro alrededor de él, derecho. Si se agarra
## de la tapa, sólo derecha. Lo que no es caja (un compañero, ver CharacterGrabbable) sigue como estaba.
##
## ── LOS PAQUETES SON MÓDULOS (04/11/2026, lo pidió el usuario: «cada celda es como un tamaño de caja y la larga
## serían dos celdas juntas… el punto de agarre se centre en las caras») ───────────────────────────────────────────────
## Una caja es una pila de MÓDULOS de `MODULE` m de lado (la grande, 1 × 1 × 1; la alargada, 1 × 1 × 2), y sus puntos —los
## de agarre y los de las manos, los mismos— son EL CENTRO DE LA CARA DE CADA MÓDULO. Lo que se declara en celdas sale
## en módulos redondeando (`modules`, nunca menos de uno por lado). *Antes una grilla de celdas de 10,5 cm con su densidad
## (un punto cada 3 celdas para agarrar, cada 4 para las manos): el punto agarrado quedaba corrido del centro de la cara,
## la caja colgaba corrida y la cápsula de quien la llevaba le tocaba una esquina y la giraba.*
##
## ── CADA UNO LLEVA EL CENTRO DE SU PARTE (04/11/2026, propuesto al usuario a partir de su idea y aprobado) ─────
## El punto por donde lleva cada mano no es el que agarró sino uno que se deriva de él (`_held`, lo que usa el solver):
## la cara que agarró, y en ella, el centro de SU PARTE de la caja. Solo, su parte es la caja entera: su punto queda
## sobre el centro de la caja y la alargada nunca cuelga de una punta. Por eso SOLO, LA ALARGADA SE LLEVA DE LO ANCHO:
## agarrada de una punta, el punto se pasa a la cara larga que da a quien la lleva (`_carry_face`). Y NUNCA DE LA TAPA NI
## DE LA BASE: el punto de agarre más cerca del pecho suele ser el de arriba, y colgada de él la caja quedaba abajo y
## lejos; agarrada de ahí, el punto se pasa a la cara de costado que da a quien la lleva. De a varios, la caja
## se parte en partes iguales a lo largo de su eje más largo (las que entran: nunca más que sus módulos), en el orden en
## que están las manos a lo largo de él, y cada uno se va al centro de la suya. El punto viaja de a poco
## (LocomotionCommon.share_shift_speed), así que sumarse o irse alguien no pega saltos: el solver ya mueve la caja hacia
## el punto con su resorte. Quien agarró una punta en la caja de a dos se queda en la punta.

var grab_points: Array[Node3D] = []
## La mitad de la caja (m) si salió de celdas; cero si no es una caja (ver arriba).
var box_half := Vector3.ZERO
## Cuántos módulos tiene por lado (ver LOS PAQUETES SON MÓDULOS).
var modules := Vector3i.ONE
## El lado de un módulo (m): seis celdas, la caja grande.
const MODULE := 0.63

## ── LOS GOLPES A LO QUE SE LLEVA (03/11/2026) ─────────────────────────────────────────────────────────────────────
## Mientras alguien lo sostiene, lo que lo golpea —una pared, un poste, otro— le llega a quien lo lleva como un golpe
## más (ver InteractionController y ExhibitOperator, que lo escuchan): lo inclina, le resta equilibrio y le achica el
## cono de agarre, así un roce puede hacer que se le caiga. Se mide como el daño del paquete (ver PackageDamage): el
## impulso de los contactos del cuadro, que en reposo es casi nada y en un choque es grande. `impulse` en N·s, del
## mundo, el que recibió el paquete.
signal struck(impulse: Vector3)
## Cuánto de ese golpe le llega a quien lo lleva: el impulso, dividido por su masa, por esto (lo demás lo toman los
## brazos).
const STRUCK_SHARE := 0.5
## Lo que tiene que cambiarle la velocidad al paquete en un cuadro (m/s) para ser un golpe, y cuánto se ignora después.
const STRUCK_MIN_DV := 0.6
const STRUCK_COOLDOWN_MS := 150
## Un contacto cuenta como golpe si su normal es más de costado que esto (el componente vertical, de 0 a 1).
const SIDE_CONTACT := 0.7
var _struck_at := -100000

## SI ESTE CUERPO OFRECE EL AGARRE. En false el detector no lo resalta ni lo engancha, como si no
## tuviera agarrable (ver InteractionDetector, que consulta `can_interact`). Lo apaga el paquete
## CONGELADO de una parcela del design sandbox: el solver mueve el cuerpo con fuerzas y a un `freeze`
## las fuerzas no le hacen nada, así que resaltarlo y ofrecer "[LMB] to grab" sería mentir.
##
## ⚠ ES UNA BANDERA Y NO LA REGLA "CONGELADO ⇒ NO AGARRABLE", que parece la general y no lo es: los
## PROXIES REMOTOS son cuerpos congelados (ver CharacterKind.simulates), y agarrar, empujar
## y tirarle cosas a un compañero es juego deseado (ver character-parametric:docs/conceptual/multiplayer.md). Esa regla en la base
## habría apagado en silencio toda la interacción entre jugadores en red.
var offers_grab := true

## Unidad en la que se miden TODOS los grabbables: los tamaños se declaran en celdas y de acá salen
## los metros (ver MODULE: los puntos salen por módulo, no por celda).
##
## Solo la usan los grabbables. El dashboard tiene la suya (`ProceduralDashboard.CELL`) y no tiene nada que ver.
const CELL_SIZE      := 0.105

## Constante de tiempo del seguimiento (s): cuánto tarda el objeto en llegar a donde apuntás. Es el
## único parámetro de "feel" — la rigidez y la amortiguación se DERIVAN de él y de la masa
## (k = m·ω², c = 2·m·ω), así que el sistema es crítico siempre: no hay overshoot ni oscilación, y
## no hay ganancias que tunear por objeto. Más chico = más firme.
const RESPONSE_TIME     := 0.08
const ANG_RESPONSE_TIME := 0.12
## Fuerza (N) y torque (N·m) por unidad de `strength` del arquetipo. Como la rigidez escala con la
## masa, todo objeto responde igual de rápido: lo que hace que el peso SE SIENTA es este techo. La
## fuerza incluye sostener el propio peso del objeto, así que si la fuerza combinada de los
## agarradores no llega a m·g el objeto cuelga — que es el feedback legible de "vení a ayudarme".
##
## Con `strength` entre 0.3 (el pibe) y 1.2 (el fuerte) y las cajas de debug (4/8/40/80 kg), 1600
## da: las livianas las mueve cualquiera; la pesada cuadrada (40 kg = 392 N) la sostiene uno solo
## con margen para maniobrar; la pesada larga (80 kg = 784 N) deja a un arquetipo medio justo en el
## límite (la sostiene pero no la maneja) y entre dos va cómoda. Es EL número a tocar si el peso no
## se siente bien: son newtons por unidad de fuerza, nada más.
const FORCE_PER_STRENGTH  := 1600.0
const TORQUE_PER_STRENGTH := 300.0

## ── LO QUE PESA SE NOTA EN LA LENTITUD, NUNCA EN NO PODER ────────────────────────────────────────
## Todo paquete se levanta, también solo (el usuario, 11/10/2026: «un paquete que nadie pueda
## levantar es una decisión que nos limita mucho en gameplays»). Antes, si la fuerza no llegaba a m·g el
## objeto colgaba: el pibe no levantaba el armario y la caja fuerte sólo el genérico y el forzudo.
##
## Dos cosas lo hacen notar, las dos de la CARGA —el peso contra la fuerza de quienes lo sostienen, 1 =
## justo su fuerza (`load_of`)—: el techo de fuerza nunca baja de m·g × (1 + LIFT_MARGIN), así que lo que
## pasa tu fuerza sube despacio y cuesta manejarlo con la mira (con 0,15 le quedan 1,5 m/s² para moverlo);
## y quien lo lleva camina, corre, arranca y frena más lento (`carry_speed_factor`), lo que además evita que el paquete
## torpe se le quede atrás y se le suelte. Debajo de una carga de 1 / 1,15 = 0,87 el techo es el de
## siempre: lo que ya se llevaba se lleva igual. TODO PESO FRENA ALGO (04/11/2026, el usuario: «simplifica el
## sistema»): *hasta entonces, hasta una carga de 0,3 se caminaba como con las manos vacías, y los fuertes no notaban
## la caja grande.*
const LIFT_MARGIN := 0.15
## ── LO QUE SE LLEVA VA UN POCO ABAJO DE LA MIRADA (03/11/2026, lo pidió el usuario) ──────────────────────
## «El paquete le tapa la vista… en tercera persona se ve medio ridículo… corriendo con un paquete justo al frente de su
## cara». Lo agarrado sigue yendo adonde se apunta, a `LocomotionCommon.hold_reach` del pecho —la misma para todos, ver
## LocomotionCommon—, pero `hold_drop_deg` más abajo: mirando al horizonte o arriba, esa diferencia entera; mirando abajo se
## desvanece y a `hold_drop_fade_deg` hacia abajo ya no hay, así se lo apoya donde se mira. Es correr la puntería, no
## aflojar el resorte: lo mismo para todos y con cualquier peso. Los números, en el F1 de los experimentos (ver LocomotionPanel).
## ── EL CONO DE LO QUE SE LLEVA (03/11/2026) ─────────────────────────────────────────────────────────────────────────
## Lo que se lleva se suelta si su punto sale de este cono alrededor de la mirada: el mismo para todos los arquetipos (el
## usuario: «no es algo que se lea visualmente… se podría sentir inconsistente o injusto»). Se achica mientras el
## cuerpo está inclinado por un golpe —un roce, el golpe a la caja, ver LOS GOLPES A LO QUE SE LLEVA—, hasta
## `carry_cone_at_fall` de él justo antes de caerse: la diferencia entre arquetipos es cuánto los inclina un golpe, su
## estabilidad. *Antes era el de los controles, 120°: no se soltaba casi nunca.*
## ── EL TOPE DEL PECHO (04/11/2026, lo pidió el usuario: «hacer esta colisión de una manera más inteligente…
## simple y bien documentado… estructural») ──────────────────────────────────────────────────────────────────────────
## Lo que se lleva no choca con nada de quien lo lleva (ver `ignore_holder`): lo frena una PARED INVISIBLE delante de su
## pecho, vertical y de frente a donde apunta —la sacada horizontal de la mano, del pecho al objetivo—, a
## `LocomotionCommon.chest_clear`. La pared sale SÓLO DE LO QUE CADA MANO YA MANDA EN CADA CUADRO (de dónde sale y hacia
## dónde tira), sin estado ni preguntas al personaje, así que no tiene casos aparte: sentado, el pecho sale de la silla y
## la pared con él; tirado, levantándose o desconectado no hay mano y no hay pared (caer suelta lo que se lleva, y una
## mano que no se refresca se descarta, ver HOLD_TIMEOUT_MS); de a dos, cada mano trae la suya; en red, la mano del
## compañero viaja con su pecho. El objetivo nunca la cruza, y si el cuerpo la cruzó (se atrasa al acelerar) lo empuja
## para afuera una fuerza sin techo, como una pared. Nunca empuja a quien lo lleva: lo que se lleva sólo le pasa fuerzas
## por programa (ver LOS GOLPES A LO QUE SE LLEVA). *Antes chocaba con la cápsula: le tocaba una esquina a la caja y la
## giraba, y los débiles no la enderezaban.*
## Una mano se descarta si dejó de refrescarse (el agarrador se desconectó o perdió el stream).
const HOLD_TIMEOUT_MS := 200
## Clave de la mano local cuando no hay red (offline no hay peer id).
const LOCAL_HOLD := 0
## Qué tan cerca de su objetivo (m) tiene que estar el punto de una mano para haber llegado (ver `cone_point`).
const ARRIVED := 0.2

## Manos que sostienen el cuerpo. key (peer id, o LOCAL_HOLD) ->
## {offset: Vector3 local (lo que agarró), held: Vector3 local (por donde lleva, ver CADA UNO LLEVA EL CENTRO DE SU
## PARTE), target: Vector3 mundo, origin: Vector3 mundo (el pecho), strength, t}
var _holds: Dictionary = {}
## ── EL FRENO SIGUE AL OBJETIVO (04/11/2026) ──────────────────────────────────────────────────────────────────────────
## El freno del resorte va contra lo que se mueve el objetivo, no contra el marco: frenando contra el mundo, con el
## objetivo andando a v la caja quedaba 2v/ω atrás —a 1,2 m/s, 19 cm, pegada al pecho—. Lo que se mueve el objetivo sale
## de dónde estaba el cuadro anterior (`_prev_desired`), suavizado.
var _prev_desired := Vector3.INF
var _desired_velocity := Vector3.ZERO
## EL FRENO DEL GIRO, CONTRA LO QUE GIRA EL OBJETIVO (04/11/2026, el usuario: «cuando estás girando con el
## paquete… se está cambiando de posición y después se gira para coincidir con la cara del agarre con tu pecho… no gira
## con movimiento angular en base al yaw»): el mismo arreglo que el de la posición. El freno del giro pegaba sobre todo el
## giro de la caja contra el mundo, así que al girar quien la lleva la caja se quedaba mirando adonde miraba y llegaba
## tarde; ahora frena el giro respecto de cuánto gira la orientación que se le pide (la de cuadro anterior, `_prev_aim`),
## y la caja gira con el que la lleva. Un salto de la orientación pedida de más de `AIM_JUMP` rad en un cuadro (cambió la
## cara por donde se lleva) no cuenta como giro.
##
## GIRAR LO QUE SE LLEVA (04/11/2026, el usuario: «meté lo de poder girar paquetes»): quien lo lleva solo le suma
## un giro (`set_turn`: rumbo alrededor de la vertical y vuelta alrededor de su derecha, en rad), relativo a cómo lo
## llevaría sin girarlo, así que gira con él; el paquete gira sobre su centro, no sobre la mano (ver `_turn_now`), y las
## manos toman las caras que les queden a los costados (ver ArmsController, UNA CAJA). Con dos o más, no gira.
var _prev_aim := Quaternion.IDENTITY
var _has_prev_aim := false
var _aim_spin := Vector3.ZERO
const AIM_JUMP := 0.3
## El giro de este cuadro (ver GIRAR LO QUE SE LLEVA), el que se le sumó a la orientación pedida.
var _turn_now := Quaternion.IDENTITY


func set_turn(key: int, turn: Vector2) -> void:
	if _holds.has(key):
		(_holds[key] as Dictionary)["turn"] = turn
const DESIRED_VELOCITY_SMOOTH := 0.25

func _ready() -> void:
	set_physics_process(false)  # sólo corre mientras alguien lo sostiene

# ── Manos ─────────────────────────────────────────────────────────────────────

## Registra/refresca una mano. La llama cada frame quien agarra: el agarrador local directo, o
## NetBody al recibir la intención de un co-grabber remoto.
func set_hold(key: int, offset_local: Vector3, target_world: Vector3, origin_world: Vector3, strength: float) -> void:
	var held: Vector3 = (_holds[key] as Dictionary)["held"] if _holds.has(key) else offset_local
	var arrived: bool = (_holds[key] as Dictionary)["arrived"] if _holds.has(key) else false
	if not arrived and global_transform * held != Vector3.INF:
		arrived = (global_transform * held).distance_to(target_world) < ARRIVED
	if _holds.is_empty():
		_prev_desired = Vector3.INF
		_has_prev_aim = false
		_has_turn_base = false
	var turn: Vector2 = (_holds[key] as Dictionary).get("turn", Vector2.ZERO) if _holds.has(key) else Vector2.ZERO
	_holds[key] = {"offset": offset_local, "held": held, "target": target_world, "origin": origin_world,
		"strength": strength, "t": Time.get_ticks_msec(), "arrived": arrived, "turn": turn}
	set_physics_process(true)

## POR DONDE LLEVA LA MANO `key` AHORA, en el mundo (ver CADA UNO LLEVA EL CENTRO DE SU PARTE); INF si no la tiene.
## Es lo que cuenta para el alcance y el cono de quien lo lleva.
func held_world(key: int) -> Vector3:
	if not _holds.has(key):
		return Vector3.INF
	# GIRADO (ver GIRAR LO QUE SE LLEVA), donde estaría la mano sin el giro: lo que cuenta para el alcance no se va al
	# otro lado de la caja al darla vuelta.
	var held := (_holds[key] as Dictionary)["held"] as Vector3
	if _holds.size() == 1 and _turn_now != Quaternion.IDENTITY:
		var center := global_transform.origin
		return center + Basis(_turn_now.inverse()) * global_transform.basis * held
	return global_transform * held

func clear_hold(key: int) -> void:
	if _holds.erase(key) and _holds.is_empty():
		_released()

func clear_all_holds() -> void:
	var had := not _holds.is_empty()
	_holds.clear()
	if had:
		_released()


## ── AL SOLTARLO, NO SALE PERFECTO (04/11/2026, el usuario) ─────────────────────────────────────────────────
## El agarre lo lleva derecho y sin girar, así que soltado aterrizaba plano y se clavaba. Al soltar la última mano, una
## caja se lleva un giro de vuelco: hacia donde iba, `RELEASE_TUMBLE` rad/s por cada m/s de lo que avanzaba (respecto de
## su marco), y un poco alrededor de la vertical. Así cae de canto y se vuelca o se desliza, como un objeto.
const RELEASE_TUMBLE := 0.6
const RELEASE_TWIST := 0.3

func _released() -> void:
	var body := get_parent() as RigidBody3D
	if box_half == Vector3.ZERO or not is_instance_valid(body) or not _simulates(body):
		return
	var moving := body.linear_velocity - frame_velocity(body, body.global_position)
	moving.y = 0.0
	if moving.length() < 0.2:
		return
	var axis := Vector3.UP.cross(moving).normalized()
	body.angular_velocity += axis * moving.length() * RELEASE_TUMBLE \
		+ Vector3.UP * randf_range(-1.0, 1.0) * RELEASE_TWIST

func hold_count() -> int:
	return _holds.size()

# ── Solver ────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_expire_holds()
	if _holds.is_empty():
		set_physics_process(false)
		return
	var body := get_parent() as RigidBody3D
	if not is_instance_valid(body) or not _simulates(body):
		return
	body.sleeping = false
	_share_points(delta)
	_solve_position(body, delta)
	_solve_orientation(body)
	if box_half != Vector3.ZERO:
		_feel_hits(body)

func _expire_holds() -> void:
	var now := Time.get_ticks_msec()
	var had := not _holds.is_empty()
	for key in _holds.keys():
		if now - int((_holds[key] as Dictionary)["t"]) > HOLD_TIMEOUT_MS:
			_holds.erase(key)
	if had and _holds.is_empty():
		_released()

## Sólo resuelve quien simula el cuerpo: offline siempre, en red la autoridad de su NetBody. Los
## demás lo siguen (NetBody._follow_reference) y no tocan las fuerzas.
func _simulates(body: RigidBody3D) -> bool:
	if not multiplayer.has_multiplayer_peer():
		return true
	for child in body.get_children():
		if child is NetBody:
			return (child as NetBody).is_multiplayer_authority()
	return true  # sin NetBody (p.ej. la cápsula de un compañero): lo maneja su propio sistema

func _solve_position(body: RigidBody3D, delta: float) -> void:
	var basis := body.global_transform.basis
	var desired := Vector3.ZERO
	# GIRA SOBRE SU CENTRO (ver GIRAR LO QUE SE LLEVA): la mano se mide sin el giro.
	var held_basis := Basis(_turn_now.inverse()) * basis if _holds.size() == 1 else basis
	for h in _holds.values():
		desired += (h["target"] as Vector3) - held_basis * (h["held"] as Vector3)
	desired /= float(_holds.size())
	var wall := Vector3.ZERO
	if box_half != Vector3.ZERO:
		desired = _behind_walls(basis, desired)
		wall = _wall_push(body, basis)

	var omega := 1.0 / (RESPONSE_TIME * _softness(body))
	var m     := body.mass
	# EL FRENO, CONTRA LO QUE SE MUEVE EL OBJETIVO (ver arriba). El primer cuadro, contra el marco (ver `frame_velocity`):
	# a bordo, la velocidad que se frena es la de la caja respecto de la meca, no la del mundo; si no, a 30 m/s el freno
	# tiraba la caja para atrás de la mano.
	var following := frame_velocity(body, body.global_position)
	if _prev_desired.is_finite() and delta > 0.0:
		_desired_velocity = _desired_velocity.lerp((desired - _prev_desired) / delta, DESIRED_VELOCITY_SMOOTH)
		following = _desired_velocity
	else:
		_desired_velocity = following
	_prev_desired = desired
	var force := (desired - body.global_position) * (m * omega * omega) \
		- (body.linear_velocity - following) * (2.0 * m * omega)
	force -= body.get_gravity() * m  # sostener el peso propio; cuenta contra el techo
	var ceiling := maxf(total_strength() * FORCE_PER_STRENGTH, body.get_gravity().length() * m * (1.0 + LIFT_MARGIN))
	body.apply_central_force(force.limit_length(ceiling) + wall)


## ── LO PESADO SE LLEVA MÁS BLANDO (04/11/2026, el usuario) ──────────────────────────────────────────────────
## El resorte del agarre era igual de firme para todo —0,08 s— y cualquier golpe se corregía enseguida: parecía
## programado. Ahora tarda más en llegar adonde se apunta cuanto más pesa para quienes lo llevan (la carga, ver
## `load_of`): de 1 con nada a `LocomotionCommon.heavy_softness` veces con una carga de 1 o más. Lo liviano, firme; lo pesado
## se bambolea y los golpes se notan. El tope del pecho no se ablanda: es una pared.
func _softness(body: RigidBody3D) -> float:
	if not is_instance_valid(body):
		return 1.0
	var weight := clampf(load_of(body.mass, maxf(total_strength(), 0.01)), 0.0, 1.0)
	return lerpf(1.0, maxf(LocomotionCommon.base().heavy_softness, 1.0), weight)


## ── EL TOPE DEL PECHO, en números (ver arriba) ──────────────────────────────────────────────────────────────────────
## La pared de la mano `h`: su normal (horizontal, del pecho hacia donde tira) y cuánto está la caja delante de ella si
## su centro está en `centre` (lo más cerca de sus ocho esquinas, menos el tope). Negativo: la cruzó. Sin normal (tira
## derecho para arriba o abajo), no hay pared.
func _wall_gap(h: Dictionary, basis: Basis, centre: Vector3) -> Vector2:
	var normal := (h["target"] as Vector3) - (h["origin"] as Vector3)
	normal.y = 0.0
	if normal.length_squared() < 0.0001:
		return Vector2(INF, 0.0)
	normal = normal.normalized()
	var spread := absf((basis.x * box_half.x).dot(normal)) + absf((basis.y * box_half.y).dot(normal)) \
		+ absf((basis.z * box_half.z).dot(normal))
	var gap := (centre - (h["origin"] as Vector3)).dot(normal) - spread - LocomotionCommon.base().chest_clear
	return Vector2(gap, 1.0)


func _wall_normal(h: Dictionary) -> Vector3:
	var normal := (h["target"] as Vector3) - (h["origin"] as Vector3)
	normal.y = 0.0
	return normal.normalized() if normal.length_squared() > 0.0001 else Vector3.ZERO


## El objetivo, corrido hasta quedar delante de todas las paredes.
func _behind_walls(basis: Basis, desired: Vector3) -> Vector3:
	for h in _holds.values():
		var gap := _wall_gap(h, basis, desired)
		if gap.y > 0.0 and gap.x < 0.0:
			desired += _wall_normal(h) * -gap.x
	return desired


## Lo que empuja la pared a un cuerpo que la cruzó: un resorte crítico, sin techo.
func _wall_push(body: RigidBody3D, basis: Basis) -> Vector3:
	var omega := 1.0 / RESPONSE_TIME
	var out := Vector3.ZERO
	for h in _holds.values():
		var gap := _wall_gap(h, basis, body.global_position)
		if gap.y <= 0.0 or gap.x >= 0.0:
			continue
		var normal := _wall_normal(h)
		var closing := minf((body.linear_velocity - frame_velocity(body, body.global_position)).dot(normal), 0.0)
		out += normal * (-gap.x * omega * omega - closing * 2.0 * omega) * body.mass
	return out


## ── CADA UNO LLEVA EL CENTRO DE SU PARTE, en números (ver arriba) ────────────────────────────────────────────────────
## Cada cuadro, el punto de cada mano va hacia el que le toca.
func _share_points(delta: float) -> void:
	if box_half == Vector3.ZERO:
		for h in _holds.values():
			h["held"] = h["offset"]
		return
	var keys := _holds.keys()
	var along := _long_axis()
	if along >= 0:
		keys.sort_custom(func(a: Variant, b: Variant) -> bool:
			return ((_holds[a] as Dictionary)["offset"] as Vector3)[along] < ((_holds[b] as Dictionary)["offset"] as Vector3)[along])
	var parts := mini(keys.size(), modules[along]) if along >= 0 else 1
	var step := LocomotionCommon.base().share_shift_speed * delta
	for i in keys.size():
		var h: Dictionary = _holds[keys[i]]
		var face := face_of(h["offset"] as Vector3, box_half)
		var sags := keys.size() == 1 and LocomotionCommon.base().long_alone_sags
		var wide := keys.size() == 1 and along >= 0 and not sags
		if not _carries_by(face, wide, along):
			face = _carry_face(h, wide, along)
		# SE VENCE (ver LocomotionCommon.long_alone_sags): solo, por donde agarró —el centro de ese módulo—.
		if sags and face == face_of(h["offset"] as Vector3, box_half):
			h["held"] = (h["held"] as Vector3).move_toward(h["offset"] as Vector3, step)
			continue
		var want := Vector3(face.x * box_half.x, face.y * box_half.y, face.z * box_half.z)
		if along >= 0 and absf(face[along]) < 0.5:
			var part := floori(float(i) * parts / float(keys.size()))
			want[along] = -box_half[along] + (part + 0.5) * 2.0 * box_half[along] / float(parts)
		h["held"] = (h["held"] as Vector3).move_toward(want, step)


## El eje de la caja con más módulos (0, 1 o 2), si tiene más de uno; −1 si es un cubo de un módulo por lado.
func _long_axis() -> int:
	var best := -1
	var most := 1
	for axis in 3:
		if modules[axis] > most:
			most = modules[axis]
			best = axis
	return best


## SI LA CARA `face` (local) SIRVE PARA LLEVAR: de costado —ni tapa ni base, en el mundo— y, si `wide` (solo con la
## alargada), a lo largo de su eje `along`.
func _carries_by(face: Vector3, wide: bool, along: int) -> bool:
	if absf((global_transform.basis.orthonormalized() * face).dot(Vector3.UP)) > 0.7:
		return false
	return not wide or absf(face[along]) < 0.5


## LA CARA POR DONDE SE LLEVA (ver `_carries_by`) que más da hacia el pecho de la mano `h`, en los ejes de la caja.
func _carry_face(h: Dictionary, wide: bool, along: int) -> Vector3:
	var toward := global_transform.basis.inverse() * ((h["origin"] as Vector3) - global_position)
	var best := Vector3.ZERO
	var best_dot := -INF
	for axis in 3:
		for sign_of: float in [-1.0, 1.0]:
			var face := Vector3.ZERO
			face[axis] = sign_of
			if not _carries_by(face, wide, along):
				continue
			var d := face.dot(toward)
			if d > best_dot:
				best_dot = d
				best = face
	return best if best != Vector3.ZERO else face_of(h["offset"] as Vector3, box_half)

func _solve_orientation(body: RigidBody3D) -> void:
	# Si el error es identidad (p.ej. dos manos en el mismo punto) igual seguimos: el término de
	# amortiguación solo ya frena cualquier giro suelto, que es lo que queremos.
	var err := _orientation_error(body)
	# EL FRENO DEL GIRO, CONTRA LO QUE GIRA EL OBJETIVO (ver `_prev_aim`). La orientación pedida está en el mundo, así que
	# a bordo ya trae el giro de la meca.
	var following := frame_spin(body)
	var aim := (err * body.global_transform.basis.orthonormalized().get_rotation_quaternion()).normalized()
	var dt := get_physics_process_delta_time()
	if _has_prev_aim and dt > 0.0:
		var step := (aim * _prev_aim.inverse()).normalized()
		if step.w < 0.0:
			step = -step
		var turned := step.get_angle()
		if turned <= AIM_JUMP:
			var spin_now := step.get_axis() * (turned / dt) if turned > 0.00001 else Vector3.ZERO
			_aim_spin = _aim_spin.lerp(spin_now, DESIRED_VELOCITY_SMOOTH)
		following = _aim_spin
	else:
		_aim_spin = following
	_prev_aim = aim
	_has_prev_aim = true
	if err.w < 0.0:
		err = -err  # camino corto
	var angle := err.get_angle()
	var axis  := err.get_axis() if angle > 0.0001 else Vector3.ZERO

	var omega     := 1.0 / (ANG_RESPONSE_TIME * _softness(get_parent() as RigidBody3D))
	# El término de amortiguación pega sobre TODA la velocidad angular, así que el giro que la
	# restricción no fija (el roll alrededor del eje entre las dos manos) queda frenado, no libre.
	var ang_accel := axis * angle * (omega * omega) - (body.angular_velocity - following) * (2.0 * omega)

	var state := PhysicsServer3D.body_get_direct_state(body.get_rid())
	if state == null:
		return
	var inv_inertia := state.inverse_inertia_tensor
	if is_zero_approx(inv_inertia.determinant()):
		return  # ejes bloqueados / inercia degenerada: sin torque
	var torque := inv_inertia.inverse() * ang_accel  # τ = I·α
	body.apply_torque(torque.limit_length(total_strength() * TORQUE_PER_STRENGTH))

## Rotación que falta aplicarle al cuerpo: siempre la que alinea un eje del cuerpo con un eje que
## definen los agarres. El giro que la restricción no fija queda amortiguado, no libre.
func _orientation_error(body: RigidBody3D) -> Quaternion:
	var basis := body.global_transform.basis.orthonormalized()

	# Una sola mano: el eje centro→grab point apunta de vuelta al pecho, así que la parte que
	# agarraste te queda de frente y el resto del objeto se extiende para el otro lado. Una caja: su
	# cara, de frente y derecha (ver LA CAJA SE AGARRA POR UNA CARA).
	if _holds.size() < 2:
		var only: Dictionary = _holds.values()[0]
		var toward := (only["origin"] as Vector3) - (only["target"] as Vector3)
		# EL GIRO DE QUIEN LO LLEVA (ver GIRAR LO QUE SE LLEVA): las caras se eligen sin él, y se le suma al final.
		var unturned := Basis(_turn_now.inverse()) * basis
		if box_half != Vector3.ZERO:
			var facing := _facing_upright(unturned, face_of(only["held"] as Vector3, box_half), toward)
			var carried := _sagged(facing, unturned, only) if LocomotionCommon.base().long_alone_sags else facing
			return _with_turn(only, carried, basis, unturned)
		return _swing(basis * (only["held"] as Vector3), toward)

	_turn_now = Quaternion.IDENTITY
	var a: Dictionary = {}
	var b: Dictionary = {}
	var best := -1.0
	var vals := _holds.values()
	for i in range(vals.size()):
		for j in range(i + 1, vals.size()):
			var d: float = ((vals[i]["held"] as Vector3) - (vals[j]["held"] as Vector3)).length_squared()
			if d > best:
				best = d
				a = vals[i]
				b = vals[j]
	var between := (b["held"] as Vector3) - (a["held"] as Vector3)
	var to_axis := (b["target"] as Vector3) - (a["target"] as Vector3)
	if box_half != Vector3.ZERO and absf(to_axis.normalized().dot(Vector3.UP)) < 0.9:
		# UNA CAJA VA A NIVEL también entre dos (ver LA CAJA SE AGARRA POR UNA CARA): el eje entre las manos, acostado
		# —en la caja, sin lo que va a lo alto; en el mundo, sin la diferencia de altura de las manos—. Si no, dos de
		# alturas distintas, o dos puntos de filas distintas, la inclinaban.
		var up_local := _up_axis(basis, between)
		between -= up_local * between.dot(up_local)
		to_axis.y = 0.0
	var swing := _swing(basis * between, to_axis)
	if box_half == Vector3.ZERO or to_axis.length_squared() < 0.0001:
		return swing
	# DERECHA ALREDEDOR DEL EJE DE LAS MANOS (ver LA CAJA SE AGARRA POR UNA CARA): si el eje no es casi vertical.
	var axis := to_axis.normalized()
	if absf(axis.dot(Vector3.UP)) > 0.9:
		return swing
	var up_now := Basis(swing) * (basis * _up_axis(basis, between))
	var from_flat := up_now - axis * up_now.dot(axis)
	var to_flat := Vector3.UP - axis * axis.y
	if from_flat.length_squared() < 0.0001 or to_flat.length_squared() < 0.0001:
		return swing
	return Quaternion(axis, from_flat.normalized().signed_angle_to(to_flat.normalized(), axis)) * swing


## El error de orientación con el giro de `h` encima (ver GIRAR LO QUE SE LLEVA): `err` lleva de `unturned` (la caja sin
## el giro de este cuadro) a como se la llevaría; a eso se le suma el giro, y se mide desde como está (`basis`).
func _with_turn(h: Dictionary, err: Quaternion, basis: Basis, unturned: Basis) -> Quaternion:
	var turn: Vector2 = h.get("turn", Vector2.ZERO)
	if turn == Vector2.ZERO:
		_turn_now = Quaternion.IDENTITY
		_has_turn_base = false
		return (err * unturned.get_rotation_quaternion() * basis.get_rotation_quaternion().inverse()).normalized()
	var ahead := (h["target"] as Vector3) - (h["origin"] as Vector3)
	ahead.y = 0.0
	var heading := atan2(ahead.x, ahead.z) if ahead.length_squared() > 0.0001 else 0.0
	# LA FOTO DE CÓMO LA LLEVABA al empezar a girarla, y el giro encima; la foto sólo acompaña el rumbo de quien la lleva.
	# *Antes se recalculaba cada cuadro desde cómo estaba la caja: atrasada, el objetivo se movía con ella y algunas no
	# paraban nunca de girar.*
	if not _has_turn_base:
		_turn_base = (err * unturned.get_rotation_quaternion()).normalized()
		_turn_base_heading = heading
		_has_turn_base = true
	var follow := Quaternion(Vector3.UP, angle_difference(_turn_base_heading, heading))
	var right := ahead.cross(Vector3.UP).normalized() if ahead.length_squared() > 0.0001 else Vector3.RIGHT
	var spin := (Quaternion(Vector3.UP, -turn.x) * Quaternion(right, turn.y)).normalized()
	_turn_now = spin
	var goal := spin * follow * _turn_base
	return (goal * basis.get_rotation_quaternion().inverse()).normalized()


## La foto de la orientación de cuando empezó a girarla (ver `_with_turn`), y el rumbo de quien la llevaba entonces.
var _turn_base := Quaternion.IDENTITY
var _turn_base_heading := 0.0
var _has_turn_base := false


## ── SE VENCE (ver LocomotionCommon.long_alone_sags) ──────────────────────────────────────────────────────────────────────
## Lo que el peso le gana a la fuerza: el torque del peso —la masa por g por la distancia horizontal de la mano al
## centro— contra el que puede hacer quien lo lleva (`strength` × TORQUE_PER_STRENGTH). De 0 a 1.
func sag_share(body: RigidBody3D, h: Dictionary) -> float:
	var lever := global_transform.basis * (h["held"] as Vector3)
	lever.y = 0.0
	var capacity := maxf((h["strength"] as float) * TORQUE_PER_STRENGTH, 0.01)
	return clampf(body.mass * 9.8 * lever.length() / capacity, 0.0, 1.0)


## La caja de una mano, vencida: la punta libre baja `sag_share × sag_max_deg`, girando sobre el eje horizontal que cruza
## de la mano al centro.
func _sagged(facing: Quaternion, _basis: Basis, h: Dictionary) -> Quaternion:
	var body := get_parent() as RigidBody3D
	var lever := global_transform.basis * (h["held"] as Vector3)
	lever.y = 0.0
	if not is_instance_valid(body) or lever.length_squared() < 0.0001:
		return facing
	# La punta libre está del lado contrario a la mano: de la mano al centro es `-lever`.
	var axis := Vector3.UP.cross(-lever).normalized()
	var angle := deg_to_rad(LocomotionCommon.base().sag_max_deg) * sag_share(body, h)
	return Quaternion(axis, angle) * facing


## UNA MANO EN UNA CAJA: derecha —su eje que más mira arriba, arriba— y la cara `face` (local) de frente a `toward`,
## girando sólo alrededor de la vertical. Si la cara es la de arriba o la de abajo, sólo derecha.
func _facing_upright(basis: Basis, face: Vector3, toward: Vector3) -> Quaternion:
	var up_local := _up_axis(basis, Vector3.ZERO)
	var upright := _swing(basis * up_local, Vector3.UP)
	if absf(up_local.dot(face)) > 0.5:
		return upright
	var face_now := Basis(upright) * (basis * face)
	var flat_face := Vector3(face_now.x, 0.0, face_now.z)
	var flat_to := Vector3(toward.x, 0.0, toward.z)
	if flat_face.length_squared() < 0.0001 or flat_to.length_squared() < 0.0001:
		return upright
	return Quaternion(Vector3.UP, flat_face.normalized().signed_angle_to(flat_to.normalized(), Vector3.UP)) * upright


## El eje de la caja (local, con su signo) que más mira hacia arriba ahora, sin contar el que va a lo largo de `skip`.
static func _up_axis(basis: Basis, skip: Vector3) -> Vector3:
	var best := Vector3.UP
	var best_dot := -INF
	for axis: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		if skip != Vector3.ZERO and absf(axis.dot(skip.normalized())) > 0.7:
			continue
		var d := (basis * axis).dot(Vector3.UP)
		if absf(d) > best_dot:
			best_dot = absf(d)
			best = axis * signf(d) if d != 0.0 else axis
	return best


## LA CARA DE UNA CAJA en la que está `local` (un punto de su superficie, en sus ejes): la normal de afuera, un eje con
## su signo. `half`, la mitad de la caja.
static func face_of(local: Vector3, half: Vector3) -> Vector3:
	var r := Vector3(absf(local.x) / maxf(half.x, 0.001), absf(local.y) / maxf(half.y, 0.001),
		absf(local.z) / maxf(half.z, 0.001))
	if r.x >= r.y and r.x >= r.z:
		return Vector3(signf(local.x), 0.0, 0.0)
	if r.y >= r.z:
		return Vector3(0.0, signf(local.y), 0.0)
	return Vector3(0.0, 0.0, signf(local.z))


## LOS GOLPES DEL CUADRO (ver LOS GOLPES A LO QUE SE LLEVA). El monitor de contactos es lo que hace que el estado traiga
## los impulsos; se prende la primera vez.
func _feel_hits(body: RigidBody3D) -> void:
	if not body.contact_monitor:
		body.contact_monitor = true
		body.max_contacts_reported = maxi(body.max_contacts_reported, 4)
		return
	var state := PhysicsServer3D.body_get_direct_state(body.get_rid())
	if state == null:
		return
	# SÓLO LO QUE PEGA DE COSTADO: un contacto de piso o de techo (normal casi vertical) no es un golpe —la caja
	# llevada baja que roza el piso daba un «golpe» por cuadro—.
	var impulse := Vector3.ZERO
	for i in state.get_contact_count():
		if absf(state.get_contact_local_normal(i).y) > SIDE_CONTACT:
			continue
		impulse += state.get_contact_impulse(i)
	if impulse.length() / maxf(body.mass, 0.01) < STRUCK_MIN_DV:
		return
	var now := Time.get_ticks_msec()
	if now - _struck_at < STRUCK_COOLDOWN_MS:
		return
	_struck_at = now
	struck.emit(impulse)

## Rotación mínima que lleva `from_axis` sobre `to_axis`. Identidad si alguno es degenerado (agarre
## justo en el centro del cuerpo, o dos manos en el mismo punto): ahí no hay eje que definir y la
## orientación queda sólo amortiguada.
func _swing(from_axis: Vector3, to_axis: Vector3) -> Quaternion:
	if from_axis.length_squared() < 0.0001 or to_axis.length_squared() < 0.0001:
		return Quaternion.IDENTITY
	return Quaternion(from_axis.normalized(), to_axis.normalized())

## EL MARCO DE LO AGARRADO (el usuario, 2/11/2026: «tiene que tener en cuenta cómo anular la inercia de la nave. No
## anularla, pero hacerla relativa… que funcione así bien ese PD controller mientras está en la meca»): la velocidad, en
## `point`, de aquello en lo que va el cuerpo —a bordo, la meca—, y su giro. El PD frena la velocidad RELATIVA a eso: con
## la meca a velocidad constante, llevar algo es como en tierra; cuando acelera o dobla, se atrasa lo que la fuerza de las
## manos no alcanza a compensar (la inercia, relativa). El marco del cuerpo es el suyo (ver MotionFrame); si no va
## adentro de nada, es el mundo y da cero, como siempre.
static func frame_velocity(body: Node, point: Vector3) -> Vector3:
	var frame := MotionFrame.frame_of(body)
	return frame.velocity_at(point) if frame != null else Vector3.ZERO


static func frame_spin(body: Node) -> Vector3:
	var frame := MotionFrame.frame_of(body)
	return frame.spin() if frame != null else Vector3.ZERO

## La `strength` sumada de las manos que lo sostienen. En red sólo la conoce quien simula el cuerpo: en
## las otras máquinas no hay manos registradas y da 0.
func total_strength() -> float:
	var total := 0.0
	for h in _holds.values():
		total += h["strength"] as float
	return total

## ADÓNDE VA LO QUE SE LLEVA mirando hacia `look` (ver LO QUE SE LLEVA VA UN POCO ABAJO DE LA MIRADA).
static func held_aim(look: Vector3) -> Vector3:
	var dir := look.normalized()
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length_squared() < 0.000001:
		return dir
	var tuning := LocomotionCommon.base()
	var pitch := asin(clampf(dir.y, -1.0, 1.0))
	var fade := 1.0 if pitch >= 0.0 else clampf(1.0 + pitch / deg_to_rad(tuning.hold_drop_fade_deg), 0.0, 1.0)
	var aimed := maxf(pitch - deg_to_rad(tuning.hold_drop_deg) * fade, -PI * 0.49)
	return flat.normalized() * cos(aimed) + Vector3.UP * sin(aimed)


## EL CONO DE LO QUE LLEVA `body` ahora, en grados (ver EL CONO DE LO QUE SE LLEVA).
static func carry_cone_deg(body: Node) -> float:
	var lean := 0.0
	if body is CharacterRigidBody3D:
		var rb := body as CharacterRigidBody3D
		lean = clampf(rb.impact_xz.length() / maxf(rb.ragdoll_threshold, 0.01), 0.0, 1.0)
	return LocomotionCommon.base().carry_cone_deg * lerpf(1.0, LocomotionCommon.base().carry_cone_at_fall, lean)


## LO QUE TIENE QUE QUEDAR EN EL CONO de la mano `key` (ver EL CONO DE LO QUE SE LLEVA): de una caja, su centro —el punto
## por donde se la lleva está al ras del pecho, y a esa distancia cualquier diferencia de altura era un ángulo grande y
## se soltaba caminando—; de lo demás, por donde se lo lleva. INF MIENTRAS NO LLEGÓ A LA MANO (`ARRIVED`): levantándola
## del piso no cuenta —al flaco alto, mirando adelante, la caja en el piso le quedaba fuera y la soltaba en el acto—.
func cone_point(key: int) -> Vector3:
	if not _holds.has(key) or not bool((_holds[key] as Dictionary)["arrived"]):
		return Vector3.INF
	if box_half != Vector3.ZERO and get_parent() is Node3D:
		return (get_parent() as Node3D).global_position
	return held_world(key)


## SI `point` QUEDÓ FUERA DEL CONO de quien mira hacia `look` desde `origin` (ver EL CONO DE LO QUE SE LLEVA).
static func outside_carry_cone(body: Node, origin: Vector3, look: Vector3, point: Vector3) -> bool:
	var to := point - origin
	if to.length() <= 0.001:
		return false
	return to.normalized().dot(look.normalized()) < cos(deg_to_rad(carry_cone_deg(body)))


## LO QUE LE LLEGA A `holder` de un golpe de `impulse` a lo que lleva (ver LOS GOLPES A LO QUE SE LLEVA).
static func strike_holder(holder: Node, impulse: Vector3) -> void:
	if holder is CharacterRigidBody3D:
		var rb := holder as CharacterRigidBody3D
		rb.strike(impulse / maxf(rb.mass, 0.01) * STRUCK_SHARE)


## QUE LO QUE SE LLEVA NO CHOQUE CON QUIEN LO LLEVA (`on`), o que vuelva a chocar: ni con su cápsula ni con los cuerpos
## de sus huesos (BoneInstantiator.skel_rigidbodies) —las piernas animadas la pateaban a cada paso, y cada patada era
## un golpe a lo que lleva—. Lo que lo frena contra el cuerpo es EL TOPE DEL PECHO.
static func ignore_holder(body: Node, holder: Node, on: bool) -> void:
	if not is_instance_valid(body) or not is_instance_valid(holder) or not (body is PhysicsBody3D):
		return
	var others: Array[PhysicsBody3D] = []
	if holder is PhysicsBody3D:
		others.append(holder as PhysicsBody3D)
	var bi := holder.get_parent() as BoneInstantiator
	if is_instance_valid(bi) and is_instance_valid(bi.skel_rigidbodies):
		for bone in bi.skel_rigidbodies.get_children():
			if bone is PhysicsBody3D:
				others.append(bone as PhysicsBody3D)
	for other in others:
		if on:
			(body as PhysicsBody3D).add_collision_exception_with(other)
		else:
			(body as PhysicsBody3D).remove_collision_exception_with(other)


## LA CARGA de un peso contra una fuerza (ver «Lo que pesa se nota en la lentitud»): 1 = justo la fuerza.
## La usan el agarrador para frenarse y el panel de la fila Paquetes.
static func load_of(mass: float, strength: float) -> float:
	return mass * 9.8 / maxf(strength * FORCE_PER_STRENGTH, 0.001)

## CUÁNTO DE SU VELOCIDAD le queda a quien lleva esa carga: el peso divide la velocidad, la de caminar y la
## del sprint por igual. Una carga de 1 deja el 59 %; el pibe solo con la caja fuerte (3,06), un cuarto.
static func carry_speed_factor(carry_load: float) -> float:
	return 1.0 / (1.0 + maxf(carry_load, 0.0))

func add_grab_point_local(local_pos: Vector3) -> void:
	var pt := Node3D.new()
	pt.position = local_pos
	add_child(pt)
	grab_points.append(pt)

func get_nearest_grab_point(world_pos: Vector3) -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for pt in grab_points:
		if not is_instance_valid(pt):
			continue
		var d := pt.global_position.distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best = pt
	return best

func setup_from_cells(cells_x: int, cells_y: int, cells_z: int) -> void:
	var sx := cells_x * CELL_SIZE
	var sy := cells_y * CELL_SIZE
	var sz := cells_z * CELL_SIZE
	box_half = Vector3(sx, sy, sz) * 0.5
	modules = Vector3i(maxi(1, roundi(sx / MODULE)), maxi(1, roundi(sy / MODULE)), maxi(1, roundi(sz / MODULE)))
	_generate_grab_points(cells_x, cells_y, cells_z, sx, sy, sz)
	_generate_handle_points(cells_x, cells_y, cells_z, sx, sy, sz)

## Ver `offers_grab`. `CharacterGrabbable` lo encadena con su propia regla (no se agarra a un caído).
func can_interact() -> bool:
	return offers_grab

## El grabbable cuelga del cuerpo que representa; se contornea el objeto entero, no el grabbable
## (que solo contiene puntos de grab/handle, no la malla visible).
func get_outline_targets() -> Array[Node]:
	var parent := get_parent()
	var targets: Array[Node] = [parent if is_instance_valid(parent) else self]
	return targets

## LOS PUNTOS DE AGARRE Y LOS DE LAS MANOS, LOS MISMOS: el centro de la cara de cada módulo (ver LOS PAQUETES SON
## MÓDULOS).
func _generate_grab_points(_cx: int, _cy: int, _cz: int, sx: float, sy: float, sz: float) -> void:
	for pos in module_faces(sx, sy, sz, modules):
		add_grab_point_local(pos)

func _generate_handle_points(_cx: int, _cy: int, _cz: int, sx: float, sy: float, sz: float) -> void:
	for pos in module_faces(sx, sy, sz, modules):
		add_handle_point_local(pos)

## EL CENTRO DE LA CARA DE CADA MÓDULO de una caja de `sx`×`sy`×`sz` m con `count` módulos por lado, en sus ejes.
static func module_faces(sx: float, sy: float, sz: float, count: Vector3i) -> PackedVector3Array:
	var out := PackedVector3Array()
	var faces: Array = [
		[ sx * 0.5, count.y, count.z, sy, sz, 0],
		[-sx * 0.5, count.y, count.z, sy, sz, 0],
		[ sy * 0.5, count.x, count.z, sx, sz, 1],
		[-sy * 0.5, count.x, count.z, sx, sz, 1],
		[ sz * 0.5, count.x, count.y, sx, sy, 2],
		[-sz * 0.5, count.x, count.y, sx, sy, 2],
	]
	for face in faces:
		var fc: float  = face[0]
		var na: int    = face[1]
		var nb: int    = face[2]
		var sa: float  = face[3]
		var sb: float  = face[4]
		var axis: int  = face[5]
		for ia in na:
			for ib in nb:
				var pa  := -sa * 0.5 + (ia + 0.5) * sa / na
				var pb  := -sb * 0.5 + (ib + 0.5) * sb / nb
				var pos := Vector3.ZERO
				match axis:
					0: pos = Vector3(fc, pa, pb)
					1: pos = Vector3(pa, fc, pb)
					2: pos = Vector3(pa, pb, fc)
				out.append(pos)
	return out

## LAS ESFERAS DE LOS PUNTOS, anotadas para poder APAGARLAS sin volver a crearlas. `show_debug_points`
## las creaba de cero cada vez que se la llamaba, así que llamarla dos veces dejaba dos esferas por
## punto; la fila de paquetes del design sandbox las cicla, así que necesita prenderlas y apagarlas.
var _debug_points: Array[MeshInstance3D] = []


## Los puntos dibujados: cian los de agarre, amarillos los de mano. La primera vez los construye; de
## ahí en adelante solo los prende y los apaga.
func set_debug_points(on: bool) -> void:
	if on and _debug_points.is_empty():
		_build_debug_points()
	for sphere in _debug_points:
		if is_instance_valid(sphere):
			sphere.visible = on


func show_debug_points() -> void:
	set_debug_points(true)


func _build_debug_points() -> void:
	for pt in grab_points:
		if not is_instance_valid(pt):
			continue
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.03
		sphere.height = 0.06
		mi.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.CYAN
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.no_depth_test = true  # visibles atravesando el mesh
		mi.material_override = mat
		mi.set_meta("no_outline", true)  # nunca contornear los puntos de debug
		pt.add_child(mi)
		_debug_points.append(mi)

	for pt in handle_points:
		if not is_instance_valid(pt):
			continue
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.03
		sphere.height = 0.06
		mi.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.YELLOW
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.no_depth_test = true  # visibles atravesando el mesh
		mi.material_override = mat
		mi.set_meta("no_outline", true)  # nunca contornear los puntos de debug
		pt.add_child(mi)
		_debug_points.append(mi)
