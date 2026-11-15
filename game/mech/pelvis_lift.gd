class_name PelvisLift
extends Node3D

## EL ASCENSOR DE LA PELVIS de la meca: por donde se sube desde el suelo. Lo propuso el usuario el 12/11/2026 («un
## ascensor cilíndrico que baja… hasta una altura que sea cómoda para cuando la meca esté agachada y un jugador salte… No
## quiero que sea cuando esté parada»; «que la pelvis también sea circular y que tenga un cutout con la base de la caja.
## Así… cuando gira sigue coincidiendo»).
##
##   · LA PELVIS es un tambor hueco, de pared fina, debajo del cubo (ver `tube`; la dibuja la meca, que la gira con los
##     pies: redonda, siempre coincide).
##   · LA LOSA del piso de la cabina tiene UN RECORTE redondo del mismo hueco (`build_floor`).
##   · EL ASCENSOR (este nodo, en el espacio del cubo): UNA PLATAFORMA REDONDA que llena el hueco, y nada más (el
##     usuario, 14/11/2026: «simplificar un poco el ascensor para que sea solamente una plataforma sin toda la estructura
##     metálica… después vamos a los detalles»). BAJADA, queda a un salto del suelo con la meca agachada; SUBIDA, al ras
##     del piso. *Hasta el 14/11/2026 tenía cuatro parantes, un aro y una baranda alrededor del recorte.*
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

var _shape: CollisionShape3D = null


func _ready() -> void:
	name = "Ascensor"
	position.y = raised_y()
	Clay.cylinder(self, platform(), 0.1, Vector3(0, -0.05, 0), GRATE)
	_shape = CollisionShape3D.new()
	var disc := CylinderShape3D.new()
	disc.radius = platform()
	disc.height = 0.12
	_shape.shape = disc
	solid.add_child(_shape)
	_place()


## Su piso bajado: a la misma distancia debajo del cubo que con la caja de siempre.
static func lowered() -> float:
	return -CabinGrid.HALF_HEIGHT - LOWERED_BELOW * MechBody.WAIST / MechBody.BASE["WAIST"]


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
	return lowered() if stop < 0 else raised_y()


## Si está viajando.
func moving() -> bool:
	return not is_equal_approx(position.y, target())


func _physics_process(delta: float) -> void:
	if not moving():
		return
	position.y = move_toward(position.y, target(), SPEED * delta)
	_place()


func _place() -> void:
	_shape.position = Vector3(0.0, position.y - 0.06, 0.0)


## ── LO FIJO: LA LOSA CON EL RECORTE ──────────────────────────────────────────────────────────────────────────────

## La losa del piso de la cabina, a la altura `y` (su medio), de `thickness`: se ve con su recorte redondo, y se pisa
## alrededor (cuatro piezas en torno al hueco).
static func build_floor(holder: Node3D, body: PhysicsBody3D, y: float, thickness: float, color: Color) -> void:
	holder.add_child(holed(square(CabinGrid.HALF), hole(), y - thickness * 0.5, y + thickness * 0.5, color))
	var beside := CabinGrid.HALF - hole()
	for way: float in [-1.0, 1.0]:
		Clay.shape_box(body, Vector3(CabinGrid.SIZE, thickness, beside), Vector3(0, y, way * (hole() + beside * 0.5)))
		Clay.shape_box(body, Vector3(beside, thickness, hole() * 2.0), Vector3(way * (hole() + beside * 0.5), y, 0))


## El volumen del hueco por donde viaja, en el espacio del cubo: para el marco de la meca. Empieza un poco arriba del
## piso bajado: el que camina por el suelo debajo de la meca agachada no entra; el que se para en el ascensor, sí.
static func shaft() -> AABB:
	var bottom := lowered() + 0.55
	return AABB(Vector3(-drum(), bottom, -drum()), Vector3(drum() * 2.0, -CabinGrid.HALF_HEIGHT - bottom + 0.3, drum() * 2.0))


## LA PELVIS: el tambor hueco, centrado en su medio (como la caja de siempre).
static func tube(color: Color) -> MeshInstance3D:
	return holed(circle(drum()), hole(), -MechBody.PELVIS_SIZE.y * 0.5, MechBody.PELVIS_SIZE.y * 0.5, color)


## ── UNA PLACA CON UN HUECO REDONDO ───────────────────────────────────────────────────────────────────────────────

const SIDES := 48


## El borde de un círculo de `radius`, en `SIDES` puntos.
static func circle(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in SIDES:
		points.append(Vector2(cos(TAU * step / SIDES), sin(TAU * step / SIDES)) * radius)
	return points


## El borde de un cuadrado de medio lado `half`, en los mismos `SIDES` ángulos.
static func square(half: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in SIDES:
		var way := Vector2(cos(TAU * step / SIDES), sin(TAU * step / SIDES))
		points.append(way * (half / maxf(absf(way.x), absf(way.y))))
	return points


## UNA PLACA de `bottom` a `top`, con el borde de afuera `outer` (ver `circle`, `square`) y un hueco redondo de radio
## `hole` en el medio: las dos caras, la pared del hueco y la de afuera.
static func holed(outer: PackedVector2Array, hole: float, bottom: float, top: float, color: Color) -> MeshInstance3D:
	var inner := circle(hole)
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
		_quad(tool, a + low, b + low, b + up_offset, a + up_offset, -(a + b).normalized())
		_quad(tool, c + low, d + low, d + up_offset, c + up_offset, (c + d).normalized())
	var instance := MeshInstance3D.new()
	instance.mesh = tool.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	return instance


static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		tool.set_normal(normal)
		tool.add_vertex(point)
