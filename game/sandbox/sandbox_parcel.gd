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
## el 11/11/2026: «las parcelas deberían tener paredes invisibles que eviten que sus contenidos se escapen». Van en el
## borde de la parcela y no en el de la zona de interacción: los objetos viven en la parcela; uno, en toda la zona.
##
## ── LA ZONA DE INTERACCIÓN (`pad_for`) ───────────────────────────────────────────────────────────────────────────
## Sale lo mismo en los cuatro lados: una parte del lado más largo, nunca menos de `PAD_MIN` ni más de `PAD_MAX`. Así
## una parcela grande deja alejarse para mirar lo que hace una tecla sin salirse (el usuario, 13/11/2026: «me quiero
## alejar para apretar una tecla… pero se me sale de la zona de interacción»). Era 2 m fijos.
##
## ── CUÁNDO SE ARMA Y LO DE LEJOS (ver SandboxRow.Build) ──────────────────────────────────────────────────────────
## Nace sin armar: su piso, su marco y su nombre. Se arma la primera vez que uno se acerca (NEAR) o sólo con la R
## parado en ella (ON_KEY). De lejos (`set_far`), lo armado se esconde y se pausa —deja de procesar y sale de la física—
## y en su lugar va un cubo gris de la medida de lo que había; de cerca vuelve igual que estaba. UNA SIN ARMAR TAMBIÉN
## TIENE SU CUBO DE LEJOS (el usuario, 13/11/2026: «las cajas me parecen una buena forma de ubicarme… si está fuera de
## rango debería verse siempre»): del tamaño de su parcela y del alto que diga su arquetipo (`far_height`); al armarse
## pasa a la medida de verdad.
##
## ── EL CARTEL ────────────────────────────────────────────────────────────────────────────────────────────────────
## Su nombre, parado en el borde y siempre de frente (ver SandboxLayout.signpost). El alto de la letra sale del ancho de su
## zona (`SIGN_SHARE`, entre `SIGN_MIN` y `SIGN_MAX`), sin pasarse de ese ancho: una parcela grande se lee de lejos.

const PLANE_LIFT := 0.002
const FRAME_LIFT := 0.01
const FRAME_WIDTH := 0.08
const PARCEL_COLOR := Color(0.74, 0.72, 0.68)
const FRAME_COLOR := Color(0.55, 0.53, 0.5)
const LABEL_COLOR := Color(0.3, 0.29, 0.27)
const BOUND_H := 20.0
const BOUND_THICK := 0.5
const PAD_SHARE := 0.2
const PAD_MIN := 3.0
const PAD_MAX := 15.0
## El cubo de una parcela lejana (ver `set_far`).
const FAR_COLOR := Color(0.6, 0.6, 0.62)
## El cartel de una parcela que se arma con la R y todavía no se armó.
const ON_KEY_HINT := "R: armarla"
const SIGN_SHARE := 0.04
const SIGN_MIN := 0.25
const SIGN_MAX := 2.5
## Cuánto del alto de la letra ocupa de ancho cada carácter, para que el cartel no se pase de la zona.
const SIGN_CHAR_SHARE := 0.55

var archetype: SeededArchetype = null
var category := ""
## La fila que la declaró (sus teclas, sus paneles, sus hermanas) y su subcategoría (vacía si va suelta).
var row: SandboxRow = null
var group := ""
var build_mode := SandboxRow.Build.NEAR
## Si ya armó su individuo (ver CUÁNDO SE ARMA).
var built := false
## Sus hermanas de fila, ella incluida: las escribe el sandbox al armar las filas.
var siblings_list: Array[SandboxParcel] = []
var seed_value := 0
var size := Vector2.ZERO
## Cuánto sale la zona de interacción alrededor de la parcela, igual en los cuatro lados.
var interact_pad := 0.0

var _root: Node3D = null
var _keys: Array[SandboxKey] = []
var _far := false
var _proxy: MeshInstance3D = null
var _proxy_for: Node3D = null
var _hint_label: Label3D = null
## Cuántas parcelas hay en el árbol: mientras haya alguna, el árbol avisa de cada nodo nuevo (ver `_on_node_added`).
static var _alive := 0


func setup(p_archetype: SeededArchetype, p_row: SandboxRow, p_group: String, p_build: SandboxRow.Build,
		p_size: Vector2, p_seed: int) -> void:
	archetype = p_archetype
	row = p_row
	category = p_row.name
	group = p_group
	build_mode = p_build
	size = p_size
	interact_pad = pad_for(p_size)
	seed_value = p_seed
	name = "%s · %s" % [category, archetype.display_name]
	_draw()
	_build_bounds()
	# Las teclas, una vez: las que chocan con el sandbox o se repiten no se montan (las avisa SandboxCatalogue.check).
	var taken := {}
	for made in archetype.keys():
		if made.problems().is_empty() and not taken.has(made.key):
			taken[made.key] = true
			_keys.append(made)


## LA ZONA DE INTERACCIÓN de una parcela de `p_size` (ver arriba).
static func pad_for(p_size: Vector2) -> float:
	return clampf(maxf(p_size.x, p_size.y) * PAD_SHARE, PAD_MIN, PAD_MAX)


## Las teclas propias de esta parcela que se pueden usar.
func own_keys() -> Array[SandboxKey]:
	return _keys


## Las de su fila que se pueden usar acá (sin las que choquen con las propias).
func row_keys() -> Array[SandboxKey]:
	var out: Array[SandboxKey] = []
	var mine := {}
	for made in _keys:
		mine[made.key] = true
	for made in row.keys:
		if made.problems().is_empty() and not mine.has(made.key):
			mine[made.key] = true
			out.append(made)
	return out


## Sus hermanas de fila, ella incluida (para las teclas de fila).
func siblings() -> Array[SandboxParcel]:
	return siblings_list


## La arma, si todavía no lo hizo.
func build() -> void:
	if not built:
		regenerate(seed_value)


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
	built = true
	if is_instance_valid(_hint_label):
		_hint_label.visible = false
	if _far:
		_far = false
		set_far(true)


## ── LO DE LEJOS ──────────────────────────────────────────────────────────────────────────────────────────────────
func is_far() -> bool:
	return _far


func set_far(far: bool) -> void:
	if far == _far:
		return
	_far = far
	var has_root := is_instance_valid(_root)
	if far:
		if has_root and _proxy_for != _root:
			_measure_proxy()
		elif not has_root and _proxy == null:
			_rough_proxy()
	if has_root:
		_root.visible = not far
		_root.process_mode = Node.PROCESS_MODE_DISABLED if far else Node.PROCESS_MODE_INHERIT
	if _proxy != null:
		_proxy.visible = far


## El cubo de una sin armar: su parcela, del alto que diga su arquetipo.
func _rough_proxy() -> void:
	var height := archetype.far_height()
	_set_proxy(Vector3(size.x, height, size.y), Vector3(0.0, height * 0.5, 0.0))


func _set_proxy(box: Vector3, centre: Vector3) -> void:
	if is_instance_valid(_proxy):
		_proxy.queue_free()
	_proxy = MeshInstance3D.new()
	_proxy.name = "De lejos"
	var cube := BoxMesh.new()
	cube.size = box.max(Vector3.ONE * 0.1)
	_proxy.mesh = cube
	_proxy.material_override = _flat(FAR_COLOR)
	_proxy.position = centre
	_proxy.visible = false
	add_child(_proxy)


## El cubo de lo que armó: la caja de todo lo que se ve, en el espacio de la parcela, sin pasarse de su borde.
func _measure_proxy() -> void:
	_proxy_for = _root
	var to_parcel := global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for node in _root.find_children("*", "GeometryInstance3D", true, false):
		var view := node as GeometryInstance3D
		if not view.is_visible_in_tree():
			continue
		var bounds := to_parcel * view.global_transform * view.get_aabb()
		if bounds.size == Vector3.ZERO:
			continue
		box = bounds if first else box.merge(bounds)
		first = false
	if first:
		_rough_proxy()
		return
	var low := Vector3(maxf(box.position.x, -size.x * 0.5), maxf(box.position.y, 0.0), maxf(box.position.z, -size.y * 0.5))
	var high := Vector3(minf(box.end.x, size.x * 0.5), maxf(box.end.y, 0.1), minf(box.end.z, size.y * 0.5))
	_set_proxy(high - low, (low + high) * 0.5)


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

	# EL CARTEL (ver arriba): del ancho de su zona, sin pasarse.
	var height := clampf(outer.x * SIGN_SHARE, SIGN_MIN, SIGN_MAX)
	var text_width := archetype.display_name.length() * height * SIGN_CHAR_SHARE
	if text_width > outer.x * 0.95:
		height = maxf(SIGN_MIN, height * outer.x * 0.95 / text_width)
	SandboxLayout.signpost(self, archetype.display_name, height, Vector3(0.0, 0.0, size.y * 0.5 + interact_pad * 0.5),
		LABEL_COLOR)
	if build_mode == SandboxRow.Build.ON_KEY:
		_hint_label = SandboxLayout.signpost(self, ON_KEY_HINT, height, Vector3.ZERO, LABEL_COLOR)


static func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


## Lo que suma a lo que choca quien vive en una parcela: su borde (0 afuera). Para quien rehace su máscara después de
## aparecer —el cuerpo caído de una persona de character-parametric, que lo pide—.
static func bound_mask(node: Node) -> int:
	return PhysicsLayers.PARCEL_BOUND if owner_of(node) != null else 0
