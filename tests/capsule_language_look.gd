extends Node

## UN SOLO IDIOMA PARA LAS DOS CÁPSULAS, EN ARCILLA (17/11/2026, el usuario: «la circularidad del de arriba… y la cápsula
## de abajo son como dos esferas distintas: una es un cubo chanfleado y la otra es todo compuesto de planos. Tal vez
## podríamos probar unificando todo: que el de arriba sean planos y triángulos, básicamente 4 planos usables o 3, y lo de
## abajo también cubo chanfleado, y que las dos cápsulas coincidan de más o menos tamaño… y la otra es hacer que las
## esferas sean con planos, como si fuera la de arriba pero hecha de esfera»). Tres idiomas para los dos puestos:
##   1 · HOY: abajo, la cápsula de cubo chanfleado (rombicuboctaedro); arriba, el pozo: la pared de ocho y el tablero de
##       ocho trapecios.
##   2 · TODO CUBO CHANFLEADO: arriba, la mitad de abajo de la MISMA cápsula (un tazón): cuatro cuadrados inclinados que
##       miran a los ojos —los tableros— y cuatro triángulos.
##   3 · TODO EN ANILLOS DE OCHO PLANOS: la cápsula de abajo hecha como el pozo de arriba —la misma silueta que el cubo
##       chanfleado, pero girada con ocho caras en cada anillo: ocho trapecios abajo, ocho cuadrados en el cinturón, ocho
##       trapecios arriba—; arriba, la mitad de abajo de esa misma (ocho trapecios inclinados).
## En 2 y 3 las dos cápsulas son del mismo tamaño. Cada idioma: los dos puestos cortados de costado, desde los ojos del que
## maneja y desde los del de los brazos. Y afuera, las mecas jaula para 3 con cada idioma: la cuadrada y la redonda (el
## cuerpo a la medida de la cápsula, que con el mismo tamaño arriba y abajo calza en las dos caras).
##   tools/godot_ventana.sh res://tests/capsule_language_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const LANGUAGES := ["hoy", "todo cubo chanfleado", "todo en anillos de ocho planos"]
const SHELL := Color(0.6, 0.61, 0.63)
const INSIDE := Color(0.42, 0.43, 0.46)
const DESK := Color(0.56, 0.62, 0.5)
const DARK := Color(0.22, 0.23, 0.25)
const GLASS := Color(0.55, 0.74, 0.7)
const METAL := Color(0.5, 0.52, 0.56)
## Dónde van las maquetas de adentro, lejos de las mecas.
const STATIONS_Z := -90.0
const STATIONS_SPACING := 8.0
const MECH_SPACING := 16.0

var _folder := ""
var _eye: Camera3D = null
var _shots: Array[Image] = []
var _materials := {}


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	var form := CageCabin.shape()
	var r := form.capsule_radius()
	# Del ojo del que maneja al del de los brazos: lo de hoy.
	var rise := form.height() + form.arms_eye - form.bubble_y()
	# ── ADENTRO: los dos puestos de cada idioma, sin cuerpo (cada foto muestra sólo los suyos) ──
	var holders: Array[Node3D] = []
	for index in LANGUAGES.size():
		var at := Vector3(index * STATIONS_SPACING, 2.0, STATIONS_Z)
		for cut in [false, true]:
			var holder := Node3D.new()
			holder.name = "puestos_%d_%s" % [index, "cortados" if cut else "enteros"]
			holder.position = at + (Vector3(0.0, 0.0, 20.0) if cut else Vector3.ZERO)
			add_child(holder)
			holders.append(holder)
			_stations(holder, index, r, rise, cut)
	# ── AFUERA: las mecas para 3 con cada idioma, la cuadrada y la redonda ──
	var padding := form.padding
	var forward := form.shoulder_forward
	var mechs: Array[CageMech] = []
	var plan: Array = []
	for language in [1, 2]:
		for is_round in [false, true]:
			plan.append([language, is_round])
	for index in plan.size():
		var is_round: bool = plan[index][1]
		if is_round:
			form.padding = r * (1.0 + sqrt(2.0)) - r
			form.shoulder_forward = 0.0
		var mech := CageMech.new()
		mech.equipment = "Meca jaula"
		mech.scripted = true
		mech.position = Vector3(-index * MECH_SPACING, Mech.standing_height(mech.cabin_shape), 0.0)
		add_child(mech)
		mechs.append(mech)
		form.padding = padding
		form.shoulder_forward = forward
	await get_tree().create_timer(1.2).timeout
	for index in mechs.size():
		var cabin := mechs[index].cabin as CageCabin
		for seat in CageCabin.SEAT_NAMES.size():
			cabin.evict(seat)
		cabin.board_root().visible = false
		for label in mechs[index].find_children("*", "Label3D", true, false):
			(label as Label3D).visible = false
		var clay := Node3D.new()
		clay.position = Vector3(0.0, CageCabin.bottom(), 0.0)
		cabin.add_child(clay)
		_outside(clay, plan[index][0], plan[index][1], r)
	await get_tree().create_timer(0.6).timeout
	# Las fotos de adentro: cortados de costado; desde los ojos del que maneja; desde los del de los brazos.
	for index in LANGUAGES.size():
		var at := Vector3(index * STATIONS_SPACING, 2.0, STATIONS_Z)
		var cut_at := at + Vector3(0.0, rise * 0.5, 20.0)
		for i in holders.size():
			holders[i].visible = i == index * 2 + 1
		await _shot(cut_at + Vector3(6.0, 0.4, 0.0), cut_at, 40.0)
		for i in holders.size():
			holders[i].visible = i == index * 2
		await _shot(at + Vector3(0.0, 0.05, 0.3), at + Vector3(0.75, -0.3, -0.6), 95.0)
		var arms := at + Vector3(0.0, rise, 0.0)
		await _shot(arms + Vector3(0.0, 0.15, 0.35), arms + Vector3(0.0, -0.9, -0.8), 95.0)
	for holder in holders:
		holder.visible = false
	# Las de afuera: de frente y de tres cuartos.
	for mech in mechs:
		var look := mech.global_position + Vector3(0.0, 1.6, 0.0)
		await _shot(look + Vector3(0.0, 1.0, -16.0), look, 40.0)
		await _shot(look + Vector3(-9.5, 6.0, -10.5), look, 42.0)
	_save()
	get_tree().quit()


## ── LAS CÁPSULAS ─────────────────────────────────────────────────────────────────────────────────────────────────

## LAS CARAS DEL CUBO CHANFLEADO (CageMesh.faceted_sphere) de `radius` en `center`: [{points, normal}].
static func _chamfered(center: Vector3, radius: float) -> Array:
	var out: Array = []
	for face: Dictionary in CageMesh.faceted_sphere():
		var points: Array = []
		for p: Vector3 in face["points"]:
			points.append(center + p * radius)
		out.append({"points": points, "normal": face["normal"]})
	return out


## LAS CARAS DE LA ESFERA EN ANILLOS DE OCHO de `radius` (apotema) en `center`: el perfil del cubo chanfleado (el fondo,
## el anillo de abajo, el cinturón, el de arriba y la tapa) girado con ocho caras por anillo, una mirando al frente.
static func _rings(center: Vector3, radius: float) -> Array:
	var half := radius / (1.0 + sqrt(2.0))
	# El perfil: (apotema del octógono, alto), de abajo arriba.
	var profile: Array[Vector2] = [Vector2(half, -radius), Vector2(radius, -half), Vector2(radius, half),
		Vector2(half, radius)]
	var out: Array = []
	var rings: Array = []
	for step: Vector2 in profile:
		var ring: Array = []
		for p: Vector2 in CageMesh.polygon(step.x / cos(PI / 8.0), 8, -PI * 0.5 - PI / 8.0):
			ring.append(center + Vector3(p.x, step.y, p.y))
		rings.append(ring)
	out.append({"points": rings[0].duplicate(), "normal": Vector3.DOWN})
	for band in 3:
		for k in 8:
			var j := (k + 1) % 8
			var points: Array = [rings[band][k], rings[band][j], rings[band + 1][j], rings[band + 1][k]]
			var middle := Vector3.ZERO
			for p: Vector3 in points:
				middle += p / 4.0
			var normal := ((points[1] - points[0]) as Vector3).cross((points[3] - points[0]) as Vector3).normalized()
			if normal.dot(middle - center) < 0.0:
				normal = -normal
			out.append({"points": points, "normal": normal})
	out.append({"points": rings[3].duplicate(), "normal": Vector3.UP})
	return out


## EL POZO DE HOY (DeskPit), con el piso en `floor_at`: la pared de ocho y el tablero de ocho trapecios.
static func _pit(floor_at: Vector3) -> Array:
	var pit := CageCabin.pit_of(CageCabin.shape())
	var inner := DeskPit._octagon(pit.radius)
	var outer := DeskPit._octagon(pit.rim())
	var low := pit.low()
	var high := pit.top()
	var out: Array = []
	for k in 8:
		var j := (k + 1) % 8
		var middle := Vector3((inner[k].x + inner[j].x) * 0.5, 0.0, (inner[k].y + inner[j].y) * 0.5)
		out.append({"points": [floor_at + Vector3(inner[k].x, 0.0, inner[k].y), floor_at + Vector3(inner[j].x, 0.0, inner[j].y),
			floor_at + Vector3(inner[j].x, low, inner[j].y), floor_at + Vector3(inner[k].x, low, inner[k].y)],
			"normal": middle.normalized(), "desk": false})
		out.append({"points": [floor_at + Vector3(inner[k].x, low, inner[k].y), floor_at + Vector3(inner[j].x, low, inner[j].y),
			floor_at + Vector3(outer[j].x, high, outer[j].y), floor_at + Vector3(outer[k].x, high, outer[k].y)],
			"normal": (middle.normalized() + Vector3.DOWN).normalized(), "desk": true})
	return out


## LOS DOS PUESTOS del idioma `language` en `at`, con el ojo del que maneja en el origen y el del de los brazos `rise`
## arriba; `cut`, sin la mitad de +x (para verlos de costado).
func _stations(at: Node3D, language: int, r: float, rise: float, cut: bool) -> void:
	var lower := _rings(Vector3.ZERO, r) if language == 2 else _chamfered(Vector3.ZERO, r)
	var upper_center := Vector3(0.0, rise, 0.0)
	var upper: Array = []
	match language:
		0:
			var form := CageCabin.shape()
			upper = _pit(Vector3(0.0, form.height() - form.bubble_y(), 0.0))
		1:
			upper = _chamfered(upper_center, r)
		2:
			upper = _rings(upper_center, r)
	var glass := SurfaceTool.new()
	glass.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall := SurfaceTool.new()
	wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	var desk := SurfaceTool.new()
	desk.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Abajo: el domo de vidrio; lo opaco que no es triángulo ni mira al piso, tablero (verde; ver CageCabin.capsule_boards).
	for face: Dictionary in lower:
		var normal: Vector3 = face["normal"]
		if normal.is_equal_approx(Vector3.DOWN) or (cut and _right_half(face["points"])):
			continue
		var board: bool = (face["points"] as Array).size() >= 4 and normal.y > -0.5
		CageMesh.face(glass if normal.z < -0.1 else (desk if board else wall), face["points"], normal)
	for face: Dictionary in upper:
		var normal: Vector3 = face["normal"]
		if cut and _right_half(face["points"]):
			continue
		if language == 0:
			CageMesh.face(desk if face["desk"] else wall, face["points"], normal)
			continue
		# EL TAZÓN: la mitad de abajo de la cápsula, sin el fondo (por ahí sube la silla); lo que mira a los ojos desde
		# abajo y a los costados es tablero (los cuadrados inclinados del cubo chanfleado, los trapecios de los anillos).
		if normal.y > -0.1 or normal.is_equal_approx(Vector3.DOWN):
			continue
		var square: bool = (face["points"] as Array).size() == 4
		CageMesh.face(desk if square else wall, face["points"], normal)
	for pair: Array in [[glass, Color(GLASS, 0.25)], [wall, INSIDE], [desk, DESK]]:
		var mesh := MeshInstance3D.new()
		mesh.mesh = (pair[0] as SurfaceTool).commit()
		mesh.material_override = _both_sides(pair[1])
		at.add_child(mesh)
	# Los ojos, de referencia (sólo en los cortados: en los otros, la cámara está ahí).
	if cut:
		Clay.sphere(at, 0.06, Vector3.ZERO, Color(0.85, 0.4, 0.3))
		Clay.sphere(at, 0.06, upper_center, Color(0.85, 0.4, 0.3))


static func _right_half(points: Array) -> bool:
	var middle := Vector3.ZERO
	for p: Vector3 in points:
		middle += p / points.size()
	return middle.x > 0.02


## ── AFUERA: la meca para 3 con el idioma `language` (1 cubo chanfleado, 2 anillos de ocho), cuadrada o redonda ──────

func _outside(at: Node3D, language: int, is_round: bool, r: float) -> void:
	var form := CageCabin.shape()
	var faces := func(center: Vector3, radius: float) -> Array:
		return _rings(center, radius) if language == 2 else _chamfered(center, radius)
	var capsule_center: Vector3
	var top: float
	var gunner_back: float
	if is_round:
		# El cuerpo a la medida de la cápsula: su cara de adelante y la de arriba son tan anchas como ella.
		var body := r * (1.0 + sqrt(2.0))
		var center := Vector3(0.0, body, 0.0)
		_solid(at, faces.call(center, body), SHELL)
		capsule_center = center + Vector3(0.0, 0.0, -body + r / (1.0 + sqrt(2.0)))
		top = center.y + body
		gunner_back = body * 0.55
	else:
		var side := form.side()
		var tall := form.height()
		Clay.box(at, Vector3(side, tall, side), Vector3(0.0, tall * 0.5, 0.0), SHELL)
		capsule_center = CageCabin.bubble_center(form)
		var high := CageCabin.pit_of(form).top()
		Clay.box(at, Vector3(side, high, side), Vector3(0.0, tall + high * 0.5, 0.0), SHELL)
		top = tall + high
		gunner_back = side * 0.32
	# La cápsula de abajo: lo que sobresale es el domo, de vidrio.
	var dome: Array = []
	for face: Dictionary in faces.call(capsule_center, r):
		if (face["normal"] as Vector3).z < -0.1:
			dome.append(face)
	_solid(at, dome, GLASS)
	# El tazón de arriba, visto de afuera: la boca, oscura, en lo alto (un octógono del ancho de la cápsula: la vuelta de
	# arriba del tazón, en los dos idiomas).
	var mouth: Array = []
	for p: Vector2 in CageMesh.polygon(r * 0.95 / cos(PI / 8.0), 8, -PI * 0.5 - PI / 8.0):
		mouth.append(Vector3(p.x, top + 0.02, p.y))
	_solid(at, [{"points": mouth, "normal": Vector3.UP}], DARK)
	# El artillero, atrás: una columna con el plato y el arma.
	var up := 1.4
	var base := Vector3(0.0, top - 0.3, gunner_back)
	Clay.cylinder(at, 0.42, up + 0.3, base + Vector3(0.0, (up + 0.3) * 0.5, 0.0), SHELL)
	var plate := base + Vector3(0.0, up + 0.3, 0.0)
	Clay.cylinder(at, 0.75, 0.12, plate + Vector3(0.0, 0.06, 0.0), METAL)
	Clay.box(at, Vector3(0.5, 0.45, 0.5), plate + Vector3(0.0, 0.35, 0.2), DARK)
	Clay.box(at, Vector3(0.45, 0.35, 0.7), plate + Vector3(0.0, 0.75, -0.35), DARK)
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(at, 0.06, 0.9, plate + Vector3(s * 0.12, 0.75, -1.1), METAL, Vector3(90.0, 0.0, 0.0))


func _solid(at: Node3D, faces: Array, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Dictionary in faces:
		CageMesh.face(tool, face["points"], face["normal"])
	var mesh := MeshInstance3D.new()
	mesh.mesh = CageMesh.commit(tool, color)
	at.add_child(mesh)


func _both_sides(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var made := StandardMaterial3D.new()
		made.albedo_color = color
		made.roughness = 0.85
		made.cull_mode = BaseMaterial3D.CULL_DISABLED
		if color.a < 1.0:
			made.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materials[color] = made
	return _materials[color]


func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 215.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	_eye.near = 0.02
	add_child(_eye)
	_eye.make_current()


func _shot(from: Vector3, to: Vector3, fov: float) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(VIEW.x / 2, VIEW.y / 2, Image.INTERPOLATE_BILINEAR)
	_shots.append(image)


## Las fotos sueltas: idioma_N_cortados / _abajo / _arriba, y afuera_N_frente / _tres_cuartos.
func _save() -> void:
	var names: Array[String] = []
	for index in LANGUAGES.size():
		for view in ["cortados", "abajo", "arriba"]:
			names.append("idioma_%d_%s" % [index + 1, view])
	for index in 4:
		for view in ["frente", "tres_cuartos"]:
			names.append("afuera_%d_%s" % [index + 1, view])
	for index in mini(_shots.size(), names.size()):
		_shots[index].save_png("%s/%s.png" % [_folder, names[index]])
	print("CAPTURAS ", _shots.size())
