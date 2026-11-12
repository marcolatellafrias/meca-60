class_name SupplyLook
extends RefCounted

## EL DIBUJO DE LOS RECURSOS DE LA MECA, en arcilla y «así nomás» (el usuario, 13/11/2026: «después voy a remodelar
## todos y voy a hacer eso con las texturas con píxeles. Pero bueno, por ahora se entiende lo que son»). Elegidos entre
## cuatro tandas de maquetas. TODO ES UN CUBO DE 63 cm («una celda de tamaño único que se agarra siempre igual»): lo que
## se lleva y también el lugar de la meca donde se carga la munición. Cada función dibuja uno en `cube`, un nodo en el
## centro del cubo, con LA CARA DE LECTURA HACIA +Z.
##
## LO QUE PIDIÓ, que vale para lo que se agregue:
##   · QUE SE SIENTA UNA CAJA, una unidad: ni un armazón de barras alrededor ni cosas sueltas sobre una base; lo suyo,
##     empotrado o sobresaliendo.
##   · DOWN TO EARTH, no futurista: colores tranquilos y con poco contraste, sin verdes ni brillos; estereotipos (la
##     batería con sus polos, la bomba como un atado de cartuchos).
##   · LOW POLY («le da más carácter»): cilindros de pocas caras, con las caras planas.
##   · Las cajas de munición, lisas: son pura textura, y eso viene después.
##
## LOS QUE SE LLEVAN (ver `KEYS`; los arma como paquetes PackageArchetype): la batería, el componente eléctrico, la caja
## de misiles, la caja de balas y la bomba. LOS QUE VAN EN LA MECA: los misiles (nueve tubos) y las balas (la cinta en
## una ventana), que muestran lo que les queda.

const U := 0.63
const H := U * 0.5
const KEYS := ["battery", "component", "crate_missiles", "crate_bullets", "bomb"]
const LEAD := Color(0.46, 0.46, 0.47)
const OXIDE := Color(0.4, 0.21, 0.17)
const ENAMEL := Color(0.47, 0.45, 0.4)
const CERAMIC := Color(0.72, 0.69, 0.62)
const CREAM := Color(0.8, 0.75, 0.62)
const WARM := Color(0.95, 0.78, 0.45)
const SOOT := Color(0.09, 0.085, 0.08)
const CRATE := Color(0.38, 0.39, 0.32)
const CRATE_MISSILES := Color(0.47, 0.4, 0.27)
const STEEL := Color(0.4, 0.41, 0.43)
const MUSTARD := Color(0.72, 0.6, 0.25)
const DYNAMITE := Color(0.6, 0.22, 0.17)
## Cuántos misiles y cuántas filas de balas (en cuatro columnas) entran en su cubo de la meca.
const MISSILES := 9
const BELT_ROWS := 19


## Dibuja en `cube` el recurso que se lleva de clave `key` (ver `KEYS`), entero y sano. Devuelve si lo conoce.
static func carried(cube: Node3D, key: String) -> bool:
	match key:
		"battery": battery(cube, 1.0)
		"component": component(cube, false)
		"crate_missiles": crate(cube, CRATE_MISSILES, MUSTARD)
		"crate_bullets": crate(cube, CRATE, LEAD)
		"bomb": dynamite(cube)
		_: return false
	return true


## LA BATERÍA: colorada, como una de auto: la caja, la tapa, los dos polos y las tapas de sus celdas arriba, y una
## mirilla acostada con el nivel (`level`, de 0 a 1). Gastada, toda más oscura y la mirilla vacía.
static func battery(cube: Node3D, level: float) -> void:
	var body := OXIDE if level > 0.0 else OXIDE.darkened(0.45)
	var lid := body.darkened(0.3)
	Clay.box(cube, Vector3(U, 0.5, U), Vector3(0, -0.065, 0), body)
	Clay.box(cube, Vector3(U, 0.06, U), Vector3(0, 0.215, 0), lid)
	for side: float in [-1.0, 1.0]:
		for rib in 4:
			Clay.box(cube, Vector3(0.012, 0.42, 0.05), Vector3(side * H, -0.08, -0.21 + rib * 0.14), body.darkened(0.25))
		_cyl(cube, 0.05, 0.065, 0.07, Vector3(side * 0.2, 0.28, -0.14), LEAD if level > 0.0 else LEAD.darkened(0.4))
	for cell in 3:
		_cyl(cube, 0.045, 0.045, 0.035, Vector3((cell - 1) * 0.16, 0.262, 0.12), lid.lightened(0.2), Vector3.ZERO, 6)
	var window := Vector3(0.44, 0.13, 0.012)
	Clay.box(cube, window + Vector3(0.05, 0.05, 0.0), Vector3(0, -0.07, H), body.darkened(0.35))
	Clay.box(cube, window, Vector3(0, -0.07, H + 0.004), SOOT)
	if level > 0.0:
		var full := window.x - 0.03
		_lit(Clay.box(cube, Vector3(full * level, window.y - 0.03, 0.012), Vector3(-full * (1.0 - level) * 0.5, -0.07, H + 0.008), WARM), WARM, 0.7)


## EL COMPONENTE ELÉCTRICO (algo que se quema y se reemplaza; no un fusible literal): una caja esmaltada tipo
## transformador, casi un cubo: el cuerpo, aletas que apenas asoman a los costados, dos bornes de porcelana arriba y una
## lamparita al frente que dice que anda. Quemado: todo oscuro, tiznado, la lamparita apagada.
static func component(cube: Node3D, burnt: bool) -> void:
	var body := ENAMEL if not burnt else ENAMEL.darkened(0.62)
	var trim := body.darkened(0.22)
	var ceramic := CERAMIC if not burnt else CERAMIC.darkened(0.7)
	var metal := LEAD if not burnt else LEAD.darkened(0.6)
	Clay.box(cube, Vector3(0.55, 0.5, U), Vector3(0, -0.065, 0), body)
	for side: float in [-1.0, 1.0]:
		for fin in 8:
			Clay.box(cube, Vector3(0.04, 0.5, 0.035), Vector3(side * 0.295, -0.065, -0.266 + fin * 0.076), trim)
		for disc in 2:
			_cyl(cube, 0.045, 0.07, 0.04, Vector3(side * 0.13, 0.205 + disc * 0.045, 0.0), ceramic)
		_cyl(cube, 0.02, 0.02, 0.03, Vector3(side * 0.13, 0.3, 0.0), metal, Vector3.ZERO, 6)
	Clay.box(cube, Vector3(0.34, 0.2, 0.012), Vector3(0, -0.13, H), trim)
	var bulb := _cyl(cube, 0.035, 0.035, 0.03, Vector3(0.0, 0.08, H + 0.012), WARM if not burnt else SOOT, Vector3(90, 0, 0))
	if not burnt:
		_lit(bulb, WARM, 1.6)
	else:
		Clay.box(cube, Vector3(0.16, 0.14, 0.008), Vector3(0.0, 0.11, H), SOOT)


## UNA CAJA DE MUNICIÓN: lisa, con su tapa y una etiqueta plana con una franja del color de lo que lleva.
static func crate(cube: Node3D, body: Color, label: Color) -> void:
	Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, body)
	Clay.box(cube, Vector3(U + 0.006, 0.02, U + 0.006), Vector3(0, 0.2, 0), body.darkened(0.3))
	Clay.box(cube, Vector3(0.34, 0.2, 0.008), Vector3(0, -0.04, H), CREAM)
	Clay.box(cube, Vector3(0.34, 0.05, 0.01), Vector3(0, -0.04, H + 0.002), label)


## LA BOMBA (la tira el jugador a pie): nueve cartuchos de dinamita parados, con una faja ancha de papel, y la mecha en
## el del medio. Como la TNT de Minecraft: sin armazón ni botón.
static func dynamite(cube: Node3D) -> void:
	var radius := U / 6.0
	for a in 3:
		for b in 3:
			var at := Vector3((a - 1) * radius * 2.0, 0.0, (b - 1) * radius * 2.0)
			_cyl(cube, radius - 0.004, radius - 0.004, U - 0.03, at, DYNAMITE, Vector3(0, 22.5, 0))
			_cyl(cube, radius * 0.72, radius * 0.72, U, at, DYNAMITE.darkened(0.35), Vector3(0, 22.5, 0))
	Clay.box(cube, Vector3(U + 0.006, 0.2, U + 0.006), Vector3.ZERO, CREAM)
	_cyl(cube, 0.012, 0.012, 0.09, Vector3(0, H + 0.04, 0), Color(0.3, 0.27, 0.22), Vector3.ZERO, 6)


## LOS MISILES, EN LA MECA: un cubo con nueve tubos en la cara; cada misil que queda (`left`) asoma la punta.
static func missiles(cube: Node3D, left: int) -> void:
	Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, STEEL)
	for index in MISSILES:
		var at := Vector3((index % 3 - 1) * 0.195, (1 - float(index / 3)) * 0.195, H)
		_cyl(cube, 0.08, 0.08, 0.012, at, SOOT, Vector3(90, 0, 0))
		if index < left:
			_cyl(cube, 0.0, 0.066, 0.11, at + Vector3(0, 0, 0.05), MUSTARD, Vector3(90, 0, 0))


## LAS BALAS, EN LA MECA: un cubo con una ventana donde se ve la cinta, en cuatro columnas apretadas de balas finas;
## baja a medida que se gasta (`rows`, de 0 a `BELT_ROWS`).
static func belt(cube: Node3D, rows: int) -> void:
	Clay.box(cube, Vector3(U, U, U), Vector3.ZERO, STEEL)
	Clay.box(cube, Vector3(0.55, 0.55, 0.012), Vector3(0, 0, H), SOOT)
	for column in 4:
		var x := (column - 1.5) * 0.132
		for row in rows:
			var y := -0.243 + row * 0.027
			_cyl(cube, 0.0105, 0.0105, 0.08, Vector3(x - 0.02, y, H + 0.014), LEAD.lightened(0.15), Vector3(0, 0, 90), 6)
			_cyl(cube, 0.0, 0.0105, 0.04, Vector3(x + 0.04, y, H + 0.014), CREAM, Vector3(0, 0, -90), 6)


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## UN CILINDRO (o un cono) LOW POLY: de `sides` caras, con las caras planas (cada una con su normal).
static func _cyl(parent: Node3D, top: float, bottom: float, height: float, at: Vector3, color: Color,
		turn := Vector3.ZERO, sides := 8) -> MeshInstance3D:
	var round := CylinderMesh.new()
	round.top_radius = top
	round.bottom_radius = bottom
	round.height = height
	round.radial_segments = sides
	round.rings = 0
	var tool := SurfaceTool.new()
	tool.create_from(round, 0)
	tool.deindex()
	tool.generate_normals()
	var part := MeshInstance3D.new()
	part.mesh = tool.commit()
	part.material_override = Clay.material(color)
	part.position = at
	part.rotation_degrees = turn
	parent.add_child(part)
	return part


## Una pieza que brilla un poco (el nivel de la batería, la lamparita).
static func _lit(part: MeshInstance3D, color: Color, energy := 1.0) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	part.material_override = material
