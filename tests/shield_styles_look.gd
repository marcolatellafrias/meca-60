extends Node

## TRES CAMINOS PARA EL ESCUDO, SACADOS DE OTROS JUEGOS (MechShield.look «style»; 18/11/2026, el usuario: «no me gusta
## ninguno… tomar inspiración de algún otro juego… campos de fuerza que no sean circulares o que dejan algunas partes por
## afuera»): 1) pegado al cuerpo y siempre visible (el Overshield de Halo, el Pulse Armor de Armored Core 6); 2) pegado al
## cuerpo y casi invisible, que se enciende donde pega el golpe (el escudo de Halo); 3) una pantalla curva de frente (la
## de Reinhardt en Overwatch). La hoja: las tres, cada una de cerca (la 2 quieta y en el golpe; la 3 también de costado) y
## desde adentro.
##   tools/godot_ventana.sh res://tests/shield_styles_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const GAP := 12.0
const LOOKS: Array[Dictionary] = [
	{"style": "cuerpo", "torso": false, "facets": -1, "center": 0.12, "rim": 0.6, "lines": 0.0, "grow": 0.06},
	{"style": "cuerpo", "torso": false, "facets": -1, "center": 0.0, "rim": 0.12, "lines": 0.0, "grow": 0.06},
	{"style": "frente", "torso": false, "facets": -1, "center": 0.08, "rim": 0.35, "lines": 0.0, "grow": 0.0},
]

var _folder := ""
var _eye: Camera3D = null
var _shots: Array = []
var _mechs: Array[CageMech] = []
var _numbers: Array[Label3D] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
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
	for index in LOOKS.size():
		var mech := CageMech.new()
		mech.equipment = CageMechArchetype.ROW
		mech.position = Vector3((1 - index) * GAP, Mech.standing_height(mech.cabin_shape), 0.0)
		add_child(mech)
		_mechs.append(mech)
		var number := Label3D.new()
		number.text = str(index + 1)
		number.font_size = 160
		number.pixel_size = 0.01
		number.outline_size = 24
		number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		number.position = mech.position + Vector3(0.0, 4.3, 0.0)
		add_child(number)
		_numbers.append(number)
	await get_tree().create_timer(1.0).timeout
	for index in _mechs.size():
		var mech := _mechs[index]
		mech.label.visible = false
		mech.shield.look = LOOKS[index].duplicate()
		mech.shield.dress()
		(mech.keys as ToolMechKeys).cockpit.shield = true
		var cabin := mech.cabin as CageCabin
		for seat in CageCabin.SEAT_NAMES.size():
			cabin.evict(seat)
	await get_tree().create_timer(0.8).timeout
	await _shot(Vector3(-3.0, 6.0, -26.0), Vector3(0.0, 2.5, 0.0), 60.0)
	# De cerca, cada una con su número solo; la 2 también en el momento de un golpe en el pecho; la 3 también de costado.
	for index in _mechs.size():
		for other in _numbers.size():
			_numbers[other].visible = other == index
		var mech := _mechs[index]
		var front := mech.global_position + Vector3(-5.0, 1.0, -10.0)
		await _shot(front, mech.global_position, 50.0)
		if index == 1:
			await _hit(mech)
			await _shot(front, mech.global_position, 50.0)
		if index == 2:
			await _shot(mech.global_position + Vector3(-12.0, 1.5, 3.0), mech.global_position, 50.0)
	for number in _numbers:
		number.visible = false
	var form := CageCabin.shape()
	for index in _mechs.size():
		var mech := _mechs[index]
		if index == 1:
			await _hit(mech)
		var cabin := mech.cabin as CageCabin
		var seat := cabin.board_root().global_transform * CageCabin.driver_eye(form)
		await _shot(seat, seat - mech.global_basis.z, 85.0)
	_save()
	get_tree().quit()


## UN GOLPE FRENADO EN EL PECHO (como lo avisaría un jefe: block_hit con dónde pegó), y un instante para que se vea.
func _hit(mech: CageMech) -> void:
	mech.block_hit(mech.global_position - mech.global_basis.z * 1.6 + Vector3.UP * 0.3)
	await get_tree().create_timer(0.1).timeout


## El escudo prendido todo el tiempo: la energía, siempre llena.
func _physics_process(_delta: float) -> void:
	for mech in _mechs:
		mech.energy.level = 1.0


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


func _save() -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var columns := 3
	var rows := ceili(_shots.size() / float(columns))
	var sheet := Image.create(first.get_width() * columns, first.get_height() * rows, false, first.get_format())
	for index in _shots.size():
		sheet.blit_rect(_shots[index], Rect2i(Vector2i.ZERO, first.get_size()),
			Vector2i(first.get_width() * (index % columns), first.get_height() * (index / columns)))
	var path := "%s/escudos_caminos.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
