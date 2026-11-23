extends Node

## EL RETROCESO (con ventana, unos 25 s): con batería negativa no se empieza otra carga; el cañón tira plano y empuja hacia
## atrás según la carga, sin quitar el control; el propulsor hacia adelante lo contrarresta; la ametralladora frena sólo el
## avance hacia el frente. No guarda nada. Termina con RETROCESO OK o RETROCESO MAL.

const PEER := 999

var _bad := 0
var _mech: CageMech = null
var _crew: MechCrew = null
var _cannon: CannonTip = null
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
		ArmLoadout.of(ArmLoadout.Tip.FIST)]
	_mech.position = Vector3(0.0, Mech.standing_height(_mech.cabin_shape), 0.0)
	add_child(_mech)
	_run()


func _run() -> void:
	await _wait(0.8)
	_crew = _mech.get_node("Tripulacion") as MechCrew
	_cannon = _mech.arms[0].tip as CannonTip
	var knobs := DashSettings.current
	knobs.stun_on = true
	knobs.stun_time = 1.2
	knobs.recoil_on = true
	knobs.cannon_recoil = 3.0
	knobs.tap_recoil = 0.5
	knobs.recoil_time = 0.35
	knobs.minigun_slow = 0.35
	knobs.style = DashSettings.Style.THRUST
	knobs.thrust_speed = 14.0
	knobs.inertia = false
	await _no_chain()
	await _full_recoil()
	await _tap_recoil()
	await _thrust_counters()
	await _still_controls()
	await _minigun_slows()
	await _toggle_off()
	knobs.load_values(_saved)
	print("RETROCESO OK" if _bad == 0 else "RETROCESO MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _no_chain() -> void:
	await _reset(0.12)
	_hold()
	await _wait(2.6)
	await _release()
	_check("el súper la deja en negativo y con stun", _mech.energy.level < 0.0 and not _mech.energy.able())
	await _wait(1.3)
	_check("pasó el stun, sigue en negativo", _mech.energy.able() and _mech.energy.level < 0.0)
	var bolts := EnergyBolt.made
	_hold()
	await _wait(0.5)
	_check("en negativo no empieza otra carga", is_zero_approx(_cannon.charge))
	await _release()
	_check("en negativo tampoco sale un toque", EnergyBolt.made == bolts)
	_mech.energy.level = 0.2
	_hold()
	await _wait(0.3)
	_check("con su primer segmento sí se puede volver a cargar", _cannon.charge > 0.05)
	await _release()


func _full_recoil() -> void:
	await _reset(1.0)
	_hold()
	await _wait(2.6)
	var from := _mech.mover.global_position
	var back := _back()
	await _release()
	var shot := _last_bolt()
	if shot != null:
		print("tiro: para arriba %.4f" % (-shot.global_basis.z).y)
		_check("el tiro sale plano", absf((-shot.global_basis.z).y) < 0.001)
	await _wait(0.7)
	var moved := (_mech.mover.global_position - from).dot(back)
	print("a fondo: retrocedió %.2f m" % moved)
	_check("a fondo retrocede unos 3 m", moved > 2.6 and moved < 3.4)
	_check("el retroceso se termina", _mech.mover.recoil.is_zero_approx())


func _tap_recoil() -> void:
	await _reset(1.0)
	var from := _mech.mover.global_position
	var back := _back()
	_hold()
	await _wait(0.9)
	await _release()
	await _wait(0.6)
	var moved := (_mech.mover.global_position - from).dot(back)
	print("primer segmento: retrocedió %.2f m" % moved)
	_check("el primer segmento retrocede poco", moved > 0.3 and moved < 0.7)


func _thrust_counters() -> void:
	await _reset(1.0)
	var back := _back()
	var forward := _screen_slot(-back)
	_hold()
	await _wait(1.3)
	var from := _mech.mover.global_position
	_crew._store(PEER, (1 << MechCrew.ARM_LEFT) | (1 << forward) | (1 << MechCrew.DASH))
	await _steps(3)
	_crew._store(PEER, (1 << forward) | (1 << MechCrew.DASH))
	await _wait(0.2)
	var moved := (_mech.mover.global_position - from).dot(-back)
	print("con propulsor al frente: avanzó %.2f m mientras disparaba" % moved)
	_check("el propulsor gana contra el retroceso", moved > 0.3)
	_crew._store(PEER, 0)


func _still_controls() -> void:
	await _reset(1.0)
	var back := _back()
	var side := back.cross(Vector3.UP).normalized()
	var slot := _screen_slot(side)
	_hold()
	await _steps(3)
	await _release()
	var from := _mech.mover.global_position
	_crew._store(PEER, 1 << slot)
	await _wait(0.25)
	var moved := (_mech.mover.global_position - from).dot(side)
	print("caminando de costado durante el retroceso: %.2f m" % moved)
	_check("durante el retroceso se sigue manejando", moved > 0.6)
	_crew._store(PEER, 0)


func _minigun_slows() -> void:
	await _reset(1.0)
	var back := _back()
	var forward := _screen_slot(-back)
	var backward := _screen_slot(back)
	_crew._store(PEER, 1 << forward)
	await _wait(0.2)
	var plain := _speed()
	_crew._store(PEER, (1 << forward) | (1 << MechCrew.MINIGUN))
	await _wait(1.2)
	var slowed := _speed()
	print("al frente: %.2f m/s, disparando %.2f" % [plain, slowed])
	_check("disparando avanza menos", absf(slowed - plain * 0.65) < 0.15)
	_crew._store(PEER, (1 << backward) | (1 << MechCrew.MINIGUN))
	await _wait(0.2)
	var away := _speed()
	print("hacia atrás disparando: %.2f m/s" % away)
	_check("hacia atrás no la frena", absf(away - plain) < 0.15)
	_crew._store(PEER, 0)
	_mech.guns.weapons.heat = 0.0


func _toggle_off() -> void:
	DashSettings.current.recoil_on = false
	await _reset(1.0)
	var from := _mech.mover.global_position
	_hold()
	await _wait(1.3)
	await _release()
	await _wait(0.5)
	_check("apagado no retrocede", from.distance_to(_mech.mover.global_position) < 0.05)
	DashSettings.current.recoil_on = true


## La tecla de caminar más alineada con `way` (la meca mira donde mira; la pantalla, según su giro).
func _screen_slot(way: Vector3) -> int:
	var best := MechCrew.W
	var score := -2.0
	var options := {MechCrew.W: Vector2(0, 1), MechCrew.S: Vector2(0, -1), MechCrew.A: Vector2(-1, 0), MechCrew.D: Vector2(1, 0)}
	for slot: int in options:
		var dot := IsoSettings.current.screen_to_world(options[slot]).dot(way)
		if dot > score:
			score = dot
			best = slot
	return best


func _back() -> Vector3:
	var back := _mech.global_basis.z
	back.y = 0.0
	return back.normalized()


func _speed() -> float:
	var v := _mech.mover.get_real_velocity()
	return Vector2(v.x, v.z).length()


func _last_bolt() -> EnergyBolt:
	var found := get_tree().root.find_children("*", "EnergyBolt", true, false)
	return null if found.is_empty() else found[-1] as EnergyBolt


func _hold() -> void:
	_crew._store(PEER, 1 << MechCrew.ARM_LEFT)


func _release() -> void:
	_crew._store(PEER, 0)
	await _steps(4)


func _reset(level: float) -> void:
	_crew._store(PEER, 0)
	await _wait(0.6)
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
