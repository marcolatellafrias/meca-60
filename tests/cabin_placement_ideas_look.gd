extends Node3D

## TREINTA IDEAS DE MECAS DE CABINAS SEPARADAS, MAQUETAS DE ARCILLA (15/11/2026, el usuario, después del disco con
## cápsulas: «los cápsulas están muy altas, tienen que ser más chatas… el cuerpo… muy chato… desproporcionado… las
## piernas deberían ser más grandes, los brazos también… estás usando brazos de placeholder… la baranda también la
## sacaría… dos formas de visualizar… las cabinas… esferas y… cápsulas parciales, partidas de mitad… o medio esferas…
## varias ideas de mechas compuestos en distintos lugares… dame como 30»). Sobre la meca de verdad (sus piernas y sus
## brazos; la caja escondida), un cuerpo de arcilla del tamaño de la caja y cuatro cabinas chatas (azul el movimiento,
## rojas los brazos, amarilla la artillería), cada una con su vidrio. Una persona en el piso, para la escala. Sale en
## hojas de seis. *Con los tropos de las mecas, para que se entienda de un vistazo (el usuario: «siempre manteniendo brazos
## y piernas… trata de jugar con tropes de mechas y no hacer cosas tan raras»): cabezas con visor, bloques de hombro,
## pechos con escotilla, mochilas.*
##   tools/godot_ventana.sh res://tests/cabin_placement_ideas_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const METAL := Color(0.55, 0.57, 0.6)
const DARK := Color(0.32, 0.33, 0.36)
const SHELL := Color(0.62, 0.64, 0.67)
const ROLE := {"walk": Color(0.3, 0.45, 0.75), "arm": Color(0.8, 0.25, 0.2), "gun": Color(0.93, 0.75, 0.16)}
const GLASS := Color(0.55, 0.78, 0.92, 0.55)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _real: Mech = null
var _shell: Node3D = null
## La caja de la meca: medio ancho, medio alto, medio fondo.
var _h := Vector3.ONE


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	_real = Mech.new()
	_real.has_cabin = false
	_real.arms_kind = Mech.Arms.POSE
	_real.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_real)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(9.0, 0.0, -9.0), -PI * 0.75)
	await get_tree().create_timer(2.5).timeout
	_real.freeze = true
	if _real.label != null:
		_real.label.visible = false
	for part in _real.look.get_children():
		if part is MeshInstance3D and (part as MeshInstance3D).mesh is BoxMesh:
			(part as MeshInstance3D).visible = false
	_h = _real.size * 0.5
	var ideas := _ideas()
	var shots: Array = []
	for index in ideas.size():
		var idea: Dictionary = ideas[index]
		if _shell != null:
			_shell.queue_free()
		_shell = Node3D.new()
		_real.look.add_child(_shell)
		_body(idea["body"])
		for cabin: Array in idea["cabins"]:
			_cabin(cabin)
		_title.text = "%d. %s" % [index + 1, idea["name"]]
		var center := _real.global_position
		_eye.global_position = center + Vector3(-12.0, 7.0, -15.0)
		_eye.look_at(center + Vector3(0.0, -1.0, 0.0), Vector3.UP)
		shots.append(await _grab())
	_save(shots)
	get_tree().quit()


## ── LAS IDEAS: el cuerpo y las cabinas [forma, dónde (en partes de la caja: x a la derecha, y arriba, −z adelante),
## radio (m), rol, hacia dónde mira el vidrio (grados, 0 adelante, + a la derecha)] ────────────────────────────────
## Formas: "half" media esfera chata; "sphere" esfera hundida a la mitad; "ball" esfera entera, colgando; "pod" media
## cápsula acostada (de adelante a atrás); "side" media cápsula parada, pegada a una cara; "cap" casquete casi al ras.

func _ideas() -> Array:
	var T := 1.0
	return [
		{"name": "cuatro medias esferas en el techo, en cruz", "body": "box", "cabins": [
			["half", Vector3(0, T, -0.35), 1.5, "walk", 0], ["half", Vector3(-0.55, T, 0.1), 1.2, "arm", -90],
			["half", Vector3(0.55, T, 0.1), 1.2, "arm", 90], ["half", Vector3(0, T, 0.6), 1.2, "gun", 180]]},
		{"name": "esferas en las cuatro esquinas de arriba", "body": "box", "cabins": [
			["sphere", Vector3(-0.8, T, -0.8), 1.3, "walk", -30], ["sphere", Vector3(0.8, T, -0.8), 1.3, "arm", 30],
			["sphere", Vector3(-0.8, T, 0.8), 1.3, "arm", -150], ["sphere", Vector3(0.8, T, 0.8), 1.3, "gun", 150]]},
		{"name": "una esfera grande en el pecho, tres medias arriba", "body": "box", "cabins": [
			["sphere", Vector3(0, 0.1, -1.0), 1.8, "walk", 0], ["half", Vector3(-0.55, T, 0.3), 1.1, "arm", -60],
			["half", Vector3(0.55, T, 0.3), 1.1, "arm", 60], ["half", Vector3(0, T, 0.7), 1.1, "gun", 180]]},
		{"name": "esferas en los hombros, el pecho y la espalda", "body": "box", "cabins": [
			["sphere", Vector3(0, 0.2, -1.0), 1.4, "walk", 0], ["sphere", Vector3(-1.0, 0.6, 0), 1.3, "arm", -90],
			["sphere", Vector3(1.0, 0.6, 0), 1.3, "arm", 90], ["sphere", Vector3(0, 0.3, 1.0), 1.3, "gun", 180]]},
		{"name": "tres medias esferas en fila al frente, una arriba", "body": "box", "cabins": [
			["side", Vector3(-0.55, 0.15, -1.0), 1.0, "arm", 0], ["side", Vector3(0, 0.15, -1.0), 1.1, "walk", 0],
			["side", Vector3(0.55, 0.15, -1.0), 1.0, "arm", 0], ["half", Vector3(0, T, 0.3), 1.3, "gun", 180]]},
		{"name": "cápsulas acostadas en el techo, como torpedos", "body": "box", "cabins": [
			["pod", Vector3(0, T, -0.2), 1.0, "walk", 0], ["pod", Vector3(-0.6, T, 0.1), 0.85, "arm", 0],
			["pod", Vector3(0.6, T, 0.1), 0.85, "arm", 0], ["pod", Vector3(0, T, 0.75), 0.75, "gun", 180]]},
		{"name": "medias cápsulas paradas a los costados, como sidecars", "body": "box", "cabins": [
			["side", Vector3(-1.0, 0.0, -0.3), 1.2, "arm", -90], ["side", Vector3(1.0, 0.0, -0.3), 1.2, "arm", 90],
			["half", Vector3(0, T, -0.3), 1.4, "walk", 0], ["side", Vector3(0, 0.0, 1.0), 1.1, "gun", 180]]},
		{"name": "esferas a los lados de la cintura", "body": "box", "cabins": [
			["sphere", Vector3(-1.0, -0.6, -0.2), 1.3, "arm", -60], ["sphere", Vector3(1.0, -0.6, -0.2), 1.3, "arm", 60],
			["half", Vector3(0, T, -0.3), 1.4, "walk", 0], ["half", Vector3(0, T, 0.6), 1.1, "gun", 180]]},
		{"name": "cabeza con visor y bloques en los hombros", "body": "box", "cabins": [
			["block", Vector3(0, T + 0.45, -0.3), 1.3, "walk", 0], ["block", Vector3(-1.05, T + 0.1, 0), 1.1, "arm", -20],
			["block", Vector3(1.05, T + 0.1, 0), 1.1, "arm", 20], ["half", Vector3(0, T, 0.65), 0.9, "gun", 180]]},
		{"name": "disco, cabinas medias esferas en el canto, en cruz", "body": "disc", "cabins": [
			["side", Vector3(0, 0.1, -1.0), 1.2, "walk", 0], ["side", Vector3(-1.0, 0.1, 0), 1.1, "arm", -90],
			["side", Vector3(1.0, 0.1, 0), 1.1, "arm", 90], ["side", Vector3(0, 0.1, 1.0), 1.1, "gun", 180]]},
		{"name": "disco, tres en el canto y una arriba al medio", "body": "disc", "cabins": [
			["half", Vector3(0, T, 0), 1.5, "walk", 0], ["side", Vector3(-0.87, 0.1, -0.5), 1.1, "arm", -60],
			["side", Vector3(0.87, 0.1, -0.5), 1.1, "arm", 60], ["side", Vector3(0, 0.1, 1.0), 1.1, "gun", 180]]},
		{"name": "en dos pisos: dos abajo al frente, dos arriba", "body": "box", "cabins": [
			["side", Vector3(-0.45, -0.3, -1.0), 1.1, "arm", 0], ["side", Vector3(0.45, -0.3, -1.0), 1.1, "arm", 0],
			["half", Vector3(0, T, -0.4), 1.3, "walk", 0], ["half", Vector3(0, T, 0.5), 1.1, "gun", 180]]},
		{"name": "una cabeza esfera arriba, cabinas en los hombros", "body": "box", "cabins": [
			["ball", Vector3(0, T + 0.5, -0.3), 1.4, "walk", 0], ["half", Vector3(-0.85, T, 0), 1.1, "arm", -90],
			["half", Vector3(0.85, T, 0), 1.1, "arm", 90], ["half", Vector3(0, T, 0.75), 0.9, "gun", 180]]},
		{"name": "un pecho grande al frente, dos en la espalda", "body": "box", "cabins": [
			["side", Vector3(0, 0.0, -1.0), 1.7, "walk", 0], ["side", Vector3(-0.5, 0.2, 1.0), 1.1, "arm", 180],
			["side", Vector3(0.5, 0.2, 1.0), 1.1, "arm", 180], ["half", Vector3(0, T, 0.2), 1.0, "gun", 180]]},
		{"name": "una en cada cara del cuerpo", "body": "box", "cabins": [
			["side", Vector3(0, 0.1, -1.0), 1.3, "walk", 0], ["side", Vector3(-1.0, 0.1, 0), 1.2, "arm", -90],
			["side", Vector3(1.0, 0.1, 0), 1.2, "arm", 90], ["side", Vector3(0, 0.1, 1.0), 1.2, "gun", 180]]},
		{"name": "en las cuatro esquinas verticales", "body": "box", "cabins": [
			["corner", Vector3(-1.0, 0.0, -1.0), 1.2, "walk", -45], ["corner", Vector3(1.0, 0.0, -1.0), 1.2, "arm", 45],
			["corner", Vector3(-1.0, 0.0, 1.0), 1.2, "arm", -135], ["corner", Vector3(1.0, 0.0, 1.0), 1.2, "gun", 135]]},
		{"name": "una bola colgando abajo, como la torreta del B-17", "body": "box", "cabins": [
			["ball", Vector3(0, -T - 0.4, -0.6), 1.2, "gun", 0], ["half", Vector3(0, T, -0.3), 1.4, "walk", 0],
			["half", Vector3(-0.6, T, 0.4), 1.1, "arm", -90], ["half", Vector3(0.6, T, 0.4), 1.1, "arm", 90]]},
		{"name": "el pecho con escotilla (núcleo) y una cabeza", "body": "box", "cabins": [
			["block", Vector3(0, 0.1, -1.0), 1.5, "walk", 0], ["block", Vector3(0, T + 0.45, -0.2), 1.0, "gun", 0],
			["side", Vector3(-1.0, 0.2, 0), 1.0, "arm", -90], ["side", Vector3(1.0, 0.2, 0), 1.0, "arm", 90]]},
		{"name": "una cabeza ancha al frente, como un caminante", "body": "box", "cabins": [
			["block", Vector3(-0.4, T + 0.35, -0.6), 1.1, "arm", 0], ["block", Vector3(0.4, T + 0.35, -0.6), 1.1, "arm", 0],
			["block", Vector3(0, 0.3, -1.0), 1.3, "walk", 0], ["half", Vector3(0, T, 0.55), 1.0, "gun", 180]]},
		{"name": "combinador: cada brazo con su bloque de hombro", "body": "box", "cabins": [
			["block", Vector3(-1.15, 0.55, 0), 1.4, "arm", -10], ["block", Vector3(1.15, 0.55, 0), 1.4, "arm", 10],
			["block", Vector3(0, 0.2, -1.0), 1.3, "walk", 0], ["block", Vector3(0, T + 0.4, 0.2), 1.0, "gun", 0]]},
		{"name": "un visor corrido en el pecho, partido en cuatro", "body": "box", "cabins": [
			["side", Vector3(-0.66, 0.35, -1.0), 0.85, "arm", 0], ["side", Vector3(-0.22, 0.35, -1.0), 0.85, "walk", 0],
			["side", Vector3(0.22, 0.35, -1.0), 0.85, "gun", 0], ["side", Vector3(0.66, 0.35, -1.0), 0.85, "arm", 0]]},
		{"name": "cabinas encima de las articulaciones de los hombros", "body": "box", "cabins": [
			["half", Vector3(-1.05, T, 0), 1.2, "arm", -90], ["half", Vector3(1.05, T, 0), 1.2, "arm", 90],
			["sphere", Vector3(0, 0.3, -1.0), 1.4, "walk", 0], ["half", Vector3(0, T, 0.5), 1.0, "gun", 180]]},
		{"name": "canopias de caza en tándem, dos y dos", "body": "box", "cabins": [
			["pod", Vector3(-0.4, T, -0.35), 0.85, "walk", 0], ["pod", Vector3(0.4, T, -0.35), 0.85, "arm", 0],
			["pod", Vector3(-0.4, T, 0.45), 0.85, "arm", 0], ["pod", Vector3(0.4, T, 0.45), 0.85, "gun", 0]]},
		{"name": "ancho y bajo, cuatro cúpulas en línea como un tanque", "body": "wide", "cabins": [
			["half", Vector3(-0.75, T, 0), 1.0, "arm", -90], ["half", Vector3(-0.25, T, 0), 1.0, "walk", 0],
			["half", Vector3(0.25, T, 0), 1.0, "gun", 0], ["half", Vector3(0.75, T, 0), 1.0, "arm", 90]]},
		{"name": "torretas: medias esferas con su caño", "body": "box", "cabins": [
			["turret", Vector3(0, T, -0.3), 1.4, "walk", 0], ["turret", Vector3(-0.6, T, 0.35), 1.1, "arm", -40],
			["turret", Vector3(0.6, T, 0.35), 1.1, "arm", 40], ["turret", Vector3(0, T, 0.8), 1.0, "gun", 180]]},
		{"name": "una grande hundida al medio, tres en pétalo", "body": "disc", "cabins": [
			["sphere", Vector3(0, T, 0), 1.8, "walk", 0], ["half", Vector3(-0.75, T, -0.4), 1.0, "arm", -60],
			["half", Vector3(0.75, T, -0.4), 1.0, "arm", 60], ["half", Vector3(0, T, 0.85), 1.0, "gun", 180]]},
		{"name": "disco grueso, casquetes casi al ras", "body": "disc", "cabins": [
			["cap", Vector3(0, T, -0.3), 1.6, "walk", 0], ["cap", Vector3(-0.6, T, 0.2), 1.3, "arm", -90],
			["cap", Vector3(0.6, T, 0.2), 1.3, "arm", 90], ["cap", Vector3(0, T, 0.75), 1.2, "gun", 180]]},
		{"name": "cabeza, pecho y una mochila con dos cabinas", "body": "box", "cabins": [
			["block", Vector3(0, T + 0.45, -0.3), 1.1, "walk", 0], ["block", Vector3(0, 0.0, -1.0), 1.2, "gun", 0],
			["block", Vector3(-0.45, 0.4, 1.15), 1.0, "arm", 180], ["block", Vector3(0.45, 0.4, 1.15), 1.0, "arm", 180]]},
		{"name": "asimétrica: una grande adelante a la izquierda", "body": "box", "cabins": [
			["sphere", Vector3(-0.45, 0.4, -1.0), 1.7, "walk", -10], ["half", Vector3(0.45, T, -0.2), 1.0, "arm", 30],
			["half", Vector3(0.6, T, 0.5), 0.9, "arm", 90], ["half", Vector3(-0.3, T, 0.6), 0.9, "gun", 180]]},
		{"name": "en escalera: cada una un poco más alta hacia atrás", "body": "box", "cabins": [
			["half", Vector3(0, T, -0.7), 1.1, "walk", 0], ["half", Vector3(-0.45, T + 0.25, -0.1), 1.0, "arm", -90],
			["half", Vector3(0.45, T + 0.25, -0.1), 1.0, "arm", 90], ["half", Vector3(0, T + 0.5, 0.55), 1.0, "gun", 180]]},
	]


## ── EL CUERPO (del tamaño de la caja de la meca) ─────────────────────────────────────────────────────────────────

func _body(kind: String) -> void:
	match kind:
		"box":
			Clay.box(_shell, _h * 2.0, Vector3.ZERO, SHELL)
			Clay.box(_shell, Vector3(_h.x * 2.0 + 0.1, 0.3, _h.z * 2.0 + 0.1), Vector3(0, -_h.y + 0.15, 0), DARK)
		"disc":
			_cyl(_shell, _h.x * 1.05, _h.y * 2.0, Vector3.ZERO, SHELL, 64)
			_cyl(_shell, _h.x * 1.08, 0.3, Vector3(0, -_h.y + 0.15, 0), DARK, 64)
		"sphere":
			Clay.sphere(_shell, _h.x * 1.1, Vector3(0, -0.3, 0), SHELL)
		"tower":
			_cyl(_shell, _h.x * 0.75, _h.y * 3.0, Vector3(0, _h.y * 0.5, 0), SHELL, 48)
		"dome":
			_cyl(_shell, _h.x * 1.05, _h.y, Vector3(0, -_h.y * 0.5, 0), SHELL, 64)
			var dome := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = _h.x * 1.05
			sphere.height = _h.x * 1.05
			sphere.is_hemisphere = true
			dome.mesh = sphere
			dome.material_override = Clay.material(SHELL)
			_shell.add_child(dome)
		"long":
			Clay.box(_shell, Vector3(_h.x * 1.4, _h.y * 2.0, _h.z * 2.6), Vector3.ZERO, SHELL)
		"wide":
			Clay.box(_shell, Vector3(_h.x * 2.6, _h.y * 1.4, _h.z * 1.6), Vector3(0, -_h.y * 0.3, 0), SHELL)
		"hex":
			_cyl(_shell, _h.x * 1.1, _h.y * 2.0, Vector3.ZERO, SHELL, 6)


## ── LAS CABINAS ──────────────────────────────────────────────────────────────────────────────────────────────────

func _cabin(cabin: Array) -> void:
	var kind: String = cabin[0]
	var where: Vector3 = cabin[1]
	var radius: float = cabin[2]
	var role: String = cabin[3]
	var facing := deg_to_rad(float(cabin[4]))
	var at := Vector3(where.x * _h.x, where.y * _h.y, where.z * _h.z)
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = -facing
	_shell.add_child(holder)
	# Del color de su puesto, aclarado: que se lea de un vistazo cuál es cuál.
	var paint := (ROLE[role] as Color).lerp(Color.WHITE, 0.45)
	match kind:
		"half", "turret":
			_dome(holder, radius, 0.55, paint)
			_window(holder, radius, 0.35, 0.28)
			if kind == "turret":
				Clay.cylinder(holder, 0.14, radius * 1.6, Vector3(0, radius * 0.3, -radius * 1.3), DARK, Vector3(90, 0, 0))
		"sphere":
			Clay.sphere(holder, radius, Vector3.ZERO, paint)
			_window(holder, radius, 0.2, 0.32)
		"ball":
			Clay.sphere(holder, radius, Vector3.ZERO, paint)
			_window(holder, radius, 0.0, 0.4)
			_cyl(holder, 0.3, 0.8, Vector3(0, radius + 0.2 * signf(-where.y), 0), DARK, 12)
		"cap":
			_dome(holder, radius, 0.3, paint)
			_window(holder, radius, 0.12, 0.2)
		"pod":
			var pod := Clay.cylinder(holder, radius, radius * 2.6, Vector3(0, 0, 0), paint, Vector3(90, 0, 0))
			(pod.mesh as CylinderMesh).radial_segments = 32
			pod.scale = Vector3(1.0, 1.0, 0.6)
			Clay.sphere(holder, radius, Vector3(0, 0, -radius * 1.3), paint).scale = Vector3(1, 0.6, 1)
			_window(holder, radius, 0.25, 0.25, -radius * 0.6)
		"side":
			var half := Clay.cylinder(holder, radius, radius * 1.4, Vector3(0, 0, 0), paint)
			(half.mesh as CylinderMesh).radial_segments = 32
			half.scale = Vector3(1.0, 1.0, 0.55)
			_window(holder, radius * 0.55, 0.1, 0.3)
		"block":
			# Un bloque redondeado, como una cabeza o un hombro de meca, con un visor corrido.
			Clay.box(holder, Vector3(radius * 1.6, radius * 0.9, radius * 1.4), Vector3.ZERO, paint)
			Clay.box(holder, Vector3(radius * 1.7, radius * 0.25, radius * 1.2), Vector3(0, radius * 0.5, 0.05), paint.darkened(0.1))
			_window(holder, radius * 0.72, 0.15, 0.4)
		"corner":
			var quarter := Clay.cylinder(holder, radius, _h.y * 1.6, Vector3.ZERO, paint)
			(quarter.mesh as CylinderMesh).radial_segments = 32
			_window(holder, radius, 0.1, 0.3)
	# La franja de su color.
	Clay.box(holder, Vector3(radius * 0.9, 0.12, 0.12), Vector3(0, radius * 0.08, radius * 0.6), ROLE[role])


## Una media esfera achatada (`squash` de alto), de radio `radius`.
func _dome(holder: Node3D, radius: float, squash: float, paint: Color) -> void:
	var dome := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius
	sphere.is_hemisphere = true
	dome.mesh = sphere
	dome.scale = Vector3(1.0, squash * 2.0, 1.0)
	dome.material_override = Clay.material(paint)
	holder.add_child(dome)


## El vidrio: una franja curva al frente (−z del que la tiene), a `height` de alto y de `tall` de alto (en partes del
## radio).
func _window(holder: Node3D, radius: float, height: float, tall: float, ahead := 0.0) -> void:
	var glass := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(radius * 1.4, radius * tall * 1.5, 0.05)
	glass.mesh = box
	var paint := StandardMaterial3D.new()
	paint.albedo_color = GLASS
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.roughness = 0.1
	glass.material_override = paint
	glass.position = Vector3(0, radius * height, -radius * 0.98 + ahead)
	holder.add_child(glass)


func _cyl(parent: Node3D, radius: float, tall: float, at: Vector3, color: Color, sides: int) -> void:
	var part := Clay.cylinder(parent, radius, tall, at, color)
	(part.mesh as CylinderMesh).radial_segments = sides


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
	_eye.fov = 45.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 46)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 12)
	layer.add_child(_title)


## Hojas de seis (dos por tres), para mirar desde el teléfono.
func _save(shots: Array) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first: Image = shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	for sheet_index in ceili(shots.size() / 6.0):
		var sheet := Image.create(w * 2, h * 3, false, first.get_format())
		for k in 6:
			var index := sheet_index * 6 + k
			if index >= shots.size():
				break
			var shot: Image = (shots[index] as Image).duplicate()
			shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
			sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (k % 2), h * (k / 2)))
		var path := "%s/cabinas_ideas_%d.png" % [_folder, sheet_index + 1]
		sheet.save_png(path)
		print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
