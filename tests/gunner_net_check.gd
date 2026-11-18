extends Node3D

## LA TORRETA DEL ARTILLERO EN RED, CON DOS INSTANCIAS (sin ventana; ver GunnerTurret, «La red»):
##   godot --headless --path . res://tests/gunner_net_check.tscn --host-local   (el host)
##   godot --headless --path . res://tests/gunner_net_check.tscn --join-local   (el otro: el artillero)
## Las dos arman lo mismo: la meca jaula de 3 y un blanco adelante (una caja donde se le pega, que cuenta los golpes).
## EL OTRO toma la torreta, la gira 40° a la izquierda, tira la minigun 2 s, aprieta «salva» y la vuelve al frente.
## Las dos dicen lo que ven: hacia dónde quedó la torreta, cuántas balas y misiles dibujaron, cuántos misiles le
## quedan a la caja y cuántos golpes recibió el blanco (sólo el host los aplica: el del otro tiene que dar 0).

var _host := false
var _mech: CageMech = null
var _target: Node = null


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
	# El blanco: una caja grande adelante, a la altura de las armas, donde se le pega.
	_target = (load("res://tests/net_target.gd") as GDScript).new()
	_target.name = "Blanco"
	add_child(_target)
	var box := BossHurtbox.new()
	box.name = "Caja"
	box.owner_of_hits = _target
	add_child(box)
	box.shape(Vector3(14.0, 14.0, 2.0), Vector3.ZERO)
	box.global_position = Vector3(0.0, 4.0, -30.0)
	await get_tree().create_timer(4.0).timeout
	var turret := (_mech.cabin as CageCabin).turret
	if not _host:
		turret.take_control()
		await get_tree().create_timer(0.5).timeout
		var front := _mech.global_basis * Vector3.FORWARD
		var yaw := atan2(-front.x, -front.z)
		for k in 120:
			turret.aim(yaw + deg_to_rad(40.0), 0.05)
			await get_tree().physics_frame
		var at_40 := rad_to_deg(turret.yaw)
		for k in 90:
			turret.aim(yaw, 0.05)
			await get_tree().physics_frame
		turret.weapons.trigger(true)
		await get_tree().create_timer(2.0).timeout
		turret.weapons.trigger(false)
		turret.weapons.press("misiles")
		turret.weapons.press("salva")
		print("CLIENTE: giró a %.0f°" % at_40)
	# El host espera más: que el otro termine y diga lo suyo antes de que se corte la sesión.
	await get_tree().create_timer(16.0 if _host else 6.0).timeout
	_report("HOST" if _host else "CLIENTE", turret)
	await get_tree().create_timer(6.0 if _host else 1.0).timeout
	get_tree().quit()


func _report(who: String, turret: GunnerTurret) -> void:
	print("%s: dueño %d, giro %.0f°, balas dibujadas %d, misiles dibujados %d, tubos %d, golpes al blanco %d" % [who,
		turret._authority, rad_to_deg(turret.yaw), GunnerBullet.made, GunnerMissile.made, turret.weapons.tubes,
		_target.get("hits")])
