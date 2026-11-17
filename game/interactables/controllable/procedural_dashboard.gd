@tool
class_name ProceduralDashboard
extends Node3D

enum PresetType { NONE, STEERING_WHEEL }

## ── LA CELDA ────────────────────────────────────────────────────────────────────────────────────
## Unidad mínima de ubicación: 4 cm, sin separación entre celdas. Es chica A PROPÓSITO: un control
## ocupa muchas (un botón 2 × 2, una palanca 6 × 8), y a cambio los controles pueden ser tan chicos
## como uno real y ubicarse con precisión. Más fina no sirve: 4 cm es lo más chico que se apunta bien
## con la mira a un brazo de distancia.
##
## La nave se mide en esta misma celda (ver ShipGrid). Cambiarla cambia el tamaño de todo lo que está
## contado en celdas —dashboards, controles y casco—: es una decisión de diseño, no una perilla.
const CELL := 0.04
## Profundidad de la caja de cada control.
const CONTROL_DEPTH := 0.06
## Aire que deja cada control de su lado, dentro de su área, para que dos vecinos no se toquen.
const CONTROL_MARGIN := 0.01

## Tamaños estándar de control, en celdas.
const BUTTON := Vector2i(2, 2)

## ── ALGUNOS BOTONES TITILAN ──────────────────────────────────────────────────────────────────────
## Una lente redonda en la cara de UNO DE CADA `BLINK_EVERY` botones, prendiéndose y apagándose. Un tablero
## de controles quietos se lee como un mueble; con dos o tres luces que van a su ritmo se lee como algo
## ENCENDIDO, y es lo único que hace falta para eso.
##
## ⚠ TITILA EN EL SHADER, NO EN CÓDIGO. La alternativa —un nodo con `_process` por lente, o uno por tablero
## con su lista de materiales— cuesta CPU por cuadro, y de tableros hay uno por consola y de naves varias en
## escena a la vez (la nave vieja tenía un toggle que los apagaba). Con `TIME` adentro del
## shader el costo por cuadro es CERO: la GPU ya sabe qué hora es.
##
## Cada lente tiene SU ritmo y SU fase, sacados del índice del control, así que ni titilan todas juntas ni
## cambian de una nave a la otra.
const BLINK_EVERY := 5
const BLINK_LENS := 0.30          # el radio de la lente, en veces el lado del control
const BLINK_PROUD := 0.004        # cuánto asoma de la cara
const BLINK_SHADER := """shader_type spatial;
uniform vec4 lit : source_color;
uniform vec4 dark : source_color;
uniform float rate;
uniform float phase;
void fragment() {
	float on = step(0.5, fract(TIME * rate + phase));
	ALBEDO = mix(dark.rgb, lit.rgb, on);
	EMISSION = lit.rgb * on;
}"""
const BLINK_LIT := Color(1.0, 0.86, 0.45)
const BLINK_DARK := Color(0.24, 0.20, 0.14)
## EL SHADER SE COMPILA UNA SOLA VEZ para todas las lentes de todas las naves: lo que cambia de una a otra
## son los uniformes, que viven en el material. Uno por lente compilaba el mismo código decenas de veces.
static var _blink_shader: Shader = null
## El de encendido, al doble: es el único que se busca a las apuradas y el que más se usa.
const POWER_BUTTON := Vector2i(4, 4)
## La palanca va de punta a punta de sus celdas (ver OneAxisComponent): el alto es su recorrido.
const LEVER  := Vector2i(6, 8)
const WHEEL  := Vector2i(12, 12)

## Por defecto, 1.28 × 0.96 m.
@export var grid_columns: int        = 32
@export var grid_rows:    int        = 24
@export var seed_value:   int        = 0
## La caja de área de cada control y sus puntos de agarre.
@export var show_debug:   bool       = false
@export var preset_type:  PresetType = PresetType.NONE
## Preset armado desde código. Si está, manda sobre `preset_type`. Existe para quien construye
## dashboards en tiempo de ejecución —la nave arma los suyos según su layout— sin tener que agregar
## cada disposición como un caso nuevo del enum.
@export var custom_preset: DashboardPreset = null

# Relleno al azar: [estilo (ver ControlArchetype), tamaño en celdas, peso]. Sin perillas: una perilla nace con sus
# posiciones y sus marcas (ver KnobComponent), y al azar saldría girando libre.
const _DEFS: Array = [
	["button", BUTTON, 3.0],
	["lever", Vector2i(6, 6), 2.0],
	["lever", Vector2i(12, 6), 1.5],
	["lever", LEVER, 1.5],
	["stick", Vector2i(6, 6), 2.0],
	["stick", Vector2i(12, 12), 1.0],
	["wheel", WHEEL, 1.2],
]

var _grid: Array                 = []
var _rng:  RandomNumberGenerator = null
## Índice incremental por control colocado (orden determinístico) → nombre estable "ctrl_N" para que
## el path del control coincida en todas las máquinas y el sync por RPC rutee. Ver ControllableInteractable.
var _ctrl_index: int             = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		generate()
		return
	generate()
	# Cliente que se une: pedir al host el estado actual de los controles. El dashboard se regenera
	# determinístico (en default); los que alguien movió hay que traerlos (permanencia). Ver multiplayer.md.
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		_request_control_states.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_control_states() -> void:
	if not multiplayer.is_server():
		return
	var states: Array = []
	for i in _ctrl_index:
		var ctrl := get_node_or_null("ctrl_%d/Control" % i) as ControllableInteractable
		states.append(ctrl.get_sync_state() if is_instance_valid(ctrl) else null)
	_receive_control_states.rpc_id(multiplayer.get_remote_sender_id(), states)

@rpc("authority", "reliable", "call_remote")
func _receive_control_states(states: Array) -> void:
	for i in mini(_ctrl_index, states.size()):
		var ctrl := get_node_or_null("ctrl_%d/Control" % i) as ControllableInteractable
		if is_instance_valid(ctrl) and states[i] != null:
			ctrl.apply_sync_state(states[i])

func generate() -> void:
	for child in get_children():
		child.queue_free()

	_rng        = RandomNumberGenerator.new()
	_rng.seed   = seed_value
	_ctrl_index = 0
	_grid       = []
	for _c in grid_columns:
		var col: Array[bool] = []
		for _r in grid_rows:
			col.append(false)
		_grid.append(col)

	var preset := _build_preset()

	# ── 1. Place fixed slots from preset ──────────────────────────────────────
	if is_instance_valid(preset):
		for slot in preset.fixed_slots:
			var c := slot.cell
			if c.x < 0 or c.x >= grid_columns or c.y < 0 or c.y >= grid_rows:
				continue
			if not is_instance_valid(slot.definition):
				_grid[c.x][c.y] = true
				continue
			var def := slot.definition
			if not _fits(c, def.grid_size):
				# Can't place — mark only the origin cell as empty so the
				# random pass doesn't try to fill it with something unexpected.
				_grid[c.x][c.y] = true
				continue
			_place_definition(c, def)
			_occupy(c, def.grid_size)

		if not preset.fill_remaining_random:
			return

	# ── 2. Fill remaining cells with seeded random ────────────────────────────
	var safety := grid_columns * grid_rows * 4
	while _has_empty() and safety > 0:
		safety -= 1
		var cell := _first_empty()
		if cell.x == -1:
			break
		_place_at(cell)

# ── Preset builder ────────────────────────────────────────────────────────────

func _build_preset() -> DashboardPreset:
	if is_instance_valid(custom_preset):
		return custom_preset
	match preset_type:
		PresetType.STEERING_WHEEL:
			return _preset_steering_wheel()
	return null

# Layout en áreas de 8 × 8 celdas, cada control centrado en la suya:
#   fila 0: [btn][btn][btn][btn]
#   fila 1: [btn][volante  ][palanca]
#   fila 2: [btn][volante  ][palanca]
func _preset_steering_wheel() -> DashboardPreset:
	var p                  := DashboardPreset.new()
	p.fill_remaining_random = false

	# ── Volante, en las áreas (1..2, 1..2) ─────────────────────────────────────
	var wheel_slot      := DashboardSlot.new()
	wheel_slot.cell      = Vector2i(10, 10)
	wheel_slot.definition = ControlArchetype.definition_of("wheel")

	# ── Palanca, en las áreas (3, 1..2) ────────────────────────────────────────
	var lever_def              := ControlArchetype.definition_of("lever")
	lever_def.max_angle_degrees = 180.0

	var lever_slot      := DashboardSlot.new()
	lever_slot.cell      = Vector2i(25, 10)
	lever_slot.definition = lever_def

	# ── Un botón en cada área libre ───────────────────────────────────────────
	var button_cells: Array[Vector2i] = [
		Vector2i(3, 3), Vector2i(11, 3), Vector2i(19, 3), Vector2i(27, 3),
		Vector2i(3, 11), Vector2i(3, 19),
	]

	var slots: Array[DashboardSlot] = [wheel_slot, lever_slot]
	for cell in button_cells:
		var btn_slot      := DashboardSlot.new()
		btn_slot.cell      = cell
		btn_slot.definition = ControlArchetype.definition_of("button")
		slots.append(btn_slot)

	p.fixed_slots = slots
	return p

# ── Grid helpers ──────────────────────────────────────────────────────────────

func _has_empty() -> bool:
	for c in grid_columns:
		for r in grid_rows:
			if not _grid[c][r]:
				return true
	return false

func _first_empty() -> Vector2i:
	for r in grid_rows:
		for c in grid_columns:
			if not _grid[c][r]:
				return Vector2i(c, r)
	return Vector2i(-1, -1)

func _fits(cell: Vector2i, size: Vector2i) -> bool:
	if cell.x + size.x > grid_columns or cell.y + size.y > grid_rows:
		return false
	for dc in size.x:
		for dr in size.y:
			if _grid[cell.x + dc][cell.y + dr]:
				return false
	return true

func _occupy(cell: Vector2i, size: Vector2i) -> void:
	for dc in size.x:
		for dr in size.y:
			_grid[cell.x + dc][cell.y + dr] = true

# ── Placement ─────────────────────────────────────────────────────────────────

## LA PERILLA ES SÓLO DISCRETA (ver KnobComponent): lo que se ve como perilla y no trae posiciones válidas no se arma —es
## un error de quien la pidió—, y su lugar queda vacío.
func _place_definition(cell: Vector2i, def: ControlDefinition) -> void:
	var look := ControlArchetype.for_definition(def)
	var knob := look.key == ControlArchetype.KNOB
	if knob and not KnobComponent.valid(def.positions):
		push_error("[Tablero] Una perilla con %d posiciones no se arma: tiene de %d a %d, cada una con su marca. Se pide con RotaryArchetype.knob(rótulos)."
			% [def.positions.size(), KnobComponent.MIN_POSITIONS, KnobComponent.MAX_POSITIONS])
		return
	_spawn(cell, def.grid_size, _make_control_from_def(def, knob), look)

func _place_at(cell: Vector2i) -> void:
	var valid: Array = []
	var total: float = 0.0
	for def in _DEFS:
		if _fits(cell, def[1]):
			valid.append(def)
			total += float(def[2])

	if valid.is_empty():
		_grid[cell.x][cell.y] = true
		return

	var pick   := _rng.randf() * total
	var chosen: Array = valid[0]
	for def in valid:
		pick -= float(def[2])
		if pick <= 0.0:
			chosen = def
			break

	var definition := ControlArchetype.definition_of(chosen[0])
	definition.grid_size = chosen[1]
	_occupy(cell, definition.grid_size)
	_place_definition(cell, definition)

## Coloca un control que ocupa `size` celdas desde `cell`, su esquina superior izquierda. La grilla
## crece hacia +X y −Y, con la cara hacia +Z: el cuerpo queda con su origen en la superficie del
## tablero, y el arquetipo lo viste de ahí hacia afuera.
func _spawn(cell: Vector2i, size: Vector2i, interactable: ControllableInteractable, archetype: ControlArchetype) -> void:
	var area    := Vector2(size) * CELL
	var ctrl_sz := Vector3(area.x - 2.0 * CONTROL_MARGIN, area.y - 2.0 * CONTROL_MARGIN, CONTROL_DEPTH)
	interactable.grid_size = size
	interactable.name      = "Control"

	var body := StaticBody3D.new()
	body.name = "ctrl_%d" % _ctrl_index  # path estable en todas las máquinas (sync de controllables)
	_ctrl_index += 1
	var shape  := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = ctrl_sz
	shape.shape = bshape
	body.add_child(shape)
	body.add_child(interactable)
	add_child(body)
	body.position = Vector3(cell.x * CELL + area.x * 0.5, -(cell.y * CELL + area.y * 0.5), 0.0)

	interactable.build(ctrl_sz, show_debug)
	archetype.dress(body, interactable, ctrl_sz)
	if interactable is TouchComponent and body.name.hash() % BLINK_EVERY == 0:
		_add_blink_lens(interactable, ctrl_sz, _ctrl_index)
	if show_debug:
		_add_area_mesh(body, ctrl_sz)

# ── Factory ───────────────────────────────────────────────────────────────────

## El control de `def`; con `knob`, una perilla (ver `_place_definition`, que ya miró sus posiciones).
func _make_control_from_def(def: ControlDefinition, knob := false) -> ControllableInteractable:
	var ctrl: ControllableInteractable
	match def.type:
		ControlDefinition.ControlType.TOUCH:
			var c     := TouchComponent.new()
			c.is_toggle = def.is_toggle
			ctrl        = c
		ControlDefinition.ControlType.ONE_AXIS:
			var c                := OneAxisComponent.new()
			c.sensitivity         = def.sensitivity
			c.max_angle_degrees   = def.max_angle_degrees
			c.rotation_axis_local = def.rotation_axis_local
			ctrl                  = c
		ControlDefinition.ControlType.TWO_AXIS:
			var c              := TwoAxisComponent.new()
			c.sensitivity       = def.sensitivity
			c.max_angle_degrees = def.max_angle_degrees
			ctrl                = c
		ControlDefinition.ControlType.ROTATING:
			var c: RotatingComponent = KnobComponent.new(def.positions) if knob else RotatingComponent.new()
			c.sensitivity         = def.rotate_sensitivity
			c.rotation_axis_local = def.rotation_axis_local
			c.height_offset       = def.height_offset
			c.input_mode          = def.rotate_input
			c.max_rotation        = def.rotate_max
			c.stretch_max         = def.stretch_max
			ctrl                  = c
		_:
			ctrl = TouchComponent.new()

	ctrl.auto_return       = def.auto_return
	ctrl.default_value     = def.default_value
	ctrl.positions         = def.positions.duplicate()
	ctrl.rest_rotation_deg = def.rest_rotation_deg
	ctrl.camera_sensitivity_factor = def.camera_sensitivity_factor
	ctrl.drag_gain = def.drag_gain
	ctrl.inertia = def.inertia
	return ctrl

## LA LENTE QUE TITILA de un botón, colgada de la parte que se mueve: apretar el botón mueve la luz con él,
## que es lo que hace cualquier botón iluminado.
static func _add_blink_lens(interactable: ControllableInteractable, size: Vector3, index: int) -> void:
	var radius := minf(size.x, size.y) * BLINK_LENS
	if radius <= 0.001:
		return
	var lens := CylinderMesh.new()
	lens.top_radius = radius
	lens.bottom_radius = radius
	lens.height = BLINK_PROUD * 2.0
	lens.radial_segments = 10
	lens.rings = 0
	if _blink_shader == null:
		_blink_shader = Shader.new()
		_blink_shader.code = BLINK_SHADER
	var material := ShaderMaterial.new()
	material.shader = _blink_shader
	material.set_shader_parameter("lit", BLINK_LIT)
	material.set_shader_parameter("dark", BLINK_DARK)
	# El ritmo y la fase salen del índice: dos lentes seguidas nunca van juntas, y la misma nave sale
	# siempre igual.
	material.set_shader_parameter("rate", 0.55 + 0.12 * float(index % 7))
	material.set_shader_parameter("phase", float(index % 11) / 11.0)
	var mi := MeshInstance3D.new()
	mi.name = "blink"
	mi.mesh = lens
	mi.material_override = material
	mi.set_meta("no_outline", true)
	# El cilindro nace con el eje en Y y la cara del control mira a +Z.
	mi.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.0, size.z * 0.5))
	interactable.add_child(mi)


# ── Debug helpers ─────────────────────────────────────────────────────────────

func _add_area_mesh(body: StaticBody3D, size: Vector3) -> void:
	var mi  := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh  = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color            = Color(0.3, 0.55, 1.0, 0.1)
	mat.transparency            = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode               = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode            = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override        = mat
	mi.set_meta("no_outline", true)
	body.add_child(mi)
