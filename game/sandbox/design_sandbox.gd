class_name DesignSandbox
extends Node3D

## EL SANDBOX DE DISEÑO: un piso neutro con FILAS DE PARCELAS —una fila por categoría, una parcela por arquetipo— y
## alguien que camina entre ellas. Sirve para probar una cosa por vez sin armar el juego. Es la idea del sandbox de
## character-parametric, traída del proyecto del taxi.
##
## Las filas crecen hacia +Z desde donde uno aparece, y sus parcelas hacia +X. Estando en la zona de una parcela, el
## panel de la derecha dice qué es y qué teclas valen.

const INTERACT_PAD := 2.0
const ELEMENT_GAP := 3.0
const CATEGORY_GAP := 4.0
const GROUND_SIZE := 900.0
const GROUND_COLOR := Color(0.82, 0.80, 0.76)
const SKY_TOP := Color(0.55, 0.68, 0.85)
const SKY_HORIZON := Color(0.82, 0.86, 0.9)
const CATEGORY_LABEL_COLOR := Color(0.25, 0.24, 0.22)
const PLAYER_START := Vector3(-4.0, 0.0, 3.0)

var _rows: Array[Dictionary] = []
var _panel: SandboxPanel = null
var _walker: SandboxWalker = null
var _current: SandboxParcel = null


## EL CATÁLOGO: una entrada por fila, en orden. Una fila nueva se agrega acá.
static func categories() -> Array[Dictionary]:
	return [
		{"name": "Meca", "archetypes": [MechTestArchetype.new(), BalanceTestArchetype.new()]},
	]


func _ready() -> void:
	_build_world()
	_build_rows()
	_panel = SandboxPanel.new()
	add_child(_panel)
	_walker = SandboxWalker.new()
	_walker.position = PLAYER_START
	# Mirando hacia las parcelas (+X).
	_walker.rotation.y = -PI * 0.5
	add_child(_walker)


func _build_world() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Piso"
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(GROUND_SIZE, GROUND_SIZE)
	floor_mesh.mesh = plane
	floor_mesh.material_override = SandboxParcel._flat(GROUND_COLOR)
	floor_mesh.position.y = -0.01
	ground.add_child(floor_mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(GROUND_SIZE, 1.0, GROUND_SIZE)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	add_child(ground)

	var sun := DirectionalLight3D.new()
	sun.name = "Sol"
	sun.rotation_degrees = Vector3(-55.0, 215.0, 0.0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	add_child(sun)

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.ground_bottom_color = GROUND_COLOR
	sky_material.ground_horizon_color = SKY_HORIZON
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)


func _build_rows() -> void:
	var z := 0.0
	for category in categories():
		var category_name: String = category["name"]
		var archetypes: Array = category["archetypes"]
		var depth := 0.0
		for archetype: SeededArchetype in archetypes:
			depth = maxf(depth, archetype.max_footprint().y)
		var centre_z := z + INTERACT_PAD + depth * 0.5
		var parcels: Array[SandboxParcel] = []
		var x := 0.0
		for i in archetypes.size():
			var archetype := archetypes[i] as SeededArchetype
			if i > 0:
				x += ELEMENT_GAP
			var width := archetype.max_footprint().x
			var parcel := SandboxParcel.new()
			parcel.position = Vector3(x + INTERACT_PAD + width * 0.5, 0.0, centre_z)
			add_child(parcel)
			parcel.setup(archetype, category_name, Vector2(width, depth), INTERACT_PAD,
				hash(category_name + archetype.display_name) & 0x7fffffff)
			parcels.append(parcel)
			x += width + INTERACT_PAD * 2.0
		_label_row(category_name, centre_z)
		_rows.append({"name": category_name, "parcels": parcels})
		z += depth + INTERACT_PAD * 2.0 + CATEGORY_GAP


func _label_row(category_name: String, centre_z: float) -> void:
	var label := Label3D.new()
	label.text = category_name
	label.font_size = 160
	label.pixel_size = 0.005
	label.modulate = CATEGORY_LABEL_COLOR
	label.outline_size = 0
	label.rotation_degrees = Vector3(-90.0, -90.0, 0.0)
	label.position = Vector3(-1.0, 0.01, centre_z)
	add_child(label)


func _process(_delta: float) -> void:
	var at := _walker.global_position
	var inside: SandboxParcel = null
	for row in _rows:
		for parcel: SandboxParcel in row["parcels"]:
			if parcel.contains(at):
				inside = parcel
				break
		if inside != null:
			break
	if inside == _current:
		return
	if _current != null:
		_current.archetype.entered(_current, false)
	_current = inside
	if _current != null:
		_current.archetype.entered(_current, true)
	_refresh()


## Lo que muestra el panel: después de entrar, salir o regenerar.
func _refresh() -> void:
	if _current == null:
		_panel.hide_panel()
		return
	_panel.show_parcel(_current, _current.archetype.parcel_options())


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _current == null or key == null or not key.pressed or key.echo or _walker.typing:
		return
	# SENTADO (en un puesto de la meca, ver SandboxWalker.seated), las teclas son de la meca: de la parcela valen sólo las que se
	# declaran `"seated": true` (bajarse), y ni R ni C, que regenerarían o copiarían en medio de la pelea.
	if _walker.seated:
		for option in _current.archetype.parcel_options():
			if bool(option.get("seated", false)) and int(option["key"]) == key.keycode:
				(option["apply"] as Callable).call(_current)
				get_viewport().set_input_as_handled()
				_refresh()
				return
		return
	var used := true
	match key.keycode:
		KEY_R:
			_current.regenerate(randi() & 0x7fffffff)
		KEY_C:
			_panel.copy(_current)
		_:
			used = false
			for option in _current.archetype.parcel_options():
				if int(option["key"]) == key.keycode:
					(option["apply"] as Callable).call(_current)
					used = true
					break
	if not used:
		return
	# UNA TECLA DE LA PARCELA SE GASTA ACÁ: si siguiera de largo, lo que ella misma abrió la recibiría —el visor F1 se
	# abría y se cerraba con la misma pulsación—.
	get_viewport().set_input_as_handled()
	_refresh()
