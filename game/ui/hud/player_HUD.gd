class_name PlayerHUD
extends CanvasLayer

## EL HUD DEL JUGADOR (ver docs/conceptual/hud.md): UNA SOLA BARRA, la de la ESTAMINA, como en Peak —lo amarillo se
## gasta corriendo y se recarga; las HERIDAS ocupan una parte roja desde el final, que se cura sola (ver CrewHealth),
## y con la barra entera roja se queda herido—. Se ve sólo al correr, mientras se recarga o mientras haya heridas.
## Lo demás —la velocidad, la carga del salto y del lanzamiento, la estabilidad— es de depuración: se ve sólo con el
## panel F1 abierto.

const BAR_W := 156.0
const INJURY_COLOR := Color(0.85, 0.15, 0.12, 1.0)

var _bar_fill: ColorRect
var _stamina_bar_fill: ColorRect
var _stamina_panel: Panel
var _injury_fill: ColorRect
var _debug_parts: Array[Control] = []
var _jump_bar_fill: ColorRect
var _throw_bar_fill: ColorRect
var _stability_hud: StabilityHUD
var _max_speed: float = 1.0

static func create(inst: EntityInstantiation) -> PlayerHUD:
	var hud := PlayerHUD.new()
	var arch := inst.arch_final
	var spec := inst.spec
	hud._max_speed = arch.speed * spec.speed_forw_multiplier * 10.0 * arch.sprint_multiplier

	# --- Stamina bar ---
	var stamina_panel := Panel.new()
	stamina_panel.anchor_left = 0.5
	stamina_panel.anchor_right = 0.5
	stamina_panel.anchor_top = 1.0
	stamina_panel.anchor_bottom = 1.0
	stamina_panel.offset_left = -80
	stamina_panel.offset_right = 80
	stamina_panel.offset_top = -56
	stamina_panel.offset_bottom = -44
	var stamina_border := StyleBoxFlat.new()
	stamina_border.bg_color = Color(0, 0, 0, 0)
	stamina_border.border_color = Color(1.0, 0.85, 0.2, 1.0)
	stamina_border.border_width_left = 2
	stamina_border.border_width_right = 2
	stamina_border.border_width_top = 2
	stamina_border.border_width_bottom = 2
	stamina_panel.add_theme_stylebox_override("panel", stamina_border)
	var stamina_fill := ColorRect.new()
	stamina_fill.color = Color(1.0, 0.85, 0.2, 1.0)
	stamina_fill.size = Vector2(156, 8)
	stamina_fill.position = Vector2(2, 2)
	stamina_panel.add_child(stamina_fill)
	hud._stamina_bar_fill = stamina_fill
	var injury_fill := ColorRect.new()
	injury_fill.color = INJURY_COLOR
	injury_fill.size = Vector2(0, 8)
	injury_fill.position = Vector2(2 + BAR_W, 2)
	stamina_panel.add_child(injury_fill)
	hud._injury_fill = injury_fill
	hud._stamina_panel = stamina_panel
	stamina_panel.visible = false
	hud.add_child(stamina_panel)

	# --- Speed bar ---
	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -80
	panel.offset_right = 80
	panel.offset_top = -34
	panel.offset_bottom = -26
	var border_mat := StyleBoxFlat.new()
	border_mat.bg_color = Color(0, 0, 0, 0)
	border_mat.border_color = Color(0.4, 0.85, 1.0, 1.0)
	border_mat.border_width_left = 2
	border_mat.border_width_right = 2
	border_mat.border_width_top = 2
	border_mat.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", border_mat)
	var fill := ColorRect.new()
	fill.color = Color(0.4, 0.85, 1.0, 1.0)
	fill.size = Vector2(0, 4)
	fill.position = Vector2(2, 2)
	panel.add_child(fill)
	hud._bar_fill = fill
	hud.add_child(panel)
	hud._debug_parts.append(panel)

	# --- Jump bar ---
	var jump_panel := Panel.new()
	jump_panel.anchor_left = 0.5
	jump_panel.anchor_right = 0.5
	jump_panel.anchor_top = 1.0
	jump_panel.anchor_bottom = 1.0
	jump_panel.offset_left = -80
	jump_panel.offset_right = 80
	jump_panel.offset_top = -78
	jump_panel.offset_bottom = -70
	var jump_border := StyleBoxFlat.new()
	jump_border.bg_color = Color(0, 0, 0, 0)
	jump_border.border_color = Color(0.4, 1.0, 0.5, 1.0)
	jump_border.border_width_left = 2
	jump_border.border_width_right = 2
	jump_border.border_width_top = 2
	jump_border.border_width_bottom = 2
	jump_panel.add_theme_stylebox_override("panel", jump_border)
	var jump_fill := ColorRect.new()
	jump_fill.color = Color(0.4, 1.0, 0.5, 1.0)
	jump_fill.size = Vector2(0, 4)
	jump_fill.position = Vector2(2, 2)
	jump_panel.add_child(jump_fill)
	hud._jump_bar_fill = jump_fill
	hud.add_child(jump_panel)
	hud._debug_parts.append(jump_panel)

	# --- Throw bar ---
	var throw_panel := Panel.new()
	throw_panel.anchor_left = 0.5
	throw_panel.anchor_right = 0.5
	throw_panel.anchor_top = 1.0
	throw_panel.anchor_bottom = 1.0
	throw_panel.offset_left = -80
	throw_panel.offset_right = 80
	throw_panel.offset_top = -100
	throw_panel.offset_bottom = -92
	var throw_border := StyleBoxFlat.new()
	throw_border.bg_color = Color(0, 0, 0, 0)
	throw_border.border_color = Color(1.0, 0.4, 0.4, 1.0)
	throw_border.border_width_left = 2
	throw_border.border_width_right = 2
	throw_border.border_width_top = 2
	throw_border.border_width_bottom = 2
	throw_panel.add_theme_stylebox_override("panel", throw_border)
	var throw_fill := ColorRect.new()
	throw_fill.color = Color(1.0, 0.4, 0.4, 1.0)
	throw_fill.size = Vector2(0, 4)
	throw_fill.position = Vector2(2, 2)
	throw_panel.add_child(throw_fill)
	hud._throw_bar_fill = throw_fill
	hud.add_child(throw_panel)
	hud._debug_parts.append(throw_panel)

	# --- Stability indicators ---
	var stability := StabilityHUD.new()
	stability.anchor_left = 0.5
	stability.anchor_right = 0.5
	stability.anchor_top = 1.0
	stability.anchor_bottom = 1.0
	stability.offset_left = -90.0
	stability.offset_right = 90.0
	stability.offset_top = -140.0
	stability.offset_bottom = -68.0
	hud._stability_hud = stability
	hud.add_child(stability)
	hud._debug_parts.append(stability)

	# Los stats del personaje (seed/arquetipo/height/weight/…) ahora viven en el tab
	# Info del panel de debug (F1), no en el HUD de gameplay. Ver technical/ui.md.

	return hud

func update_speed(current_speed: float) -> void:
	var ratio: float = clamp(current_speed / _max_speed, 0.0, 1.0)
	_bar_fill.size.x = ratio * 156.0

## LA BARRA: `ratio` la estamina sobre el máximo, `injury` la parte que ocupan las heridas (0 a 1, desde el final), y
## `active` si se está gastando o recargando. Sin nada de eso, no se ve.
func update_stamina(ratio: float, injury := 0.0, active := false) -> void:
	_stamina_bar_fill.size.x = clampf(ratio, 0.0, 1.0) * BAR_W
	var red := clampf(injury, 0.0, 1.0) * BAR_W
	_injury_fill.size.x = red
	_injury_fill.position.x = 2.0 + BAR_W - red
	_stamina_panel.visible = active or injury > 0.005


func _process(_delta: float) -> void:
	var debug := UIState.is_open(UIState.DEBUG)
	for part in _debug_parts:
		part.visible = debug

func update_jump(ratio: float) -> void:
	_jump_bar_fill.size.x = clamp(ratio, 0.0, 1.0) * 156.0

func update_throw(ratio: float) -> void:
	_throw_bar_fill.size.x = clamp(ratio, 0.0, 1.0) * 156.0

func update_stability(v_ind: Vector2, imp_xz: Vector2, imp_y: float) -> void:
	if is_instance_valid(_stability_hud):
		_stability_hud.update_stability(v_ind, imp_xz, imp_y)
