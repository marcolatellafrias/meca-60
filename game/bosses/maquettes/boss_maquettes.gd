class_name BossMaquettes
extends RefCounted

## LAS MAQUETAS DE JEFES (14/11/2026): bocetos de arcilla, quietos, para pensar con el usuario jefes con PUNTOS DÉBILES,
## FASES y ATAQUES DE ÁREA. El usuario: «un sistema en el que los bosses tienen puntos débiles… si me tiro con un
## personaje… desconectar algún cable o sacarle un core… mucho risk y mucho reward. Si voy a pie y me tiro desde un punto
## alto y justo encajo, puedo llegar a matarlo desde cerca»; «varios ciclos… caminando, pero después tal vez va volando…
## por tiempo o por threshold de vida… cuando le rompe las alas se cae y va caminando… modo frenzy»; «ataques… menos
## físicos y más bien poderes de AoE»; «empecemos con muchas maquetas de clay».
##
## Cada maqueta muestra DOS ESTADOS uno al lado del otro (el de la izquierda, el primero). Lo que se lee en todas:
##   · NARANJA QUE BRILLA: un punto débil (un núcleo, una unión de cables). Los cables, naranja oscuro.
##   · ROJO TRANSPARENTE EN EL PISO: un ataque de área (adónde pega, o la onda).
##   · El bloque rojo es la meca (18 m) y el muñeco amarillo, una persona (1,8 m). Las torres grises son los puntos altos
##     desde donde tirarse.
## Provisorio a propósito: son para mirar y elegir, no para jugar.

const WEAK := Color(1.0, 0.5, 0.1)
const CABLE := Color(0.75, 0.35, 0.08)
const ZONE := Color(0.95, 0.2, 0.1, 0.28)
const BEAM := Color(1.0, 0.85, 0.3, 0.3)
const STONE := Color(0.62, 0.6, 0.56)
const HULL := Color(0.45, 0.47, 0.5)
## Cuánto separa los dos estados (m, del centro a cada uno).
const APART := 75.0

## LAS MAQUETAS: cuál es (`kind`), nombre, los dos estados y lo que se piensa de cada una (las de ArmedMaquettes, en su
## ficha: ver `entry`). Primero las siluetas del HUMANOIDE (HumanoidMaquettes); después las seis CON PERSONALIDAD (ArmedMaquettes, 15/11/2026); después las dos RECORRIBLES
## (WalkerMaquettes, 15/11/2026); después la primera tanda, de seis (el usuario: «muy simplistas… no se dan mucho a espacios
## a recorrer a pie», aunque «hay algunos que tienen algo de potencial»).
const ALL: Array[Dictionary] = [
	{"kind": "humanoid", "spec": 0},
	{"kind": "humanoid", "spec": 1},
	{"kind": "humanoid", "spec": 2},
	{"kind": "humanoid", "spec": 3},
	{"kind": "humanoid", "spec": 4},
	{"kind": "humanoid", "spec": 5},
	{"kind": "humanoid", "spec": 6},
	{"kind": "armed", "spec": 0},
	{"kind": "armed", "spec": 1},
	{"kind": "armed", "spec": 2},
	{"kind": "armed", "spec": 3},
	{"kind": "armed", "spec": 4},
	{"kind": "armed", "spec": 5},
	{"kind": "hexapod", "name": "Hexápodo plataforma", "states": ["compuertas cerradas: camina",
		"compuertas abiertas: después del pisotón"], "lines": WalkerMaquettes.HEXAPOD_LINES},
	{"kind": "quadruped", "name": "Cuadrúpedo bastión", "states": ["compuertas cerradas: camina",
		"compuertas abiertas: después del cañonazo"], "lines": WalkerMaquettes.QUADRUPED_LINES},
	{"kind": "tripod", "name": "Trípode faro", "states": ["camina en tres patas", "una pata rota: se arrodilla"], "lines": [
		"alto y lento, en tres patas; arriba de la cabeza, una escotilla con el núcleo",
		"PUNTO DÉBIL: el núcleo de arriba, sólo tirándose desde lo alto (la torre); y los cables de cada rodilla",
		"cortar los cables de una rodilla la traba; trabada una, se arrodilla y la cabeza queda a tiro",
		"ÁREA: el faro barre el piso con su luz (lo que toca, quema) y el pisotón hace una onda"]},
	{"kind": "moth", "name": "Polilla", "states": ["volando", "sin alas: camina"], "lines": [
		"primero vuela en círculos, alto, y tira columnas desde arriba",
		"PUNTO DÉBIL: las raíces de las alas, con sus cables; se llega desde lo alto cuando pasa cerca",
		"FASE: rotas dos alas se cae (por vida); camina en seis patas cortas y la panza, con su núcleo, queda a la vista",
		"ÁREA: las columnas que caen en fila; en el piso, arrastra los muñones de las alas"]},
	{"kind": "snail", "name": "Caracol fortaleza", "states": ["anda", "frenesí: se mete en la caparazón"], "lines": [
		"lento y enorme; la caparazón es una torre con una chimenea arriba",
		"PUNTO DÉBIL: el núcleo en la chimenea: hay que caer adentro, desde lo alto",
		"FASE: con poca vida se mete en la caparazón, se agrieta y brilla por las grietas: frenesí, gira y empuja",
		"ÁREA: golpea el piso y salen anillos (saltarlos); alrededor, una zona que quema"]},
	{"kind": "reliquary", "name": "Relicario", "states": ["flota con sus nodos", "caído: es una rampa"], "lines": [
		"un monolito que flota; tres nodos le dan vueltas, atados con cables",
		"PUNTO DÉBIL: los nodos, de a uno (bajos, pero giran); rotos los tres, se cae",
		"FASE: caído queda como una rampa; se sube caminando hasta el núcleo de la punta, mientras se levanta",
		"ÁREA: círculos en el piso que explotan después de un rato, y rayos que bajan"]},
	{"kind": "centipede", "name": "Ciempiés de vagones", "states": ["entero", "partido en dos"], "lines": [
		"un tren de vagones con patas; cada unión es un enganche con cables",
		"PUNTO DÉBIL: los enganches de arriba, subiéndose al lomo mientras anda",
		"FASE: desenganchado uno, se parte en dos más chicos que pelean aparte (y más rápido)",
		"ÁREA: la cola deja una línea que quema; los vagones barren al doblar"]},
	{"kind": "hive", "name": "Colmena colgante", "states": ["en lo alto de sus patas", "frenesí: se agacha"], "lines": [
		"un cuerpo alto en seis patas largas; abajo cuelga una bolsa con el núcleo, de cables",
		"PUNTO DÉBIL: los cables de la bolsa, por debajo: hay que meterse donde pisa",
		"FASE: cortada la bolsa, se enoja (frenesí): se agacha, pisa más rápido y el núcleo cae al piso",
		"ÁREA: debajo, el pisotón; de la bolsa caen gotas que dejan charcos"]},
]

static var _glow: StandardMaterial3D = null


## LA FICHA de la maqueta `index`: nombre, sus dos estados y lo que se piensa de ella.
static func entry(index: int) -> Dictionary:
	if str(ALL[index]["kind"]) == "armed":
		return ArmedMaquettes.ALL[int(ALL[index]["spec"])]
	if str(ALL[index]["kind"]) == "humanoid":
		return HumanoidMaquettes.ALL[int(ALL[index]["spec"])]
	return ALL[index]


## ARMA la maqueta `index`: sus dos estados, la meca y una persona para la escala, y los carteles.
static func build(index: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = str(entry(index)["name"])
	parent.add_child(root)
	for state in 2:
		var holder := Node3D.new()
		holder.position = Vector3(APART * (state * 2 - 1), 0.0, 0.0)
		root.add_child(holder)
		match str(ALL[index]["kind"]):
			"armed": ArmedMaquettes.build(int(ALL[index]["spec"]), holder, state == 1)
			"humanoid": HumanoidMaquettes.build(int(ALL[index]["spec"]), holder, state == 1)
			"hexapod": WalkerMaquettes.hexapod(holder, state == 1)
			"quadruped": WalkerMaquettes.quadruped(holder, state == 1)
			"tripod": _tripod(holder, state)
			"moth": _moth(holder, state)
			"snail": _snail(holder, state)
			"reliquary": _reliquary(holder, state)
			"centipede": _centipede(holder, state)
			"hive": _hive(holder, state)
		_sign(holder, "%s · %s" % [entry(index)["name"], entry(index)["states"][state]], Vector3(0.0, 62.0, 0.0))
	_mech(root, Vector3(0.0, 0.0, 45.0))
	_person(root, Vector3(6.0, 0.0, 45.0))
	return root


## ── 1. EL TRÍPODE FARO ───────────────────────────────────────────────────────────────────────────────────────────

static func _tripod(p: Node3D, state: int) -> void:
	var body := Node3D.new()
	body.transform = Transform3D(Basis(Vector3.BACK, deg_to_rad(22.0)), Vector3(4.0, 22.0, 0.0)) if state == 1 \
		else Transform3D(Basis(), Vector3(0.0, 36.0, 0.0))
	p.add_child(body)
	Clay.cylinder(body, 7.0, 10.0, Vector3.ZERO, HULL)
	Clay.cylinder(body, 4.0, 5.0, Vector3(0.0, -7.0, 0.0), Clay.DARK)
	Clay.cylinder(body, 6.0, 4.0, Vector3(0.0, 7.0, 0.0), Color(1.0, 0.9, 0.5) if state == 0 else Clay.RED)
	Clay.cylinder(body, 9.0, 2.0, Vector3(0.0, 10.0, 0.0), Clay.DARK)
	# La escotilla de arriba, abierta, con el núcleo.
	var hatch := Clay.box(body, Vector3(5.0, 0.6, 5.0), Vector3(3.5, 12.5, 0.0), Clay.YELLOW)
	hatch.rotation_degrees = Vector3(0.0, 0.0, -55.0)
	_weak(body, 2.0, Vector3(0.0, 11.8, 0.0))
	for i in 3:
		var angle := TAU * i / 3.0 + PI * 0.5
		var out := Vector3(cos(angle), 0.0, sin(angle))
		var root := body.transform * (out * 6.0 + Vector3.DOWN * 3.0)
		var knee := Vector3(out.x * 18.0, 40.0, out.z * 18.0)
		var foot := Vector3(out.x * 25.0, 0.0, out.z * 25.0)
		if state == 1:
			knee = root + (Vector3(out.x * 14.0, 0.0, out.z * 14.0) + Vector3(0.0, 6.0, 0.0)) * 0.8
			foot = Vector3(out.x * 22.0, 0.0, out.z * 22.0)
		_rod(p, root, knee, 1.6, HULL)
		Clay.sphere(p, 2.2, knee, Clay.DARK)
		_rod(p, root + Vector3.UP * 1.5, knee + Vector3.UP * 1.5, 0.45, CABLE)
		_weak(p, 0.9, knee + Vector3.UP * 2.0)
		if state == 1 and i == 0:
			# La rota: un muñón con chispas.
			_rod(p, knee, knee.lerp(foot, 0.35), 1.3, HULL)
			_weak(p, 1.2, knee.lerp(foot, 0.35))
			continue
		_rod(p, knee, foot + Vector3.UP, 1.3, HULL)
		Clay.cylinder(p, 3.0, 1.0, foot + Vector3.UP * 0.5, Clay.DARK)
	if state == 0:
		# El faro barre: un rayo al piso y lo que quema; el pisotón, una onda.
		var spot := Vector3(28.0, 0.0, 18.0)
		_rod(p, Vector3(0.0, 43.0, 0.0), spot, 2.0, BEAM)
		_zone(p, 6.0, spot)
		_ring(p, 12.0, Vector3(-12.5, 0.0, 21.6))
		_tower(p, Vector3(-26.0, 0.0, -20.0), 54.0)
	else:
		_ring(p, 16.0, Vector3(0.0, 0.0, 0.0))


## ── 2. LA POLILLA ────────────────────────────────────────────────────────────────────────────────────────────────

static func _moth(p: Node3D, state: int) -> void:
	var body := Node3D.new()
	body.position = Vector3(0.0, 34.0 if state == 0 else 7.0, 0.0)
	p.add_child(body)
	_rod(body, Vector3(0.0, 0.0, -8.0), Vector3(0.0, 0.0, 10.0), 4.0, HULL)
	Clay.sphere(body, 4.5, Vector3(0.0, 0.5, -10.0), Clay.DARK)
	Clay.sphere(body, 1.0, Vector3(1.8, 1.5, -13.6), Clay.RED)
	Clay.sphere(body, 1.0, Vector3(-1.8, 1.5, -13.6), Clay.RED)
	for side: float in [-1.0, 1.0]:
		for z: float in [-3.0, 6.0]:
			var root := Vector3(side * 3.5, 1.5, z)
			_weak(body, 1.3, root + Vector3(side * 0.8, 0.8, 0.0))
			_rod(body, root, root + Vector3(side * 3.0, 2.5, 1.0), 0.4, CABLE)
			var length := 26.0 if state == 0 else 5.0
			var wing := Clay.box(body, Vector3(length, 0.6, 9.0 if z < 0.0 else 7.0),
				root + Vector3(side * length * 0.5, 0.0, 0.0), Color(0.78, 0.74, 0.62) if state == 0 else HULL)
			wing.rotation_degrees = Vector3(0.0, side * (-12.0 if z < 0.0 else 14.0), side * 14.0)
			wing.position = root + Basis.from_euler(wing.rotation) * Vector3(side * length * 0.5, 0.0, 0.0)
	if state == 0:
		# Las columnas que caen en fila.
		for i in 4:
			var spot := Vector3(-18.0 + i * 12.0, 0.0, 22.0)
			_zone(p, 4.5, spot)
			_rod(p, spot + Vector3.UP * 30.0, spot, 1.2, BEAM)
		_tower(p, Vector3(22.0, 0.0, -14.0), 36.0)
	else:
		# Seis patas cortas y la panza con su núcleo a la vista; un ala, tirada.
		for side: float in [-1.0, 1.0]:
			for z: float in [-6.0, 1.0, 8.0]:
				var hip := body.position + Vector3(side * 3.0, -2.0, z)
				var knee := hip + Vector3(side * 6.0, 3.0, 0.0)
				_rod(p, hip, knee, 1.0, Clay.DARK)
				_rod(p, knee, Vector3(hip.x + side * 9.0, 0.0, z), 0.8, Clay.DARK)
		_weak(body, 2.2, Vector3(0.0, -3.8, 1.0))
		var lost := Clay.box(p, Vector3(22.0, 0.6, 9.0), Vector3(-14.0, 0.8, 22.0), Color(0.78, 0.74, 0.62))
		lost.rotation_degrees = Vector3(4.0, 30.0, 8.0)
		_zone(p, 5.0, Vector3(14.0, 0.0, 18.0))


## ── 3. EL CARACOL FORTALEZA ──────────────────────────────────────────────────────────────────────────────────────

static func _snail(p: Node3D, state: int) -> void:
	var low := state == 1
	if not low:
		Clay.box(p, Vector3(16.0, 6.0, 40.0), Vector3(0.0, 3.0, -2.0), HULL.darkened(0.2))
		Clay.sphere(p, 6.0, Vector3(0.0, 7.0, -22.0), HULL.darkened(0.2))
		for side: float in [-1.0, 1.0]:
			_rod(p, Vector3(side * 2.5, 11.0, -24.0), Vector3(side * 4.5, 19.0, -28.0), 0.7, Clay.DARK)
			Clay.sphere(p, 1.4, Vector3(side * 4.5, 19.5, -28.0), Clay.RED)
	var base := 0.0 if low else 6.0
	var radii := [15.0, 13.0, 11.0, 8.5, 6.0]
	for i in radii.size():
		var y := base + 3.0 + i * 6.0
		Clay.cylinder(p, radii[i], 6.0, Vector3(0.0, y, 4.0), STONE if i % 2 == 0 else STONE.darkened(0.15))
		if low and i > 0:
			# Frenesí: brilla por las grietas.
			var crack := MeshInstance3D.new()
			var torus := TorusMesh.new()
			torus.inner_radius = radii[i] - 0.2
			torus.outer_radius = radii[i] + 0.6
			crack.mesh = torus
			crack.material_override = _glow_material()
			crack.position = Vector3(0.0, y - 3.0, 4.0)
			p.add_child(crack)
	var top := base + 30.0
	Clay.cylinder(p, 3.0, 8.0, Vector3(0.0, top + 4.0, 4.0), Clay.DARK)
	_weak(p, 2.2 if not low else 3.0, Vector3(0.0, top + 8.5, 4.0))
	_ring(p, 26.0, Vector3(0.0, 0.0, 4.0))
	if not low:
		_ring(p, 36.0, Vector3(0.0, 0.0, 4.0))
		_tower(p, Vector3(-26.0, 0.0, 22.0), 50.0)
	else:
		_zone(p, 22.0, Vector3(0.0, 0.0, 4.0))


## ── 4. EL RELICARIO ──────────────────────────────────────────────────────────────────────────────────────────────

static func _reliquary(p: Node3D, state: int) -> void:
	if state == 0:
		var slab := Clay.box(p, Vector3(8.0, 36.0, 4.0), Vector3(0.0, 26.0, 0.0), STONE.darkened(0.1))
		slab.rotation_degrees = Vector3(0.0, 20.0, 5.0)
		_weak(p, 1.6, Vector3(0.0, 44.5, 0.0))
		var orbit := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 15.8
		torus.outer_radius = 16.2
		orbit.mesh = torus
		orbit.material_override = Clay.material(BEAM)
		orbit.position = Vector3(0.0, 15.0, 0.0)
		p.add_child(orbit)
		for i in 3:
			var angle := TAU * i / 3.0
			var node := Vector3(cos(angle) * 16.0, 9.0 + i * 6.0, sin(angle) * 16.0)
			Clay.sphere(p, 3.0, node, Clay.DARK)
			_weak(p, 1.8, node + Vector3.UP * 2.0)
			_rod(p, Vector3(0.0, 18.0 + i * 6.0, 0.0), node, 0.35, CABLE)
		# Los círculos que explotan y un rayo que baja.
		for spot: Vector3 in [Vector3(-24.0, 0.0, 20.0), Vector3(4.0, 0.0, 28.0), Vector3(26.0, 0.0, 14.0)]:
			_zone(p, 7.0, spot)
			_ring(p, 7.0, spot)
		_rod(p, Vector3(4.0, 60.0, 28.0), Vector3(4.0, 0.0, 28.0), 1.5, BEAM)
	else:
		# Caído: una rampa; el núcleo, en la punta de arriba. Los nodos, rotos en el piso.
		var slab := Clay.box(p, Vector3(8.0, 4.0, 40.0), Vector3(0.0, 9.0, 0.0), STONE.darkened(0.1))
		slab.rotation_degrees = Vector3(-24.0, 25.0, 0.0)
		var tip := slab.transform * Vector3(0.0, 2.6, -18.0)
		_weak(p, 2.4, tip)
		for i in 3:
			var angle := TAU * i / 3.0 + 0.6
			Clay.sphere(p, 2.6, Vector3(cos(angle) * 22.0, 2.0, sin(angle) * 22.0), Clay.DARK.lightened(0.1))
		_person(p, slab.transform * Vector3(0.0, 2.0, 8.0))


## ── 5. EL CIEMPIÉS DE VAGONES ────────────────────────────────────────────────────────────────────────────────────

static func _centipede(p: Node3D, state: int) -> void:
	for i in 5:
		var at := Vector3(0.0, 9.0, -28.0 + i * 14.0)
		var turn := 0.0
		if state == 1:
			# Partido: los dos de adelante para un lado, los dos de atrás para el otro; el del medio, caído.
			if i < 2:
				at += Vector3(-14.0, 0.0, -6.0)
				turn = 25.0
			elif i > 2:
				at += Vector3(14.0, 0.0, 6.0)
				turn = -20.0
			else:
				at = Vector3(0.0, 4.0, 0.0)
		var car := Clay.box(p, Vector3(11.0, 8.0, 12.0), at, HULL if i % 2 == 0 else HULL.lightened(0.1))
		car.rotation_degrees = Vector3(0.0, turn, 18.0 if state == 1 and i == 2 else 0.0)
		if i == 0:
			Clay.box(p, Vector3(8.0, 5.0, 4.0), at + Vector3(0.0, -1.0, -8.0), Clay.DARK)
		if state == 1 and i == 2:
			_weak(p, 1.4, at + Vector3(0.0, 5.0, 0.0))
			continue
		for side: float in [-1.0, 1.0]:
			for dz: float in [-3.5, 3.5]:
				var hip := at + Basis(Vector3.UP, deg_to_rad(turn)) * Vector3(side * 5.5, -2.0, dz)
				var foot := at + Basis(Vector3.UP, deg_to_rad(turn)) * Vector3(side * 11.0, 0.0, dz)
				foot.y = 0.0
				_rod(p, hip, hip.lerp(foot, 0.5) + Vector3.UP * 4.0, 0.8, Clay.DARK)
				_rod(p, hip.lerp(foot, 0.5) + Vector3.UP * 4.0, foot, 0.7, Clay.DARK)
	# Los enganches de arriba, con sus cables (en el estado partido, los dos rotos chispean).
	for i in 4:
		var link := Vector3(0.0, 13.5, -21.0 + i * 14.0)
		if state == 1 and (i == 1 or i == 2):
			_weak(p, 1.0, link + Vector3(0.0, -3.0, 0.0) + (Vector3(-14.0, 0.0, -6.0) if i == 1 else Vector3(14.0, 0.0, 6.0)))
			continue
		if state == 1:
			link += Vector3(-14.0, 0.0, -6.0) if i == 0 else Vector3(14.0, 0.0, 6.0)
		_weak(p, 1.2, link)
		_rod(p, link + Vector3(0.0, -0.5, -3.0), link + Vector3(0.0, -0.5, 3.0), 0.5, CABLE)
	if state == 0:
		var line := Clay.box(p, Vector3(5.0, 0.1, 40.0), Vector3(0.0, 0.05, 54.0), ZONE)
		line.rotation_degrees = Vector3.ZERO
		_tower(p, Vector3(-20.0, 0.0, -8.0), 20.0)


## ── 6. LA COLMENA COLGANTE ───────────────────────────────────────────────────────────────────────────────────────

static func _hive(p: Node3D, state: int) -> void:
	var low := state == 1
	var center := Vector3(0.0, 14.0 if low else 38.0, 0.0)
	var body := Clay.sphere(p, 9.0, center, HULL)
	body.scale = Vector3(1.0, 0.6, 1.2)
	Clay.sphere(p, 1.2, center + Vector3(2.5, 2.0, -10.0), Clay.RED if low else Clay.DARK)
	Clay.sphere(p, 1.2, center + Vector3(-2.5, 2.0, -10.0), Clay.RED if low else Clay.DARK)
	for i in 6:
		var angle := TAU * (i + 0.5) / 6.0
		var out := Vector3(cos(angle), 0.0, sin(angle))
		var hip := center + out * 7.0
		var knee := out * (16.0 if low else 22.0) + Vector3.UP * (center.y + (16.0 if low else 12.0))
		var foot := out * (24.0 if low else 34.0)
		_rod(p, hip, knee, 1.4, Clay.DARK)
		_rod(p, knee, foot, 1.1, Clay.DARK)
	if not low:
		# La bolsa colgada de cuatro cables, con su núcleo; debajo, el pisotón; caen gotas.
		var sac := Vector3(0.0, 16.0, 0.0)
		for i in 4:
			var corner := Vector3(cos(TAU * i / 4.0) * 3.0, 0.0, sin(TAU * i / 4.0) * 3.0)
			_rod(p, center + corner + Vector3.DOWN * 4.0, sac + corner * 0.6 + Vector3.UP * 4.0, 0.35, CABLE)
			_weak(p, 0.7, sac + corner * 0.6 + Vector3.UP * 4.5)
		Clay.sphere(p, 5.0, sac, Color(0.55, 0.45, 0.3))
		_weak(p, 2.0, sac + Vector3(0.0, -3.0, -3.0))
		_zone(p, 20.0, Vector3.ZERO)
		for i in 3:
			Clay.sphere(p, 0.8, Vector3(8.0 - i * 6.0, 10.0 - i * 3.0, 14.0), Color(0.55, 0.45, 0.3))
			_zone(p, 3.0, Vector3(8.0 - i * 6.0, 0.0, 22.0))
		_person(p, Vector3(3.0, 0.0, 4.0))
	else:
		# La bolsa, rota en el piso; el núcleo, afuera. Frenesí: pisa por todos lados.
		var sac := Clay.sphere(p, 5.0, Vector3(8.0, 2.0, 10.0), Color(0.55, 0.45, 0.3))
		sac.scale = Vector3(1.2, 0.5, 1.0)
		_weak(p, 2.4, Vector3(12.0, 2.4, 13.0))
		_zone(p, 26.0, Vector3.ZERO)


## ── LA ARCILLA DE LAS MAQUETAS ───────────────────────────────────────────────────────────────────────────────────

## Un punto débil: una esfera naranja que brilla.
static func _weak(p: Node3D, radius: float, at: Vector3) -> void:
	var part := Clay.sphere(p, radius, at, WEAK)
	part.material_override = _glow_material()


static func _glow_material() -> StandardMaterial3D:
	if _glow == null:
		_glow = StandardMaterial3D.new()
		_glow.albedo_color = WEAK
		_glow.emission_enabled = true
		_glow.emission = WEAK
		_glow.emission_energy_multiplier = 2.5
	return _glow


## Un palo redondo de `from` a `to` (una pata, un cable, un rayo).
static func _rod(p: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> void:
	var part := Clay.limb(p, radius, 1.0, Vector3.ZERO, color)
	var along := to - from
	var size := maxf(along.length(), 0.001)
	var up := Vector3.UP if absf(along.normalized().dot(Vector3.UP)) < 0.95 else Vector3.BACK
	part.transform = Transform3D(Basis.looking_at(along / size, up).scaled_local(Vector3(1.0, 1.0, size)),
		(from + to) * 0.5)


## Una zona de ataque en el piso (un disco rojo transparente).
static func _zone(p: Node3D, radius: float, at: Vector3) -> void:
	Clay.cylinder(p, radius, 0.12, Vector3(at.x, 0.08, at.z), ZONE)


## Una onda en el piso (un anillo rojo).
static func _ring(p: Node3D, radius: float, at: Vector3) -> void:
	var part := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.8
	torus.outer_radius = radius
	part.mesh = torus
	part.material_override = Clay.material(Color(0.95, 0.2, 0.1, 0.55))
	part.position = Vector3(at.x, 0.3, at.z)
	p.add_child(part)


## Un punto alto desde donde tirarse, con una persona arriba.
static func _tower(p: Node3D, at: Vector3, height: float) -> void:
	Clay.box(p, Vector3(7.0, height, 7.0), at + Vector3.UP * height * 0.5, STONE.lightened(0.15))
	_person(p, at + Vector3.UP * height)


## La meca, para la escala: el bloque de 18 m.
static func _mech(p: Node3D, at: Vector3) -> void:
	Clay.box(p, Vector3(9.0, 18.0, 7.0), at + Vector3.UP * 9.0, Clay.RED)


## Una persona, para la escala: 1,8 m.
static func _person(p: Node3D, at: Vector3) -> void:
	Clay.cylinder(p, 0.35, 1.4, at + Vector3.UP * 0.7, Clay.YELLOW)
	Clay.sphere(p, 0.25, at + Vector3.UP * 1.6, Clay.YELLOW)


static func _sign(p: Node3D, text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.02
	label.font_size = 160
	label.outline_size = 24
	label.position = at
	p.add_child(label)
