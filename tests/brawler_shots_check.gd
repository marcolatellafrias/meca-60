extends Node

## LOS TIROS DE LA MECA DE TRES AL LUCHADOR (sin ventana, unos 20 segundos): la meca, enfrente y quieta, le tira con el
## cañón (simple, ráfaga y el rayo) y le pega con el taladro; de cada uno, cuánta vida le sacó (llegan por BossHurtbox:
## EnergyBolt.lands → take_hit). El jefe no piensa.

var _boss: Brawler = null
var _mech: ToolMech = null


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = false
	BrawlerSettings.current.rage.every = 0.0
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	await _wait(0.5)
	_mech = (_boss.get_node("Cabeza") as BrawlerBrain).target as ToolMech
	_mech.scripted = true
	for mode in [CannonTip.Mode.SIMPLE, CannonTip.Mode.BURST, CannonTip.Mode.BEAM]:
		await _place(40.0)
		var before := Health.of(_boss).left
		_mech.cannon.mode = mode
		_mech.cannon.lever = Vector2(0.0, 0.0)
		await _wait(0.8)
		_mech.cannon.trigger = true
		await _wait(2.0)
		_mech.cannon.trigger = false
		await _wait(1.0)
		print("cañón %s: le sacó %.1f" % [CannonTip.MODE_NAMES[mode], before - Health.of(_boss).left])
	# El taladro, si lo lleva (la meca jaula, sin nada guardado, lleva el palo: ver CageMech.default_arms).
	if _mech.drill == null:
		print("taladro: no lo lleva")
		get_tree().quit()
		return
	await _place(_boss_reach())
	var before := Health.of(_boss).left
	_mech.drill.charging = true
	await _wait(1.5)
	_mech.drill.charging = false
	_mech.drill.strike()
	await _wait(1.5)
	print("taladro: le sacó %.1f" % (before - Health.of(_boss).left))
	get_tree().quit()


## A cuánto de su medio queda la meca para que el taladro llegue (m): el frente de su caja, más lo que llega la punta
## desde el centro de la jaula (el taladro 4,7 m y la sierra 6,35: tests/spin_tips_movie). *Eran 9 m, el brazo de la
## meca grande: desde ahí la punta no llegaba y le sacaba 0.*
func _boss_reach() -> float:
	return Brawler.box().z * 0.5 + 4.0


func _place(gap: float) -> void:
	_boss.put(Transform3D(Basis(), Vector3.ZERO))
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -gap)))
	_mech.energy.level = 1.0
	_mech.energy.stunned = 0.0
	Health.of(_boss).left = BrawlerArchetype.BOSS_HEALTH
	await _wait(0.5)


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
