extends Node

## LA RED EN EL SANDBOX, PROBADA CON DOS INSTANCIAS: una con `--host-local` abre la sesión, otra con `--join-local` se
## une (ver SessionManager). Cada una arma el sandbox, espera y dice cuántos jugadores ve, cuántos personajes hay y cuántos
## objetos compartidos.
##   godot --headless --path . res://tests/net_check.tscn --host-local
##   godot --headless --path . res://tests/net_check.tscn --join-local

## Cuánto espera: el que se une arranca después y tiene que terminar antes de que el anfitrión se vaya.
var SECONDS := 14.0


func _ready() -> void:
	if OS.get_cmdline_args().has("--join-local"):
		SECONDS = 8.0
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate()
	add_child(sandbox)
	await get_tree().create_timer(SECONDS).timeout
	var role := "anfitrión" if SessionManager.is_host else "unido"
	var characters := sandbox.find_children("*", "BoneInstantiator", true, false).filter(
		func(node: Node) -> bool: return node.get_parent().name == SandboxSession.CHARS)
	var shared := get_tree().root.find_children("*", "NetBody", true, false).size()
	print("RED %s: sesión %s · jugadores %d · personajes en la sesión %d · cuerpos de red %d" % [role,
		SessionManager.session_started, SessionManager.players.size(), characters.size(), shared])
	get_tree().quit()
