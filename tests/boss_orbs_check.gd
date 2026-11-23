extends Node

## EL JEFE DE LAS BOLITAS Y EL STUN (con ventana, unos 45 s, la partida real): firma su contrato y sube. Cada tipo hace lo
## suyo, los cinco patrones tiran, el escudo frena, la eléctrica aturde con los brazos caídos y los rayos. Saca capturas.
## Termina con BOLITAS OK o BOLITAS MAL.
##   tools/godot_ventana.sh res://tests/boss_orbs_check.tscn -- --salida=C:/carpeta

const CONTRACT := 3

var _folder := ""
var _bad := 0
var _mech: CageMech = null
var _brain: BrawlerBrain = null
var _power: OrbsPower = null


func _ready() -> void:
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	SessionManager.host()
	var world := (load("res://game/base/base_world.tscn") as PackedScene).instantiate() as BaseWorld
	add_child(world)
	_run(world)


func _run(world: BaseWorld) -> void:
	await _wait(2.5)
	var player := DesignSandbox.player_of(get_tree())
	player.player_controller.set("_shown", false)
	(world.find_child("Esclusa", true, false) as BaseAirlock)._open(1)
	await _wait(1.0)
	BaseState.current.sign_contract(CONTRACT)
	await _wait(0.3)
	_check("el contrato es el de las bolitas", Experiments.active == "bolitas")
	_mech = world.get_node("Base/Meca jaula") as CageMech
	var way := Vector3(1.0, 0.0, 1.0).normalized()
	var spot := _mech.mover.global_position + way * 2.2
	player.place_at(Vector3(spot.x, player.char_rigidbody.global_position.y - 1.0, spot.z), atan2(way.x, way.z))
	player.player_controller.camera_yaw = atan2(way.x, way.z)
	for tick in 120:
		await get_tree().physics_frame
	player.intent.activate = true
	await _wait(1.0)
	BaseSync.current._launch.rpc()
	var left := 40.0
	while left > 0.0 and not _awake(world):
		await _wait(0.25)
		left -= 0.25
	_check("la arena y el jefe despierto", _awake(world))
	_brain = world.get_node("Arena/Jefe/Luchador/Cabeza") as BrawlerBrain
	_power = _brain.power(BrawlerBrain.Act.ORBS) as OrbsPower
	_check("sólo tiene las bolitas", _only_orbs())
	_brain.awake = false
	await _wait(0.4)
	_power.start(_brain)
	await _kinds()
	await _stun()
	await _shield()
	await _patterns()
	print("BOLITAS OK" if _bad == 0 else "BOLITAS MAL (%d)" % _bad)
	BaseState.current.sign_contract(-1)
	get_tree().quit(_bad)


func _awake(world: Node) -> bool:
	var brain := world.get_node_or_null("Arena/Jefe/Luchador/Cabeza") as BrawlerBrain
	return brain != null and brain.awake


func _only_orbs() -> bool:
	for index in _brain.powers.size():
		var is_orbs := _brain.powers[index] is OrbsPower
		if _brain.powers[index].in_calm != is_orbs:
			return false
	return true


## TIRA UNA de `kind` desde `offset` metros de la meca, hacia `yaw`.
func _shoot(kind: BossOrbField.Kind, offset: Vector3, yaw: float) -> int:
	var at := _brain.ground() + offset
	var before := _power._next_id
	_power.send_from(_brain, at, [[kind, yaw]])
	return before


func _find(id: int) -> Dictionary:
	for orb: Dictionary in _power.field.live():
		if int(orb["id"]) == id:
			return orb
	return {}


func _kinds() -> void:
	var field := _power.field
	var far := Vector3(60.0, 0.0, 0.0)
	var pace := {}
	for kind: BossOrbField.Kind in [BossOrbField.Kind.NORMAL, BossOrbField.Kind.FAST, BossOrbField.Kind.SLOW]:
		var id := _shoot(kind, far, 0.0)
		var from: Vector3 = _find(id)["at"]
		await _wait(0.5)
		pace[kind] = from.distance_to(_find(id)["at"]) / 0.5
	print("velocidades: común %.1f, rápida %.1f, lenta %.1f" % [pace[BossOrbField.Kind.NORMAL], pace[BossOrbField.Kind.FAST],
		pace[BossOrbField.Kind.SLOW]])
	_check("la rápida va más rápido", pace[BossOrbField.Kind.FAST] > pace[BossOrbField.Kind.NORMAL] * 1.5)
	_check("la lenta va más lento", pace[BossOrbField.Kind.SLOW] < pace[BossOrbField.Kind.NORMAL] * 0.7)
	var bounces := field.bounced
	var toward_ring := field.center + Vector3(field.ring - 2.0, 0.0, 0.0) - _brain.ground()
	var bouncing := _shoot(BossOrbField.Kind.BOUNCE, toward_ring, -PI * 0.5)
	await _wait(0.6)
	var after: Dictionary = _find(bouncing)
	_check("la verde rebota en el anillo", field.bounced == bounces + 1)
	_check("y vuelve para adentro", not after.is_empty() and Vector2((after["at"] as Vector3).x - field.center.x,
		(after["at"] as Vector3).z - field.center.z).length() < field.ring)
	var splits := field.split_count
	var count := field.live().size()
	_shoot(BossOrbField.Kind.SPLIT, far + Vector3(0.0, 0.0, 12.0), 0.0)
	await _wait(1.05)
	_check("la naranja se parte en seis", field.split_count == splits + 1 and field.live().size() >= count + BossOrbField.SHARDS - 3)
	await _wait(0.2)


func _stun() -> void:
	_mech.energy.level = 1.0
	var life := Health.of(_mech).left
	_check("sin stun, los brazos arriba", is_zero_approx(_mech.arms[0].limp))
	_shoot(BossOrbField.Kind.STUN, Vector3(3.5, 0.0, 0.0), PI * 0.5)
	var left := 2.0
	while left > 0.0 and _mech.energy.able():
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()
	_check("la eléctrica aturde", not _mech.energy.able())
	_check("y lastima", Health.of(_mech).left < life)
	await _wait(0.4)
	_check("los brazos caen", _mech.arms[0].limp > 0.95 and _mech.arms[1].limp > 0.95)
	var fx := _mech.get_node_or_null("Electricidad") as ElectricFx
	_check("le saltan rayos", fx != null and fx.visible)
	await _shot("stun")
	await _wait(1.0)
	_check("se pasa", _mech.energy.able())
	await _wait(0.5)
	_check("los brazos vuelven", is_zero_approx(_mech.arms[0].limp))
	_check("los rayos se apagan", fx != null and not fx.visible)


func _shield() -> void:
	await _wait(0.2)
	_mech.energy.level = 1.0
	var life := Health.of(_mech).left
	var crew := _mech.get_node("Tripulacion") as MechCrew
	crew._store(999, 1 << MechCrew.SHIELD)
	await _steps(8)
	_check("el escudo prendió", _mech.shield.on)
	var front := Basis(Vector3.UP, _mech.yaw()) * Vector3.FORWARD
	var id := _shoot(BossOrbField.Kind.STUN, front * 7.0, atan2(front.x, front.z))
	var left := 2.0
	while left > 0.0 and not _find(id).is_empty():
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()
	_check("el escudo la frena", _find(id).is_empty() and is_equal_approx(Health.of(_mech).left, life) and _mech.energy.able())
	crew._store(999, 0)
	await _steps(8)


func _patterns() -> void:
	Health.of(_mech).left = 100000.0
	var field := _power.field
	for pattern: int in OrbsPower.Pattern.size():
		var before := field.launched
		_power.forced = pattern
		_power.start(_brain)
		_power._wait = 0.0
		var shots := 0
		while _power._fire(_brain) and shots < 60:
			shots += 1
			_power._wait = 0.0
			await _steps(6)
		print("patrón %s: %d bolitas" % [OrbsPower.Pattern.keys()[pattern], field.launched - before])
		_check("el patrón %s tira" % OrbsPower.Pattern.keys()[pattern], field.launched > before)
		if pattern == OrbsPower.Pattern.MIX:
			await _wait(0.35)
			await _shot("bolitas")
		await _wait(0.5)
	_power.forced = -1


func _steps(count: int) -> void:
	for tick in count:
		await get_tree().physics_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(what: String) -> void:
	if _folder.is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_folder.path_join(what + ".png"))


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1
