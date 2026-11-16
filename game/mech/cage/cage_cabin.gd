class_name CageCabin
extends MechCabin

## LA MECA JAULA (16/11/2026, de las maquetas de tests/cage_ideas_look, la 166; el usuario: «empezar a migrar esta meca
## a algo funcional… que camine… que sus tres cabinas se puedan usar»). Una cabina más de la meca (ver Mech.Cabin.CAGE),
## CHICA: las cabinas a la medida de una persona y los brazos y las piernas de la meca de siempre al 30 % (`LIMBS`; el
## usuario: «mantener estos grosores y estos largos de brazos que me gustan»).
##   · ABAJO, LA CÁPSULA DEL QUE MANEJA: una caja de 2 m de planta con la burbuja de vidrio al frente (la 144), el piso
##     adentro y la tapa de la panza. Es LA CAJA de la meca (la que choca): los hombros salen de la mitad de sus
##     costados (los de la 166: «van a estar en el módulo de abajo»).
##   · ARRIBA, LA CUBIERTA DEL DE LOS BRAZOS: sentado, dentro de un borde bajo con bisel adelante y paredes que suben
##     hacia atrás; adelante, sus controles (botonera, dos palancas y el reloj). Sólo se ven.
##   · ATRÁS, LA TORRE DEL ARTILLERO, metida en la planta: arriba, el plato que gira con su silla y el arma montada en su
##     horquilla (sólo se ve: «después lo vamos a hacer funcional»).
##   · ATRÁS, EN LA ESPALDA: el hueco de un recurso, la batería metida y la mochila del jetpack con el bisel abajo (la
##     129). Sólo se ven.
## Todo se arma desde el fondo de la caja (`_root`, a `bottom()`): las medidas de abajo son alturas desde ahí.

## Brazos y piernas: la meca de siempre al 30 %.
const LIMBS := 0.3
static var BODY := MechBody.scaled(LIMBS)
## La caja: su planta (la mitad del lado), el grosor de sus paredes y su alto (hasta la cubierta).
const HALF := 1.0
const SKIN := 0.1
const DECK_Y := 1.78
## La pared baja hasta acá; arriba, la placa de la cubierta.
const WALL_TOP := 1.66
## El piso de adentro de la cápsula.
const FLOOR := 0.12
## La ventana: el centro (también el alto de los hombros) y el radio del hueco.
const WINDOW_CENTER := 0.83
const WINDOW := 0.64
## El borde de la cubierta: su ancho, el alto de afuera y el de adentro; y lo que queda para caminar adentro (la mitad).
const RIM := 0.35
const RIM_OUT := 0.72
const RIM_IN := 0.6
const WALK := HALF - RIM
## La torre del artillero: su alto sobre la cubierta y dónde va (z, hacia atrás).
const TOWER_TALL := 1.05
const TOWER_Z := 0.72
## Lo que lleva el plato del artillero hacia adelante (el pie del arma).
const GUN_REACH := 0.35
## La mochila: su profundidad; el hueco y la batería, a qué alto y su tamaño (partes del de 72 cm).
const PACK_DEPTH := 0.38
const SLOTS_Y := 0.45
const SLOTS_K := 0.7
const SLOTS_X := 0.45

const SHELL := Color(0.6, 0.61, 0.63)
const METAL := Color(0.55, 0.57, 0.6)
const DARK := Color(0.3, 0.31, 0.34)
const DECK := Color(0.68, 0.69, 0.7)
const RIM_COLOR := Color(0.22, 0.23, 0.25)
const HOLE := Color(0.08, 0.08, 0.1)
const GLASS := Color(0.62, 0.8, 0.92, 0.3)
const JOINT := Color(0.36, 0.375, 0.4)
const CELL := Color(0.62, 0.6, 0.42)
const RED := Color(0.78, 0.18, 0.15)
const YELLOW := Color(0.95, 0.75, 0.15)
const FACE := Color(0.92, 0.9, 0.84)
## Los puestos, en el orden de las sillas.
const SEAT_NAMES := ["brazos", "artillero", "manejo"]
const DRIVER := 2

## El arma del artillero (la parte que cabecea), para cuando sea funcional.
var gun: Node3D = null
var _root: Node3D = null


## ── LAS MEDIDAS (en el espacio de la caja: el centro, en el medio) ──────────────────────────────────────────────

static func box() -> Vector3:
	return Vector3(HALF * 2.0, DECK_Y, HALF * 2.0)


static func bottom() -> float:
	return -DECK_Y * 0.5


## EL HOMBRO (el derecho; el izquierdo, espejado): afuera del costado, a la altura del centro de la ventana.
static func shoulder() -> Vector3:
	return Vector3(HALF + BODY.LEG_THICKNESS * 0.7, bottom() + WINDOW_CENTER, -0.1)


## Lo alto de la torre del artillero, desde el fondo.
static func tower_head() -> float:
	return DECK_Y + TOWER_TALL


## Donde se mira en primera persona al poseerla: la silla del que maneja, abajo. La cámara pone los ojos a la altura de
## un puesto de pie (SeatInteractable.STATION_EYE_HEIGHT) sobre este punto: se baja lo que hace falta para que queden
## a la altura de los ojos de uno sentado en ella, que es la que mira por la burbuja.
func top_seat() -> Vector3:
	if chairs.size() <= DRIVER:
		return Vector3.ZERO
	var chair := chairs[DRIVER]
	return chair.position + _root.position + Vector3(0.0, chair.eye_height - SeatInteractable.STATION_EYE_HEIGHT, 0.0)


func _ready() -> void:
	name = "Cabina jaula"
	interior = StaticBody3D.new()
	interior.name = "Interior"
	interior.collision_layer = 0
	interior.collision_mask = 0
	add_child(interior)
	_root = Node3D.new()
	_root.name = "Forma"
	_root.position = Vector3(0.0, bottom(), 0.0)
	add_child(_root)
	_pod()
	_deck()
	_tower()
	_back()
	_chair(0, Vector3(0.0, DECK_Y + 0.03, -0.3))
	_chair(1, Vector3(0.0, tower_head() + 0.2, TOWER_Z + 0.1))
	_chair(2, Vector3(0.0, FLOOR + 0.03, 0.1))


## ── LA CÁPSULA DE ABAJO ──────────────────────────────────────────────────────────────────────────────────────────

## LA CAJA: los costados, la espalda y el fondo; el frente en tiras cortadas por el círculo de la ventana; la burbuja con
## su marco; el piso de adentro y la tapa de la panza.
func _pod() -> void:
	var mid := WALL_TOP * 0.5
	for s: float in [-1.0, 1.0]:
		_part(Vector3(SKIN, WALL_TOP, HALF * 2.0), Vector3(s * (HALF - SKIN * 0.5), mid, 0.0), SHELL)
		_solid(Vector3(SKIN, WALL_TOP, HALF * 2.0), Vector3(s * (HALF - SKIN * 0.5), mid, 0.0))
	_part(Vector3(HALF * 2.0, WALL_TOP, SKIN), Vector3(0.0, mid, HALF - SKIN * 0.5), SHELL)
	_solid(Vector3(HALF * 2.0, WALL_TOP, SKIN), Vector3(0.0, mid, HALF - SKIN * 0.5))
	_part(Vector3(HALF * 2.0, 0.12, HALF * 2.0), Vector3(0.0, 0.06, 0.0), SHELL)
	# El frente (el vidrio también es pared para los de adentro).
	_solid(Vector3(HALF * 2.0, WALL_TOP, SKIN), Vector3(0.0, mid, -HALF + SKIN * 0.5))
	var outline := _circle(WINDOW, 40)
	var strips := 80
	var width := HALF * 2.0 / strips
	for i in strips:
		var x := -HALF + width * (i + 0.5)
		for band: Array in _bands(outline, x):
			var from: float = band[0]
			var to: float = band[1]
			_part(Vector3(width + 0.005, to - from, SKIN), Vector3(x, (from + to) * 0.5, -HALF + SKIN * 0.5), SHELL)
	# El marco de la ventana, tramo por tramo, y la burbuja que sobresale (media esfera).
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var along := b - a
		var bar := _part(Vector3(along.length() + 0.08, 0.09, 0.07),
			Vector3((a.x + b.x) * 0.5, WINDOW_CENTER + (a.y + b.y) * 0.5, -HALF - 0.01), RIM_COLOR)
		bar.basis = Basis(Vector3.BACK, along.angle())
	var bubble := MeshInstance3D.new()
	bubble.name = "Burbuja"
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	bubble.mesh = sphere
	bubble.material_override = Clay.material(GLASS)
	bubble.scale = Vector3(0.66, 0.66, 0.62)
	bubble.position = Vector3(0.0, WINDOW_CENTER, -HALF + SKIN * 0.5)
	_root.add_child(bubble)
	# El piso de adentro, y la tapa de la panza.
	_part(Vector3(1.8, 0.03, 1.8), Vector3(0.0, FLOOR + 0.015, 0.0), DECK)
	_solid(Vector3(1.8, 0.1, 1.8), Vector3(0.0, FLOOR - 0.05 + 0.03, 0.0))
	Clay.cylinder(_root, 0.42, 0.06, Vector3(0.0, -0.01, 0.0), RIM_COLOR)
	Clay.cylinder(_root, 0.34, 0.07, Vector3(0.0, -0.01, 0.0), HOLE)


## Los tramos de pared de la tira vertical en `x`: lo que queda entre el fondo, el hueco de la ventana y arriba.
func _bands(outline: PackedVector2Array, x: float) -> Array:
	var low := INF
	var high := -INF
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		if is_equal_approx(a.x, b.x) or x < minf(a.x, b.x) or x > maxf(a.x, b.x):
			continue
		var y := lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
		low = minf(low, y)
		high = maxf(high, y)
	if low >= high:
		return [[0.0, WALL_TOP]]
	return [[0.0, WINDOW_CENTER + low], [WINDOW_CENTER + high, WALL_TOP]]


static func _circle(radius: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		var a := TAU * i / sides
		points.append(Vector2(cos(a), sin(a)) * radius)
	return points


## ── LA CUBIERTA DEL DE LOS BRAZOS ────────────────────────────────────────────────────────────────────────────────

## La placa, el piso, el borde con bisel adelante, la pared de atrás a la altura de la torre y, a los costados, paredes
## que suben de adelante hacia atrás; adelante, sus controles.
func _deck() -> void:
	_part(Vector3(2.02, 0.12, 2.02), Vector3(0.0, DECK_Y - 0.06, 0.0), METAL)
	_part(Vector3(WALK * 2.0, 0.03, WALK * 2.0), Vector3(0.0, DECK_Y + 0.015, 0.0), DECK)
	_solid(Vector3(2.0, 0.1, 2.0), Vector3(0.0, DECK_Y - 0.05, 0.0))
	var back := Vector3(1.99, TOWER_TALL, RIM - 0.01)
	_part(back, Vector3(0.0, DECK_Y + TOWER_TALL * 0.5, WALK + RIM * 0.5), METAL)
	_solid(back, Vector3(0.0, DECK_Y + TOWER_TALL * 0.5, WALK + RIM * 0.5))
	for s: float in [-1.0, 1.0]:
		_prism(s * (WALK + RIM * 0.5), RIM - 0.01, PackedVector2Array([Vector2(-HALF, DECK_Y),
			Vector2(-HALF, DECK_Y + RIM_OUT), Vector2(HALF, DECK_Y + TOWER_TALL), Vector2(HALF, DECK_Y)]), METAL)
		_solid(Vector3(RIM - 0.01, RIM_OUT, HALF * 2.0), Vector3(s * (WALK + RIM * 0.5), DECK_Y + RIM_OUT * 0.5, 0.0))
	# El borde de adelante: la pared baja, la tapa inclinada y el labio.
	var rise := Vector2(RIM, RIM_OUT - RIM_IN)
	var front := -(WALK + RIM * 0.5)
	_part(Vector3(1.99, RIM_IN, RIM - 0.01), Vector3(0.0, DECK_Y + RIM_IN * 0.5, front), METAL)
	_solid(Vector3(1.99, RIM_OUT, RIM - 0.01), Vector3(0.0, DECK_Y + RIM_OUT * 0.5, front))
	var cap := _part(Vector3(1.99, 0.05, rise.length()), Vector3(0.0, DECK_Y + (RIM_IN + RIM_OUT) * 0.5, front), METAL)
	cap.basis = Basis(Vector3.RIGHT, -atan2(rise.y, rise.x))
	_part(Vector3(1.99, RIM_OUT - RIM_IN, RIM * 0.5 - 0.01), Vector3(0.0, DECK_Y + (RIM_IN + RIM_OUT) * 0.5,
		-(WALK + RIM * 0.75)), METAL)
	for item: Array in [[-0.5, "buttons"], [0.0, "drive"], [0.5, "dial"]]:
		_control(item[1], rise, item[0])


## UN CONTROL sobre la tapa inclinada de adelante, corrido `offset` de costado (sólo se ve).
func _control(kind: String, bevel: Vector2, offset: float) -> void:
	var outward := Vector3.FORWARD
	var up := (Vector3.UP * bevel.x - outward * bevel.y).normalized()
	var along := Vector3.RIGHT
	var plate := Node3D.new()
	plate.basis = Basis(along, up, along.cross(up))
	plate.position = outward * (WALK + RIM * 0.5) + Vector3(0.0, DECK_Y + (RIM_IN + RIM_OUT) * 0.5, 0.0) + along * offset
	_root.add_child(plate)
	match kind:
		"drive":
			for side: float in [-1.0, 1.0]:
				Clay.box(plate, Vector3(0.16, 0.06, 0.24), Vector3(side * 0.2, 0.03, 0.0), DARK)
				Clay.cylinder(plate, 0.025, 0.42, Vector3(side * 0.2, 0.24, 0.0), DARK)
				Clay.sphere(plate, 0.06, Vector3(side * 0.2, 0.46, 0.0), RED)
		"buttons":
			Clay.box(plate, Vector3(0.45, 0.04, 0.24), Vector3(0.0, 0.02, 0.0), DARK)
			for i in 3:
				Clay.cylinder(plate, 0.05, 0.06, Vector3((i - 1) * 0.14, 0.06, 0.0), YELLOW if i == 1 else RED)
		"dial":
			Clay.cylinder(plate, 0.15, 0.05, Vector3(0.0, 0.025, 0.0), FACE)
			Clay.box(plate, Vector3(0.02, 0.02, 0.13), Vector3(0.03, 0.06, -0.03), RED).rotation.y = 0.6


## ── EL ARTILLERO ─────────────────────────────────────────────────────────────────────────────────────────────────

## LA TORRE, un bloque metido en la planta contra la espalda; arriba, el rulemán y el plato que gira, con la silla y, al
## frente, el pie del arma con su horquilla y el arma (sólo se ve).
func _tower() -> void:
	var head := tower_head()
	var block := Vector3(1.2, TOWER_TALL, 0.56)
	_part(block, Vector3(0.0, DECK_Y + TOWER_TALL * 0.5, TOWER_Z), SHELL)
	_solid(block, Vector3(0.0, DECK_Y + TOWER_TALL * 0.5, TOWER_Z))
	_part(Vector3(1.22, 0.08, 0.58), Vector3(0.0, head - 0.15, TOWER_Z), RIM_COLOR)
	Clay.cylinder(_root, 0.42, 0.1, Vector3(0.0, head + 0.05, TOWER_Z), RIM_COLOR)
	for i in 8:
		var a := TAU * i / 8.0
		Clay.cylinder(_root, 0.03, 0.05, Vector3(sin(a) * 0.35, head + 0.12, TOWER_Z - cos(a) * 0.35), DARK)
	var turn := Node3D.new()
	turn.name = "Plato del artillero"
	turn.position = Vector3(0.0, head + 0.1, TOWER_Z)
	_root.add_child(turn)
	Clay.cylinder(turn, 0.4, 0.1, Vector3(0.0, 0.05, 0.1), METAL)
	Clay.box(turn, Vector3(0.3, 0.1, GUN_REACH - 0.05), Vector3(0.0, 0.05, -GUN_REACH * 0.5 - 0.15), METAL)
	_solid(Vector3(0.9, 0.1, 0.9), Vector3(0.0, head + 0.15, TOWER_Z + 0.05))
	# El pie del arma y la horquilla; el arma cabecea en ella.
	var foot := Vector3(0.0, 0.1, -GUN_REACH)
	var trunnion := Vector3(0.0, 0.78, -GUN_REACH)
	Clay.cylinder(turn, 0.08, trunnion.y - foot.y - 0.1, Vector3(0.0, (trunnion.y + foot.y) * 0.5 - 0.05, foot.z), DARK)
	for side: float in [-1.0, 1.0]:
		Clay.box(turn, Vector3(0.05, 0.22, 0.12), trunnion + Vector3(side * 0.2, -0.06, 0.0), DARK)
	Clay.box(turn, Vector3(0.45, 0.06, 0.12), trunnion + Vector3(0.0, -0.17, 0.0), DARK)
	Clay.cylinder(turn, 0.04, 0.5, trunnion, RIM_COLOR, Vector3(0.0, 0.0, 90.0))
	gun = Node3D.new()
	gun.name = "Arma del artillero"
	gun.position = trunnion
	turn.add_child(gun)
	Clay.box(gun, Vector3(0.3, 0.25, 0.55), Vector3(0.0, 0.0, -0.05), DARK)
	for x: float in [-0.06, 0.06]:
		for y: float in [-0.06, 0.06]:
			Clay.cylinder(gun, 0.035, 0.9, Vector3(x, y, -0.75), RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	Clay.box(gun, Vector3(0.9, 0.5, 0.05), Vector3(0.0, 0.05, -0.38), METAL)
	for side: float in [-1.0, 1.0]:
		Clay.cylinder(gun, 0.03, 0.22, Vector3(side * 0.16, -0.06, 0.3), YELLOW, Vector3(90.0, 0.0, 0.0))


## ── LA ESPALDA ──────────────────────────────────────────────────────────────────────────────────────────────────

## El hueco de un recurso y la batería metida, abajo; arriba, la mochila del jetpack con el bisel abajo y tres toberas
## cortas en el bisel (sólo se ven).
func _back() -> void:
	var face := HALF + 0.005
	var size := 0.72 * SLOTS_K
	for at: Vector3 in [Vector3(-SLOTS_X, SLOTS_Y, face), Vector3(SLOTS_X, SLOTS_Y, face)]:
		for s: float in [-1.0, 1.0]:
			_part(Vector3(0.08, size + 0.16, 0.06), at + Vector3(s * (size + 0.08) * 0.5, 0.0, 0.02), RIM_COLOR)
			_part(Vector3(size + 0.16, 0.08, 0.06), at + Vector3(0.0, s * (size + 0.08) * 0.5, 0.02), RIM_COLOR)
		_part(Vector3(size, size, 0.02), at, HOLE)
	var hole := Vector3(-SLOTS_X, SLOTS_Y, face)
	_part(Vector3(size + 0.16, 0.05, 0.22 * SLOTS_K), hole + Vector3(0.0, -(size + 0.16) * 0.5, 0.12 * SLOTS_K), DARK)
	var slot := Vector3(SLOTS_X, SLOTS_Y, face)
	var k := SLOTS_K
	_part(Vector3(0.63, 0.63, 0.3) * k, slot, CELL)
	_part(Vector3(0.65, 0.08, 0.32) * k, slot + Vector3(0.0, 0.18 * k, 0.0), CELL.darkened(0.3))
	for bx: float in [-0.16, 0.16]:
		Clay.cylinder(_root, 0.05 * k, 0.08 * k, slot + Vector3(bx * k, 0.355 * k, 0.05 * k), DARK)
	_part(Vector3(0.3, 0.05, 0.04) * k, slot + Vector3(0.0, -0.1 * k, 0.16 * k), DARK)
	# La mochila: del hueco + 40 cm de aire hasta arriba de la pared de atrás de la cubierta.
	var from := SLOTS_Y + 0.33 + 0.4 + 0.1
	var to := tower_head() - 0.05
	_prism(0.0, 1.6, PackedVector2Array([Vector2(HALF, from), Vector2(HALF, to), Vector2(HALF + PACK_DEPTH, to),
		Vector2(HALF + PACK_DEPTH, from + 0.35), Vector2(HALF + 0.1, from)]), DARK.lightened(0.15))
	_part(Vector3(1.64, 0.05, PACK_DEPTH + 0.04), Vector3(0.0, to - 0.25, HALF + PACK_DEPTH * 0.5), RIM_COLOR)
	var bevel := Vector2(HALF + (0.1 + PACK_DEPTH) * 0.5, from + 0.175)
	for x: float in [-0.45, 0.0, 0.45]:
		var holder := Node3D.new()
		holder.position = Vector3(x, bevel.y, bevel.x)
		holder.rotation.x = deg_to_rad(-40.0)
		_root.add_child(holder)
		Clay.cylinder(holder, 0.1, 0.05, Vector3.ZERO, RIM_COLOR)
		var nozzle := MeshInstance3D.new()
		var bell := CylinderMesh.new()
		bell.top_radius = 0.07
		bell.bottom_radius = 0.12
		bell.height = 0.16
		nozzle.mesh = bell
		nozzle.material_override = Clay.material(RIM_COLOR)
		nozzle.position = Vector3(0.0, -0.08, 0.0)
		holder.add_child(nozzle)


## ── LAS PIEZAS ──────────────────────────────────────────────────────────────────────────────────────────────────

## Una caja que se ve, desde el fondo.
func _part(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	return Clay.box(_root, size, at, color)


## Una caja que pisan y tocan los de adentro (en `interior`, del que el marco copia su sombra), desde el fondo.
func _solid(size: Vector3, at: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position = at + _root.position
	interior.add_child(shape)


## Una silla del puesto `index` (ver `SEAT_NAMES`), mirando al frente.
func _chair(index: int, at: Vector3) -> void:
	var chair := (load(SEAT_SCENE) as PackedScene).instantiate() as SeatInteractable
	chair.name = "Asiento %s" % SEAT_NAMES[index]
	chair.position = at
	chair.eye_height = CabinGrid.EYE_HEIGHT
	_root.add_child(chair)
	chairs.append(chair)


## Un prisma de grosor `thick` en x, centrado en `x`, con el contorno convexo `profile` en (z, y).
func _prism(x: float, thick: float, profile: PackedVector2Array, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := PackedVector3Array()
	var count := profile.size()
	for side: float in [-thick * 0.5, thick * 0.5]:
		for point in profile:
			points.append(Vector3(x + side, point.y, point.x))
	for i in range(1, count - 1):
		for cap: int in [0, count]:
			for index: int in [cap, cap + i, cap + i + 1]:
				tool.add_vertex(points[index])
	for i in count:
		var j := (i + 1) % count
		for index: int in [i, j, count + j, i, count + j, count + i]:
			tool.add_vertex(points[index])
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	_root.add_child(mesh)


## ── LOS DE ADENTRO, EL MARCO Y LA U ──────────────────────────────────────────────────────────────────────────────

## UN MANIQUÍ EN CADA SILLA MENOS LA DEL QUE MANEJA: desde ahí se mira en primera persona al poseerla.
func seat_dummies() -> void:
	var driver := chairs[DRIVER]
	chairs.remove_at(DRIVER)
	super()
	chairs.insert(DRIVER, driver)


## EL MARCO: la cápsula de abajo y, arriba, la cubierta con la torre (lo que se camina adentro son sus pisos).
func build_frame() -> void:
	frame = MotionFrame.new()
	mech.add_child(frame)
	var low := bottom()
	frame.floor_height = low + FLOOR
	frame.add_volume(AABB(Vector3(-HALF, low, -HALF), Vector3(HALF * 2.0, DECK_Y, HALF * 2.0)))
	frame.add_volume(AABB(Vector3(-HALF, low + DECK_Y, -HALF), Vector3(HALF * 2.0, TOWER_TALL + 2.2, HALF * 2.0)))
	interior.collision_layer = 1
	frame.cast_shadow(self)
	interior.collision_layer = 0
	interior.collision_mask = 0
	for body in find_children("*", "RigidBody3D", true, false):
		mech.add_collision_exception_with(body as RigidBody3D)


## LA U: arriba, en la cubierta, al lado de la silla de los brazos.
func board() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if mech.keys.driving:
		SandboxPossession.of(get_tree()).release()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	var spot := Vector3(0.42, bottom() + DECK_Y + 0.05, 0.1)
	player.place_at(mech.global_transform * spot, mech.yaw())
