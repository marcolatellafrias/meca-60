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
##   · SU CAJA: la que diga (`box`: la de verdad, como la caja de la meca, `set_core_box`) o la que envuelve su dibujo
##     (en los ejes de su primera malla). *Hasta el 18/11/2026 el tronco de la jaula envolvía todo su dibujo (la cabina,
##     las sillas, los maniquíes): más grande que la meca, y quedaba flotando en ella.*
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
const SWING := 45.0
const TWIST := 20.0
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
		var box := {}
		if given.is_empty():
			box = _box(own, _root.global_basis.orthonormalized() if index == 0 else Basis())
		else:
			var where: Transform3D = given["transform"]
			box = {"basis": where.basis.orthonormalized(), "center": where.origin, "size": given["size"]}
		var body := RigidBody3D.new()
		body.name = "Pedazo"
		body.add_to_group(GROUP)
		world.add_child(body)
		body.global_transform = Transform3D(box["basis"], box["center"])
		var shape := CollisionShape3D.new()
		var cube := BoxShape3D.new()
		cube.size = (box["size"] as Vector3).max(Vector3.ONE * 0.1)
		shape.shape = cube
		body.add_child(shape)
		body.mass = maxf(cube.size.x * cube.size.y * cube.size.z * 0.5, 1.0)
		body.gravity_scale = gravity
		# Un poco de freno: se acomoda y se queda (sin él se mece sin parar en las articulaciones).
		body.linear_damp = 0.4
		body.angular_damp = 2.5
		body.collision_mask = 1 | PhysicsLayers.FIXED
		body.physics_material_override = _rough
		for mesh: Node3D in own:
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


## EL ESQUELETO DE UNA MECA (BalanceBody con piernas y brazos): el tronco con SU CAJA DE VERDAD (la del cuerpo); la
## pelvis, unida a él en la cintura (el piso de la caja); cada pierna en tres, desde la pelvis: el muslo en la cadera, la
## canilla en la rodilla, el pie en el tobillo; y cada brazo entero, en su hombro.
static func _mech_parts(ragdoll: PartsRagdoll, body: BalanceBody) -> void:
	ragdoll.set_core_box(body.global_transform, body.size)
	var pelvis := 0
	if body.legs != null:
		var waist := body.global_transform * Vector3(0.0, -body.size.y * 0.5, 0.0)
		var pelvis_mesh = body.legs.get("_pelvis")
		if pelvis_mesh != null:
			pelvis = ragdoll.add([pelvis_mesh], 0, waist)
		for leg: MechLeg in body.legs.get("_legs"):
			var hip := leg.get("_hip") as Node3D
			var knee := leg.get("_knee") as Node3D
			var ankle := leg.get("_ankle") as Node3D
			var thigh := ragdoll.add([leg.get("_thigh"), hip], pelvis, hip.global_position)
			var shin := ragdoll.add([leg.get("_shin"), knee], thigh, knee.global_position)
			ragdoll.add([leg.get("_foot"), ankle], shin, ankle.global_position)
	if body is Mech:
		var mech := body as Mech
		for arm: MechArm in mech.arms:
			ragdoll.add([arm], 0, mech.global_transform * arm.shoulder_local)


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
