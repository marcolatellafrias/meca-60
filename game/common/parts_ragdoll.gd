class_name PartsRagdoll
extends RefCounted

## ── EL RAGDOLL AL MORIR, PARA CUALQUIER CUERPO HECHO DE PIEZAS (18/11/2026; módulo Jefes, el sistema común) ─────────
## El usuario: «todos (la meca propia, los jefes, los personajes) se caen con ragdoll al morir; los grandes, quizás más
## lento para que se lea la escala». Los personajes tienen el suyo, de huesos (RagdollUtil); éste es el de los cuerpos
## de piezas: la meca jaula y los jefes.
##   · UN ESQUELETO: CADA PARTE (`add`: una lista de nodos del dibujo) es UN HUESO, un cuerpo físico, UNIDO A SU PADRE
##     (`parent`) con una articulación que dobla con límite (ConeTwistJoint3D) EN SU PUNTO DE VERDAD (`joint_at`: la
##     cadera, la rodilla, el tobillo, el hombro, la cintura; sin él, la punta de la parte más cerca del padre). Todo
##     queda conectado (el usuario: «todos los huesos deberían estar conectados»). LO QUE NO ES DE NINGUNA PARTE va al
##     TRONCO (la parte 0).
##   · SUS CAJAS Y SU PESO, UNA SOLA REGLA: CADA PIEZA DE ARCILLA ES SU PROPIA CAJA (la de su malla, donde está), y
##     el peso sale de ese volumen (`DENSITY`), igual para todos. El tronco, con su caja de verdad (`set_core_box`: la de
##     la meca), pesa lo que pesa: mucho más que un brazo. *Hasta el 18/11/2026 cada hueso era UNA caja que envolvía su
##     dibujo: la del tronco de la jaula envolvía la cabina, las sillas y los maniquíes (quedaba flotando), y la de un
##     brazo estirado era enorme (pesaba casi como el torso y lo frenaba; el usuario: «los brazos frenan el torso, que se
##     supone que es mucho más pesado»).*
##   · SALE COMO LO EMPUJÓ EL GOLPE QUE LO MATÓ (`Health.push`, lo dice quien pega; el usuario: «se controla en base al
##     hit»): con una parte de esa velocidad (`PUSH_SHARE`, `LIFT_SHARE`), más la que traía, y se vuelca hacia allá (lo
##     de arriba, más). Sin empujón, se desploma. Con roce contra el piso, sin rebote.
##   · LOS GRANDES CAEN MÁS LENTO: la gravedad, por su tamaño (`gravity_for`): una meca jaula de 4 m, entera; un jefe de
##     20 m, la mitad.
## Las mallas se mudan a los cuerpos nuevos (en el mismo lugar del mundo); el cuerpo vivo lo apaga quien lo llama.

## Tamaño (m) hasta el que la gravedad es la de siempre, y lo menos que baja.
const FULL_GRAVITY_SIZE := 6.0
const LEAST_GRAVITY := 0.4
## Cuánto dobla una articulación (°) y cuánto se tuerce.
const SWING := 60.0
const TWIST := 25.0
## Lo que pesa cada metro cúbico de pieza (kg), y lo poco que frena al girar (lo que la acomoda al final; el resto lo
## hacen el peso y el roce).
const DENSITY := 400.0
const SPIN_DAMP := 0.8
## QUÉ PARTE DEL EMPUJÓN QUE LO MATÓ se lleva el ragdoll: de costado y para arriba. El empujón es el del motor, que
## frena con un roce fuerte en el piso (KinematicMover.knock); los pedazos ruedan y se deslizan: con todo, se iban 100 m.
const PUSH_SHARE := 0.35
const LIFT_SHARE := 0.6
## El roce de los pedazos contra el piso (1: mucho).
const FRICTION := 1.0
## Cuánto se vuelca con el empujón que lo mató: lo de más arriba se lleva esta parte más del empujón (lo de abajo, nada).
const TOPPLE := 0.5
## El grupo de los pedazos (para encontrarlos).
const GROUP := "pedazos"

## Las partes: {nodes, parent, joint, box}. La 0 es el tronco.
var _parts: Array[Dictionary] = [{"nodes": [], "parent": -1, "joint": Vector3.INF, "box": {}}]
var _root: Node3D = null
## Los cuerpos que quedaron (para las pruebas).
var bodies: Array[RigidBody3D] = []
## PARA LEVANTARSE (ver `get_up`): el cuerpo de cada parte (null si no tuvo), su hueso (lo que sigue al levantarse: el
## cuerpo vivo para el tronco, el primer nodo de la parte para las otras), las uniones, y de dónde salió cada malla
## ([malla, su padre, su lugar en él]).
var _made: Array = []
var _anchors: Array = []
var _joints: Array[Node] = []
var _homes: Array = []
var _starts: Array[Transform3D] = []
var _rise_left := 0.0
var _rise_time := 1.0
var _riser: Node = null
## El material de los pedazos: con roce, sin rebote.
var _rough := PhysicsMaterial.new()


## Lo que se va a desarmar: `root`, el cuerpo entero (lo que no sea de ninguna parte, al tronco).
func _init(root: Node3D) -> void:
	_root = root
	_rough.friction = FRICTION
	_rough.rough = true
	_rough.bounce = 0.0


## UN HUESO: sus nodos del dibujo (con lo que cuelga de ellos), a qué parte se une (0, el tronco), dónde (el mundo; sin
## punto, la punta más cerca) y su caja (`{transform, size}`; sin ella, la que envuelve su dibujo). Devuelve su índice.
func add(nodes: Array, parent := 0, joint_at := Vector3.INF, box := {}) -> int:
	_parts.append({"nodes": nodes, "parent": parent, "joint": joint_at, "box": box})
	return _parts.size() - 1


## LA CAJA DEL TRONCO (la de verdad: la del cuerpo), en el mundo.
func set_core_box(where: Transform3D, size: Vector3) -> void:
	_parts[0]["box"] = {"transform": where, "size": size}


## LA GRAVEDAD de un cuerpo de `size` m (ver arriba).
static func gravity_for(size: float) -> float:
	return clampf(sqrt(FULL_GRAVITY_SIZE / maxf(size, 0.01)), LEAST_GRAVITY, 1.0)


## LO DESARMA en `world` (donde quedan los cuerpos), con la velocidad `velocity` (m/s).
func activate(world: Node, velocity: Vector3) -> void:
	# Las mallas de cada parte; lo que sobra, al tronco.
	# De la última parte a la primera (lo que cuelga de otra parte, antes: un brazo antes que el torso que lo lleva).
	var taken := {}
	var meshes: Array = []
	meshes.resize(_parts.size())
	for index in range(_parts.size() - 1, 0, -1):
		var own: Array = []
		for node: Node3D in _parts[index]["nodes"]:
			_collect(node, own, taken)
		meshes[index] = own
	var core: Array = []
	_collect(_root, core, taken)
	meshes[0] = core
	var whole := _box(core, _root.global_basis.orthonormalized())
	var gravity := gravity_for(maxf(whole["size"].x, maxf(whole["size"].y, whole["size"].z)))
	var made: Array[RigidBody3D] = []
	for index in _parts.size():
		var own: Array = meshes[index]
		if own.is_empty():
			made.append(null)
			continue
		var given: Dictionary = _parts[index]["box"]
		var body := RigidBody3D.new()
		body.name = "Pedazo"
		body.add_to_group(GROUP)
		world.add_child(body)
		# El cuerpo, donde está su dibujo (sus ejes: los del tronco o los de su primera malla); sus cajas, adentro.
		var frame := _box(own, _root.global_basis.orthonormalized() if index == 0 else Basis())
		var volume := 0.0
		if not given.is_empty():
			var where: Transform3D = given["transform"]
			body.global_transform = Transform3D(where.basis.orthonormalized(), where.origin)
			volume += _add_box(body, Transform3D(where.basis.orthonormalized(), where.origin), given["size"])
		else:
			# Una parte que sale de un hueso (o de un nodo del cuerpo) nace con su lugar y su giro, como en los
			# personajes: así, al levantarse, la mezcla (RagdollBlend) la lleva de vuelta exacto a su hueso.
			var first: Variant = (_parts[index]["nodes"] as Array)[0] if not (_parts[index]["nodes"] as Array).is_empty() else null
			if index == 0:
				first = _root
			if first is Node3D:
				body.global_transform = Transform3D((first as Node3D).global_basis.orthonormalized(),
					(first as Node3D).global_position)
			else:
				body.global_transform = Transform3D(frame["basis"], frame["center"])
			for mesh: Node3D in own:
				for drawn: VisualInstance3D in _drawn(mesh):
					var aabb := drawn.get_aabb()
					var scale := drawn.global_basis.get_scale()
					var at := drawn.global_transform * aabb.get_center()
					volume += _add_box(body, Transform3D(drawn.global_basis.orthonormalized(), at), aabb.size * scale)
		if body.get_child_count() == 0:
			volume += _add_box(body, body.global_transform, Vector3.ONE * 0.2)
		body.mass = maxf(volume * DENSITY, 1.0)
		body.gravity_scale = gravity
		body.linear_damp = 0.2
		body.angular_damp = SPIN_DAMP
		body.collision_mask = 1 | PhysicsLayers.FIXED
		body.physics_material_override = _rough
		for mesh: Node3D in own:
			_homes.append([mesh, mesh.get_parent(), mesh.transform])
			mesh.reparent(body, true)
		body.linear_velocity = velocity
		body.angular_velocity = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 0.6
		made.append(body)
		bodies.append(body)
	for index in range(1, _parts.size()):
		var child := made[index]
		var parent := made[int(_parts[index]["parent"])] if int(_parts[index]["parent"]) < made.size() else null
		if child == null or parent == null:
			continue
		var joint := ConeTwistJoint3D.new()
		world.add_child(joint)
		_joints.append(joint)
		var at: Vector3 = _parts[index]["joint"]
		if not at.is_finite():
			at = _near_end(child, parent.global_position)
		joint.global_transform = Transform3D(Basis.looking_at((child.global_position - at).normalized()
			if (child.global_position - at).length() > 0.01 else Vector3.DOWN, Vector3.UP
			if absf((child.global_position - at).normalized().y) < 0.95 else Vector3.BACK), at)
		joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(SWING))
		joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(TWIST))
		joint.node_a = joint.get_path_to(parent)
		joint.node_b = joint.get_path_to(child)
	# Los pedazos de un mismo cuerpo no chocan entre ellos (sus cajas se pisan: el hombro dentro del torso).
	for a in bodies.size():
		for b in range(a + 1, bodies.size()):
			bodies[a].add_collision_exception_with(bodies[b])
	_made = made
	_anchors.clear()
	for index in _parts.size():
		var nodes: Array = _parts[index]["nodes"]
		_anchors.append(_root if index == 0 else (nodes[0] if not nodes.is_empty() else null))
	_root.set_meta(META, self)


## ── LEVANTARSE (18/11/2026; el usuario: «la capacidad de recuperarse, aunque no haga falta aún, así cuando la queramos
## usar ya está lista y hay unificación de código») ──────────────────────────────────────────────────────────────────
## El cuerpo vivo se para donde quedó el tronco (sin andar todavía) y cada pedazo va de donde quedó tirado a su hueso en
## `time` s, con LA MEZCLA DE LOS PERSONAJES (RagdollBlend: el tronco con su lugar y su giro; cada otro, su giro respecto
## del padre y su lugar sobre él). Al terminar, cada malla vuelve a colgar de donde salió, los pedazos se van y el cuerpo
## vuelve a andar. Quien lo
## llama le devuelve antes la vida (Health) si hace falta. *Hoy la meca sólo se desarma al morir y no se levanta: queda
## lista para cuando se use (tests/ragdoll_rise_check).*
const META := "ragdoll"


## El ragdoll en el que está desarmado `body` (o null).
static func of(body: Node) -> PartsRagdoll:
	return body.get_meta(META) as PartsRagdoll if body != null and body.has_meta(META) else null


## SE LEVANTA en `time` s (ver arriba). Devuelve si arrancó.
func get_up(time := 0.8) -> bool:
	if _riser != null or _made.is_empty() or _made[0] == null:
		return false
	for joint in _joints:
		if is_instance_valid(joint):
			joint.queue_free()
	_joints.clear()
	_starts.clear()
	for body: Variant in _made:
		var piece := body as RigidBody3D
		if piece != null:
			piece.freeze = true
			piece.collision_layer = 0
			piece.collision_mask = 0
			_starts.append(piece.global_transform)
		else:
			_starts.append(Transform3D())
	# El cuerpo vivo, parado donde quedó el tronco, mirando hacia donde mira (de costado).
	var core := _made[0] as RigidBody3D
	var ahead := -core.global_basis.z
	ahead.y = 0.0
	if ahead.length() < 0.01:
		ahead = core.global_basis.y
		ahead.y = 0.0
	var yaw := atan2(-ahead.x, -ahead.z) if ahead.length() > 0.01 else 0.0
	# PARADO DONDE QUEDÓ EL TRONCO, SIN ANDAR TODAVÍA: lo suyo busca sus mallas cada cuadro (la torreta del artillero,
	# por ejemplo), y hasta `_stand` están en los pedazos. `put` lo para ahí con su pose de parado, y hacia esa pose van.
	if _root is BalanceBody:
		(_root as BalanceBody).state = BalanceBody.State.STANDING
	if _root.has_method("put"):
		_root.call("put", Transform3D(Basis(Vector3.UP, yaw), _floor_under(core.global_position)))
	_rise_time = maxf(time, 0.05)
	_rise_left = _rise_time
	_riser = _Riser.new()
	_riser.name = "Levantándose"
	(_riser as _Riser).ragdoll = self
	core.get_parent().add_child(_riser)
	return true


## Si se está levantando.
func rising() -> bool:
	return _riser != null


## Un paso de levantarse (lo llama `_Riser`).
func _rise_step(delta: float) -> void:
	_rise_left -= delta
	var t := 1.0 - clampf(_rise_left / _rise_time, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	var core := _made[0] as RigidBody3D
	RagdollBlend.place_root(core, _root, _starts[0], _starts[0].origin.lerp(_root.global_position, eased), eased)
	for index in range(1, _made.size()):
		var piece := _made[index] as RigidBody3D
		var bone := _anchors[index] as Node3D
		if piece == null or bone == null:
			continue
		var parent := int(_parts[index]["parent"])
		var parent_piece := _made[parent] as RigidBody3D
		var parent_bone := _anchors[parent] as Node3D
		if parent_piece != null and parent_bone != null:
			RagdollBlend.place_child(piece, bone, parent_piece, parent_bone, _starts[index], _starts[parent], eased)
		else:
			RagdollBlend.place_loose(piece, bone, core, _root, _starts[index], eased)
	if _rise_left <= 0.0:
		_stand()


## TERMINÓ DE LEVANTARSE: cada malla vuelve a donde salió, los pedazos se van y el cuerpo vivo se ve.
func _stand() -> void:
	for home: Array in _homes:
		var mesh := home[0] as Node3D
		var parent := home[1] as Node
		if not is_instance_valid(mesh) or not is_instance_valid(parent):
			continue
		mesh.get_parent().remove_child(mesh)
		parent.add_child(mesh)
		mesh.transform = home[2]
	_homes.clear()
	for body: Variant in _made:
		if body != null and is_instance_valid(body):
			(body as Node).queue_free()
	_made.clear()
	bodies.clear()
	_root.visible = true
	_root.process_mode = Node.PROCESS_MODE_INHERIT
	_root.remove_meta(META)
	_riser.queue_free()
	_riser = null


## El piso debajo de `at` (lo fijo del mundo); sin piso, a la altura de `at`.
func _floor_under(at: Vector3) -> Vector3:
	var space := _root.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 2.0, at + Vector3.DOWN * 60.0, PhysicsLayers.FIXED)
	var hit := space.intersect_ray(query)
	return hit["position"] if not hit.is_empty() else at


## Lo que mueve la mezcla en cada paso de física mientras se levanta.
class _Riser extends Node:
	var ragdoll: PartsRagdoll = null

	func _physics_process(delta: float) -> void:
		if ragdoll != null:
			ragdoll._rise_step(delta)


## UNA CAJA de `size` m en `where` (el mundo) dentro de `body`. Devuelve su volumen (m³).
static func _add_box(body: RigidBody3D, where: Transform3D, size: Vector3) -> float:
	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = size.abs().max(Vector3.ONE * 0.05)
	shape.shape = cube
	body.add_child(shape)
	shape.global_transform = where
	return cube.size.x * cube.size.y * cube.size.z


## LO VUELCA con `push` (m/s): a cada pedazo, lo de costado por la parte de su altura (0 el más bajo, 1 el más alto) por
## `rate`: lo de arriba sale más, como un golpe arriba.
func topple(push: Vector3, rate: float) -> void:
	var flat := Vector3(push.x, 0.0, push.z)
	var lowest := INF
	var highest := -INF
	for piece in bodies:
		lowest = minf(lowest, piece.global_position.y)
		highest = maxf(highest, piece.global_position.y)
	for piece in bodies:
		var share := (piece.global_position.y - lowest) / maxf(highest - lowest, 0.01)
		piece.linear_velocity += flat * share * rate


## SE DESARMA `body` (al morir): sus partes (la meca, las de sus piernas y brazos; otro cuerpo, las que dice su
## `ragdoll_parts`), con su velocidad, y el cuerpo vivo se apaga (sale de la física y de los pasos).
static func fall_apart(body: Node3D) -> PartsRagdoll:
	var ragdoll := PartsRagdoll.new(body)
	var velocity := Vector3.ZERO
	if body is BalanceBody and (body as BalanceBody).mover != null:
		var mover := (body as BalanceBody).mover
		velocity = mover.velocity
		_mech_parts(ragdoll, body as BalanceBody)
	else:
		if body.get("velocity") is Vector3:
			velocity = body.get("velocity")
		if body.has_method("ragdoll_parts"):
			body.call("ragdoll_parts", ragdoll)
	# COMO LO EMPUJÓ EL GOLPE QUE LO MATÓ (Health.push): sale con eso y se vuelca hacia allá.
	var push := Vector3.ZERO
	var health := Health.of(body)
	if health != null:
		push = health.push
	# Sin el destello del golpe (lo apaga la reacción, que se apaga con el cuerpo vivo: quedaba blanco).
	for reaction in body.find_children("*", "HitReaction", false, false):
		reaction.call("clear")
	var world := body.get_parent()
	var thrown := Vector3(push.x, 0.0, push.z) * PUSH_SHARE + Vector3.UP * push.y * LIFT_SHARE
	# Con empujón, manda el del golpe (el motor ya lo había empezado: no se suma dos veces); sin él, lo que traía.
	if push != Vector3.ZERO:
		velocity = Vector3.ZERO
	ragdoll.activate(world, velocity + thrown)
	ragdoll.topple(thrown, TOPPLE)
	body.process_mode = Node.PROCESS_MODE_DISABLED
	body.visible = false
	return ragdoll


## EL ESQUELETO DE UNA MECA (BalanceBody con su MechSkeleton): UN PEDAZO POR HUESO, unido a su padre donde nace el
## hueso (el origen del hueso: la cintura, la cadera, la rodilla, el tobillo, el hombro, el codo). El tronco, con su
## caja de verdad (la del cuerpo); la pelvis con sus caderas fijas, un solo pedazo; lo que lleva la punta del brazo va
## con el antebrazo. Las partes se juntan de la más chica a la más grande, así cada hueso se lleva lo suyo y no lo de
## sus hijos.
static func _mech_parts(ragdoll: PartsRagdoll, body: BalanceBody) -> void:
	ragdoll.set_core_box(body.global_transform, body.size)
	var bones := body.skeleton
	if bones == null:
		return
	var pelvis := ragdoll.add([bones.pelvis], 0, bones.waist.global_position)
	for side in 2:
		var thigh := ragdoll.add([bones.thighs[side]], pelvis, bones.thighs[side].global_position)
		var shin := ragdoll.add([bones.shins[side]], thigh, bones.shins[side].global_position)
		ragdoll.add([bones.feet[side]], shin, bones.feet[side].global_position)
		var upper := ragdoll.add([bones.uppers[side]], 0, bones.uppers[side].global_position)
		var forearm: Array = [bones.forearms[side]]
		if body is Mech and side < (body as Mech).arms.size():
			var arm := (body as Mech).arms[side]
			if arm.tip != null:
				forearm.append(arm.tip)
		ragdoll.add(forearm, upper, bones.forearms[side].global_position)


## Las mallas visibles debajo de `node` (las de más arriba: lo que cuelga de ellas va con ellas), sin las ya tomadas.
func _collect(node: Node, out: Array, taken: Dictionary) -> void:
	if taken.has(node):
		return
	if node is GeometryInstance3D and not (node is Label3D) and not (node is GPUParticles3D):
		if (node as Node3D).is_visible_in_tree():
			out.append(node)
			taken[node] = true
		return
	for child in node.get_children():
		_collect(child, out, taken)


## LA CAJA QUE ENVUELVE `meshes`, en los ejes `axes` (el tronco, los del cuerpo) o, sin ellos (`Basis()`), en los de
## la primera malla con dibujo: {basis, center, size}.
func _box(meshes: Array, axes := Basis()) -> Dictionary:
	if axes == Basis():
		for mesh: Node3D in meshes:
			var drawn := _drawn(mesh)
			if not drawn.is_empty():
				axes = (drawn[0] as Node3D).global_basis.orthonormalized()
				break
	var low := Vector3.INF
	var high := -Vector3.INF
	for mesh: Node3D in meshes:
		for drawn: VisualInstance3D in _drawn(mesh):
			var aabb := drawn.get_aabb()
			for corner in 8:
				var point := drawn.global_transform * aabb.get_endpoint(corner)
				var local := axes.inverse() * point
				low = low.min(local)
				high = high.max(local)
	if not low.is_finite():
		var at := (meshes[0] as Node3D).global_position
		return {"basis": axes, "center": at, "size": Vector3.ONE * 0.2}
	return {"basis": axes, "center": axes * ((low + high) * 0.5), "size": high - low}


## Lo que se dibuja de verdad debajo de `node` (las mallas con malla).
static func _drawn(node: Node) -> Array:
	var out := []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node)
	for child in node.get_children():
		out.append_array(_drawn(child))
	return out


## La punta de la caja de `body` más cerca de `toward` (la articulación): sobre su eje más largo.
static func _near_end(body: RigidBody3D, toward: Vector3) -> Vector3:
	var size := ((body.get_child(0) as CollisionShape3D).shape as BoxShape3D).size
	var axis := 0
	if size.y > size[axis]:
		axis = 1
	if size.z > size[axis]:
		axis = 2
	var along := body.global_basis[axis].normalized() * size[axis] * 0.5
	var a := body.global_position + along
	var b := body.global_position - along
	return a if a.distance_to(toward) < b.distance_to(toward) else b
