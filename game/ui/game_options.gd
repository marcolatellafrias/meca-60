class_name GameOptions
extends RefCounted

## LAS OPCIONES DEL JUGADOR: lo que se elige en la pantalla de Opciones (OptionsMenu) y se guarda en esta máquina. Es la
## del taxi sin lo de la voz: el volumen general, la sensibilidad del mouse, el campo de visión y la pantalla completa.
##
## Estático, sin autoload. Lo carga el menú de pausa al arrancar (ver PauseMenu) y se guarda en cada cambio.

const PATH := "user://opciones.cfg"
const SENSITIVITY_MIN := 0.25
const SENSITIVITY_MAX := 3.0
const FOV_MIN := 50.0
const FOV_MAX := 100.0

static var master_volume := 1.0
static var mouse_sensitivity := 1.0
static var field_of_view := 75.0
static var fullscreen := false
static var _loaded := false


static func load_and_apply() -> void:
	if _loaded:
		return
	_loaded = true
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		master_volume = clampf(float(config.get_value("audio", "general", 1.0)), 0.0, 1.0)
		mouse_sensitivity = clampf(float(config.get_value("control", "sensibilidad", 1.0)), SENSITIVITY_MIN,
			SENSITIVITY_MAX)
		fullscreen = bool(config.get_value("pantalla", "completa", false))
		field_of_view = clampf(float(config.get_value("pantalla", "campo_de_vision", 75.0)), FOV_MIN, FOV_MAX)
	_apply_volume()
	_apply_window()


static func set_master(linear: float) -> void:
	master_volume = clampf(linear, 0.0, 1.0)
	_apply_volume()
	save()


static func set_field_of_view(degrees: float) -> void:
	field_of_view = clampf(degrees, FOV_MIN, FOV_MAX)
	save()


static func set_sensitivity(factor: float) -> void:
	mouse_sensitivity = clampf(factor, SENSITIVITY_MIN, SENSITIVITY_MAX)
	save()


static func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_window()
	save()


static func save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "general", master_volume)
	config.set_value("control", "sensibilidad", mouse_sensitivity)
	config.set_value("pantalla", "campo_de_vision", field_of_view)
	config.set_value("pantalla", "completa", fullscreen)
	var error := config.save(PATH)
	if error != OK:
		push_warning("[Opciones] no se pudo guardar %s: %s" % [PATH, error_string(error)])


static func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	AudioServer.set_bus_mute(0, master_volume <= 0.0)


## Pantalla completa o ventana, sólo si cambia: una ventana maximizada no se toca si no se pidió la pantalla completa.
static func _apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.window_get_mode()
	var full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if fullscreen and not full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
