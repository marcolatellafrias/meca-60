class_name Sounds

## EL REGISTRO DE SONIDOS POR CLAVE: cada sonido del juego se pide por su clave (ver SoundCatalog) y suena el archivo
## que tenga —`assets/audio/<categoría>/<clave>.ogg` o `.wav`— o, si no hay, el sonido de prueba (ver TestSounds). Cada
## clave va por su bus. Ver character-parametric:docs/technical/audio.md.
##
##     Sounds.play(&"palanca", self)          # un golpe, donde está `self`, y se borra solo
##     var hum := Sounds.player(&"ventilador")  # un reproductor, para prender y apagar
##
## LOS OBJETOS NO PIDEN ACÁ: piden por sus eventos y estados (ver SoundEntity), que declaran qué clave suena en cada
## uno. Esto es lo de abajo —qué stream, qué bus, qué volumen—, y lo usan directo sólo las herramientas (la fila
## Sonidos, su panel) y el ambiente.

const ROOT := "res://assets/audio"
const EXTENSIONS := ["ogg", "wav"]

## LOS BUSES (default_bus_layout.tres), todos bajo Master: lo que la pantalla de Opciones mueve, uno por perilla. El de
## la voz (VoiceMeter.BUS) es aparte: lo arma el código, no sale por los parlantes y no se toca desde Opciones.
const BUS_MASTER := &"Master"
const BUS_EFFECTS := &"Efectos"
const BUS_AMBIENCE := &"Ambiente"
const BUS_MUSIC := &"Música"
const BUSES: Array[StringName] = [BUS_EFFECTS, BUS_AMBIENCE, BUS_MUSIC]

## Lo que dice la fila Sonidos del sandbox de cada clave (ver `status`).
const FILE := "ARCHIVO"
const TEST := "PRUEBA"
const SILENT := "SIN SONIDO"

## La meta que lleva cada reproductor con la clave que suena (ver `tag`): la lee la fila Sonidos para decir qué sonó.
const META_KEY := &"sound_key"

## PARA COMPARAR DE OÍDO (la fila Sonidos, tecla de fila): con esto prendido se ignoran los archivos y suena el de prueba.
static var prefer_test := false
## El último golpe que sonó: su clave, dónde y cuándo (msec). Lo lee la fila Sonidos para decir qué sonó.
static var last_key: StringName = &""
static var last_at: WeakRef = null
static var last_msec := 0

## Lo que se encontró para cada clave: el stream del archivo, o null si no hay. Se busca una vez (ver `reload`).
static var _files: Dictionary = {}

## LA MEZCLA GUARDADA (ver `mix_db` y `mix_pitch`): clave → dB, y clave → tono.
const MIX_PATH := "res://assets/audio/mezcla.cfg"
const MIX_SECTION := "db"
const PITCH_SECTION := "tono"
const MOMENT_SECTION := "momento"
const PAUSE_SECTION := "pausa"
const TRIM_SECTION := "corte"
static var _mix: Dictionary = {}
static var _pitch: Dictionary = {}
## Las claves que suenan en otro punto de su transición que al final (ver `sound_moment`): clave → 0 a 1.
static var _moment: Dictionary = {}
## Las pausas entre vuelta y vuelta de los loops (ver `loop_pause`): clave → segundos.
static var _pause: Dictionary = {}
## Los cortes de cada archivo (ver `trim_of`): ruta → Vector2(desde, hasta), en segundos; hasta 0 es hasta el final.
static var _trim: Dictionary = {}
## Los archivos ya cortados: "ruta|desde|hasta" → el stream cortado.
static var _trimmed: Dictionary = {}
static var _mix_loaded := false


# ── Pedir un sonido ───────────────────────────────────────────────────────────────────────────────────────────────

## UN GOLPE de `key` en la posición de `at`, con su volumen, su alcance y su bus. El reproductor se borra solo al
## terminar. `pitch` lo sube o lo baja (1 = como está). Una clave en loop no se pide así: ver `player`.
## `variant`: cuál de sus variantes, si la clave las tiene (ver `variants`); −1, todas al azar.
static func play(key: StringName, at: Node3D, pitch := 1.0, variant := -1) -> AudioStreamPlayer3D:
	if at == null or not at.is_inside_tree():
		return null
	var p := player(key, variant)
	if p.stream == null:
		p.free()
		return null
	p.pitch_scale *= pitch
	at.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	heard(key, at)
	return p


## UN REPRODUCTOR POSICIONAL de `key`, armado y sin colgar: lo agrega, lo prende y lo apaga quien lo pide.
static func player(key: StringName, variant := -1) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.name = String(key)
	var defaults := settings(key)
	p.stream = variant_stream(key, variant) if variant >= 0 else stream_of(key)
	p.volume_db = defaults["db"]
	p.unit_size = defaults["unit"]
	p.max_distance = defaults["max"]
	p.bus = bus_of(key)
	p.pitch_scale = test_pitch(key) * mix_pitch(key)
	tag(p, key)
	return p


## UNA NOTA de `key` —las que tienen `ref_hz` en el catálogo: la corneta, el grabador, el ding— de `hz` y `length`
## segundos en la posición de `at`: el archivo, subido o bajado de `ref_hz` a `hz`, o la nota de prueba. Se borra sola.
static func note(key: StringName, at: Node3D, hz: float, length: float) -> AudioStreamPlayer3D:
	if at == null or not at.is_inside_tree():
		return null
	var p := player(key)
	var file := file_stream(key)
	if file != null:
		p.pitch_scale = hz / float(SoundCatalog.row(key).get("ref_hz", 440.0)) * mix_pitch(key)
	else:
		var test := String(SoundCatalog.row(key).get("test", ""))
		p.stream = null if test.is_empty() else TestSounds.stream(StringName(test), hz, length)
		p.pitch_scale = 1.0
	if p.stream == null:
		p.free()
		return null
	at.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	heard(key, at)
	return p


## EL TONO CON QUE SUENA `key`: 1 con archivo; sin archivo, el que la fila le pone al de prueba sólo para distinguirlo
## de los demás de prueba (`test_pitch`: la lectora, los arcos, la expendedora, que comparten el zumbido).
static func test_pitch(key: StringName) -> float:
	if file_stream(key) != null:
		return 1.0
	return float(SoundCatalog.row(key).get("test_pitch", 1.0))


## UN REPRODUCTOR SIN POSICIÓN de `key` —se oye igual donde sea, como la cama del ambiente—, armado y sin colgar.
static func flat_player(key: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = String(key)
	p.stream = stream_of(key)
	p.volume_db = settings(key)["db"]
	p.pitch_scale = test_pitch(key) * mix_pitch(key)
	p.bus = bus_of(key)
	tag(p, key)
	return p


## Lo que suena para `key`: el archivo, o el sonido de prueba, o null si no tiene ninguno de los dos.
static func stream_of(key: StringName) -> AudioStream:
	var file := file_stream(key)
	if file != null:
		return file
	var test := String(SoundCatalog.row(key).get("test", ""))
	return null if test.is_empty() else TestSounds.stream(StringName(test))


## El bus de `key`; Efectos si la clave no existe.
static func bus_of(key: StringName) -> StringName:
	return StringName(SoundCatalog.row(key).get("bus", BUS_EFFECTS))


## El volumen, el alcance y si hace loop: lo de la fila, o lo de su sonido de prueba (ver TestSounds.KINDS). El volumen,
## el de la mezcla guardada si la clave tiene uno (ver `mix_db`).
static func settings(key: StringName) -> Dictionary:
	var row := SoundCatalog.row(key)
	var kind: Dictionary = TestSounds.KINDS.get(StringName(row.get("test", "")), {})
	return {
		"db": mix_db(key, float(row.get("db", kind.get("db", 0.0)))),
		"unit": float(row.get("unit", kind.get("unit", 10.0))),
		"max": float(row.get("max", kind.get("max", 0.0))),
		"loop": bool(row.get("loop", kind.get("loop", false))),
	}


## Marca a `p` con la clave que suena, para que la fila Sonidos sepa qué es.
static func tag(p: Node, key: StringName) -> void:
	p.set_meta(META_KEY, key)


## Anota el último golpe que sonó (ver `last_key`).
static func heard(key: StringName, at: Node) -> void:
	last_key = key
	last_at = weakref(at)
	last_msec = Time.get_ticks_msec()


# ── Los archivos ──────────────────────────────────────────────────────────────────────────────────────────────────

## El archivo de `key` como stream, o null si no hay (o si se está comparando con el de prueba). Se busca una vez: un
## archivo que se suelta con el juego andando se encuentra después de `reload`.
static func file_stream(key: StringName) -> AudioStream:
	if prefer_test:
		return null
	var id := String(key)
	if _files.has(id):
		return _files[id]
	var row := SoundCatalog.row(key)
	var found: AudioStream = null
	if not row.is_empty():
		found = _find(row)
	_files[id] = found
	return found


## DÓNDE ESTÁ EL ARCHIVO de `key` (el primero, si son varios), o dónde soltarlo si no hay (en .ogg).
static func file_path(key: StringName) -> String:
	var found := files(key)
	if not found.is_empty():
		return found[0]
	return "%s/%s.ogg" % [folder_of(key), key]


## La carpeta de los archivos de `key`: `assets/audio/<categoría>`.
static func folder_of(key: StringName) -> String:
	return "%s/%s" % [ROOT, SoundCatalog.row(key).get("category", "otros")]


## LOS ARCHIVOS DE `key`, ordenados: en su carpeta, los .ogg y .wav que se llaman como la clave o empiezan con la clave
## y un guion bajo (`ciudad_voces.ogg`, `ciudad_voces_2.ogg`, `ciudad_voces_mercado.wav`), salvo los que son de una
## clave más larga (`expendedora_cae.ogg` es de expendedora_cae, no de expendedora). Por listado y no por números: un
## archivo que se borra no deja un hueco que corte la búsqueda, y el panel de sonidos los suelta con su nombre.
##
## En una exportación la carpeta lista los `.import` y no el original: se cuentan igual.
static func files(key: StringName) -> PackedStringArray:
	var out := PackedStringArray()
	var folder := folder_of(key)
	if not DirAccess.dir_exists_absolute(folder):
		return out
	for entry: String in DirAccess.get_files_at(folder):
		var file_name := entry.trim_suffix(".import").trim_suffix(".remap")
		if not EXTENSIONS.has(file_name.get_extension()):
			continue
		var path := "%s/%s" % [folder, file_name]
		if not out.has(path) and key_of_file(file_name) == key:
			out.append(path)
	out.sort()
	return out


## DE QUÉ CLAVE ES UN ARCHIVO, por su nombre (con o sin extensión): la clave más larga que es el nombre entero o su
## comienzo seguido de un guion bajo. "" si no es de ninguna.
static func key_of_file(file_name: String) -> StringName:
	var stem := file_name.get_basename() if EXTENSIONS.has(file_name.get_extension()) else file_name
	var best := ""
	for key in SoundCatalog.keys():
		var id := String(key)
		if (stem == id or stem.begins_with(id + "_")) and id.length() > best.length():
			best = id
	return StringName(best)


## PRUEBA, ARCHIVO o SIN SONIDO: lo que suena hoy para `key`. Sin archivo, PRUEBA si cae a un sonido de prueba o a
## otra cosa provisoria (`fallback`: la melodía de notas de la radio).
static func status(key: StringName) -> String:
	if file_stream(key) != null:
		return FILE
	var row := SoundCatalog.row(key)
	return TEST if not String(row.get("test", "")).is_empty() or row.has("fallback") else SILENT


## Olvida lo encontrado: lo próximo que se pida busca de nuevo (un archivo recién soltado).
static func reload() -> void:
	_trimmed.clear()
	_files.clear()
	_variant_streams.clear()
	_playlists.clear()


# ── Las listas de canciones ───────────────────────────────────────────────────────────────────────────────────────

## Las canciones de cada clave con `playlist`, ya cargadas.
static var _playlists: Dictionary = {}


## LAS CANCIONES DE `key` (las claves con `playlist`: las emisoras), en el orden de sus nombres, cada una SIN LOOP —la
## lista entera es el loop—. Vacía sin archivos (o comparando con el de prueba).
static func playlist(key: StringName) -> Array[AudioStream]:
	var out: Array[AudioStream] = []
	if prefer_test:
		return out
	var id := String(key)
	if _playlists.has(id):
		out.assign(_playlists[id])
		return out
	for path in files(key):
		var song := load_file(path)
		if song == null or song.get_length() <= 0.0:
			continue
		# Una copia: el recurso cargado es el mismo que usa `_find`, que lo pone en loop.
		song = song.duplicate()
		if song is AudioStreamOggVorbis:
			(song as AudioStreamOggVorbis).loop = false
		elif song is AudioStreamWAV:
			(song as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
		out.append(song)
	_playlists[id] = out
	return out


## EN QUÉ CANCIÓN Y EN QUÉ SEGUNDO va la lista de `key` a la hora `time` (segundos), con la lista dando vueltas desde
## la hora cero: `{"index", "stream", "offset"}`, o vacío si no tiene canciones. Es lo que hace que todos oigan lo mismo
## (ver Radio.broadcast_time).
static func playlist_at(key: StringName, time: float) -> Dictionary:
	var songs := playlist(key)
	if songs.is_empty():
		return {}
	var total := 0.0
	for song in songs:
		total += song.get_length()
	var at := fmod(time, total)
	for i in songs.size():
		var length := songs[i].get_length()
		if at < length:
			return {"index": i, "stream": songs[i], "offset": at}
		at -= length
	return {"index": 0, "stream": songs[0], "offset": 0.0}


# ── Las variantes ─────────────────────────────────────────────────────────────────────────────────────────────────

## Cada archivo de variante ya cargado, por su ruta.
static var _variant_streams: Dictionary = {}


## LAS VARIANTES DE `key` (las claves con `variants` en el catálogo: el timbre): sus archivos, cada uno una variante con
## nombre —`timbre_dingdong.ogg` es la variante «dingdong»—. Distinto de las alternativas, que se sortean en cada golpe:
## cada objeto suena SIEMPRE con la suya (ver SoundEntity.sound_variant). Vacío si la clave no las tiene.
static func variants(key: StringName) -> PackedStringArray:
	var out := PackedStringArray()
	if not SoundCatalog.has_variants(key):
		return out
	for path in files(key):
		var stem := path.get_file().get_basename()
		out.append(stem.trim_prefix(String(key) + "_") if stem != String(key) else String(key))
	return out


## Lo que suena de la variante `index` de `key` (da la vuelta: cualquier número es una); lo de siempre si la clave no
## tiene variantes, o todavía ningún archivo.
static func variant_stream(key: StringName, index: int) -> AudioStream:
	if prefer_test or not SoundCatalog.has_variants(key):
		return stream_of(key)
	var found := files(key)
	if found.is_empty():
		return stream_of(key)
	var path := found[posmod(index, found.size())]
	if not _variant_streams.has(path):
		var stream := load_file(path)
		if stream != null and bool(SoundCatalog.row(key).get("loop", false)):
			stream = _looped(stream)
		_variant_streams[path] = stream
	return _variant_streams[path] if _variant_streams[path] != null else stream_of(key)


## Lo que suena de una fila: su archivo, o todos los suyos al azar sin repetir el anterior (ver `files`).
static func _find(row: Dictionary) -> AudioStream:
	var loop := bool(row.get("loop", TestSounds.KINDS.get(StringName(row.get("test", "")), {}).get("loop", false)))
	var versions: Array[AudioStream] = []
	for path in files(StringName(row["key"])):
		var version := load_file(path)
		if version != null:
			versions.append(_looped(version) if loop else version)
	if versions.is_empty():
		return null
	if versions.size() == 1 and not row.has("random_pitch") and not row.has("random_db"):
		return versions[0]
	var mix := AudioStreamRandomizer.new()
	mix.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS if versions.size() > 2 \
		else AudioStreamRandomizer.PLAYBACK_RANDOM
	mix.random_pitch = float(row.get("random_pitch", 1.0))
	mix.random_volume_offset_db = float(row.get("random_db", 0.0))
	for version in versions:
		mix.add_stream(-1, version)
	return mix


## UN ARCHIVO DE SONIDO, solo: uno IMPORTADO se carga como cualquier recurso; uno RECIÉN SOLTADO, que Godot todavía no
## importó (el editor importa al volver a su ventana), se lee directo del disco. En una exportación sólo existe el
## importado.
## CON SU CORTE (ver `trim_of`), salvo que se pida `whole`: una copia que empieza y termina donde dice, y como todo lo
## que suena pasa por acá, vale para los golpes, los loops, las variantes y las canciones.
static func load_file(path: String, whole := false) -> AudioStream:
	var stream := _load_whole(path)
	if whole or stream == null:
		return stream
	var cut := trim_of(path)
	if cut == Vector2.ZERO:
		return stream
	var id := "%s|%.3f|%.3f" % [path, cut.x, cut.y]
	if not _trimmed.has(id):
		_trimmed[id] = cut_stream(stream, cut.x, cut.y)
	return _trimmed[id]


static func _load_whole(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	if not FileAccess.file_exists(path):
		return null
	var absolute := ProjectSettings.globalize_path(path)
	match path.get_extension():
		"ogg":
			return AudioStreamOggVorbis.load_from_file(absolute)
		"wav":
			return AudioStreamWAV.load_from_file(absolute)
	return null


## UNA COPIA DE `stream` DE `from` A `to` SEGUNDOS (`to` 0, hasta el final): se decodifica a muestras
## (AudioStreamPlayback.mix_audio, a la frecuencia del mezclador) y se arma un .wav en memoria, estéreo de 16 bits. El
## original no se toca, y sin loop: quien lo quiere en loop se lo pone.
static func cut_stream(stream: AudioStream, from: float, to: float) -> AudioStream:
	var length := stream.get_length()
	var end := length if to <= 0.0 else minf(to, length)
	var start := clampf(from, 0.0, maxf(end - 0.01, 0.0))
	var source := unlooped(stream)
	var rate := AudioServer.get_mix_rate()
	var wanted := int((end - start) * rate)
	if wanted <= 0:
		return stream
	var playback := source.instantiate_playback()
	playback.start(start)
	var data := PackedByteArray()
	data.resize(wanted * 4)
	var at := 0
	while at < wanted:
		var chunk: PackedVector2Array = playback.mix_audio(1.0, mini(4096, wanted - at))
		if chunk.is_empty():
			break
		for frame: Vector2 in chunk:
			data.encode_s16(at * 4, int(clampf(frame.x, -1.0, 1.0) * 32767.0))
			data.encode_s16(at * 4 + 2, int(clampf(frame.y, -1.0, 1.0) * 32767.0))
			at += 1
			if at >= wanted:
				break
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = true
	wav.mix_rate = int(rate)
	wav.data = data.slice(0, at * 4)
	return wav


## UNA COPIA SIN LOOP de `stream` (el mismo si no tiene cómo hacer loop): las vueltas con pausa (ver SoundEntity, LAS
## VUELTAS) y el corte necesitan que el archivo termine.
static func unlooped(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamOggVorbis:
		var ogg := stream.duplicate() as AudioStreamOggVorbis
		ogg.loop = false
		return ogg
	if stream is AudioStreamWAV:
		var wav := stream.duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
		return wav
	return stream


## El archivo, en loop: el .ogg lo dice con una bandera; el .wav, con dónde empieza y dónde termina la vuelta.
static func _looped(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = maxi(int(wav.get_length() * wav.mix_rate) - 1, 1)
	return stream


# ── La mezcla (el panel de sonidos) ───────────────────────────────────────────────────────────────────────────────

## EL VOLUMEN DE CADA CLAVE QUE SE MOVIÓ EN EL PANEL DE SONIDOS (F1 en la fila Sonidos, ver SoundPanel), en dB: pisa
## el `db` de su fila.
## Se guarda con el botón Guardar del panel en `MIX_PATH`, y el juego arranca con esa mezcla (lo decidió el dios del
## juego el 11/10/2026). El archivo es suyo: lo escribe él desde el panel.
static func mix_db(key: StringName, otherwise: float) -> float:
	_load_mix()
	return float(_mix.get(String(key), otherwise))


static func has_mix(key: StringName) -> bool:
	_load_mix()
	return _mix.has(String(key))


## Mueve el volumen de `key` en el acto (sin guardar): lo que se pide desde ahora suena así.
static func set_mix_db(key: StringName, db: float) -> void:
	_load_mix()
	_mix[String(key)] = db


## Vuelve `key` al volumen de su fila (sin guardar).
static func clear_mix(key: StringName) -> void:
	_load_mix()
	_mix.erase(String(key))


## EL TONO DE `key` que se movió en el panel: cuánto más agudo (> 1) o más grave (< 1) suena todo lo suyo —el archivo,
## el de prueba, las notas—, multiplicando lo que ya le ponga quien lo pide. 1 si no se movió.
static func mix_pitch(key: StringName) -> float:
	_load_mix()
	return float(_pitch.get(String(key), 1.0))


## EN QUÉ PUNTO DE SU TRANSICIÓN SUENA `key`, si es de un evento con transición (ver SoundEntity, EL MOMENTO): de 0
## (al pedirlo, el clic) a 1 (al terminar, lo de siempre). Lo elige el slider de su caja en el panel.
static func sound_moment(key: StringName) -> float:
	_load_mix()
	return float(_moment.get(String(key), 1.0))


static func set_sound_moment(key: StringName, at: float) -> void:
	_load_mix()
	if at >= 1.0:
		_moment.erase(String(key))
	else:
		_moment[String(key)] = clampf(at, 0.0, 1.0)


## LA PAUSA ENTRE VUELTA Y VUELTA del loop `key`, en segundos: 0 es un loop seguido; con pausa, suena una vez entera,
## calla la pausa y vuelve (el timbre del teléfono). Ver SoundEntity, LAS VUELTAS.
static func loop_pause(key: StringName) -> float:
	_load_mix()
	return float(_pause.get(String(key), 0.0))


static func set_loop_pause(key: StringName, seconds: float) -> void:
	_load_mix()
	if seconds <= 0.0:
		_pause.erase(String(key))
	else:
		_pause[String(key)] = seconds


## EL CORTE DE UN ARCHIVO: desde qué segundo y hasta cuál suena (hasta 0, hasta el final). Vector2.ZERO, entero. El
## archivo no se toca: lo que suena es una copia cortada (ver `load_file`).
static func trim_of(path: String) -> Vector2:
	_load_mix()
	return _trim.get(path, Vector2.ZERO)


static func set_trim(path: String, trim: Vector2) -> void:
	_load_mix()
	if trim.x <= 0.0 and trim.y <= 0.0:
		_trim.erase(path)
	else:
		_trim[path] = trim


## Mueve el tono de `key` en el acto (sin guardar); 1 lo saca de la mezcla.
static func set_mix_pitch(key: StringName, pitch: float) -> void:
	_load_mix()
	if is_equal_approx(pitch, 1.0):
		_pitch.erase(String(key))
	else:
		_pitch[String(key)] = pitch


## Guarda la mezcla en `MIX_PATH`. Devuelve el error, si no se pudo escribir (un juego exportado).
static func save_mix() -> Error:
	_load_mix()
	var file := ConfigFile.new()
	var keys: Array = _mix.keys()
	keys.sort()
	for key: String in keys:
		file.set_value(MIX_SECTION, key, snappedf(float(_mix[key]), 0.1))
	var pitched: Array = _pitch.keys()
	pitched.sort()
	for key: String in pitched:
		file.set_value(PITCH_SECTION, key, snappedf(float(_pitch[key]), 0.001))
	var timed: Array = _moment.keys()
	timed.sort()
	for key: String in timed:
		file.set_value(MOMENT_SECTION, key, snappedf(float(_moment[key]), 0.01))
	var paused: Array = _pause.keys()
	paused.sort()
	for key: String in paused:
		file.set_value(PAUSE_SECTION, key, snappedf(float(_pause[key]), 0.01))
	var trimmed: Array = _trim.keys()
	trimmed.sort()
	for path: String in trimmed:
		var cut: Vector2 = _trim[path]
		file.set_value(TRIM_SECTION, path.trim_prefix(ROOT + "/"), Vector2(snappedf(cut.x, 0.001), snappedf(cut.y, 0.001)))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	return file.save(MIX_PATH)


static func _load_mix() -> void:
	if _mix_loaded:
		return
	_mix_loaded = true
	var file := ConfigFile.new()
	if file.load(MIX_PATH) != OK:
		return
	if file.has_section(MIX_SECTION):
		for key: String in file.get_section_keys(MIX_SECTION):
			_mix[key] = float(file.get_value(MIX_SECTION, key))
	if file.has_section(PITCH_SECTION):
		for key: String in file.get_section_keys(PITCH_SECTION):
			_pitch[key] = float(file.get_value(PITCH_SECTION, key))
	if file.has_section(MOMENT_SECTION):
		for key: String in file.get_section_keys(MOMENT_SECTION):
			var at: Variant = file.get_value(MOMENT_SECTION, key)
			# Antes del slider era un toggle: "al_pedir" es el clic (0); lo demás, al final.
			_moment[key] = float(at) if at is float or at is int else (0.0 if str(at) == "al_pedir" else 1.0)
	if file.has_section(PAUSE_SECTION):
		for key: String in file.get_section_keys(PAUSE_SECTION):
			_pause[key] = float(file.get_value(PAUSE_SECTION, key))
	if file.has_section(TRIM_SECTION):
		for path: String in file.get_section_keys(TRIM_SECTION):
			_trim["%s/%s" % [ROOT, path]] = file.get_value(TRIM_SECTION, path) as Vector2


# ── Los volúmenes por bus (para la pantalla de Opciones) ──────────────────────────────────────────────────────────

## El volumen de un bus, de 0 a 1 (lineal, como una perilla). 0 lo calla del todo.
static func set_volume(bus_name: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_linear(index, clampf(linear, 0.0, 1.0))
	AudioServer.set_bus_mute(index, linear <= 0.0)


static func volume(bus_name: StringName) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return AudioServer.get_bus_volume_linear(index)
