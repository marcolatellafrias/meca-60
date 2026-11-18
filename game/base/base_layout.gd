class_name BaseLayout
extends RefCounted

## LA BASE (la sucursal bajo tierra), EN ARCILLA, A ESCALA HUMANA (el plano de la esclusa, 17/11/2026, ver
## docs/conceptual/base.md): la misma estructura que tenía para la meca grande, achicada para la meca jaula (≈ 7 m).
## Un solo piso, todo al mismo nivel:
##   · EL ELEVADOR, un cuadrado marcado del piso donde duerme la meca; arriba, la compuerta del techo (BaseHatch).
##   · EL GIMNASIO con la bolsa, a la altura de los brazos de la meca.
##   · LA FRANJA DE LAS CONSOLAS, abajo del gimnasio, separada por la línea de peligro. Usa sus dos caras libres (el
##     usuario: «tenemos… dos caras… vos estás dejando una vacía»): EL FONDO, con la armería, los cosméticos, el cuadro
##     del empleado del mes y los casilleros (junto a la esclusa: lo primero al salir); y LA PARED BAJO EL ELEVADOR, con
##     los contratos (al lado de la meca: lo último antes de salir).
##   · LA ESCLUSA (BaseAirlock), la sala de espera, en la punta de la franja: un cuadrado DEL LADO DEL FONDO DE LA FRANJA
##     (el usuario: «coincide siempre, por más de que cambie… el fondo de la franja… paramétrico»). Se aparece ahí; su
##     compuerta da a la franja y se abre una sola vez.
##
## Las medidas, en metros sobre el plano: X a lo largo (0 el borde del elevador), Z hacia la franja (0 la pared del
## fondo). Todo se corre con OFFSET para quedar centrado en la parcela. Las grandes se mueven con el F1 (ver `measure`).
## *Hasta el 17/11/2026 la base era para la meca grande (14 m): el elevador de 24 m, la nave de 22 m de alto y el
## ascensor de personal metido en la pared, que la esclusa reemplaza.*

## LO MÁS GRANDE QUE PUEDEN SER las medidas del F1 (BaseSettings): la parcela se mide con eso.
const MAX_DEPTH := 20.0
const MAX_WIDTH := 30.0
const MAX_STRIP := 12.0
const WALL := 0.3
## El grosor del techo y el borde de la compuerta: el mismo cuadrado marcado del elevador.
const ROOF := 0.35
const HATCH_INSET := 0.5
## LA BOLSA (ver `bag_at`): su radio, de qué alto a qué alto (que se le pegue con la meca agachada: el usuario, 17/11/2026,
## «termina demasiado arriba… que se pueda pegar aunque la meca esté agachada»), y lo libre a su alrededor (para dar
## vueltas pegándole, o para que un golpe fuerte no la lleve a la pared).
const BAG_RADIUS := 0.9
const BAG_LOW := 1.0
const BAG_HIGH := 4.6
const BAG_CLEAR := 2.5
## Cuánto puede ocupar todo, con todo lo más grande. El plano queda centrado en eso.
const SIZE := Vector2(MAX_DEPTH + MAX_WIDTH + MAX_STRIP, MAX_DEPTH + MAX_STRIP)
const OFFSET := Vector3(-SIZE.x * 0.5, 0.0, -SIZE.y * 0.5)
## El grupo de los nodos que tienen una base armada adentro (para rearmarla al guardar el F1).
const GROUP := "base_plano"
## LO DEL FONDO DE LA FRANJA, en fila desde la pared bajo el elevador: la armería, los cosméticos y el cuadro; los
## casilleros llenan lo que sobra hasta la esclusa (sin lugares vacíos: entran los que entran).
const CONSOLE_WIDTH := 3.0
const BACK_GAP := 0.4
const FRAME_WIDTH := 0.7
const LOCKER_WIDTH := 0.9

## LAS MEDIDAS QUE SE MUEVEN (BaseSettings, el F1), tomadas al armar (el usuario, 17/11/2026: «perillas para el alto
## de la zona de gimnasio más ascensor, la profundidad… el ancho de la franja de consolas y el fondo»):
##   · `height`, el alto de la nave (el elevador y el gimnasio).
##   · `depth`, su fondo, que es también EL LADO DEL ELEVADOR: es siempre un cuadrado, y crece hacia su lado (la franja
##     queda alineada con él).
##   · `width`, el ancho de la franja, que es también el largo del gimnasio.
##   · `strip` y `strip_height`, el fondo y el alto de la franja (y de la esclusa, que los sigue).
static var height := 12.0
static var depth := 10.0
static var width := 14.0
static var strip := 6.0
static var strip_height := 4.0
## Lo que sale de ésas: el lado del elevador, el largo de todo (elevador y gimnasio) y el fondo de la nave.
static var ELEVATOR := 10.0
static var LENGTH := 24.0
static var NAVE := 10.0
## Dónde duerme la meca (el centro del elevador; mira al gimnasio) y dónde cuelga la bolsa.
static var MECH_AT := Vector2(5.0, 5.0)
static var bag_at := Vector2(17.0, 5.0)

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
	depth = settings.nave_depth
	width = settings.strip_width
	strip = settings.strip_depth
	strip_height = settings.strip_height
	ELEVATOR = depth
	NAVE = depth
	LENGTH = depth + width
	MECH_AT = Vector2(ELEVATOR * 0.5, NAVE * 0.5)
	# LA BOLSA (el usuario: «el toggle básicamente decide con qué criterio sitúas la bolsa»): AL MEDIO del gimnasio, para
	# dar vueltas pegándole; o EN LA PUNTA, contra la pared del fondo con lo libre de margen, para pegarle de un lado.
	var x := ELEVATOR + width * 0.5
	if settings.bag_place == 1:
		x = maxf(x, LENGTH - BAG_CLEAR - BAG_RADIUS)
	bag_at = Vector2(x, NAVE * 0.5)


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
	# la meca, de nuevo al centro del elevador (pudo cambiar el fondo de la nave)
	BaseArchetype.place_mech(holder.get_parent() as Node3D)


static func build(parent: Node3D) -> StaticBody3D:
	measure()
	var body := StaticBody3D.new()
	body.name = "Base"
	# lo fijo del mundo: la meca (cinemática) frena y se para sólo contra eso (PhysicsLayers.FIXED)
	PhysicsLayers.mark_fixed(body)
	parent.add_child(body)
	_floor(body)
	_walls(body)
	_bag(parent)
	_consoles(body)
	_characters(body)
	_roof(body)
	_lights(body)
	var hatch := BaseHatch.new()
	hatch.name = "Compuerta"
	parent.add_child(hatch)
	hatch.build()
	var airlock := BaseAirlock.new()
	airlock.name = "Esclusa"
	airlock.position = at(LENGTH, NAVE)
	parent.add_child(airlock)
	airlock.build(strip, strip_height)
	return body


## EL PISO, en L, y el cuadrado del elevador marcado con su borde amarillo.
static func _floor(body: StaticBody3D) -> void:
	_slab(body, 0.0, LENGTH, 0.0, NAVE, FLOOR_COLOR)
	_slab(body, ELEVATOR, LENGTH, NAVE, NAVE + strip, FLOOR_COLOR)
	var side := ELEVATOR - HATCH_INSET * 2.0
	Clay.box(body, Vector3(side, 0.02, side), at(ELEVATOR * 0.5, NAVE * 0.5, 0.01), ELEVATOR_COLOR)
	var dash := 0.5
	var count := int(side / (dash * 2.0))
	for i in count:
		var along := HATCH_INSET + dash * (i * 2.0 + 0.5)
		for edge in [HATCH_INSET, ELEVATOR - HATCH_INSET]:
			Clay.box(body, Vector3(dash, 0.03, 0.15), at(along, edge, 0.015), STRIPE_COLOR)
			Clay.box(body, Vector3(0.15, 0.03, dash), at(edge, along, 0.015), STRIPE_COLOR)
	_hazard_line(body)


## LA LÍNEA DE PELIGRO entre el gimnasio y la franja de las consolas (el usuario, 15/11/2026): rayas amarillas y negras
## en el piso, sin pared ni vidrio. Del lado de la gente, se está a salvo de la meca.
static func _hazard_line(body: StaticBody3D) -> void:
	var stripe := 0.4
	var count := int((LENGTH - ELEVATOR) / stripe)
	for i in count:
		var color := STRIPE_COLOR if i % 2 == 0 else HAZARD_DARK
		Clay.box(body, Vector3(stripe, 0.03, 0.3), at(ELEVATOR + stripe * (i + 0.5), NAVE, 0.015), color)


static func _slab(body: StaticBody3D, x1: float, x2: float, z1: float, z2: float, color: Color) -> void:
	Clay.solid(body, Vector3(x2 - x1, 0.4, z2 - z1), at((x1 + x2) * 0.5, (z1 + z2) * 0.5, -0.2), color)


## LAS PAREDES, por el contorno de la L. La de la punta de la franja es de la esclusa (BaseAirlock), con su compuerta.
static func _walls(body: StaticBody3D) -> void:
	var outline: Array[Vector2] = [
		Vector2(LENGTH, NAVE), Vector2(LENGTH, 0), Vector2(0, 0), Vector2(0, NAVE), Vector2(ELEVATOR, NAVE),
		Vector2(ELEVATOR, NAVE + strip), Vector2(LENGTH, NAVE + strip),
	]
	for i in outline.size() - 1:
		var a := outline[i]
		var b := outline[i + 1]
		# las de la franja, del alto de la franja
		var high := strip_height if minf(a.y, b.y) >= NAVE - 0.01 and minf(a.x, b.x) >= ELEVATOR - 0.01 else height
		var mid := (a + b) * 0.5
		var length := a.distance_to(b) + WALL
		var size := Vector3(length, high, WALL) if is_equal_approx(a.y, b.y) else Vector3(WALL, high, length)
		Clay.solid(body, size, at(mid.x, mid.y, high * 0.5), WALL_COLOR)
	# el dintel: la pared de la nave sobre el borde abierto de la franja, y sobre la esclusa
	Clay.solid(body, Vector3(LENGTH - ELEVATOR + WALL, height - strip_height, WALL),
		at((ELEVATOR + LENGTH) * 0.5, NAVE, (height + strip_height) * 0.5), WALL_COLOR)


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
	var high := height - 1.5
	var low := strip_height - 0.4
	var middle := NAVE + strip * 0.5
	for spot: Vector3 in [Vector3(ELEVATOR * 0.5, NAVE * 0.5, high), Vector3(ELEVATOR + width * 0.5, NAVE * 0.5, high),
			Vector3(ELEVATOR + width * 0.3, middle, low), Vector3(ELEVATOR + width * 0.75, middle, low)]:
		var where := at(spot.x, spot.y, spot.z)
		Clay.sphere(body, 0.2, where, Color(1.0, 0.95, 0.8))
		var lamp := OmniLight3D.new()
		lamp.position = where
		lamp.omni_range = 16.0
		lamp.light_energy = 1.4
		body.add_child(lamp)


## LA BOLSA CON FÍSICA (BaseBagRig): la chapa hexagonal en el techo, la cadena y la bolsa en tramos, a la altura de
## los brazos de la meca.
static func _bag(parent: Node3D) -> void:
	var rig := BaseBagRig.new()
	rig.name = "Bolsa"
	rig.position = at(bag_at.x, bag_at.y, height)
	parent.add_child(rig)
	rig.build(BAG_RADIUS, BAG_HIGH - BAG_LOW, height - BaseBag.PLATE_THICK - BAG_HIGH, BAG_COLOR)


## LAS TRES CONSOLAS: los contratos en la pared bajo el elevador (mirando a la franja), la armería y los cosméticos en
## el fondo (mirando al gimnasio).
static func _consoles(body: StaticBody3D) -> void:
	var back := NAVE + strip - WALL * 0.5 - 0.5
	var contracts_width := minf(strip - 1.6, 4.0)
	_console(body, Vector2(ELEVATOR + WALL * 0.5 + 0.5, NAVE + strip * 0.5), Basis(Vector3.UP, -PI * 0.5),
		contracts_width, "Contratos", BaseTerminal.Screen.CONTRACTS)
	var from := ELEVATOR + WALL * 0.5 + 1.0 + BACK_GAP
	_console(body, Vector2(from + CONSOLE_WIDTH * 0.5, back), Basis(), CONSOLE_WIDTH, "Armería",
		BaseTerminal.Screen.ARMORY)
	from += CONSOLE_WIDTH + BACK_GAP
	_console(body, Vector2(from + CONSOLE_WIDTH * 0.5, back), Basis(), CONSOLE_WIDTH, "Cosméticos y pintura")


## Una consola: su mueble y su pantalla inclinada, en un cuerpo propio para que se contornee sola al mirarla, con su
## frente (−Z, donde se para la gente) girado con `facing`. Con `screen`, se usa con E (BaseTerminal); sin, es de adorno.
static func _console(body: StaticBody3D, where: Vector2, facing: Basis, width: float, label: String,
		screen := -1) -> void:
	var console := StaticBody3D.new()
	console.name = label
	console.transform = Transform3D(facing, at(where.x, where.y))
	body.add_child(console)
	Clay.solid(console, Vector3(width, 1.0, 1.0), Vector3(0, 0.5, 0), CONSOLE_COLOR)
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-35.0))
	Clay.solid(console, Vector3(width * 0.9, 0.9, 0.08), Vector3(0, 1.35, 0.15), SCREEN_COLOR, tilt)
	_sign(console, label, Vector3(0, 2.4, 0))
	if screen >= 0:
		var terminal := BaseTerminal.new()
		terminal.screen = screen as BaseTerminal.Screen
		terminal.position = Vector3(0, 1.2, 0)
		console.add_child(terminal)


## LOS PERSONAJES: el cuadro chiquito y los casilleros, en el fondo de la franja, junto a la esclusa.
static func _characters(body: StaticBody3D) -> void:
	var back := NAVE + strip - WALL * 0.5
	var frame_x := ELEVATOR + WALL * 0.5 + 1.0 + BACK_GAP * 3.0 + CONSOLE_WIDTH * 2.0 + FRAME_WIDTH * 0.5
	Clay.box(body, Vector3(FRAME_WIDTH - 0.1, 0.8, 0.05), at(frame_x, back - 0.03, 1.7), FRAME_COLOR)
	_sign(body, "El empleado del mes", at(frame_x, back - 0.3, 2.4))
	var first := frame_x + FRAME_WIDTH * 0.5 + BACK_GAP
	var count := int((LENGTH - 0.2 - first) / LOCKER_WIDTH)
	for i in count:
		Clay.solid(body, Vector3(LOCKER_WIDTH - 0.04, 2.0, 0.55), at(first + (i + 0.5) * LOCKER_WIDTH, back - 0.3, 1.0),
			LOCKER_COLOR)
	if count > 0:
		_sign(body, "Casilleros", at(first + count * LOCKER_WIDTH * 0.5, back - 0.3, 2.4))


static func _sign(parent: Node3D, text: String, where: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.15, 0.14, 0.13)
	label.outline_modulate = Color(0.95, 0.93, 0.9)
	label.outline_size = 12
	label.position = where
	parent.add_child(label)
