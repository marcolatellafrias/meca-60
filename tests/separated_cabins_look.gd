extends Node3D

## LA MECA DE CABINAS SEPARADAS, MAQUETA DE ARCILLA (15/11/2026, el camino 2 de docs/conceptual/dos-paradigmas.md).
## Sale de la 1 de `tests/cabin_pods_look` y de la 1 de `tests/four_cabins_look` (hombros al costado, torreta arriba):
## cada jugador se mete en su cabina con una tecla (sin caminar adentro, sin puertas ni pasarelas), sentado; las
## cuatro cabinas son piezas del cuerpo (las piernas, cada brazo, la artillería). LAS PIERNAS VAN APARTE DEL TORSO: el
## torso gira sobre un aro en la cintura (en todas, girado 35° respecto de las piernas), con el límite marcado en el
## aro (la marca amarilla es adonde miran las piernas; las rojas, hasta dónde puede girar el torso). Las baterías,
## AFUERA (cubos verdes de 63 cm).
##   1 · la base: el de las piernas en el torso, baterías en la espalda;
##   2 · el de las piernas en la pelvis, abajo del aro (gira con las piernas); el torso, al centro, sólo el conector;
##   3 · como la 2, sin torreta: la artillería al centro del torso, los cohetes en los hombros;
##   4 · como la 2, los hombros ajustados a su cabina;
##   5 · el de las piernas en una góndola colgada entre las piernas;
##   6 · como la 2, las baterías alrededor de la pelvis;
##   7 · como la 2, las baterías en las canillas, a mano desde el piso.
##   8 · la 1, con las cabinas empotradas: el frente de cada cabina al ras de su parte;
##   9 · la 8 sin cabeza: el pecho más alto, el de las piernas abajo y el artillero arriba.
##   tools/godot_ventana.sh res://tests/separated_cabins_look.tscn -- --salida=C:/carpeta --variante=1

const VIEW := Vector2i(1280, 720)
const WALL := 0.1
const TORSO := Vector3(3.2, 2.8, 2.6)
const SHOULDER := Vector3(2.2, 2.2, 2.4)
const TURRET := Vector3(2.0, 1.8, 2.2)
## Sin cabeza (la 9): el pecho con dos cabinas, una encima de otra.
const CHEST_HIGH := 3.6
## La cabina de uno, sentado: por fuera.
const POD := Vector3(1.2, 1.6, 1.5)
## Cuánto asoma la cabina del frente de su parte.
const POKE := 1.4
## Cuánto está girado el torso respecto de las piernas, y hasta dónde podría.
const TWIST := -35.0
const TWIST_LIMIT := 90.0
const RING := Vector2(1.35, 0.35)
const BATTERY := 0.63

## waist: el alto del aro (abajo del torso); legs: dónde va el de las piernas (torso, pelvis, góndola); gun: torreta o
## al centro del torso; shoulder: el tamaño del hombro; battery: espalda, cintura o canillas.
const VARIANTS := {
	1: {"name": "la base: piernas en el torso", "waist": 3.9, "legs": "torso", "gun": "turret",
		"shoulder": SHOULDER, "battery": "back"},
	2: {"name": "piernas en la pelvis, conector al centro", "waist": 5.0, "legs": "pelvis", "gun": "turret",
		"shoulder": SHOULDER, "battery": "back"},
	3: {"name": "artillería al centro, cohetes en los hombros", "waist": 5.0, "legs": "pelvis", "gun": "torso",
		"shoulder": SHOULDER, "battery": "back"},
	4: {"name": "hombros ajustados a su cabina", "waist": 5.0, "legs": "pelvis", "gun": "turret",
		"shoulder": Vector3(1.6, 2.0, 1.9), "battery": "back"},
	5: {"name": "piernas en una góndola colgada", "waist": 4.8, "legs": "gondola", "gun": "turret",
		"shoulder": SHOULDER, "battery": "back"},
	6: {"name": "baterías alrededor de la pelvis", "waist": 5.0, "legs": "pelvis", "gun": "turret",
		"shoulder": SHOULDER, "battery": "waist"},
	7: {"name": "baterías en las canillas, desde el piso", "waist": 5.0, "legs": "pelvis", "gun": "turret",
		"shoulder": SHOULDER, "battery": "shins"},
	8: {"name": "la 1, con las cabinas empotradas", "waist": 3.9, "legs": "torso", "gun": "turret",
		"shoulder": SHOULDER, "battery": "back", "flush": true},
	9: {"name": "sin cabeza: piernas abajo y artillero arriba, en el pecho", "waist": 3.9, "legs": "torso",
		"gun": "chest", "shoulder": SHOULDER, "battery": "back", "flush": true},
}

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const FLOOR := Color(0.68, 0.69, 0.71)
const SKIN := Color(0.86, 0.66, 0.5)
const SEAT := Color(0.25, 0.42, 0.7)
const CELL := Color(0.36, 0.58, 0.36)
const CORE := Color(0.95, 0.8, 0.3)
const LIMIT := Color(0.8, 0.22, 0.18)
const ACCENT := {"walk": Color(0.3, 0.45, 0.75), "arm": Color(0.8, 0.25, 0.2), "gun": Color(0.93, 0.75, 0.16)}

var _folder := ""
var _variant := 1
var _plan: Dictionary = {}
var _eye: Camera3D = null
var _title: Label = null
var _glass := StandardMaterial3D.new()
## Lo que gira con el torso.
var _upper := Node3D.new()


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
	get_window().size = VIEW
	_plan = VARIANTS[_variant]
	_glass.albedo_color = Color(0.7, 0.85, 0.95, 0.15)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass.roughness = 0.1
	_stage()
	add_child(_upper)
	_upper.rotation_degrees.y = TWIST
	var top := _mech()
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(4.8, 0.0, -3.2), -PI * 0.7)
	await get_tree().create_timer(3.0).timeout
	_title.text = "%d. %s" % [_variant, _plan["name"]]
	var middle := top * 0.5
	var k := top / 9.0
	var shots: Array = []
	for view: Array in [
			[Vector3(-9.0, 7.5, -13.0) * k, Vector3(0.0, middle, 0.0), 45.0],
			[Vector3(0.0, middle + 1.0, -17.0 * k), Vector3(0.0, middle, 0.0), 42.0],
			[Vector3(10.0, 8.0, 12.0) * k, Vector3(0.0, middle, 0.0), 45.0],
			[Vector3(-7.0, 1.2, -9.0) * k, Vector3(0.0, float(_plan["waist"]), 0.0), 48.0]]:
		_look(view[0], view[1], view[2])
		shots.append(await _grab())
	_save(shots)
	get_tree().quit()


## ── LA MECA ──────────────────────────────────────────────────────────────────────────────────────────────────────

## Devuelve el alto de arriba de todo.
func _mech() -> float:
	var waist: float = _plan["waist"]
	var legs: String = _plan["legs"]
	var ring_bottom := waist - RING.y
	# El aro de la cintura, con sus marcas de giro (en el marco de las piernas).
	Clay.cylinder(self, RING.x, RING.y, Vector3(0.0, waist - RING.y * 0.5, 0.0), DARK_METAL)
	_tick(0.0, CORE)
	_tick(TWIST_LIMIT, LIMIT)
	_tick(-TWIST_LIMIT, LIMIT)
	# La pelvis, abajo del aro: con la cabina de las piernas adentro, una placa, o una góndola colgada.
	var hip := ring_bottom
	match legs:
		"pelvis":
			var pelvis := Vector3(2.8, 1.9, 2.2)
			hip = ring_bottom - pelvis.y
			Clay.box(self, pelvis, Vector3(0.0, ring_bottom - pelvis.y * 0.5, 0.0), METAL)
			_pod(self, Vector3(0.0, hip + 0.1, -pelvis.z * 0.5 - POKE + POD.z * 0.5), "walk")
		"gondola":
			var plate := Vector3(3.0, 0.7, 1.8)
			hip = ring_bottom - plate.y
			Clay.box(self, plate, Vector3(0.0, ring_bottom - plate.y * 0.5, 0.0), METAL)
			# La góndola: una caja colgada entre las piernas, con su cabina asomando adelante.
			var gondola := Vector3(1.5, 1.8, 1.6)
			Clay.box(self, Vector3(0.3, 0.4, 0.3), Vector3(0.0, hip - 0.2, 0.0), DARK_METAL)
			Clay.box(self, gondola, Vector3(0.0, hip - 0.4 - gondola.y * 0.5, 0.0), METAL)
			_pod(self, Vector3(0.0, hip - 0.4 - gondola.y + 0.1, -gondola.z * 0.5 - 1.0 + POD.z * 0.5), "walk")
		_:
			var plate := Vector3(2.8, 0.6, 1.8)
			hip = ring_bottom - plate.y
			Clay.box(self, plate, Vector3(0.0, ring_bottom - plate.y * 0.5, 0.0), METAL)
	var spread := 1.5 if legs == "gondola" else 1.05
	for side: float in [-1.0, 1.0]:
		var from := Vector3(side * spread, hip + 0.1, 0.0)
		var foot := Vector3(side * (spread + 0.1), 0.4, 0.0)
		var knee := Vector3(foot.x, (from.y + foot.y) * 0.5, -0.4)
		_bar(self, from, knee, 0.85, METAL)
		_bar(self, knee, foot, 0.75, METAL)
		Clay.box(self, Vector3(0.95, 0.95, 0.95), knee, DARK_METAL)
		Clay.box(self, Vector3(1.0, 0.4, 1.6), Vector3(foot.x, 0.2, -0.3), DARK_METAL)
		if _plan["battery"] == "shins":
			_shin_cells(side, knee, foot)
	return _torso(waist)


## Lo que gira: el torso, los hombros con sus brazos, la torreta, las baterías de la espalda. Devuelve el alto de arriba.
func _torso(waist: float) -> float:
	var up := _upper
	var legs: String = _plan["legs"]
	var gun: String = _plan["gun"]
	var floor_y := waist + 0.7
	var torso_center := Vector3(0.0, waist + TORSO.y * 0.5, 0.0)
	if gun == "chest":
		# SIN CABEZA: el pecho más alto, con el de las piernas abajo y el artillero arriba.
		var chest := Vector3(TORSO.x, CHEST_HIGH, TORSO.z)
		torso_center = Vector3(0.0, waist + chest.y * 0.5, 0.0)
		var lower := waist + 0.2
		_housed(up, chest, torso_center, [lower, lower + POD.y + 0.15], ["walk", "gun"])
		# Los dos caños del artillero, sobre el techo del pecho.
		for side: float in [-1.0, 1.0]:
			var at := Vector3(side * 1.1, waist + chest.y + 0.3, -0.2)
			Clay.box(up, Vector3(0.5, 0.6, 1.2), at, DARK_METAL)
			Clay.box(up, Vector3(0.3, 0.3, 2.2), at + Vector3(0.0, 0.0, -1.7), DARK_METAL)
	elif legs == "torso":
		_housed(up, TORSO, torso_center, [floor_y], ["walk"])
	elif gun == "torso":
		_housed(up, TORSO, torso_center, [floor_y], ["gun"])
	else:
		Clay.box(up, TORSO, torso_center, METAL)
		# El conector: una tapa oscura con el núcleo, al centro del frente.
		Clay.box(up, Vector3(1.4, 1.4, 0.2), Vector3(0.0, waist + TORSO.y * 0.5, -TORSO.z * 0.5 - 0.1), DARK_METAL)
		Clay.box(up, Vector3(0.6, 0.6, 0.12), Vector3(0.0, waist + TORSO.y * 0.5, -TORSO.z * 0.5 - 0.25), CORE)
	var shoulder: Vector3 = _plan["shoulder"]
	var top := waist + (CHEST_HIGH + 0.6 if gun == "chest" else TORSO.y)
	for side: float in [-1.0, 1.0]:
		var center := Vector3(side * (TORSO.x + shoulder.x) * 0.5, waist + 1.8, 0.0)
		_housed(up, shoulder, center, [floor_y], ["arm"], POKE - (SHOULDER.z - shoulder.z) * 0.5)
		var from := center + Vector3(side * 0.4, -shoulder.y * 0.5, 0.3)
		var elbow := Vector3(from.x + side * 0.3, from.y - 2.2, 0.5)
		var fist := elbow + Vector3(0.0, -0.3, -1.5)
		_bar(up, from, elbow, 0.75, METAL)
		_bar(up, elbow, fist, 0.7, METAL)
		Clay.box(up, Vector3(0.95, 0.95, 1.05), fist, DARK_METAL)
		if gun == "torso":
			# Los cohetes: una caja de tubos arriba de cada hombro.
			var rack := center + Vector3(0.0, shoulder.y * 0.5 + 0.35, 0.2)
			Clay.box(up, Vector3(1.4, 0.7, 1.6), rack, DARK_METAL)
			for x: float in [-0.4, 0.0, 0.4]:
				for y: float in [-0.15, 0.15]:
					Clay.box(up, Vector3(0.24, 0.24, 0.1), rack + Vector3(x, y, -0.82), ACCENT["gun"])
			top = maxf(top, rack.y + 0.35)
	if gun == "turret":
		var turret_center := Vector3(0.0, waist + TORSO.y + TURRET.y * 0.5, 0.1)
		_housed(up, TURRET, turret_center, [waist + TORSO.y + 0.1], ["gun"])
		for side: float in [-1.0, 1.0]:
			var at := turret_center + Vector3(side * (TURRET.x * 0.5 + 0.25), 0.1, -0.2)
			Clay.box(up, Vector3(0.5, 0.6, 1.2), at, DARK_METAL)
			Clay.box(up, Vector3(0.3, 0.3, 2.2), at + Vector3(0.0, 0.0, -1.7), DARK_METAL)
		top = turret_center.y + TURRET.y * 0.5
	match _plan["battery"]:
		"back":
			_back_cells(waist)
		"waist":
			_waist_cells(waist)
	return top


## UNA PARTE DEL CUERPO CON SUS CABINAS al frente, centradas de lado, una encima de otra, de pisos en `floors` (de abajo
## arriba) y puestos en `roles`: asomando `poke` (las 1 a 7) o EMPOTRADAS (la 8 en adelante): la parte se arma
## alrededor de nichos del tamaño de la cabina y el frente de cada cabina queda al ras del frente de la parte (el
## usuario: «la 1 pero que no sobresalgan, que estén empotrados»).
func _housed(parent: Node3D, size: Vector3, center: Vector3, floors: Array, roles: Array, poke := POKE) -> void:
	if not _plan.get("flush", false):
		Clay.box(parent, size, center, METAL)
		for index in floors.size():
			_pod(parent, Vector3(center.x, floors[index], center.z - size.z * 0.5 - poke + POD.z * 0.5), roles[index])
		return
	var front := center.z - size.z * 0.5
	var slab_z := front + POD.z * 0.5
	# Atrás de los nichos, macizo.
	Clay.box(parent, Vector3(size.x, size.y, size.z - POD.z), Vector3(center.x, center.y, front + POD.z
		+ (size.z - POD.z) * 0.5), METAL)
	# A los costados de los nichos, de arriba abajo.
	var side_width := (size.x - POD.x) * 0.5
	for side: float in [-1.0, 1.0]:
		Clay.box(parent, Vector3(side_width, size.y, POD.z), Vector3(center.x + side * (POD.x + side_width) * 0.5,
			center.y, slab_z), METAL)
	# Entre los nichos (y abajo del primero y arriba del último), relleno.
	var from := center.y - size.y * 0.5
	for index in floors.size() + 1:
		var to: float = floors[index] if index < floors.size() else center.y + size.y * 0.5
		if to - from > 0.01:
			Clay.box(parent, Vector3(POD.x, to - from, POD.z), Vector3(center.x, (from + to) * 0.5, slab_z), METAL)
		if index < floors.size():
			_pod(parent, Vector3(center.x, floors[index], slab_z), roles[index])
			from = float(floors[index]) + POD.y


## UNA CABINA DE UNO, de piso en `base`: piso, techo y fondo de metal, costados y frente de vidrio sobre un antepecho,
## la franja de su puesto y el piloto sentado. Sin puerta: se entra con una tecla.
func _pod(parent: Node3D, base: Vector3, role: String) -> void:
	var half := POD * 0.5
	var center := base + Vector3(0.0, half.y, 0.0)
	var sill := 0.45
	Clay.box(parent, Vector3(POD.x, WALL, POD.z), center + Vector3(0.0, -half.y + WALL * 0.5, 0.0), FLOOR)
	Clay.box(parent, Vector3(POD.x, WALL * 1.5, POD.z), center + Vector3(0.0, half.y - WALL * 0.75, 0.0), METAL)
	Clay.box(parent, Vector3(POD.x, POD.y, WALL), center + Vector3(0.0, 0.0, half.z - WALL * 0.5), METAL)
	for x: float in [-1.0, 1.0]:
		Clay.box(parent, Vector3(0.12, POD.y, 0.12), center + Vector3(x * (half.x - 0.06), 0.0, -half.z + 0.06), METAL)
	for wall: Array in [[Vector3(0, 0, -1), POD.x], [Vector3(-1, 0, 0), POD.z], [Vector3(1, 0, 0), POD.z]]:
		var out: Vector3 = wall[0]
		var width: float = wall[1]
		var reach := absf(out.dot(half))
		var turn := Basis(Vector3.UP, PI * 0.5) if absf(out.x) > 0.5 else Basis()
		var low := Clay.box(parent, Vector3(width, sill, WALL), center + out * (reach - WALL * 0.5)
			+ Vector3(0.0, -half.y + sill * 0.5, 0.0), METAL)
		low.basis = turn
		var pane := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(width - 0.2, POD.y - sill - WALL * 1.5, 0.03)
		pane.mesh = mesh
		pane.material_override = _glass
		pane.basis = turn
		pane.position = center + out * (reach - 0.04) + Vector3(0.0, -half.y + sill + (POD.y - sill - WALL * 1.5) * 0.5,
			0.0)
		parent.add_child(pane)
	Clay.box(parent, Vector3(POD.x + 0.02, 0.12, POD.z + 0.02), center + Vector3(0.0, half.y - 0.2, 0.0), ACCENT[role])
	_seated(parent, base + Vector3(0.0, WALL, 0.2))
	Clay.box(parent, Vector3(0.6, 0.08, 0.22), base + Vector3(0.0, 0.62, -half.z + 0.3), DARK_METAL)


## UN PILOTO SENTADO, de arcilla, mirando adelante (−Z), con su asiento: `at`, el piso debajo del asiento.
func _seated(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(parent, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), SEAT)
	Clay.box(parent, Vector3(0.08, 0.42, 0.08), at + Vector3(0.0, 0.21, 0.05), DARK_METAL)
	Clay.box(parent, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(parent, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(parent, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(parent, Vector3(0.12, 0.42, 0.12), at + Vector3(side * 0.1, 0.27, -0.28), SKIN)
		Clay.box(parent, Vector3(0.1, 0.1, 0.38), at + Vector3(side * 0.24, 0.8, -0.12), SKIN)


## Una marca en el canto del aro, a `degrees` del frente de las piernas.
func _tick(degrees: float, color: Color) -> void:
	var angle := deg_to_rad(degrees)
	var out := Vector3(-sin(angle), 0.0, -cos(angle))
	var mark := Clay.box(self, Vector3(0.18, RING.y + 0.04, 0.3), out * RING.x + Vector3(0.0, float(_plan["waist"])
		- RING.y * 0.5, 0.0), color)
	mark.basis = Basis(Vector3.UP, angle)


## UNA BATERÍA: un cubo verde con su borne arriba.
func _cell(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3.ONE * BATTERY, at, CELL)
	Clay.box(parent, Vector3(0.2, 0.08, 0.2), at + Vector3(0.0, BATTERY * 0.5 + 0.04, 0.0), DARK_METAL)


## Las baterías en la espalda: un bastidor de dos por dos, colgado atrás del torso.
func _back_cells(waist: float) -> void:
	var back := TORSO.z * 0.5
	Clay.box(_upper, Vector3(1.7, 1.7, 0.12), Vector3(0.0, waist + 1.4, back + 0.06), DARK_METAL)
	for x: float in [-0.4, 0.4]:
		for y: float in [-0.4, 0.4]:
			_cell(_upper, Vector3(x, waist + 1.4 + y, back + 0.12 + BATTERY * 0.5))


## Las baterías alrededor de la pelvis (no giran): seis en un estante bajo el aro.
func _waist_cells(waist: float) -> void:
	var y := waist - RING.y - 0.6
	for x: float in [-1.0, 0.0, 1.0]:
		_cell(self, Vector3(x * 0.8, y, 1.1 + BATTERY * 0.5))
	for side: float in [-1.0, 1.0]:
		for z: float in [-0.45, 0.45]:
			_cell(self, Vector3(side * (1.4 + BATTERY * 0.5), y, z))


## Las baterías en la canilla, por fuera: dos en una cuna, a la altura de la mano de uno parado en el piso.
func _shin_cells(side: float, knee: Vector3, foot: Vector3) -> void:
	var x := foot.x + side * (0.4 + BATTERY * 0.5)
	for index in 2:
		var y := 0.9 + index * (BATTERY + 0.05) + BATTERY * 0.5
		var z := lerpf(foot.z, knee.z, (y - foot.y) / (knee.y - foot.y))
		_cell(self, Vector3(x, y, z))
	Clay.box(self, Vector3(0.1, BATTERY * 2.3, 0.7), Vector3(x + side * (BATTERY * 0.5 + 0.05), 0.9 + BATTERY + 0.05,
		-0.15), DARK_METAL)


## Una barra cuadrada de `a` a `b`, de `thick` de lado.
func _bar(parent: Node3D, a: Vector3, b: Vector3, thick: float, color: Color) -> void:
	var part := Clay.box(parent, Vector3(thick, thick, a.distance_to(b)), (a + b) * 0.5, color)
	part.basis = Basis.looking_at(b - a, Vector3.RIGHT if absf((b - a).normalized().y) > 0.9 else Vector3.UP)


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


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)


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
	var path := "%s/cabinas_separadas_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
