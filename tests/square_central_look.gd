extends Node3D

## LA CUADRADA CON LO DE LA REDONDA, MAQUETA DE ARCILLA (15/11/2026, el usuario: «antes de descartar por completo la
## cuadrada, quisiera aplicar lo que aprendimos en esta nueva cilíndrica… tarima al medio con ascensor inscripto y flujo
## continuo alrededor y sillas sin tableros»; de las plantas, la 1: «mostrame cómo sonaría la primera con la misma altura
## que tiene la chata, el disco chato ahora»).
##   · LA CAJA CUADRADA de 6,14 m por dentro, con el vidrio al frente y en la mitad de adelante de los costados.
##   · LAS ALTURAS DE LA REDONDA GUARDADA (RoundGrid): la cabina, las losas y el disco de abajo; techo plano.
##   · LA TARIMA CUADRADA AL MEDIO, con un escalón todo alrededor; el ascensor adentro, atrás; el movimiento delante.
##   · TRES SILLAS EN FILA, mirando al frente, sin tableros; los recursos al ras de la pared de atrás.
## Sobre la meca de verdad (sus piernas y sus brazos; la caja escondida).
##   tools/godot_ventana.sh res://tests/square_central_look.tscn -- --salida=C:/carpeta [--escalonada]
## `--escalonada` (el usuario, 15/11/2026: «toda la parte desde donde está el del medio sea más elevada y tenga
## escalones, pero que ocupen todo el ancho… solamente hacia la dirección de los del frente… el ascensor sea un recuadro
## al final de la pared de atrás… de extremo a extremo… los 7 componentes en las paredes izquierda y derecha… reduciría
## la abertura lateral del vidrio»; y más baja: la cabina de 2,3 m y el disco de 1 m, los de la chata).

const VIEW := Vector2i(1280, 720)
const IN := 3.07
const WALL := 0.24
const PLATFORM := 2.4
const STEP := 0.3
const PLATFORM_TALL := 0.3
const LIFT_R := 0.5
const LIFT_AT := 0.55

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.42, 0.44, 0.47)
const FLOOR := Color(0.62, 0.63, 0.65)
const DECK := Color(0.7, 0.71, 0.73)
const SEAT := Color(0.25, 0.42, 0.7)
const PERSON := Color(0.93, 0.93, 0.93)
const LIFT := Color(0.3, 0.45, 0.75)
const KIT := Color(0.78, 0.27, 0.27)
const BATTERY := Color(0.93, 0.75, 0.16)
const AMMO := Color(0.47, 0.53, 0.32)
const GLASS_OUTSIDE := Color(0.5, 0.66, 0.76, 0.38)
const GLASS_INSIDE := Color(0.6, 0.8, 0.92, 0.14)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _real: Mech = null
var _shell := Node3D.new()
var _glass_paint := StandardMaterial3D.new()
var _roof: Node3D = null
var _clear := 2.3
var _disc := 1.0
var _slab := 0.22
var _stepped := false


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	_stepped = OS.get_cmdline_user_args().has("--escalonada")
	_clear = 2.3 if _stepped else RoundGrid.CLEAR
	_disc = 1.0 if _stepped else RoundGrid.DISC
	_slab = RoundGrid.SLAB
	# La meca de verdad, sin cabina, con la caja de esta (12 celdas de 51 cm por lado y el alto de la redonda).
	var form := CabinGrid.current()
	form.cell = 13
	form.across = 12
	form.height_cells = roundi((_disc + _clear + _slab * 2.0 - CabinGrid.SLAB * 2.0) / CabinGrid.CELL)
	# `--hombro=2`: cuánto salen los hombros del costado (ver CabinGrid.SHOULDER_OUT).
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--hombro="):
			form.shoulder_out = float(argument.trim_prefix("--hombro="))
	CabinGrid.apply(form)
	_real = Mech.new()
	_real.has_cabin = false
	_real.arms_kind = Mech.Arms.POSE
	_real.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_real)
	await get_tree().create_timer(2.5).timeout
	_real.freeze = true
	if _real.label != null:
		_real.label.visible = false
	for part in _real.look.get_children():
		if part is MeshInstance3D and (part as MeshInstance3D).mesh is BoxMesh:
			(part as MeshInstance3D).visible = false
	_real.look.add_child(_shell)
	_shell.position.y = -CabinGrid.HALF_HEIGHT + _disc + _slab
	_glass_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass_paint.roughness = 0.15
	if _stepped:
		_build_stepped()
	else:
		_build()
	print("CUADRADA: %.2f m de lado · cabina %.2f m · disco %.2f m · la caja a %.2f m del piso" % [(IN + WALL) * 2.0, _clear,
		_disc, Mech.standing_height()])
	var shots: Array = []
	_glass_paint.albedo_color = GLASS_OUTSIDE
	_title.text = "1. De frente"
	_look(Vector3(-15.0, 0.0, -24.0), Vector3(0.0, -4.0, 0.0), 45.0)
	shots.append(await _grab())
	_title.text = "2. De costado"
	_look(Vector3(-28.0, -2.0, -5.0), Vector3(0.0, -4.0, 0.0), 42.0)
	shots.append(await _grab())
	_title.text = "3. De atrás"
	_look(Vector3(14.0, 0.0, 23.0), Vector3(0.0, -4.0, 0.0), 45.0)
	shots.append(await _grab())
	_glass_paint.albedo_color = GLASS_INSIDE
	_title.text = "4. Adentro, desde atrás"
	_look(Vector3(0.6, 1.8, IN - 0.4), Vector3(-0.2, 0.7, -3.0), 85.0)
	shots.append(await _grab())
	_title.text = "5. Adentro, desde el costado de adelante"
	_look(Vector3(-2.6, 1.7, -1.6), Vector3(1.0, 0.6, 1.5), 85.0)
	shots.append(await _grab())
	_roof.visible = false
	_title.text = "6. Desde arriba, sin techo"
	_look(Vector3(-2.0, 11.0, 4.0), Vector3(0.0, 0.0, -0.3), 50.0)
	shots.append(await _grab())
	_save(shots)
	get_tree().quit()


func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -40.0, 0.0)
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
	_eye = Camera3D.new()
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


## ── LA CAJA (el origen, en el piso de la cabina) ─────────────────────────────────────────────────────────────────

func _build() -> void:
	var half := IN + WALL
	var mid := _clear * 0.5
	# El disco de abajo (cuadrado, como la caja), el piso y el techo.
	Clay.box(_shell, Vector3(half * 2.0, _disc, half * 2.0), Vector3(0, -_slab - _disc * 0.5, 0), DARK_METAL)
	Clay.box(_shell, Vector3(half * 2.0 + 0.12, 0.12, half * 2.0 + 0.12), Vector3(0, -_slab, 0), METAL.darkened(0.25))
	Clay.box(_shell, Vector3(half * 2.0, _slab, half * 2.0), Vector3(0, -_slab * 0.5, 0), FLOOR)
	_roof = Clay.box(_shell, Vector3(half * 2.0, _slab, half * 2.0), Vector3(0, _clear + _slab * 0.5, 0), METAL)
	# Atrás, de metal: la pared y la mitad de atrás de los costados. Adelante, el vidrio: el frente y la mitad de
	# adelante de los costados.
	Clay.box(_shell, Vector3(half * 2.0, _clear, WALL), Vector3(0, mid, IN + WALL * 0.5), METAL)
	for side: float in [-1.0, 1.0]:
		Clay.box(_shell, Vector3(WALL, _clear, half), Vector3(side * (IN + WALL * 0.5), mid, half * 0.5), METAL)
		_glass(Vector3(0.04, _clear, half), Vector3(side * (half - 0.02), mid, -half * 0.5))
	_glass(Vector3(half * 2.0, _clear, 0.04), Vector3(0, mid, -half + 0.02))
	# La tarima con su escalón, el ascensor adentro y atrás.
	Clay.box(_shell, Vector3(PLATFORM + STEP * 2.0, PLATFORM_TALL * 0.5, PLATFORM + STEP * 2.0),
		Vector3(0, PLATFORM_TALL * 0.25, 0), DECK.darkened(0.08))
	Clay.box(_shell, Vector3(PLATFORM, PLATFORM_TALL, PLATFORM), Vector3(0, PLATFORM_TALL * 0.5, 0), DECK)
	Clay.cylinder(_shell, LIFT_R, 0.04, Vector3(0, PLATFORM_TALL + 0.02, LIFT_AT), LIFT)
	# Las sillas: tres en fila al frente y el movimiento en la tarima, delante del ascensor.
	for x: float in [-1.9, 0.0, 1.9]:
		_post(Vector3(x, 0.0, -2.25))
	_post(Vector3(0.0, PLATFORM_TALL, LIFT_AT - LIFT_R - 0.5))
	# Atrás, al ras de la pared: los kits a los costados, las dos municiones y la batería al medio.
	var back := IN - 0.06
	for x: float in [-2.4, -1.7, 1.7, 2.4]:
		Clay.box(_shell, Vector3(0.55, 0.55, 0.12), Vector3(x, 0.6, back), KIT)
	for x: float in [-0.6, 0.6]:
		Clay.box(_shell, Vector3(0.6, 0.6, 0.12), Vector3(x, 1.4, back), AMMO)
	Clay.box(_shell, Vector3(0.4, 0.5, 0.12), Vector3(0.0, 0.6, back), BATTERY)


## LA ESCALONADA: de la silla del medio hacia atrás, el piso elevado de pared a pared, con escalones de pared a pared
## que bajan sólo hacia adelante; el ascensor, una franja contra la pared de atrás, de pared a pared; los siete
## recursos en las paredes de los costados, sobre lo elevado; el vidrio de los costados, corto.
const RAISED := 0.45
const RAISED_FROM := -0.9
const STEPS := 3
const TREAD := 0.32
const LIFT_DEEP := 1.1
const SIDE_GLASS := 1.3


func _build_stepped() -> void:
	var half := IN + WALL
	var mid := _clear * 0.5
	Clay.box(_shell, Vector3(half * 2.0, _disc, half * 2.0), Vector3(0, -_slab - _disc * 0.5, 0), DARK_METAL)
	Clay.box(_shell, Vector3(half * 2.0 + 0.12, 0.12, half * 2.0 + 0.12), Vector3(0, -_slab, 0), METAL.darkened(0.25))
	Clay.box(_shell, Vector3(half * 2.0, _slab, half * 2.0), Vector3(0, -_slab * 0.5, 0), FLOOR)
	_roof = Clay.box(_shell, Vector3(half * 2.0, _slab, half * 2.0), Vector3(0, _clear + _slab * 0.5, 0), METAL)
	# Las paredes: atrás, metal; los costados, vidrio sólo en su primer tramo; el frente, vidrio.
	Clay.box(_shell, Vector3(half * 2.0, _clear, WALL), Vector3(0, mid, IN + WALL * 0.5), METAL)
	var metal_from := -IN + SIDE_GLASS
	for side: float in [-1.0, 1.0]:
		Clay.box(_shell, Vector3(WALL, _clear, IN - metal_from), Vector3(side * (IN + WALL * 0.5), mid, (metal_from + IN) * 0.5),
			METAL)
		_glass(Vector3(0.04, _clear, SIDE_GLASS + WALL), Vector3(side * (half - 0.02), mid, -half + (SIDE_GLASS + WALL) * 0.5))
	_glass(Vector3(half * 2.0, _clear, 0.04), Vector3(0, mid, -half + 0.02))
	# Lo elevado, de pared a pared, desde la silla del medio hacia atrás, hasta el ascensor.
	var lift_from := IN - LIFT_DEEP
	Clay.box(_shell, Vector3(IN * 2.0, RAISED, lift_from - RAISED_FROM), Vector3(0, RAISED * 0.5, (RAISED_FROM + lift_from) * 0.5),
		DECK)
	# Los escalones, de pared a pared, bajando hacia adelante.
	for k in STEPS:
		var tall := RAISED * (k + 1) / (STEPS + 1)
		var z0 := RAISED_FROM - TREAD * (STEPS - k)
		Clay.box(_shell, Vector3(IN * 2.0, tall, TREAD), Vector3(0, tall * 0.5, z0 + TREAD * 0.5), DECK.darkened(0.04 * (STEPS - k)))
	# El ascensor: la franja de atrás, de pared a pared, al ras de lo elevado.
	Clay.box(_shell, Vector3(IN * 2.0 - 0.1, 0.06, LIFT_DEEP - 0.1), Vector3(0, RAISED - 0.03, (lift_from + IN) * 0.5), LIFT)
	# Las sillas: tres en fila al frente; el movimiento arriba, al medio, al borde de lo elevado.
	for x: float in [-1.9, 0.0, 1.9]:
		_post(Vector3(x, 0.0, -2.25))
	_post(Vector3(0.0, RAISED, RAISED_FROM + 0.5))
	# Los siete recursos, en las paredes de los costados, sobre lo elevado: a la izquierda dos kits, una munición y la
	# batería; a la derecha dos kits y la otra munición.
	var wall_x := IN - 0.06
	var along := [RAISED_FROM + 0.6, RAISED_FROM + 1.4, RAISED_FROM + 2.2, RAISED_FROM + 3.0]
	var left := [KIT, KIT, AMMO, BATTERY]
	var right := [KIT, KIT, AMMO]
	for i in left.size():
		_side_box(-wall_x, along[i], left[i])
	for i in right.size():
		_side_box(wall_x, along[i], right[i])


func _side_box(x: float, z: float, color: Color) -> void:
	var size := Vector2(0.5, 0.45) if color == BATTERY else Vector2(0.6, 0.6)
	Clay.box(_shell, Vector3(0.12, size.y, size.x), Vector3(x, RAISED + 0.5 + size.y * 0.5, z), color)


func _glass(size: Vector3, at: Vector3) -> void:
	var pane := Clay.box(_shell, size, at, Color.WHITE)
	pane.material_override = _glass_paint


## UN PUESTO: la silla y el que se sienta, mirando al frente.
func _post(at: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = at
	_shell.add_child(holder)
	Clay.box(holder, Vector3(0.55, 0.12, 0.5), Vector3(0, 0.45, 0.05), SEAT)
	Clay.box(holder, Vector3(0.55, 0.65, 0.1), Vector3(0, 0.8, 0.3), SEAT)
	Clay.cylinder(holder, 0.06, 0.4, Vector3(0, 0.2, 0.05), DARK_METAL)
	Clay.box(holder, Vector3(0.4, 0.6, 0.25), Vector3(0, 0.85, 0.15), PERSON)
	Clay.sphere(holder, 0.13, Vector3(0, 1.3, 0.12), PERSON)
	Clay.box(holder, Vector3(0.36, 0.14, 0.45), Vector3(0, 0.56, -0.12), PERSON)


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _shell.global_transform * from
	_eye.look_at(_shell.global_transform * to, Vector3.UP)


func _save(shots: Array) -> void:
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
	var path := "%s/%s.png" % [_folder, "cuadrada_escalonada" if _stepped else "cuadrada_central"]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
