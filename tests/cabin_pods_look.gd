extends Node3D

## LA MECA CUADRADA CON CABINAS DE A UNO, MAQUETA DE ARCILLA (15/11/2026, el usuario, sobre la de cuatro cabinas: «lo
## que hiciste en la 1 es lo que más se parece… los personajes irían sentados y las cabinas serían mucho más
## ajustadas… una especie de pasarela que conecte varias zonas… si los jugadores quieren cambiarse de cabina… sin
## necesidad de salirse de la meca… las cabinas van a ser elementos de la meca, no la meca… los cuadrados son un
## elemento conector, por ejemplo, que puede estar al centro del torso, no es el torso»). El cuerpo es de cajas macizas
## (torso, hombros, torreta); en cada parte, al frente, una cabina chica de vidrio con su piloto sentado, que asoma del
## cuerpo; la pasarela une las puertas de atrás de las cabinas. Una persona de verdad en la pasarela y otra en el piso.
##   1 · la pasarela atrás, un balcón con baranda, y una escalera a la torreta;
##   2 · la pasarela arriba, sobre los hombros y el torso, con escotillas sobre las cabinas;
##   3 · la pasarela adentro, un pasillo en el cuerpo detrás de las cabinas (la cuarta vista, el cuerpo en corte).
##   tools/godot_ventana.sh res://tests/cabin_pods_look.tscn -- --salida=C:/carpeta --variante=1

const VIEW := Vector2i(1280, 720)
const WALL := 0.1
const HIP := 3.6
const TORSO := Vector3(3.2, 2.8, 2.6)
const SHOULDER := Vector3(2.2, 2.2, 2.4)
const TURRET := Vector3(2.0, 1.8, 2.2)
## La cabina de uno, sentado: por fuera.
const POD := Vector3(1.2, 1.6, 1.5)
## Cuánto asoma la cabina del frente de su parte: casi entera, para que el piloto se vea desde afuera.
const POKE := 1.4
const NAMES := {1: "la pasarela atrás", 2: "la pasarela arriba", 3: "la pasarela adentro"}

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const FLOOR := Color(0.68, 0.69, 0.71)
const HATCH := Color(0.2, 0.21, 0.23)
const WALKWAY := Color(0.62, 0.55, 0.42)
const SKIN := Color(0.86, 0.66, 0.5)
const SEAT := Color(0.25, 0.42, 0.7)
const ACCENT := {"walk": Color(0.3, 0.45, 0.75), "arm": Color(0.8, 0.25, 0.2), "gun": Color(0.93, 0.75, 0.16)}

var _folder := ""
var _variant := 1
var _eye: Camera3D = null
var _title: Label = null
var _glass := StandardMaterial3D.new()
var _body_paint := StandardMaterial3D.new()


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
	get_window().size = VIEW
	_glass.albedo_color = Color(0.7, 0.85, 0.95, 0.15)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass.roughness = 0.1
	_body_paint.albedo_color = METAL
	_body_paint.roughness = 0.85
	_body_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	_stage()
	_mech()
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(4.6, 0.0, -2.6), -PI * 0.7)
	await get_tree().create_timer(3.0).timeout
	_title.text = "%d. %s" % [_variant, NAMES[_variant]]
	var middle := HIP + 1.0
	var views: Array = [
		[Vector3(-8.0, 7.0, -11.0), Vector3(0.0, middle, 0.0), 45.0],
		[Vector3(0.0, middle + 1.0, -14.0), Vector3(0.0, middle, 0.0), 40.0],
		[Vector3(8.5, 9.0, 10.0), Vector3(0.0, middle + 0.5, 0.0), 45.0],
		[Vector3(-3.0, 12.0, 6.0), Vector3(0.0, HIP + 2.0, 0.0), 50.0]]
	var shots: Array = []
	for index in views.size():
		var view: Array = views[index]
		if _variant == 3 and index == 3:
			# El cuerpo en corte: medio transparente, para ver el pasillo.
			_body_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_body_paint.albedo_color = Color(METAL, 0.25)
			view = [Vector3(7.0, 8.0, 9.0), Vector3(0.0, HIP + 1.0, 0.0), 45.0]
		_look(view[0], view[1], view[2])
		shots.append(await _grab())
	_save(shots)
	get_tree().quit()


## ── LA MECA ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _mech() -> void:
	var floor_y := HIP + 0.7
	# El torso: una caja maciza, y su cabina al frente, en el centro.
	var torso_center := Vector3(0.0, HIP + TORSO.y * 0.5, 0.0)
	_part(TORSO, torso_center)
	_pod(Vector3(0.0, floor_y, -TORSO.z * 0.5 - POKE + POD.z * 0.5), "walk")
	# Las piernas, de abajo del torso: muslo, rodilla, canilla y pie.
	for side: float in [-1.0, 1.0]:
		var from := Vector3(side * 1.0, HIP + 0.1, 0.0)
		var foot := Vector3(side * 1.1, 0.4, 0.0)
		var knee := Vector3(foot.x, (from.y + foot.y) * 0.5, -0.4)
		_bar(from, knee, 0.85, METAL)
		_bar(knee, foot, 0.75, METAL)
		Clay.box(self, Vector3(0.95, 0.95, 0.95), knee, DARK_METAL)
		Clay.box(self, Vector3(1.0, 0.4, 1.6), Vector3(foot.x, 0.2, -0.3), DARK_METAL)
	# Los hombros: cajas al costado, cada una con su cabina al frente y su brazo colgando.
	for side: float in [-1.0, 1.0]:
		var center := Vector3(side * (TORSO.x + SHOULDER.x) * 0.5, HIP + 1.8, 0.0)
		_part(SHOULDER, center)
		_pod(Vector3(center.x, floor_y, -SHOULDER.z * 0.5 - POKE + POD.z * 0.5), "arm")
		var from := center + Vector3(side * 0.5, -SHOULDER.y * 0.5, 0.3)
		var elbow := Vector3(from.x + side * 0.3, 1.9, 0.5)
		var fist := elbow + Vector3(0.0, -0.3, -1.5)
		_bar(from, elbow, 0.75, METAL)
		_bar(elbow, fist, 0.7, METAL)
		Clay.box(self, Vector3(0.95, 0.95, 1.05), fist, DARK_METAL)
	# La torreta: arriba del torso (en la 2, más atrás, para dejar la pasarela adelante), su cabina y dos caños.
	var turret_z := 0.4 if _variant == 2 else 0.1
	var turret_center := Vector3(0.0, HIP + TORSO.y + TURRET.y * 0.5, turret_z)
	_part(TURRET, turret_center)
	_pod(Vector3(0.0, HIP + TORSO.y + 0.1, turret_z - TURRET.z * 0.5 - POKE + POD.z * 0.5), "gun")
	for side: float in [-1.0, 1.0]:
		var at := turret_center + Vector3(side * (TURRET.x * 0.5 + 0.25), 0.1, -0.2)
		Clay.box(self, Vector3(0.5, 0.6, 1.2), at, DARK_METAL)
		Clay.box(self, Vector3(0.3, 0.3, 2.2), at + Vector3(0.0, 0.0, -1.7), DARK_METAL)
	match _variant:
		1:
			_walkway_back(floor_y)
		2:
			_walkway_top()
		3:
			_walkway_inside(floor_y)


## Una parte maciza del cuerpo.
func _part(size: Vector3, center: Vector3) -> void:
	var part := Clay.box(self, size, center, METAL)
	part.material_override = _body_paint


## UNA CABINA DE UNO, de piso en `base` (el centro de abajo): piso, techo y fondo de metal, los costados y el frente de
## vidrio sobre un antepecho, una franja del color de su puesto y el piloto sentado.
func _pod(base: Vector3, role: String) -> void:
	var half := POD * 0.5
	var center := base + Vector3(0.0, half.y, 0.0)
	var sill := 0.45
	Clay.box(self, Vector3(POD.x, WALL, POD.z), center + Vector3(0.0, -half.y + WALL * 0.5, 0.0), FLOOR)
	Clay.box(self, Vector3(POD.x, WALL * 1.5, POD.z), center + Vector3(0.0, half.y - WALL * 0.75, 0.0), METAL)
	Clay.box(self, Vector3(POD.x, POD.y, WALL), center + Vector3(0.0, 0.0, half.z - WALL * 0.5), METAL)
	for x: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.12, POD.y, 0.12), center + Vector3(x * (half.x - 0.06), 0.0, -half.z + 0.06), METAL)
	for wall: Array in [[Vector3(0, 0, -1), POD.x], [Vector3(-1, 0, 0), POD.z], [Vector3(1, 0, 0), POD.z]]:
		var out: Vector3 = wall[0]
		var width: float = wall[1]
		var reach := absf(out.dot(half))
		var turn := Basis(Vector3.UP, PI * 0.5) if absf(out.x) > 0.5 else Basis()
		var low := Clay.box(self, Vector3(width, sill, WALL), center + out * (reach - WALL * 0.5)
			+ Vector3(0.0, -half.y + sill * 0.5, 0.0), METAL)
		low.basis = turn
		var pane := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(width - 0.2, POD.y - sill - WALL * 1.5, 0.03)
		pane.mesh = mesh
		pane.material_override = _glass
		pane.basis = turn
		pane.position = center + out * (reach - 0.04) + Vector3(0.0, -half.y + sill + (POD.y - sill - WALL * 1.5) * 0.5,
			0.0)
		add_child(pane)
	Clay.box(self, Vector3(POD.x + 0.02, 0.12, POD.z + 0.02), center + Vector3(0.0, half.y - 0.2, 0.0), ACCENT[role])
	_seated(base + Vector3(0.0, WALL, 0.2))
	# Los mandos: una consola baja adelante.
	Clay.box(self, Vector3(0.6, 0.08, 0.22), base + Vector3(0.0, 0.62, -half.z + 0.3), DARK_METAL)


## UN PILOTO SENTADO, de arcilla, mirando adelante (−Z), con su asiento: `at`, el piso debajo del asiento.
func _seated(at: Vector3) -> void:
	Clay.box(self, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(self, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), SEAT)
	Clay.box(self, Vector3(0.08, 0.42, 0.08), at + Vector3(0.0, 0.21, 0.05), DARK_METAL)
	Clay.box(self, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(self, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(self, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.12, 0.42, 0.12), at + Vector3(side * 0.1, 0.27, -0.28), SKIN)
		Clay.box(self, Vector3(0.1, 0.1, 0.38), at + Vector3(side * 0.24, 0.8, -0.12), SKIN)


## LA PASARELA ATRÁS: un balcón de lado a lado a la altura del piso de las cabinas, con baranda; una puerta en el
## fondo de cada parte (el pasillo corto hasta la cabina) y una escalera de peldaños a la torreta.
func _walkway_back(floor_y: float) -> void:
	var back := TORSO.z * 0.5
	var width := TORSO.x + SHOULDER.x * 2.0
	var deep := 1.0
	_deck(Vector3(width, 0.12, deep), Vector3(0.0, floor_y - 0.06, back + deep * 0.5))
	_rail(Vector3(-width * 0.5, floor_y, back + deep), Vector3(width * 0.5, floor_y, back + deep))
	_rail(Vector3(-width * 0.5, floor_y, back), Vector3(-width * 0.5, floor_y, back + deep))
	_rail(Vector3(width * 0.5, floor_y, back), Vector3(width * 0.5, floor_y, back + deep))
	for x: float in [0.0, -(TORSO.x + SHOULDER.x) * 0.5, (TORSO.x + SHOULDER.x) * 0.5]:
		var face := back if x == 0.0 else SHOULDER.z * 0.5
		_door(Vector3(x, floor_y, face))
	var turret_back := 0.1 + TURRET.z * 0.5
	_door(Vector3(0.0, HIP + TORSO.y, turret_back))
	# La escalera: peldaños por el fondo del torso, al costado de su puerta, hasta arriba.
	var rung := floor_y + 0.35
	while rung < HIP + TORSO.y + 0.2:
		Clay.box(self, Vector3(0.6, 0.06, 0.06), Vector3(1.05, rung, back + 0.12), DARK_METAL)
		rung += 0.35
	for x: float in [0.75, 1.35]:
		Clay.box(self, Vector3(0.06, HIP + TORSO.y + 0.4 - floor_y, 0.06),
			Vector3(x, (floor_y + HIP + TORSO.y + 0.4) * 0.5, back + 0.12), DARK_METAL)
	_visitor(Vector3(-2.3, floor_y, back + 0.5), -PI * 0.5)


## LA PASARELA ARRIBA: una cubierta sobre los hombros y el torso, delante de la torreta, con baranda adelante y a los
## costados; una escotilla sobre cada cabina (un pozo corto hasta ella).
func _walkway_top() -> void:
	var top := HIP + TORSO.y + 0.1
	var width := TORSO.x + SHOULDER.x * 2.0
	var front := -SHOULDER.z * 0.5
	var deep := 1.6
	_deck(Vector3(width, 0.12, deep), Vector3(0.0, top - 0.06, front + deep * 0.5))
	_rail(Vector3(-width * 0.5, top, front), Vector3(width * 0.5, top, front))
	_rail(Vector3(-width * 0.5, top, front), Vector3(-width * 0.5, top, front + deep))
	_rail(Vector3(width * 0.5, top, front), Vector3(width * 0.5, top, front + deep))
	for x: float in [-(TORSO.x + SHOULDER.x) * 0.5, (TORSO.x + SHOULDER.x) * 0.5]:
		Clay.box(self, Vector3(0.8, 0.05, 0.8), Vector3(x, top + 0.02, front + 0.8), HATCH)
	Clay.box(self, Vector3(0.8, 0.05, 0.8), Vector3(0.9, top + 0.02, front + 0.8), HATCH)
	_door(Vector3(-TURRET.x * 0.5 - 0.01, top, 0.4), true)
	_visitor(Vector3(-2.4, top, front + 0.8), -PI * 0.5)


## LA PASARELA ADENTRO: un pasillo de lado a lado por el cuerpo, detrás de las cabinas, a la altura de su piso, y una
## escalera adentro del torso a la torreta. Se ve en la cuarta vista, con el cuerpo en corte.
func _walkway_inside(floor_y: float) -> void:
	var width := TORSO.x + SHOULDER.x * 2.0 - 0.3
	_deck(Vector3(width, 0.12, 1.0), Vector3(0.0, floor_y - 0.06, 0.3))
	var rung := floor_y + 0.35
	while rung < HIP + TORSO.y + 0.2:
		Clay.box(self, Vector3(0.6, 0.06, 0.06), Vector3(0.9, rung, 0.85), DARK_METAL)
		rung += 0.35
	_visitor(Vector3(-2.3, floor_y, 0.3), -PI * 0.5)


func _deck(size: Vector3, center: Vector3) -> void:
	Clay.box(self, size, center, WALKWAY)
	var body := StaticBody3D.new()
	Clay.shape_box(body, size, center)
	add_child(body)


## Una baranda de `a` a `b` (en el piso de la pasarela): postes y pasamanos a 1 m.
func _rail(a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	var posts := maxi(1, ceili(length / 1.2))
	for i in posts + 1:
		Clay.box(self, Vector3(0.06, 1.0, 0.06), a.lerp(b, float(i) / posts) + Vector3(0.0, 0.5, 0.0), DARK_METAL)
	for y: float in [1.0, 0.5]:
		var bar := Clay.box(self, Vector3(0.05, 0.05, length), (a + b) * 0.5 + Vector3(0.0, y, 0.0), DARK_METAL)
		bar.basis = Basis.looking_at(b - a, Vector3.UP)


## El marco de una puerta en una cara de atrás (o de costado), de piso en `base`.
func _door(base: Vector3, sideways := false) -> void:
	var size := Vector3(0.06, 1.75, 0.8) if sideways else Vector3(0.8, 1.75, 0.06)
	Clay.box(self, size, base + Vector3(0.0, size.y * 0.5, 0.0), HATCH)


func _visitor(at: Vector3, yaw: float) -> void:
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.lanky, at, yaw)


## Una barra cuadrada de `a` a `b`, de `thick` de lado.
func _bar(a: Vector3, b: Vector3, thick: float, color: Color) -> void:
	var part := Clay.box(self, Vector3(thick, thick, a.distance_to(b)), (a + b) * 0.5, color)
	part.basis = Basis.looking_at(b - a, Vector3.RIGHT if absf((b - a).normalized().y) > 0.9 else Vector3.UP)


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


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)


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
	var path := "%s/cabinas_de_uno_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
