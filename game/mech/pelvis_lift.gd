class_name PelvisLift
extends Node3D

## EL ASCENSOR DE LA PELVIS de la meca: por donde se sube desde el suelo. Lo propuso el usuario el 12/11/2026 («un
## ascensor cilíndrico que baja… hasta una altura que sea cómoda para cuando la meca esté agachada y un jugador salte… No
## quiero que sea cuando esté parada»; «que la pelvis también sea circular y que tenga un cutout con la base de la caja.
## Así… cuando gira sigue coincidiendo»).
##
##   · LA PELVIS es un tambor hueco, de pared fina, debajo del cubo (ver `tube`; la dibuja la meca, que la gira con los
##     pies: redonda, siempre coincide).
##   · LA LOSA del piso de la cabina tiene UN RECORTE redondo del mismo hueco (lo arma cada cabina).
##   · EL ASCENSOR (este nodo, en el espacio del cubo): UNA PLATAFORMA REDONDA que llena el hueco, y nada más (el
##     usuario, 14/11/2026: «simplificar un poco el ascensor para que sea solamente una plataforma sin toda la estructura
##     metálica… después vamos a los detalles»). BAJADA, queda a un salto del suelo con la meca agachada; SUBIDA, al ras
##     del piso. *Hasta el 14/11/2026 tenía cuatro parantes, un aro y una baranda alrededor del recorte.*
##
## *Del 15/11/2026 hasta que se retiró la cuadrada de antes, podía ser cuadrado (un toggle del F2): el hueco, la
## plataforma y la pelvis. Las cabinas de ahora lo llevan adentro de la tarima, redondo.*
##
## SE VIAJA EN ELLA: su piso tiene forma de choque en `solid` (las formas de adentro de la meca, de las que su marco
## copia la sombra), y se mueve con ella. DOS TECLAS (el usuario, 13/11/2026: «dos teclas»): `up` la sube y `lower` la
## baja. Las paradas (`stop`): bajada (-1) y subida (0); subir arriba de todo no hace nada.

## El hueco (el recorte de la losa y el de la pelvis), la pelvis por fuera y la plataforma: sus radios. Casi iguales: se
## leen como una sola forma. El hueco sale de la trama (ver CabinGrid.LIFT_HOLE).
static func hole() -> float:
	return CabinGrid.LIFT_HOLE


static func drum() -> float:
	return hole() + 2 * CabinGrid.CELL


static func platform() -> float:
	return hole() - CabinGrid.CELL


## Dónde queda el piso bajado (en el espacio del cubo; la meca agachada, a un salto del suelo) y a qué velocidad viaja.
const LOWERED_BELOW := 3.03
const SPEED := 1.6
const GRATE := Color(0.36, 0.38, 0.41)

## Las formas de choque de adentro de la meca: ahí va la de la plataforma. Se pone antes de agregarla al árbol.
var solid: PhysicsBody3D = null
## Adónde va: -1 bajada, 0 subida.
var stop := 0
## LO DE CADA CABINA (lo pone la que lo arma, antes de agregarlo; por defecto, el de la cuadrada): el radio del hueco,
## las dos paradas (en el espacio del cubo) y dónde va en planta (`center`, x y z).
var hole_radius := 0.0
var raised_at := 0.0
var lowered_at := 0.0
var center := Vector2.ZERO

var _shape: CollisionShape3D = null


func _init() -> void:
	hole_radius = hole()
	raised_at = raised_y()
	lowered_at = lowered()


## Su plataforma: un poco más chica que el hueco.
func plate_radius() -> float:
	return hole_radius - CabinGrid.CELL


func _ready() -> void:
	name = "Ascensor"
	position = Vector3(center.x, raised_at, center.y)
	_shape = CollisionShape3D.new()
	var reach := plate_radius()
	Clay.cylinder(self, reach, 0.1, Vector3(0, -0.05, 0), GRATE)
	var disc := CylinderShape3D.new()
	disc.radius = reach
	disc.height = 0.12
	_shape.shape = disc
	solid.add_child(_shape)
	_place()


## Su piso bajado: a la misma distancia debajo del cubo que con la caja de siempre (`half_height`: la mitad del alto de
## la caja; por defecto, la cuadrada).
static func lowered(half_height := -1.0) -> float:
	var half := CabinGrid.HALF_HEIGHT if half_height < 0.0 else half_height
	return -half - LOWERED_BELOW * MechBody.current.WAIST / MechBody.BASE["WAIST"]


## Su piso subido: al ras del piso de la cabina.
static func raised_y() -> float:
	return CabinGrid.floor_top()


## Sube (subida, nada).
func up() -> void:
	stop = 0


## Baja (bajada, nada).
func lower() -> void:
	stop = -1


## La altura de su piso en la parada de ahora.
func target() -> float:
	return lowered_at if stop < 0 else raised_at


## Si está viajando.
func moving() -> bool:
	return not is_equal_approx(position.y, target())


func _physics_process(delta: float) -> void:
	if not moving():
		return
	position.y = move_toward(position.y, target(), SPEED * delta)
	_place()


func _place() -> void:
	_shape.position = Vector3(center.x, position.y - 0.06, center.y)


## LA PELVIS: el tambor hueco, centrado en su medio (como la caja de siempre).
static func tube(color: Color, tall := MechBody.current.PELVIS_SIZE.y) -> MeshInstance3D:
	return holed(outline(drum()), hole(), -tall * 0.5, tall * 0.5, color)


## ── UNA PLACA CON UN HUECO REDONDO ───────────────────────────────────────────────────────────────────────────────

const SIDES := 48


## El borde de un círculo de `radius`, en `SIDES` puntos.
static func circle(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in SIDES:
		points.append(Vector2(cos(TAU * step / SIDES), sin(TAU * step / SIDES)) * radius)
	return points


## El borde de la forma del ascensor, de radio `size`.
static func outline(size: float) -> PackedVector2Array:
	return circle(size)


## El borde de un cuadrado de medio lado `half`, en los mismos `SIDES` ángulos.
static func square(half: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in SIDES:
		var way := Vector2(cos(TAU * step / SIDES), sin(TAU * step / SIDES))
		points.append(way * (half / maxf(absf(way.x), absf(way.y))))
	return points


## UNA PLACA de `bottom` a `top`, con el borde de afuera `outer` (ver `circle`, `square`) y un hueco de la forma del
## ascensor (`outline`), de radio `hole`, en el medio: las dos caras, la pared del hueco y la de afuera. EL SOMBREADO,
## COMO EL AUTO SMOOTH (el usuario, 15/11/2026: «la pelvis… en shading smooth cuando deberían estar… auto smooth»): una
## pared redonda, suave; una de lados (el cuadrado), cada lado plano. *Las paredes llevaban la normal hacia el centro
## de cada tramo: en el cuadrado, inclinada hacia la esquina, y se veía como suavizado.*
static func holed(outer: PackedVector2Array, hole: float, bottom: float, top: float, color: Color) -> MeshInstance3D:
	var inner := outline(hole)
	var outer_round := _is_round(outer)
	var inner_round := _is_round(inner)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step in SIDES:
		var next := (step + 1) % SIDES
		var a := Vector3(inner[step].x, 0, inner[step].y)
		var b := Vector3(inner[next].x, 0, inner[next].y)
		var c := Vector3(outer[step].x, 0, outer[step].y)
		var d := Vector3(outer[next].x, 0, outer[next].y)
		var up_offset := Vector3.UP * top
		var low := Vector3.UP * bottom
		_quad(tool, a + up_offset, b + up_offset, d + up_offset, c + up_offset, Vector3.UP)
		_quad(tool, a + low, b + low, d + low, c + low, Vector3.DOWN)
		_wall(tool, a, b, low, up_offset, inner_round, false)
		_wall(tool, c, d, low, up_offset, outer_round, true)
	var instance := MeshInstance3D.new()
	instance.mesh = tool.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	return instance


## Una pared de la placa, de `from` a `to` (en el piso, sin alto), de `low` a `high`: si es redonda, cada borde con la
## normal hacia afuera del centro (suave); si no, toda con la normal de su cara (plana). `outward`: la de afuera (si no,
## la del hueco, que mira hacia adentro).
static func _wall(tool: SurfaceTool, from: Vector3, to: Vector3, low: Vector3, high: Vector3, round_wall: bool,
		outward: bool) -> void:
	var way := 1.0 if outward else -1.0
	var flat := (to - from).cross(Vector3.UP).normalized()
	if flat.dot(from + to) * way < 0.0:
		flat = -flat
	var n_from := from.normalized() * way if round_wall else flat
	var n_to := to.normalized() * way if round_wall else flat
	for pair: Array in [[from + low, n_from], [to + low, n_to], [to + high, n_to], [from + low, n_from], [to + high, n_to],
			[from + high, n_from]]:
		tool.set_normal(pair[1])
		tool.add_vertex(pair[0])


## Si un borde es redondo: todos sus puntos a la misma distancia del centro.
static func _is_round(edge: PackedVector2Array) -> bool:
	var reach := edge[0].length()
	for point in edge:
		if absf(point.length() - reach) > 0.01:
			return false
	return true


static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		tool.set_normal(normal)
		tool.add_vertex(point)
