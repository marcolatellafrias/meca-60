class_name BossOrbField
extends Node3D

## LAS BOLITAS DE UN JEFE (22/11/2026; el usuario: «distintas bolitas con distintas propiedades… un concepto más de muchos
## elementos esquivables»). Una sola pieza lleva todas: cada máquina las mueve con las mismas reglas desde la orden de
## lanzarlas (BossNet), así no viaja la posición de cada una. Si tocan algo lo decide el host (OrbsPower).
##   · COMÚN, blanca. RÁPIDA, roja y chica. LENTA, violeta y grande. REBOTA, verde, en el anillo del piso. ELÉCTRICA, celeste:
##     aturde (MechStun). SE PARTE, naranja: a mitad de camino se abre en seis chicas.

enum Kind { NORMAL, FAST, SLOW, BOUNCE, STUN, SPLIT, SHARD }

const LOOKS := {
	Kind.NORMAL: {"color": Color(0.95, 0.95, 0.9), "radius": 0.45, "pace": 1.0},
	Kind.FAST: {"color": Color(1.0, 0.25, 0.2), "radius": 0.3, "pace": 1.8},
	Kind.SLOW: {"color": Color(0.65, 0.35, 1.0), "radius": 0.95, "pace": 0.5},
	Kind.BOUNCE: {"color": Color(0.3, 0.95, 0.4), "radius": 0.55, "pace": 0.9},
	Kind.STUN: {"color": Color(0.35, 0.85, 1.0), "radius": 0.55, "pace": 0.8},
	Kind.SPLIT: {"color": Color(1.0, 0.6, 0.1), "radius": 0.7, "pace": 0.7},
	Kind.SHARD: {"color": Color(1.0, 0.75, 0.35), "radius": 0.28, "pace": 1.2},
}
## A qué altura del piso vuelan (m): se esquivan caminando, o pasándoles por arriba con el sobrevuelo.
const HEIGHT := 1.0
const LIFE := 7.0
const FADE := 0.35
const BOUNCES := 3
const SPLIT_AT := 0.9
const SHARDS := 6
const RING_WIDE := 0.22
const RING_STEPS := 72

var center := Vector3.ZERO
var ring := 20.0
## id → {id, kind, at, way, speed, radius, age, bounces, body, mark}
var _orbs := {}
var _meshes := {}
var _paints := {}
var _mark_mesh: CylinderMesh = null
var _mark_paint: StandardMaterial3D = null
## Cuántas salieron, rebotaron y se partieron (para las pruebas).
var launched := 0
var bounced := 0
var split_count := 0


func _init() -> void:
	top_level = true


## EL ANILLO DONDE REBOTAN, alrededor de `at` (el piso).
func setup(at: Vector3, radius: float) -> void:
	center = at
	ring = radius
	global_transform = Transform3D.IDENTITY
	var points := PackedVector3Array()
	for step in RING_STEPS:
		var a := TAU * step / RING_STEPS
		var b := TAU * (step + 1) / RING_STEPS
		var inner_a := at + Vector3(cos(a), 0.0, sin(a)) * (radius - RING_WIDE) + Vector3.UP * 0.06
		var outer_a := at + Vector3(cos(a), 0.0, sin(a)) * radius + Vector3.UP * 0.06
		var inner_b := at + Vector3(cos(b), 0.0, sin(b)) * (radius - RING_WIDE) + Vector3.UP * 0.06
		var outer_b := at + Vector3(cos(b), 0.0, sin(b)) * radius + Vector3.UP * 0.06
		points.append_array(PackedVector3Array([inner_a, outer_a, outer_b, inner_a, outer_b, inner_b]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var drawn := ArrayMesh.new()
	drawn.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var line := MeshInstance3D.new()
	line.name = "Anillo"
	line.mesh = drawn
	var paint := EnergyBolt.shine((LOOKS[Kind.BOUNCE]["color"] as Color))
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.albedo_color.a = 0.35
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	line.material_override = paint
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(line)


## LANZA VARIAS de una: cada una [id, desde (mundo), rumbo (rad), tipo, velocidad común (m/s)].
func launch(items: Array) -> void:
	for item: Array in items:
		_add(int(item[0]), item[1], float(item[2]), int(item[3]) as Kind, float(item[4]))


## SE APAGA la bolita `id`, con su destello.
func pop(id: int) -> void:
	var orb: Dictionary = _orbs.get(id, {})
	if orb.is_empty():
		return
	EnergyBolt.flash(get_parent(), orb["at"], float(orb["radius"]) * 1.2, LOOKS[orb["kind"]]["color"])
	_remove(id)


## Las que están volando.
func live() -> Array:
	return _orbs.values()


func _add(id: int, from: Vector3, yaw: float, kind: Kind, speed: float) -> void:
	var look: Dictionary = LOOKS[kind]
	var at := Vector3(from.x, center.y + HEIGHT, from.z)
	var body := MeshInstance3D.new()
	body.mesh = _mesh_of(kind)
	body.material_override = _paint_of(kind)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(body)
	body.global_position = at
	var mark := MeshInstance3D.new()
	mark.mesh = _mark()
	mark.material_override = _mark_paint
	mark.scale = Vector3(look["radius"], 1.0, look["radius"])
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mark)
	mark.global_position = Vector3(at.x, center.y + 0.05, at.z)
	if kind == Kind.STUN:
		var sparks := ElectricFx.attach(body, Vector3.ONE * float(look["radius"]) * 1.25, 2, false)
		sparks.on = true
	_orbs[id] = {"id": id, "kind": kind, "at": at, "way": Basis(Vector3.UP, yaw) * Vector3.FORWARD,
		"speed": speed * float(look["pace"]), "base": speed, "radius": look["radius"], "age": 0.0, "bounces": BOUNCES,
		"body": body, "mark": mark}
	launched += 1


func _remove(id: int) -> void:
	var orb: Dictionary = _orbs[id]
	(orb["body"] as Node).queue_free()
	(orb["mark"] as Node).queue_free()
	_orbs.erase(id)


func _mesh_of(kind: Kind) -> SphereMesh:
	if not _meshes.has(kind):
		var ball := SphereMesh.new()
		ball.radius = LOOKS[kind]["radius"]
		ball.height = float(LOOKS[kind]["radius"]) * 2.0
		ball.radial_segments = 16
		ball.rings = 8
		_meshes[kind] = ball
	return _meshes[kind]


func _paint_of(kind: Kind) -> StandardMaterial3D:
	if not _paints.has(kind):
		_paints[kind] = EnergyBolt.shine(LOOKS[kind]["color"])
	return _paints[kind]


## LA SOMBRITA EN EL PISO: en una cámara inclinada, dice dónde está de verdad la bolita.
func _mark() -> CylinderMesh:
	if _mark_mesh == null:
		_mark_mesh = CylinderMesh.new()
		_mark_mesh.top_radius = 1.0
		_mark_mesh.bottom_radius = 1.0
		_mark_mesh.height = 0.01
		_mark_mesh.radial_segments = 16
		_mark_paint = StandardMaterial3D.new()
		_mark_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mark_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mark_paint.albedo_color = Color(0.0, 0.0, 0.0, 0.4)
	return _mark_mesh


func _physics_process(delta: float) -> void:
	for id: int in _orbs.keys():
		if not _orbs.has(id):
			continue
		var orb: Dictionary = _orbs[id]
		var age := float(orb["age"]) + delta
		orb["age"] = age
		if age >= LIFE:
			_remove(id)
			continue
		var was: Vector3 = orb["at"]
		var at: Vector3 = was + (orb["way"] as Vector3) * float(orb["speed"]) * delta
		if orb["kind"] == Kind.BOUNCE:
			at = _bounce(orb, was, at)
		orb["at"] = at
		var body := orb["body"] as Node3D
		body.global_position = at
		(orb["mark"] as Node3D).global_position = Vector3(at.x, center.y + 0.05, at.z)
		if age > LIFE - FADE:
			body.scale = Vector3.ONE * maxf((LIFE - age) / FADE, 0.05)
		if orb["kind"] == Kind.SPLIT and age >= SPLIT_AT:
			_split(orb)


## SI CRUZA EL ANILLO DESDE ADENTRO, vuelve para adentro, como una bola de billar. Después de sus rebotes, sigue de largo.
func _bounce(orb: Dictionary, was: Vector3, at: Vector3) -> Vector3:
	if int(orb["bounces"]) <= 0:
		return at
	var inside := Vector2(was.x - center.x, was.z - center.z).length() < ring
	var off := Vector3(at.x - center.x, 0.0, at.z - center.z)
	if not inside or off.length() < ring:
		return at
	var normal := off.normalized()
	orb["way"] = (orb["way"] as Vector3).bounce(normal).normalized()
	orb["bounces"] = int(orb["bounces"]) - 1
	bounced += 1
	EnergyBolt.flash(get_parent(), at, 0.35, LOOKS[Kind.BOUNCE]["color"])
	var back := center + normal * (ring - 0.02)
	return Vector3(back.x, at.y, back.z)


## SE PARTE en seis para todos lados. Los ids salen del suyo, así son los mismos en todas las máquinas.
func _split(orb: Dictionary) -> void:
	var id := int(orb["id"])
	var at: Vector3 = orb["at"]
	var base := float(orb["base"])
	var start := atan2(-(orb["way"] as Vector3).x, -(orb["way"] as Vector3).z)
	split_count += 1
	EnergyBolt.flash(get_parent(), at, 0.7, LOOKS[Kind.SPLIT]["color"])
	_remove(id)
	for index in SHARDS:
		_add(-(absi(id) * 10 + index), at, start + TAU * index / SHARDS, Kind.SHARD, base)
