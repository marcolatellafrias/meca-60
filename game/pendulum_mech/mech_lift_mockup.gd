class_name MechLiftMockup
extends RefCounted

## MAQUETAS DEL ASCENSOR DE LA PELVIS (12/11/2026), para elegir. Lo propuso el usuario: «que el ascensor sea como una base
## circular con algunos parantes… que lo conecten con la pelvis, pero que la pelvis también sea circular y que tenga un
## cutout con la base de la caja. Así… cuando gira sigue coincidiendo, y que en el cutout ese tenga como una baranda todo
## alrededor con un hueco en la dirección de la primera puerta… del primer piso». ES SÓLO DIBUJO, en el espacio del
## cubo (el centro en el origen): nada sube ni baja todavía.
##
## LO COMÚN: LA PELVIS REDONDA, un tambor hueco debajo del cubo (las caderas, a sus costados); EL RECORTE redondo en la
## losa de abajo del cubo, del mismo hueco (ver PendulumMech.floor_cutout); LA BARANDA alrededor del recorte, adentro del
## piso de abajo, con el hueco hacia la puerta de atrás; y EL ASCENSOR: un piso redondo con sus parantes, que son tan
## altos como el viaje: bajado, las puntas siguen metidas en la pelvis (nada se estira); subido, el piso queda al ras
## del piso de abajo y los parantes son su jaula.
## LAS VARIANTES cambian la jaula: cuántos parantes y si lleva aro.

const NAMES := [
	"cuatro parantes y un aro",
	"tres parantes y un aro",
	"seis parantes finos, sin aro",
	"dos parantes anchos y un aro",
]
const HALF := HoverCube.SIZE * 0.5
## El hueco (el recorte de la losa y el de la pelvis), el tambor de la pelvis y el piso del ascensor: sus radios.
const HOLE := 1.4
const DRUM := 1.85
const PLATFORM := 1.28
## El alto de los parantes (y de la jaula), y dónde queda el piso del ascensor bajado.
const CAGE := 2.2
const LOWERED := -7.05
const RAIL := 1.05
## Cuánto se abre la baranda del recorte hacia la puerta (grados, a cada lado).
const GATE := 36.0
const STEEL := Color(0.24, 0.25, 0.28)
const GRATE := Color(0.36, 0.38, 0.41)


## Arma la maqueta `variant` (ver NAMES) colgada de `holder`; `raised`: el ascensor arriba, al ras del piso, o bajado.
static func build(holder: Node3D, variant: int, raised: bool) -> void:
	var floor_at := PendulumMech.floor_y(0) + PendulumMech.SLAB * 0.5
	# LA PELVIS: un tambor hueco, del alto de la de siempre.
	holder.add_child(holed(circle(DRUM), HOLE, -HALF - MechBody.PELVIS_SIZE.y, -HALF, Clay.METAL.darkened(0.15)))
	# LA BARANDA del recorte, con el hueco hacia la puerta de atrás (+Z).
	var rim := HOLE + 0.14
	var posts: Array[Vector3] = []
	for step in 13:
		var angle := deg_to_rad(90.0 + GATE + (360.0 - GATE * 2.0) * step / 12.0)
		posts.append(Vector3(cos(angle) * rim, floor_at, sin(angle) * rim))
	for index in posts.size():
		_bar(holder, posts[index], posts[index] + Vector3.UP * RAIL)
		if index > 0:
			_bar(holder, posts[index - 1] + Vector3.UP * RAIL, posts[index] + Vector3.UP * RAIL)
			_bar(holder, posts[index - 1] + Vector3.UP * RAIL * 0.5, posts[index] + Vector3.UP * RAIL * 0.5, 0.05)
	# EL ASCENSOR.
	var base := floor_at if raised else LOWERED
	Clay.cylinder(holder, PLATFORM, 0.1, Vector3(0, base - 0.05, 0), GRATE)
	var top := base + CAGE
	match variant:
		0:
			_cage(holder, base, 4, 0.09, true)
		1:
			_cage(holder, base, 3, 0.09, true)
		2:
			_cage(holder, base, 6, 0.06, false)
		3:
			for side: float in [-1.0, 1.0]:
				Clay.box(holder, Vector3(0.12, CAGE, 0.6), Vector3(side * (PLATFORM - 0.08), base + CAGE * 0.5, 0), STEEL)
			_ring(holder, top, PLATFORM - 0.05)


## La jaula: `count` parantes en ronda (ninguno en el paso hacia la puerta) y, si lleva, un aro arriba.
static func _cage(holder: Node3D, base: float, count: int, thickness: float, ring: bool) -> void:
	for index in count:
		var angle := deg_to_rad(90.0) + TAU * (index + 0.5) / count
		var at := Vector3(cos(angle), 0, sin(angle)) * (PLATFORM - 0.07)
		_bar(holder, at + Vector3.UP * base, at + Vector3.UP * (base + CAGE), thickness)
	if ring:
		_ring(holder, base + CAGE, PLATFORM - 0.05)


static func _ring(holder: Node3D, y: float, radius: float) -> void:
	for step in 20:
		var from := Vector3(cos(TAU * step / 20.0), 0, sin(TAU * step / 20.0)) * radius
		var to := Vector3(cos(TAU * (step + 1) / 20.0), 0, sin(TAU * (step + 1) / 20.0)) * radius
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
		var down := Vector3.UP * bottom
		_quad(tool, a + up, b + up, d + up, c + up, Vector3.UP)
		_quad(tool, a + down, b + down, d + down, c + down, Vector3.DOWN)
		_quad(tool, a + down, b + down, b + up, a + up, -(a + b).normalized())
		_quad(tool, c + down, d + down, d + up, c + up, (c + d).normalized())
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
