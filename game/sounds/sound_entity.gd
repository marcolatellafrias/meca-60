class_name SoundEntity
extends Node3D

## ALGO QUE SUENA: todo objeto que hace un sonido (Interactable hereda de acá, y los paquetes). Cada clase DECLARA en su
## constante `SOUNDS` qué clave suena en cada evento, y su código sólo dice CUÁNDO:
##
##     const SOUNDS := {
##         SIT: &"silla_sienta",                              # un evento, una clave
##         &"hit_metal": [&"golpe_paquete", &"golpe_metal"],   # varias claves: suenan juntas
##         MOVE_UP: &"rueda_derecha",                          # mientras se mueve para un lado (ver `move_sound`)
##     }
##     func sounds() -> Dictionary: return SOUNDS
##
##   · UN GOLPE: `play_sound(evento)`.
##   · UN LOOP: `start_sound(evento)` y `stop_sound(evento)`.
##   · EL MOVIMIENTO: lo que tiene un valor que se mueve (el giro de una rueda, una palanca) se lo pasa a
##     `move_sound(valor)` cada vez que cambia (los controles lo hacen solos). Suena en loop MOVE_UP o MOVE_DOWN según
##     para dónde va —o MOVE_SELF si se mueve solo y la clase lo declara— y se apaga a los MOVE_IDLE_S quieto.
##
## Suena en `sound_anchor(evento)`: la entidad, salvo que la clase diga otra cosa. Cómo suena una clave, en Sounds.
## *Hasta el 13/11/2026 tenía estados, transiciones con su momento, cortes, continuidad, variantes y el archivo que
## seguía a la mano; se simplificó (ver Sounds).*

const TAKE := &"take"
const DROP := &"drop"
const CLICK := &"click"
const SIT := &"sit"
const STAND := &"stand"
const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const MOVE_SELF := &"move_self"
## Quieto este tiempo (s), se apaga lo que suena al moverse.
const MOVE_IDLE_S := 0.15

## evento → los reproductores de su loop.
var _loops: Dictionary = {}
var _move_value := NAN
var _move_msec := 0
var _watch: MoveWatch = null


## EVENTO → CLAVE (o lista de claves) de esta clase: su constante `SOUNDS`. Cada clase que suena pisa esto.
func sounds() -> Dictionary:
	return {}


## Dónde suena `event`: acá, salvo que la clase diga otra cosa.
func sound_anchor(_event: StringName) -> Node3D:
	return self


func _keys(event: StringName) -> Array:
	var raw: Variant = sounds().get(event)
	if raw == null:
		return []
	return raw if raw is Array else [raw]


## UN GOLPE de `event`, todas sus claves, en `at` (si no, en su ancla). `volume` es lineal.
func play_sound(event: StringName, at: Node3D = null, pitch := 1.0, volume := 1.0) -> void:
	for key: StringName in _keys(event):
		Sounds.play(key, at if at != null else sound_anchor(event), pitch, volume)


## PRENDE el loop de `event`, si no está sonando.
func start_sound(event: StringName) -> void:
	if _loops.has(event):
		return
	var players: Array = []
	for key: StringName in _keys(event):
		var player := Sounds.loop(key, sound_anchor(event))
		if player != null:
			players.append(player)
	if not players.is_empty():
		_loops[event] = players


## APAGA el loop de `event`.
func stop_sound(event: StringName) -> void:
	for player: Variant in _loops.get(event, []):
		if is_instance_valid(player):
			(player as Node).queue_free()
	_loops.erase(event)


## EL VALOR QUE SE MUEVE, cada vez que cambia (ver arriba). El primero sólo dice dónde está.
func move_sound(value: float, by_itself := false) -> void:
	var before := _move_value
	_move_value = value
	_move_msec = Time.get_ticks_msec()
	if is_nan(before) or is_equal_approx(value, before) or not is_inside_tree():
		return
	var playing := MOVE_UP if value > before else MOVE_DOWN
	if by_itself and sounds().has(MOVE_SELF):
		playing = MOVE_SELF
	for event: StringName in [MOVE_UP, MOVE_DOWN, MOVE_SELF]:
		if event != playing:
			stop_sound(event)
	start_sound(playing)
	if _watch == null:
		_watch = MoveWatch.new()
		_watch.entity = self
		add_child(_watch)
	_watch.set_process(true)


## QUIEN APAGA LO QUE SUENA AL MOVERSE cuando la entidad queda quieta: un nodo aparte, porque las clases que suenan
## tienen su propio `_process` y lo pisarían.
class MoveWatch extends Node:
	var entity: SoundEntity = null

	func _process(_delta: float) -> void:
		if Time.get_ticks_msec() - entity._move_msec < int(SoundEntity.MOVE_IDLE_S * 1000.0):
			return
		for event: StringName in [SoundEntity.MOVE_UP, SoundEntity.MOVE_DOWN, SoundEntity.MOVE_SELF]:
			entity.stop_sound(event)
		set_process(false)
