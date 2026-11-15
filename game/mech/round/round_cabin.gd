class_name RoundCabin
extends MechCabin

## LA CABINA REDONDA (ver RoundGrid, docs/technical/cabina-redonda.md): la forma de la maqueta de arcilla
## (tests/round_cabin_look.tscn), en la meca de verdad. Lo que hace la cuadrada lo hereda (el marco, ir adentro, los
## maniquíes en las sillas, subir con la U); arma otra cosa:
##   · ADENTRO, LOS LADOS PLANOS, de metal atrás; AFUERA, la piel lisa del cilindro, de vidrio en los lados del frente,
##     de piso a techo. El techo, liso.
##   · DEBAJO DEL PISO, EL DISCO, macizo, con el hueco por donde pasa el ascensor.
##   · LA TARIMA, al centro, con un escalón alrededor que se ve; para la cápsula, una rampa (como las escaleras, ver
##     Stairs). Dentro de ella, corrido atrás, el ascensor (atraviesa la pelvis: después se arregla).
##   · LAS SILLAS: tres adelante, cada una en su lado, mirando hacia afuera; el movimiento en la tarima, delante del
##     ascensor. Sin tableros ni puestos (el usuario, 15/11/2026: «sacale los tableros y los hologramas a las sillas»).
##   · ATRÁS, en las paredes: los cuatro kits en los lados de los costados, y las dos municiones con la batería al medio
##     en el de atrás de todo (por ahora, sólo se ven).

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.42, 0.44, 0.47)
const FLOOR := Color(0.62, 0.63, 0.65)
const DECK := Color(0.7, 0.71, 0.73)
## Cuántos puntos por lado tienen las placas y los cilindros.
const PER_SIDE := 4


func top_seat() -> Vector3:
	return RoundGrid.top_seat()


func _ready() -> void:
	name = "Cabina redonda"
	interior = StaticBody3D.new()
	interior.name = "Interior"
	interior.collision_layer = 0
	interior.collision_mask = 0
	add_child(interior)
	var floor_top := RoundGrid.floor_top()
	var ceiling := RoundGrid.ceiling()
	var hole := Vector2(0.0, RoundGrid.LIFT_BACK)
	var hole_radius := RoundGrid.LIFT_R + CabinGrid.CELL
	var outer := RoundGrid.circle(RoundGrid.OUTER, Vector2.ZERO, PER_SIDE * 2)
	var gap := RoundGrid.circle(hole_radius, hole, PER_SIDE * 2)
	# El disco de abajo y la losa del piso, con el hueco del ascensor; el techo, liso.
	if RoundGrid.DISC > 0.01:
		add_child(_plate(outer, gap, -RoundGrid.HALF_HEIGHT, floor_top - RoundGrid.SLAB, DARK_METAL, true))
		var belt := RoundGrid.circle(RoundGrid.OUTER + 0.06, Vector2.ZERO, PER_SIDE * 2)
		add_child(_plate(belt, outer, floor_top - RoundGrid.SLAB - 0.06, floor_top - RoundGrid.SLAB + 0.06,
			METAL.darkened(0.25), true))
	add_child(_plate(outer, gap, floor_top - RoundGrid.SLAB, floor_top, FLOOR, true))
	var room := RoundGrid.polygon(RoundGrid.RADIUS, PER_SIDE * 2)
	_ring_shapes(room, RoundGrid.circle(hole_radius, hole, PER_SIDE * 2), floor_top - RoundGrid.SLAB, floor_top)
	if RoundGrid.DOME:
		_dome(ceiling)
	else:
		var roof := Clay.cylinder(self, RoundGrid.OUTER, RoundGrid.SLAB, Vector3(0, ceiling + RoundGrid.SLAB * 0.5, 0), METAL)
		(roof.mesh as CylinderMesh).radial_segments = 64
		roof.name = "Techo"
		Clay.shape_box(interior, Vector3(RoundGrid.OUTER * 2.0, RoundGrid.SLAB, RoundGrid.OUTER * 2.0),
			Vector3(0, ceiling + RoundGrid.SLAB * 0.5, 0))
	_walls(floor_top, ceiling)
	_deck(floor_top, hole, hole_radius)
	_supplies(floor_top)
	_round_seats()
	lift = PelvisLift.new()
	lift.solid = interior
	lift.hole_radius = hole_radius
	lift.raised_at = floor_top + RoundGrid.PLATFORM_TALL
	lift.lowered_at = PelvisLift.lowered(RoundGrid.HALF_HEIGHT)
	lift.center = hole
	add_child(lift)


## EL DOMO (ver RoundGrid.DOME): un casquete de esfera de metal, sin vidrio, que nace del borde de arriba de la piel y
## sube `DOME_TALL`; por dentro, abierto (la cabina gana todo ese alto). Su cara de adentro choca.
func _dome(base: float) -> void:
	var tall := RoundGrid.DOME_TALL
	var outer := _cap(RoundGrid.OUTER, tall)
	var inner := _cap(RoundGrid.APOTHEM, maxf(tall - RoundGrid.SLAB, 0.1))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var around := 64
	var faces := PackedVector3Array()
	for ring in outer.size() - 1:
		for k in around:
			var a0 := TAU * k / around
			var a1 := TAU * (k + 1) / around
			_quad(tool, _ring_at(outer[ring], a0, base), _ring_at(outer[ring], a1, base), _ring_at(outer[ring + 1], a1, base),
				_ring_at(outer[ring + 1], a0, base), SMOOTH_OUT)
			var p := [_ring_at(inner[ring], a0, base), _ring_at(inner[ring], a1, base), _ring_at(inner[ring + 1], a1, base),
				_ring_at(inner[ring + 1], a0, base)]
			_quad(tool, p[0], p[1], p[2], p[3], SMOOTH_IN)
			faces.append_array(PackedVector3Array([p[0], p[1], p[2], p[0], p[2], p[3]]))
	# El borde de abajo, entre las dos caras, plano.
	for k in around:
		var a0 := TAU * k / around
		var a1 := TAU * (k + 1) / around
		_quad(tool, _ring_at(inner[0], a0, base), _ring_at(inner[0], a1, base), _ring_at(outer[0], a1, base),
			_ring_at(outer[0], a0, base), FLAT)
	var dome := _mesh(tool, METAL)
	dome.name = "Techo"
	add_child(dome)
	var shape := CollisionShape3D.new()
	var hull := ConcavePolygonShape3D.new()
	hull.backface_collision = true
	hull.set_faces(faces)
	shape.shape = hull
	interior.add_child(shape)


## Los anillos de un casquete de esfera de base `radius` y alto `tall`, de la base a la punta: [radio, alto sobre la base].
func _cap(radius: float, tall: float) -> Array[Vector2]:
	var sphere := (radius * radius + tall * tall) / (2.0 * tall)
	var widest := atan2(radius, sphere - tall)
	var rings: Array[Vector2] = []
	var count := 14
	for i in count + 1:
		var angle := widest * (1.0 - float(i) / count)
		rings.append(Vector2(sphere * sin(angle), tall - sphere + sphere * cos(angle)))
	return rings


## Un punto de un anillo del domo, hacia el ángulo `angle`, sobre la base `base`.
func _ring_at(ring: Vector2, angle: float, base: float) -> Vector3:
	return RoundGrid.at(ring.x, angle, base + ring.y)


## LA PIEL Y LOS LADOS: afuera, la banda lisa (metal atrás, vidrio adelante); adentro, los lados planos de metal (los
## de vidrio no tienen: el vidrio es la piel). Todos los lados chocan, de piso a techo.
func _walls(floor_top: float, ceiling: float) -> void:
	var glass_half := PI * RoundGrid.GLASS_SIDES / RoundGrid.SIDES
	var apothem := RoundGrid.APOTHEM
	add_child(_band(apothem, RoundGrid.OUTER, glass_half, TAU - glass_half, floor_top, ceiling, METAL))
	# El visor: de vidrio desde el piso hasta su alto; arriba, hasta el techo, metal.
	var visor_top := floor_top + RoundGrid.VISOR
	if ceiling - visor_top > 0.01:
		add_child(_band(apothem, RoundGrid.OUTER, -glass_half, glass_half, visor_top, ceiling, METAL))
	var glass := _band(RoundGrid.OUTER - 0.03, RoundGrid.OUTER, -glass_half, glass_half, floor_top, visor_top, Color.WHITE)
	glass.name = "Vidrio"
	var paint := StandardMaterial3D.new()
	paint.albedo_color = RoundGrid.GLASS_COLOR
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.roughness = 0.15
	glass.material_override = paint
	add_child(glass)
	var width := 2.0 * RoundGrid.RADIUS * sin(PI / RoundGrid.SIDES)
	var tall := ceiling - floor_top
	for side in RoundGrid.SIDES:
		var angle := RoundGrid.side_angle(side)
		var turn := Basis(Vector3.UP, -angle)
		# Gruesa hacia afuera: el que se resbala adentro cuando la meca arranca llega rápido y una fina la atraviesa.
		var mid := RoundGrid.at(apothem + 0.4, angle, (floor_top + ceiling) * 0.5)
		Clay.shape_box(interior, Vector3(width + 0.5, tall, 0.8), mid, turn)
		var reach := int((RoundGrid.GLASS_SIDES - 1) / 2.0)
		var front := side <= reach or side >= RoundGrid.SIDES - reach
		if not front:
			var panel := Clay.box(self, Vector3(width, tall, 0.06), RoundGrid.at(apothem + 0.03, angle, mid.y),
				METAL.lightened(0.08))
			panel.basis = turn


## LA TARIMA: la placa de arriba con el hueco del ascensor, el escalón de alrededor (a la mitad del alto) y, para la
## cápsula, una rampa del piso al borde de la tarima (los pies pisan el escalón).
func _deck(floor_top: float, hole: Vector2, hole_radius: float) -> void:
	var tall := RoundGrid.PLATFORM_TALL
	var deck := RoundGrid.polygon(RoundGrid.PLATFORM_R, PER_SIDE)
	var step := RoundGrid.polygon(RoundGrid.PLATFORM_R + RoundGrid.STEP, PER_SIDE)
	var gap := RoundGrid.circle(hole_radius, hole, PER_SIDE)
	add_child(_plate(deck, gap, floor_top, floor_top + tall, DECK))
	add_child(_plate(step, deck, floor_top, floor_top + tall * 0.5, DECK.darkened(0.08)))
	# Lo que se pisa arriba, y la rampa: del borde de afuera del escalón, en el piso, al de la tarima, arriba.
	_ring_shapes(deck, gap, floor_top, floor_top + tall)
	var foot := RoundGrid.polygon(RoundGrid.PLATFORM_R + RoundGrid.STEP + 0.15, PER_SIDE)
	for i in deck.size():
		var j := (i + 1) % deck.size()
		var points := PackedVector3Array([
			_v(deck[i], floor_top + tall), _v(deck[j], floor_top + tall), _v(deck[i], floor_top), _v(deck[j], floor_top),
			_v(foot[i], floor_top), _v(foot[j], floor_top)])
		_convex(points)


## LOS RECURSOS, en las paredes de atrás (sólo se ven): los kits en los dos lados de cada costado de atrás; en el de
## atrás de todo, las dos municiones y la batería al medio.
func _supplies(floor_top: float) -> void:
	var back := RoundGrid.SIDES / 2
	for offset in [-2, -1, 1, 2]:
		_on_wall(back + offset, 0.0, Vector2(0.6, 0.6), floor_top + 0.6, KIT)
	_on_wall(back, -0.55, Vector2(0.6, 0.6), floor_top + 1.2, AMMO)
	_on_wall(back, 0.55, Vector2(0.6, 0.6), floor_top + 1.2, AMMO)
	_on_wall(back, 0.0, Vector2(0.4, 0.5), floor_top + 0.6, BATTERY)


func _on_wall(side: int, shift: float, size: Vector2, y: float, color: Color) -> void:
	var angle := RoundGrid.side_angle(side)
	var along := Vector3(cos(angle), 0, sin(angle))
	var part := Clay.box(self, Vector3(size.x, size.y, 0.12),
		RoundGrid.at(RoundGrid.APOTHEM - 0.04, angle, y + size.y * 0.5) + along * shift, color)
	part.basis = Basis(Vector3.UP, -angle)


## LAS SILLAS, las de verdad, en el orden de `POSTS`: las tres de adelante, mirando hacia afuera, y la del movimiento.
func _round_seats() -> void:
	var places := RoundGrid.front_seats()
	places.append([RoundGrid.top_seat(), 0.0])
	for index in places.size():
		var chair := (load(SEAT_SCENE) as PackedScene).instantiate() as SeatInteractable
		chair.name = "Asiento %s" % POSTS[index]
		chair.position = places[index][0]
		chair.rotation.y = places[index][1]
		chair.eye_height = CabinGrid.EYE_HEIGHT
		add_child(chair)
		chairs.append(chair)


## EL MARCO: el volumen de la cabina (de la losa del piso al techo) y el del hueco del ascensor, por el disco y hasta
## su parada de abajo.
func build_frame() -> void:
	frame = MotionFrame.new()
	mech.add_child(frame)
	frame.floor_height = RoundGrid.floor_top()
	var outer := RoundGrid.OUTER
	var bottom := RoundGrid.floor_top() - RoundGrid.SLAB
	frame.add_volume(AABB(Vector3(-outer, bottom, -outer), Vector3(outer * 2.0, RoundGrid.HALF_HEIGHT - bottom, outer * 2.0)))
	var reach := RoundGrid.LIFT_R + 0.3
	var low := PelvisLift.lowered(RoundGrid.HALF_HEIGHT) + 0.55
	frame.add_volume(AABB(Vector3(-reach, low, RoundGrid.LIFT_BACK - reach), Vector3(reach * 2.0, bottom + 0.3 - low,
		reach * 2.0)))
	interior.collision_layer = 1
	frame.cast_shadow(self)
	interior.collision_layer = 0
	interior.collision_mask = 0
	for body in find_children("*", "RigidBody3D", true, false):
		mech.add_collision_exception_with(body as RigidBody3D)


## LA U: al piso, entre la silla del medio de adelante y el escalón de la tarima, mirando al frente.
func board() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if mech.keys.driving:
		SandboxPossession.of(get_tree()).release()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	var front := -(RoundGrid.APOTHEM - RoundGrid.SEAT_IN)
	var step := -(RoundGrid.PLATFORM_R + RoundGrid.STEP)
	var spot := Vector3(0.0, RoundGrid.floor_top() + 0.05, (front + step) * 0.5 + 0.2)
	player.place_at(mech.global_transform * spot, mech.yaw())


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────


## Una banda de cilindro de `r0` a `r1`, de los ángulos `a0` a `a1` (0 al frente, positivo a la derecha), de `y0` a `y1`.
func _band(r0: float, r1: float, a0: float, a1: float, y0: float, y1: float, color: Color) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := maxi(int((a1 - a0) / TAU * 96.0), 2)
	for k in steps:
		var b0 := a0 + (a1 - a0) * k / steps
		var b1 := a0 + (a1 - a0) * (k + 1) / steps
		_quad(tool, RoundGrid.at(r0, b0, y0), RoundGrid.at(r0, b1, y0), RoundGrid.at(r0, b1, y1), RoundGrid.at(r0, b0, y1),
			SMOOTH_IN)
		_quad(tool, RoundGrid.at(r1, b0, y0), RoundGrid.at(r1, b1, y0), RoundGrid.at(r1, b1, y1), RoundGrid.at(r1, b0, y1),
			SMOOTH_OUT)
		_quad(tool, RoundGrid.at(r0, b0, y1), RoundGrid.at(r0, b1, y1), RoundGrid.at(r1, b1, y1), RoundGrid.at(r1, b0, y1),
			FLAT)
		_quad(tool, RoundGrid.at(r0, b0, y0), RoundGrid.at(r1, b0, y0), RoundGrid.at(r1, b1, y0), RoundGrid.at(r0, b1, y0),
			FLAT)
	for b: float in [a0, a1]:
		_quad(tool, RoundGrid.at(r0, b, y0), RoundGrid.at(r1, b, y0), RoundGrid.at(r1, b, y1), RoundGrid.at(r0, b, y1), FLAT)
	return _mesh(tool, color)
