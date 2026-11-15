class_name BaseLayout
extends RefCounted

## LA BASE (la sucursal bajo tierra), EN ARCILLA: el plano 6 de docs/conceptual/base.md, sin estética todavía.
## Un solo piso, todo al mismo nivel y sin divisiones: el elevador (un cuadrado marcado del piso, donde duerme la meca),
## el gimnasio con la bolsa, y abajo una franja angosta con las consolas contra la pared (los contratos, la armería,
## los cosméticos con la pintura), los casilleros con el cuadro del empleado del mes y el ascensor de personal metido en
## la pared. Debajo del elevador, pared. Arriba, el techo, con la compuerta sobre el elevador (BaseHatch) que se abre
## cuando empieza una partida.
##
## Las medidas, en metros sobre el plano: X a lo largo (0 el borde del elevador), Z hacia la franja (0 la pared del
## fondo). Todo se corre con OFFSET para quedar centrado en la parcela.

const ELEVATOR := 24.0          # el lado del cuadrado del elevador
const LENGTH := 60.0            # el largo del elevador más el gimnasio
const NAVE := 24.0              # el fondo del elevador y del gimnasio
## El fondo más grande que puede tener la franja (BaseSettings): la parcela se mide con él.
const MAX_STRIP := 30.0
const WALL := 0.5
## El hueco del ascensor de personal, metido en la pared de la punta, PERSONNEL_DEPTH hacia afuera.
const PERSONNEL_DEPTH := 4.5
const PERSONNEL_WIDTH := 5.2
## El alto del hueco: sólo lo del ascensor (el usuario: «es una ilusión de continuidad»). Arriba sigue la pared.
const PERSONNEL_HEIGHT := 3.4
## El grosor del techo y el borde de la compuerta: el mismo cuadrado marcado del elevador.
const ROOF := 0.6
const HATCH_INSET := 1.0
## La bolsa: centrada en alto, a la derecha del gimnasio, con margen para que un golpe fuerte no la lleve a la pared.
const BAG_AT := Vector2(50.0, 12.0)
const BAG_RADIUS := 2.6
const BAG_LOW := 7.0
const BAG_HIGH := 15.0
## Cuánto puede ocupar todo, con el hueco del ascensor de personal y la franja más honda. El plano queda centrado en
## eso: con una franja menos honda, la base se arrima a la pared del fondo.
const SIZE := Vector2(LENGTH + PERSONNEL_DEPTH, NAVE + MAX_STRIP)
const OFFSET := Vector3(-SIZE.x * 0.5, 0.0, -SIZE.y * 0.5)
## Dónde duerme la meca (el centro del elevador) y hacia dónde mira (al gimnasio).
const MECH_AT := Vector2(ELEVATOR * 0.5, NAVE * 0.5)
## El grupo de los nodos que tienen una base armada adentro (para rearmarla al guardar el F1).
const GROUP := "base_plano"

## LAS MEDIDAS QUE SE MUEVEN (BaseSettings, el F1), tomadas al armar: el alto de la nave, el fondo y el alto de la
## franja (a escala de persona, no de meca: encima de su borde abierto, la pared de la nave baja hasta ahí, como un
## dintel), y de dónde a dónde va el hueco del ascensor de personal (en la esquina del fondo de la franja).
static var height := 22.0
static var strip := 12.0
static var strip_height := 5.0
static var personnel_z1 := 0.0
static var personnel_z2 := 0.0

const FLOOR_COLOR := Color(0.62, 0.6, 0.56)
const ELEVATOR_COLOR := Color(0.55, 0.57, 0.6)
const STRIPE_COLOR := Color(0.85, 0.68, 0.22)
const HAZARD_DARK := Color(0.16, 0.15, 0.14)
const WALL_COLOR := Color(0.72, 0.69, 0.64)
const BAG_COLOR := Color(0.55, 0.33, 0.25)
const CONSOLE_COLOR := Color(0.42, 0.44, 0.46)
const SCREEN_COLOR := Color(0.45, 0.6, 0.5)
const LOCKER_COLOR := Color(0.5, 0.56, 0.52)
const FRAME_COLOR := Color(0.75, 0.6, 0.25)
const CAGE_COLOR := Color(0.5, 0.5, 0.48)


## Un punto del plano (x, z, alto) en las coordenadas de la parcela.
static func at(x: float, z: float, y := 0.0) -> Vector3:
	return OFFSET + Vector3(x, y, z)


## Toma las medidas del F1.
static func measure() -> void:
	var settings := BaseSettings.current
	height = settings.nave_height
	strip = settings.strip_depth
	strip_height = settings.strip_height
	personnel_z2 = NAVE + strip - 1.2
	personnel_z1 = personnel_z2 - PERSONNEL_WIDTH


## Arma la base en un nodo propio, colgado de `parent` (en el grupo GROUP, para rearmarla).
static func build_into(parent: Node3D) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Plano"
	holder.add_to_group(GROUP)
	parent.add_child(holder)
	build(holder)
	return holder


## La vuelve a armar con las medidas de ahora, en el mismo nodo.
static func rebuild(holder: Node3D) -> void:
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	build(holder)


static func build(parent: Node3D) -> StaticBody3D:
	measure()
	var body := StaticBody3D.new()
	body.name = "Base"
	parent.add_child(body)
	_floor(body)
	_walls(body)
	_bag(body)
	_consoles(body)
	_characters(body)
	_roof(body)
	_lights(body)
	var hatch := BaseHatch.new()
	hatch.name = "Compuerta"
	parent.add_child(hatch)
	hatch.build()
	return body


## EL PISO, en L, y el cuadrado del elevador marcado con su borde amarillo.
static func _floor(body: StaticBody3D) -> void:
	_slab(body, 0.0, LENGTH, 0.0, NAVE, FLOOR_COLOR)
	_slab(body, ELEVATOR, LENGTH, NAVE, NAVE + strip, FLOOR_COLOR)
	_slab(body, LENGTH, LENGTH + PERSONNEL_DEPTH, personnel_z1, personnel_z2, FLOOR_COLOR)
	var inset := 1.0
	var side := ELEVATOR - inset * 2.0
	Clay.box(body, Vector3(side, 0.02, side), at(ELEVATOR * 0.5, NAVE * 0.5, 0.01), ELEVATOR_COLOR)
	var dash := 1.0
	var count := int(side / (dash * 2.0))
	for i in count:
		var along := inset + dash * (i * 2.0 + 0.5)
		for edge in [inset, ELEVATOR - inset]:
			Clay.box(body, Vector3(dash, 0.03, 0.3), at(along, edge, 0.015), STRIPE_COLOR)
			Clay.box(body, Vector3(0.3, 0.03, dash), at(edge, along, 0.015), STRIPE_COLOR)
	_hazard_line(body)


## LA LÍNEA DE PELIGRO entre el gimnasio y la franja de las consolas (el usuario, 15/11/2026): rayas amarillas y negras
## en el piso, sin pared ni vidrio. Del lado de la gente, se está a salvo de la meca.
static func _hazard_line(body: StaticBody3D) -> void:
	var stripe := 0.8
	var count := int((LENGTH - ELEVATOR) / stripe)
	for i in count:
		var color := STRIPE_COLOR if i % 2 == 0 else HAZARD_DARK
		Clay.box(body, Vector3(stripe, 0.03, 0.6), at(ELEVATOR + stripe * (i + 0.5), NAVE, 0.015), color)


static func _slab(body: StaticBody3D, x1: float, x2: float, z1: float, z2: float, color: Color) -> void:
	Clay.solid(body, Vector3(x2 - x1, 0.4, z2 - z1), at((x1 + x2) * 0.5, (z1 + z2) * 0.5, -0.2), color)


## LAS PAREDES, por el contorno de la L y del hueco del ascensor de personal.
static func _walls(body: StaticBody3D) -> void:
	var outline: Array[Vector2] = [
		Vector2(0, 0), Vector2(LENGTH, 0), Vector2(LENGTH, NAVE), Vector2(LENGTH, personnel_z1),
		Vector2(LENGTH + PERSONNEL_DEPTH, personnel_z1), Vector2(LENGTH + PERSONNEL_DEPTH, personnel_z2),
		Vector2(LENGTH, personnel_z2), Vector2(LENGTH, NAVE + strip), Vector2(ELEVATOR, NAVE + strip),
		Vector2(ELEVATOR, NAVE), Vector2(0, NAVE), Vector2(0, 0),
	]
	for i in outline.size() - 1:
		var a := outline[i]
		var b := outline[i + 1]
		# las tres del hueco del ascensor de personal, sólo de su alto; las de la franja, del alto de la franja
		var high := height
		if i in [3, 4, 5]:
			high = PERSONNEL_HEIGHT
		elif minf(a.y, b.y) >= NAVE - 0.01 and minf(a.x, b.x) >= ELEVATOR - 0.01:
			high = strip_height
		var mid := (a + b) * 0.5
		var length := a.distance_to(b) + WALL
		var size := Vector3(length, high, WALL) if is_equal_approx(a.y, b.y) else Vector3(WALL, high, length)
		Clay.solid(body, size, at(mid.x, mid.y, high * 0.5), WALL_COLOR)
	# encima del hueco sigue la pared de la franja, y el hueco tiene su techito
	var gap := personnel_z2 - personnel_z1
	Clay.solid(body, Vector3(WALL, strip_height - PERSONNEL_HEIGHT, gap), at(LENGTH, (personnel_z1 + personnel_z2) * 0.5,
		(strip_height + PERSONNEL_HEIGHT) * 0.5), WALL_COLOR)
	# el dintel: la pared de la nave sobre el borde abierto de la franja
	Clay.solid(body, Vector3(LENGTH - ELEVATOR + WALL, height - strip_height, WALL),
		at((ELEVATOR + LENGTH) * 0.5, NAVE, (height + strip_height) * 0.5), WALL_COLOR)
	Clay.solid(body, Vector3(PERSONNEL_DEPTH + WALL, 0.3, gap + WALL), at(LENGTH + PERSONNEL_DEPTH * 0.5,
		(personnel_z1 + personnel_z2) * 0.5, PERSONNEL_HEIGHT + 0.15), WALL_COLOR)


## EL TECHO, sobre todo menos la compuerta del elevador.
static func _roof(body: StaticBody3D) -> void:
	var y := height + ROOF * 0.5
	var far := ELEVATOR - HATCH_INSET
	for piece: Rect2 in [
			Rect2(0, 0, HATCH_INSET, NAVE), Rect2(far, 0, HATCH_INSET, NAVE),
			Rect2(HATCH_INSET, 0, far - HATCH_INSET, HATCH_INSET),
			Rect2(HATCH_INSET, NAVE - HATCH_INSET, far - HATCH_INSET, HATCH_INSET),
			Rect2(ELEVATOR, 0, LENGTH - ELEVATOR, NAVE)]:
		Clay.solid(body, Vector3(piece.size.x, ROOF, piece.size.y), at(piece.get_center().x, piece.get_center().y, y),
			WALL_COLOR)
	# el techo bajo de la franja
	Clay.solid(body, Vector3(LENGTH - ELEVATOR, ROOF, strip), at((ELEVATOR + LENGTH) * 0.5, NAVE + strip * 0.5,
		strip_height + ROOF * 0.5), WALL_COLOR)


## LAS LUCES: con techo, el sol no entra. Lámparas colgadas, sin sombras.
static func _lights(body: StaticBody3D) -> void:
	var high := height - 4.0
	var low := strip_height - 0.7
	var middle := NAVE + strip * 0.5
	for spot: Vector3 in [Vector3(12, 12, high), Vector3(36, 8, high), Vector3(52, 18, high), Vector3(34, middle, low),
			Vector3(52, middle, low)]:
		var where := at(spot.x, spot.y, spot.z)
		Clay.sphere(body, 0.4, where, Color(1.0, 0.95, 0.8))
		var lamp := OmniLight3D.new()
		lamp.position = where
		lamp.omni_range = 34.0
		lamp.light_energy = 1.6
		body.add_child(lamp)


## LA BOLSA, colgada de una viga a lo ancho del gimnasio. Fija por ahora (la física, después).
static func _bag(body: StaticBody3D) -> void:
	var center := at(BAG_AT.x, BAG_AT.y)
	Clay.box(body, Vector3(0.6, 0.8, NAVE), Vector3(center.x, height - 0.4, OFFSET.z + NAVE * 0.5), CAGE_COLOR)
	Clay.cylinder(body, 0.12, height - BAG_HIGH, center + Vector3.UP * (BAG_HIGH + height) * 0.5, CAGE_COLOR)
	Clay.cylinder(body, BAG_RADIUS, BAG_HIGH - BAG_LOW, center + Vector3.UP * (BAG_LOW + BAG_HIGH) * 0.5, BAG_COLOR)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = BAG_RADIUS
	cylinder.height = BAG_HIGH - BAG_LOW
	shape.shape = cylinder
	shape.position = center + Vector3.UP * (BAG_LOW + BAG_HIGH) * 0.5
	body.add_child(shape)


## LAS TRES CONSOLAS, contra la pared de la franja: una caja con la pantalla inclinada encima y su cartel.
static func _consoles(body: StaticBody3D) -> void:
	_console(body, 30.75, 6.0, "Contratos")
	_console(body, 41.0, 4.5, "Armería")
	_console(body, 47.0, 4.5, "Cosméticos y pintura")


static func _console(body: StaticBody3D, x: float, width: float, label: String) -> void:
	var z := NAVE + strip - WALL * 0.5 - 0.5
	Clay.solid(body, Vector3(width, 1.0, 1.0), at(x, z, 0.5), CONSOLE_COLOR)
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-35.0))
	Clay.solid(body, Vector3(width * 0.9, 0.9, 0.08), at(x, z + 0.15, 1.35), SCREEN_COLOR, tilt)
	_sign(body, label, at(x, z, 2.6))


## LOS PERSONAJES: los casilleros contra la pared, el cuadro chiquito al lado y el ascensor de personal en su hueco.
static func _characters(body: StaticBody3D) -> void:
	var z := NAVE + strip - WALL * 0.5 - 0.3
	for i in 6:
		Clay.solid(body, Vector3(0.95, 2.0, 0.6), at(51.5 + i * 1.05, z, 1.0), LOCKER_COLOR)
	Clay.box(body, Vector3(0.6, 0.8, 0.05), at(57.8, NAVE + strip - WALL * 0.5 - 0.03, 1.7), FRAME_COLOR)
	_sign(body, "Casilleros · el empleado del mes", at(54.5, z, 2.8))
	# el ascensor de personal: una jaula de reja, abierta hacia el piso
	var x0 := LENGTH + 0.3
	var x1 := LENGTH + PERSONNEL_DEPTH - 0.3
	for k in 7:
		var bx := lerpf(x0, x1, k / 6.0)
		Clay.box(body, Vector3(0.06, 3.0, 0.06), at(bx, personnel_z1 + 0.3, 1.5), CAGE_COLOR)
		Clay.box(body, Vector3(0.06, 3.0, 0.06), at(bx, personnel_z2 - 0.3, 1.5), CAGE_COLOR)
	Clay.box(body, Vector3(PERSONNEL_DEPTH - 0.6, 0.1, personnel_z2 - personnel_z1 - 0.6),
		at(LENGTH + PERSONNEL_DEPTH * 0.5, (personnel_z1 + personnel_z2) * 0.5, 3.05), CAGE_COLOR)
	_sign(body, "Ascensor de personal", at(LENGTH + PERSONNEL_DEPTH * 0.5, (personnel_z1 + personnel_z2) * 0.5, 3.8))


static func _sign(parent: Node3D, text: String, where: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.15, 0.14, 0.13)
	label.outline_modulate = Color(0.95, 0.93, 0.9)
	label.outline_size = 12
	label.position = where
	parent.add_child(label)
