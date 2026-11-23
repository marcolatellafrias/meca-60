class_name ElectricFx
extends MeshInstance3D

## EL EFECTO DE ESTAR ELECTRIFICADO (22/11/2026; el usuario: «que se note como electrificado… y luego podemos reusar ese
## efecto»). Se le cuelga a cualquier cosa (`attach`) y, con `on`, le saltan rayos quebrados entre puntos de su caja, se
## redibujan varias veces por segundo y una luz parpadea. Sólo se ve: no sabe de daño ni de red.

const COLOR := Color(0.55, 0.9, 1.0)
const CORE := Color(0.95, 1.0, 1.0)
const REDRAW := 20.0
const STEPS := 6
const JAG := 0.16
const WIDTH := 0.045

## Si está prendido, la media caja donde saltan los rayos (m, en sus ejes) y cuántos rayos.
var on := false:
	set(value):
		on = value
		visible = value
		if _light != null:
			_light.visible = value
var half := Vector3.ONE
var arcs := 6
var _clock := 0.0
var _lines := ImmediateMesh.new()
var _light: OmniLight3D = null


## LE CUELGA EL EFECTO A `parent`, apagado.
static func attach(parent: Node3D, box_half: Vector3, arc_count := 6, with_light := true) -> ElectricFx:
	var made := ElectricFx.new()
	made.name = "Electricidad"
	made.half = box_half
	made.arcs = arc_count
	if with_light:
		made._light = OmniLight3D.new()
		made._light.light_color = COLOR
		made._light.omni_range = box_half.length() * 2.5
		made._light.visible = false
		made.add_child(made._light)
	parent.add_child(made)
	return made


func _ready() -> void:
	mesh = _lines
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.vertex_color_use_as_albedo = true
	paint.no_depth_test = true
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = paint
	visible = on


func _process(delta: float) -> void:
	if not on:
		return
	_clock -= delta
	if _clock > 0.0:
		return
	_clock = 1.0 / REDRAW
	_redraw()
	if _light != null:
		_light.light_energy = randf_range(0.6, 2.6)


func _redraw() -> void:
	_lines.clear_surfaces()
	var camera := get_viewport().get_camera_3d()
	var eye := to_local(camera.global_position) if camera != null else Vector3.UP * 10.0
	_lines.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for arc in arcs:
		var from := _on_box()
		var to := _on_box()
		var last := from
		var size := (to - from).length()
		for step in range(1, STEPS + 1):
			var at := from.lerp(to, float(step) / STEPS)
			if step < STEPS:
				at += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * size * JAG
			_segment(last, at, eye, WIDTH * 2.2, COLOR)
			_segment(last, at, eye, WIDTH, CORE)
			last = at
	_lines.surface_end()


## UN TRAMO: una cinta que mira a la cámara, porque las líneas de un píxel casi no se ven de lejos.
func _segment(a: Vector3, b: Vector3, eye: Vector3, width: float, tint: Color) -> void:
	var side := (b - a).cross(eye - a)
	if side.length() < 0.0001:
		return
	side = side.normalized() * width
	for point: Vector3 in [a - side, a + side, b + side, a - side, b + side, b - side]:
		_lines.surface_set_color(tint)
		_lines.surface_add_vertex(point)


## Un punto al azar sobre una cara de la caja.
func _on_box() -> Vector3:
	var point := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	var face := randi() % 3
	point[face] = 1.0 if randf() < 0.5 else -1.0
	return point * half
