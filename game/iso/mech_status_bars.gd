class_name MechStatusBars
extends CanvasLayer

## LA SALUD Y LA ENERGÍA DE LA MECA, ARRIBA (22/11/2026; el usuario: «la parte de arriba esté mano izquierda la salud de la
## nave y mano derecha la energía»). En la partida las ve toda la tripulación, también a pie: hay que saber qué le falta para
## ir a buscarlo. En el sandbox, sólo yendo arriba. Antes de la pelea la meca todavía no tiene vida (Health): se ve llena.
## LA ENERGÍA baja de golpe y deja UN FANTASMA de lo gastado, como la vida en League of Legends: espera y después se achica.

const WIDTH := 360.0
const HIGH := 18.0
const MARGIN := 24.0
const TOP := 36.0
const LABEL_SIZE := 15
const BACK := Color(0.0, 0.0, 0.0, 0.6)
const HEALTH := Color(0.25, 0.7, 0.35)
const ENERGY := Color.WHITE
const DEBT := Color(0.95, 0.25, 0.2)
const GHOST := Color(1.0, 0.72, 0.2)
## Cuánto se queda quieto el fantasma (s), lo que se achica por segundo (partes de la barra) y la caída de un cuadro que
## cuenta como un gasto de golpe: lo que se va de a poco (el escudo, el sobrevuelo) no lo vuelve a frenar.
const GHOST_HOLD := 0.45
const GHOST_SPEED := 0.8
const GHOST_JUMP := 0.02

var crew: MechCrew = null

var _health: Dictionary = {}
var _energy: Dictionary = {}
var _ghost: ColorRect = null
var _ghost_share := 1.0
var _ghost_wait := 0.0
var _share_was := 1.0


func _ready() -> void:
	name = "Barras de la meca"
	layer = 29
	_health = _bar("SALUD", HEALTH, HORIZONTAL_ALIGNMENT_LEFT)
	_energy = _bar("ENERGÍA", ENERGY, HORIZONTAL_ALIGNMENT_RIGHT)
	_ghost = ColorRect.new()
	_ghost.color = GHOST
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := _energy["back"] as ColorRect
	back.add_child(_ghost)
	back.move_child(_ghost, 0)
	visible = false


func _bar(title: String, color: Color, align: HorizontalAlignment) -> Dictionary:
	var back := ColorRect.new()
	back.color = BACK
	back.size = Vector2(WIDTH, HIGH)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	var fill := ColorRect.new()
	fill.color = color
	fill.size = back.size
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(fill)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = align
	label.position = Vector2(0.0, -23.0)
	label.size = Vector2(WIDTH, 20.0)
	label.add_theme_font_size_override("font_size", LABEL_SIZE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(label)
	return {"back": back, "fill": fill, "label": label, "title": title}


func _process(delta: float) -> void:
	visible = crew.local_aboard() or get_tree().get_first_node_in_group(BaseWorld.GROUP) != null
	if not visible:
		return
	var screen := get_viewport().get_visible_rect().size
	var wide := minf(WIDTH, screen.x * 0.3)
	_place(_health, Vector2(MARGIN, TOP), wide)
	_place(_energy, Vector2(screen.x - MARGIN - wide, TOP), wide)
	_show_health(wide)
	_show_energy(wide, delta)


func _place(bar: Dictionary, at: Vector2, wide: float) -> void:
	var back := bar["back"] as ColorRect
	back.position = at
	back.size.x = wide
	(bar["label"] as Label).size.x = wide


func _show_health(wide: float) -> void:
	var life := Health.of(crew.mech)
	var share := life.share() if life != null else 1.0
	(_health["fill"] as ColorRect).size.x = wide * share
	var label := _health["label"] as Label
	if life == null:
		label.text = "SALUD"
	elif life.dead():
		label.text = "SALUD  ·  DERROTADA"
	else:
		label.text = "SALUD  %d / %d" % [ceili(life.left), roundi(life.full)]


func _show_energy(wide: float, delta: float) -> void:
	var energy := crew.mech.energy
	var owed := energy.level < 0.0
	var fill := _energy["fill"] as ColorRect
	# EN NEGATIVO, lo que se debe, en rojo (ver MechEnergy).
	fill.size.x = wide * (energy.debt_share() if owed else energy.share())
	fill.color = DEBT if not energy.able() or owed else ENERGY
	_follow_ghost(energy.share(), delta)
	_ghost.size = Vector2(wide * _ghost_share, HIGH)
	var label := _energy["label"] as Label
	label.text = "ATURDIDA" if not energy.able() else "ENERGÍA  %d / %d" % [roundi(energy.level * MechEnergy.UNIT),
		roundi(MechEnergy.capacity() * MechEnergy.UNIT)]


## EL FANTASMA: un gasto de golpe lo deja quieto un rato; después alcanza a la barra. Si la barra sube, la acompaña.
func _follow_ghost(share: float, delta: float) -> void:
	if _share_was - share >= GHOST_JUMP:
		_ghost_wait = GHOST_HOLD
	_share_was = share
	_ghost_wait = maxf(_ghost_wait - delta, 0.0)
	if _ghost_wait <= 0.0:
		_ghost_share = move_toward(_ghost_share, share, GHOST_SPEED * delta)
	_ghost_share = maxf(_ghost_share, share)
