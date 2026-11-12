extends Node3D

## MAQUETAS DE LOS RECURSOS DE LA MECA, SEGUNDA TANDA (numeradas desde el 15; sólo dibujo). Todo es UN CUBO DE 63 cm: lo
## que se lleva y también el lugar de la meca donde se carga la munición (el usuario, 13/11/2026: «que los lugares a donde
## vos cargas las municiones sean el mismo formato de cubo»). SIN ARMAZONES: la forma del objeto llena el cubo; colores
## tranquilos y con poco contraste; estereotipos (la batería con sus polos, la bomba como un atado de cartuchos). La
## figura naranja mide 1,8 m.
##   tools/godot_ventana.sh res://tests/supply_mockup.tscn -- --salida=C:/carpeta

const U := 0.63
const H := U * 0.5
const GAP := 6.0
const TABLE := 0.75
const FIRST := 15
const CHARCOAL := Color(0.27, 0.27, 0.28)
const LEAD := Color(0.46, 0.46, 0.47)
const OXIDE := Color(0.4, 0.21, 0.17)
const BAKELITE := Color(0.25, 0.19, 0.15)
const CREAM := Color(0.8, 0.75, 0.62)
const WARM := Color(0.95, 0.78, 0.45)
const GLASS := Color(0.78, 0.74, 0.64, 0.38)
const SOOT := Color(0.09, 0.085, 0.08)
const CRATE := Color(0.38, 0.39, 0.32)
const STEEL := Color(0.4, 0.41, 0.43)
const MUSTARD := Color(0.72, 0.6, 0.25)
const DYNAMITE := Color(0.6, 0.22, 0.17)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _stations: Array[Dictionary] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	Clay.box(self, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	_build()
	_eye = Camera3D.new()
	_eye.fov = 40.0
	add_child(_eye)
	_eye.make_current()
	await get_tree().create_timer(1.0).timeout
	for index in _stations.size():
		var station := _stations[index]
		var at: Vector3 = (station["node"] as Node3D).position
		var wide := float(station["wide"])
		_eye.global_position = at + Vector3(wide * 0.4, 1.75, 1.3 + wide * 0.8)
		_eye.look_at(at + Vector3(0.0, 1.0, 0.0))
		await _shot("%d · %s" % [index + FIRST, station["name"]], "%02d" % (index + FIRST))
	get_tree().quit()


## ── LAS ESTACIONES ───────────────────────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	for design in 2:
		_row("Batería %s: llena, a medias, gastada" % ["A, negra, con sus dos polos", "B, colorada, con sus celdas"][design],
			func(at: Node3D, state: float) -> void: _battery(at, design, state))
	for design in 3:
		var s := _station("Componente eléctrico %s: sano y quemado" % ["A1, cuatro válvulas", "A2, una válvula grande",
			"A3, tres válvulas contra un respaldo"][design], 2.2)
		for index in 2:
			_component(_block(s, (index - 0.5) * 1.0), design, index == 1)
	var crates := _station("Cajas de munición (se llevan), bien simples: misiles y balas", 2.2)
	_crate(_block(crates, -0.5), MUSTARD)
	_crate(_block(crates, 0.5), LEAD)
	for design in 2:
		_row("Misiles en la meca %s: ocho, cuatro, ninguno" % ["A, ocho en anillo", "B, dos filas de cuatro"][design],
			func(at: Node3D, state: float) -> void: _missiles(at, design, roundi(state * 8.0)))
	_row("Balas en la meca A, la cinta en una ventana: llena, a medias, vacía",
		func(at: Node3D, state: float) -> void: _belt(at, roundi(state * 8.0)))
	_row("Balas en la meca B, un tambor: lleno, a medias, vacío",
		func(at: Node3D, state: float) -> void: _drum(at, roundi(state * 6.0)))
	for design in 3:
		var s := _station("Bomba %s" % ["A: nueve cartuchos parados, con su faja", "B: dieciséis cartuchos finos, atados",
			"C: nueve cartuchos acostados, con su faja"][design], 1.6)
		_dynamite(_block(s, 0.0), design)


## Una estación con tres cubos: lleno, a medias y gastado.
func _row(station_name: String, make: Callable) -> void:
	var s := _station(station_name, 3.0)
	for index in 3:
		make.call(_block(s, (index - 1) * 0.95), [1.0, 0.5, 0.0][index])


func _station(station_name: String, wide: float) -> Node3D:
	var node := Node3D.new()
	node.position = Vector3(_stations.size() * GAP, 0.0, 0.0)
	add_child(node)
	_stations.append({"node": node, "name": station_name, "wide": wide})
	Clay.box(node, Vector3(wide - 0.4, TABLE, 0.9), Vector3(0, TABLE * 0.5, 0), Color(0.62, 0.6, 0.56))
	# La persona, para la escala.
	Clay.box(node, Vector3(0.5, 1.8, 0.3), Vector3(-wide * 0.5 - 0.35, 0.9, 0.2), Color(0.95, 0.5, 0.1))
	return node


## El centro de un cubo apoyado en la mesa, en `x`.
func _block(station: Node3D, x: float) -> Node3D:
	var node := Node3D.new()
	node.position = Vector3(x, TABLE + H, 0.0)
	station.add_child(node)
	return node


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

func _cyl(parent: Node3D, top: float, bottom: float, height: float, at: Vector3, color: Color,
		turn := Vector3.ZERO) -> MeshInstance3D:
	var part := Clay.cylinder(parent, bottom, height, at, color, turn)
	(part.mesh as CylinderMesh).top_radius = top
	(part.mesh as CylinderMesh).radial_segments = 16
	return part


func _lit(part: MeshInstance3D, color: Color, energy := 1.2) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	part.material_override = material


## LA BATERÍA, como una de auto: la caja, la tapa y arriba sus polos; en el frente, una mirilla con el nivel. Gastada,
## toda más oscura y la mirilla vacía.
func _battery(cube: Node3D, design: int, level: float) -> void:
	var dim := 1.0 if level > 0.0 else 0.55
	var body := (CHARCOAL if design == 0 else OXIDE) * dim
	body.a = 1.0
	var lid := body.lightened(0.12) if design == 0 else body.darkened(0.3)
	Clay.box(cube, Vector3(U, 0.5, U), Vector3(0, -0.065, 0), body)
	Clay.box(cube, Vector3(U, 0.06, U), Vector3(0, 0.215, 0), lid)
	# Las costillas de la caja, en los costados.
	for side: float in [-1.0, 1.0]:
		for rib in 4:
			Clay.box(cube, Vector3(0.012, 0.42, 0.05), Vector3(side * H, -0.08, -0.21 + rib * 0.14), body.darkened(0.25))
	# Los dos polos (y, en la B, las tapas de sus celdas entre ellos).
	for side: float in [-1.0, 1.0]:
		_cyl(cube, 0.05, 0.065, 0.07, Vector3(side * 0.2, 0.28, 0.0 if design == 0 else -0.14), LEAD.darkened(1.0 - dim))
	if design == 1:
		for cell in 3:
			_cyl(cube, 0.045, 0.045, 0.035, Vector3((cell - 1) * 0.16, 0.262, 0.12), lid.lightened(0.2))
	# La mirilla del nivel: parada en la A, acostada en la B.
	var upright := design == 0
	var window := Vector3(0.14, 0.4, 0.012) if upright else Vector3(0.44, 0.13, 0.012)
	Clay.box(cube, window + Vector3(0.05, 0.05, 0.0), Vector3(0, -0.07, H), body.darkened(0.35))
	Clay.box(cube, window, Vector3(0, -0.07, H + 0.004), SOOT)
	if level > 0.0:
		var fill := Vector3(window.x - 0.03, (window.y - 0.03) * level, 0.012) if upright \
			else Vector3((window.x - 0.03) * level, window.y - 0.03, 0.012)
		var at := Vector3(0, -0.07 - (window.y - 0.03) * (1.0 - level) * 0.5, H + 0.008) if upright \
			else Vector3(-(window.x - 0.03) * (1.0 - level) * 0.5, -0.07, H + 0.008)
		_lit(Clay.box(cube, fill, at, WARM), WARM, 0.7)


## EL COMPONENTE ELÉCTRICO: una base de baquelita con sus válvulas de vidrio; el filamento apenas brilla. Quemado: el
## vidrio ahumado, sin brillo, la base tiznada.
func _component(cube: Node3D, design: int, burnt: bool) -> void:
	var base := BAKELITE if not burnt else BAKELITE.darkened(0.55)
	var glass := GLASS if not burnt else Color(0.1, 0.09, 0.08, 0.9)
	Clay.box(cube, Vector3(U, 0.18, U), Vector3(0, -0.225, 0), base)
	match design:
		0:
			for x: float in [-0.155, 0.155]:
				for z: float in [-0.155, 0.155]:
					_valve(cube, Vector3(x, -0.135, z), 0.135, 0.45, glass, burnt)
		1:
			_cyl(cube, 0.22, 0.26, 0.1, Vector3(0, -0.085, 0), base.lightened(0.08))
			Clay.sphere(cube, 0.265, Vector3(0, 0.05, 0), glass)
			for plate in 3:
				_cyl(cube, 0.13 - plate * 0.03, 0.13 - plate * 0.03, 0.02, Vector3(0, -0.02 + plate * 0.09, 0), LEAD if not burnt else SOOT)
			var core := _cyl(cube, 0.025, 0.025, 0.3, Vector3(0, 0.07, 0), WARM if not burnt else SOOT)
			if not burnt:
				_lit(core, WARM)
		2:
			Clay.box(cube, Vector3(U, 0.45, 0.2), Vector3(0, 0.09, -0.215), base.lightened(0.06))
			for index in 3:
				_valve(cube, Vector3((index - 1) * 0.205, -0.135, 0.09), 0.1, 0.45, glass, burnt)


## Una válvula parada en `foot`: el vidrio con su cúpula, las placas de adentro y el filamento.
func _valve(cube: Node3D, foot: Vector3, radius: float, height: float, glass: Color, burnt: bool) -> void:
	var straight := height - radius
	_cyl(cube, radius, radius, straight, foot + Vector3(0, straight * 0.5, 0), glass)
	Clay.sphere(cube, radius, foot + Vector3(0, straight, 0), glass)
	_cyl(cube, radius * 0.55, radius * 0.55, straight * 0.7, foot + Vector3(0, straight * 0.45, 0), LEAD.darkened(0.2) if not burnt else SOOT)
	var core := _cyl(cube, radius * 0.2, radius * 0.2, straight * 0.95, foot + Vector3(0, straight * 0.55, 0), WARM if not burnt else SOOT)
	if not burnt:
		_lit(core, WARM)


## UNA CAJA DE MUNICIÓN: lisa, con su tapa y una etiqueta plana del color de lo que lleva.
func _crate(cube: Node3D, label: Color) -> void:
	Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, CRATE)
	Clay.box(cube, Vector3(U + 0.006, 0.02, U + 0.006), Vector3(0, 0.2, 0), CRATE.darkened(0.3))
	Clay.box(cube, Vector3(0.34, 0.2, 0.008), Vector3(0, -0.04, H), CREAM)
	Clay.box(cube, Vector3(0.34, 0.05, 0.01), Vector3(0, -0.04, H + 0.002), label)


## LOS MISILES, EN LA MECA: un cubo con ocho tubos en la cara; cada misil que queda asoma la punta.
func _missiles(cube: Node3D, design: int, left: int) -> void:
	Clay.box(cube, Vector3(U, U, U - 0.06), Vector3(0, 0, -0.03), STEEL)
	Clay.box(cube, Vector3(U, U, 0.06), Vector3(0, 0, H - 0.03), STEEL.darkened(0.2))
	var spots: Array[Vector2] = []
	if design == 0:
		for row in 3:
			for column in 3:
				if not (row == 1 and column == 1):
					spots.append(Vector2((column - 1) * 0.195, (1 - row) * 0.195))
	else:
		for row in 2:
			for column in 4:
				spots.append(Vector2((column - 1.5) * 0.15, (0.5 - row) * 0.26))
	var radius := 0.08 if design == 0 else 0.062
	for index in spots.size():
		var at := Vector3(spots[index].x, spots[index].y, H)
		_cyl(cube, radius, radius, 0.012, at, SOOT, Vector3(90, 0, 0))
		if index < left:
			_cyl(cube, 0.0, radius * 0.82, 0.11, at + Vector3(0, 0, 0.05), MUSTARD, Vector3(90, 0, 0))


## LAS BALAS, EN LA MECA, A: un cubo con una ventana donde se ve la cinta; baja a medida que se gasta.
func _belt(cube: Node3D, rows: int) -> void:
	Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, STEEL)
	Clay.box(cube, Vector3(0.36, 0.52, 0.012), Vector3(0, 0, H), SOOT)
	for row in rows:
		var y := -0.21 + row * 0.06
		_cyl(cube, 0.022, 0.022, 0.2, Vector3(-0.03, y, H + 0.02), LEAD.lightened(0.15), Vector3(0, 0, 90))
		_cyl(cube, 0.0, 0.022, 0.07, Vector3(0.105, y, H + 0.02), CREAM, Vector3(0, 0, -90))


## LAS BALAS, EN LA MECA, B: un cubo con un tambor en la cara; los sectores cargados se ven llenos.
func _drum(cube: Node3D, loaded: int) -> void:
	Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, STEEL)
	_cyl(cube, 0.28, 0.28, 0.03, Vector3(0, 0, H + 0.005), STEEL.darkened(0.35), Vector3(90, 0, 0))
	_cyl(cube, 0.06, 0.06, 0.06, Vector3(0, 0, H + 0.02), LEAD, Vector3(90, 0, 0))
	for sector in 6:
		var angle := PI * 0.5 - TAU * sector / 6.0
		var at := Vector3(cos(angle) * 0.17, sin(angle) * 0.17, H + 0.02)
		_cyl(cube, 0.068, 0.068, 0.012, at, SOOT, Vector3(90, 0, 0))
		if sector < loaded:
			_cyl(cube, 0.055, 0.055, 0.03, at + Vector3(0, 0, 0.008), CREAM, Vector3(90, 0, 0))


## LA BOMBA: UN ATADO DE CARTUCHOS DE DINAMITA que llena el cubo (como la TNT de Minecraft), sin armazón ni botón.
func _dynamite(cube: Node3D, design: int) -> void:
	var count := 4 if design == 1 else 3
	var radius := U / count * 0.5
	var lying := design == 2
	for a in count:
		for b in count:
			var x := (a - (count - 1) * 0.5) * radius * 2.0
			var z := (b - (count - 1) * 0.5) * radius * 2.0
			var at := Vector3(0.0, x, z) if lying else Vector3(x, 0.0, z)
			var turn := Vector3(0, 0, 90) if lying else Vector3.ZERO
			_cyl(cube, radius - 0.004, radius - 0.004, U - 0.03, at, DYNAMITE, turn)
			_cyl(cube, radius * 0.75, radius * 0.75, U, at, DYNAMITE.darkened(0.35), turn)
	# Lo que los ata: una faja ancha de papel, o dos sogas finas.
	var around := Vector3(0.0, 1.0, 1.0) if lying else Vector3(1.0, 0.0, 1.0)
	var along := Vector3(1.0, 0.0, 0.0) if lying else Vector3(0.0, 1.0, 0.0)
	if design == 1:
		for way: float in [-1.0, 1.0]:
			Clay.box(cube, around * (U + 0.006) + along * 0.035, along * way * 0.16, Color(0.5, 0.42, 0.3))
	else:
		Clay.box(cube, around * (U + 0.006) + along * 0.2, Vector3.ZERO, CREAM)
	# La mecha, saliendo del cartucho del medio.
	var wick := Vector3(H + 0.04, 0.0, 0.0) if lying else Vector3(0.0, H + 0.04, 0.0)
	var offset := Vector3.ZERO if count == 3 else (Vector3(radius, 0, radius) if not lying else Vector3.ZERO)
	_cyl(cube, 0.012, 0.012, 0.09, wick + offset, Color(0.3, 0.27, 0.22), Vector3(0, 0, 90) if lying else Vector3.ZERO)


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
