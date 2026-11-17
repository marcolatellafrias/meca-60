extends Node3D

## EL VIDRIO DE LA CÁPSULA CON DEGRADÉ, EN PRUEBA (16/11/2026, el usuario: «el vidrio está demasiado transparente… las
## manchas todavía no se notan… tal vez una solución es hacer un shader de gradiente para el vidrio para que al medio se
## vea más, experimentar con esto en separado»). El shader de la meca (cage_glass.gdshader) con sus cuatro maneras: desde
## la cámara del que maneja y desde afuera.
##   tools/godot_ventana.sh res://tests/glass_tint_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const RADIUS := 0.75
const BOX := Vector3(2.0, 2.0, 2.0)
## Cada uno: el título y los números del vidrio (degradé, lo claro, lo teñido, lo que ocupa lo claro).
const READS := [
	["1 · parejo (como está)", 0, 0.2, 0.2, 0.6],
	["2 · degradé por el ángulo con el frente de la cápsula", 1, 0.04, 0.5, 0.8],
	["3 · degradé por la pantalla: claro en el medio de lo que se mira", 2, 0.04, 0.5, 1.0],
	["4 · degradé por lo de costado que se lo mira", 3, 0.04, 0.55, 0.9],
]
const INSIDE := Color(0.72, 0.72, 0.7)
const SHELL := Color(0.6, 0.61, 0.63)
const BODY := Color(0.85, 0.55, 0.35)
const DARK := Color(0.26, 0.27, 0.3)
var _out := 0.35

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	for index in READS.size():
		var root := Node3D.new()
		root.position = Vector3(0.0, 0.0, index * 40.0)
		add_child(root)
		_capsule(root, index)
	for index in READS.size():
		var at := Vector3(0.0, 0.0, index * 40.0)
		var c := at + _center()
		_title.text = READS[index][0]
		var shots: Array[Image] = []
		_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		_eye.fov = 95.0
		_eye.near = 0.02
		shots.append(await _view(c, c + Vector3(0.0, -0.15, -1.0), Vector3.UP))
		_eye.fov = 45.0
		_eye.near = 0.05
		shots.append(await _view(at + Vector3(-2.6, 1.8, -4.4), at + Vector3(0.0, 1.0, -0.6), Vector3.UP))
		_save(shots, index + 1)
	get_tree().quit()


func _center() -> Vector3:
	return Vector3(0.0, 1.2, -BOX.z * 0.5 - RADIUS * (2.0 * _out - 1.0))


func _capsule(root: Node3D, read: int) -> void:
	var c := _center()
	var front := -BOX.z * 0.5
	var inner := SurfaceTool.new()
	inner.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glass := SurfaceTool.new()
	glass.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Dictionary in CageMesh.faceted_sphere():
		var normal: Vector3 = face["normal"]
		if normal.is_equal_approx(Vector3.DOWN):
			continue
		var points: Array = []
		for p: Vector3 in face["points"]:
			points.append(c + p * RADIUS)
		var parts := CageMesh.split_by_z(points, front)
		if (parts[0] as Array).size() >= 3:
			CageMesh.smooth_face(glass, parts[0], c, normal)
		if (parts[1] as Array).size() >= 3:
			CageMesh.face(inner, parts[1], normal)
	_mesh(root, inner, INSIDE)
	var pane := MeshInstance3D.new()
	pane.mesh = glass.commit()
	var paint := ShaderMaterial.new()
	paint.shader = load("res://game/mech/cage/cage_glass.gdshader") as Shader
	var numbers: Array = READS[read]
	paint.set_shader_parameter("gradient", numbers[1])
	paint.set_shader_parameter("clear_alpha", numbers[2])
	paint.set_shader_parameter("edge_alpha", numbers[3])
	paint.set_shader_parameter("spread", numbers[4])
	paint.set_shader_parameter("center", c)
	paint.set_shader_parameter("smudge_alpha", 0.3)
	pane.material_override = paint
	root.add_child(pane)
	var box := SurfaceTool.new()
	box.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := BOX * 0.5
	for normal: Vector3 in [Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN]:
		var u := Vector3(normal.y, normal.z, normal.x)
		var v := normal.cross(u)
		var m := Vector3(0.0, half.y, 0.0) + normal * half
		u *= half
		v *= half
		CageMesh.face(box, [m - u - v, m + u - v, m + u + v, m - u + v], normal)
	_mesh(root, box, SHELL)
	var pelvis := c + Vector3(0.0, -0.8, 0.12)
	Clay.box(root, Vector3(0.46, 0.06, 0.46), pelvis + Vector3(0.0, -0.1, -0.04), DARK)
	_limb(root, pelvis, c + Vector3(0.0, -0.22, 0.1), 0.15, BODY)
	Clay.sphere(root, 0.12, c + Vector3(0.0, 0.0, 0.05), BODY)
	for s: float in [-1.0, 1.0]:
		var knee := pelvis + Vector3(s * 0.12, 0.0, -0.42)
		_limb(root, pelvis + Vector3(s * 0.11, 0.0, 0.0), knee, 0.07, BODY)
		_limb(root, knee, knee + Vector3(0.0, -0.46, 0.06), 0.06, BODY)


func _limb(root: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var holder := Clay.limb(root, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)


func _mesh(root: Node3D, tool: SurfaceTool, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	root.add_child(mesh)


func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(400, 1, 400), Vector3(0, -2.5, 0), Color(0.82, 0.8, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -140.0, 0.0)
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.86)
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


func _view(from: Vector3, to: Vector3, up: Vector3) -> Image:
	_eye.global_position = from
	_eye.look_at(to, up)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array[Image], number: int) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var w := shots[0].get_width()
	var h := shots[0].get_height()
	var sheet := Image.create(w * 2, h * 2, false, shots[0].get_format())
	for index in shots.size():
		sheet.blit_rect(shots[index], Rect2i(Vector2i.ZERO, shots[index].get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/tinte_%d.png" % [_folder, number]
	sheet.save_png(path)
	print("CAPTURA ", path)
