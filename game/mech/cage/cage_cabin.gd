class_name CageCabin
extends MechCabin

## LA MECA JAULA (16/11/2026, de las maquetas de tests/cage_ideas_look, la 166; el usuario: «empezar a migrar esta meca
## a algo funcional… que camine… que sus tres cabinas se puedan usar»). Una cabina más de la meca (ver Mech.Cabin.CAGE),
## con los brazos y las piernas de la meca de siempre al 30 % (`LIMBS`; «mantener estos grosores y estos largos»). TODO
## SALE DE SU FORMA (CageShape, el F2 de su fila; el usuario: «un sistema… para controlar el tamaño de la meca… sin tener
## tantos sliders… que todos los elementos encajen bien»), con mallas de caras propias (CageMesh):
##   · ABAJO, LA CAJA DEL QUE MANEJA CON LA BURBUJA AL FRENTE (la de la maqueta 166): la burbuja es una ventana; el que
##     maneja va sentado adentro de la caja, en la silla de siempre (BubbleSeat), y su cámara de primera persona va a la
##     altura del centro del vidrio. Los hombros, en el centro de cada costado sin el piso ni el techo. Es LA CAJA de la
##     meca.
##   · ARRIBA, EL BLOQUE LLENO CON EL POZO DEL DE LOS BRAZOS (DeskPit): sobre la tapa del cubo, del mismo lado.
##   · ATRÁS, LA TORRE DEL ARTILLERO contra el borde de atrás, redonda o cuadrada; arriba, el plato que gira con su silla
##     y el arma montada (sólo se ve: «después lo vamos a hacer funcional»).
##   · ATRÁS, EN LA ESPALDA DEL CUBO: el hueco de un recurso, la batería metida y la mochila del jetpack (sólo se ven).
## *Hasta el 16/11/2026 era una caja de 2 m maquetada a mano, con la cubierta de borde en bisel y la torre metida.*
## Todo se arma desde el fondo de la caja (`_root`, a `bottom()`): las medidas de abajo son alturas desde ahí.

## Brazos y piernas: la meca de siempre al 30 %.
const LIMBS := 0.3
## EL CUERPO: el de sus perillas de «Brazos y piernas» (las de todas las mecas), achicado a `LIMBS`.
static func body() -> MechBody:
	var made := MechBody.from_shape(shape())
	made.shrink(LIMBS)
	return made

## LA SILLA DEL QUE MANEJA (BubbleSeat): cuánto detrás del centro de la cápsula va su base (m).
const DRIVER_BACK := 0.12
## Los ojos sobre la silla de uno sentado arriba de la torre (m): la torre llega a los ojos del artillero menos esto.
const GUNNER_SEATED := 1.15
## Lo que lleva el plato del artillero hacia adelante (el pie del arma).
const GUN_REACH := 0.35
## La mochila: su profundidad; el hueco y la batería, a qué alto y su tamaño (partes del de 72 cm).
const PACK_DEPTH := 0.38
const SLOTS_Y := 0.45
const SLOTS_K := 0.7
const SLOTS_X := 0.45

const SHELL := Color(0.6, 0.61, 0.63)
## Lo opaco de la cápsula, por dentro: un gris oscuro (el usuario: «el espacio enterrado del habitáculo de abajo… un gris más oscuro»).
const INSIDE := Color(0.36, 0.37, 0.39)
const METAL := Color(0.55, 0.57, 0.6)
const DARK := Color(0.3, 0.31, 0.34)
const DECK := Color(0.68, 0.69, 0.7)
const RIM_COLOR := Color(0.22, 0.23, 0.25)
const HOLE := Color(0.08, 0.08, 0.1)
const GLASS := Color(0.62, 0.8, 0.92, 0.3)
## EL VIDRIO DE LA CÁPSULA: casi transparente, apenas verdoso, con manchas muy sutiles (cage_glass.gdshader).
static var GLASS_PAINT := CageCabin._glass_paint()
const CELL := Color(0.62, 0.6, 0.42)
## El amarillo apagado del arma del artillero (el usuario: «desatura un poco sus colores y oscurecelos un poco»).
const YELLOW := Color(0.68, 0.57, 0.26)
## Los puestos, en el orden de las sillas: arriba la locomoción, atrás el artillero, abajo (en la cápsula) los brazos y el
## torso (17/11/2026, la variante de 3: CageBoards). *Hasta entonces, arriba los brazos y abajo el manejo.*
## La de abajo va primero: la meca de `n` jugadores tiene las primeras `n` (ver CageShape.crew). *Hasta el 18/11/2026,
## abajo era la última.*
const SEAT_NAMES := ["brazos", "locomoción", "artillero"]
## Los puestos: abajo, en la cápsula, los brazos y el torso; arriba, la locomoción; en la torre, el artillero.
const DRIVER := 0
const LOCOMOTION := 1
const GUNNER := 2

## Dónde va la silla del artillero, sobre su plato. *Hasta el 22/11/2026 tenía una torreta con yugo, armas y tableros: las
## armas pasaron a los costados de toda meca (MechGuns), y lo demás está en el commit 5238ff8.*
var _gunner_at := Vector3.ZERO
var _root: Node3D = null
## ── EL MÓDULO DE ARRIBA, EN SU PROPIO PIVOTE (17/11/2026, el usuario: «le daría la habilidad de girar aparte… por ahora
## lo único que dejaría sería el groundwork bien hecho para que sea fácil de hacerlo en el futuro») ────────────────────
## El pozo con su bloque (o su octógono), sus tableros, la silla de los brazos y la torre con el artillero cuelgan de
## `upper`, que gira alrededor del eje vertical de la meca; sus formas de choque (las que pisan los de adentro) giran
## con él (`_upper_colliders`), y el marco por el que se camina las sigue solo (MotionFrame copia la sombra de donde
## estén). Quién lo hace girar y hacia dónde: CageMech (`upper_heading`), sólo en la redonda y con `upper_turns`.
var upper: Node3D = null
## Lo que gira, relativo a la cabina (rad).
var upper_yaw := 0.0
var _upper_colliders: Array = []
## La caja de abajo, la malla: al desarmarse la meca, el pedazo que se la lleva es el que se lleva las sillas.
var _box: Node3D = null


## ── LAS MEDIDAS (en el espacio de la caja: el centro, en el medio) ──────────────────────────────────────────────

static func shape() -> CageShape:
	return CageShape.current


## LA CAJA: el módulo de abajo.
static func box() -> Vector3:
	var side := shape().side()
	return Vector3(side, shape().height(), side)


static func bottom() -> float:
	return -shape().height() * 0.5


## EL HOMBRO (el derecho; el izquierdo, espejado), CON UNA SOLA REGLA PARA LOS DOS TORSOS (17/11/2026, el usuario: «que
## el plano de ese cuadrado se centre en ese cuadrado y que el offset del parámetro que tengo para adelantar el hombro
## funcione ahí… tenés las dos con una sola regla»): afuera de la cara del costado, en su centro —en la cuadrada, la cara
## sin el piso ni el techo («centrados en la cara del módulo sin techo y sin piso»); en la redonda, el cuadrado del
## costado del cubo chanfleado—, a la altura de los ojos del que maneja. Y ADELANTADO `shoulder_forward` (16/11/2026:
## «en cero, los hombros al medio… al máximo, adelantados al máximo sin que sobresalgan… va a actuar como un offset»):
## de 0, al medio, a 1, con la bola del hombro tocando el borde de adelante de esa cara (`side_face_half`).
static func shoulder() -> Vector3:
	var form := shape()
	var lift := form.bubble_y() - form.height() * 0.5
	var limbs := body()
	var room := maxf(form.side_face_half() - limbs.LEG_THICKNESS * MechBody.JOINT_SHARE, 0.0)
	return Vector3(form.side() * 0.5 + limbs.LEG_THICKNESS * 0.7 + limbs.shoulder_out * limbs.thick, lift,
		-room * form.shoulder_forward)


## EL BLOQUE DE ARRIBA de una forma: el pozo con sus perillas.
static func pit_of(form: CageShape) -> DeskPit:
	var pit := DeskPit.new()
	pit.side = form.side()
	if form.is_round():
		pit.outer_octagon = form.octagon_apothem()
		pit.sink = form.octagon_sink()
	pit.radius = form.pit_apothem()
	pit.tilt = form.desk_tilt
	pit.eye = form.arms_eye
	return pit


## Lo alto de la torre sobre el piso de arriba: los ojos del artillero menos lo de uno sentado, nunca debajo del bloque.
static func tower_top(form: CageShape) -> float:
	return maxf(form.gunner_eye - GUNNER_SEATED, pit_of(form).top() + 0.1)


## Donde se mira en primera persona al poseerla: los ojos del que maneja (`driver_eye`). La cámara pone los ojos a la
## altura de un puesto de pie (SeatInteractable.STATION_EYE_HEIGHT) sobre este punto: se baja eso.
func top_seat() -> Vector3:
	return _root.position + driver_eye(shape()) - Vector3(0.0, SeatInteractable.STATION_EYE_HEIGHT, 0.0)


## El centro de la cápsula, desde el fondo de la caja: la tapa de adelante (el domo) sobresale entera y el cinturón empieza
## en la cara de la caja.
static func bubble_center(form: CageShape) -> Vector3:
	return Vector3(0.0, form.bubble_y(), -form.side() * 0.5 + form.capsule_radius() / (1.0 + sqrt(2.0)))


## Cuánto se estira el cinturón hacia adentro: el doble de lo que mide (ver _cube).
static func belt_back(form: CageShape) -> float:
	return 2.0 * form.capsule_radius() / (1.0 + sqrt(2.0))


## LOS OJOS DE LA PRIMERA PERSONA DEL QUE MANEJA, desde el fondo de la caja: a la altura del centro de su cápsula
## (16/11/2026, el usuario: «que la cámara ya no tenga el offset por profundidad… la altura de la visión al medio»), y
## RETROCEDIDOS MEDIO CINTURÓN (el usuario: «que el asiento retroceda… para que las piernas no clipeen»; y después, «lo
## vamos a dejar al medio… el sweet spot de que no atraviesa las piernas, pero no está tan lejos»): entre medio del anillo
## de adelante y el de atrás.
static func driver_eye(form: CageShape) -> Vector3:
	return bubble_center(form) + Vector3(0.0, 0.0, belt_back(form) * 0.5)


## Los ojos del de arriba, sentado en el pozo (la silla 0), desde el fondo de la caja.
static func pit_eye(form: CageShape) -> Vector3:
	return Vector3(0.0, form.height() + form.arms_eye, 0.05)


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
	upper = Node3D.new()
	upper.name = "Módulo de arriba"
	_root.add_child(upper)
	var form := shape()
	var tall := form.height()
	# PARA CUÁNTOS (CageShape.crew): de 1, sólo la cápsula; de 2, además el bloque de arriba con el pozo; de 3, la torre.
	var crew := form.players()
	_cube(form)
	var pit := pit_of(form)
	if crew >= 2:
		_upper(pit, tall)
	# LOS TABLEROS DE VERDAD en las caras de la cápsula y del bloque de arriba (CageBoards; el usuario, 17/11/2026: «está
	# bien ahora el sistema… lo pases a la meca»).
	CageBoards.dress(_root, form, upper, crew >= 2)
	if crew >= 3:
		_tower(form, tall, pit)
	_back(form)
	# LA DEL QUE MANEJA, la de siempre (BubbleSeat), en el piso de la cabina debajo de la cápsula (sale por su hueco de
	# abajo), un poco detrás de los ojos, que van con el anillo de atrás.
	var driver := BubbleSeat.new()
	driver.name = "Asiento %s" % SEAT_NAMES[DRIVER]
	driver.position = Vector3(0.0, form.cabin_floor(), driver_eye(form).z + DRIVER_BACK)
	driver.eye_point = driver_eye(form)
	driver.seat_height = form.seat_height
	_root.add_child(driver)
	chairs.append(driver)
	if crew >= 2:
		_chair(LOCOMOTION, Vector3(0.0, tall, 0.05), form.arms_eye, upper)
	if crew >= 3:
		_chair(GUNNER, _gunner_at, GUNNER_SEATED, upper)


## ── LAS CARAS QUE PUEDEN LLEVAR TABLERO (ver FaceBoard) ──────────────────────────────────────────────────────────

## LAS CARAS DE LA CÁPSULA, desde el fondo de la caja: las del rombicuboctaedro (CageMesh.faceted_sphere) sin la de abajo,
## con el cinturón estirado hacia adentro (ver `_cube`). Cada una: `normal` (hacia afuera), `points`, `raw` (los puntos
## de la esfera de radio 1, antes de estirar), `square` y `glass` (la tapa de adelante, el domo).
static func capsule_faces(form: CageShape) -> Array[Dictionary]:
	var radius := form.capsule_radius()
	var center := bubble_center(form)
	var deeper := belt_back(form)
	var out: Array[Dictionary] = []
	for face: Dictionary in CageMesh.faceted_sphere():
		var normal: Vector3 = face["normal"]
		if normal.is_equal_approx(Vector3.DOWN):
			continue
		var points: Array = []
		for p: Vector3 in face["points"]:
			var at := center + p * radius
			if p.z > 0.001:
				at.z += deeper
			points.append(at)
		out.append({"normal": normal, "points": points, "raw": face["points"], "square": face["square"],
			"glass": normal.z < -0.1})
	return out


## LAS CARAS DE LA CÁPSULA QUE PUEDEN LLEVAR TABLERO, desde el fondo de la caja: las opacas que no son triángulos ni
## miran al piso (el usuario: «todas las que pueden llegar a tener tablero»).
static func capsule_boards(form: CageShape) -> Array[FaceBoard]:
	var out: Array[FaceBoard] = []
	for face: Dictionary in capsule_faces(form):
		var normal: Vector3 = face["normal"]
		if face["glass"] or (face["points"] as Array).size() < 4 or normal.y < -0.5:
			continue
		# Todas sus aristas son de celdas enteras (CageShape.capsule_radius): cualquier esquina engancha igual.
		out.append(FaceBoard.from_points("cápsula " + FaceBoard.direction_name(normal), face["points"], -normal,
			face["points"][0]))
	return out


## LAS DEL BLOQUE DE ARRIBA, desde el fondo de la caja (ver DeskPit.boards).
static func upper_boards(form: CageShape) -> Array[FaceBoard]:
	return pit_of(form).boards(Vector3(0.0, form.height(), 0.0))


## Donde cuelgan las caras de arriba: el fondo de la caja.
func board_root() -> Node3D:
	return _root


## ── EL CUBO DE ABAJO ─────────────────────────────────────────────────────────────────────────────────────────────

## LA CAJA DEL QUE MANEJA CON SU CÁPSULA FACETADA (16/11/2026, el usuario: «hacer un octógono igual que arriba, pero
## hecho como esfera… que el octógono de la base tenga un hueco… de ahí sale la silla… el domo sea básicamente esta misma
## estructura pero hecha transparente»; de tests/pod_facets_look, la 2):
##   · LA CAJA, hueca y vista de los dos lados, con el frente abierto donde la corta la cápsula; su piso de la cabina.
##   · LA CÁPSULA: un rombicuboctaedro (CageMesh.faceted_sphere) alrededor de los ojos del que maneja, sin la cara de
##     abajo (por ahí salen la silla y las piernas), con EL CINTURÓN DEL MEDIO EL DOBLE DE LARGO HACIA ADENTRO. La tapa de
##     adelante sobresale de la caja: es EL DOMO, de vidrio; el cinturón empieza en la cara de la caja.
##   · EL VIDRIO: liso o facetado (`glass_smooth`), con su degradé y sus manchas (cage_glass.gdshader).
##   · LOS TABLEROS: en sus caras opacas, cada una con su grilla (ver CageBoards).
##   · EL MARCO en la cara de la caja, con la forma del corte, y la tapa de la panza.
## EN LA REDONDA, el cuerpo es el cubo chanfleado (CageMesh.chamfered_body) en lugar de la caja: la cápsula, en su cara
## de adelante; el resto, igual.
func _cube(form: CageShape) -> void:
	var edge := form.side() * 0.5
	var tall := form.height()
	var radius := form.capsule_radius()
	var center := bubble_center(form)
	var front := -edge
	var shell_tool := SurfaceTool.new()
	shell_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner := SurfaceTool.new()
	inner.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glass := SurfaceTool.new()
	glass.begin(Mesh.PRIMITIVE_TRIANGLES)
	# EL CINTURÓN, EL DOBLE DE LARGO HACIA ADENTRO (el usuario: «no se tiene que dar vuelta para tocar controles…
	# podemos romper un poco con la esfera… haciendo que el cinturón sea más largo para adentro… el doble del
	# cinturón»): lo de atrás del centro se corre hacia atrás el largo del cinturón.
	var cut := PackedVector2Array()
	for face: Dictionary in capsule_faces(form):
		var normal: Vector3 = face["normal"]
		var points: Array = face["points"]
		if absf(normal.z) < 0.1:
			for p: Vector3 in face["raw"]:
				if p.z <= 0.001:
					cut.append(Vector2(p.x * radius, p.y * radius))
		# EL DOMO: sólo la tapa de adelante es de vidrio; el cinturón y la tapa de atrás, opacos.
		if normal.z < -0.1:
			if form.glass_smooth:
				CageMesh.smooth_face(glass, points, center, normal)
			else:
				CageMesh.face(glass, points, normal)
			continue
		CageMesh.face(inner, points, normal)
	var outline := _around(cut)
	var place := func(p: Vector2) -> Vector3: return Vector3(p.x, center.y + p.y, front)
	# EL PISO DE LA CABINA, donde está la silla (ver CageShape.cabin_floor): una cara por encima del fondo; en la redonda,
	# sólo lo de abajo de la cápsula (el cuerpo se angosta abajo).
	var floor_y := form.cabin_floor()
	var floor_half := edge
	if form.is_round():
		var face_half := form.side_face_half()
		floor_half = minf(face_half, radius + 0.3)
		for face: Dictionary in CageMesh.chamfered_body(Vector3(0.0, center.y, 0.0), edge, form.body_chamfer):
			if not (face["normal"] as Vector3).is_equal_approx(Vector3.FORWARD):
				CageMesh.face(shell_tool, face["points"], face["normal"])
		if outline.size() >= 3:
			CageMesh.fill_to_rect(shell_tool, outline, Vector2(-face_half, -face_half), Vector2(face_half, face_half),
				place, Vector3.FORWARD)
	else:
		# La caja.
		var middle_box := Vector3(0.0, tall * 0.5, 0.0)
		var half := Vector3(edge, tall * 0.5, edge)
		for normal: Vector3 in [Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN]:
			var u := Vector3(normal.y, normal.z, normal.x)
			var v := normal.cross(u)
			var middle := middle_box + normal * half
			u *= half
			v *= half
			CageMesh.face(shell_tool, [middle - u - v, middle + u - v, middle + u + v, middle - u + v], normal)
		if outline.size() >= 3:
			CageMesh.fill_to_rect(shell_tool, outline, Vector2(-edge, -center.y), Vector2(edge, tall - center.y), place,
				Vector3.FORWARD)
	if floor_y > 0.01:
		CageMesh.face(shell_tool, [Vector3(-floor_half, floor_y, -floor_half), Vector3(floor_half, floor_y, -floor_half),
			Vector3(floor_half, floor_y, floor_half), Vector3(-floor_half, floor_y, floor_half)], Vector3.UP)
	_both_sides(shell_tool, SHELL, "Caja de abajo")
	_both_sides(inner, INSIDE, "Cápsula")
	var tinted := GLASS_PAINT.duplicate() as ShaderMaterial
	tinted.set_shader_parameter("gradient", 1)
	tinted.set_shader_parameter("center", center)
	tinted.set_shader_parameter("clear_alpha", form.glass_clear)
	tinted.set_shader_parameter("edge_alpha", form.glass_tint)
	tinted.set_shader_parameter("spread", form.glass_spread)
	tinted.set_shader_parameter("smudge_alpha", form.glass_smudges)
	tinted.set_shader_parameter("pixel", form.glass_pixel)
	_both_sides(glass, GLASS, "Vidrio de la cápsula", tinted)
	if outline.size() >= 3 and form.rim_width > 0.0 and form.rim_depth > 0.0:
		var rim := SurfaceTool.new()
		rim.begin(Mesh.PRIMITIVE_TRIANGLES)
		CageMesh.outline_ring(rim, Vector3(center.x, center.y, front), outline, form.rim_width, form.rim_depth)
		var frame_ring := MeshInstance3D.new()
		frame_ring.name = "Marco de la cápsula"
		frame_ring.mesh = CageMesh.commit(rim, RIM_COLOR)
		_root.add_child(frame_ring)
	Clay.cylinder(_root, minf(0.42, edge * 0.4), 0.06, Vector3(0.0, -0.01, 0.0), RIM_COLOR)
	Clay.cylinder(_root, minf(0.34, edge * 0.32), 0.07, Vector3(0.0, -0.01, 0.0), HOLE)


static func _glass_paint() -> ShaderMaterial:
	var paint := ShaderMaterial.new()
	paint.shader = load("res://game/mech/cage/cage_glass.gdshader") as Shader
	return paint


## Una malla vista de los dos lados (los de adentro también la ven), que además tocan los de adentro.
func _both_sides(tool: SurfaceTool, color: Color, label: String, paint_with: Material = null) -> void:
	var piece := MeshInstance3D.new()
	piece.name = label
	piece.mesh = CageMesh.commit(tool, color)
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	piece.material_override = paint
	if paint_with != null:
		piece.material_override = paint_with
	_root.add_child(piece)
	if label == "Caja de abajo":
		_box = piece
	if piece.mesh.get_surface_count() > 0:
		_mesh_solid(piece.mesh)


## El área de un polígono plano convexo.
static func _area(points: Array) -> float:
	var total := 0.0
	for i in range(1, points.size() - 1):
		total += ((points[i] as Vector3) - (points[0] as Vector3)).cross((points[i + 1] as Vector3) - (points[0] as Vector3)).length() * 0.5
	return total


## Los puntos del corte, sin repetidos y en orden alrededor del centro.
static func _around(points: PackedVector2Array) -> PackedVector2Array:
	var kept: Array[Vector2] = []
	for p in points:
		var seen := false
		for q in kept:
			seen = seen or p.distance_to(q) < 0.001
		if not seen:
			kept.append(p)
	kept.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.angle() < b.angle())
	return PackedVector2Array(kept)


## ── EL BLOQUE DE ARRIBA ──────────────────────────────────────────────────────────────────────────────────────────

## EL BLOQUE CON EL POZO, sobre la tapa del cubo (sus tableros, ver CageBoards).
func _upper(pit: DeskPit, tall: float) -> void:
	var block := MeshInstance3D.new()
	block.name = "Bloque de arriba"
	block.mesh = pit.mesh(SHELL)
	block.position = Vector3(0.0, tall, 0.0)
	upper.add_child(block)
	_mesh_solid(block.mesh, block.position, true)


## ── EL ARTILLERO ─────────────────────────────────────────────────────────────────────────────────────────────────

## LA TORRE, contra el borde de atrás (redonda o cuadrada, de su lado); arriba, el rulemán y el plato, con la silla.
func _tower(form: CageShape, tall: float, pit: DeskPit) -> void:
	var wide := form.tower_wide()
	var deep := form.tower_deep()
	var middle := Vector2(0.0, form.upper_back() - deep * 0.5)
	var outline := CageMesh.polygon(1.0, 32) if form.tower_round \
		else CageMesh.polygon(sqrt(2.0), 4, PI * 0.25)
	# Redonda: la elipse del ancho y el fondo; cuadrada: el rectángulo.
	for k in outline.size():
		outline[k] = middle + outline[k] * Vector2(wide * 0.5, deep * 0.5)
	var head := tall + tower_top(form)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	CageMesh.prism(tool, outline, tall + pit.top() - 0.01, head)
	var tower := MeshInstance3D.new()
	tower.name = "Torre"
	tower.mesh = CageMesh.commit(tool, SHELL)
	upper.add_child(tower)
	_mesh_solid(tower.mesh, Vector3.ZERO, true)
	var at := Vector3(0.0, head, middle.y)
	var plate := minf(minf(wide, deep) * 0.5, 0.42)
	Clay.cylinder(upper, plate, 0.08, at + Vector3(0.0, 0.04, 0.0), RIM_COLOR)
	# EL PUESTO DEL ARTILLERO: por ahora, sólo su silla sobre el plato.
	_gunner_at = at + Vector3(0.0, 0.08, 0.05)


## ── LA ESPALDA ──────────────────────────────────────────────────────────────────────────────────────────────────

## El hueco de un recurso y la batería metida, abajo; arriba, la mochila del jetpack con el bisel abajo y tres toberas
## cortas en el bisel (sólo se ven). En la cara de atrás: en la cuadrada, la de la caja; en la redonda, el cuadrado de atrás
## del cubo chanfleado (`low` a `tall`, de `side` de ancho).
func _back(form: CageShape) -> void:
	var half := form.side() * 0.5
	var low := 0.0
	var tall := form.height()
	var side := form.side()
	if form.is_round():
		low = form.bubble_y() - form.side_face_half()
		tall = form.bubble_y() + form.side_face_half()
		side = form.side_face_half() * 2.0
	var face := half + 0.005
	var size := 0.72 * SLOTS_K
	for at: Vector3 in [Vector3(-SLOTS_X, low + SLOTS_Y, face), Vector3(SLOTS_X, low + SLOTS_Y, face)]:
		for s: float in [-1.0, 1.0]:
			_part(Vector3(0.08, size + 0.16, 0.06), at + Vector3(s * (size + 0.08) * 0.5, 0.0, 0.02), RIM_COLOR)
			_part(Vector3(size + 0.16, 0.08, 0.06), at + Vector3(0.0, s * (size + 0.08) * 0.5, 0.02), RIM_COLOR)
		_part(Vector3(size, size, 0.02), at, HOLE)
	var hole := Vector3(-SLOTS_X, low + SLOTS_Y, face)
	_part(Vector3(size + 0.16, 0.05, 0.22 * SLOTS_K), hole + Vector3(0.0, -(size + 0.16) * 0.5, 0.12 * SLOTS_K), DARK)
	var slot := Vector3(SLOTS_X, low + SLOTS_Y, face)
	var k := SLOTS_K
	_part(Vector3(0.63, 0.63, 0.3) * k, slot, CELL)
	_part(Vector3(0.65, 0.08, 0.32) * k, slot + Vector3(0.0, 0.18 * k, 0.0), CELL.darkened(0.3))
	for bx: float in [-0.16, 0.16]:
		Clay.cylinder(_root, 0.05 * k, 0.08 * k, slot + Vector3(bx * k, 0.355 * k, 0.05 * k), DARK)
	_part(Vector3(0.3, 0.05, 0.04) * k, slot + Vector3(0.0, -0.1 * k, 0.16 * k), DARK)
	# La mochila: del hueco + 40 cm de aire hasta arriba del cubo.
	var from := low + SLOTS_Y + 0.33 + 0.4 + 0.1
	var to := tall - 0.05
	var wide := minf(1.6, side - 0.4)
	_prism(0.0, wide, PackedVector2Array([Vector2(half, from), Vector2(half, to), Vector2(half + PACK_DEPTH, to),
		Vector2(half + PACK_DEPTH, from + 0.35), Vector2(half + 0.1, from)]), DARK.lightened(0.15))
	_part(Vector3(wide + 0.04, 0.05, PACK_DEPTH + 0.04), Vector3(0.0, to - 0.25, half + PACK_DEPTH * 0.5), RIM_COLOR)
	var bevel := Vector2(half + (0.1 + PACK_DEPTH) * 0.5, from + 0.175)
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


## Una malla que pisan y tocan los de adentro (en `interior`, del que el marco copia su sombra), corrida `at` desde el
## fondo; con `turns`, es del módulo de arriba y gira con él (ver `set_upper_yaw`).
func _mesh_solid(mesh: ArrayMesh, at := Vector3.ZERO, turns := false) -> void:
	var collider := CollisionShape3D.new()
	collider.shape = mesh.create_trimesh_shape()
	collider.position = at + _root.position
	interior.add_child(collider)
	if turns:
		_upper_colliders.append([collider, collider.transform])


## Una silla del puesto `index` (ver `SEAT_NAMES`), mirando al frente, con los ojos a `eye` sobre su base; cuelga de
## `parent` (el módulo de arriba, las de arriba).
func _chair(index: int, at: Vector3, eye: float, parent: Node3D = null) -> void:
	var chair := (load(SEAT_SCENE) as PackedScene).instantiate() as SeatInteractable
	chair.name = "Asiento %s" % SEAT_NAMES[index]
	chair.position = at
	chair.eye_height = eye
	(parent if parent != null else _root).add_child(chair)
	chairs.append(chair)


## EL MÓDULO DE ARRIBA GIRADO `yaw` (rad) respecto de la cabina: lo que se ve y lo que se pisa.
func set_upper_yaw(yaw: float) -> void:
	upper_yaw = wrapf(yaw, -PI, PI)
	upper.rotation.y = upper_yaw
	var turn := Transform3D(Basis(Vector3.UP, upper_yaw), Vector3.ZERO)
	for pair: Array in _upper_colliders:
		if is_instance_valid(pair[0]):
			(pair[0] as CollisionShape3D).transform = turn * (pair[1] as Transform3D)


## EL MÓDULO DE ARRIBA MIRANDO A `world_yaw` (el giro en Y del mundo, como BalanceBody.yaw), sea cual sea el del torso.
func set_upper_world_yaw(world_yaw: float) -> void:
	var forward := -global_basis.z
	set_upper_yaw(world_yaw - atan2(-forward.x, -forward.z))


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

## EL QUE ENTRA DESALOJA AL MANIQUÍ (el usuario, 16/11/2026: «el dummy sí está ocupando el asiento, pero cuando yo me
## meto es como que lo saco»): hay un maniquí en cada silla, y al tomar el puesto `index` (por ahora, poseerla: el que
## maneja) el de esa silla se va. `seat_back` vuelve a sentar uno al dejarlo.
func evict(index: int) -> void:
	if index >= chairs.size():
		return
	for dummy in dummies.duplicate():
		if is_instance_valid(dummy) and dummy.intent.seat == chairs[index]:
			chairs[index].release(dummy)
			dummy.intent.seat = null
			dummies.erase(dummy)
			dummy.queue_free()


func seat_back(index: int) -> void:
	if index >= chairs.size():
		return
	for dummy in dummies:
		if is_instance_valid(dummy) and dummy.intent.seat == chairs[index]:
			return
	seat_dummy(index)


## ── AL DESARMARSE, LAS SILLAS VAN CON EL TRONCO (18/11/2026, el usuario: «las sillas deberían estar totalmente
## atornilladas a la meca… cuando… se quedan atrás… en ragdoll»; y de la tripulación: «que se queden sentados») ────────
## Al morir, la meca se desarma (PartsRagdoll.fall_apart): sus mallas se mudan a pedazos con física y el cuerpo vivo se
## apaga, y con él lo que cuelga de él. Las sillas quedaban flotando donde estaban, sin llevar a nadie. Cuando se apaga,
## CADA SILLA QUEDA CLAVADA AL PEDAZO QUE SE LLEVÓ LA CAJA DE ABAJO (el tronco): un pasador en él (RemoteTransform3D) le
## lleva su lugar cada paso, y la silla sigue andando (procesa aunque la meca esté apagada), así lleva a su sentado
## mientras cae. Las tres, cuelguen de donde cuelguen (la de la torreta también). Y los pedazos no chocan con las
## sillas, como la caja viva (ver `build_frame`): clavadas adentro del tronco, lo despedían lejos. *Mudarla de padre la
## sacaba del árbol un instante, y al salir la silla para a su sentado.*
var _riding := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED and not _riding:
		_ride_wreck.call_deferred()


func _ride_wreck() -> void:
	var wreck := _box.get_parent() as RigidBody3D if is_instance_valid(_box) else null
	if wreck == null or _riding:
		return
	_riding = true
	var pieces := get_tree().get_nodes_in_group(PartsRagdoll.GROUP)
	for chair in chairs:
		if not is_instance_valid(chair):
			continue
		for found in chair.find_children("*", "PhysicsBody3D", true, false):
			for piece in pieces:
				(piece as PhysicsBody3D).add_collision_exception_with(found as PhysicsBody3D)
		var pin := RemoteTransform3D.new()
		pin.name = "Silla clavada"
		wreck.add_child(pin)
		pin.global_transform = chair.global_transform
		pin.remote_path = pin.get_path_to(chair)
		chair.process_mode = Node.PROCESS_MODE_ALWAYS


## EL MARCO: el cubo de abajo y, arriba, el bloque con la torre (lo que se camina adentro es el piso del pozo).
func build_frame() -> void:
	frame = MotionFrame.new()
	mech.add_child(frame)
	var form := shape()
	var side := form.side()
	var tall := form.height()
	var low := bottom()
	frame.floor_height = low + tall
	frame.add_volume(AABB(Vector3(-side * 0.5, low, -side * 0.5), Vector3(side, tall, side)))
	frame.add_volume(AABB(Vector3(-side * 0.5, low + tall, -side * 0.5), Vector3(side, tower_top(form) + 2.2, side)))
	interior.collision_layer = 1
	frame.cast_shadow(self)
	interior.collision_layer = 0
	interior.collision_mask = 0
	# LA CAJA NO CHOCA CON NADA DE LO SUYO: los cuerpos sueltos (las sillas) y también los fijos y los animados (las bases
	# de los tableros, los brazos plegables), que van adentro de ella. *Hasta el 17/11/2026, sólo los sueltos: la jaula
	# es cinemática y lo fijo no la toca; la de práctica, física desde que es una jaula (ese día, al borrarse la meca
	# grande), salía despedida por los 75 cuerpos fijos de sus tableros.*
	for body in find_children("*", "PhysicsBody3D", true, false):
		mech.add_collision_exception_with(body as PhysicsBody3D)


## LA U: arriba, en el pozo, al lado de la silla de los brazos.
func board() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if mech.keys.driving:
		SandboxPossession.of(get_tree()).release()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	var spot := Basis(Vector3.UP, upper_yaw) * Vector3(shape().pit_apothem() * 0.65, 0.0, 0.1) \
		+ Vector3(0.0, bottom() + shape().height() + 0.05, 0.0)
	player.place_at(mech.global_transform * spot, mech.yaw())
