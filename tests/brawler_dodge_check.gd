extends Node

## ESQUIVAR LA EMBESTIDA (sin ventana, unos 2 minutos): la meca cinemática contra el Luchador, que embiste desde
## `GAPS`. Cada manera de esquivar, cuántas veces la alcanzó: quieta; caminando de costado desde el aviso; caminando
## de costado desde que arranca; y el dash de costado cuando el jefe está a tantos metros (con y sin caminar después).
## También el golpe al piso (--solo-piso), la piedra de arrancar el piso (--solo-piedra), el trompo (--solo-trompo) y
## el agarre (--solo-agarre).
##   godot --headless --path . res://tests/brawler_dodge_check.tscn

const GAPS := [50.0, 80.0, 110.0]
## Sólo el golpe al piso (--solo-piso) o sólo la embestida (--solo-embestida).
const DASH_AT := [8.0, 16.0, 24.0, 32.0, 45.0]

var _boss: Brawler = null
var _brain: BrawlerBrain = null
var _mech: Mech = null


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = true
	BrawlerArchetype.mech_kind = BrawlerArchetype.Kind.KINEMATIC
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	_brain = _boss.get_node("Cabeza") as BrawlerBrain
	_mech = _brain.target as Mech
	await _wait(0.5)
	_mech.scripted = true
	var k := BrawlerSettings.current
	# Para probar otros números sin tocar las perillas: --homing=, --tiempo=, --aviso=, --dash=, --radio= (de la piedra).
	for argument in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=")
		if pair.size() != 2:
			continue
		match pair[0]:
			"homing": k.charge_homing = float(pair[1])
			"tiempo": k.charge_time = float(pair[1])
			"aviso": k.charge_windup = float(pair[1])
			"dash": KinematicSettings.current.dash_distance = float(pair[1])
			"radio": k.rock_radius = float(pair[1])
	print("la embestida: aviso %.2f s, %.0f m/s, corrige %.0f°/s · la meca: camina %.0f m/s, dash %.0f m en %.2f s" % [
		k.charge_windup, k.charge_speed, k.charge_homing, KinematicSettings.current.walk_speed,
		KinematicSettings.current.dash_distance, KinematicSettings.current.dash_time])
	var args := OS.get_cmdline_user_args()
	if args.has("--solo-trompo") or args.has("--solo-agarre"):
		if args.has("--solo-trompo"):
			await _spins(k)
		if args.has("--solo-agarre"):
			await _hooks(k)
		get_tree().quit()
		return
	if not args.has("--solo-piso") and not args.has("--solo-embestida"):
		await _throws(k)
	if args.has("--solo-piedra"):
		get_tree().quit()
		return
	for gap: float in ([] if args.has("--solo-piso") else GAPS):
		var line := "a %3.0f m:" % gap
		line += " quieta %s" % await _try(gap, "still", 0.0)
		line += " · camina desde el aviso %s" % await _try(gap, "walk_early", 0.0)
		line += " · camina desde que arranca %s" % await _try(gap, "walk_late", 0.0)
		print(line)
		var dash := "        dash a:"
		for at: float in DASH_AT:
			dash += " %2.0f m %s/%s/%s" % [at, await _try(gap, "dash", at), await _try(gap, "dash_walk", at),
				await _try(gap, "dash_twice", at)]
		print(dash + "   (sólo el dash / el dash y después camina / dos dashes seguidos)")
	if args.has("--solo-embestida"):
		get_tree().quit()
		return
	print("el golpe al piso: aviso %.2f s, la onda a %.0f m/s, %.0f de ancho · la meca salta %.0f m en %.2f s" % [
		k.slam_windup, k.wave_speed, k.wave_width, KinematicSettings.current.jump_height,
		KinematicSettings.current.jump_time])
	for gap: float in [40.0, 80.0, 115.0]:
		var line := "a %3.0f m:" % gap
		line += " quieta %s" % await _try_slam(gap, "still", 0.0)
		line += " · camina desde el aviso %s" % await _try_slam(gap, "walk_early", 0.0)
		line += " · camina desde el golpe %s" % await _try_slam(gap, "walk_late", 0.0)
		print(line)
		for how: String in ["jump", "dash"]:
			var row := "        %s cuando la onda está a:" % ("salta" if how == "jump" else "dash ")
			for at: float in [3.0, 8.0, 15.0, 25.0, 40.0]:
				row += " %2.0f m %s" % [at, await _try_slam(gap, how, at)]
			print(row)
	get_tree().quit()


## EL TROMPO: quieta, caminando para atrás desde el aviso, un dash para atrás al empezar a girar (solo, y después
## caminando, o dos), y un dash para atrás desde el aviso y después caminando.
func _spins(k: BrawlerSettings) -> void:
	print("el trompo: aviso %.2f s, gira %.1f s, los brazos a %.0f m, las orugas a %.0f m/s" % [k.spin_windup,
		k.spin_time, k.spin_reach, k.spin_move])
	for gap: float in [30.0, 45.0, 60.0]:
		var line := "a %3.0f m:" % gap
		for how: String in ["still", "walk", "dash", "dash_walk", "dash_twice", "dash_aim_walk"]:
			line += " %s %s" % [how, await _try_spin(gap, how)]
		print(line)


func _try_spin(gap: float, how: String) -> String:
	await _place(gap)
	var spun := _brain.spun
	_brain.awake = true
	await get_tree().physics_frame
	_brain._begin(BrawlerBrain.Act.SPIN)
	var dashes := 0
	var clock := 0.0
	while clock < 10.0 and _brain.act == BrawlerBrain.Act.SPIN and _brain.spun == spun:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_face_boss()
		var spinning := _brain.stage == "¡trompo!"
		var back := how == "walk" or (how != "still" and how != "dash" and dashes > 0)
		_mech.move = Vector2(0.0, -1.0) if back else Vector2.ZERO
		_mech.dash = false
		var wanted := 0
		if how == "dash_aim_walk":
			wanted = 1
		elif how.begins_with("dash") and spinning:
			wanted = 2 if how == "dash_twice" and _brain._clock > 0.6 else 1
		if dashes < wanted:
			dashes += 1
			_mech.move = Vector2(0.0, -1.0)
			_mech.dash = true
	_mech.move = Vector2.ZERO
	_mech.dash = false
	return "X" if _brain.spun > spun else "·"


## EL AGARRE: quieta, caminando de costado desde el aviso, desde que apuntó o desde que sale la mano, y el dash de
## costado cuando apuntó o cuando sale la mano.
func _hooks(k: BrawlerSettings) -> void:
	print("el agarre: aviso %.2f s, quieta %.2f s, la mano a %.0f m/s hasta %.0f m, franja de %.0f m" % [k.hook_windup,
		k.hook_lock, k.hook_speed, k.hook_reach, k.hook_width])
	for gap: float in [35.0, 55.0, 75.0]:
		var line := "a %3.0f m:" % gap
		for how: String in ["still", "walk_aim", "walk_lock", "walk_shot", "dash_lock", "dash_shot"]:
			line += " %s %s" % [how, await _try_hook(gap, how)]
		print(line)


func _try_hook(gap: float, how: String) -> String:
	await _place(gap)
	var grabbed := _brain.grabbed
	_brain.awake = true
	await get_tree().physics_frame
	_brain._begin(BrawlerBrain.Act.HOOK)
	var dashed := false
	var clock := 0.0
	while clock < 8.0 and _brain.act == BrawlerBrain.Act.HOOK and _brain.grabbed == grabbed:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_face_boss()
		var locked := _brain._step > 0 or _brain.stage.ends_with("apuntó!")
		var shot := _brain._step > 0
		var walk := how == "walk_aim" or (how == "walk_lock" and locked) or (how == "walk_shot" and shot)
		_mech.move = Vector2(1.0, 0.0) if walk else Vector2.ZERO
		_mech.dash = false
		if not dashed and ((how == "dash_lock" and locked) or (how == "dash_shot" and shot)):
			dashed = true
			_mech.move = Vector2(1.0, 0.0)
			_mech.dash = true
	_mech.move = Vector2.ZERO
	_mech.dash = false
	var hit := _brain.grabbed > grabbed
	# Que termine el revoleo antes de la próxima.
	await _wait(5.0)
	return "X" if hit else "·"


func _face_boss() -> void:
	var to_boss := _boss.global_position - _mech.mover.global_position
	_mech.aim_yaw = atan2(-to_boss.x, -to_boss.z)


## ARRANCAR EL PISO: quieta, caminando de costado desde el aviso o desde el tiro, y el dash a tantos segundos del tiro.
func _throws(k: BrawlerSettings) -> void:
	print("la piedra: aviso %.2f s, vuela %.2f s, radio %.0f m" % [k.lift_time, k.rock_flight, k.rock_radius])
	for gap: float in [40.0, 80.0, 120.0]:
		var line := "a %3.0f m:" % gap
		line += " quieta %s" % await _try_throw(gap, "still", 0.0)
		line += " · camina desde el aviso %s" % await _try_throw(gap, "walk_early", 0.0)
		line += " · camina desde el tiro %s" % await _try_throw(gap, "walk_late", 0.0)
		var row := " · dash a los"
		for at: float in [0.0, 0.4, 0.8, 1.1]:
			row += " %.1f s %s" % [at, await _try_throw(gap, "dash", at)]
		print(line + row + " del tiro")


## Una piedra desde `gap`; devuelve «X» si le cayó encima, «·» si no.
func _try_throw(gap: float, how: String, at: float) -> String:
	await _place(gap)
	var rocked := _brain.rocked
	var throws := _brain.throws
	_brain.awake = true
	await get_tree().physics_frame
	_brain._begin(BrawlerBrain.Act.THROW)
	var since := -1.0
	var done := false
	var clock := 0.0
	while clock < 8.0 and _brain.rocked == rocked and (_brain.act == BrawlerBrain.Act.THROW or not _brain._rocks.is_empty()):
		await get_tree().physics_frame
		var delta := 1.0 / Engine.physics_ticks_per_second
		clock += delta
		var ground := _mech.mover.global_position
		var to_boss := _boss.global_position - ground
		to_boss.y = 0.0
		_mech.aim_yaw = atan2(-to_boss.x, -to_boss.z)
		if _brain.throws > throws:
			since = 0.0 if since < 0.0 else since + delta
		_mech.move = Vector2(1.0, 0.0) if how == "walk_early" or (how == "walk_late" and since >= 0.0) else Vector2.ZERO
		_mech.dash = false
		if how == "dash" and not done and since >= at:
			done = true
			_mech.move = Vector2(1.0, 0.0)
			_mech.dash = true
	_mech.move = Vector2.ZERO
	_mech.dash = false
	return "X" if _brain.rocked > rocked else "·"


## Un golpe al piso desde `gap`; devuelve «X» si la onda la alcanzó, «·» si no.
func _try_slam(gap: float, how: String, at: float) -> String:
	await _place(gap)
	var waved := _brain.waved
	var slams := _brain.slams
	_brain.awake = true
	await get_tree().physics_frame
	_brain._begin(BrawlerBrain.Act.SLAM)
	var done := false
	var clock := 0.0
	while clock < 8.0 and _brain.waved == waved and (_brain.act == BrawlerBrain.Act.SLAM or _live_waves()):
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		var ground := _mech.mover.global_position
		var to_boss := _boss.global_position - ground
		to_boss.y = 0.0
		_mech.aim_yaw = atan2(-to_boss.x, -to_boss.z)
		var slammed := _brain.slams > slams
		_mech.move = Vector2(1.0, 0.0) if how == "walk_early" or (how == "walk_late" and slammed) else Vector2.ZERO
		_mech.jump = false
		_mech.dash = false
		if _brain._waves.is_empty() or done or not is_instance_valid(_brain._waves[0]):
			continue
		var wave: BrawlerWave = _brain._waves[0]
		if not wave.launched:
			continue
		var left := wave.way.dot(ground - wave.origin) - wave.front - BrawlerWave.RIDGE.y * 0.5 - 4.0
		if left <= at:
			done = true
			if how == "jump":
				_mech.jump = true
			elif how == "dash":
				_mech.move = Vector2(1.0, 0.0)
				_mech.dash = true
	_mech.move = Vector2.ZERO
	_mech.jump = false
	_mech.dash = false
	if OS.get_cmdline_user_args().has("--ver") and _brain.waved > waved:
		print("   %s %.0f a %.0f m: a los %.2f s; la meca, a %.1f del medio de la onda; dash %s" % [how, at, gap, clock,
			_mech.mover.global_position.x, "usado" if (_mech.mover as KinematicMover).dash_fuel < 0.9 else "no"])
	return "X" if _brain.waved > waved else "·"


func _live_waves() -> bool:
	for wave in _brain._waves:
		if is_instance_valid(wave):
			return true
	return false


func _place(gap: float) -> void:
	_brain.awake = false
	for wave in _brain._waves:
		if is_instance_valid(wave):
			wave.queue_free()
	_brain._waves.clear()
	for rock in _brain._rocks:
		if is_instance_valid(rock):
			rock.queue_free()
	_brain._rocks.clear()
	for rock in _brain.get_parent().get_parent().find_children("Piedra*", "BrawlerRock", false, false):
		rock.queue_free()
	await _wait(0.1)
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, gap * 0.5)))
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, Mech.standing_height(), -gap * 0.5)))
	Health.of(_mech).left = BrawlerArchetype.MECH_HEALTH
	(_mech.mover as KinematicMover).dash_fuel = 1.0
	await _wait(0.6)


## Una embestida desde `gap`; devuelve «X» si la alcanzó, «·» si no.
func _try(gap: float, how: String, dash_at: float) -> String:
	_brain.awake = false
	await _wait(0.1)
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, gap * 0.5)))
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, Mech.standing_height(), -gap * 0.5)))
	Health.of(_mech).left = BrawlerArchetype.MECH_HEALTH
	(_mech.mover as KinematicMover).dash_fuel = 1.0
	await _wait(0.3)
	var landed := _brain.landed
	var charges := _brain.charges
	_brain.awake = true
	await get_tree().physics_frame
	_brain._begin(BrawlerBrain.Act.CHARGE)
	var dashed := false
	var again := 0.0
	var clock := 0.0
	while clock < 8.0 and _brain.act == BrawlerBrain.Act.CHARGE and _brain.landed == landed:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		var ground := _mech.mover.global_position
		var to_boss := _boss.global_position - ground
		to_boss.y = 0.0
		_mech.aim_yaw = atan2(-to_boss.x, -to_boss.z)
		var started := _brain.charges > charges
		var walk := how == "walk_early" or (how == "walk_late" and started) or (how == "dash_walk" and dashed)
		_mech.move = Vector2(1.0, 0.0) if walk else Vector2.ZERO
		_mech.dash = false
		if how == "dash_twice" and dashed and again >= 0.0:
			again += 1.0 / Engine.physics_ticks_per_second
			_mech.move = Vector2(1.0, 0.0)
			if again > KinematicSettings.current.dash_time + 0.05:
				_mech.dash = true
				again = -1.0
		if how.begins_with("dash") and started and not dashed and to_boss.length() - Brawler.BOX.z * 0.5 <= dash_at:
			dashed = true
			_mech.move = Vector2(1.0, 0.0)
			_mech.dash = true
	_mech.move = Vector2.ZERO
	_mech.dash = false
	if OS.get_cmdline_user_args().has("--ver") and _brain.landed > landed:
		var off := _mech.mover.global_position - _boss.global_position
		off.y = 0.0
		print("   %s %.0f: a los %.2f s, adelante %.1f, de costado %.1f, el jefe a %.0f m/s; la meca se corrió %.1f" % [how,
			dash_at, clock, _boss.heading().dot(off), absf(_boss.heading().cross(Vector3.UP).dot(off)), _boss.speed,
			absf(_mech.mover.global_position.x)])
	return "X" if _brain.landed > landed else "·"


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
