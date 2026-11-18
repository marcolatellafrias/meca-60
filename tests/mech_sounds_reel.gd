extends Node

## LOS SONIDOS DE LA MECA, DE A UNO (18/11/2026; ver MechSounds, MechSynth): cada evento, numerado y con su nombre y su nivel en
## pantalla, suena solo (los continuos, `LOOP_TIME` s, con su tono subiendo como sube en el juego). Para escucharlos
## desde el teléfono. Se graba (el .avi lleva el sonido):
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/sonidos.avi --fixed-fps 30 res://tests/mech_sounds_reel.tscn

const GAP := 0.6
const LOOP_TIME := 2.0
## Los nombres, en el orden de la lista repasada con el usuario.
const NAMES := {
	MechSounds.LAND: "aterrizar", MechSounds.STEP: "paso", MechSounds.JUMP: "saltar", MechSounds.DASH: "dash",
	MechSounds.LEVITATE: "levitar (continuo)", MechSounds.FUEL_EMPTY: "propulsor vacío",
	MechSounds.EMPTY: "sin energía", MechSounds.HURT: "la meca recibe un golpe",
	MechSounds.SWING: "piña al aire", MechSounds.PUNCH_CHARGE: "piña cargándose (continuo, sube)",
	MechSounds.STRIKE_HIT: "golpe que conecta", MechSounds.SPIN: "taladro o sierra girando (continuo, sube)",
	MechSounds.SPIN_STRIKE: "directo del taladro o la sierra", MechSounds.SHIELD_BLOCK: "escudo frena",
	MechSounds.CANNON_SHOT: "cañón: tiro simple", MechSounds.CANNON_BURST: "cañón: ráfaga",
	MechSounds.CANNON_BEAM: "cañón: rayo (continuo)", MechSounds.BEAM_HIT: "rayo pegando (continuo)",
	MechSounds.CANNON_CHARGE: "cañón: cargando el súper (continuo, sube)", MechSounds.CANNON_SUPER: "cañón: súper",
	MechSounds.CANNON_HIT: "tiro del cañón que pega", MechSounds.MINIGUN_SPIN: "minigun girando (continuo, sube)",
	MechSounds.MINIGUN_FIRE: "minigun disparando (continuo)", MechSounds.BULLET_HIT: "bala que pega",
	MechSounds.MINIGUN_JAM: "minigun trabada", MechSounds.MISSILE_LAUNCH: "misil sale",
	MechSounds.MISSILE_BLAST: "misil explota", MechSounds.RELOAD: "empezar a recargar",
	MechSounds.RELOAD_GOOD: "recarga bien hecha", MechSounds.RELOAD_BAD: "recarga trabada",
	MechSounds.ABILITY_READY: "habilidad lista", MechSounds.LOCK: "blanco fijado",
}
## Los continuos cuyo tono sube en el juego (con el giro, la carga).
const RISING := [MechSounds.PUNCH_CHARGE, MechSounds.SPIN, MechSounds.CANNON_CHARGE, MechSounds.MINIGUN_SPIN]

var _title: Label = null


func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color(0.12, 0.13, 0.15)
	back.size = Vector2(4000, 4000)
	add_child(back)
	_title = Label.new()
	_title.position = Vector2(40, 200)
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color.WHITE)
	add_child(_title)
	MechSynth.provide_all()
	await get_tree().create_timer(0.5).timeout
	var number := 0
	for event: StringName in NAMES:
		number += 1
		var made := MechSynth.build(event)
		var level := float(MechSynth.LEVELS.get(event, MechSynth.LOW))
		var tier: String = {MechSynth.STRONG: "fuerte", MechSynth.MEDIUM: "medio", MechSynth.LOW: "bajo",
			MechSynth.SOFT: "muy bajo"}.get(level, "fuerte")
		_title.text = "%d. %s\n%s" % [number, NAMES[event], tier]
		print("%2d. %-45s %-9s se oye a %5.1f dB" % [number, NAMES[event], tier, MechSynth.loudness(made)])
		var player := AudioStreamPlayer.new()
		player.stream = made
		add_child(player)
		player.play()
		if made.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			var time := 0.0
			while time < LOOP_TIME:
				if event in RISING:
					player.pitch_scale = 0.5 + time / LOOP_TIME
				await get_tree().process_frame
				time += get_process_delta_time()
		else:
			await get_tree().create_timer(made.get_length() + 0.05).timeout
		player.queue_free()
		await get_tree().create_timer(GAP).timeout
	get_tree().quit()
