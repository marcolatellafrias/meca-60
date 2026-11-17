extends Node

## LAS SILUETAS DEL TORSO, EN ARCILLA (17/11/2026, el usuario: «con esta estructura básica le podemos dar 2 formas al
## cuerpo… una configuración de forma más cuadrada como la actual… otra posibilidad, que el cuerpo es como si fuera una
## esfera chanfleada también, y después tiene la cápsula metida al medio, obviamente más chica, y después arriba tiene
## como el octógono extruido hacia arriba»; y la meca de 1 a 3: «si estás jugando a 1, la meca sería solamente eso, sin la
## parte de arriba y sin la torreta… lo del artillero lo tendría, pero solamente las armas y en otro lugar»). Seis mecas
## jaula de verdad —las piernas, los brazos y la escala de hoy— con el torso cambiado por arcilla:
##   1 a 3, LA CUADRADA, para 1, 2 y 3 jugadores: la caja con la cápsula; más el bloque de arriba con el pozo; más la
##          torre del artillero.
##   4 a 6, LA REDONDA, para 1, 2 y 3: el cuerpo como una esfera chanfleada con la cápsula más chica al medio; más el
##          octógono extruido arriba; más la torreta.
## Para 1 jugador, el arma del artillero va sola, sin silla, arriba atrás. Cada una de frente, de costado y de tres
## cuartos; y las seis juntas.
##   tools/godot_ventana.sh res://tests/torso_shapes_look.tscn -- --salida=C:/carpeta
##
## CON --serie=talles, LA REDONDA CON EL CUERPO MÁS GRANDE (el usuario, 17/11/2026: «aumentar solamente el cubo
## chanfleado del cuerpo para que la cápsula del medio coincida con la cara cuadrada del frente y el de arriba coincida
## con la cara cuadrada de arriba… lo de arriba y la cápsula no le cambiaría el tamaño»), para 3: la de antes y tres
## talles del cuerpo —a la medida de la cápsula, al medio, a la medida del octógono— (la cara de adelante y la de arriba
## miden lo mismo, y la cápsula y el octógono no: las dos a la vez no calzan). Los hombros, al medio de los costados del
## cuerpo nuevo.

const VIEW := Vector2i(1280, 720)
const SPACING := 16.0
const NAMES := ["cuadrada, para 1", "cuadrada, para 2", "cuadrada, para 3", "redonda, para 1", "redonda, para 2",
	"redonda, para 3"]
const SHELL := Color(0.6, 0.61, 0.63)
const DARK := Color(0.22, 0.23, 0.25)
const GLASS := Color(0.55, 0.74, 0.7)
const METAL := Color(0.5, 0.52, 0.56)

## Los talles del cuerpo de la serie: el de antes (−1) y los nuevos, en partes entre la cápsula (0) y el octógono (1).
const SIZES := [-1.0, 0.0, 0.5, 1.0]
const SIZE_NAMES := ["redonda de antes", "cuerpo a la medida de la cápsula", "cuerpo al medio",
	"cuerpo a la medida del octógono de arriba"]

var _folder := ""
var _sizes := false
var _eye: Camera3D = null
var _shots: Array[Image] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		elif argument == "--serie=talles":
			_sizes = true
	get_window().size = VIEW
	_stage()
	var mechs: Array[CageMech] = []
	var form := CageCabin.shape()
	var padding := form.padding
	var forward := form.shoulder_forward
	var count := SIZES.size() if _sizes else NAMES.size()
	for index in count:
		# Los hombros salen de la caja (CageShape.side): en la serie, del ancho del cuerpo nuevo y al medio. Se leen al
		# armar los brazos, así que se cambian un momento y se vuelven a poner.
		if _sizes and SIZES[index] >= 0.0:
			form.padding = _body_radius(SIZES[index]) - form.capsule_radius()
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
		clay.name = "Arcilla"
		clay.position = Vector3(0.0, CageCabin.bottom(), 0.0)
		cabin.add_child(clay)
		if _sizes:
			_round(clay, 3, SIZES[index])
		elif index < 3:
			_square(clay, index + 1)
		else:
			_round(clay, index - 2)
	await get_tree().create_timer(0.6).timeout
	# Las altas, mirando más arriba y un poco más lejos.
	var lifts: Array[float] = [0.3, 0.6, 1.0, 0.3, 0.9, 1.5]
	if _sizes:
		lifts = [1.5, 2.0, 2.2, 2.4]
	for index in mechs.size():
		var at := mechs[index].global_position + Vector3(0.0, lifts[index], 0.0)
		var far := 1.0 + lifts[index] * 0.12
		await _shot(at + Vector3(0.0, 1.0, -13.0) * far, at, 40.0)
		# De costado, sin alejarse: la vecina está a SPACING.
		await _shot(at + Vector3(12.0, 1.0, 0.0), at, 40.0 + lifts[index] * 4.0)
		await _shot(at + Vector3(-7.5, 5.0, -8.5) * far, at, 42.0)
	var middle := mechs[0].global_position.lerp(mechs[mechs.size() - 1].global_position, 0.5)
	await _shot(middle + Vector3(0.0, 6.0, -64.0), middle + Vector3(0.0, 1.0, 0.0), 44.0, false)
	_save()
	get_tree().quit()


## ── LA CUADRADA: la de hoy, por partes (las medidas de CageShape y CageCabin) ──────────────────────────────────────

func _square(at: Node3D, players: int) -> void:
	var form := CageCabin.shape()
	var side := form.side()
	var tall := form.height()
	Clay.box(at, Vector3(side, tall, side), Vector3(0.0, tall * 0.5, 0.0), SHELL)
	# La cápsula: lo que sobresale de la cara de adelante es el domo.
	_faceted(at, CageCabin.bubble_center(form), form.capsule_radius(), GLASS)
	if players == 1:
		_lone_gun(at, Vector3(0.0, tall, side * 0.3))
		return
	var pit := CageCabin.pit_of(form)
	var high := pit.top()
	Clay.box(at, Vector3(side, high, side), Vector3(0.0, tall + high * 0.5, 0.0), SHELL)
	_prism(at, pit.rim(), 0.02, Vector3(0.0, tall + high, 0.0), DARK)
	if players == 3:
		var wide := form.tower_width
		var deep := form.tower_deep()
		var up := CageCabin.tower_top(form)
		Clay.box(at, Vector3(wide, up, deep), Vector3(0.0, tall + up * 0.5, side * 0.5 - deep * 0.5), SHELL)
		_turret(at, Vector3(0.0, tall + up, side * 0.5 - deep * 0.5))


## ── LA REDONDA: el cuerpo, una esfera chanfleada del ancho de la caja; la cápsula de hoy al medio, con el domo afuera ──

## `size`: −1, el cuerpo de la primera tanda (del ancho de la caja); si no, el talle de la serie (ver `_body_radius`),
## con la cápsula en la cara de adelante y el octógono en la de arriba.
func _round(at: Node3D, players: int, size := -1.0) -> void:
	var form := CageCabin.shape()
	var small := form.capsule_radius()
	var pit := CageCabin.pit_of(form)
	var rim := _octagon_apothem()
	var high := pit.top()
	var fitted := size >= 0.0
	var body := _body_radius(size) if fitted else form.side() * 0.5
	var center := Vector3(0.0, body, 0.0)
	_faceted(at, center, body, SHELL)
	# La cápsula: como hoy en la caja, el cinturón empieza en la cara de adelante y el domo sobresale entero.
	var capsule := center + Vector3(0.0, 0.0, -body + small / (1.0 + sqrt(2.0))) if fitted \
		else center + Vector3(0.0, -0.1, -body + small * 0.55)
	_faceted(at, capsule, small, GLASS)
	var top := center.y + body
	if players == 1:
		_lone_gun(at, Vector3(0.0, top, body * 0.35))
		return
	# EL OCTÓGONO EXTRUIDO ARRIBA: del ancho del tablero de arriba de hoy, tan alto como su bloque; en la serie, parado
	# en la cara de arriba.
	var from := top if fitted else top - 0.35
	var tall := high if fitted else high + 0.35
	_prism(at, rim, tall, Vector3(0.0, from, 0.0), SHELL)
	_prism(at, pit.rim(), 0.02, Vector3(0.0, from + tall, 0.0), DARK)
	if players == 3:
		var up := CageCabin.tower_top(form) * 0.8
		var base := Vector3(0.0, from + tall, rim * 0.55)
		Clay.cylinder(at, 0.45, up, base + Vector3(0.0, up * 0.5, 0.0), SHELL)
		_turret(at, base + Vector3(0.0, up, 0.0))


## El apotema del octógono de arriba de la redonda: el del tablero de arriba de hoy, un poco más ancho.
func _octagon_apothem() -> float:
	return CageCabin.pit_of(CageCabin.shape()).rim() + 0.15


## EL CUERPO DE LA SERIE: la cara cuadrada de un rombicuboctaedro de apotema R mide 2R / (1 + √2) de lado. A la medida
## de la cápsula (0), esa cara es tan ancha como la cápsula (2r); a la del octógono (1), como el octógono (2a).
func _body_radius(size: float) -> float:
	var capsule := CageCabin.shape().capsule_radius()
	return lerpf(capsule, _octagon_apothem(), size) * (1.0 + sqrt(2.0))


## ── LAS PIEZAS ──────────────────────────────────────────────────────────────────────────────────────────────────────

## La cápsula facetada (CageMesh.faceted_sphere) de `radius` en `center`.
func _faceted(at: Node3D, center: Vector3, radius: float, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Dictionary in CageMesh.faceted_sphere():
		var points: Array = []
		for p: Vector3 in face["points"]:
			points.append(center + p * radius)
		CageMesh.face(tool, points, face["normal"])
	var mesh := MeshInstance3D.new()
	mesh.mesh = CageMesh.commit(tool, color)
	at.add_child(mesh)


## Un octógono de apotema `apothem` y `height` de alto, parado desde `base`, con una cara al frente.
func _prism(at: Node3D, apothem: float, height: float, base: Vector3, color: Color) -> void:
	var ring := CageMesh.polygon(apothem / cos(PI / 8.0), 8, -PI * 0.5 - PI / 8.0)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top: Array = []
	for k in 8:
		var a := ring[k]
		var b := ring[(k + 1) % 8]
		var out := Vector3((a.x + b.x) * 0.5, 0.0, (a.y + b.y) * 0.5).normalized()
		CageMesh.face(tool, [base + Vector3(a.x, 0.0, a.y), base + Vector3(b.x, 0.0, b.y),
			base + Vector3(b.x, height, b.y), base + Vector3(a.x, height, a.y)], out)
		top.append(base + Vector3(a.x, height, a.y))
	CageMesh.face(tool, top, Vector3.UP)
	var mesh := MeshInstance3D.new()
	mesh.mesh = CageMesh.commit(tool, color)
	at.add_child(mesh)


## El plato del artillero con su silla y el arma, sobre `base`.
func _turret(at: Node3D, base: Vector3) -> void:
	Clay.cylinder(at, 0.75, 0.12, base + Vector3(0.0, 0.06, 0.0), METAL)
	Clay.box(at, Vector3(0.5, 0.45, 0.5), base + Vector3(0.0, 0.35, 0.2), DARK)
	Clay.box(at, Vector3(0.5, 0.7, 0.12), base + Vector3(0.0, 0.6, 0.45), DARK)
	_gun(at, base + Vector3(0.0, 0.75, -0.35))


## El arma del artillero sola, sin silla (para 1 jugador), sobre un pie corto en `base`.
func _lone_gun(at: Node3D, base: Vector3) -> void:
	Clay.cylinder(at, 0.35, 0.1, base + Vector3(0.0, 0.05, 0.0), METAL)
	Clay.cylinder(at, 0.12, 0.45, base + Vector3(0.0, 0.3, 0.0), DARK)
	_gun(at, base + Vector3(0.0, 0.6, 0.0))


func _gun(at: Node3D, center: Vector3) -> void:
	Clay.box(at, Vector3(0.45, 0.35, 0.7), center, DARK)
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(at, 0.06, 0.9, center + Vector3(s * 0.12, 0.0, -0.75), METAL, Vector3(90.0, 0.0, 0.0))


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


func _shot(from: Vector3, to: Vector3, fov: float, half := true) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if half:
		image.resize(VIEW.x / 2, VIEW.y / 2, Image.INTERPOLATE_BILINEAR)
	_shots.append(image)


## Cada foto suelta (torso_N_frente.png, _costado, _tres_cuartos, y torso_todas.png; en la serie, talle_N_…): la hoja la
## arma quien las mira.
func _save() -> void:
	var prefix := "talle" if _sizes else "torso"
	var count := SIZES.size() if _sizes else NAMES.size()
	for index in _shots.size():
		var path := "%s/%s_todas.png" % [_folder, prefix]
		if index < count * 3:
			path = "%s/%s_%d_%s.png" % [_folder, prefix, index / 3 + 1, ["frente", "costado", "tres_cuartos"][index % 3]]
		_shots[index].save_png(path)
	print("CAPTURAS ", _shots.size())
