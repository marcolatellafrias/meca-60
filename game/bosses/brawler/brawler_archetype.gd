class_name BrawlerArchetype
extends SeededArchetype

## LA PARCELA DEL LUCHADOR DE ORUGAS (Brawler): el jefe en su arena (BossArena: un círculo del que no sale; los
## edificios, afuera; el medio, despejado) y, enfrente, UNA MECA, el blanco de su cabeza (BrawlerBrain). Los dos con vida
## (Health) y sus barras (FightBars). Mirándolos, la O posee a cualquiera de los dos.
##   · LA MECA ES LA JAULA (CageMech), con el equipo guardado de su fila (ver `swap_mech`). *Hasta el 17/11/2026 la K la
##     cambiaba entre cinco tipos de la meca grande (la de tres, física, mixta, cinemática y simplificada), borrada ese
##     día (el usuario: «limitarnos solamente a un approach de meca a una escala más humana»).*
##   · LA J: si el jefe piensa. LA L: qué ataques usa (todos, o uno solo, para probarlo).

## Lo que ocupa: la arena más grande del F1 y los edificios de afuera.
const FOOTPRINT := 500.0
const START := Vector3(0.0, 0.0, 30.0)
## Dónde está la meca (el punto del piso; mira al jefe).
const TARGET_AT := Vector3(0.0, 0.0, -50.0)
const BOSS_HEALTH := 400.0
const MECH_HEALTH := 100.0

## Si el jefe piensa (la J).
static var thinking := true


func _init() -> void:
	display_name = "Luchador de orugas"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func far_height() -> float:
	return 30.0


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"el jefe humanoide: el Luchador (ancho, la cabeza hundida) sobre orugas de tanque",
		"te rodea mirándote y TE EMBISTE: antes abre el horno (la ventana para pegarle)",
		"o GOLPEA EL PISO: la franja roja dice por dónde sale la onda (saltala o corréte)",
		"o ARRANCA EL PISO y te lo tira: el círculo rojo dice dónde cae (corréte); si no te pega, queda un rato",
		"de cerca, el TROMPO (alejate; después queda mareado con el horno abierto)",
		"o el AGARRE: la franja angosta se queda quieta y la mano sale derecho (salite de la franja); si te agarra, te revolea",
		"si llega al borde de la arena se estrella y queda aturdido, con el horno abierto",
		"el horno es el punto débil: una piña ahí le saca mucho; en el cuerpo, poco",
		"J el jefe piensa · L los ataques · O poseer la meca (o al jefe) · F1 las perillas",
		"poseído: W/S orugas, A/D girarlas, el mouse la cintura, Q el horno, G la ira",
	])


func keys() -> Array[SandboxKey]:
	return [
		SandboxKey.toggle(KEY_J, SandboxKey.Weight.MAIN, "el jefe piensa", func() -> bool: return thinking,
			func(_parcel: SandboxParcel, on: bool) -> void:
				thinking = on
				for brawler in _brawlers():
					var brain := brawler.get_node_or_null("Cabeza") as BrawlerBrain
					if brain != null:
						brain.awake = on),
		SandboxKey.cycle(KEY_L, SandboxKey.Weight.MAIN, "los poderes", BrawlerBrain.move_names(),
			func() -> int: return BrawlerBrain.moves + 1,
			func(_parcel: SandboxParcel, index: int) -> void: BrawlerBrain.moves = index - 1),
		SandboxKey.toggle(KEY_H, SandboxKey.Weight.NORMAL, "el horno abierto", func() -> bool: return _all(func(b: Brawler) -> bool: return b.furnace),
			func(_parcel: SandboxParcel, on: bool) -> void: _each(func(b: Brawler) -> void: b.furnace = on)),
		SandboxKey.toggle(KEY_P, SandboxKey.Weight.NORMAL, "con ira", func() -> bool: return _all(func(b: Brawler) -> bool: return b.rage),
			func(_parcel: SandboxParcel, on: bool) -> void: _each(func(b: Brawler) -> void: b.rage = on)),
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
	# LA CABEZA, y su blanco: la meca enfrente.
	var brain := BrawlerBrain.new()
	brain.name = "Cabeza"
	brain.awake = thinking
	boss.add_child(brain)
	var bars := FightBars.new()
	bars.name = "Barras"
	bars.boss = boss
	bars.boss_name = "LUCHADOR DE ORUGAS"
	root.add_child(bars)
	BrawlerArchetype.swap_mech(brain)
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


## PONE LA MECA (la jaula, CageMech, con el equipo guardado de su fila, como la arma su parcela: CageMechArchetype.build)
## enfrente del jefe, con la vida entera, en lugar de la que había: es el blanco de `brain`. Como lo aprendido con el
## jefe bola (ver docs/technical/pelea-jefes.md): la nueva nace cuando la vieja ya no está, y sin nada suelto encima; si
## no, el motor la despide a lo bruto. *Hasta el 17/11/2026 era la del tipo de la K (`kind`), de la meca grande.*
static func swap_mech(brain: BrawlerBrain) -> void:
	var boss := brain.get_parent() as Brawler
	var root := boss.get_parent() as Node3D
	var tree := root.get_tree()
	if brain.target != null and is_instance_valid(brain.target):
		var old := brain.target as Mech
		brain.target = null
		if old.keys != null and old.keys.driving:
			SandboxPossession.of(tree).release()
		if old.cabin != null:
			old.cabin.free_dummies()
		old.queue_free()
		await tree.physics_frame
		await tree.physics_frame
	var mech := CageMech.new()
	mech.equipment = CageMechArchetype.ROW
	mech.transform = Transform3D(Basis(), TARGET_AT + Vector3.UP * Mech.standing_height(mech.cabin_shape))
	root.add_child(mech)
	Health.attach(mech, MECH_HEALTH)
	brain.target = mech
	for bars: FightBars in root.find_children("*", "FightBars", false, false):
		bars.mech = mech


## Los Luchadores que hay (los paneles los avisan).
static func brawlers() -> Array[Brawler]:
	return _brawlers()


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
