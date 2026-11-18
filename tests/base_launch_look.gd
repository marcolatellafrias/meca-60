extends Node3D

## EL ASCENSOR A LA ARENA, PARA MIRAR (con ventana, unos 40 s; ver BaseElevator): la partida sola (como «crear
## partida»), con el contrato firmado y el jugador puesto sobre la plataforma; aprieta el botón y saca capturas: antes,
## subiendo por el pozo, llegando a la arena y desde los ojos del jugador arriba. Imprime dónde quedan la plataforma,
## la meca y el jugador (los dos tienen que haber subido con ella).
##   tools/godot_ventana.sh res://tests/base_launch_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _eye: Camera3D


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	SessionManager.host()
	var world := (load("res://game/base/base_world.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().create_timer(4.0).timeout
	var holder := world.get_node("Base/Plano") as Node3D
	var elevator := holder.get_node("Ascensor") as BaseElevator
	var spawner := world.get_node("CharacterSpawner") as CharacterSpawner
	var platform := elevator.get_node("Plataforma") as Node3D
	print("cartel sin contrato: ", _sign(elevator))
	BaseState.current.sign_contract(0)
	(holder.get_node("Esclusa") as BaseAirlock)._on_front_pressed()
	await get_tree().create_timer(1.0).timeout
	print("cartel con contrato, abajo afuera: ", _sign(elevator))
	# arriba de la plataforma, en el borde del lado de la franja, mirando a la meca
	spawner.place_local_at(platform.global_position + Vector3(-2.5, 0.3, 3.0))
	await get_tree().create_timer(1.5).timeout
	print("cartel arriba: ", _sign(elevator))
	_eye = Camera3D.new()
	_eye.far = 1500.0
	add_child(_eye)
	var nave := holder.to_global(BaseLayout.at(BaseLayout.ELEVATOR + BaseLayout.width * 0.6, BaseLayout.NAVE * 0.8, 3.0))
	_look(nave, platform.global_position + Vector3.UP * 2.5)
	await _shot("ascensor_1_abajo")
	BaseSync.current.launch()
	await get_tree().create_timer(BaseHatch.SLIDE_TIME + 0.3 + 3.0).timeout
	# subiendo: desde el pozo, mirando para abajo a la plataforma
	var top := holder.to_global(BaseLayout.at(BaseLayout.ELEVATOR * 0.5, BaseLayout.NAVE * 0.5, BaseLayout.shaft_top()))
	_look(top + Vector3(0.5, -1.0, 0.5), platform.global_position)
	await _shot("ascensor_2_subiendo")
	await elevator.arrived
	await get_tree().create_timer(1.5).timeout
	_look(top + Vector3(22.0, 9.0, 18.0), top + Vector3.UP * 3.0)
	await _shot("ascensor_3_en_la_arena")
	var mech := world.get_node("Base/Meca jaula") as Mech
	var player := spawner.local_player.char_rigidbody.global_position
	print("piso de la arena %.2f · plataforma %.2f · meca (motor) %.2f · jugador %.2f" % [top.y,
		platform.global_position.y + BaseElevator.LIFT, mech.mover.global_position.y, player.y])
	# desde los ojos del jugador
	_eye.current = false
	await _shot("ascensor_4_ojos")
	get_tree().quit()


func _sign(elevator: BaseElevator) -> String:
	for node: Node in elevator.find_children("*", "Label3D", true, false):
		return (node as Label3D).text
	return "?"


func _look(from: Vector3, to: Vector3) -> void:
	_eye.global_position = from
	_eye.look_at(to)
	_eye.make_current()


func _shot(file: String) -> void:
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/" + file + ".png")
		print("CAPTURA ", _folder + "/" + file + ".png")
