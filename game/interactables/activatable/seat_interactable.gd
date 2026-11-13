@tool
class_name SeatInteractable
extends ActivatableInteractable

## ── ALTURA ──────────────────────────────────────────────────────────────────────────────────────
## La silla se acomoda al que se sienta: sube o baja hasta que el origen de SU rayo de interacción quede
## a `eye_height` sobre la base, la altura óptima para usar lo que tiene adelante. Así un tablero se ve
## y se alcanza igual con cualquier arquetipo. Sin nadie vuelve a la altura de un arquetipo medio (ver
## TYPICAL_EYE_ABOVE_PELVIS). Cada cambio es una transición corta, y el ocupante sube y baja con la silla
## porque la pose sentada lee `height` en cada frame. No viaja por red: cada máquina conoce el esqueleto de
## cada personaje y deriva la misma altura.
##
## ── CÓMO SE SIENTA: DE SUS CAJAS (02/11/2026) ──────────────────────────────────────────────────────────────────────
## El respaldo está quieto, pegado al asiento (ver ProceduralSeat). DOS NÚMEROS dicen cómo se sienta cada uno: cuánto
## arriba del asiento va su pelvis y cuánto adelante de la cara del respaldo. Eran a mano por arquetipo (29/10/2026),
## puestos mirando la malla de costado; con el cuerpo de cajas salen de su forma (BlockShape.seat_fit): la pelvis, un
## radio de pierna arriba —el fondo de la caja de la cadera apoya—, y la columna, media caja de torso adelante —la
## espalda apoya—. Así no se desajustan cuando cambian las proporciones (02/11/2026, el usuario: «cambiamos los
## personajes y sus siluetas… pero no ajustamos la distancia… para que encajen bien los arquetipos con su espalda en el
## respaldar»). Si las rodillas se pasan del borde, los pies se meten (ver knees_past_edge).
##
## ── EL RESPALDO SE RECLINA CON LA ESPALDA ──────────────────────────────────────────────────────────────────────────
## Sentado, el tronco se recuesta desde la pelvis: al mirar para arriba (BoneAnimations.SEATED_LOOK_UP_LEAN), con la
## inercia de la meca o con un golpe. El respaldo gira lo mismo —lo mide en el hueso (ver `_recline`)—, pero sobre SU
## ESQUINA, donde se junta con el asiento (29/10/2026, lo pidió el usuario: girando sobre la pelvis se descolocaba
## de la silla). Como los dos giran sobre puntos distintos, reclinada la espalda se separa un poco del respaldo: más cuanto
## más alto y adelante de la esquina va la pelvis (ver CÓMO SE SIENTA).

## Altura de la pelvis sobre la base con la silla a su altura de modelo. Es la referencia de la silla
## para estirar el pie, no la altura de la silla vacía.
@export var rest_height:       float       = 0.42
## LA MIRA DEL QUE SE SIENTA EN UNA CONSOLA, sobre la base de la silla (la cabina de la meca, la silla suelta del lote
## de recursos). Era la altura de ojos sentado de la nave de character-parametric.
const STATION_EYE_HEIGHT := 1.7
## A qué altura sobre la base tiene que quedar la mira del que se sienta. Las sillas de las consolas ponen
## `STATION_EYE_HEIGHT`; este default es para asientos sueltos.
@export var eye_height:        float       = 1.15
@export var seat_area:         Vector3     = Vector3(0.6, 0.5, 0.6)
@export var stand_up_location: Vector2     = Vector2(0.0, 1.2)
@export var seat_scene:        PackedScene = null
@export var show_debug:        bool        = false

## ── CUÁNTO SE AGRANDA LA SILLA QUE SE VE, para acompañar a un maniquí ampliado ───────────────────
## La fila de personajes del sandbox agranda a sus maniquíes REGENERÁNDOLOS (ver SkeletonSizesUtil.size_scale,
## y por qué un `scale` de nodo no les sirve), y para mirar una pierna sentada la silla tiene que acompañar:
## con una silla de tamaño real, un maniquí a ×5 se sienta en un banquito de juguete.
##
## ⚠ ESCALA LA GEOMETRÍA DEL VISUAL Y NO EL NODO DEL ASIENTO, y eso es la decisión: la lógica de este nodo
## está en METROS —la altura que deja la mira del ocupante a `eye_height`, dónde va su pelvis, el colisionador—
## y escalando el nodo esas cuentas se multiplicarían DOS veces. Así que lo único que se
## escala es lo que se dibuja, y lo que se le pide al visual se le pide en su propia escala (ver
## `_fit_visual`). Las medidas del asiento —`rest_height`, `seat_area`, `eye_height`— las escala quien lo
## coloca, porque son suyas y son metros.
var display_scale := 1.0

## Cuánto puede bajar y subir la silla respecto de su altura de modelo, en metros.
const MIN_LIFT := -0.2
const MAX_LIFT := 0.5
## Qué tan rápido llega a la altura nueva (1/s): con 8 está al 95 % en unos 0,4 s.
const LIFT_RATE := 8.0
## La mira sobre la pelvis de un arquetipo medio: medida, los arquetipos van de 0,61 (nene) a 0,79
## (gordo). Pone la altura de la silla vacía, a mitad de camino entre sus ocupantes posibles.
const TYPICAL_EYE_ABOVE_PELVIS := 0.70
## El fémur de un arquetipo medio (de 0,22 el gordo a 0,54 el flaco largo): dónde caen las rodillas con la silla vacía.
const TYPICAL_FEMUR := 0.37

## CÓMO SE SIENTA (ver CÓMO SE SIENTA): x, cuánto arriba de la cara del asiento va la pelvis; y, cuánto adelante de la
## cara del respaldo. En metros de un cuerpo sin agrandar. Éste es el de la silla vacía, y el de quien no tiene forma de
## cajas.
const DEFAULT_FIT := Vector2(0.12, 0.2)
## Cuánto sobresale la pantorrilla detrás de la rodilla: es lo que va contra el borde del asiento (ver knees_past_edge).
const CALF_BEHIND_KNEE := 0.06

## Altura ACTUAL de la pelvis sobre la base. Ver ALTURA.
var height := 0.0
var _visual_root:   Node3D      = null
var _body:          RigidBody3D = null
var _spawn_point:   Node3D      = null
var _seated_bi:     Node        = null
var _borrowed_mesh: Node3D      = null
## Transform de reposo del visual (sin ocupante), guardado al construirlo: es a donde vuelve solo.
var _visual_rest_local: Transform3D = Transform3D.IDENTITY
## Personaje que está posando este asiento EN ESTA MÁQUINA (lo registra update_seated_visual).
var _visual_occupant: Node = null
## Ocupación exclusiva (un solo jugador por asiento), arbitrada por el host. Ver ExclusiveClaim.
var _claim:         ExclusiveClaim = null

## ── ASIENTO SOBRE ALGO QUE SE MUEVE ─────────────────────────────────────────────────────────────
## Sentarse es una FOTO: `_sit` pone la cápsula en el asiento una vez y la deja inerte (collider
## apagado, Y bloqueada). La pose del esqueleto sí sigue al asiento cada frame, y
## `BoneInstantiator._pose_root` además fija la cápsula en X y Z — pero nada movía su ALTURA ni su
## rumbo. En un asiento fijo da igual; en la meca, al despegar el piloto quedaba colgando donde se
## sentó —y la cámara, que es hija de la cápsula, con él—, y al girar la meca seguía mirando al mismo
## punto del mundo mientras la cabina rotaba alrededor.
##
## Mover la cápsula acá es seguro justamente porque está inerte: con el collider apagado no tiene
## contactos, así que escribirle la posición no pelea con el motor de física.
##
## Corre en todas las máquinas desde el 03/11/2026 (una sola silla para todos: ver `sit`), pero a un compañero de red
## no lo lleva: su cápsula llega por red, ya movida.
var _occupant_y_offset := 0.0
## Para quién están puestas las dos de abajo, así no se recalculan cada frame.
var _lift_occupant: Node = null
## La mira sobre la pelvis del que está sentado, y cómo se sienta (ver CÓMO SE SIENTA).
var _occupant_eye := TYPICAL_EYE_ABOVE_PELVIS
var _fit := DEFAULT_FIT

func _ready() -> void:
	height = typical_height()  # nace ya a su altura, sin acomodarse al aparecer
	if Engine.is_editor_hint():
		_build_visual()
		return
	_build_visual()
	_build_collider()
	_build_spawn_point()
	_claim = ExclusiveClaim.new()
	_claim.name = "Claim"  # nombre estable → mismo path en todas las máquinas
	add_child(_claim)
	_claim.granted.connect(_on_claim_granted)
	_claim.released.connect(_on_claim_released)

func _build_visual() -> void:
	if not is_instance_valid(seat_scene):
		return
	_visual_root = _instantiate_visual()
	add_child(_visual_root)
	_visual_rest_local = _visual_root.transform

## Una copia del visual de la silla, ya enterada de a qué altura se sienta la pelvis en reposo. Pasa por
## acá y no por `seat_scene.instantiate()` suelto porque hay DOS copias —la de la silla y la prestada que
## cuelga del ocupante (ver _sit)— y las dos tienen que nacer iguales.
func _instantiate_visual() -> Node3D:
	var visual := seat_scene.instantiate() as Node3D
	var seat := visual as ProceduralSeat
	if seat != null:
		# En la escala del visual, igual que todo lo demás que se le pasa (ver `_fit_visual`).
		seat.rest_pelvis_height = rest_height / _scale()
	return visual

func _build_collider() -> void:
	_body                 = RigidBody3D.new()
	_body.freeze_mode     = RigidBody3D.FREEZE_MODE_KINEMATIC
	_body.freeze          = true
	_body.collision_layer = 1
	_body.collision_mask  = 0
	_body.position.y      = seat_area.y * 0.5

	var shape  := CollisionShape3D.new()
	var box    := BoxShape3D.new()
	box.size   = seat_area
	shape.shape = box
	_body.add_child(shape)

	if show_debug:
		var dbg_mesh               := MeshInstance3D.new()
		dbg_mesh.set_meta("no_outline", true)
		var box_mesh               := BoxMesh.new()
		box_mesh.size              = seat_area
		dbg_mesh.mesh              = box_mesh
		var mat                    := StandardMaterial3D.new()
		mat.albedo_color           = Color(0.2, 0.8, 1.0, 0.15)
		mat.transparency           = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode              = BaseMaterial3D.CULL_DISABLED
		dbg_mesh.material_override = mat
		_body.add_child(dbg_mesh)

	add_child(_body)
	add_handle_point_local(Vector3(0.0, rest_height + seat_area.y * 0.5, 0.0))

## DÓNDE SE PARA QUIEN SE LEVANTA, en el plano del asiento (x, z desde su base); lo mueve también si ya está armado
## (ver ShipKits.build: hacia la cola de la nave).
func set_stand_up_location(at: Vector2) -> void:
	stand_up_location = at
	if is_instance_valid(_spawn_point):
		_spawn_point.position = Vector3(at.x, 0.0, at.y)


func _build_spawn_point() -> void:
	_spawn_point = Node3D.new()
	_spawn_point.position = Vector3(stand_up_location.x, 0.0, stand_up_location.y)
	add_child(_spawn_point)

	if show_debug:
		var dbg          := MeshInstance3D.new()
		dbg.set_meta("no_outline", true)
		var sphere       := SphereMesh.new()
		sphere.radius    = 0.12
		sphere.height    = 0.24
		dbg.mesh         = sphere
		var mat          := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.4, 0.0, 0.6)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dbg.material_override = mat
		_spawn_point.add_child(dbg)

func can_interact() -> bool:
	return _claim == null or _claim.is_free() or _claim.is_mine()

func activate(actor: Node = null) -> void:
	if not is_instance_valid(actor) or _claim == null:
		return
	if _claim.is_mine():
		_claim.release()      # ya estoy sentado → pararme
	elif _claim.is_free():
		_claim.request()      # libre → sentarme (offline concede al toque; online arbitra el host)
	# ocupado por otro → nada (can_interact ya lo bloquea)

## El asiento pasó a ser mío: sentar al jugador local (en las demás máquinas es un proxy y el pose
## llega aparte por su intención: ver BoneInstantiator._follow_seat).
func _on_claim_granted(_peer: int) -> void:
	if not _claim.is_mine():
		return
	var local := _local_player()
	if is_instance_valid(local):
		_sit(local)

## El asiento se liberó: si yo era el ocupante, pararme. Sólo el jugador de esta máquina: al compañero de red lo para su
## intención, cuando llega por red (ver BoneInstantiator._follow_seat).
func _on_claim_released() -> void:
	if is_instance_valid(_seated_bi) and _is_local(_seated_bi):
		_stand_up()


static func _is_local(bi: Node) -> bool:
	var kind: CharacterKind = bi.get("kind")
	return kind != null and kind.is_local()


## ── UNA SOLA SILLA PARA TODOS (03/11/2026) ──────────────────────────────────────────────────────────────────────────
## Al jugador de esta máquina lo sienta el host (ver `activate`, el claim); a todos los demás —el compañero de red, el de
## exhibición, una figura—, su intención (ver BoneInstantiator._follow_seat), por acá: el mismo `_sit` y el mismo
## `_release_occupant`, sin claim que pedir. Devuelve false si el asiento ya está tomado por otro que no se va (ver
## `_evict_display_occupant`).
func sit(bi: Node) -> bool:
	if is_instance_valid(_seated_bi) and _seated_bi != bi and not _is_exhibit(_seated_bi):
		return false
	_sit(bi)
	return true


## Lo para en el lugar, si estaba sentado acá.
func release(bi: Node) -> void:
	if _seated_bi == bi:
		_release_occupant(false, false)


static func _is_exhibit(bi: Node) -> bool:
	var kind: CharacterKind = bi.get("kind")
	return kind != null and kind.is_exhibit()

func _local_player() -> Node:
	var spawner := get_tree().get_first_node_in_group("character_spawner")
	return spawner.get("local_player") if is_instance_valid(spawner) else null

## Saca al ocupante EN EL LUGAR (sin teleport al spawn point): libera localmente ya —sincrónico, sin
## esperar el round-trip del host— y avisa a los proxies. Lo usan los cambios de estado que la cápsula
## sentada no soporta y que necesitan el asiento libre ANTES de seguir: el respawn (reconstruye el
## esqueleto) y el ragdoll (ver PlayerController._leave_seat_in_place).
func release_occupant_in_place() -> void:
	if not is_instance_valid(_seated_bi):
		return
	# PRIMERO SE SUELTA ACÁ, DESPUÉS EL HOST: sin red el claim avisa en el acto (`_on_claim_released`), y con el
	# ocupante todavía puesto lo paraba con teleport, diferido al final del cuadro —al lugar de pararse de la silla—,
	# después de que quien lo soltaba ya lo había ubicado. Medido por la meca: el ente que bajaba de la meca de la
	# maqueta aparecía donde estaba la meca, a 1160 m, cayendo.
	_release_occupant(false, true)  # revert local ya, sin teleport pero avisando a los proxies
	if is_instance_valid(_claim):
		_claim.release()          # que el host libere la ocupación (async, no importa el orden)

# ── Visual: función de la ocupación, no efecto de los eventos ─────────────────
# Girar con el ocupante y volver al reposo se DERIVAN cada frame de quién ocupa el asiento,
# revalidado contra el estado vivo del personaje. No salen de los eventos de sentarse/pararse porque
# esos solo corren en la máquina del ocupante (_seated_bi solo lo setea _sit): en un proxy el visual
# se rotaba y nadie lo devolvía nunca, así que quedaba congelado en el último yaw al pararse. Con la
# derivación no hay ninguna salida —pararse, ragdollear, despawn del personaje, desconexión— que haya
# que acordarse de limpiar: dejan de cumplir la condición y el asiento se acomoda solo.

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# EL OCUPANTE QUE SE BORRÓ SIN PARARSE (una parcela que se rearma, un despawn): la silla queda libre y vuelve a su
	# reposo. Sin esto seguía creyéndolo sentado, con la copia prestada ya borrada.
	if _seated_bi != null and not is_instance_valid(_seated_bi):
		_seated_bi = null
		_borrowed_mesh = null
		_fit_station(null)
		if is_instance_valid(_visual_root):
			_visual_root.visible = true
	_carry_occupant()
	# LA VALIDEZ SE PREGUNTA ANTES DE LLAMAR: `_is_occupied_by` la chequea adentro, pero pasarle un nodo YA
	# LIBERADO falla en el tipo del argumento y el error salta antes de entrar (ver arriba, el maniquí
	# echado). Un ocupante registrado puede desaparecer sin pararse —despawn, respawn, el cuerpo prestado
	# del sandbox—, así que la pregunta tiene que soportar que no esté.
	if not is_instance_valid(_visual_occupant) or not _is_occupied_by(_visual_occupant):
		_visual_occupant = null
		_restore_rest_visual()
	_update_height(delta)

## Lleva la silla a la altura de su ocupante, o a la de reposo si no hay nadie. Ver ALTURA.
func _update_height(delta: float) -> void:
	if _visual_occupant != _lift_occupant:
		_lift_occupant = _visual_occupant
		_measure_occupant(_visual_occupant)
	height = lerpf(height, _height_for(_occupant_eye), 1.0 - exp(-LIFT_RATE * delta))
	# LA COPIA PRESTADA CUELGA DE LA CÁPSULA DEL OCUPANTE, que no es nuestra: si a él se la borran
	# —reconstruir el esqueleto crea una cápsula nueva—, acá queda un puntero a un nodo muerto. Se
	# revalida como `_visual_occupant`, por la misma razón (ver el bloque de arriba): es estado que
	# depende de otro, así que se deriva y no se recuerda.
	#
	# ⚠ Y HAY QUE HACERLO ANTES DE LA LLAMADA: pasar un nodo liberado a un parámetro tipado es un error
	# en el pasaje del argumento, y adentro no hay `is_instance_valid` que llegue a tiempo.
	# (`is_instance_valid` y no `!= null`: un nodo ya liberado no siempre compara igual a null.)
	if not is_instance_valid(_borrowed_mesh):
		_borrowed_mesh = null
	_fit_visual(_visual_root)
	_fit_visual(_borrowed_mesh)

## LA ALTURA DE LA PELVIS YA ASENTADA: a la que va la silla con quien está sentado, sin el acomodo (ver ALTURA). La lee la
## cámara, que no baja mientras la silla se acomoda.
func settled_height() -> float:
	return _height_for(_occupant_eye)


## LO DEL QUE SE SENTÓ, o lo de un arquetipo medio si no hay nadie: la mira sobre la pelvis y cómo se sienta. Se toma UNA
## VEZ, cuando cambia quién ocupa la silla.
func _measure_occupant(who: Node) -> void:
	var bones: CustomBonesUtil = who.get("custom_bones_util") if is_instance_valid(who) else null
	_occupant_eye = bones.rest_eye_above_pelvis() if bones != null else TYPICAL_EYE_ABOVE_PELVIS
	var sizes: SkeletonSizesUtil = who.get("skel_sizes_util") if is_instance_valid(who) else null
	_fit = sizes.block_shape.seat_fit() if sizes != null and sizes.block_shape != null else DEFAULT_FIT

## CUÁNTO ATRÁS DEL EJE DE LA COLUMNA va la pelvis: la cara del respaldo menos lo que el que se sienta va adelante de ella
## (ver CÓMO SE SIENTA). En metros del mundo.
func pelvis_back_of_centre() -> float:
	return (ProceduralSeat.BACK_FACE - _fit.y) * _scale()

## CUÁNTO SE PASAN LAS RODILLAS del borde de adelante del asiento, con un fémur de `femur` metros: la pantorrilla, que
## cuelga detrás de la rodilla, no tiene que atravesar el borde. Con esto la pose mete los pies (ver
## BoneInstantiator._pose_legs_seated).
func knees_past_edge(femur: float) -> float:
	return femur - pelvis_back_of_centre() - (ProceduralSeat.FRONT + CALF_BEHIND_KNEE) * _scale()

## Hasta dónde llegan las rodillas de un arquetipo medio, desde el eje de la columna: con eso la meca planea el lugar para
## las rodillas bajo la consola (ver StationSeat.from_hinge).
func typical_knee_reach() -> float:
	return (TYPICAL_FEMUR - ProceduralSeat.BACK_FACE + DEFAULT_FIT.y) * _scale()

func _scale() -> float:
	return maxf(display_scale, 0.01)

## EL RUMBO DE LA SILLA EN EL MUNDO: hacia dónde mira su frente, sobre el plano horizontal. Es lo que necesita quien
## sigue derecho en el mundo —la cápsula del jugador y su cámara—, y no `global_rotation.y`: con la meca cabeceando o
## rolando, ese ángulo de Euler mezcla los tres giros y deja de ser el rumbo.
func heading() -> float:
	var front := -global_basis.z
	return atan2(-front.x, -front.z)

## Altura de la silla vacía: la de un arquetipo medio. Con ella planea quien arma el asiento, por ejemplo
## el lugar para las rodillas.
func typical_height() -> float:
	return _height_for(TYPICAL_EYE_ABOVE_PELVIS)

## La altura de pelvis que deja la mira a `eye_height`, dentro de lo que la silla puede estirarse.
func _height_for(eye_above_pelvis: float) -> float:
	return clampf(eye_height - eye_above_pelvis, rest_height + MIN_LIFT, rest_height + MAX_LIFT)

## Le pasa a la silla que se ve cómo tiene que quedar, EN SU PROPIA ESCALA (ver `display_scale`): el asiento bajo la pelvis
## y el respaldo reclinado (ver EL RESPALDO SE RECLINA CON LA ESPALDA).
func _fit_visual(visual: Node3D) -> void:
	var seat := visual as ProceduralSeat
	if not is_instance_valid(seat):
		return
	var factor := _scale()
	seat.scale = Vector3.ONE * factor
	seat.set_pose(height / factor - _fit.x, _recline())

## LO QUE SE RECUESTA EL TRONCO del que está sentado, en este cuadro, MEDIDO EN SU HUESO: el giro hacia atrás de la base
## de la columna respecto de su reposo, sea por qué sea —mirar para arriba, la inercia de la nave, un golpe— (02/11/2026,
## el usuario: «no quiero agregar una regla más a ese sistema, sino que quiero hacerlo más robusto»). Hacia
## adelante no: el respaldo se queda y la espalda se despega.
func _recline() -> float:
	if not is_instance_valid(_visual_occupant):
		return 0.0
	var bones: CustomBonesUtil = _visual_occupant.get("custom_bones_util")
	if bones == null or not is_instance_valid(bones.lower_spine):
		return 0.0
	var spine := bones.lower_spine
	var rest := spine.posture * spine.rest_transform.basis
	return maxf(0.0, (rest.inverse() * spine.transform.basis).get_euler().x)


## Lleva al ocupante con el asiento. Ver ASIENTO SOBRE ALGO QUE SE MUEVE.
##
## AL QUE SE SIMULA (el jugador), la altura, SOBRE EL ARRIBA DEL ASIENTO —no la vertical del mundo: con la meca cabeceando
## o ladeada, la altura del mundo lo corría de la silla (ver BoneInstantiator, LOS EJES DE LA SILLA)—. Su rumbo lo lleva
## su mirada, que va en los ejes del marco y viaja sola con la meca (ver CharacterIntent).
##
## AL QUE NO SE SIMULA NI LLEGA POR RED (uno de exhibición, una figura), EL TRANSFORM ENTERO, derivado del asiento:
## "la altura del asiento en el mundo" sólo es donde está el asiento MIENTRAS LA NAVE ESTÁ DERECHA; volcada, la
## corrección lo tiraba a un punto que ya no es la silla (medido: las cuatro cápsulas se iban entre 1,25 y 2,02 m, el
## cuerpo se despegaba del asiento y salía de la cabina). GIRADO CON LA SILLA lo que su mirada se aparte del frente de
## la silla: mirar a un costado es girar entero, la silla con él, como un jugador (ver characters.md, Where you look is
## the whole body). Su cápsula está estática y fuera de toda capa, así que esto es una escritura de transform y nada más.
func _carry_occupant() -> void:
	if not is_instance_valid(_seated_bi):
		return
	var char_rb := _seated_bi.get("char_rigidbody") as CharacterRigidBody3D
	if not is_instance_valid(char_rb):
		return
	if char_rb.kind.simulates():
		char_rb.global_position = global_position + global_basis.y.normalized() * _occupant_y_offset
		return
	if not char_rb.kind.is_exhibit():
		return
	var intent: CharacterIntent = _seated_bi.get("intent")
	var turn := angle_difference(CharacterIntent.yaw_of(char_rb.frame, -global_basis.z), intent.look_yaw) \
		if intent != null else 0.0
	var lift := Transform3D(Basis(Vector3.UP, turn), Vector3(0.0, _occupant_y_offset, 0.0))
	char_rb.global_transform = global_transform.orthonormalized() * lift


## ¿Este personaje sigue realmente sentado acá? Es la MISMA condición que el gate del solve de pose
## (BoneInstantiator._solve_frame), así que el visual y el pose no pueden discrepar. Ragdollear cuenta
## como NO sentado: la cápsula deja de mandar el pose y el asiento no tiene a quién seguir. Eso lo
## cubre además en el orden en que llegan las dos novedades a un proxy (el asiento libre viaja por RPC
## confiable y el flag de ragdoll en el estado por tick), sin importar cuál gane.
func _is_occupied_by(bi: Node) -> bool:
	if not is_instance_valid(bi):
		return false
	if bi.get("current_seat") != self or not bi.get("is_seated"):
		return false
	var rd = bi.get("ragdoll_util")
	return not (is_instance_valid(rd) and (rd.is_active or rd.is_recovering))

func _restore_rest_visual() -> void:
	if not is_instance_valid(_visual_root):
		return
	_visual_root.transform = _visual_rest_local
	if not is_instance_valid(_borrowed_mesh):
		_visual_root.visible = true  # sin malla prestada, nadie lo está reemplazando

## El asiento gira con el ocupante (mismo yaw) — sin sincronizar nada extra: el yaw ya viaja en el
## transform del personaje. Owner: la malla prestada (hija de la cápsula, para esconderse en primera
## persona con el cuerpo); proxy remoto: el visual propio del asiento (a la vista, porque ahí nunca
## se corrió _sit). Lo llama BoneInstantiator._pose_root cada frame del que está sentado, y de paso
## REGISTRA al ocupante para que _physics_process pueda soltar el visual cuando deje de estarlo.
##
## ⚠ SÓLO SE REGISTRA EL QUE ESTÁ SENTADO ACÁ, y eso no es una guarda de más. A un maniquí de escala al que
## el asiento acaba de echar le queda vivo el resto del cuadro —se va con un `queue_free`— y su pose sigue
## corriendo, así que VOLVÍA A ANOTARSE acá después de que el asiento lo había soltado; al final del cuadro
## se liberaba y `_visual_occupant` quedaba apuntando a un nodo muerto. Medido: sentarse en una meca con la
## tripulación de escala puesta y antes de que se congele (ver StationSeat.CREW_SETTLE_FRAMES) deja al asiento
## tirando un error por cuadro en `_physics_process` y termina en segfault. La regla que lo hace imposible no
## es revisar ese caso: es que el único que puede registrarse sea el ocupante.
func update_seated_visual(occupant: Node, occupant_yaw: float) -> void:
	if occupant != _seated_bi:
		return
	_visual_occupant = occupant
	var mesh: Node3D = _borrowed_mesh if is_instance_valid(_borrowed_mesh) else _visual_root
	if not is_instance_valid(mesh):
		return
	mesh.global_position = _visual_root.global_position
	# ALREDEDOR DEL ARRIBA DE LA SILLA, NO DEL MUNDO (2/11/2026, lo pidió el usuario: «cada vez que se inclina la
	# nave, las sillas como que no se inclinan»): a bordo todo se mide desde lo que lo lleva. El rumbo del ocupante se
	# pasa a los ejes de la silla y se gira ahí, así que con la meca cabeceando o rolando la silla va con el piso. El
	# frente sale de la cápsula misma y no de `occupant_yaw`: la de un maniquí viaja inclinada con la silla, y ahí el
	# ángulo de Euler ya no es su rumbo. La del jugador va derecha, y las dos cuentas dan lo mismo.
	var capsule := occupant.get("char_rigidbody") as Node3D
	var front := capsule.global_basis * Vector3.FORWARD if is_instance_valid(capsule) 		else Basis(Vector3.UP, occupant_yaw) * Vector3.FORWARD
	var facing := global_basis.orthonormalized().inverse() * front
	var turn := Basis(Vector3.UP, atan2(-facing.x, -facing.z))
	mesh.global_basis = global_basis.orthonormalized() * turn * Basis.from_scale(mesh.global_basis.get_scale())

## Si el asiento lo tenía UNO DE EXHIBICIÓN (ver CharacterKind.is_exhibit) y el que llega es otro, se lo saca: el que se
## sienta de verdad tiene prioridad, y con dos ocupantes el asiento queda posado por los dos a la vez. La malla prestada se
## va con él —es hija de su cápsula—, así que acá sólo se la suelta antes de devolver el visual a su reposo.
##
## NO SE BORRA: se para, SE APAGA Y SE ESCONDE (BoneInstantiator.set_active), y cuando el que llegó se levanta, vuelve y
## se sienta de nuevo (el usuario: «si me siento en una silla desaparecen y se desactivan»).
func _evict_display_occupant(incoming: Node) -> void:
	if not is_instance_valid(_seated_bi) or _seated_bi == incoming:
		return
	if not _is_exhibit(_seated_bi):
		return
	var dummy: Node = _seated_bi
	_put_aside = dummy
	_release_occupant(false, false)
	if dummy.has_method("set_active"):
		dummy.call("set_active", false)


## El de exhibición que se apartó para que se siente otro (ver `_evict_display_occupant`), o null.
var _put_aside: Node = null


## Vuelve el apartado, si lo hay, y se sienta otra vez.
func _bring_back_put_aside() -> void:
	var back := _put_aside
	_put_aside = null
	if not is_instance_valid(back) or not back.is_inside_tree():
		return
	if back.has_method("set_active"):
		back.call("set_active", true)
	var intent: CharacterIntent = back.get("intent")
	if intent != null:
		intent.seat = self


## Un sonido al sentarse y otro al pararse, en la máquina de quien se sienta (ver SoundEntity).
const SOUNDS := {SIT: &"silla_sienta", STAND: &"silla_levanta"}

func sounds() -> Dictionary:
	return SOUNDS


## EL PUESTO AL QUE SIRVE ESTA SILLA: la consola de adelante. La pone quien arma las dos —DashboardShapeArchetype en el
## sandbox; en la meca, la cabina—, porque la silla no cuelga de su consola. Cuando alguien se sienta, lo que hay en el
## puesto se le acomoda (ControllableInteractable.fit_to_seat: el volante se inclina hacia él), y al levantarse vuelve.
var station: Node3D = null


## Lo del puesto, acomodado a `sitter`, o devuelto con null.
func _fit_station(sitter: Node) -> void:
	if not is_instance_valid(station):
		return
	for node in station.find_children("*", "ControllableInteractable", true, false):
		if sitter != null:
			(node as ControllableInteractable).fit_to_seat(sitter)
		else:
			(node as ControllableInteractable).leave_seat()


func _sit(bi: Node) -> void:
	_evict_display_occupant(bi)
	_seated_bi = bi
	_fit_station(bi)
	var char_rb := bi.get("char_rigidbody") as CharacterRigidBody3D
	if not is_instance_valid(char_rb):
		return

	if char_rb.kind.simulates():
		char_rb.linear_velocity    = Vector3.ZERO
		char_rb.angular_velocity   = Vector3.ZERO
	char_rb.is_snapshot_active = false
	char_rb.reset_impact_state()
	char_rb.collider.disabled  = true
	char_rb.axis_lock_linear_y = true
	char_rb.input_enabled      = false
	char_rb.set_seated(true)
	# Para `_carry_occupant`: a qué altura quedó la cápsula respecto del asiento.
	_occupant_y_offset = char_rb.global_position.y - global_position.y

	char_rb.global_position.x = global_position.x
	char_rb.global_position.z = global_position.z
	char_rb.global_rotation.y = heading()
	# EL MARCO, EL DE LA SILLA, y la mirada al frente de ella, en sus ejes (ver CharacterIntent). Al compañero de red le
	# llega todo eso de su dueño.
	var intent: CharacterIntent = bi.get("intent")
	if char_rb.kind.driver != CharacterKind.Driver.NETWORK:
		char_rb.set_frame(MotionFrame.around(global_position, char_rb.frame))
		if intent != null:
			intent.look_yaw = CharacterIntent.yaw_of(char_rb.frame, -global_basis.z)
			intent.look_pitch = 0.0
	if intent != null:
		intent.seat = self

	var pc: PlayerController = bi.get("player_controller")
	if is_instance_valid(pc):
		pc.call("apply_camera_pitch", 0.0)

	if is_instance_valid(_visual_root):
		_visual_root.visible   = false
		_borrowed_mesh         = _instantiate_visual()
		_borrowed_mesh.visible = true
		char_rb.add_child(_borrowed_mesh)
		_borrowed_mesh.global_position = _visual_root.global_position
		_borrowed_mesh.rotation        = Vector3.ZERO

	bi.set("is_seated", true)
	bi.set("current_seat", self)

	var ic: InteractionController = bi.get("interaction_controller")
	if is_instance_valid(ic):
		ic.detector.force_clear()

	var anim_mod: AnimationModifiers = bi.get("anim_mod")
	if is_instance_valid(anim_mod):
		anim_mod.set("is_seated", true)

	var proc_anim: ProceduralBoneAnimator = bi.get("procedural_animator")
	if is_instance_valid(proc_anim):
		proc_anim.set("is_seated", true)
		var bu: CustomBonesUtil = bi.get("custom_bones_util")
		if is_instance_valid(bu):
			proc_anim.set("_seated_locked_bone", bu.lower_spine)

	if bi.has_method("refresh_shown"):
		bi.call("refresh_shown")  # el ente: sentado, las manos (ver CharacterKind.hands)

	# Multiplayer: avisar a los demás en qué asiento me senté (arman el pose sentado del proxy).
	var ns: CharacterNetSync = bi.get("net_sync")
	if is_instance_valid(ns) and _is_local(bi):
		ns.send_seat(self)
	play_sound(SIT)


func _stand_up() -> void:
	_release_occupant(true, true)

## Si el asiento se destruye (despawn) con alguien sentado, hay que liberarlo o queda trabado: en la
## máquina del ocupante _sit dejó la cápsula inactiva + colisión off + axis lock, y sin _stand_up eso
## nunca se revierte. Solo corre donde _seated_bi está seteado (el ocupante); en las demás máquinas el
## proxy se auto-cura (el productor ve el asiento inválido y limpia los flags). Ver multiplayer.md.
func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	_release_occupant(false, false)  # sin broadcast: el asiento ya se borró en todas las máquinas

## Revierte el estado de "sentado" del ocupante: flags (bi/anim/proc) + física de la cápsula. Con
## teleport=true lo reubica en el spawn point del asiento (pararse normal); con false lo deja donde
## está y no hace RPC — el asiento se está destruyendo y ya no existe en ninguna máquina.
func _release_occupant(teleport: bool, broadcast: bool) -> void:
	if not is_instance_valid(_seated_bi):
		return
	var bi      := _seated_bi
	var char_rb := bi.get("char_rigidbody") as CharacterRigidBody3D
	_seated_bi = null
	_fit_station(null)
	if bi != _put_aside and is_inside_tree():
		_bring_back_put_aside.call_deferred()
	if teleport:
		play_sound(STAND)

	if is_instance_valid(_borrowed_mesh):
		_borrowed_mesh.queue_free()
		_borrowed_mesh = null
	if is_instance_valid(_visual_root):
		_visual_root.visible = true

	bi.set("is_seated", false)
	bi.set("current_seat", null)
	# Y SU INTENCIÓN, sin silla: si no, a quien no es el jugador lo volvería a sentar (ver BoneInstantiator._follow_seat).
	var intent: CharacterIntent = bi.get("intent")
	if intent != null and intent.seat == self:
		intent.seat = null
	if bi.has_method("refresh_shown"):
		bi.call("refresh_shown")

	var anim_mod: AnimationModifiers = bi.get("anim_mod")
	if is_instance_valid(anim_mod):
		anim_mod.set("is_seated", false)

	var proc_anim: ProceduralBoneAnimator = bi.get("procedural_animator")
	if is_instance_valid(proc_anim):
		proc_anim.set("is_seated", false)
		proc_anim.set("_seated_locked_bone", null)

	var ns: CharacterNetSync = bi.get("net_sync")
	if is_instance_valid(ns) and broadcast and _is_local(bi):
		ns.send_seat(null)  # avisar a los proxies (vuelven al solve de parado); destruido, ya se borró en todas

	var pc: PlayerController = bi.get("player_controller")
	if is_instance_valid(pc):
		pc.call("apply_camera_pitch", 0.0)

	if not is_instance_valid(char_rb):
		return
	char_rb.axis_lock_linear_y = false
	char_rb.collider.disabled  = false
	char_rb.set_seated(false)  # vuelve al marco con la velocidad de la meca en su punto
	if char_rb.kind.simulates():
		char_rb.angular_velocity   = Vector3.ZERO
	char_rb.reset_impact_state()
	char_rb.is_snapshot_active = true
	char_rb.input_enabled      = char_rb.kind.simulates()

	if teleport and is_instance_valid(_spawn_point) and char_rb.kind.simulates():
		var target_pos   := _spawn_point.global_position
		var target_rot_y := char_rb.global_rotation.y
		char_rb.call_deferred("move_to", target_pos, target_rot_y)
