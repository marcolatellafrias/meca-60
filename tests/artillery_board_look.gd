extends Node

## EL TABLERO-ARMA DEL ARTILLERO (18/11/2026; el usuario: «los botones donde puedes cambiar el tipo de munición, ver los
## cooldowns… era como… la misma plancha de la primera ametralladora… pero hacerla con muchos botones, con cooldowns e
## indicadores, y además los mandos que sean como dos manijas para agarrarla… si apretas los mandos… la capturas y tu
## visión se va… para disparar… si no… se pueden ver todos los botones… así se siente como más físico»): la ametralladora
## fina (la 2 de tests/artillery_slim_look) con una plancha que es su tablero, en cuatro maneras. De cada una, tres
## fotos: de costado, desde los ojos con el arma suelta (se ve el tablero) y desde la mira con el arma agarrada.
##   tools/godot_ventana.sh res://tests/artillery_board_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const GAP := 14.0
const IDEAS := [
	"1. la plancha de antes, baja: el tablero en su cara de atrás, la mira de anillo arriba",
	"2. plancha alta con ventana: el tablero alrededor del hueco; se apunta por el hueco",
	"3. un atril entre las manijas, con dos ametralladoras a los costados",
	"4. dos alas a los costados de la cabeza, el medio libre para ver",
]
## El maniquí, en el espacio de su silla (m): las manos en L, con los codos en la cadera; los ojos.
const HIP := 0.5
const SHOULDER := 1.0
const ELBOW := Vector3(0.22, 0.62, 0.0)
const HAND := Vector3(0.17, 0.64, -0.33)
const EYE := Vector3(0.0, 1.15, 0.02)
const GUNMETAL := Color(0.24, 0.25, 0.27)
const PLATE := Color(0.5, 0.52, 0.55)
const SCREEN := Color(0.05, 0.12, 0.06)
const GREEN := Color(0.35, 0.9, 0.4)
const RED := Color(0.85, 0.2, 0.15)
## Los tres tipos de munición, por color (los botones y las ranuras).
const AMMO := [Color(0.85, 0.75, 0.3), Color(0.3, 0.6, 0.9), Color(0.85, 0.35, 0.25)]

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _shots: Array = []
## Dónde va el ojo apuntando, en cada variante (en el espacio de la silla).
var _sights: Array[Vector3] = []


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
	# Unos blancos lejos, para ver la mira contra algo.
	for k in 5:
		Clay.box(ground, Vector3(2.0, 3.0 + k, 2.0), Vector3(-12.0 + k * 14.0, 1.5 + k * 0.5, -40.0), Color(0.6, 0.35, 0.3))
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
	_eye.near = 0.02
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 46)
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
		var seat := (cage.chairs[CageCabin.GUNNER] as Node3D).global_transform
		var at := seat * Vector3(0.0, 0.8, -0.4)
		var name_of: String = IDEAS[index].substr(0, 2)
		await _shot(IDEAS[index], at + seat.basis * Vector3(2.0, 0.4, -0.6), at, 45.0)
		var eye := seat * EYE
		await _shot(name_of + " suelta: desde sus ojos", eye, eye + seat.basis * Vector3(0.0, -1.6, -3.0), 80.0)
		var sight := seat * _sights[index]
		await _shot(name_of + " agarrada: desde la mira", sight, sight + seat.basis * Vector3(0.0, 0.0, -10.0), 55.0)
	_save()
	get_tree().quit()


## LA VARIANTE `index` en la cabina `cage`: el maniquí sentado, el arma de hoy escondida y el tablero-arma.
func _idea(index: int, cage: CageCabin) -> void:
	var chair := cage.chairs[CageCabin.GUNNER] as Node3D
	_dummy(chair)
	cage.gun.visible = false
	var turn := cage.gun.get_parent() as Node3D
	for child in turn.get_children():
		if child != cage.gun and child is MeshInstance3D and (child as Node3D).position.y > 0.3:
			(child as Node3D).visible = false
	# Todo en el espacio de la silla (cuelga de la silla para la maqueta).
	var rig := Node3D.new()
	chair.add_child(rig)
	Clay.cylinder(rig, 0.035, 0.5, Vector3(0.0, 0.3, -0.5), GUNMETAL)
	match index:
		0:
			var plate := _panel(rig, Vector3(0.0, 0.8, -0.48), Vector2(0.78, 0.36), -15.0)
			_controls(plate, Vector2(0.78, 0.36))
			_handles(rig, 0.42)
			_machine_gun(rig, Vector3(0.0, 0.6, -0.5))
			_ring_sight(rig, Vector3(0.0, 1.12, -0.62))
			_sights.append(Vector3(0.0, 1.12, -0.3))
		1:
			_window_plate(rig, Vector3(0.0, 0.95, -0.5))
			_handles(rig, 0.42)
			_machine_gun(rig, Vector3(0.0, 0.6, -0.5))
			_sights.append(Vector3(0.0, 1.13, -0.35))
		2:
			var desk := _panel(rig, Vector3(0.0, 0.78, -0.42), Vector2(0.34, 0.24), -35.0)
			_controls(desk, Vector2(0.34, 0.24))
			_handles(rig, 0.26)
			for s: float in [-1.0, 1.0]:
				_machine_gun(rig, Vector3(s * 0.36, 0.62, -0.42))
			_ring_sight(rig, Vector3(0.0, 1.1, -0.6))
			_sights.append(Vector3(0.0, 1.1, -0.3))
		3:
			for s: float in [-1.0, 1.0]:
				var wing := _panel(rig, Vector3(s * 0.36, 0.95, -0.38), Vector2(0.3, 0.44), -10.0, s * 30.0)
				_controls(wing, Vector2(0.3, 0.44))
			_handles(rig, 0.3)
			_machine_gun(rig, Vector3(0.0, 0.6, -0.5))
			_ring_sight(rig, Vector3(0.0, 1.1, -0.65))
			_sights.append(Vector3(0.0, 1.1, -0.32))


## UNA PLANCHA de `size` (ancho, alto) en `at`, inclinada `tilt` grados hacia atrás y girada `turn` en Y; devuelve el
## nodo de su cara de atrás (la que mira al artillero: +Z).
func _panel(parent: Node3D, at: Vector3, size: Vector2, tilt: float, turn := 0.0) -> Node3D:
	var panel := Node3D.new()
	panel.position = at
	panel.basis = Basis(Vector3.UP, deg_to_rad(turn)) * Basis(Vector3.RIGHT, deg_to_rad(tilt))
	parent.add_child(panel)
	Clay.box(panel, Vector3(size.x, size.y, 0.03), Vector3.ZERO, PLATE)
	return panel


## LOS CONTROLES en la cara de atrás de una plancha de `size`: tres botones de munición (por color), dos relojes, el
## calor (una barra roja) y tres tiempos de recarga (barras verdes), y una pantallita con el contador.
func _controls(panel: Node3D, size: Vector2) -> void:
	var front := 0.02
	var w := size.x
	var h := size.y
	for k in 3:
		Clay.box(panel, Vector3(w * 0.12, h * 0.14, 0.02), Vector3(-w * 0.32 + k * w * 0.16, -h * 0.3, front), AMMO[k])
	for k in 2:
		var dial := Vector3(-w * 0.3 + k * w * 0.22, h * 0.18, front)
		Clay.cylinder(panel, minf(w, h) * 0.12, 0.01, dial, SCREEN, Vector3(90.0, 0.0, 0.0))
		Clay.box(panel, Vector3(0.006, minf(w, h) * 0.1, 0.012), dial + Vector3(0.0, minf(w, h) * 0.04, 0.008), GREEN)
	Clay.box(panel, Vector3(w * 0.06, h * 0.7, 0.012), Vector3(w * 0.4, 0.0, front), SCREEN)
	Clay.box(panel, Vector3(w * 0.05, h * 0.45, 0.014), Vector3(w * 0.4, -h * 0.12, front + 0.002), RED)
	for k in 3:
		var y := h * (0.28 - k * 0.12)
		Clay.box(panel, Vector3(w * 0.22, h * 0.06, 0.012), Vector3(w * 0.15, y, front), SCREEN)
		Clay.box(panel, Vector3(w * 0.22 * (0.3 + k * 0.3), h * 0.05, 0.014), Vector3(w * 0.15 - w * 0.11 * (0.7 - k * 0.3), y, front + 0.002), GREEN)
	Clay.box(panel, Vector3(w * 0.2, h * 0.16, 0.012), Vector3(w * 0.15, -h * 0.3, front), SCREEN)


## LA PLANCHA ALTA CON VENTANA (la 2): cuatro tramos alrededor de un hueco a la altura de los ojos; los controles, abajo.
func _window_plate(parent: Node3D, at: Vector3) -> void:
	var w := 0.8
	var h := 0.7
	var hole := Vector2(0.32, 0.18)
	var middle := Vector3(0.0, 0.18, 0.0)
	var plate := _panel(parent, at, Vector2(0.01, 0.01), -8.0)
	var below := (h * 0.5 + middle.y - hole.y * 0.5)
	Clay.box(plate, Vector3(w, below, 0.03), Vector3(0.0, -h * 0.5 + below * 0.5, 0.0), PLATE)
	var above := h * 0.5 - middle.y - hole.y * 0.5
	Clay.box(plate, Vector3(w, above, 0.03), Vector3(0.0, h * 0.5 - above * 0.5, 0.0), PLATE)
	var side := (w - hole.x) * 0.5
	for s: float in [-1.0, 1.0]:
		Clay.box(plate, Vector3(side, hole.y, 0.03), Vector3(s * (hole.x * 0.5 + side * 0.5), middle.y, 0.0), PLATE)
	var lower := Node3D.new()
	lower.position = Vector3(0.0, -h * 0.5 + below * 0.5, 0.0)
	plate.add_child(lower)
	_controls(lower, Vector2(w, below))
	# Una cruz en el hueco.
	Clay.box(plate, Vector3(hole.x, 0.004, 0.004), middle, RED)
	Clay.box(plate, Vector3(0.004, hole.y, 0.004), middle, RED)


## LA MIRA DE ANILLO en un poste, en `at`.
func _ring_sight(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.02, at.y - 0.95, 0.02), Vector3(at.x, (at.y + 0.95) * 0.5 - 0.06, at.z), GUNMETAL)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.075
	torus.outer_radius = 0.085
	ring.mesh = torus
	ring.position = at
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = GUNMETAL
	ring.material_override = paint
	parent.add_child(ring)
	Clay.box(parent, Vector3(0.15, 0.004, 0.004), at, GUNMETAL)
	Clay.box(parent, Vector3(0.004, 0.15, 0.004), at, GUNMETAL)


## LAS DOS MANIJAS, a `half` del medio, donde van las manos.
func _handles(parent: Node3D, half: float) -> void:
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(parent, 0.022, 0.14, Vector3(s * half, HAND.y, HAND.z - 0.02), CageCabin.DARK)
		Clay.box(parent, Vector3(0.04, 0.03, 0.18), Vector3(s * half, HAND.y + 0.08, HAND.z - 0.1), GUNMETAL)
		Clay.box(parent, Vector3(0.03, 0.02, 0.02), Vector3(s * half, HAND.y + 0.08, HAND.z + 0.01), RED)


## LA AMETRALLADORA FINA (la 2 de tests/artillery_slim_look), con la boca de la culata en `at`.
func _machine_gun(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.09, 0.09, 0.42), at + Vector3(0.0, 0.0, -0.12), GUNMETAL)
	for x: float in [-0.022, 0.022]:
		Clay.cylinder(parent, 0.017, 0.75, at + Vector3(x, 0.01, -0.68), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	for k in 4:
		Clay.cylinder(parent, 0.042, 0.015, at + Vector3(0.0, 0.01, -0.4 - k * 0.05), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(0.1, 0.12, 0.16), at + Vector3(0.11, -0.02, -0.1), CageCabin.YELLOW.darkened(0.25))


## EL MANIQUÍ SENTADO en `chair`, con los brazos en L.
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
		var hip := Vector3(s * 0.12, HIP, 0.05)
		var knee := Vector3(s * 0.16, HIP, -0.38)
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


## UNA HOJA DE TRES COLUMNAS: una fila por variante.
func _save() -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var w := first.get_width() / 3
	var h := first.get_height() / 3
	var sheet := Image.create(w * 3, h * ceili(_shots.size() / 3.0), false, first.get_format())
	for index in _shots.size():
		var shot: Image = _shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 3), h * (index / 3)))
	var path := "%s/artilleria_tablero.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
