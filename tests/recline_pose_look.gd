extends Node3D

## EL QUE MANEJA, RECOSTADO EN LA ESFERA: POSES (16/11/2026, el usuario: «tal vez una forma más natural sería que esté
## como recostado con la espalda curvada, siguiendo la forma de la esfera… y ver cómo van los pies de la forma más
## natural posible… que se mueva sólo su cabeza… mostrame varias poses»). Maquetas de arcilla del más alto (flaco
## largo), con LA ESPALDA Y LA CABEZA APOYADAS EN LA PARED DE ATRÁS (segunda tanda: «ninguna pose tiene la espalda
## apoyada… tendrías que hacerla más chica»), mirando derecho adelante. Cada pose busca el radio más chico en que entran
## las piernas y la esfera se dibuja de ese radio: atrás opaca, adelante el vidrio; el punto rojo es su centro. De
## costado cortada al medio, y de adelante y arriba.
##   tools/godot_ventana.sh res://tests/recline_pose_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
## Las medidas del más alto (m): el cuello y la columna en tres tramos, muslo, canilla y pie.
const NECK := 0.22
const SPINE := [0.2, 0.2, 0.18]
const THIGH := 0.5
const SHIN := 0.48
const FOOT := 0.24
## LA ESPALDA APOYADA EN LA ESFERA (el usuario: «ninguna pose tiene la espalda apoyada en la parte de atrás de la
## esfera»): la columna va por la pared, a `BACK` de ella, y la cabeza apoyada, a `HEAD`. Los ojos ya no van al centro:
## toda la mitad de adelante es vidrio, se ve igual.
const BACK := 0.12
const HEAD := 0.13
## Lo que dejan las piernas hasta la pared (m).
const CLEAR := 0.07
## Cada pose: dónde se apoya la cabeza (° sobre el centro de la esfera, atrás), el muslo (° sobre la horizontal, hacia
## adelante) y la rodilla (° que se dobla). El radio sale de la pose: el más chico en que las piernas entran.
const POSES := [
	{"name": "1 · la cabeza a la altura del centro, rodillas arriba", "head": 0.0, "thigh": 20.0, "knee": 100.0},
	{"name": "2 · la cabeza a la altura del centro, piernas adelante", "head": 0.0, "thigh": -5.0, "knee": 25.0},
	{"name": "3 · más acostado, rodillas arriba", "head": 25.0, "thigh": 30.0, "knee": 110.0},
	{"name": "4 · más acostado, piernas adelante", "head": 25.0, "thigh": 5.0, "knee": 40.0},
	{"name": "5 · más sentado, rodillas arriba", "head": -15.0, "thigh": 30.0, "knee": 100.0},
	{"name": "6 · como en gravedad cero", "head": 15.0, "thigh": 20.0, "knee": 50.0},
]
const SHELL := Color(0.6, 0.61, 0.63)
const GLASS := Color(0.62, 0.8, 0.92, 0.3)
const BODY := Color(0.85, 0.55, 0.35)
const PAD := Color(0.35, 0.3, 0.28)
const RED := Color(0.78, 0.18, 0.15)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	var radii: Array[float] = []
	for index in POSES.size():
		var root := Node3D.new()
		root.position = Vector3(0.0, 0.0, index * 60.0)
		add_child(root)
		radii.append(_build(root, POSES[index]))
	for index in POSES.size():
		var at := Vector3(0.0, 0.0, index * 60.0)
		var shots: Array[Image] = []
		_title.text = "%s · esfera de %.2f m" % [POSES[index]["name"], radii[index]]
		_eye.near = 10.0 - 0.32
		shots.append(await _view(at + Vector3(10.0, 0.0, 0.0), at + Vector3(0.0, -0.2, 0.0), 0.0, 2.8))
		_eye.near = 0.05
		shots.append(await _view(at + Vector3(-2.4, 1.4, -3.6), at + Vector3(0.0, -0.4, 0.0), 50.0))
		_save(shots, index + 1)
	get_tree().quit()


## LA POSE EN UNA ESFERA DE `radius`, en el plano del medio (adelante, arriba), con el centro en el origen: los ojos, la
## cabeza, la columna (de la base del cuello a la cadera, por la pared) y la pierna (rodilla, tobillo y punta del pie).
func _pose(radius: float, pose: Dictionary) -> Dictionary:
	var along := radius - BACK
	var angle := deg_to_rad(180.0 - float(pose["head"]))
	var head := Vector2(cos(angle), sin(angle)) * (radius - HEAD)
	var chain: Array[Vector2] = []
	for length: float in [NECK] + SPINE:
		angle += 2.0 * asin(minf(length / (2.0 * along), 1.0))
		chain.append(Vector2(cos(angle), sin(angle)) * along)
	var hip := chain[chain.size() - 1]
	var thigh := float(pose["thigh"])
	var bend := thigh - float(pose["knee"])
	var knee := hip + _dir(thigh, THIGH)
	var ankle := knee + _dir(bend, SHIN)
	return {"eye": head + Vector2(0.09, 0.02), "head": head, "chain": chain, "knee": knee, "ankle": ankle,
		"toe": ankle + _dir(bend + 90.0, FOOT)}


## ARMA UNA POSE con el radio más chico en que las piernas entran, y su esfera. Devuelve el radio.
func _build(root: Node3D, pose: Dictionary) -> float:
	var radius := 0.7
	var shape := _pose(radius, pose)
	while radius < 2.0:
		shape = _pose(radius, pose)
		var inside := true
		for key: String in ["knee", "ankle", "toe"]:
			inside = inside and (shape[key] as Vector2).length() <= radius - CLEAR
		if inside:
			break
		radius += 0.01
	for part: Array in [[PI * 0.5, PI, SHELL], [0.0, PI * 0.5, GLASS]]:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		CageMesh.sphere_band(tool, Vector3.ZERO, radius, part[0], part[1], false)
		var mesh := MeshInstance3D.new()
		mesh.mesh = tool.commit()
		var paint := Clay.material(part[2]).duplicate() as StandardMaterial3D
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = paint
		root.add_child(mesh)
	var eye: Vector2 = shape["eye"]
	var chain: Array[Vector2] = shape["chain"]
	Clay.sphere(root, 0.12, _at(shape["head"], 0.0), BODY)
	var previous: Vector2 = shape["head"]
	for k in chain.size():
		_limb(root, _at(previous, 0.0), _at(chain[k], 0.0), 0.06 if k == 0 else 0.15)
		previous = chain[k]
	# El acolchado: una tira sobre la pared, de la cabeza a la cadera.
	var pad: Array[Vector2] = [shape["head"]]
	pad.append_array(chain)
	for k in range(1, pad.size()):
		_limb(root, _at(pad[k - 1].normalized() * (radius - 0.03), 0.0), _at(pad[k].normalized() * (radius - 0.03), 0.0),
			0.04, PAD, 0.5)
	var hip := chain[chain.size() - 1]
	for s: float in [-1.0, 1.0]:
		var x := s * 0.11
		_limb(root, _at(hip, x), _at(shape["knee"], x), 0.075)
		_limb(root, _at(shape["knee"], x), _at(shape["ankle"], x), 0.06)
		_limb(root, _at(shape["ankle"], x), _at(shape["toe"], x), 0.045)
		# Los brazos, a unos controles adelante y abajo de la mirada.
		var shoulder := chain[0]
		var hand := eye + Vector2(0.45, -0.4)
		var elbow := (shoulder + hand) * 0.5 + Vector2(-0.05, -0.1)
		_limb(root, _at(shoulder, s * 0.2), _at(elbow, s * 0.26), 0.05)
		_limb(root, _at(elbow, s * 0.26), _at(hand, s * 0.2), 0.045)
	Clay.box(root, Vector3(0.7, 0.04, 0.25), _at(eye + Vector2(0.5, -0.45), 0.0), Color(0.3, 0.31, 0.34))
	# La mirada, y el centro de la esfera.
	_limb(root, _at(eye, 0.0), _at(Vector2(sqrt(maxf(radius * radius - eye.y * eye.y, 0.0)), eye.y), 0.0), 0.008, RED)
	Clay.sphere(root, 0.03, Vector3.ZERO, RED)
	print("POSE ", pose["name"], " · radio ", radius, " · ojos ", eye.snapped(Vector2.ONE * 0.01))
	return radius


## (adelante, arriba) y el costado x → espacio (adelante es −Z).
func _at(p: Vector2, x: float) -> Vector3:
	return Vector3(x, p.y, -p.x)


## Un paso de `length` a `degrees` (0 adelante, 90 arriba).
func _dir(degrees: float, length: float) -> Vector2:
	var a := deg_to_rad(degrees)
	return Vector2(cos(a), sin(a)) * length


func _limb(root: Node3D, a: Vector3, b: Vector3, radius: float, color := BODY, flat := 1.0) -> void:
	var holder := Clay.limb(root, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)
	if flat != 1.0:
		holder.scale = Vector3(1.0 / flat * 1.6, flat, 1.0)


func _stage() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -60.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.82, 0.86, 0.9)
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
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


func _view(from: Vector3, to: Vector3, fov: float, ortho := 0.0) -> Image:
	if fov > 0.0:
		_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		_eye.fov = fov
	else:
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.size = ortho
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array[Image], number: int) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var w := shots[0].get_width()
	var sheet := Image.create(w * 2, shots[0].get_height(), false, shots[0].get_format())
	for index in shots.size():
		sheet.blit_rect(shots[index], Rect2i(Vector2i.ZERO, shots[index].get_size()), Vector2i(w * index, 0))
	var path := "%s/pose_%d.png" % [_folder, number]
	sheet.save_png(path)
	print("CAPTURA ", path)
