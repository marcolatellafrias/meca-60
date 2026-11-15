class_name ArmedMaquettes
extends RefCounted

## LOS JEFES CON PERSONALIDAD (15/11/2026): maquetas de arcilla, quietas, todas con LA MISMA BASE (cuatro patas, dos
## brazos y un accesorio en el techo) y formas simples, no de insecto. El usuario: «un boss divertido que no sea tan
## monotemático… distintas formas de moverse que puedan cambiar en base a la fase, y distintas formas de atacar… distintas
## armas en distintos brazos… a qué brazo nos conviene romperle primero»; «empezando con uno de 4 patas, con 2 brazos y un
## attachment en el techo… formas más simples»; «personalidades a cada meca… un caño de escape, algo en el pecho como una
## furnace que tal vez se abre, o cuando entra en ira… se cambia de color, una cabeza con ojos que tiran láser».
##
## Cada una se arma con un KIT (torso, patas, armas, techo, cabeza, pecho) según su ficha (`ALL`). Dos estados: el normal
## (izquierda) y CON IRA (derecha): cambia de color, cambia la pose (cómo se mueve en esa fase) y se le prende lo suyo.
## Las baterías (una por componente: las patas, cada brazo, el techo; siempre en el mismo lugar) van después.

const FLAME := Color(1.0, 0.5, 0.1, 0.5)
const SMOKE := Color(0.35, 0.35, 0.37, 0.45)
const SPARK := Color(0.5, 0.75, 1.0)

## LAS FICHAS. `torso`: box, tall, drum, dome o wedge, de `size` (m), con el centro a `height`. `legs`: pillar, stilt,
## crab, tread o dog. Las armas (`left`, `right`): hammer, flamer, shield, cannon, claw_big, claw_small, drill, prong,
## flail, saw o gatling. `roof`: stacks, radar, mortar, lamp, coil o rack. `head`: eyes, lasers (ojos que tiran láser) o nada. `chest`: furnace, grille,
## core o nada. `rage`: la pose con ira (charge, crouch, side, dig, float o plant).
const ALL: Array[Dictionary] = [
	{"name": "Fogonero", "torso": "box", "size": Vector3(18, 12, 16), "height": 22.0, "legs": "pillar",
		"left": "hammer", "right": "flamer", "roof": "stacks", "head": "", "chest": "furnace", "exhaust": true,
		"color": Color(0.5, 0.46, 0.42), "rage_color": Color(0.55, 0.2, 0.12), "rage": "charge",
		"states": ["normal: camina pesado", "con ira: abre el horno y embiste"], "lines": [
		"pesado y lento; le sale humo por las chimeneas y los caños de atrás",
		"brazo izquierdo, MARTILLO: golpe al piso con onda · brazo derecho, LANZALLAMAS: barre un cono adelante",
		"techo, CHIMENEAS: con ira escupen brasas que caen alrededor",
		"CON IRA abre el horno del pecho (brilla), se pone al rojo y embiste de frente, agachado"]},
	{"name": "Vigía", "torso": "tall", "size": Vector3(12, 16, 12), "height": 32.0, "legs": "stilt",
		"left": "shield", "right": "cannon", "roof": "radar", "head": "lasers", "chest": "grille", "exhaust": false,
		"color": Color(0.46, 0.5, 0.55), "rage_color": Color(0.25, 0.27, 0.36), "rage": "crouch",
		"states": ["normal: alto, se cubre", "con ira: tira el escudo y se agacha"], "lines": [
		"alto y flaco; la cabeza sigue a la meca y los ojos tiran láser",
		"brazo izquierdo, ESCUDO: se cubre y empuja · brazo derecho, CAÑÓN LARGO: de lejos, lento y fuerte",
		"techo, RADAR: marca en el piso dónde va a caer el cañonazo",
		"CON IRA tira el escudo, se agacha con las patas abiertas y salta de costado; los ojos barren con láser"]},
	{"name": "Tenaza", "torso": "box", "size": Vector3(24, 8, 16), "height": 14.0, "legs": "crab",
		"left": "claw_big", "right": "claw_small", "roof": "mortar", "head": "eyes", "chest": "", "exhaust": false,
		"color": Color(0.58, 0.42, 0.36), "rage_color": Color(0.75, 0.25, 0.12), "rage": "side",
		"states": ["normal: bajo y ancho", "con ira: pinzas arriba, de costado"], "lines": [
		"bajo y ancho, las patas abiertas; el cangrejo, en formas simples",
		"brazo izquierdo, PINZA GRANDE: agarra a la meca y la aprieta · brazo derecho, PINZA CHICA: cortes rápidos",
		"techo, MORTERO: cuatro tubos que tiran en parábola",
		"CON IRA levanta las dos pinzas abiertas y corre de costado; se pone rojo"]},
	{"name": "Minero", "torso": "wedge", "size": Vector3(16, 10, 22), "height": 12.0, "legs": "tread",
		"left": "claw_small", "right": "drill", "roof": "lamp", "head": "", "chest": "grille", "exhaust": true,
		"color": Color(0.75, 0.62, 0.25), "rage_color": Color(0.5, 0.35, 0.15), "rage": "dig",
		"states": ["normal: rueda sobre orugas", "con ira: se clava y perfora"], "lines": [
		"bajo, en cuña, con orugas en las patas: rueda en vez de caminar",
		"brazo izquierdo, GARRA: agarra rocas y las tira · brazo derecho, TALADRO: embiste y perfora",
		"techo, REFLECTOR: encandila (la vista se pone blanca si te mira)",
		"CON IRA se clava con el taladro en el piso y salen grietas que se levantan alrededor"]},
	{"name": "Campanario", "torso": "dome", "size": Vector3(18, 12, 18), "height": 24.0, "legs": "dog",
		"left": "prong", "right": "flail", "roof": "coil", "head": "", "chest": "core", "exhaust": false,
		"color": Color(0.5, 0.52, 0.6), "rage_color": Color(0.3, 0.36, 0.62), "rage": "float",
		"states": ["normal: camina", "con ira: recoge las patas y flota"], "lines": [
		"una cúpula sobre cuatro patas; el núcleo del pecho brilla celeste",
		"brazo izquierdo, HORQUILLA: un rayo de punta a punta · brazo derecho, BOLA CON CADENA: barre alrededor",
		"techo, BOBINA: carga y suelta rayos al piso en círculo",
		"CON IRA recoge las patas, flota sobre un anillo de energía y se desliza; lo que toca el anillo, da"]},
	{"name": "Artillero", "torso": "box", "size": Vector3(20, 9, 18), "height": 18.0, "legs": "dog",
		"left": "saw", "right": "gatling", "roof": "rack", "head": "eyes", "chest": "", "exhaust": true,
		"color": Color(0.45, 0.48, 0.38), "rage_color": Color(0.5, 0.3, 0.2), "rage": "plant",
		"states": ["normal: anda rápido", "con ira: se planta y es una torreta"], "lines": [
		"ágil y bajo, corre y frena; una cabeza chica que apunta",
		"brazo izquierdo, SIERRA: de cerca · brazo derecho, AMETRALLADORA: ráfagas largas que barren",
		"techo, LANZAMISILES: una salva que persigue",
		"CON IRA clava las patas y se planta: no camina, gira; levanta los brazos y tira todo a la vez"]},
]


## ARMA la ficha `index`, normal o con ira, en `p`.
static func build(index: int, p: Node3D, rage: bool) -> void:
	var spec := ALL[index]
	var size: Vector3 = spec["size"]
	var half := size * 0.5
	var height := float(spec["height"])
	var pose := str(spec["rage"]) if rage else ""
	var hull: Color = spec["rage_color"] if rage else spec["color"]
	var yaw := 0.0
	var pitch := 0.0
	match pose:
		"charge":
			height -= 5.0
			pitch = -14.0
		"crouch":
			height -= 12.0
		"side":
			yaw = 90.0
			height -= 2.0
		"dig":
			height -= 3.0
			pitch = -18.0
		"float":
			height += 6.0
		"plant":
			height -= 5.0
	var body := Node3D.new()
	body.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0)), Vector3.UP * height)
	p.add_child(body)
	_torso(body, str(spec["torso"]), size, hull)
	# Las patas, del torso al piso.
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var hip := body.transform * Vector3(x * half.x * 0.7, -half.y, z * half.z * 0.6)
			_leg(p, str(spec["legs"]), hip, Vector3(x, 0.0, z), pose, hull)
	# Los brazos y sus armas.
	for side: float in [-1.0, 1.0]:
		var weapon := str(spec["left"] if side < 0.0 else spec["right"])
		if rage and weapon == "shield":
			# El Vigía tira el escudo con ira: queda en el piso.
			var dropped := Clay.box(p, Vector3(10.0, 1.0, 13.0), Vector3(side * 16.0, 0.5, -14.0), hull.darkened(0.2))
			dropped.rotation_degrees = Vector3(0.0, 20.0, 4.0)
			weapon = ""
		_arm(p, body, side, half, weapon, rage, hull)
	_roof(p, body, str(spec["roof"]), half, rage, hull)
	if str(spec["head"]) != "":
		_head(p, body, half, rage, hull, str(spec["head"]) == "lasers")
	_chest(p, body, str(spec["chest"]), half, rage)
	if spec["exhaust"]:
		for x: float in [-1.0, 1.0]:
			var from := body.transform * Vector3(x * half.x * 0.5, half.y * 0.3, half.z)
			var to := body.transform * Vector3(x * half.x * 0.55, half.y + 4.0, half.z + 2.5)
			BossMaquettes._rod(p, from, to, 0.9, Clay.DARK)
			if rage:
				_cone(p, to, to + Vector3(0.0, 6.0, 2.0), 1.3, FLAME)
			else:
				Clay.sphere(p, 1.6, to + Vector3(0.0, 2.0, 1.0), SMOKE)
	if pose == "float":
		_glow_ring(p, 14.0, Vector3(0.0, 3.0, 0.0), SPARK)
	if pose == "dig":
		for i in 5:
			var out := Vector3.FORWARD.rotated(Vector3.UP, i * 0.9 - 1.8)
			var crack := Clay.box(p, Vector3(2.0, 3.0, 9.0), out * 24.0 + Vector3.UP * 0.8, BossMaquettes.STONE.darkened(0.2))
			crack.basis = Basis.looking_at(out, Vector3.UP) * Basis(Vector3.RIGHT, 0.4)


## ── EL TORSO ─────────────────────────────────────────────────────────────────────────────────────────────────────

static func _torso(body: Node3D, kind: String, size: Vector3, color: Color) -> void:
	match kind:
		"drum":
			Clay.cylinder(body, size.y * 0.5, size.x, Vector3.ZERO, color, Vector3(0.0, 0.0, 90.0))
		"dome":
			var top := Clay.sphere(body, size.x * 0.5, Vector3(0.0, -size.y * 0.15, 0.0), color)
			top.scale = Vector3(1.0, size.y / size.x * 1.3, 1.0)
			Clay.cylinder(body, size.x * 0.5, 2.0, Vector3(0.0, -size.y * 0.4, 0.0), color.darkened(0.25))
		"wedge":
			Clay.box(body, Vector3(size.x, size.y * 0.6, size.z), Vector3(0.0, -size.y * 0.2, 0.0), color)
			Clay.box(body, Vector3(size.x * 0.9, size.y * 0.5, size.z * 0.55), Vector3(0.0, size.y * 0.3, size.z * 0.2), color.lightened(0.05))
			var slope := Clay.box(body, Vector3(size.x * 0.9, 0.8, size.z * 0.55), Vector3(0.0, size.y * 0.15, -size.z * 0.32), color.darkened(0.1))
			slope.rotation_degrees = Vector3(-28.0, 0.0, 0.0)
		_:
			Clay.box(body, size, Vector3.ZERO, color)
			# Un canto más oscuro abajo: que no sea una caja pelada.
			Clay.box(body, Vector3(size.x + 0.4, 1.2, size.z + 0.4), Vector3(0.0, -size.y * 0.5 + 0.6, 0.0), color.darkened(0.3))


## ── LAS PATAS ────────────────────────────────────────────────────────────────────────────────────────────────────

static func _leg(p: Node3D, kind: String, hip: Vector3, out: Vector3, pose: String, color: Color) -> void:
	var dark := Clay.DARK
	Clay.box(p, Vector3(4.0, 3.0, 4.0), hip, color.darkened(0.3))
	if pose == "float":
		# Recogidas debajo del cuerpo.
		var tucked := hip + Vector3(out.x * 3.0, -5.0, out.z * 3.0)
		BossMaquettes._rod(p, hip, tucked, 1.4, dark)
		Clay.sphere(p, 2.0, tucked, dark)
		return
	var spread := 1.5 if pose in ["crouch", "plant"] else 1.0
	match kind:
		"pillar":
			var foot := Vector3(hip.x + out.x * 2.0 * spread, 0.0, hip.z + out.z * 2.0)
			BossMaquettes._rod(p, hip, foot + Vector3.UP * 2.0, 2.6, dark)
			Clay.cylinder(p, 4.2, 2.0, foot + Vector3.UP, dark.lightened(0.05))
		"stilt":
			var foot := Vector3(hip.x + out.x * 8.0 * spread, 0.0, hip.z + out.z * 6.0 * spread)
			var knee := hip.lerp(foot, 0.45) + Vector3(out.x * 4.0, 2.0, 0.0)
			BossMaquettes._rod(p, hip, knee, 1.3, dark)
			Clay.sphere(p, 1.8, knee, dark.lightened(0.1))
			BossMaquettes._rod(p, knee, foot + Vector3.UP, 1.1, dark)
			Clay.cylinder(p, 2.6, 1.0, foot + Vector3.UP * 0.5, dark)
		"crab":
			var foot := Vector3(hip.x + out.x * 16.0, 0.0, hip.z + out.z * 5.0)
			var knee := Vector3(hip.x + out.x * 9.0, hip.y + 7.0, hip.z + out.z * 3.0)
			BossMaquettes._rod(p, hip, knee, 1.8, dark)
			Clay.sphere(p, 2.3, knee, dark.lightened(0.1))
			BossMaquettes._rod(p, knee, foot + Vector3.UP, 1.5, dark)
			Clay.cylinder(p, 2.8, 1.0, foot + Vector3.UP * 0.5, dark)
		"tread":
			var foot := Vector3(hip.x + out.x * 3.0, 0.0, hip.z + out.z * 2.0)
			BossMaquettes._rod(p, hip, foot + Vector3.UP * 3.0, 1.8, dark)
			var track := Clay.box(p, Vector3(3.5, 3.5, 9.0), foot + Vector3.UP * 1.75, dark.lightened(0.05))
			track.rotation_degrees = Vector3.ZERO
			for i in 3:
				Clay.cylinder(p, 1.6, 3.8, foot + Vector3(0.0, 1.75, -3.0 + i * 3.0), Clay.METAL, Vector3(0.0, 0.0, 90.0))
		_:
			# "dog": el muslo para adelante, la rodilla para atrás, el pie debajo.
			var foot := Vector3(hip.x + out.x * 5.0 * spread, 0.0, hip.z + out.z * 4.0 * spread)
			var knee := hip.lerp(foot, 0.5) + Vector3(out.x * 2.0, 0.0, -out.z * 0.0 + 4.0 * signf(out.z))
			BossMaquettes._rod(p, hip, knee, 1.8, dark)
			Clay.sphere(p, 2.3, knee, dark.lightened(0.1))
			BossMaquettes._rod(p, knee, foot + Vector3.UP * 1.5, 1.5, dark)
			Clay.cylinder(p, 3.0, 1.5, foot + Vector3.UP * 0.75, dark)
			if pose == "plant":
				_cone(p, foot + Vector3.UP * 1.0, foot + Vector3.DOWN * 0.5, 1.2, Clay.METAL)


## ── LOS BRAZOS Y SUS ARMAS ───────────────────────────────────────────────────────────────────────────────────────

static func _arm(p: Node3D, body: Node3D, side: float, half: Vector3, weapon: String, rage: bool, color: Color) -> void:
	var shoulder := body.transform * Vector3(side * (half.x + 1.5), half.y * 0.3, -half.z * 0.3)
	Clay.sphere(p, 2.6, shoulder, color.darkened(0.2))
	# Con ira, lo que se blande va arriba; lo que apunta, al frente; el taladro, clavado en el piso.
	var elbow := shoulder + Vector3(side * 3.0, -6.0, -2.0)
	var hand := elbow + Vector3(0.0, -1.0, -8.0)
	if rage and weapon in ["flamer", "cannon", "gatling"]:
		elbow = shoulder + Vector3(side * 3.0, -2.0, -4.0)
		hand = elbow + Vector3(0.0, -0.5, -8.0)
	elif rage and weapon == "drill":
		elbow = shoulder + Vector3(side * 2.0, -5.0, -3.0)
		hand = elbow + Vector3(0.0, -6.0, -5.0)
	elif rage:
		elbow = shoulder + Vector3(side * 3.0, 2.0, -4.0)
		hand = elbow + Vector3(0.0, 5.0, -6.0)
	BossMaquettes._rod(p, shoulder, elbow, 1.6, Clay.DARK)
	Clay.sphere(p, 1.9, elbow, Clay.DARK.lightened(0.1))
	BossMaquettes._rod(p, elbow, hand, 1.4, Clay.DARK)
	var way := (hand - elbow).normalized()
	match weapon:
		"hammer":
			BossMaquettes._rod(p, hand, hand + way * 6.0, 0.5, Clay.DARK)
			var head := Clay.box(p, Vector3(5.0, 5.0, 8.0), hand + way * 7.0, color.darkened(0.35))
			head.basis = _axis_basis(way)
		"flamer":
			BossMaquettes._rod(p, hand, hand + way * 4.0, 1.2, Clay.YELLOW.darkened(0.3))
			var made1 := Clay.cylinder(p, 1.6, 1.0, hand + way * 4.0, Clay.DARK)
			made1.basis = _axis_basis(way)
			if rage:
				_cone(p, hand + way * 4.5, hand + way * 22.0, 5.0, FLAME)
			else:
				_cone(p, hand + way * 4.5, hand + way * 8.0, 1.2, FLAME)
		"shield":
			var plate := Clay.box(p, Vector3(10.0, 13.0, 1.0), hand + way * 1.5 + Vector3(side * -2.0, 2.0, 0.0), color.lightened(0.1))
			plate.basis = Basis.looking_at(way.slide(Vector3.UP).normalized(), Vector3.UP)
		"cannon":
			BossMaquettes._rod(p, hand, hand + way * 16.0, 1.2, Clay.DARK)
			var made2 := Clay.cylinder(p, 1.9, 4.0, hand + way * 15.0, Clay.DARK.lightened(0.1))
			made2.basis = _axis_basis(way)
			var made3 := Clay.box(p, Vector3(3.0, 3.0, 5.0), hand, color.darkened(0.2))
			made3.basis = _axis_basis(way)
		"claw_big", "claw_small":
			var big := weapon == "claw_big"
			var length := 11.0 if big else 6.0
			var palm := Clay.box(p, Vector3(1.0, 1.0, 1.0) * (5.0 if big else 2.8), hand, color.darkened(0.15))
			palm.basis = _axis_basis(way)
			var open := 0.55 if rage else 0.25
			var up := way.cross(Vector3.RIGHT if absf(way.x) < 0.9 else Vector3.UP).normalized()
			for jaw: float in [-1.0, 1.0]:
				var tip := hand + (way * cos(open) + up * jaw * sin(open)).normalized() * length
				BossMaquettes._rod(p, hand + up * jaw * 1.0, tip, 1.6 if big else 0.9, color.darkened(0.1))
				_cone(p, tip, tip + (tip - hand).normalized() * (3.0 if big else 2.0) - up * jaw * 1.2, 1.2 if big else 0.7,
					color.darkened(0.1))
		"drill":
			_cone(p, hand, hand + way * 12.0, 3.2, Clay.METAL.lightened(0.1))
		"prong":
			BossMaquettes._rod(p, hand, hand + way * 4.0, 0.7, Clay.DARK)
			var cross := way.cross(Vector3.UP).normalized()
			for tine: float in [-1.0, 1.0]:
				var base := hand + way * 4.0 + cross * tine * 2.0
				BossMaquettes._rod(p, hand + way * 4.0, base, 0.5, Clay.DARK)
				BossMaquettes._rod(p, base, base + way * 6.0, 0.5, Clay.DARK)
				BossMaquettes._weak(p, 0.8, base + way * 6.0)
			if rage:
				BossMaquettes._rod(p, hand + way * 10.0 + cross * 2.0, hand + way * 10.0 - cross * 2.0, 0.3, BossMaquettes.BEAM)
		"flail":
			# Con ira la revolea: la bola, de costado a la altura del brazo.
			var ball := hand + Vector3(side * 11.0, -1.0, -3.0) if rage else 				hand + (way + Vector3.DOWN * 1.2).normalized() * 10.0 + Vector3(side * 4.0, 0.0, 0.0)
			BossMaquettes._rod(p, hand, ball, 0.3, Clay.DARK)
			Clay.sphere(p, 3.0, ball, Clay.DARK.lightened(0.1))
			for i in 6:
				var spike := Vector3.UP.rotated(Vector3.RIGHT, i * 1.05).rotated(Vector3.UP, i * 0.8)
				_cone(p, ball + spike * 2.6, ball + spike * 4.2, 0.6, Clay.METAL)
		"saw":
			BossMaquettes._rod(p, hand, hand + way * 4.0, 0.8, Clay.DARK)
			var disc := Clay.cylinder(p, 5.0, 0.5, hand + way * 8.0, Clay.METAL.lightened(0.15))
			disc.basis = _axis_basis(Vector3(side, 0.0, 0.0))
		"gatling":
			var cross := way.cross(Vector3.UP).normalized()
			var up := cross.cross(way).normalized()
			for i in 6:
				var around := (cross * cos(i * TAU / 6.0) + up * sin(i * TAU / 6.0)) * 1.1
				BossMaquettes._rod(p, hand + around, hand + around + way * 9.0, 0.35, Clay.DARK)
			var made4 := Clay.cylinder(p, 2.2, 3.0, hand + way * 1.0, color.darkened(0.25))
			made4.basis = _axis_basis(way)
			if rage:
				_cone(p, hand + way * 9.5, hand + way * 13.0, 1.8, FLAME)


## ── EL TECHO, LA CABEZA Y EL PECHO ───────────────────────────────────────────────────────────────────────────────

static func _roof(p: Node3D, body: Node3D, kind: String, half: Vector3, rage: bool, color: Color) -> void:
	var top := body.transform * Vector3(0.0, half.y, half.z * 0.15)
	var up := body.transform.basis.y
	match kind:
		"stacks":
			for x: float in [-1.0, 1.0]:
				var base := body.transform * Vector3(x * 3.0, half.y, half.z * 0.3)
				var made5 := Clay.cylinder(p, 1.5, 8.0, base + up * 4.0, Clay.DARK)
				made5.basis = body.transform.basis
				if rage:
					_cone(p, base + up * 8.0, base + up * 15.0, 2.0, FLAME)
					for i in 3:
						Clay.sphere(p, 0.8, base + up * 10.0 + Vector3(x * (5.0 + i * 3.0), -i * 2.5, i * 2.0), FLAME)
				else:
					Clay.sphere(p, 2.2, base + up * 10.0, SMOKE)
					Clay.sphere(p, 2.8, base + up * 13.0 + Vector3(0.0, 0.0, 2.0), SMOKE)
		"radar":
			BossMaquettes._rod(p, top, top + up * 5.0, 0.6, Clay.DARK)
			var dish := Clay.cylinder(p, 4.5, 0.6, top + up * 6.0, color.lightened(0.2))
			dish.basis = _axis_basis((up + Vector3.FORWARD * 0.8).normalized())
			if rage:
				BossMaquettes._zone(p, 6.0, Vector3(top.x, 0.0, top.z - 40.0))
		"mortar":
			var made6 := Clay.box(p, Vector3(7.0, 3.0, 7.0), top + up * 1.5, color.darkened(0.2))
			made6.basis = body.transform.basis
			for i in 4:
				var at := top + body.transform.basis * Vector3(-1.6 + (i % 2) * 3.2, 0.0, -1.6 + (i >> 1) * 3.2)
				BossMaquettes._rod(p, at + up * 2.5, at + up * 7.0 + Vector3.FORWARD * 1.5, 0.9, Clay.DARK)
		"lamp":
			Clay.box(p, Vector3(3.0, 3.0, 3.0), top + up * 1.5, Clay.DARK)
			var lens := Clay.cylinder(p, 3.0, 2.5, top + up * 4.0 + Vector3.FORWARD, Clay.DARK)
			lens.basis = _axis_basis(Vector3.FORWARD)
			var light := Clay.cylinder(p, 2.5, 0.3, top + up * 4.0 + Vector3.FORWARD * 2.4, Color(1.0, 0.95, 0.7))
			light.basis = _axis_basis(Vector3.FORWARD)
			light.material_override = _glow_of(Color(1.0, 0.95, 0.7))
			_cone(p, top + up * 4.0 + Vector3.FORWARD * 2.5, top + up * 4.0 + Vector3.FORWARD * 28.0 + Vector3.DOWN * 8.0, 7.0,
				Color(1.0, 0.95, 0.7, 0.18))
		"coil":
			BossMaquettes._rod(p, top, top + up * 10.0, 0.9, Clay.DARK)
			for i in 3:
				_glow_ring(p, 3.2 - i * 0.7, top + up * (3.0 + i * 2.5), SPARK if rage else Clay.METAL)
			var ball := Clay.sphere(p, 2.0, top + up * 11.5, SPARK)
			ball.material_override = _glow_of(SPARK)
			if rage:
				for i in 4:
					var out := Vector3.FORWARD.rotated(Vector3.UP, i * PI * 0.5 + 0.4)
					BossMaquettes._rod(p, top + up * 11.5, Vector3(top.x, 0.0, top.z) + out * 22.0, 0.25, BossMaquettes.BEAM)
					BossMaquettes._zone(p, 3.0, Vector3(top.x, 0.0, top.z) + out * 22.0)
		"rack":
			var tilt := Basis(Vector3.RIGHT, 0.6 if rage else 0.15)
			var box := Clay.box(p, Vector3(9.0, 4.0, 6.0), top + up * 2.5, color.darkened(0.25))
			box.basis = body.transform.basis * tilt
			for i in 6:
				var at := box.position + box.basis * Vector3(-3.0 + (i % 3) * 3.0, -0.8 + int(i / 3.0) * 1.8, -3.1)
				var tip := Clay.sphere(p, 0.7, at, Clay.RED)
				tip.position = at
			if rage:
				for i in 3:
					var trail := box.position + Vector3(-4.0 + i * 4.0, 8.0 + i * 3.0, -10.0 - i * 4.0)
					Clay.sphere(p, 0.8, trail, Clay.RED)
					_cone(p, trail, trail + Vector3(0.0, -2.0, 4.0), 0.5, SMOKE)


## La cabeza con dos ojos; con ira se ponen rojos y, si es de `lasers`, tiran láser al piso.
static func _head(p: Node3D, body: Node3D, half: Vector3, rage: bool, color: Color, lasers: bool) -> void:
	var at := body.transform * Vector3(0.0, half.y + 2.0, -half.z + 2.5)
	var head := Clay.box(p, Vector3(5.0, 3.5, 4.5), at, color.lightened(0.08))
	head.basis = body.transform.basis
	var eye_color := Clay.RED if rage else Color(0.4, 0.9, 1.0)
	for x: float in [-1.0, 1.0]:
		var eye := at + body.transform.basis * Vector3(x * 1.3, 0.3, -2.3)
		var made7 := Clay.sphere(p, 0.7, eye, eye_color)
		made7.material_override = _glow_of(eye_color)
		if rage and lasers:
			var spot := Vector3(eye.x + x * 6.0, 0.0, eye.z - 30.0)
			BossMaquettes._rod(p, eye, spot, 0.3, Color(1.0, 0.2, 0.15, 0.6))
			BossMaquettes._zone(p, 2.0, spot)


static func _chest(p: Node3D, body: Node3D, kind: String, half: Vector3, rage: bool) -> void:
	var front := body.transform * Vector3(0.0, -half.y * 0.1, -half.z)
	var facing := body.transform.basis
	match kind:
		"furnace":
			var made8 := Clay.box(p, Vector3(7.0, 6.0, 0.4), front, Clay.DARK)
			made8.basis = facing
			var inside := Clay.box(p, Vector3(5.5, 4.5, 0.3), front + facing.z * -0.15, BossMaquettes.WEAK)
			inside.basis = facing
			inside.material_override = _glow_of(Color(1.0, 0.45, 0.1) if rage else Color(0.4, 0.15, 0.05))
			if rage:
				# La puerta, abierta hacia abajo.
				var door := Clay.box(p, Vector3(6.0, 0.5, 5.0), front + facing * Vector3(0.0, -3.2, -2.6), Clay.DARK.lightened(0.1))
				door.basis = facing
			else:
				var made9 := Clay.box(p, Vector3(6.0, 5.0, 0.5), front + facing * Vector3(0.0, 0.0, -0.4), Clay.DARK.lightened(0.1))
				made9.basis = facing
		"grille":
			for i in 4:
				var made10 := Clay.box(p, Vector3(6.0, 0.4, 0.4), front + facing * Vector3(0.0, -1.5 + i * 1.0, -0.3), Clay.DARK)
				made10.basis = facing
		"core":
			var core := Clay.sphere(p, 2.6, front + facing * Vector3(0.0, 0.0, -0.5), SPARK)
			core.material_override = _glow_of(SPARK)


## ── LA ARCILLA DE ESTAS ──────────────────────────────────────────────────────────────────────────────────────────

## Una base que lleva el eje Y hacia `way` (para cilindros y conos).
static func _axis_basis(way: Vector3) -> Basis:
	var y := way.normalized()
	var x := (Vector3.UP if absf(y.y) < 0.9 else Vector3.FORWARD).cross(y).normalized()
	return Basis(x, y, x.cross(y))


## Un cono de `base` (de `radius`) a `tip`.
static func _cone(p: Node3D, base: Vector3, tip: Vector3, radius: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = 0.0
	mesh.height = maxf(base.distance_to(tip), 0.01)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = Clay.material(color)
	part.transform = Transform3D(_axis_basis(tip - base), (base + tip) * 0.5)
	p.add_child(part)


static func _glow_ring(p: Node3D, radius: float, at: Vector3, color: Color) -> void:
	var part := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.5
	torus.outer_radius = radius
	part.mesh = torus
	part.material_override = _glow_of(color)
	part.position = at
	p.add_child(part)


static var _glows := {}


static func _glow_of(color: Color) -> StandardMaterial3D:
	if not _glows.has(color):
		var made := StandardMaterial3D.new()
		made.albedo_color = color
		made.emission_enabled = true
		made.emission = color
		made.emission_energy_multiplier = 2.0
		_glows[color] = made
	return _glows[color]
