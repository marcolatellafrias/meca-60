class_name PackageContents
extends Node
## Lo que va ADENTRO de un paquete contenedor (botellas en un cajón, frutas en un cajón…). La
## durabilidad del paquete es cuántos ítems siguen adentro: un ítem que sale de la caja de contención
## se rompe y desaparece.
##
## Los ítems son cuerpos físicos reales, pero COSMÉTICOS y LOCALES: cada máquina simula los suyos y
## nadie los puede agarrar ni tocar (su capa solo choca contra los contenedores y entre ellos). Lo
## único que viaja por red es el CONTEO. Que dos jugadores vean una botella en distinta posición no
## importa; que vean distinto número, sí.
##
## Quién decide que un ítem se cayó: quien simula el paquete (la autoridad de su NetBody: el host en
## reposo, el que lo sostiene mientras lo lleva). Sus ítems son los que cuentan. En los demás un ítem
## que se sale queda PENDIENTE (escondido) hasta que la autoridad confirme la rotura; si no la confirma
## en `PENDING_TIMEOUT_MS`, vuelve a su lugar — fue un desvío de la simulación local, no una rotura.
##
## El conteo solo baja (`min`), así que el orden de los mensajes y un cambio de autoridad a mitad de
## camino no pueden resucitar nada.

## Capa de los ítems. El contenedor tiene que estar en esta capa (además de la suya) para que lo
## toquen. Ni el piso, ni los jugadores, ni el rayo de interacción la miran.
const LAYER := 1 << 4  # 3d_physics/layer_5 "Contenido"
const PENDING_TIMEOUT_MS := 1000

signal intact_changed(intact: int, total: int)

## Caja de contención en local del contenedor: un ítem cuyo centro sale de acá se rompió.
@export var containment := AABB()

var total: int = 0
var intact: int = 0

## Por ítem: {body: RigidBody3D, rest: Transform3D (local al contenedor), pending_since: int (-1 = no)}
var _items: Array = []
var _placed := false

## Agrega un ítem. `rest` es su pose de reposo en local del contenedor. Llamar antes de entrar al árbol.
func add_item(body: RigidBody3D, rest: Transform3D) -> void:
	body.top_level = true  # simula en mundo: que el contenedor se mueva no lo arrastra por la jerarquía
	body.collision_layer = LAYER
	body.collision_mask = LAYER
	body.continuous_cd = true  # paredes finas y el agarre acelera fuerte
	body.freeze = true  # hasta que esté en su lugar (el contenedor recibe su transform después de entrar)
	body.transform = rest
	_items.append({"body": body, "rest": rest, "pending_since": -1})
	total += 1
	intact += 1

## 0..1: la durabilidad del paquete.
func durability() -> float:
	return 1.0 if total == 0 else float(intact) / float(total)

func _ready() -> void:
	# A SU LUGAR YA, todavía congelados, y de nuevo al fin del cuadro. Los ítems son `top_level`: hasta que
	# alguien los ubique están en su pose de reposo pero EN MUNDO, o sea al lado del origen. La pasada
	# diferida sigue haciendo falta (quien spawnea suele darle el transform al contenedor después de
	# agregarlo), pero sin esta el que mida al contenedor en el mismo cuadro encuentra las botellas lejos:
	# la parcela del design sandbox las medía a metros del cajón (ver SandboxParcel._check_footprint).
	var c := _container()
	if c != null and c.is_inside_tree():
		for it in _items:
			_reset_item(it, c)
	_place_items.call_deferred()
	# Recién llegado: el paquete puede haber perdido ítems antes de que existiéramos.
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		_request_intact.rpc_id(1)

func _container() -> RigidBody3D:
	return get_parent() as RigidBody3D

## Los ítems nacen en su pose de reposo respecto del contenedor ya ubicado.
func _place_items() -> void:
	var c := _container()
	if c == null:
		return
	for it in _items:
		_reset_item(it, c)
		(it["body"] as RigidBody3D).freeze = false
	_placed = true

func _reset_item(it: Dictionary, c: RigidBody3D) -> void:
	var b := it["body"] as RigidBody3D
	b.global_transform = c.global_transform * (it["rest"] as Transform3D)
	b.linear_velocity = c.linear_velocity
	b.angular_velocity = Vector3.ZERO
	b.visible = true
	b.process_mode = Node.PROCESS_MODE_INHERIT
	it["pending_since"] = -1

func _physics_process(_delta: float) -> void:
	var c := _container()
	if c == null or not _placed:
		return
	var to_local := c.global_transform.affine_inverse()
	var authority := _simulates()
	var now := Time.get_ticks_msec()
	for i in range(_items.size() - 1, -1, -1):
		var it: Dictionary = _items[i]
		var b := it["body"] as RigidBody3D
		var pending := int(it["pending_since"])
		if pending >= 0:
			# Pendiente: si ahora somos la autoridad o la confirmación no llegó, no se rompió.
			if authority or now - pending > PENDING_TIMEOUT_MS:
				_reset_item(it, c)
			continue
		# El contenedor despierto despierta a los suyos: si se lo llevan de abajo, que caigan.
		if not c.sleeping and b.sleeping:
			b.sleeping = false
		if containment.has_point(to_local * b.global_position):
			continue
		if authority:
			_break_item(i)
			_broadcast_intact()
		else:
			it["pending_since"] = now
			b.visible = false
			b.process_mode = Node.PROCESS_MODE_DISABLED  # sale de la simulación mientras espera

func _break_item(i: int) -> void:
	(_items[i]["body"] as RigidBody3D).queue_free()
	_items.remove_at(i)
	intact = _items.size()
	intact_changed.emit(intact, total)

## Baja el conteo local a `count`, rompiendo primero los pendientes (los que acá ya se habían salido).
func _apply_intact(count: int) -> void:
	while _items.size() > maxi(count, 0):
		var victim := _items.size() - 1
		for i in _items.size():
			if int(_items[i]["pending_since"]) >= 0:
				victim = i
				break
		_break_item(victim)

## Quien simula el contenedor: offline siempre; en red, la autoridad de su NetBody (o el host si no tiene).
func _simulates() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return true
	var c := _container()
	for child in c.get_children():
		if child is NetBody:
			return (child as NetBody).is_multiplayer_authority()
	return multiplayer.is_server()

# ── Red: solo el conteo ───────────────────────────────────────────────────────

func _broadcast_intact() -> void:
	if multiplayer.has_multiplayer_peer():
		_sync_intact.rpc(intact)

## any_peer a propósito: la autoridad cambia con cada agarre y el conteo solo baja, así que aceptar
## de cualquiera no puede romper nada que no se haya roto en alguna máquina que simulaba.
@rpc("any_peer", "reliable", "call_remote")
func _sync_intact(count: int) -> void:
	_apply_intact(count)

@rpc("any_peer", "reliable")
func _request_intact() -> void:
	if multiplayer.is_server():
		_sync_intact.rpc_id(multiplayer.get_remote_sender_id(), intact)
