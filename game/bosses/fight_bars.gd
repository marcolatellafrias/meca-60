class_name FightBars
extends CanvasLayer

## LAS BARRAS DE VIDA DE LA PELEA (13/11/2026): la del jefe, ancha arriba al medio, con su nombre (como en los Souls); la
## de la meca, abajo a la izquierda. Se ven sólo cuando la cámara está cerca del jefe. Leen las vidas (Health) en cada
## cuadro: no hay que avisarles nada.

## A cuánto del jefe tiene que estar la cámara para verlas (m).
const RANGE := 300.0
const BOSS_SIZE := Vector2(760.0, 18.0)
const MECH_SIZE := Vector2(360.0, 14.0)

var boss: Node3D = null
var boss_name := ""
## La meca: se la puede cambiar (la K de la parcela).
var mech: Node3D = null

var _boss_bar: Dictionary = {}
var _mech_bar: Dictionary = {}


func _ready() -> void:
	layer = 5
	_boss_bar = _make(BOSS_SIZE, Color(0.75, 0.15, 0.12))
	_mech_bar = _make(MECH_SIZE, Color(0.25, 0.7, 0.35))


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var near := boss != null and is_instance_valid(boss) and camera != null \
		and camera.global_position.distance_to(boss.global_position) < RANGE
	var size := get_viewport().get_visible_rect().size
	_show(_boss_bar, near, Health.of(boss) if near else null, boss_name,
		Vector2((size.x - BOSS_SIZE.x) * 0.5, 84.0))
	var mech_ok := near and mech != null and is_instance_valid(mech)
	_show(_mech_bar, mech_ok, Health.of(mech) if mech_ok else null, str(mech.name) if mech_ok else "",
		Vector2(24.0, size.y - 60.0))


func _make(bar_size: Vector2, color: Color) -> Dictionary:
	var holder := Control.new()
	add_child(holder)
	var back := ColorRect.new()
	back.color = Color(0.0, 0.0, 0.0, 0.6)
	back.size = bar_size + Vector2(4.0, 4.0)
	back.position = Vector2(-2.0, -2.0)
	holder.add_child(back)
	var fill := ColorRect.new()
	fill.color = color
	fill.size = bar_size
	holder.add_child(fill)
	var label := Label.new()
	label.position = Vector2(0.0, -26.0)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 6)
	holder.add_child(label)
	return {"holder": holder, "fill": fill, "label": label, "size": bar_size}


func _show(bar: Dictionary, on: bool, health: Health, title: String, at: Vector2) -> void:
	var holder := bar["holder"] as Control
	holder.visible = on and health != null
	if not holder.visible:
		return
	holder.position = at
	var bar_size: Vector2 = bar["size"]
	(bar["fill"] as ColorRect).size = Vector2(bar_size.x * health.share(), bar_size.y)
	var label := bar["label"] as Label
	label.text = "%s   %d / %d%s" % [title, ceili(health.left), roundi(health.full),
		("   · %s" % health.last) if not health.last.is_empty() else ""]
	if health.dead():
		label.text = "%s   · DERROTADO" % title
