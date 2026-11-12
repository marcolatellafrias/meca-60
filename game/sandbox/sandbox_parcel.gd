class_name SandboxParcel
extends Node3D

## UNA PARCELA DEL SANDBOX: un arquetipo, su semilla actual y el individuo armado encima. Alrededor, la zona de
## interacción (un marco): estando adentro, el panel muestra la parcela y valen sus teclas. El tamaño sale del
## `max_footprint` del arquetipo una sola vez.
##
## ── LOS BORDES (como los de character-parametric: SandboxParcel._build_bounds de allá) ──────────────────────────────
## Cuatro paredes invisibles en el borde de la parcela (no de su zona de interacción), de `BOUND_H` de alto, en su capa
## (PhysicsLayers.PARCEL_BOUND): las ve sólo lo que se mueve con física y vive en una parcela —el cubo, la meca de
## equilibrio y sus partes caídas, las personas, los paquetes—, que la suma a lo que choca al aparecer
## (`_on_node_added`). El jugador no vive en una parcela: pasa; y la bola que se tira desde afuera se la saca (ver
## TestBall). Lo que se mueve por código (las mecas de pelea) le pregunta a su parcela con `holds`. Lo pidió el usuario
## el 11/11/2026: «las parcelas deberían tener paredes invisibles que eviten que sus contenidos se escapen».

const PLANE_LIFT := 0.002
const FRAME_LIFT := 0.01
const FRAME_WIDTH := 0.08
const PARCEL_COLOR := Color(0.74, 0.72, 0.68)
const FRAME_COLOR := Color(0.55, 0.53, 0.5)
const LABEL_COLOR := Color(0.3, 0.29, 0.27)
const BOUND_H := 20.0
const BOUND_THICK := 0.5

var archetype: SeededArchetype = null
var category := ""
var seed_value := 0
var size := Vector2.ZERO
## Cuánto sale la zona de interacción alrededor de la parcela, igual en los cuatro lados.
var interact_pad := 0.0

var _root: Node3D = null
## Cuántas parcelas hay en el árbol: mientras haya alguna, el árbol avisa de cada nodo nuevo (ver `_on_node_added`).
static var _alive := 0


func setup(p_archetype: SeededArchetype, p_category: String, p_size: Vector2, p_pad: float, p_seed: int) -> void:
	archetype = p_archetype
	category = p_category
	size = p_size
	interact_pad = p_pad
	name = "%s · %s" % [category, archetype.display_name]
	_draw()
	_build_bounds()
	regenerate(p_seed)


func _enter_tree() -> void:
	_alive += 1
	if not get_tree().node_added.is_connected(SandboxParcel._on_node_added):
		get_tree().node_added.connect(SandboxParcel._on_node_added)


func _exit_tree() -> void:
	_alive -= 1
	if _alive <= 0 and get_tree().node_added.is_connected(SandboxParcel._on_node_added):
		get_tree().node_added.disconnect(SandboxParcel._on_node_added)


## La parcela donde vive `node` (la primera hacia arriba), o null.
static func owner_of(node: Node) -> SandboxParcel:
	var up := node
	while up != null:
		if up is SandboxParcel:
			return up as SandboxParcel
		up = up.get_parent()
	return null


## LO QUE SE MUEVE CON FÍSICA ADENTRO DE UNA PARCELA ve sus bordes (ver LOS BORDES).
static func _on_node_added(node: Node) -> void:
	if (node is RigidBody3D or node is CharacterBody3D) and owner_of(node) != null:
		(node as CollisionObject3D).collision_mask |= PhysicsLayers.PARCEL_BOUND


## Si un círculo de `radius` alrededor de `at` (en el mundo) queda adentro de la parcela: para lo que se mueve por código
## y no choca con los bordes (las mecas de pelea).
func holds(at: Vector3, radius: float) -> bool:
	var local := to_local(at)
	return absf(local.x) <= size.x * 0.5 - radius and absf(local.z) <= size.y * 0.5 - radius


func _build_bounds() -> void:
	var walls := StaticBody3D.new()
	walls.name = "Bordes"
	walls.collision_layer = PhysicsLayers.PARCEL_BOUND
	walls.collision_mask = 0
	var half := size * 0.5
	for side: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var box := BoxShape3D.new()
		var along := size.y if side.x != 0.0 else size.x
		box.size = Vector3(BOUND_THICK, BOUND_H, along + BOUND_THICK * 2.0) if side.x != 0.0 \
			else Vector3(along + BOUND_THICK * 2.0, BOUND_H, BOUND_THICK)
		var shape := CollisionShape3D.new()
		shape.shape = box
		shape.position = Vector3(side.x * (half.x + BOUND_THICK * 0.5), BOUND_H * 0.5 - 1.0,
			side.z * (half.y + BOUND_THICK * 0.5))
		walls.add_child(shape)
	add_child(walls)


## Lo que armó el arquetipo, o null.
func root() -> Node3D:
	return _root if is_instance_valid(_root) else null


## (`_flash`: el destello de la parcela que se rearma, de allá; acá no hay destello.)
func regenerate(p_seed: int, _flash := true) -> void:
	seed_value = p_seed
	if is_instance_valid(_root):
		_root.queue_free()
	_root = archetype.build(seed_value, self)


## La zona de interacción, en el plano XZ del mundo.
func interaction_rect() -> Rect2:
	var half := size * 0.5 + Vector2.ONE * interact_pad
	return Rect2(Vector2(global_position.x, global_position.z) - half, half * 2.0)


func contains(at: Vector3) -> bool:
	return interaction_rect().has_point(Vector2(at.x, at.z))


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray([
		"%s · %s" % [category, archetype.display_name],
		"semilla %d" % seed_value,
	])
	lines.append_array(archetype.describe(seed_value))
	return lines


func _draw() -> void:
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	plane.mesh = mesh
	plane.material_override = _flat(PARCEL_COLOR)
	plane.position.y = PLANE_LIFT
	add_child(plane)

	# El marco de la zona de interacción: cuatro tiras.
	var outer := size + Vector2.ONE * interact_pad * 2.0
	for side in 4:
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		var along_x := side < 2
		box.size = Vector3(outer.x if along_x else FRAME_WIDTH, 0.005, FRAME_WIDTH if along_x else outer.y)
		strip.mesh = box
		strip.material_override = _flat(FRAME_COLOR)
		var sign_side := -1.0 if side % 2 == 0 else 1.0
		strip.position = Vector3(0.0 if along_x else sign_side * outer.x * 0.5, FRAME_LIFT,
			sign_side * outer.y * 0.5 if along_x else 0.0)
		add_child(strip)

	var label := Label3D.new()
	label.text = archetype.display_name
	label.font_size = 64
	label.pixel_size = 0.004
	label.modulate = LABEL_COLOR
	label.outline_size = 0
	label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	label.position = Vector3(0.0, FRAME_LIFT + 0.01, size.y * 0.5 + interact_pad * 0.5)
	add_child(label)


static func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


## Lo que suma a lo que choca quien vive en una parcela: su borde (0 afuera). Para quien rehace su máscara después de
## aparecer —el cuerpo caído de una persona de character-parametric, que lo pide—.
static func bound_mask(node: Node) -> int:
	return PhysicsLayers.PARCEL_BOUND if owner_of(node) != null else 0
