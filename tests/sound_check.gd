extends Node3D

## EL SONIDO SIMPLE (ver Sounds, SoundEntity): una clave con archivo, una sin archivo (el clic de prueba), un loop que se
## frena y el movimiento que se apaga solo. Imprime qué sonó.

class Wheel extends SoundEntity:
	const SOUNDS := {MOVE_UP: &"rueda_derecha", MOVE_DOWN: &"rueda_izquierda", CLICK: [&"perilla", &"pagina"]}

	func sounds() -> Dictionary:
		return SOUNDS


func _ready() -> void:
	var with_file := Sounds.play(&"perilla", self)
	print("CON ARCHIVO: ", with_file.stream.resource_path if with_file != null else "nada")
	var without := Sounds.play(&"no_existe", self)
	print("SIN ARCHIVO: ", "clic de prueba" if without != null and without.stream is AudioStreamWAV else "nada")
	var wheel := Wheel.new()
	add_child(wheel)
	wheel.play_sound(SoundEntity.CLICK)
	wheel.move_sound(0.0)
	wheel.move_sound(0.5)
	print("MOVIENDO: loops ", wheel._loops.keys())
	await get_tree().create_timer(0.4).timeout
	print("QUIETO: loops ", wheel._loops.keys())
	get_tree().quit()
