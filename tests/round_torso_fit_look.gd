extends Node

## LA REDONDA: CÓMO ENCAJAN LOS MÓDULOS EN EL CUERPO (17/11/2026, el usuario: «la versión esférica, con cuerpo de cubo
## chanfleado, cápsula de cubo chanfleado alargada, la de abajo, como ya la tenemos en el juego ahora, y arriba una sección
## cilíndrica con el hueco octogonal, pero que encaje con el cuerpo de una manera satisfactoria… el cuerpo es como la glue
## en términos de geometría, en la que podés aumentar su tamaño para que los otros módulos encajen bien»). La cápsula y el
## módulo de arriba son los de hoy y no cambian; cambia el cuerpo:
##   1 · a la medida del octógono de arriba: el octógono apoya entero en la cara de arriba; la cápsula, con su marco, en
##       la de adelante, que le queda grande.
##   2 · a la medida de la cápsula con su marco: el marco llega justo al borde de la cara de adelante; el octógono es más
##       ancho que la cara de arriba y sale de adentro del cuerpo.
##   3 · al medio de las dos.
##   4 · más cuadrado: el mismo octógono apoyado, con el chanfle a la mitad (un cubo de esquinas cortadas, más chico).
##   5 y 6 · la 1 para 1 y para 2 jugadores (la 1 es para 3).
## Y la cuadrada para 3, de referencia. Todas sobre las piernas y los brazos de la meca jaula, de afuera.
##   tools/godot_ventana.sh res://tests/round_torso_fit_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const SPACING := 34.0
const SHELL := Color(0.6, 0.61, 0.63)
const DARK := Color(0.22, 0.23, 0.25)
const DESK := Color(0.45, 0.47, 0.5)
const RIM := Color(0.3, 0.31, 0.33)
const GLASS := Color(0.55, 0.74, 0.7)
const METAL := Color(0.5, 0.52, 0.56)
## Lo que el octógono de arriba tiene de pared alrededor del pozo (m).
const WALL := 0.15
## Lo que se corta del triángulo de la esquina en un cubo chanfleado uniforme (el rombicuboctaedro), en apotemas.
const CORNER_UNIFORM := 1.0557

## Cada maqueta: [nombre, talle (0 cápsula … 1 octógono), chanfle (0 uniforme … 1 cubo), jugadores]; el talle −1 es la
## cuadrada.
const PLAN := [
	["cuerpo a la medida del octógono de arriba", 1.0, 0.0, 3],
	["cuerpo a la medida de la cápsula con su marco", 0.0, 0.0, 3],
	["cuerpo al medio", 0.5, 0.0, 3],
	["más cuadrado, a la medida del octógono", 1.0, 0.5, 3],
	["la 1 para 1 jugador", 1.0, 0.0, 1],
	["la 1 para 2 jugadores", 1.0, 0.0, 2],
	["la cuadrada para 3, de referencia", -1.0, 0.0, 3],
]

var _folder := ""
var _eye: Camera3D = null
var _shots: Array[Image] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	var form := CageCabin.shape()
	var padding := form.padding
	var forward := form.shoulder_forward
	var mechs: Array[CageMech] = []
	for index in PLAN.size():
		var entry: Array = PLAN[index]
		if entry[1] >= 0.0:
			# Los hombros, al medio de los costados del cuerpo (CageShape.side): se leen al armar los brazos.
			form.padding = _half(entry[1], entry[2]) - form.capsule_radius()
			form.shoulder_forward = 0.0
		var mech := CageMech.new()
		mech.equipment = "Meca jaula"
		mech.scripted = true
		mech.position = Vector3(-index * SPACING, Mech.standing_height(mech.cabin_shape), 0.0)
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
		var entry: Array = PLAN[index]
		if entry[1] < 0.0:
			_square(clay)
		else:
			_round(clay, entry[1], entry[2], entry[3])
	await get_tree().create_timer(0.6).timeout
	for index in mechs.size():
		var entry: Array = PLAN[index]
		var high := 2.0 * (_half(entry[1], entry[2]) if entry[1] >= 0.0 else 1.4)
		var at := mechs[index].global_position + Vector3(0.0, CageCabin.bottom() + high * 0.45, 0.0)
		var far := 11.0 + high * 1.6
		await _shot(at + Vector3(0.0, 1.0, -far), at, 40.0)
		await _shot(at + Vector3(far, 1.0, 0.0), at, 40.0)
		await _shot(at + Vector3(-far * 0.4, far * 0.95, -far * 0.45), at + Vector3(0.0, high * 0.3, 0.0), 40.0)
	_save()
	get_tree().quit()


## ── LAS MEDIDAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## El apotema del octógono de arriba: el borde del tablero de hoy y su pared.
static func _octagon() -> float:
	return CageCabin.pit_of(CageCabin.shape()).rim() + WALL


## La mitad del ancho de la cara de arriba (y de adelante) de un cuerpo de mitad `half` y chanfle `chamfer`: donde la
## corta el chanfle de la arista.
static func _face_half(half: float, chamfer: float) -> float:
	return half * (sqrt(2.0) * lerpf(1.0, sqrt(2.0), chamfer) - 1.0)


## La cápsula con su marco, de mitad: hasta el borde de afuera del marco (CageMesh.outline_ring lo corre hacia afuera por
## las puntas del octógono).
static func _framed() -> float:
	var form := CageCabin.shape()
	return form.capsule_radius() + form.rim_width * cos(PI / 8.0)


## LA MITAD DEL CUERPO para que su cara mida, de mitad, lo de la cápsula con su marco (talle 0) o lo del octógono (talle 1).
static func _half(size: float, chamfer: float) -> float:
	var wanted := lerpf(_framed(), _octagon(), size)
	return wanted / (sqrt(2.0) * lerpf(1.0, sqrt(2.0), chamfer) - 1.0)


## ── LA REDONDA ────────────────────────────────────────────────────────────────────────────────────────────────────

func _round(at: Node3D, size: float, chamfer: float, players: int) -> void:
	var form := CageCabin.shape()
	var r := form.capsule_radius()
	var half := _half(size, chamfer)
	var center := Vector3(0.0, half, 0.0)
	_solid(at, _body(center, half, chamfer), SHELL)
	# LA CÁPSULA DE HOY, alargada hacia atrás: el cinturón empieza en la cara de adelante y el domo sobresale entero; su
	# marco, en la cara.
	_dome(at, center + Vector3(0.0, 0.0, -half + r / (1.0 + sqrt(2.0))), -half)
	var top := center.y + half
	if players == 1:
		_lone_gun(at, Vector3(0.0, top, half * 0.35))
		return
	# EL MÓDULO DE ARRIBA: el octógono con el pozo de hoy. Apoya en la cara de arriba; si es más ancho que ella, sale de
	# más abajo, de donde el cuerpo ya lo cubre (el chanfle de la arista).
	var apothem := _octagon()
	var face_half := _face_half(half, chamfer)
	var base := top
	if apothem > face_half:
		base = center.y + half * sqrt(2.0) * lerpf(1.0, sqrt(2.0), chamfer) - apothem
	var pit := CageCabin.pit_of(form)
	var floor_y := top
	var rim_y := floor_y + pit.top()
	_prism(at, apothem, pit.rim(), base, rim_y)
	_pit(at, floor_y)
	if players == 3:
		var wide := form.tower_wide()
		var deep := form.tower_deep()
		var up := CageCabin.tower_top(form)
		var z := apothem - deep * 0.5
		Clay.box(at, Vector3(wide, up, deep), Vector3(0.0, floor_y + up * 0.5, z), SHELL)
		_turret(at, Vector3(0.0, floor_y + up, z))


## ── LA CUADRADA (la de hoy, por partes) ───────────────────────────────────────────────────────────────────────────

func _square(at: Node3D) -> void:
	var form := CageCabin.shape()
	var side := form.side()
	var tall := form.height()
	Clay.box(at, Vector3(side, tall, side), Vector3(0.0, tall * 0.5, 0.0), SHELL)
	_dome(at, CageCabin.bubble_center(form), -side * 0.5)
	var pit := CageCabin.pit_of(form)
	var block := MeshInstance3D.new()
	block.mesh = pit.mesh(SHELL)
	block.position = Vector3(0.0, tall, 0.0)
	at.add_child(block)
	var wide := form.tower_wide()
	var deep := form.tower_deep()
	var up := CageCabin.tower_top(form)
	Clay.box(at, Vector3(wide, up, deep), Vector3(0.0, tall + up * 0.5, side * 0.5 - deep * 0.5), SHELL)
	_turret(at, Vector3(0.0, tall + up, side * 0.5 - deep * 0.5))


## ── LAS PIEZAS ────────────────────────────────────────────────────────────────────────────────────────────────────

## EL CUERPO: un cubo de mitad `half` con las aristas y las esquinas cortadas (`chamfer` 0, el rombicuboctaedro: todas las
## caras cuadradas iguales; 1, el cubo). Cada cara, su plano recortado por los demás.
static func _body(center: Vector3, half: float, chamfer: float) -> Array:
	var planes: Array = []
	for axis: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		planes.append([axis, half])
		planes.append([-axis, half])
	var edge := half * lerpf(1.0, sqrt(2.0), chamfer)
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			for normal: Vector3 in [Vector3(a, b, 0.0), Vector3(a, 0.0, b), Vector3(0.0, a, b)]:
				planes.append([normal.normalized(), edge])
	var corner := half * lerpf(CORNER_UNIFORM, sqrt(3.0), chamfer)
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			for c: float in [-1.0, 1.0]:
				planes.append([Vector3(a, b, c).normalized(), corner])
	var out: Array = []
	for i in planes.size():
		var normal: Vector3 = planes[i][0]
		var u := normal.cross(Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT).normalized()
		var w := normal.cross(u)
		var big := half * 10.0
		var origin: Vector3 = normal * planes[i][1]
		var points: Array = [origin + (u + w) * big, origin + (u - w) * big, origin + (-u - w) * big, origin + (-u + w) * big]
		for j in planes.size():
			if j != i:
				points = _clip(points, planes[j][0], planes[j][1])
			if points.size() < 3:
				break
		if points.size() >= 3:
			var moved: Array = []
			for p: Vector3 in points:
				moved.append(center + p)
			out.append({"points": moved, "normal": normal})
	return out


## Lo de `points` que queda del lado de adentro del plano (normal · p ≤ distancia).
static func _clip(points: Array, normal: Vector3, distance: float) -> Array:
	var out: Array = []
	for i in points.size():
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i + 1) % points.size()]
		var da := normal.dot(a) - distance
		var db := normal.dot(b) - distance
		if da <= 1e-5:
			out.append(a)
		if (da <= 1e-5) != (db <= 1e-5):
			out.append(a.lerp(b, da / (da - db)))
	return out


## EL OCTÓGONO DE ARRIBA: de apotema `outer`, de `from` a `to`, con la boca del pozo (apotema `inner`) arriba.
func _prism(at: Node3D, outer: float, inner: float, from: float, to: float) -> void:
	var out_ring := CageMesh.polygon(outer / cos(PI / 8.0), 8, -PI * 0.5 - PI / 8.0)
	var in_ring := CageMesh.polygon(inner / cos(PI / 8.0), 8, -PI * 0.5 - PI / 8.0)
	var faces: Array = []
	for k in 8:
		var a := out_ring[k]
		var b := out_ring[(k + 1) % 8]
		var normal := Vector3((a.x + b.x) * 0.5, 0.0, (a.y + b.y) * 0.5).normalized()
		faces.append({"points": [Vector3(a.x, from, a.y), Vector3(b.x, from, b.y), Vector3(b.x, to, b.y), Vector3(a.x, to, a.y)],
			"normal": normal})
		var c := in_ring[(k + 1) % 8]
		var d := in_ring[k]
		faces.append({"points": [Vector3(a.x, to, a.y), Vector3(b.x, to, b.y), Vector3(c.x, to, c.y), Vector3(d.x, to, d.y)],
			"normal": Vector3.UP})
	_solid(at, faces, SHELL)


## EL POZO DE HOY adentro del octógono, con su piso en `floor_y`: el tablero de ocho trapecios y la pared.
func _pit(at: Node3D, floor_y: float) -> void:
	var pit := CageCabin.pit_of(CageCabin.shape())
	var inner := DeskPit._octagon(pit.radius)
	var outer := DeskPit._octagon(pit.rim())
	var low := pit.low()
	var high := pit.top()
	var desk: Array = []
	var walls: Array = [{"points": Array(inner).map(func(p: Vector2) -> Vector3: return Vector3(p.x, floor_y + 0.01, p.y)),
		"normal": Vector3.UP}]
	for k in 8:
		var j := (k + 1) % 8
		var middle := Vector3((inner[k].x + inner[j].x) * 0.5, 0.0, (inner[k].y + inner[j].y) * 0.5)
		walls.append({"points": [Vector3(inner[k].x, floor_y, inner[k].y), Vector3(inner[j].x, floor_y, inner[j].y),
			Vector3(inner[j].x, floor_y + low, inner[j].y), Vector3(inner[k].x, floor_y + low, inner[k].y)],
			"normal": -middle.normalized()})
		desk.append({"points": [Vector3(inner[k].x, floor_y + low, inner[k].y), Vector3(inner[j].x, floor_y + low, inner[j].y),
			Vector3(outer[j].x, floor_y + high, outer[j].y), Vector3(outer[k].x, floor_y + high, outer[k].y)],
			"normal": (Vector3.UP - middle.normalized()).normalized()})
	_solid(at, walls, DARK)
	_solid(at, desk, DESK)


## EL DOMO de la cápsula con centro en `capsule`, de vidrio y LISO (normales de esfera, como `glass_smooth` en la cabina;
## el usuario: «que la parte de vidrio… esté shading smooth… y el marquito»), y SU MARCO en la cara de adelante (en z =
## `face_z`), el de la cabina: el contorno del corte —el octógono del cinturón—, `rim_width` hacia afuera y `rim_depth`
## hacia adelante.
func _dome(at: Node3D, capsule: Vector3, face_z: float) -> void:
	var form := CageCabin.shape()
	var r := form.capsule_radius()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Dictionary in CageMesh.faceted_sphere():
		if (face["normal"] as Vector3).z < -0.1:
			var points: Array = []
			for p: Vector3 in face["points"]:
				points.append(capsule + p * r)
			CageMesh.smooth_face(tool, points, capsule, face["normal"])
	var glass := MeshInstance3D.new()
	glass.mesh = CageMesh.commit(tool, GLASS)
	at.add_child(glass)
	var ring := SurfaceTool.new()
	ring.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outline := CageMesh.polygon(r / cos(PI / 8.0), 8, PI / 8.0)
	CageMesh.outline_ring(ring, Vector3(capsule.x, capsule.y, face_z), outline, form.rim_width, form.rim_depth)
	var frame := MeshInstance3D.new()
	frame.mesh = CageMesh.commit(ring, RIM)
	at.add_child(frame)


func _turret(at: Node3D, base: Vector3) -> void:
	Clay.cylinder(at, 0.75, 0.12, base + Vector3(0.0, 0.06, 0.0), METAL)
	Clay.box(at, Vector3(0.5, 0.45, 0.5), base + Vector3(0.0, 0.35, 0.2), DARK)
	Clay.box(at, Vector3(0.5, 0.7, 0.12), base + Vector3(0.0, 0.6, 0.45), DARK)
	_gun(at, base + Vector3(0.0, 0.75, -0.35))


func _lone_gun(at: Node3D, base: Vector3) -> void:
	Clay.cylinder(at, 0.35, 0.1, base + Vector3(0.0, 0.05, 0.0), METAL)
	Clay.cylinder(at, 0.12, 0.45, base + Vector3(0.0, 0.3, 0.0), DARK)
	_gun(at, base + Vector3(0.0, 0.6, 0.0))


func _gun(at: Node3D, center: Vector3) -> void:
	Clay.box(at, Vector3(0.45, 0.35, 0.7), center, DARK)
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(at, 0.06, 0.9, center + Vector3(s * 0.12, 0.0, -0.75), METAL, Vector3(90.0, 0.0, 0.0))


func _solid(at: Node3D, faces: Array, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Dictionary in faces:
		CageMesh.face(tool, face["points"], face["normal"])
	var mesh := MeshInstance3D.new()
	mesh.mesh = CageMesh.commit(tool, color)
	at.add_child(mesh)


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
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
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


## Cada foto suelta: encaje_N_frente / _costado / _tres_cuartos.
func _save() -> void:
	for index in _shots.size():
		_shots[index].save_png("%s/encaje_%d_%s.png" % [_folder, index / 3 + 1, ["frente", "costado", "tres_cuartos"][index % 3]])
	print("CAPTURAS ", _shots.size())
