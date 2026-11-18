class_name PartsRagdoll
extends RefCounted

## ── EL RAGDOLL AL MORIR, PARA CUALQUIER CUERPO HECHO DE PIEZAS (18/11/2026; módulo Jefes, el sistema común) ─────────
## El usuario: «todos (la meca propia, los jefes, los personajes) se caen con ragdoll al morir; los grandes, quizás más
## lento para que se lea la escala». Los personajes tienen el suyo, de huesos (RagdollUtil); éste es el de los cuerpos
## de piezas: la meca jaula y los jefes.
##   · CADA PARTE (`add`: una lista de nodos del dibujo) pasa a ser UN CUERPO FÍSICO con una caja que la envuelve (en los
##     ejes de su primera malla). LO QUE NO ES DE NINGUNA PARTE va al TRONCO (`core`, la parte 0).
##   · LAS PARTES SE UNEN con una articulación que dobla con límite (ConeTwistJoint3D) a la que dicen (`parent`), en la
##     punta de la parte que queda más cerca de ella (la cadera de un muslo, la rodilla de una canilla).
##   · HEREDAN LA VELOCIDAD del cuerpo (`velocity`) y un poco de giro.
##   · LOS GRANDES CAEN MÁS LENTO: la gravedad, por su tamaño (`gravity_for`): una meca jaula de 4 m, entera; un jefe de
##     20 m, la mitad.
## Las mallas se mudan a los cuerpos nuevos (en el mismo lugar del mundo); el cuerpo vivo lo apaga quien lo llama.

## Tamaño (m) hasta el que la gravedad es la de siempre, y lo menos que baja.
const FULL_GRAVITY_SIZE := 6.0
const LEAST_GRAVITY := 0.4
## Cuánto dobla una articulación (°) y cuánto se tuerce.
const SWING := 45.0
const TWIST := 20.0
## Cuánto se vuelca al morir (rad/s: la velocidad hacia atrás de cada pedazo, por metro de alto).
const TOPPLE := 0.8
## El grupo de los pedazos (para encontrarlos).
const GROUP := "pedazos"

## Las partes: {nodes, parent}. La 0 es el tronco.
var _parts: Array[Dictionary] = [{"nodes": [], "parent": -1}]
var _root: Node3D = null
## Los cuerpos que quedaron (para las pruebas).
var bodies: Array[RigidBody3D] = []


## Lo que se va a desarmar: `root`, el cuerpo entero (lo que no sea de ninguna parte, al tronco).
func _init(root: Node3D) -> void:
	_root = root


## UNA PARTE: sus nodos del dibujo (con lo que cuelga de ellos) y a qué parte se une (0, el tronco). Devuelve su índice.
func add(nodes: Array, parent := 0) -> int:
	_parts.append({"nodes": nodes, "parent": parent})
	return _parts.size() - 1


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
		var box := _box(own, _root.global_basis.orthonormalized() if index == 0 else Basis())
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
		var at := _near_end(child, parent.global_position)
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


## LO VUELCA hacia `way`: a cada pedazo, `rate` m/s por cada metro que está más alto que el más bajo.
func topple(way: Vector3, rate: float) -> void:
	var lowest := INF
	for piece in bodies:
		lowest = minf(lowest, piece.global_position.y)
	for piece in bodies:
		piece.linear_velocity += way * (piece.global_position.y - lowest) * rate


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
	var world := body.get_parent()
	ragdoll.activate(world, velocity + Vector3.UP * 1.5)
	# SE VUELCA: lo de arriba sale hacia atrás (más cuanto más alto), así no se queda sentado en su lugar.
	var back := body.global_basis.z
	back.y = 0.0
	ragdoll.topple(back.normalized() if back.length() > 0.01 else Vector3.BACK, TOPPLE)
	body.process_mode = Node.PROCESS_MODE_DISABLED
	body.visible = false
	return ragdoll


## LAS PARTES DE UNA MECA (BalanceBody con piernas y brazos): cada pierna en tres (el muslo con la cadera, la canilla
## con la rodilla, el pie con el tobillo, encadenados desde el tronco) y cada brazo entero.
static func _mech_parts(ragdoll: PartsRagdoll, body: BalanceBody) -> void:
	if body.legs != null:
		for leg: MechLeg in body.legs.get("_legs"):
			var thigh := ragdoll.add([leg.get("_thigh"), leg.get("_hip")], 0)
			var shin := ragdoll.add([leg.get("_shin"), leg.get("_knee")], thigh)
			ragdoll.add([leg.get("_foot"), leg.get("_ankle")], shin)
	if body is Mech:
		for arm: Node3D in (body as Mech).arms:
			ragdoll.add([arm], 0)


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
