extends Node3D

## MAQUETAS DE LOS RECURSOS DE LA MECA, NUMERADAS, PARA ELEGIR (sólo dibujo). Todo lo que se lleva es UN CUBO DE 63 cm
## (el usuario, 13/11/2026: «una celda de tamaño único que se agarra siempre igual»); lo que se enchufa deja a la vista
## UNA cara, la de lectura (+Z acá). La figura naranja mide 1,8 m.
##   tools/godot_ventana.sh res://tests/supply_mockup.tscn -- --salida=C:/carpeta

const U := 0.63
const GAP := 6.0
const TABLE := 0.75
const GREY := Color(0.42, 0.44, 0.47)
const DARK := Color(0.16, 0.17, 0.19)
const WALL := Color(0.55, 0.57, 0.6)
const SOOT := Color(0.07, 0.065, 0.06)
const GREEN := Color(0.35, 1.0, 0.55)
const AMBER := Color(1.0, 0.62, 0.15)
const YELLOW := Color(0.95, 0.78, 0.15)
const CREAM := Color(0.86, 0.82, 0.7)
const RED := Color(0.85, 0.16, 0.12)
const OLIVE := Color(0.33, 0.37, 0.27)
const GLASS := Color(0.55, 0.75, 0.8, 0.35)

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
	world.environment.glow_enabled = true
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
		_eye.global_position = at + Vector3(wide * 0.45, 1.65, 1.5 + wide * 0.9)
		_eye.look_at(at + Vector3(0.0, 1.05, 0.0))
		await _shot("%d · %s" % [index + 1, station["name"]], "%02d" % (index + 1))
	get_tree().quit()


## ── LAS ESTACIONES ───────────────────────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	# 1 · LA BATERÍA, llevada: llena, a medias y gastada.
	var s := _station("Batería (se lleva): llena, a medias, gastada", 3.0)
	_table(s, 2.6)
	for index in 3:
		_battery(s, Vector3((index - 1) * 0.95, TABLE + U * 0.5, 0.0), [1.0, 0.45, 0.0][index])
	# 2 · LA BATERÍA, puesta: el nicho deja a la vista la cara de lectura; al lado, un nicho vacío con su indicador.
	s = _station("Batería puesta en la meca, y un hueco vacío con su indicador", 3.2)
	_wall(s, 3.0, [Vector3(-0.75, 1.3, 0.0), Vector3(0.75, 1.3, 0.0)], [GREEN, DARK])
	_battery(s, Vector3(-0.75, 1.3, -U * 0.5), 0.7)
	# 3 a 5 · EL COMPONENTE ELÉCTRICO (algo que se quema y se reemplaza; no un fusible literal): sano y quemado.
	for design in 3:
		s = _station("Componente eléctrico %s: sano y quemado" % ["A, de válvulas", "B, de bobina", "C, de aletas"][design], 2.2)
		_table(s, 1.9)
		for index in 2:
			_component(s, Vector3((index - 0.5) * 1.0, TABLE + U * 0.5, 0.0), design, index == 1)
	# 6 · EL COMPONENTE, puesto: uno sano y uno quemado en la pared.
	s = _station("Componente puesto: sano, y quemado (oscuro, con humo y chispas en el juego)", 3.2)
	_wall(s, 3.0, [Vector3(-0.75, 1.3, 0.0), Vector3(0.75, 1.3, 0.0)], [AMBER, RED])
	_component(s, Vector3(-0.75, 1.3, -U * 0.5), 0, false)
	_component(s, Vector3(0.75, 1.3, -U * 0.5), 0, true)
	# 7 · LA CAJA DE MISILES, llevada: una caja con su etiqueta.
	s = _station("Caja de misiles (se lleva): una caja con etiqueta", 1.6)
	_table(s, 1.2)
	_crate(s, Vector3(0.0, TABLE + U * 0.5, 0.0), YELLOW, true)
	# 8 · EL LANZADOR, en la meca: la caja entra por la boca de carga y los tubos se llenan.
	s = _station("Lanzador en la meca: boca de carga y cuatro tubos (quedan dos misiles)", 4.0)
	_launcher(s)
	# 9 · LA CAJA DE BALAS, llevada.
	s = _station("Caja de balas (se lleva): una caja con etiqueta", 1.6)
	_table(s, 1.2)
	_crate(s, Vector3(0.0, TABLE + U * 0.5, 0.0), CREAM, false)
	# 10 y 11 · EL ARMA DE BALAS, en la meca: la cinta en una ventana, o un tambor.
	s = _station("Balas en la meca A: boca de carga y ventana con la cinta que baja", 4.0)
	_belt_feed(s)
	s = _station("Balas en la meca B: boca de carga y tambor que se vacía por sectores", 4.0)
	_drum_feed(s)
	# 12 a 14 · LA BOMBA (la tira el jugador a pie).
	s = _station("Bomba A: esfera en un armazón cúbico (misma caja, mismo agarre)", 1.6)
	_table(s, 1.2)
	_bomb(s, Vector3(0.0, TABLE + U * 0.5, 0.0), 0)
	s = _station("Bomba B: cubo macizo con fajas y espoleta", 1.6)
	_table(s, 1.2)
	_bomb(s, Vector3(0.0, TABLE + U * 0.5, 0.0), 1)
	s = _station("Bomba C: barril en un armazón cúbico", 1.6)
	_table(s, 1.2)
	_bomb(s, Vector3(0.0, TABLE + U * 0.5, 0.0), 2)


func _station(station_name: String, wide: float) -> Node3D:
	var node := Node3D.new()
	node.position = Vector3(_stations.size() * GAP, 0.0, 0.0)
	add_child(node)
	_stations.append({"node": node, "name": station_name, "wide": wide})
	# La persona, para la escala.
	Clay.box(node, Vector3(0.5, 1.8, 0.3), Vector3(-wide * 0.5 - 0.5, 0.9, 0.2), Color(0.95, 0.5, 0.1))
	return node


func _table(parent: Node3D, wide: float) -> void:
	Clay.box(parent, Vector3(wide, TABLE, 0.9), Vector3(0, TABLE * 0.5, 0), Color(0.62, 0.6, 0.56))


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## Un cubo de 63 cm: el armazón de doce cantos gruesos. Devuelve su nodo (el centro del cubo).
func _frame(parent: Node3D, at: Vector3, color: Color) -> Node3D:
	var cube := Node3D.new()
	cube.position = at
	parent.add_child(cube)
	var edge := 0.07
	var off := U * 0.5 - edge * 0.5
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			Clay.box(cube, Vector3(U, edge, edge), Vector3(0, a * off, b * off), color)
			Clay.box(cube, Vector3(edge, U, edge), Vector3(a * off, 0, b * off), color)
			Clay.box(cube, Vector3(edge, edge, U), Vector3(a * off, b * off, 0), color)
	return cube


## El cuerpo adentro del armazón, y la faja del color de su familia alrededor.
func _body(cube: Node3D, color: Color, band: Color, depth := 0.56, back := 0.0) -> void:
	Clay.box(cube, Vector3(0.56, 0.56, depth), Vector3(0, 0, back), color)
	Clay.box(cube, Vector3(0.575, 0.1, minf(depth + 0.015, 0.575)), Vector3(0, 0.19, back), band)


func _lit(part: MeshInstance3D, color: Color, energy := 2.5) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	part.material_override = material


func _cyl(parent: Node3D, top: float, bottom: float, height: float, at: Vector3, color: Color,
		turn := Vector3.ZERO) -> MeshInstance3D:
	var part := Clay.cylinder(parent, bottom, height, at, color, turn)
	(part.mesh as CylinderMesh).top_radius = top
	(part.mesh as CylinderMesh).radial_segments = 16
	return part


## LA BATERÍA: una columna de vidrio en la cara de lectura, con un nivel luminoso que baja. Gastada, el cuerpo oscuro.
func _battery(parent: Node3D, at: Vector3, level: float) -> void:
	var spent := level <= 0.0
	var cube := _frame(parent, at, DARK if not spent else SOOT)
	_body(cube, Color(0.3, 0.36, 0.4) if not spent else Color(0.13, 0.14, 0.15), Color(0.2, 0.6, 0.45) if not spent else Color(0.17, 0.2, 0.19))
	# El marco de la columna, el vidrio y el nivel.
	Clay.box(cube, Vector3(0.26, 0.5, 0.02), Vector3(0, 0, 0.283), DARK)
	Clay.box(cube, Vector3(0.18, 0.44, 0.02), Vector3(0, 0, 0.292), Color(0.05, 0.08, 0.08))
	if level > 0.0:
		_lit(Clay.box(cube, Vector3(0.15, 0.42 * level, 0.02), Vector3(0, -0.21 + 0.21 * level, 0.3), GREEN), GREEN)
	for mark in 5:
		Clay.box(cube, Vector3(0.05, 0.012, 0.02), Vector3(0.14, -0.2 + mark * 0.1, 0.296), GREY)
	# Los bornes, arriba.
	for side: float in [-1.0, 1.0]:
		_cyl(cube, 0.055, 0.055, 0.035, Vector3(side * 0.15, 0.297, 0.0), GREY)


## EL COMPONENTE ELÉCTRICO, tres diseños. Quemado: todo oscuro, sin brillo.
func _component(parent: Node3D, at: Vector3, design: int, burnt: bool) -> void:
	var cube := _frame(parent, at, DARK if not burnt else SOOT)
	var metal := Color(0.4, 0.38, 0.36) if not burnt else Color(0.1, 0.095, 0.09)
	var band := Color(0.85, 0.5, 0.12) if not burnt else Color(0.16, 0.13, 0.1)
	match design:
		0:
			# A · VÁLVULAS: el cuerpo atrás y, en la bahía de adelante, tres válvulas de vidrio con su filamento.
			_body(cube, metal, band, 0.3, -0.13)
			Clay.box(cube, Vector3(0.5, 0.05, 0.24), Vector3(0, -0.235, 0.16), DARK)
			for index in 3:
				var x := (index - 1) * 0.16
				_cyl(cube, 0.065, 0.065, 0.36, Vector3(x, -0.03, 0.17), GLASS if not burnt else SOOT)
				_cyl(cube, 0.05, 0.065, 0.06, Vector3(x, 0.18, 0.17), GLASS if not burnt else SOOT)
				var core := _cyl(cube, 0.022, 0.022, 0.3, Vector3(x, -0.04, 0.17), AMBER if not burnt else SOOT)
				if not burnt:
					_lit(core, AMBER, 4.0)
		1:
			# B · BOBINA: el cuerpo atrás y una bobina gorda acostada adelante, con sus dos tapas que brillan.
			_body(cube, metal, band, 0.24, -0.16)
			var wire := Color(0.2, 0.33, 0.36) if not burnt else SOOT
			_cyl(cube, 0.17, 0.17, 0.4, Vector3(0, 0, 0.12), wire, Vector3(0, 0, 90))
			for ring in 6:
				_cyl(cube, 0.19, 0.19, 0.03, Vector3(-0.17 + ring * 0.068, 0, 0.12), wire.darkened(0.35), Vector3(0, 0, 90))
			for side: float in [-1.0, 1.0]:
				var cap := _cyl(cube, 0.09, 0.09, 0.04, Vector3(side * 0.225, 0, 0.12), AMBER if not burnt else SOOT, Vector3(0, 0, 90))
				if not burnt:
					_lit(cap, AMBER, 3.0)
		2:
			# C · ALETAS: macizo; en la cara, una ranura que brilla detrás de siete aletas.
			_body(cube, metal, band)
			var slit := Clay.box(cube, Vector3(0.1, 0.46, 0.02), Vector3(0, 0, 0.285), AMBER if not burnt else SOOT)
			if not burnt:
				_lit(slit, AMBER, 4.0)
			for fin in 7:
				Clay.box(cube, Vector3(0.48, 0.03, 0.035), Vector3(0, -0.2 + fin * 0.067, 0.296), DARK if not burnt else SOOT)


## UNA CAJA DE MUNICIÓN (de misiles, o de balas): una caja con fajas, manijas hundidas y una etiqueta con su dibujo.
func _crate(parent: Node3D, at: Vector3, band: Color, missiles: bool) -> void:
	var cube := _frame(parent, at, OLIVE.darkened(0.4))
	_body(cube, OLIVE, band)
	Clay.box(cube, Vector3(0.575, 0.05, 0.575), Vector3(0, -0.19, 0), OLIVE.darkened(0.3))
	for side: float in [-1.0, 1.0]:
		Clay.box(cube, Vector3(0.012, 0.09, 0.26), Vector3(side * 0.285, -0.02, 0), DARK)
	# La etiqueta, en la cara de adelante.
	Clay.box(cube, Vector3(0.42, 0.24, 0.012), Vector3(0, -0.02, 0.284), CREAM)
	if missiles:
		_cyl(cube, 0.04, 0.04, 0.2, Vector3(-0.03, -0.02, 0.294), DARK, Vector3(0, 0, 90))
		_cyl(cube, 0.0, 0.04, 0.09, Vector3(0.115, -0.02, 0.294), band, Vector3(0, 0, -90))
		for fin: float in [-1.0, 1.0]:
			Clay.box(cube, Vector3(0.05, 0.05, 0.008), Vector3(-0.12, -0.02 + fin * 0.055, 0.294), DARK)
	else:
		for bullet in 5:
			var x := -0.14 + bullet * 0.07
			_cyl(cube, 0.02, 0.02, 0.11, Vector3(x, -0.045, 0.294), DARK)
			_cyl(cube, 0.0, 0.02, 0.05, Vector3(x, 0.035, 0.294), GREY)


## UNA PARED DE LA MECA con nichos de un cubo (su centro, en `niches`) y una lámpara indicadora sobre cada uno.
func _wall(parent: Node3D, wide: float, niches: Array, lamps: Array) -> void:
	var high := 2.4
	var hole := U + 0.05
	Clay.box(parent, Vector3(wide, high, 0.12), Vector3(0, high * 0.5, -U - 0.06), WALL.darkened(0.25))
	# La pared de adelante, alrededor de los nichos: tiras arriba, abajo y entre ellos.
	var y: float = (niches[0] as Vector3).y
	Clay.box(parent, Vector3(wide, high - y - hole * 0.5, U), Vector3(0, (high + y + hole * 0.5) * 0.5, -U * 0.5), WALL)
	Clay.box(parent, Vector3(wide, y - hole * 0.5, U), Vector3(0, (y - hole * 0.5) * 0.5, -U * 0.5), WALL)
	var left := -wide * 0.5
	for index in niches.size() + 1:
		var right := wide * 0.5 if index == niches.size() else (niches[index] as Vector3).x - hole * 0.5
		if right - left > 0.01:
			Clay.box(parent, Vector3(right - left, hole, U), Vector3((left + right) * 0.5, y, -U * 0.5), WALL)
		if index < niches.size():
			left = (niches[index] as Vector3).x + hole * 0.5
	for index in niches.size():
		var at: Vector3 = niches[index]
		Clay.box(parent, Vector3(hole + 0.14, 0.07, 0.03), Vector3(at.x, at.y + hole * 0.5 + 0.035, 0.015), DARK)
		Clay.box(parent, Vector3(hole + 0.14, 0.07, 0.03), Vector3(at.x, at.y - hole * 0.5 - 0.035, 0.015), DARK)
		var lamp := _cyl(parent, 0.06, 0.06, 0.05, Vector3(at.x, at.y + hole * 0.5 + 0.2, 0.02), lamps[index], Vector3(90, 0, 0))
		if lamps[index] != DARK:
			_lit(lamp, lamps[index], 3.0)


## EL LANZADOR: a la izquierda, la boca de carga (un nicho donde entra la caja); a la derecha, cuatro tubos; cada
## misil que queda asoma la punta, y el que se disparó deja el tubo vacío.
func _launcher(parent: Node3D) -> void:
	_wall(parent, 3.8, [Vector3(-1.2, 1.3, 0.0)], [YELLOW])
	var rack := Vector3(0.75, 1.3, 0.0)
	Clay.box(parent, Vector3(1.5, 1.5, 0.08), rack + Vector3(0, 0, 0.04), DARK)
	for index in 4:
		var at := rack + Vector3((index % 2 - 0.5) * 0.7, (float(index / 2) - 0.5) * 0.7, 0.08)
		_cyl(parent, 0.28, 0.28, 0.1, at, GREY, Vector3(90, 0, 0))
		_cyl(parent, 0.23, 0.23, 0.11, at, SOOT, Vector3(90, 0, 0))
		if index == 0 or index == 3:
			_cyl(parent, 0.2, 0.2, 0.2, at + Vector3(0, 0, 0.06), CREAM, Vector3(90, 0, 0))
			_cyl(parent, 0.0, 0.2, 0.26, at + Vector3(0, 0, 0.29), YELLOW, Vector3(90, 0, 0))


## LAS BALAS, A: la boca de carga y una ventana alta por donde se ve la cinta; baja a medida que se gasta.
func _belt_feed(parent: Node3D) -> void:
	_wall(parent, 3.8, [Vector3(-1.2, 1.3, 0.0)], [CREAM])
	var window := Vector3(0.75, 1.3, 0.0)
	Clay.box(parent, Vector3(0.75, 1.75, 0.08), window + Vector3(0, 0, 0.04), DARK)
	Clay.box(parent, Vector3(0.55, 1.55, 0.04), window + Vector3(0, 0, 0.07), SOOT)
	for row in 9:
		var at := window + Vector3(0, -0.7 + row * 0.11, 0.11)
		_cyl(parent, 0.04, 0.04, 0.32, at + Vector3(-0.06, 0, 0), GREY, Vector3(0, 0, 90))
		_cyl(parent, 0.0, 0.04, 0.12, at + Vector3(0.16, 0, 0), CREAM, Vector3(0, 0, -90))
	Clay.box(parent, Vector3(0.55, 1.55, 0.02), window + Vector3(0, 0, 0.17), GLASS)


## LAS BALAS, B: la boca de carga y un tambor: ocho sectores; los que quedan tienen su carga, los gastados están vacíos.
func _drum_feed(parent: Node3D) -> void:
	_wall(parent, 3.8, [Vector3(-1.2, 1.3, 0.0)], [CREAM])
	var centre := Vector3(0.75, 1.3, 0.0)
	_cyl(parent, 0.8, 0.8, 0.1, centre + Vector3(0, 0, 0.05), DARK, Vector3(90, 0, 0))
	_cyl(parent, 0.2, 0.2, 0.16, centre + Vector3(0, 0, 0.08), GREY, Vector3(90, 0, 0))
	for sector in 8:
		var angle := TAU * sector / 8.0 + PI * 0.5
		var at := centre + Vector3(cos(angle), sin(angle), 0.0) * 0.5 + Vector3(0, 0, 0.1)
		_cyl(parent, 0.16, 0.16, 0.04, at, SOOT, Vector3(90, 0, 0))
		if sector < 5:
			_cyl(parent, 0.13, 0.13, 0.08, at + Vector3(0, 0, 0.02), CREAM, Vector3(90, 0, 0))


## LA BOMBA, tres formatos, con su espoleta y su luz arriba.
func _bomb(parent: Node3D, at: Vector3, design: int) -> void:
	var cube := _frame(parent, at, DARK)
	var shell := Color(0.2, 0.2, 0.22)
	match design:
		0:
			Clay.sphere(cube, 0.265, Vector3.ZERO, shell)
			_cyl(cube, 0.27, 0.27, 0.07, Vector3.ZERO, RED)
		1:
			Clay.box(cube, Vector3(0.56, 0.56, 0.56), Vector3.ZERO, Color(0.6, 0.16, 0.13))
			for y: float in [-0.17, 0.17]:
				Clay.box(cube, Vector3(0.575, 0.07, 0.575), Vector3(0, y, 0), shell)
			Clay.box(cube, Vector3(0.36, 0.16, 0.012), Vector3(0, 0, 0.286), CREAM)
		2:
			_cyl(cube, 0.265, 0.265, 0.5, Vector3(0, -0.03, 0), shell)
			for y: float in [-0.2, 0.0, 0.2]:
				_cyl(cube, 0.275, 0.275, 0.05, Vector3(0, y - 0.03, 0), RED)
	_cyl(cube, 0.07, 0.09, 0.05, Vector3(0, 0.275, 0), GREY)
	_lit(_cyl(cube, 0.04, 0.04, 0.03, Vector3(0, 0.3, 0), RED), RED, 4.0)


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
