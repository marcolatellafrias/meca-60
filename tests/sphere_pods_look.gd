extends Node3D

## LA MECA DE CÁPSULAS, MAQUETA DE ARCILLA (15/11/2026): sin interior. El torso es una esfera (o un disco, para comparar)
## y cada jugador va en una CÁPSULA, una esfera chica metida en la grande, todas del mismo tamaño. Para cuatro: la
## principal arriba y las tres secundarias adelante, la del medio y las dos de sus costados. El usuario: «las cápsulas
## son como esferas metidas adentro de esta otra esfera de cuerpo».
## UN SOLO SISTEMA DE ENCHUFES: todo lo que va pegado al cuerpo (las cápsulas, los recursos, los hombros y la escotilla
## de abajo) es un enchufe con su dirección (rumbo y altura) y el mismo aro oscuro donde se mete en el cuerpo (el
## usuario: «en ese mismo sistema los hombros de los brazos, así… encaja todo el sistema y se ve más unificado»).
## Entrar: a la principal, desde abajo (parado bajo la escotilla, E, sube por el tubo); a las secundarias, E en la
## cápsula misma. Eyectar: la principal, para arriba por su hueco; las secundarias salen hacia afuera y dan la vuelta
## para arriba (la 8 lo muestra con cápsulas fantasma).
##   1 · esfera, cápsulas a medias (la mitad afuera), las secundarias en el ecuador;
##   2 · como la 1, cápsulas casi al ras (un cuarto afuera);
##   3 · como la 1, cápsulas bien afuera (tres cuartos);
##   4 · como la 1, las secundarias abajo del ecuador, más a mano desde el piso;
##   5 · como la 1, en arco: la del medio más abajo, las de los costados más arriba;
##   6 · disco con domos arriba: las secundarias asoman del techo, la principal al centro sobre un cuello;
##   7 · disco con domos en el canto: las secundarias en el borde delantero, la principal arriba al centro;
##   8 · la 1 con la entrada y la eyección.
## Cada hoja: de frente a la izquierda, de frente, de atrás (los recursos) y con el cuerpo transparente.
##   tools/godot_ventana.sh res://tests/sphere_pods_look.tscn -- --salida=C:/carpeta --variante=1

const VIEW := Vector2i(1280, 720)
## La esfera del cuerpo: radio y alto del centro.
const BODY := 2.5
const BODY_HEIGHT := 4.6
## El disco (las 6 y 7): radio, alto y alto del centro.
const DISC := Vector2(3.3, 1.8)
const DISC_HEIGHT := 4.2
## La cápsula de uno: todas iguales.
const POD := 0.9
## El hombro (una bola) y lo que asoma.
const SHOULDER := 0.8
const SHOULDER_OUT := 0.6
## Los recursos (cubos de 63 cm) y la escotilla de abajo.
const SUPPLY := 0.63
const HATCH := 0.55
## Los recursos de atrás: de qué rumbo a qué rumbo (grados, 0 adelante, positivo a la derecha) y en qué orden.
const SUPPLY_FROM := 120.0
const SUPPLY_STEP := 20.0
const SUPPLIES := ["kit", "kit", "ammo", "battery", "ammo", "kit", "kit"]

## shape: sphere, disc_top, disc_rim; out: qué parte de la cápsula asoma (0..1); middle / sides: la altura (grados en la
## esfera) de la del medio y de las de los costados; spread: el rumbo de las de los costados.
const VARIANTS := {
	1: {"name": "esfera, cápsulas a medias", "shape": "sphere", "out": 0.5, "middle": 0.0, "sides": 0.0, "spread": 45.0},
	2: {"name": "cápsulas casi al ras", "shape": "sphere", "out": 0.25, "middle": 0.0, "sides": 0.0, "spread": 45.0},
	3: {"name": "cápsulas bien afuera", "shape": "sphere", "out": 0.75, "middle": 0.0, "sides": 0.0, "spread": 45.0},
	4: {"name": "secundarias abajo, más a mano", "shape": "sphere", "out": 0.5, "middle": -32.0, "sides": -32.0,
		"spread": 45.0},
	5: {"name": "en arco: el medio abajo, los costados arriba", "shape": "sphere", "out": 0.5, "middle": -25.0,
		"sides": 12.0, "spread": 45.0},
	6: {"name": "disco con domos arriba", "shape": "disc_top", "out": 0.55, "middle": 0.0, "sides": 0.0,
		"spread": 50.0},
	7: {"name": "disco con domos en el canto", "shape": "disc_rim", "out": 0.5, "middle": 0.0, "sides": 0.0,
		"spread": 45.0},
	8: {"name": "la 1: la entrada y la eyección", "shape": "sphere", "out": 0.5, "middle": 0.0, "sides": 0.0,
		"spread": 45.0, "show": true},
	# DE LA 9 EN ADELANTE: la 2 (cápsulas casi al ras) en cuerpos curvos COLGADOS BAJO, las piernas desde los costados
	# (enchufes también), así las secundarias quedan a mano desde el piso (el usuario: «siguen estando muy arriba para
	# alguien que está en el piso… más cilíndrica con domos… armoniosa y orgánica… simple… no quiero planos rectos»).
	9: {"name": "huevo", "shape": "egg", "out": 0.25, "spread": 62.0, "radius": 2.4, "low": 1.8, "high": 3.2},
	10: {"name": "cilindro con domos", "shape": "capsule", "out": 0.25, "spread": 62.0, "radius": 2.3, "half": 0.8},
	11: {"name": "cápsula acostada", "shape": "pill", "out": 0.25, "spread": 62.0, "radius": 1.9, "half": 1.3},
	12: {"name": "bollo: ancho y bajo", "shape": "egg", "out": 0.25, "spread": 62.0, "radius": 2.8, "low": 1.5,
		"high": 2.3},
	13: {"name": "cilindro con domos, alto", "shape": "capsule", "out": 0.25, "spread": 64.0, "radius": 2.0,
		"half": 1.5},
}
## DE LA 14 EN ADELANTE: una curva continua, SIMÉTRICA DE ARRIBA A ABAJO, y las secundarias EN EL ECUADOR (el radio
## más ancho), mirando al frente y espaciadas (el usuario: «son dos domos pegados casi… una curva continua… simétrico de
## abajo a arriba… las secundarias tienen que ir todas a lo largo del radio más ancho»). La forma: un ESFEROIDE
## ACHATADO (power 2) o un SUPERELIPSOIDE (power 3 o 4: el costado más derecho, sin perder la curva): (r/radius)^power
## + (y/half)^power = 1, con una franja recta de 2·band en el medio si band > 0. El centro, a center de alto.
const VARIANTS_EQUATOR := {
	14: {"name": "esferoide achatado", "radius": 3.0, "half": 1.9, "band": 0.0, "power": 2.0},
	15: {"name": "lenteja, más chata", "radius": 3.2, "half": 1.5, "band": 0.0, "power": 2.0},
	16: {"name": "dos domos con una franja", "radius": 2.9, "half": 1.6, "band": 0.45, "power": 2.0},
	17: {"name": "superelipsoide, apenas cuadrado", "radius": 3.0, "half": 1.9, "band": 0.0, "power": 3.0},
	18: {"name": "tambor redondeado", "radius": 3.0, "half": 1.9, "band": 0.0, "power": 4.0},
	19: {"name": "casi esfera, apenas achatada", "radius": 2.9, "half": 2.4, "band": 0.0, "power": 2.0},
}
const EQUATOR_HEIGHT := 3.0
const EQUATOR_SPREAD := 56.0

## DE LA 20 EN ADELANTE: LAS CÁPSULAS SON DOMOS QUE SOBRESALEN (media cápsula: la mitad de vidrio afuera, el piloto
## sentado mirando adelante con la cabeza adentro del domo). Los de los costados van donde estaban los hombros; los
## hombros, un poco más adelante. TODOS SUBEN DESDE ABAJO, cada uno por su escotilla y su tubo (el usuario: «las de
## izquierda y derecha están metidas adentro y no pueden ver al frente… media cápsula… los brazos un poquito más
## adelante… todos suban desde abajo… la misma regla»). El cuerpo, alto: se está parado debajo.
## body: la forma (de las 14 a 19); sides: el rumbo de los domos de los costados; stretch: cuánto se alargan hacia
## adelante los domos de los costados (1, redondos).
const VARIANTS_DOMES := {
	20: {"name": "esferoide, domos redondos", "body": 14, "sides": 90.0, "stretch": 1.0},
	21: {"name": "esferoide, domos alargados hacia adelante", "body": 14, "sides": 90.0, "stretch": 1.6},
	22: {"name": "esferoide, domos de los costados girados al frente", "body": 14, "sides": 75.0, "stretch": 1.3},
	23: {"name": "tambor, domos redondos", "body": 18, "sides": 90.0, "stretch": 1.0},
	24: {"name": "tambor, domos alargados hacia adelante", "body": 18, "sides": 90.0, "stretch": 1.6},
}
const DOME := 1.0
const DOME_EQUATOR := 4.6
const SHOULDER_HEADING := 50.0

## DE LA 25 EN ADELANTE: EL ESFEROIDE MÁS GRANDE y LAS CÁPSULAS SOBRE UN CUELLO: un cuello corto que sale del cuerpo y
## una burbuja de vidrio entera en la punta, con el piloto adentro, así queda afuera del casco y ve al frente entero
## (el usuario: «el jugador de los costados va a tener la visión cortada a la mitad… o hay que hacer que sobresalgan
## con un poco de cilindro, o posicionarlos como en el hombro»). LOS BRAZOS, EN LA LÍNEA MEDIA del esferoide (el
## ecuador, «la misma trama»), menos en la 29 (desde abajo).
## arms: el rumbo de los hombros; arms_low: los hombros abajo del ecuador; reach: cuánto lleva el codo hacia adelante;
## shoulder_pod: el hombro ES la cápsula de los costados (un esferoide con frente de vidrio, el brazo colgando abajo).
const VARIANTS_BULBS := {
	25: {"name": "burbujas en cuellos, brazos en la línea media adelante", "sides": 90.0, "arms": 45.0, "reach": 0.4},
	26: {"name": "brazos en la línea media, atrás", "sides": 90.0, "arms": 135.0, "reach": -2.4},
	27: {"name": "burbujas de los costados adelante, brazos atrás de ellas", "sides": 60.0, "arms": 105.0,
		"reach": -1.2},
	28: {"name": "el hombro es la cápsula", "sides": 90.0, "arms": 90.0, "reach": 0.4, "shoulder_pod": true},
	29: {"name": "brazos desde abajo", "sides": 90.0, "arms": 70.0, "reach": 0.0, "arms_low": true},
}
## DE LA 30 EN ADELANTE: DE VUELTA A LAS EMPOTRADAS (las de la 2, casi al ras), y que juegue a favor: cada uno ve lo
## que le sirve (el usuario: «el del medio es artillero, entonces está centrado. El de la izquierda y la derecha usan
## brazo izquierdo y derecho, entonces ven su lado. Y el de arriba ve como todo»). Dos cuerpos: el esferoide achatado
## y un cilindro con domo arriba (el fondo, una curva baja: nada de planos rectos). Todos suben desde abajo. En cada
## hoja, dos fotos desde los ojos de los pilotos de la izquierda y la derecha (para ver si ven su brazo).
## body: spheroid o cylinder; sides: el rumbo de las cápsulas de los costados; arms: el de los hombros (en la línea
## media); reach: cuánto lleva el codo hacia atrás (negativo, adelante).
const VARIANTS_EMBED := {
	30: {"name": "esferoide: costados a 45°, brazos en los hombros", "body": "spheroid", "sides": 45.0, "arms": 90.0,
		"reach": 0.4},
	31: {"name": "esferoide: costados en los hombros, brazos atrás", "body": "spheroid", "sides": 90.0, "arms": 135.0,
		"reach": -2.6},
	32: {"name": "cilindro con domo: costados a 45°, brazos en los hombros", "body": "cylinder", "sides": 45.0,
		"arms": 90.0, "reach": 0.4},
	33: {"name": "cilindro con domo: costados en los hombros, brazos atrás", "body": "cylinder", "sides": 90.0,
		"arms": 135.0, "reach": -2.6},
}
const EMBED_BELLY := 2.7

## DE LA 34 EN ADELANTE: A LA ESCALA DE LA MECA DE VERDAD (unos 12 m de diámetro), con BRAZOS Y PIERNAS COMO LOS
## REALES (las medidas de MechBody: muslo y canilla de 4,4 m, brazo y antebrazo de 5,5, de 2,1 de grueso; la cintura a
## 7,4 m), quietos, sólo para la foto (el usuario: «aumentar bastante más el diámetro… usar brazos y piernas reales…
## solamente para la foto»). Dos cuerpos: el esferoide y el cilindro con domo DE ABAJO CHATO (el borde, apenas
## redondeado). Tres arreglos: los costados a 45° con los brazos en los hombros; los costados en los hombros con los
## brazos atrás; y LA Y: la del medio abajo y dos en diagonal hacia arriba, con los brazos donde estaban los costados
## (el usuario: «que hagan como una Y hacia arriba, y que los brazos estén donde están las cápsulas izquierda y derecha
## ahora… van a tener visión del brazo, pero a su vez no van a tener visión tan limitada»).
const VARIANTS_BIG := {
	34: {"name": "esferoide grande: costados a 45°, brazos en los hombros", "body": "spheroid", "layout": "sides45"},
	35: {"name": "esferoide grande: costados en los hombros, brazos atrás", "body": "spheroid", "layout": "shoulders"},
	36: {"name": "esferoide grande: la Y, brazos a 45°", "body": "spheroid", "layout": "y"},
	37: {"name": "domo de abajo chato: costados a 45°, brazos en los hombros", "body": "flat", "layout": "sides45"},
	38: {"name": "domo de abajo chato: costados en los hombros, brazos atrás", "body": "flat", "layout": "shoulders"},
	39: {"name": "domo de abajo chato: la Y, brazos a 45°", "body": "flat", "layout": "y"},
}
## Las medidas de la meca de verdad (MechBody).
const REAL_WAIST := 7.4
const REAL_HIP := Vector2(2.7, 1.2)
const REAL_THIGH := 4.4
const REAL_SHIN := 4.4
const REAL_UPPER := 5.5
const REAL_FOREARM := 5.5
const REAL_THICK := 2.1
const REAL_FOOT := Vector3(2.2, 0.7, 3.4)
const JOINT := Color(0.36, 0.375, 0.4)
## Los brazos de estas, más grandes (crecieron con el cuerpo).
const ARM_SCALE := 1.35

const BIG := {"radius": 4.0, "half": 2.6, "band": 0.0, "power": 2.0}
const BIG_EQUATOR := 5.3
const NECK := 0.7

## Las de cuerpo colgado (9 en adelante): el alto de la panza (se puede parar uno abajo, para la escotilla) y a qué
## alto toca el cuerpo cada secundaria.
const BELLY := 2.0
const POD_AT := 2.9
const ROUND_SHAPES := ["egg", "capsule", "pill", "spheroid"]

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const RIM := Color(0.22, 0.23, 0.25)
const SKIN := Color(0.86, 0.66, 0.5)
const SEAT := Color(0.25, 0.42, 0.7)
const PATH := Color(0.95, 0.75, 0.15)
## Los recursos: poco contraste (ver la memoria de los recursos de la meca).
const SUPPLY_COLORS := {"kit": Color(0.72, 0.42, 0.36), "ammo": Color(0.48, 0.5, 0.36), "battery": Color(0.36, 0.55, 0.38)}
const PRIMARY := Color(0.93, 0.75, 0.16)
const SECONDARY := Color(0.3, 0.45, 0.75)

var _folder := ""
var _variant := 1
var _plan: Dictionary = {}
var _eye: Camera3D = null
var _title: Label = null
var _glass := StandardMaterial3D.new()
var _ghost := StandardMaterial3D.new()
var _see_through := StandardMaterial3D.new()
## Las mallas del cuerpo, para verlas transparentes en la última vista.
var _shell: Array[MeshInstance3D] = []
## El centro del cuerpo.
var _center := Vector3.ZERO
## El metal del cuerpo (en las 30 en adelante, de dos caras: desde adentro de la cápsula también se ve).
var _solid: StandardMaterial3D = null
## Los ojos de los pilotos de los costados: [ojo, adónde mira].
var _eyes: Array = []
## El perfil del cuerpo torneado (30 en adelante): de abajo arriba, (radio, alto) desde el centro.
var _profile: Array[Vector2] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
	get_window().size = VIEW
	if VARIANTS_BIG.has(_variant):
		_plan = (VARIANTS_BIG[_variant] as Dictionary).duplicate()
		_plan["shape"] = "profile"
		_plan["big"] = true
		_solid = StandardMaterial3D.new()
		_solid.albedo_color = METAL
		_solid.roughness = 0.85
		_solid.cull_mode = BaseMaterial3D.CULL_DISABLED
	elif VARIANTS_EMBED.has(_variant):
		_plan = (VARIANTS_EMBED[_variant] as Dictionary).duplicate()
		_plan["shape"] = "profile"
		_plan["out"] = 0.25
		_solid = StandardMaterial3D.new()
		_solid.albedo_color = METAL
		_solid.roughness = 0.85
		_solid.cull_mode = BaseMaterial3D.CULL_DISABLED
	elif VARIANTS_BULBS.has(_variant):
		_plan = BIG.duplicate()
		_plan.merge(VARIANTS_BULBS[_variant], true)
		_plan["shape"] = "bulbs"
	elif VARIANTS_DOMES.has(_variant):
		var dome_plan: Dictionary = VARIANTS_DOMES[_variant]
		_plan = (VARIANTS_EQUATOR[dome_plan["body"]] as Dictionary).duplicate()
		_plan.merge(dome_plan, true)
		_plan["shape"] = "domes"
	elif VARIANTS_EQUATOR.has(_variant):
		_plan = (VARIANTS_EQUATOR[_variant] as Dictionary).duplicate()
		_plan["shape"] = "spheroid"
		_plan["out"] = 0.25
		_plan["spread"] = EQUATOR_SPREAD
	else:
		_plan = VARIANTS[_variant]
	_glass.albedo_color = Color(0.7, 0.85, 0.95, 0.22)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass.roughness = 0.1
	_ghost.albedo_color = Color(0.95, 0.85, 0.5, 0.28)
	_ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost.cull_mode = BaseMaterial3D.CULL_DISABLED
	_see_through.albedo_color = Color(METAL.r, METAL.g, METAL.b, 0.18)
	_see_through.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_see_through.cull_mode = BaseMaterial3D.CULL_DISABLED
	_stage()
	var top := _mech()
	if _plan.get("show", false):
		_entry_and_ejection()
	elif _plan["shape"] != "profile":
		PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(4.2, 0.0, -2.6), -PI * 0.7)
	await get_tree().create_timer(3.0).timeout
	_title.text = "%d. %s" % [_variant, _plan["name"]]
	var middle := _center.y
	var k := maxf(top, 7.0) / 8.0
	var shots: Array = []
	var views: Array = [
			[Vector3(-9.0, 7.0, -12.0) * k, Vector3(0.0, middle - 0.6, 0.0), 45.0, false],
			[Vector3(0.0, middle + 1.0, -15.0 * k), Vector3(0.0, middle - 0.8, 0.0), 42.0, false],
			[Vector3(10.0, 8.0, 11.0) * k, Vector3(0.0, middle - 0.6, 0.0), 45.0, false],
			[Vector3(-8.0, 6.5, -9.5) * k, Vector3(0.0, middle - 0.4, 0.0), 45.0, true]]
	if _plan.get("show", false):
		views = [
			[Vector3(-12.0, 9.0, -16.0), Vector3(0.0, 8.0, 0.0), 50.0, false],
			[Vector3(-19.0, 8.0, -2.0), Vector3(0.0, 8.0, -1.5), 50.0, false],
			[Vector3(14.0, 10.0, 14.0), Vector3(0.0, 8.0, 0.0), 50.0, false],
			[Vector3(-7.5, 2.6, -8.5), Vector3(0.0, 3.6, 0.0), 55.0, true]]
	if _plan["shape"] == "profile":
		views = [views[0], views[1]]
		# Desde los ojos: los dos mirando al frente, después los dos mirando hacia su costado (su brazo).
		for look in [1, 2]:
			for eye: Array in _eyes:
				views.append([eye[0], eye[look], 85.0, false])
	for view: Array in views:
		_look(view[0], view[1], view[2])
		_transparent(view[3])
		shots.append(await _grab())
	_save(shots)
	get_tree().quit()


## ── EL CUERPO Y SUS ENCHUFES ─────────────────────────────────────────────────────────────────────────────────────

## Arma la meca; devuelve el alto de arriba de todo.
func _mech() -> float:
	var shape: String = _plan["shape"]
	if shape == "profile" and _plan.get("big", false):
		return _big_mech()
	if shape == "profile":
		return _embed_mech()
	if shape == "domes":
		return _dome_mech()
	if shape == "bulbs":
		return _bulb_mech()
	if shape in ROUND_SHAPES:
		return _hung_mech()
	var spread: float = _plan["spread"]
	var belly := 0.0
	var top := 0.0
	# Los enchufes de cada forma: [donde toca el cuerpo, hacia afuera].
	var main: Array = []
	var pods: Array = []
	var shoulders: Array = []
	var supplies: Array = []
	var hatch: Array = []
	if shape == "sphere":
		_center = Vector3(0.0, BODY_HEIGHT, 0.0)
		_shell.append(Clay.sphere(self, BODY, _center, METAL))
		belly = _center.y - BODY
		main = _on_sphere(0.0, 90.0)
		pods = [_on_sphere(-spread, _plan["sides"]), _on_sphere(0.0, _plan["middle"]), _on_sphere(spread, _plan["sides"])]
		for side: float in [-1.0, 1.0]:
			shoulders.append(_on_sphere(side * 90.0, 8.0))
		for index in SUPPLIES.size():
			supplies.append(_on_sphere(SUPPLY_FROM + index * SUPPLY_STEP, 0.0))
		hatch = _on_sphere(0.0, -90.0)
	else:
		_center = Vector3(0.0, DISC_HEIGHT, 0.0)
		_shell.append(Clay.cylinder(self, DISC.x, DISC.y, _center, METAL))
		belly = _center.y - DISC.y * 0.5
		var roof := _center.y + DISC.y * 0.5
		if shape == "disc_top":
			# La principal, al centro sobre un cuello; las secundarias asoman del techo, adelante.
			var neck := 0.7
			_shell.append(Clay.cylinder(self, POD * 0.95, neck, Vector3(0.0, roof + neck * 0.5, 0.0), METAL))
			main = [Vector3(0.0, roof + neck, 0.0), Vector3.UP]
			for heading: float in [-spread, 0.0, spread]:
				pods.append([_flat(heading) * 2.1 + Vector3(0.0, roof, 0.0), Vector3.UP])
		else:
			main = [Vector3(0.0, roof, 0.0), Vector3.UP]
			for heading: float in [-spread, 0.0, spread]:
				pods.append([_flat(heading) * DISC.x + Vector3(0.0, _center.y, 0.0), _flat(heading)])
		for side: float in [-1.0, 1.0]:
			shoulders.append([_flat(side * 90.0) * DISC.x + Vector3(0.0, _center.y, 0.0), _flat(side * 90.0)])
		for index in SUPPLIES.size():
			var heading := SUPPLY_FROM + index * SUPPLY_STEP
			supplies.append([_flat(heading) * DISC.x + Vector3(0.0, _center.y, 0.0), _flat(heading)])
		hatch = [Vector3(0.0, belly, 0.0), Vector3.DOWN]
	var out: float = _plan["out"]
	top = _pod(main[0], main[1], out, PRIMARY)
	for socket: Array in pods:
		top = maxf(top, _pod(socket[0], socket[1], out, SECONDARY))
	for index in shoulders.size():
		_shoulder(shoulders[index][0], shoulders[index][1], -1.0 if index == 0 else 1.0)
	for index in supplies.size():
		_supply(supplies[index][0], supplies[index][1], SUPPLIES[index])
	_hatch(hatch[0], hatch[1], (main[0] as Vector3) + (main[1] as Vector3) * POD * (2.0 * out - 1.0))
	_legs(belly)
	return top


## ── EL CUERPO COLGADO (9 en adelante) ───────────────────────────────────────────────────────────────────────────

## Huevo (dos medios elipsoides, el de arriba más alto), cilindro con domos (una cápsula parada) o cápsula acostada,
## con la panza a BELLY. Los mismos enchufes: la principal arriba, la escotilla abajo, las secundarias tocando el
## cuerpo a POD_AT, los hombros arriba a los costados, LAS CADERAS abajo a los costados, los recursos atrás.
func _hung_mech() -> float:
	var shape: String = _plan["shape"]
	var radius: float = _plan["radius"]
	var top := 0.0
	match shape:
		"spheroid":
			var half: float = _plan["half"]
			var band: float = _plan["band"]
			_center = Vector3(0.0, EQUATOR_HEIGHT, 0.0)
			top = _center.y + half + band
			var part := MeshInstance3D.new()
			part.mesh = _lathe(radius, half, band, _plan["power"])
			part.material_override = Clay.material(METAL)
			part.position = _center
			add_child(part)
			_shell.append(part)
		"egg":
			var low: float = _plan["low"]
			var high: float = _plan["high"]
			_center = Vector3(0.0, BELLY + low, 0.0)
			top = _center.y + high
			for half: Array in [[high, Basis()], [low, Basis(Vector3.RIGHT, PI)]]:
				var part := MeshInstance3D.new()
				var mesh := SphereMesh.new()
				mesh.radius = 1.0
				mesh.height = 1.0
				mesh.is_hemisphere = true
				part.mesh = mesh
				part.material_override = Clay.material(METAL)
				part.transform = Transform3D((half[1] as Basis).scaled(Vector3(radius, half[0], radius)), _center)
				add_child(part)
				_shell.append(part)
		_:
			var half_length: float = _plan["half"]
			var part := MeshInstance3D.new()
			var mesh := CapsuleMesh.new()
			mesh.radius = radius
			mesh.height = 2.0 * (radius + half_length)
			part.mesh = mesh
			part.material_override = Clay.material(METAL)
			if shape == "capsule":
				_center = Vector3(0.0, BELLY + radius + half_length, 0.0)
				top = _center.y + radius + half_length
				part.position = _center
			else:
				_center = Vector3(0.0, BELLY + radius, 0.0)
				top = _center.y + radius
				part.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), _center)
			add_child(part)
			_shell.append(part)
	var mid := (BELLY + top) * 0.5
	var belly := BELLY
	# Las alturas de los enchufes: en las de ecuador, las secundarias y los recursos en el ecuador, los hombros arriba y
	# las caderas abajo, parejos.
	var pod_at := POD_AT
	var shoulder_at := mid + 0.9
	var hip_at := BELLY + 1.0
	var supply_at := mid + 0.2
	if shape == "spheroid":
		var reach: float = _plan["half"] + _plan["band"]
		belly = _center.y - reach
		pod_at = _center.y
		supply_at = _center.y
		shoulder_at = _center.y + reach * 0.55
		hip_at = _center.y - reach * 0.55
	var out: float = _plan["out"]
	var spread: float = _plan["spread"]
	var main: Array = _toward(Vector3.UP)
	top = maxf(top, _pod(main[0], main[1], out, PRIMARY))
	var middle_at := Vector3.ZERO
	for heading: float in [-spread, 0.0, spread]:
		var socket := _on_body(heading, pod_at)
		# En la curva de abajo la piel mira al piso: la cápsula, en cambio, casi al frente (el piloto ve adelante).
		var facing: Vector3 = socket[1]
		facing = Vector3(facing.x, facing.y * 0.35, facing.z).normalized()
		_pod(socket[0], facing, out, SECONDARY)
		if heading == 0.0:
			middle_at = socket[0]
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		var shoulder := _on_body(side * 90.0, shoulder_at)
		_shoulder(shoulder[0], shoulder[1], side)
		var hip := _on_body(side * 100.0, hip_at)
		_hip(hip[0], hip[1], side)
	for index in SUPPLIES.size():
		var supply := _on_body(SUPPLY_FROM + index * SUPPLY_STEP, supply_at)
		_supply(supply[0], supply[1], SUPPLIES[index])
	var hatch: Array = _toward(Vector3.DOWN)
	_hatch(hatch[0], hatch[1], (main[0] as Vector3) + (main[1] as Vector3) * POD * (2.0 * out - 1.0))
	# Uno frente a la del medio (E en la cápsula) y uno bajo la escotilla (E, sube a la principal).
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(middle_at.x, 0.0, middle_at.z - 1.3), PI)
	if belly > 1.9:
		PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(0.0, 0.0, 0.2), PI)
	return top


## EL CUERPO DE LAS DE ECUADOR, torneado: el perfil (r/radius)^power + (y/half)^power = 1, abierto en el medio por una
## franja de `band` para cada lado, girado en redondo.
func _lathe(radius: float, half: float, band: float, power: float) -> ArrayMesh:
	var profile: Array[Vector2] = []
	var steps := 24
	for i in range(-steps, steps + 1):
		var angle := PI * 0.5 * float(i) / steps
		var r := radius * pow(absf(cos(angle)), 2.0 / power)
		var y := half * pow(absf(sin(angle)), 2.0 / power) * signf(sin(angle))
		if i == 0 and band > 0.0:
			profile.append(Vector2(r, -band))
			profile.append(Vector2(r, band))
			continue
		profile.append(Vector2(r, y + band * signf(y)))
	return _lathe_profile(profile)


## Tornea `profile` (de abajo arriba, (radio, alto)) en redondo, con sus normales.
func _lathe_profile(profile: Array[Vector2]) -> ArrayMesh:
	var normals: Array[Vector2] = []
	for i in profile.size():
		var before := profile[maxi(i - 1, 0)]
		var after := profile[mini(i + 1, profile.size() - 1)]
		var along := (after - before).normalized()
		normals.append(Vector2(along.y, -along.x))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var around := 48
	for j in around:
		var a0 := TAU * j / around
		var a1 := TAU * (j + 1) / around
		for i in profile.size() - 1:
			var quad: Array = [[i, a0], [i + 1, a0], [i + 1, a1], [i, a1]]
			for corner: int in [0, 2, 1, 0, 3, 2]:
				var index: int = quad[corner][0]
				var turn: float = quad[corner][1]
				var p := profile[index]
				var n := normals[index]
				tool.set_normal(Vector3(n.x * cos(turn), n.y, n.x * sin(turn)))
				tool.add_vertex(Vector3(p.x * cos(turn), p.y, p.x * sin(turn)))
	return tool.commit()


## ── LOS DOMOS (20 en adelante) ──────────────────────────────────────────────────────────────────────────────────

func _dome_mech() -> float:
	var radius: float = _plan["radius"]
	var reach: float = _plan["half"] + _plan["band"]
	_center = Vector3(0.0, DOME_EQUATOR, 0.0)
	var top := _center.y + reach
	var part := MeshInstance3D.new()
	part.mesh = _lathe(radius, _plan["half"], _plan["band"], _plan["power"])
	part.material_override = Clay.material(METAL)
	part.position = _center
	add_child(part)
	_shell.append(part)
	var sides: float = _plan["sides"]
	var stretch: float = _plan["stretch"]
	# Los cuatro domos: el de arriba, el del frente y los de los costados; cada uno con su escotilla abajo.
	var main: Array = _toward(Vector3.UP)
	top = maxf(top, _dome(main[0], main[1], 1.0, PRIMARY))
	var hatches: Array[Vector3] = []
	var hatch_main: Array = _toward(Vector3.DOWN)
	hatches.append(_dome_hatch(hatch_main[0], hatch_main[1], main[0]))
	for heading: float in [-sides, 0.0, sides]:
		var socket := _on_body(heading, _center.y)
		var long := 1.0 if heading == 0.0 else stretch
		_dome(socket[0], socket[1], long, SECONDARY)
		var below := _on_body(heading * 0.6, _center.y - reach * 0.9)
		hatches.append(_dome_hatch(below[0], below[1], socket[0]))
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		var shoulder := _on_body(side * SHOULDER_HEADING, _center.y + reach * 0.35)
		_shoulder(shoulder[0], shoulder[1], side)
		var hip := _on_body(side * 110.0, _center.y - reach * 0.55)
		_hip(hip[0], hip[1], side)
	for index in SUPPLIES.size():
		var supply := _on_body(SUPPLY_FROM + index * SUPPLY_STEP, _center.y)
		_supply(supply[0], supply[1], SUPPLIES[index])
	# Uno parado bajo cada escotilla.
	for at in hatches:
		PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(at.x, 0.0, at.z), PI)
	return top


## ── LAS EMPOTRADAS, DE VUELTA (30 en adelante) ──────────────────────────────────────────────────────────────────

func _embed_mech() -> float:
	var body: String = _plan["body"]
	var pod_y := 0.0
	var low := 0.0
	var steps := 24
	if body == "spheroid":
		# El esferoide achatado, más grande que la 14.
		var radius := 3.4
		var half := 2.1
		for i in range(-steps, steps + 1):
			var angle := PI * 0.5 * float(i) / steps
			_profile.append(Vector2(radius * cos(angle), half * sin(angle)))
		low = half
	else:
		# El cilindro con domo: el fondo, un cuenco bajo; la pared; arriba, un domo.
		var radius := 3.1
		var bowl := 0.9
		var wall := 1.9
		var dome := 2.1
		for i in range(-steps, 1):
			var angle := PI * 0.5 * float(i) / steps
			_profile.append(Vector2(radius * cos(angle), bowl * sin(angle)))
		for i in range(0, steps + 1):
			var angle := PI * 0.5 * float(i) / steps
			_profile.append(Vector2(radius * cos(angle), wall + dome * sin(angle)))
		low = bowl
		pod_y = wall * 0.5
	_center = Vector3(0.0, EMBED_BELLY + low, 0.0)
	var part := MeshInstance3D.new()
	part.mesh = _lathe_profile(_profile)
	part.material_override = _metal()
	part.position = _center
	add_child(part)
	_shell.append(part)
	var top := _center.y + _profile[_profile.size() - 1].y
	var sides: float = _plan["sides"]
	var arms: float = _plan["arms"]
	var reach: float = _plan["reach"]
	var hatches: Array[Vector3] = []
	# La de arriba asoma la mitad: ve todo alrededor.
	var main: Array = _toward(Vector3.UP)
	_pod(main[0], main[1], 0.5, PRIMARY)
	var hatch_main: Array = _toward(Vector3.DOWN)
	var main_center: Vector3 = main[0]
	hatches.append(_dome_hatch(hatch_main[0], hatch_main[1], main_center))
	top = maxf(top, main_center.y + POD)
	for heading: float in [-sides, 0.0, sides]:
		var socket := _on_body(heading, _center.y + pod_y)
		var at: Vector3 = socket[0]
		var way: Vector3 = socket[1]
		_pod(at, way, 0.25, SECONDARY)
		var pod_center := at - way * POD * 0.5
		var below := _on_body(heading * 0.5, EMBED_BELLY + 0.3)
		hatches.append(_dome_hatch(below[0], below[1], pod_center))
		if heading != 0.0:
			# El ojo del piloto: la cabeza, apenas adelante; mira al frente, un poco hacia su lado.
			var floor_at := pod_center + Vector3(0.0, -POD * 0.78, 0.0)
			var eye := floor_at + Vector3(0.0, 1.2, 0.0)
			var ahead := eye + Vector3(signf(heading) * 0.35, -0.1, -1.0)
			var aside := eye + Vector3(signf(heading) * 1.0, -0.45, -0.25)
			_eyes.append([eye + Vector3(0.0, 0.0, -0.05), ahead, aside])
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		var shoulder := _on_body(side * arms, _center.y + pod_y + 0.2)
		_big_shoulder(shoulder[0], shoulder[1], side, reach)
	for index in SUPPLIES.size():
		var heading := SUPPLY_FROM + 10.0 + index * (SUPPLY_STEP - 4.0)
		var lift := 1.0 if absf(arms) > 100.0 else 0.0
		var supply := _on_body(heading, _center.y + pod_y + lift)
		_supply(supply[0], supply[1], SUPPLIES[index])
	_legs(EMBED_BELLY + 0.2)
	for at in hatches:
		PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(at.x, 0.0, at.z), PI)
	return top


## El radio del cuerpo torneado al alto `y` (desde el centro); −1 afuera.
func _profile_radius(y: float) -> float:
	if y < _profile[0].y or y > _profile[_profile.size() - 1].y:
		return -1.0
	for i in _profile.size() - 1:
		var a := _profile[i]
		var b := _profile[i + 1]
		if y >= a.y and y <= b.y:
			if b.y - a.y < 0.0001:
				return maxf(a.x, b.x)
			return lerpf(a.x, b.x, (y - a.y) / (b.y - a.y))
	return -1.0


## UN HOMBRO MÁS GRANDE (30 en adelante): la bola y el brazo, crecidos con el cuerpo.
func _big_shoulder(at: Vector3, way: Vector3, side: float, reach: float) -> void:
	var size := SHOULDER * ARM_SCALE
	var offset := size * (2.0 * SHOULDER_OUT - 1.0)
	var center := at + way * offset
	Clay.sphere(self, size, center, DARK_METAL)
	_rim(at, way, sqrt(size * size - offset * offset) + 0.02)
	var from := center + Vector3(side * 0.2, -0.5, 0.0)
	var elbow := from + Vector3(side * 0.3, -2.7, reach)
	var fist := elbow + Vector3(0.0, -0.3, -2.0)
	_bar(from, elbow, 0.72 * ARM_SCALE, METAL)
	_bar(elbow, fist, 0.66 * ARM_SCALE, METAL)
	Clay.box(self, Vector3(0.9, 0.9, 1.0) * ARM_SCALE, fist, DARK_METAL)


## ── A ESCALA, CON BRAZOS Y PIERNAS REALES (34 en adelante) ─────────────────────────────────────────────────────

func _big_mech() -> float:
	var steps := 28
	var pod_y := 0.0
	var belly := REAL_WAIST + 0.4
	if _plan["body"] == "spheroid":
		var radius := 6.0
		var half := 3.6
		for i in range(-steps, steps + 1):
			var angle := PI * 0.5 * float(i) / steps
			_profile.append(Vector2(radius * cos(angle), half * sin(angle)))
		_center = Vector3(0.0, belly + half, 0.0)
	else:
		# El fondo chato, con el borde apenas redondeado; la pared; el domo arriba.
		var radius := 5.8
		var edge := 0.7
		var wall := 3.0
		var dome := 3.8
		_profile.append(Vector2(0.0, 0.0))
		for i in range(0, steps + 1):
			var angle := -PI * 0.5 + PI * 0.5 * float(i) / steps
			_profile.append(Vector2(radius - edge + edge * cos(angle), edge + edge * sin(angle)))
		for i in range(0, steps + 1):
			var angle := PI * 0.5 * float(i) / steps
			_profile.append(Vector2(radius * cos(angle), edge + wall + dome * sin(angle)))
		_center = Vector3(0.0, belly, 0.0)
		pod_y = edge + wall * 0.5
	var part := MeshInstance3D.new()
	part.mesh = _lathe_profile(_profile)
	part.material_override = _metal()
	part.position = _center
	add_child(part)
	_shell.append(part)
	var top := _center.y + _profile[_profile.size() - 1].y
	var layout: String = _plan["layout"]
	var hatches: Array[Vector3] = []
	var main: Array = _toward(Vector3.UP)
	_pod(main[0], main[1], 0.5, PRIMARY)
	var hatch_main: Array = _toward(Vector3.DOWN)
	hatches.append(_dome_hatch(hatch_main[0], hatch_main[1], main[0]))
	top = maxf(top, (main[0] as Vector3).y + POD)
	# Las secundarias: [rumbo, cuánto arriba de la línea media], y los hombros.
	var mid := _center.y + pod_y
	var pods: Array = []
	var arms := 90.0
	match layout:
		"sides45":
			pods = [[-45.0, 0.0], [0.0, 0.0], [45.0, 0.0]]
		"shoulders":
			pods = [[-90.0, 0.0], [0.0, 0.0], [90.0, 0.0]]
			arms = 135.0
		_:
			pods = [[-17.0, 2.0], [0.0, 0.0], [17.0, 2.0]]
			arms = 45.0
	for spot: Array in pods:
		var heading: float = spot[0]
		var socket := _on_body(heading, mid + float(spot[1]))
		var at: Vector3 = socket[0]
		var way: Vector3 = socket[1]
		_pod(at, way, 0.25, SECONDARY)
		var pod_center := at - way * POD * 0.5
		# La escotilla, en la panza, hacia el centro (no en el borde: se vería de adelante).
		var h := deg_to_rad(heading * 0.6)
		var e := deg_to_rad(-72.0)
		var below: Array = _toward(Vector3(sin(h) * cos(e), sin(e), -cos(h) * cos(e)))
		hatches.append(_dome_hatch(below[0], below[1], pod_center))
		if heading != 0.0:
			var floor_at := pod_center + Vector3(0.0, -POD * 0.78, 0.0)
			var eye := floor_at + Vector3(0.0, 1.2, 0.0)
			var ahead := eye + Vector3(signf(heading) * 0.35, -0.1, -1.0)
			var aside := eye + Vector3(signf(heading) * 0.8, -0.7, -0.6)
			_eyes.append([eye + Vector3(0.0, 0.0, -0.05), ahead, aside])
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		var shoulder := _on_body(side * arms, mid)
		_real_arm(shoulder[0], shoulder[1], side, arms > 100.0)
	for index in SUPPLIES.size():
		var heading := SUPPLY_FROM + 10.0 + index * (SUPPLY_STEP - 4.0)
		var supply := _on_body(heading, mid + (1.8 if arms > 100.0 else 0.0))
		_supply(supply[0], supply[1], SUPPLIES[index])
	_real_legs(belly)
	for at in hatches:
		PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(at.x, 0.0, at.z), PI)
	return top


## UN MIEMBRO como los de la meca (Clay.limb: un cilindro de pocas caras) de `a` a `b`.
func _limb(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var holder := Clay.limb(self, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)


## UN BRAZO COMO EL REAL, quieto en guardia: el hombro (la bola, en su enchufe), el brazo abajo y afuera hasta el codo,
## el antebrazo adelante y un poco arriba, el puño. `behind`: el hombro va atrás, el codo lo trae adelante.
func _real_arm(at: Vector3, way: Vector3, side: float, behind: bool) -> void:
	var joint_size := REAL_THICK * 0.78
	var center := at + way * joint_size * 0.3
	Clay.sphere(self, joint_size, center, JOINT)
	_rim(at, way, joint_size + 0.05)
	var to_elbow := Vector3(side * 0.45, -1.0, -0.9 if behind else 0.25).normalized() * REAL_UPPER
	var elbow := center + to_elbow
	var fist := elbow + Vector3(side * -0.1, 0.35, -1.0).normalized() * REAL_FOREARM
	_limb(center, elbow, REAL_THICK * 0.5, Clay.METAL.darkened(0.1))
	Clay.sphere(self, REAL_THICK * 0.66, elbow, JOINT)
	_limb(elbow, fist, REAL_THICK * 0.5, Clay.METAL.darkened(0.2))
	var hand := Clay.box(self, Vector3(2.3, 2.3, 2.6), fist + Vector3(0.0, 0.0, -0.9), JOINT)
	hand.basis = Basis()


## LAS PIERNAS COMO LAS REALES, paradas: la pelvis bajo el cuerpo, las caderas a los costados, la rodilla adelante, el
## pie.
func _real_legs(belly: float) -> void:
	var hip_y := REAL_WAIST - REAL_HIP.y
	Clay.box(self, Vector3(REAL_HIP.x * 2.0 - REAL_THICK, 1.8, 3.6), Vector3(0.0, hip_y + 0.3, 0.0), JOINT)
	Clay.box(self, Vector3(2.4, belly - hip_y, 2.4), Vector3(0.0, (belly + hip_y) * 0.5 + 0.3, 0.0), JOINT)
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * REAL_HIP.x, hip_y, 0.0)
		var ankle := Vector3(side * (REAL_HIP.x + 0.3), 0.7 + REAL_FOOT.y * 0.5, 0.0)
		var span := hip.distance_to(ankle)
		var bend := sqrt(maxf(REAL_THIGH * REAL_THIGH - span * span * 0.25, 0.0))
		var knee := (hip + ankle) * 0.5 + Vector3(0.0, 0.0, -bend)
		Clay.sphere(self, REAL_THICK * 0.62, hip, JOINT)
		_limb(hip, knee, REAL_THICK * 0.5, Clay.METAL.darkened(0.1))
		Clay.sphere(self, REAL_THICK * 0.62, knee, JOINT)
		_limb(knee, ankle, REAL_THICK * 0.5, Clay.METAL.darkened(0.2))
		Clay.sphere(self, REAL_THICK * 0.62 * 0.85, ankle, JOINT)
		Clay.box(self, REAL_FOOT, Vector3(ankle.x, REAL_FOOT.y * 0.5, ankle.z - 0.4), JOINT)


## ── LAS BURBUJAS EN CUELLOS (25 en adelante) ────────────────────────────────────────────────────────────────────

func _bulb_mech() -> float:
	var radius: float = _plan["radius"]
	var reach: float = _plan["half"] + _plan["band"]
	_center = Vector3(0.0, BIG_EQUATOR, 0.0)
	var part := MeshInstance3D.new()
	part.mesh = _lathe(radius, _plan["half"], _plan["band"], _plan["power"])
	part.material_override = Clay.material(METAL)
	part.position = _center
	add_child(part)
	_shell.append(part)
	var sides: float = _plan["sides"]
	var arms: float = _plan["arms"]
	var arm_reach: float = _plan["reach"]
	var shoulder_pod: bool = _plan.get("shoulder_pod", false)
	var hatches: Array[Vector3] = []
	var main: Array = _toward(Vector3.UP)
	var main_at := _bulb(main[0], main[1], PRIMARY)
	var hatch_main: Array = _toward(Vector3.DOWN)
	hatches.append(_dome_hatch(hatch_main[0], hatch_main[1], main_at))
	var top := main_at.y + POD
	for heading: float in [-sides, 0.0, sides]:
		var socket := _on_body(heading, _center.y)
		var pod_at := Vector3.ZERO
		if shoulder_pod and heading != 0.0:
			pod_at = _shoulder_pod(socket[0], socket[1], signf(heading))
		else:
			pod_at = _bulb(socket[0], socket[1], SECONDARY)
		var below := _on_body(heading * 0.5, _center.y - reach * 0.92)
		hatches.append(_dome_hatch(below[0], below[1], pod_at))
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		if not shoulder_pod:
			var height := _center.y - reach * 0.55 if _plan.get("arms_low", false) else _center.y
			var shoulder := _on_body(side * arms, height)
			_shoulder(shoulder[0], shoulder[1], side, arm_reach)
		var hip := _on_body(side * 115.0, _center.y - reach * 0.6)
		_hip(hip[0], hip[1], side)
	for index in SUPPLIES.size():
		# Los recursos, atrás en la línea media, corridos si un brazo está ahí.
		var heading := SUPPLY_FROM + 10.0 + index * (SUPPLY_STEP - 4.0)
		var supply := _on_body(heading, _center.y + (0.9 if absf(arms) > 100.0 else 0.0))
		_supply(supply[0], supply[1], SUPPLIES[index])
	for at in hatches:
		PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(at.x, 0.0, at.z), PI)
	return top


## UNA CÁPSULA EN SU CUELLO: el cuello sale del enchufe de `at` hacia `way` y en la punta, la burbuja de vidrio entera
## con su franja y el piloto adentro, mirando adelante. Devuelve el centro de la burbuja.
func _bulb(at: Vector3, way: Vector3, tint: Color) -> Vector3:
	var dir := way.normalized()
	var neck := Clay.cylinder(self, 0.6, NECK + 0.3, at + dir * (NECK + 0.3) * 0.5 - dir * 0.15, DARK_METAL)
	neck.basis = _pointing(dir)
	_rim(at, dir, 0.62)
	var center := at + dir * (NECK + POD * 0.8)
	var glass := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = POD
	mesh.height = POD * 2.0
	glass.mesh = mesh
	glass.material_override = _glass
	glass.position = center
	add_child(glass)
	var band := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = POD - 0.03
	ring.outer_radius = POD + 0.06
	band.mesh = ring
	band.material_override = Clay.material(tint)
	band.transform = Transform3D(_pointing(dir), center - dir * POD * 0.55)
	add_child(band)
	var floor_at := center + Vector3(0.0, -POD * 0.78, 0.0)
	Clay.cylinder(self, 0.45, 0.05, floor_at, DARK_METAL)
	_seated(self, floor_at + Vector3(0.0, 0.0, 0.12))
	return center


## EL HOMBRO ES LA CÁPSULA (la 28): del enchufe sale un cuello y un esferoide de metal más grande que la burbuja, con el
## frente de vidrio, el piloto adentro y el brazo colgando de abajo. Devuelve el centro.
func _shoulder_pod(at: Vector3, way: Vector3, side: float) -> Vector3:
	var dir := way.normalized()
	var size := 1.25
	var neck := Clay.cylinder(self, 0.7, NECK, at + dir * NECK * 0.5 - dir * 0.15, DARK_METAL)
	neck.basis = _pointing(dir)
	_rim(at, dir, 0.72)
	var center := at + dir * (NECK + size * 0.7)
	for half: Array in [[_glass, Basis(Vector3.RIGHT, -PI * 0.5)], [Clay.material(DARK_METAL), Basis(Vector3.RIGHT, PI * 0.5)]]:
		var part := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = size
		mesh.height = size
		mesh.is_hemisphere = true
		part.mesh = mesh
		part.material_override = half[0]
		part.transform = Transform3D(half[1], center)
		add_child(part)
	var band := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = size - 0.03
	ring.outer_radius = size + 0.08
	band.mesh = ring
	band.material_override = Clay.material(SECONDARY)
	band.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), center)
	add_child(band)
	var floor_at := center + Vector3(0.0, -size * 0.7, -0.1)
	Clay.cylinder(self, 0.5, 0.05, floor_at, DARK_METAL)
	_seated(self, floor_at + Vector3(0.0, 0.0, 0.12))
	# La articulación del brazo, abajo del hombro.
	var joint := center + Vector3(side * 0.2, -size - 0.2, 0.2)
	Clay.sphere(self, 0.55, joint, DARK_METAL)
	_arm_from(joint + Vector3(0.0, -0.3, 0.0), side, 0.0)
	return center


## UN DOMO (media cápsula) en el enchufe de `at` hacia `way`: medio vidrio afuera, alargado `long` veces hacia adelante
## (sobre la piel), con su aro y su franja; el piloto sentado mirando adelante, la cabeza adentro del domo. Devuelve su
## alto de arriba.
func _dome(at: Vector3, way: Vector3, long: float, tint: Color) -> float:
	var up := way.normalized()
	var ahead := Vector3.FORWARD - up * Vector3.FORWARD.dot(up)
	if ahead.length() < 0.2:
		ahead = Vector3.UP - up * Vector3.UP.dot(up)
	ahead = ahead.normalized()
	var across := up.cross(ahead).normalized()
	# La base: X de costado, Y hacia afuera, Z hacia adelante (alargada).
	var basis := Basis(across * DOME, up * DOME, ahead * DOME * long)
	var glass := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 1.0
	mesh.is_hemisphere = true
	glass.mesh = mesh
	glass.material_override = _glass
	glass.transform = Transform3D(basis, at)
	add_child(glass)
	for ring_at: Array in [[0.0, RIM, 0.14], [0.08, tint, 0.08]]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.0
		torus.outer_radius = 1.0 + float(ring_at[2])
		ring.mesh = torus
		ring.material_override = Clay.material(ring_at[1])
		ring.transform = Transform3D(Basis(across, up, ahead * long), at + up * float(ring_at[0]))
		add_child(ring)
	# El piloto: con la cabeza y los hombros adentro del domo.
	var floor_at := at + up * 0.15 + Vector3(0.0, -0.75, 0.0)
	if up.y > 0.9:
		floor_at = at + Vector3(0.0, -0.75, 0.0)
	Clay.cylinder(self, 0.45, 0.05, floor_at, DARK_METAL)
	_seated(self, floor_at + Vector3(0.0, 0.0, 0.12))
	return at.y + DOME * maxf(up.y, 0.0)


## UNA ESCOTILLA DE ABAJO en `at` (hacia `way`), con el tubo que sube a su domo en `dome_at`. Devuelve dónde está.
func _dome_hatch(at: Vector3, way: Vector3, dome_at: Vector3) -> Vector3:
	_rim(at, way, HATCH)
	var lid := Clay.cylinder(self, HATCH, 0.08, at + way * 0.02, DARK_METAL)
	lid.basis = _pointing(way)
	var to := dome_at + Vector3(0.0, -0.8, 0.0)
	var tube := Clay.cylinder(self, HATCH * 0.9, maxf(at.distance_to(to), 0.1), (at + to) * 0.5, DARK_METAL)
	tube.basis = _pointing(to - at)
	return at


## Donde el cuerpo colgado corta el rayo que sale del centro hacia `way`, y hacia afuera ahí: [punto, normal].
func _toward(way: Vector3) -> Array:
	var dir := way.normalized()
	var shape: String = _plan["shape"]
	if shape == "egg":
		var radius: float = _plan["radius"]
		var high: float = _plan["high"]
		var low: float = _plan["low"]
		var scale := Vector3(radius, high if dir.y >= 0.0 else low, radius)
		var at := _center + dir / (dir / scale).length()
		var local := at - _center
		return [at, Vector3(local.x / (scale.x * scale.x), local.y / (scale.y * scale.y),
			local.z / (scale.z * scale.z)).normalized()]
	# La cápsula: por mitades, hasta dar con la piel.
	var near := 0.0
	var far := 12.0
	for i in 40:
		var t := (near + far) * 0.5
		if _inside(_center + dir * t):
			near = t
		else:
			far = t
	var hit := _center + dir * near
	if shape in ["spheroid", "domes", "bulbs", "profile"]:
		# La normal: hacia donde más crece la forma.
		var e := 0.01
		var grow := Vector3(_shape_value(hit + Vector3(e, 0, 0)) - _shape_value(hit - Vector3(e, 0, 0)),
			_shape_value(hit + Vector3(0, e, 0)) - _shape_value(hit - Vector3(0, e, 0)),
			_shape_value(hit + Vector3(0, 0, e)) - _shape_value(hit - Vector3(0, 0, e)))
		return [hit, grow.normalized()]
	return [hit, (hit - _spine_point(hit)).normalized()]


func _inside(at: Vector3) -> bool:
	if _plan["shape"] == "profile":
		return _shape_value(at) < 0.0
	if _plan["shape"] in ["spheroid", "domes", "bulbs"]:
		return _shape_value(at) < 1.0
	return _skin_distance(at) < 0.0


## El esferoide o superelipsoide: menos de 1 adentro. El perfil torneado: negativo adentro.
func _shape_value(at: Vector3) -> float:
	if _plan["shape"] == "profile":
		var flat := at - _center
		return Vector2(flat.x, flat.z).length() - _profile_radius(flat.y)
	var radius: float = _plan["radius"]
	var half: float = _plan["half"]
	var band: float = _plan["band"]
	var power: float = _plan["power"]
	var local := at - _center
	var r := Vector2(local.x, local.z).length()
	var y := maxf(absf(local.y) - band, 0.0)
	return pow(r / radius, power) + pow(y / half, power)


## La distancia a la piel de la cápsula (negativa adentro).
func _skin_distance(at: Vector3) -> float:
	var radius: float = _plan["radius"]
	return at.distance_to(_spine_point(at)) - radius


## El punto más cercano del eje de la cápsula (parada: vertical; acostada: de lado a lado).
func _spine_point(at: Vector3) -> Vector3:
	var half_length: float = _plan["half"]
	var axis := Vector3.UP if _plan["shape"] == "capsule" else Vector3.RIGHT
	var along := clampf((at - _center).dot(axis), -half_length, half_length)
	return _center + axis * along


## Un enchufe del cuerpo colgado a `heading` grados del frente, que toque la piel a la altura `height`.
func _on_body(heading: float, height: float) -> Array:
	var h := deg_to_rad(heading)
	var low := deg_to_rad(-88.0)
	var high := deg_to_rad(88.0)
	for i in 40:
		var e := (low + high) * 0.5
		var hit: Array = _toward(Vector3(sin(h) * cos(e), sin(e), -cos(h) * cos(e)))
		if (hit[0] as Vector3).y < height:
			low = e
		else:
			high = e
	var e_final := (low + high) * 0.5
	return _toward(Vector3(sin(h) * cos(e_final), sin(e_final), -cos(h) * cos(e_final)))


## UNA CADERA (cuerpo colgado): una bola en su enchufe, como el hombro, y la pierna que sale hacia el costado, la
## rodilla arriba, y baja al pie.
func _hip(at: Vector3, way: Vector3, side: float) -> void:
	var offset := SHOULDER * (2.0 * SHOULDER_OUT - 1.0)
	var center := at + way * offset
	Clay.sphere(self, SHOULDER, center, DARK_METAL)
	_rim(at, way, sqrt(SHOULDER * SHOULDER - offset * offset) + 0.02)
	var knee := center + Vector3(side * 1.6, 0.35, -0.2)
	var foot := Vector3(knee.x + side * 0.3, 0.4, knee.z - 0.1)
	_bar(center, knee, 0.8, METAL)
	_bar(knee, foot, 0.72, METAL)
	Clay.box(self, Vector3(0.9, 0.9, 0.9), knee, DARK_METAL)
	Clay.box(self, Vector3(1.0, 0.4, 1.6), Vector3(foot.x, 0.2, foot.z - 0.2), DARK_METAL)


## Un punto de la esfera del cuerpo, a `heading` grados del frente (positivo a la derecha) y `height` grados de altura.
func _on_sphere(heading: float, height: float) -> Array:
	var h := deg_to_rad(heading)
	var e := deg_to_rad(height)
	var way := Vector3(sin(h) * cos(e), sin(e), -cos(h) * cos(e))
	return [_center + way * BODY, way]


## Hacia afuera, acostado, a `heading` grados del frente.
func _flat(heading: float) -> Vector3:
	var h := deg_to_rad(heading)
	return Vector3(sin(h), 0.0, -cos(h))


## EL ARO DE UN ENCHUFE: donde la pieza se mete en el cuerpo, igual para todo (oscuro, de `radius`).
func _rim(at: Vector3, way: Vector3, radius: float) -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius
	mesh.outer_radius = radius + 0.14
	ring.mesh = mesh
	ring.material_override = Clay.material(RIM)
	ring.transform = Transform3D(_pointing(way), at)
	add_child(ring)


## Una base que lleva +Y a `way`.
func _pointing(way: Vector3) -> Basis:
	var dir := way.normalized()
	if dir.dot(Vector3.UP) > 0.999:
		return Basis()
	if dir.dot(Vector3.UP) < -0.999:
		return Basis(Vector3.RIGHT, PI)
	return Basis(Quaternion(Vector3.UP, dir))


## UNA CÁPSULA en el enchufe de `at` hacia `way`, asomando `out` de su diámetro: la mitad de afuera de vidrio, la de
## adentro de metal, una franja de su color en el medio, el piloto sentado mirando adelante. Devuelve su alto de arriba.
func _pod(at: Vector3, way: Vector3, out: float, tint: Color) -> float:
	var center := at + way * POD * (2.0 * out - 1.0)
	var turn := _pointing(way)
	for half: Array in [[_glass, Basis()], [_pod_metal(), Basis(Vector3.RIGHT, PI)]]:
		var part := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = POD
		mesh.height = POD
		mesh.is_hemisphere = true
		part.mesh = mesh
		part.material_override = half[0]
		part.transform = Transform3D(turn * (half[1] as Basis), center)
		add_child(part)
	var band := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = POD - 0.03
	ring.outer_radius = POD + 0.06
	band.mesh = ring
	band.material_override = Clay.material(tint)
	band.transform = Transform3D(turn, center)
	add_child(band)
	var offset := POD * (2.0 * out - 1.0)
	_rim(at, way, sqrt(maxf(POD * POD - offset * offset, 0.04)) + 0.02)
	# El piso de la cápsula y el piloto.
	var floor_at := center + Vector3(0.0, -POD * 0.78, 0.0)
	Clay.cylinder(self, 0.45, 0.05, floor_at, DARK_METAL)
	_seated(self, floor_at + Vector3(0.0, 0.0, 0.12))
	return center.y + POD


## UN HOMBRO: una bola en su enchufe, el brazo colgando y el puño adelante.
func _shoulder(at: Vector3, way: Vector3, side: float, reach := 0.4) -> void:
	var offset := SHOULDER * (2.0 * SHOULDER_OUT - 1.0)
	var center := at + way * offset
	Clay.sphere(self, SHOULDER, center, DARK_METAL)
	_rim(at, way, sqrt(SHOULDER * SHOULDER - offset * offset) + 0.02)
	_arm_from(center + Vector3(side * 0.15, -0.4, 0.0), side, reach)


## El brazo colgando de `from`: el codo abajo (y `reach` hacia atrás, negativo adelante), el puño al frente.
func _arm_from(from: Vector3, side: float, reach: float) -> void:
	var elbow := from + Vector3(side * 0.25, -2.0, reach)
	var fist := elbow + Vector3(0.0, -0.2, -1.5)
	_bar(from, elbow, 0.72, METAL)
	_bar(elbow, fist, 0.66, METAL)
	Clay.box(self, Vector3(0.9, 0.9, 1.0), fist, DARK_METAL)


## UN RECURSO (kit, munición, batería): un cubo de 63 cm metido a medias en su enchufe, con su aro.
func _supply(at: Vector3, way: Vector3, kind: String) -> void:
	var cube := Clay.box(self, Vector3.ONE * SUPPLY, at + way * SUPPLY * 0.12, SUPPLY_COLORS[kind])
	cube.basis = _pointing(way)
	_rim(at, way, SUPPLY * 0.72)


## LA ESCOTILLA DE ABAJO: un enchufe más, con su tapa, y el tubo que sube a la principal (se ve con el cuerpo
## transparente).
func _hatch(at: Vector3, way: Vector3, main_center: Vector3) -> void:
	_rim(at, way, HATCH)
	var lid := Clay.cylinder(self, HATCH, 0.08, at + way * 0.02, DARK_METAL)
	lid.basis = _pointing(way)
	var low := at.y + 0.05
	var high := main_center.y - POD * 0.7
	if high > low:
		_shell.append(Clay.cylinder(self, HATCH * 0.95, high - low, Vector3(0.0, (low + high) * 0.5, 0.0), DARK_METAL))


## Las piernas: una cadera debajo del cuerpo y dos patas.
func _legs(belly: float) -> void:
	var hip_at := belly + 0.15
	Clay.box(self, Vector3(2.8, 0.7, 1.6), Vector3(0.0, hip_at, 0.3), DARK_METAL)
	for side: float in [-1.0, 1.0]:
		var from := Vector3(side * 1.1, hip_at - 0.2, 0.3)
		var foot := Vector3(side * 1.2, 0.4, 0.3)
		var knee := Vector3(foot.x, (from.y + foot.y) * 0.5, -0.1)
		_bar(from, knee, 0.8, METAL)
		_bar(knee, foot, 0.72, METAL)
		Clay.box(self, Vector3(0.9, 0.9, 0.9), knee, DARK_METAL)
		Clay.box(self, Vector3(1.0, 0.4, 1.6), Vector3(foot.x, 0.2, 0.0), DARK_METAL)


## ── LA ENTRADA Y LA EYECCIÓN (la 8) ──────────────────────────────────────────────────────────────────────────────

## Uno parado bajo la escotilla (E, sube por el tubo a la principal) y uno frente a la del medio (E en la cápsula).
## La eyección, con cápsulas fantasma: la principal derecho para arriba; las secundarias salen hacia afuera y dan la
## vuelta para arriba.
func _entry_and_ejection() -> void:
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(0.0, 0.0, 0.0), PI)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(0.0, 0.0, -3.6), PI)
	_trail([Vector3(0.0, 1.9, 0.0), Vector3(0.0, _center.y - BODY, 0.0)])
	_trail([Vector3(0.0, 1.6, -3.3), _center + Vector3(0.0, 0.0, -BODY - 0.2)])
	var spread: float = _plan["spread"]
	var main_center := _center + Vector3.UP * BODY
	var points: Array[Vector3] = [main_center]
	for step: float in [2.6, 5.2, 7.8]:
		_ghost_pod(main_center + Vector3.UP * step)
		points.append(main_center + Vector3.UP * step)
	_trail(points)
	for heading: float in [-spread, 0.0, spread]:
		var start: Vector3 = _on_sphere(heading, 0.0)[0]
		var way: Vector3 = _on_sphere(heading, 0.0)[1]
		var path: Array[Vector3] = [start]
		# Afuera primero, después para arriba, volviendo un poco por encima de la meca.
		for t: float in [0.25, 0.5, 0.75, 1.0]:
			var at := start + way * (3.2 * sin(t * PI * 0.75)) + Vector3.UP * (7.0 * t * t + 1.0 * t)
			path.append(at)
		for index in [2, 4]:
			_ghost_pod(path[index])
		_trail(path)


func _ghost_pod(at: Vector3) -> void:
	var part := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = POD
	mesh.height = POD * 2.0
	part.mesh = mesh
	part.material_override = _ghost
	part.position = at
	add_child(part)


## Una línea de puntos amarillos por `points`.
func _trail(points: Array[Vector3]) -> void:
	for index in points.size() - 1:
		var a := points[index]
		var b := points[index + 1]
		var count := maxi(int(a.distance_to(b) / 0.45), 1)
		for step in count:
			Clay.sphere(self, 0.09, a.lerp(b, (step + 0.5) / count), PATH)


## ── LO DE SIEMPRE ────────────────────────────────────────────────────────────────────────────────────────────────

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


## Una barra cuadrada de `a` a `b`, de `thick` de lado.
func _bar(a: Vector3, b: Vector3, thick: float, color: Color) -> void:
	var part := Clay.box(self, Vector3(thick, thick, a.distance_to(b)), (a + b) * 0.5, color)
	part.basis = Basis.looking_at(b - a, Vector3.RIGHT if absf((b - a).normalized().y) > 0.9 else Vector3.UP)


func _transparent(on: bool) -> void:
	for part in _shell:
		part.material_override = _see_through if on else _metal()


func _metal() -> StandardMaterial3D:
	return Clay.material(METAL)


## El metal de la cápsula: de dos caras en las 30 en adelante (el cuerpo no: desde adentro no se ve, como si tuviera el
## hueco de la cápsula recortado).
func _pod_metal() -> StandardMaterial3D:
	return _solid if _solid != null else Clay.material(METAL)


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
	var path := "%s/capsulas_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
