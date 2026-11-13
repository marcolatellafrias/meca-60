class_name DesignSandbox
extends Node3D

## EL SANDBOX DE DISEÑO: un piso neutro con FILAS DE PARCELAS y alguien que camina entre ellas, para probar una cosa
## por vez sin armar el juego. Las reglas para agregar filas, teclas y paneles, en docs/technical/sandbox.md. Las piezas:
##   · SandboxCatalogue   las filas de cada módulo (SandboxRow), los paneles globales y el chequeo de las reglas.
##   · SandboxLayout      dónde va cada fila en el piso: supercategorías, subcategorías, archivados.
##   · SandboxParcel      una parcela: su zona, sus bordes, cuándo se arma y su cubo de lejos.
##   · SandboxKey         una tecla del panel chico; SandboxPanel, el panel chico.
##   · este archivo       el que camina (ente o cuerpo), en qué parcela está, sus teclas y qué panel F abre dónde.
##
## EL QUE CAMINA ES EL PERSONAJE (11/11/2026): arranca como ENTE (`CharacterKind.ente`: sin cuerpo a la vista,
## movimiento directo) y la B larga lo vuelve CUERPO (`CharacterKind.player`: el jugador del juego, que se cae, agarra,
## se sienta y empuja), del arquetipo `body_archetype`; la B corta prende el modo creativo (volar y atravesar, como la
## V). Contesta quién es el jugador local (`local_player`, el grupo `character_spawner`).

const PLAYER_START := Vector3(-4.0, 0.0, 3.0)
const PLAYER_SCENE := preload("res://game/character/player.tscn")
const SKY_TOP := Color(0.55, 0.68, 0.85)
const SKY_HORIZON := Color(0.82, 0.86, 0.9)
## LA B: apretada menos que esto es corta (el modo creativo); más, larga (ente o cuerpo), y cambia sin esperar a soltar.
const LONG_B_S := 0.45
## LO DE LEJOS (ver SandboxParcel.set_far): una parcela a más de `FAR_M` de uno pasa a su cubo y vuelve a menos de
## `NEAR_M`, que es también cuando se arma la primera vez (las NEAR). Se mira cada `FAR_CHECK_S`, no por cuadro.
const FAR_M := 90.0
const NEAR_M := 70.0
const FAR_CHECK_S := 0.25
## El arquetipo del cuerpo (la B larga). El gordo atlético: el genérico no se muestra.
static var body_archetype := EntityArchetype.Archetype.fat_athletic

## EL JUGADOR DE ESTA MÁQUINA (ver arriba).
var local_player: BoneInstantiator = null
var _body := false
## LA SESIÓN DE RED (ver SandboxSession): con sesión, el personaje lo pone el spawner del juego y no se cambia con la B.
var _session: SandboxSession = null
var _rows: Array[Dictionary] = []
var _parcels: Array[SandboxParcel] = []
var _panel: SandboxPanel = null
var _current: SandboxParcel = null
## LOS PANELES F montados: `{tuner, row (SandboxRow o null), archetype (o null)}`. Sin fila, global.
var _tuners: Array[Dictionary] = []
var _far_clock := 0.0
var _b_down_at := -1.0
var _b_long_done := false


func _ready() -> void:
	# Lo elegido en Opciones, guardado en esta máquina: el sandbox es la escena con la que arranca la meca.
	GameOptions.load_and_apply()
	_build_world()
	var declared := SandboxCatalogue.rows()
	var globals := SandboxCatalogue.global_panels()
	_panel = SandboxPanel.new()
	add_child(_panel)
	var problems := SandboxCatalogue.check(declared, globals)
	for problem in problems:
		push_error("[Sandbox] " + problem)
	_panel.show_errors(problems)
	_rows = SandboxLayout.build(self, declared)
	for row in _rows:
		for parcel: SandboxParcel in row["parcels"]:
			_parcels.append(parcel)
	_mount_panels(declared, globals)
	var possession := SandboxPossession.new()
	possession.name = "Poseer"
	add_child(possession)
	add_to_group("character_spawner")
	# Mirando hacia las parcelas (+X).
	_spawn(false, PLAYER_START, -PI * 0.5, 0.0)
	_session = SandboxSession.new()
	_session.name = "SandboxSession"
	_session.sandbox = self
	add_child(_session)
	_update_far()


## ── LOS PANELES F (ver SandboxRow.panel, SandboxRow.parcel_panel, SandboxCatalogue.global_panels) ────────────────
## Cada uno abre parado donde vale (`serves_panel`), cierra con la misma tecla desde cualquier lado y abre a la izquierda
## (la derecha es del panel chico, que lo anota). Abrir uno cierra los demás. Dos con la misma tecla que puedan abrir en el
## mismo lugar los avisa el chequeo y el segundo no se monta.
func _mount_panels(declared: Array[SandboxRow], globals: Array[Dictionary]) -> void:
	var taken := {}
	for row in declared:
		for entry in row.panels:
			var spot := "%d:%s" % [row.get_instance_id(), "fila" if entry["archetype"] == null else
				str((entry["archetype"] as SeededArchetype).get_instance_id())]
			_mount(entry, row, taken, spot)
	for entry in globals:
		_mount(entry, null, taken, "global")


func _mount(entry: Dictionary, row: SandboxRow, taken: Dictionary, spot: String) -> void:
	var f_key: Key = entry["key"]
	var allowed := SandboxKey.GLOBAL_PANEL_KEYS if row == null else SandboxKey.LOCAL_PANEL_KEYS
	var claim := "%s:%d" % [spot, f_key]
	var row_claim := "%d:fila:%d" % [row.get_instance_id(), f_key] if row != null else claim
	if not f_key in allowed or taken.has(claim) or (entry["archetype"] != null and taken.has(row_claim)):
		return
	taken[claim] = true
	var tuner: TunerPanel = entry["panel"]
	tuner.sandbox = self
	tuner.category = row.name if row != null else ""
	tuner.menu_label = entry["label"]
	tuner.menu_key = f_key
	add_child(tuner)
	tuner.side = TunerPanel.SIDE_LEFT
	tuner.call("setup_panel")
	_tuners.append({"tuner": tuner, "row": row, "archetype": entry["archetype"]})


## SI `tuner` ABRE ACÁ (lo pregunta TunerPanel.serves): global, en cualquier lado; de fila, en sus parcelas; de parcela,
## en la suya.
func serves_panel(tuner: TunerPanel) -> bool:
	for entry in _tuners:
		if entry["tuner"] != tuner:
			continue
		if entry["row"] == null:
			return true
		if _current == null or _current.row != entry["row"]:
			return false
		return entry["archetype"] == null or entry["archetype"] == _current.archetype
	return false


## LA PARCELA DONDE ESTÁ PARADO EL JUGADOR, o null (para los paneles que actúan sobre ella).
func current_parcel() -> SandboxParcel:
	return _current


## LA FILA DONDE ESTÁ PARADO EL JUGADOR, por nombre.
func current_category() -> String:
	return _current.category if _current != null else ""


## ── ENTE O CUERPO (la B larga) ───────────────────────────────────────────────────────────────────────────────────
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


## SI LAS TECLAS SON DE OTRO: sentado en una silla, o manejando una meca desde afuera (el grupo `driving`, ver
## SandboxPossession).
func _busy() -> bool:
	var seated := is_instance_valid(local_player) and local_player.is_seated
	return seated or get_tree().get_first_node_in_group("driving") != null


func _build_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sol"
	sun.rotation_degrees = Vector3(-55.0, 215.0, 0.0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	add_child(sun)

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.ground_bottom_color = SandboxLayout.GROUND_COLOR
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


## ── CADA CUADRO: en qué parcela está uno, lo de lejos y la B larga ───────────────────────────────────────────────
func _process(delta: float) -> void:
	_far_clock -= delta
	if _far_clock <= 0.0:
		_update_far()
	if _b_down_at >= 0.0 and not _b_long_done and _now() - _b_down_at >= LONG_B_S:
		_b_long_done = true
		toggle_body()
	var at := player_position()
	var inside: SandboxParcel = null
	for parcel in _parcels:
		if parcel.contains(at):
			inside = parcel
			break
	if inside == _current:
		return
	if _current != null:
		_current.archetype.entered(_current, false)
	_current = inside
	if _current != null:
		if _current.build_mode == SandboxRow.Build.NEAR:
			_current.build()
		_current.set_far(false)
		_current.archetype.entered(_current, true)
	_refresh()


## Cada parcela, según lo lejos que está uno de su zona: se arma (las NEAR, la primera vez), se apaga o vuelve. Una sin
## armar muestra su cubo apenas deja de estar cerca. Manejando, nada cambia: lo manejado puede estar lejos del que lo
## maneja.
func _update_far() -> void:
	_far_clock = FAR_CHECK_S
	if _busy():
		return
	var at := player_position()
	var spot := Vector2(at.x, at.z)
	for parcel in _parcels:
		var rect := parcel.interaction_rect()
		var gap := (spot.clamp(rect.position, rect.end) - spot).length()
		if gap < NEAR_M:
			if parcel.build_mode == SandboxRow.Build.NEAR:
				parcel.build()
			parcel.set_far(false)
		elif gap > FAR_M or not parcel.built:
			parcel.set_far(true)


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## ── EL PANEL CHICO ───────────────────────────────────────────────────────────────────────────────────────────────
## Lo que muestra: después de entrar, salir o apretar algo.
func _refresh() -> void:
	if _current == null:
		_panel.hide_panel()
		return
	var parcel_lines := _key_lines(_current.own_keys())
	var row_lines := _key_lines(_current.row_keys())
	var global_lines: Array[Dictionary] = []
	for entry in _tuners:
		var line := {"key": (entry["tuner"] as TunerPanel).menu_key, "text": "panel: " +
			(entry["tuner"] as TunerPanel).menu_label, "kind": SandboxPanel.Line.PANEL}
		if entry["row"] == null:
			global_lines.append(line)
		elif entry["row"] == _current.row and entry["archetype"] == _current.archetype:
			parcel_lines.append(line)
		elif entry["row"] == _current.row and entry["archetype"] == null:
			row_lines.append(line)
	var hints := PackedStringArray()
	for hint in SandboxKey.HINTS:
		var text: String = SandboxKey.RESERVED[hint]
		if hint == KEY_R and not _current.built:
			text = "armar la parcela"
		hints.append("%s  %s" % [SandboxKey.name_of(hint), text])
	_panel.show_parcel(_current, [
		{"title": "esta parcela", "lines": parcel_lines},
		{"title": "esta fila", "lines": row_lines},
		{"title": "siempre", "lines": global_lines},
	] as Array[Dictionary], hints)


## Las teclas, las principales primero. Sentado o manejando, sólo las que valen así.
func _key_lines(keys: Array[SandboxKey]) -> Array[Dictionary]:
	var main: Array[Dictionary] = []
	var rest: Array[Dictionary] = []
	var busy := _busy()
	for made in keys:
		if busy and not made.seated:
			continue
		var is_main := made.weight == SandboxKey.Weight.MAIN
		(main if is_main else rest).append({"key": made.key, "text": made.text(),
			"kind": SandboxPanel.Line.MAIN if is_main else SandboxPanel.Line.NORMAL})
	main.append_array(rest)
	return main


## ── LAS TECLAS ───────────────────────────────────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or key.echo:
		return
	var keycode := SandboxKey.plain(key.keycode)
	# LA B, desde cualquier parte: corta, el modo creativo; larga, ente o cuerpo (ver `_process`).
	if keycode == KEY_B:
		_press_b(key.pressed)
		get_viewport().set_input_as_handled()
		return
	if not key.pressed or not UIState.gameplay_active() or _current == null:
		return
	var busy := _busy()
	if not busy and keycode == KEY_R:
		if _current.built:
			_current.regenerate(randi() & 0x7fffffff)
		else:
			_current.build()
	elif not busy and keycode == KEY_C:
		_panel.copy(_current)
	elif not _press_key(_current.own_keys(), keycode, busy) and not _press_key(_current.row_keys(), keycode, busy):
		return
	# UNA TECLA DE LA PARCELA SE GASTA ACÁ: si siguiera de largo, lo que ella misma abrió la recibiría.
	get_viewport().set_input_as_handled()
	_refresh()


func _press_key(keys: Array[SandboxKey], keycode: Key, busy: bool) -> bool:
	for made in keys:
		if made.matches(keycode) and (made.seated or not busy):
			# Una parcela que se arma con la R no tiene nada sobre qué actuar hasta armarse.
			if _current.built:
				made.press(_current)
			return true
	return false


func _press_b(down: bool) -> void:
	if down:
		if UIState.gameplay_active() and not _busy():
			_b_down_at = _now()
			_b_long_done = false
		return
	if _b_down_at >= 0.0 and not _b_long_done and is_instance_valid(local_player) \
			and is_instance_valid(local_player.player_controller):
		local_player.player_controller.toggle_creative()
	_b_down_at = -1.0
