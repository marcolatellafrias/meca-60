class_name BossHealthBar
extends CanvasLayer

## LA VIDA DE LA MECA ENEMIGA, ARRIBA DE LA PANTALLA (13/11/2026): su nombre y una barra, como en las peleas contra
## jefes (el usuario: «un boss que tenga vida arriba, que se puede ver»). La prende quien la arma cuando el jugador
## está cerca (ver BossArenaArchetype). Al recibir un golpe, la barra destella; sin vida, dice «destruida».

const WIDTH := 720.0
const HEIGHT := 22.0

var boss: BossMech = null

var _title: Label = null
var _back: ColorRect = null
var _fill: ColorRect = null
var _flash := 0.0


func _ready() -> void:
	layer = 5
	var box := Control.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.position = Vector2(-WIDTH * 0.5, 18.0)
	add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 6)
	_title.size = Vector2(WIDTH, 30.0)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_back = ColorRect.new()
	_back.color = Color(0.08, 0.08, 0.09, 0.85)
	_back.position = Vector2(0.0, 34.0)
	_back.size = Vector2(WIDTH, HEIGHT)
	box.add_child(_back)
	_fill = ColorRect.new()
	_fill.position = Vector2(3.0, 37.0)
	_fill.size = Vector2(WIDTH - 6.0, HEIGHT - 6.0)
	box.add_child(_fill)
	if boss != null:
		boss.hurt_by.connect(func(_amount: float) -> void: _flash = 0.25)


func _process(delta: float) -> void:
	if not is_instance_valid(boss):
		return
	var share := clampf(boss.health / boss.max_health, 0.0, 1.0)
	_fill.size.x = (WIDTH - 6.0) * share
	_flash = maxf(_flash - delta, 0.0)
	_fill.color = Color(1.0, 0.95, 0.85) if _flash > 0.0 else Color(0.78, 0.22, 0.16)
	_title.text = "%s — %s" % [boss.design.title, "destruida" if boss.broken else "%d / %d" % [ceili(boss.health),
		roundi(boss.max_health)]]
