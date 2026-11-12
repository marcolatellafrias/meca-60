class_name ControllableInteractable
extends Interactable

## Por defecto, mientras se maneja un control la cámara se mueve al 30 %: se ve hacia dónde va la mano
## sin que la vista se escape. Cada control lo puede cambiar (ControlDefinition.camera_sensitivity_factor).
const DEFAULT_CAMERA_SENSITIVITY := 0.3

@export var auto_return:               bool         = false
@export var default_value:             float        = 0.0
@export var positions:                 Array[float] = []
## Cuánto sigue moviendo la cámara el mouse mientras se maneja el control: una fracción de lo normal.
@export var camera_sensitivity_factor: float        = DEFAULT_CAMERA_SENSITIVITY
@export var snap_lerp_speed:           float        = 8.0
@export var return_speed:              float        = 3.0

# Applied as a constant offset in every _apply_visual call.
# Lets you set the resting orientation of any control at instantiation time.
@export var rest_rotation_deg: Vector3 = Vector3.ZERO

var grid_size:            Vector2i              = Vector2i(1, 1)
var visual_value:         float                 = 0.0
var _network_state:       float                 = 0.0
var _is_being_controlled: bool                  = false
## True en las demás máquinas mientras OTRO jugador lo manipula: suprime la dinámica local
## (auto-return/lerp) para que no pelee con el valor sincronizado que fija apply_sync_state.
var _remote_controlled:   bool                  = false
## Propiedad exclusiva (un solo controlador a la vez), arbitrada por el host. Ver ExclusiveClaim.
var _claim:               ExclusiveClaim        = null
## Las mallas que se iluminan mientras alguien lo maneja: la parte móvil (ver ControlArchetype.dress).
var highlighted:          Array[MeshInstance3D] = []

## ── EL MOUSE SE LEE COMO INTENCIÓN ───────────────────────────────────────────────────────────────
## No se mira si el mouse fue a la derecha o arriba en pantalla, sino ADÓNDE QUIERE LLEVAR LA MANO el punto
## que agarró. El movimiento del mouse es un desplazamiento en el plano de la cámara (`_drag_world`), y cada
## control lo proyecta sobre CÓMO SE MOVERÍA SU PUNTO AGARRADO con su grado de libertad (`_along`): lo que va
## en esa dirección cuenta, lo que va de costado no. Así no importa desde dónde se lo mire: agarrado del lado
## izquierdo, subir el mouse sube ese lado del volante, que es doblar a la derecha.
##
## Quién lo maneja deja acá su cámara y el punto que agarró (ver InteractionController._start_control). Sin
## cámara —una prueba—, se lee como si se lo mirara de frente.
const DRAG_METRES_PER_PIXEL := 0.002
var grab_view:  Node3D = null  # el ojo de quien lo maneja (ver InteractionController.player_camera)
var grab_point: Node3D   = null
## Cuánto rinde el arrastre en este control: más, menos mouse para el mismo recorrido.
@export var drag_gain: float = 1.0

## LO QUE SE CONTORNEA AL MIRARLO ES LO MISMO QUE SE RESALTA AL AGARRARLO: además de las mallas que cuelgan del
## control, sus `highlighted`. Antes solo contaban las que colgaban de él, y en las piezas armadas con la parte que se
## agarra AL LADO del control —la manija de una compuerta (ver SlidingHatch)— mirarla no contorneaba nada y recién
## agarrada se ponía verde.
func get_outline_targets() -> Array[Node]:
	var targets: Array[Node] = [self]
	for mesh in highlighted:
		if is_instance_valid(mesh) and not is_ancestor_of(mesh):
			targets.append(mesh)
	return targets


## ── LA INERCIA, ESTÁNDAR Y FLUIDA ────────────────────────────────────────────────────────────────
## Un control con `inertia` no se frena en seco al soltarlo: SIGUE CON LA VELOCIDAD QUE LLEVABA y se va apagando, como
## un tambor pesado que se larga girando. `inertia` es cuánto tarda en apagarse (s); 0, en seco, que es lo de siempre.
##
## ES UNA SOLA PARA TODOS (Era 3 del plan de la nave): la base mide la velocidad mientras se lo maneja (`_track_motion`,
## con el valor que el control mueve; los de dos ejes, `_track_motion_2d`) y el control, suelto, avanza lo que le da
## `_coast` (o `_coast_2d`) y dice si se movió (`_coasted`). Cuando se apaga o da contra un tope, frena y hace lo suyo al
## quedar suelto (`_coast_ended`: con posiciones, va a la más cercana). La usan la rueda (RotatingComponent), la palanca
## (OneAxisComponent) y la de dos ejes (TwoAxisComponent), y la prende cualquiera, también desde su definición
## (ControlDefinition.inertia); la palanca de cambios y el fichero giratorio la traen prendida. Uno que VUELVE SOLO
## (`auto_return`) no sigue: vuelve.
##
## ES FLUIDA: agarrarlo mientras sigue solo lo frena en el acto, y desde ahí manda la mano (`start_control`).
##
## EN RED, quien lo suelta manda con el valor la velocidad que llevaba (`_sync_final`) y cada máquina sigue igual; cuando
## queda quieto, les manda dónde (`_came_to_rest`): cada una lo siguió por su cuenta y puede haber quedado apenas corrida.
@export var inertia: float = 0.0
## La velocidad que lleva, en unidades de su valor por segundo (los de un eje usan la x).
var coast_velocity := Vector2.ZERO
## Debajo de esto, ya está quieto.
const COAST_STOP := 0.05
var _last_motion := Vector2(NAN, NAN)
## Lo soltó esta máquina y todavía no quedó quieto: cuando quede, les dice a las demás dónde (ver `_came_to_rest`).
var _settling_mine := false


## Mientras se lo maneja: la velocidad de `value`, suavizada, para seguir con ella al soltarlo.
func _track_motion(value: float, delta: float) -> void:
	_track_motion_2d(Vector2(value, 0.0), delta)


## Lo mismo, en los de dos ejes.
func _track_motion_2d(value: Vector2, delta: float) -> void:
	if inertia <= 0.0:
		return
	if delta > 0.0 and _last_motion.is_finite():
		coast_velocity = coast_velocity.lerp((value - _last_motion) / delta, 0.35)
	_last_motion = value


## Suelto: lo que avanza este cuadro con la velocidad que lleva, que se va apagando. Quien lo avanza dice después si se
## movió (`_coasted`).
func _coast(delta: float) -> float:
	return _coast_2d(delta).x


## Lo mismo, en los de dos ejes.
func _coast_2d(delta: float) -> Vector2:
	if inertia <= 0.0:
		coast_velocity = Vector2.ZERO
		return Vector2.ZERO
	var step := coast_velocity * delta
	coast_velocity *= exp(-delta * 3.0 / inertia)
	return step


## Después de avanzar lo que dio `_coast`: si no se movió —dio contra un tope— o ya se apagó, frena.
func _coasted(moved: bool) -> void:
	if not moved or coast_velocity.length() < COAST_STOP:
		_stop_coast()


## FRENA lo que venía siguiendo solo, y hace lo que hace al quedar suelto (`_coast_ended`).
func _stop_coast() -> void:
	coast_velocity = Vector2.ZERO
	_coast_ended()


## Lo que hace al dejar de seguir solo: con posiciones, va a la más cercana; y quedó quieto (`_came_to_rest`). El que
## después todavía se acomoda —el fichero se traba en una tarjeta, la palanca de cambios va a su marcha— lo cambia, y
## avisa cuando llega.
func _coast_ended() -> void:
	if not auto_return and positions.size() > 0:
		_snap_to_nearest()
	_came_to_rest()


## QUEDÓ QUIETO después de soltarlo: si lo soltó esta máquina, les manda a las demás dónde —con posiciones, la que
## eligió—.
func _came_to_rest() -> void:
	if not _settling_mine:
		return
	_settling_mine = false
	if multiplayer.has_multiplayer_peer():
		_sync_final.rpc(_network_state if positions.size() > 0 else get_sync_state(), Vector2.ZERO)


## Si todavía va siguiendo solo.
func coasting() -> bool:
	return not _is_being_controlled and not _remote_controlled and coast_velocity.length() >= COAST_STOP


## Lo pone a seguir solo con `coast` —lo que mandó quien lo soltó, en otra máquina—, o lo deja quieto donde está.
func _set_coast(coast: Vector2) -> void:
	coast_velocity = coast if inertia > 0.0 else Vector2.ZERO


signal state_changed(value: float)
## El host me quitó el control (perdí una carrera por el mismo control): el InteractionController suelta.
signal control_lost()

# ── Build ─────────────────────────────────────────────────────────────────────

## Los puntos de agarre de un control de `control_size`; la malla la pone el tablero (ver
## ControlArchetype.dress). Con `debug`, los puntos se ven.
func build(control_size: Vector3, debug := false) -> void:
	_clear_handle_points()
	_setup_handle_points(control_size)
	if debug:
		_visualize_handle_points(control_size)

# ── Physics ───────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _is_being_controlled:
		# Solo el controlador CONFIRMADO por el host streamea (evita que dos peleen en una carrera).
		if multiplayer.has_multiplayer_peer() and is_instance_valid(_claim) and _claim.is_mine():
			_sync_state.rpc(get_sync_state())
		return
	if _remote_controlled:
		return  # lo maneja otro jugador: el visual lo fija apply_sync_state, no corras dinámica local
	if auto_return:
		_do_auto_return(delta)
	elif positions.size() > 0 and not coasting():
		visual_value = lerp(visual_value, _network_state, clamp(delta * snap_lerp_speed, 0.0, 1.0))
		_apply_visual()

# ── Sincronización + propiedad exclusiva ──────────────────────────────────────
# Un solo controlador a la vez vía ExclusiveClaim (host-arbitrado); can_interact bloquea el caso
# común y el claim cubre la carrera simultánea (el perdedor suelta vía control_lost). El controlador
# confirmado streamea su estado; los demás lo aplican y suprimen su dinámica local (_remote_controlled).
# El ruteo va por el path del nodo, estable porque el dashboard se genera determinístico por seed y
# nombra sus controles (ver ProceduralDashboard). Ver conceptual/multiplayer.md.
# (Falta: el estado en reposo no viaja en el snapshot de join — lo trae _request_control_states.)

func _ready() -> void:
	# EL CONTROL NACE EN SU VALOR DE REPOSO. `default_value` era solo el destino del auto-retorno, así
	# que una palanca con reposo en el medio nacía en 0 y "volvía" al centro emitiendo todo el recorrido:
	# la palanca de altura de la nave la hacía bajar sola al aparecer. Quien lo arma (ProceduralDashboard)
	# setea `default_value` antes de meterlo al árbol, así que acá ya tiene el valor bueno.
	visual_value   = default_value
	_network_state = default_value
	move_sound(default_value)  # dónde arranca: el movimiento suena desde acá (ver SoundEntity.move_sound)
	# Y en su POSE de reposo: un control que no vuelve solo se quedaba en rotación 0 hasta que lo tocaban.
	_apply_visual()
	_claim = ExclusiveClaim.new()
	_claim.name = "Claim"  # nombre estable → mismo path en todas las máquinas
	add_child(_claim)
	_claim.granted.connect(_on_claim_granted)
	_claim.released.connect(_on_claim_released)
	_claim.revoked.connect(_on_claim_revoked)

func _on_claim_granted(_peer: int) -> void:
	_remote_controlled = not _claim.is_mine()  # otro lo maneja → suprimo mi dinámica local
	if _remote_controlled:
		# Lo agarró otro mientras seguía solo: manda su mano (ver LA INERCIA).
		coast_velocity = Vector2.ZERO
		_settling_mine = false

func _on_claim_released() -> void:
	_remote_controlled = false

func _on_claim_revoked() -> void:
	control_lost.emit()  # perdí la carrera por el mismo control: el IC suelta

## A QUIEN SE SIENTA EN LA SILLA DE SU PUESTO se acomoda (ver SeatInteractable.station), y `leave_seat` lo devuelve
## cuando se levanta. Lo de casi todos: nada. El volante se inclina hacia él (ver RotatingComponent). Lo decidió el dios
## del juego (11/10/2026): el ajuste es al sentarse, no al agarrar.
func fit_to_seat(_sitter: Node) -> void:
	pass


func leave_seat() -> void:
	pass


func can_interact() -> bool:
	return _claim == null or _claim.is_free() or _claim.is_mine()

## Estado a replicar (float por defecto; two-axis = Vector2, touch = bool, override en subclases).
func get_sync_state() -> Variant:
	return visual_value

## Aplica un estado recibido: fija el visual y emite el cambio SIN re-transmitir.
func apply_sync_state(state: Variant) -> void:
	visual_value = state
	_apply_visual()
	_emit_if_changed(state)

@rpc("any_peer", "unreliable_ordered", "call_remote")
func _sync_state(state: Variant) -> void:
	apply_sync_state(state)

## Estado final al soltar (reliable, para no perder la posición de reposo por un paquete tirado), y la velocidad con la
## que sigue solo (ver LA INERCIA); cero, ya quieto.
@rpc("any_peer", "reliable", "call_remote")
func _sync_final(final_state: Variant, coast: Vector2) -> void:
	apply_sync_state(final_state)
	_set_coast(coast)

# ── API ───────────────────────────────────────────────────────────────────────

func get_network_state() -> float:
	return _network_state

## Si lo está manejando alguien EN ESTA MÁQUINA. Un control que maneja otro jugador también emite sus señales acá (ver
## `apply_sync_state`): quien tenga que actuar una sola vez por apretada —una compuerta, ver ShipDoor— pregunta esto.
func is_controlled_here() -> bool:
	return _is_being_controlled

func start_control() -> void:
	# FLUIDO (ver LA INERCIA): si seguía solo, la mano lo frena en el acto.
	coast_velocity = Vector2.ZERO
	_last_motion = Vector2(NAN, NAN)
	_settling_mine = false
	_is_being_controlled = true
	_set_highlight(true)
	if is_instance_valid(_claim):
		_claim.request()  # pedir el control (offline concede al toque; online arbitra el host)

func stop_control() -> void:
	_is_being_controlled = false
	_set_highlight(false)
	# El que vuelve solo no sigue: vuelve. Y lo que no llega a seguir, queda quieto (ver LA INERCIA).
	if auto_return or not coasting():
		coast_velocity = Vector2.ZERO
	if not auto_return and positions.size() > 0 and not coasting():
		_snap_to_nearest()
	if is_instance_valid(_claim) and _claim.is_mine():
		_settling_mine = true
		if multiplayer.has_multiplayer_peer():
			_sync_final.rpc(get_sync_state(), coast_velocity)  # estado final de reposo (reliable), y si sigue solo
		_claim.release()

func handle_mouse_motion(_delta: Vector2) -> void:
	pass

func handle_scroll(_delta: float) -> void:
	pass

# ── Internals ─────────────────────────────────────────────────────────────────

func _do_auto_return(delta: float) -> void:
	visual_value = move_toward(visual_value, default_value, return_speed * delta)
	_emit_if_changed(visual_value)
	_apply_visual()

func _snap_to_nearest() -> void:
	if positions.is_empty():
		return
	var nearest   := positions[0]
	var best_dist : float = abs(visual_value - nearest)
	for p in positions:
		var d : float = abs(visual_value - p)
		if d < best_dist:
			best_dist = d
			nearest   = p
	_emit_if_changed(nearest)

## TODO CAMBIO DE VALOR PASA POR ACÁ —la mano, la inercia, el que vuelve solo, el que llega por red—, así que acá suena
## el movimiento, si la clase lo declara (MOVE, MOVE_UP, MOVE_DOWN, y MOVE_SELF si nadie lo tiene en la mano: la
## inercia, el que vuelve solo, lo que lo mueve el código; ver SoundEntity.move_sound).
func _emit_if_changed(new_state: float) -> void:
	if abs(new_state - _network_state) > 0.001:
		_network_state = new_state
		move_sound(new_state, not (_is_being_controlled or _remote_controlled))
		state_changed.emit(_network_state)

func _apply_visual() -> void:
	pass

# ── Helpers for subclasses ────────────────────────────────────────────────────

# Returns rest_rotation_deg converted to radians as a Vector3, for use in _apply_visual.
func _rest_rot() -> Vector3:
	return Vector3(
		deg_to_rad(rest_rotation_deg.x),
		deg_to_rad(rest_rotation_deg.y),
		deg_to_rad(rest_rotation_deg.z)
	)

## El movimiento `delta` del mouse (píxeles, +y hacia abajo) como desplazamiento en el mundo, en metros, sobre el
## plano de la cámara de quien lo maneja; sin cámara, sobre el del tablero —el del cuerpo del control, que no
## gira con él—, como si se lo mirara de frente.
func _drag_world(delta: Vector2) -> Vector3:
	var still := get_parent_node_3d()
	var basis := (still.global_basis if still != null else global_basis)
	if is_instance_valid(grab_view):
		basis = grab_view.global_basis
	return (basis.x.normalized() * delta.x - basis.y.normalized() * delta.y) * DRAG_METRES_PER_PIXEL * drag_gain


## CUÁNTO AVANZA un grado de libertad cuyo punto agarrado se mueve `tangent` (metros por unidad) con el arrastre
## `drag`. Es la proyección del arrastre sobre cómo se VE moverse ese punto, así que el punto sigue al mouse en
## pantalla. Visto casi de punta, el punto apenas se mueve en pantalla y la cuenta se dispararía: se la limita
## como si se viera al menos a medias.
func _along(drag: Vector3, tangent: Vector3) -> float:
	var full := tangent.length_squared()
	if full <= 1e-10:
		return 0.0
	var seen := tangent
	if is_instance_valid(grab_view):
		var view := grab_view.global_basis.z.normalized()
		seen = tangent - view * tangent.dot(view)
	return drag.dot(seen) / maxf(seen.length_squared(), full * 0.25)


## Dónde está la mano: el punto agarrado, o si no hay, el más cercano al centro del control.
func _hand_world() -> Vector3:
	if is_instance_valid(grab_point):
		return grab_point.global_position
	if not handle_points.is_empty() and is_instance_valid(handle_points[0]):
		return handle_points[0].global_position
	return global_position


## Cuánto sale del tablero la parte móvil (un volante va sobre un eje: ver RotatingComponent).
func mesh_offset() -> Vector3:
	return Vector3.ZERO

## Mientras alguien lo maneja, la parte móvil se ilumina.
##
## ⚠ SE ILUMINA SU PROPIO MATERIAL, NUNCA UNO COMPARTIDO: la primera vez, cada malla resaltada se queda con una copia
## del suyo (`_own_material`). Las piezas toman materiales de cachés que comparte todo el juego —uno por color, ver
## StrokeLabel.material_for—, y prender la emisión de uno de esos prendía en verde todo lo que lo usaba: agarrar el
## fichero giratorio ponía verde la palanca de cambios de al lado. Pasó dos veces; con la copia no puede pasar más,
## use la pieza el material que use.
func _set_highlight(active: bool) -> void:
	for m in highlighted:
		if not is_instance_valid(m):
			continue
		var mat := _own_material(m)
		if mat == null:
			continue
		mat.emission_enabled = active
		if active:
			mat.emission                   = Color(0.05, 0.45, 0.1)
			mat.emission_energy_multiplier = 1.2


## El material de `m` que es SOLO SUYO: la primera vez, una copia del que tenga.
static func _own_material(m: MeshInstance3D) -> StandardMaterial3D:
	var mat := m.material_override as StandardMaterial3D
	if mat == null:
		return null
	if not m.has_meta("own_material"):
		mat = mat.duplicate() as StandardMaterial3D
		m.material_override = mat
		m.set_meta("own_material", true)
	return mat

# ── Debug ─────────────────────────────────────────────────────────────────────

func _setup_handle_points(_control_size: Vector3) -> void:
	pass

## El punto sigue el tamaño del control: con uno fijo, a un botón de 4 cm lo tapaba entero.
func _visualize_handle_points(control_size: Vector3) -> void:
	var dot := minf(0.035, minf(control_size.x, control_size.y) * 0.15)
	for pt in handle_points:
		if not is_instance_valid(pt):
			continue
		pt.add_child(DebugUtil.create_debug_sphere(Color(1.0, 0.75, 0.0), dot, true))
