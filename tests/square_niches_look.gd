extends Node3D

## LA MECA CUADRADA DE CABINAS SIN INTERIOR, MAQUETA DE ARCILLA (15/11/2026; sigue la numeración de
## tests/sphere_pods_look). El usuario: «probablemente sea el mejor approach hacer algo más cuadrado, literalmente
## cuadrado, pero con los nuevos puntos de acceso sin poder caminar en el interior… los tres de adelante, que una vez
## adentro se pueden ver entre ellos, pero no pueden tocarle los controles a los otros… cabinas cuadradas cada uno… el
## único que tiene cápsula es el que maneja todo, que es el que va arriba… un cuadrado con tres huecos adelante y el
## resto macizo atrás, y arriba una cápsula». Brazos y piernas como los reales, quietos, sólo para la foto.
##   40 · la caja casi cubo, las tres cabinas con vidrio entre ellas, la cápsula arriba al centro;
##   41 · como la 40, la cápsula arriba adelante, sobre las cabinas;
##   42 · la caja más ancha y baja;
##   43 · como la 40, un solo ventanal corrido al frente (sin parantes entre las cabinas).
## Cada hoja: de frente a la izquierda, de frente, desde la cabina de la izquierda mirando al frente y hacia las otras,
## desde la del medio y desde la cápsula de arriba.
##   tools/godot_ventana.sh res://tests/square_niches_look.tscn -- --salida=C:/carpeta --variante=40

const VIEW := Vector2i(1280, 720)
## size: la caja (ancho, alto, fondo); top: dónde va la cápsula de arriba (0 al centro, 1 sobre las cabinas);
## posts: los parantes de metal entre las cabinas.
## size: la caja, en partes de la de la meca cuadrada de verdad (CabinGrid.box).
const VARIANTS := {
	40: {"name": "la caja de la cuadrada, vidrio entre las cabinas", "size": Vector3(1.0, 1.0, 1.0), "top": 0.0,
		"posts": true},
	41: {"name": "la cápsula de arriba, adelante", "size": Vector3(1.0, 1.0, 1.0), "top": 1.0, "posts": true},
	42: {"name": "caja más ancha y baja", "size": Vector3(1.25, 0.8, 1.0), "top": 0.0, "posts": true},
	43: {"name": "un solo ventanal corrido", "size": Vector3(1.0, 1.0, 1.0), "top": 0.0, "posts": false},
	# DE LA 44 EN ADELANTE: LA CAJA CHICA Y CHATA, justa para las tres cabinas pegadas; LAS DE LOS COSTADOS, CON VIDRIO
	# TAMBIÉN A SU LADO; los hombros, en la parte maciza de atrás (el usuario: «siguen como muy separados los tres de
	# adelante… disminuir el tamaño de la caja… un poco más chato… los de izquierda y de derecha deberían tener vidrio a
	# sus costados, así tienen más visión»). `fit`: la caja sale de las cabinas (`deep`: su fondo, m); `cell` y `gap`:
	# la cabina y el vidrio entre dos.
	44: {"name": "chata, cabinas pegadas, vidrio a los costados", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.2, "top": 0.0, "posts": true, "side_glass": true},
	45: {"name": "como la 44, una sola pecera (sin parantes)", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true},
	46: {"name": "como la 44, más chica todavía", "fit": true, "deep": 3.6, "cell": Vector3(1.25, 1.9, 1.5),
		"gap": 0.12, "top": 0.0, "posts": true, "side_glass": true},
	47: {"name": "como la 44, la cápsula adelante", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.2, "top": 1.0, "posts": true, "side_glass": true},
	# DE LA 48 EN ADELANTE: LA 45 CON BRAZOS Y PIERNAS MÁS CHICOS, todo junto (largo, grosor, pies, la cintura), en
	# partes de los de la meca de hoy (el usuario: «achicar piernas y brazos… varios achiques… hasta qué tanto puedo
	# bajarlo sin que se vea ridículo»).
	48: {"name": "la 45, brazos y piernas al 80 %", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08,
		"top": 0.0, "posts": false, "side_glass": true, "limbs": 0.8},
	49: {"name": "la 45, brazos y piernas al 65 %", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08,
		"top": 0.0, "posts": false, "side_glass": true, "limbs": 0.65},
	50: {"name": "la 45, brazos y piernas al 55 %", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08,
		"top": 0.0, "posts": false, "side_glass": true, "limbs": 0.55},
	51: {"name": "la 45, brazos y piernas al 45 %", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08,
		"top": 0.0, "posts": false, "side_glass": true, "limbs": 0.45},
	# DE LA 53 EN ADELANTE: LA 50 (al 55 %), con brazos y piernas MÁS GRUESOS (`thick`: el grosor, los pies, las manos,
	# en partes de los de hoy, aparte del largo) y LA CINTURA SEPARADA (`waist`: de la caja a la línea de las caderas, m;
	# se ve la columna). Sólo vistas de afuera. El usuario: «los brazos un poco más gruesos… quedaron como muy finitos…
	# la pelvis… antes tenía como una separación… parecía un poco más como un cuerpo humano».
	53: {"name": "la 50, gruesos al 75 %, cintura de 1,2 m", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true, "limbs": 0.55, "thick": 0.75, "waist": 1.2,
		"outside": true},
	54: {"name": "la 50, gruesos al 85 %, cintura de 1,2 m", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true, "limbs": 0.55, "thick": 0.85, "waist": 1.2,
		"outside": true},
	55: {"name": "la 50, gruesos al 75 %, cintura de 1,8 m", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true, "limbs": 0.55, "thick": 0.75, "waist": 1.8,
		"outside": true},
	56: {"name": "la 50, gruesos al 85 %, cintura de 1,8 m", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true, "limbs": 0.55, "thick": 0.85, "waist": 1.8,
		"outside": true},
	# 57 Y 58: EL DIAGRAMA DE AGACHADA, para entrar desde abajo (el usuario: «cómo es tu diagrama de cuando está
	# agachado, qué tanto tienen que saltar los personajes»): la meca agachada (la cintura al `crouch` de la parada, como
	# KinematicSettings.crouch_share), vista de costado y de frente sin perspectiva, con las alturas marcadas y gente
	# debajo: parada con el brazo arriba, y saltando lo de siempre (0,8 m) y lo del que más salta (1,12 m).
	57: {"name": "la 50 agachada", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08, "top": 0.0,
		"posts": false, "side_glass": true, "limbs": 0.55, "crouch": 0.6, "diagram": true},
	58: {"name": "la 55 agachada", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08, "top": 0.0,
		"posts": false, "side_glass": true, "limbs": 0.55, "thick": 0.75, "waist": 1.8, "crouch": 0.6, "diagram": true},
	# DE LA 59 EN ADELANTE: LA 50 CON BRAZOS Y PIERNAS MÁS CHICOS (las caderas también), PERO LA CINTURA IGUAL (la
	# separación de la caja a las caderas, 0,66 m, la de la 50; el usuario: «podés escalar las piernas y brazos… la
	# cadera ya está con el mínimo de gap… no disminuyas más ese gap»). Agachadas (el diagrama) y paradas (de afuera).
	59: {"name": "brazos y piernas al 50 %, agachada", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true, "limbs": 0.5, "waist": 0.66, "crouch": 0.6,
		"diagram": true},
	60: {"name": "brazos y piernas al 45 %, agachada", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true, "limbs": 0.45, "waist": 0.66, "crouch": 0.6,
		"diagram": true},
	61: {"name": "brazos y piernas al 40 %, agachada", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true, "limbs": 0.4, "waist": 0.66, "crouch": 0.6,
		"diagram": true},
	62: {"name": "brazos y piernas al 50 %, parada", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true, "limbs": 0.5, "waist": 0.66, "outside": true},
	63: {"name": "brazos y piernas al 45 %, parada", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true, "limbs": 0.45, "waist": 0.66, "outside": true},
	64: {"name": "brazos y piernas al 40 %, parada", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6),
		"gap": 0.08, "top": 0.0, "posts": false, "side_glass": true, "limbs": 0.4, "waist": 0.66, "outside": true},
	# DE LA 68 EN ADELANTE: LA 50 CON LAS PIERNAS MÁS CORTAS (`legs`: el largo del muslo y la canilla, en partes de las de
	# la 50), el grosor, los brazos y la cintura iguales (el usuario: «las piernas más cortas y con varios grados de
	# corticidad… manteniendo el grosor»). En el título, la panza parada y agachada.
	68: {"name": "piernas al 100 %", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08,
		"top": 0.0, "posts": false, "side_glass": true, "limbs": 0.55, "legs": 1.0, "outside": true},
	69: {"name": "piernas al 85 %", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08,
		"top": 0.0, "posts": false, "side_glass": true, "limbs": 0.55, "legs": 0.85, "outside": true},
	70: {"name": "piernas al 70 %", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08,
		"top": 0.0, "posts": false, "side_glass": true, "limbs": 0.55, "legs": 0.7, "outside": true},
	71: {"name": "piernas al 55 %", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08,
		"top": 0.0, "posts": false, "side_glass": true, "limbs": 0.55, "legs": 0.55, "outside": true},
	72: {"name": "piernas al 40 %", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08,
		"top": 0.0, "posts": false, "side_glass": true, "limbs": 0.55, "legs": 0.4, "outside": true},
	52: {"name": "la 45, brazos y piernas al 35 %", "fit": true, "deep": 4.4, "cell": Vector3(1.4, 2.0, 1.6), "gap": 0.08,
		"top": 0.0, "posts": false, "side_glass": true, "limbs": 0.35},
}
## Una cabina de uno: ancho, alto, fondo (m); el vidrio entre dos (los cambian las de la 44 en adelante).
var CELL := Vector3(1.7, 2.1, 1.8)
var GAP := 0.3
## Dónde arranca el piso de las cabinas, sobre el fondo de la caja; en las chatas, y lo de arriba de las cabinas.
var SILL := 1.0
const FIT_SILL := 0.45
const FIT_ROOF := 0.4
## El marco de la caja a los costados de la fila, en las chatas.
const FIT_SIDE := 0.12
const POD := 0.9

## LAS MEDIDAS DE LA MECA DE VERDAD: las de la cuadrada, como el usuario las tiene guardadas (MechBody, de la forma de
## la cabina). Se llenan en `_ready`.
var REAL_WAIST := 7.4
var REAL_HIP := Vector2(2.7, 1.2)
var REAL_THIGH := 4.4
var REAL_UPPER := 5.5
var REAL_FOREARM := 5.5
var REAL_THICK := 2.1
var REAL_FOOT := Vector3(2.2, 0.7, 3.4)

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const JOINT := Color(0.36, 0.375, 0.4)
const RIM := Color(0.22, 0.23, 0.25)
const SKIN := Color(0.86, 0.66, 0.5)
const SEAT := Color(0.25, 0.42, 0.7)
const SUPPLY_COLORS := [Color(0.72, 0.42, 0.36), Color(0.48, 0.5, 0.36), Color(0.36, 0.55, 0.38)]

var _folder := ""
var _variant := 40
## --agachada: la arma agachada (como KinematicSettings.crouch_share) y saca sólo dos vistas (ver `_ready`).
var _crouched := false
var _plan: Dictionary = {}
var _eye: Camera3D = null
var _title: Label = null
var _glass := StandardMaterial3D.new()
## Los ojos: [ojo, adónde mira, nombre].
var _eyes: Array = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
		if argument == "--agachada":
			_crouched = true
	get_window().size = VIEW
	_plan = VARIANTS[_variant]
	_glass.albedo_color = Color(0.7, 0.85, 0.95, 0.18)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass.roughness = 0.1
	_stage()
	var body := MechBody.current
	REAL_WAIST = body.WAIST
	REAL_HIP = Vector2(body.HIP_X, body.HIP_DROP)
	REAL_THIGH = body.THIGH
	REAL_UPPER = body.UPPER_ARM
	REAL_FOREARM = body.FOREARM
	REAL_THICK = body.LEG_THICKNESS
	REAL_FOOT = body.FOOT_SIZE
	var limbs: float = _plan.get("limbs", 1.0)
	var thick: float = _plan.get("thick", limbs)
	REAL_WAIST *= limbs
	REAL_HIP *= limbs
	REAL_THIGH *= limbs
	REAL_UPPER *= limbs
	REAL_FOREARM *= limbs
	REAL_THICK *= thick
	REAL_FOOT *= thick
	if _plan.has("waist"):
		# La línea de las caderas queda donde estaba (las piernas, iguales); la caja sube.
		var hip_line := REAL_WAIST - REAL_HIP.y
		REAL_HIP = Vector2(REAL_HIP.x * thick / limbs, float(_plan["waist"]))
		REAL_WAIST = hip_line + REAL_HIP.y
	if _plan.has("legs"):
		# Las piernas más cortas: la línea de las caderas baja con ellas; la cintura (de la caja a las caderas), igual.
		var legs: float = _plan["legs"]
		var gap := REAL_HIP.y
		var hip_line := (REAL_WAIST - gap) * legs
		REAL_THIGH *= legs
		REAL_WAIST = hip_line + gap
	var standing_bottom := REAL_WAIST
	if _crouched:
		REAL_WAIST *= KinematicSettings.current.crouch_share
	if _plan.has("crouch"):
		REAL_WAIST *= float(_plan["crouch"])
	var size := Vector3.ZERO
	if _plan.get("fit", false):
		CELL = _plan["cell"]
		GAP = _plan["gap"]
		SILL = FIT_SILL
		size = Vector3(CELL.x * 3.0 + GAP * 2.0 + FIT_SIDE * 2.0, FIT_SILL + CELL.y + FIT_ROOF, float(_plan["deep"]))
	else:
		size = (_plan["size"] as Vector3) * CabinGrid.box()
	print("CAJA ", size, " · CINTURA ", REAL_WAIST, " · BRAZO ", REAL_UPPER, " · MUSLO ", REAL_THIGH)
	var bottom := REAL_WAIST
	var center := Vector3(0.0, bottom + size.y * 0.5, 0.0)
	_mech(center, size)
	_real_legs(bottom)
	if _plan.get("diagram", false):
		_diagram(standing_bottom, bottom, size)
	else:
		PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(5.5, 0.0, -5.0), -PI * 0.75)
	await get_tree().create_timer(3.0).timeout
	_title.text = "%d. %s" % [_variant, _plan["name"]]
	if _plan.has("legs"):
		_title.text = "%d. %s · la panza: parada %.1f m, agachada %.1f m" % [_variant, _plan["name"], standing_bottom,
			standing_bottom * KinematicSettings.current.crouch_share]
	var shots: Array = []
	var middle := (center.y + size.y * 0.5) * 0.5
	# Las chatas, más cerca (la caja es chica): mirando la caja, no el medio de la meca.
	var near := 0.62 if _plan.get("fit", false) else 1.0
	var look_at := lerpf(middle, center.y, 0.5) if _plan.get("fit", false) else middle
	shots.append(await _view(Vector3(-17.0, 6.0, -24.0) * near + Vector3(0.0, look_at, 0.0), Vector3(0.0, look_at, 0.0),
		45.0))
	shots.append(await _view(Vector3(0.0, 3.0, -30.0) * near + Vector3(0.0, look_at, 0.0), Vector3(0.0, look_at, 0.0),
		42.0))
	if _plan.has("legs"):
		# DOS VISTAS POR POSICIÓN (el usuario: «con 2 ángulos por posición, agachado y parado, está bien»): de frente a la
		# izquierda y de costado; la hoja la arma afuera, una fila parada y otra agachada.
		shots.clear()
		var where := "agachada" if _crouched else "parada"
		_title.text = "%d. %s, %s · la panza a %.1f m" % [_variant, _plan["name"], where, REAL_WAIST]
		var aim := Vector3(0.0, 3.2, 0.0)
		shots.append(await _view(aim + Vector3(-10.5, 3.5, -15.0), aim, 45.0))
		shots.append(await _view(aim + Vector3(-22.0, 1.0, -1.5), aim, 42.0))
		var row := Image.create(VIEW.x, VIEW.y / 2, false, (shots[0] as Image).get_format())
		for index in 2:
			var shot: Image = shots[index]
			shot.resize(VIEW.x / 2, VIEW.y / 2, Image.INTERPOLATE_BILINEAR)
			row.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(VIEW.x / 2 * index, 0))
		if not _folder.is_empty():
			row.save_png("%s/piernas_%d_%s.png" % [_folder, _variant, where])
			print("CAPTURA ", where)
		get_tree().quit()
		return
	if _plan.get("diagram", false):
		# Sin perspectiva: de costado y de frente.
		shots.clear()
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.size = 10.0
		_title.text = "%d. %s, de costado" % [_variant, _plan["name"]]
		shots.append(await _view(Vector3(-30.0, 3.4, 3.4), Vector3(0.0, 3.4, 3.4), 40.0))
		_title.text = "%d. %s, de frente" % [_variant, _plan["name"]]
		shots.append(await _view(Vector3(-3.4, 3.4, -30.0), Vector3(-3.4, 3.4, 0.0), 40.0))
	elif _plan.get("outside", false):
		# Sólo de afuera: de costado (la cintura) y de atrás.
		shots.append(await _view(Vector3(-40.0, 3.0, -2.0) * near + Vector3(0.0, look_at, 0.0), Vector3(0.0, look_at, 0.0),
			42.0))
		shots.append(await _view(Vector3(17.0, 6.0, 24.0) * near + Vector3(0.0, look_at, 0.0), Vector3(0.0, look_at, 0.0),
			45.0))
	else:
		for eye: Array in _eyes:
			_title.text = "%d. %s" % [_variant, eye[2]]
			shots.append(await _view(eye[0], eye[1], 85.0))
	_save(shots)
	get_tree().quit()


## ── LA MECA ──────────────────────────────────────────────────────────────────────────────────────────────────────

## LA CAJA: maciza atrás; adelante, las tres cabinas en fila (un hueco cada una, con su vidrio al frente y vidrio entre
## ellas), en la mitad del ancho; arriba, la cápsula; a los costados, los hombros; atrás, los recursos.
func _mech(center: Vector3, size: Vector3) -> void:
	var half := size * 0.5
	var front := center.z - half.z
	var floor_y := center.y - half.y + SILL
	var row := CELL.x * 3.0 + GAP * 2.0
	# Atrás de las cabinas, macizo.
	Clay.box(self, Vector3(size.x, size.y, size.z - CELL.z), Vector3(center.x, center.y, front + CELL.z
		+ (size.z - CELL.z) * 0.5), METAL)
	# La franja de adelante: abajo, arriba y los costados de la fila.
	var low := floor_y - (center.y - half.y)
	Clay.box(self, Vector3(size.x, low, CELL.z), Vector3(center.x, center.y - half.y + low * 0.5, front + CELL.z * 0.5),
		METAL)
	var high := center.y + half.y - (floor_y + CELL.y)
	Clay.box(self, Vector3(size.x, high, CELL.z), Vector3(center.x, floor_y + CELL.y + high * 0.5, front + CELL.z * 0.5),
		METAL)
	var side := (size.x - row) * 0.5
	for s: float in [-1.0, 1.0]:
		if _plan.get("side_glass", false):
			# EL VIDRIO DEL COSTADO de las cabinas de afuera, con un parante en la esquina de adelante y otro atrás.
			_pane(Vector3(0.04, CELL.y, CELL.z), Vector3(s * (size.x * 0.5 - 0.02), floor_y + CELL.y * 0.5,
				front + CELL.z * 0.5))
			for z: float in [0.06, CELL.z - 0.06]:
				Clay.box(self, Vector3(side, CELL.y, 0.12), Vector3(s * (row + side) * 0.5, floor_y + CELL.y * 0.5,
					front + z), METAL)
		else:
			Clay.box(self, Vector3(side, CELL.y, CELL.z), Vector3(s * (row + side) * 0.5, floor_y + CELL.y * 0.5,
				front + CELL.z * 0.5), METAL)
	# Las tres cabinas.
	var names := ["brazo izquierdo", "artillero", "brazo derecho"]
	for index in 3:
		var x := (index - 1) * (CELL.x + GAP)
		_cell(Vector3(x, floor_y, front), index, names[index])
	# Entre las cabinas: vidrio (se ven, no se alcanzan), con parante adelante o sin.
	for s: float in [-1.0, 1.0]:
		var x := s * (CELL.x + GAP) * 0.5
		_pane(Vector3(0.05, CELL.y, CELL.z), Vector3(x, floor_y + CELL.y * 0.5, front + CELL.z * 0.5))
		if _plan["posts"]:
			Clay.box(self, Vector3(GAP, CELL.y, 0.25), Vector3(x, floor_y + CELL.y * 0.5, front + 0.125), METAL)
	# El ventanal: uno por cabina, o uno corrido.
	if _plan["posts"]:
		for index in 3:
			_pane(Vector3(CELL.x, CELL.y, 0.04), Vector3((index - 1) * (CELL.x + GAP), floor_y + CELL.y * 0.5, front + 0.02))
	else:
		_pane(Vector3(row, CELL.y, 0.04), Vector3(0.0, floor_y + CELL.y * 0.5, front + 0.02))
	# La cápsula de arriba.
	var top_z := lerpf(center.z, front + CELL.z * 0.5, float(_plan["top"]))
	_capsule(Vector3(0.0, center.y + half.y, top_z))
	# Los hombros y los brazos, a los costados.
	# En las chatas, en la parte maciza de atrás (no tapan el vidrio del costado).
	var shoulder_z := center.z
	var shoulder_y := center.y + 0.6
	if _plan.get("fit", false):
		shoulder_z = front + CELL.z + (size.z - CELL.z) * 0.5
		shoulder_y = center.y
	for s: float in [-1.0, 1.0]:
		_real_arm(Vector3(s * half.x, shoulder_y, shoulder_z), Vector3(s, 0.0, 0.0), s)
	# Los recursos, atrás: una fila de cubos a medias en la pared.
	for i in 7:
		var x := (i - 3) * minf(0.95, (size.x - 0.9) / 6.0)
		Clay.box(self, Vector3.ONE * 0.63, Vector3(x, center.y, center.z + half.z + 0.08), SUPPLY_COLORS[i % 3])


## EL DIAGRAMA: las alturas, en barras finitas de lado a lado (con su cartel), las escotillas debajo de cada cabina
## y la gente: uno parado con el brazo arriba (unos 2,25 m), uno saltando 0,8 m y otro 1,12 m, debajo de la caja.
const REACH := 2.25
func _diagram(standing: float, crouched: float, size: Vector3) -> void:
	var front := -size.z * 0.5
	# Las escotillas: una debajo de cada cabina, y la de arriba (la cápsula) atrás, al medio.
	for index in 3:
		Clay.box(self, Vector3(0.9, 0.06, 0.9), Vector3((index - 1) * (CELL.x + GAP), crouched - 0.03,
			front + CELL.z * 0.5), Color(0.95, 0.75, 0.15))
	Clay.box(self, Vector3(0.9, 0.06, 0.9), Vector3(0.0, crouched - 0.03, front + CELL.z + 1.0), Color(0.95, 0.75, 0.15))
	var marks: Array = [[REACH, "parado, la mano arriba: %.2f m", Color(0.2, 0.5, 0.2)],
			[REACH + 0.8, "saltando 0,8 m (casi todos): %.2f m", Color(0.15, 0.35, 0.7)],
			[crouched, "AGACHADA, la panza: %.2f m", Color(0.75, 0.55, 0.0)],
			[REACH + 1.12, "saltando 1,12 m (el que más salta): %.2f m", Color(0.45, 0.25, 0.7)],
			[standing, "parada, la panza: %.2f m", Color(0.75, 0.18, 0.15)]]
	marks.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var label_y := -10.0
	Clay.box(self, Vector3(20.0, 0.08, 0.08), Vector3(0.0, 0.0, front - 1.5), Color(0.2, 0.2, 0.2))
	Clay.box(self, Vector3(0.08, 0.08, 20.0), Vector3(-5.5, 0.0, 0.0), Color(0.2, 0.2, 0.2))
	for mark: Array in marks:
		var y: float = mark[0]
		var color: Color = mark[2]
		Clay.box(self, Vector3(9.0, 0.05, 0.05), Vector3(0.0, y, front - 1.5), color)
		Clay.box(self, Vector3(0.05, 0.05, 9.0), Vector3(-5.5, y, 0.5), color)
		# Los carteles, a la derecha, escalonados para que no se pisen (con una rayita hasta su barra).
		label_y = maxf(y, label_y + 0.55)
		for place: Array in [[Vector3(-4.4, label_y, front - 1.5), Vector3(0.0, PI, 0.0)],
				[Vector3(-5.6, label_y, 3.0), Vector3(0.0, -PI * 0.5, 0.0)]]:
			var label := Label3D.new()
			label.text = (mark[1] as String) % y
			label.font_size = 64
			label.pixel_size = 0.0085
			label.modulate = color
			label.outline_size = 14
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			label.position = place[0]
			label.rotation = place[1]
			add_child(label)
	# La gente, debajo de la cabina del medio: parado, saltando lo de siempre y lo que más salta.
	var under := front + CELL.z * 0.5
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(0.0, 0.0, under), PI)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(-(CELL.x + GAP), 0.8, under), PI)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(CELL.x + GAP, 1.12, under), PI)
	# Un brazo arriba de cada uno, hasta lo que alcanza (sólo una marca).
	for pair: Array in [[0.0, 0.0], [-(CELL.x + GAP), 0.8], [CELL.x + GAP, 1.12]]:
		Clay.box(self, Vector3(0.1, 0.55, 0.1), Vector3(pair[0], pair[1] + REACH - 0.28, under), Color(0.86, 0.66, 0.5))


## UNA CABINA: el hueco (el piso oscuro, el fondo), la silla y el piloto mirando al frente. `at`: el piso, al frente.
func _cell(at: Vector3, index: int, name_of: String) -> void:
	Clay.box(self, Vector3(CELL.x, 0.08, CELL.z), at + Vector3(0.0, 0.04, CELL.z * 0.5), DARK_METAL)
	Clay.box(self, Vector3(CELL.x, CELL.y, 0.05), at + Vector3(0.0, CELL.y * 0.5, CELL.z - 0.03), DARK_METAL)
	Clay.box(self, Vector3(CELL.x, 0.05, CELL.z), at + Vector3(0.0, CELL.y - 0.03, CELL.z * 0.5), DARK_METAL)
	var seat_at := at + Vector3(0.0, 0.08, CELL.z * 0.55)
	_seated(seat_at)
	Clay.box(self, Vector3(1.0, 0.1, 0.35), seat_at + Vector3(0.0, 0.75, -0.6), RIM)
	var eye := seat_at + Vector3(0.0, 1.2, -0.25)
	if index == 0:
		_eyes.append([eye, eye + Vector3(0.0, -0.15, -1.0), "desde la cabina de la izquierda, al frente"])
		_eyes.append([eye, eye + Vector3(1.0, -0.2, -0.15), "desde la izquierda, hacia las otras"])
		if _plan.get("side_glass", false):
			_eyes.append([eye, eye + Vector3(-1.0, -0.25, -0.35), "desde la izquierda, hacia su costado"])
	elif index == 1:
		_eyes.append([eye, eye + Vector3(0.0, -0.2, -1.0), "desde la cabina del medio"])
	var _unused := name_of


## LA CÁPSULA DE ARRIBA, la del movimiento: la esfera opaca con su mitad de afuera de vidrio (PodCabin.capsule), su
## aro donde se mete en la caja, y el piloto.
func _capsule(at: Vector3) -> void:
	var shell := MeshInstance3D.new()
	shell.mesh = PodCabin.capsule(POD, 95.0)
	shell.position = at
	add_child(shell)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = POD + 0.02
	torus.outer_radius = POD + 0.16
	ring.mesh = torus
	ring.material_override = Clay.material(RIM)
	ring.position = at
	add_child(ring)
	var floor_at := at + Vector3(0.0, -POD * 0.8, 0.0)
	_seated(floor_at + Vector3(0.0, 0.0, 0.15))
	var eye := floor_at + Vector3(0.0, 1.2, -0.1)
	_eyes.append([eye, eye + Vector3(0.0, -0.2, -1.0), "desde la cápsula de arriba"])


## Un paño de vidrio, una caja finita.
func _pane(size: Vector3, at: Vector3) -> void:
	var pane := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	pane.mesh = mesh
	pane.material_override = _glass
	pane.position = at
	add_child(pane)


## UN PILOTO SENTADO, de arcilla, mirando adelante (−Z), con su asiento: `at`, el piso debajo del asiento.
func _seated(at: Vector3) -> void:
	Clay.box(self, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(self, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), SEAT)
	Clay.box(self, Vector3(0.08, 0.42, 0.08), at + Vector3(0.0, 0.21, 0.05), DARK_METAL)
	Clay.box(self, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(self, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(self, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.12, 0.42, 0.12), at + Vector3(side * 0.1, 0.27, -0.28), SKIN)
		Clay.box(self, Vector3(0.1, 0.1, 0.38), at + Vector3(side * 0.24, 0.8, -0.12), SKIN)


## ── BRAZOS Y PIERNAS COMO LOS REALES (quietos) ───────────────────────────────────────────────────────────────────

func _limb(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var holder := Clay.limb(self, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)


## El hombro en `at` (la cara del costado, hacia `way`), el brazo abajo y afuera, el antebrazo al frente, el puño.
func _real_arm(at: Vector3, way: Vector3, side: float) -> void:
	var joint_size := REAL_THICK * 0.78
	var center := at + way * joint_size * 0.6
	Clay.sphere(self, joint_size, center, JOINT)
	var elbow := center + Vector3(side * 0.45, -1.0, 0.25).normalized() * REAL_UPPER
	var fist := elbow + Vector3(side * -0.1, 0.35, -1.0).normalized() * REAL_FOREARM
	_limb(center, elbow, REAL_THICK * 0.5, Clay.METAL.darkened(0.1))
	Clay.sphere(self, REAL_THICK * 0.66, elbow, JOINT)
	_limb(elbow, fist, REAL_THICK * 0.5, Clay.METAL.darkened(0.2))
	Clay.box(self, Vector3(2.3, 2.3, 2.6) * REAL_THICK / 2.1, fist + Vector3(0.0, 0.0, -0.9 * REAL_THICK / 2.1), JOINT)


## La pelvis (un tubo) bajo la caja, las caderas, la rodilla adelante, el pie.
func _real_legs(bottom: float) -> void:
	var hip_y := REAL_WAIST - REAL_HIP.y
	Clay.cylinder(self, REAL_THICK * 0.43, REAL_HIP.x * 2.0, Vector3(0.0, hip_y, 0.0), JOINT, Vector3(0.0, 0.0, 90.0))
	Clay.cylinder(self, REAL_THICK * 0.48, bottom - hip_y + 0.2, Vector3(0.0, (bottom + hip_y) * 0.5, 0.0), JOINT)
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * REAL_HIP.x, hip_y, 0.0)
		var ankle := Vector3(side * (REAL_HIP.x + 0.3), REAL_THICK * 0.33 + REAL_FOOT.y * 0.5, 0.0)
		var span := hip.distance_to(ankle)
		var bend := sqrt(maxf(REAL_THIGH * REAL_THIGH - span * span * 0.25, 0.0))
		var knee := (hip + ankle) * 0.5 + Vector3(0.0, 0.0, -bend)
		Clay.sphere(self, REAL_THICK * 0.62, hip, JOINT)
		_limb(hip, knee, REAL_THICK * 0.5, Clay.METAL.darkened(0.1))
		Clay.sphere(self, REAL_THICK * 0.62, knee, JOINT)
		_limb(knee, ankle, REAL_THICK * 0.5, Clay.METAL.darkened(0.2))
		Clay.sphere(self, REAL_THICK * 0.53, ankle, JOINT)
		Clay.box(self, REAL_FOOT, Vector3(ankle.x, REAL_FOOT.y * 0.5, ankle.z - 0.4), JOINT)


## ── LO DE SIEMPRE ────────────────────────────────────────────────────────────────────────────────────────────────

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
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


func _view(from: Vector3, to: Vector3, fov: float) -> Image:
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first: Image = shots[0]
	if _plan.get("diagram", false):
		# El diagrama, entero: una vista debajo de la otra.
		var whole := Image.create(first.get_width(), first.get_height() * shots.size(), false, first.get_format())
		for index in shots.size():
			whole.blit_rect(shots[index], Rect2i(Vector2i.ZERO, first.get_size()), Vector2i(0, first.get_height() * index))
		whole.save_png("%s/cuadrada_%d.png" % [_folder, _variant])
		print("CAPTURA ", "%s/cuadrada_%d.png" % [_folder, _variant])
		return
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(shots.size() / 2.0), false, first.get_format())
	for index in shots.size():
		var shot: Image = shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/cuadrada_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)
