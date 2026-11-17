extends Node3D

## LA SILLA CURVA DEL QUE MANEJA Y SU POSE, CON POCAS REGLAS (16/11/2026, el usuario: «una silla con respaldar curvo,
## más como si fuera de una meca de ciencia ficción… los personajes… una leve curva… el cuello en una posición
## ergonómicamente normal… un sistema de IK y poner el punto target donde puedan tocar la esfera, manteniendo un cierto
## doblamiento… mover nosotros mismos la cámara… como un offset… pocas reglas simples»). LAS REGLAS:
##   1 · LA SILLA ES FIJA en la esfera: su cadera (`HIP`) a una altura fija sobre el fondo y un poco detrás del centro.
##       No sube ni baja con el arquetipo.
##   2 · EL CUERPO SE APOYA EN ELLA: el tronco recostado `RECLINE` con una leve curva (`CURVE` por tramo); el cuello sigue
##       un poco hacia adelante y la cabeza queda derecha, mirando al frente.
##   3 · LOS PIES, POR IK, A LA ESFERA: donde la esfera queda a `REACH` del largo de la pierna desde la cadera (la rodilla
##       siempre algo doblada); de los dos puntos, el de más adelante.
##   4 · LA CÁMARA VA AL CENTRO DE LA ESFERA, no a los ojos (la de primera persona sólo ve las manos).
## Los seis arquetipos con sus medidas (tests/archetype_bones_measure). Cortados de costado; el punto rojo es la cámara.
##   tools/godot_ventana.sh res://tests/driver_seat_look.tscn -- --salida=C:/carpeta --radio=1.0

const VIEW := Vector2i(1280, 720)
## La cadera de la silla: sobre el fondo de la esfera y detrás del centro (m).
const HIP_UP := 0.42
const HIP_BACK := 0.28
const RECLINE := 28.0
const CURVE := 7.0
const REACH := 0.88
## Ojos sobre la pelvis, muslo, canilla, del tobillo a la suela, pie y grosor de la espalda (m).
const KINDS := [
	["gordo", 0.87, 0.43, 0.43, 0.12, 0.29, 0.17],
	["nene", 0.71, 0.37, 0.37, 0.07, 0.23, 0.11],
	["flaco largo", 0.82, 0.5, 0.5, 0.1, 0.28, 0.12],
	["musculoso", 0.76, 0.45, 0.45, 0.1, 0.28, 0.14],
	["viejo", 0.68, 0.4, 0.4, 0.07, 0.26, 0.12],
	["gordo atlético", 0.88, 0.45, 0.45, 0.1, 0.3, 0.15],
]
const BODY := Color(0.85, 0.55, 0.35)
const SEAT := Color(0.28, 0.3, 0.34)
const CUSHION := Color(0.55, 0.22, 0.18)
const SHELL := Color(0.6, 0.61, 0.63)
const GLASS := Color(0.62, 0.8, 0.92, 0.3)
const RED := Color(0.85, 0.12, 0.1)

var _folder := ""
var _radius := 1.0
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--radio="):
			_radius = float(argument.trim_prefix("--radio="))
	get_window().size = VIEW
	_stage()
	for index in KINDS.size():
		var root := Node3D.new()
		root.position = Vector3(0.0, 0.0, index * 40.0)
		add_child(root)
		_sphere(root)
		_seat(root)
		_figure(root, KINDS[index])
	var shots: Array[Image] = []
	for index in KINDS.size():
		var at := Vector3(0.0, 0.0, index * 40.0)
		_title.text = "%s · esfera de %.2f m" % [KINDS[index][0], _radius]
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.near = 10.0 - 0.4
		shots.append(await _view(at + Vector3(10.0, 0.0, 0.0), at, 2.0 * _radius + 0.5))
	# La silla sola, de tres cuartos.
	_title.text = "la silla, de atrás y de costado"
	_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
	_eye.near = 0.05
	_eye.fov = 45.0
	var last := Vector3(0.0, 0.0, 6 * 40.0)
	var lone := Node3D.new()
	lone.position = last
	add_child(lone)
	_seat(lone)
	shots.append(await _view(last + Vector3(2.2, 1.2, 2.0), last + Vector3(0.0, -0.3, 0.0), 0.0))
	_figure(lone, KINDS[2])
	_title.text = "la silla con el flaco largo"
	shots.append(await _view(last + Vector3(-2.0, 1.0, -2.4), last + Vector3(0.0, -0.3, 0.0), 0.0))
	_save(shots)
	get_tree().quit()


func _hip() -> Vector2:
	return Vector2(-HIP_BACK, -_radius + HIP_UP)


## LA COLUMNA DE `length`, desde la cadera, recostada y con la leve curva: sus puntos.
func _spine(length: float) -> Array[Vector2]:
	var points: Array[Vector2] = [_hip()]
	var angle := 90.0 + RECLINE
	for k in 3:
		points.append(points[k] + _dir(angle, length / 3.0))
		angle -= CURVE
	return points


## LA SILLA (regla 1): el respaldo curvo en tramos y el asiento, todos del mismo grosor (`SHELL_THICK`), con orejas a
## los costados; arriba, separado del respaldo, el apoyacabezas en dos varillas (a la cabeza de uno medio); y el brazo
## que la atornilla a la pared de atrás.
const SHELL_THICK := 0.08


func _seat(root: Node3D) -> void:
	var spine := _spine(0.62)
	var rim: Array[Vector2] = []
	for k in spine.size():
		var along := (spine[mini(k + 1, spine.size() - 1)] - spine[maxi(k - 1, 0)]).normalized()
		rim.append(spine[k] + Vector2(along.y, -along.x) * -0.17)
	# El respaldo, en tres tramos hasta los hombros (sin el tramo de la cabeza).
	for k in range(1, rim.size()):
		_slab(root, rim[k - 1], rim[k], 0.5, SHELL_THICK, SEAT)
		for s: float in [-1.0, 1.0]:
			_wing(root, rim[k - 1], rim[k], s * 0.26, 0.12)
	var hip := _hip()
	var pan := hip + _dir(12.0, 0.42)
	_slab(root, rim[0] + Vector2(0.0, -0.08), pan + Vector2(0.0, -0.11), 0.5, SHELL_THICK, SEAT)
	# El apoyacabezas, aparte: detrás de la cabeza de uno medio, unido al respaldo por dos varillas.
	var top := rim[rim.size() - 1]
	var medium := _spine(0.8 - 0.24)
	var chest := medium[medium.size() - 1]
	var lean := (chest - medium[medium.size() - 2]).normalized()
	var head := chest + lean.rotated(deg_to_rad(-18.0)) * 0.12 + Vector2(0.03, 0.11)
	var rest := head + Vector2(-0.17, 0.0)
	var rest_low := rest + Vector2(0.0, -0.09)
	_slab(root, rest_low, rest + Vector2(0.0, 0.09), 0.3, SHELL_THICK, SEAT)
	for s: float in [-1.0, 1.0]:
		_limb(root, _at(top, s * 0.1), _at(rest_low, s * 0.1), 0.015, SEAT)
	var mount := (rim[1] + rim[2]) * 0.5
	var wall := mount.normalized() * _radius
	_limb(root, _at(mount, 0.0), _at(wall, 0.0), 0.06, SEAT)


## UN ARQUETIPO EN LA SILLA (reglas 2 y 3) y la cámara (regla 4).
func _figure(root: Node3D, kind: Array) -> void:
	var eye_above: float = kind[1]
	var thigh: float = kind[2]
	var shin: float = kind[3] + kind[4]
	var foot: float = kind[5]
	var thick: float = kind[6]
	# Del tronco: la columna, el cuello y la cabeza (lo que queda de los ojos sobre la pelvis).
	var spine := _spine(eye_above - 0.24)
	var hip := spine[0]
	var chest := spine[spine.size() - 1]
	var lean := (chest - spine[spine.size() - 2]).normalized()
	var neck := chest + lean.rotated(deg_to_rad(-18.0)) * 0.12
	var head := neck + Vector2(0.03, 0.11)
	var eye := head + Vector2(0.08, 0.0)
	for k in range(1, spine.size()):
		_limb(root, _at(spine[k - 1], 0.0), _at(spine[k], 0.0), thick, BODY)
	_limb(root, _at(chest, 0.0), _at(neck, 0.0), 0.06, BODY)
	Clay.sphere(root, 0.11, _at(head, 0.0), BODY)
	Clay.sphere(root, 0.02, _at(eye, 0.0), Color.BLACK)
	# Las piernas: el pie donde la esfera queda a `REACH` del largo de la pierna.
	var leg := thigh + shin
	var target := _touch(hip, leg * REACH, _radius - 0.06)
	var knee := _knee(hip, target, thigh, shin)
	var toe := target + (target - knee).normalized().rotated(deg_to_rad(80.0)) * foot
	# Las manos, en los controles, adelante y abajo del centro.
	var hand := Vector2(0.35, -0.38)
	for s: float in [-1.0, 1.0]:
		var x := s * 0.11
		_limb(root, _at(hip, x), _at(knee, x), thick * 0.55, BODY)
		_limb(root, _at(knee, x), _at(target, x), thick * 0.45, BODY)
		_limb(root, _at(target, x), _at(toe, x), 0.045, BODY)
		var shoulder := chest + Vector2(0.0, -0.04)
		var elbow := _knee(shoulder, hand, 0.3, 0.3, -1.0)
		_limb(root, _at(shoulder, s * 0.21), _at(elbow, s * 0.27), 0.05, BODY)
		_limb(root, _at(elbow, s * 0.27), _at(hand, s * 0.2), 0.045, BODY)
	Clay.box(root, Vector3(0.7, 0.04, 0.22), _at(hand + Vector2(0.06, -0.06), 0.0), SEAT)
	# La cámara: el centro, y su mirada.
	Clay.sphere(root, 0.045, Vector3.ZERO, RED)
	_limb(root, Vector3.ZERO, _at(Vector2(_radius, 0.0), 0.0), 0.008, RED)


## Donde la esfera de radio `wall` queda a `reach` de `from`: de los dos, el de más adelante. Si no la alcanza, lo más
## lejos adelante y abajo.
func _touch(from: Vector2, reach: float, wall: float) -> Vector2:
	var gap := from.length()
	if gap + reach < wall or gap < 0.001:
		return from + _dir(-25.0, reach)
	var along := (gap * gap + wall * wall - reach * reach) / (2.0 * gap)
	var side := sqrt(maxf(wall * wall - along * along, 0.0))
	var axis := from / gap
	var middle := axis * along
	var a := middle + axis.orthogonal() * side
	var b := middle - axis.orthogonal() * side
	return a if a.x > b.x else b


## LA RODILLA (o el codo) de un IK de dos huesos de `from` a `to`, doblada hacia arriba (`bend` 1) o abajo (−1).
func _knee(from: Vector2, to: Vector2, upper: float, lower: float, bend := 1.0) -> Vector2:
	var span := clampf(from.distance_to(to), 0.01, upper + lower - 0.001)
	var cosine := clampf((upper * upper + span * span - lower * lower) / (2.0 * upper * span), -1.0, 1.0)
	return from + (to - from).normalized().rotated(bend * acos(cosine)) * upper


func _slab(root: Node3D, a: Vector2, b: Vector2, wide: float, thick: float, color: Color) -> void:
	var holder := Clay.box(root, Vector3(wide, thick, a.distance_to(b) + 0.02), Vector3.ZERO, color)
	var along := (_at(b, 0.0) - _at(a, 0.0)).normalized()
	holder.transform = Transform3D(Basis.looking_at(along, Vector3.RIGHT.cross(along).normalized() * -1.0),
		(_at(a, 0.0) + _at(b, 0.0)) * 0.5)


## Una oreja del casco: una tira de costado que sale hacia adelante.
func _wing(root: Node3D, a: Vector2, b: Vector2, x: float, out: float) -> void:
	var along := (b - a).normalized()
	var front := Vector2(along.y, -along.x)
	if front.x < 0.0:
		front = -front
	var holder := Clay.box(root, Vector3(0.04, out, a.distance_to(b) + 0.02), Vector3.ZERO, SEAT)
	var dir3 := (_at(b, 0.0) - _at(a, 0.0)).normalized()
	holder.transform = Transform3D(Basis.looking_at(dir3, _at(front, 0.0).normalized()),
		_at((a + b) * 0.5 + front * out * 0.5, x))


func _sphere(root: Node3D) -> void:
	for part: Array in [[PI * 0.5, PI, SHELL], [0.0, PI * 0.5, GLASS]]:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		CageMesh.sphere_band(tool, Vector3.ZERO, _radius, part[0], part[1], false)
		var mesh := MeshInstance3D.new()
		mesh.mesh = tool.commit()
		var paint := Clay.material(part[2]).duplicate() as StandardMaterial3D
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = paint
		root.add_child(mesh)


func _at(p: Vector2, x: float) -> Vector3:
	return Vector3(x, p.y, -p.x)


func _dir(degrees: float, length: float) -> Vector2:
	var a := deg_to_rad(degrees)
	return Vector2(cos(a), sin(a)) * length


func _limb(root: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var holder := Clay.limb(root, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)


func _stage() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 60.0, 0.0)
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
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


func _view(from: Vector3, to: Vector3, size: float) -> Image:
	if size > 0.0:
		_eye.size = size
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array[Image]) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var w := shots[0].get_width()
	var h := shots[0].get_height()
	var sheet := Image.create(w * 2, h * ceili(shots.size() / 2.0), false, shots[0].get_format())
	for index in shots.size():
		sheet.blit_rect(shots[index], Rect2i(Vector2i.ZERO, shots[index].get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/silla_%d.png" % [_folder, int(round(_radius * 100.0))]
	sheet.save_png(path)
	print("CAPTURA ", path)
