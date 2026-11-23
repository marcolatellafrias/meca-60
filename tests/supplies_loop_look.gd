extends Node

## LOS PAQUETES, JUGANDO (con ventana, unos 60 s, la base real): agarrar con la E, llevarlo atado a las manos, la E cerca de la
## meca se lo pone en vez de subir, y sin paquete sube. Después cada munición contra la bolsa. Saca capturas.
## Termina con RECURSOS OK o RECURSOS MAL.
##   tools/godot_ventana.sh res://tests/supplies_loop_look.tscn -- --salida=C:/carpeta

const PEER := 999

var _folder := ""
var _bad := 0
var _player: BoneInstantiator = null
var _mech: CageMech = null
var _crew: MechCrew = null
var _bag: HitTarget = null


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
	_player = DesignSandbox.player_of(get_tree())
	_player.player_controller.set("_shown", false)
	(world.find_child("Esclusa", true, false) as BaseAirlock)._open(2)
	await _wait(1.5)
	_mech = world.get_node("Base/Meca jaula") as CageMech
	_crew = _mech.get_node("Tripulacion") as MechCrew
	for node in get_tree().get_nodes_in_group(HitTarget.GROUP):
		if (node as HitTarget).receiver == null:
			_bag = node
	await _wait(1.5)
	await _shot("1_tubos")
	await _carry_and_load()
	await _board_after()
	await _bullets()
	await _missile_kinds()
	print("RECURSOS OK" if _bad == 0 else "RECURSOS MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _carry_and_load() -> void:
	var supplies := BaseSupplies.current
	var tube := supplies._tubes[0] as BaseSupplyTube
	var button := tube.find_child("Usar", true, false) as BaseTubeButton
	await _stand_at(button.get_parent(), Vector3(1.2, 0.0, 0.2))
	_check("el botón se resalta", _hovered() == button)
	_player.intent.activate = true
	await _wait(1.8)
	_check("el botón cambió a incendiarias", tube.kind() == SupplyKinds.Kind.INCENDIARY)
	var crate := supplies._on_pad(0)
	_check("cayó una incendiaria", crate != null and int(crate.kind) == SupplyKinds.Kind.INCENDIARY)
	await _stand_at(crate, Vector3(0.0, 0.0, 1.25))
	_check("la E tiene a tiro el paquete", _hovered() == crate)
	_player.intent.activate = true
	await _steps(6)
	_check("lo agarró", _player.carried == crate)
	await _wait(0.4)
	var hands := _player.custom_bones_util
	var left: Vector3 = hands.left_lower_arm.global_position
	_check("las manos van al paquete", left.distance_to(crate.global_position) < 0.75)
	await _shot("2_llevando")
	_player.roll.stop()
	var way := Vector3(1.0, 0.0, 1.0).normalized()
	var spot := _mech.mover.global_position + way * 2.2
	_player.place_at(Vector3(spot.x, _player.char_rigidbody.global_position.y - 1.0, spot.z), atan2(way.x, way.z))
	_player.player_controller.camera_yaw = atan2(way.x, way.z)
	await _steps(60)
	_check("sigue en las manos al moverse", _player.carried == crate
		and crate.global_position.distance_to(_player.char_rigidbody.global_position) < 1.5)
	_player.intent.activate = true
	await _steps(8)
	_check("la E cerca de la meca se lo puso", not is_instance_valid(_player.carried))
	_check("y no se subió", not _player.is_seated)
	_check("la meca tiene incendiarias", _mech.guns.weapons.bullet_kind == SupplyKinds.Kind.INCENDIARY)
	await _shot("3_puesto")
	BaseSync.current.hurt_mech()
	await _wait(1.3)
	_check("dañada: 70", is_equal_approx(Health.of(_mech).left, 70.0))
	await _shot("4_danada")
	var kit := supplies._on_pad(1)
	await _stand_at(kit, Vector3(0.0, 0.0, 1.25))
	_player.intent.activate = true
	await _steps(6)
	_check("agarró el kit", _player.carried == kit)
	spot = _mech.mover.global_position + way * 2.2
	_player.place_at(Vector3(spot.x, _player.char_rigidbody.global_position.y - 1.0, spot.z), atan2(way.x, way.z))
	_player.player_controller.camera_yaw = atan2(way.x, way.z)
	await _steps(60)
	_player.intent.activate = true
	await _steps(8)
	_check("el kit la curó", is_equal_approx(Health.of(_mech).left, 100.0) and not is_instance_valid(_player.carried))
	await _wait(0.3)


func _board_after() -> void:
	await _steps(30)
	_player.intent.activate = true
	await _wait(0.8)
	_check("sin paquete, la E sube", _player.is_seated)
	_player.intent.activate = true
	await _wait(0.5)


func _bullets() -> void:
	var weapons := _mech.guns.weapons
	var near := _bag.center() + Vector3(-7.0, 0.0, 0.0)
	_mech.mover.put(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(near.x, _mech.mover.global_position.y, near.z)))
	await _wait(0.6)
	_crew.aim.store(PEER, Vector3(7.0, 0.0, 0.0))
	_crew._store(PEER, 1 << MechCrew.MINIGUN)
	await _wait(1.5)
	_crew.aim.store(PEER, _bag.center() - _mech.global_position)
	var common := await _measure(SupplyKinds.Kind.BULLETS)
	var piercing := await _measure(SupplyKinds.Kind.PIERCING)
	_check("la perforante pega más", piercing > common * 1.4)
	var burns := _bag.effects.burns
	await _measure(SupplyKinds.Kind.INCENDIARY)
	_check("la incendiaria prende", _bag.effects.burns > burns)
	weapons.hold_minigun(false)
	_crew._store(PEER, 0)
	await _wait(0.2)
	var after := _bag.dealt
	var ticks := _bag.effects.burns
	await _wait(1.2)
	_check("y sigue quemando sin disparar", _bag.effects.burns > ticks and _bag.dealt > after)
	await _wait(2.5)
	var shocks := _bag.effects.shocks
	_crew.aim.store(PEER, _bag.center() - _mech.global_position)
	_crew._store(PEER, 1 << MechCrew.MINIGUN)
	await _wait(1.0)
	weapons.load_supply(SupplyKinds.Kind.ELECTRIC)
	weapons.heat = 0.0
	await _wait(2.8)
	_check("la eléctrica lo aturde", _bag.effects.shocks > shocks)
	await _shot("5_electrica")
	_crew._store(PEER, 0)
	weapons.heat = 0.0
	weapons.jammed = false
	weapons.belt = 1
	_crew._store(PEER, 1 << MechCrew.MINIGUN)
	await _wait(1.5)
	_crew._store(PEER, 0)
	await _wait(GunnerWeapons.RELOAD_TIME[GunnerWeapons.Weapon.MINIGUN] + 0.3)
	_check("vacía, vuelve a la común", weapons.bullet_kind == SupplyKinds.Kind.BULLETS and weapons.belt == GunnerWeapons.BELT)


func _measure(kind: int) -> float:
	var weapons := _mech.guns.weapons
	weapons.load_supply(kind)
	weapons.heat = 0.0
	weapons.jammed = false
	var from := _bag.dealt
	await _wait(0.8)
	return _bag.dealt - from


func _missile_kinds() -> void:
	var weapons := _mech.guns.weapons
	_crew.aim.store(PEER, _bag.center() - _mech.global_position + Vector3(0.0, 0.0, 4.0))
	var before := GunnerMissile.made
	weapons.load_supply(SupplyKinds.Kind.BOUNCER)
	weapons.launch_missile(PEER)
	await _wait(1.8)
	_check("el rebotador salta", GunnerMissile.made == before + 2)
	before = GunnerMissile.made
	weapons.load_supply(SupplyKinds.Kind.CLUSTER)
	weapons.launch_missile(PEER)
	await _wait(1.5)
	await _shot("6_racimo")
	_check("el racimo suelta cuatro", GunnerMissile.made == before + 1 + GunnerMissile.BOMBLETS)
	await _wait(0.5)
	var dealt := _bag.dealt
	weapons.load_supply(SupplyKinds.Kind.MINE)
	var free_way := Basis(Vector3.UP, _mech.yaw()) * Vector3.BACK * 6.0
	_crew.aim.store(PEER, free_way)
	weapons.launch_missile(PEER)
	await _wait(1.6)
	var mine: GunnerMissile = null
	for node in get_children():
		pass
	for node in get_tree().current_scene.get_children():
		if node is GunnerMissile and (node as GunnerMissile)._armed:
			mine = node
	_check("la mina se queda en el piso", mine != null)
	if mine != null:
		_check("sin nadie cerca, espera", is_instance_valid(mine) and is_equal_approx(_bag.dealt, dealt))
		mine.global_position = _bag.center() + Vector3(1.0, -_bag.center().y + mine.global_position.y, 0.0)
		await _steps(8)
		_check("con un blanco cerca, explota", not is_instance_valid(mine) and _bag.dealt > dealt)


func _hovered() -> Interactable:
	var hands: InteractionController = _player.player_controller.interaction_controller
	return hands.detector.get_hovered()


## Lo para a `offset` de `thing` (en los ejes del mundo), mirándolo.
func _stand_at(thing: Node3D, offset: Vector3) -> void:
	var spot := thing.global_position + offset
	var ground := _player.char_rigidbody.global_position.y - 1.0
	var way := (thing.global_position - spot)
	way.y = 0.0
	var yaw := atan2(-way.x, -way.z)
	_player.place_at(Vector3(spot.x, ground, spot.z), yaw)
	_player.player_controller.camera_yaw = yaw
	await _steps(40)


func _steps(count: int) -> void:
	for tick in count:
		await get_tree().physics_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(what: String) -> void:
	if _folder.is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_folder.path_join("rec_" + what + ".png"))
	# Volver al paso de física: lo que se teletransporta desde el dibujo, la física lo pisa.
	await get_tree().physics_frame


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1
