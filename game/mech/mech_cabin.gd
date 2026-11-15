class_name MechCabin
extends Node3D

## LA CABINA DE LA MECA: lo que se ve de la caja y por donde se camina. Este nodo es EL DIBUJO (va con la caja). Las
## medidas salen de la trama (CabinGrid), que se cambia jugando (el F2).
##   · UN SOLO PISO, con el recorte del ascensor en el medio (PelvisLift), y el techo.
##   · ADELANTE, EL VIDRIO, SIN MARCOS (`_glass`): el frente y los costados (hasta CabinGrid.SIDE_GLASS), de piso a
##     techo, la arista de arriba del frente cortada a 45° y el techo hasta CabinGrid.ROOF_GLASS, también de vidrio.
##     Paños planos que se tocan justo en las aristas (el usuario,
##     14/11/2026: «toda esa zona de cristal… el suelo no… en la esquina superior delantera, tenga un chamfer»). Lo
##     demás, de metal: la pared de atrás, los costados y el techo desde donde termina el vidrio.
##   · ADELANTE, EL TABLERO CORRIDO con sus tres puestos (un brazo a cada lado y la espalda al medio).
##   · ATRÁS, LA TARIMA de pared a pared, con el movimiento arriba al medio, y una escalera recta contra cada costado. En
##     el frente de la tarima, de cara al ascensor, los cuatro kits y la batería; arriba, en la pared de atrás, la
##     munición (por ahora, sólo se ven: los huecos de verdad vienen con los recursos).
##   · EL MARCO (MotionFrame): adentro se camina. El piso, las paredes, el vidrio, el tablero y la tarima tienen sus
##     formas de choque en `interior`, un cuerpo que NO choca con nada: es de donde el marco copia su SOMBRA. El que
##     entra a la caja pasa a ir en el marco, que lo lleva con la meca, y choca sólo con esa sombra. Y LA CAJA DE AFUERA,
##     que es maciza y es la que choca con el mundo, deja de chocar con él (`ride`).
## *Hasta el 14/11/2026 era de varios pisos, con una caja de vidrio que sobresalía, puertas atrás y una pasarela y
## escaleras por afuera (MechExterior) o una escalera adentro (MechInsideStairs), a elegir. Se sacó todo.*

const SLAB := CabinGrid.SLAB
const WALL := CabinGrid.WALL
const KIT := Color(0.78, 0.27, 0.27)
const BATTERY := Color(0.93, 0.75, 0.16)
const AMMO := Color(0.47, 0.53, 0.32)
const SEAT_SCENE := "res://game/interactables/activatable/working_seat.tscn"
const DUMMY_SCENE := "res://game/character/player.tscn"
const DUMMY_BODIES: Array[EntityArchetype.Archetype] = [EntityArchetype.Archetype.fat_athletic,
	EntityArchetype.Archetype.lanky, EntityArchetype.Archetype.buff, EntityArchetype.Archetype.fat_man]
## Los puestos, en el orden de las sillas (`chairs`): los tres de adelante, de izquierda a derecha, y el de arriba.
const POSTS := ["brazo izquierdo", "espalda", "brazo derecho", "movimiento"]

var mech: Mech = null
var frame: MotionFrame = null
var lift: PelvisLift = null
var interior: StaticBody3D = null
## Las sillas (ver `_seats`, en el orden de `POSTS`) y los maniquíes sentados en ellas (ver `seat_dummies`).
var chairs: Array[SeatInteractable] = []
var dummies: Array[Node3D] = []

var _riders := {}


## La silla desde la que se mira en primera persona al poseer la meca: la del movimiento, arriba.
static func seat() -> Vector3:
	return CabinGrid.top_seat()


func _ready() -> void:
	name = "Cabina"
	interior = StaticBody3D.new()
	interior.name = "Interior"
	interior.collision_layer = 0
	interior.collision_mask = 0
	add_child(interior)
	var metal := Clay.METAL
	var floor_top := CabinGrid.floor_top()
	var ceiling := CabinGrid.ceiling()
	var half := CabinGrid.HALF
	var trama := CabinGrid.TRAMA
	var cut := CabinGrid.CHAMFER * trama
	# Hasta dónde llega el vidrio de los costados y el del techo (el del techo, por lo menos hasta el corte).
	var side_to := CabinGrid.line(CabinGrid.SIDE_GLASS)
	var roof_to := maxf(CabinGrid.line(CabinGrid.ROOF_GLASS), -half + cut)
	# El piso, con el recorte del ascensor; el techo de metal, de donde termina el vidrio hasta atrás.
	PelvisLift.build_floor(self, interior, floor_top - SLAB * 0.5, SLAB, metal.darkened(0.12))
	_solid(Vector3(CabinGrid.SIZE, SLAB, half - roof_to), Vector3(0, ceiling + SLAB * 0.5, (roof_to + half) * 0.5), metal)
	# De metal: la pared de atrás y los costados de donde termina el vidrio hasta ella.
	var mid := (floor_top + ceiling) * 0.5
	_solid(Vector3(CabinGrid.SIZE, CabinGrid.CLEAR, WALL), Vector3(0, mid, half - WALL * 0.5), metal)
	var back := half - WALL
	if back - side_to > 0.01:
		for side: float in [-1.0, 1.0]:
			_solid(Vector3(WALL, CabinGrid.CLEAR, back - side_to), Vector3(side * (half - WALL * 0.5), mid, (side_to + back) * 0.5),
				metal)
	_glass(cut, side_to, roof_to)
	_desk()
	_platform()
	_seats()
	lift = PelvisLift.new()
	lift.solid = interior
	add_child(lift)


## EL VIDRIO, EN PAÑOS EXACTOS Y SIN MARCOS: el frente hasta el corte, el corte a 45° de arista a arista, el techo
## hasta `roof_to` y cada costado hasta `side_to`, con su esquina cortada igual. Todos van en la cara de afuera de la
## caja y se tocan justo en las aristas.
func _glass(cut: float, side_to: float, roof_to: float) -> void:
	var half := CabinGrid.HALF
	var y0 := CabinGrid.floor_top()
	var y1 := CabinGrid.HALF_HEIGHT
	var yc := y1 - cut
	var front := -half + 0.02
	var side_x := half - 0.02
	_pane([Vector3(-side_x, y0, front), Vector3(side_x, y0, front), Vector3(side_x, yc, front), Vector3(-side_x, yc, front)])
	if cut > 0.0:
		_pane([Vector3(-side_x, yc, front), Vector3(side_x, yc, front), Vector3(side_x, y1, front + cut),
			Vector3(-side_x, y1, front + cut)])
		Clay.shape_box(interior, Vector3(CabinGrid.SIZE, 0.1, cut * sqrt(2.0)), Vector3(0, yc + cut * 0.5, front + cut * 0.5),
			Basis(Vector3.RIGHT, PI * 0.25))
	Clay.shape_box(interior, Vector3(CabinGrid.SIZE, yc - y0, 0.1), Vector3(0, (y0 + yc) * 0.5, front - 0.03))
	var roof_from := front + cut
	if roof_to - roof_from > 0.01:
		_pane([Vector3(-side_x, y1, roof_from), Vector3(side_x, y1, roof_from), Vector3(side_x, y1, roof_to),
			Vector3(-side_x, y1, roof_to)])
		Clay.shape_box(interior, Vector3(CabinGrid.SIZE, 0.1, roof_to - roof_from), Vector3(0, y1 - 0.05, (roof_from + roof_to) * 0.5))
	for side: float in [-1.0, 1.0]:
		var x := side * side_x
		_pane([Vector3(x, y0, front), Vector3(x, y0, side_to), Vector3(x, y1, side_to), Vector3(x, y1, front + cut),
			Vector3(x, yc, front)])
		Clay.shape_box(interior, Vector3(0.1, y1 - y0, side_to - front), Vector3(side * (half - 0.02), (y0 + y1) * 0.5,
			(front + side_to) * 0.5))


## Un paño de vidrio plano, con sus esquinas en orden (un abanico desde la primera).
func _pane(corners: Array) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a: Vector3 = corners[0]
	var normal := ((corners[1] as Vector3) - a).cross((corners[2] as Vector3) - a).normalized()
	for i in range(1, corners.size() - 1):
		for point: Vector3 in [a, corners[i], corners[i + 1]]:
			tool.set_normal(normal)
			tool.add_vertex(point)
	var pane := MeshInstance3D.new()
	pane.name = "Vidrio"
	pane.mesh = tool.commit()
	var paint := StandardMaterial3D.new()
	# Su color y cuánto se ve, de la forma (el F2).
	paint.albedo_color = CabinGrid.GLASS_COLOR
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.roughness = 0.2
	pane.material_override = paint
	add_child(pane)


## EL TABLERO CORRIDO DE ADELANTE, de pared a pared, con una raya donde termina cada puesto.
func _desk() -> void:
	var trama := CabinGrid.TRAMA
	var depth := CabinGrid.DESK_ROWS * trama
	var floor_top := CabinGrid.floor_top()
	_solid(Vector3(CabinGrid.INNER * 2.0, CabinGrid.DESK_HEIGHT, depth),
		Vector3(0, floor_top + CabinGrid.DESK_HEIGHT * 0.5, CabinGrid.line(0) + depth * 0.5), Clay.DARK)
	var margin := (CabinGrid.ACROSS - CabinGrid.POST_CELLS * 3) * 0.5
	for post in [1, 2]:
		Clay.box(self, Vector3(0.04, CabinGrid.DESK_HEIGHT + 0.02, depth),
			Vector3(CabinGrid.line(margin + CabinGrid.POST_CELLS * post), floor_top + CabinGrid.DESK_HEIGHT * 0.5 + 0.01,
			CabinGrid.line(0) + depth * 0.5), Clay.METAL)


## LA TARIMA DE ATRÁS, de pared a pared, y una escalera recta contra cada costado (con `Stairs`, la regla de toda
## escalera: escalones para los pies y una rampa para la cápsula). En su frente, de cara al ascensor, los cuatro kits y
## la batería, parejos entre las dos escaleras; arriba, en la pared de atrás, la munición (sólo sobresale el cubo).
func _platform() -> void:
	var trama := CabinGrid.TRAMA
	var floor_top := CabinGrid.floor_top()
	var tall := CabinGrid.PLATFORM_HEIGHT
	var front := CabinGrid.platform_front()
	_solid(Vector3(CabinGrid.INNER * 2.0, tall, CabinGrid.INNER - front),
		Vector3(0, floor_top + tall * 0.5, (front + CabinGrid.INNER) * 0.5), Clay.METAL.darkened(0.05))
	var width := CabinGrid.STAIR_CELLS * trama
	var run := Stairs.run_for(tall)
	for side: float in [-1.0, 1.0]:
		Stairs.flight(self, Vector3(side * (CabinGrid.INNER - width * 0.5), floor_top, front - run), Vector3.BACK, tall, width,
			Clay.METAL.lightened(0.15))
	# Los kits y la batería, cuadrados, en celdas: de 1,2 celdas de trama (61 cm), o menos si no entran a lo ancho o a lo
	# alto de la tarima.
	var free := (CabinGrid.INNER - width) * 2.0
	var kit := minf(1.2 * trama, minf(free / 5.0 * 0.85, tall - 2.0 * CabinGrid.CELL))
	for index in 5:
		var x := -free * 0.5 + free * (index + 0.5) / 5.0
		Clay.box(self, Vector3(kit, kit, 0.06), Vector3(x, floor_top + CabinGrid.CELL + kit * 0.5, front - 0.03),
			BATTERY if index == 2 else KIT)
	# La munición: un cubo de 1,6 celdas de trama (82 cm) que sobresale de la pared de atrás, con su tapa de adentro.
	var ammo := 1.6 * trama
	for side: float in [-1.0, 1.0]:
		var at := Vector3(side * 2.5 * trama, floor_top + tall + CabinGrid.CELL * 0.5 + ammo * 0.5, CabinGrid.HALF + ammo * 0.375)
		Clay.box(self, Vector3(ammo, ammo, ammo * 0.75), at, Clay.METAL)
		Clay.box(self, Vector3(ammo * 0.75, ammo * 0.75, 0.06), at + Vector3(0, 0, -ammo * 0.775), AMMO)


## LAS SILLAS (las de verdad, las de las consolas, `SEAT_SCENE`), mirando al frente: las tres de adelante y la de arriba,
## en el orden de `POSTS`.
func _seats() -> void:
	var places := CabinGrid.front_seats()
	places.append(CabinGrid.top_seat())
	for index in places.size():
		var chair := (load(SEAT_SCENE) as PackedScene).instantiate() as SeatInteractable
		chair.name = "Asiento %s" % POSTS[index]
		chair.position = places[index]
		# La altura de los ojos que busca (ver CabinGrid.EYE_HEIGHT): cada uno se nivela a ella.
		chair.eye_height = CabinGrid.EYE_HEIGHT
		add_child(chair)
		chairs.append(chair)


## UN MANIQUÍ SENTADO EN CADA SILLA, para ver la escala de adentro (el usuario, 13/11/2026: «le pondría los asientos
## reales y dejaría sentados… unos dummies. Así veo cómo se siente la escala de adentro»). Personajes de la calle, de
## varios cuerpos, que van al lado de la meca en el árbol y los lleva su silla. Los sienta la meca de brazos, no la de
## práctica.
func seat_dummies() -> void:
	var holder := mech.get_parent() as Node3D
	if holder == null:
		return
	# EL PRIMER PANEL JUGABLE (ver SeatPanels, docs/technical/paneles.md): en la primera silla de la derecha, la del
	# brazo derecho. Esa silla queda sin maniquí, para sentarse uno con E.
	SeatPanels.attach(self)
	var free_chair: SeatInteractable = null
	for chair_found in chairs:
		if chair_found.position.x > 0.0:
			free_chair = chair_found
			break
	for i in chairs.size():
		if chairs[i] == free_chair:
			continue
		var dummy := (load(DUMMY_SCENE) as PackedScene).instantiate() as BoneInstantiator
		dummy.kind = CharacterKind.npc()
		dummy.master_seed = EntityInstantiation.debug_seed(DUMMY_BODIES[i % DUMMY_BODIES.size()], i)
		holder.add_child(dummy)
		dummies.append(dummy)
		# Aparece adentro de la caja maciza: que no la empuje antes de que el marco lo lleve (ver `ride`).
		mech.add_collision_exception_with(dummy.char_rigidbody)
		dummy.place_at(chairs[i].global_position + chairs[i].global_basis.z * 0.8, chairs[i].heading())
		dummy.intent.seat = chairs[i]


## Saca a los maniquíes (van al lado de la meca en el árbol, no adentro): para cuando la meca se cambia por otra.
func free_dummies() -> void:
	for dummy in dummies:
		if is_instance_valid(dummy):
			dummy.queue_free()
	dummies.clear()


## Una pieza de la cabina que se ve y que, adentro, se choca.
func _solid(size: Vector3, at: Vector3, color: Color) -> void:
	Clay.box(self, size, at, color)
	Clay.shape_box(interior, size, at)


## EL MARCO, con sus volúmenes (la caja y el hueco del ascensor), y su sombra: la copia de las formas de `interior` y de
## los escalones y las rampas de las escaleras. El marco copia las de un cuerpo de la capa 1; `interior` lo es sólo
## mientras se copia. Se llama cuando la meca ya tiene todo armado.
func build_frame() -> void:
	frame = MotionFrame.new()
	mech.add_child(frame)
	frame.floor_height = CabinGrid.floor_top()
	frame.add_volume(AABB(-CabinGrid.box() * 0.5, CabinGrid.box()))
	frame.add_volume(PelvisLift.shaft())
	interior.collision_layer = 1
	frame.cast_shadow(self)
	interior.collision_layer = 0
	interior.collision_mask = 0
	# LAS ESCALERAS (ver Stairs): sus escalones y sus rampas ya están copiados en la sombra; los de verdad, que van con la
	# meca, dejan de chocar, como `interior`.
	for body in find_children("*", "StaticBody3D", true, false):
		if body != interior:
			(body as StaticBody3D).collision_layer = 0
	# LAS SILLAS: su cuerpo (quieto, ver SeatInteractable) también quedó copiado; la caja maciza, que las tiene adentro,
	# no choca con él (la empujaba y la volteaba).
	for body in find_children("*", "RigidBody3D", true, false):
		mech.add_collision_exception_with(body as RigidBody3D)


## LA CAJA DE AFUERA NO CHOCA CON LOS QUE VAN ADENTRO: ellos ya dejaron de mirar al mundo (ver MotionFrame.join), pero
## la caja los seguía viendo. Se mira quién va en el marco en cada paso.
func ride() -> void:
	var inside := {}
	for body: Variant in frame._members.keys():
		if is_instance_valid(body) and body is PhysicsBody3D:
			inside[body] = true
			if not _riders.has(body):
				mech.add_collision_exception_with(body as PhysicsBody3D)
	for body: Variant in _riders.keys():
		if not inside.has(body) and is_instance_valid(body):
			mech.remove_collision_exception_with(body as PhysicsBody3D)
	_riders = inside


## SUBE AL JUGADOR (la U del sandbox): al piso, entre las sillas de adelante y el ascensor, mirando al frente.
func board() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if mech.keys.driving:
		SandboxPossession.of(get_tree()).release()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	var spot := Vector3(0.0, CabinGrid.floor_top() + 0.05, (CabinGrid.front_seats()[0].z - PelvisLift.hole()) * 0.5)
	player.place_at(mech.global_transform * spot, mech.yaw())
