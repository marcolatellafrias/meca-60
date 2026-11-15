class_name BossSounds
extends RefCounted

## LOS SONIDOS DE LA PELEA CON LOS JEFES (15/11/2026): sintetizados por código (no hay archivos de audio todavía), cada
## uno armado una vez y guardado. Son AVISOS para el oído, como en los jefes de Souls: el golpe que entra, el derribo,
## el agarre, el aviso de cada ataque y el cambio de ira (el usuario: «tal vez una audio cue… audio cues para las
## distintas etapas de ira o no ira del boss»). Se tocan en un punto del mundo y se van solos.

enum Kind { HIT, KNOCKDOWN, LAND, GRAB, WINDUP, RAGE_ON, RAGE_OFF, FLAME }

const RATE := 22050
## Hasta dónde se oye (m) y a qué distancia empieza a bajar: todo es enorme.
const UNIT := 40.0

static var _made := {}


## TOCA `kind` en `at` (mundo), colgado de `parent`.
static func play(kind: Kind, at: Vector3, parent: Node, volume_db := 0.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream(kind)
	player.unit_size = UNIT
	player.max_db = 6.0
	player.volume_db = volume_db
	parent.add_child(player)
	player.global_position = at
	player.finished.connect(player.queue_free)
	player.play()


## El sonido de `kind` (se arma la primera vez).
static func stream(kind: Kind) -> AudioStreamWAV:
	if not _made.has(kind):
		_made[kind] = _build(kind)
	return _made[kind]


static func _build(kind: Kind) -> AudioStreamWAV:
	var noise := RandomNumberGenerator.new()
	noise.seed = 7 + int(kind)
	var samples := PackedFloat32Array()
	match kind:
		Kind.HIT:
			# Un golpe seco: un bombo que baja (90 a 40 Hz) y un chasquido de ruido al principio.
			samples = _render(0.35, func(t: float, phase: float) -> float:
				return sin(phase) * exp(-t * 11.0) + noise.randf_range(-1.0, 1.0) * exp(-t * 45.0) * 0.6,
				func(t: float) -> float: return lerpf(90.0, 40.0, minf(t / 0.2, 1.0)))
		Kind.KNOCKDOWN:
			# Más pesado y largo: un bombo hondo con un crujido de metal.
			samples = _render(0.7, func(t: float, phase: float) -> float:
				return sin(phase) * exp(-t * 5.0) + sin(phase * 3.7) * exp(-t * 9.0) * 0.35 \
					+ noise.randf_range(-1.0, 1.0) * exp(-t * 18.0) * 0.5,
				func(t: float) -> float: return lerpf(70.0, 32.0, minf(t / 0.4, 1.0)))
		Kind.LAND:
			# Caer al piso: ruido sordo.
			samples = _render(0.5, func(t: float, phase: float) -> float:
				return sin(phase) * exp(-t * 7.0) * 0.8 + noise.randf_range(-1.0, 1.0) * exp(-t * 12.0) * 0.4,
				func(_t: float) -> float: return 45.0)
		Kind.GRAB:
			# Un clanc de metal: dos tonos que no combinan, cortos.
			samples = _render(0.45, func(t: float, phase: float) -> float:
				return (sin(phase) + sin(phase * 2.76) * 0.7 + sin(phase * 5.4) * 0.3) * exp(-t * 9.0) * 0.6,
				func(_t: float) -> float: return 310.0)
		Kind.WINDUP:
			# El aviso de un ataque: un zumbido que sube.
			samples = _render(0.6, func(t: float, phase: float) -> float:
				return (sin(phase) + sin(phase * 2.0) * 0.4) * minf(t * 8.0, 1.0) * exp(-maxf(t - 0.4, 0.0) * 12.0) * 0.5,
				func(t: float) -> float: return lerpf(110.0, 260.0, t / 0.6))
		Kind.RAGE_ON:
			# LA IRA: un bramido grave de serrucho con temblor, que crece.
			samples = _render(1.6, func(t: float, phase: float) -> float:
				var saw := fmod(phase / TAU, 1.0) * 2.0 - 1.0
				return saw * minf(t * 2.5, 1.0) * exp(-maxf(t - 1.1, 0.0) * 6.0) * 0.55,
				func(t: float) -> float: return 52.0 + sin(t * 38.0) * 4.0 + t * 10.0)
		Kind.RAGE_OFF:
			# SE CALMA: un tono que baja y un soplido de vapor.
			samples = _render(1.2, func(t: float, phase: float) -> float:
				return sin(phase) * exp(-t * 3.0) * 0.5 + noise.randf_range(-1.0, 1.0) * sin(minf(t / 1.2, 1.0) * PI) * 0.25,
				func(t: float) -> float: return lerpf(220.0, 70.0, t / 1.2))
	if kind == Kind.FLAME:
		# EL LANZALLAMAS: un rugido de ruido grave, parejo, que se apaga al final.
		var low := 0.0
		samples = _render(2.4, func(t: float, phase: float) -> float:
			low = lerpf(low, noise.randf_range(-1.0, 1.0), 0.12)
			return (low * 2.2 + sin(phase) * 0.25) * minf(t * 6.0, 1.0) * clampf((2.4 - t) * 3.0, 0.0, 1.0) * 0.6,
			func(_t: float) -> float: return 60.0)
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for index in samples.size():
		data.encode_s16(index * 2, int(clampf(samples[index], -1.0, 1.0) * 30000.0))
	var made := AudioStreamWAV.new()
	made.format = AudioStreamWAV.FORMAT_16_BITS
	made.mix_rate = RATE
	made.stereo = false
	made.data = data
	return made


## `seconds` de sonido: `wave(t, fase)` con la frecuencia `pitch(t)` (Hz).
static func _render(seconds: float, wave: Callable, pitch: Callable) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	var phase := 0.0
	for index in out.size():
		var t := float(index) / RATE
		phase += TAU * float(pitch.call(t)) / RATE
		out[index] = float(wave.call(t, phase))
	return out
