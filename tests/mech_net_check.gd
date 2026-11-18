extends Node3D

## LA MECA POR LA RED, CON DOS INSTANCIAS (sin ventana, unos 20 segundos; ver BodyNet):
##   godot --headless --path . res://tests/mech_net_check.tscn --host-local   (el host)
##   godot --headless --path . res://tests/mech_net_check.tscn --join-local   (el otro: la maneja)
## Las dos arman la meca jaula. EL OTRO la toma (como al poseerla) y la maneja: camina adelante, dobla, se agacha,
## salta y hace un dash. Al final, quieta, las dos dicen dónde la ven (el motor, el rumbo, el estado, lo agachada, la
## caja y un pie) y cuántos estados mandaron y recibieron: el host la sigue (la simula el otro) y tiene que verla igual.
## Y mientras anda, el host mide lo más que su meca se aleja de la del dueño 100 ms atrás (no lo puede saber: imprime
## sólo cuánto se movió en cada paso, para ver que no salta).

var _host := false
var _mech: CageMech = null


func _enter_tree() -> void:
	# Es un mundo de red: la sesión espera uno para conectarse (ver SessionManager._world_loaded).
	add_to_group("net_world")


func _ready() -> void:
	SessionManager.world_ready()
	_host = OS.get_cmdline_args().has("--host-local")
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	_mech = CageMech.new()
	_mech.name = "Meca"
	_mech.scripted = true
	_mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
	add_child(_mech)
	await get_tree().create_timer(4.0).timeout
	var biggest_jump := 0.0
	if not _host:
		_mech.net.take_control()
		await get_tree().create_timer(0.5).timeout
		await _drive(Vector2(0.0, 1.0), 2.0, 0.0)
		await _drive(Vector2(0.0, 1.0), 1.5, 40.0)
		_mech.crouch = true
		await _drive(Vector2.ZERO, 1.0, 0.0)
		_mech.crouch = false
		_mech.jump = true
		await _drive(Vector2.ZERO, 0.3, 0.0)
		_mech.jump = false
		await _drive(Vector2.ZERO, 1.5, 0.0)
		_mech.dash = true
		await _drive(Vector2(1.0, 0.0), 0.2, 0.0)
		_mech.dash = false
		await _drive(Vector2.ZERO, 2.0, 0.0)
		print("CLIENTE: terminó de manejarla")
	else:
		# El host mira cuánto se mueve su meca en cada paso: siguiéndola, nunca a los saltos.
		var was := _mech.mover.global_position
		var clock := 0.0
		while clock < 9.0:
			await get_tree().physics_frame
			clock += 1.0 / Engine.physics_ticks_per_second
			var now := _mech.mover.global_position
			biggest_jump = maxf(biggest_jump, now.distance_to(was))
			was = now
	await get_tree().create_timer(3.0 if _host else 1.0).timeout
	_report("HOST" if _host else "CLIENTE", biggest_jump)
	await get_tree().create_timer(4.0 if _host else 1.0).timeout
	get_tree().quit()


func _drive(move: Vector2, seconds: float, turn: float) -> void:
	var clock := 0.0
	while clock < seconds:
		_mech.move = move
		_mech.aim_yaw += deg_to_rad(turn) / Engine.physics_ticks_per_second
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
	_mech.move = Vector2.ZERO


func _report(who: String, biggest_jump: float) -> void:
	var foot := _mech.skeleton.feet[0].global_position
	print("%s: dueño %d · motor %s · rumbo %.1f° · estado %s · agachada %.2f · caja %s · pie %s · mandó %d, recibió %d%s" % [
		who, _mech.net.authority, _mech.mover.global_position.snapped(Vector3.ONE * 0.01),
		rad_to_deg(_mech.mover.rotation.y), BalanceBody.State.keys()[_mech.state], _mech.mover.crouched,
		_mech.global_position.snapped(Vector3.ONE * 0.01), foot.snapped(Vector3.ONE * 0.01), _mech.net.sent,
		_mech.net.received, (" · lo más que se movió en un paso, siguiéndola: %.2f m" % biggest_jump) if _host else ""])
