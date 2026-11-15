class_name VortexCabin
extends MechCabin

## EL DISCO DE DOS PISOS CON VÓRTICE (15/11/2026, el usuario, de la maqueta tests/vortex_disc_look: «creo que hay
## potencial, ponémelo con brazos reales (con física), piernas reales, y torso con física en una parcela al principio
## del sandbox así lo pruebo y veo cómo se siente»). Una cabina más de la meca (ver Mech.Cabin.VORTEX), sin sillas ni
## ascensor:
##   · EL VÓRTICE: una columna opaca en el centro, con la boca abajo del disco. El que se para debajo sube chupado por
##     adentro de la boca y sale a la planta baja por un hueco del piso (de radio `TUBE`); el que pisa el hueco baja
##     despacio hasta el suelo (ver `_physics_process`). Llega hasta el suelo con la meca parada: por ahora no hace falta agacharla.
##   · LA PLANTA BAJA, cerrada: la máquina, el banco de reparación, el tablero de la energía y las municiones (sólo se
##     ven). La ESCALERA CARACOL, pegada a la pared, sube al primer piso por un hueco del piso de arriba; se pisa una
##     rampa en hélice (los escalones se ven).
##   · EL PRIMER PISO, abierto: el anillo alrededor de un núcleo opaco que no se cruza; el borde con su bevel; ATRÁS,
##     ELEVADO con un escalón (el piso y el borde suben juntos); LAS ZONAS DE TABLEROS, piezas paradas en el piso que
##     crecen hasta el canto de afuera del disco, de anchos distintos (el manejo, los brazos, una chica); las
##     ametralladoras a la altura del borde, en sus enchufes (sólo se ven). Es la idea 9 de tests/vortex_ideas_look
##     (el usuario: «sí, al juego, pero las ametralladoras no me gustan subidas, y las zonas de tableros haría que tengan
##     tamaños más variados, y tamaño mínimo, como zonas»).
## Arriba se camina al aire libre: el marco (ver MechCabin) lleva a todos hasta 2,6 m sobre el primer piso.

## LA FORMA SE CAMBIA JUGANDO (el F2 de su fila, VortexShapePanel; se guarda en `SAVED`, ver VortexShape): el radio, el
## alto de la planta baja, el núcleo del medio, el ancho de la escalera y el largo de los brazos y las piernas de esta
## meca. Lo demás sale de acá. *El radio era 3,2 y la planta baja 2,3; el usuario los fue subiendo al probarla.*
const SAVED := "res://game/mech/vortex/vortex_shape.tres"
const BODY_FIELDS: Array[String] = ["arm_length", "leg_length", "thickness", "leg_stretch", "shoulder_out"]
static var OUTER := 5.5
static var WALK := 5.05
static var CLEAR := 3.0
static var STAIR_OUT := 5.0
static var STAIR_IN := 3.2
static var CORE_ON := true
## ATRÁS ELEVADO: si va, desde qué z hacia atrás (en partes del radio que se camina) y cuánto sube (m).
static var BACK_ON := true
const BACK_FROM := 0.24
const RAISE := 0.6
## LAS ZONAS DE TABLEROS: [ángulo (grados, desde el frente hacia la derecha), ancho (m), qué es]. Ninguna más angosta que
## `MIN_ZONE`; salen `ZONE_DEPTH` hacia adentro del borde y llegan hasta el canto de afuera; `ZONE_TALL` de alto.
const ZONES := [[0.0, 2.6, "drive"], [70.0, 1.6, "arm"], [290.0, 1.1, "arm"], [265.0, 0.9, "panel"]]
const MIN_ZONE := 0.9
const ZONE_DEPTH := 0.7
const ZONE_TALL := 1.1
## Las ametralladoras y los enchufes vacíos, en el borde (grados).
const GUNS := [45.0, 315.0]
const SOCKETS := [100.0, 180.0, 240.0]
## EL CUERPO DE ESTA MECA (los campos de la pestaña «Brazos y piernas», ver VortexShape) y lo que sale de él: el largo
## de las piernas y de los brazos en partes de los de las otras (los lee Mech.cabin_kit).
static var BODY := VortexShape.new()
const RIM_OUT := 1.0
const RIM_IN := 0.8
const SHELL := 0.15
const CORE := 0.85
## El radio del vórtice (m): el hueco del piso de la planta baja por donde sube; aparte del núcleo de arriba.
static var TUBE := 0.7
const TUBE_WALL := 0.12
const DECK_SLAB := 0.25
const STAIR_FROM := PI / 3.0
const STAIR_TO := PI * 25.0 / 18.0
const STEPS := 14
## Hacia dónde te deja el vórtice, al lado del hueco (ángulo desde el frente, hacia la derecha).
const EXIT_AT := PI * 11.0 / 6.0
## LO QUE HACE EL VÓRTICE: sube a esto (m/s) y baja a no más de esto.
const RISE := 6.0
const SINK := 4.0
## Arriba se camina hasta este alto sobre el primer piso (m): lo que lleva el marco.
const OPEN_ABOVE := 2.6

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const DECK := Color(0.72, 0.73, 0.75)
const LOW_FLOOR := Color(0.6, 0.58, 0.55)
const STAIR := Color(0.62, 0.55, 0.42)
const VORTEX := Color(0.36, 0.3, 0.5)
const RED := Color(0.8, 0.22, 0.18)
const YELLOW := Color(0.93, 0.75, 0.16)
const FACE := Color(0.92, 0.9, 0.84)

var _vortex: Area3D = null
## Los que están en el vórtice: cuerpo → true si sube, false si baja.
var _pulled := {}


static func _static_init() -> void:
	var saved := load(SAVED) as VortexShape if ResourceLoader.exists(SAVED) else null
	apply(saved if saved != null else VortexShape.new())


## TOMA LA FORMA. Las mecas que ya estaban no cambian: hay que rearmarlas (ver VortexShapePanel).
static func apply(shape: VortexShape) -> void:
	OUTER = shape.radius
	WALK = OUTER - 0.45
	CLEAR = shape.floor_height
	TUBE = shape.vortex_radius
	STAIR_OUT = WALK - 0.05
	# La escalera deja por lo menos un paso de 0,9 m entre ella y el tubo del vórtice.
	STAIR_IN = maxf(STAIR_OUT - shape.stair_width, TUBE + TUBE_WALL + 0.9)
	CORE_ON = shape.core
	BACK_ON = shape.back_raised
	for field: String in BODY_FIELDS:
		BODY.set(field, shape.get(field))


## La forma de hoy, para guardarla.
static func current() -> VortexShape:
	var now := VortexShape.new()
	now.radius = OUTER
	now.floor_height = CLEAR
	now.core = CORE_ON
	now.back_raised = BACK_ON
	now.vortex_radius = TUBE
	now.stair_width = STAIR_OUT - STAIR_IN
	for field: String in BODY_FIELDS:
		now.set(field, BODY.get(field))
	return now


## LA CAJA, EL HOMBRO Y LOS PISOS (en el espacio de la caja: el centro, en el medio).
static func box() -> Vector3:
	return Vector3(OUTER * 2.0, height(), OUTER * 2.0)


static func height() -> float:
	return DECK_SLAB + CLEAR + DECK_SLAB + RIM_OUT


static func bottom() -> float:
	return -height() * 0.5


static func ground_floor() -> float:
	return bottom() + DECK_SLAB


static func upper_floor() -> float:
	return ground_floor() + CLEAR + DECK_SLAB


static func shoulder() -> Vector3:
	return Vector3(OUTER, ground_floor() + 1.25, 0.0)


static func out(angle: float) -> Vector3:
	return Vector3(sin(angle), 0.0, -cos(angle))


## Desde qué z empieza atrás (hacia +z).
static func back_from() -> float:
	return WALK * BACK_FROM


## Si el punto a `reach` del centro hacia `angle` está en la parte elevada de atrás.
static func is_back(angle: float, reach: float) -> bool:
	return BACK_ON and -cos(angle) * reach > back_from()


## El piso donde se pisa hacia `angle`, a `reach` del centro: el primer piso, o atrás, más alto.
static func floor_at(angle: float, reach: float) -> float:
	return upper_floor() + (RAISE if is_back(angle, reach) else 0.0)


## El alto de arriba del borde hacia `angle` (por afuera).
static func rim_top(angle: float) -> float:
	return upper_floor() + RIM_OUT + (RAISE if is_back(angle, OUTER) else 0.0)


## Hasta dónde sube la escalera: el piso de arriba donde termina (atrás, más alto).
static func stair_top() -> float:
	return floor_at(STAIR_TO, (STAIR_IN + STAIR_OUT) * 0.5)


## Donde se mira en primera persona al poseerla: parado en el manejo, adelante (ver MechKeys.camera, que le suma el
## alto de los ojos sentado).
func top_seat() -> Vector3:
	return out(0.0) * (WALK - ZONE_DEPTH - 0.55) + Vector3(0.0, upper_floor() + 1.65 - SeatInteractable.STATION_EYE_HEIGHT,
		0.0)


func _ready() -> void:
	name = "Cabina del vórtice"
	interior = StaticBody3D.new()
	interior.name = "Interior"
	interior.collision_layer = 0
	interior.collision_mask = 0
	add_child(interior)
	_shell()
	_upstairs()
	_tube()
	_stairs()
	_rooms()
	_rim()
	if BACK_ON:
		_raised_back()
	for zone: Array in ZONES:
		_zone(deg_to_rad(zone[0]), maxf(zone[1], MIN_ZONE), zone[2])
	for degrees: float in GUNS:
		_gun(deg_to_rad(degrees), true)
	for degrees: float in SOCKETS:
		_gun(deg_to_rad(degrees), false)
	_vortex = Area3D.new()
	_vortex.name = "Vórtice"
	_vortex.collision_layer = 0
	_vortex.collision_mask = 1 | MotionFrame.LAYER
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	# Hasta el suelo con la meca parada, y un poco más (la tiene agachada o en un pozo).
	var low := -Mech.standing_height(Mech.Cabin.VORTEX) - 1.0
	var high := ground_floor() + 1.4
	# Del ancho del hueco: el que está parado al lado, en la planta baja, no se cae.
	cylinder.radius = TUBE
	cylinder.height = high - low
	shape.shape = cylinder
	shape.position.y = (low + high) * 0.5
	_vortex.add_child(shape)
	add_child(_vortex)


## ── LA CÁSCARA Y LOS PISOS ───────────────────────────────────────────────────────────────────────────────────────

func _shell() -> void:
	var low := bottom()
	var floor0 := ground_floor()
	var floor1 := upper_floor()
	var wall := OUTER - SHELL
	# Afuera: el fondo, la pared hasta el borde de arriba, el bevel y la cara de adentro del borde.
	_revolve(self, [Vector2(TUBE + TUBE_WALL, low), Vector2(OUTER - 0.15, low), Vector2(OUTER, low + 0.15),
		Vector2(OUTER, floor1)], METAL)
	# Adentro de la planta baja: la pared y el piso.
	_revolve(self, [Vector2(wall, floor1 - DECK_SLAB), Vector2(wall, floor0)], METAL.lightened(0.08))
	_revolve(self, [Vector2(wall, floor0), Vector2(TUBE + TUBE_WALL, floor0)], LOW_FLOOR)
	_arc_shapes(TUBE + TUBE_WALL, wall, 0.0, TAU, low, floor0)
	# La pared choca gruesa hacia afuera (el que se resbala adentro cuando la meca arranca no la atraviesa).
	_arc_shapes(wall, OUTER + 0.5, 0.0, TAU, floor0, floor1)


## EL PRIMER PISO: la losa con el hueco de la escalera (ver `_hole_from`) y el núcleo opaco.
func _upstairs() -> void:
	var floor1 := upper_floor()
	var wall := OUTER - SHELL
	var hole_from := _hole_from()
	for part: Array in [[0.0, STAIR_IN, 0.0, TAU], [STAIR_IN, STAIR_OUT, STAIR_TO, hole_from + TAU],
			[STAIR_OUT, wall, 0.0, TAU]]:
		var r0: float = part[0]
		var r1: float = part[1]
		_revolve(self, [Vector2(r1, floor1 - DECK_SLAB), Vector2(r1, floor1), Vector2(r0, floor1), Vector2(r0, floor1 - DECK_SLAB),
			Vector2(r1, floor1 - DECK_SLAB)], DECK, part[2], part[3])
		_arc_shapes(r0, r1, part[2], part[3], floor1 - DECK_SLAB, floor1)
	# Los cantos del hueco.
	for r: float in [STAIR_IN, STAIR_OUT]:
		_revolve(self, [Vector2(r, floor1), Vector2(r, floor1 - DECK_SLAB)], METAL, hole_from, STAIR_TO)
	var rail := stair_top() - floor1
	# La baranda del hueco, del lado de adentro (se ve; no choca: el que se cae, cae a la escalera).
	var posts := 8
	for i in posts + 1:
		var angle := lerpf(hole_from, STAIR_TO, float(i) / posts)
		var base := floor_at(angle, STAIR_IN + 0.05)
		Clay.cylinder(self, 0.03, 1.0, out(angle) * (STAIR_IN + 0.05) + Vector3(0, base + 0.5, 0), DARK_METAL)
	_revolve(self, [Vector2(STAIR_IN + 0.08, floor1 + rail + 1.0), Vector2(STAIR_IN + 0.08, floor1 + rail + 0.94)],
		DARK_METAL, maxf(hole_from, PI - acos(minf(back_from() / (STAIR_IN + 0.08), 1.0))) if BACK_ON else hole_from,
		STAIR_TO)
	# El núcleo: opaco, con una tapa; choca. Se puede sacar (ver VortexShape.core).
	if not CORE_ON:
		return
	_revolve(self, [Vector2(CORE, floor1), Vector2(CORE, floor1 + 1.9), Vector2(CORE - 0.15, floor1 + 2.05),
		Vector2(0.0, floor1 + 2.05)], DARK_METAL.lightened(0.15))
	_arc_shapes(0.0, CORE, 0.0, TAU, floor1, floor1 + 2.05)


## EL VÓRTICE: la boca acampanada debajo del disco y un hueco redondo en el piso de la planta baja, con un borde que se
## ve; adentro de la planta baja no hay nada que tape la vista (el usuario: «que el vórtice te lleve… y que no haya nada
## obstruyendo la vista en planta baja… eso violeta que está en planta baja hasta el primer piso lo sacás»; después
## irá una tapa de hojas que se abre en círculo). El que pisa el hueco cae despacio hasta el suelo.
func _tube() -> void:
	var low := bottom()
	var floor0 := ground_floor()
	_revolve(self, [Vector2(TUBE + 0.6, low - 0.3), Vector2(TUBE + TUBE_WALL, low - 0.05), Vector2(TUBE + TUBE_WALL, floor0)],
		VORTEX)
	_revolve(self, [Vector2(TUBE, floor0), Vector2(TUBE, low - 0.05), Vector2(TUBE + 0.45, low - 0.3)], VORTEX.darkened(0.5))
	_revolve(self, [Vector2(TUBE + 0.25, floor0 + 0.02), Vector2(TUBE, floor0 + 0.02)], YELLOW.darkened(0.25))
	_arc_shapes(TUBE, TUBE + TUBE_WALL, 0.0, TAU, low - 0.3, floor0)
	# La corriente que chupa, del suelo a la boca: se ve a través (es aire).
	var pull := StandardMaterial3D.new()
	pull.albedo_color = Color(0.6, 0.5, 0.9, 0.16)
	pull.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pull.cull_mode = BaseMaterial3D.CULL_DISABLED
	pull.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var air := _revolve(self, [Vector2(TUBE * 1.3, low - Mech.standing_height(Mech.Cabin.VORTEX) + height() * 0.5 + 0.02),
		Vector2(TUBE * 1.45, low - 0.3)], Color.WHITE)
	air.material_override = pull
	air.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## LA ESCALERA CARACOL: cada escalón, un trozo de anillo macizo hasta el piso, entre dos líneas que salen del centro
## (el usuario: «que se atenga más al cilindro, salen solos los escalones de líneas del centro»); se pisa una rampa en
## hélice.
func _stairs() -> void:
	var floor0 := ground_floor()
	var rise := (stair_top() - floor0) / STEPS
	var sweep := (STAIR_TO - STAIR_FROM) / STEPS
	for i in STEPS:
		add_child(_wedge(STAIR_IN, STAIR_OUT, STAIR_FROM + sweep * i, STAIR_FROM + sweep * (i + 1), floor0,
			floor0 + rise * (i + 1), STAIR.darkened(0.06 * (i % 2))))
	var pieces := STEPS * 2
	var span := (STAIR_TO - STAIR_FROM) / pieces
	var climb := (stair_top() - floor0) / pieces
	for i in pieces:
		var a0 := STAIR_FROM + span * i
		var a1 := a0 + span
		var h0 := floor0 + climb * i
		var h1 := h0 + climb
		var points := PackedVector3Array()
		for r: float in [STAIR_IN, STAIR_OUT]:
			points.append_array([out(a0) * r + Vector3(0, floor0, 0), out(a1) * r + Vector3(0, floor0, 0),
				out(a0) * r + Vector3(0, h0, 0), out(a1) * r + Vector3(0, h1, 0)])
		_convex(points)


## LA PLANTA BAJA (sólo se ve): la máquina adelante, el banco de reparación, el tablero de la energía y las municiones.
func _rooms() -> void:
	var floor0 := ground_floor()
	var at := func(degrees: float, reach: float, y: float) -> Vector3:
		return out(deg_to_rad(degrees)) * reach + Vector3(0, floor0 + y, 0)
	Clay.box(self, Vector3(1.6, 1.5, 0.9), at.call(0.0, OUTER - 0.85, 0.75), DARK_METAL.lightened(0.1))
	Clay.shape_box(interior, Vector3(1.6, 1.5, 0.9), at.call(0.0, OUTER - 0.85, 0.75))
	for x: float in [-0.5, 0.0, 0.5]:
		Clay.cylinder(self, 0.08, 0.7, at.call(0.0, OUTER - 0.85, 1.85) + Vector3(x, 0, 0), METAL)
	Clay.cylinder(self, 0.25, 0.4, at.call(0.0, OUTER - 1.45, 0.9), RED, Vector3(90, 0, 0))
	var bench_angle := deg_to_rad(300.0)
	var bench := Clay.box(self, Vector3(1.4, 0.9, 0.6), at.call(300.0, OUTER - 0.6, 0.45), Color(0.5, 0.42, 0.32))
	bench.rotation.y = -bench_angle
	Clay.shape_box(interior, Vector3(1.4, 0.9, 0.6), bench.position, bench.basis)
	Clay.box(self, Vector3(0.3, 0.2, 0.3), bench.position + Vector3(0, 0.55, 0), METAL)
	var panel := Clay.box(self, Vector3(1.0, 0.9, 0.12), at.call(340.0, OUTER - SHELL - 0.08, 1.3), DARK_METAL)
	panel.rotation.y = -deg_to_rad(340.0)
	for i in 3:
		var lever := Clay.cylinder(panel, 0.03, 0.4, Vector3((i - 1) * 0.3, (i - 1) * 0.12, 0.22), YELLOW, Vector3(90, 0, 0))
		lever.name = "Palanca %d" % i
	for i in 4:
		# Fuera de la escalera (que termina a los 250°): la cuarta, encima de la segunda.
		var angle := 262.0 + (i if i < 3 else 1) * 8.0
		var crate := Clay.box(self, Vector3(0.6, 0.45, 0.45), at.call(angle, OUTER - 0.65, 0.225 + (0.45 if i == 3 else 0.0)), AMMO)
		crate.rotation.y = -deg_to_rad(angle)


## EL BORDE: por afuera, la pared hasta `rim_top`; arriba, el bevel hacia adentro; por adentro, la cara hasta el piso
## (atrás, hasta el piso elevado). Choca hasta su alto.
func _rim() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var floor1 := upper_floor()
	var sides := 192
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var t0 := rim_top(a0)
		var t1 := rim_top(a1)
		var bevel := RIM_OUT - RIM_IN
		var low0 := floor_at(a0, WALK)
		var low1 := floor_at(a1, WALK)
		_quad(tool, out(a0) * OUTER + Vector3(0, floor1, 0), out(a1) * OUTER + Vector3(0, floor1, 0),
			out(a1) * OUTER + Vector3(0, t1, 0), out(a0) * OUTER + Vector3(0, t0, 0), FLAT)
		_quad(tool, out(a0) * OUTER + Vector3(0, t0, 0), out(a1) * OUTER + Vector3(0, t1, 0),
			out(a1) * WALK + Vector3(0, t1 - bevel, 0), out(a0) * WALK + Vector3(0, t0 - bevel, 0), FLAT)
		_quad(tool, out(a0) * WALK + Vector3(0, t0 - bevel, 0), out(a1) * WALK + Vector3(0, t1 - bevel, 0),
			out(a1) * WALK + Vector3(0, low1, 0), out(a0) * WALK + Vector3(0, low0, 0), FLAT)
	add_child(_mesh(tool, METAL))
	var pieces := 64
	for k in pieces:
		var a0 := TAU * k / pieces
		var a1 := TAU * (k + 1) / pieces
		_arc_shapes(WALK, OUTER + 0.5, a0, a1, floor1, rim_top((a0 + a1) * 0.5))


## ATRÁS ELEVADO: el trozo de piso detrás de `back_from`, `RAISE` más alto, con su escalón (el canto, marcado); el hueco
## de la escalera sigue abierto. Se ve y se pisa.
func _raised_back() -> void:
	var floor1 := upper_floor()
	var top := floor1 + RAISE
	var edge := back_from()
	var half := acos(edge / WALK)
	var hole_from := _hole_from()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pieces := 48
	for k in pieces:
		var a0 := PI - half + 2.0 * half * k / pieces
		var a1 := PI - half + 2.0 * half * (k + 1) / pieces
		var middle := (a0 + a1) * 0.5
		var r0 := minf(edge / maxf(-cos(a0), 0.001), WALK)
		var r1 := minf(edge / maxf(-cos(a1), 0.001), WALK)
		var spans: Array = [[r0, r1, WALK]]
		if middle > hole_from and middle < STAIR_TO:
			spans = [[r0, r1, STAIR_IN], [STAIR_OUT, STAIR_OUT, WALK]]
		for span: Array in spans:
			var in0: float = span[0]
			var in1: float = span[1]
			var far: float = span[2]
			if in0 >= far and in1 >= far:
				continue
			in0 = minf(in0, far)
			in1 = minf(in1, far)
			var p := [out(a0) * in0, out(a1) * in1, out(a1) * far, out(a0) * far]
			_quad(tool, p[0] + Vector3(0, top, 0), p[3] + Vector3(0, top, 0), p[2] + Vector3(0, top, 0),
				p[1] + Vector3(0, top, 0), FLAT)
			_quad(tool, p[0] + Vector3(0, floor1, 0), p[0] + Vector3(0, top, 0), p[1] + Vector3(0, top, 0),
				p[1] + Vector3(0, floor1, 0), FLAT)
			var points := PackedVector3Array()
			for corner: Vector3 in p:
				points.append_array([corner + Vector3(0, floor1, 0), corner + Vector3(0, top, 0)])
			_convex(points)
	add_child(_mesh(tool, DECK.darkened(0.08)))
	var width := 2.0 * sqrt(WALK * WALK - edge * edge)
	Clay.box(self, Vector3(width, 0.06, 0.1), Vector3(0.0, top - 0.03, edge + 0.05), YELLOW.darkened(0.3))


## UNA ZONA DE TABLEROS hacia `angle`, de `wide` de ancho: una pieza parada en el piso que sale `ZONE_DEPTH` hacia
## adentro del borde y llega hasta el canto de afuera del disco, con la cara de arriba inclinada hacia adentro y los
## mandos de lo que es (el manejo: palancas; un brazo: dos mandos; las otras: botones), repartidos por su ancho.
func _zone(angle: float, wide: float, kind: String) -> void:
	var inner := WALK - ZONE_DEPTH
	var depth := OUTER - inner
	var base := floor_at(angle, inner)
	var holder := Node3D.new()
	holder.position = out(angle) * (inner + depth * 0.5) + Vector3(0, base, 0)
	holder.rotation.y = -angle
	add_child(holder)
	Clay.box(holder, Vector3(wide, ZONE_TALL, depth), Vector3(0, ZONE_TALL * 0.5, 0), METAL.darkened(0.1))
	Clay.shape_box(interior, Vector3(wide, ZONE_TALL, depth), holder.position + Vector3(0, ZONE_TALL * 0.5, 0),
		holder.basis)
	# La cara de los mandos: arriba, en el lado de adentro, inclinada hacia quien está parado delante.
	var face := Node3D.new()
	face.position = Vector3(0, ZONE_TALL + 0.04, depth * 0.5 - 0.35)
	face.rotation.x = deg_to_rad(30.0)
	holder.add_child(face)
	Clay.box(face, Vector3(wide - 0.1, 0.06, 0.6), Vector3.ZERO, DARK_METAL)
	var groups := maxi(1, floori(wide / 0.7))
	for g in groups:
		var x := (g - (groups - 1) * 0.5) * (wide - 0.2) / groups
		match kind:
			"drive":
				Clay.cylinder(face, 0.025, 0.42, Vector3(x, 0.24, 0.0), DARK_METAL)
				Clay.sphere(face, 0.06, Vector3(x, 0.46, 0.0), RED)
			"arm":
				Clay.cylinder(face, 0.04, 0.3, Vector3(x, 0.17, 0.0), DARK_METAL)
				Clay.box(face, Vector3(0.1, 0.1, 0.18), Vector3(x, 0.34, 0.0), RED)
			_:
				Clay.cylinder(face, 0.06, 0.06, Vector3(x, 0.05, 0.0), YELLOW if g % 2 == 0 else RED)
	Clay.cylinder(face, 0.13, 0.04, Vector3(0.0, 0.04, 0.2), FACE)


## UNA AMETRALLADORA EN SU ENCHUFE (o el enchufe vacío) arriba del borde, a su altura (el usuario: «las ametralladoras
## no me gustan subidas»).
func _gun(angle: float, mounted: bool) -> void:
	var outward := out(angle)
	var top := rim_top(angle) - (RIM_OUT - RIM_IN) * 0.3
	Clay.box(self, Vector3(0.45, 0.06, 0.45), outward * (WALK + 0.32) + Vector3(0, top - 0.03, 0),
		YELLOW.darkened(0.3)).rotation.y = -angle
	if not mounted:
		return
	var gun := Node3D.new()
	gun.position = outward * (WALK + 0.32) + Vector3(0.0, top, 0.0)
	gun.rotation.y = -angle
	add_child(gun)
	Clay.cylinder(gun, 0.07, 0.3, Vector3(0.0, 0.15, 0.0), DARK_METAL)
	Clay.box(gun, Vector3(0.24, 0.24, 0.6), Vector3(0.0, 0.4, -0.05), DARK_METAL)
	Clay.cylinder(gun, 0.05, 0.85, Vector3(0.0, 0.42, -0.75), DARK_METAL, Vector3(90.0, 0.0, 0.0))
	Clay.box(gun, Vector3(0.5, 0.3, 0.04), Vector3(0.0, 0.5, -0.38), METAL)
	for side: float in [-1.0, 1.0]:
		Clay.cylinder(gun, 0.03, 0.2, Vector3(side * 0.13, 0.38, 0.3), YELLOW, Vector3(90.0, 0.0, 0.0))


## ── EL MARCO Y EL VÓRTICE ────────────────────────────────────────────────────────────────────────────────────────

## EL MARCO: la cabina entera (de la losa de abajo hasta `OPEN_ABOVE` sobre el primer piso, que está al aire libre) y
## la boca del vórtice, un poco debajo del disco.
func build_frame() -> void:
	frame = MotionFrame.new()
	mech.add_child(frame)
	frame.floor_height = ground_floor()
	var low := bottom()
	frame.add_volume(AABB(Vector3(-OUTER, low, -OUTER), Vector3(OUTER * 2.0, upper_floor() + OPEN_ABOVE - low, OUTER * 2.0)))
	frame.add_volume(AABB(Vector3(-TUBE, low - 1.2, -TUBE), Vector3(TUBE * 2.0, 1.2, TUBE * 2.0)))
	interior.collision_layer = 1
	frame.cast_shadow(self)
	interior.collision_layer = 0
	interior.collision_mask = 0
	for body in find_children("*", "RigidBody3D", true, false):
		mech.add_collision_exception_with(body as RigidBody3D)


## GENTE PARADA ADENTRO, PARA VER LA ESCALA (el usuario: «ponele personajes adentro así veo escala»): tres arriba,
## cada uno frente a un puesto (el manejo, el brazo izquierdo y la ametralladora de la izquierda), y uno en la planta
## baja, en el banco. Van al lado de la meca en el árbol (como los maniquíes de las sillas) y los lleva el marco.
func seat_dummies() -> void:
	var holder := mech.get_parent() as Node3D
	if holder == null:
		return
	var places := [[0.0, upper_floor(), WALK - ZONE_DEPTH - 0.5], [deg_to_rad(290.0), upper_floor(), WALK - ZONE_DEPTH - 0.45],
		[deg_to_rad(315.0), upper_floor(), WALK - 0.45], [deg_to_rad(300.0), ground_floor(), OUTER - 1.3]]
	for i in places.size():
		var angle: float = places[i][0]
		var spot: Vector3 = out(angle) * float(places[i][2]) + Vector3(0.0, places[i][1], 0.0)
		var person := PeopleArchetype.spawn(holder, DUMMY_BODIES[i % DUMMY_BODIES.size()], mech.global_transform * spot,
			mech.yaw() - angle)
		# Aparece adentro de la caja maciza: que no la empuje antes de que el marco lo lleve (ver `ride`).
		mech.add_collision_exception_with(person.char_rigidbody)
		dummies.append(person)


## LA U: a la planta baja, al lado del hueco del vórtice, mirándolo.
func board() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if mech.keys.driving:
		SandboxPossession.of(get_tree()).release()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	var spot := out(EXIT_AT) * (TUBE + 1.0) + Vector3(0.0, ground_floor() + 0.05, 0.0)
	player.place_at(mech.global_transform * spot, mech.yaw() - EXIT_AT + PI)


## LA CAJA NO CHOCA CON LOS QUE VAN ADENTRO (ver MechCabin.ride) NI CON LOS QUE ESTÁ LLEVANDO EL VÓRTICE: suben por
## debajo de la caja antes de entrar al marco, y bajan por debajo después de salir.
func ride() -> void:
	super()
	for body: Variant in _pulled.keys():
		if is_instance_valid(body):
			mech.add_collision_exception_with(body as PhysicsBody3D)


## EL VÓRTICE, en cada paso: a quien entra desde abajo lo sube por el tubo, hacia el medio, y arriba lo deja en la planta
## baja, al lado del hueco; a quien entra desde la planta baja (pisando el hueco) lo deja caer despacio hasta el suelo.
func _physics_process(_delta: float) -> void:
	if mech == null or _vortex == null:
		return
	var inside := {}
	for found in _vortex.get_overlapping_bodies():
		var body := found as CharacterRigidBody3D
		if body == null or not body.kind.simulates():
			continue
		inside[body] = true
		var local := mech.to_local(body.global_position)
		if not _pulled.has(body):
			_pulled[body] = local.y < ground_floor() - 0.6
			mech.add_collision_exception_with(body)
		var carried := mech.linear_velocity + mech.angular_velocity.cross(body.global_position - mech.global_position)
		var up := mech.global_basis.y
		var relative := body.linear_velocity - carried
		var toward := mech.global_basis * Vector3(-local.x, 0.0, -local.z)
		if _pulled[body]:
			if local.y >= ground_floor() + 1.0:
				_pop(body)
				continue
			body.linear_velocity = carried + toward * 4.0 + up * RISE
		else:
			var along := relative.dot(up)
			body.linear_velocity = carried + toward * 1.5 + (relative - up * along) * 0.5 + up * maxf(along, -SINK)
	for body: Variant in _pulled.keys():
		if inside.has(body):
			continue
		_pulled.erase(body)
		if is_instance_valid(body) and not frame._members.has(body):
			mech.remove_collision_exception_with(body as PhysicsBody3D)


## Arriba del hueco: lo para en la planta baja, al lado, mirando hacia afuera.
func _pop(body: CharacterRigidBody3D) -> void:
	_pulled.erase(body)
	for found in get_tree().root.find_children("*", "BoneInstantiator", true, false):
		var person := found as BoneInstantiator
		if person.char_rigidbody == body:
			var spot := out(EXIT_AT) * (TUBE + 1.0) + Vector3(0.0, ground_floor() + 0.05, 0.0)
			person.place_at(mech.global_transform * spot, mech.yaw() - EXIT_AT)
			return


## DESDE DÓNDE VA EL HUECO DE ARRIBA: desde el escalón en que, bajando, la cabeza ya no pasa debajo del piso de arriba.
func _hole_from() -> float:
	var rise := (stair_top() - ground_floor()) / STEPS
	var step := clampi(floori((CLEAR - 2.0) / rise), 1, STEPS - 2)
	return STAIR_FROM + (STAIR_TO - STAIR_FROM) * step / STEPS


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## UNA VUELTA (o un tramo, de `from` a `to`) de un perfil (`r`, `y`): suave alrededor, con aristas en el perfil.
func _revolve(parent: Node3D, profile: Array, color: Color, from := 0.0, to := TAU) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := maxi(4, ceili(64.0 * (to - from) / TAU))
	for s in sides:
		var a0 := lerpf(from, to, float(s) / sides)
		var a1 := lerpf(from, to, float(s + 1) / sides)
		for p in profile.size() - 1:
			var p0: Vector2 = profile[p]
			var p1: Vector2 = profile[p + 1]
			var edge := p1 - p0
			var normal := Vector2(edge.y, -edge.x).normalized()
			var quad := [[p0, a0], [p1, a0], [p1, a1], [p0, a1]]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				var point: Vector2 = quad[corner][0]
				var away := out(quad[corner][1])
				tool.set_normal(away * normal.x + Vector3.UP * normal.y)
				tool.add_vertex(away * point.x + Vector3.UP * point.y)
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	parent.add_child(mesh)
	return mesh


## UN TROZO DE ANILLO MACIZO, de `r0` a `r1`, entre los ángulos `a0` y `a1`, de `y0` a `y1`: las caras de adentro y de
## afuera, suaves; arriba y las dos puntas, planas.
func _wedge(r0: float, r1: float, a0: float, a1: float, y0: float, y1: float, color: Color) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var at := func(r: float, a: float, y: float) -> Vector3:
		return out(a) * r + Vector3(0.0, y, 0.0)
	var pieces := maxi(2, ceili(48.0 * (a1 - a0) / TAU))
	for k in pieces:
		var b0 := lerpf(a0, a1, float(k) / pieces)
		var b1 := lerpf(a0, a1, float(k + 1) / pieces)
		_quad(tool, at.call(r1, b0, y0), at.call(r1, b1, y0), at.call(r1, b1, y1), at.call(r1, b0, y1), SMOOTH_OUT)
		_quad(tool, at.call(r0, b1, y0), at.call(r0, b0, y0), at.call(r0, b0, y1), at.call(r0, b1, y1), SMOOTH_IN)
		_quad(tool, at.call(r0, b0, y1), at.call(r1, b0, y1), at.call(r1, b1, y1), at.call(r0, b1, y1), FLAT)
	for b: float in [a0, a1]:
		_quad(tool, at.call(r0, b, y0), at.call(r1, b, y0), at.call(r1, b, y1), at.call(r0, b, y1), FLAT)
	return _mesh(tool, color)


## Formas de choque de un anillo (o un tramo) entre `r0` y `r1`, de `y0` a `y1`: un trozo convexo cada tanto.
func _arc_shapes(r0: float, r1: float, from: float, to: float, y0: float, y1: float) -> void:
	var pieces := maxi(2, ceili(32.0 * (to - from) / TAU))
	for i in pieces:
		var a0 := lerpf(from, to, float(i) / pieces)
		var a1 := lerpf(from, to, float(i + 1) / pieces)
		var points := PackedVector3Array()
		for y: float in [y0, y1]:
			for a: float in [a0, a1]:
				points.append(out(a) * r1 + Vector3(0, y, 0))
				if r0 > 0.001:
					points.append(out(a) * r0 + Vector3(0, y, 0))
				else:
					points.append(Vector3(0, y, 0))
		_convex(points)
