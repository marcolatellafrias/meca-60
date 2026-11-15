class_name ChamferCabin
extends MechCabin

## LA CABINA CUADRADA CON CHANFLES Y EL CENTRO OCTOGONAL (CabinGrid.chamfered; el usuario, 15/11/2026: «tiene que ser en
## realidad la nueva que hicimos… con chamfers y tarima octogonal»). Es la planta 1 de la maqueta de los chanfles
## (tests/chamfer_cabin_look.tscn) en la meca de verdad, con las medidas de la trama (CabinGrid) y las cabezas de
## siempre (la plana con el corte, o en rampa). Lo de la cuadrada lo hereda (ir adentro, los maniquíes, `ride`); arma:
##   · LA CAJA CON LAS CUATRO ESQUINAS CORTADAS (`corner`). Adelante, el vidrio: el frente, los chanfles de adelante y
##     los costados hasta CabinGrid.SIDE_GLASS, con el zócalo abajo; el techo de vidrio hasta donde diga la cabeza.
##     Atrás, metal. LA CABEZA ES UN PERFIL (`_top`): el alto de arriba de la caja según qué tan adelante; las paredes
##     y el techo se parten donde el perfil dobla, así cada paño es plano.
##   · AL MEDIO, LA TARIMA OCTOGONAL con escalones alrededor (de 15 cm de alto y una pisada de escalera, Stairs.TREAD);
##     para la cápsula, una rampa (como las escaleras). Adentro, corrido atrás, el ascensor (atraviesa la pelvis, como
##     en la redonda: después se arregla). Arriba, delante del ascensor, el movimiento.
##   · ADELANTE, TRES SILLAS SIN TABLERO (lo que aprendió la redonda): la del medio más adelante, los brazos un paso
##     atrás, todas mirando al frente. Sin puestos, por ahora (los de SeatStation se apoyan en el tablero).
##   · ATRÁS: los kits en los chanfles de atrás, dos en cada uno; las municiones y la batería en la pared de atrás (por
##     ahora, sólo se ven).

const DECK := Color(0.7, 0.71, 0.73)
## El alto de cada escalón de la tarima.
const STEP_TALL := 0.15
## En cuántos tramos se parte cada lado de los bordes que llevan el hueco del ascensor (para emparejarlos con él).
const PER_EDGE := 4

## Lo que sale de la forma al armarse: hasta dónde llega el vidrio de los costados y el del techo, y el corte de arriba.
var _side_to := 0.0
var _roof_to := 0.0
var _cut := 0.0
## Las aristas del marco ya puestas (para no poner dos veces la de dos paños que se tocan).
var _edges := {}


## ── LA PLANTA (todo en celdas chicas de la forma, ver CabinGrid) ──────────────────────────────────────────────────

## El corte de las esquinas, de cada lado de la esquina, por dentro (m).
static func corner() -> float:
	return CabinGrid.CORNER_CELLS * CabinGrid.CELL


## La tarima: de su centro a cada lado (m), cuántos escalones (con ella) y su alto.
static func deck_reach() -> float:
	return CabinGrid.DECK_CELLS * CabinGrid.CELL


static func deck_tall() -> float:
	return CabinGrid.DECK_STEPS * STEP_TALL


## Hasta dónde llegan los escalones, del centro (m).
static func deck_foot() -> float:
	return deck_reach() + (CabinGrid.DECK_STEPS - 1) * Stairs.TREAD


## EL ASCENSOR, adentro de la tarima: su centro, corrido atrás, y su radio (el de la forma, o menos si no entra: deja
## por lo menos 12 cm de tarima detrás).
static func lift_center() -> Vector2:
	return Vector2(0.0, minf(CabinGrid.LIFT_BACK_CELLS * CabinGrid.CELL, deck_reach() - 0.42))


static func lift_radius() -> float:
	return clampf(CabinGrid.LIFT_HOLE, 0.3, deck_reach() - lift_center().y - 0.12)


## LAS TRES SILLAS DE ADELANTE, en el piso, de izquierda a derecha (el brazo izquierdo, la espalda, el brazo derecho):
## la del medio a 1,2 celdas de trama del vidrio; las de los brazos un paso atrás (2,2) y a 2,3 de los costados.
static func front_seats() -> Array[Vector3]:
	var inner := CabinGrid.INNER
	var trama := CabinGrid.TRAMA
	var y := CabinGrid.floor_top()
	var arm := inner - 2.3 * trama
	return [Vector3(-arm, y, -inner + 2.2 * trama), Vector3(0.0, y, -inner + 1.2 * trama), Vector3(arm, y, -inner + 2.2 * trama)]


## LA SILLA DEL MOVIMIENTO: en la tarima, delante del ascensor, adentro de su borde.
static func top_seat_at() -> Vector3:
	var z := maxf(lift_center().y - lift_radius() - 0.45, -deck_reach() + 0.35)
	return Vector3(0.0, CabinGrid.floor_top() + deck_tall(), z)


func top_seat() -> Vector3:
	return top_seat_at()


## El borde de la caja con las esquinas cortadas, de `half` del centro a cada lado y `cut` de corte, en orden (de
## adelante a la izquierda, hacia la derecha): el frente, el chanfle de adelante a la derecha, el costado derecho, el de
## atrás a la derecha, la pared de atrás, el de atrás a la izquierda, el costado izquierdo, el de adelante a la izquierda.
static func outline(half: float, cut: float) -> PackedVector2Array:
	# Sin corte, el cuadrado (sin lados de largo cero).
	if cut < 0.001:
		return PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	return PackedVector2Array([Vector2(-half + cut, -half), Vector2(half - cut, -half), Vector2(half, -half + cut),
		Vector2(half, half - cut), Vector2(half - cut, half), Vector2(-half + cut, half), Vector2(-half, half - cut),
		Vector2(-half, -half + cut)])


## El borde de afuera de la caja: el de adentro corrido el espesor de la pared (el chanfle a 45° crece un poco menos).
static func outer_outline() -> PackedVector2Array:
	return outline(CabinGrid.HALF, grown_corner(CabinGrid.WALL))


## El corte de las esquinas de un borde corrido `by` hacia afuera (a 45°, crece un poco menos; sin corte, sigue sin).
static func grown_corner(by: float) -> float:
	return corner() + by * (2.0 - sqrt(2.0)) if corner() > 0.001 else 0.0


## Un octógono regular con un lado al frente, de `reach` de su centro a cada lado.
static func octagon(reach: float) -> PackedVector2Array:
	var tip := reach / cos(PI / 8.0)
	var points := PackedVector2Array()
	for i in 8:
		var angle := PI / 8.0 + TAU * i / 8.0
		points.append(Vector2(sin(angle), -cos(angle)) * tip)
	return points


## ── EL ARMADO ─────────────────────────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	name = "Cabina con chanfles"
	interior = StaticBody3D.new()
	interior.name = "Interior"
	interior.collision_layer = 0
	interior.collision_mask = 0
	add_child(interior)
	var half := CabinGrid.HALF
	_side_to = CabinGrid.line(CabinGrid.SIDE_GLASS)
	if CabinGrid.ramp():
		_cut = 0.0
		_roof_to = _side_to
	else:
		_cut = CabinGrid.CHAMFER * CabinGrid.TRAMA
		_roof_to = maxf(CabinGrid.line(CabinGrid.ROOF_GLASS), -half + _cut)
	var floor_top := CabinGrid.floor_top()
	var center := lift_center()
	var hole := lift_radius()
	# El piso, con el hueco del ascensor.
	var floor_edge := _fine(outer_outline())
	add_child(_plate(floor_edge, _gap(floor_edge, center, hole), floor_top - SLAB, floor_top, Clay.METAL.darkened(0.12)))
	_ring_shapes(floor_edge, _gap(floor_edge, center, hole), floor_top - SLAB, floor_top)
	_base(floor_edge, center, hole)
	_walls()
	_roof()
	if CabinGrid.FRAME_KIND == 2:
		_posts()
	_deck(center, hole)
	_supplies()
	_seats_here()
	lift = PelvisLift.new()
	lift.solid = interior
	lift.hole_radius = hole
	lift.raised_at = floor_top + deck_tall()
	lift.lowered_at = PelvisLift.lowered()
	lift.center = center
	lift.square_shape = false
	add_child(lift)


## LA PELVIS DE ABAJO (CabinGrid.BASE): una placa chata con la planta de la caja, del fondo de la caja al piso, con el
## hueco del ascensor; en la junta con el piso, una franja un poco más ancha y más oscura (como el disco de la redonda).
## De abajo de ella salen las piernas: es parte de la caja.
func _base(edge: PackedVector2Array, center: Vector2, hole: float) -> void:
	if CabinGrid.BASE < 0.01:
		return
	var bottom := -CabinGrid.HALF_HEIGHT
	var joint := CabinGrid.floor_top() - SLAB
	var gap := _gap(edge, center, hole)
	var base := _plate(edge, gap, bottom, joint, Clay.METAL.darkened(0.25))
	base.name = "Pelvis de abajo"
	add_child(base)
	_ring_shapes(edge, gap, bottom, joint)
	var belt := _fine(outline(CabinGrid.HALF + 0.06, grown_corner(CabinGrid.WALL + 0.06)))
	add_child(_plate(belt, edge, joint - 0.06, joint + 0.06, Clay.METAL.darkened(0.35)))


## LA CABEZA, COMO PERFIL: el alto de arriba de la caja (la cara de afuera del techo) en `z`. Plana: arriba de todo,
## salvo el corte a 45° del frente. En rampa: del alto del frente sube derecho hasta donde termina el vidrio de los
## costados; de ahí atrás, arriba de todo.
func _top(z: float) -> float:
	var half := CabinGrid.HALF
	var high := CabinGrid.HALF_HEIGHT
	if CabinGrid.ramp():
		var low := CabinGrid.floor_top() + CabinGrid.front_clear() + SLAB
		return lerpf(low, high, clampf((z + half) / (_side_to + half), 0.0, 1.0))
	return high - maxf(0.0, _cut - (z + half))


## Donde el perfil dobla (ahí se parten las paredes y el techo).
func _bends() -> Array[float]:
	var bends: Array[float] = []
	if CabinGrid.ramp():
		bends.append(_side_to)
	elif _cut > 0.0:
		bends.append(-CabinGrid.HALF + _cut)
	return bends


## LAS PAREDES, tramo por tramo del borde de afuera (partido donde dobla el perfil y donde termina el vidrio). Las de
## adelante de `_side_to`, de vidrio, con el zócalo abajo; las demás, de metal, de piso a techo.
func _walls() -> void:
	var floor_top := CabinGrid.floor_top()
	var sill := CabinGrid.sill()
	var low := floor_top + sill
	var cuts := _bends()
	cuts.append(_side_to)
	var edge := _split(outer_outline(), cuts)
	for i in edge.size():
		var a := edge[i]
		var b := edge[(i + 1) % edge.size()]
		var length := a.distance_to(b)
		if length < 0.01:
			continue
		var inward := -_outward(a, b)
		var turn := Basis(Vector3.UP, atan2(-(b - a).y, (b - a).x))
		var middle := (a + b) * 0.5 + inward * WALL * 0.5
		if (a.y + b.y) * 0.5 >= _side_to - 0.001:
			_turned(Vector3(length + WALL * 0.4, CabinGrid.CLEAR, WALL), Vector3(middle.x, (floor_top + CabinGrid.ceiling()) * 0.5,
				middle.y), turn)
			continue
		if sill > 0.0:
			_turned(Vector3(length, sill, WALL), Vector3(middle.x, floor_top + sill * 0.5, middle.y), turn)
		var top_a := _top(a.y)
		var top_b := _top(b.y)
		_pane([_v(a, low), _v(b, low), _v(b, top_b), _v(a, top_a)])
		var face := (a + b) * 0.5 - inward * 0.03
		Clay.shape_box(interior, Vector3(length, maxf(top_a, top_b) - low, 0.1), Vector3(face.x, (low + maxf(top_a, top_b)) * 0.5,
			face.y), turn)
		_edge(_v(a, low), _v(b, low))
		_edge(_v(a, top_a), _v(b, top_b))
		_edge(_v(a, low), _v(a, top_a))
		_edge(_v(b, low), _v(b, top_b))


## EL TECHO, en franjas de adelante hacia atrás (partido donde dobla el perfil y donde termina su vidrio): cada franja,
## plana; las de adelante de `_roof_to`, de vidrio; las demás, una losa de metal.
func _roof() -> void:
	var half := CabinGrid.HALF
	var lines: Array[float] = [-half - 1.0]
	for z in _bends():
		lines.append(z)
	lines.append(_roof_to)
	lines.append(half + 1.0)
	lines.sort()
	var edge := outer_outline()
	for k in lines.size() - 1:
		if lines[k + 1] - lines[k] < 0.01:
			continue
		var part := _clip(edge, lines[k], lines[k + 1])
		if part.size() < 3:
			continue
		var top := PackedVector3Array()
		var under := PackedVector3Array()
		for point in part:
			top.append(_v(point, _top(point.y)))
			under.append(_v(point, _top(point.y) - SLAB))
		var hull := top.duplicate()
		hull.append_array(under)
		_convex(hull)
		if lines[k + 1] <= _roof_to + 0.001:
			_pane(Array(top))
			for i in top.size():
				_edge(top[i], top[(i + 1) % top.size()])
		else:
			var slab := _slab(top, under, Clay.METAL)
			slab.name = "Techo"
			add_child(slab)


## LOS PARANTES ENTRE PUESTOS (CabinGrid.FRAME_KIND 2): entre la silla del medio y cada brazo, uno que sube por el frente
## y sigue por el vidrio del techo, doblando donde dobla el perfil.
func _posts() -> void:
	var half := CabinGrid.HALF
	var post := CabinGrid.POST_THICKNESS
	var low := CabinGrid.floor_top() + CabinGrid.sill()
	var stops: Array[float] = [-half]
	for z in _bends():
		if z > -half and z < _roof_to:
			stops.append(z)
	stops.append(_roof_to)
	for x: float in [front_seats()[0].x * 0.5, front_seats()[2].x * 0.5]:
		_bar(Vector3(x, low, -half), Vector3(x, _top(-half), -half), post)
		for k in stops.size() - 1:
			_bar(Vector3(x, _top(stops[k]), stops[k]), Vector3(x, _top(stops[k + 1]), stops[k + 1]), post)


## LA TARIMA OCTOGONAL: arriba, la placa con el hueco del ascensor (de piso a arriba, así el hueco tiene su pared); los
## escalones, anillos de octógono alrededor, cada uno un escalón más bajo. Para la cápsula, una rampa de cada lado: del
## piso, un poco afuera del último escalón, al borde de la tarima (los pies pisan los escalones).
func _deck(center: Vector2, hole: float) -> void:
	var floor_top := CabinGrid.floor_top()
	var steps := CabinGrid.DECK_STEPS
	var reach := deck_reach()
	var top_edge := _fine(octagon(reach))
	var gap := _gap(top_edge, center, hole)
	add_child(_plate(top_edge, gap, floor_top, floor_top + deck_tall(), DECK))
	_ring_shapes(top_edge, gap, floor_top, floor_top + deck_tall())
	for k in range(1, steps):
		var tall := (steps - k) * STEP_TALL
		add_child(_plate(octagon(reach + k * Stairs.TREAD), octagon(reach + (k - 1) * Stairs.TREAD), floor_top, floor_top + tall,
			DECK.darkened(0.05 * k)))
	var deck := octagon(reach)
	var foot := octagon(deck_foot() + 0.15)
	for i in 8:
		var j := (i + 1) % 8
		_convex(PackedVector3Array([_v(deck[i], floor_top + deck_tall()), _v(deck[j], floor_top + deck_tall()),
			_v(deck[i], floor_top), _v(deck[j], floor_top), _v(foot[i], floor_top), _v(foot[j], floor_top)]))


## LOS RECURSOS (sólo se ven): dos kits en cada chanfle de atrás; las dos municiones arriba y la batería al medio en la
## pared de atrás.
func _supplies() -> void:
	var inner := CabinGrid.INNER
	var floor_top := CabinGrid.floor_top()
	var cut := corner()
	var kit := minf(0.5, cut * sqrt(2.0) * 0.45)
	# SIN LUGAR EN LOS CHANFLES (el corte chico o cero; el usuario, 15/11/2026, eligió que el corte llegue a 0): los
	# cuatro kits en la pared de atrás, a los costados de las municiones.
	if kit < 0.3:
		for x: float in [-1.8, -1.2, 1.2, 1.8]:
			Clay.box(self, Vector3(0.5, 0.5, 0.12), Vector3(x, floor_top + 0.7, inner - 0.06), KIT)
	for side: float in ([] if kit < 0.3 else [-1.0, 1.0]):
		var middle := Vector2(side * (inner - cut * 0.5), inner - cut * 0.5)
		var out := Vector2(side, 1.0).normalized()
		var along := Vector2(-out.y, out.x)
		for shift: float in [-0.55, 0.55]:
			var spot := middle + along * shift * kit - out * 0.06
			var box := Clay.box(self, Vector3(kit, kit, 0.12), _v(spot, floor_top + 0.7), KIT)
			box.basis = Basis(Vector3.UP, atan2(-along.y, along.x))
	for x: float in [-0.6, 0.6]:
		Clay.box(self, Vector3(0.6, 0.6, 0.12), Vector3(x, floor_top + 1.4, inner - 0.06), AMMO)
	Clay.box(self, Vector3(0.4, 0.5, 0.12), Vector3(0.0, floor_top + 0.6, inner - 0.06), BATTERY)


## LAS SILLAS, las de verdad, en el orden de `POSTS`, mirando al frente.
func _seats_here() -> void:
	var places := front_seats()
	places.append(top_seat_at())
	for index in places.size():
		var chair := (load(SEAT_SCENE) as PackedScene).instantiate() as SeatInteractable
		chair.name = "Asiento %s" % POSTS[index]
		chair.position = places[index]
		chair.eye_height = CabinGrid.EYE_HEIGHT
		add_child(chair)
		chairs.append(chair)


## Sin puestos, por ahora: los de SeatStation se apoyan en el tablero, y esta no tiene.
func _stations() -> void:
	pass


## EL MARCO: la caja y el hueco del ascensor, por debajo del piso hasta su parada de abajo.
func build_frame() -> void:
	frame = MotionFrame.new()
	mech.add_child(frame)
	frame.floor_height = CabinGrid.floor_top()
	frame.add_volume(AABB(-CabinGrid.box() * 0.5, CabinGrid.box()))
	var center := lift_center()
	var reach := lift_radius() + 0.3
	var low := PelvisLift.lowered() + 0.55
	var bottom := CabinGrid.floor_top() - SLAB
	frame.add_volume(AABB(Vector3(center.x - reach, low, center.y - reach), Vector3(reach * 2.0, bottom + 0.3 - low, reach * 2.0)))
	interior.collision_layer = 1
	frame.cast_shadow(self)
	interior.collision_layer = 0
	interior.collision_mask = 0
	for body in find_children("*", "RigidBody3D", true, false):
		mech.add_collision_exception_with(body as RigidBody3D)


## LA U: al piso, entre la silla del medio y los escalones, mirando al frente.
func board() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if mech.keys.driving:
		SandboxPossession.of(get_tree()).release()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	var spot := Vector3(0.0, CabinGrid.floor_top() + 0.05, (front_seats()[1].z - deck_foot()) * 0.5)
	player.place_at(mech.global_transform * spot, mech.yaw())


## ── LAS PIEZAS ─────────────────────────────────────────────────────────────────────────────────────────────────

## Un borde partido en `PER_EDGE` tramos por lado (para emparejarlo con un hueco redondo, ver `_gap`).
static func _fine(edge: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in edge.size():
		for k in PER_EDGE:
			out.append(edge[i].lerp(edge[(i + 1) % edge.size()], float(k) / PER_EDGE))
	return out


## EL HUECO DEL ASCENSOR para una placa de borde `edge`: un círculo de `radius` en `center`, con tantos puntos como el
## borde y parejos, empezando por el ángulo del primero (así cada punto del borde tiene el suyo enfrente).
static func _gap(edge: PackedVector2Array, center: Vector2, radius: float) -> PackedVector2Array:
	var first := edge[0] - center
	var start := atan2(first.x, -first.y)
	var out := PackedVector2Array()
	for i in edge.size():
		var angle := start + TAU * i / edge.size()
		out.append(center + Vector2(sin(angle), -cos(angle)) * radius)
	return out


## Hacia afuera del tramo de `a` a `b` (el borde rodea al centro).
static func _outward(a: Vector2, b: Vector2) -> Vector2:
	var normal := Vector2(b.y - a.y, a.x - b.x).normalized()
	return normal if normal.dot((a + b) * 0.5) > 0.0 else -normal


## El borde con un punto más donde cada lado cruza cada `z` de `cuts`.
static func _split(edge: PackedVector2Array, cuts: Array[float]) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in edge.size():
		var a := edge[i]
		var b := edge[(i + 1) % edge.size()]
		out.append(a)
		var crossings: Array[float] = []
		for z in cuts:
			if (a.y - z) * (b.y - z) < 0.0:
				crossings.append((z - a.y) / (b.y - a.y))
		crossings.sort()
		for t in crossings:
			out.append(a.lerp(b, t))
	return out


## Lo de un borde convexo entre `z0` y `z1`.
static func _clip(edge: PackedVector2Array, z0: float, z1: float) -> PackedVector2Array:
	var out := edge
	for limit: Array in [[z0, 1.0], [z1, -1.0]]:
		var z: float = limit[0]
		var keep: float = limit[1]
		var kept := PackedVector2Array()
		for i in out.size():
			var a := out[i]
			var b := out[(i + 1) % out.size()]
			var a_in := (a.y - z) * keep >= 0.0
			var b_in := (b.y - z) * keep >= 0.0
			if a_in:
				kept.append(a)
			if a_in != b_in:
				kept.append(a.lerp(b, (z - a.y) / (b.y - a.y)))
		out = kept
	return out


## Una caja girada, que se ve y se choca.
func _turned(size: Vector3, at: Vector3, turn: Basis) -> void:
	var part := Clay.box(self, size, at, Clay.METAL)
	part.basis = turn
	Clay.shape_box(interior, size, at, turn)


## Una arista del marco, una sola vez aunque la pidan dos paños (CabinGrid.FRAME_KIND: ninguna si es 0).
func _edge(a: Vector3, b: Vector3) -> void:
	if CabinGrid.FRAME_KIND == 0 or a.distance_to(b) < 0.01:
		return
	var key_a := str(a.snappedf(0.01))
	var key_b := str(b.snappedf(0.01))
	var key := key_a + key_b if key_a < key_b else key_b + key_a
	if _edges.has(key):
		return
	_edges[key] = true
	_bar(a, b, CabinGrid.EDGE_THICKNESS)


## Una losa de dos caras (`top` y `under`, los mismos puntos en orden) con sus cantos, plana.
func _slab(top: PackedVector3Array, under: PackedVector3Array, color: Color) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, top.size() - 1):
		_quad(tool, top[0], top[i], top[i + 1], top[i + 1], FLAT)
		_quad(tool, under[0], under[i + 1], under[i], under[i], FLAT)
	for i in top.size():
		var j := (i + 1) % top.size()
		_quad(tool, under[i], under[j], top[j], top[i], FLAT)
	return _mesh(tool, color)
