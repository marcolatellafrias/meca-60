class_name PelvisLift
extends Node3D

## EL ASCENSOR DE LA PELVIS de la meca: por donde se sube desde el suelo. Lo propuso el usuario el 12/11/2026 («un
## ascensor cilíndrico que baja… hasta una altura que sea cómoda para cuando la meca esté agachada y un jugador salte… No
## quiero que sea cuando esté parada»; «una base circular con algunos parantes… que la pelvis también sea circular y que
## tenga un cutout con la base de la caja. Así… cuando gira sigue coincidiendo, y que en el cutout ese tenga como una
## baranda todo alrededor con un hueco en la dirección de la primera puerta») y eligió, entre cuatro maquetas, la de
## CUATRO PARANTES Y UN ARO, con el ascensor casi del radio de la pelvis («que se lea como una sola forma»).
##
##   · LA PELVIS es un tambor hueco, de pared fina, debajo del cubo (ver `tube`; la dibuja la meca, que la gira con los
##     pies: redonda, siempre coincide).
##   · LA LOSA de abajo del cubo tiene UN RECORTE redondo del mismo hueco (`build_floor`), y alrededor, adentro del piso
##     de abajo, UNA BARANDA con el paso abierto hacia la puerta de atrás.
##   · EL ASCENSOR (este nodo, en el espacio del cubo): un piso redondo que llena el hueco, cuatro parantes y un aro
##     arriba. Los parantes son tan altos como el viaje: BAJADO, sus puntas siguen dentro de la pelvis (nada se estira) y
##     el piso queda a un salto del suelo con la meca agachada, lejos con la meca parada; SUBIDO, el piso queda al ras del
##     piso de abajo y los parantes son su jaula.
##
## SE VIAJA EN ÉL: su piso tiene forma de choque en `solid` (las formas de adentro de la meca, de las que su marco copia
## la sombra), y se mueve con él. `down` lo manda abajo o arriba; `toggle` lo cambia.

const HALF := CabinGrid.HALF
## El hueco (el recorte de la losa y el de la pelvis), la pelvis por fuera y el piso del ascensor: sus radios. Casi
## iguales: se leen como una sola forma. EN CELDAS (ver CabinGrid): el hueco ocupa los 2 × 2 módulos del medio de la
## planta baja, tres celdas adentro de sus bordes.
const HOLE := CabinGrid.MODULE - 3 * CabinGrid.CELL
const DRUM := HOLE + 2 * CabinGrid.CELL
const PLATFORM := HOLE - CabinGrid.CELL
## El alto de los parantes (y de la jaula), dónde queda el piso bajado (en el espacio del cubo) y a qué velocidad viaja.
const CAGE := 56 * CabinGrid.CELL
const LOWERED := -7.05
const SPEED := 1.6
const RAIL := 1.05
## Cuánto se abre la baranda del recorte hacia la puerta (grados, a cada lado).
const GATE := 36.0
const STEEL := Color(0.24, 0.25, 0.28)
const GRATE := Color(0.36, 0.38, 0.41)

## Las formas de choque de adentro de la meca: ahí va la del piso del ascensor. Se pone antes de agregarlo al árbol.
var solid: PhysicsBody3D = null
## Adónde va: abajo, o arriba.
var down := false

var _shape: CollisionShape3D = null


func _ready() -> void:
	name = "Ascensor"
	position.y = raised_y()
	Clay.cylinder(self, PLATFORM, 0.1, Vector3(0, -0.05, 0), GRATE)
	for index in 4:
		var angle := PI * 0.5 + TAU * (index + 0.5) / 4.0
		var at := Vector3(cos(angle), 0, sin(angle)) * (PLATFORM - 0.08)
		_bar(self, at, at + Vector3.UP * CAGE, 0.09)
	_ring(self, CAGE, PLATFORM - 0.06)
	_shape = CollisionShape3D.new()
	var disc := CylinderShape3D.new()
	disc.radius = PLATFORM
	disc.height = 0.12
	_shape.shape = disc
	solid.add_child(_shape)
	_place()


## Su piso subido: al ras del piso de abajo.
static func raised_y() -> float:
	return CabinGrid.ground(0)


func toggle() -> void:
	down = not down


## Si está viajando.
func moving() -> bool:
	return not is_equal_approx(position.y, LOWERED if down else raised_y())


func _physics_process(delta: float) -> void:
	if not moving():
		return
	position.y = move_toward(position.y, LOWERED if down else raised_y(), SPEED * delta)
	_place()


func _place() -> void:
	_shape.position = Vector3(0.0, position.y - 0.06, 0.0)


## ── LO FIJO: LA LOSA CON EL RECORTE Y SU BARANDA ─────────────────────────────────────────────────────────────────

## La losa de abajo del cubo, a la altura `y`, de `thickness`: se ve con su recorte redondo, y se pisa alrededor (cuatro
## piezas en torno al hueco). Y la baranda del recorte, con el paso hacia la puerta de atrás (+Z).
static func build_floor(holder: Node3D, body: PhysicsBody3D, y: float, thickness: float, color: Color) -> void:
	holder.add_child(holed(square(HALF), HOLE, y - thickness * 0.5, y + thickness * 0.5, color))
	var beside := HALF - HOLE
	for way: float in [-1.0, 1.0]:
		Clay.shape_box(body, Vector3(CabinGrid.SIZE, thickness, beside), Vector3(0, y, way * (HOLE + beside * 0.5)))
		Clay.shape_box(body, Vector3(beside, thickness, HOLE * 2.0), Vector3(way * (HOLE + beside * 0.5), y, 0))
	var top := y + thickness * 0.5
	var rim := HOLE + 0.16
	var before := Vector3.ZERO
	for step in 13:
		var angle := deg_to_rad(90.0 + GATE + (360.0 - GATE * 2.0) * step / 12.0)
		var post := Vector3(cos(angle) * rim, top, sin(angle) * rim)
		_bar(holder, post, post + Vector3.UP * RAIL)
		if step > 0:
			_bar(holder, before + Vector3.UP * RAIL, post + Vector3.UP * RAIL)
			_bar(holder, before + Vector3.UP * RAIL * 0.5, post + Vector3.UP * RAIL * 0.5, 0.05)
			# La pared fina de la baranda: no deja caer al hueco.
			var along := MechBody.segment(before, post, Vector3.UP)
			Clay.shape_box(body, Vector3(0.1, RAIL, before.distance_to(post)), along.origin + Vector3.UP * RAIL * 0.5,
				along.basis)
		before = post


## El volumen del hueco por donde viaja, en el espacio del cubo: para el marco de la meca. Empieza un poco arriba del
## piso bajado: el que camina por el suelo debajo de la meca agachada no entra; el que se para en el ascensor, sí.
static func shaft() -> AABB:
	var bottom := LOWERED + 0.55
	return AABB(Vector3(-DRUM, bottom, -DRUM), Vector3(DRUM * 2.0, -HALF - bottom + 0.3, DRUM * 2.0))


## LA PELVIS: el tambor hueco, centrado en su medio (como la caja de siempre).
static func tube(color: Color) -> MeshInstance3D:
	return holed(circle(DRUM), HOLE, -MechBody.PELVIS_SIZE.y * 0.5, MechBody.PELVIS_SIZE.y * 0.5, color)


static func _ring(holder: Node3D, y: float, radius: float) -> void:
	for step in 24:
		var from := Vector3(cos(TAU * step / 24.0), 0, sin(TAU * step / 24.0)) * radius
		var to := Vector3(cos(TAU * (step + 1) / 24.0), 0, sin(TAU * (step + 1) / 24.0)) * radius
		_bar(holder, from + Vector3.UP * y, to + Vector3.UP * y)


static func _bar(holder: Node3D, from: Vector3, to: Vector3, thickness := 0.07) -> void:
	var bar := Clay.box(holder, Vector3(thickness, thickness, from.distance_to(to)), Vector3.ZERO, STEEL)
	bar.transform = MechBody.segment(from, to, Vector3.UP)


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
		var up := Vector3.UP * top
		var low := Vector3.UP * bottom
		_quad(tool, a + up, b + up, d + up, c + up, Vector3.UP)
		_quad(tool, a + low, b + low, d + low, c + low, Vector3.DOWN)
		_quad(tool, a + low, b + low, b + up, a + up, -(a + b).normalized())
		_quad(tool, c + low, d + low, d + up, c + up, (c + d).normalized())
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
