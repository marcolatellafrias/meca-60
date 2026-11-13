extends Node3D

## MAQUETAS DE ARCILLA (13/11/2026), PARA ELEGIR ANTES DE HACER: el vidrio del frente que sobresale y las toberas
## nuevas debajo de la caja. No toca el código de la meca: arma encima de una meca discreta parada, con sus maniquíes
## sentados, y esconde lo que reemplaza (el vidrio plano del frente, las toberas de las caras).
## Escribe dos hojas: `frente_ideas.png` (cada variante de afuera y desde el asiento) y `toberas_ideas.png`.
##   tools/godot_ventana.sh res://tests/front_ideas_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
## Cuánto sobresale el vidrio (celdas): medio módulo.
const OUT_CELLS := 24
const BAR := 0.07
const STEEL := Color(0.3, 0.31, 0.34)

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _mock: Node3D = null
var _front: Array[Node3D] = []
var _nozzles: Array[Node3D] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	for i in 30:
		# Marcas en el piso, para leer lo que se ve para abajo.
		Clay.box(self, Vector3(0.3, 0.02, 0.3), Vector3(float(i % 6) * 4.0 - 10.0, 0.01, -float(i / 6) * 4.0 - 4.0),
			Color(0.55, 0.5, 0.45))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -60.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	world.environment.ambient_light_energy = 1.0
	add_child(world)
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.POSE
	_mech.position = Vector3(0.0, BodySettings.current.hover_height + Mech.SIZE * 0.5, 0.0)
	add_child(_mech)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 44)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	await get_tree().create_timer(3.0).timeout
	_mech.freeze = true
	if _mech.label != null:
		_mech.label.visible = false
	_find()
	for part in _nozzles:
		part.visible = false
	await _glass_sheet()
	await _nozzle_sheet()
	get_tree().quit()


## Lo que las maquetas reemplazan: el vidrio del frente (y sus parantes) y las toberas de las caras.
func _find() -> void:
	for part in _mech.cabin.get_children():
		var mesh := part as MeshInstance3D
		if mesh != null and mesh.position.z < -CabinGrid.INNER:
			_front.append(mesh)
	for part in _mech.look.get_children():
		if part.get_class() == "Node3D" and not part.find_children("*", "GPUParticles3D", true, false).is_empty():
			_nozzles.append(part as Node3D)


## ── EL VIDRIO ─────────────────────────────────────────────────────────────────────────────────────────────────────

func _glass_sheet() -> void:
	var out := OUT_CELLS * CabinGrid.CELL
	var full := CabinGrid.INNER * 2.0
	var shots: Array = []
	var seated: Array[Vector3] = []
	for chair in _mech.cabin.chairs:
		seated.append(chair.position)
	var names := [
		"1. Caja por piso, de ancho entero (sale %.2f m)" % out,
		"2. Caja por asiento, pisos de arriba",
		"3. Escalonada al revés: arriba sale más",
		"4. Burbuja por asiento, silla adentro",
		"5. Sin salir: dobla a los costados",
	]
	for variant in names.size():
		_reset()
		match variant:
			0:
				for index in CabinGrid.FLOORS:
					_bay(index, 0.0, full, out)
				_flat_front()
			1:
				for index: int in CabinGrid.SEATS:
					for column: int in CabinGrid.SEATS[index]:
						_bay(index, CabinGrid.column_x(column) + CabinGrid.MODULE * 0.5, CabinGrid.MODULE - 0.1, out)
				_flat_front([0])
			2:
				for index in CabinGrid.FLOORS:
					if index > 0:
						_bay(index, 0.0, full, out * index)
				_flat_front([0])
			3:
				var pod := out + 0.25
				for index: int in CabinGrid.SEATS:
					for column: int in CabinGrid.SEATS[index]:
						_bay(index, CabinGrid.column_x(column) + CabinGrid.MODULE * 0.5, 1.5, pod)
				for chair in _mech.cabin.chairs:
					chair.position.z -= pod + 0.15
				_flat_front([0])
			4:
				for index in CabinGrid.FLOORS:
					for side: float in [-1.0, 1.0]:
						_side_glass(index, side)
		_title.text = names[variant]
		_look(Vector3(-11.0, 1.5, -15.0), Vector3(0.0, -0.5, 0.0), 42.0)
		shots.append(await _grab())
		_dummies(false)
		_title.text = "%d. Desde el asiento de la izquierda del medio" % (variant + 1)
		var chair: SeatInteractable = _mech.cabin.chairs[0]
		_look_cabin(chair.position + Vector3(0.0, 1.15, -0.15), chair.position + Vector3(0.0, 0.2, -3.0), 80.0)
		shots.append(await _grab())
		_dummies(true)
		for i in seated.size():
			_mech.cabin.chairs[i].position = seated[i]
	_save(shots, "frente_ideas")
	_reset()


## Vuelve a lo de siempre: borra la maqueta y muestra el vidrio plano.
func _reset() -> void:
	if is_instance_valid(_mock):
		_mock.free()
	_mock = Node3D.new()
	_mech.cabin.add_child(_mock)
	for part in _front:
		part.visible = not _mech.cabin.posts.has(part) or CabinGrid.FRONT_POSTS


## El vidrio plano del frente, salvo en los pisos `keep`: lo reemplaza la maqueta.
func _flat_front(keep: Array = []) -> void:
	for part in _front:
		var floor_index := -1
		for index in CabinGrid.FLOORS:
			if part.position.y > CabinGrid.ground(index) and part.position.y < CabinGrid.ground(index + 1):
				floor_index = index
		part.visible = keep.has(floor_index) and (not _mech.cabin.posts.has(part) or CabinGrid.FRONT_POSTS)


## UNA CAJA QUE SOBRESALE en el piso `index`: centrada en `x`, de `width` de ancho y `out` hacia adelante. Vidrio al
## frente, a los costados, abajo y arriba, con sus aristas de metal fino para que se lea la forma.
func _bay(index: int, x: float, width: float, out: float) -> void:
	var bottom := CabinGrid.ground(index) - CabinGrid.SLAB
	var top := CabinGrid.ground(index) + CabinGrid.clear_height(index)
	var height := top - bottom
	var z0 := -CabinGrid.HALF
	var center := Vector3(x, bottom + height * 0.5, z0 - out * 0.5)
	Clay.box(_mock, Vector3(width, height, out), center, Clay.GLASS)
	# El piso de la caja: el borde de la losa sigue, fino, y el resto vidrio.
	Clay.box(_mock, Vector3(width, CabinGrid.SLAB * 0.5, BAR * 2.0), Vector3(x, CabinGrid.ground(index) - 0.03, z0 - BAR),
		STEEL)
	var half := Vector3(width, height, out) * 0.5
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			Clay.box(_mock, Vector3(BAR, BAR, out), center + Vector3(sx * half.x, sy * half.y, 0.0), STEEL)
			Clay.box(_mock, Vector3(width, BAR, BAR), center + Vector3(0.0, sy * half.y, sx * half.z), STEEL)
			Clay.box(_mock, Vector3(BAR, height, BAR), center + Vector3(sx * half.x, 0.0, sy * half.z), STEEL)
	# A los costados de la caja, hasta las paredes, el vidrio plano de siempre.
	for side: float in [-1.0, 1.0]:
		var edge := x + side * width * 0.5
		var wide := absf(side * CabinGrid.INNER - edge)
		if wide > 0.05:
			Clay.box(_mock, Vector3(wide, CabinGrid.clear_height(index), 0.04), Vector3((edge + side * CabinGrid.INNER)
				* 0.5, CabinGrid.ground(index) + CabinGrid.clear_height(index) * 0.5, -CabinGrid.HALF + CabinGrid.WALL
				* 0.5), Clay.GLASS)


## El costado del piso `index` del lado `side`, en su primer módulo (el de adelante), de vidrio.
func _side_glass(index: int, side: float) -> void:
	var y := CabinGrid.ground(index) + CabinGrid.clear_height(index) * 0.5
	var x := side * (CabinGrid.HALF - CabinGrid.WALL * 0.5)
	var z := CabinGrid.row_z(0) + CabinGrid.MODULE * 0.5
	# Tapa la pared de ese tramo con vidrio, un poco por fuera.
	Clay.box(_mock, Vector3(CabinGrid.WALL + 0.02, CabinGrid.clear_height(index), CabinGrid.MODULE + CabinGrid.WALL),
		Vector3(x, y, z - CabinGrid.WALL * 0.5), Color(0.62, 0.8, 0.9))
	var glass := Clay.GLASS
	Clay.box(_mock, Vector3(0.04, CabinGrid.clear_height(index), CabinGrid.MODULE), Vector3(x, y, z), glass)
	Clay.box(_mock, Vector3(0.04, CabinGrid.clear_height(index), CabinGrid.MODULE + CabinGrid.WALL),
		Vector3(side * (CabinGrid.HALF + 0.02), y, z - CabinGrid.WALL * 0.5), glass)


func _dummies(on: bool) -> void:
	for dummy in get_tree().root.find_children("*", "BoneInstantiator", true, false):
		(dummy as Node3D).visible = on


## ── LAS TOBERAS ───────────────────────────────────────────────────────────────────────────────────────────────────

func _nozzle_sheet() -> void:
	for arm in _mech.arms:
		arm.visible = false
	var bottom := -CabinGrid.HALF
	var shots: Array = []
	var names := [
		"A. Dos barras, adelante y atrás",
		"B. Cuatro módulos en las esquinas",
		"C. Corona en la pelvis, inclinadas",
		"D. Cuatro toberas en rótula",
	]
	for variant in names.size():
		_reset()
		var under := Node3D.new()
		_mech.look.add_child(under)
		match variant:
			0:
				for z: float in [-3.0, 3.0]:
					var y := bottom - 0.35
					Clay.box(under, Vector3(5.6, 0.5, 0.9), Vector3(0, y, z), STEEL)
					for x: float in [-1.8, 0.0, 1.8]:
						_nozzle(under, Vector3(x, y - 0.25, z), Vector3.DOWN, 0.32)
					for side: float in [-1.0, 1.0]:
						_nozzle(under, Vector3(side * 2.8, y, z), Vector3(side, 0, 0), 0.28)
					for x: float in [-1.0, 1.0]:
						_nozzle(under, Vector3(x, y, z + signf(z) * 0.45), Vector3(0, 0, signf(z)), 0.28)
			1:
				for sx: float in [-1.0, 1.0]:
					for sz: float in [-1.0, 1.0]:
						var at := Vector3(sx * 3.3, bottom - 0.5, sz * 3.2)
						Clay.box(under, Vector3(1.2, 1.0, 1.2), at, STEEL)
						_nozzle(under, at + Vector3(0, -0.5, 0), Vector3.DOWN, 0.35)
						_nozzle(under, at + Vector3(sx * 0.6, 0, 0), Vector3(sx, 0, 0), 0.3)
						_nozzle(under, at + Vector3(0, 0, sz * 0.6), Vector3(0, 0, sz), 0.3)
			2:
				var radius := PelvisLift.DRUM + 0.2
				var y := bottom - 0.6
				for degrees in [-60.0, -30.0, 0.0, 30.0, 60.0]:
					for sz: float in [-1.0, 1.0]:
						var way := Vector3(sin(deg_to_rad(degrees)), 0, sz * cos(deg_to_rad(degrees)))
						_nozzle(under, way * radius + Vector3(0, y, 0), (way + Vector3.DOWN).normalized(), 0.3)
			3:
				var tilts := [Vector3(-1, -1, 0), Vector3(0, -1, -1), Vector3(0, -1, 1), Vector3(1, -1, 0)]
				var places := [Vector3(-1.6, 0, -3.0), Vector3(1.6, 0, -3.0), Vector3(-1.6, 0, 3.0), Vector3(1.6, 0, 3.0)]
				for i in 4:
					var at: Vector3 = places[i] + Vector3(0, bottom - 0.45, 0)
					Clay.box(under, Vector3(1.0, 0.3, 1.0), at + Vector3(0, 0.3, 0), STEEL)
					Clay.sphere(under, 0.4, at, STEEL)
					_nozzle(under, at + (tilts[i] as Vector3).normalized() * 0.55, (tilts[i] as Vector3).normalized(), 0.42)
		_title.text = names[variant]
		_look(Vector3(-15.0, -9.0, -17.0), Vector3(0.0, -4.0, 0.0), 34.0)
		shots.append(await _grab())
		_look(Vector3(16.0, -9.0, 12.0), Vector3(0.0, -4.0, 0.0), 34.0)
		shots.append(await _grab())
		under.free()
	_save(shots, "toberas_ideas")


## Una tobera: una campana oscura que echa hacia `out`.
func _nozzle(parent: Node3D, at: Vector3, out: Vector3, radius: float) -> void:
	var mount := Node3D.new()
	var up := Vector3.UP if absf(out.y) < 0.9 else Vector3.FORWARD
	mount.transform = Transform3D(Basis.looking_at(out, up), at)
	parent.add_child(mount)
	Clay.cylinder(mount, radius, radius * 1.6, Vector3(0, 0, -radius * 0.8), Clay.DARK, Vector3(90, 0, 0))


## ── CÁMARA Y HOJAS ────────────────────────────────────────────────────────────────────────────────────────────────

func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _mech.global_transform * from
	_eye.look_at(_mech.global_transform * to, Vector3.UP)


func _look_cabin(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _mech.cabin.global_transform * from
	_eye.look_at(_mech.cabin.global_transform * to, Vector3.UP)


## Dos columnas (afuera y adentro, o las dos vistas), una fila por variante, a la mitad.
func _save(shots: Array, file: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first: Image = shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(shots.size() / 2.0), false, first.get_format())
	for index in shots.size():
		var shot: Image = shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/%s.png" % [_folder, file]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
