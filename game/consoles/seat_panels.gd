class_name SeatPanels
extends Node3D

## LOS PANELES DE UNA SILLA (14/11/2026, módulo Tableros y controles; ver docs/conceptual/armamento.md, «Los paneles de
## la silla»). El primer caso jugable, lo más chico posible: UN panel, el del brazo derecho, y la tira que tienen todos.
##
## - EL PANEL, plegado al costado de la silla sobre su brazo articulado. Sentado, mirándolo, la E lo abre: viene adelante
##   de los ojos y TOMA EL MOUSE. El mouse mueve una mira por la vista del frente; el clic izquierdo tira una piña hacia
##   ella. La E otra vez lo cierra. (Escape abre la pausa: por eso la E, el usuario: «se abren con E y se salen con E».)
##   Con el panel abierto se mira al frente: la cabeza no se mueve.
## - LA TIRA, fija adelante y abajo: la meca dibujada en contorno, de frente y de costado, inclinada como está. La
##   energía todavía no existe: su barra queda vacía.
##
## Todo cuelga de la cabina, en una ZONA FIJA delante de la silla (no de la silla: si el que va sentado se da vuelta, nada
## lo persigue). Sin choques: es sólo lo que se ve.
##
## A QUIÉN LE HACE CASO: a quien mira desde esa silla, sea el jugador sentado o un maniquí poseído (ver poseer.md): la
## cámara tiene que estar a los ojos de la silla, con alguien sentado. No pregunta quién es.

const PANEL_SIZE := Vector2(0.56, 0.34)
## Cuánto tarda el panel en venir o en volver a su lugar.
const SWING_TIME := 0.25
## Hasta qué ángulo de la vista se considera que se lo está mirando (grados).
const LOOK_CONE := 14.0
## Qué tan lejos de los ojos de la silla puede estar la cámara para que cuente como sentado ahí.
const EYE_SLACK := 0.9
## Por dónde anda la mira: una fracción del ancho y del alto de la pantalla, alrededor del centro.
const AIM_SPAN := Vector2(0.42, 0.36)
## Si la mira no da con nada, la piña va a un punto a esta distancia.
const AIM_FAR := 18.0

const FRAME := Color(0.2, 0.21, 0.23)
const FRAME_LIT := Color(0.25, 0.7, 0.8)
const GLASS := Color(0.55, 0.85, 1.0, 0.05)

var mech: Mech = null
var chair: SeatInteractable = null
## Qué brazo maneja este panel (0 el izquierdo, 1 el derecho).
var arm_index := 1

var _open := false
var _swing := 0.0
var _hovered := false
var _cursor := Vector2.ZERO

var _glass: Node3D = null
var _frame_parts: Array[MeshInstance3D] = []
var _upper: MeshInstance3D = null
var _lower: MeshInstance3D = null
var _mount := Vector3.ZERO
var _folded := Transform3D()
var _unfolded := Transform3D()
var _hint: Label = null
var _cross: Control = null
var _strip: SeatStrip = null

static var _catcher: _InputCatcher = null


## LOS PANELES DE LA CABINA: por ahora uno, en la primera silla de la derecha (la del brazo derecho).
static func attach(cabin: MechCabin) -> void:
	for chair_found in cabin.chairs:
		if chair_found.position.x > 0.0:
			var panels := SeatPanels.new()
			panels.name = "Paneles de %s" % chair_found.name
			panels.mech = cabin.mech
			panels.chair = chair_found
			cabin.add_child(panels)
			return


func _ready() -> void:
	# Todo en el espacio de la cabina, con la silla mirando a −Z.
	var eye := chair.position + Vector3(0, chair.eye_height, 0)
	var ahead := Basis(Vector3.UP, chair.rotation.y)
	_mount = eye + ahead * Vector3(0.42, -0.72, -0.2)
	_unfolded = Transform3D(ahead, eye + ahead * Vector3(0.0, -0.1, -0.62))
	_folded = Transform3D(ahead * Basis(Vector3.UP, deg_to_rad(-70.0)) * Basis(Vector3.RIGHT, deg_to_rad(-55.0)),
		eye + ahead * Vector3(0.5, -0.5, -0.35))
	_build_panel()
	_strip = SeatStrip.new()
	_strip.mech = mech
	add_child(_strip)
	_strip.place(Transform3D(ahead * Basis(Vector3.RIGHT, deg_to_rad(-35.0)), eye + ahead * Vector3(0.0, -0.4, -0.6)))
	_build_screen()
	if _catcher == null or not is_instance_valid(_catcher):
		_catcher = _InputCatcher.new()
		get_tree().root.add_child.call_deferred(_catcher)
	_catcher.panels.append(self)


func _exit_tree() -> void:
	if is_instance_valid(_catcher):
		_catcher.panels.erase(self)
	if is_instance_valid(_hint):
		_hint.get_parent().queue_free()


## ── LO QUE SE VE ─────────────────────────────────────────────────────────────────────────────────────────────────

func _build_panel() -> void:
	Clay.box(self, Vector3(0.12, 0.06, 0.12), _mount, FRAME)
	_upper = _bar()
	_lower = _bar()
	_glass = Node3D.new()
	add_child(_glass)
	var pane := Clay.box(_glass, Vector3(PANEL_SIZE.x, PANEL_SIZE.y, 0.01), Vector3.ZERO, GLASS)
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var half := PANEL_SIZE * 0.5
	for edge: Array in [[Vector3(0, half.y, 0), Vector3(PANEL_SIZE.x + 0.016, 0.016, 0.016)],
			[Vector3(0, -half.y, 0), Vector3(PANEL_SIZE.x + 0.016, 0.016, 0.016)],
			[Vector3(half.x, 0, 0), Vector3(0.016, PANEL_SIZE.y, 0.016)],
			[Vector3(-half.x, 0, 0), Vector3(0.016, PANEL_SIZE.y, 0.016)]]:
		_frame_parts.append(Clay.box(_glass, edge[1], edge[0], FRAME))
	var title := Label3D.new()
	title.text = "BRAZO DERECHO"
	title.font_size = 40
	title.pixel_size = 0.0008
	title.modulate = SeatStrip.LINE
	title.outline_size = 0
	title.position = Vector3(-half.x + 0.03, half.y - 0.035, 0.01)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_glass.add_child(title)
	var help := Label3D.new()
	help.text = "clic: piña · E: cerrar"
	help.font_size = 28
	help.pixel_size = 0.0008
	help.modulate = Color(SeatStrip.LINE, 0.8)
	help.outline_size = 0
	help.position = Vector3(-half.x + 0.03, -half.y + 0.03, 0.01)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_glass.add_child(help)
	_place_panel()


func _bar() -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = BoxMesh.new()
	part.material_override = Clay.material(FRAME)
	add_child(part)
	return part


## EL PANEL EN SU LUGAR: entre plegado y abierto según `_swing`, con su brazo de dos tramos del soporte al panel (el codo,
## un poco afuera y arriba de la mitad).
func _place_panel() -> void:
	var t := smoothstep(0.0, 1.0, _swing)
	_glass.transform = _folded.interpolate_with(_unfolded, t)
	var grip := _glass.transform * Vector3(PANEL_SIZE.x * 0.5, -PANEL_SIZE.y * 0.5, -0.02)
	var elbow := (_mount + grip) * 0.5 + Vector3(0, 0.12, 0) + (grip - _mount).cross(Vector3.UP).normalized() * -0.06
	Clay.segment(_upper, _mount, elbow, 0.035)
	Clay.segment(_lower, elbow, grip, 0.03)


func _light(on: bool) -> void:
	for part in _frame_parts:
		part.material_override = Clay.material(FRAME_LIT if on else FRAME)


## La mira y el cartel de «E: abrir», en la pantalla.
func _build_screen() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_hint = Label.new()
	_hint.text = "E: abrir el panel del brazo derecho"
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.anchor_left = 0.5
	_hint.anchor_right = 0.5
	_hint.anchor_top = 0.62
	_hint.anchor_bottom = 0.62
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.visible = false
	layer.add_child(_hint)
	_cross = _Crosshair.new()
	_cross.visible = false
	layer.add_child(_cross)


## ── CADA CUADRO ──────────────────────────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	var here := _seated_here()
	if _open and not here:
		_set_open(false)
	var target := 1.0 if _open else 0.0
	if _swing != target:
		_swing = move_toward(_swing, target, delta / SWING_TIME)
		_place_panel()
	_hovered = here and not _open and _looking_at_panel()
	_light(_hovered or _open)
	_hint.visible = _hovered
	_cross.visible = _open
	if _open:
		var screen := get_viewport().get_visible_rect().size
		_cross.position = screen * 0.5 + _cursor


## La cámara está a los ojos de esta silla y hay alguien sentado: es quien maneja este panel.
func _seated_here() -> bool:
	var camera := get_viewport().get_camera_3d()
	if camera == null or chair.occupant() == null:
		return false
	var eye := chair.global_transform * Vector3(0, chair.eye_height, 0)
	return camera.global_position.distance_to(eye) < EYE_SLACK


func _looking_at_panel() -> bool:
	var camera := get_viewport().get_camera_3d()
	var to_panel := _glass.global_position - camera.global_position
	var ahead := -camera.global_basis.z
	return rad_to_deg(ahead.angle_to(to_panel)) < LOOK_CONE


func _set_open(on: bool) -> void:
	_open = on
	_cursor = Vector2.ZERO


## ── EL MOUSE Y LAS TECLAS (los pasa `_InputCatcher`, antes que el jugador) ───────────────────────────────────────

## Devuelve si el evento era para este panel.
func handle(event: InputEvent) -> bool:
	if not UIState.gameplay_active() or not _seated_here():
		return false
	var key := event as InputEventKey
	if key != null and key.physical_keycode == KEY_E:
		if not (_open or _hovered):
			return false
		if key.pressed and not key.echo:
			_set_open(not _open)
		return true
	if not _open:
		return false
	var motion := event as InputEventMouseMotion
	if motion != null:
		var screen := get_viewport().get_visible_rect().size
		var span := screen * AIM_SPAN
		_cursor = (_cursor + motion.relative * GameOptions.mouse_sensitivity).clamp(-span, span)
		return true
	var click := event as InputEventMouseButton
	if click != null and click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_punch()
		return true
	return false


func _punch() -> void:
	if mech.state != BalanceBody.State.STANDING or arm_index >= mech.arms.size():
		return
	var arm := mech.arms[arm_index]
	if arm.has_method("punch_at"):
		arm.call("punch_at", _aim_point())
	else:
		arm.punch(MechArm.Punch.STRAIGHT)


## ADÓNDE APUNTA LA MIRA: lo primero que encuentra el rayo que sale de los ojos por la mira (sin la meca), o un punto
## lejos sobre ese rayo.
func _aim_point() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	var at := get_viewport().get_visible_rect().size * 0.5 + _cursor
	var from := camera.project_ray_origin(at)
	var way := camera.project_ray_normal(at)
	var query := PhysicsRayQueryParameters3D.create(from, from + way * 60.0)
	query.exclude = [mech.get_rid()]
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit["position"] if hit.has("position") else from + way * AIM_FAR


## ── LAS PIEZAS DE ADENTRO ────────────────────────────────────────────────────────────────────────────────────────

## Recibe el mouse y las teclas ANTES que el jugador: es el último hijo de la raíz, y `_input` va de atrás para adelante.
class _InputCatcher extends Node:
	var panels: Array[SeatPanels] = []

	func _input(event: InputEvent) -> void:
		for panel in panels:
			if is_instance_valid(panel) and panel.handle(event):
				get_viewport().set_input_as_handled()
				return


## La mira del panel abierto: una cruz con un hueco al medio.
class _Crosshair extends Control:
	func _draw() -> void:
		var color := Color(0.35, 0.95, 1.0)
		for way: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			draw_line(way * 6.0, way * 16.0, Color.BLACK, 5.0)
			draw_line(way * 6.0, way * 16.0, color, 2.0)
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, color, 1.5)
