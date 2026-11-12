class_name MechCabin
extends Node3D

## LA CABINA DE LA MECA: lo que se ve de la caja y por donde se camina. Este nodo es EL DIBUJO (va con la caja).
##   · TRES PISOS de paredes de verdad, no una caja pintada (el usuario, 12/11/2026): las losas, los costados, al frente
##     el antepecho, el HUECO con su vidrio y sus parantes y el dintel, atrás la pared con el HUECO de la puerta, y los
##     asientos con su tablero. Por los huecos se ve del otro lado. Las medidas, de la grilla (CabinGrid).
##   · EL AFUERA (MechExterior): la pasarela de planta baja y la escalera de atrás.
##   · EL ASCENSOR DE LA PELVIS (PelvisLift): por donde se sube desde el suelo, con la meca agachada.
##   · EL MARCO (MotionFrame): ADENTRO Y AFUERA SE CAMINA. Las losas, las paredes, la pasarela y la escalera tienen sus
##     formas de choque en `interior`, un cuerpo que NO choca con nada: es de donde el marco copia su SOMBRA. El que
##     entra a alguno de sus volúmenes pasa a ir en el marco, que lo lleva con la meca, y choca sólo con esa sombra. Y
##     LA CAJA DE AFUERA, que es maciza y es la que choca con el mundo, deja de chocar con él (`ride`).

## LAS MEDIDAS SALEN DE LA GRILLA (CabinGrid, 13/11/2026): todo es celdas enteras, y cambiar un número de la grilla
## cambia los pisos, las paredes, los huecos y los asientos.
const FLOORS := CabinGrid.FLOORS
const FLOOR_HEIGHT := CabinGrid.FLOOR_HEIGHT
const SLAB := CabinGrid.SLAB
const WALL := CabinGrid.WALL
const SILL := CabinGrid.SILL_CELLS * CabinGrid.CELL
const GLASS := CabinGrid.GLASS_CELLS * CabinGrid.CELL
const DOOR := Vector2(CabinGrid.DOOR_CELLS) * CabinGrid.CELL

var mech: Mech = null
var frame: MotionFrame = null
var lift: PelvisLift = null
var interior: StaticBody3D = null

var _riders := {}


## La losa del piso `index` (0 el de abajo), su medio, en el espacio de la caja: se pisa a media losa más arriba.
static func floor_y(index: int) -> float:
	return CabinGrid.slab_y(index)


## El asiento desde el que se mira en primera persona: el de la izquierda del piso del medio.
static func seat() -> Vector3:
	return CabinGrid.seat(1, CabinGrid.SEATS[1][0])


func _ready() -> void:
	name = "Cabina"
	interior = StaticBody3D.new()
	interior.name = "Interior"
	interior.collision_layer = 0
	interior.collision_mask = 0
	add_child(interior)
	var size := CabinGrid.SIZE
	var metal := Clay.METAL
	var half := CabinGrid.HALF - WALL * 0.5
	for index in FLOORS + 1:
		var y := floor_y(index)
		if index == 0:
			# La losa de abajo, con el recorte redondo del ascensor y su baranda (ver PelvisLift).
			PelvisLift.build_floor(self, interior, y, SLAB, metal.darkened(0.12))
			continue
		_solid(Vector3(size, SLAB, size), Vector3(0, y, 0), metal.darkened(0.12))
	for index in FLOORS:
		var base := CabinGrid.ground(index)
		var wall_h := CabinGrid.clear_height(index)
		var mid := base + wall_h * 0.5
		var glass_mid := base + SILL + GLASS * 0.5
		var lintel := wall_h - SILL - GLASS
		for side: float in [-1.0, 1.0]:
			_solid(Vector3(WALL, wall_h, size - WALL * 2.0), Vector3(side * half, mid, 0), metal)
		# El frente: el antepecho, el dintel, UNA VENTANA POR MÓDULO y un parante en cada línea entre módulos.
		_solid(Vector3(size, SILL, WALL), Vector3(0, base + SILL * 0.5, -half), metal)
		_solid(Vector3(size, lintel, WALL), Vector3(0, base + wall_h - lintel * 0.5, -half), metal)
		# El vidrio no se atraviesa.
		Clay.shape_box(interior, Vector3(size, GLASS, WALL * 0.5), Vector3(0, glass_mid, -half))
		var post := CabinGrid.POST_CELLS * CabinGrid.CELL
		for line in range(1, CabinGrid.COLUMNS):
			Clay.box(self, Vector3(post, GLASS, WALL), Vector3(CabinGrid.column_x(line), glass_mid, -half), metal.darkened(0.2))
		Clay.box(self, Vector3(size - WALL * 2.0, GLASS, 0.04), Vector3(0, glass_mid, -half), Clay.GLASS)
		# Atrás: la pared a los costados y arriba del hueco de la puerta, en el medio.
		var beside := (size - DOOR.x) * 0.5
		for side: float in [-1.0, 1.0]:
			_solid(Vector3(beside, wall_h, WALL), Vector3(side * (DOOR.x + beside) * 0.5, mid, half), metal)
		_solid(Vector3(DOOR.x, wall_h - DOOR.y, WALL), Vector3(0, base + DOOR.y + (wall_h - DOOR.y) * 0.5, half), metal)
		_seats(index, metal)
	MechExterior.build(self, interior)
	lift = PelvisLift.new()
	lift.solid = interior
	add_child(lift)


## LOS ASIENTOS DEL PISO `index` (ver CabinGrid.SEATS) y, adelante de cada uno, su tablero: por ahora un bloque bajo
## hasta el antepecho, que no tapa el vidrio. Los tableros de verdad vienen después.
func _seats(index: int, metal: Color) -> void:
	if not CabinGrid.SEATS.has(index):
		return
	var cell := CabinGrid.CELL
	var depth := CabinGrid.CONSOLE_CELLS * cell
	for column: int in CabinGrid.SEATS[index]:
		var chair := CabinGrid.seat(index, column)
		Clay.box(self, Vector3(0.6, 0.5, 0.6), chair + Vector3(0, 0.25, 0), Clay.DARK)
		Clay.box(self, Vector3(0.6, 0.7, 0.12), chair + Vector3(0, 0.85, 0.3), Clay.DARK)
		var wide := CabinGrid.MODULE - 8 * cell
		_solid(Vector3(wide, SILL, depth), Vector3(chair.x, chair.y + SILL * 0.5, -CabinGrid.INNER + depth * 0.5),
			metal.darkened(0.25))


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
	frame.add_volume(AABB(Vector3.ONE * -CabinGrid.HALF, Vector3.ONE * CabinGrid.SIZE))
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
	player.place_at(mech.global_transform * (Vector3(0.0, CabinGrid.ground(1) + 0.05, CabinGrid.row_z(2))),
		mech.yaw())
