class_name ControlArchetype
extends ComponentArchetype

## UN TIPO DE CONTROL —botón, palanca, volante, perilla— como arquetipo: QUÉ es (su componente, su tamaño
## en celdas y cómo se maneja: ver `definition`) y CÓMO SE VE, en dos mallas separadas de su lógica
## (ControllableInteractable): la BASE, que no se mueve y cuelga del cuerpo del control, y la PARTE
## MÓVIL, lo que el jugador agarra, que cuelga del componente y por eso rota o se hunde con él.
##
## Las dos se diseñan en el cubo unitario del control —`x` a lo largo del tablero, `y` subiendo por él,
## `z` hacia quien lo mira, con z = 0 en la superficie del tablero— y se escalan a la caja del control:
## sus celdas menos el margen, por CONTROL_DEPTH de profundidad (ver ProceduralDashboard). Así el mismo
## estilo sirve para un botón de 2 × 2 y para el de la compuerta, de 4 × 4. Lo que tiene que ser redondo
## de verdad (la bola de una palanca) se calcula con el tamaño en metros.
##
## Todo tablero viste sus controles con esto (`dress`), y toda definición de control sale de acá
## (`definition_of`): la nave solo agrega lo suyo —cuánto recorre, dónde descansa—. Un estilo nuevo es
## una entrada más del catálogo, y aparece solo en la fila "Componentes" del sandbox. La semilla no varía
## nada todavía.
##
## Es un COMPONENTE (ver ComponentArchetype) que se arma con su propio tablero de un control.

const BASE_COLOR := Color(0.32, 0.33, 0.36)
## El pivote de las mallas: el centro del control sobre la superficie del tablero, que es donde está el
## origen de su cuerpo y de su componente.
const ON_PANEL := Vector3(0.5, 0.5, 0.0)

## Por qué nombre lo pide una definición (`ControlDefinition.archetype_name`).
var key := "button"
var type: ControlDefinition.ControlType = ControlDefinition.ControlType.TOUCH
var grid_size := Vector2i(2, 2)
var moving_color := Color(0.85, 0.35, 0.25)

static var _by_key: Dictionary = {}


func _init(p_key := "button", p_name := "Botón", p_type: ControlDefinition.ControlType = ControlDefinition.ControlType.TOUCH,
		p_grid := Vector2i(2, 2), p_color := Color(0.85, 0.35, 0.25)) -> void:
	key = p_key
	display_name = p_name
	type = p_type
	grid_size = p_grid
	moving_color = p_color


## Los estilos que hay: la fila "Controles" del sandbox.
static func catalogue() -> Array[ControlArchetype]:
	return [
		ControlArchetype.new("button", "Botón", ControlDefinition.ControlType.TOUCH, ProceduralDashboard.BUTTON,
			Color(0.85, 0.35, 0.25)),
		ControlArchetype.new("power", "Botón de encendido", ControlDefinition.ControlType.TOUCH,
			ProceduralDashboard.POWER_BUTTON, Color(0.3, 0.8, 0.4)),
		ControlArchetype.new("lever", "Palanca", ControlDefinition.ControlType.ONE_AXIS, ProceduralDashboard.LEVER,
			Color(0.9, 0.6, 0.2)),
		ControlArchetype.new("wheel", "Volante", ControlDefinition.ControlType.ROTATING, ProceduralDashboard.WHEEL,
			Color(0.36, 0.24, 0.2)),
		ControlArchetype.new("stick", "Palanca de dos ejes", ControlDefinition.ControlType.TWO_AXIS, Vector2i(6, 6),
			Color(0.85, 0.85, 0.3)),
	]


## El estilo `key`; el botón si no existe. La perilla no es un estilo suelto (ver `KNOB`): pedirla así es un error, y el
## tablero no la arma sin sus posiciones.
static func of(key: String) -> ControlArchetype:
	if key == KNOB:
		push_error("[Controles] La perilla no es un estilo suelto: se arma con RotaryArchetype.knob(rótulos), que le da " +
			"sus posiciones y sus marcas (ver docs/technical/panel-pieces.md).")
		return _knob_look()
	if key == DOOR:
		return _door_look()
	if key == DRIVE_LEVER or key == DRIVE_STICK:
		return _drive_look(key)
	if _by_key.is_empty():
		for archetype in catalogue():
			_by_key[archetype.key] = archetype
	return _by_key.get(key, _by_key["button"])


## ── LA PERILLA ES SÓLO DISCRETA (ver KnobComponent) ──────────────────────────────────────────────
## Por eso NO ESTÁ EN EL CATÁLOGO ni se pide con `of`: suelta, una perilla sería un control que gira libre. Lo que vive
## acá es cómo se ve —sus mallas, que el tablero le pone como a cualquier control— y su definición, que sólo sale con sus
## posiciones (`knob_definition`). Quien la monta la pide a la rueda, RotaryArchetype.knob(rótulos): un ángulo y una
## marca por rótulo. Un tablero que recibe una perilla sin posiciones válidas no la arma (ver ProceduralDashboard).
const KNOB := "knob"
static var _knob: ControlArchetype = null


## EL BOTÓN DE LAS COMPUERTAS DE LA NAVE (lo pidió el usuario): el de encendido, de 3 × 3 celdas y con la cabeza
## más grande en su caja, así se ve casi del tamaño del de 4 × 4. Fuera del catálogo, como la perilla: sólo lo pide
## ShipBuilder._door.
const DOOR := "door"
static var _door: ControlArchetype = null


static func _door_look() -> ControlArchetype:
	if _door == null:
		_door = ControlArchetype.new(DOOR, "Botón de compuerta", ControlDefinition.ControlType.TOUCH, Vector2i(3, 3),
			Color(0.3, 0.8, 0.4))
	return _door


## LAS DE MANEJAR DE LA MECA JAULA (17/11/2026, el usuario: «una que es de aceleración… con un palo negro y punta roja,
## como los que estaban en el placeholder low poly… y la otra… XZ, que se trabe y que decida para dónde ir»): el palo
## negro con la bola roja de las palancas de mentira que tuvo la jaula, sobre una base oscura (`_dress_drive`).
##   · DRIVE_LEVER, EL ACELERADOR, de un eje: la palanca de siempre (va de punta a punta de sus celdas). Arranca ABAJO en
##     su tablero (`default_value` 1: hacia quien la usa), y arriba es el mínimo: quien la lee da vuelta el valor.
##   · DRIVE_STICK, LA DE DIRECCIÓN, de dos ejes: NO VUELVE SOLA, queda donde se la deja.
## Fuera del catálogo, como la compuerta: sólo las pide CageBoards.
const DRIVE_LEVER := "drive_lever"
const DRIVE_STICK := "drive_stick"
const DRIVE_PAINT := Color(0.1, 0.1, 0.11)
const DRIVE_TIP := Color(0.78, 0.18, 0.15)
const DRIVE_BASE := Color(0.2, 0.21, 0.23)
static var _drive: Dictionary = {}


static func _drive_look(drive_key: String) -> ControlArchetype:
	if not _drive.has(drive_key):
		if drive_key == DRIVE_LEVER:
			_drive[drive_key] = ControlArchetype.new(DRIVE_LEVER, "Acelerador", ControlDefinition.ControlType.ONE_AXIS,
				Vector2i(3, 8), DRIVE_TIP)
		else:
			_drive[drive_key] = ControlArchetype.new(DRIVE_STICK, "Palanca de dirección",
				ControlDefinition.ControlType.TWO_AXIS, Vector2i(6, 6), DRIVE_TIP)
	return _drive[drive_key]


## Cómo se ve la perilla: su estilo, fuera del catálogo.
static func _knob_look() -> ControlArchetype:
	if _knob == null:
		_knob = ControlArchetype.new(KNOB, "Perilla", ControlDefinition.ControlType.ROTATING, Vector2i(6, 6),
			Color(0.75, 0.75, 0.72))
	return _knob


## LA DEFINICIÓN DE UNA PERILLA de `grid` celdas, con sus posiciones —un ángulo cada una, de KnobComponent.MIN_POSITIONS
## a MAX_POSITIONS— y la de reposo, `rest` (un índice). La pide RotaryArchetype; sin posiciones válidas, el tablero no la
## arma.
static func knob_definition(angles: Array[float], grid: Vector2i, rest := 0) -> ControlDefinition:
	var d := _knob_look().definition()
	d.grid_size = grid
	d.positions = angles.duplicate()
	if angles.is_empty():
		return d
	d.default_value = angles[clampi(rest, 0, angles.size() - 1)]
	for angle in angles:
		d.rotate_max = maxf(d.rotate_max, absf(angle))
	return d


static func definition_of(key: String) -> ControlDefinition:
	return of(key).definition()


## El estilo que pide una definición: por nombre, o si no lo dice —una armada a mano—, el de su tipo. Lo que se ve como
## perilla ES una perilla: el tablero le exige sus posiciones (ver `KNOB`).
static func for_definition(definition: ControlDefinition) -> ControlArchetype:
	if definition.archetype_name == KNOB:
		return _knob_look()
	if definition.archetype_name != "":
		return of(definition.archetype_name)
	match definition.type:
		ControlDefinition.ControlType.ONE_AXIS:
			return of("lever")
		ControlDefinition.ControlType.TWO_AXIS:
			return of("stick")
		ControlDefinition.ControlType.ROTATING:
			return of("wheel") if definition.grid_size.x >= ProceduralDashboard.WHEEL.x else _knob_look()
	return of("button")


## La definición de un control de este estilo: su tipo, su tamaño y cómo se maneja. Quien lo coloca
## agrega lo suyo encima.
func definition() -> ControlDefinition:
	var d := ControlDefinition.new()
	d.archetype_name = key
	d.type = type
	d.grid_size = grid_size
	match key:
		"power", DOOR:
			d.is_toggle = true
		"lever":
			d.rotation_axis_local = Vector3.RIGHT
		"wheel":
			# Como el del Cybertruck: a fondo hace tope, sin dar una vuelta; suelto vuelve al centro. Sale del tablero
			# sobre un eje. SE GIRA MIRANDO (ver RotatingComponent.look_gain): la cámara se mueve entera mientras se
			# lo agarra, y lo que se mira de costado de su centro es lo que gira.
			d.rotation_axis_local = Vector3.BACK
			d.rotate_input = RotatingComponent.InputMode.LOOK
			d.camera_sensitivity_factor = 1.0
			d.rotate_sensitivity = 0.0015
			d.rotate_max = 1.2
			d.height_offset = 0.16
			d.auto_return = true
			# El aro es grande: a ritmo de mano se pasaría de vueltas. Unos 400 píxeles de lado a lado.
			d.drag_gain = 0.4
			# Y se estira hacia quien lo agarra, sobre un fuelle (ver RotatingComponent).
			d.stretch_max = 0.25
		KNOB:
			# Gira con la ruedita alrededor de la normal del tablero, como un dial, apenas despegada de él. Sus posiciones
			# las pone `knob_definition`.
			d.rotation_axis_local = Vector3.BACK
			d.height_offset = 0.02
			d.rotate_input = RotatingComponent.InputMode.SCROLL
		"stick":
			d.auto_return = true
			# La punta se mueve poco: sin esto, se volcaba con un movimiento de muñeca.
			d.drag_gain = 0.3
		DRIVE_LEVER:
			d.rotation_axis_local = Vector3.RIGHT
			d.default_value = 1.0
		DRIVE_STICK:
			d.drag_gain = 0.3
	return d


# ── Las mallas ───────────────────────────────────────────────────────────────────────────────────

## La base: lo que no se mueve, apoyado en el tablero.
func base_unit(size: Vector3) -> UnitMesh:
	var m := UnitMesh.new()
	match key:
		"button", "power", DOOR:
			# LOS BOTONES son el botón sin leyenda con sus parámetros de siempre (ver ButtonArchetype.for_control).
			return ButtonArchetype.for_control(key, moving_color).base_unit(size)
		"wheel":
			m.add_cylinder_z(Vector3(0.3, 0.3, 0.0), Vector3(0.7, 0.7, 0.25), BASE_COLOR, 16)
		"knob":
			m.add_cylinder_z(Vector3(0.05, 0.05, 0.0), Vector3(0.95, 0.95, 0.3), BASE_COLOR, 16)
		"stick":
			m.add_box(Vector3(0.1, 0.1, 0.0), Vector3(0.9, 0.9, 0.3), BASE_COLOR)
			m.add_cylinder_z(Vector3(0.3, 0.3, 0.3), Vector3(0.7, 0.7, 0.6), BASE_COLOR.darkened(0.3), 16)
		_:
			m.add_box(Vector3(0.0, 0.0, 0.0), Vector3(1.0, 1.0, 0.25), BASE_COLOR)
	return m


## La parte móvil: lo que el componente rota o hunde, desde el tablero hacia afuera.
func moving_unit(size: Vector3) -> UnitMesh:
	var m := UnitMesh.new()
	match key:
		"button", "power", DOOR:
			return ButtonArchetype.for_control(key, moving_color).moving_unit(size)
		"wheel":
			m.add_ring_z(Vector3(0.02, 0.02, 0.0), Vector3(0.98, 0.98, 0.45), 0.14, moving_color, 24)
			m.add_cylinder_z(Vector3(0.36, 0.36, 0.05), Vector3(0.64, 0.64, 0.5), BASE_COLOR, 16)
			m.add_box(Vector3(0.47, 0.1, 0.1), Vector3(0.53, 0.9, 0.35), moving_color.lightened(0.4))
			m.add_box(Vector3(0.1, 0.47, 0.1), Vector3(0.9, 0.53, 0.35), moving_color.lightened(0.4))
		"knob":
			m.add_cylinder_z(Vector3(0.22, 0.22, 0.0), Vector3(0.78, 0.78, 0.7), moving_color, 16)
			m.add_box(Vector3(0.47, 0.5, 0.55), Vector3(0.53, 0.76, 0.8), BASE_COLOR)
		"stick":
			# La punta está donde el componente pone la mano (ver TwoAxisComponent), y la bola es redonda.
			var tip := (0.5 * size.z + 0.55 * minf(size.x, size.y)) / size.z
			var r := Vector3(0.02, 0.02, 0.02) / size
			m.add_box(Vector3(0.47, 0.47, 0.4), Vector3(0.53, 0.53, tip), BASE_COLOR.lightened(0.3))
			m.add_cylinder_z(Vector3(0.5, 0.5, tip) - r, Vector3(0.5, 0.5, tip) + r, moving_color, 16)
		_:
			m.add_cylinder_z(Vector3(0.15, 0.15, 0.2), Vector3(0.85, 0.85, 0.65), moving_color, 16)
	return m


## Viste un control ya colocado: la base bajo su cuerpo, la parte móvil bajo el componente —donde éste la
## quiera: un volante sale del tablero— y, si sale, el eje que la sostiene.
func dress(body: StaticBody3D, interactable: ControllableInteractable, size: Vector3) -> void:
	# LA PALANCA es la unificada (ver LeverArchetype.dress_control): la de dos brazos de antes se borró.
	if key == "lever" and interactable is OneAxisComponent:
		LeverArchetype.dress_control(body, interactable as OneAxisComponent, size)
		return
	if key == DRIVE_LEVER or key == DRIVE_STICK:
		_dress_drive(body, interactable, size)
		return
	body.add_child(_instance(base_unit(size), size))
	var offset := interactable.mesh_offset()
	var moving := _instance(moving_unit(size), size)
	moving.position = offset
	interactable.add_child(moving)
	interactable.highlighted.append(moving)
	if offset.z > 0.0:
		var rotating := interactable as RotatingComponent
		if rotating != null and rotating.stretch_max > 0.0:
			# EL FUELLE, en vez del eje: une el tablero con el volante y se estira con él.
			var sleeve := BellowsSleeve.new()
			sleeve.name = "Bellows"
			body.add_child(sleeve)
			var rubber := StandardMaterial3D.new()
			rubber.albedo_color = Color(0.08, 0.08, 0.08)
			rubber.roughness = 0.7
			var r := minf(size.x, size.y) * 0.1
			sleeve.build(8, r, r * 0.75, offset.z, rubber)
			rotating.bellows = sleeve
		else:
			var shaft := UnitMesh.new()
			shaft.add_cylinder_z(Vector3(0.44, 0.44, 0.0), Vector3(0.56, 0.56, 1.0), BASE_COLOR)
			body.add_child(_instance(shaft, Vector3(size.x, size.y, offset.z)))


## LAS DE MANEJAR (ver DRIVE_LEVER): en el cuerpo, la base oscura —una ranura a lo largo para el acelerador, un cuadrado
## para la de dirección—; en el componente, el palo negro y la bola roja hasta donde pone la mano (la de un eje, en la
## punta de su brazo; la de dos, ver TwoAxisComponent._setup_handle_points). Las medidas, las de la de mentira: la bola,
## un séptimo del palo.
func _dress_drive(body: StaticBody3D, interactable: ControllableInteractable, size: Vector3) -> void:
	var lever := interactable as OneAxisComponent
	var reach := lever.arm_length if lever != null else size.z * 0.5 + minf(size.x, size.y) * 0.55
	var base := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(size.x * 0.55, size.y * 0.55, 0.02)
	if lever != null:
		plate.size = Vector3(size.x * 0.6, size.y * 0.9, 0.012)
	base.mesh = plate
	base.material_override = MeshKit.material(DRIVE_BASE, 0.8)
	base.position = Vector3(0.0, 0.0, plate.size.z * 0.5)
	body.add_child(base)
	var at := interactable.mesh_offset()
	var stick := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = reach * 0.05
	rod.bottom_radius = reach * 0.06
	rod.height = reach
	stick.mesh = rod
	stick.material_override = MeshKit.material(DRIVE_PAINT, 0.5)
	stick.rotation.x = PI * 0.5
	stick.position = at + Vector3(0.0, 0.0, reach * 0.5)
	interactable.add_child(stick)
	var ball := MeshInstance3D.new()
	var round_mesh := SphereMesh.new()
	round_mesh.radius = reach * 0.15
	round_mesh.height = reach * 0.3
	ball.mesh = round_mesh
	ball.material_override = MeshKit.material(DRIVE_TIP, 0.45)
	ball.position = at + Vector3(0.0, 0.0, reach)
	interactable.add_child(ball)
	interactable.highlighted.append_array([stick, ball])


static func _instance(unit: UnitMesh, size: Vector3) -> MeshInstance3D:
	return PanelArchetype.instance(unit, size)


# ── La muestra del sandbox ───────────────────────────────────────────────────────────────────────

func cells(_seed_value: int) -> Vector2i:
	return grid_size


## MONTADO EN UN TABLERO cualquiera (ver PanelArchetype.mount): un tablero de un control del tamaño justo de sus
## celdas, con su esquina en la del rectángulo. Así un control de siempre entra en un tablero de componentes igual
## que una manivela.
func _build_on(_seed_value: int, root: Node3D, area: Vector2) -> void:
	var dash := ProceduralDashboard.new()
	dash.name = "Dashboard"
	dash.grid_columns = grid_size.x
	dash.grid_rows = grid_size.y
	dash.custom_preset = DashboardPreset.single(definition(), Vector2i.ZERO)
	dash.transform = Transform3D(Basis(), Vector3(-area.x * 0.5, area.y * 0.5, 0.0))
	root.add_child(dash)


## Un atril (ver PanelArchetype.stand), y un tablero de un solo control en el medio.
func build(_seed_value: int, parent: Node3D) -> Node3D:
	var plate_cells := grid_size + Vector2i(2, 2)
	var root := PanelArchetype.stand(parent, plate_cells)
	var dash := ProceduralDashboard.new()
	dash.name = "Dashboard"
	dash.grid_columns = plate_cells.x
	dash.grid_rows = plate_cells.y
	dash.custom_preset = DashboardPreset.single(definition(), Vector2i(1, 1))
	dash.transform = PanelArchetype.stand_grid(plate_cells)
	root.add_child(dash)
	return root


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray(["%s · %d × %d celdas" % [ControlDefinition.ControlType.keys()[type], grid_size.x, grid_size.y]])


## SU USO (ver PanelArchetype.use): el volante y la palanca de dos ejes se manejan todo el tiempo; el volante, con las
## dos manos.
func use() -> Use:
	return Use.CONSTANT if key == "wheel" or key == "stick" else Use.OCCASIONAL


func two_handed() -> bool:
	return key == "wheel"
