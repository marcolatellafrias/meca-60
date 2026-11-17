extends Node3D

## LA CÁPSULA DEL QUE MANEJA, FACETADA (16/11/2026, el usuario: «hacer un octógono igual que arriba, pero hecho como
## esfera… un cubo [facetado]… que el octógono de la base tenga un hueco… de ahí sale la silla y el personaje también
## puede colgar sus piernas… cómo lo conectamos con la cápsula de adelante. A menos de que el domo sea básicamente esta
## misma estructura pero hecha transparente… maquetes… con unos cortes»). Maquetas de arcilla: un rombicuboctaedro (el
## cubo con las aristas y las esquinas cortadas: de frente, de costado y de arriba es un octógono) alrededor de los ojos
## del que maneja, con `RADIUS` del centro a sus caras, sin la cara de abajo (el hueco). Sus caras de adentro, todas a
## la misma distancia de los ojos, son los lugares de los controles. Tres maneras de unirla al domo:
##   1 · cerrada adentro de la caja, con su cara de adelante abierta a un túnel corto hasta la burbuja de siempre;
##   2 · el domo ES la cápsula: sale media por la cara de la caja y su mitad de adelante es de vidrio, facetada;
##   3 · la 2 con el vidrio liso (las normales de una esfera): las facetas casi no se notan.
## Cada una: cortada de costado, cortada de arriba (a la altura de los ojos) y de afuera.
##   tools/godot_ventana.sh res://tests/pod_facets_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const BOX := Vector3(2.0, 1.84, 2.0)
const RADIUS := 0.75
## Los ojos sobre el piso de la caja.
const EYE_Y := 1.2
const OPTIONS := [
	"1 · cerrada adentro, túnel hasta la burbuja",
	"2 · el domo es la cápsula: media afuera, de vidrio facetado",
	"3 · la 2 con el vidrio liso",
]
const SHELL := Color(0.6, 0.61, 0.63)
const INSIDE := Color(0.72, 0.72, 0.7)
const GLASS := Color(0.62, 0.8, 0.92, 0.35)
const DARK := Color(0.28, 0.29, 0.32)
const BODY := Color(0.85, 0.55, 0.35)
const RED := Color(0.8, 0.2, 0.15)
const YELLOW := Color(0.95, 0.75, 0.15)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	for index in OPTIONS.size():
		var root := Node3D.new()
		root.position = Vector3(0.0, 0.0, index * 40.0)
		add_child(root)
		_build(root, index + 1)
	for index in OPTIONS.size():
		var at := Vector3(0.0, 0.0, index * 40.0)
		var center := at + _center(index + 1)
		_title.text = OPTIONS[index]
		var shots: Array[Image] = []
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.size = 2.8
		_eye.near = 10.0 - 0.02
		shots.append(await _view(center + Vector3(10.0, 0.0, 0.0), center, Vector3.UP))
		_eye.near = 10.0 - 0.05
		shots.append(await _view(center + Vector3(0.0, 10.0, 0.0), center, Vector3.FORWARD))
		_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		_eye.fov = 45.0
		_eye.near = 0.05
		shots.append(await _view(at + Vector3(-3.2, 2.6, -4.2), at + Vector3(0.0, 0.9, -0.4), Vector3.UP))
		_save(shots, index + 1)
	get_tree().quit()


## El centro de la cápsula (los ojos), desde el centro del piso de la caja.
func _center(kind: int) -> Vector3:
	return Vector3(0.0, EYE_Y, 0.1 if kind == 1 else -BOX.z * 0.5)


func _build(root: Node3D, kind: int) -> void:
	var center := _center(kind)
	_box(root, kind, center)
	# La cápsula: sin la cara de abajo; en la 1, sin la de adelante (el túnel); en la 2 y la 3, lo de adelante de la cara
	# de la caja, de vidrio.
	var opaque := SurfaceTool.new()
	opaque.begin(Mesh.PRIMITIVE_TRIANGLES)
	var clear := SurfaceTool.new()
	clear.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Dictionary in _faces():
		var normal: Vector3 = face["normal"]
		if normal.is_equal_approx(Vector3.DOWN):
			continue
		if kind == 1 and normal.is_equal_approx(Vector3.FORWARD):
			continue
		var points: Array = []
		for p: Vector3 in face["points"]:
			points.append(center + p * RADIUS)
		var glassy := kind != 1 and normal.z < -0.3
		if glassy and kind == 3:
			_smooth_face(clear, points, center)
		else:
			CageMesh.face(clear if glassy else opaque, points, normal)
		if not glassy:
			_controls(root, face, center)
	_mesh(root, opaque, INSIDE)
	if kind != 1:
		_mesh(root, clear, GLASS)
	else:
		# El túnel hasta la cara de la caja, del tamaño de la cara de adelante, y la burbuja.
		var half := RADIUS / (1.0 + sqrt(2.0))
		var from := center.z - RADIUS
		var to := -BOX.z * 0.5
		var tunnel := SurfaceTool.new()
		tunnel.begin(Mesh.PRIMITIVE_TRIANGLES)
		for side: Vector3 in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT]:
			var across := Vector3(side.y, side.x, 0.0)
			var a := Vector3(center.x, center.y, 0.0) + side * half
			CageMesh.face(tunnel, [a - across * half + Vector3(0, 0, from), a + across * half + Vector3(0, 0, from),
				a + across * half + Vector3(0, 0, to), a - across * half + Vector3(0, 0, to)], -side)
		_mesh(root, tunnel, INSIDE)
		var glass := SurfaceTool.new()
		glass.begin(Mesh.PRIMITIVE_TRIANGLES)
		CageMesh.sphere_band(glass, Vector3(0.0, center.y, to), half * 1.35, 0.0, PI * 0.5, false)
		_mesh(root, glass, GLASS)
	_seated(root, center)


## LA CAJA de siempre, hueca; con el agujero de adelante donde corresponda.
func _box(root: Node3D, kind: int, center: Vector3) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := BOX * 0.5
	var middle := Vector3(0.0, half.y, 0.0)
	for normal: Vector3 in [Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN]:
		var u := Vector3(normal.y, normal.z, normal.x)
		var v := normal.cross(u)
		var m := middle + normal * half
		u *= half
		v *= half
		CageMesh.face(tool, [m - u - v, m + u - v, m + u + v, m - u + v], normal)
	var hole := RADIUS / (1.0 + sqrt(2.0)) * 1.35 if kind == 1 else RADIUS
	CageMesh.fill_to_rect(tool, CageMesh.polygon(hole, 32), Vector2(-half.x, -center.y), Vector2(half.x, BOX.y - center.y),
		func(p: Vector2) -> Vector3: return Vector3(p.x, center.y + p.y, -half.z), Vector3.FORWARD)
	_mesh(root, tool, SHELL)


## LAS CARAS DEL ROMBICUBOCTAEDRO de inradio 1 en las caras cuadradas: sus normales (6 de los ejes, 12 de las aristas, 8
## de las esquinas) y sus vértices en orden.
func _faces() -> Array[Dictionary]:
	var k := 1.0 + sqrt(2.0)
	var vertices: Array[Vector3] = []
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			for c: float in [-k, k]:
				vertices.append(Vector3(a, b, c) / k)
				vertices.append(Vector3(a, c, b) / k)
				vertices.append(Vector3(c, a, b) / k)
	var normals: Array[Vector3] = []
	for axis: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		normals.append(axis)
		normals.append(-axis)
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			normals.append(Vector3(a, b, 0.0).normalized())
			normals.append(Vector3(a, 0.0, b).normalized())
			normals.append(Vector3(0.0, a, b).normalized())
			for c: float in [-1.0, 1.0]:
				normals.append(Vector3(a, b, c).normalized())
	var faces: Array[Dictionary] = []
	for normal in normals:
		var best := -INF
		for v in vertices:
			best = maxf(best, v.dot(normal))
		var on: Array[Vector3] = []
		for v in vertices:
			if v.dot(normal) > best - 0.001:
				on.append(v)
		var middle := Vector3.ZERO
		for v in on:
			middle += v / on.size()
		var u := (on[0] - middle).normalized()
		var w := normal.cross(u)
		on.sort_custom(func(p: Vector3, q: Vector3) -> bool:
			return atan2((p - middle).dot(w), (p - middle).dot(u)) < atan2((q - middle).dot(w), (q - middle).dot(u)))
		faces.append({"normal": normal, "points": on})
	return faces


## Una cara del vidrio, con las normales de una esfera (liso).
func _smooth_face(tool: SurfaceTool, points: Array, center: Vector3) -> void:
	for i in range(1, points.size() - 1):
		for p: Vector3 in [points[0], points[i], points[i + 1]]:
			tool.set_normal((p - center).normalized())
			tool.add_vertex(p)


## Unos controles en una cara de adentro (las que quedan a mano: no las de arriba ni las de atrás).
func _controls(root: Node3D, face: Dictionary, center: Vector3) -> void:
	var normal: Vector3 = face["normal"]
	if normal.y > 0.5 or normal.z > 0.3 or (face["points"] as Array).size() < 4:
		return
	var middle := Vector3.ZERO
	for p: Vector3 in face["points"]:
		middle += p / (face["points"] as Array).size()
	var at := center + middle * RADIUS * 0.97
	var inward := -normal
	var up := Vector3.UP if absf(inward.y) < 0.9 else Vector3.BACK
	var plate := Node3D.new()
	plate.transform = Transform3D(Basis.looking_at(-inward, up), at)
	root.add_child(plate)
	Clay.box(plate, Vector3(0.22, 0.16, 0.03), Vector3.ZERO, DARK)
	Clay.sphere(plate, 0.03, Vector3(-0.05, 0.03, -0.03), RED)
	Clay.sphere(plate, 0.03, Vector3(0.05, -0.03, -0.03), YELLOW)


## EL QUE MANEJA: los ojos en el centro; la silla sale por el hueco de abajo y las piernas cuelgan.
func _seated(root: Node3D, eye: Vector3) -> void:
	var pelvis := eye + Vector3(0.0, -0.8, 0.12)
	Clay.box(root, Vector3(0.46, 0.06, 0.46), pelvis + Vector3(0.0, -0.1, -0.04), DARK)
	Clay.box(root, Vector3(0.46, 0.55, 0.06), pelvis + Vector3(0.0, 0.22, 0.2), DARK)
	Clay.cylinder(root, 0.05, pelvis.y - 0.1, Vector3(0.0, (pelvis.y - 0.1) * 0.5, pelvis.z - 0.04), DARK)
	_limb(root, pelvis, eye + Vector3(0.0, -0.22, 0.1), 0.15)
	Clay.sphere(root, 0.12, eye + Vector3(0.0, 0.0, 0.05), BODY)
	for s: float in [-1.0, 1.0]:
		var knee := pelvis + Vector3(s * 0.12, 0.0, -0.42)
		_limb(root, pelvis + Vector3(s * 0.11, 0.0, 0.0), knee, 0.07)
		_limb(root, knee, knee + Vector3(0.0, -0.46, 0.06), 0.06)
		var elbow := eye + Vector3(s * 0.28, -0.52, -0.08)
		_limb(root, eye + Vector3(s * 0.2, -0.3, 0.08), elbow, 0.05)
		_limb(root, elbow, eye + Vector3(s * 0.36, -0.42, -0.4), 0.045)


func _limb(root: Node3D, a: Vector3, b: Vector3, radius: float) -> void:
	var holder := Clay.limb(root, radius, a.distance_to(b), Vector3.ZERO, BODY)
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
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -140.0, 0.0)
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.82, 0.86, 0.9)
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
	_title.add_theme_font_size_override("font_size", 34)
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
	var path := "%s/facetas_%d.png" % [_folder, number]
	sheet.save_png(path)
	print("CAPTURA ", path)
