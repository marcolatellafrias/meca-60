class_name HumanoidMaquettes
extends RefCounted

## SILUETAS DEL JEFE HUMANOIDE (15/11/2026): maquetas de arcilla, quietas, para elegir la forma. El usuario: «más
## humanoide… que los brazos en vez de cilíndricos y las piernas sean más cuadrados y tengan formas más interesantes y que
## tenga cabeza… un diseño un poquito más alocado porque no dependemos de la cabina»; «haceme varios intentos… tiene que
## parecer una meca… inspirarte de las mecas… para que se sienta medio un trope». Los tropos de las mecas, genéricos: la
## cresta en V, el visor o el ojo único, las hombreras grandes, la mochila con toberas, las faldas de placas y las rejillas.
##
## Todo es de cajas (los miembros, cuadrados). Dos estados: el normal y CON IRA (otro color, los ojos rojos, las rejillas
## al rojo y las toberas prendidas). La pose es la misma: lo que se elige acá es la silueta.

const FIRE := Color(1.0, 0.45, 0.1)
const FLAME := Color(1.0, 0.5, 0.1, 0.5)

## LAS FICHAS. Medidas en metros. `hip`: alto de la cadera; `leg`: grueso de las patas; `reverse`: rodilla para atrás.
## `chest`, `waist`: cajas. `hunch`: cuánto se encorva (°). `shoulder`: la hombrera. `upper`, `fore`: largo del brazo y
## del antebrazo; `reach`: cuánto adelanta los brazos (0 a 1); `fist`: lado del puño. `head`: crest, mono, sunk, dome o
## visor. `back`: thrusters, stacks o fins. `skirt`: placas en la cadera. `blades`: hojas en los antebrazos.
const ALL: Array[Dictionary] = [
	{"name": "Gorila", "hip": 11.0, "leg": 3.6, "reverse": false, "chest": Vector3(20, 12, 12), "waist": Vector3(8, 4, 7),
		"hunch": 28.0, "shoulder": Vector3(8, 7, 8), "upper": 11.0, "fore": 13.0, "reach": 0.25, "fist": 5.5,
		"head": "mono", "back": "thrusters", "skirt": false, "blades": false,
		"color": Color(0.38, 0.42, 0.34), "rage_color": Color(0.45, 0.2, 0.15),
		"states": ["normal", "con ira"], "lines": [
		"encorvado, hombros enormes, brazos largos que casi tocan el piso y patas cortas",
		"la cabeza baja, metida adelante, con un ojo único",
		"pega con los puños y los antebrazos: el golpe doble al piso, el hombrazo, el agarre"]},
	{"name": "Caballero", "hip": 16.0, "leg": 3.0, "reverse": false, "chest": Vector3(14, 10, 9), "waist": Vector3(6, 4, 6),
		"hunch": 0.0, "shoulder": Vector3(9, 6, 9), "upper": 9.0, "fore": 9.0, "reach": 0.1, "fist": 3.2,
		"head": "crest", "back": "thrusters", "skirt": true, "blades": false,
		"color": Color(0.85, 0.85, 0.82), "rage_color": Color(0.3, 0.3, 0.34),
		"states": ["normal", "con ira"], "lines": [
		"alto y erguido, cintura fina, hombreras altas y una falda de placas",
		"la cresta en V y el visor; la mochila con dos toberas",
		"el clásico: elegante, rápido para su tamaño; con ira se pone negro"]},
	{"name": "Luchador", "hip": 10.0, "leg": 5.0, "reverse": false, "chest": Vector3(22, 13, 13), "waist": Vector3(12, 5, 10),
		"hunch": 12.0, "shoulder": Vector3(7, 7, 7), "upper": 8.0, "fore": 9.0, "reach": 0.35, "fist": 4.8,
		"head": "sunk", "back": "stacks", "skirt": false, "blades": false,
		"color": Color(0.62, 0.2, 0.18), "rage_color": Color(0.2, 0.2, 0.22),
		"states": ["normal", "con ira"], "lines": [
		"ancho y bajo, el pecho enorme y la cabeza hundida entre los hombros",
		"patas gruesas, los brazos adelante, en guardia",
		"agarres, revoleos y pisotones; con ira suelta vapor por las chimeneas"]},
	{"name": "Tanque", "hip": 8.0, "leg": 6.0, "reverse": false, "chest": Vector3(24, 14, 14), "waist": Vector3(14, 4, 12),
		"hunch": 5.0, "shoulder": Vector3(6, 6, 8), "upper": 8.0, "fore": 10.0, "reach": 0.2, "fist": 7.0,
		"head": "dome", "back": "stacks", "skirt": false, "blades": false,
		"color": Color(0.82, 0.7, 0.28), "rage_color": Color(0.5, 0.3, 0.12),
		"states": ["normal", "con ira"], "lines": [
		"una caja enorme sobre patas cortas, con pies grandes",
		"puños como bloques; la cabeza, una cúpula con el ojo en un riel",
		"lento y pesado: arranca el piso y lo tira, golpes que hacen ondas"]},
	{"name": "Duelista", "hip": 18.0, "leg": 2.4, "reverse": true, "chest": Vector3(11, 9, 8), "waist": Vector3(4, 5, 4),
		"hunch": 10.0, "shoulder": Vector3(5, 5, 5), "upper": 10.0, "fore": 11.0, "reach": 0.3, "fist": 2.6,
		"head": "visor", "back": "fins", "skirt": false, "blades": true,
		"color": Color(0.32, 0.28, 0.4), "rage_color": Color(0.55, 0.12, 0.2),
		"states": ["normal", "con ira"], "lines": [
		"alto y flaco, las rodillas para atrás, cintura de avispa",
		"hojas en los antebrazos, aletas en la espalda y un visor fino",
		"rápido: combos con ritmo, la picada, el visor láser"]},
	{"name": "Torre", "hip": 9.0, "leg": 4.0, "reverse": false, "chest": Vector3(26, 16, 14), "waist": Vector3(8, 4, 8),
		"hunch": 0.0, "shoulder": Vector3(10, 10, 10), "upper": 9.0, "fore": 9.0, "reach": 0.15, "fist": 4.0,
		"head": "visor", "back": "thrusters", "skirt": true, "blades": false,
		"color": Color(0.3, 0.48, 0.5), "rage_color": Color(0.6, 0.35, 0.1),
		"states": ["normal", "con ira"], "lines": [
		"todo arriba: un pecho y unas hombreras gigantes sobre patas chicas",
		"la cabeza, chiquita, con un visor; toberas grandes atrás",
		"se cubre con los hombros y embiste; con ira prende las toberas y salta"]},
]


## ARMA la ficha `index`, normal o con ira, en `p` (de pie en y = 0, mirando a −Z).
static func build(index: int, p: Node3D, rage: bool) -> void:
	var k := ALL[index]
	var color: Color = k["rage_color"] if rage else k["color"]
	var trim := color.darkened(0.45)
	var eye := Color(1.0, 0.12, 0.08) if rage else Color(0.45, 0.95, 1.0)
	var hip := float(k["hip"])
	var leg := float(k["leg"])
	var chest: Vector3 = k["chest"]
	var waist: Vector3 = k["waist"]
	var hip_x := waist.x * 0.5 + leg * 0.4
	# LAS PATAS, de la cadera al piso.
	for side: float in [-1.0, 1.0]:
		var top := Vector3(side * hip_x, hip, 0.0)
		var ankle := Vector3(side * hip_x * 1.1, leg * 0.7, 0.0)
		var knee := Vector3(side * hip_x * 1.05, hip * 0.5, (hip * 0.15) if k["reverse"] else -hip * 0.12)
		if k["reverse"]:
			ankle.z = -hip * 0.08
		_beam(p, top, knee, leg, leg * 1.1, color)
		Clay.box(p, Vector3(leg * 1.3, leg * 1.3, leg * 1.2), knee + Vector3(0.0, 0.0, -0.3), trim)
		_beam(p, knee, ankle, leg * 0.9, leg, color.darkened(0.1))
		Clay.box(p, Vector3(leg * 1.4, leg * 0.7, leg * 2.6), Vector3(ankle.x, leg * 0.35, ankle.z - leg * 0.5), trim)
	Clay.box(p, Vector3(waist.x + leg * 1.2, leg * 1.2, waist.z), Vector3(0.0, hip, 0.0), trim)
	# LO DE ARRIBA, encorvado desde la cadera.
	var upper := Node3D.new()
	upper.transform = Transform3D(Basis(Vector3.RIGHT, -deg_to_rad(float(k["hunch"]))), Vector3(0.0, hip, 0.0))
	p.add_child(upper)
	Clay.box(upper, waist, Vector3(0.0, waist.y * 0.5 + 0.5, 0.0), color.darkened(0.2))
	var chest_at := Vector3(0.0, waist.y + chest.y * 0.5, 0.0)
	Clay.box(upper, chest, chest_at, color)
	# El frente del pecho: una placa más clara y las rejillas (al rojo con ira).
	Clay.box(upper, Vector3(chest.x * 0.6, chest.y * 0.45, 0.6), chest_at + Vector3(0.0, chest.y * 0.15, -chest.z * 0.5),
		color.lightened(0.12))
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var vent := Clay.box(upper, Vector3(chest.x * 0.18, 0.5, 0.4),
				chest_at + Vector3(side * chest.x * 0.3, -chest.y * 0.2 - i * 1.0, -chest.z * 0.5 - 0.2), FIRE if rage else trim)
			if rage:
				vent.material_override = _glow(FIRE)
	if k["skirt"]:
		for side: float in [-1.0, 1.0]:
			var plate := Clay.box(p, Vector3(waist.x * 0.55, hip * 0.3, 1.0),
				Vector3(side * waist.x * 0.35, hip * 0.82, -waist.z * 0.55), color.lightened(0.05))
			plate.rotation_degrees = Vector3(-12.0, 0.0, side * 8.0)
		var back_plate := Clay.box(p, Vector3(waist.x, hip * 0.3, 1.0), Vector3(0.0, hip * 0.82, waist.z * 0.55), color)
		back_plate.rotation_degrees = Vector3(12.0, 0.0, 0.0)
	# LOS BRAZOS: cuelgan derecho (contra lo encorvado), un poco adelante.
	var straight := Basis(Vector3.RIGHT, deg_to_rad(float(k["hunch"])))
	var shoulder: Vector3 = k["shoulder"]
	var reach := float(k["reach"])
	for side: float in [-1.0, 1.0]:
		var joint := chest_at + Vector3(side * (chest.x * 0.5 + shoulder.x * 0.35), chest.y * 0.3, 0.0)
		Clay.box(upper, shoulder, joint + Vector3(side * shoulder.x * 0.1, shoulder.y * 0.2, 0.0), color.lightened(0.05))
		var elbow := joint + straight * Vector3(side * 0.8, -float(k["upper"]), -float(k["upper"]) * reach)
		var wrist := elbow + straight * Vector3(0.0, -float(k["fore"]) * (1.0 - reach), -float(k["fore"]) * reach * 2.0)
		var arm := shoulder.x * 0.45
		_beam(upper, joint, elbow, arm, arm, color.darkened(0.1))
		Clay.box(upper, Vector3(arm, arm, arm) * 1.25, elbow, trim)
		_beam(upper, elbow, wrist, arm * 1.25, arm * 1.25, color)
		var fist := float(k["fist"])
		Clay.box(upper, Vector3(fist, fist, fist), wrist + (wrist - elbow).normalized() * fist * 0.5, trim)
		if k["blades"]:
			var along := (wrist - elbow).normalized()
			var blade := Clay.box(upper, Vector3(0.4, 1.6, float(k["fore"]) * 1.1), elbow.lerp(wrist, 0.5) + Vector3(side * arm * 0.8, 0.0, 0.0),
				Clay.METAL.lightened(0.2))
			blade.basis = Basis.looking_at(along, Vector3.UP)
	# LA CABEZA.
	var neck := chest_at + Vector3(0.0, chest.y * 0.5, -chest.z * 0.15)
	_head(upper, str(k["head"]), neck, color, trim, eye, rage)
	# LA ESPALDA.
	var back := chest_at + Vector3(0.0, chest.y * 0.1, chest.z * 0.5)
	match str(k["back"]):
		"thrusters":
			Clay.box(upper, Vector3(chest.x * 0.6, chest.y * 0.7, 3.0), back + Vector3(0.0, 0.0, 1.5), trim)
			for side: float in [-1.0, 1.0]:
				var nozzle := back + Vector3(side * chest.x * 0.2, -chest.y * 0.35, 3.5)
				Clay.cylinder(upper, 1.4, 3.0, nozzle, Clay.DARK)
				if rage:
					_cone(upper, nozzle + Vector3.DOWN * 1.5, nozzle + Vector3(0.0, -8.0, 2.0), 1.3, FLAME)
		"stacks":
			for side: float in [-1.0, 1.0]:
				var stack := back + Vector3(side * chest.x * 0.25, chest.y * 0.3, 1.5)
				Clay.cylinder(upper, 1.2, 7.0, stack + Vector3.UP * 3.0, Clay.DARK)
				var puff := Clay.sphere(upper, 2.0, stack + Vector3.UP * 8.0, FLAME if rage else Color(0.35, 0.35, 0.37, 0.45))
				puff.scale = Vector3.ONE * (1.4 if rage else 1.0)
		"fins":
			for side: float in [-1.0, 1.0]:
				var fin := Clay.box(upper, Vector3(0.6, chest.y * 1.4, 4.0), back + Vector3(side * chest.x * 0.35, chest.y * 0.5, 2.0),
					color.lightened(0.1))
				fin.rotation_degrees = Vector3(-25.0, 0.0, side * -20.0)
				if rage:
					var edge := Clay.box(upper, Vector3(0.3, chest.y * 1.4, 0.3), fin.position + Vector3(side * 0.4, 0.0, 1.8), FIRE)
					edge.rotation_degrees = fin.rotation_degrees
					edge.material_override = _glow(FIRE)


static func _head(upper: Node3D, kind: String, neck: Vector3, color: Color, trim: Color, eye: Color, rage: bool) -> void:
	match kind:
		"crest":
			var head := neck + Vector3(0.0, 2.5, 0.0)
			Clay.box(upper, Vector3(4.0, 4.0, 4.5), head, color.lightened(0.08))
			_lit(Clay.box(upper, Vector3(3.2, 0.7, 0.3), head + Vector3(0.0, 0.3, -2.3), eye), eye)
			for side: float in [-1.0, 1.0]:
				var fin := Clay.box(upper, Vector3(0.5, 4.5, 0.5), head + Vector3(side * 1.6, 3.2, -2.0), Clay.YELLOW)
				fin.rotation_degrees = Vector3(0.0, 0.0, side * -40.0)
		"mono":
			# Baja y adelante, con un ojo único.
			var head := neck + Vector3(0.0, 0.5, -4.0)
			Clay.box(upper, Vector3(5.0, 3.5, 5.0), head, color.darkened(0.1))
			_lit(Clay.sphere(upper, 1.0, head + Vector3(0.0, 0.2, -2.5), eye), eye)
		"sunk":
			var head := neck + Vector3(0.0, 0.3, -2.0)
			Clay.box(upper, Vector3(5.0, 3.0, 4.0), head, trim)
			_lit(Clay.box(upper, Vector3(4.0, 0.8, 0.3), head + Vector3(0.0, 0.2, -2.05), eye), eye)
		"dome":
			var head := neck + Vector3(0.0, 1.5, -1.0)
			var dome := Clay.sphere(upper, 4.0, head, color.lightened(0.05))
			dome.scale = Vector3(1.0, 0.6, 1.0)
			Clay.box(upper, Vector3(6.0, 0.9, 0.6), head + Vector3(0.0, 0.3, -3.6), Clay.DARK)
			_lit(Clay.sphere(upper, 0.8, head + Vector3(1.2 if rage else -1.2, 0.3, -3.9), eye), eye)
		_:
			# "visor": chica, con una franja fina y dos antenas.
			var head := neck + Vector3(0.0, 1.8, 0.0)
			Clay.box(upper, Vector3(3.2, 3.2, 3.6), head, color.lightened(0.08))
			_lit(Clay.box(upper, Vector3(2.8, 0.45, 0.3), head + Vector3(0.0, 0.4, -1.85), eye), eye)
			for side: float in [-1.0, 1.0]:
				BossMaquettes._rod(upper, head + Vector3(side * 1.4, 1.4, 0.5), head + Vector3(side * 2.2, 4.5, 2.0), 0.15, Clay.DARK)


## UN MIEMBRO CUADRADO de `from` a `to`, de `width` por `depth`.
static func _beam(p: Node3D, from: Vector3, to: Vector3, width: float, depth: float, color: Color) -> void:
	var along := to - from
	var part := Clay.box(p, Vector3(width, depth, along.length()), (from + to) * 0.5, color)
	var up := Vector3.UP if absf(along.normalized().dot(Vector3.UP)) < 0.95 else Vector3.BACK
	part.basis = Basis.looking_at(along.normalized(), up)


static func _lit(part: MeshInstance3D, color: Color) -> void:
	part.material_override = _glow(color)


static func _glow(color: Color) -> StandardMaterial3D:
	return ArmedMaquettes._glow_of(color)


static func _cone(p: Node3D, base: Vector3, tip: Vector3, radius: float, color: Color) -> void:
	ArmedMaquettes._cone(p, base, tip, radius, color)
