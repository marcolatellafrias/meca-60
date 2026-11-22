extends Node

## LA PARTIDA EN ISOMÉTRICA, DE PUNTA A PUNTA (con ventana, sin red): la base real, el botón de la esclusa con la E, la meca
## de un jugador sin maniquíes, subirse, firmar un contrato, el ascensor y la arena. Saca una captura de cada parte e
## imprime ok o MAL; termina con LOOP OK o LOOP MAL.
##   tools/godot_ventana.sh res://tests/iso_base_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _bad := 0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	SessionManager.host()
	var world := (load("res://game/base/base_world.tscn") as PackedScene).instantiate() as BaseWorld
	add_child(world)
	_run(world)


func _run(world: BaseWorld) -> void:
	await _wait(2.5)
	var player := DesignSandbox.player_of(get_tree())
	_check("hay jugador", is_instance_valid(player))
	_check("la cámara es la isométrica", get_viewport().get_camera_3d() is IsoView)
	await _shot("1_esclusa")
	var base := world.get_node("Base") as Node3D
	var airlock := base.find_child("Esclusa", true, false) as BaseAirlock
	var elevator := base.find_child("Ascensor", true, false) as BaseElevator
	elevator.arrived.connect(_noop)
	# EL BOTÓN DE ADENTRO DE LA ESCLUSA, con la E: el que abre (el más cercano al que nace).
	var door := _inner_button(airlock)
	await _stand_before(player, door, door.global_basis.z)
	_check("la E tiene a tiro el botón de la esclusa", _hovered(player) == door)
	player.intent.activate = true
	await _wait(1.5)
	_check("la E abrió la esclusa", not airlock.armed)
	var mech := base.get_node_or_null("Meca jaula") as CageMech
	_check("la meca es de un puesto", mech != null and mech.cabin.chairs.size() == 1)
	_check("sin maniquíes", mech != null and mech.cabin.dummies.is_empty())
	# LA CONSOLA DE CONTRATOS, con la E.
	var console := base.find_child("Contratos", true, false) as Node3D
	await _stand_before(player, console, -console.global_basis.z)
	_check("la E tiene a tiro la consola", _hovered(player) is BaseTerminal)
	await _shot("2_consola_resaltada")
	player.intent.activate = true
	await _wait(0.4)
	_check("la E abrió la pantalla", not UIState.gameplay_active())
	await _shot("3_consola_abierta")
	for screen: Node in get_tree().root.find_children("*", "TerminalScreen", true, false):
		(screen as TerminalScreen).close()
	await _wait(0.3)
	_check("la pantalla se cerró", UIState.gameplay_active())
	BaseState.current.contract = 0
	# EL BOTÓN DEL ASCENSOR, con la E, parado en la plataforma.
	var lift := _nearest_button(elevator, elevator.global_position)
	await _stand_before(player, lift, lift.global_basis.z)
	_check("la E tiene a tiro el botón del ascensor", _hovered(player) == lift)
	await _shot("4_base_ascensor")
	_check("puede salir", elevator.can_launch())
	player.intent.activate = true
	await _wait(0.5)
	_check("la E lanzó el ascensor", elevator.launched)
	# SUBIRSE A LA MECA mientras sube.
	await _stand_before(player, mech.mover, Vector3(1.0, 0.0, 1.0), 2.2)
	_check("mirando la meca, la E la tiene a tiro", _hovered(player) is CageBoarding)
	player.intent.activate = true
	await _wait(0.8)
	_check("subido", player.is_seated)
	await _wait(2.0)
	await _shot("5_subiendo")
	var limit := 40.0
	while not _arrived and limit > 0.0:
		await _wait(0.5)
		limit -= 0.5
	_check("llegó a la arena", _arrived)
	await _wait(1.0)
	await _shot("6_arena")
	print("LOOP OK" if _bad == 0 else "LOOP MAL (%d)" % _bad)
	get_tree().quit(_bad)


var _arrived := false


func _hovered(player: BoneInstantiator) -> Interactable:
	return player.player_controller.interaction_controller.detector.get_hovered()


func _nearest_button(root: Node, to: Vector3) -> TouchComponent:
	var best: TouchComponent = null
	for found: Node in root.find_children("*", "TouchComponent", true, false):
		var button := found as TouchComponent
		if best == null or button.global_position.distance_to(to) < best.global_position.distance_to(to):
			best = button
	return best


## El de adentro de la esclusa: el que está más hacia su compuerta de adelante (−X en sus ejes).
func _inner_button(airlock: BaseAirlock) -> TouchComponent:
	var best: TouchComponent = null
	for found: Node in airlock.find_children("*", "TouchComponent", true, false):
		var button := found as TouchComponent
		if best == null or airlock.to_local(button.global_position).x < airlock.to_local(best.global_position).x:
			best = button
	return best


## Lo para a `away` metros de `thing`, del lado de `front`, mirándolo.
func _stand_before(player: BoneInstantiator, thing: Node3D, front: Vector3, away := 1.0) -> void:
	var way := Vector3(front.x, 0.0, front.z).normalized()
	var spot := thing.global_position + way * away
	var feet_y := player.char_rigidbody.global_position.y - 1.0
	player.place_at(Vector3(spot.x, feet_y, spot.z), atan2(way.x, way.z))
	player.player_controller.camera_yaw = atan2(way.x, way.z)
	await _wait(0.5)


func _noop() -> void:
	_arrived = true


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String) -> void:
	if _folder.is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_folder, title])
