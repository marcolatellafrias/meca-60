extends Node3D

## LA SUCURSAL EN RED, CON DOS INSTANCIAS (sin ventana; ver docs/technical/flujo-de-partida.md):
##   godot --headless res://tests/base_net_check.tscn --host-local   (el capitán)
##   godot --headless res://tests/base_net_check.tscn --join-local   (otro)
## El host, con el otro adentro, compra un taladro, firma un contrato y aprieta el botón de la esclusa. El otro intenta
## firmar otro (no puede: no es el capitán) y, al final, dice lo que ve: la plata, el depósito, el contrato y si la
## esclusa se abrió. Tienen que coincidir con el host.

var _host := false
var _world: Node


func _ready() -> void:
	_host = OS.get_cmdline_args().has("--host-local")
	_world = (load("res://game/base/base_world.tscn") as PackedScene).instantiate()
	add_child(_world)
	if _host:
		await get_tree().create_timer(8.0).timeout
		print("HOST: jugadores ", SessionManager.players.size())
		BaseState.current.buy("drill")
		BaseState.current.sign_contract(1)
		(_world.get_node("Base/Plano/Esclusa") as BaseAirlock)._on_front_pressed()
		await get_tree().create_timer(4.0).timeout
		_report("HOST")
		# que el otro llegue a mirar antes de que el host se vaya
		await get_tree().create_timer(10.0).timeout
	else:
		await get_tree().create_timer(10.0).timeout
		# no es el capitán: la terminal no lo deja; y aunque apretara el botón de la esclusa, el host no le hace caso
		print("CLIENTE: capitán? ", BaseState.is_captain(get_tree()))
		await get_tree().create_timer(4.0).timeout
		_report("CLIENTE")
	get_tree().quit()


func _report(who: String) -> void:
	var state := BaseState.current
	var airlock := _world.get_node("Base/Plano/Esclusa") as BaseAirlock
	print("%s: plata %d, depósito %s, contrato %d, esclusa abierta %s" % [who, state.money, str(state.depot),
		state.contract, str(not airlock.armed)])
