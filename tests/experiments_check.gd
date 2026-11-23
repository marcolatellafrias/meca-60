extends Node

## LOS EXPERIMENTOS (con ventana, unos 5 s; Experiments): firmar cada contrato de prueba cambia las perillas del dash, de
## todos los jefes y del Luchador; firmar uno sin experimento vuelve a lo guardado; «Guardar» apunta al archivo del
## experimento. Y la ráfaga intocable: durante `burst_untouchable` ningún golpe la toca (CageMech.block_hit), después sí.
## Si ya hay un archivo guardado de un experimento, ése manda y sus números no se miden. Termina con EXPERIMENTOS OK o MAL.

const PEER := 999

var _bad := 0
var _mech: CageMech = null


func _ready() -> void:
	# Esta prueba es de las teclas: no depende de lo que el usuario tenga guardado en el F6.
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	get_window().size = Vector2i(640, 360)
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
	var saved_dash := (KnobsFile.load_into(DashSettings.new(), DashSettings.SAVED) as DashSettings).values()
	var position := ContractsCatalog.CONTRACTS.find_custom(func(c: Dictionary) -> bool:
		return c.get("experiment", "") == "posicion")
	var timing := ContractsCatalog.CONTRACTS.find_custom(func(c: Dictionary) -> bool:
		return c.get("experiment", "") == "timing")
	_check("hay los dos contratos de prueba", position >= 0 and timing >= 0)
	var mixed := ContractsCatalog.CONTRACTS.find_custom(func(c: Dictionary) -> bool:
		return c.get("experiment", "") == "mixto")
	_check("hay el contrato mixto", mixed >= 0)
	_check("sin contrato no hay experimento", ContractsCatalog.experiment_of(-1) == "")
	Experiments.follow(mixed, get_tree())
	if _fresh("mixto"):
		var b := BrawlerSettings.current
		_check("mixto: la ráfaga intocable y el sobrevuelo", DashSettings.current.style == DashSettings.Style.BOTH
			and is_equal_approx(DashSettings.current.burst_untouchable, 0.3))
		_check("mixto: marcas para las zonas", BossSettings.current.floor_marks)
		_check("mixto: los seis ataques", b.charge.in_calm and b.spin.in_calm and b.slam.in_calm and b.throw.in_calm
			and b.hook.in_calm and b.flame.in_calm and not b.bomb.in_calm)
	Experiments.follow(position, get_tree())
	_check("firmado: posición", Experiments.active == "posicion")
	_check("guarda en su archivo", Experiments.path_for(DashSettings.SAVED).ends_with("dash_settings_exp_posicion.tres"))
	if _fresh("posicion"):
		var b := BrawlerSettings.current
		_check("posición: sin intocable", DashSettings.current.burst_untouchable == 0.0)
		_check("posición: marcas en el piso", BossSettings.current.floor_marks)
		_check("posición: la onda, la piedra, el agarre y el lanzallamas",
			b.slam.in_calm and b.throw.in_calm and b.hook.in_calm and b.flame.in_calm)
		_check("posición: sin embestida ni trompo, tampoco con ira",
			not b.charge.in_calm and not b.charge.in_mode_1 and not b.spin.in_calm and not b.spin.in_mode_1)
	Experiments.follow(timing, get_tree())
	_check("firmado: tiempo", Experiments.active == "timing")
	if _fresh("timing"):
		var b := BrawlerSettings.current
		_check("tiempo: intocable 0,3 s y ráfaga de 5 m",
			is_equal_approx(DashSettings.current.burst_untouchable, 0.3) and is_equal_approx(DashSettings.current.burst_distance, 5.0))
		_check("tiempo: sin marcas en el piso", not BossSettings.current.floor_marks)
		_check("tiempo: la embestida y el trompo, nada más", b.charge.in_calm and b.spin.in_calm and not b.slam.in_calm
			and not b.throw.in_calm and not b.hook.in_calm and not b.flame.in_calm and not b.flame.in_mode_1)
		await _untouchable_check()
	Experiments.follow(-1, get_tree())
	_check("sin contrato: lo de siempre", Experiments.active == "" and DashSettings.current.values() == saved_dash)
	_check("sin contrato: guarda en el de siempre", Experiments.path_for(DashSettings.SAVED) == DashSettings.SAVED)
	print("EXPERIMENTOS OK" if _bad == 0 else "EXPERIMENTOS MAL (%d)" % _bad)
	get_tree().quit(_bad)


## La ráfaga intocable, con las perillas del experimento de tiempo.
func _untouchable_check() -> void:
	await _wait(0.8)
	var crew := _mech.get_node("Tripulacion") as MechCrew
	crew._store(PEER, 1 << MechCrew.D)
	await _steps(8)
	_check("caminando, un golpe la toca", not _mech.block_hit())
	crew._store(PEER, (1 << MechCrew.D) | (1 << MechCrew.DASH))
	await _steps(3)
	_check("en la ráfaga, intocable", _mech.block_hit())
	await _wait(DashSettings.current.burst_untouchable + 0.1)
	_check("pasado el rato, la toca", not _mech.block_hit())
	crew._store(PEER, 0)


func _fresh(id: String) -> bool:
	var exists := ResourceLoader.exists(Experiments.path_for(DashSettings.SAVED))
	if exists:
		print("el experimento «%s» ya tiene archivo guardado: manda ése, no se miden sus números" % id)
	return not exists


func _steps(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
