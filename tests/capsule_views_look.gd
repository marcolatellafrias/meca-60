extends Node3D

## CÓMO SE VE DESDE CADA CÁPSULA (15/11/2026, sesión Tableros): la meca de cápsulas (ver tests/sphere_pods_look), con
## cuatro cápsulas esféricas metidas a medias en el cuerpo: la de adelante, las de los brazos a los costados y la de
## arriba. La mitad de afuera de cada cápsula es VIDRIO; la de adentro, pared con controles. Para ver si los de los
## costados ven su brazo entero aunque media vista sea pared, y qué le pasa a la de arriba. Sólo para mirar.
##   tools/godot_ventana.sh res://tests/capsule_views_look.tscn -- --salida=C:/carpeta

const BODY_CENTER := Vector3(0, 3.2, 0)
const BODY_RADIUS := 2.5
const POD_RADIUS := 0.9
## Cuánto sale cada cápsula del cuerpo: 0 al ras, 1 entera afuera (0,5: la mitad).
const POD_OUT := 0.5
const SPREAD := 62.0
const EYE_UP := 0.2

const STEEL := Color(0.36, 0.37, 0.39)
const DARK := Color(0.13, 0.13, 0.14)
const LIGHT := Color(0.62, 0.64, 0.66)
const CREAM := Color(0.86, 0.83, 0.74)
const INK := Color(0.08, 0.08, 0.08)
const GREEN := Color(0.35, 1.0, 0.45)
const AMBER := Color(1.0, 0.6, 0.18)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
## Cada cápsula: su nombre, hacia dónde sale del cuerpo y su centro.
var _pods: Array[Dictionary] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	_world()
	for spec in [["ADELANTE", 0.0, 0.0], ["BRAZO IZQUIERDO", SPREAD, 0.0], ["BRAZO DERECHO", -SPREAD, 0.0], ["ARRIBA", 0.0, 90.0]]:
		var way := _direction(spec[1], spec[2])
		_pods.append({"name": spec[0], "way": way, "center": BODY_CENTER + way * (BODY_RADIUS + POD_RADIUS * (POD_OUT * 2.0 - 1.0))})
	_body()
	for pod in _pods:
		_pod(pod)
	_arms()
	_eye = Camera3D.new()
	_eye.fov = 78.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 680)
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 6)
	layer.add_child(_title)
	await get_tree().process_frame
	_view_from(Vector3(5.5, 5.0, -7.5), BODY_CENTER + Vector3(0, 0.4, 0))
	await _shot("1. Desde afuera: las cuatro cápsulas, la mitad afuera (vidrio) y la mitad adentro", "1")
	_view_from(Vector3(-7.0, 4.2, -3.5), BODY_CENTER)
	await _shot("2. Desde afuera, del lado del brazo izquierdo", "2")
	_inside(0, 0.0, -6.0)
	await _shot("3. Adelante, mirando al frente", "3")
	_inside(1, 0.0, -8.0)
	await _shot("4. Brazo izquierdo, mirando hacia afuera (a su brazo)", "4")
	_inside(1, 32.0, -18.0)
	await _shot("4b. Brazo izquierdo, girado hacia su hombro", "4b")
	_inside(1, -50.0, -6.0)
	await _shot("5. Brazo izquierdo, girado hacia el frente", "5")
	_inside(1, 70.0, -5.0)
	await _shot("6. Brazo izquierdo, girado hacia atrás: la pared con los controles", "6")
	_inside(2, 0.0, -8.0)
	await _shot("7. Brazo derecho, mirando hacia afuera (a su brazo)", "7")
	_inside(3, 0.0, -10.0, true)
	await _shot("8. Arriba, mirando al frente por encima del cuerpo", "8")
	_inside(3, 0.0, -40.0, true)
	await _shot("9. Arriba, mirando abajo: el cuerpo tapa", "9")
	get_tree().quit()


func _direction(yaw: float, pitch: float) -> Vector3:
	var y := deg_to_rad(yaw)
	var p := deg_to_rad(pitch)
	return Vector3(-sin(y) * cos(p), sin(p), -cos(y) * cos(p))


func _world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, -150.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.62, 0.6, 0.57)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.62, 0.62, 0.66)
	world.environment.ambient_light_energy = 0.5
	world.environment.fog_enabled = true
	world.environment.fog_light_color = Color(0.62, 0.6, 0.57)
	world.environment.fog_density = 0.01
	add_child(world)
	Clay.box(self, Vector3(300, 1, 300), Vector3(0, -0.5, 0), Color(0.44, 0.41, 0.37))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 30:
		var angle := rng.randf_range(-PI, PI)
		var distance := rng.randf_range(40.0, 90.0)
		var tall := rng.randf_range(10.0, 40.0)
		Clay.box(self, Vector3(12, tall, 12), Vector3(sin(angle) * distance, tall * 0.5, -cos(angle) * distance), Color(0.4, 0.4, 0.42))
	# Una meca enemiga adelante.
	var boss := Color(0.2, 0.19, 0.2)
	Clay.box(self, Vector3(5, 6, 4), Vector3(4, 9, -28), boss)
	Clay.box(self, Vector3(2.6, 0.5, 0.3), Vector3(4, 10.5, -25.9), AMBER)
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(1.6, 6, 1.6), Vector3(4 + side * 1.4, 3, -28), boss)


# ── EL CUERPO: una esfera de chapa, hueca donde están las cápsulas; con piernas ─────────────────────────────────
func _body() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 pods[4];
varying vec3 world;
varying vec3 local;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; local = VERTEX; }
void fragment() {
	for (int i = 0; i < 4; i++) { if (distance(world, pods[i].xyz) < pods[i].w + 0.06) { discard; } }
	vec3 d = normalize(local);
	float lon = atan(d.x, -d.z) * 57.2958;
	float lat = asin(clamp(d.y, -1.0, 1.0)) * 57.2958;
	float seam = step(abs(mod(lon + 7.5, 15.0) - 7.5), 0.25) + step(abs(mod(lat + 7.5, 15.0) - 7.5), 0.25);
	ALBEDO = mix(vec3(0.5, 0.52, 0.55), vec3(0.28, 0.29, 0.31), clamp(seam, 0.0, 1.0));
	ROUGHNESS = 0.65;
	METALLIC = 0.3;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	var spots: Array[Vector4] = []
	for pod in _pods:
		spots.append(Vector4(pod.center.x, pod.center.y, pod.center.z, POD_RADIUS))
	material.set_shader_parameter("pods", spots)
	var body := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = BODY_RADIUS
	ball.height = BODY_RADIUS * 2.0
	ball.radial_segments = 128
	ball.rings = 64
	body.mesh = ball
	body.material_override = material
	body.position = BODY_CENTER
	add_child(body)
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(1.0, 1.6, 1.2), Vector3(side * 1.1, 0.8, 0), STEEL)
		Clay.box(self, Vector3(1.4, 0.3, 1.8), Vector3(side * 1.1, 0.15, -0.2), DARK)


# ── UNA CÁPSULA: la mitad de afuera del cuerpo es vidrio; la de adentro, pared con controles. Su silla y alguien. ──
func _pod(pod: Dictionary) -> void:
	var center: Vector3 = pod.center
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, depth_draw_always;
uniform vec3 body_center;
uniform float body_radius;
varying vec3 world;
varying vec3 local;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; local = VERTEX; }
void fragment() {
	bool glass = distance(world, body_center) > body_radius;
	vec3 d = normalize(local);
	float lon = atan(d.x, -d.z) * 57.2958;
	float lat = asin(clamp(d.y, -1.0, 1.0)) * 57.2958;
	float seam = step(abs(mod(lon + 15.0, 30.0) - 15.0), 0.4) + step(abs(mod(lat + 10.0, 20.0) - 10.0), 0.35);
	if (glass) {
		// El vidrio va en paños, con su marco de metal donde están las costuras.
		float frame = clamp(step(abs(mod(lon + 22.5, 45.0) - 22.5), 0.45) + step(abs(mod(lat + 15.0, 30.0) - 15.0), 0.4), 0.0, 1.0);
		ALBEDO = mix(vec3(0.6, 0.72, 0.75), vec3(0.16, 0.16, 0.17), frame);
		ALPHA = mix(0.1, 1.0, frame);
		ROUGHNESS = mix(0.05, 0.6, frame);
	} else {
		ALBEDO = mix(vec3(0.27, 0.28, 0.29), vec3(0.1, 0.1, 0.11), clamp(seam, 0.0, 1.0));
		ROUGHNESS = 0.7;
	}
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("body_center", BODY_CENTER)
	material.set_shader_parameter("body_radius", BODY_RADIUS)
	var shell := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = POD_RADIUS
	ball.height = POD_RADIUS * 2.0
	ball.radial_segments = 64
	ball.rings = 32
	shell.mesh = ball
	shell.material_override = material
	shell.position = center
	add_child(shell)
	# El aro donde la cápsula se mete en el cuerpo: el canto entre vidrio y pared.
	var way: Vector3 = pod.way
	var cut := (BODY_RADIUS * BODY_RADIUS - POD_RADIUS * POD_RADIUS + center.distance_squared_to(BODY_CENTER)) / (2.0 * center.distance_to(BODY_CENTER))
	var rim_center := BODY_CENTER + way * cut
	var rim_radius := sqrt(maxf(BODY_RADIUS * BODY_RADIUS - cut * cut, 0.01))
	_ring(rim_center, way, rim_radius, 0.05, DARK)
	_ring(rim_center + way * 0.04, way, rim_radius - 0.03, 0.015, Clay.YELLOW)
	# Controles en la pared de adentro (la mitad metida en el cuerpo): tres placas y una pantalla verde.
	var frame := _frame(way)
	for spot: Vector2 in [Vector2(-50, -20), Vector2(50, -20), Vector2(0, -55), Vector2(-40, 30), Vector2(40, 30)]:
		var inward := (frame * _direction(spot.x, spot.y) * Vector3(1, 1, 1))
		var back := -way * 0.75 + inward * 0.55
		var at := center + back.normalized() * (POD_RADIUS - 0.06)
		if at.distance_to(BODY_CENTER) > BODY_RADIUS - 0.02:
			continue
		var plate := Node3D.new()
		add_child(plate)
		plate.position = at
		plate.look_at(center, Vector3.UP if absf((center - at).normalized().y) < 0.95 else Vector3.FORWARD)
		plate.rotate_object_local(Vector3.UP, PI)
		Clay.box(plate, Vector3(0.3, 0.22, 0.04), Vector3.ZERO, STEEL)
		for k in 3:
			Clay.box(plate, Vector3(0.06, 0.05, 0.03), Vector3(-0.08 + k * 0.08, -0.02, 0.025), CREAM if k != 1 else INK)
			Clay.sphere(plate, 0.012, Vector3(-0.08 + k * 0.08, 0.05, 0.025), AMBER if k == 0 else Color(0.3, 0.22, 0.14))
		Clay.box(plate, Vector3(0.24, 0.04, 0.02), Vector3(0, 0.085, 0.022), INK)
	# La silla, mirando hacia afuera del cuerpo (lo que tiene que ver), y alguien sentado.
	var seat := Node3D.new()
	add_child(seat)
	seat.position = center + Vector3(0, -0.62, 0)
	var flat := Vector3(way.x, 0, way.z)
	if flat.length() > 0.1:
		seat.look_at(seat.position + flat, Vector3.UP)
	Clay.box(seat, Vector3(0.5, 0.08, 0.5), Vector3(0, 0.36, 0.08), STEEL)
	Clay.box(seat, Vector3(0.5, 0.7, 0.08), Vector3(0, 0.72, 0.36), STEEL)
	Clay.cylinder(seat, 0.08, 0.36, Vector3(0, 0.18, 0.08), DARK)
	var suit := Color(0.32, 0.36, 0.42)
	var skin := Color(0.78, 0.62, 0.5)
	Clay.box(seat, Vector3(0.34, 0.48, 0.22), Vector3(0, 0.66, 0.24), suit)
	Clay.sphere(seat, 0.11, Vector3(0, 1.0, 0.18), skin)
	for side: float in [-1.0, 1.0]:
		Clay.box(seat, Vector3(0.13, 0.13, 0.4), Vector3(side * 0.1, 0.44, 0.04), suit)
		Clay.box(seat, Vector3(0.12, 0.38, 0.12), Vector3(side * 0.1, 0.22, -0.14), suit)
	pod["eye"] = seat.position + seat.global_basis * Vector3(0, 0.98 + EYE_UP * 0.0, 0.12)
	pod["seat_basis"] = seat.global_basis
	var tag := StrokeLabel.make(pod.name, 0.12, CREAM)
	add_child(tag)
	tag.position = center + way * (POD_RADIUS + 0.25)
	tag.look_at(tag.position - Vector3(0.4, -0.1, 1).normalized(), Vector3.UP)
	tag.rotate_object_local(Vector3.UP, PI)


## Una base con el eje −Z hacia `way`.
func _frame(way: Vector3) -> Basis:
	if absf(way.y) > 0.95:
		return Basis(Vector3.RIGHT, Vector3.BACK if way.y > 0.0 else Vector3.FORWARD, -way).orthonormalized()
	return Basis.looking_at(way, Vector3.UP)


func _ring(at: Vector3, axis: Vector3, radius: float, thick: float, color: Color) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thick
	mesh.outer_radius = radius + thick
	mesh.rings = 64
	var ring := MeshInstance3D.new()
	ring.mesh = mesh
	ring.material_override = Clay.material(color)
	add_child(ring)
	var up := axis.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	ring.transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(), at)


# ── LOS BRAZOS: a los costados del cuerpo, atrás de las cápsulas de los brazos; el cañón y la espada ─────────────
func _arms() -> void:
	for side: float in [-1.0, 1.0]:
		var shoulder := BODY_CENTER + _direction(side * 92.0, -5.0) * (BODY_RADIUS + 0.2)
		Clay.sphere(self, 0.75, shoulder, STEEL)
		var elbow := shoulder + Vector3(side * -0.5, -1.4, -0.9)
		_bar(shoulder, elbow, 0.38, Color(0.3, 0.31, 0.33))
		Clay.sphere(self, 0.42, elbow, DARK)
		if side > 0.0:
			# Brazo izquierdo: el cañón, apuntando al frente.
			var tip := elbow + Vector3(0.1, 0.3, -2.6)
			_bar(elbow, tip, 0.34, Color(0.24, 0.25, 0.26))
			for k in 4:
				var at := elbow.lerp(tip, 0.25 + k * 0.18)
				Clay.sphere(self, 0.38, at, DARK).scale = Vector3(1, 1, 0.25)
		else:
			# Brazo derecho: la mano con la espada.
			var fist := elbow + Vector3(0.0, 0.2, -1.6)
			_bar(elbow, fist, 0.32, Color(0.3, 0.31, 0.33))
			Clay.box(self, Vector3(0.6, 0.6, 0.6), fist, Color(0.26, 0.27, 0.28))
			Clay.box(self, Vector3(1.2, 0.12, 0.25), fist + Vector3(0, 0.36, -0.1), DARK)
			_bar(fist + Vector3(0, 0.4, -0.1), fist + Vector3(-0.6, 3.6, -1.4), 0.09, Color(0.82, 0.84, 0.86))


func _bar(from: Vector3, to: Vector3, radius: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = from.distance_to(to)
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = Clay.material(color)
	add_child(piece)
	var up := (to - from).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	piece.transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(), (from + to) * 0.5)


## La cámara en los ojos de quien va en la cápsula `index`, girada `yaw` grados (izquierda +) y `pitch`.
func _inside(index: int, yaw: float, pitch: float, top := false) -> void:
	var pod := _pods[index]
	var base: Basis = pod.seat_basis
	_eye.global_position = pod.eye
	var look := base * Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, deg_to_rad(pitch))
	_eye.global_basis = look


func _view_from(from: Vector3, to: Vector3) -> void:
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)


func _shot(title: String, file_name: String) -> void:
	_title.text = title
	for i in 6:
		await get_tree().process_frame
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
