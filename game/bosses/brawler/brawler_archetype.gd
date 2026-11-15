class_name BrawlerArchetype
extends SeededArchetype

## LA PARCELA DEL LUCHADOR DE ORUGAS (Brawler): el jefe en su arena (BossArena: un círculo del que no sale; los
## edificios, afuera; el medio, despejado) y, enfrente, la meca simplificada para la escala (todavía no pelean). Los dos
## con vida (Health) y sus barras (FightBars). Mirándolo, la O lo posee.

## Lo que ocupa: la arena más grande del F1 y los edificios de afuera.
const FOOTPRINT := 500.0
const START := Vector3(0.0, 0.0, 30.0)
## Dónde está la meca (el punto del piso; mira al jefe).
const TARGET_AT := Vector3(0.0, 0.0, -50.0)
const BOSS_HEALTH := 400.0
const MECH_HEALTH := 100.0


func _init() -> void:
	display_name = "Luchador de orugas"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func far_height() -> float:
	return 30.0


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"el jefe humanoide: el Luchador (ancho, la cabeza hundida) sobre orugas de tanque",
		"paso 1: cómo se mueve (sin ataques): las orugas arrancan pesado, la cintura gira aparte",
		"el horno del pecho, con la puerta para arriba: el punto débil · con ira, humo negro",
		"no sale de la arena (el anillo) · enfrente, la meca simplificada, para la escala",
		"O poseerlo: W/S orugas, A/D girarlas, el mouse la cintura, Q el horno, G la ira · F1 las perillas",
	])


func keys() -> Array[SandboxKey]:
	return [
		SandboxKey.toggle(KEY_H, SandboxKey.Weight.MAIN, "el horno abierto", func() -> bool: return _all(func(b: Brawler) -> bool: return b.furnace),
			func(on: bool) -> void: _each(func(b: Brawler) -> void: b.furnace = on)),
		SandboxKey.toggle(KEY_P, SandboxKey.Weight.MAIN, "con ira", func() -> bool: return _all(func(b: Brawler) -> bool: return b.rage),
			func(on: bool) -> void: _each(func(b: Brawler) -> void: b.rage = on)),
	]


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Luchador de orugas"
	parent.add_child(root)
	var boss := Brawler.new()
	boss.name = "Luchador"
	boss.position = START
	boss.rotation.y = PI
	root.add_child(boss)
	Health.attach(boss, BOSS_HEALTH)
	var arena_radius := BrawlerSettings.current.arena_radius
	boss.arena = BossArena.new(root, arena_radius)
	boss.arena.draw(root)
	# LA META, ENFRENTE: la simplificada (cinemática, sin brazos ni cabina).
	var mech := Mech.new()
	mech.arms_kind = Mech.Arms.NONE
	mech.kinematic = true
	mech.has_cabin = false
	mech.transform = Transform3D(Basis(), TARGET_AT + Vector3.UP * Mech.standing_height())
	root.add_child(mech)
	mech.name = "Meca simplificada"
	Health.attach(mech, MECH_HEALTH)
	var bars := FightBars.new()
	bars.name = "Barras"
	bars.boss = boss
	bars.boss_name = "LUCHADOR DE ORUGAS"
	bars.mech = mech
	root.add_child(bars)
	# AFUERA, LOS EDIFICIOS (lo fijo; el jefe no llega).
	var fixed := StaticBody3D.new()
	fixed.name = "Fijo"
	PhysicsLayers.mark_fixed(fixed)
	root.add_child(fixed)
	for i in 8:
		var out := Vector3.FORWARD.rotated(Vector3.UP, i * TAU / 8.0 + 0.3)
		var tall := 20.0 + (i % 3) * 10.0
		Clay.solid(fixed, Vector3(18.0, tall, 18.0), out * (arena_radius + 18.0) + Vector3.UP * tall * 0.5,
			Clay.METAL.lightened(0.1 + (i % 2) * 0.1), Basis(Vector3.UP, i * TAU / 8.0 + 0.3))
	return root


static func _brawlers() -> Array[Brawler]:
	var out: Array[Brawler] = []
	var tree := Engine.get_main_loop() as SceneTree
	for node in tree.get_nodes_in_group(SandboxPossession.GROUP):
		if node is Brawler:
			out.append(node)
	return out


static func _all(test: Callable) -> bool:
	var found := _brawlers()
	if found.is_empty():
		return false
	for brawler in found:
		if not test.call(brawler):
			return false
	return true


static func _each(change: Callable) -> void:
	for brawler in _brawlers():
		change.call(brawler)
