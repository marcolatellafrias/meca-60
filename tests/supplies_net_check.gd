extends Node

## LOS PAQUETES POR LA RED (dos instancias sin ventana):
##   godot --headless --path . --host-local res://tests/supplies_net_check.tscn
##   godot --headless --path . --join-local res://tests/supplies_net_check.tscn
## Caen de los tubos en las dos; el otro agarra uno, se ve en sus manos, el tubo tira otro, lo deja y lo vuelve a agarrar, se
## lo pone a la meca; el botón cambia lo que sale; el kit no se gasta con la vida llena y cura después de dañarla.
## Cada una termina con PAQUETES <quién> OK.

const WORLD := "res://game/base/base_world.tscn"

var _host := false
var _fails := 0


func _ready() -> void:
	if has_meta("driver"):
		return
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	var driver := Node.new()
	driver.set_script(get_script())
	driver.set_meta("driver", true)
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
	await _until(func() -> bool:
		var spawner := get_tree().get_first_node_in_group("character_spawner") as CharacterSpawner
		return BaseSupplies.current != null and spawner != null and is_instance_valid(spawner.local_player) \
			and spawner.remote_players.size() == 1, 30.0)
	await _until(func() -> bool: return _pad(0) != null and _pad(1) != null, 8.0)
	_check("los dos tubos tiraron su paquete", _pad(0) != null and _pad(1) != null)
	await _wait(2.0)
	await _carry()
	await _deliver_ammo()
	await _selector()
	await _repair()
	print("PAQUETES %s %s" % ["HOST" if _host else "OTRO", "OK" if _fails == 0 else "MAL %d" % _fails])
	await _wait(1.0)
	get_tree().quit(_fails)


func _carry() -> void:
	var first := _pad(0)
	var id := first.id
	if not _host:
		BaseSupplies.current.ask_take(id)
	await _until(func() -> bool: return first.carrier != null, 4.0)
	_check("uno lo lleva, en las dos", first.carrier != null)
	if not _host:
		_check("es el de esta máquina", first.carrier == _me() and _me().carried == first)
	await _wait(0.4)
	var hands := first.carrier.char_rigidbody.global_position.distance_to(first.global_position)
	_check("va pegado a su cuerpo", hands < 1.4)
	await _until(func() -> bool: return _pad(0) != null, 5.0)
	_check("el tubo tiró otro", _pad(0) != null and _pad(0) != first)
	if _host:
		BaseSupplies.current._do_take(1, id)
		await _wait(0.3)
		_check("no se lo puede sacar otro", first.carrier != _me())
	else:
		await _wait(0.5)
		var spot := _me().char_rigidbody.global_position + Vector3(0.0, -0.9, 1.0)
		BaseSupplies.current._req_drop.rpc_id(1, id, spot)
	await _until(func() -> bool: return first.carrier == null, 4.0)
	_check("lo dejó en el piso", first.carrier == null)
	await _wait(0.3)


func _deliver_ammo() -> void:
	var crate := _find_loose()
	var mech := BaseSupplies.current._mech()
	var weapons := mech.guns.weapons
	# LAS DOS MÁQUINAS VAN A SU RITMO: cada paso espera ver el anterior, no un tiempo.
	if _host:
		weapons.belt = 10
	await _until(func() -> bool: return weapons.belt == 10, 5.0)
	if not _host:
		BaseSupplies.current.ask_take(crate.id)
		await _until(func() -> bool: return is_instance_valid(_me().carried), 4.0)
		BaseSupplies.current._req_deliver.rpc_id(1, crate.id)
	await _until(func() -> bool: return not is_instance_valid(crate), 4.0)
	_check("se la puso a la meca", not is_instance_valid(crate))
	await _until(func() -> bool: return weapons.belt == GunnerWeapons.BELT, 3.0)
	_check("la carga está llena en las dos", weapons.belt == GunnerWeapons.BELT)


func _selector() -> void:
	var tube := BaseSupplies.current._tubes[0] as BaseSupplyTube
	if not _host:
		await _wait(0.4)
		BaseSupplies.current.ask_next(0)
	await _until(func() -> bool: return tube.index == 1, 6.0)
	_check("el botón cambió el tipo", tube.index == 1)
	await _until(func() -> bool: return _pad(0) != null and int(_pad(0).kind) == tube.kind(), 5.0)
	_check("cae el tipo nuevo", _pad(0) != null and int(_pad(0).kind) == SupplyKinds.Kind.INCENDIARY)
	var crate := _pad(0)
	var mech := BaseSupplies.current._mech()
	await _wait(1.0)
	if not _host:
		BaseSupplies.current.ask_take(crate.id)
		await _until(func() -> bool: return is_instance_valid(_me().carried), 4.0)
		BaseSupplies.current._req_deliver.rpc_id(1, crate.id)
	await _until(func() -> bool: return mech.guns.weapons.bullet_kind == SupplyKinds.Kind.INCENDIARY, 4.0)
	_check("la meca tiene incendiarias", mech.guns.weapons.bullet_kind == SupplyKinds.Kind.INCENDIARY)


func _repair() -> void:
	await _until(func() -> bool: return _pad(1) != null, 5.0)
	var kit := _pad(1)
	var mech := BaseSupplies.current._mech()
	await _wait(0.8)
	if not _host:
		BaseSupplies.current.ask_take(kit.id)
		await _until(func() -> bool: return is_instance_valid(_me().carried), 4.0)
		BaseSupplies.current._req_deliver.rpc_id(1, kit.id)
	await _until(func() -> bool: return kit.carrier != null, 5.0)
	await _wait(0.7)
	_check("con la vida llena no se gasta", is_instance_valid(kit))
	if _host:
		BaseSync.current.hurt_mech()
	await _until(func() -> bool: return Health.of(mech) != null and Health.of(mech).left < Health.of(mech).full, 4.0)
	_check("el botón la daña", Health.of(mech) != null and is_equal_approx(Health.of(mech).left, 70.0))
	if not _host:
		await _wait(0.3)
		BaseSupplies.current._req_deliver.rpc_id(1, kit.id)
	await _until(func() -> bool: return not is_instance_valid(kit), 4.0)
	await _until(func() -> bool: return Health.of(mech).left > 99.0, 3.0)
	_check("el kit la cura", is_equal_approx(Health.of(mech).left, 100.0))


func _pad(slot: int) -> SupplyCrate:
	return BaseSupplies.current._on_pad(slot) if BaseSupplies.current != null else null


func _find_loose() -> SupplyCrate:
	for crate: SupplyCrate in BaseSupplies.current._crates.values():
		if not crate.on_pad and crate.carrier == null:
			return crate
	return null


func _me() -> BoneInstantiator:
	return (get_tree().get_first_node_in_group("character_spawner") as CharacterSpawner).local_player


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
