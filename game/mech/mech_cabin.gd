class_name MechCabin
extends Node3D

## LA CABINA DE LA MECA: lo que se ve de la caja y por donde se camina. Este nodo es EL DIBUJO (va con la caja).
##   · LOS PISOS de paredes de verdad, no una caja pintada (el usuario, 12/11/2026): las losas, los costados, atrás la
##     pared con el HUECO de la puerta, y los asientos. Las medidas, de la grilla (CabinGrid), que se cambia jugando.
##   · AL FRENTE, UNA CAJA DE VIDRIO QUE SOBRESALE (`_glass`): vidrio al frente, a los costados, arriba y abajo, sin
##     parantes ni marcos; todas las losas llegan en metal hasta la cara de la caja y siguen en vidrio. El de más arriba
##     ve para arriba y el de más abajo, para abajo (el usuario, 13/11/2026: «que también se doble en la parte de arriba y de abajo… así
##     efectivamente logramos una parte más sobresalida»).
##   · LA ESTRUCTURA (CabinGrid.STRUCTURE, el F2): AFUERA, la pasarela de planta baja, la escalera de atrás y una
##     puerta atrás en cada piso (MechExterior); o ADENTRO, sin nada afuera ni puertas, la escalera contra la pared de
##     atrás y un hueco en cada losa por donde se sube (MechInsideStairs); o EL ASCENSOR ENTRE PISOS, sin nada afuera,
##     ni puertas, ni escalera: el ascensor sube hasta el último piso y cada losa tiene su recorte y su baranda.
##   · EL ASCENSOR DE LA PELVIS (PelvisLift): por donde se sube desde el suelo, con la meca agachada.
##   · EL MARCO (MotionFrame): ADENTRO Y AFUERA SE CAMINA. Las losas, las paredes, la pasarela y la escalera tienen sus
##     formas de choque en `interior`, un cuerpo que NO choca con nada: es de donde el marco copia su SOMBRA. El que
##     entra a alguno de sus volúmenes pasa a ir en el marco, que lo lleva con la meca, y choca sólo con esa sombra. Y
##     LA CAJA DE AFUERA, que es maciza y es la que choca con el mundo, deja de chocar con él (`ride`).

## LAS MEDIDAS SALEN DE LA GRILLA (CabinGrid, 13/11/2026): todo es celdas enteras, y cambiar un número de la grilla
## cambia los pisos, las paredes, los huecos y los asientos.
const SLAB := CabinGrid.SLAB
const WALL := CabinGrid.WALL
const DOOR := Vector2(CabinGrid.DOOR_CELLS) * CabinGrid.CELL
## El vidrio, bien transparente (el usuario: «haría más transparente el vidrio»).
const GLASS := Color(0.6, 0.8, 0.92, 0.12)
const SEAT_SCENE := "res://game/interactables/activatable/working_seat.tscn"
const DUMMY_SCENE := "res://game/character/player.tscn"
const DUMMY_BODIES: Array[EntityArchetype.Archetype] = [EntityArchetype.Archetype.fat_athletic,
	EntityArchetype.Archetype.lanky, EntityArchetype.Archetype.buff, EntityArchetype.Archetype.fat_man]

var mech: Mech = null
var frame: MotionFrame = null
var lift: PelvisLift = null
var interior: StaticBody3D = null
## Las sillas (ver `_seats`) y los maniquíes sentados en ellas (ver `seat_dummies`).
var chairs: Array[SeatInteractable] = []
var dummies: Array[Node3D] = []

var _riders := {}


## La losa del piso `index` (0 el de abajo), su medio, en el espacio de la caja: se pisa a media losa más arriba.
static func floor_y(index: int) -> float:
	return CabinGrid.slab_y(index)


## El asiento desde el que se mira en primera persona: el de la izquierda del primer piso con asientos.
static func seat() -> Vector3:
	return CabinGrid.seat(CabinGrid.seat_floors()[0], -1.0)


func _ready() -> void:
	name = "Cabina"
	interior = StaticBody3D.new()
	interior.name = "Interior"
	interior.collision_layer = 0
	interior.collision_mask = 0
	add_child(interior)
	var size := CabinGrid.SIZE
	var out := CabinGrid.GLASS_OUT
	var metal := Clay.METAL
	var half := CabinGrid.HALF - WALL * 0.5
	# Sin nada afuera (la escalera adentro, o el ascensor entre pisos): sin puertas atrás.
	var inside := CabinGrid.STRUCTURE != CabinGrid.Structure.OUTSIDE
	var stairs := CabinGrid.STRUCTURE == CabinGrid.Structure.INSIDE
	var lift_floors := CabinGrid.STRUCTURE == CabinGrid.Structure.LIFT
	for index in CabinGrid.FLOORS + 1:
		var y := floor_y(index)
		if index == 0 or (lift_floors and index < CabinGrid.FLOORS):
			# La losa de abajo (con el ascensor entre pisos, todas menos el techo), con el recorte redondo del ascensor y
			# su baranda (ver PelvisLift).
			PelvisLift.build_floor(self, interior, y, SLAB, metal.darkened(0.12))
		elif stairs:
			# Con la escalera adentro, el hueco por donde se sube (ver MechInsideStairs).
			MechInsideStairs.slab(self, interior, index, metal.darkened(0.12))
		else:
			_solid(Vector3(size, SLAB, size), Vector3(0, y, 0), metal.darkened(0.12))
		# ADELANTE, EN LA CAJA DE VIDRIO, TODAS LAS LOSAS IGUALES: el metal llega hasta la cara de la caja y lo que sigue
		# hasta el vidrio es vidrio que se pisa (el usuario, 13/11/2026: «quiero que los tres estén alineados»).
		if out > 0.0:
			var ahead := Vector3(size, SLAB, out)
			var at := Vector3(0, y, -CabinGrid.HALF - out * 0.5)
			Clay.box(self, ahead, at, GLASS)
			Clay.shape_box(interior, ahead, at)
	for index in CabinGrid.FLOORS:
		var base := CabinGrid.ground(index)
		var wall_h := CabinGrid.clear_height(index)
		var mid := base + wall_h * 0.5
		# Los costados llegan hasta el frente de la caja: de ahí en adelante, el vidrio.
		for side: float in [-1.0, 1.0]:
			_solid(Vector3(WALL, wall_h, size - WALL), Vector3(side * half, mid, -WALL * 0.5), metal)
		# Atrás: sin nada afuera, la pared entera; si no, a los costados y arriba del hueco de la puerta.
		if inside:
			_solid(Vector3(size, wall_h, WALL), Vector3(0, mid, half), metal)
			_seats(index)
			continue
		var beside := (size - DOOR.x) * 0.5
		for side: float in [-1.0, 1.0]:
			_solid(Vector3(beside, wall_h, WALL), Vector3(side * (DOOR.x + beside) * 0.5, mid, half), metal)
		# La puerta, no más alta que el piso (con pisos bajos, llega hasta el techo).
		var door_h := minf(DOOR.y, wall_h)
		if wall_h - door_h > 0.01:
			_solid(Vector3(DOOR.x, wall_h - door_h, WALL), Vector3(0, base + door_h + (wall_h - door_h) * 0.5, half), metal)
		_seats(index)
	_glass(size, out)
	if stairs:
		MechInsideStairs.build(self, interior)
	elif not inside:
		MechExterior.build(self, interior)
	lift = PelvisLift.new()
	lift.solid = interior
	add_child(lift)


## LA CAJA DE VIDRIO DEL FRENTE, de `out` de fondo (sin fondo, el vidrio plano en la cara de la caja): el frente y los
## dos costados, de punta a punta, con formas que no dejan atravesarlos. Sin marcos (el usuario, 13/11/2026: «esos
## marcos se los sacaría»). El vidrio de arriba y de abajo es la punta de las losas (ver `_ready`).
func _glass(size: float, out: float) -> void:
	var height := CabinGrid.HEIGHT
	var front := -CabinGrid.HALF - out + 0.02 if out > 0.0 else -CabinGrid.HALF + WALL * 0.5
	Clay.box(self, Vector3(size, height, 0.04), Vector3(0, 0, front), GLASS)
	Clay.shape_box(interior, Vector3(size, height, 0.1), Vector3(0, 0, front - 0.03))
	if out <= 0.0:
		return
	for side: float in [-1.0, 1.0]:
		var x := side * (CabinGrid.HALF - 0.02)
		Clay.box(self, Vector3(0.04, height, out), Vector3(x, 0, -CabinGrid.HALF - out * 0.5), GLASS)
		Clay.shape_box(interior, Vector3(0.1, height, out), Vector3(x, 0, -CabinGrid.HALF - out * 0.5))


## LOS ASIENTOS DEL PISO `index` (ver CabinGrid.seat_floors): LAS SILLAS DE VERDAD, las de las consolas (`SEAT_SCENE`),
## mirando al frente. Sin tablero adelante: el bloque bajo que había tapaba la vista para abajo (el usuario,
## 13/11/2026). Los controles vienen después.
func _seats(index: int) -> void:
	if not CabinGrid.seat_floors().has(index):
		return
	for side: float in [-1.0, 1.0]:
		var chair := (load(SEAT_SCENE) as PackedScene).instantiate() as SeatInteractable
		chair.name = "Asiento %d %s" % [index, "izquierdo" if side < 0.0 else "derecho"]
		chair.position = CabinGrid.seat(index, side)
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


## EL MARCO, con sus volúmenes (la caja, el afuera y el hueco del ascensor), y su sombra: la copia de las formas de
## `interior` y de los escalones y la rampa de la escalera. El marco copia las de un cuerpo de la capa 1; `interior` lo
## es sólo mientras se copia. Se llama cuando la meca ya tiene todo armado.
func build_frame() -> void:
	frame = MotionFrame.new()
	mech.add_child(frame)
	frame.floor_height = CabinGrid.ground(0)
	var out := CabinGrid.GLASS_OUT
	frame.add_volume(AABB(Vector3(-CabinGrid.HALF, -CabinGrid.HALF_HEIGHT, -CabinGrid.HALF - out),
		Vector3(CabinGrid.SIZE, CabinGrid.HEIGHT, CabinGrid.SIZE + out)))
	if CabinGrid.STRUCTURE == CabinGrid.Structure.OUTSIDE:
		frame.add_volume(MechExterior.bounds())
	frame.add_volume(PelvisLift.shaft())
	interior.collision_layer = 1
	frame.cast_shadow(self)
	interior.collision_layer = 0
	interior.collision_mask = 0
	# LA ESCALERA DE ATRÁS (ver MechExterior, Stairs): sus escalones y su rampa ya están copiados en la sombra; los de
	# verdad, que van con la meca, dejan de chocar, como `interior`.
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


## SUBE AL JUGADOR (la U del sandbox): al piso del medio, detrás del asiento, mirando al frente.
func board() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if mech.keys.driving:
		SandboxPossession.of(get_tree()).release()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	player.place_at(mech.global_transform * (Vector3(0.0, CabinGrid.ground(mini(1, CabinGrid.FLOORS - 1)) + 0.05, CabinGrid.row_z(2))),
		mech.yaw())
