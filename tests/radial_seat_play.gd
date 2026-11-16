extends Node3D

## EL PUESTO DEL CAÑÓN CON LOS CONTROLES EN RADIO (15/11/2026, sesión Tableros; ver docs/conceptual/armamento.md,
## «Controles en radio alrededor de la silla»). Una maqueta para jugar: sentado en una cabina redonda, con los controles
## en brazos alrededor de la silla, como la de las referencias del usuario. Sólo el clic izquierdo:
##   · el mouse mira (con tope: no se mira atrás); el punto del medio es lo que se toca;
##   · clic en un botón lo aprieta; mantener el clic en la empuñadura la agarra, y entonces lo que mirás es adonde va
##     el cañón, que la sigue con su resorte (llega tarde y se pasa);
##   · los ataques: se aprietan, se cargan un tiempo fijo y salen solos. Ráfaga se prende y se apaga; barrido se carga y
##     dura un rato; súper se carga más y tira una sola vez.
## Esc suelta el mouse; otra vez Esc, sale.
##   tools/godot_ventana.sh res://tests/radial_seat_play.tscn
##   tools/godot_ventana.sh res://tests/radial_seat_play.tscn -- --demo --salida=C:/carpeta   (se juega solo y captura)

const EYE := Vector3(0, 1.15, 0)
const YAW_LIMIT := 110.0
const PITCH_UP := 40.0
const PITCH_DOWN := -65.0
const LOOK_SPEED := 0.12

const STEEL := Color(0.36, 0.37, 0.39)
const DARK := Color(0.13, 0.13, 0.14)
const LIGHT := Color(0.62, 0.64, 0.66)
const CREAM := Color(0.86, 0.83, 0.74)
const INK := Color(0.08, 0.08, 0.08)
const GREEN := Color(0.35, 1.0, 0.45)
const AMBER := Color(1.0, 0.6, 0.18)
const RED := Color(0.85, 0.15, 0.12)
const HOVER := Color(1.0, 0.85, 0.3)

## Las demoras de cada ataque (s) y lo que dura el barrido.
const SWEEP_CHARGE := 1.2
const SWEEP_TIME := 3.0
const SUPER_CHARGE := 2.6
const BURST_EVERY := 0.11

var _eye: Camera3D = null
var _yaw := 0.0
var _pitch := -8.0
var _hint: Label = null
var _dot: ColorRect = null
var _controls: Array[Dictionary] = []
var _hovered: Dictionary = {}
var _holding: Dictionary = {}

# El cañón: el hombro, hacia dónde mira de verdad y a qué velocidad gira (el resorte).
var _shoulder: Node3D = null
var _muzzle: Node3D = null
var _aim := Vector3.FORWARD
var _aim_speed := Vector3.ZERO
var _marker: MeshInstance3D = null

var _energy := 1.0
var _burst := false
var _burst_clock := 0.0
var _sweep_charge := -1.0
var _sweep_left := 0.0
var _super_charge := -1.0
var _beam: MeshInstance3D = null
var _bolts: Array[Dictionary] = []
var _target: Node3D = null
var _target_flash := 0.0
var _target_home := Vector3.ZERO

# Lo que se prende: lamparitas y barras.
var _lamps := {}
var _bars := {}

var _demo := false
## La cámara de afuera (en la demo): `_process` no la toca.
var _outside := false
var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--demo":
			_demo = true
		elif argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	_world()
	_cabin()
	_cannon()
	_station()
	_eye = Camera3D.new()
	_eye.fov = 74.0
	_eye.position = EYE
	add_child(_eye)
	_eye.make_current()
	_hud()
	if _demo:
		_play_demo()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ── EL MUNDO ─────────────────────────────────────────────────────────────────────────────────────────────────────
func _world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38.0, -150.0, 0.0)
	sun.shadow_enabled = true
	sun.light_energy = 0.9
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.55, 0.53, 0.5)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.6, 0.6, 0.64)
	world.environment.ambient_light_energy = 0.3
	world.environment.fog_enabled = true
	world.environment.fog_light_color = Color(0.55, 0.53, 0.5)
	world.environment.fog_density = 0.008
	world.environment.glow_enabled = true
	add_child(world)
	Clay.box(self, Vector3(400, 1, 400), Vector3(0, -6.5, 0), Color(0.42, 0.39, 0.35))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 40:
		var angle := rng.randf_range(-2.4, 2.4)
		var distance := rng.randf_range(70.0, 140.0)
		var tall := rng.randf_range(15.0, 60.0)
		Clay.box(self, Vector3(rng.randf_range(10, 22), tall, rng.randf_range(10, 22)),
			Vector3(sin(angle) * distance, -6.0 + tall * 0.5, -cos(angle) * distance), Color(0.38, 0.38, 0.4))
	# La meca enemiga, de blanco.
	_target = Node3D.new()
	add_child(_target)
	_target_home = Vector3(6.0, -6.0, -40.0)
	_target.position = _target_home
	var body := Color(0.2, 0.19, 0.2)
	Clay.box(_target, Vector3(7, 8, 5), Vector3(0, 13, 0), body)
	Clay.box(_target, Vector3(3.6, 0.6, 0.4), Vector3(0, 15, 2.6), AMBER)
	for side: float in [-1.0, 1.0]:
		Clay.box(_target, Vector3(1.6, 6, 2.6), Vector3(side * 4.6, 12, 0), body)
		Clay.box(_target, Vector3(2, 9, 2.6), Vector3(side * 1.8, 4.5, 0), body)


# ── LA CÁPSULA: una esfera ceñida al que va sentado, con una ventana al frente; la silla gira adentro, en su aro ──
## La esfera: su centro y su radio de adentro; la ventana, hacia dónde mira y su medio ángulo.
const SPHERE_CENTER := Vector3(0, 0.95, 0.08)
const SPHERE_RADIUS := 0.92
const WINDOW_DIR := Vector3(0, -0.1, -1)
const WINDOW_HALF := 36.0

var _shell: ShaderMaterial = null
var _seat: Node3D = null


func _cabin() -> void:
	# La cáscara: chapa con sus costuras; la ventana, un hueco redondo adelante (y un corte para mirarla desde afuera).
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 center;
uniform vec3 window_dir;
uniform float window_cos;
uniform float cut_z = 99.0;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 d = normalize(world - center);
	if (dot(d, normalize(window_dir)) > window_cos || world.z > cut_z) { discard; }
	float lon = atan(d.x, -d.z) * 57.2958;
	float lat = asin(clamp(d.y, -1.0, 1.0)) * 57.2958;
	float seam = step(abs(mod(lon + 15.0, 30.0) - 15.0), 0.35) + step(abs(mod(lat + 10.0, 20.0) - 10.0), 0.3);
	vec3 inner = mix(vec3(0.24, 0.25, 0.26), vec3(0.09, 0.09, 0.1), clamp(seam, 0.0, 1.0));
	vec3 outer = mix(vec3(0.42, 0.43, 0.45), vec3(0.25, 0.25, 0.26), clamp(seam, 0.0, 1.0));
	ALBEDO = FRONT_FACING ? outer : inner;
	ROUGHNESS = 0.7;
	METALLIC = 0.35;
}
"""
	_shell = ShaderMaterial.new()
	_shell.shader = shader
	_shell.set_shader_parameter("center", SPHERE_CENTER)
	_shell.set_shader_parameter("window_dir", WINDOW_DIR)
	_shell.set_shader_parameter("window_cos", cos(deg_to_rad(WINDOW_HALF)))
	var shell := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = SPHERE_RADIUS + 0.03
	ball.height = (SPHERE_RADIUS + 0.03) * 2.0
	ball.radial_segments = 96
	ball.rings = 48
	shell.mesh = ball
	shell.material_override = _shell
	shell.position = SPHERE_CENTER
	add_child(shell)
	# El marco de la ventana: un aro grueso con su franja de peligro y remaches.
	var window := WINDOW_DIR.normalized()
	var rim_center := SPHERE_CENTER + window * SPHERE_RADIUS * cos(deg_to_rad(WINDOW_HALF))
	var rim_radius := SPHERE_RADIUS * sin(deg_to_rad(WINDOW_HALF))
	var rim := _ring(rim_center, window, rim_radius, 0.045, DARK)
	rim.name = "Marco de la ventana"
	_ring(rim_center - window * 0.02, window, rim_radius - 0.05, 0.012, Clay.YELLOW)
	for k in 24:
		var angle := TAU * k / 24.0
		var side := window.cross(Vector3.UP).normalized()
		var up := side.cross(window).normalized()
		Clay.sphere(self, 0.012, rim_center - window * 0.03 + (side * cos(angle) + up * sin(angle)) * (rim_radius - 0.02), LIGHT)
	# Las costillas: dos aros que abrazan la cabeza (adelante y atrás de los ojos) y dos de latitud, con remaches.
	for z: float in [-0.15, 0.3]:
		var reach := sqrt(SPHERE_RADIUS * SPHERE_RADIUS - pow(z - SPHERE_CENTER.z, 2.0)) - 0.02
		_ring(Vector3(SPHERE_CENTER.x, SPHERE_CENTER.y, z), Vector3.BACK, reach, 0.028, STEEL)
		for k in 20:
			var angle := TAU * k / 20.0
			Clay.sphere(self, 0.01, Vector3(cos(angle) * (reach - 0.025), SPHERE_CENTER.y + sin(angle) * (reach - 0.025), z - 0.02), LIGHT)
	for pitch: float in [-38.0, 42.0]:
		var y := SPHERE_CENTER.y + sin(deg_to_rad(pitch)) * SPHERE_RADIUS
		_ring(Vector3(SPHERE_CENTER.x, y, SPHERE_CENTER.z), Vector3.UP, cos(deg_to_rad(pitch)) * SPHERE_RADIUS - 0.02, 0.022, STEEL)
	# Caños de cables que corren por la pared, de abajo hacia arriba, por atrás y los costados.
	for yaw: float in [-120.0, -95.0, 95.0, 120.0, 170.0]:
		for k in 10:
			var from := _on_wall(yaw, -60.0 + k * 13.0, 0.04)
			var to := _on_wall(yaw, -60.0 + (k + 1) * 13.0, 0.04)
			_bar(self, from, to, 0.016, INK)
		for pitch: float in [-30.0, 10.0, 50.0]:
			Clay.sphere(self, 0.024, _on_wall(yaw, pitch, 0.04), STEEL)
	# Dos lámparas enjauladas arriba, de luz cálida.
	for yaw: float in [40.0, -40.0]:
		var lamp_at := _wall(yaw, 35.0, 0.03)
		Clay.cylinder(lamp_at, 0.05, 0.03, Vector3(0, 0, 0.0), DARK, Vector3(90, 0, 0))
		var bulb := Clay.sphere(lamp_at, 0.035, Vector3(0, 0, 0.03), CREAM)
		bulb.material_override = _glow(Color(1.0, 0.85, 0.6), 2.2)
		for k in 4:
			var cage := Clay.box(lamp_at, Vector3(0.008, 0.09, 0.008), Vector3(0, 0, 0.05), DARK)
			cage.rotation_degrees = Vector3(0, 0, k * 45.0)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.85, 0.65)
		light.light_energy = 0.3
		light.omni_range = 1.1
		light.position = Vector3(0, 0, 0.12)
		lamp_at.add_child(light)
	# Placas atornilladas que cubren la pared, en dos bandas, y cajas de empalme sobre los caños (donde no hay controles).
	var busy: Array[Vector2] = [Vector2(58, -14), Vector2(-58, -4), Vector2(0, 50), Vector2(-22, 58), Vector2(40, 35),
		Vector2(-40, 35), Vector2(105, -28), Vector2(-105, -28), Vector2(150, 15), Vector2(80, 18), Vector2(-80, 22)]
	for band: float in [-26.0, 14.0]:
		for k in 14:
			var yaw := -165.0 + k * 25.0 + (12.0 if band > 0.0 else 0.0)
			if absf(yaw) < 44.0 and band > -40.0:
				continue
			var near := false
			for spot in busy:
				if absf(spot.x - yaw) < 22.0 and absf(spot.y - band) < 22.0:
					near = true
			if near:
				continue
			var plate := _wall(yaw, band, 0.02)
			Clay.box(plate, Vector3(0.2, 0.16, 0.015), Vector3.ZERO, Color(0.3, 0.31, 0.32))
			for sx: float in [-1.0, 1.0]:
				for sy: float in [-1.0, 1.0]:
					Clay.cylinder(plate, 0.007, 0.01, Vector3(sx * 0.085, sy * 0.065, 0.01), LIGHT, Vector3(90, 0, 0))
	for yaw: float in [-120.0, 95.0, 170.0]:
		var junction := _wall(yaw, -5.0, 0.07)
		Clay.box(junction, Vector3(0.1, 0.12, 0.06), Vector3.ZERO, DARK)
		Clay.box(junction, Vector3(0.08, 0.02, 0.062), Vector3(0, 0.04, 0.001), Clay.YELLOW)
	# Rejillas y placas de datos donde no hay controles.
	for spot: Vector2 in [Vector2(105, -28), Vector2(-105, -28), Vector2(150, 15)]:
		var grille := _wall(spot.x, spot.y, 0.03)
		Clay.box(grille, Vector3(0.22, 0.14, 0.02), Vector3.ZERO, DARK)
		for k in 6:
			Clay.box(grille, Vector3(0.19, 0.008, 0.01), Vector3(0, -0.05 + k * 0.02, 0.012), INK)
	for spot: Vector3 in [Vector3(80, 18, 0), Vector3(-80, 22, 1)]:
		var plate := _wall(spot.x, spot.y, 0.03)
		Clay.box(plate, Vector3(0.16, 0.07, 0.01), Vector3.ZERO, CREAM)
		_label(plate, "TALLERES N. A." if spot.z < 0.5 else "NO PISAR", Vector3(0, 0, 0.006), 0.016, INK, false)
	# La silla: el pie fijo con su aro, y arriba lo que gira con la mirada (la silla y la empuñadura).
	Clay.cylinder(self, 0.09, 0.32, Vector3(0, 0.2, 0.12), DARK)
	_ring(Vector3(0, 0.36, 0.12), Vector3.UP, 0.26, 0.03, STEEL)
	for k in 12:
		var angle := TAU * k / 12.0
		Clay.sphere(self, 0.012, Vector3(cos(angle) * 0.26, 0.39, 0.12 + sin(angle) * 0.26), LIGHT)
	_seat = Node3D.new()
	_seat.position = Vector3(0, 0, 0.12)
	add_child(_seat)
	Clay.cylinder(_seat, 0.2, 0.06, Vector3(0, 0.4, 0), DARK)
	Clay.box(_seat, Vector3(0.5, 0.1, 0.5), Vector3(0, 0.48, 0), STEEL)
	Clay.box(_seat, Vector3(0.46, 0.04, 0.44), Vector3(0, 0.55, -0.02), Color(0.2, 0.18, 0.17))
	Clay.box(_seat, Vector3(0.5, 0.74, 0.1), Vector3(0, 0.9, 0.3), STEEL)
	Clay.box(_seat, Vector3(0.42, 0.6, 0.04), Vector3(0, 0.92, 0.24), Color(0.2, 0.18, 0.17))
	Clay.box(_seat, Vector3(0.3, 0.16, 0.12), Vector3(0, 1.36, 0.3), STEEL)
	for side: float in [-1.0, 1.0]:
		Clay.box(_seat, Vector3(0.08, 0.06, 0.46), Vector3(side * 0.29, 0.72, -0.02), DARK)
		Clay.box(_seat, Vector3(0.06, 0.2, 0.06), Vector3(side * 0.29, 0.6, 0.15), STEEL)
		for k in 3:
			Clay.box(_seat, Vector3(0.02, 0.025, 0.4), Vector3(side * 0.24 + side * k * -0.0, 0.88 + k * 0.12, 0.25), INK)


## Un aro (toro) con centro, eje y radio.
func _ring(at: Vector3, axis: Vector3, radius: float, thick: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thick
	mesh.outer_radius = radius + thick
	mesh.rings = 64
	mesh.ring_segments = 10
	var ring := MeshInstance3D.new()
	ring.mesh = mesh
	ring.material_override = Clay.material(color)
	add_child(ring)
	var up := axis.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	ring.transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(), at)
	return ring


## Un punto de la pared de adentro, a `inset` de ella: `yaw` grados a la izquierda del frente, `pitch` para arriba.
func _on_wall(yaw: float, pitch: float, inset: float) -> Vector3:
	var y := deg_to_rad(yaw)
	var p := deg_to_rad(pitch)
	var way := Vector3(-sin(y) * cos(p), sin(p), -cos(y) * cos(p))
	return SPHERE_CENTER + way * (SPHERE_RADIUS - inset)


## Un lugar en la pared para montar algo: su +Z mira al centro de la esfera.
func _wall(yaw: float, pitch: float, inset: float) -> Node3D:
	var spot := Node3D.new()
	add_child(spot)
	spot.position = _on_wall(yaw, pitch, inset)
	spot.look_at(SPHERE_CENTER, Vector3.UP if absf(pitch) < 80.0 else Vector3.FORWARD)
	spot.rotate_object_local(Vector3.UP, PI)
	return spot


## Un tubo entre dos puntos.
func _bar(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 10
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = Clay.material(color)
	parent.add_child(piece)
	var up := (to - from).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	piece.transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(), (from + to) * 0.5)
	return piece


func _glow(color: Color, energy := 1.6) -> StandardMaterial3D:
	var made := StandardMaterial3D.new()
	made.albedo_color = color
	made.emission_enabled = true
	made.emission = color
	made.emission_energy_multiplier = energy
	return made


# ── EL CAÑÓN (brazo izquierdo de la meca, afuera, a la izquierda de la cabina) ─────────────────────────────────────
func _cannon() -> void:
	_shoulder = Node3D.new()
	_shoulder.position = Vector3(-1.9, 0.5, -0.5)
	add_child(_shoulder)
	Clay.sphere(_shoulder, 0.55, Vector3.ZERO, STEEL)
	var arm := Node3D.new()
	_shoulder.add_child(arm)
	Clay.cylinder(arm, 0.3, 2.4, Vector3(0, 0, -1.3), Color(0.24, 0.25, 0.26), Vector3(90, 0, 0))
	for k in 4:
		Clay.cylinder(arm, 0.34, 0.12, Vector3(0, 0, -0.5 - k * 0.5), DARK, Vector3(90, 0, 0))
	Clay.cylinder(arm, 0.2, 0.4, Vector3(0, 0, -2.65), INK, Vector3(90, 0, 0))
	_muzzle = Node3D.new()
	_muzzle.position = Vector3(0, 0, -2.9)
	arm.add_child(_muzzle)
	_marker = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 0.8
	_marker.mesh = torus
	_marker.material_override = _glow(AMBER, 2.5)
	add_child(_marker)
	_beam = MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.18
	beam_mesh.bottom_radius = 0.18
	beam_mesh.height = 1.0
	_beam.mesh = beam_mesh
	_beam.material_override = _glow(AMBER, 3.5)
	_beam.visible = false
	add_child(_beam)


# ── EL PUESTO: la empuñadura en el apoyabrazos (gira con la silla); lo demás, montado en la pared de la esfera ──
## Una placa de montaje: un respaldo oscuro un poco más grande, con sus tornillos, donde se apoya lo que va encima.
func _mount(spot: Node3D, size: Vector2) -> void:
	Clay.box(spot, Vector3(size.x + 0.04, size.y + 0.04, 0.025), Vector3(0, 0, -0.03), DARK)
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			Clay.cylinder(spot, 0.008, 0.01, Vector3(sx * (size.x * 0.5 + 0.005), sy * (size.y * 0.5 + 0.005), -0.015), LIGHT,
				Vector3(90, 0, 0))


func _station() -> void:
	# 1. La empuñadura del cañón, en el apoyabrazos izquierdo: se agarra y lo que mirás es la mira.
	var grip_base := Node3D.new()
	_seat.add_child(grip_base)
	grip_base.position = Vector3(-0.29, 0.76, -0.22)
	Clay.cylinder(grip_base, 0.05, 0.03, Vector3.ZERO, DARK)
	var grip := Node3D.new()
	grip_base.add_child(grip)
	var handle := Clay.box(grip, Vector3(0.045, 0.13, 0.055), Vector3(0, 0.07, 0), INK)
	handle.rotation_degrees = Vector3(-15, 0, 0)
	for k in 3:
		Clay.box(grip, Vector3(0.05, 0.008, 0.06), Vector3(0, 0.03 + k * 0.035, 0.005), DARK)
	Clay.box(grip, Vector3(0.055, 0.03, 0.07), Vector3(0, 0.15, -0.015), RED)
	_controls.append({"name": "empuñadura", "kind": "grip", "node": grip, "radius": 0.09})
	# 2. Los modos, en la pared a la izquierda: ráfaga se traba; barrido y súper se aprietan y se cargan.
	var modes := _wall(58.0, -14.0, 0.06)
	_mount(modes, Vector2(0.38, 0.3))
	Clay.box(modes, Vector3(0.38, 0.3, 0.05), Vector3(0, 0, -0.01), STEEL)
	Clay.box(modes, Vector3(0.38, 0.05, 0.052), Vector3(0, 0.125, -0.01), INK)
	_label(modes, "CAÑÓN", Vector3(0, 0.125, 0.018), 0.026, CREAM, false)
	var names := ["RÁFAGA", "BARRIDO", "SÚPER"]
	for i in names.size():
		var x := -0.12 + i * 0.12
		var key := Clay.box(modes, Vector3(0.08, 0.07, 0.04), Vector3(x, 0.0, 0.02), CREAM)
		_lamps[names[i]] = Clay.sphere(modes, 0.016, Vector3(x, 0.07, 0.02), Color(0.3, 0.22, 0.14))
		_label(modes, names[i], Vector3(x, -0.06, 0.016), 0.016, INK, false)
		_controls.append({"name": names[i], "kind": "button", "node": key, "radius": 0.06})
		_bars[names[i]] = _light_row(modes, Vector3(x, -0.1, 0.016), 5, 0.018)
	# 3. La energía, arriba de la ventana: una pantallita verde.
	var screen := _wall(0.0, 50.0, 0.06)
	_mount(screen, Vector2(0.36, 0.16))
	Clay.box(screen, Vector3(0.36, 0.16, 0.05), Vector3(0, 0, -0.01), DARK)
	Clay.box(screen, Vector3(0.32, 0.12, 0.01), Vector3(0, 0, 0.016), Color(0.03, 0.06, 0.04))
	_label(screen, "ENERGÍA", Vector3(-0.08, 0.035, 0.024), 0.018, GREEN, false)
	_bars["energía"] = _light_row(screen, Vector3(0, -0.02, 0.024), 14, 0.018)
	# 4. El estado de la meca, en la pared a la derecha.
	var status := _wall(-58.0, -4.0, 0.06)
	_mount(status, Vector2(0.42, 0.38))
	Clay.box(status, Vector3(0.42, 0.38, 0.06), Vector3(0, 0, -0.015), DARK)
	var drawing := _StatusDrawing.new()
	var view := SubViewport.new()
	view.size = Vector2i(360, 330)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	drawing.size = Vector2(view.size)
	view.add_child(drawing)
	status.add_child(view)
	var sheet := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.36, 0.33)
	sheet.mesh = quad
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_texture = view.get_texture()
	sheet.material_override = look
	sheet.position = Vector3(0, 0, 0.017)
	status.add_child(sheet)
	# 5. Eyectar: arriba adelante, una manija rayada que cuelga de un soporte, a mano y a la vista mirando arriba.
	var eject := _wall(-22.0, 58.0, 0.05)
	_mount(eject, Vector2(0.3, 0.1))
	for dx: float in [-0.1, 0.1]:
		Clay.box(eject, Vector3(0.01, 0.01, 0.16), Vector3(dx, 0, 0.08), INK)
	for k in 6:
		Clay.box(eject, Vector3(0.045, 0.045, 0.045), Vector3(-0.125 + k * 0.05, 0, 0.17), Clay.YELLOW if k % 2 else INK)
	_label(eject, "EYECTAR", Vector3(0, 0.07, 0.0), 0.022, CREAM, true)


func _label(parent: Node3D, text: String, at: Vector3, height: float, color: Color, plate: bool) -> void:
	var label := StrokeLabel.make(text, height, color)
	label.position = at + Vector3(0, 0, 0.004)
	parent.add_child(label)
	if plate:
		Clay.box(parent, Vector3(text.length() * height * 0.78 + height, height * 1.8, 0.01), at, INK)


## Una fila de luces apagadas (se prenden en `_process`).
func _light_row(parent: Node3D, at: Vector3, count: int, cell: float) -> Array[MeshInstance3D]:
	var row: Array[MeshInstance3D] = []
	var step := cell * 1.25
	Clay.box(parent, Vector3(count * step + 0.01, cell + 0.01, 0.006), at + Vector3(0, 0, -0.002), INK)
	for k in count:
		row.append(Clay.box(parent, Vector3(cell, cell * 0.7, 0.004), at + Vector3(-count * step * 0.5 + step * (k + 0.5), 0, 0.002),
			Color(0.1, 0.2, 0.1)))
	return row


# ── EL HUD: un punto al medio y una línea de ayuda ───────────────────────────────────────────────────────────────
func _hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_dot = ColorRect.new()
	_dot.size = Vector2(6, 6)
	_dot.position = Vector2(637, 357)
	_dot.color = Color(1, 1, 1, 0.8)
	layer.add_child(_dot)
	_hint = Label.new()
	_hint.position = Vector2(20, 680)
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 6)
	layer.add_child(_hint)


# ── LA ENTRADA ───────────────────────────────────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			get_tree().quit()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event.relative * LOOK_SPEED)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		if event.pressed:
			_press()
		else:
			_holding = {}


func _look(delta: Vector2) -> void:
	_yaw = clampf(_yaw - delta.x, -YAW_LIMIT, YAW_LIMIT)
	_pitch = clampf(_pitch - delta.y, PITCH_DOWN, PITCH_UP)


func _press() -> void:
	if _hovered.is_empty():
		return
	match _hovered.kind:
		"grip":
			_holding = _hovered
		"button":
			_trigger(_hovered.name)
	var node: Node3D = _hovered.node
	var tween := create_tween()
	tween.tween_property(node, "position:z", node.position.z - 0.015, 0.05)
	tween.tween_property(node, "position:z", node.position.z, 0.1)


## LOS ATAQUES: se aprietan, se cargan un tiempo fijo y salen solos.
func _trigger(mode: String) -> void:
	match mode:
		"RÁFAGA":
			_burst = not _burst
		"BARRIDO":
			if _sweep_charge < 0.0 and _sweep_left <= 0.0:
				_sweep_charge = 0.0
		"SÚPER":
			if _super_charge < 0.0:
				_super_charge = 0.0


# ── CADA CUADRO ──────────────────────────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _outside:
		_eye.rotation_degrees = Vector3(_pitch, _yaw, 0.0)
	_seat.rotation_degrees.y = _yaw
	_hover()
	_spring(delta)
	_shoot(delta)
	_lights()
	_target_flash = maxf(0.0, _target_flash - delta * 3.0)
	_target.position = _target_home + Vector3(sin(Time.get_ticks_msec() * 0.06) * _target_flash * 0.6, 0, 0)
	if _demo:
		return
	var holding := "agarrando la empuñadura: lo que mirás es la mira" if not _holding.is_empty() else "mantené el clic en la empuñadura para apuntar"
	_hint.text = holding + ("   ·   " + str(_hovered.name) if not _hovered.is_empty() else "")


## Lo que está bajo el punto del medio (el más cercano al rayo, dentro de su radio), resaltado.
func _hover() -> void:
	var origin := _eye.global_position
	var forward := -_eye.global_basis.z
	var best: Dictionary = {}
	var best_distance := INF
	for control in _controls:
		var at: Vector3 = (control.node as Node3D).global_position
		var along := (at - origin).dot(forward)
		if along <= 0.0:
			continue
		var miss := (origin + forward * along).distance_to(at)
		if miss < control.radius and along < best_distance:
			best = control
			best_distance = along
	if not _holding.is_empty():
		best = _holding
	if best != _hovered:
		_tint(_hovered, false)
		_hovered = best
		_tint(_hovered, true)


func _tint(control: Dictionary, on: bool) -> void:
	if control.is_empty():
		return
	for piece in (control.node as Node3D).find_children("*", "MeshInstance3D", true, false) + [control.node]:
		var mesh := piece as MeshInstance3D
		if mesh == null:
			continue
		if on:
			var lit := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			lit.emission_enabled = true
			lit.emission = HOVER
			lit.emission_energy_multiplier = 0.18
			mesh.set_meta("plain", mesh.material_override)
			mesh.material_override = lit
		elif mesh.has_meta("plain"):
			mesh.material_override = mesh.get_meta("plain")


## EL RESORTE DEL BRAZO: mientras se agarra la empuñadura, el cañón va hacia donde mira la cámara; llega tarde y se pasa.
func _spring(delta: float) -> void:
	var wanted := -_eye.global_basis.z if not _holding.is_empty() else _aim
	_aim_speed += (wanted - _aim) * 38.0 * delta
	_aim_speed *= exp(-4.5 * delta)
	_aim = (_aim + _aim_speed * delta).normalized()
	var target := _shoulder.global_position + _aim
	if not _aim.is_equal_approx(Vector3.UP):
		_shoulder.look_at(target, Vector3.UP)
	# La mira, donde el cañón pega (el piso o la meca enemiga): un aro naranja en el mundo.
	var tip := _muzzle.global_position
	var reach := 60.0
	if _aim.y < -0.01:
		reach = minf(reach, (tip.y + 6.0) / -_aim.y)
	_marker.global_position = tip + _aim * reach
	_marker.look_at(tip, Vector3.UP if absf(_aim.y) < 0.95 else Vector3.FORWARD)
	_marker.rotate_object_local(Vector3.RIGHT, PI * 0.5)


func _shoot(delta: float) -> void:
	_energy = minf(1.0, _energy + delta * 0.08)
	var tip := _muzzle.global_position
	# Ráfaga: mientras está prendida, tiros chicos seguidos.
	if _burst:
		_burst_clock -= delta
		if _burst_clock <= 0.0 and _energy > 0.02:
			_burst_clock = BURST_EVERY
			_energy -= 0.012
			_fire(tip, _aim.rotated(Vector3.UP, randf_range(-0.03, 0.03)), 0.2, 160.0, 0.3)
	# Barrido: se carga y después un rayo que dura un rato y empuja.
	if _sweep_charge >= 0.0:
		_sweep_charge += delta
		if _sweep_charge >= SWEEP_CHARGE:
			_sweep_charge = -1.0
			_sweep_left = SWEEP_TIME
	_beam.visible = _sweep_left > 0.0
	if _sweep_left > 0.0:
		_sweep_left -= delta
		_energy = maxf(0.0, _energy - delta * 0.12)
		var end := _marker.global_position
		var along := (end - tip).normalized()
		var side := along.cross(Vector3.UP if absf(along.y) < 0.95 else Vector3.RIGHT).normalized()
		var basis := Basis(side, along, side.cross(along)).orthonormalized()
		_beam.global_transform = Transform3D(basis.scaled_local(Vector3(1, tip.distance_to(end), 1)), (tip + end) * 0.5)
		if _hits_target(end):
			_target_flash = 1.0
	# Súper: se carga más y sale uno solo, grande.
	if _super_charge >= 0.0:
		_super_charge += delta
		if _super_charge >= SUPER_CHARGE:
			_super_charge = -1.0
			_energy = maxf(0.0, _energy - 0.35)
			_fire(tip, _aim, 1.1, 90.0, 3.0)
			_aim_speed += Vector3(0, 1.2, 0)
	for bolt in _bolts.duplicate():
		var ball: MeshInstance3D = bolt.node
		ball.global_position += bolt.velocity * delta
		bolt.life -= delta
		if _hits_target(ball.global_position):
			_target_flash = minf(1.0, _target_flash + bolt.punch)
			bolt.life = 0.0
		if bolt.life <= 0.0:
			ball.queue_free()
			_bolts.erase(bolt)


func _fire(from: Vector3, way: Vector3, radius: float, speed: float, punch: float) -> void:
	var ball := Clay.sphere(self, radius, from, AMBER)
	ball.material_override = _glow(AMBER, 3.0)
	_bolts.append({"node": ball, "velocity": way.normalized() * speed, "life": 1.2, "punch": punch})
	_aim_speed += Vector3(0, 0.08, 0) + way.cross(Vector3.UP) * randf_range(-0.04, 0.04)


func _hits_target(point: Vector3) -> bool:
	var local := point - _target.global_position
	return absf(local.x) < 6.5 and local.y > 0.0 and local.y < 17.0 and absf(local.z) < 3.0


## Las lamparitas y las barras: la energía, la ráfaga prendida, la carga de barrido y súper.
func _lights() -> void:
	_row(_bars["energía"], _energy, GREEN)
	_lamp("RÁFAGA", _burst)
	_row(_bars["RÁFAGA"], 1.0 if _burst else 0.0, AMBER)
	var sweep := _sweep_charge / SWEEP_CHARGE if _sweep_charge >= 0.0 else (_sweep_left / SWEEP_TIME)
	_lamp("BARRIDO", _sweep_charge >= 0.0 or _sweep_left > 0.0)
	_row(_bars["BARRIDO"], sweep, AMBER)
	_lamp("SÚPER", _super_charge >= 0.0)
	_row(_bars["SÚPER"], _super_charge / SUPER_CHARGE if _super_charge >= 0.0 else 0.0, AMBER)


func _row(row: Array[MeshInstance3D], fraction: float, color: Color) -> void:
	for k in row.size():
		var on := float(k) < fraction * row.size()
		row[k].material_override = _glow(color, 2.0) if on else Clay.material(Color(color.r * 0.15, color.g * 0.15, color.b * 0.15))


func _lamp(name_key: String, on: bool) -> void:
	var lamp: MeshInstance3D = _lamps[name_key]
	var blink := on and (Time.get_ticks_msec() / 150) % 2 == 0
	lamp.material_override = _glow(AMBER, 2.5) if (on and (name_key == "RÁFAGA" or blink)) else Clay.material(Color(0.3, 0.22, 0.14))


# ── LA DEMO: se juega sola y captura ─────────────────────────────────────────────────────────────────────────────
func _play_demo() -> void:
	await _wait(0.5)
	_set_look(0.0, -8.0)
	await _capture("1. Sentado, mirando al frente", "1")
	_set_look(38.0, -22.0)
	await _capture("2. Mirando los modos, a la izquierda", "2")
	for control in _controls:
		if control.kind == "grip":
			_holding = control
	await _wait(0.2)
	_trigger("RÁFAGA")
	_set_look(6.0, 2.0)
	await _wait(0.8)
	await _capture("3. Agarrando la empuñadura, con la ráfaga prendida", "3")
	_trigger("RÁFAGA")
	_trigger("SÚPER")
	await _wait(SUPER_CHARGE * 0.6)
	_set_look(-4.0, 4.0)
	await _capture("4. El súper cargando", "4")
	await _wait(SUPER_CHARGE * 0.45)
	await _capture("5. El súper sale solo", "5")
	_trigger("BARRIDO")
	await _wait(SWEEP_CHARGE + 0.4)
	_set_look(14.0, 1.0)
	await _wait(0.4)
	await _capture("6. El barrido", "6")
	_set_look(-38.0, -10.0)
	await _wait(0.6)
	await _capture("7. El estado de la meca, a la derecha", "8")
	_set_look(-70.0, -20.0)
	await _wait(0.3)
	await _capture("7. Mirando a la derecha: el tope", "7")
	# Desde afuera, con alguien sentado.
	_set_look(0.0, -8.0)
	_sit_dummy()
	_outside = true
	_view_from(Vector3(1.2, 1.6, -2.6), Vector3(0, 1.0, 0))
	await _capture("9. Desde afuera, por la ventana", "9")
	_view_from(Vector3(2.6, 1.4, 0.6), Vector3(0, 0.95, 0))
	await _capture("10. Desde afuera, de costado", "10")
	_shell.set_shader_parameter("cut_z", 0.05)
	for piece in get_children():
		var part := piece as Node3D
		if part == null or part == _seat or (part is MeshInstance3D and (part as MeshInstance3D).material_override == _shell):
			continue
		if part.global_position.z > 0.05 and part.global_position.distance_to(SPHERE_CENTER) < 1.2:
			part.visible = false
	_view_from(Vector3(1.7, 1.7, 1.9), Vector3(0, 0.9, -0.1))
	await _capture("11. Cortada al medio: la silla en su aro, mirando al frente", "11")
	_set_look(45.0, -8.0)
	await _wait(0.1)
	await _capture("12. Cortada: la silla girada a la izquierda, hacia los modos", "12")
	get_tree().quit()


func _view_from(from: Vector3, to: Vector3) -> void:
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)


## Un maniquí de arcilla sentado en la silla, con la mano izquierda en la empuñadura.
func _sit_dummy() -> void:
	var skin := Color(0.78, 0.62, 0.5)
	var suit := Color(0.32, 0.36, 0.42)
	var body := _seat
	Clay.box(body, Vector3(0.36, 0.5, 0.24), Vector3(0, 0.85, 0.12), suit)
	Clay.sphere(body, 0.12, Vector3(0, 1.2, 0.06), skin)
	Clay.box(body, Vector3(0.26, 0.06, 0.3), Vector3(0, 1.17, 0.13), Color(0.15, 0.12, 0.1))
	for side: float in [-1.0, 1.0]:
		Clay.box(body, Vector3(0.14, 0.14, 0.42), Vector3(side * 0.11, 0.6, -0.12), suit)
		Clay.box(body, Vector3(0.12, 0.42, 0.13), Vector3(side * 0.11, 0.32, -0.3), suit)
		Clay.box(body, Vector3(0.12, 0.06, 0.2), Vector3(side * 0.11, 0.1, -0.35), INK)
	for side: float in [-1.0, 1.0]:
		_seat_bar(Vector3(side * 0.2, 1.0, 0.1), Vector3(side * 0.28, 0.82, -0.05), suit)
		_seat_bar(Vector3(side * 0.28, 0.82, -0.05), Vector3(side * 0.29, 0.86, -0.24), suit)
		Clay.sphere(body, 0.05, Vector3(side * 0.29, 0.88, -0.26), skin)


func _seat_bar(from: Vector3, to: Vector3, color: Color) -> void:
	var piece := _bar(self, from, to, 0.045, color)
	remove_child(piece)
	_seat.add_child(piece)


func _set_look(yaw: float, pitch: float) -> void:
	_yaw = yaw
	_pitch = pitch


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _capture(title: String, file_name: String) -> void:
	_hint.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	_hint.text = title
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)


## LA PANTALLA DE ESTADO: la meca de frente con formas llenas, a lo dibujo de mechas (la cresta en V, el visor, las
## hombreras, el núcleo en el pecho, la falda de placas): cada parte del color de cómo está (verde sana, ámbar dañada
## y titilando, rojo rota), con sus paneles más oscuros adentro. A la izquierda de la pantalla, el brazo derecho con la
## espada; a la derecha, el izquierdo con el cañón (se la mira de frente).
class _StatusDrawing extends Control:
	const BACK := Color(0.02, 0.05, 0.03)
	const GRID := Color(0.06, 0.14, 0.08)
	const OK := Color(0.22, 0.78, 0.36)
	const HURT := Color(1.0, 0.62, 0.15)
	const BROKEN := Color(0.9, 0.2, 0.15)
	const TEXT := Color(0.45, 1.0, 0.55)
	const FIN := Color(0.95, 0.85, 0.4)

	## Cómo está cada parte: 0 sana, 1 dañada, 2 rota.
	var states := {"cabeza": 0, "pecho": 0, "hombro derecho": 0, "hombro izquierdo": 0, "espada": 0, "cañón": 0,
		"cintura": 0, "pierna derecha": 0, "pierna izquierda": 1}
	var _blink := 0.0

	func _process(delta: float) -> void:
		_blink += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), BACK)
		for x in range(0, int(size.x), 20):
			draw_line(Vector2(x, 0), Vector2(x, size.y), GRID, 1.0)
		for y in range(0, int(size.y), 20):
			draw_line(Vector2(0, y), Vector2(size.x, y), GRID, 1.0)
		# Las esquinas del visor.
		for corner: Vector2 in [Vector2(8, 8), Vector2(size.x - 8, 8), Vector2(8, size.y - 8), Vector2(size.x - 8, size.y - 8)]:
			var sx := 1.0 if corner.x < size.x * 0.5 else -1.0
			var sy := 1.0 if corner.y < size.y * 0.5 else -1.0
			draw_line(corner, corner + Vector2(sx * 22, 0), TEXT, 3.0)
			draw_line(corner, corner + Vector2(0, sy * 22), TEXT, 3.0)
		_write("ESTADO", Vector2(22, 34), 16, TEXT)
		var c := 180.0
		# Las piernas.
		for side: float in [-1.0, 1.0]:
			var leg := "pierna derecha" if side < 0.0 else "pierna izquierda"
			_part(leg, [Vector2(c + side * 14, 178), Vector2(c + side * 44, 178), Vector2(c + side * 46, 226), Vector2(c + side * 16, 226)])
			_part(leg, [Vector2(c + side * 12, 230), Vector2(c + side * 48, 230), Vector2(c + side * 54, 290), Vector2(c + side * 50, 300),
				Vector2(c + side * 18, 300), Vector2(c + side * 14, 290)])
			_part(leg, [Vector2(c + side * 22, 214), Vector2(c + side * 40, 214), Vector2(c + side * 44, 232), Vector2(c + side * 31, 240),
				Vector2(c + side * 18, 232)], 0.55)
			_part(leg, [Vector2(c + side * 10, 302), Vector2(c + side * 58, 302), Vector2(c + side * 64, 318), Vector2(c + side * 6, 318)])
		# La cintura y la falda de placas.
		_part("cintura", [Vector2(c - 30, 150), Vector2(c + 30, 150), Vector2(c + 26, 166), Vector2(c - 26, 166)])
		for side: float in [-1.0, 1.0]:
			_part("cintura", [Vector2(c + side * 8, 168), Vector2(c + side * 46, 166), Vector2(c + side * 50, 196), Vector2(c + side * 14, 192)])
		_part("cintura", [Vector2(c - 8, 168), Vector2(c + 8, 168), Vector2(c + 6, 192), Vector2(c - 6, 192)])
		# El pecho, con su collar y el núcleo.
		_part("pecho", [Vector2(c - 44, 74), Vector2(c + 44, 74), Vector2(c + 54, 110), Vector2(c + 34, 146), Vector2(c - 34, 146),
			Vector2(c - 54, 110)])
		for side: float in [-1.0, 1.0]:
			_part("pecho", [Vector2(c + side * 8, 112), Vector2(c + side * 34, 106), Vector2(c + side * 30, 138), Vector2(c + side * 10, 140)], 0.7)
		draw_circle(Vector2(c, 98), 11, Color(0.04, 0.1, 0.06))
		draw_circle(Vector2(c, 98), 7, FIN)
		# La cabeza: el visor y la cresta en V.
		_part("cabeza", [Vector2(c - 16, 40), Vector2(c + 16, 40), Vector2(c + 22, 54), Vector2(c + 16, 72), Vector2(c - 16, 72), Vector2(c - 22, 54)])
		draw_rect(Rect2(c - 15, 52, 30, 7), Color(0.02, 0.05, 0.03))
		draw_rect(Rect2(c - 12, 54, 24, 3), FIN)
		for side: float in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(c + side * 2, 46), Vector2(c + side * 40, 18), Vector2(c + side * 36, 26),
				Vector2(c + side * 6, 50)]), FIN)
		draw_colored_polygon(PackedVector2Array([Vector2(c - 5, 44), Vector2(c + 5, 44), Vector2(c, 54)]), BROKEN)
		# Las hombreras y los brazos: a la izquierda de la pantalla la espada, a la derecha el cañón.
		for side: float in [-1.0, 1.0]:
			var shoulder := "hombro derecho" if side < 0.0 else "hombro izquierdo"
			_part(shoulder, [Vector2(c + side * 48, 66), Vector2(c + side * 86, 62), Vector2(c + side * 98, 82), Vector2(c + side * 92, 108),
				Vector2(c + side * 56, 110), Vector2(c + side * 46, 90)])
			_part(shoulder, [Vector2(c + side * 62, 112), Vector2(c + side * 84, 112), Vector2(c + side * 82, 146), Vector2(c + side * 64, 146)])
		_part("espada", [Vector2(c - 90, 148), Vector2(c - 58, 148), Vector2(c - 56, 190), Vector2(c - 92, 190)])
		_part("espada", [Vector2(c - 94, 192), Vector2(c - 54, 192), Vector2(c - 56, 214), Vector2(c - 92, 214)])
		draw_colored_polygon(PackedVector2Array([Vector2(c - 100, 204), Vector2(c - 46, 204), Vector2(c - 46, 210), Vector2(c - 100, 210)]),
			_color("espada").darkened(0.3))
		_part("espada", [Vector2(c - 77, 214), Vector2(c - 69, 214), Vector2(c - 66, 300), Vector2(c - 73, 316), Vector2(c - 80, 300)], 1.0)
		_part("cañón", [Vector2(c + 58, 148), Vector2(c + 92, 148), Vector2(c + 96, 176), Vector2(c + 88, 184), Vector2(c + 62, 184),
			Vector2(c + 54, 176)])
		_part("cañón", [Vector2(c + 64, 184), Vector2(c + 86, 184), Vector2(c + 84, 262), Vector2(c + 66, 262)])
		for ring in 3:
			draw_rect(Rect2(c + 61, 196 + ring * 22, 28, 6), _color("cañón").darkened(0.45))
		draw_rect(Rect2(c + 68, 262, 14, 12), Color(0.02, 0.05, 0.03))
		# Los rótulos, con su línea.
		_callout("ESPADA", Vector2(c - 80, 250), Vector2(24, 262), TEXT)
		_callout("CAÑÓN", Vector2(c + 86, 230), Vector2(size.x - 92, 246), TEXT)
		_callout("PIERNA", Vector2(c + 50, 266), Vector2(size.x - 92, 300), _color("pierna izquierda"))

	## El color de una parte según cómo está; la dañada titila.
	func _color(part: String) -> Color:
		match int(states.get(part, 0)):
			1:
				return HURT if fmod(_blink, 0.8) < 0.5 else HURT.darkened(0.55)
			2:
				return BROKEN
		return OK

	## Una pieza llena, con un panel más oscuro adentro (la misma forma, más chica).
	func _part(part: String, points: Array, inset := 0.68) -> void:
		var shape := PackedVector2Array(points)
		var color := _color(part)
		draw_colored_polygon(shape, color.darkened(0.55))
		var middle := Vector2.ZERO
		for point in shape:
			middle += point
		middle /= shape.size()
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for point in shape:
			outer.append(middle + (point - middle) * 0.9)
			inner.append(middle + (point - middle) * inset)
		draw_colored_polygon(outer, color)
		if inset < 1.0:
			draw_colored_polygon(inner, color.darkened(0.28))

	func _callout(text: String, from: Vector2, to: Vector2, color: Color) -> void:
		draw_line(from, Vector2(from.x + (to.x - from.x) * 0.6, to.y), color, 2.0)
		draw_line(Vector2(from.x + (to.x - from.x) * 0.6, to.y), to + Vector2(0 if to.x > from.x else 70, 0), color, 2.0)
		_write(text, to + Vector2(2, -12), 11, color)

	func _write(text: String, at: Vector2, height: float, color: Color) -> void:
		var lines := StrokeFont.segments(text, height, StrokeFont.Align.LEFT)
		for k in range(0, lines.size(), 2):
			draw_line(at + Vector2(lines[k].x, -lines[k].y - height * 0.5), at + Vector2(lines[k + 1].x, -lines[k + 1].y - height * 0.5),
				color, 2.0)
