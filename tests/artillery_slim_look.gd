extends Node

## LA ARMA DEL ARTILLERO, BAJA Y FINA (18/11/2026; el usuario, de las ideas de tests/artillery_ideas_look: «la que más
## me gusta es la que ya está… caños… el problema… es que ofuscan la visión… lo haría mucho más bajo… y menos bulky…
## el personaje… tiene que poder mirar hacia donde está disparando y… agarrar las armas con sus brazos en… L, con los
## codos en su cadera… y viendo derecho… una ametralladora mucho más slim»; «la idea del tambor no es mala… que se
## pueda girar»; «si es ametralladora, tiene que tener sistema de calor y munición… si tiene un cañón que tenga una
## trayectoria»): la meca jaula, una por variante, con el arma de hoy escondida y la de la variante en la torre, A LA
## ALTURA DE LAS MANOS de un maniquí sentado con los brazos en L. De cada una, dos fotos: de atrás y desde sus ojos.
##   tools/godot_ventana.sh res://tests/artillery_slim_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const GAP := 14.0
const IDEAS := [
	"1. hoy",
	"2. ametralladora fina y baja, dos caños, manijas a los costados",
	"3. la misma con un tambor: caño fino (balas) o caño grueso corto (cañón); gira media vuelta",
	"4. lado a lado: la ametralladora fina y el cañón corto, juntos",
	"5. una arriba de la otra: la ametralladora fina y el cañón corto debajo",
]
## El maniquí, en el espacio de su silla (m): las manos en L, con los codos en la cadera.
const HIP := 0.5
const SHOULDER := 1.0
const ELBOW := Vector3(0.22, 0.62, 0.0)
const HAND := Vector3(0.17, 0.64, -0.33)
const GUNMETAL := Color(0.24, 0.25, 0.27)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _shots: Array = []


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
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
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
	var mechs: Array[CageMech] = []
	for index in IDEAS.size():
		var mech := CageMech.new()
		mech.scripted = true
		mech.position = Vector3(index * GAP, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
		add_child(mech)
		mechs.append(mech)
	await get_tree().create_timer(2.0).timeout
	for found in get_tree().root.find_children("*", "Label3D", true, false):
		(found as Label3D).visible = false
	for index in IDEAS.size():
		_idea(index, mechs[index].cabin as CageCabin)
	await get_tree().create_timer(0.3).timeout
	for index in IDEAS.size():
		var cage := mechs[index].cabin as CageCabin
		var chair := cage.chairs[CageCabin.GUNNER] as Node3D
		var seat := chair.global_transform
		var at := seat * Vector3(0.0, 0.7, -0.4)
		await _shot(IDEAS[index], at + seat.basis * Vector3(2.0, 0.5, -0.9), at + seat.basis * Vector3(0.0, 0.0, -0.1), 45.0)
		var eye := seat * Vector3(0.0, 1.15, 0.02)
		await _shot(IDEAS[index] + " · desde sus ojos", eye, eye + seat.basis * Vector3(0.0, -0.15, -6.0), 75.0)
	_save()
	get_tree().quit()


## LA VARIANTE `index` en la cabina `cage`: el maniquí sentado y, si no es la de hoy, el arma nueva en su lugar.
func _idea(index: int, cage: CageCabin) -> void:
	var chair := cage.chairs[CageCabin.GUNNER] as Node3D
	_dummy(chair)
	if index == 0:
		return
	cage.gun.visible = false
	var turn := cage.gun.get_parent() as Node3D
	# Lo viejo del pie (la horquilla alta, la caja del plato) se queda; lo nuevo cuelga de un pie bajo, en las manos.
	for child in turn.get_children():
		if child != cage.gun and child is MeshInstance3D and (child as Node3D).position.y > 0.3:
			(child as Node3D).visible = false
	# Las manos del maniquí, en el espacio del plato: ahí van las manijas.
	var hands := turn.global_transform.affine_inverse() * chair.global_transform
	var grip := hands * Vector3(0.0, HAND.y, HAND.z)
	var gun := Node3D.new()
	gun.position = grip
	turn.add_child(gun)
	# El pie: del plato hasta debajo del arma.
	Clay.cylinder(turn, 0.035, grip.y - 0.12, Vector3(0.0, (grip.y - 0.12) * 0.5, grip.z - 0.12), GUNMETAL)
	Clay.box(turn, Vector3(0.1, 0.05, 0.1), Vector3(0.0, grip.y - 0.1, grip.z - 0.12), GUNMETAL)
	match index:
		1:
			_machine_gun(gun, Vector3.ZERO)
			_grips(gun, 0.17)
			_ammo(gun, Vector3(0.12, -0.02, -0.14))
		2:
			_machine_gun(gun, Vector3(0.0, 0.03, 0.0))
			_grips(gun, 0.17)
			# EL TAMBOR, debajo de los caños: dos caños más, uno fino y uno grueso corto, en un cilindro que gira.
			Clay.cylinder(gun, 0.07, 0.24, Vector3(0.0, -0.07, -0.3), GUNMETAL, Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(gun, 0.06, 0.4, Vector3(0.0, -0.11, -0.6), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(gun, 0.045, 0.02, Vector3(0.0, -0.11, -0.81), CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
			Clay.box(gun, Vector3(0.16, 0.02, 0.2), Vector3(0.0, -0.07, -0.3), CageCabin.YELLOW)
		3:
			_machine_gun(gun, Vector3(-0.06, 0.0, 0.0))
			_cannon(gun, Vector3(0.09, -0.01, 0.0))
			_grips(gun, 0.2)
		4:
			_machine_gun(gun, Vector3(0.0, 0.04, 0.0))
			_cannon(gun, Vector3(0.0, -0.07, 0.0))
			_grips(gun, 0.17)


## LA AMETRALLADORA FINA: un cajón angosto con dos caños finos con aletas (el calor), y la cinta de munición.
func _machine_gun(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.09, 0.09, 0.42), at + Vector3(0.0, 0.0, -0.12), GUNMETAL)
	for x: float in [-0.022, 0.022]:
		Clay.cylinder(parent, 0.017, 0.75, at + Vector3(x, 0.01, -0.68), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	# Las aletas del calor, en el primer tramo de los caños.
	for k in 4:
		Clay.cylinder(parent, 0.042, 0.015, at + Vector3(0.0, 0.01, -0.4 - k * 0.05), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(0.05, 0.03, 0.12), at + Vector3(0.0, 0.06, 0.02), CageCabin.YELLOW)


## EL CAÑÓN CORTO (con trayectoria): un caño grueso y corto con su recámara.
func _cannon(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.12, 0.12, 0.3), at + Vector3(0.0, 0.0, -0.08), GUNMETAL)
	Clay.cylinder(parent, 0.05, 0.42, at + Vector3(0.0, 0.0, -0.43), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	Clay.cylinder(parent, 0.038, 0.02, at + Vector3(0.0, 0.0, -0.645), CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(0.13, 0.025, 0.14), at + Vector3(0.0, 0.07, -0.02), CageCabin.YELLOW)


## LAS DOS MANIJAS, paradas, a los costados de atrás: donde van las manos (a `half` del medio).
func _grips(parent: Node3D, half: float) -> void:
	Clay.box(parent, Vector3(half * 2.0, 0.035, 0.05), Vector3(0.0, -0.02, 0.0), GUNMETAL)
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(parent, 0.022, 0.13, Vector3(s * half, 0.0, 0.0), CageCabin.DARK)


## LA CAJA DE MUNICIÓN, chica, al costado, con su cinta.
func _ammo(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.1, 0.12, 0.16), at, CageCabin.YELLOW.darkened(0.25))
	Clay.box(parent, Vector3(0.06, 0.015, 0.06), at + Vector3(-0.07, 0.05, 0.0), GUNMETAL)


## EL MANIQUÍ SENTADO en `chair`, con los brazos en L: los codos en la cadera, los antebrazos adelante.
func _dummy(chair: Node3D) -> void:
	var skin := Color(0.85, 0.72, 0.6)
	var cloth := Color(0.35, 0.42, 0.55)
	var body := Node3D.new()
	chair.add_child(body)
	Clay.box(body, Vector3(0.36, SHOULDER - HIP, 0.22), Vector3(0.0, (SHOULDER + HIP) * 0.5, 0.05), cloth)
	Clay.sphere(body, 0.12, Vector3(0.0, 1.18, 0.04), skin)
	for s: float in [-1.0, 1.0]:
		var shoulder := Vector3(s * 0.21, SHOULDER - 0.04, 0.05)
		var elbow := Vector3(s * ELBOW.x, ELBOW.y, ELBOW.z)
		var hand := Vector3(s * HAND.x, HAND.y, HAND.z)
		_limb(body, shoulder, elbow, 0.05, cloth)
		_limb(body, elbow, hand, 0.045, cloth)
		Clay.sphere(body, 0.05, hand, skin)
		# Los muslos, adelante, y las piernas colgando.
		var hip := Vector3(s * 0.1, HIP, 0.05)
		var knee := Vector3(s * 0.11, HIP, -0.38)
		_limb(body, hip, knee, 0.07, cloth)
		_limb(body, knee, knee + Vector3(0.0, -0.45, 0.02), 0.06, cloth)


func _limb(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> void:
	var piece := Clay.cylinder(parent, radius, from.distance_to(to), (from + to) * 0.5, color)
	var along := (to - from).normalized()
	var side := along.cross(Vector3.FORWARD if absf(along.y) > 0.5 else Vector3.UP).normalized()
	piece.basis = Basis(side, along, side.cross(along))


func _shot(name_of: String, from: Vector3, to: Vector3, fov: float) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	_title.text = name_of
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_shots.append(get_viewport().get_texture().get_image())


func _save() -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(_shots.size() / 2.0), false, first.get_format())
	for index in _shots.size():
		var shot: Image = _shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/artilleria_fina.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
