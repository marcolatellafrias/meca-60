class_name TestSounds

## SONIDOS DE PRUEBA — generados por código, sin archivos, y rudimentarios a propósito: sirven para comprobar que las
## cosas suenan donde y cuando tienen que sonar. Son LA CAÍDA del registro por clave (ver Sounds): una clave sin
## archivo suena con el de prueba que dice su fila del catálogo (ver SoundCatalog), y el día que todas tengan el suyo
## esto queda sin uso. Nadie los pide directo: los objetos piden por sus eventos (ver SoundEntity).
##
## NO hay FMOD en el proyecto —no está entre los addons y su GDExtension necesita el SDK propietario—: todo es el audio
## de Godot. Hubo también un zumbido de fondo de ciudad; se sacó porque molestaba (el ambiente de ahora es CityAmbience,
## con archivos, y en silencio mientras no los haya).

const MIX_RATE := 22050
## Hasta dónde se oye un motor: más lejos, el reproductor ni suena (ver CarManager._update_visual).
const ENGINE_MAX_DISTANCE := 260.0

## LOS OCHO SONIDOS DE PRUEBA y cómo suena cada uno: volumen, alcance (`unit` es el `unit_size`; `max` 0 es sin límite,
## que se mezcla por lejos que esté) y si hace loop. Una clave sin volumen propio usa el de su sonido de prueba.
const KINDS := {
	&"click": {"db": -6.0, "unit": 10.0, "max": 0.0, "loop": false, "what": "un clic de tecla (1,8 kHz, 25 ms)"},
	&"buzz": {"db": -6.0, "unit": 10.0, "max": 0.0, "loop": false, "what": "un zumbido de error (cuadrada de 110 Hz)"},
	&"hum": {"db": -12.0, "unit": 10.0, "max": 0.0, "loop": true, "what": "un zumbido grave (110 Hz y dos armónicos)"},
	&"engine": {"db": -10.0, "unit": 20.0, "max": ENGINE_MAX_DISTANCE, "loop": true,
		"what": "un motor (diente de sierra de 92 Hz con golpeteo)"},
	&"ring": {"db": -8.0, "unit": 3.0, "max": 14.0, "loop": true, "what": "un timbre de campanillas (440 + 480 Hz)"},
	&"siren": {"db": -10.0, "unit": 6.0, "max": 30.0, "loop": true, "what": "una sirena (sube y baja de 600 a 900 Hz)"},
	&"static": {"db": -14.0, "unit": 4.0, "max": 25.0, "loop": true, "what": "estática de radio (ruido con crujidos)"},
	&"horn": {"db": -8.0, "unit": 4.0, "max": 25.0, "loop": false, "what": "una nota de corneta de bronce"},
}

static var _click: AudioStreamWAV = null
static var _hum: AudioStreamWAV = null
static var _engine: AudioStreamWAV = null
static var _ring: AudioStreamWAV = null
static var _siren: AudioStreamWAV = null
static var _buzz: AudioStreamWAV = null
static var _static: AudioStreamWAV = null
## Los tonos de bocina, por frecuencia redondeada (ver `horn`).
static var _horns: Dictionary = {}


## EL SONIDO DE PRUEBA `kind` (ver KINDS), armado la primera vez que se pide. La corneta es una nota: `hz` y `length`.
static func stream(kind: StringName, hz := 440.0, length := 0.3) -> AudioStream:
	match kind:
		&"click":
			if _click == null:
				_click = _make_click()
			return _click
		&"buzz":
			if _buzz == null:
				_buzz = _make_buzz()
			return _buzz
		&"hum":
			if _hum == null:
				_hum = _make_hum()
			return _hum
		&"engine":
			if _engine == null:
				_engine = _make_engine()
			return _engine
		&"ring":
			if _ring == null:
				_ring = _make_ring()
			return _ring
		&"siren":
			if _siren == null:
				_siren = _make_siren()
			return _siren
		&"static":
			if _static == null:
				_static = _make_static()
			return _static
		&"horn":
			var key := "%d|%d" % [roundi(hz), roundi(length * 100.0)]
			if not _horns.has(key):
				_horns[key] = _make_horn(hz, length)
			return _horns[key]
	return null


## Una bocina de bronce: diente de sierra con un vibrato apenas audible, un ataque corto y una caída al final —sin
## eso el corte chasquea—. Los armónicos altos se atenúan más que 1/h: suena a lengüeta, no a sintetizador.
static func _make_horn(frequency: float, length: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(MIX_RATE * length))
	var phase := 0.0
	for i in samples.size():
		var t := float(i) / MIX_RATE
		phase += (frequency * (1.0 + 0.006 * sin(TAU * 5.5 * t))) / MIX_RATE
		var value := 0.0
		for harmonic in range(1, 7):
			value += sin(TAU * phase * float(harmonic)) / pow(float(harmonic), 1.3)
		var envelope := minf(t / 0.03, 1.0) * minf((length - t) / 0.06, 1.0)
		samples[i] = value * 0.3 * clampf(envelope, 0.0, 1.0)
	return _wav(samples, false)


## 25 ms de un tono de 1.8 kHz que se apaga enseguida: suena a tecla.
static func _make_click() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(MIX_RATE * 0.025))
	for i in samples.size():
		var t := float(i) / MIX_RATE
		samples[i] = sin(TAU * 1800.0 * t) * exp(-t * 250.0)
	return _wav(samples, false)


## Un segundo de 110 Hz con dos armónicos. Frecuencias enteras en un segundo exacto: el final empalma con
## el principio y el loop no chasquea.
static func _make_hum() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(MIX_RATE)
	for i in samples.size():
		var t := float(i) / MIX_RATE
		samples[i] = 0.5 * sin(TAU * 110.0 * t) + 0.25 * sin(TAU * 220.0 * t) + 0.12 * sin(TAU * 330.0 * t)
	return _wav(samples, true)


## Un segundo de motor rudimentario. La fundamental es de 92 Hz y no de 55 porque a 55 el sonido se lo come
## el parlante —uno de notebook no baja de ~150 Hz— y lo único que llega son los armónicos. Diente de sierra —armónicos
## con peso 1/h— porque es lo que suena a explosión y no a flauta, y un golpeteo de 23 Hz encima, como una
## combustión despareja. 92 y 23 son enteros: el segundo cierra justo y el loop no chasquea.
static func _make_engine() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(MIX_RATE)
	for i in samples.size():
		var t := float(i) / MIX_RATE
		var value := 0.0
		for harmonic in range(1, 9):
			value += sin(TAU * 92.0 * float(harmonic) * t) / float(harmonic)
		samples[i] = value * 0.32 * (0.75 + 0.25 * sin(TAU * 23.0 * t))
	return _wav(samples, true)


## Dos segundos de timbre: dos golpes de campanilla (440 + 480 Hz, batidos por un martillo de 20 Hz) y un
## silencio. Todo entero en dos segundos exactos: el loop empalma sin clic.
static func _make_ring() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(MIX_RATE * 2)
	for i in samples.size():
		var t := float(i) / MIX_RATE
		var on := t < 0.4 or (t >= 0.6 and t < 1.0)
		if not on:
			samples[i] = 0.0
			continue
		var clapper := 0.65 + 0.35 * sin(TAU * 20.0 * t)
		samples[i] = (0.4 * sin(TAU * 440.0 * t) + 0.4 * sin(TAU * 480.0 * t)) * clapper
	return _wav(samples, true)


## Dos segundos de sirena: un tono que sube y baja entre 600 y 900 Hz. La fase es la integral de la frecuencia,
## 750·t − (150/π)·cos(π·t), y a los dos segundos da 1500 vueltas justas: el loop empalma sin clic.
static func _make_siren() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(MIX_RATE * 2)
	for i in samples.size():
		var t := float(i) / MIX_RATE
		var phase := 750.0 * t - (150.0 / PI) * cos(PI * t) + 150.0 / PI
		samples[i] = 0.45 * sin(TAU * phase)
	return _wav(samples, true)


## 0,3 s de una onda cuadrada de 110 Hz que se apaga: el zumbido de "eso no era".
static func _make_buzz() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(MIX_RATE * 0.3))
	for i in samples.size():
		var t := float(i) / MIX_RATE
		samples[i] = 0.35 * signf(sin(TAU * 110.0 * t)) * (1.0 - t / 0.3)
	return _wav(samples, false)


## Dos segundos de ruido blanco suavizado —un filtro de un polo le saca lo más agudo—, con crujidos sueltos: suena a
## válvula buscando. La semilla es fija, así que es siempre la misma estática. Empieza y termina en cero, para que el
## loop no chasquee.
static func _make_static() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1920
	var samples := PackedFloat32Array()
	samples.resize(int(MIX_RATE * 2.0))
	var smooth := 0.0
	for i in samples.size():
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.35)
		var crackle := rng.randf_range(-1.0, 1.0) if rng.randf() < 0.0015 else 0.0
		var edge := minf(float(i), float(samples.size() - 1 - i)) / (MIX_RATE * 0.01)
		samples[i] = (smooth * 0.5 + crackle * 0.6) * clampf(edge, 0.0, 1.0)
	return _wav(samples, true)


static func _wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		# UNA MENOS que el tamaño: `loop_end` es un ÍNDICE de muestra, no una cantidad. Apuntando a
		# `size()` el mezclador lee una muestra fuera del buffer en cada vuelta, y eso es un CLIC
		# periódico —el "tac, tac" que se escuchaba en los tres sonidos, el zumbido de la meca incluido—.
		wav.loop_end = samples.size() - 1
	return wav
