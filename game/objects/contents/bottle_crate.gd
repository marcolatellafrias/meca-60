class_name BottleCrate
extends RefCounted
## Cajón de botellas de época: caja de madera abierta arriba, con separadores, y una botella por
## compartimento. La durabilidad es cuántas botellas llegan adentro (ver PackageContents).
##
## Las botellas sobresalen del borde como en un cajón de verdad: el borde las contiene a medias, así
## que inclinarlo mucho o darlo vuelta es lo que las tira. Los separadores son bajos a propósito para
## que una botella pueda volcar por encima de ellos; son la perilla de cuánto perdona el cajón.
##
## DOS MODELOS, el cajón y la botella, cada uno con su caja (ver ModelBox y `write_crate_box`, `write_bottle_box`):
## la botella se modela una vez y se repite. Mientras no haya `.glb`, cada uno dibuja su boceto. La colisión no
## depende del modelo: son las tablas del cajón y el cilindro de cada botella.

## Exterior en celdas de grabbable. Alto de 2 celdas → una sola fila de grab points a media altura, así
## el agarre no lo inclina de entrada (ver GrabbableInteractable._orientation_error). Cinco de ancho para que entren
## tres botellas gruesas con aire (ver BOTTLE_RADIUS).
const CELLS := Vector3i(5, 2, 6)
const COLS := 3  # compartimentos a lo ancho (X)
const ROWS := 4  # compartimentos a lo largo (Z)
const CRATE_MASS := 3.0
const WALL := 0.015
const DIVIDER := 0.008
const DIVIDER_HEIGHT := 0.5  # fracción del alto del cajón

## LA BOTELLA ES GRUESA: lo que se usa fuera de un tablero no es diminuto, su lado más corto mide al menos una
## celda (conceptual/objects.md, Package standards). 11 cm de diámetro; antes eran 6,6.
const BOTTLE_RADIUS := 0.055
const BOTTLE_HEIGHT := 0.30
const BOTTLE_MASS := 1.0
const NECK_FRACTION := 0.3  # parte de la altura que es cuello

## Margen de la caja de contención más allá de las paredes.
const CONTAIN_MARGIN := 0.01

## Dónde van sus modelos: con los paquetes. El cajón, con la clave del paquete.
const MODEL_AREA := "packages"
const CRATE_KEY := "crate_bottles"
const BOTTLE_KEY := "bottle"

const WOOD := Color(0.55, 0.38, 0.22)
const GLASS := Color(0.22, 0.45, 0.28, 0.85)
const CAP := Color(0.75, 0.7, 0.55)


static func crate_size() -> Vector3:
	return Vector3(CELLS) * GrabbableInteractable.CELL_SIZE


static func bottle_size() -> Vector3:
	return Vector3(BOTTLE_RADIUS * 2.0, BOTTLE_HEIGHT, BOTTLE_RADIUS * 2.0)


static func build() -> RigidBody3D:
	var size := crate_size()
	var half := size * 0.5
	var body := RigidBody3D.new()
	body.mass = CRATE_MASS
	body.collision_layer = 1 | PackageContents.LAYER  # el mundo lo toca a él; sus botellas también

	for slab: Array in _slabs():
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = slab[0]
		col.shape = shape
		col.position = slab[1]
		body.add_child(col)
	var look := Node3D.new()
	look.name = "cajon"
	body.add_child(look)
	if ModelBox.load_into(look, MODEL_AREA, CRATE_KEY, size, BottleCrate._material).is_empty():
		_build_crate_sketch(look)

	# Contenido: una botella por compartimento.
	var inner := Vector3(size.x - WALL * 2.0, size.y, size.z - WALL * 2.0)
	var floor_top := -half.y + WALL
	var cell := Vector2(inner.x / COLS, inner.z / ROWS)
	var contents := PackageContents.new()
	contents.name = "Contents"  # nombre estable → mismo path en todas las máquinas (sync del conteo)
	contents.containment = AABB(
		Vector3(-half.x - CONTAIN_MARGIN, -half.y - CONTAIN_MARGIN, -half.z - CONTAIN_MARGIN),
		Vector3(size.x + CONTAIN_MARGIN * 2.0, size.y + BOTTLE_HEIGHT * 0.5 + CONTAIN_MARGIN * 2.0,
			size.z + CONTAIN_MARGIN * 2.0))
	var i := 0
	for c in COLS:
		for r in ROWS:
			var bottle := _build_bottle()
			bottle.name = "Bottle%d" % i
			i += 1
			var at := Vector3(-inner.x * 0.5 + (c + 0.5) * cell.x, floor_top + BOTTLE_HEIGHT * 0.5 + 0.002,
				-inner.z * 0.5 + (r + 0.5) * cell.y)
			contents.add_item(bottle, Transform3D(Basis(), at))
			body.add_child(bottle)
	body.add_child(contents)

	var grab := GrabbableInteractable.new()
	grab.name = "Grabbable"  # nombre estable → mismo path en todas las máquinas (grab sync)
	body.add_child(grab)
	grab.setup_from_cells(CELLS.x, CELLS.y, CELLS.z)
	grab.show_debug_points()

	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 4
	label.pixel_size = 0.004
	label.position.y = half.y + BOTTLE_HEIGHT * 0.5 + 0.25
	body.add_child(label)
	var refresh := func(intact: int, total: int) -> void:
		label.text = "botellas %d/%d" % [intact, total]
	refresh.call(contents.intact, contents.total)
	contents.intact_changed.connect(refresh)
	return body


## LAS TABLAS DEL CAJÓN, `[tamaño, centro]`: el piso, las cuatro paredes a alto completo y los separadores bajos,
## apoyados en el piso. Una sola lista para la colisión y el boceto.
static func _slabs() -> Array:
	var size := crate_size()
	var half := size * 0.5
	var out := [[Vector3(size.x, WALL, size.z), Vector3(0.0, -half.y + WALL * 0.5, 0.0)]]
	for sx in [-1.0, 1.0]:
		out.append([Vector3(WALL, size.y, size.z), Vector3(sx * (half.x - WALL * 0.5), 0.0, 0.0)])
	for sz in [-1.0, 1.0]:
		out.append([Vector3(size.x - WALL * 2.0, size.y, WALL), Vector3(0.0, 0.0, sz * (half.z - WALL * 0.5))])
	var inner := Vector3(size.x - WALL * 2.0, size.y, size.z - WALL * 2.0)
	var div_h := size.y * DIVIDER_HEIGHT
	var div_y := -half.y + WALL + div_h * 0.5
	var cell := Vector2(inner.x / COLS, inner.z / ROWS)
	for c in range(1, COLS):
		out.append([Vector3(DIVIDER, div_h, inner.z), Vector3(-inner.x * 0.5 + c * cell.x, div_y, 0.0)])
	for r in range(1, ROWS):
		out.append([Vector3(inner.x, div_h, DIVIDER), Vector3(0.0, div_y, -inner.z * 0.5 + r * cell.y)])
	return out


static func _build_crate_sketch(parent: Node3D) -> void:
	var wood := _material(WOOD)
	for slab: Array in _slabs():
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = slab[0]
		mesh.material = wood
		mi.mesh = mesh
		mi.position = slab[1]
		parent.add_child(mi)


static func _build_bottle() -> RigidBody3D:
	var b := RigidBody3D.new()
	b.mass = BOTTLE_MASS
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = BOTTLE_RADIUS
	shape.height = BOTTLE_HEIGHT
	col.shape = shape
	b.add_child(col)
	if ModelBox.load_into(b, MODEL_AREA, BOTTLE_KEY, bottle_size(), BottleCrate._material).is_empty():
		_build_bottle_sketch(b)
	return b


static func _build_bottle_sketch(parent: Node3D) -> void:
	var glass := _material(GLASS)
	glass.roughness = 0.15
	var cap := _material(CAP)
	cap.metallic = 0.6
	var body_h := BOTTLE_HEIGHT * (1.0 - NECK_FRACTION)
	var neck_h := BOTTLE_HEIGHT * NECK_FRACTION
	var base := -BOTTLE_HEIGHT * 0.5
	_add_cylinder(parent, glass, BOTTLE_RADIUS, BOTTLE_RADIUS, body_h, base + body_h * 0.5)
	# Hombro + cuello en un solo cono truncado, y la chapa arriba, que termina en el techo de la caja.
	_add_cylinder(parent, glass, BOTTLE_RADIUS * 0.35, BOTTLE_RADIUS, neck_h - 0.012, base + body_h + (neck_h - 0.012) * 0.5)
	_add_cylinder(parent, cap, BOTTLE_RADIUS * 0.4, BOTTLE_RADIUS * 0.4, 0.012, base + BOTTLE_HEIGHT - 0.006)


## El material de una pieza, del boceto o del modelo (ModelBox.load_into le pasa el color de Blender): con
## transparencia si el color la tiene, como el vidrio.
static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


static func _add_cylinder(parent: Node3D, mat: Material, top: float, bottom: float, h: float, y: float) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = h
	mesh.radial_segments = 10
	mesh.rings = 1
	mesh.material = mat
	mi.mesh = mesh
	mi.position.y = y
	parent.add_child(mi)


## LAS CAJAS PARA BLENDER (ver ModelBox.write_box), una por modelo, con el boceto como referencia. Devuelven dónde
## las escribieron.
static func write_crate_box() -> String:
	var reference := Node3D.new()
	_build_crate_sketch(reference)
	var path := ModelBox.write_box(MODEL_AREA, CRATE_KEY, "Cajón de botellas", crate_size(),
		GrabbableInteractable.CELL_SIZE, {}, reference)
	reference.free()
	return path


static func write_bottle_box() -> String:
	var reference := Node3D.new()
	_build_bottle_sketch(reference)
	var path := ModelBox.write_box(MODEL_AREA, BOTTLE_KEY, "Botella", bottle_size(),
		GrabbableInteractable.CELL_SIZE, {}, reference)
	reference.free()
	return path
