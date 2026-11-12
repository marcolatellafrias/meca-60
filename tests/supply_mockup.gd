extends Node3D

## MAQUETAS DE LOS RECURSOS DE LA MECA, CUARTA TANDA (numeradas desde el 38; sólo dibujo). Todo es UN CUBO DE 63 cm: lo
## que se lleva y también el lugar de la meca donde se carga la munición. Lo que pidió el usuario (13/11/2026): que cada
## cosa se sienta UNA CAJA, una unidad —ni un armazón de barras ni cosas sueltas sobre una base—, con lo suyo empotrado
## o sobresaliendo; colores tranquilos y con poco contraste; estereotipos; y LOW POLY («le da más carácter»): cilindros
## de ocho caras, con las caras planas. La figura naranja mide 1,8 m.
##   tools/godot_ventana.sh res://tests/supply_mockup.tscn -- --salida=C:/carpeta

const U := 0.63
const H := U * 0.5
const GAP := 6.0
const TABLE := 0.75
const FIRST := 38
const LEAD := Color(0.46, 0.46, 0.47)
const OXIDE := Color(0.4, 0.21, 0.17)
const ENAMEL := Color(0.47, 0.45, 0.4)
const CERAMIC := Color(0.72, 0.69, 0.62)
const CREAM := Color(0.8, 0.75, 0.62)
const WARM := Color(0.95, 0.78, 0.45)
const SOOT := Color(0.09, 0.085, 0.08)
const CRATE := Color(0.38, 0.39, 0.32)
const CRATE_MISSILES := Color(0.47, 0.4, 0.27)
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
		_eye.global_position = at + (Vector3(wide * 0.4, 1.75, 1.3 + wide * 0.8) if wide < 6.0 else Vector3(0.8, 1.7, 6.8))
		_eye.look_at(at + Vector3(0.0, 1.0, 0.0))
		await _shot("%d · %s" % [index + FIRST, station["name"]], "%02d" % (index + FIRST))
	get_tree().quit()


## ── LAS ESTACIONES ───────────────────────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	var s := _station("Componente eléctrico (el de aletas, más cuadrado): sano y quemado", 2.2)
	for index in 2:
		_component(_block(s, (index - 0.5) * 1.0), 3, index == 1)
	_row("Balas en la meca, finas y apretadas: llena, a medias, vacía",
		func(at: Node3D, state: float) -> void: _belt(at, roundi(state * BELT_ROWS)))
	# LA FAMILIA ELEGIDA, junta.
	var family := _station("La familia elegida", 7.4)
	family.position.x += 14.0
	var x := -3.0
	for index in 7:
		var cube := _block(family, x + index * 1.0)
		match index:
			0: _battery(cube, 0.7)
			1: _component(cube, 3, false)
			2: _crate(cube, CRATE_MISSILES, MUSTARD)
			3: _crate(cube, CRATE, LEAD)
			4: _missiles(cube, 6)
			5: _belt(cube, 13)
			6: _dynamite(cube)


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

## UN CILINDRO (o un cono) LOW POLY: de `sides` caras, con las caras planas (cada una con su normal).
func _cyl(parent: Node3D, top: float, bottom: float, height: float, at: Vector3, color: Color,
		turn := Vector3.ZERO, sides := 8) -> MeshInstance3D:
	var round := CylinderMesh.new()
	round.top_radius = top
	round.bottom_radius = bottom
	round.height = height
	round.radial_segments = sides
	round.rings = 0
	var tool := SurfaceTool.new()
	tool.create_from(round, 0)
	tool.deindex()
	tool.generate_normals()
	var part := MeshInstance3D.new()
	part.mesh = tool.commit()
	part.material_override = Clay.material(color)
	part.position = at
	part.rotation_degrees = turn
	parent.add_child(part)
	return part


func _lit(part: MeshInstance3D, color: Color, energy := 1.0) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	part.material_override = material


## LA BATERÍA (la 16): colorada, como una de auto: la caja, la tapa, los dos polos y las tapas de sus celdas arriba, y
## una mirilla acostada con el nivel. Gastada, toda más oscura y la mirilla vacía.
func _battery(cube: Node3D, level: float) -> void:
	var body := OXIDE if level > 0.0 else OXIDE.darkened(0.45)
	var lid := body.darkened(0.3)
	Clay.box(cube, Vector3(U, 0.5, U), Vector3(0, -0.065, 0), body)
	Clay.box(cube, Vector3(U, 0.06, U), Vector3(0, 0.215, 0), lid)
	for side: float in [-1.0, 1.0]:
		for rib in 4:
			Clay.box(cube, Vector3(0.012, 0.42, 0.05), Vector3(side * H, -0.08, -0.21 + rib * 0.14), body.darkened(0.25))
		_cyl(cube, 0.05, 0.065, 0.07, Vector3(side * 0.2, 0.28, -0.14), LEAD if level > 0.0 else LEAD.darkened(0.4))
	for cell in 3:
		_cyl(cube, 0.045, 0.045, 0.035, Vector3((cell - 1) * 0.16, 0.262, 0.12), lid.lightened(0.2), Vector3.ZERO, 6)
	var window := Vector3(0.44, 0.13, 0.012)
	Clay.box(cube, window + Vector3(0.05, 0.05, 0.0), Vector3(0, -0.07, H), body.darkened(0.35))
	Clay.box(cube, window, Vector3(0, -0.07, H + 0.004), SOOT)
	if level > 0.0:
		var full := window.x - 0.03
		_lit(Clay.box(cube, Vector3(full * level, window.y - 0.03, 0.012), Vector3(-full * (1.0 - level) * 0.5, -0.07, H + 0.008), WARM), WARM, 0.7)


## EL COMPONENTE ELÉCTRICO: UNA CAJA esmaltada, toda de un color, con lo eléctrico empotrado o sobresaliendo. Una
## lamparita dice que anda. Quemado: toda oscura, tiznada, la lamparita apagada.
func _component(cube: Node3D, design: int, burnt: bool) -> void:
	var body := ENAMEL if not burnt else ENAMEL.darkened(0.62)
	var trim := body.darkened(0.22)
	var ceramic := CERAMIC if not burnt else CERAMIC.darkened(0.7)
	var metal := LEAD if not burnt else LEAD.darkened(0.6)
	var lamp := Vector3(-0.2, 0.2, H + 0.012)
	match design:
		0:
			# A · La caja, más baja, con tres aisladores de porcelana arriba; al frente, un tablerito hundido con su palanca.
			Clay.box(cube, Vector3(U, 0.48, U), Vector3(0, -0.075, 0), body)
			for index in 3:
				var x := (index - 1) * 0.2
				for disc in 3:
					_cyl(cube, 0.05, 0.075, 0.035, Vector3(x, 0.185 + disc * 0.04, 0.0), ceramic)
				_cyl(cube, 0.02, 0.02, 0.03, Vector3(x, 0.3, 0.0), metal, Vector3.ZERO, 6)
			Clay.box(cube, Vector3(0.44, 0.26, 0.012), Vector3(0, -0.08, H), trim)
			Clay.box(cube, Vector3(0.05, 0.14, 0.05), Vector3(0.1, -0.06, H + 0.02), metal)
			lamp = Vector3(-0.1, -0.08, H + 0.012)
		1:
			# B · La caja entera; al frente, una placa de porcelana con una llave de cuchilla grande.
			Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, body)
			Clay.box(cube, Vector3(0.34, 0.48, 0.02), Vector3(0.07, -0.02, H + 0.005), ceramic)
			for y: float in [-0.19, 0.15]:
				Clay.box(cube, Vector3(0.12, 0.06, 0.06), Vector3(0.07, y, H + 0.04), metal)
			var blade := Clay.box(cube, Vector3(0.05, 0.4, 0.03), Vector3(0.07, 0.0, H + 0.07), metal)
			blade.rotation_degrees = Vector3(-12.0 if not burnt else -55.0, 0, 0)
			blade.position += Vector3(0, 0.0 if not burnt else 0.02, 0.0 if not burnt else 0.12)
			lamp = Vector3(-0.21, 0.2, H + 0.012)
		2:
			# C · La caja entera; al frente, un hueco con tres cartuchos de porcelana acostados, en sus grampas.
			Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, body)
			Clay.box(cube, Vector3(0.5, 0.36, 0.012), Vector3(0, -0.07, H), trim.darkened(0.3))
			for index in 3:
				var y := -0.18 + index * 0.11
				_cyl(cube, 0.042, 0.042, 0.34, Vector3(0, y, H + 0.035), ceramic if not (burnt and index == 1) else SOOT, Vector3(0, 0, 90), 6)
				for side: float in [-1.0, 1.0]:
					Clay.box(cube, Vector3(0.04, 0.09, 0.05), Vector3(side * 0.19, y, H + 0.03), metal)
			lamp = Vector3(0.0, 0.21, H + 0.012)
		3:
			# D · Un transformador, CASI UN CUBO: el cuerpo ocupa casi todo el ancho y las aletas apenas asoman a los
			# costados, del mismo alto que él; arriba, dos bornes.
			Clay.box(cube, Vector3(0.55, 0.5, U), Vector3(0, -0.065, 0), body)
			for side: float in [-1.0, 1.0]:
				for fin in 8:
					Clay.box(cube, Vector3(0.04, 0.5, 0.035), Vector3(side * 0.295, -0.065, -0.266 + fin * 0.076), trim)
				for disc in 2:
					_cyl(cube, 0.045, 0.07, 0.04, Vector3(side * 0.13, 0.205 + disc * 0.045, 0.0), ceramic)
				_cyl(cube, 0.02, 0.02, 0.03, Vector3(side * 0.13, 0.3, 0.0), metal, Vector3.ZERO, 6)
			Clay.box(cube, Vector3(0.34, 0.2, 0.012), Vector3(0, -0.13, H), trim)
			lamp = Vector3(0.0, 0.08, H + 0.012)
		4:
			# E · La caja entera; al frente, un reloj empotrado, dos luces y una bornera; arriba, ranuras de ventilación.
			Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, body)
			_cyl(cube, 0.15, 0.15, 0.02, Vector3(0.08, 0.06, H + 0.005), trim, Vector3(90, 0, 0))
			_cyl(cube, 0.125, 0.125, 0.02, Vector3(0.08, 0.06, H + 0.01), ceramic, Vector3(90, 0, 0))
			var needle := Clay.box(cube, Vector3(0.012, 0.11, 0.01), Vector3(0.08, 0.06, H + 0.024), SOOT)
			needle.rotation_degrees = Vector3(0, 0, -40.0 if not burnt else 115.0)
			for screw in 4:
				Clay.box(cube, Vector3(0.07, 0.07, 0.03), Vector3(-0.165 + screw * 0.11, -0.21, H + 0.012), metal)
			for slot in 4:
				Clay.box(cube, Vector3(0.4, 0.012, 0.035), Vector3(0, H, -0.16 + slot * 0.1), trim.darkened(0.4))
			lamp = Vector3(-0.2, 0.14, H + 0.012)
	# La lamparita: prendida si anda.
	var bulb := _cyl(cube, 0.035, 0.035, 0.03, lamp, WARM if not burnt else SOOT, Vector3(90, 0, 0))
	if not burnt:
		_lit(bulb, WARM, 1.6)
	else:
		# Tiznada arriba de donde se quemó.
		var top := 0.165 if design == 0 else (0.185 if design == 3 else H)
		Clay.box(cube, Vector3(0.16, 0.14, 0.008), Vector3(lamp.x, minf(lamp.y + 0.09, top - 0.075), H), SOOT)


## UNA CAJA DE MUNICIÓN: lisa, con su tapa y una etiqueta plana del color de lo que lleva.
func _crate(cube: Node3D, body: Color, label: Color) -> void:
	Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, body)
	Clay.box(cube, Vector3(U + 0.006, 0.02, U + 0.006), Vector3(0, 0.2, 0), body.darkened(0.3))
	Clay.box(cube, Vector3(0.34, 0.2, 0.008), Vector3(0, -0.04, H), CREAM)
	Clay.box(cube, Vector3(0.34, 0.05, 0.01), Vector3(0, -0.04, H + 0.002), label)


## LOS MISILES, EN LA MECA: un cubo con nueve tubos en la cara; cada misil que queda asoma la punta.
func _missiles(cube: Node3D, left: int) -> void:
	Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, STEEL)
	for index in 9:
		var at := Vector3((index % 3 - 1) * 0.195, (1 - float(index / 3)) * 0.195, H)
		_cyl(cube, 0.08, 0.08, 0.012, at, SOOT, Vector3(90, 0, 0))
		if index < left:
			_cyl(cube, 0.0, 0.066, 0.11, at + Vector3(0, 0, 0.05), MUSTARD, Vector3(90, 0, 0))


## LAS BALAS, EN LA MECA: un cubo con una ventana donde se ve la cinta, en cuatro columnas apretadas de balas finas y
## largas; baja a medida que se gasta.
const BELT_ROWS := 19


func _belt(cube: Node3D, rows: int) -> void:
	Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, STEEL)
	Clay.box(cube, Vector3(0.55, 0.55, 0.012), Vector3(0, 0, H), SOOT)
	for column in 4:
		var x := (column - 1.5) * 0.132
		for row in rows:
			var y := -0.243 + row * 0.027
			_cyl(cube, 0.0105, 0.0105, 0.08, Vector3(x - 0.02, y, H + 0.014), LEAD.lightened(0.15), Vector3(0, 0, 90), 6)
			_cyl(cube, 0.0, 0.0105, 0.04, Vector3(x + 0.04, y, H + 0.014), CREAM, Vector3(0, 0, -90), 6)


## LA BOMBA: nueve cartuchos de dinamita parados, con una faja ancha de papel, y la mecha en el del medio.
func _dynamite(cube: Node3D) -> void:
	var radius := U / 6.0
	for a in 3:
		for b in 3:
			var at := Vector3((a - 1) * radius * 2.0, 0.0, (b - 1) * radius * 2.0)
			_cyl(cube, radius - 0.004, radius - 0.004, U - 0.03, at, DYNAMITE, Vector3(0, 22.5, 0))
			_cyl(cube, radius * 0.72, radius * 0.72, U, at, DYNAMITE.darkened(0.35), Vector3(0, 22.5, 0))
	Clay.box(cube, Vector3(U + 0.006, 0.2, U + 0.006), Vector3.ZERO, CREAM)
	_cyl(cube, 0.012, 0.012, 0.09, Vector3(0, H + 0.04, 0), Color(0.3, 0.27, 0.22), Vector3.ZERO, 6)


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
