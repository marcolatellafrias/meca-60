class_name SoundEntity
extends Node3D

## ALGO QUE SUENA: todo objeto del juego que hace un sonido es uno de estos —los componentes y artefactos (Interactable
## hereda de acá), la lógica de un artefacto, las compuertas, los paquetes, los autos—. Cada clase DECLARA en su
## constante `SOUNDS` qué suena, y su código sólo dice CUÁNDO: el evento que pasó o el estado en que está. Cómo suena
## cada clave —su archivo o su sonido de prueba, su bus, su volumen— lo dice el catálogo (ver SoundCatalog, Sounds).
##
##     const SOUNDS := {
##         PRESS: &"boton",                                          # un evento, una clave
##         &"hit": [&"golpe_paquete", &"golpe_vidrio"],              # CAPAS: suenan juntas
##         &"line": {"keys": &"sirena", "while": HELD},      # un loop MIENTRAS está en un estado
##         MOVE: {"keys": &"palanca_corre", "resume": true},         # al moverse, CON CONTINUIDAD
##         MOVE_UP: {"keys": &"rueda_derecha", "scrub": true},       # para un lado, y el valor recorre el archivo
##         &"page": {"keys": &"pagina", "choke": &"hoja"},           # la nueva CORTA a la anterior
##     }
##     func sounds() -> Dictionary: return SOUNDS
##
## Lo que se puede declarar de cada sonido (una clave sola o una lista equivalen a {"keys": …}):
##
##   · `keys` — LAS CAPAS: una clave o varias, que suenan a la vez, cada una con su volumen de la mezcla.
##   · EVENTOS Y ESTADOS: un evento es un golpe, `play_sound(PRESS)`; lo que dura es un loop, que se prende y se apaga
##     a mano (`start_sound`, `stop_sound`) o SOLO, con `while`: suena mientras la entidad esté en ese estado (o en uno
##     de esa lista), y `set_sound_state` prende y apaga lo que corresponda. Levantar y apoyar son eventos; sostener
##     (HELD), estar en su lugar (RESTING) o sonar, estados.
##   · `cut` — CÓMO SE CORTA un loop al apagarse: CUT, seco, o FADE, con un fundido de `fade` segundos (el de siempre,
##     FADE_S, para que no chasquee). Un golpe no se corta: suena hasta el final, salvo un choke.
##   · `choke` — UN GRUPO DE CORTE: lo que suena de un grupo se corta seco cuando arranca otro del mismo grupo en la
##     misma entidad —la puerta que cierra a mitad de abrir corta el sonido de abrir; el tono de línea, la voz—.
##   · `resume` — CONTINUIDAD: el loop que se apaga guarda dónde quedó y, al volver a prenderse, sigue desde ahí en vez
##     de empezar de nuevo (la palanca que se corre de a poco suena como un solo recorrido).
##   · EL MOVIMIENTO: lo que tiene un valor que se mueve (el giro de una rueda, el recorrido de una palanca) se lo pasa
##     a `move_sound(valor)` cada vez que cambia —los controles lo hacen solos, ver ControllableInteractable—, y suenan
##     MOVE mientras se mueve, para cualquier lado, y MOVE_UP o MOVE_DOWN según para dónde (a un lado un sonido, al
##     otro, otro); se apagan solos al quedar quieto MOVE_IDLE_S. Lo que SE MUEVE SOLO —sin una mano: la inercia, un
##     reloj, lo que lo mueve el código— suena MOVE_SELF si la clase lo declara (la rueda que gira sola, con
##     continuidad), y si no, igual que movido a mano. Lo que se puede decir de cada uno:
##       · `scrub` — EL VALOR ES LA POSICIÓN EN EL ARCHIVO: el rango del valor (`sound_range`, 0 a 1 si la clase no
##         dice otro) recorre el archivo de punta a punta, así el sonido sigue a la mano: girar despacio es oírlo
##         despacio, volver es volver a oír lo mismo, y es continuo porque el lugar lo pone el valor y no el reloj.
##       · `reverse` — el archivo se recorre al revés (vaciarse es llenarse para atrás).
##       · `speed` — a qué velocidad (unidades del valor por segundo) suena a pleno; más despacio, más bajo.
##     Un nivel de líquido es eso mismo: subir es llenarse (MOVE_UP), bajar es vaciarse (MOVE_DOWN).
##   · EL MOMENTO: un evento que es un pedido y una transición —soltar el libro es el clic y después el viaje de vuelta
##     a su lugar; subir el interruptor, el clic y el salto hasta el tope— suena en UN PUNTO de la transición, de 0 (el
##     clic) a 1 (al terminar), el elegido para su clave con un slider en el panel de sonidos (Sounds.sound_moment; 1
##     si no se tocó). La entidad cuenta la transición: `begin_sound_transition(event)` al pedirlo,
##     `sound_transition(event, avance)` mientras pasa (0 a 1), `end_sound_transition(event)` al terminar, y
##     `cancel_sound_transition(event)` si se corta; el golpe suena una vez, cuando el avance cruza el punto. La clase
##     anuncia qué eventos lo tienen en su constante `SOUND_MOMENTS`, que heredan sus hijas, y el panel le pone a cada
##     una de esas claves su slider. Lo pidió el dios del juego el 11/10/2026: primero un toggle, después «un slider,
##     así puedo decidir en qué momento de la transición ocurre», y como primitiva, para cualquiera.
##   · LAS VUELTAS: un loop puede tener una PAUSA entre vuelta y vuelta (Sounds.loop_pause, un slider de su caja):
##     suena el archivo entero, calla la pausa y vuelve, mientras siga prendido —el timbre del teléfono—. Cuándo suena
##     y cuándo está en la pausa lo dice la señal `sound_phase(event, sonando)` (también al prender y apagar un loop
##     seguido) y `is_sound_sounding(event)`: así el objeto acompaña lo que se oye —el tubo tiembla mientras suena el
##     timbre, y en la pausa se queda quieto— sin saber nada del archivo.
##
## LOS GENÉRICOS (`GENERIC`): error, las fallas (general, de tablero, de cable, la fuga de vapor), aprobado y calculando
## no son de ninguna pieza; cualquier entidad los hace sonar sin declararlos (`play_sound(PASS)`,
## `start_sound(COMPUTING)`), y una clase que quiera otro sonido para uno de esos eventos lo declara en su `SOUNDS`, que
## manda.
##
## LAS VARIANTES: una clave con `variants` en el catálogo (el timbre) tiene varios archivos con nombre, y cada objeto
## suena SIEMPRE con uno, el suyo: `sound_variant`, que elige quien lo arma (con su semilla) o se cambia con
## `set_sound_variant` (la tecla de la fila Sonidos). No es lo mismo que las alternativas, que se sortean en cada golpe.
##
## DÓNDE SUENA: en `sound_anchor(event)`, que es la entidad salvo que la clase diga otra cosa (lo que se sostiene suena
## en la pieza que va en la mano, ver HeldInteractable), o en el `at` que se le pase.
##
## De las constantes `SOUNDS` sale quién pide cada clave (`askers`): lo que dice el panel de sonidos, y lo que mira el
## test (tests/sound_keys). Ver docs/technical/audio.md.

## LOS EVENTOS Y ESTADOS QUE SE REPITEN ENTRE CLASES; cada clase puede tener los suyos.
const PRESS := &"press"
const RELEASE := &"release"
const TAKE := &"take"
const DROP := &"drop"
const PLUG := &"plug"
const UNPLUG := &"unplug"
const PLACE := &"place"
const REMOVE := &"remove"
const ON := &"on"
const OFF := &"off"
const OPEN := &"open"
const CLOSE := &"close"
const CLICK := &"click"
const ERROR := &"error"
const HIT := &"hit"

const ARRIVE := &"arrive"
const NOTE := &"note"
const FAIL := &"fail"
const FAIL_BOARD := &"fail_board"
const FAIL_CABLE := &"fail_cable"
const LEAK := &"leak"
const PASS := &"pass"
const COMPUTING := &"computing"
const ACTIVATE := &"activate"
const SIT := &"sit"
const STAND := &"stand"
const RUNNING := &"running"
const RING := &"ring"
## El movimiento (ver `move_sound`).
const MOVE := &"move"
const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const MOVE_SELF := &"move_self"
## Estados.
const RESTING := &"resting"
const HELD := &"held"
const RETURNING := &"returning"
const ACTIVE := &"active"

## Cuánto quieto hace falta para que se apague lo que suena al moverse.
const MOVE_IDLE_S := 0.15
## Cuánto se deja correr el archivo de donde dice el valor antes de llevarlo ahí (`scrub`), en segundos: menos es más
## pegado a la mano y más cortado.
const SCRUB_SLACK := 0.06

## LOS SONIDOS GENÉRICOS: de nadie en particular, para usar donde haga falta —sobre todo los artefactos—. Cualquier
## entidad los tiene; su `SOUNDS` los pisa.
const GENERIC := {
	ERROR: &"error",
	FAIL: &"falla",
	FAIL_BOARD: &"falla_tablero",
	FAIL_CABLE: &"falla_cable",
	LEAK: {"keys": &"fuga_vapor", "cut": FADE, "fade": 0.3},
	PASS: &"aprobado",
	COMPUTING: {"keys": &"calculando", "cut": FADE, "fade": 0.15},
}

## Cómo se corta un loop (ver `cut`).
const CUT := &"cut"
const FADE := &"fade"
const FADE_S := 0.08
## Hasta dónde baja un fundido antes de parar.
const SILENCE_DB := -60.0

## UN LOOP EMPEZÓ A SONAR o se calló (ver LAS VUELTAS): al prenderlo y apagarlo, y en cada vuelta y cada pausa.
signal sound_phase(event: StringName, sounding: bool)

## EL ESTADO en que está, para los loops con `while` (ver `set_sound_state`).
var sound_state: StringName = &""
## QUÉ VARIANTE suena en sus claves con variantes (ver Sounds.variants): un número, que da la vuelta.
var sound_variant := 0

## Los loops de cada evento: `{"players": [...], "on": bool, "resume": [segundos por capa], "base": [dB por capa],
## "gain": dB, "tween": Tween}`. Se arman la primera vez y se reusan.
var _voices: Dictionary = {}
## Los golpes de cada grupo de corte que todavía suenan.
var _choked: Dictionary = {}
## Las transiciones en curso (ver EL MOMENTO): evento → hasta dónde llegó (−1 recién pedida; INF, ya sonó).
var _transitions: Dictionary = {}
## El movimiento: el último valor, cuándo llegó, y quién apaga lo que suena al quedar quieto.
var _move_value := NAN
var _move_msec := 0
var _move_watch: MoveWatch = null


## EVENTO → SONIDO de esta clase: su constante `SOUNDS`. Cada clase que suena pisa esto.
func sounds() -> Dictionary:
	return {}


## Dónde suena `event`: acá, salvo que la clase diga otra cosa.
func sound_anchor(_event: StringName) -> Node3D:
	return self


## Lo declarado para `event`, completo (`keys` siempre una lista); vacío si esta clase no lo hace sonar.
func sound_spec(event: StringName) -> Dictionary:
	return spec_of(sounds().get(event, GENERIC.get(event)))


## La primera clave de `event`, o vacía.
func sound_key(event: StringName) -> StringName:
	var keys: Array = sound_spec(event).get("keys", [])
	return keys[0] if not keys.is_empty() else &""


# ── Los golpes ────────────────────────────────────────────────────────────────────────────────────────────────────

## UN GOLPE de `event`, todas sus capas, en `at` (si no, en su ancla). Devuelve el reproductor de la primera capa que
## suena, o null.
## `volume`, lineal, sobre el de cada clave (un golpe más suave, más bajo).
func play_sound(event: StringName, at: Node3D = null, pitch := 1.0, volume := 1.0) -> AudioStreamPlayer3D:
	var spec := sound_spec(event)
	if spec.is_empty():
		return null
	_choke(spec, event)
	var first: AudioStreamPlayer3D = null
	for key: StringName in spec["keys"]:
		var player := Sounds.play(key, at if at != null else sound_anchor(event), pitch, sound_variant)
		if player == null:
			continue
		if volume != 1.0:
			player.volume_db += linear_to_db(maxf(volume, 0.0001))
		_track_choke(spec, player)
		if first == null:
			first = player
	return first


# ── El momento ────────────────────────────────────────────────────────────────────────────────────────────────────

## EMPIEZA LA TRANSICIÓN de `event` (el clic): avance 0. Si su punto es 0, suena ya.
func begin_sound_transition(event: StringName) -> void:
	_transitions[event] = -1.0
	sound_transition(event, 0.0)


## CUÁNTO VA la transición de `event`, de 0 a 1: suena una vez, cuando cruza su punto (ver EL MOMENTO).
func sound_transition(event: StringName, progress: float) -> void:
	if not _transitions.has(event):
		return
	var before: float = _transitions[event]
	if is_inf(before):
		return
	var at := Sounds.sound_moment(sound_key(event))
	if before < at and progress >= at:
		_transitions[event] = INF
		play_sound(event)
	else:
		_transitions[event] = maxf(before, progress)


## TERMINÓ: si todavía no sonó (su punto es 1), suena ahora.
func end_sound_transition(event: StringName) -> void:
	sound_transition(event, 1.0)
	_transitions.erase(event)


## SE CORTÓ a la mitad (lo volvieron a agarrar, cambió de lado): no suena más lo que faltaba.
func cancel_sound_transition(event: StringName) -> void:
	_transitions.erase(event)


## UNA NOTA de `event`, de `hz` y `length` segundos (las claves con `ref_hz`: la corneta, el grabador, el ding).
func play_note(event: StringName, hz: float, length: float, at: Node3D = null) -> AudioStreamPlayer3D:
	var spec := sound_spec(event)
	if spec.is_empty():
		return null
	_choke(spec, event)
	var first: AudioStreamPlayer3D = null
	for key: StringName in spec["keys"]:
		var player := Sounds.note(key, at if at != null else sound_anchor(event), hz, length)
		if player == null:
			continue
		_track_choke(spec, player)
		if first == null:
			first = player
	return first


# ── Los loops ─────────────────────────────────────────────────────────────────────────────────────────────────────

## PRENDE el loop de `event` (todas sus capas). Si ya suena, nada; si se estaba apagando, vuelve sin cortarse; con
## `resume`, sigue desde donde quedó.
func start_sound(event: StringName) -> void:
	var voice: Dictionary = _voices.get(event, {})
	if not voice.is_empty() and voice["on"]:
		return
	var spec := sound_spec(event)
	if spec.is_empty():
		return
	if voice.is_empty():
		voice = _make_voice(event, spec)
	_choke(spec, event)
	voice["on"] = true
	_kill_tween(voice)
	_apply_gain(voice)
	if is_inside_tree():
		_resume(voice, spec)


## APAGA el loop de `event` como diga su `cut`.
func stop_sound(event: StringName) -> void:
	var voice: Dictionary = _voices.get(event, {})
	if voice.is_empty() or not voice["on"]:
		return
	voice["on"] = false
	voice["cycle"] = int(voice["cycle"]) + 1
	_set_phase(voice, false)
	var spec := sound_spec(event)
	var fade := float(spec.get("fade", FADE_S))
	_kill_tween(voice)
	if spec.get("cut", FADE) == CUT or fade <= 0.0 or not is_inside_tree() or not _any_playing(voice):
		_halt(voice, spec)
		return
	var tween := create_tween().set_parallel(true)
	for player: Variant in voice["players"]:
		if is_instance_valid(player):
			tween.tween_property(player as AudioStreamPlayer3D, "volume_db", SILENCE_DB, fade)
	tween.chain().tween_callback(_halt.bind(voice, spec))
	voice["tween"] = tween


func set_sound_on(event: StringName, on: bool) -> void:
	if on:
		start_sound(event)
	else:
		stop_sound(event)


func is_sound_on(event: StringName) -> bool:
	return bool((_voices.get(event, {}) as Dictionary).get("on", false))


## SI EL LOOP DE `event` SUENA AHORA: prendido y no en la pausa entre vueltas (ver LAS VUELTAS).
func is_sound_sounding(event: StringName) -> bool:
	return bool((_voices.get(event, {}) as Dictionary).get("sounding", false))


## El tono de todas las capas del loop de `event` (el ventilador sigue su velocidad).
func set_sound_pitch(event: StringName, pitch: float) -> void:
	var voice: Dictionary = _voices.get(event, {})
	if voice.is_empty():
		voice = _make_voice(event, sound_spec(event))
	for player: Variant in voice.get("players", []):
		if is_instance_valid(player):
			# Sobre el tono de su clave en la mezcla (ver Sounds.mix_pitch): el ventilador lento sigue sonando más grave.
			var key := StringName((player as Node).get_meta(Sounds.META_KEY, &""))
			(player as AudioStreamPlayer3D).pitch_scale = maxf(pitch * Sounds.mix_pitch(key), 0.01)


## El volumen del loop de `event` sobre el de su clave, en lineal: 1 es como está (la estática sube cuanto peor se
## sintoniza).
func set_sound_volume(event: StringName, linear: float) -> void:
	var voice: Dictionary = _voices.get(event, {})
	if voice.is_empty():
		voice = _make_voice(event, sound_spec(event))
	if voice.is_empty():
		return
	voice["gain"] = linear_to_db(maxf(linear, 0.0001))
	if voice["on"] and not is_instance_valid(voice.get("tween")):
		_apply_gain(voice)


## LOS REPRODUCTORES del loop de `event`, armados si hace falta (para lo que el loop necesita tocar a mano).
func sound_players(event: StringName) -> Array:
	var voice: Dictionary = _voices.get(event, {})
	if voice.is_empty():
		voice = _make_voice(event, sound_spec(event))
	return voice.get("players", [])


# ── Las variantes ─────────────────────────────────────────────────────────────────────────────────────────────────

## PASA A LA VARIANTE `index`: lo que suene desde ahora suena con ella; los loops se rearman, y el que sonaba sigue.
func set_sound_variant(index: int) -> void:
	sound_variant = index
	for event: StringName in _voices.keys():
		var voice: Dictionary = _voices[event]
		var was_on: bool = voice["on"]
		voice["cycle"] = int(voice["cycle"]) + 1
		_set_phase(voice, false)
		_kill_tween(voice)
		for player: Variant in voice["players"]:
			if is_instance_valid(player):
				(player as Node).queue_free()
		_voices.erase(event)
		if was_on:
			start_sound(event)


## Los nombres de las variantes de `event` (vacío si su clave no tiene), y cuál suena.
func sound_variants(event: StringName) -> PackedStringArray:
	return Sounds.variants(sound_key(event))


func sound_variant_name(event: StringName) -> String:
	var names := sound_variants(event)
	return names[posmod(sound_variant, names.size())] if not names.is_empty() else ""


# ── Los estados ───────────────────────────────────────────────────────────────────────────────────────────────────

## LOS ESTADOS QUE SUENAN: los de los `while` de lo que declara, en orden, para quien quiera recorrerlos (el panel de
## sonidos, que los fuerza para escucharlos).
func sound_states() -> Array[StringName]:
	var out: Array[StringName] = []
	var declared := sounds()
	for event: Variant in declared:
		var spec := spec_of(declared[event])
		if not spec.has("while"):
			continue
		for state: Variant in (spec["while"] if spec["while"] is Array else [spec["while"]]):
			if not out.has(StringName(state)):
				out.append(StringName(state))
	return out


## Los eventos cuyas claves tienen variantes (ver `set_sound_variant`).
func variant_events() -> Array[StringName]:
	var out: Array[StringName] = []
	var declared := sounds()
	for event: Variant in declared:
		for key: StringName in spec_of(declared[event]).get("keys", []):
			if SoundCatalog.has_variants(key) and not out.has(StringName(event)):
				out.append(StringName(event))
	return out


## PASA AL ESTADO `state`: prende los loops cuyo `while` lo incluye y apaga, como diga su `cut`, los demás que tengan
## `while`.
func set_sound_state(state: StringName) -> void:
	if state == sound_state:
		return
	sound_state = state
	var declared := sounds()
	for event: StringName in declared:
		var spec := spec_of(declared[event])
		if not spec.has("while"):
			continue
		var during: Array = spec["while"] if spec["while"] is Array else [spec["while"]]
		if during.has(state):
			start_sound(event)
		else:
			stop_sound(event)


# ── El movimiento ─────────────────────────────────────────────────────────────────────────────────────────────────

## EL VALOR QUE SE MUEVE, cada vez que cambia: prende MOVE y MOVE_UP o MOVE_DOWN según para dónde fue —o MOVE_SELF,
## si se mueve solo (`by_itself`) y la clase lo declara—, los lleva a la posición del valor (`scrub`) y al volumen de su
## velocidad (`speed`). El primero sólo dice dónde está.
func move_sound(value: float, by_itself := false) -> void:
	var before := _move_value
	var now := Time.get_ticks_msec()
	var dt := clampf(float(now - _move_msec) / 1000.0, 1.0 / 240.0, MOVE_IDLE_S)
	_move_value = value
	_move_msec = now
	if is_nan(before) or is_equal_approx(value, before) or not is_inside_tree():
		return
	var declared := sounds()
	if not (declared.has(MOVE) or declared.has(MOVE_UP) or declared.has(MOVE_DOWN) or declared.has(MOVE_SELF)):
		return
	var playing: Array[StringName] = [MOVE, MOVE_UP if value > before else MOVE_DOWN]
	if by_itself and declared.has(MOVE_SELF):
		playing = [MOVE_SELF]
	for event: StringName in [MOVE, MOVE_UP, MOVE_DOWN, MOVE_SELF]:
		if not playing.has(event):
			stop_sound(event)
	var speed := absf(value - before) / dt
	for event: StringName in playing:
		if not declared.has(event):
			continue
		start_sound(event)
		_drive(event, value, speed)
	if _move_watch == null:
		_move_watch = MoveWatch.new()
		_move_watch.name = "SoundMove"
		_move_watch.entity = self
		add_child(_move_watch)
	_move_watch.set_process(true)


## EL RANGO DEL VALOR de `event` que recorre el archivo de punta a punta (`scrub`). Fuera de él, da la vuelta (una
## rueda sin tope).
func sound_range(_event: StringName) -> Vector2:
	return Vector2(0.0, 1.0)


## Quieto: se apaga lo que suena al moverse, como diga su `cut`.
func _move_stopped() -> void:
	for event: StringName in [MOVE, MOVE_UP, MOVE_DOWN, MOVE_SELF]:
		stop_sound(event)


func _drive(event: StringName, value: float, speed: float) -> void:
	var spec := sound_spec(event)
	if spec.has("speed"):
		set_sound_volume(event, clampf(speed / maxf(float(spec["speed"]), 0.001), 0.15, 1.0))
	if not spec.get("scrub", false):
		return
	var span := sound_range(event)
	var width := maxf(span.y - span.x, 0.0001)
	var t := (value - span.x) / width if value >= span.x and value <= span.y else fposmod(value - span.x, width) / width
	if spec.get("reverse", false):
		t = 1.0 - t
	for item: Variant in sound_players(event):
		if not is_instance_valid(item):
			continue
		var player := item as AudioStreamPlayer3D
		var length := player.stream.get_length() if player.stream != null else 0.0
		if length <= 0.0 or not player.is_inside_tree():
			continue
		var at := clampf(t, 0.0, 0.999) * length
		if not player.playing:
			player.play(at)
		elif absf(player.get_playback_position() - at) > SCRUB_SLACK:
			player.seek(at)


## QUIEN APAGA LO QUE SUENA AL MOVERSE cuando la entidad queda quieta: un nodo aparte, porque la entidad tiene su propio
## `_process` (o no) y no se lo pisa.
class MoveWatch extends Node:
	var entity: SoundEntity = null

	func _process(_delta: float) -> void:
		if entity == null or Time.get_ticks_msec() - entity._move_msec < int(SoundEntity.MOVE_IDLE_S * 1000.0):
			return
		entity._move_stopped()
		set_process(false)


# ── Un reproductor suelto ─────────────────────────────────────────────────────────────────────────────────────────

## UN REPRODUCTOR de `event` (su primera capa), colgado de `parent` y sin prender: para cuando una entidad lleva
## muchos del mismo, cada uno en otro nodo (el motor de cada auto, ver CarManager). null si no suena.
func sound_player(event: StringName, parent: Node) -> AudioStreamPlayer3D:
	var key := sound_key(event)
	if key.is_empty():
		return null
	var player := Sounds.player(key, sound_variant)
	parent.add_child(player)
	return player


# ── Por dentro ────────────────────────────────────────────────────────────────────────────────────────────────────

func _notification(what: int) -> void:
	# Lo que estaba prendido vuelve a sonar al volver al árbol (o al entrar por primera vez, prendido antes).
	if what == NOTIFICATION_ENTER_TREE:
		for event: StringName in _voices:
			var voice: Dictionary = _voices[event]
			if voice["on"] and not _any_playing(voice):
				_resume.call_deferred(voice, sound_spec(event))


func _make_voice(event: StringName, spec: Dictionary) -> Dictionary:
	if spec.is_empty():
		return {}
	var anchor := sound_anchor(event)
	var players: Array = []
	var base: Array = []
	var resume: Array = []
	for key: StringName in spec["keys"]:
		var player := Sounds.player(key, sound_variant)
		player.name = "%s_%s" % [event, key]
		anchor.add_child(player)
		players.append(player)
		base.append(player.volume_db)
		resume.append(0.0)
	var voice := {"players": players, "on": false, "resume": resume, "base": base, "gain": 0.0, "tween": null,
		"event": event, "sounding": false, "cycle": 0, "unlooped": false}
	_voices[event] = voice
	return voice


func _resume(voice: Dictionary, spec: Dictionary) -> void:
	if not voice["on"]:
		return
	var players: Array = voice["players"]
	# CON PAUSA (ver LAS VUELTAS): el archivo sin loop, para que termine, y al terminar la primera capa, la pausa.
	if not voice["unlooped"] and Sounds.loop_pause(StringName(spec["keys"][0])) > 0.0:
		voice["unlooped"] = true
		for i in players.size():
			var player: AudioStreamPlayer3D = players[i]
			if is_instance_valid(player) and player.stream != null:
				player.stream = Sounds.unlooped(player.stream)
				if i == 0:
					player.finished.connect(_lap_finished.bind(voice))
	for i in players.size():
		var player: AudioStreamPlayer3D = players[i]
		if not is_instance_valid(player) or not player.is_inside_tree() or player.stream == null or player.playing:
			continue
		player.play(float(voice["resume"][i]) if spec.get("resume", false) else 0.0)
	_set_phase(voice, true)


## TERMINÓ UNA VUELTA de un loop con pausa: calla la pausa y vuelve, si sigue prendido.
func _lap_finished(voice: Dictionary) -> void:
	if not voice["on"] or not is_inside_tree():
		return
	var key := StringName(sound_spec(voice["event"])["keys"][0])
	var pause := Sounds.loop_pause(key)
	voice["cycle"] = int(voice["cycle"]) + 1
	if pause <= 0.0:
		_resume(voice, sound_spec(voice["event"]))
		return
	_set_phase(voice, false)
	get_tree().create_timer(pause, false).timeout.connect(_lap_again.bind(voice, int(voice["cycle"])))


## Pasó la pausa: otra vuelta, si nadie lo apagó ni lo rearmó en el medio (`cycle`).
func _lap_again(voice: Dictionary, cycle: int) -> void:
	if voice["on"] and voice["cycle"] == cycle and is_inside_tree():
		_resume(voice, sound_spec(voice["event"]))


## Avisa si el loop pasó a sonar o a callarse (ver `sound_phase`).
func _set_phase(voice: Dictionary, sounding: bool) -> void:
	if voice["sounding"] == sounding:
		return
	voice["sounding"] = sounding
	sound_phase.emit(voice["event"], sounding)


func _halt(voice: Dictionary, spec: Dictionary) -> void:
	voice["tween"] = null
	var players: Array = voice["players"]
	for i in players.size():
		var player: AudioStreamPlayer3D = players[i]
		if not is_instance_valid(player):
			continue
		if spec.get("resume", false) and player.playing:
			voice["resume"][i] = player.get_playback_position()
		player.stop()
	_apply_gain(voice)


func _apply_gain(voice: Dictionary) -> void:
	var players: Array = voice["players"]
	for i in players.size():
		if is_instance_valid(players[i]):
			(players[i] as AudioStreamPlayer3D).volume_db = float(voice["base"][i]) + float(voice["gain"])


func _kill_tween(voice: Dictionary) -> void:
	var tween: Tween = voice.get("tween")
	if is_instance_valid(tween):
		tween.kill()
	voice["tween"] = null


func _any_playing(voice: Dictionary) -> bool:
	for player: Variant in voice["players"]:
		if is_instance_valid(player) and (player as AudioStreamPlayer3D).playing:
			return true
	return false


## Corta seco lo que suena del grupo de `spec`, menos `event` mismo si es un loop.
func _choke(spec: Dictionary, event: StringName) -> void:
	var group: StringName = spec.get("choke", &"")
	if group.is_empty():
		return
	for player: Variant in _choked.get(group, []):
		if is_instance_valid(player):
			(player as AudioStreamPlayer3D).stop()
			(player as AudioStreamPlayer3D).queue_free()
	_choked[group] = []
	for other: StringName in _voices:
		var other_spec := sound_spec(other)
		if other != event and other_spec.get("choke", &"") == group and is_sound_on(other):
			var voice: Dictionary = _voices[other]
			voice["on"] = false
			voice["cycle"] = int(voice["cycle"]) + 1
			_set_phase(voice, false)
			_kill_tween(voice)
			_halt(voice, other_spec)


func _track_choke(spec: Dictionary, player: AudioStreamPlayer3D) -> void:
	var group: StringName = spec.get("choke", &"")
	if group.is_empty():
		return
	var alive: Array = (_choked.get(group, []) as Array).filter(func(p: Variant) -> bool: return is_instance_valid(p))
	alive.append(player)
	_choked[group] = alive


# ── Lo declarado ──────────────────────────────────────────────────────────────────────────────────────────────────

## Una declaración de `SOUNDS` completa: una clave o una lista son {"keys": …}; `keys` siempre una lista.
static func spec_of(raw: Variant) -> Dictionary:
	if raw == null:
		return {}
	if raw is Dictionary:
		var spec := (raw as Dictionary).duplicate()
		spec["keys"] = _key_list(spec.get("keys", []))
		return spec if not (spec["keys"] as Array).is_empty() else {}
	var keys := _key_list(raw)
	return {"keys": keys} if not keys.is_empty() else {}


static func _key_list(raw: Variant) -> Array:
	var out: Array = []
	if raw is Array:
		for key: Variant in raw:
			if not String(key).is_empty():
				out.append(StringName(key))
	elif raw is String or raw is StringName:
		if not String(raw).is_empty():
			out.append(StringName(raw))
	return out


static var _askers: Dictionary = {}


## CLAVE → LAS CLASES QUE LA PIDEN, leído de la constante `SOUNDS` de cada clase que hereda de SoundEntity.
static func askers() -> Dictionary:
	if not _askers.is_empty():
		return _askers
	for event: StringName in GENERIC:
		for key: StringName in spec_of(GENERIC[event]).get("keys", []):
			_askers[String(key)] = PackedStringArray(["cualquiera (genérico)"])
	for entry: Dictionary in sound_classes():
		var declared: Dictionary = entry["sounds"]
		for event: Variant in declared:
			for key: StringName in spec_of(declared[event]).get("keys", []):
				var id := String(key)
				var who: PackedStringArray = _askers.get(id, PackedStringArray())
				if not who.has(entry["class"]):
					who.append(entry["class"])
				_askers[id] = who
	return _askers


## LAS CLASES QUE SUENAN: cada una con lo que declara (`{"class", "path", "sounds"}`), de la lista de clases globales.
## Lo declarado es toda constante propia cuyo nombre termina en SOUNDS —`SOUNDS`, o `TOGGLE_SOUNDS` en una subclase que
## suena distinto, porque GDScript no deja redeclarar la de su base—; la heredada no se cuenta dos veces.
static func sound_classes() -> Array[Dictionary]:
	var base_of := {}
	var path_of := {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		base_of[String(entry["class"])] = String(entry["base"])
		path_of[String(entry["class"])] = String(entry["path"])
	var out: Array[Dictionary] = []
	var names: Array = base_of.keys()
	names.sort()
	for class_id: String in names:
		if not _inherits(class_id, base_of):
			continue
		var script := load(path_of[class_id]) as Script
		if script == null:
			continue
		var base_script := script.get_base_script()
		var inherited: Dictionary = base_script.get_script_constant_map() if base_script != null else {}
		var declared := {}
		var constants := script.get_script_constant_map()
		for constant: String in constants:
			if constant.ends_with("SOUNDS") and constants[constant] is Dictionary and not inherited.has(constant):
				declared.merge(constants[constant] as Dictionary)
		if not declared.is_empty():
			out.append({"class": class_id, "path": path_of[class_id], "sounds": declared, "moments": _moments_of(script)})
	return out


## Los eventos con momento de `script` (su `SOUND_MOMENTS`, o el de la clase más cercana de las que hereda): el mapa de
## constantes de un script trae sólo las suyas.
static func _moments_of(script: Script) -> Array:
	while script != null:
		var constants := script.get_script_constant_map()
		if constants.has("SOUND_MOMENTS"):
			return constants["SOUND_MOMENTS"]
		script = script.get_base_script()
	return []


static func _inherits(class_id: String, base_of: Dictionary) -> bool:
	var up := class_id
	for _depth in 16:
		if up == "SoundEntity":
			return true
		if not base_of.has(up):
			return false
		up = base_of[up]
	return false
