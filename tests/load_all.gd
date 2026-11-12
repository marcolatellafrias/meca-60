extends Node

## CARGA TODOS LOS SCRIPTS DEL JUEGO Y DE LOS TESTS, uno por uno: el chequeo de compilación del editor no los compila a todos, y así
## los errores salen en la consola.

func _ready() -> void:
	var count := _walk("res://game") + _walk("res://tests")
	print("SCRIPTS cargados: ", count)
	get_tree().quit()


func _walk(folder: String) -> int:
	var count := 0
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			var script := load(folder + "/" + file) as Script
			if script == null or not script.can_instantiate():
				print("NO CARGA: ", folder + "/" + file)
			count += 1
	for sub in DirAccess.get_directories_at(folder):
		count += _walk(folder + "/" + sub)
	return count
