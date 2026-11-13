extends Node3D

## MAQUETAS DE ARCILLA DE LAS TOBERAS (13/11/2026), PARA ELEGIR ANTES DE HACER: las de DIRECCIÓN (atrás, giran hacia
## donde empuja el impulso; adelante, un par para ir para atrás) y las de VOLAR (cuatro, en las esquinas de abajo), por
## separado. No toca el código de la meca: arma encima de una meca parada y esconde las toberas de las caras. Lo que
## empuja lleva su llama naranja.
## Escribe dos hojas: `toberas_direccion.png` y `toberas_volar.png`.
##   tools/godot_ventana.sh res://tests/nozzle_ideas_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const STEEL := Color(0.3, 0.31, 0.34)
## Cuánto se inclinan las de atrás en un impulso de costado (el usuario: «medias inclinadas… no tanto»).
const SIDE_TILT := 35.0

var _folder := ""
## Qué hoja: `direccion`, `volar` o `esquinas`; vacío, todas.
var _sheet := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _mock: Node3D = null
var _flame: StandardMaterial3D = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--hoja="):
			_sheet = argument.trim_prefix("--hoja=")
	get_window().size = VIEW
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 120.0, 0.0)
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
	_flame = StandardMaterial3D.new()
	_flame.albedo_color = Color(1.0, 0.55, 0.15)
	_flame.emission_enabled = true
	_flame.emission = Color(1.0, 0.5, 0.1)
	_flame.emission_energy_multiplier = 2.0
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.POSE
	_mech.position = Vector3(0.0, BodySettings.current.hover_height + CabinGrid.HALF_HEIGHT, 0.0)
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
	for part in _mech.look.get_children():
		if part.get_class() == "Node3D" and not part.find_children("*", "GPUParticles3D", true, false).is_empty():
			(part as Node3D).visible = false
	if _sheet.is_empty() or _sheet == "direccion":
		await _direction_sheet()
	if _sheet.is_empty() or _sheet == "volar":
		await _flight_sheet()
	if _sheet.is_empty() or _sheet == "esquinas":
		await _corner_sheet()
	get_tree().quit()


## ── LAS DE DIRECCIÓN ──────────────────────────────────────────────────────────────────────────────────────────────

func _direction_sheet() -> void:
	var h := CabinGrid.HALF
	var names := ["1. Tres arriba, en el borde de atrás del techo", "2. Tres abajo, en el borde de atrás",
		"3. Dos por costado, pegadas a la esquina de atrás", "4. Dos grandes, en las esquinas de atrás del techo"]
	var shots: Array = []
	for variant in names.size():
		for dash: String in ["adelante", "a la derecha"]:
			_clear()
			# Hacia dónde echan: adelante, todo para atrás; a la derecha, para atrás y a la izquierda, sin exagerar.
			var tilt := deg_to_rad(SIDE_TILT) if dash == "a la derecha" else 0.0
			var out := Vector3(-sin(tilt), 0.0, cos(tilt))
			match variant:
				0:
					for x: float in [-2.5, 0.0, 2.5]:
						_mount(Vector3(x, h + 0.25, h - 0.45), Vector3(1.0, 0.5, 0.9))
						_nozzle(Vector3(x, h + 0.75, h - 0.3), out, 0.42, true)
				1:
					for x: float in [-2.5, 0.0, 2.5]:
						_mount(Vector3(x, -h - 0.25, h - 0.45), Vector3(1.0, 0.5, 0.9))
						_nozzle(Vector3(x, -h - 0.75, h - 0.3), out, 0.42, true)
				2:
					for side: float in [-1.0, 1.0]:
						for y: float in [0.6, 2.8]:
							_mount(Vector3(side * (h + 0.25), y, h - 0.6), Vector3(0.5, 0.9, 0.9))
							_nozzle(Vector3(side * (h + 0.75), y, h - 0.45), out, 0.38, true)
				3:
					for side: float in [-1.0, 1.0]:
						_mount(Vector3(side * (h - 0.8), h + 0.3, h - 0.8), Vector3(1.4, 0.6, 1.4))
						_nozzle(Vector3(side * (h - 0.8), h + 1.05, h - 0.5), out, 0.7, true)
			_title.text = "%s · impulso %s" % [names[variant], dash]
			_look(Vector3(15.0, 6.0, 21.0), Vector3(0.0, 0.0, 1.0), 36.0)
			shots.append(await _grab())
	# Para atrás: el par de adelante, debajo del vidrio (lo mismo para cualquiera de las cuatro).
	_clear()
	var front := -h - CabinGrid.GLASS_OUT
	for x: float in [-2.2, 2.2]:
		_mount(Vector3(x, -h - 0.25, front + 0.5), Vector3(1.0, 0.5, 0.9))
		_nozzle(Vector3(x, -h - 0.75, front + 0.35), Vector3.FORWARD, 0.42, true)
	_title.text = "5. Para ir para atrás: un par adelante, debajo del vidrio"
	_look(Vector3(-13.0, -2.0, -19.0), Vector3(0.0, -2.5, 0.0), 36.0)
	shots.append(await _grab())
	_title.text = "5. El mismo par, de costado"
	_look(Vector3(-20.0, -4.0, -3.0), Vector3(0.0, -3.0, -2.0), 36.0)
	shots.append(await _grab())
	_save(shots, "toberas_direccion")


## ── LAS DE VOLAR ──────────────────────────────────────────────────────────────────────────────────────────────────

func _flight_sheet() -> void:
	var h := CabinGrid.HALF
	var corner := h - 0.7
	var names := ["A. Una por esquina, debajo, para abajo", "B. Un módulo por esquina, con dos",
		"C. Una por esquina, abierta hacia afuera", "D. Una por esquina, colgada afuera de la caja"]
	var shots: Array = []
	for variant in names.size():
		_clear()
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				match variant:
					0:
						_mount(Vector3(sx * corner, -h - 0.2, sz * corner), Vector3(1.0, 0.4, 1.0))
						_nozzle(Vector3(sx * corner, -h - 0.7, sz * corner), Vector3.DOWN, 0.45, true)
					1:
						_mount(Vector3(sx * corner, -h - 0.35, sz * corner), Vector3(1.4, 0.7, 1.4))
						for dx: float in [-0.35, 0.35]:
							_nozzle(Vector3(sx * corner + dx, -h - 0.95, sz * corner), Vector3.DOWN, 0.3, true)
					2:
						_mount(Vector3(sx * corner, -h - 0.2, sz * corner), Vector3(1.0, 0.4, 1.0))
						_nozzle(Vector3(sx * corner, -h - 0.7, sz * corner),
							(Vector3.DOWN + Vector3(sx, 0.0, sz) * 0.3).normalized(), 0.45, true)
					3:
						_mount(Vector3(sx * (h + 0.35), -h + 0.5, sz * corner), Vector3(0.7, 1.2, 0.9))
						_nozzle(Vector3(sx * (h + 0.5), -h - 0.35, sz * corner), Vector3.DOWN, 0.45, true)
		_title.text = names[variant]
		_look(Vector3(-14.0, -8.0, -17.0), Vector3(0.0, -4.0, 0.0), 36.0)
		shots.append(await _grab())
		_look(Vector3(19.0, -7.0, 9.0), Vector3(0.0, -4.0, 0.0), 36.0)
		shots.append(await _grab())
	_save(shots, "toberas_volar")


## ── LAS CUATRO DE LAS ESQUINAS, QUE HACEN TODO (13/11/2026) ─────────────────────────────────────────────────────
## El usuario: «el de las cuatro en las esquinas, pero más chunky y que no sobresalgan tanto para abajo… en varias
## posiciones… adelante… atrás… al costado, porque tal vez con eso ya se entiende y no hagan falta los otros sets». Las
## cuatro giran juntas en su rótula: echan para abajo y, para empujar a un lado, se inclinan hacia el otro.

## Cuánto se inclinan para empujar de costado (grados desde abajo).
const PUSH_TILT := 40.0


func _corner_sheet() -> void:
	for arm in _mech.arms:
		arm.visible = false
	var h := CabinGrid.HALF
	var corner := h - 0.95
	# Hacia dónde empujan, en el espacio de la caja (−Z adelante); vacío, sólo para arriba.
	var pushes := [["volar (sólo para arriba)", Vector3.ZERO], ["impulso adelante", Vector3.FORWARD],
		["impulso para atrás", Vector3.BACK], ["impulso a la derecha", Vector3.RIGHT],
		["adelante y a la izquierda", (Vector3.FORWARD + Vector3.LEFT).normalized()]]
	var shots: Array = []
	for push: Array in pushes:
		_clear()
		var way: Vector3 = push[1]
		# Echan para abajo y hacia el lado contrario del empuje.
		var out := (Vector3.DOWN * cos(deg_to_rad(PUSH_TILT)) - way * sin(deg_to_rad(PUSH_TILT))).normalized() 			if way != Vector3.ZERO else Vector3.DOWN
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var at := Vector3(sx * corner, -h, sz * corner)
				# La base, ancha y baja, pegada a la caja: casi no baja.
				_mount(at + Vector3(0, -0.15, 0), Vector3(1.7, 0.3, 1.7))
				_chunky(at + Vector3(0, -0.55, 0), out)
		_title.text = "Las cuatro de las esquinas · %s" % push[0]
		_look(Vector3(-21.0, -5.0, -6.0), Vector3(0.0, -4.5, -0.5), 34.0)
		shots.append(await _grab())
		# De atrás y abajo: la derecha de la meca es la derecha de la foto.
		_look(Vector3(3.0, -7.5, 21.0), Vector3(0.0, -4.5, 0.0), 34.0)
		shots.append(await _grab())
	for arm in _mech.arms:
		arm.visible = true
	_save(shots, "toberas_esquinas")


## UNA TOBERA CHUNKY: una rótula grande y una campana corta y ancha que echa hacia `out`, con su llama.
func _chunky(at: Vector3, out: Vector3) -> void:
	var mount := Node3D.new()
	var up := Vector3.FORWARD if absf(out.y) > 0.9 else Vector3.UP
	mount.transform = Transform3D(Basis.looking_at(out, up), at)
	_mock.add_child(mount)
	Clay.sphere(mount, 0.55, Vector3.ZERO, STEEL)
	var bell := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.72
	cone.bottom_radius = 0.5
	cone.height = 0.7
	bell.mesh = cone
	bell.material_override = Clay.material(Clay.DARK)
	bell.rotation_degrees = Vector3(-90, 0, 0)
	bell.position = Vector3(0, 0, -0.55)
	mount.add_child(bell)
	var flame := MeshInstance3D.new()
	var tongue := CylinderMesh.new()
	tongue.top_radius = 0.0
	tongue.bottom_radius = 0.6
	tongue.height = 2.2
	flame.mesh = tongue
	flame.material_override = _flame
	flame.rotation_degrees = Vector3(-90, 0, 0)
	flame.position = Vector3(0, 0, -0.9 - 1.1)
	mount.add_child(flame)


## ── LAS PIEZAS ────────────────────────────────────────────────────────────────────────────────────────────────────

func _clear() -> void:
	if is_instance_valid(_mock):
		_mock.free()
	_mock = Node3D.new()
	_mech.cabin.add_child(_mock)


## Donde se agarra una tobera a la caja: una pieza maciza.
func _mount(at: Vector3, size: Vector3) -> void:
	Clay.box(_mock, size, at, STEEL)


## UNA TOBERA QUE GIRA: la rótula (una bola) y la campana, que echa hacia `out`; si empuja, su llama.
func _nozzle(at: Vector3, out: Vector3, radius: float, firing: bool) -> void:
	var mount := Node3D.new()
	var up := Vector3.UP if absf(out.y) < 0.9 else Vector3.FORWARD
	mount.transform = Transform3D(Basis.looking_at(out, up), at)
	_mock.add_child(mount)
	Clay.sphere(mount, radius * 0.75, Vector3.ZERO, STEEL)
	var bell := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	# El cilindro va sobre su Y, que el giro lleva a −Z: arriba es la boca, ancha.
	cone.top_radius = radius
	cone.bottom_radius = radius * 0.6
	cone.height = radius * 1.8
	bell.mesh = cone
	bell.material_override = Clay.material(Clay.DARK)
	bell.rotation_degrees = Vector3(-90, 0, 0)
	bell.position = Vector3(0, 0, -radius * 1.2)
	mount.add_child(bell)
	if not firing:
		return
	var flame := MeshInstance3D.new()
	var tongue := CylinderMesh.new()
	tongue.top_radius = 0.0
	tongue.bottom_radius = radius * 0.85
	tongue.height = radius * 4.0
	flame.mesh = tongue
	flame.material_override = _flame
	flame.rotation_degrees = Vector3(-90, 0, 0)
	flame.position = Vector3(0, 0, -radius * 2.1 - radius * 2.0)
	mount.add_child(flame)


## ── CÁMARA Y HOJAS ────────────────────────────────────────────────────────────────────────────────────────────────

func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _mech.global_transform * from
	_eye.look_at(_mech.global_transform * to, Vector3.UP)


## Dos columnas, a la mitad.
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
