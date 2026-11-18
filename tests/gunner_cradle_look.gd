extends Node

## LA TORRETA DE GUERRA DEL ARTILLERO (18/11/2026; el usuario: «hay que hacer una silla bien hecha… como se haría en la
## guerra, como son los artilleros… que le permite a la silla inclinarse hacia arriba o hacia abajo, llevando también las
## cosas que tiene junto a la silla… los brazos dejarían de salir desde el piso y empezarían a salir desde… la silla»).
## Dos piezas: ABAJO, el plato que gira de costado con dos parantes (una horquilla), fijo en el giro; ARRIBA, LA CUNA,
## colgada de dos ejes a los costados a la altura de la cadera, que se inclina con la silla, las dos armas, el yugo y los
## tres tableros. Cuatro fotos: a nivel de afuera, desde sus ojos, inclinada 25° arriba y 10° abajo. Hoja: cuna_1.png.
##   tools/godot_ventana.sh res://tests/gunner_cradle_look.tscn -- --salida=C:/carpeta
##
## Todo en el espacio de la silla del artillero (m): −Z adelante, los ojos en `EYE`. La cuna es `_rig` (se inclina sobre
## `PIVOT`); el plato y la horquilla, `_base` (no se inclinan).

const VIEW := Vector2i(1280, 720)
const PER_SHEET := 6
const IDEAS := [
	["la torreta de guerra", "abajo el plato con la horquilla; arriba la cuna que se inclina"],
]
## Los ejes de la cuna, en el espacio de la silla: a la altura de la cadera.
const PIVOT := Vector3(0.0, 0.55, 0.0)
## LOS DOS AROS (m, al medio de cada lado; alto sobre el piso): el de afuera, fijo; el de adentro, que gira.
const OUTER := Vector2(0.4, 0.05)
const INNER := Vector2(0.27, 0.12)
## El aro: ocho lados, como el pozo de la locomoción.
const SIDES := 8
const HIP := 0.5
const SHOULDER := 1.0
const EYE := Vector3(0.0, 1.15, 0.02)
const HAND := Vector3(0.17, 0.64, -0.33)
const GUNMETAL := Color(0.24, 0.25, 0.27)
const PLATE := Color(0.5, 0.52, 0.55)
const GRAB := Color(0.62, 0.22, 0.18)
const SCREEN := Color(0.05, 0.12, 0.06)
const GREEN := Color(0.35, 0.9, 0.4)
const RED := Color(0.85, 0.2, 0.15)
const AMMO := [Color(0.85, 0.75, 0.3), Color(0.3, 0.6, 0.9), Color(0.85, 0.35, 0.25)]
const GLASS := Color(0.62, 0.8, 0.92, 0.3)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _note: Label = null
var _shots: Array = []
var _mech: CageMech = null
var _cage: CageCabin = null
var _chair: Node3D = null
## Lo de la idea de ahora (se borra al pasar a la siguiente); dónde quedan los ojos y las manos del maniquí.
var _rig: Node3D = null
var _eyes := EYE
var _hands: Array[Vector3] = []
var _sunk := 0.0
var _standing := false
var _facing := 0.0
## Cuánto se inclina la silla para apuntar arriba (grados).
var _tilt := 0.0
## Lo que no se inclina: el plato y la horquilla.
var _base: Node3D = null
## Lo que gira con las armas (el carro y lo suyo).
var _carriage: Node3D = null


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
	for k in 5:
		Clay.box(ground, Vector3(2.0, 3.0 + k, 2.0), Vector3(-12.0 + k * 6.0, 1.5 + k * 0.5, -40.0), Color(0.6, 0.35, 0.3))
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
	_title = _label(layer, Vector2(20, 8), 44)
	_note = _label(layer, Vector2(20, 64), 34)
	_mech = CageMech.new()
	_mech.scripted = true
	_mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
	add_child(_mech)
	await get_tree().create_timer(2.0).timeout
	for found in get_tree().root.find_children("*", "Label3D", true, false):
		(found as Label3D).visible = false
	_cage = _mech.cabin as CageCabin
	_chair = _cage.chairs[CageCabin.GUNNER] as Node3D
	_cage.gun.visible = false
	var turn := _cage.gun.get_parent() as Node3D
	for child in turn.get_children():
		if child != _cage.gun and child is MeshInstance3D and (child as Node3D).position.y > 0.3:
			(child as Node3D).visible = false
	for index in IDEAS.size():
		# Lo de la idea va al lado de la silla (en su lugar), no adentro: así la silla se puede esconder sola.
		_rig = Node3D.new()
		_chair.get_parent().add_child(_rig)
		_rig.transform = _chair.transform
		_base = Node3D.new()
		_chair.get_parent().add_child(_base)
		_base.transform = _chair.transform
		_eyes = EYE
		_hands = [Vector3(-HAND.x, HAND.y, HAND.z), HAND]
		_sunk = 0.0
		_standing = false
		_facing = 0.0
		_tilt = 0.0
		_carriage = null
		_chair.visible = true
		_idea(index + 1)
		# La silla de maqueta (se inclina y gira con lo suyo); la de verdad, escondida.
		_chair.visible = false
		_seat(Vector3.ZERO)
		_dummy()
		await get_tree().process_frame
		var seat := _rig.global_transform
		var at := seat * Vector3(0.0, 0.75, -0.2)
		var outside := at + seat.basis * Vector3(1.5, 1.2, -1.7)
		await _shot(IDEAS[index][0], "prueba: " + IDEAS[index][1], outside, at, 60.0)
		var eye := seat * _eyes
		await _shot("desde sus ojos, al frente", "", eye, eye + seat.basis * Vector3(0.0, -1.2, -3.0), 85.0)
		# De costado, para ver los ejes.
		var middle := seat * PIVOT
		var side := middle + seat.basis * Vector3(2.4, 0.4, -0.2)
		_tilt = 25.0
		_place_rig()
		await _shot("de costado: la cuna 25° arriba", "", side, middle + seat.basis * Vector3(0.0, 0.2, -0.2), 55.0)
		_tilt = -10.0
		_place_rig()
		await _shot("de costado: la cuna 10° abajo", "", side, middle + seat.basis * Vector3(0.0, 0.2, -0.2), 55.0)
		_rig.queue_free()
		_base.queue_free()
		await get_tree().process_frame
		if (index + 1) % PER_SHEET == 0 or index == IDEAS.size() - 1:
			_save(index / PER_SHEET + 1)
	get_tree().quit()


## ── LAS IDEAS ────────────────────────────────────────────────────────────────────────────────────────────────────

func _idea(_number: int) -> void:
	_hands = [Vector3(-0.15, 0.68, -0.4), Vector3(0.15, 0.68, -0.4)]
	# ABAJO: el plato y la horquilla, con los ejes a la altura de la cadera.
	Clay.cylinder(_base, 0.34, 0.06, Vector3(0.0, 0.03, 0.0), GUNMETAL)
	for side: float in [-1.0, 1.0]:
		Clay.box(_base, Vector3(0.06, PIVOT.y, 0.16), Vector3(side * 0.42, PIVOT.y * 0.5 + 0.03, 0.0), GUNMETAL)
		Clay.cylinder(_base, 0.06, 0.08, PIVOT + Vector3(side * 0.42, 0.0, 0.0), CageCabin.RIM_COLOR, Vector3(0.0, 0.0, 90.0))
	# ARRIBA: LA CUNA. Dos chapas a los costados de la silla, colgadas de los ejes, unidas abajo y atrás.
	for side: float in [-1.0, 1.0]:
		Clay.box(_rig, Vector3(0.04, 0.42, 0.5), Vector3(side * 0.36, 0.48, -0.02), PLATE)
		Clay.cylinder(_rig, 0.045, 0.06, PIVOT + Vector3(side * 0.36, 0.0, 0.0), GUNMETAL, Vector3(0.0, 0.0, 90.0))
	Clay.box(_rig, Vector3(0.76, 0.05, 0.3), Vector3(0.0, 0.29, 0.02), GUNMETAL)
	Clay.box(_rig, Vector3(0.76, 0.05, 0.05), Vector3(0.0, 0.31, -0.3), GUNMETAL)
	# Las armas: de cada chapa, un brazo corto hacia afuera y arriba.
	for side: float in [-1.0, 1.0]:
		var base := Vector3(side * 0.38, 0.62, -0.12)
		var at := Vector3(side * 0.56, 0.86, -0.3)
		_beam(base, at + Vector3(-side * 0.04, -0.09, 0.06), 0.03)
		Clay.sphere(_rig, 0.04, base, GUNMETAL)
		_weapon(_rig, at, side)
	# El yugo: una columna desde el travesaño de adelante, entre las rodillas.
	var top := Vector3(0.0, 0.6, -0.42)
	_beam(Vector3(0.0, 0.31, -0.3), top, 0.028)
	Clay.box(_rig, Vector3(0.32, 0.045, 0.05), top + Vector3(0.0, 0.06, 0.02), GRAB)
	for side: float in [-1.0, 1.0]:
		Clay.box(_rig, Vector3(0.045, 0.13, 0.055), top + Vector3(side * 0.14, 0.12, 0.02), GRAB)
	# Los tres tableros, en un cono adelante, en brazos desde el travesaño de adelante y desde las chapas.
	for spot: Vector3 in [Vector3(0.0, 0.92, -0.52), Vector3(-0.36, 0.82, -0.44), Vector3(0.36, 0.82, -0.44)]:
		var angle := atan2(spot.x, -spot.z)
		var foot := Vector3(spot.x * 0.9, 0.33, -0.3) if spot.x != 0.0 else Vector3(0.0, 0.62, -0.42)
		var elbow := (foot + spot) * 0.5 + Vector3(spot.x * 0.25, 0.0, -0.06)
		_beam(foot, elbow, 0.02)
		_beam(elbow, spot + Vector3(0.0, -0.06, 0.0), 0.018)
		Clay.sphere(_rig, 0.03, elbow, GUNMETAL)
		_face_panel(_rig, spot, angle, 35.0 if spot.x == 0.0 else 45.0)


## LA CUNA EN SU LUGAR: la silla, girada `_facing` e inclinada `_tilt` grados sobre los ejes (`PIVOT`).
func _place_rig() -> void:
	_rig.transform = _chair.transform * Transform3D(Basis(Vector3.UP, _facing), Vector3.ZERO) 		* Transform3D(Basis(), PIVOT) * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(_tilt)), Vector3.ZERO) 		* Transform3D(Basis(), -PIVOT)


## LO QUE GIRA: un nodo en el medio de la silla (las armas y su tablero cuelgan de él).
func _turning() -> Node3D:
	var turning := Node3D.new()
	_rig.add_child(turning)
	return turning


## UN ARO DE OCHO LADOS en `parent`, a `high` de alto, de `radius` (al medio de cada lado), de `thick` de grosor; con
## cuatro patas al piso si va fijo.
func _octagon(parent: Node3D, high: float, radius: float, thick: float) -> void:
	var side := 2.0 * radius * tan(PI / SIDES)
	for k in SIDES:
		var angle := TAU * k / SIDES
		var piece := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(side + thick, thick, thick)
		piece.mesh = box
		piece.material_override = _paint(GUNMETAL)
		piece.position = Vector3(sin(angle) * radius, high, -cos(angle) * radius)
		piece.rotation.y = -angle
		parent.add_child(piece)
	if parent == _rig:
		for k in 4:
			var angle := TAU * (k + 0.5) / 4.0
			Clay.box(_rig, Vector3(0.035, high, 0.035), Vector3(sin(angle) * radius, high * 0.5, -cos(angle) * radius), GUNMETAL)


## LOS PANELES FIJOS en la banda inclinada: en cada ángulo (grados, 0 adelante, a la derecha), un brazo articulado que
## sale del aro y un panel inclinado mirando al artillero.
func _fixed_panels(high: float, radius: float, angles: Array) -> void:
	for degrees: float in angles:
		var angle := deg_to_rad(degrees)
		var base := Vector3(sin(angle) * radius, high, -cos(angle) * radius)
		var spot := Vector3(sin(angle) * (radius * 0.85), high + 0.38, -cos(angle) * (radius * 0.85))
		var elbow := (base + spot) * 0.5 + Vector3(sin(angle), 0.0, -cos(angle)) * 0.12
		_beam(base, elbow, 0.02)
		_beam(elbow, spot, 0.018)
		_face_panel(_rig, spot, angle, 50.0)


## UN PANEL de tablero en `at`, en la dirección `angle` (rad, 0 adelante), inclinado `lean` grados mirando al medio.
func _face_panel(parent: Node3D, at: Vector3, angle: float, lean: float) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation = Vector3(0.0, -angle, 0.0)
	parent.add_child(holder)
	var tilted := Node3D.new()
	tilted.rotation_degrees = Vector3(-lean, 0.0, 0.0)
	holder.add_child(tilted)
	Clay.box(tilted, Vector3(0.26, 0.18, 0.02), Vector3.ZERO, PLATE)
	_controls(tilted, Vector2(0.26, 0.18))


## UN PANEL COLGADO por afuera y abajo del aro (la 3): el carro le pasa por arriba.
func _hanging_panel(degrees: float, radius: float, high: float) -> void:
	var angle := deg_to_rad(degrees)
	var base := Vector3(sin(angle) * radius, high, -cos(angle) * radius)
	var spot := Vector3(sin(angle) * (radius + 0.1), high - 0.22, -cos(angle) * (radius + 0.1))
	_beam(base, spot + Vector3(0.0, 0.08, 0.0), 0.02)
	_face_panel(_rig, spot, angle, 65.0)


## UN PANEL PLEGADO (la 6): su brazo caído hacia afuera, el panel boca abajo, donde pasa el carro.
func _folded_panel(degrees: float, high: float, radius: float) -> void:
	var angle := deg_to_rad(degrees)
	var base := Vector3(sin(angle) * radius, high, -cos(angle) * radius)
	var spot := base + Vector3(sin(angle), 0.0, -cos(angle)) * 0.3 + Vector3(0.0, -0.15, 0.0)
	_beam(base, spot, 0.02)
	_face_panel(_rig, spot, angle, -60.0)


## LAS ARMAS Y SU TABLERO en el carro: la minigun a la derecha y los misiles a la izquierda, cada una en un brazo que
## sale del aro (a `high`, de `radius`); al medio, el tablero de las armas con el yugo.
func _arms_and_board(high: float, radius: float) -> void:
	for s: float in [-1.0, 1.0]:
		var base := Vector3(s * radius * 0.7, high, -radius * 0.7)
		var at := Vector3(s * 0.62, 0.92, -0.45)
		var elbow := (base + at) * 0.5 + Vector3(s * 0.1, 0.0, 0.0)
		_beam_on(_carriage, base, elbow, 0.03)
		_beam_on(_carriage, elbow, at + Vector3(0.0, -0.08, 0.05), 0.028)
		_weapon(_carriage, at, s)
	_board_and_yoke(_carriage, high)


## UNA ARMA del carro: la minigun (`s` 1) o los misiles (−1), en `at`.
func _weapon(parent: Node3D, at: Vector3, s: float) -> void:
	var keep := _rig
	_rig = parent
	if s > 0.0:
		_minigun(at)
	else:
		_pod(at)
	_rig = keep


## EL TABLERO DE LAS ARMAS a la altura de la cara del medio, adelante, con EL YUGO abajo: una sola pieza para agarrar,
## corta, que sale del aro (a `high`).
func _board_and_yoke(parent: Node3D, high: float) -> void:
	var base := Vector3(0.0, high, -0.55)
	var spot := Vector3(0.0, 0.92, -0.5)
	_beam_on(parent, base, spot + Vector3(0.0, -0.1, 0.05), 0.025)
	_face_panel(parent, spot, 0.0, 25.0)
	# El yugo: una columna corta y la barra con las dos manijas, todo una pieza.
	var yoke := Vector3(0.0, 0.66, -0.42)
	_beam_on(parent, base + Vector3(0.0, 0.0, 0.08), yoke + Vector3(0.0, -0.02, 0.0), 0.022)
	Clay.box(parent, Vector3(0.34, 0.05, 0.05), yoke, GRAB)
	for s: float in [-1.0, 1.0]:
		Clay.box(parent, Vector3(0.05, 0.14, 0.06), yoke + Vector3(s * 0.15, 0.06, 0.0), GRAB)


## UNA VIGA en `parent`.
func _beam_on(parent: Node3D, from: Vector3, to: Vector3, radius: float) -> void:
	var piece := Clay.cylinder(parent, radius, from.distance_to(to), (from + to) * 0.5, GUNMETAL)
	var along := (to - from).normalized()
	var side := along.cross(Vector3.FORWARD if absf(along.y) > 0.5 else Vector3.UP).normalized()
	piece.basis = Basis(side, along, side.cross(along))


## LAS DOS ARMAS a `out` m del medio, a `high` de alto y `ahead` adelante: la minigun a la derecha y los misiles a la
## izquierda; con `arms`, cada una en un brazo desde el costado del asiento.
func _weapons(out: float, high: float, ahead: float, arms: bool) -> void:
	for s: float in [-1.0, 1.0]:
		var at := Vector3(s * out, high, ahead)
		if arms:
			_beam(Vector3(s * 0.24, 0.45, 0.02), at + Vector3(-s * 0.05, -0.06, 0.05), 0.035)
			Clay.sphere(_rig, 0.05, Vector3(s * 0.24, 0.45, 0.02), GUNMETAL)
		else:
			Clay.box(_rig, Vector3(0.1, 0.12, 0.2), Vector3(s * (out - 0.09), high - 0.05, ahead), GUNMETAL)
		if s > 0.0:
			_minigun(at)
		else:
			_pod(at)


## LA MINIGUN: el motor atrás, seis caños en rueda con dos aros, y el tambor de munición abajo con su cinta.
func _minigun(at: Vector3) -> void:
	Clay.box(_rig, Vector3(0.14, 0.14, 0.22), at + Vector3(0.0, 0.0, 0.06), GUNMETAL)
	Clay.cylinder(_rig, 0.075, 0.12, at + Vector3(0.0, 0.0, -0.1), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
	for k in 6:
		var angle := TAU * k / 6.0
		var spot := Vector3(cos(angle), sin(angle), 0.0) * 0.045
		Clay.cylinder(_rig, 0.014, 0.62, at + spot + Vector3(0.0, 0.0, -0.45), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	for z: float in [-0.42, -0.72]:
		Clay.cylinder(_rig, 0.068, 0.025, at + Vector3(0.0, 0.0, z), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
	Clay.cylinder(_rig, 0.09, 0.12, at + Vector3(0.0, -0.17, 0.05), CageCabin.YELLOW.darkened(0.25), Vector3(0.0, 0.0, 90.0))
	Clay.box(_rig, Vector3(0.05, 0.12, 0.04), at + Vector3(0.0, -0.08, -0.02), GUNMETAL)


## LA CAJA DE MISILES: seis tubos, tres por dos.
func _pod(at: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = at
	_rig.add_child(holder)
	_missiles_on(holder, Vector3.ZERO, 3, 2, 0.085)


## LOS APOYABRAZOS de la silla; con `boards`, grandes y con botones arriba.
func _armrests(boards: bool) -> void:
	for s: float in [-1.0, 1.0]:
		var wide := 0.14 if boards else 0.07
		Clay.box(_rig, Vector3(wide, 0.05, 0.42), Vector3(s * (0.24 + wide * 0.5), 0.55, -0.06), GUNMETAL)
		if boards:
			var holder := Node3D.new()
			holder.position = Vector3(s * (0.24 + wide * 0.5), 0.58, -0.08)
			holder.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			_rig.add_child(holder)
			Clay.box(holder, Vector3(wide - 0.01, 0.36, 0.01), Vector3.ZERO, PLATE)
			_controls(holder, Vector2(wide - 0.01, 0.36))


## MEDIO ARO de tableros al pecho, adelante de la silla, de `radius`.
func _half_ring(at: Vector3, radius: float) -> void:
	for k in 5:
		var angle := deg_to_rad(-90.0 + (k - 2) * 32.0)
		var spot := Vector3(cos(angle), 0.0, sin(angle)) * radius + at
		var holder := Node3D.new()
		holder.position = spot
		holder.rotation = Vector3(deg_to_rad(-40.0), -angle - PI * 0.5, 0.0)
		_rig.add_child(holder)
		Clay.box(holder, Vector3(0.28, 0.2, 0.02), Vector3.ZERO, PLATE)
		_controls(holder, Vector2(0.28, 0.2))
	for s: float in [-1.0, 1.0]:
		_beam(Vector3(s * 0.24, 0.45, 0.0), Vector3(s * radius * 0.85, at.y - 0.1, -radius * 0.5), 0.025)


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## UNA SILLA DE MAQUETA (donde la de verdad no va): el asiento y el respaldo, en `at`.
func _seat(at: Vector3) -> void:
	Clay.box(_rig, Vector3(0.48, 0.08, 0.46), at + Vector3(0.0, 0.42, 0.02), Color(0.42, 0.36, 0.42))
	Clay.box(_rig, Vector3(0.48, 0.6, 0.08), at + Vector3(0.0, 0.72, 0.24), Color(0.42, 0.36, 0.42))
	Clay.cylinder(_rig, 0.05, 0.4, at + Vector3(0.0, 0.2, 0.05), GUNMETAL)


## Un pie del plato hasta `tall` de alto, en `at`.
func _post(at: Vector3, tall: float) -> void:
	Clay.cylinder(_rig, 0.035, tall, at + Vector3(0.0, tall * 0.5, 0.0), GUNMETAL)


func _mg(at: Vector3) -> void:
	_mg_on(_rig, at)


## LA AMETRALLADORA FINA: cajón, dos caños con aletas, la caja de munición al costado.
func _mg_on(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.09, 0.09, 0.42), at + Vector3(0.0, 0.0, -0.12), GUNMETAL)
	for x: float in [-0.022, 0.022]:
		Clay.cylinder(parent, 0.017, 0.75, at + Vector3(x, 0.01, -0.68), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	for k in 4:
		Clay.cylinder(parent, 0.042, 0.015, at + Vector3(0.0, 0.01, -0.4 - k * 0.05), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(0.08, 0.1, 0.14), at + Vector3(0.09, -0.02, -0.1), CageCabin.YELLOW.darkened(0.25))


func _missiles(at: Vector3, columns: int, rows: int, cell: float, pitch := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees = Vector3(pitch, 0.0, 0.0)
	_rig.add_child(holder)
	_missiles_on(holder, Vector3.ZERO, columns, rows, cell)


## LA CAJA DE MISILES: `columns` × `rows` tubos de `cell`, con las bocas oscuras adelante (−Z) y la tapa amarilla.
func _missiles_on(parent: Node3D, at: Vector3, columns: int, rows: int, cell: float) -> void:
	var size := Vector3(columns * cell + 0.03, rows * cell + 0.03, cell * 5.0)
	Clay.box(parent, size, at, CageCabin.METAL)
	for c in columns:
		for k in rows:
			var spot := at + Vector3((c - (columns - 1) * 0.5) * cell, (k - (rows - 1) * 0.5) * cell, -size.z * 0.5 - 0.005)
			Clay.cylinder(parent, cell * 0.36, 0.012, spot, CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(parent, cell * 0.2, 0.014, spot, AMMO[2], Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(size.x + 0.01, 0.02, size.z * 0.6), at + Vector3(0.0, size.y * 0.5 + 0.01, 0.0), CageCabin.YELLOW)


## EL CAÑÓN CORTO: caño grueso y corto con su recámara.
func _cannon(at: Vector3) -> void:
	Clay.box(_rig, Vector3(0.12, 0.12, 0.3), at + Vector3(0.0, 0.0, -0.08), GUNMETAL)
	Clay.cylinder(_rig, 0.05, 0.42, at + Vector3(0.0, 0.0, -0.43), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))


func _spade(at: Vector3, half: float, with_board: bool) -> void:
	_spade_on(_rig, at, half, with_board)
	_hands = [at + Vector3(-half, 0.0, 0.0), at + Vector3(half, 0.0, 0.0)]


## LA HORQUILLA: dos manijas paradas unidas por una barra, TODO UNA PIEZA (del color de lo que se agarra); con
## `with_board`, el tablero entre las manijas, mirando al artillero.
func _spade_on(parent: Node3D, at: Vector3, half: float, with_board: bool) -> void:
	Clay.box(parent, Vector3(half * 2.0 + 0.05, 0.04, 0.04), at + Vector3(0.0, -0.08, 0.0), GRAB)
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(parent, 0.024, 0.16, at + Vector3(s * half, 0.0, 0.0), GRAB)
		Clay.box(parent, Vector3(0.03, 0.03, 0.12), at + Vector3(s * half, -0.08, -0.06), GRAB)
	if with_board:
		var holder := Node3D.new()
		holder.position = at + Vector3(0.0, 0.04, -0.02)
		holder.rotation_degrees = Vector3(-20.0, 0.0, 0.0)
		parent.add_child(holder)
		var size := Vector2(half * 1.6, 0.16)
		Clay.box(holder, Vector3(size.x, size.y, 0.02), Vector3.ZERO, PLATE)
		_controls(holder, size)


## UNA MANIJA SUELTA (el mando de un arma), en `at`.
func _grip(at: Vector3) -> void:
	Clay.cylinder(_rig, 0.024, 0.16, at, GRAB)
	Clay.box(_rig, Vector3(0.03, 0.03, 0.12), at + Vector3(0.0, -0.08, -0.06), GRAB)


## UN MANUBRIO: una barra entera de lado a lado, de `half` a cada lado.
func _bar(at: Vector3, half: float) -> void:
	Clay.cylinder(_rig, 0.022, half * 2.0, at, GRAB, Vector3(0.0, 0.0, 90.0))
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(_rig, 0.028, 0.12, at + Vector3(s * half, 0.0, 0.0), GRAB, Vector3(0.0, 0.0, 90.0))
	Clay.box(_rig, Vector3(0.04, 0.2, 0.04), at + Vector3(0.0, -0.1, -0.05), GUNMETAL)
	_hands = [at + Vector3(-half, 0.0, 0.0), at + Vector3(half, 0.0, 0.0)]


## UNA PALANCA SOLA, parada desde el piso en `at`.
func _stick(at: Vector3) -> void:
	Clay.box(_rig, Vector3(0.14, 0.04, 0.14), at, GUNMETAL)
	Clay.cylinder(_rig, 0.02, 0.6, at + Vector3(0.0, 0.3, 0.0), GRAB)
	Clay.sphere(_rig, 0.04, at + Vector3(0.0, 0.62, 0.0), GRAB)


## UNA PALANCA DE LANZAR al costado, en `at`.
func _lever(at: Vector3) -> void:
	Clay.box(_rig, Vector3(0.1, 0.3, 0.12), at, GUNMETAL)
	Clay.cylinder(_rig, 0.018, 0.3, at + Vector3(0.0, 0.3, 0.0), GRAB)
	Clay.sphere(_rig, 0.035, at + Vector3(0.0, 0.46, 0.0), RED)


## UN ARCO sobre la cabeza, de `half` a cada lado.
func _arch(half: float) -> void:
	for s: float in [-1.0, 1.0]:
		Clay.box(_rig, Vector3(0.05, 1.55, 0.05), Vector3(s * half, 0.78, -0.3), GUNMETAL)
	Clay.box(_rig, Vector3(half * 2.0 + 0.05, 0.05, 0.05), Vector3(0.0, 1.6, -0.3), GUNMETAL)


## UN ANILLO horizontal alrededor de la silla, a `at`, de `radius`; con `panels`, paneles colgados adelante.
func _ring(at: Vector3, radius: float, panels: bool) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.03
	torus.outer_radius = radius + 0.03
	ring.mesh = torus
	ring.position = at
	ring.material_override = _paint(GUNMETAL)
	_rig.add_child(ring)
	for k in 4:
		var angle := TAU * (k + 0.5) / 4.0
		var foot := Vector3(cos(angle), 0.0, sin(angle)) * radius
		Clay.box(_rig, Vector3(0.04, at.y, 0.04), Vector3(foot.x, at.y * 0.5, foot.z), GUNMETAL)
	if not panels:
		return
	for k in 3:
		var angle := deg_to_rad(-90.0 + (k - 1) * 40.0)
		var spot := Vector3(cos(angle), 0.0, sin(angle)) * (radius + 0.02) + Vector3(0.0, at.y + 0.1, 0.0)
		var holder := Node3D.new()
		holder.position = spot
		holder.rotation = Vector3(deg_to_rad(-55.0), -angle - PI * 0.5, 0.0)
		_rig.add_child(holder)
		Clay.box(holder, Vector3(0.3, 0.18, 0.02), Vector3.ZERO, PLATE)
		_controls(holder, Vector2(0.3, 0.18))


## UNA BOLA DE VIDRIO de `radius` alrededor de la silla, en `at`.
func _ball(at: Vector3, radius: float) -> void:
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	ball.mesh = sphere
	ball.position = at
	ball.material_override = _glass()
	_rig.add_child(ball)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.02
	torus.outer_radius = radius + 0.04
	rim.mesh = torus
	rim.position = at
	rim.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	rim.material_override = _paint(GUNMETAL)
	_rig.add_child(rim)


## UNA PANTALLA en un brazo articulado, de `base` a `at`.
func _screen_arm(base: Vector3, at: Vector3) -> void:
	var elbow := (base + at) * 0.5 + Vector3(0.0, 0.2, 0.15)
	_beam(base, elbow, 0.025)
	_beam(elbow, at, 0.022)
	var holder := Node3D.new()
	holder.position = at
	_rig.add_child(holder)
	holder.look_at(_rig.global_transform * Vector3(0.0, 1.1, 0.0), Vector3.UP)
	holder.rotate_object_local(Vector3.UP, PI)
	Clay.box(holder, Vector3(0.26, 0.18, 0.03), Vector3.ZERO, PLATE)
	_controls(holder, Vector2(0.26, 0.18))


## UNA VIGA de `from` a `to`, de `radius`.
func _beam(from: Vector3, to: Vector3, radius: float) -> void:
	var piece := Clay.cylinder(_rig, radius, from.distance_to(to), (from + to) * 0.5, GUNMETAL)
	var along := (to - from).normalized()
	var side := along.cross(Vector3.FORWARD if absf(along.y) > 0.5 else Vector3.UP).normalized()
	piece.basis = Basis(side, along, side.cross(along))


## UN TABLERO de `size` en `at`, inclinado `tilt` grados (hacia atrás, negativo) y girado `turn` en Y, con sus controles
## mirando al artillero.
func _board(at: Vector3, size: Vector2, tilt: float, turn := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.basis = Basis(Vector3.UP, deg_to_rad(turn)) * Basis(Vector3.RIGHT, deg_to_rad(tilt))
	_rig.add_child(holder)
	Clay.box(holder, Vector3(size.x, size.y, 0.02), Vector3.ZERO, PLATE)
	_controls(holder, size)


## LOS CONTROLES en la cara de un tablero de `size` (+Z): munición por color, relojes, calor y recargas.
func _controls(panel: Node3D, size: Vector2) -> void:
	var front := 0.015
	var w := size.x
	var h := size.y
	for k in 3:
		Clay.box(panel, Vector3(w * 0.12, h * 0.16, 0.012), Vector3(-w * 0.32 + k * w * 0.16, -h * 0.28, front), AMMO[k])
	for k in 2:
		var dial := Vector3(-w * 0.3 + k * w * 0.22, h * 0.16, front)
		Clay.cylinder(panel, minf(w, h) * 0.13, 0.008, dial, SCREEN, Vector3(90.0, 0.0, 0.0))
	Clay.box(panel, Vector3(w * 0.06, h * 0.7, 0.01), Vector3(w * 0.4, 0.0, front), SCREEN)
	Clay.box(panel, Vector3(w * 0.05, h * 0.45, 0.012), Vector3(w * 0.4, -h * 0.12, front + 0.002), RED)
	for k in 3:
		var y := h * (0.28 - k * 0.12)
		Clay.box(panel, Vector3(w * 0.22, h * 0.07, 0.01), Vector3(w * 0.15, y, front), SCREEN)
		Clay.box(panel, Vector3(w * 0.22 * (0.3 + k * 0.3), h * 0.06, 0.012), Vector3(w * 0.15 - w * 0.11 * (0.7 - k * 0.3), y, front + 0.002), GREEN)


## ── EL MANIQUÍ ───────────────────────────────────────────────────────────────────────────────────────────────────

## EL MANIQUÍ con las manos en `_hands`: sentado (o parado, `_standing`), hundido `_sunk` m, mirando hacia `_facing`.
func _dummy() -> void:
	var skin := Color(0.85, 0.72, 0.6)
	var cloth := Color(0.35, 0.42, 0.55)
	var body := Node3D.new()
	body.position = Vector3(0.0, -_sunk, 0.0)
	_rig.add_child(body)
	# Girada y, para apuntar arriba, inclinada sobre el asiento.
	_place_rig()
	var hip_y := 1.0 if _standing else HIP
	var top := hip_y + (SHOULDER - HIP)
	Clay.box(body, Vector3(0.36, top - hip_y, 0.22), Vector3(0.0, (top + hip_y) * 0.5, 0.05), cloth)
	Clay.sphere(body, 0.12, Vector3(0.0, top + 0.18, 0.04), skin)
	for i in 2:
		var s := -1.0 if i == 0 else 1.0
		var shoulder := Vector3(s * 0.21, top - 0.04, 0.05)
		var hand: Vector3 = _hands[i] + Vector3(0.0, _sunk, 0.0)
		var elbow := (shoulder + hand) * 0.5 + Vector3(s * 0.08, -0.16, 0.08)
		_limb(body, shoulder, elbow, 0.05, cloth)
		_limb(body, elbow, hand, 0.045, cloth)
		Clay.sphere(body, 0.05, hand, skin)
		var hip := Vector3(s * 0.12, hip_y, 0.05)
		if _standing:
			_limb(body, hip, Vector3(s * 0.14, 0.05, 0.05), 0.07, cloth)
		else:
			var knee := Vector3(s * 0.16, hip_y, -0.38)
			_limb(body, hip, knee, 0.07, cloth)
			_limb(body, knee, knee + Vector3(0.0, -0.45, 0.02), 0.06, cloth)


func _limb(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> void:
	var piece := Clay.cylinder(parent, radius, from.distance_to(to), (from + to) * 0.5, color)
	var along := (to - from).normalized()
	var side := along.cross(Vector3.FORWARD if absf(along.y) > 0.5 else Vector3.UP).normalized()
	piece.basis = Basis(side, along, side.cross(along))


func _paint(color: Color) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	return paint


func _glass() -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = GLASS
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return paint


## ── LAS FOTOS ────────────────────────────────────────────────────────────────────────────────────────────────────

func _label(layer: CanvasLayer, at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.size = Vector2(VIEW.x - at.x * 2.0, 0.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 10)
	layer.add_child(label)
	return label


func _shot(name_of: String, note: String, from: Vector3, to: Vector3, fov: float) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	_title.text = name_of
	_note.text = note
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_shots.append(get_viewport().get_texture().get_image())


## UNA HOJA: tres columnas (de afuera, desde sus ojos, con las armas giradas), una fila por idea; y vacía la lista.
func _save(number: int) -> void:
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
	var path := "%s/cuna_%d.png" % [_folder, number]
	sheet.save_png(path)
	print("CAPTURA ", path)
	_shots.clear()
