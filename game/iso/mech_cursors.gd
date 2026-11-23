class_name MechCursors
extends CanvasLayer

## LOS CURSORES DE LOS OTROS TRIPULANTES (22/11/2026; el usuario: «que puedan ver el cursor de los otros jugadores, así… se
## sincronicen más espacialmente»). Se ven yendo arriba, de cada uno que tenga el mouse a la vista. Cada máquina tiene su
## cámara, así que no viaja el píxel sino LO QUE SEÑALA:
##   · SOBRE LOS CUADRADOS, el punto del tablero (MechCrewHud.board), que mide lo mismo en todas.
##   · SOBRE EL MUNDO, el punto del piso, en metros desde la meca.

const SEND_RATE := 15.0
## Cada cuánto lo repite aunque esté quieto, y cuánto sin noticias lo da por ido (s).
const HEARTBEAT := 0.4
const STALE := 1.2
const FOLLOW := 18.0
const NAME_SIZE := 13
const COLORS: Array[Color] = [Color(0.25, 0.9, 0.5), Color(1.0, 0.65, 0.1), Color(0.85, 0.45, 1.0)]
const ARROW: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.0, 19.0), Vector2(5.0, 15.0), Vector2(9.0, 23.0),
	Vector2(12.0, 21.0), Vector2(8.0, 14.0), Vector2(14.0, 14.0)]

var crew: MechCrew = null
var hud: MechCrewHud = null

## peer → {on_board: bool, at: Vector2 o Vector3, age: float, shown: Vector2, fresh: bool}
var _others := {}
var _paper: Control = null
var _clock := 0.0
var _beat := 0.0
var _sharing := false
var _last: Variant = null


func _ready() -> void:
	name = "Cursores"
	layer = 31
	multiplayer.peer_disconnected.connect(_forget)
	_paper = Control.new()
	_paper.set_anchors_preset(Control.PRESET_FULL_RECT)
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.draw.connect(_draw_all)
	add_child(_paper)


func _forget(peer: int) -> void:
	_others.erase(peer)


func _process(delta: float) -> void:
	_send(delta)
	var aboard := crew.local_aboard()
	_paper.visible = aboard
	for peer: int in _others.keys():
		var other: Dictionary = _others[peer]
		other["age"] = float(other["age"]) + delta
		if float(other["age"]) > STALE:
			_others.erase(peer)
			continue
		var goal := screen_of(peer)
		other["fresh"] = bool(other["fresh"]) or not goal.is_finite()
		if goal.is_finite():
			other["shown"] = goal if other["fresh"] else (other["shown"] as Vector2).lerp(goal, 1.0 - exp(-FOLLOW * delta))
			other["fresh"] = false
	_paper.queue_redraw()


## DÓNDE VA EN ESTA PANTALLA el cursor de `peer`; INF si no se ve.
func screen_of(peer: int) -> Vector2:
	var other: Dictionary = _others.get(peer, {})
	if other.is_empty():
		return Vector2.INF
	if other["on_board"]:
		return hud.board.global_position + (other["at"] as Vector2)
	var camera := IsoView.of(get_tree())
	if camera == null:
		return Vector2.INF
	var point := crew.mech.global_position + (other["at"] as Vector3)
	point.y = _floor()
	return Vector2.INF if camera.is_position_behind(point) else camera.unproject_position(point)


func _floor() -> float:
	return crew.mech.global_position.y - Mech.standing_height(crew.mech.cabin_shape)


func _send(delta: float) -> void:
	if not NetFollow.online(self):
		return
	var wanted := crew.local_aboard() and UIState.gameplay_active() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	if not wanted:
		if _sharing:
			_sharing = false
			_gone.rpc()
		return
	_sharing = true
	_clock -= delta
	_beat -= delta
	if _clock > 0.0:
		return
	var mouse := get_viewport().get_mouse_position()
	var on_board := hud.board.get_global_rect().has_point(mouse)
	var at: Variant = mouse - hud.board.global_position
	if not on_board:
		var camera := IsoView.of(get_tree())
		var ground := camera.pointed_at(_floor()) if camera != null else Vector3.INF
		if not ground.is_finite():
			return
		at = ground - crew.mech.global_position
	if at == _last and _beat > 0.0:
		return
	_last = at
	_clock = 1.0 / SEND_RATE
	_beat = HEARTBEAT
	_tell.rpc(on_board, at)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _tell(on_board: bool, at: Variant) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not (at is Vector2 or at is Vector3) or on_board != (at is Vector2):
		return
	var before: Dictionary = _others.get(peer, {})
	_others[peer] = {"on_board": on_board, "at": at, "age": 0.0, "shown": before.get("shown", Vector2.ZERO),
		"fresh": before.is_empty()}


@rpc("any_peer", "call_remote", "reliable")
func _gone() -> void:
	_others.erase(multiplayer.get_remote_sender_id())


## EL MISMO COLOR PARA CADA JUGADOR EN TODAS LAS MÁQUINAS: por su lugar entre los ids de la sesión.
func color_of(peer: int) -> Color:
	var everyone: Array = SessionManager.players.keys()
	everyone.sort()
	return COLORS[maxi(everyone.find(peer), 0) % COLORS.size()]


func _name_of(peer: int) -> String:
	if SessionManager.players.has(peer):
		var player: SessionPlayer = SessionManager.players[peer]
		if player.steam_name != "":
			return player.steam_name
	return "Jugador %d" % peer


func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	for peer: int in _others:
		var other: Dictionary = _others[peer]
		if other["fresh"]:
			continue
		var at: Vector2 = other["shown"]
		var tint := color_of(peer)
		var shape := PackedVector2Array()
		for corner in ARROW:
			shape.append(at + corner)
		_paper.draw_colored_polygon(shape, tint)
		var outline := shape.duplicate()
		outline.append(shape[0])
		_paper.draw_polyline(outline, Color.BLACK, 1.5, true)
		var label := at + Vector2(16.0, 30.0)
		_paper.draw_string_outline(font, label, _name_of(peer), HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_SIZE, 4, Color.BLACK)
		_paper.draw_string(font, label, _name_of(peer), HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_SIZE, tint)
