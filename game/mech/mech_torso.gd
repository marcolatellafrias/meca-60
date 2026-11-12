class_name MechTorso
extends AnimatableBody3D

## EL TORSO DE LA MECA: una caja de tres pisos por dentro, cada piso un puesto (MechSeat), con una ventana grande al
## frente (−Z) y una puerta atrás que da a la ESCALERA DE INCENDIO de afuera: un balcón por piso y tramos de escalera
## entre ellos, en dos carriles para que un tramo no pase por encima del otro. Del piso de abajo al suelo baja un
## montacargas (MechLift), que no es parte de este cuerpo.
##
## Es un cuerpo animable: la meca lo mueve en cada paso de física (ver Mech) y el que camina adentro se mueve con él. El
## origen está abajo en el medio; las medidas son las constantes de acá.
##
##   piso 1 (abajo): Piernas · piso 2: Brazos (los hombros salen a los costados) · piso 3: Vigía (la cámara de afuera)

const WIDTH := 8.0
const DEPTH := 6.0
const FLOOR_HEIGHT := 3.3
const FLOORS := 3
const SLAB := 0.25
const WALL := 0.25
## La escalera de afuera, detrás de la pared de atrás: el balcón y los dos carriles de los tramos.
const DECK := 1.5
const LANE := 1.2
const RAIL := 1.05
const BAR := 0.06
## Dónde aparece el montacargas, en el balcón del piso de abajo: x de −4 a −2.
const LIFT_X := Vector2(-WIDTH * 0.5, -2.0)

var seats: Array[MechSeat] = []
## EL MARCO (ver MotionFrame, de character-parametric): el torso lleva a los que van adentro —parados, en la escalera,
## sentados—, como la nave de allá. Su volumen es el torso con la escalera de incendio de atrás.
var frame: MotionFrame = null


func _init() -> void:
	name = "Torso"
	sync_to_physics = true


func _ready() -> void:
	_build()
	frame = MotionFrame.new()
	add_child(frame)
	frame.floor_height = floor_y(0)
	var back := back_face() + DECK + LANE * 2.0 + 0.5
	frame.add_volume(AABB(Vector3(-WIDTH * 0.5 - 0.5, -0.5, -DEPTH * 0.5 - 0.5),
		Vector3(WIDTH + 1.0, top_y() + 2.5, back + DEPTH * 0.5 + 0.5)))
	frame.cast_shadow(self)


## La altura del piso `index` (0 el de abajo), en el espacio del torso.
static func floor_y(index: int) -> float:
	return SLAB + index * FLOOR_HEIGHT


## Arriba del techo, en el espacio del torso.
static func top_y() -> float:
	return FLOORS * FLOOR_HEIGHT + SLAB


## Dónde empieza el balcón (la cara de afuera de la pared de atrás), en z.
static func back_face() -> float:
	return DEPTH * 0.5 + WALL * 0.5


## El centro del montacargas en el balcón de abajo (x, z), en el espacio del torso.
static func lift_centre() -> Vector2:
	return Vector2((LIFT_X.x + LIFT_X.y) * 0.5, back_face() + DECK * 0.5)


func _build() -> void:
	var metal := Clay.METAL
	var half_w := WIDTH * 0.5
	var half_d := DEPTH * 0.5
	var doors := [1.0, 0.0, 0.0]
	for index in FLOORS + 1:
		# La losa del piso (y el techo del de abajo).
		var y := index * FLOOR_HEIGHT
		Clay.solid(self, Vector3(WIDTH, SLAB, DEPTH), Vector3(0, y + SLAB * 0.5, 0), metal.darkened(0.15))
	for index in FLOORS:
		var base := floor_y(index)
		var wall_h := FLOOR_HEIGHT - SLAB
		var mid := base + wall_h * 0.5
		# Los costados.
		for side: float in [-1.0, 1.0]:
			Clay.solid(self, Vector3(WALL, wall_h, DEPTH), Vector3(side * half_w, mid, 0), metal)
		# El frente: un antepecho, el vidrio y el dintel.
		var sill := 0.9
		var glass := 1.9
		Clay.solid(self, Vector3(WIDTH, sill, WALL), Vector3(0, base + sill * 0.5, -half_d), metal)
		Clay.shape_box(self, Vector3(WIDTH, glass, WALL), Vector3(0, base + sill + glass * 0.5, -half_d))
		Clay.box(self, Vector3(WIDTH - 0.6, glass, 0.05), Vector3(0, base + sill + glass * 0.5, -half_d), Clay.GLASS)
		for post_x: float in [-half_w + 0.15, half_w - 0.15]:
			Clay.box(self, Vector3(0.2, glass, WALL), Vector3(post_x, base + sill + glass * 0.5, -half_d), metal)
		var lintel := wall_h - sill - glass
		Clay.solid(self, Vector3(WIDTH, lintel, WALL), Vector3(0, base + sill + glass + lintel * 0.5, -half_d), metal)
		# Atrás: la pared con su puerta.
		_back_wall(base, wall_h, float(doors[index]))
		# El puesto, mirando al frente.
		var seat := MechSeat.new(index as MechSeat.Station)
		seat.position = Vector3(0, base, -half_d + 1.6)
		add_child(seat)
		seats.append(seat)
		# Un cartel con el número de piso, en la pared de atrás por dentro.
		var number := Label3D.new()
		number.text = "PISO %d · %s" % [index + 1, str(MechSeat.NAMES[index]).to_upper()]
		number.font_size = 96
		number.pixel_size = 0.006
		number.position = Vector3(-2.2, base + 2.2, half_d - WALL * 0.5 - 0.02)
		number.rotation_degrees.y = 180.0
		number.modulate = Color(0.95, 0.85, 0.5)
		add_child(number)
	_fire_escape()


func _back_wall(base: float, wall_h: float, door_x: float) -> void:
	var half_w := WIDTH * 0.5
	var z := DEPTH * 0.5
	var door_w := 1.3
	var door_h := 2.3
	var left := door_x - door_w * 0.5 + half_w
	var right := half_w - (door_x + door_w * 0.5)
	Clay.solid(self, Vector3(left, wall_h, WALL), Vector3(-half_w + left * 0.5, base + wall_h * 0.5, z), Clay.METAL)
	Clay.solid(self, Vector3(right, wall_h, WALL), Vector3(half_w - right * 0.5, base + wall_h * 0.5, z), Clay.METAL)
	Clay.solid(self, Vector3(door_w, wall_h - door_h, WALL), Vector3(door_x, base + door_h + (wall_h - door_h) * 0.5, z),
		Clay.METAL)
	Clay.box(self, Vector3(door_w + 0.2, 0.15, WALL + 0.1), Vector3(door_x, base + door_h + 0.07, z), Clay.YELLOW)


## LA ESCALERA DE INCENDIO, atrás. Balcón en cada piso (z de la pared a `DECK`), y dos carriles más afuera:
##   carril 1: del balcón 1 (sube desde x = 3,5) al balcón 2 (llega en x = −2), con su descanso en x de −4 a −2;
##   carril 2: del descanso del piso 2 (sale desde x = −3,5) al piso 3 (llega en x = 2), con su descanso y un puente.
func _fire_escape() -> void:
	var z0 := back_face()
	var deck_z := z0 + DECK * 0.5
	var lane1 := z0 + DECK + LANE * 0.5
	var lane2 := z0 + DECK + LANE * 1.5
	var outer := z0 + DECK + LANE * 2.0
	var steel := Clay.DARK
	var y0 := floor_y(0)
	var y1 := floor_y(1)
	var y2 := floor_y(2)
	var half_w := WIDTH * 0.5
	# Los balcones: el de abajo deja el hueco del montacargas.
	_slab(Vector2(LIFT_X.y, half_w), deck_z, DECK, y0, steel)
	_slab(Vector2(-half_w, half_w), deck_z, DECK, y1, steel)
	_slab(Vector2(-half_w, half_w), deck_z, DECK, y2, steel)
	# Carril 1: el pie (x 3,5 a 4), el tramo y el descanso del piso 2.
	_slab(Vector2(3.5, half_w), lane1, LANE, y0, steel)
	_flight(Vector2(3.5, y0), Vector2(-2.0, y1), lane1, steel)
	_slab(Vector2(-half_w, -2.0), lane1, LANE, y1, steel)
	# Carril 2: el pie, el tramo, el descanso del piso 3 y el puente sobre el carril 1.
	_slab(Vector2(-half_w, -3.5), lane2, LANE, y1, steel)
	_flight(Vector2(-3.5, y1), Vector2(2.0, y2), lane2, steel)
	_slab(Vector2(2.0, half_w), lane2, LANE, y2, steel)
	_slab(Vector2(2.0, half_w), lane1, LANE, y2, steel)
	# LAS BARANDAS: afuera de todo, en las puntas, entre el balcón y los tramos donde no se pasa, y entre los carriles.
	var top := y2 + RAIL
	_rail(Vector3(WIDTH, top - y0 + 0.2, BAR), Vector3(0, (y0 + top) * 0.5, outer))
	for side: float in [-1.0, 1.0]:
		_rail(Vector3(BAR, top - y0 + 0.2, DECK + LANE * 2.0), Vector3(side * (half_w + 0.03), (y0 + top) * 0.5,
			z0 + (DECK + LANE * 2.0) * 0.5))
	_rail(Vector3(3.5 - LIFT_X.y, RAIL, BAR), Vector3((LIFT_X.y + 3.5) * 0.5, y0 + RAIL * 0.5, z0 + DECK))
	_rail(Vector3(half_w - LIFT_X.y, RAIL, BAR), Vector3((LIFT_X.y + half_w) * 0.5, y1 + RAIL * 0.5, z0 + DECK))
	_rail(Vector3(2.0 + half_w, RAIL, BAR), Vector3((2.0 - half_w) * 0.5, y2 + RAIL * 0.5, z0 + DECK))
	_rail(Vector3(5.5, top - y0, BAR), Vector3(-0.75, (y0 + top) * 0.5, z0 + DECK + LANE))
	_rail(Vector3(2.0, y2 - y0 - 0.3, BAR), Vector3(3.0, (y0 + y2 - 0.3) * 0.5, z0 + DECK + LANE))


## Un piso de chapa entre `x_range`, en el carril de centro `z` y ancho `depth`, con su cara de arriba en `y`.
func _slab(x_range: Vector2, z: float, depth: float, y: float, color: Color) -> void:
	var width := x_range.y - x_range.x
	Clay.solid(self, Vector3(width, 0.15, depth), Vector3((x_range.x + x_range.y) * 0.5, y - 0.075, z), color)


## Un tramo de escalera de `from` (x, y) a `to` (x, y) en el carril de centro `z`: una rampa que choca, con los
## escalones dibujados encima.
func _flight(from: Vector2, to: Vector2, z: float, color: Color) -> void:
	var along := to - from
	var length := along.length()
	var angle := atan2(along.y, along.x)
	var basis := Basis(Vector3.BACK, angle)
	var normal := basis * Vector3.UP
	var middle := Vector3((from.x + to.x) * 0.5, (from.y + to.y) * 0.5, z) - normal * 0.075
	Clay.shape_box(self, Vector3(length, 0.15, LANE), middle, basis)
	var ramp := Clay.box(self, Vector3(length, 0.15, LANE), middle, color)
	ramp.basis = basis
	var steps := int(absf(along.y) / 0.25)
	for step in steps:
		var share := (float(step) + 0.5) / float(steps)
		var at := Vector3(from.x + along.x * share, from.y + along.y * share + 0.05, z)
		Clay.box(self, Vector3(0.08, 0.06, LANE), at, Clay.YELLOW.darkened(0.3))


## Una baranda: una caja que choca, dibujada como chapa fina.
func _rail(size: Vector3, at: Vector3) -> void:
	Clay.shape_box(self, size, at)
	var panel := Clay.box(self, size, at, Color(0.3, 0.32, 0.35, 0.55))
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
