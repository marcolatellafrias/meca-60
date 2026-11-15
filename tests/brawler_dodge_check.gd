extends Node

## ESQUIVAR LA EMBESTIDA (sin ventana, unos 2 minutos): la meca cinemática contra el Luchador, que embiste desde
## `GAPS`. Cada manera de esquivar, cuántas veces la alcanzó: quieta; caminando de costado desde el aviso; caminando
## de costado desde que arranca; y el dash de costado cuando el jefe está a tantos metros (con y sin caminar después).
##   godot --headless --path . res://tests/brawler_dodge_check.tscn

const GAPS := [50.0, 80.0, 110.0]
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
	# Para probar otros números sin tocar las perillas: --homing=, --tiempo=, --aviso=, --dash=.
	for argument in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=")
		if pair.size() != 2:
			continue
		match pair[0]:
			"homing": k.charge_homing = float(pair[1])
			"tiempo": k.charge_time = float(pair[1])
			"aviso": k.charge_windup = float(pair[1])
			"dash": KinematicSettings.current.dash_distance = float(pair[1])
	print("la embestida: aviso %.2f s, %.0f m/s, corrige %.0f°/s · la meca: camina %.0f m/s, dash %.0f m en %.2f s" % [
		k.charge_windup, k.charge_speed, k.charge_homing, KinematicSettings.current.walk_speed,
		KinematicSettings.current.dash_distance, KinematicSettings.current.dash_time])
	for gap: float in GAPS:
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
	get_tree().quit()


## Una embestida desde `gap`; devuelve «X» si la alcanzó, «·» si no.
func _try(gap: float, how: String, dash_at: float) -> String:
	_brain.awake = false
	await _wait(0.1)
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, gap * 0.5)))
	_mech.put(Transform3D(Basis(), Vector3(0.0, Mech.standing_height(), -gap * 0.5)))
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
