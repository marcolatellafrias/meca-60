class_name BrawlerFlame
extends Node3D

## EL LANZALLAMAS DEL HORNO (ver BrawlerBrain; sólo con ira): primero EL AVISO, un abanico rojo en el piso con todo lo
## que va a barrer; con el golpe, EL CHORRO, un cono de fuego que sale de la boca del horno y gira con la cintura. Sólo
## se mueve y se dibuja: si te toca lo decide la cabeza.

## Los colores del fuego (adentro y afuera).
const CORE := Color(1.0, 0.85, 0.35)
const OUTER := Color(1.0, 0.35, 0.05)

## Hasta dónde llega (m) y la mitad de su ancho (°).
var reach := 55.0
var half_angle := 12.0
## Hacia dónde va el chorro ahora (de costado, largo 1), y desde dónde (mundo).
var way := Vector3.FORWARD
var mouth := Vector3.ZERO
var burning := false

var _fan: MeshInstance3D = null
var _fan_paint := StandardMaterial3D.new()
var _cones: Array[MeshInstance3D] = []


## LO ARMA: el abanico del piso (de `sweep` grados, centrado adelante) y el chorro, apagado.
func setup(length: float, half: float, sweep: float) -> void:
	reach = length
	half_angle = half
	_fan_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fan_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fan_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fan_paint.albedo_color = Color(1.0, 0.15, 0.1, 0.25)
	_fan = MeshInstance3D.new()
	_fan.name = "Abanico"
	_fan.top_level = true
	_fan.mesh = _sector(length, sweep + half * 2.0)
	_fan.material_override = _fan_paint
	_fan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fan)
	# EL CHORRO: dos conos, uno de adentro (claro) y uno de afuera (naranja, transparente).
	for index in 2:
		var cone := MeshInstance3D.new()
		var shape := CylinderMesh.new()
		var wide := length * tan(deg_to_rad(half)) * (1.0 if index == 1 else 0.55)
		shape.top_radius = 0.8
		shape.bottom_radius = wide
		shape.height = length
		shape.radial_segments = 16
		cone.mesh = shape
		var paint := StandardMaterial3D.new()
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		paint.albedo_color = Color(CORE, 0.75) if index == 0 else Color(OUTER, 0.4)
		paint.emission_enabled = true
		paint.emission = CORE if index == 0 else OUTER
		cone.material_override = paint
		cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cone.top_level = true
		cone.visible = false
		add_child(cone)
		_cones.append(cone)


## EL AVISO: el abanico desde `from` (el piso), centrado hacia `center` (de costado).
func warn(from: Vector3, center: Vector3) -> void:
	var flat := Vector3(center.x, 0.0, center.z).normalized()
	_fan.global_transform = Transform3D(Basis.looking_at(flat, Vector3.UP), Vector3(from.x, 0.08, from.z))
	_fan_paint.albedo_color.a = (0.3 if burning else 0.2) + 0.1 * sin(Time.get_ticks_msec() * 0.015)


## EL CHORRO, de `from` (la boca del horno) hacia `toward` (de costado): prendido o no.
func blow(from: Vector3, toward: Vector3, on: bool) -> void:
	burning = on
	mouth = from
	way = Vector3(toward.x, 0.0, toward.z).normalized()
	for index in _cones.size():
		var cone := _cones[index]
		cone.visible = on
		if not on:
			continue
		# El cono del motor va a lo largo de su eje y (la punta angosta arriba): se acuesta con la punta en la boca, hacia
		# adelante y un poco abajo.
		var down := (way + Vector3.DOWN * 0.18).normalized()
		var flicker := 1.0 + 0.08 * sin(Time.get_ticks_msec() * (0.05 + index * 0.02))
		var basis := Basis.looking_at(down, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5)
		cone.global_transform = Transform3D(basis.scaled(Vector3(flicker, 1.0, flicker)), from + down * reach * 0.5)


## Si un punto del piso (con su medio ancho, m) está dentro del chorro prendido.
func covers(point: Vector3, half: float) -> bool:
	if not burning:
		return false
	var flat := Vector3(point.x - mouth.x, 0.0, point.z - mouth.z)
	var far := flat.length()
	if far > reach + half or far < 0.01:
		return false
	var off := rad_to_deg(way.angle_to(flat / far))
	var slack := rad_to_deg(atan2(half, far))
	return off < half_angle + slack


## Un abanico chato en el piso: `length` de largo y `degrees` de ancho, hacia −z.
static func _sector(length: float, degrees: float) -> ArrayMesh:
	var points := PackedVector3Array()
	var steps := 24
	for index in steps:
		var a := deg_to_rad(-degrees * 0.5 + degrees * index / steps)
		var b := deg_to_rad(-degrees * 0.5 + degrees * (index + 1) / steps)
		points.append(Vector3.ZERO)
		points.append(Vector3(sin(a), 0.0, -cos(a)) * length)
		points.append(Vector3(sin(b), 0.0, -cos(b)) * length)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
