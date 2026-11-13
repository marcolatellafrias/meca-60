class_name Sounds

## LOS SONIDOS, POR CLAVE: un sonido se pide por su clave y suena el archivo `assets/audio/<carpeta>/<clave>….ogg` (o
## `.wav`) que empiece con ella. Si hay varios (`perilla_1.ogg`, `perilla_metal.ogg`), se sortea uno cada vez. Sin
## archivo suena un clic corto de prueba, para saber que algo pidió sonar. Todo va por el bus principal.
##
##     Sounds.play(&"perilla", self)                 # un golpe donde está `self`; se borra solo
##     var loop := Sounds.loop(&"rueda_sola", self)   # un loop: quien lo pide lo frena (`queue_free`)
##
## Los objetos no piden acá sino por sus eventos (ver SoundEntity). *Hasta el 13/11/2026 era el sistema de
## character-parametric: catálogo con título y uso de cada clave, buses, mezcla guardada, alternativas, variantes, listas
## de canciones, notas afinadas y sonidos de prueba sintetizados, unas 1.750 líneas para un juego sin sonidos todavía. El
## usuario lo pidió simple.*

const ROOT := "res://assets/audio"
const EXTENSIONS := ["ogg", "wav"]
## Hasta dónde se oye un golpe (metros, el `unit_size` de Godot: a esa distancia, el volumen de referencia).
const UNIT_SIZE := 3.0
## El clic de prueba: largo y tono.
const TEST_SECONDS := 0.04
const TEST_HZ := 1800.0

## clave → rutas de sus archivos (se arma una vez).
static var _files: Dictionary = {}
static var _scanned := false
static var _test: AudioStreamWAV = null


## UN GOLPE de `key` en `at`: suena una vez y se borra. null si `at` no está en el árbol.
static func play(key: StringName, at: Node3D, pitch := 1.0, volume := 1.0) -> AudioStreamPlayer3D:
	var player := _player(key, at, pitch, volume, false)
	if player != null:
		player.finished.connect(player.queue_free)
	return player


## UN LOOP de `key` en `at`, ya sonando: lo frena quien lo pidió (`queue_free`).
static func loop(key: StringName, at: Node3D, pitch := 1.0, volume := 1.0) -> AudioStreamPlayer3D:
	return _player(key, at, pitch, volume, true)


static func _player(key: StringName, at: Node3D, pitch: float, volume: float, looped: bool) -> AudioStreamPlayer3D:
	if not is_instance_valid(at) or not at.is_inside_tree():
		return null
	var player := AudioStreamPlayer3D.new()
	player.stream = _stream(key, looped)
	player.unit_size = UNIT_SIZE
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(maxf(volume, 0.0001))
	at.add_child(player)
	player.play()
	return player


## El archivo de `key` (uno al azar si hay varios), o el clic de prueba.
static func _stream(key: StringName, looped: bool) -> AudioStream:
	if not _scanned:
		_scan(ROOT)
		_scanned = true
	var paths: Array = _files.get(String(key), [])
	if paths.is_empty():
		return _test_click()
	var stream := load(paths[randi() % paths.size()]) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = looped
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if looped else AudioStreamWAV.LOOP_DISABLED
	return stream


## Recorre las carpetas de audio y anota cada archivo bajo las claves que lo nombran: `perilla_metal.ogg` es de
## `perilla_metal` y de `perilla`.
static func _scan(folder: String) -> void:
	for file in DirAccess.get_files_at(folder):
		if not file.get_extension() in EXTENSIONS:
			continue
		var name := file.get_basename()
		var parts := name.split("_")
		for count in range(1, parts.size() + 1):
			var key := "_".join(parts.slice(0, count))
			if not _files.has(key):
				_files[key] = []
			(_files[key] as Array).append(folder + "/" + file)
	for sub in DirAccess.get_directories_at(folder):
		if not sub.begins_with("_"):
			_scan(folder + "/" + sub)


## El clic corto de prueba: un seno que se apaga.
static func _test_click() -> AudioStreamWAV:
	if _test != null:
		return _test
	var rate := 22050
	var count := int(TEST_SECONDS * rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / rate
		var sample := sin(TAU * TEST_HZ * t) * (1.0 - float(i) / count) * 0.4
		data.encode_s16(i * 2, int(sample * 32767.0))
	_test = AudioStreamWAV.new()
	_test.format = AudioStreamWAV.FORMAT_16_BITS
	_test.mix_rate = rate
	_test.data = data
	return _test
