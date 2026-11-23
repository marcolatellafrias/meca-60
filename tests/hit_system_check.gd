extends Node

## LOS GOLPES POR FICHA Y EN EL PISO (con ventana, unos 35 s): cada arma le pega a la bolsa con el daño de su ficha, sin
## revolearla; la ametralladora es una sola zona; el aguante se rompe y se recupera; una pared tapa la zona. Saca una captura.
## No guarda nada. Termina con GOLPES OK o GOLPES MAL.
##   tools/godot_ventana.sh res://tests/hit_system_check.tscn -- --salida=C:/carpeta

const PEER := 999
const BAG_AT := Vector3(0.0, 9.0, -6.0)

var _folder := ""
var _bad := 0
var _mech: CageMech = null
var _crew: MechCrew = null
var _rig: BaseBagRig = null
var _bag: HitTarget = null
var _top_speed := 0.0
var _eye: Camera3D = null


func _ready() -> void:
	# Esta prueba es de las teclas: no depende de lo que el usuario tenga guardado en el F6.
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(300, 1, 300), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(300, 1, 300), Vector3(0, -0.5, 0), Color(0.62, 0.6, 0.56))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 150.0, 0.0)
	add_child(sun)
	_rig = BaseBagRig.new()
	_rig.position = BAG_AT
	add_child(_rig)
	_rig.build(0.9, 3.6, 4.3, Color(0.55, 0.33, 0.25))
	_bag = _rig.target
	_mech = await _make(ArmLoadout.Tip.FIST, ArmLoadout.Tip.CANNON)
	_eye = Camera3D.new()
	_eye.fov = 30.0
	add_child(_eye)
	var turn := Basis(Vector3.RIGHT, -deg_to_rad(60.0))
	_eye.global_transform = Transform3D(turn, Vector3(0.0, 2.0, -5.5) + turn.z * 40.0)
	_eye.make_current()
	_run()


func _make(left: ArmLoadout.Tip, right: ArmLoadout.Tip) -> CageMech:
	var mech := CageMech.new()
	mech.loadout = [ArmLoadout.of(left), ArmLoadout.of(right)]
	mech.position = Vector3(0.0, Mech.standing_height(mech.cabin_shape), 0.0)
	add_child(mech)
	await _wait(0.8)
	_crew = mech.get_node("Tripulacion") as MechCrew
	return mech


func _physics_process(_delta: float) -> void:
	if _rig != null and not _rig.pieces().is_empty():
		var v := _rig.pieces()[1].linear_velocity
		_top_speed = maxf(_top_speed, Vector2(v.x, v.z).length())


func _run() -> void:
	var knobs := HitSettings.current
	await _settle()
	await _minigun(knobs)
	await _missile(knobs)
	await _cannon(knobs)
	await _poise(knobs)
	await _wall()
	await _fist(knobs)
	print("GOLPES OK" if _bad == 0 else "GOLPES MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _minigun(knobs: HitSettings) -> void:
	var before := _bag.dealt
	var hits := _bag.hits
	_crew._store(PEER, 1 << MechCrew.MINIGUN)
	await _wait(0.5)
	_check("mientras arranca no pega", _bag.hits == hits)
	await _wait(1.4)
	await _shot("1_ametralladora")
	await _wait(0.6)
	_crew._store(PEER, 0)
	var pulses := _bag.hits - hits
	var done := _bag.dealt - before
	print("ametralladora: %d pulsos, %.1f de daño, la bolsa a %.2f m/s" % [pulses, done, _top_speed])
	_check("le pega desde arriba de la bolsa", pulses >= 10)
	_check("cada pulso da su ficha", is_equal_approx(done, pulses * knobs.minigun_damage))
	_check("no la revolea", _top_speed < 3.0)
	await _settle()


func _missile(knobs: HitSettings) -> void:
	var before := _bag.dealt
	var hits := _bag.hits
	_crew._store(PEER, 1 << MechCrew.MISSILES)
	await _wait(0.1)
	_crew._store(PEER, 0)
	await _wait(0.8)
	var done := _bag.dealt - before
	print("misil: %.1f de daño, la bolsa a %.2f m/s" % [done, _top_speed])
	_check("el misil pega una vez", _bag.hits == hits + 1)
	_check("en el centro da su ficha", done > knobs.missile_damage * 0.8 and done <= knobs.missile_damage + 0.01)
	_check("no la revolea", _top_speed < 3.0)
	await _settle()


func _cannon(knobs: HitSettings) -> void:
	_mech.energy.level = 1.0
	var before := _bag.dealt
	_crew._store(PEER, 1 << MechCrew.ARM_RIGHT)
	await _wait(0.9)
	_crew._store(PEER, 0)
	await _wait(0.5)
	var tap := _bag.dealt - before
	await _settle()
	_mech.energy.level = 1.0
	before = _bag.dealt
	_crew._store(PEER, 1 << MechCrew.ARM_RIGHT)
	await _wait(2.6)
	_crew._store(PEER, 0)
	await _wait(0.5)
	var full := _bag.dealt - before
	print("cañón: toque %.1f, a fondo %.1f, la bolsa a %.2f m/s" % [tap, full, _top_speed])
	_check("el primer segmento da un tercio", absf(tap - knobs.cannon_damage / 3.0) < 0.1)
	_check("a fondo da la ficha entera", absf(full - knobs.cannon_damage) < 0.1)
	_check("no la revolea", _top_speed <= BaseBagRig.SWING_TOP + 0.5)
	await _settle()


func _poise(knobs: HitSettings) -> void:
	_bag.poise = knobs.bag_poise
	var breaks := _bag.breaks
	_bag.strike("cañón", 1.0, 1.0, _bag.center(), Vector3.FORWARD)
	await _steps(2)
	_check("un golpe desgasta el aguante", is_equal_approx(_bag.poise, knobs.bag_poise - knobs.cannon_stagger))
	_check("todavía no lo rompe", _bag.breaks == breaks)
	await _settle()
	_top_speed = 0.0
	_bag.poise = 10.0
	_bag.strike("cañón", 1.0, 1.0, _bag.center(), Vector3.FORWARD)
	await _wait(0.4)
	print("rompió el aguante: la bolsa a %.2f m/s" % _top_speed)
	_check("el que lo rompe cuenta", _bag.breaks == breaks + 1)
	_check("y el aguante vuelve entero", _bag.poise >= knobs.bag_poise - 0.01)
	_bag.poise = 20.0
	await _wait(knobs.poise_wait + 0.5)
	_check("sin golpes se recupera", _bag.poise > 25.0)
	await _settle()


func _wall() -> void:
	var wall := StaticBody3D.new()
	Clay.solid(wall, Vector3(10.0, 8.0, 0.5), Vector3(0.0, 4.0, BAG_AT.z + 2.0), Color(0.4, 0.4, 0.42))
	PhysicsLayers.mark_fixed(wall)
	add_child(wall)
	await _steps(3)
	var hits := _bag.hits
	_crew._store(PEER, 1 << MechCrew.MINIGUN)
	await _wait(1.6)
	_crew._store(PEER, 0)
	_check("una pared tapa la zona", _bag.hits == hits)
	remove_child(wall)
	wall.queue_free()
	_mech.guns.weapons.heat = 0.0
	await _settle()


func _fist(knobs: HitSettings) -> void:
	_mech.mover.put(Transform3D(Basis(), Vector3(0.0, 0.0, BAG_AT.z + 3.1)))
	await _wait(0.6)
	var before := _bag.dealt
	_crew._store(PEER, 1 << MechCrew.ARM_LEFT)
	await _wait(0.5)
	_crew._store(PEER, 0)
	await _wait(1.2)
	var done := _bag.dealt - before
	print("piña: %.1f de daño (ficha %.1f), la bolsa a %.2f m/s" % [done, knobs.fist_damage, _top_speed])
	_check("la piña pega con su ficha", done >= knobs.fist_damage * 0.95 and done <= knobs.fist_damage * 1.3)


func _settle() -> void:
	await _wait(2.5)
	for body in _rig.pieces():
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
	await _wait(0.2)
	_top_speed = 0.0


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
