extends Node

## LA ESCALERA DE ADENTRO, PARA MIRARLA (sin el sandbox): una meca con la estructura «adentro» (ver MechInsideStairs), y
## capturas desde afuera atrás, desde cada piso mirando a la escalera y desde arriba con el techo sacado. Imprime las
## medidas: el largo de un tramo, lo que queda de losa en cada punta y la altura libre sobre los escalones.
##   tools/godot_ventana.sh res://tests/mech_inside_stairs_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	CabinGrid.STRUCTURE = CabinGrid.Structure.INSIDE
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(300, 1, 300), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(300, 1, 300), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.88)
	world.environment.ambient_light_energy = 0.9
	add_child(world)
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.NONE
	_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_mech)
	_eye = Camera3D.new()
	_eye.far = 500.0
	_eye.fov = 80.0
	add_child(_eye)
	_eye.make_current()
	print("TRAMO: %.2f m de largo para subir %.2f m · de losa en cada punta quedan %.2f m · el carril, %.2f m de ancho" % [
		MechExterior.flight_run(), CabinGrid.FLOOR_HEIGHT, MechInsideStairs.landing_room(), MechInsideStairs.LANE])
	print("ALTURA LIBRE sobre los escalones: %.2f m (un piso menos la losa y el escalón)" % (CabinGrid.FLOOR_HEIGHT - CabinGrid.SLAB - Stairs.RISE))
	await get_tree().create_timer(2.0).timeout
	_mech.freeze = true
	var box := _mech.global_transform
	_look(box * Vector3(-16.0, 4.0, 20.0), box * Vector3(0.0, 0.0, 0.0))
	await _shot("1. desde atrás: sin pasarela, sin escalera y sin puertas", "1_atras")
	var z := MechInsideStairs.lane()
	for index in CabinGrid.FLOORS:
		# Desde una esquina de adelante (el ascensor del medio tapa la vista derecha).
		var eye := Vector3(-CabinGrid.INNER + 0.4, CabinGrid.ground(index) + 1.7, -CabinGrid.INNER + 0.4)
		_look(box * eye, box * Vector3(CabinGrid.INNER * 0.3, CabinGrid.ground(index) + 1.2, z.y))
		await _shot("%d. desde el piso %d, mirando a la pared de atrás" % [index + 2, index], "%d_piso_%d" % [index + 2, index])
	# Desde arriba, con el techo y las paredes del último piso sacados.
	_hide_above(CabinGrid.ground(CabinGrid.FLOORS - 1) + 0.5)
	_mech.label.visible = false
	_look(box * Vector3(0.0, CabinGrid.HALF_HEIGHT + 5.0, -CabinGrid.INNER * 0.4), box * Vector3(0.0, CabinGrid.ground(CabinGrid.FLOORS - 1), z.x))
	await _shot("%d. desde arriba, sin el techo: el hueco y el tramo de abajo" % (CabinGrid.FLOORS + 2), "%d_arriba" % (CabinGrid.FLOORS + 2))
	get_tree().quit()


## Esconde lo dibujado de la cabina que está más arriba de `y` (en la caja).
func _hide_above(y: float) -> void:
	for node in _mech.cabin.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var local := _mech.global_transform.affine_inverse() * mesh.global_position
		if local.y > y:
			mesh.visible = false


func _look(from: Vector3, at: Vector3) -> void:
	_eye.global_position = from
	_eye.look_at(at)


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
