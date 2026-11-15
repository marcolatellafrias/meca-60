extends Node3D

## LA MECA DE CUATRO CABINAS, MAQUETA DE ARCILLA (15/11/2026, el usuario: «eliminar toda esta complejidad del interior…
## apretás una tecla y te metés en tu cabina… una cabina por cada sección independiente… cada hombro… cuadrado, y tenga
## una cabina adentro y esa persona maneja ese brazo. Lo mismo con el del movimiento, que está en el torso, y el de la
## artillería está arriba del torso… a lo sumo la meca se tiene que agachar para que ese se pueda meter… es todas cosas
## cuadradas»). Todo cajas: el torso (el que camina), los dos hombros (cada uno su brazo) y la torreta (la artillería),
## cada uno con su vidrio al frente, su escotilla atrás y una persona de verdad adentro; las piernas y los brazos,
## barras cuadradas. Una persona en el piso, al lado, para la escala.
##   tools/godot_ventana.sh res://tests/four_cabins_look.tscn -- --salida=C:/carpeta --variante=1

const VIEW := Vector2i(1280, 720)
const WALL := 0.12
## Las variantes: el torso [ancho, alto, fondo] y a qué alto queda su piso de abajo; los hombros [lado], su alto (del
## centro, sobre el piso de abajo del torso) y si van pegados o separados; la torreta [ancho, alto, fondo], cuánto
## adelante (z, − es adelante) y si va arriba o atrás; `crouch`, cuánto se agacha (0 parada).
const VARIANTS := {
	1: {"name": "hombros al costado, torreta arriba", "torso": Vector3(3.0, 2.6, 2.6), "hip": 4.0,
		"shoulder": 2.4, "shoulder_y": 1.5, "gap": 0.05, "turret": Vector3(2.4, 2.2, 2.4), "turret_z": 0.0,
		"turret_y": 0.0, "crouch": 0.0},
	2: {"name": "hombreras altas, torreta atrás entre ellas", "torso": Vector3(3.0, 2.6, 2.6), "hip": 4.0,
		"shoulder": 2.4, "shoulder_y": 2.6, "gap": 0.05, "turret": Vector3(2.4, 2.2, 2.4), "turret_z": 0.6,
		"turret_y": -0.4, "crouch": 0.0},
	3: {"name": "torreta adelante como cabeza, torso ancho y bajo", "torso": Vector3(3.6, 2.4, 2.8), "hip": 4.0,
		"shoulder": 2.4, "shoulder_y": 1.3, "gap": 0.05, "turret": Vector3(2.2, 2.2, 2.4), "turret_z": -0.7,
		"turret_y": 0.0, "crouch": 0.0},
	4: {"name": "hombros bajos, torreta de mochila", "torso": Vector3(3.0, 3.0, 2.6), "hip": 4.0,
		"shoulder": 2.4, "shoulder_y": 0.9, "gap": 0.05, "turret": Vector3(2.4, 2.2, 2.4), "turret_z": 1.9,
		"turret_y": -0.6, "crouch": 0.0},
	5: {"name": "en cruz, compacta, piernas cortas", "torso": Vector3(2.6, 2.4, 2.6), "hip": 2.8,
		"shoulder": 2.4, "shoulder_y": 1.2, "gap": 0.0, "turret": Vector3(2.4, 2.2, 2.4), "turret_z": 0.0,
		"turret_y": 0.0, "crouch": 0.0},
	6: {"name": "la 1, agachada para que entren", "torso": Vector3(3.0, 2.6, 2.6), "hip": 4.0,
		"shoulder": 2.4, "shoulder_y": 1.5, "gap": 0.05, "turret": Vector3(2.4, 2.2, 2.4), "turret_z": 0.0,
		"turret_y": 0.0, "crouch": 0.9},
}

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const FLOOR := Color(0.68, 0.69, 0.71)
const HATCH := Color(0.2, 0.21, 0.23)
const ACCENT := {"walk": Color(0.3, 0.45, 0.75), "left": Color(0.8, 0.25, 0.2), "right": Color(0.8, 0.25, 0.2),
	"gun": Color(0.93, 0.75, 0.16)}
const CREW := {"walk": EntityArchetype.Archetype.buff, "left": EntityArchetype.Archetype.lanky,
	"right": EntityArchetype.Archetype.fat_athletic, "gun": EntityArchetype.Archetype.old}

var _folder := ""
var _variant := 1
var _eye: Camera3D = null
var _title: Label = null
var _glass := StandardMaterial3D.new()


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
	get_window().size = VIEW
	_glass.albedo_color = Color(0.7, 0.85, 0.95, 0.12)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass.roughness = 0.1
	_stage()
	var plan: Dictionary = VARIANTS[_variant]
	var top := _mech(plan)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(4.8, 0.0, -2.8), -PI * 0.7)
	await get_tree().create_timer(3.0).timeout
	_title.text = "%d. %s" % [_variant, plan["name"]]
	var middle := top * 0.5
	var shots: Array = []
	for view: Array in [
			[Vector3(-9.0, 7.5, -13.0), Vector3(0.0, middle, 0.0), 45.0],
			[Vector3(0.0, middle + 1.0, -17.0), Vector3(0.0, middle, 0.0), 40.0],
			[Vector3(10.0, 8.0, 12.0), Vector3(0.0, middle, 0.0), 45.0],
			[Vector3(-17.0, middle + 1.0, 0.0), Vector3(0.0, middle, 0.0), 40.0]]:
		_look(view[0], view[1], view[2])
		shots.append(await _grab())
	_save(shots)
	get_tree().quit()


## LA MECA: devuelve el alto de arriba de todo.
func _mech(plan: Dictionary) -> float:
	var torso: Vector3 = plan["torso"]
	var crouch: float = plan["crouch"]
	var hip: float = plan["hip"]
	# Agachada: las piernas se doblan y el torso baja.
	var leg := hip - 0.4
	var thigh := leg * 0.5
	var bend := crouch * 1.25
	var drop := 2.0 * thigh * (1.0 - cos(bend))
	hip -= drop
	var torso_center := Vector3(0.0, hip + torso.y * 0.5, 0.0)
	_cabin(torso_center, torso, "walk")
	# Las piernas, de abajo del torso, sin pelvis: muslo, canilla y pie.
	for side: float in [-1.0, 1.0]:
		var from := Vector3(side * torso.x * 0.3, hip + 0.1, 0.0)
		var foot := Vector3(side * torso.x * 0.34, 0.4, 0.0)
		var knee := Vector3(foot.x, (from.y + foot.y) * 0.5, -0.4 - sin(bend) * thigh)
		_bar(from, knee, 0.9, METAL)
		_bar(knee, foot, 0.8, METAL)
		Clay.box(self, Vector3(1.1, 0.4, 1.7), Vector3(foot.x, 0.2, -0.3), DARK_METAL)
		Clay.box(self, Vector3(1.0, 1.0, 1.0), knee, DARK_METAL)
	# Los hombros: una cabina cada uno, con su brazo colgando de abajo.
	var size: float = plan["shoulder"]
	var shoulder_y: float = hip + float(plan["shoulder_y"])
	for side: float in [-1.0, 1.0]:
		var center := Vector3(side * (torso.x * 0.5 + float(plan["gap"]) + size * 0.5), shoulder_y, 0.0)
		_cabin(center, Vector3.ONE * size, "left" if side < 0.0 else "right")
		var from := center + Vector3(side * 0.2, -size * 0.5, 0.0)
		var elbow := Vector3(from.x + side * 0.3, maxf(from.y - 2.0, 1.4), 0.3)
		var fist := elbow + Vector3(0.0, -0.3, -1.6)
		_bar(from, elbow, 0.8, METAL)
		_bar(elbow, fist, 0.75, METAL)
		Clay.box(self, Vector3(1.0, 1.0, 1.1), fist, DARK_METAL)
	# La torreta: arriba del torso (o atrás, de mochila), con su cañón al frente.
	var turret: Vector3 = plan["turret"]
	var turret_center := Vector3(0.0, hip + torso.y + float(plan["turret_y"]) + turret.y * 0.5, float(plan["turret_z"]))
	_cabin(turret_center, turret, "gun")
	# Dos caños, uno a cada lado, para que no tapen al de adentro.
	for side: float in [-1.0, 1.0]:
		var at := turret_center + Vector3(side * (turret.x * 0.5 + 0.3), 0.1, 0.0)
		Clay.box(self, Vector3(0.6, 0.7, 1.2), at, DARK_METAL)
		Clay.box(self, Vector3(0.35, 0.35, 2.4), at + Vector3(0.0, 0.0, -1.8), DARK_METAL)
	return maxf(turret_center.y + turret.y * 0.5, shoulder_y + size * 0.5)


## UNA CABINA: una caja con piso y techo de metal, las cuatro paredes de vidrio sobre un antepecho de metal y columnas
## en las esquinas (el usuario: «se debería poder ver todos los personajes adentro, desde afuera»), el marco de la
## escotilla atrás, una franja del color de su puesto, y su persona parada adentro.
func _cabin(center: Vector3, size: Vector3, role: String) -> void:
	var half := size * 0.5
	var sill := size.y * 0.3
	Clay.box(self, Vector3(size.x, WALL, size.z), center + Vector3(0.0, -half.y + WALL * 0.5, 0.0), FLOOR)
	Clay.box(self, Vector3(size.x, WALL * 2.0, size.z), center + Vector3(0.0, half.y - WALL, 0.0), METAL)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			Clay.box(self, Vector3(0.22, size.y, 0.22), center + Vector3(x * (half.x - 0.11), 0.0, z * (half.z - 0.11)),
				METAL)
	# Los cuatro lados: el antepecho y el vidrio.
	for wall: Array in [[Vector3(0, 0, -1), size.x], [Vector3(0, 0, 1), size.x], [Vector3(-1, 0, 0), size.z],
			[Vector3(1, 0, 0), size.z]]:
		var out: Vector3 = wall[0]
		var width: float = wall[1]
		var reach := absf(out.dot(half))
		var turn := Basis(Vector3.UP, PI * 0.5) if absf(out.x) > 0.5 else Basis()
		var low := Clay.box(self, Vector3(width, sill, WALL), center + out * (reach - WALL * 0.5)
			+ Vector3(0.0, -half.y + sill * 0.5, 0.0), METAL)
		low.basis = turn
		var pane := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(width - 0.3, size.y - sill - WALL * 2.0, 0.04)
		pane.mesh = mesh
		pane.material_override = _glass
		pane.basis = turn
		pane.position = center + out * (reach - 0.05) + Vector3(0.0, -half.y + sill + (size.y - sill - WALL * 2.0) * 0.5, 0.0)
		add_child(pane)
	Clay.box(self, Vector3(size.x + 0.02, 0.18, size.z + 0.02), center + Vector3(0.0, half.y - 0.3, 0.0), ACCENT[role])
	# El marco de la escotilla, atrás.
	var door := Vector2(minf(1.0, size.x - 0.6), minf(1.7, size.y - 0.45))
	var bottom := center.y - half.y + 0.15
	for x: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.08, door.y, 0.08), Vector3(center.x + x * door.x * 0.5, bottom + door.y * 0.5,
			center.z + half.z + 0.02), HATCH)
	Clay.box(self, Vector3(door.x + 0.08, 0.08, 0.08), Vector3(center.x, bottom + door.y, center.z + half.z + 0.02), HATCH)
	# El piso de choque y la persona.
	var floor_body := StaticBody3D.new()
	Clay.shape_box(floor_body, Vector3(size.x, WALL, size.z), center + Vector3(0.0, -half.y + WALL * 0.5, 0.0))
	add_child(floor_body)
	PeopleArchetype.spawn(self, CREW[role], center + Vector3(0.0, -half.y + WALL, 0.15), 0.0)


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
	var path := "%s/cuatro_cabinas_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
