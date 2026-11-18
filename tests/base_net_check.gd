extends Node3D

## LA SUCURSAL EN RED, CON DOS INSTANCIAS (sin ventana; ver docs/technical/flujo-de-partida.md):
##   godot --headless res://tests/base_net_check.tscn --host-local   (el capitán)
##   godot --headless res://tests/base_net_check.tscn --join-local   (otro)
## El host, con el otro adentro, compra un taladro, firma un contrato y aprieta el botón de la esclusa. El otro intenta
## firmar otro (no puede: no es el capitán) y, al final, dice lo que ve: la plata, el depósito, el contrato y si la
## esclusa se abrió, y la meca: para cuántos quedó armada al abrir (2, los que son) y dónde está. Después los dos se
## suben a la plataforma del ascensor y el host aprieta su botón: al final, cada uno dice si se armó la arena y dónde
## quedaron la plataforma, la meca y él (arriba, a ras del piso de la arena). Tienen que coincidir con el host.

var _host := false
var _world: Node


func _ready() -> void:
	_host = OS.get_cmdline_args().has("--host-local")
	_world = (load("res://game/base/base_world.tscn") as PackedScene).instantiate()
	add_child(_world)
	# --tarde: el host abre la esclusa enseguida (empieza la partida) y espera; el otro llega después y no tiene que
	# poder entrar
	if _host and OS.get_cmdline_user_args().has("--tarde"):
		await get_tree().create_timer(2.0).timeout
		(_world.get_node("Base/Plano/Esclusa") as BaseAirlock)._on_front_pressed()
		print("HOST: partida empezada")
		await get_tree().create_timer(20.0).timeout
		print("HOST: jugadores al final ", SessionManager.players.size())
		get_tree().quit()
		return
	if _host:
		await get_tree().create_timer(8.0).timeout
		print("HOST: jugadores ", SessionManager.players.size())
		BaseState.current.buy("drill")
		BaseState.current.sign_contract(1)
		(_world.get_node("Base/Plano/Esclusa") as BaseAirlock)._on_front_pressed()
		await get_tree().create_timer(4.0).timeout
		_report("HOST")
		_board()
		# que el otro también suba (llega unos segundos después)
		await get_tree().create_timer(8.0).timeout
		print("HOST: cartel antes de apretar: ", _elevator_sign())
		for player: Node in get_tree().root.find_children("char_*", "BoneInstantiator", true, false):
			print("HOST: ", player.name, " en ", (player as BoneInstantiator).char_rigidbody.global_position)
		BaseSync.current.launch()
		await get_tree().create_timer(20.0).timeout
		_report_arena("HOST")
		# que el otro llegue a mirar antes de que el host se vaya
		await get_tree().create_timer(6.0).timeout
	else:
		await get_tree().create_timer(10.0).timeout
		# no es el capitán: la terminal no lo deja; y aunque apretara el botón de la esclusa, el host no le hace caso
		print("CLIENTE: capitán? ", BaseState.is_captain(get_tree()))
		await get_tree().create_timer(4.0).timeout
		_report("CLIENTE")
		_board()
		await get_tree().create_timer(22.0).timeout
		_report_arena("CLIENTE")
	get_tree().quit()


## Se sube a la plataforma del ascensor (cada uno el suyo, a un costado de la meca).
func _board() -> void:
	var platform := _world.get_node("Base/Plano/Ascensor/Plataforma") as Node3D
	var spawner := _world.get_node("CharacterSpawner") as CharacterSpawner
	spawner.place_local_at(platform.global_position + Vector3(-2.5, 0.3, 3.0 if _host else -3.0))


func _elevator_sign() -> String:
	for node: Node in _world.get_node("Base/Plano/Ascensor").find_children("*", "Label3D", true, false):
		return (node as Label3D).text
	return "?"


func _report_arena(who: String) -> void:
	var elevator := _world.get_node("Base/Plano/Ascensor") as BaseElevator
	var platform := elevator.get_node("Plataforma") as Node3D
	var mech := _world.get_node_or_null("Base/Meca jaula") as Mech
	var spawner := _world.get_node("CharacterSpawner") as CharacterSpawner
	print("%s: ascensor arrancó %s · arena %s · plataforma %.2f · meca %.2f · yo %.2f" % [who, str(elevator.launched),
		str(_world.get_node_or_null("Arena") != null), platform.global_position.y,
		mech.mover.global_position.y if mech else -1.0, spawner.local_player.char_rigidbody.global_position.y])


func _report(who: String) -> void:
	var state := BaseState.current
	var airlock := _world.get_node("Base/Plano/Esclusa") as BaseAirlock
	print("%s: plata %d, depósito %s, contrato %d, esclusa abierta %s" % [who, state.money, str(state.depot),
		state.contract, str(not airlock.armed)])
	var mech := _world.get_node_or_null("Base/Meca jaula") as CageMech
	if mech:
		var at := mech.mover.global_position
		print("%s: meca para %d jugadores, en (%.2f, %.2f, %.2f), dueño %d" % [who, CageShape.crew + 1, at.x, at.y, at.z,
			mech.net.authority])
