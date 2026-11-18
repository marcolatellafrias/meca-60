extends Node

## LOS MODOS DE UN JEFE (sin ventana, unos 30 segundos): el Luchador entra en cada modo (BossMode) y se mira lo que
## cambia: qué poderes puede usar (los que tilda el modo y no piden lo que le falta), a qué altura va (el vuelo), que
## vuelva al piso al salir, y un salto (Brawler.jump). Imprime cada cosa.

var _boss: Brawler = null
var _brain: BrawlerBrain = null


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = true
	var k := BrawlerSettings.current
	k.rage.every = 0.0
	k.flight.on = true
	k.flight.every = 0.0
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	_brain = _boss.get_node("Cabeza") as BrawlerBrain
	await _wait(1.0)
	for index in [-1, 0, 1]:
		_brain.enter_mode(index)
		await _wait(4.0)
		var now := _brain.mode_now()
		print("%s: a %.1f m de alto · %.2f veces más rápido · usa: %s" % [now.title if now != null else "tranquilo",
			_boss.global_position.y, _boss.hurry, ", ".join(_usable())])
	_brain.enter_mode(-1)
	await _wait(4.0)
	print("de vuelta tranquilo: a %.1f m de alto, en el aire %s" % [_boss.global_position.y, _boss.aloft()])
	_brain.awake = false
	await _wait(0.3)
	var from := _boss.global_position
	_boss.jump(from + Vector3(40.0, 0.0, 0.0), 1.2, 25.0)
	var top := 0.0
	var landed := false
	var clock := 0.0
	while clock < 2.0 and not landed:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		top = maxf(top, _boss.global_position.y)
		landed = _boss.landed_now
	print("salto: cayó %s a los %.2f s, a %.1f m de donde salió, subió hasta %.1f m" % [landed, clock,
		_boss.global_position.distance_to(from), top])
	get_tree().quit()


## Los poderes que podría usar ahora (su modo y sus piezas), sin mirar la distancia.
func _usable() -> PackedStringArray:
	var names := PackedStringArray()
	for power in _brain.powers:
		if power.used_in(_brain.mode) and _boss.lacks_now(power.needs()).is_empty():
			names.append(power.title())
	return names


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
