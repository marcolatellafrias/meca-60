extends Node

## EL LOOP Y LOS CONTROLES DE CLIC POR LA RED (dos instancias sin ventana):
##   godot --headless --path . --host-local res://tests/match_net_check.tscn
##   godot --headless --path . --join-local res://tests/match_net_check.tscn
## El host pone los controles de clic; el otro toma la ametralladora, la palanca queda puesta, el giro sigue solo y el roll
## se ve en la otra máquina. Después el host reinicia dos veces y las dos vuelven a la base, con los dos personajes.

const WORLD := "res://game/base/base_world.tscn"

var _host := false
var _fails := 0


func _ready() -> void:
	_host = OS.get_cmdline_args().has("--host-local")
	var driver := Node.new()
	driver.set_script(get_script())
	driver.set_meta("driver", true)
	if has_meta("driver"):
		return
	get_tree().root.add_child.call_deferred(driver)
	_go.call_deferred(driver)


func _go(driver: Node) -> void:
	if not driver.is_inside_tree():
		await driver.tree_entered
	driver.call("run")
	get_tree().change_scene_to_file(WORLD)


func run() -> void:
	_host = OS.get_cmdline_args().has("--host-local")
	if _host:
		SessionManager.host_local()
	else:
		SessionManager.join_local()
	await _world_with_two()
	await _controls()
	for round_number in 2:
		if _host:
			await _wait(1.0)
			BaseSync.current.restart()
		var old := BaseSync.current
		await _until(func() -> bool: return BaseSync.current != null and BaseSync.current != old, 20.0)
		await _world_with_two()
		var crew := _crew()
		_check("reinicio %d: la meca nueva sin nada puesto" % (round_number + 1),
			crew != null and crew.stick == Vector2.ZERO and crew.turning == 0 and crew.gun_taker == 0)
	await _fight_and_die()
	await _wait(1.0)
	print("MATCH %s %s" % ["HOST" if _host else "OTRO", "OK" if _fails == 0 else "FALLÓ %d" % _fails])
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	await _wait(1.0)
	get_tree().quit(_fails)


func _controls() -> void:
	var crew := _crew()
	var mech := crew.mech
	if _host:
		MatchSettings.current.controls = MatchSettings.Controls.CLICK
		await _wait(1.0)
		BaseSync.current.share_match()
	await _until(func() -> bool: return MatchSettings.current.clicking(), 6.0)
	_check("los dos con controles de clic", MatchSettings.current.clicking())
	await _wait(1.0)
	var other := _other()
	if not _host:
		crew.click_square(MechCrew.MINIGUN, true)
	await _until(func() -> bool: return crew.gun_taker != 0, 5.0)
	_check("la ametralladora es del otro", crew.gun_taker != 1)
	await _wait(0.3)
	var gun_zone := crew.aim._zones.get(MechCrew.MINIGUN) as BossZone
	var seen := gun_zone != null and gun_zone.visible
	_check("su zona la ve sólo quien la usa", seen != _host)
	if _host:
		crew.click_square(MechCrew.MINIGUN, true)
	await _wait(0.6)
	_check("el host no se la puede sacar", crew.gun_taker != 1 and crew.gun_taker != 0)
	if _host:
		crew.click_square(MechCrew.LEFT, true)
	await _until(func() -> bool: return crew.turning == 1, 5.0)
	var yaw := mech.yaw()
	await _wait(0.7)
	_check("el giro sigue solo", absf(angle_difference(yaw, mech.yaw())) > 0.1)
	if _host:
		crew.click_square(MechCrew.LEFT, true)
	await _until(func() -> bool: return crew.turning == 0, 5.0)
	if not _host:
		crew._report.rpc_id(1, 1 << MechCrew.W)
		await _wait(0.3)
		crew._ask_stick.rpc_id(1, Vector2(0.0, 1.0))
		await _wait(0.2)
		crew._report.rpc_id(1, 0)
	await _until(func() -> bool: return crew.stick.y > 0.9, 5.0)
	await _wait(0.4)
	var from := mech.global_position
	await _wait(0.7)
	_check("la palanca se queda y camina", from.distance_to(mech.global_position) > 1.0)
	await _shield(crew)
	await _cursors(crew)
	if _host:
		crew._share(Vector2.ZERO, 0, crew.gun_taker, crew.missile_taker)
		await _wait(1.5)
		var me := _me()
		me.roll.start(Vector3.RIGHT)
		me.net_sync.tell_roll(Vector3.RIGHT)
		await _wait(1.0)
	else:
		await _until(func() -> bool: return other.roll.active(), 5.0)
		_check("el roll del host se ve acá", other.roll.active())
	await _wait(0.5)


## EL ESCUDO ES UN INTERRUPTOR: el otro lo prende, paga y queda prendido en las dos; sin energía se apaga solo en las dos.
func _shield(crew: MechCrew) -> void:
	var energy := crew.mech.energy
	if _host:
		energy.level = 1.0
		await _wait(0.5)
	else:
		await _wait(0.8)
		crew.click_square(MechCrew.SHIELD, true)
	await _until(func() -> bool: return crew.shield_by != 0 and crew.mech.shield.on, 4.0)
	_check("el escudo queda prendido sin mantener", crew.shield_by != 0 and crew.mech.shield.on)
	if _host:
		await _wait(0.6)
		energy.level = 0.01
	await _until(func() -> bool: return crew.shield_by == 0, 5.0)
	_check("sin energía se apaga solo", crew.shield_by == 0)
	await _wait(0.5)
	_check("y queda apagado", not crew.mech.shield.on)
	if _host:
		energy.level = 1.0
	await _wait(0.8)


## LOS CURSORES: el otro señala un cuadrado y después un punto del piso; acá se ven en ese mismo lugar.
func _cursors(crew: MechCrew) -> void:
	var board_point := Vector2(120.0, 40.0)
	var ground := Vector3(3.0, 0.0, -2.0)
	if not _host:
		await _wait(0.4)
		for tick in 8:
			crew.cursors._tell.rpc(true, board_point)
			await _wait(0.05)
		await _wait(0.5)
		for tick in 8:
			crew.cursors._tell.rpc(false, ground)
			await _wait(0.05)
		await _wait(0.5)
		crew.cursors._gone.rpc()
		await _wait(0.6)
		return
	var peer := _spawner().remote_players.keys()[0] as int
	await _until(func() -> bool: return crew.cursors._others.has(peer), 4.0)
	var on_board := crew.cursors.screen_of(peer)
	_check("su cursor sobre el cuadrado", on_board.distance_to(crew.cursors.hud.board.global_position + board_point) < 0.5)
	await _until(func() -> bool: return crew.cursors._others.has(peer) and not crew.cursors._others[peer]["on_board"], 3.0)
	var other: Dictionary = crew.cursors._others.get(peer, {})
	_check("su cursor sobre el piso", not other.is_empty() and other["at"] == ground)
	await _until(func() -> bool: return not crew.cursors._others.has(peer), 3.0)
	_check("al irse, su cursor se apaga", not crew.cursors._others.has(peer))


## EL LOOP ENTERO: firmar, subir a la arena, que maten a la meca, ver el cartel y reiniciar.
func _fight_and_die() -> void:
	var before := BaseSync.current
	if _host:
		BaseState.current.sign_contract(2)
		await _wait(0.5)
		BaseSync.current._launch.rpc()
	var world := get_tree().get_first_node_in_group(BaseWorld.GROUP)
	await _until(func() -> bool:
		var brain := world.get_node_or_null("Arena/Jefe/Luchador/Cabeza") as BrawlerBrain
		return brain != null and brain.awake, 40.0)
	_check("la arena y el jefe despierto", world.get_node_or_null("Arena/Jefe/Luchador") != null)
	var mech := world.get_node("Base/Meca jaula")
	await _orbs_and_stun(world, mech as CageMech)
	if _host:
		await _wait(0.5)
		Health.of(mech).hurt(1000.0, "prueba")
	await _until(func() -> bool: return Health.of(mech) != null and Health.of(mech).dead(), 6.0)
	var banner := world.get_node_or_null("Arena/Jefe/Final") as MatchEnd
	_check("el cartel de que cayó", banner != null and banner._label.visible)
	before = BaseSync.current
	await _wait(1.5)
	if _host:
		BaseSync.current.restart()
	await _until(func() -> bool: return BaseSync.current != null and BaseSync.current != before, 20.0)
	await _world_with_two()
	var fresh := get_tree().get_first_node_in_group(BaseWorld.GROUP)
	_check("después de morir, de vuelta en la base", fresh.get_node_or_null("Arena") == null and _crew() != null)
	_check("el contrato sigue firmado", BaseState.current.contract == 2)


## LAS BOLITAS Y EL STUN: el host tira una eléctrica contra la meca; las dos ven la bolita y la meca aturdida con los brazos caídos.
func _orbs_and_stun(world: Node, mech: CageMech) -> void:
	var brain := world.get_node("Arena/Jefe/Luchador/Cabeza") as BrawlerBrain
	if _host:
		brain.awake = false
		await _wait(1.5)
		var power := brain.power(BrawlerBrain.Act.ORBS) as OrbsPower
		power.send_from(brain, brain.ground() + Vector3(4.0, 0.0, 0.0), [[BossOrbField.Kind.STUN, PI * 0.5]])
	await _until(func() -> bool: return world.find_child("Bolitas", true, false) != null, 6.0)
	var field := world.find_child("Bolitas", true, false) as BossOrbField
	_check("las dos ven la bolita", field != null and field.launched >= 1)
	await _until(func() -> bool: return not mech.energy.able(), 4.0)
	_check("las dos ven la meca aturdida", not mech.energy.able())
	await _wait(0.3)
	_check("con los brazos caídos", mech.arms[0].limp > 0.9)
	await _until(func() -> bool: return mech.energy.able(), 4.0)
	await _wait(0.8)


func _crew() -> MechCrew:
	var world := get_tree().get_first_node_in_group(BaseWorld.GROUP)
	return world.get_node_or_null("Base/Meca jaula/Tripulacion") as MechCrew if world != null else null


func _spawner() -> CharacterSpawner:
	return get_tree().get_first_node_in_group("character_spawner") as CharacterSpawner


func _me() -> BoneInstantiator:
	return _spawner().local_player


func _other() -> BoneInstantiator:
	var all := _spawner().remote_players.values()
	return all[0] as BoneInstantiator if not all.is_empty() else null


func _world_with_two() -> void:
	await _until(func() -> bool:
		var spawner := _spawner()
		return BaseSync.current != null and _crew() != null and spawner != null and is_instance_valid(spawner.local_player) \
			and spawner.remote_players.size() == 1 and is_instance_valid(_other()), 25.0)
	_check("la base con los dos personajes", _spawner() != null and is_instance_valid(_other()))
	await _wait(1.0)


func _until(done: Callable, limit: float) -> void:
	var left := limit
	while left > 0.0 and not done.call():
		left -= get_physics_process_delta_time()
		await get_tree().physics_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(what: String, ok: bool) -> void:
	print("%s %s: %s" % ["HOST" if _host else "OTRO", "ok" if ok else "FALLA", what])
	if not ok:
		_fails += 1
