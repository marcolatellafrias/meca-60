class_name BaseLayout
extends RefCounted

## LA BASE (la sucursal bajo tierra), EN ARCILLA, A ESCALA HUMANA (el plano de la esclusa, 17/11/2026, ver
## docs/conceptual/base.md): la misma estructura que tenía para la meca grande, achicada para la meca jaula (≈ 7 m).
## Un solo piso, todo al mismo nivel:
##   · EL ELEVADOR, un cuadrado marcado del piso donde duerme la meca; arriba, la compuerta del techo (BaseHatch).
##   · EL GIMNASIO con la bolsa, a la altura de los brazos de la meca.
##   · LA FRANJA DE LAS CONSOLAS, abajo del gimnasio, separada por la línea de peligro. Usa sus dos caras libres: EL FONDO,
##     con los contratos, la armería y los cosméticos, cada uno en el medio de su tercio; y LA PARED CORTA, enfrente de la
##     puerta de la esclusa, con LOS DOS TUBOS DE PAQUETES (22/11/2026, BaseSupplyTube: munición y reparación).
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
const MAX_STRIP := 24.0
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
const SIZE := Vector2(MAX_DEPTH + MAX_WIDTH + MAX_STRIP, MAX_DEPTH + MAX_STRIP + 8.0)
## LO QUE RODEA EL PISO, pensado para esta cámara (22/11/2026): el fondo y el alto de los edificios de atrás, lo que cae
## el borde hacia el vacío, el alto de la pared que no se ve y las columnas de metal (bajas del lado de la cámara).
const BLOCK := 8.0
const BLOCK_HIGH := 6.0
const DROP := 6.0
const FENCE_HIGH := 8.0
const NEAR_BEAM := 3.0
const SIDE_BEAM := 9.0
const BEAM_EVERY := 6.0
const OFFSET := Vector3(-SIZE.x * 0.5, 0.0, -SIZE.y * 0.5)
## El grupo de los nodos que tienen una base armada adentro (para rearmarla al guardar el F1).
const GROUP := "base_plano"
## LO DEL FONDO DE LA FRANJA: los contratos, la armería y los cosméticos, cada uno en el medio de su tercio, de hasta CONSOLE_WIDTH. *Hasta
## el 17/11/2026 estaban también el cuadro del empleado del mes y los casilleros; el usuario los sacó de la primera
## versión: «no vamos a poner casillero ni memorial… una complejidad extra que le voy a agregar más tarde».*
const CONSOLE_WIDTH := 5.0
const BACK_GAP := 0.4

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
## El pozo del ascensor: del techo de la base al piso de la arena.
static var shaft := 14.0
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
const CAGE_COLOR := Color(0.5, 0.5, 0.48)
const ROOF_COLOR := Color(0.5, 0.48, 0.45)
const DROP_COLOR := Color(0.3, 0.29, 0.28)
const BEAM_COLOR := Color(0.36, 0.39, 0.43)


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
	shaft = settings.shaft_height
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


## EL PISO DE LA ARENA, sobre el pozo: hasta acá sube el ascensor, y ahí está la segunda compuerta.
static func shaft_top() -> float:
	return height + ROOF + shaft


## El lado de la boca del pozo (y de las compuertas): el cuadrado del elevador sin su borde.
static func span() -> float:
	return ELEVATOR - HATCH_INSET * 2.0


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
	_tubes(parent)
	_gantry(body)
	_lights(body)
	_shaft(body)
	var hatch := BaseHatch.new()
	hatch.name = "Compuerta"
	parent.add_child(hatch)
	hatch.build()
	# sin techo no tienen qué cerrar y taparían la meca: siguen andando, sin verse, hasta decidir qué pasa con ellas
	hatch.visible = false
	var top := BaseHatch.new()
	top.name = "Compuerta de arriba"
	parent.add_child(top)
	top.build(true)
	top.visible = false
	var elevator := BaseElevator.new()
	elevator.name = "Ascensor"
	parent.add_child(elevator)
	elevator.build()
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


## LOS EDIFICIOS (el usuario, 22/11/2026: «las paredes que van contrarias a mi ángulo de visión puedo mantenerlas… con una
## altura más razonable… como edificios, le hacemos los techos»): sólo del lado de atrás de la cámara, macizos y con techo.
## Uno a lo largo del fondo de la franja y otro en el rincón de la L, donde va la consola de contratos.
static func _walls(body: StaticBody3D) -> void:
	_building(body, 0.0, LENGTH + strip, NAVE + strip, NAVE + strip + BLOCK)
	_building(body, 0.0, ELEVATOR, NAVE, NAVE + strip)
	_edge(body, Vector2(0, 0), Vector2(LENGTH, 0), Vector2(0, -1), NEAR_BEAM)
	_edge(body, Vector2(0, 0), Vector2(0, NAVE), Vector2(-1, 0), SIDE_BEAM)
	# baja: queda delante de la esclusa
	_edge(body, Vector2(LENGTH, 0), Vector2(LENGTH, NAVE), Vector2(1, 0), NEAR_BEAM)
	for piece: Rect2 in [Rect2(0, 0, LENGTH, NAVE), Rect2(ELEVATOR, NAVE, LENGTH + strip - ELEVATOR, strip)]:
		Clay.box(body, Vector3(piece.size.x, DROP, piece.size.y),
			at(piece.get_center().x, piece.get_center().y, -0.4 - DROP * 0.5), DROP_COLOR)


static func _building(body: StaticBody3D, x1: float, x2: float, z1: float, z2: float) -> void:
	var middle := Vector2((x1 + x2) * 0.5, (z1 + z2) * 0.5)
	var size := Vector2(x2 - x1, z2 - z1)
	Clay.solid(body, Vector3(size.x, BLOCK_HIGH, size.y), at(middle.x, middle.y, BLOCK_HIGH * 0.5), WALL_COLOR)
	Clay.box(body, Vector3(size.x + 0.3, 0.25, size.y + 0.3), at(middle.x, middle.y, BLOCK_HIGH + 0.125), ROOF_COLOR)


## UN BORDE HACIA EL VACÍO (el usuario: «que los límites no sean paredes, sino… desniveles hacia un vacío… unos beams
## metálicos»): un cordón pintado, una pared que no se ve para que nadie caiga, y del lado de afuera una estructura de
## columnas con un travesaño. La del lado de la cámara es baja, para no tapar.
static func _edge(body: StaticBody3D, a: Vector2, b: Vector2, out: Vector2, tall: float) -> void:
	var along := (b - a).normalized()
	var length := a.distance_to(b)
	var middle := (a + b) * 0.5
	var line := func(size_along: float, size_across: float) -> Vector2:
		return Vector2(size_along, size_across) if absf(along.x) > 0.5 else Vector2(size_across, size_along)
	var curb: Vector2 = line.call(length, 0.3)
	Clay.box(body, Vector3(curb.x, 0.2, curb.y), at(middle.x - out.x * 0.15, middle.y - out.y * 0.15, 0.1), STRIPE_COLOR)
	Clay.shape_box(body, Vector3(curb.x, FENCE_HIGH, curb.y),
		at(middle.x + out.x * 0.15, middle.y + out.y * 0.15, FENCE_HIGH * 0.5))
	var count := maxi(int(length / BEAM_EVERY), 1)
	for i in count + 1:
		var spot := a + along * (length * i / count) + out * 0.5
		Clay.box(body, Vector3(0.35, tall + DROP, 0.35), at(spot.x, spot.y, (tall - DROP) * 0.5), BEAM_COLOR)
	var rail: Vector2 = line.call(length + 0.35, 0.25)
	var beam_at := middle + out * 0.5
	for y: float in [tall, tall * 0.5]:
		Clay.box(body, Vector3(rail.x, 0.25, rail.y), at(beam_at.x, beam_at.y, y), BEAM_COLOR)


## LOS RIELES DEL ASCENSOR: dos columnas contra el edificio, del lado de atrás, por donde sube la plataforma. Reemplazan
## las cuatro paredes del pozo, que la tapaban.
static func _shaft(body: StaticBody3D) -> void:
	var top := shaft_top()
	for x: float in [HATCH_INSET, ELEVATOR - HATCH_INSET]:
		Clay.box(body, Vector3(0.5, top, 0.4), at(x, NAVE - 0.2, top * 0.5), BEAM_COLOR)


## EL PÓRTICO DE LA BOLSA: como no hay techo, cuelga de una viga entre dos columnas.
static func _gantry(body: StaticBody3D) -> void:
	for z: float in [0.6, NAVE - 0.6]:
		Clay.box(body, Vector3(0.45, height, 0.45), at(bag_at.x, z, height * 0.5), BEAM_COLOR)
	Clay.box(body, Vector3(0.5, 0.5, NAVE - 0.7), at(bag_at.x, NAVE * 0.5, height + 0.25), BEAM_COLOR)


## LAS LUCES: lámparas sin sombras, repartidas sobre el piso.
static func _lights(body: StaticBody3D) -> void:
	var high := BLOCK_HIGH + 3.0
	for spot: Vector2 in [Vector2(ELEVATOR * 0.5, NAVE * 0.5), Vector2(ELEVATOR + width * 0.3, NAVE * 0.5),
			Vector2(ELEVATOR + width * 0.75, NAVE * 0.5), Vector2(ELEVATOR + width * 0.5, NAVE + strip * 0.5)]:
		var lamp := OmniLight3D.new()
		lamp.position = at(spot.x, spot.y, high)
		lamp.omni_range = 26.0
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


## LAS TRES CONSOLAS, EN EL FONDO (mirando al gimnasio), cada una en el medio de su tercio, tan anchas como dé (hasta 5 m).
static func _consoles(body: StaticBody3D) -> void:
	var back := NAVE + strip - WALL * 0.5 - 0.5
	var from := ELEVATOR + WALL * 0.5 + 1.0
	var span := LENGTH - WALL * 0.5 - from
	var console_width := minf(span / 3.0 - BACK_GAP * 2.0, CONSOLE_WIDTH)
	_console(body, Vector2(from + span / 6.0, back), Basis(), console_width, "Contratos", BaseTerminal.Screen.CONTRACTS)
	_console(body, Vector2(from + span * 0.5, back), Basis(), console_width, "Armería", BaseTerminal.Screen.ARMORY)
	_console(body, Vector2(from + span * 5.0 / 6.0, back), Basis(), console_width, "Cosméticos y pintura")


## LOS DOS TUBOS DE PAQUETES, en la pared corta, mirando a la puerta de la esclusa.
static func _tubes(parent: Node3D) -> void:
	var spots := [strip * 0.3, strip * 0.7]
	var titles := ["MUNICIÓN", "REPARACIÓN"]
	var repair: Array[int] = [SupplyKinds.Kind.REPAIR]
	var drops: Array = [SupplyKinds.AMMO, repair]
	for index in 2:
		var tube := BaseSupplyTube.new()
		tube.name = "Tubo de %s" % str(titles[index]).to_lower()
		tube.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), at(ELEVATOR, NAVE + float(spots[index])))
		parent.add_child(tube)
		var can_drop: Array[int] = []
		can_drop.assign(drops[index])
		tube.build(index, titles[index], can_drop)


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
