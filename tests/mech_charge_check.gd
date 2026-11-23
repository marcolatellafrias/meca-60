extends Node

## LAS CARGAS Y LA MUNICIÓN DE LA MECA (con ventana, unos 25 s): el puño y el cañón cargan mientras se mantienen, el cañón
## sólo hasta lo que alcance la energía y sin aturdir; la ametralladora se calienta y se traba; las dos armas dicen su
## munición y su recarga en los cuadrados. Saca capturas. Termina con CARGAS OK o CARGAS MAL.
##   tools/godot_ventana.sh res://tests/mech_charge_check.tscn -- --salida=C:/carpeta

const PEER := 999

var local_player: BoneInstantiator = null
var _folder := ""
var _bad := 0
var _mech: CageMech = null
var _crew: MechCrew = null
var _hud: MechCrewHud = null


func _ready() -> void:
	# Esta prueba es de las teclas: no depende de lo que el usuario tenga guardado en el F6.
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	add_to_group("character_spawner")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.62, 0.6, 0.56))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 150.0, 0.0)
	add_child(sun)
	_mech = CageMech.new()
	_mech.loadout = [ArmLoadout.of(ArmLoadout.Tip.CANNON),
		ArmLoadout.of(ArmLoadout.Tip.FIST)]
	_mech.position = Vector3(0.0, Mech.standing_height(_mech.cabin_shape), 0.0)
	add_child(_mech)
	add_child(IsoView.new())
	local_player = (load("res://game/character/player.tscn") as PackedScene).instantiate() as BoneInstantiator
	local_player.kind = CharacterKind.player()
	add_child(local_player)
	local_player.place_at(Vector3(0.0, 0.0, 2.4), 0.0)
	_run()


func _run() -> void:
	await _wait(0.8)
	local_player.player_controller._shown = false
	local_player.player_controller.camera_yaw = 0.0
	await _wait(0.3)
	local_player.intent.activate = true
	await _wait(0.8)
	_check("sentado, con los cuadrados", local_player.is_seated)
	_crew = _mech.get_node("Tripulacion") as MechCrew
	_hud = _crew.get_children().filter(func(n: Node) -> bool: return n is MechCrewHud)[0]
	await _fist()
	await _cannon()
	await _minigun()
	await _missiles()
	print("CARGAS OK" if _bad == 0 else "CARGAS MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _fist() -> void:
	var arm := _mech.arms[1]
	var knobs := DashSettings.current
	_mech.energy.level = 1.0
	await _steps(2)
	var before := _mech.energy.level
	_crew._store(PEER, 1 << MechCrew.ARM_RIGHT)
	await _wait(0.1)
	_crew._store(PEER, 0)
	await _steps(3)
	print("toque: gastó %.3f" % (before - _mech.energy.level))
	_check("un toque gasta y no pega", arm.punching == MechArm.Punch.NONE and absf(before - _mech.energy.level - knobs.fist_cost / MechEnergy.UNIT) < 0.01)
	await _wait(0.3)
	_crew._store(PEER, 1 << MechCrew.ARM_RIGHT)
	await _wait(0.5)
	_crew._store(PEER, 0)
	await _steps(3)
	_check("pasando el umbral sale liviano", arm.punching != MechArm.Punch.NONE and is_equal_approx(arm.punch_strength, 1.0))
	await _wait(1.6)
	_mech.energy.level = 1.0
	await _steps(2)
	before = _mech.energy.level
	_crew._store(PEER, 1 << MechCrew.ARM_RIGHT)
	await _wait(0.5)
	var half := _crew.arm_charge(1)
	_check("mantener no pega todavía", arm.punching == MechArm.Punch.NONE)
	_check("la barrita sube", half > 0.35 and half < 0.7)
	await _shot("1_puno_cargando")
	await _wait(1.0)
	_check("la carga tiene tope", is_equal_approx(_crew.arm_charge(1), 1.0))
	_crew._store(PEER, 0)
	await _steps(3)
	print("cargada: fuerza ×%.2f" % arm.punch_strength)
	_check("cargado pega con todo", is_equal_approx(arm.punch_strength, CageHandling.current.punch_strongest))
	_check("el pesado paga los dos costos", absf(before - _mech.energy.level - (knobs.fist_cost + knobs.fist_heavy_cost) / MechEnergy.UNIT) < 0.02)
	await _wait(1.6)
	_mech.energy.level = knobs.fist_cost / MechEnergy.UNIT + 0.01
	_crew._store(PEER, 1 << MechCrew.ARM_RIGHT)
	await _wait(1.2)
	_check("sin energía para el pesado queda en liviano", is_equal_approx(_crew.arm_charge(1), knobs.fist_light_share))
	_crew._store(PEER, 0)
	await _steps(3)
	_check("y sale liviano", arm.punching != MechArm.Punch.NONE and is_equal_approx(arm.punch_strength, 1.0))
	await _wait(3.0)


func _cannon() -> void:
	var cannon := _mech.arms[0].tip as CannonTip
	_mech.energy.level = 1.0
	await _wait(0.3)
	var from := _mech.energy.level
	_crew._store(PEER, 1 << MechCrew.ARM_LEFT)
	await _steps(2)
	_crew._store(PEER, 0)
	await _steps(4)
	print("toque del cañón: gastó %.3f" % (from - _mech.energy.level))
	var segment := DashSettings.current.cannon_segment_cost / MechEnergy.UNIT
	_check("un toque gasta su segmento y no dispara", absf(from - _mech.energy.level - segment) < 0.01 and is_zero_approx(cannon.charge))
	await _wait(0.4)
	_mech.energy.level = 1.0
	from = _mech.energy.level
	_crew._store(PEER, 1 << MechCrew.ARM_LEFT)
	await _wait(1.0)
	_check("va por el segundo segmento", cannon.segments_full() == 1)
	print("cargando: %.2f, gastó %.2f" % [cannon.charge, from - _mech.energy.level])
	_check("mantener carga y gasta", cannon.charge > 0.35 and from - _mech.energy.level > 0.1)
	await _shot("2_canon_cargando")
	_crew._store(PEER, 0)
	await _steps(4)
	_check("al soltar dispara", is_zero_approx(cannon.charge))
	await _wait(0.4)
	_mech.energy.level = 0.12
	_crew._store(PEER, 1 << MechCrew.ARM_LEFT)
	await _wait(2.7)
	print("con poca energía: carga %.2f, energía %.3f, aturdida %s" % [cannon.charge, _mech.energy.level, not _mech.energy.able()])
	_check("con poca energía carga igual al máximo", is_equal_approx(cannon.charge, 1.0))
	_check("la batería queda en negativo, sin stun todavía", _mech.energy.able() and _mech.energy.level < 0.0)
	_crew._store(PEER, 0)
	await _steps(4)
	_check("al disparar, el stun", is_zero_approx(cannon.charge) and not _mech.energy.able())
	_mech.energy.stunned = 0.0
	_mech.energy.level = 1.0


func _minigun() -> void:
	var weapons := _mech.guns.weapons
	var shots := weapons.belt
	_crew._store(PEER, 1 << MechCrew.MINIGUN)
	await _wait(0.5)
	_check("los primeros instantes no dispara", weapons.belt == shots)
	await _wait(1.2)
	_check("después dispara y gasta balas", weapons.belt < shots)
	_check("se calienta", weapons.heat > 0.05)
	await _shot("3_ametralladora")
	var firing := 0.0
	while not weapons.jammed and firing < 9.0:
		await _wait(0.1)
		firing += 0.1
	print("se trabó después de %.1f s más de fuego, con %d balas" % [firing, weapons.belt])
	_check("llena de calor se traba", weapons.jammed)
	var jammed_at := weapons.belt
	await _wait(0.2)
	_check("trabada no dispara", weapons.belt == jammed_at)
	await _shot("4_trabada")
	_crew._store(PEER, 0)
	weapons.heat = 0.0
	await _wait(0.2)
	_check("fría se destraba", not weapons.jammed)
	weapons.belt = 2
	_crew._store(PEER, 1 << MechCrew.MINIGUN)
	await _wait(1.3)
	_crew._store(PEER, 0)
	_check("vacía se recarga", weapons.belt == 0 and weapons.reload_share(GunnerWeapons.Weapon.MINIGUN) > 0.0)
	await _wait(1.0)
	await _shot("5_recargando")
	var fill := (_hud._ammo[GunnerWeapons.Weapon.MINIGUN] as Dictionary)["fill"] as ColorRect
	_check("su cuadrado se llena hacia arriba", fill.visible and fill.size.y > 2.0 and is_equal_approx(fill.position.y + fill.size.y, MechCrewHud.AMMO_TAG_HIGH))
	await _wait(2.0)
	_check("recargada", weapons.belt == GunnerWeapons.BELT)
	_check("el cuadrado dice las balas", ((_hud._ammo[GunnerWeapons.Weapon.MINIGUN] as Dictionary)["count"] as Label).text == str(GunnerWeapons.BELT))


func _missiles() -> void:
	var weapons := _mech.guns.weapons
	for i in GunnerWeapons.TUBES:
		_crew._store(PEER, 1 << MechCrew.MISSILES)
		await _wait(0.1)
		_crew._store(PEER, 0)
		await _wait(0.25)
	_check("sin misiles se recarga", weapons.tubes == 0 and weapons.reload_share(GunnerWeapons.Weapon.MISSILES) > 0.0)
	await _wait(3.2)
	_check("misiles recargados", weapons.tubes == GunnerWeapons.TUBES)


func _steps(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


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
	await get_tree().physics_frame
