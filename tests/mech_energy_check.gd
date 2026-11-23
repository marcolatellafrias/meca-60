extends Node

## LA REGLA DE LA ENERGÍA (con ventana, unos 25 s): en cero sólo no hay energía; en negativo, stun. La sierra y el propulsor
## se apagan en cero sin aturdir; el cañón siempre carga al máximo, y si la batería queda en negativo, el stun viene al
## disparar. Con el interruptor apagado no hay stun. No guarda nada. Termina con ENERGIA OK o ENERGIA MAL.

const PEER := 999

var _bad := 0
var _mech: CageMech = null
var _crew: MechCrew = null
var _cannon: CannonTip = null
var _saw: SpinTip = null
var _saved := {}


func _ready() -> void:
	# Esta prueba es de las teclas: no depende de lo que el usuario tenga guardado en el F6.
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	get_window().size = Vector2i(640, 360)
	_saved = DashSettings.current.values()
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	_mech = CageMech.new()
	_mech.loadout = [ArmLoadout.of(ArmLoadout.Tip.CANNON),
		ArmLoadout.of(ArmLoadout.Tip.SAW)]
	_mech.position = Vector3(0.0, Mech.standing_height(_mech.cabin_shape), 0.0)
	add_child(_mech)
	_run()


func _run() -> void:
	await _wait(0.8)
	_crew = _mech.get_node("Tripulacion") as MechCrew
	_cannon = _mech.arms[0].tip as CannonTip
	_saw = _mech.arms[1].tip as SpinTip
	var knobs := DashSettings.current
	knobs.stun_on = true
	knobs.stun_time = 1.2
	knobs.stun_blocks_guns = true
	knobs.style = DashSettings.Style.THRUST
	knobs.thrust_drain = 45.0
	knobs.thrust_start = 5.0
	knobs.energy_capacity = 100.0
	knobs.energy_refill = 14.0
	await _zero_is_only_empty()
	await _enough_energy()
	await _negative_stuns()
	await _stun_blocks()
	await _toggle_off()
	await _battery()
	knobs.load_values(_saved)
	print("ENERGIA OK" if _bad == 0 else "ENERGIA MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _zero_is_only_empty() -> void:
	await _reset(0.12)
	_crew._store(PEER, 1 << MechCrew.ARM_RIGHT)
	await _wait(1.0)
	print("sierra: energía %.3f, aturdida %s, carga %s" % [_mech.energy.level, not _mech.energy.able(), _saw.charging])
	_check("la sierra llega a cero sin stun", is_zero_approx(_mech.energy.level) and _mech.energy.able())
	_check("en cero la sierra se apaga", not _saw.charging)
	await _reset(0.1)
	_crew._store(PEER, (1 << MechCrew.D) | (1 << MechCrew.DASH))
	await _wait(0.6)
	print("propulsor: energía %.3f, aturdida %s, fase %d" % [_mech.energy.level, not _mech.energy.able(), _mech.dasher.phase])
	_check("el propulsor llega a cero sin stun", is_zero_approx(_mech.energy.level) and _mech.energy.able())
	_check("en cero no hay dash", _mech.dasher.phase == MechDash.Phase.NONE)
	var at := _mech.mover.global_position
	await _wait(0.3)
	_check("en cero sigue caminando", at.distance_to(_mech.mover.global_position) > 0.8)


func _enough_energy() -> void:
	await _reset(0.6)
	_hold()
	await _wait(2.6)
	_check("con energía de sobra carga al máximo", is_equal_approx(_cannon.charge, 1.0) and _mech.energy.level > 0.0)
	await _release()
	_check("sin negativo no hay stun", _mech.energy.able())


func _negative_stuns() -> void:
	await _reset(0.12)
	var bolts := EnergyBolt.made
	_hold()
	await _wait(2.6)
	print("poca energía: carga %.2f, energía %.3f" % [_cannon.charge, _mech.energy.level])
	_check("con poca energía igual carga al máximo", is_equal_approx(_cannon.charge, 1.0))
	_check("queda en negativo lo que faltó", absf(_mech.energy.level - (0.12 - DashSettings.current.cannon_segment_cost * CannonTip.SEGMENTS / MechEnergy.UNIT)) < 0.02)
	_check("cargando todavía no hay stun", _mech.energy.able())
	var debt := _mech.energy.level
	await _wait(1.0)
	_check("sostenerla no recarga ni hunde más", absf(_mech.energy.level - debt) < 0.001)
	await _release()
	_check("al soltar dispara", EnergyBolt.made == bolts + 1)
	_check("al disparar, el stun", not _mech.energy.able())
	await _wait(1.3)
	_check("el stun se pasa", _mech.energy.able())
	await _wait(1.2)
	print("recarga: de %.3f a %.3f" % [debt, _mech.energy.level])
	_check("se recarga desde el negativo", _mech.energy.level > debt + 0.05)


func _stun_blocks() -> void:
	await _reset(1.0)
	var weapons := _mech.guns.weapons
	var tubes := weapons.tubes
	var yaw := _mech.yaw()
	var at := _mech.mover.global_position
	_mech.energy.level = -0.1
	_mech.energy.settle()
	_crew._store(PEER, (1 << MechCrew.D) | (1 << MechCrew.LEFT) | (1 << MechCrew.MISSILES))
	await _wait(0.6)
	_check("stun: no camina", at.distance_to(_mech.mover.global_position) < 0.05)
	_check("stun: no gira", absf(angle_difference(yaw, _mech.yaw())) < 0.02)
	_check("stun: no lanza misiles", weapons.tubes == tubes)
	_crew._store(PEER, 0)
	await _wait(0.1)
	DashSettings.current.stun_blocks_guns = false
	await _reset(1.0)
	_mech.energy.level = -0.1
	_mech.energy.settle()
	_crew._store(PEER, 1 << MechCrew.MISSILES)
	await _wait(0.15)
	_crew._store(PEER, 0)
	await _wait(0.1)
	_check("con su interruptor, las armas siguen", weapons.tubes == tubes - 1)
	DashSettings.current.stun_blocks_guns = true


func _toggle_off() -> void:
	DashSettings.current.stun_on = false
	await _reset(0.12)
	_hold()
	await _wait(2.6)
	_check("sin stun también queda en negativo", _mech.energy.level < 0.0)
	await _release()
	_check("sin stun, sigue andando", _mech.energy.able())
	DashSettings.current.stun_on = true


## LA CAPACIDAD Y LA RECARGA: una batería el doble de grande sigue llena, el súper cuesta lo mismo (la mitad de la barra
## que antes) y recarga a lo que diga su perilla.
func _battery() -> void:
	var knobs := DashSettings.current
	await _reset(1.0)
	knobs.energy_capacity = 200.0
	knobs.energy_refill = 10.0
	await _steps(3)
	print("batería de 200: nivel %.2f, llena %.2f" % [_mech.energy.level, _mech.energy.share()])
	_check("al agrandarla sigue llena", is_equal_approx(_mech.energy.level, 2.0) and is_equal_approx(_mech.energy.share(), 1.0))
	_hold()
	await _wait(2.5)
	await _release()
	var used := 2.0 - _mech.energy.level
	print("un súper gastó %.1f de energía, %.0f %% de la barra" % [used * MechEnergy.UNIT, used / 2.0 * 100.0])
	_check("el súper cuesta lo mismo en energía", used > 0.34 and used < 0.42)
	_check("y menos parte de la barra", absf(_mech.energy.share() - (1.0 - used / 2.0)) < 0.01)
	await _reset(0.0)
	_mech.energy.pause_refill()
	await _wait(0.9)
	var before := _mech.energy.level
	await _wait(1.0)
	var gained := _mech.energy.level - before
	print("recarga a 10 por segundo: %.1f en 1 s" % (gained * MechEnergy.UNIT))
	_check("recarga a lo de su perilla", gained > 0.09 and gained < 0.11)
	_mech.energy.level = 1.995
	await _wait(0.2)
	_check("no pasa de la capacidad", _mech.energy.level <= 2.0)
	_mech.energy.level = -0.5
	_check("la deuda se mide contra la barra", is_equal_approx(_mech.energy.debt_share(), 0.25))
	_mech.energy.level = 2.0
	knobs.energy_capacity = 100.0
	knobs.energy_refill = 14.0
	await _steps(3)


func _hold() -> void:
	_crew._store(PEER, 1 << MechCrew.ARM_LEFT)


func _release() -> void:
	_crew._store(PEER, 0)
	await _steps(4)


func _reset(level: float) -> void:
	_crew._store(PEER, 0)
	await _wait(0.4)
	_mech.energy.stunned = 0.0
	_mech.energy.level = level
	_cannon._wait = 0.0
	await _steps(2)


func _steps(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
