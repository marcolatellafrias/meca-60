extends Node3D

## LA MECA DE TORSO DE CAJA SOBRE UNA PELVIS-PLATAFORMA, MAQUETA DE ARCILLA (16/11/2026; sigue la numeración de
## tests/stacked_discs_look). El usuario: «una meca con cuerpo de caja… un poquito más alargado hacia arriba… la pelvis…
## más separada de la parte de arriba… una especie de plataforma… el cuerpo… más chico… que la pelvis… te subís a la
## pelvis con un succionador y después elegís a qué puerta meterte desde el torso… un espacio ahí común. Pero apuntando
## hacia afuera… varias formas de hacer la transición de pelvis-torso… del mismo tamaño y… un espacio… de la altura de
## una persona… muéstrame varias ideas».
##   · EL TORSO, una caja algo más alta que ancha: abajo, brazo, artillería y brazo (tres ventanas adelante); arriba, el
##     que maneja (ventana adelante y a los costados).
##   · LA PELVIS, una losa con baranda donde se camina: el SUCCIONADOR te deja ahí, por un agujero del piso.
##   · Cada puesto, su puerta hacia la plataforma; al de arriba se sube por una escalera.
##   84 · pelvis más ancha, el torso apoyado encima: la plataforma da la vuelta; puertas a los costados y atrás;
##   85 · pelvis y torso del mismo tamaño, con un hueco de una persona entre los dos (cuatro pilares): se entra por
##        tapas en la panza del torso, con escaleritas;
##   86 · pelvis más ancha Y el hueco: se camina debajo del torso y alrededor;
##   87 · el torso adelante y la plataforma atrás, como un porche: todas las puertas en la cara de atrás.
##   tools/godot_ventana.sh res://tests/pelvis_platform_look.tscn -- --salida=C:/carpeta --variante=84

const VIEW := Vector2i(1280, 720)
## pelvis: ancho y fondo de la losa; gap: el hueco entre la pelvis y el torso; torso_z: dónde va el torso (adelante es
## −z); doors: "sides" (a los costados y atrás), "hatches" (tapas en la panza), "back" (todas atrás).
const VARIANTS := {
	84: {"name": "pelvis más ancha, el torso apoyado", "pelvis": Vector2(6.4, 6.2), "gap": 0.0, "torso_z": 0.0,
		"doors": "sides"},
	85: {"name": "mismo tamaño, con un hueco de una persona", "pelvis": Vector2(3.8, 3.6), "gap": 2.2,
		"torso_z": 0.0, "doors": "hatches"},
	86: {"name": "pelvis más ancha y el hueco", "pelvis": Vector2(6.4, 6.2), "gap": 2.2, "torso_z": 0.0,
		"doors": "hatches"},
	87: {"name": "el torso adelante, un porche atrás", "pelvis": Vector2(4.6, 6.4), "gap": 0.0, "torso_z": -1.4,
		"doors": "back"},
}
## El torso: ancho, alto y fondo; el alto del piso de abajo (brazos y artillería); el resto, el de arriba.
const TORSO := Vector3(3.8, 4.4, 3.6)
const LOWER := 2.4
const PELVIS_THICK := 0.8
const RAIL := 1.0
const DOOR := Vector2(0.85, 2.0)
const LIMBS := 0.7

const TORSO_COLOR := Color(0.6, 0.61, 0.63)
const PELVIS_COLOR := Color(0.5, 0.5, 0.52)
const DECK := Color(0.56, 0.56, 0.55)
const RIM := Color(0.22, 0.23, 0.25)
const WINDOW := Color(0.12, 0.14, 0.17)
const DOOR_COLOR := Color(0.3, 0.31, 0.34)
const JOINT := Color(0.36, 0.375, 0.4)
const SKIN := Color(0.86, 0.66, 0.5)
const SUCTION := Color(0.45, 0.35, 0.65, 0.25)

var _folder := ""
var _variant := 84
var _plan: Dictionary = {}
var _eye: Camera3D = null
var _title: Label = null
var _bottom := 0.0
var _deck_y := 0.0
var _torso_y := 0.0
var _suction := Vector3.ZERO


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
	get_window().size = VIEW
	_plan = VARIANTS[_variant]
	_stage()
	var body := MechBody.current
	var hip_line := (body.WAIST - body.HIP_DROP) * LIMBS
	_bottom = hip_line + 0.66
	_deck_y = _bottom + PELVIS_THICK
	_torso_y = _deck_y + float(_plan["gap"])
	_build()
	_legs(hip_line)
	await get_tree().create_timer(2.0).timeout
	var high := _torso_y + TORSO.y
	var k := high / 11.0
	var whole := Vector3(0.0, high * 0.5, 0.0)
	var shots: Array = []
	_title.text = "%d. %s" % [_variant, _plan["name"]]
	shots.append(await _view(whole + Vector3(-9.0, 4.0, -12.0) * k, whole, 45.0))
	_title.text = "%d. de atrás" % _variant
	shots.append(await _view(whole + Vector3(9.0, 3.5, 12.0) * k, whole, 45.0))
	_title.text = "%d. de costado" % _variant
	shots.append(await _view(whole + Vector3(-40.0, 0.0, 0.0), whole, 0.0, high + 1.5))
	_title.text = "%d. de arriba" % _variant
	shots.append(await _view(Vector3(0.0, high + 30.0, 0.01), Vector3(0.0, high, 0.0), 0.0, 13.0))
	_title.text = "%d. de cerca, sobre la plataforma" % _variant
	var torso_z: float = _plan["torso_z"]
	shots.append(await _view(Vector3(5.0, _deck_y + 3.5, torso_z + 7.0), Vector3(0.0, _deck_y + 1.3, torso_z), 50.0))
	_title.text = "%d. recién subido por el succionador" % _variant
	var eye := _suction + Vector3(0.0, 1.65, 0.0)
	shots.append(await _view(eye, Vector3(0.0, _deck_y + 1.4, torso_z), 80.0))
	_save(shots)
	get_tree().quit()


## ── LA MECA ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	var pelvis: Vector2 = _plan["pelvis"]
	var gap: float = _plan["gap"]
	var torso_z: float = _plan["torso_z"]
	var doors: String = _plan["doors"]
	var half := Vector2(TORSO.x * 0.5, TORSO.z * 0.5)
	# LA PELVIS: la losa, su cubierta y la baranda alrededor.
	Clay.box(self, Vector3(pelvis.x, PELVIS_THICK, pelvis.y), Vector3(0.0, _bottom + PELVIS_THICK * 0.5, 0.0),
		PELVIS_COLOR)
	Clay.box(self, Vector3(pelvis.x - 0.04, 0.03, pelvis.y - 0.04), Vector3(0.0, _deck_y + 0.015, 0.0), DECK)
	_rail(pelvis)
	# EL SUCCIONADOR: un agujero con borde en la cubierta, atrás, y la columna hasta el suelo.
	# En una esquina de atrás cuando la plataforma da la vuelta; al medio del porche; debajo del torso si no sobra.
	_suction = Vector3(pelvis.x * 0.5 - 0.75, _deck_y, pelvis.y * 0.5 - 0.75)
	if doors == "back":
		_suction = Vector3(0.0, _deck_y, pelvis.y * 0.5 - 1.0)
	if gap > 0.0 and pelvis.y <= TORSO.z + 0.1:
		_suction = Vector3(0.0, _deck_y, 0.6)
	Clay.cylinder(self, 0.6, 0.06, _suction + Vector3(0.0, 0.04, 0.0), RIM)
	Clay.cylinder(self, 0.5, 0.07, _suction + Vector3(0.0, 0.045, 0.0), Color(0.08, 0.08, 0.1))
	var column := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.5
	shaft.bottom_radius = 0.65
	shaft.height = _deck_y
	column.mesh = shaft
	column.material_override = Clay.material(SUCTION)
	column.position = Vector3(_suction.x, _deck_y * 0.5, _suction.z)
	add_child(column)
	# EL HUECO entre pelvis y torso: cuatro pilares en las esquinas del torso.
	if gap > 0.0:
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				Clay.box(self, Vector3(0.35, gap, 0.35), Vector3(sx * (half.x - 0.175), _deck_y + gap * 0.5,
					torso_z + sz * (half.y - 0.175)), PELVIS_COLOR)
	# EL TORSO: la caja, con una línea entre sus dos pisos, sus ventanas y sus puertas.
	var center := Vector3(0.0, _torso_y + TORSO.y * 0.5, torso_z)
	Clay.box(self, TORSO, center, TORSO_COLOR)
	Clay.box(self, Vector3(TORSO.x + 0.04, 0.08, TORSO.z + 0.04), Vector3(0.0, _torso_y + LOWER, torso_z), RIM)
	var front := torso_z - half.y - 0.01
	for x: float in [-1.27, 0.0, 1.27]:
		Clay.box(self, Vector3(1.0, 0.7, 0.06), Vector3(x, _torso_y + 1.35, front), WINDOW)
	Clay.box(self, Vector3(2.6, 0.55, 0.06), Vector3(0.0, _torso_y + LOWER + 1.1, front), WINDOW)
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.06, 0.55, 1.6), Vector3(s * (half.x + 0.01), _torso_y + LOWER + 1.1, torso_z - 0.6),
			WINDOW)
	var back := torso_z + half.y + 0.01
	match doors:
		"sides":
			# Cada brazo, por su costado (atrás del hombro); artillería, atrás; el de arriba, por una escalera atrás.
			for s: float in [-1.0, 1.0]:
				_door(Vector3(s * (half.x + 0.01), _torso_y, torso_z + 0.9), s * PI * 0.5, DOOR)
			_door(Vector3(-0.7, _torso_y, back), 0.0, DOOR)
			_upper(Vector3(0.9, _torso_y, back))
		"back":
			# Las tres de abajo, en la cara de atrás, una por puesto; el de arriba, por la escalera entre dos.
			for x: float in [-1.35, 0.0, 1.35]:
				_door(Vector3(x, _torso_y, back), 0.0, DOOR)
			_upper(Vector3(0.67, _torso_y, back + 0.1))
		"hatches":
			# Tapas en la panza del torso, con su escalerita desde la cubierta: brazos, artillería y el de arriba.
			for spot: Vector2 in [Vector2(-1.2, -0.3), Vector2(1.2, -0.3), Vector2(0.0, -1.0), Vector2(0.0, 1.0)]:
				var at := Vector3(spot.x, _torso_y - 0.01, torso_z + spot.y)
				Clay.box(self, Vector3(0.85, 0.04, 0.85), at, DOOR_COLOR)
				_ladder(Vector3(spot.x, 0.0, torso_z + spot.y + 0.35), _deck_y, _torso_y + 0.6, 0.0)
	# LOS BRAZOS, de los costados del torso, adelante y a la altura del piso de abajo.
	var body := MechBody.current
	var thick := body.LEG_THICKNESS * LIMBS
	for s: float in [-1.0, 1.0]:
		_arm(Vector3(s * (half.x + thick * 0.72), _torso_y + LOWER * 0.85, torso_z - 0.6), s)
	# LA GENTE: una recién subida por el succionador, una yendo a una puerta y una en el suelo.
	_standing(_suction + Vector3(0.0, 0.03, 0.9) if _suction.z < 1.0 else _suction + Vector3(-0.9, 0.03, 0.2))
	var near_door := Vector3(-1.5, _deck_y + 0.03, torso_z + half.y + 0.8) if doors != "hatches" \
		else Vector3(-1.0, _deck_y + 0.03, torso_z - 0.5)
	_standing(near_door)
	_standing(Vector3(-pelvis.x * 0.5 - 3.5, 0.0, -2.0))


## Una puerta: un marco y la hoja, en una cara del torso; `at`, el pie de la puerta; `turn`, hacia dónde mira.
func _door(at: Vector3, turn: float, size: Vector2) -> void:
	var frame := Clay.box(self, Vector3(size.x + 0.16, size.y + 0.1, 0.05), at + Vector3(0.0, (size.y + 0.1) * 0.5, 0.0),
		RIM)
	frame.basis = Basis(Vector3.UP, turn)
	var leaf := Clay.box(self, Vector3(size.x, size.y, 0.07), at + Vector3(0.0, size.y * 0.5, 0.0), DOOR_COLOR)
	leaf.basis = Basis(Vector3.UP, turn)


## La puerta del de arriba, en la cara de atrás, con su escalera desde la cubierta.
func _upper(at: Vector3) -> void:
	_door(at + Vector3(0.0, LOWER + 0.1, 0.0), 0.0, Vector2(0.75, 1.6))
	_ladder(at + Vector3(0.0, 0.0, 0.25), _deck_y, _torso_y + LOWER + 0.1, 0.0)


## UNA ESCALERA vertical en `at` (x, z), de `from` a `to`; los peldaños a lo ancho de x.
func _ladder(at: Vector3, from: float, to: float, _turn: float) -> void:
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.05, to - from + 0.9, 0.05), Vector3(at.x + s * 0.25, (from + to + 0.9) * 0.5, at.z), RIM)
	for i in int((to - from) / 0.3):
		Clay.box(self, Vector3(0.5, 0.04, 0.04), Vector3(at.x, from + 0.3 * (i + 1), at.z), RIM)


## La baranda alrededor de la pelvis: postes y pasamanos.
func _rail(pelvis: Vector2) -> void:
	var half := pelvis * 0.5
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(pelvis.x, 0.05, 0.05), Vector3(0.0, _deck_y + RAIL, s * half.y), RIM)
		Clay.box(self, Vector3(0.05, 0.05, pelvis.y), Vector3(s * half.x, _deck_y + RAIL, 0.0), RIM)
	for i in int(pelvis.x / 0.8) + 1:
		var x := -half.x + pelvis.x * i / int(pelvis.x / 0.8)
		for s: float in [-1.0, 1.0]:
			Clay.box(self, Vector3(0.04, RAIL, 0.04), Vector3(x, _deck_y + RAIL * 0.5, s * half.y), RIM)
	for i in int(pelvis.y / 0.8) + 1:
		var z := -half.y + pelvis.y * i / int(pelvis.y / 0.8)
		for s: float in [-1.0, 1.0]:
			Clay.box(self, Vector3(0.04, RAIL, 0.04), Vector3(s * half.x, _deck_y + RAIL * 0.5, z), RIM)


## UNA PERSONA PARADA, de arcilla (1,75 m): `at`, el piso entre los pies.
func _standing(at: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.14, 0.85, 0.16), at + Vector3(side * 0.1, 0.425, 0.0), SKIN)
		Clay.box(self, Vector3(0.1, 0.6, 0.1), at + Vector3(side * 0.27, 1.15, 0.0), SKIN)
	Clay.box(self, Vector3(0.4, 0.6, 0.24), at + Vector3(0.0, 1.15, 0.0), SKIN)
	Clay.sphere(self, 0.13, at + Vector3(0.0, 1.62, 0.0), SKIN)


## UN BRAZO de arcilla desde el hombro: el antebrazo hacia adelante.
func _arm(shoulder: Vector3, side: float) -> void:
	var body := MechBody.current
	var upper := body.UPPER_ARM * LIMBS
	var fore := body.FOREARM * LIMBS
	var thick := body.LEG_THICKNESS * LIMBS
	var elbow := shoulder + Vector3(side * 0.25, -1.0, 0.25).normalized() * upper
	var hand := elbow + Vector3(0.0, -0.25, -1.0).normalized() * fore
	Clay.sphere(self, thick * 0.7, shoulder, JOINT)
	_limb(shoulder, elbow, thick * 0.48, Clay.METAL.darkened(0.1))
	Clay.sphere(self, thick * 0.55, elbow, JOINT)
	_limb(elbow, hand, thick * 0.45, Clay.METAL.darkened(0.2))
	Clay.sphere(self, thick * 0.6, hand, JOINT)


## LAS PIERNAS de arcilla, colgadas de la pelvis.
func _legs(hip_y: float) -> void:
	var body := MechBody.current
	var thick := body.LEG_THICKNESS * LIMBS
	var hip_x := body.HIP_X * LIMBS
	var thigh := body.THIGH * LIMBS
	var foot := body.FOOT_SIZE * LIMBS
	Clay.cylinder(self, thick * 0.43, hip_x * 2.0, Vector3(0.0, hip_y, 0.0), JOINT, Vector3(0.0, 0.0, 90.0))
	Clay.cylinder(self, thick * 0.48, _bottom - hip_y + 0.2, Vector3(0.0, (_bottom + hip_y) * 0.5, 0.0), JOINT)
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * hip_x, hip_y, 0.0)
		var ankle := Vector3(side * (hip_x + 0.3 * LIMBS), thick * 0.33 + foot.y * 0.5, 0.0)
		var span := hip.distance_to(ankle)
		var bend := sqrt(maxf(thigh * thigh - span * span * 0.25, 0.0))
		var knee := (hip + ankle) * 0.5 + Vector3(0.0, 0.0, -bend)
		Clay.sphere(self, thick * 0.62, hip, JOINT)
		_limb(hip, knee, thick * 0.5, Clay.METAL.darkened(0.1))
		Clay.sphere(self, thick * 0.62, knee, JOINT)
		_limb(knee, ankle, thick * 0.5, Clay.METAL.darkened(0.2))
		Clay.sphere(self, thick * 0.53, ankle, JOINT)
		Clay.box(self, foot, Vector3(ankle.x, foot.y * 0.5, ankle.z - 0.4 * LIMBS), JOINT)


func _limb(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var holder := Clay.limb(self, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)


## ── LO DE SIEMPRE ────────────────────────────────────────────────────────────────────────────────────────────────

func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


## Una vista: con `fov`, en perspectiva; con fov 0, sin perspectiva, de `ortho` de alto.
func _view(from: Vector3, to: Vector3, fov: float, ortho := 0.0) -> Image:
	if fov > 0.0:
		_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		_eye.fov = fov
	else:
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.size = ortho
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.FORWARD)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


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
	var path := "%s/pelvis_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)
