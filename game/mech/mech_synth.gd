class_name MechSynth
extends RefCounted

## LOS SONIDOS DE LA MECA, SINTETIZADOS (18/11/2026, el usuario: «sí, sintetizalos»): mientras no haya archivo en
## `assets/audio/meca/`, cada clave de MechSounds suena con uno armado acá por código, como los de los jefes (BossSounds).
## Se arman una vez, la primera vez que suena la meca (`provide_all`), y se le dan a Sounds (Sounds.provide): un archivo
## con la misma clave lo pisa. LOS CONTINUOS (LOOPS) se arman de un largo con un número entero de vueltas de cada tono,
## para que empalmen sin clic.
## EL VOLUMEN, NORMALIZADO POR NIVELES (el usuario: «hacé un proceso de normalización… determinar cuándo un sonido vale la
## pena que suene fuerte (cañón súper cargando y disparando, está bien como ahora), pero la gran mayoría son molestos tan
## fuertes»). Cada sonido se lleva a lo que se OYE (su promedio, el RMS, no su pico) del nivel de su evento (`LEVELS`,
## en dB debajo del súper, la referencia), sin pasar de `PEAK_MAX` de pico. FUERTE, sólo el súper; MEDIO, lo que tiene
## que notarse (el golpe que conecta, el misil, aterrizar fuerte); BAJO, lo que acompaña; MUY BAJO, lo que se repite
## mucho o es un aviso chico (los pasos, cada bala, los pitidos).

const RATE := 22050

## LOS NIVELES (dB debajo del súper).
const STRONG := 0.0
const MEDIUM := -12.0
const LOW := -18.0
const SOFT := -24.0
## Cada evento, su nivel (el que no está, BAJO).
const LEVELS := {
	MechSounds.CANNON_SUPER: STRONG, MechSounds.CANNON_CHARGE: STRONG + 2.5,
	MechSounds.LAND: MEDIUM, MechSounds.HURT: MEDIUM, MechSounds.STRIKE_HIT: MEDIUM, MechSounds.SPIN_STRIKE: MEDIUM,
	MechSounds.SHIELD_BLOCK: MEDIUM, MechSounds.MISSILE_BLAST: MEDIUM, MechSounds.CANNON_SHOT: MEDIUM,
	MechSounds.EMPTY: MEDIUM,
	MechSounds.JUMP: LOW, MechSounds.DASH: LOW, MechSounds.LEVITATE: LOW, MechSounds.FUEL_EMPTY: LOW,
	MechSounds.SWING: LOW, MechSounds.PUNCH_CHARGE: LOW, MechSounds.SPIN: LOW, MechSounds.CANNON_BURST: LOW,
	MechSounds.CANNON_BEAM: LOW, MechSounds.CANNON_HIT: LOW, MechSounds.MINIGUN_SPIN: LOW, MechSounds.MINIGUN_FIRE: LOW,
	MechSounds.MINIGUN_JAM: LOW, MechSounds.MISSILE_LAUNCH: LOW, MechSounds.RELOAD: LOW, MechSounds.RELOAD_GOOD: LOW,
	MechSounds.RELOAD_BAD: LOW,
	MechSounds.STEP: SOFT, MechSounds.BULLET_HIT: SOFT, MechSounds.BEAM_HIT: SOFT, MechSounds.ABILITY_READY: SOFT,
	MechSounds.LOCK: SOFT,
}
## Lo que se oye del súper (RMS, 0 a 1): la referencia, el volumen que tenía antes de normalizar (el usuario: «está bien
## como ahora»). Y el pico más alto que puede tener cualquiera.
const REFERENCE_RMS := 0.13
const PEAK_MAX := 0.9

static var _done := false


## LE DA A Sounds todos los de MechSounds (una vez).
static func provide_all() -> void:
	if _done:
		return
	_done = true
	for event: StringName in MechSounds.SOUNDS:
		var made := build(event)
		if made != null:
			Sounds.provide(MechSounds.SOUNDS[event], made)


## EL DE `event` (ver MechSounds), o null si no tiene receta.
static func build(event: StringName) -> AudioStreamWAV:
	var noise := RandomNumberGenerator.new()
	noise.seed = hash(event)
	var low := [0.0]
	# Ruido pasado por un filtro de un polo: `amount` cerca de 0, más grave.
	var rumble := func(amount: float) -> float:
		low[0] = lerpf(float(low[0]), noise.randf_range(-1.0, 1.0), amount)
		return float(low[0])
	match event:
		# ── LA MECA ──
		MechSounds.LAND:
			return _make(_render(0.5, func(t: float, phase: float) -> float:
				return sin(phase) * exp(-t * 9.0) + rumble.call(0.25) * exp(-t * 14.0) * 1.6,
				func(t: float) -> float: return lerpf(70.0, 34.0, minf(t / 0.25, 1.0))), event)
		MechSounds.STEP:
			return _make(_render(0.22, func(t: float, phase: float) -> float:
				return sin(phase) * exp(-t * 22.0) + rumble.call(0.3) * exp(-t * 30.0) + sin(phase * 7.3) * exp(-t * 40.0) * 0.2,
				func(_t: float) -> float: return 55.0), event)
		MechSounds.JUMP:
			return _make(_render(0.32, func(t: float, phase: float) -> float:
				return rumble.call(0.35) * exp(-t * 10.0) + sin(phase) * exp(-t * 8.0) * 0.6,
				func(t: float) -> float: return lerpf(60.0, 140.0, t / 0.32)), event)
		MechSounds.DASH:
			return _make(_render(0.45, func(t: float, _phase: float) -> float:
				return rumble.call(lerpf(0.05, 0.5, sin(t / 0.45 * PI))) * sin(t / 0.45 * PI) * 1.6,
				func(_t: float) -> float: return 1.0), event)
		MechSounds.LEVITATE:
			return _make(_render(1.0, func(_t: float, phase: float) -> float:
				return rumble.call(0.2) * 1.4 + sin(phase) * 0.3,
				func(_t: float) -> float: return 50.0), event, true)
		MechSounds.FUEL_EMPTY:
			return _make(_render(0.45, func(t: float, _phase: float) -> float:
				var pop := fmod(t, 0.15)
				return rumble.call(0.4) * exp(-pop * 40.0) * (1.0 - t / 0.45),
				func(_t: float) -> float: return 1.0), event)
		MechSounds.EMPTY:
			return _make(_render(0.9, func(t: float, phase: float) -> float:
				return (sin(phase) + sin(phase * 2.0) * 0.3) * exp(-t * 3.0),
				func(t: float) -> float: return lerpf(420.0, 55.0, minf(t / 0.8, 1.0))), event)
		MechSounds.HURT:
			return _make(_render(0.45, func(t: float, phase: float) -> float:
				return (sin(phase) + sin(phase * 2.31) * 0.6 + sin(phase * 4.87) * 0.3) * exp(-t * 10.0) \
					+ rumble.call(0.5) * exp(-t * 25.0),
				func(_t: float) -> float: return 120.0), event)
		# ── LOS BRAZOS ──
		MechSounds.SWING:
			return _make(_render(0.25, func(t: float, _phase: float) -> float:
				return rumble.call(0.25) * sin(t / 0.25 * PI) * 1.5,
				func(_t: float) -> float: return 1.0), event)
		MechSounds.PUNCH_CHARGE:
			return _make(_render(0.5, func(_t: float, phase: float) -> float:
				return sin(phase) * 0.6 + sin(phase * 2.0) * 0.25,
				func(_t: float) -> float: return 180.0), event, true)
		MechSounds.STRIKE_HIT:
			return _make(_render(0.3, func(t: float, phase: float) -> float:
				return sin(phase) * exp(-t * 14.0) + rumble.call(0.6) * exp(-t * 40.0) * 0.7,
				func(t: float) -> float: return lerpf(110.0, 50.0, minf(t / 0.15, 1.0))), event)
		MechSounds.SPIN:
			return _make(_render(0.5, func(_t: float, phase: float) -> float:
				return _saw(phase) * 0.5 + sin(phase * 3.0) * 0.2 + rumble.call(0.5) * 0.15,
				func(_t: float) -> float: return 120.0), event, true)
		MechSounds.SPIN_STRIKE:
			return _make(_render(0.4, func(t: float, phase: float) -> float:
				return (_saw(phase) * 0.6 + rumble.call(0.7) * 0.6) * exp(-t * 6.0),
				func(_t: float) -> float: return 240.0), event)
		MechSounds.SHIELD_BLOCK:
			return _make(_render(0.5, func(t: float, phase: float) -> float:
				return (sin(phase) + sin(phase * 2.76) * 0.6 + sin(phase * 5.4) * 0.3) * exp(-t * 8.0),
				func(_t: float) -> float: return 520.0), event)
		# ── EL CAÑÓN ──
		MechSounds.CANNON_SHOT:
			return _make(_render(0.25, func(t: float, phase: float) -> float:
				return _square(phase) * exp(-t * 12.0),
				func(t: float) -> float: return lerpf(900.0, 180.0, t / 0.25)), event)
		MechSounds.CANNON_BURST:
			return _make(_render(0.1, func(t: float, phase: float) -> float:
				return _square(phase) * exp(-t * 30.0),
				func(t: float) -> float: return lerpf(1100.0, 400.0, t / 0.1)), event)
		MechSounds.CANNON_BEAM:
			return _make(_render(0.5, func(_t: float, phase: float) -> float:
				return _saw(phase) * 0.5 + sin(phase * 2.0) * 0.3 * sin(phase / 140.0 * 12.0),
				func(_t: float) -> float: return 140.0), event, true)
		MechSounds.BEAM_HIT:
			return _make(_render(0.5, func(_t: float, _phase: float) -> float:
				return rumble.call(0.9) * 0.8,
				func(_t: float) -> float: return 1.0), event, true)
		MechSounds.CANNON_CHARGE:
			return _make(_render(0.5, func(_t: float, phase: float) -> float:
				return sin(phase) * 0.6 + _saw(phase * 2.0) * 0.15,
				func(_t: float) -> float: return 300.0), event, true)
		MechSounds.CANNON_SUPER:
			return _make(_render(1.0, func(t: float, phase: float) -> float:
				return _square(phase) * exp(-t * 4.0) * 0.6 + rumble.call(0.15) * exp(-t * 3.0) * 1.8,
				func(t: float) -> float: return lerpf(600.0, 60.0, minf(t / 0.5, 1.0))), event)
		MechSounds.CANNON_HIT:
			return _make(_render(0.18, func(t: float, phase: float) -> float:
				return sin(phase) * exp(-t * 25.0) + rumble.call(0.5) * exp(-t * 30.0) * 0.5,
				func(t: float) -> float: return lerpf(300.0, 90.0, t / 0.18)), event)
		# ── EL ARTILLERO ──
		MechSounds.MINIGUN_SPIN:
			return _make(_render(0.5, func(_t: float, phase: float) -> float:
				return sin(phase) * 0.5 + sin(phase * 4.0) * 0.2 + rumble.call(0.3) * 0.2,
				func(_t: float) -> float: return 90.0), event, true)
		MechSounds.MINIGUN_FIRE:
			# Tiros seguidos: 15 por medio segundo (empalma), cada uno un estallido corto.
			return _make(_render(0.5, func(t: float, _phase: float) -> float:
				var since := fmod(t, 0.5 / 15.0)
				return rumble.call(0.6) * exp(-since * 120.0) * 1.5,
				func(_t: float) -> float: return 1.0), event, true)
		MechSounds.BULLET_HIT:
			return _make(_render(0.06, func(t: float, phase: float) -> float:
				return (sin(phase) * 0.5 + rumble.call(0.8) * 0.5) * exp(-t * 70.0),
				func(_t: float) -> float: return 1400.0), event)
		MechSounds.MINIGUN_JAM:
			return _make(_render(0.55, func(t: float, phase: float) -> float:
				return (sin(phase) + sin(phase * 2.3) * 0.5) * exp(-t * 18.0) + rumble.call(0.7) * smoothstep(0.1, 0.2, t) \
					* exp(-maxf(t - 0.2, 0.0) * 6.0) * 0.5,
				func(_t: float) -> float: return 180.0), event)
		MechSounds.MISSILE_LAUNCH:
			return _make(_render(0.7, func(t: float, _phase: float) -> float:
				return rumble.call(0.35) * minf(t * 30.0, 1.0) * exp(-t * 3.5) * 1.6,
				func(_t: float) -> float: return 1.0), event)
		MechSounds.MISSILE_BLAST:
			return _make(_render(1.3, func(t: float, phase: float) -> float:
				return rumble.call(0.08) * exp(-t * 2.5) * 2.5 + sin(phase) * exp(-t * 6.0) * 0.6,
				func(t: float) -> float: return lerpf(60.0, 30.0, t / 1.3)), event)
		# ── LA RECARGA Y LOS AVISOS DEL ARTILLERO ──
		MechSounds.RELOAD:
			return _make(_render(0.35, func(t: float, phase: float) -> float:
				var click := fmod(t, 0.175)
				return (sin(phase) + rumble.call(0.8) * 0.6) * exp(-click * 60.0),
				func(_t: float) -> float: return 700.0), event)
		MechSounds.RELOAD_GOOD:
			return _make(_render(0.4, func(t: float, phase: float) -> float:
				return sin(phase) * exp(-t * 7.0),
				func(t: float) -> float: return 880.0 if t < 0.1 else 1320.0), event)
		MechSounds.RELOAD_BAD:
			return _make(_render(0.35, func(t: float, phase: float) -> float:
				return _square(phase) * 0.5 * exp(-t * 4.0),
				func(_t: float) -> float: return 110.0), event)
		MechSounds.ABILITY_READY:
			return _make(_render(0.45, func(t: float, phase: float) -> float:
				return (sin(phase) + sin(phase * 1.5) * 0.5) * exp(-t * 6.0),
				func(_t: float) -> float: return 1046.0), event)
		MechSounds.LOCK:
			return _make(_render(0.26, func(t: float, phase: float) -> float:
				return sin(phase) * (1.0 if fmod(t, 0.13) < 0.07 else 0.0),
				func(_t: float) -> float: return 1500.0), event)
	return null


## Un diente de sierra y una cuadrada, de la fase.
static func _saw(phase: float) -> float:
	return fmod(phase / TAU, 1.0) * 2.0 - 1.0


static func _square(phase: float) -> float:
	return 1.0 if fmod(phase / TAU, 1.0) < 0.5 else -1.0


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


## EL SONIDO de `event`, a su nivel (ver `LEVELS`); si es un continuo, con su vuelta marcada de punta a punta.
static func _make(samples: PackedFloat32Array, event: StringName, looped := false) -> AudioStreamWAV:
	var gain := level_gain(samples, float(LEVELS.get(event, LOW)))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for index in samples.size():
		data.encode_s16(index * 2, int(clampf(samples[index] * gain, -1.0, 1.0) * 32767.0))
	var made := AudioStreamWAV.new()
	made.format = AudioStreamWAV.FORMAT_16_BITS
	made.mix_rate = RATE
	made.stereo = false
	made.data = data
	if looped:
		made.loop_begin = 0
		made.loop_end = samples.size()
		made.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return made


## POR CUÁNTO MULTIPLICAR `samples` para que se oigan `level` dB debajo de la referencia: lo que da su RMS, recortado
## para que el pico no pase de PEAK_MAX.
static func level_gain(samples: PackedFloat32Array, level: float) -> float:
	var peak := 0.0001
	var power := 0.0
	for sample in samples:
		peak = maxf(peak, absf(sample))
		power += sample * sample
	var rms := sqrt(power / maxf(samples.size(), 1))
	return minf(REFERENCE_RMS * db_to_linear(level) / maxf(rms, 0.00001), PEAK_MAX / peak)


## LO QUE SE OYE DE UN SONIDO YA ARMADO (RMS, dB): para las pruebas.
static func loudness(stream: AudioStreamWAV) -> float:
	var data := stream.data
	var power := 0.0
	var count := data.size() / 2
	for index in count:
		var sample := data.decode_s16(index * 2) / 32767.0
		power += sample * sample
	return linear_to_db(sqrt(power / maxf(count, 1)))
