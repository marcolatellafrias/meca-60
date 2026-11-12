class_name SandboxPossession
extends Node

## POSEER, EN EL SANDBOX: manejar con las teclas algo que en el juego se maneja desde adentro (una meca, un cubo), para
## probarlo de a uno. Lo pidió el usuario el 12/11/2026 («un sistema un poco más flexible… cuando vea… una entidad como
## una meca… lo puedo poseer… un mini menú… que me dice en qué toggle estoy… y los controles de lo que estoy poseyendo»).
## Separa dos cosas que antes iban pegadas en cada cosa: A QUIÉN LE LLEGAN LAS TECLAS y DESDE DÓNDE SE MIRA.
##   · **O**: mirando algo que se puede poseer, lo posee (las teclas pasan a él; el jugador se apaga donde está). **O**
##     otra vez, lo suelta: vuelve el jugador. Y SE ACUERDA de lo último: **O** sin mirar nada lo vuelve a poseer. Así
##     «soltar» sirve para moverse a mirar de otro lado y seguir: no hace falta otra tecla.
##   · **T**, poseyendo: pasa por las tres vistas. LIBRE (la cámara del jugador, donde quedó), TERCERA PERSONA y PRIMERA
##     PERSONA (las dos las dice lo poseído).
##   · EL CARTEL (abajo a la derecha): qué se posee, en qué vista, y SUS CONTROLES, que los dice lo poseído.
##
## QUÉ SE PUEDE POSEER: lo que está en el grupo `possessable` y contesta (por nombre, sin clase base):
##   possess_name() -> String                          cómo se llama
##   possess_controls() -> PackedStringArray           sus controles, una línea por renglón
##   possess_begin() / possess_end()                   empieza / deja de leer las teclas
##   possess_camera(first: bool, delta) -> Transform3D dónde va la cámara, en primera o en tercera persona
## Lo poseído va al grupo `driving` (ver DesignSandbox._busy: las teclas del sandbox son de lo que se maneja).

enum View { FREE, THIRD, FIRST }

const GROUP := "possessable"
const VIEW_NAMES := ["libre (desde donde estabas)", "tercera persona", "primera persona"]
const REACH := 600.0

## Lo poseído (o null) y la vista.
var target: Node3D = null
var view := View.THIRD

var _last: Node3D = null
var _aimed: Node3D = null
var _camera: Camera3D = null
var _card: Label = null
var _hint: Label = null


static func of(tree: SceneTree) -> SandboxPossession:
	return tree.get_first_node_in_group("sandbox_possession") as SandboxPossession


func _ready() -> void:
	add_to_group("sandbox_possession")
	_camera = Camera3D.new()
	_camera.name = "Cámara de poseer"
	_camera.far = 2000.0
	add_child(_camera)
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_card = _label(layer, 16)
	# El cartel, con fondo: se lee sobre cualquier cosa.
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.11, 0.13, 0.72)
	back.set_corner_radius_all(6)
	back.set_content_margin_all(12.0)
	_card.add_theme_stylebox_override("normal", back)
	_hint = _label(layer, 16)


func _label(layer: CanvasLayer, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_constant_override("line_spacing", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	layer.add_child(label)
	return label


## ── POSEER Y SOLTAR ──────────────────────────────────────────────────────────────────────────────────────────────

## Posee `thing` (soltando lo que hubiera), o lo suelta si ya era lo poseído.
func toggle(thing: Node3D) -> void:
	if target == thing:
		release()
	else:
		possess(thing)


func possess(thing: Node3D) -> void:
	if not _can(thing):
		return
	release()
	var player := DesignSandbox.player_of(get_tree())
	if is_instance_valid(player):
		if player.is_seated and player.current_seat is SeatInteractable:
			(player.current_seat as SeatInteractable).release_occupant_in_place()
		player.set_active(false)
	target = thing
	_last = thing
	target.add_to_group("driving")
	target.call("possess_begin")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_view()


func release() -> void:
	if target == null:
		return
	if is_instance_valid(target):
		target.remove_from_group("driving")
		target.call("possess_end")
	target = null
	var player := DesignSandbox.player_of(get_tree())
	if is_instance_valid(player):
		player.set_active(true)
		if is_instance_valid(player.player_camera):
			player.player_camera.make_current()


func _can(thing: Node3D) -> bool:
	return is_instance_valid(thing) and thing.is_inside_tree() and thing.is_in_group(GROUP)


## La vista: libre es la cámara del jugador, donde quedó; las otras, la de poseer.
func _apply_view() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if view == View.FREE and is_instance_valid(player) and is_instance_valid(player.player_camera):
		player.player_camera.make_current()
	else:
		_camera.make_current()


## ── LAS TECLAS ───────────────────────────────────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not UIState.gameplay_active():
		return
	if key.physical_keycode == KEY_O:
		if target != null:
			release()
		elif _can(_aimed):
			possess(_aimed)
		elif _can(_last):
			possess(_last)
		else:
			return
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_T and target != null:
		view = ((view + 1) % View.size()) as View
		_apply_view()
		get_viewport().set_input_as_handled()


## ── CADA CUADRO ──────────────────────────────────────────────────────────────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	_aimed = _look() if target == null else null


func _process(delta: float) -> void:
	# Lo poseído se fue (R volvió a armar su parcela): se suelta.
	if target != null and not _can(target):
		release()
	if target != null and view != View.FREE:
		_camera.global_transform = target.call("possess_camera", view == View.FIRST, delta)
	_show()


## Lo que se puede poseer en el medio de la pantalla, o null. Las paredes de las parcelas no tapan.
func _look() -> Node3D:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * REACH)
	query.collision_mask = 0xFFFFFFFF & ~PhysicsLayers.PARCEL_BOUND
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	var node := hit.get("collider") as Node
	while node != null:
		if node.is_in_group(GROUP):
			return node as Node3D
		node = node.get_parent()
	return null


## EL CARTEL (poseyendo) y LA PISTA (sin poseer: qué poseería la O).
func _show() -> void:
	var screen := get_viewport().get_visible_rect().size
	_card.visible = target != null
	_hint.visible = false
	if target != null:
		var lines := PackedStringArray()
		lines.append("POSEYENDO: %s" % str(target.call("possess_name")))
		lines.append("vista: %s" % VIEW_NAMES[view])
		lines.append("O soltar (y O otra vez lo retoma) · T cambia la vista")
		lines.append("")
		lines.append_array(target.call("possess_controls") as PackedStringArray)
		_card.text = "\n".join(lines)
		_card.size = Vector2.ZERO
		var need := _card.get_combined_minimum_size()
		_card.position = Vector2(screen.x - need.x - 20.0, screen.y - need.y - 20.0)
		return
	if _can(_aimed):
		_hint.text = "O poseer: %s" % str(_aimed.call("possess_name"))
	elif _can(_last):
		_hint.text = "O volver a poseer: %s" % str(_last.call("possess_name"))
	else:
		return
	_hint.visible = UIState.gameplay_active()
	_hint.size = Vector2.ZERO
	var size := _hint.get_combined_minimum_size()
	_hint.position = Vector2((screen.x - size.x) * 0.5, screen.y * 0.5 + 28.0)
