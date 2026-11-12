class_name DesignSandbox
extends Node3D

## EL SANDBOX DE DISEÑO: un piso neutro con FILAS DE PARCELAS —una fila por categoría, una parcela por arquetipo— y
## alguien que camina entre ellas. Sirve para probar una cosa por vez sin armar el juego. Es la idea del sandbox de
## character-parametric, traída del proyecto del taxi.
##
## Las filas crecen hacia +Z desde donde uno aparece, y sus parcelas hacia +X. Estando en la zona de una parcela, el
## panel de la derecha dice qué es y qué teclas valen.
##
## EL QUE CAMINA ES EL PERSONAJE DE CHARACTER-PARAMETRIC (11/11/2026, el usuario: el personaje reemplaza al caminante),
## como en el sandbox de allá: arranca como ENTE (`CharacterKind.ente`: sin cuerpo a la vista, movimiento directo, V
## vuela) y la B lo vuelve CUERPO (`CharacterKind.player`: el jugador del juego, que se cae, agarra, se sienta y empuja),
## del arquetipo `body_archetype`. Contesta quién es el jugador local (`local_player`, el grupo `character_spawner`).
## Sus teclas las lee él (ver PlayerController): WASD, espacio, Ctrl, E, shift, V, y las F de depuración.

const INTERACT_PAD := 2.0
const ELEMENT_GAP := 3.0
const CATEGORY_GAP := 4.0
const GROUND_SIZE := 900.0
const GROUND_COLOR := Color(0.82, 0.80, 0.76)
const SKY_TOP := Color(0.55, 0.68, 0.85)
const SKY_HORIZON := Color(0.82, 0.86, 0.9)
const CATEGORY_LABEL_COLOR := Color(0.25, 0.24, 0.22)
const PLAYER_START := Vector3(-4.0, 0.0, 3.0)
const PLAYER_SCENE := preload("res://game/character/player.tscn")
## El arquetipo del cuerpo (la B). El gordo atlético: el genérico no se muestra.
static var body_archetype := EntityArchetype.Archetype.fat_athletic

## EL JUGADOR DE ESTA MÁQUINA (ver arriba).
var local_player: BoneInstantiator = null
var _body := false
## LA SESIÓN DE RED (ver SandboxSession): con sesión, el personaje lo pone el spawner del juego y no se cambia con la B.
var _session: SandboxSession = null
var _rows: Array[Dictionary] = []
var _panel: SandboxPanel = null
var _current: SandboxParcel = null
## LOS PANELES DE LAS FILAS (ver `_mount_tuners`).
var _tuners: Array[TunerPanel] = []


## EL CATÁLOGO: una entrada por fila, en orden. Una fila nueva se agrega acá.
static func categories() -> Array[Dictionary]:
	return [
		{"name": "Meca", "archetypes": [MechTestArchetype.new()]},
		{"name": "Equilibrio", "archetypes": [BalanceTestArchetype.new()]},
		{"name": "Cubo flotante", "archetypes": [HoverCubeArchetype.new()]},
		{"name": "Personajes", "archetypes": PeopleArchetype.catalogue()},
		{"name": "Objetos", "archetypes": [ObjectLotArchetype.new()]},
		{"name": "Multijugador", "archetypes": [MultiplayerArchetype.new()]},
		{"name": "Partículas", "archetypes": ParticleArchetype.catalogue()},
	]


func _ready() -> void:
	# Lo elegido en Opciones, guardado en esta máquina: el sandbox es la escena con la que arranca la meca.
	GameOptions.load_and_apply()
	_build_world()
	_build_rows()
	_panel = SandboxPanel.new()
	add_child(_panel)
	_mount_tuners()
	add_to_group("character_spawner")
	# Mirando hacia las parcelas (+X).
	_spawn(false, PLAYER_START, -PI * 0.5, 0.0)
	_session = SandboxSession.new()
	_session.name = "SandboxSession"
	_session.sandbox = self
	add_child(_session)


## ── LOS PANELES DE LAS FILAS, como en el sandbox de character-parametric (DesignSandbox._mount_tuners de allá) ──────
## Cada uno es de UNA FILA (TunerPanel.category): su tecla F abre parado en esa fila y en ninguna otra, cierra con la
## misma tecla, abre a la izquierda (la derecha es del panel de la parcela, que lo anota con su tecla) y abrir uno cierra
## los demás. Una fila nueva con panel se monta acá.
func _mount_tuners() -> void:
	_mount(HoverPanel.new(), "Cubo flotante", "el cubo flotante: flotar, enderezarse, caerse y los propulsores", KEY_F1)
	_mount(BalancePanel.new(), "Equilibrio", "la meca de equilibrio: el resorte, la firmeza, el empuje y los pasos", KEY_F1)


func _mount(tuner: TunerPanel, category_name: String, label: String, key: Key) -> void:
	# UNA TECLA, UN PANEL por fila (como allá): dos con la misma tecla en la misma fila se pisan.
	for other: TunerPanel in _tuners:
		if other.menu_key == key and (other.category == category_name or other.category.is_empty()
				or category_name.is_empty()):
			push_error("[DesignSandbox] la tecla %s de «%s» ya la usa «%s» (fila «%s»)" % [OS.get_keycode_string(key),
				label, other.menu_label, other.category])
	tuner.sandbox = self
	tuner.category = category_name
	tuner.menu_label = label
	tuner.menu_key = key
	add_child(tuner)
	tuner.side = TunerPanel.SIDE_LEFT
	tuner.call("setup_panel")
	_tuners.append(tuner)


## LA FILA DONDE ESTÁ PARADO EL JUGADOR, por nombre: la que abre los paneles (ver TunerPanel.serves).
func current_category() -> String:
	if _current == null:
		return ""
	return _current.category


## ── ENTE O CUERPO (la B), como en el sandbox de character-parametric (DesignSandbox._spawn y _respawn_as) ────────────
## No se prenden cosas sueltas: se rearma el personaje entero con la otra clase, donde está y mirando a lo mismo.
func is_body() -> bool:
	return _body


func toggle_body() -> void:
	if is_instance_valid(_session) and _session.active():
		return
	if not is_instance_valid(local_player) or local_player.is_seated:
		return
	var feet := _feet()
	var look := Vector2(local_player.intent.look_yaw, local_player.intent.look_pitch)
	remove_child(local_player)
	local_player.queue_free()
	local_player = null
	_spawn(not _body, feet, look.x, look.y)


## CON SESIÓN (ver SandboxSession, la fila Multijugador): el personaje es el del spawner de la red, un cuerpo; el ente
## se va. Al salir, el ente vuelve al arranque.
func net_adopt(player: BoneInstantiator) -> void:
	local_player = player
	_body = true


func net_release() -> void:
	if is_instance_valid(local_player) and local_player.get_parent() == self:
		remove_child(local_player)
		local_player.queue_free()
	local_player = null


func respawn_ente() -> void:
	_spawn(false, PLAYER_START, -PI * 0.5, 0.0)


## DÓNDE PISA UNO: lo que espera `place_at` (un punto del piso, no el centro de la cápsula).
func _feet() -> Vector3:
	if not is_instance_valid(local_player) or not is_instance_valid(local_player.char_rigidbody):
		return PLAYER_START
	var sizes := local_player.skel_sizes_util
	return player_position() - Vector3.UP * (sizes.leg_height - sizes.distance_from_ground)


func _spawn(body: bool, feet: Vector3, yaw: float, pitch: float) -> void:
	_body = body
	var bi := PLAYER_SCENE.instantiate() as BoneInstantiator
	bi.name = "cuerpo" if body else "ente"
	bi.kind = CharacterKind.player() if body else CharacterKind.ente()
	bi.master_seed = EntityInstantiation.debug_seed(body_archetype if body else EntityArchetype.Archetype.generic, 0)
	add_child(bi)
	bi.place_at(feet, yaw)
	bi.intent.look_yaw = yaw
	bi.intent.look_pitch = pitch
	local_player = bi


## DÓNDE ESTÁ UNO: para saber en qué parcela se está.
func player_position() -> Vector3:
	if is_instance_valid(local_player) and is_instance_valid(local_player.char_rigidbody):
		return local_player.char_rigidbody.global_position
	return PLAYER_START


## EL JUGADOR LOCAL, para quien no tiene al sandbox a mano (la meca): el del grupo `character_spawner`.
static func player_of(tree: SceneTree) -> BoneInstantiator:
	var spawner := tree.get_first_node_in_group("character_spawner")
	if spawner == null:
		return null
	return spawner.get("local_player") as BoneInstantiator


## SI LAS TECLAS SON DE OTRO: sentado en una silla, o manejando una meca desde afuera (el grupo `driving`, ver Mech).
func _busy() -> bool:
	var seated := is_instance_valid(local_player) and local_player.is_seated
	return seated or get_tree().get_first_node_in_group("driving") != null


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
		# LAS OPCIONES DE LA FILA, una sola para todos sus arquetipos (como allá: ver SeededArchetype.options).
		var shared_options := {}
		for archetype: SeededArchetype in archetypes:
			depth = maxf(depth, archetype.max_footprint().y)
			for key: Variant in archetype.options:
				if not shared_options.has(key):
					shared_options[key] = archetype.options[key]
			archetype.options = shared_options
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
		var row_keys: Array[Dictionary] = (archetypes[0] as SeededArchetype).category_options() if not archetypes.is_empty() \
			else ([] as Array[Dictionary])
		_rows.append({"name": category_name, "parcels": parcels, "options": row_keys})
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
	var at := player_position()
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
	# Las teclas de la parcela y, debajo, los paneles de su fila (sólo para leer: los abre cada panel).
	var lines := _current.archetype.parcel_options()
	lines.append_array(_row_of(_current).get("options", []))
	for tuner in _tuners:
		if tuner.category == current_category():
			lines.append({"key": tuner.menu_key, "label": "panel: " + tuner.menu_label})
	_panel.show_parcel(_current, lines)


## La fila de `parcel` (vacía si no es de ninguna).
func _row_of(parcel: SandboxParcel) -> Dictionary:
	for row in _rows:
		if (row["parcels"] as Array).has(parcel):
			return row
	return {}


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if not UIState.gameplay_active():
		return
	if key.keycode == KEY_B and not _busy():
		toggle_body()
		get_viewport().set_input_as_handled()
		return
	if _current == null:
		return
	# SENTADO O MANEJANDO (ver `_busy`), las teclas son de lo que se maneja: de la parcela valen sólo las que se declaran
	# `"seated": true` (bajarse), y ni R ni C, que regenerarían o copiarían en medio de la pelea.
	if _busy():
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
			# LAS DE LA FILA (`category_options`): alcanzan a todas sus parcelas.
			if not used:
				var row := _row_of(_current)
				for option: Dictionary in row.get("options", []):
					if int(option["key"]) == key.keycode:
						(option["apply"] as Callable).call(row["parcels"])
						used = true
						break
	if not used:
		return
	# UNA TECLA DE LA PARCELA SE GASTA ACÁ: si siguiera de largo, lo que ella misma abrió la recibiría —el visor F1 se
	# abría y se cerraba con la misma pulsación—.
	get_viewport().set_input_as_handled()
	_refresh()
