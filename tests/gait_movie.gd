extends Node

## LA MARCHA DE 4 Y 6 PATAS (con ventana, unos 25 segundos de video): dos cuerpos de arcilla, uno de CUATRO patas (pisan
## las diagonales) y uno de SEIS (el trípode), con la marcha común (Gait) y el IK común (Gait.knee), hacen el mismo
## recorrido: arrancar, doblar andando, frenar, ir de costado, girar en el lugar, correr y frenar. Una grilla en el piso
## (cada 2 m) para ver si los pies patinan. Imprime cuántos pasos dio cada uno. Se graba con --write-movie:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/patas.avi --fixed-fps 30 res://tests/gait_movie.tscn

## El recorrido: [texto, s, adelante m/s, de costado m/s, giro °/s].
const ROUTE := [
	["quietos", 1.0, 0.0, 0.0, 0.0],
	["arrancan y andan (3 m/s)", 3.0, 3.0, 0.0, 0.0],
	["doblan andando", 3.0, 3.0, 0.0, 45.0],
	["frenan", 1.5, 0.0, 0.0, 0.0],
	["de costado", 2.5, 0.0, 2.5, 0.0],
	["giran en el lugar", 2.5, 0.0, 0.0, 70.0],
	["corren (7 m/s)", 2.5, 7.0, 0.0, 0.0],
	["frenan de golpe", 2.0, 0.0, 0.0, 0.0],
]

var _bodies: Array[Dictionary] = []
var _eye: Camera3D = null
var _title: Label = null
## Donde cuelgan las piernas (en el origen: lo que se les escribe es el mundo).
var _limbs := Node3D.new()


func _ready() -> void:
	add_child(_limbs)
	_world()
	_bodies.append(_build("cuatro patas (diagonales)", Vector3(-7.0, 0.0, 0.0), Vector3(3.4, 1.4, 4.6), 2.5,
		[-2.0, 2.0], 3.4, 2.3, 2.7))
	_bodies.append(_build("seis patas (trípode)", Vector3(7.0, 0.0, 0.0), Vector3(3.0, 1.3, 5.8), 2.3,
		[-2.4, 0.0, 2.4], 3.5, 2.1, 2.5))
	_eye = Camera3D.new()
	_eye.fov = 55.0
	add_child(_eye)
	_eye.make_current()
	var yaw := 0.0
	var first := true
	for leg in ROUTE:
		_title.text = leg[0]
		var clock := 0.0
		while clock < float(leg[1]):
			var delta := 1.0 / Engine.physics_ticks_per_second
			yaw += deg_to_rad(float(leg[4])) * delta
			var turn := Basis(Vector3.UP, yaw)
			var velocity := turn * Vector3(float(leg[3]), 0.0, -float(leg[2]))
			# Cada uno anda solo, con su giro y su velocidad: dobla y gira en el lugar sobre su medio.
			var middle := Vector3.ZERO
			for body in _bodies:
				body["at"] = (body["at"] as Vector3) + velocity * delta
				_move(body, Transform3D(turn, body["at"]), velocity, delta)
				middle += (body["at"] as Vector3) / _bodies.size()
			# La cámara, atrás y arriba de los dos, sin girar con ellos (para ver el giro).
			middle += Vector3.UP * 1.5
			var wanted := middle + Vector3(6.0, 10.0, 16.0)
			_eye.global_position = wanted if first else _eye.global_position.lerp(wanted, 0.08)
			first = false
			_eye.look_at(middle, Vector3.UP)
			await get_tree().physics_frame
			clock += delta
	for body in _bodies:
		print("%s: %d pasos" % [body["title"], (body["gait"] as Gait).steps_taken])
	get_tree().quit()


## UN CUERPO: una caja a `height` m, con un par de caderas por cada fila (`rows`, z), los pies a `reach` m del medio,
## muslo `upper` y canilla `lower`.
func _build(title: String, offset: Vector3, size: Vector3, height: float, rows: Array, reach: float, upper: float,
		lower: float) -> Dictionary:
	var body := Node3D.new()
	add_child(body)
	Clay.box(body, size, Vector3.UP * height, Color(0.55, 0.32, 0.28))
	Clay.box(body, Vector3(size.x * 0.4, 0.3, 0.6), Vector3(0.0, height + size.y * 0.3, -size.z * 0.5), Color(1.0, 0.6, 0.2))
	var hips: Array[Vector3] = []
	var rests: Array[Vector3] = []
	for z: float in rows:
		for side: float in [-1.0, 1.0]:
			hips.append(Vector3(side * size.x * 0.5, height - size.y * 0.3, z))
			rests.append(Vector3(side * reach, 0.0, z * 1.15))
	var gait := Gait.new()
	gait.stride = 2.6
	gait.lift = 0.8
	gait.setup(rests)
	var parts := []
	for leg in hips.size():
		var thigh := Clay.box(_limbs, Vector3.ONE, Vector3.ZERO, Color(0.35, 0.36, 0.4))
		var shin := Clay.box(_limbs, Vector3.ONE, Vector3.ZERO, Color(0.25, 0.26, 0.3))
		var foot := Clay.box(_limbs, Vector3(0.6, 0.25, 0.6), Vector3.ZERO, Clay.DARK)
		parts.append([thigh, shin, foot])
	var root := Transform3D(Basis(), offset)
	body.global_transform = root
	gait.place(root)
	return {"title": title, "body": body, "gait": gait, "hips": hips, "parts": parts, "at": offset,
		"upper": upper, "lower": lower}


func _move(body: Dictionary, root: Transform3D, velocity: Vector3, delta: float) -> void:
	(body["body"] as Node3D).global_transform = root
	var gait: Gait = body["gait"]
	gait.update(delta, root, velocity)
	for leg in gait.feet.size():
		var hip: Vector3 = root * (body["hips"][leg] as Vector3)
		var foot: Vector3 = gait.feet[leg] + Vector3.UP * 0.12
		# Las rodillas, arriba y hacia afuera (como una araña).
		var out := hip - root.origin
		out.y = 0.0
		var knee := Gait.knee(hip, foot, body["upper"], body["lower"], Vector3.UP * 1.5 + out.normalized())
		var parts: Array = body["parts"][leg]
		Clay.segment(parts[0], hip, knee, 0.45)
		Clay.segment(parts[1], knee, foot, 0.35)
		(parts[2] as Node3D).global_transform = Transform3D(root.basis, gait.feet[leg] + Vector3.UP * 0.12)


func _world() -> void:
	var ground := Node3D.new()
	add_child(ground)
	Clay.box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	for line in range(-60, 61):
		var x := line * 2.0
		Clay.box(ground, Vector3(0.05, 0.02, 240.0), Vector3(x, 0.01, -60.0), Color(0.55, 0.55, 0.55))
		Clay.box(ground, Vector3(240.0, 0.02, 0.05), Vector3(0.0, 0.01, x - 60.0), Color(0.55, 0.55, 0.55))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 205.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var names := Label.new()
	names.position = Vector2(20, 500)
	names.add_theme_font_size_override("font_size", 18)
	names.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	names.add_theme_constant_override("outline_size", 6)
	names.text = "izquierda: cuatro patas (diagonales) · derecha: seis patas (trípode)"
	layer.add_child(names)
