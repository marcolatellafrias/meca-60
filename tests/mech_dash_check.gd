extends Node

## EL DASH DE LA MECA (con ventana, unos 20 s): la ráfaga y el propulsor, con y sin inercia, midiendo lo que recorre, a qué
## velocidad va, lo que gasta y cómo termina. Sin caminar no sale, y apretado por dos tampoco. Termina con DASH OK o MAL.

const PEER := 999

var _bad := 0
var _mech: CageMech = null
var _crew: MechCrew = null
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
	_mech.loadout = Mech.fists()
	_mech.position = Vector3(0.0, Mech.standing_height(_mech.cabin_shape), 0.0)
	add_child(_mech)
	_run()


func _run() -> void:
	await _wait(0.8)
	_crew = _mech.get_node("Tripulacion") as MechCrew
	var knobs := DashSettings.current
	knobs.style = DashSettings.Style.BURST
	knobs.inertia = false
	knobs.burst_distance = 7.0
	knobs.burst_time = 0.1
	knobs.burst_cooldown = 0.5
	knobs.burst_cost = 20.0
	knobs.thrust_speed = 14.0
	knobs.thrust_drain = 45.0
	knobs.thrust_start = 5.0
	knobs.inertia_time = 0.4
	_check("el cuadrado dice la ráfaga", MechCrew.tip_of(MechCrew.DASH).begins_with("dash"))
	_crew._store(PEER, 1 << MechCrew.DASH)
	await _steps(6)
	_check("quieta, no sale", _mech.dasher.phase == MechDash.Phase.NONE and is_equal_approx(_mech.energy.level, 1.0))
	_crew._store(PEER, 0)
	await _steps(3)
	await _walk()
	var from := _mech.mover.global_position
	var energy := _mech.energy.level
	_crew._store(PEER, (1 << MechCrew.D) | (1 << MechCrew.DASH))
	await _steps(2)
	var top := _speed()
	var burst_steps := ceili(knobs.burst_time * Engine.physics_ticks_per_second)
	await _steps(burst_steps + 2)
	var dashed := from.distance_to(_mech.mover.global_position)
	var after := _speed()
	print("ráfaga: %.1f m/s, %.2f m, gastó %.2f, al terminar %.1f m/s (%d pasos por segundo)" % [top, dashed,
		energy - _mech.energy.level, after, Engine.physics_ticks_per_second])
	_check("la ráfaga va a 70 m/s", absf(top - 70.0) < 1.0)
	_check("la ráfaga recorre unos 7 m", dashed > 6.5 and dashed < 8.5)
	_check("la ráfaga gasta 0,2", absf(energy - _mech.energy.level - 0.2) < 0.02)
	_check("sin inercia corta en seco", absf(after - _mech.kinematic_settings().walk_speed) < 0.1)
	_crew._store(PEER, 0)
	await _refill()
	knobs.inertia = true
	_crew._store(PEER, (1 << MechCrew.D) | (1 << MechCrew.DASH))
	await _steps(ceili(knobs.burst_time * Engine.physics_ticks_per_second) + 3)
	var coast := _speed()
	await _wait(0.6)
	print("ráfaga con inercia: al terminar %.1f m/s, después %.1f" % [coast, _speed()])
	_check("con inercia sigue rápido al terminar", coast > 20.0)
	_check("con inercia vuelve a caminar", absf(_speed() - _mech.kinematic_settings().walk_speed) < 0.1)
	_crew._store(PEER, 0)
	await _refill()
	knobs.style = DashSettings.Style.THRUST
	knobs.inertia = false
	_check("el cuadrado dice el propulsor", MechCrew.tip_of(MechCrew.DASH).begins_with("propulsor"))
	energy = _mech.energy.level
	_crew._store(PEER, (1 << MechCrew.D) | (1 << MechCrew.DASH))
	await _wait(1.0)
	var thrust := _speed()
	var used := energy - _mech.energy.level
	print("propulsor: %.1f m/s, gastó %.2f en 1 s" % [thrust, used])
	_check("el propulsor va a 14 m/s", absf(thrust - 14.0) < 0.1)
	_check("el propulsor gasta mientras dura", used > 0.4 and used < 0.6)
	_crew._store(PEER, 1 << MechCrew.D)
	await _steps(3)
	_check("al soltar se acaba", absf(_speed() - _mech.kinematic_settings().walk_speed) < 0.1)
	_crew._store(PEER, 0)
	await _refill()
	knobs.inertia = true
	_crew._store(PEER, (1 << MechCrew.D) | (1 << MechCrew.DASH))
	await _wait(0.4)
	_crew._store(PEER, 1 << MechCrew.D)
	await _steps(3)
	var slowing := _speed()
	await _wait(0.6)
	print("propulsor con inercia: al soltar %.1f m/s, después %.1f" % [slowing, _speed()])
	_check("el propulsor con inercia frena de a poco", slowing > 8.0 and absf(_speed() - _mech.kinematic_settings().walk_speed) < 0.1)
	_crew._store(PEER, 0)
	await _refill()
	_crew._store(PEER, (1 << MechCrew.D) | (1 << MechCrew.DASH))
	_crew._store(PEER + 1, 1 << MechCrew.DASH)
	await _steps(5)
	_check("apretado por dos no sale", _mech.dasher.phase == MechDash.Phase.NONE)
	_crew._store(PEER, 0)
	_crew._store(PEER + 1, 0)
	knobs.load_values(_saved)
	print("DASH OK" if _bad == 0 else "DASH MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _walk() -> void:
	_crew._store(PEER, 1 << MechCrew.D)
	await _steps(8)


func _refill() -> void:
	await _wait(0.3)
	_mech.energy.level = 1.0
	_mech.energy.stunned = 0.0
	await _wait(0.6)
	await _walk()


func _speed() -> float:
	var v := _mech.mover.get_real_velocity()
	return Vector2(v.x, v.z).length()


func _steps(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
