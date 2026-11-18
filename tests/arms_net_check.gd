extends Node3D

## LOS BRAZOS Y LA ENERGÍA DE LA MECA POR LA RED, CON DOS INSTANCIAS (sin ventana, unos 20 s; ver MechArmsNet):
##   godot --headless --path . res://tests/arms_net_check.tscn --host-local   (el host)
##   godot --headless --path . res://tests/arms_net_check.tscn --join-local   (el otro: la toma y usa los brazos)
## Las dos arman la meca jaula (el cañón a la izquierda, el puño pesado a la derecha). EL OTRO la toma y, como lo haría
## quien la maneja, pone el cañón en ráfaga y aprieta el gatillo 1,5 s, después en súper, carga 1 s y suelta, y tira dos
## piñas. Al final las dos dicen cuántos tiros y piñas sonaron en su máquina (MechSounds.heard: cada máquina tira los
## suyos), la energía que le queda y el modo del cañón: tienen que dar igual.

var _host := false
var _mech: CageMech = null


func _enter_tree() -> void:
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
	await _wait(4.0)
	if not _host:
		_mech.net.take_control()
		await _wait(0.5)
		var cannon := _mech.cannon
		cannon.mode = CannonTip.Mode.BURST
		cannon.trigger = true
		await _wait(1.5)
		cannon.trigger = false
		await _wait(0.5)
		cannon.mode = CannonTip.Mode.SUPER
		cannon.trigger = true
		await _wait(1.0)
		cannon.trigger = false
		await _wait(1.5)
		_mech.melee.main_strike()
		await _wait(1.6)
		_mech.melee.punch(MechArm.Punch.HOOK)
		await _wait(2.0)
		print("CLIENTE: terminó")
	else:
		# Cuando el otro la tomó, el host intenta tirar una piña propia: no la simula él, no tiene que salir.
		while not _mech.net.remote():
			await get_tree().physics_frame
		await _wait(0.5)
		print("HOST: una piña propia salió: %s" % _mech.melee.main_strike())
		await _wait(9.0)
	await _wait(2.0)
	var heard := MechSounds.heard
	print("%s: ráfaga %d · súper %d · piñas %d · energía %.2f · cañón en %s · estados mandados %d recibidos %d · piñas recibidas %d"
		% ["HOST" if _host else "CLIENTE", heard.get(MechSounds.CANNON_BURST, 0), heard.get(MechSounds.CANNON_SUPER, 0),
		heard.get(MechSounds.SWING, 0), _mech.energy.level, CannonTip.MODE_NAMES[_mech.cannon.mode], _mech.arms_net.sent,
		_mech.arms_net.received, _mech.arms_net.punches_received])
	await _wait(1.0)
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
