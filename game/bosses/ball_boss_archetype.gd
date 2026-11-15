class_name BallBossArchetype
extends SeededArchetype

## LA PARCELA DEL JEFE BOLA (BallBoss): la bola EN SU ARENA (BossArena: un círculo del que no sale, de radio en el F1; los
## edificios, afuera; el medio, despejado: el usuario, 15/11/2026, «por ahora sacamos los obstáculos entre medio de la
## arena»); una fila de cajas; y ENFRENTE, UNA MECA, el blanco de su cabeza (BallBrain).
## Los dos con vida (Health) y sus barras (FightBars). Mirándolos, la O posee a cualquiera de los dos.
##   · LA K CAMBIA LA MECA entre los cuatro tipos (el usuario: «quisiera que pueda cambiar entre los distintos tipos de
##     meca»), con los nombres que él les da:
##       FÍSICA: el torso y los brazos simulados (brazos con músculos).
##       MIXTA: el torso simulado y los brazos cinemáticos (de pose).
##       CINEMÁTICA: todo cinemático (el torso lo mueve el motor; brazos de pose; con cabina).
##       SIMPLIFICADA: la cinemática, sin brazos ni cabina.

## Lo que ocupa: la arena más grande del F1 (180 m de radio) y los edificios de afuera.
const FOOTPRINT := 420.0
const START := Vector3(0.0, 0.0, 30.0)
## Dónde está la meca simplificada, el blanco (el punto del piso; mira al jefe).
const TARGET_AT := Vector3(0.0, 0.0, -60.0)

## Si el jefe piensa (la P).
static var thinking := true

## LOS TIPOS DE MECA (la K): su nombre y cómo se arma.
enum Kind { PHYSICAL, MIXED, KINEMATIC, SIMPLE }
const KIND_NAMES := ["física", "mixta", "cinemática", "simplificada"]
const KINDS := {
	Kind.PHYSICAL: {"arms": Mech.Arms.MUSCLE, "kinematic": false, "cabin": true},
	Kind.MIXED: {"arms": Mech.Arms.POSE, "kinematic": false, "cabin": true},
	Kind.KINEMATIC: {"arms": Mech.Arms.POSE, "kinematic": true, "cabin": true},
	Kind.SIMPLE: {"arms": Mech.Arms.NONE, "kinematic": true, "cabin": false},
}
static var mech_kind := Kind.SIMPLE
## LA VIDA de cada uno.
const BOSS_HEALTH := 400.0
const MECH_HEALTH := 100.0
## Las cajas para pegarles: cuántas, su lado (m) y lo que pesan (kg).
const CRATES := 8
const CRATE := 3.0
const CRATE_MASS := 400.0


func _init() -> void:
	display_name = "Jefe bola"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func far_height() -> float:
	return 35.0


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"la bola con su rendija, el cañón que corre por ella y cuatro tentáculos",
		"más del doble de la meca; contra lo fijo es un cilindro, como la meca simplificada",
		"Shift hecha bola: rueda, dobla y pega a lo que toca (las cajas) · Q el barrido con las paletas",
		"P el jefe piensa o no (lo maneja la computadora: pelea a la meca) · K el tipo de meca · O poseer la meca o el jefe",
		"F1 las perillas · R todo de nuevo",
		"poseída: WASD, el mouse gira y sube o baja el cañón, Ctrl se agacha, espacio salta (sólo para arriba)",
		"clic izquierdo el tiro simple, clic derecho misiles del cielo uno tras otro",
	])


func keys() -> Array[SandboxKey]:
	return [
		SandboxKey.toggle(KEY_P, SandboxKey.Weight.MAIN, "el jefe piensa", func() -> bool: return thinking,
			func(parcel: SandboxParcel, on: bool) -> void:
				thinking = on
				for brain: BallBrain in parcel.find_children("*", "BallBrain", true, false):
					brain.awake = on),
		SandboxKey.cycle(KEY_K, SandboxKey.Weight.MAIN, "la meca", KIND_NAMES, func() -> int: return int(mech_kind),
			func(parcel: SandboxParcel, index: int) -> void:
				mech_kind = index as Kind
				for brain: BallBrain in parcel.find_children("*", "BallBrain", true, false):
					BallBossArchetype.swap_mech(brain, mech_kind)),
	]


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Jefe bola"
	parent.add_child(root)
	var boss := BallBoss.new()
	boss.name = "Bola"
	boss.position = START
	# Por donde salen sus tiros: un hijo fijo de la parcela, igual en todas las máquinas (ver ProjectileField).
	var field := ProjectileField.new()
	field.name = "Proyectiles"
	root.add_child(field)
	root.add_child(boss)
	boss.cannon.field = field
	Health.attach(boss, BOSS_HEALTH)
	# LA CABEZA DEL JEFE, y su blanco: la meca enfrente, del tipo de ahora (la K). O la posee, para pelear.
	var brain := BallBrain.new()
	brain.name = "Cabeza"
	brain.awake = thinking
	boss.add_child(brain)
	var bars := FightBars.new()
	bars.name = "Barras"
	bars.boss = boss
	bars.boss_name = "JEFE BOLA"
	root.add_child(bars)
	BallBossArchetype.swap_mech(brain, mech_kind)
	# LA ARENA: el anillo en el piso y, afuera, los edificios (lo fijo; el jefe no llega).
	var arena_radius := BallBossSettings.current.arena_radius
	boss.arena = BossArena.new(root, arena_radius)
	boss.arena.draw(root)
	var fixed := StaticBody3D.new()
	fixed.name = "Fijo"
	PhysicsLayers.mark_fixed(fixed)
	root.add_child(fixed)
	for i in 8:
		var out := Vector3.FORWARD.rotated(Vector3.UP, i * TAU / 8.0 + 0.3)
		var tall := 20.0 + (i % 3) * 10.0
		Clay.solid(fixed, Vector3(18.0, tall, 18.0), out * (arena_radius + 18.0) + Vector3.UP * tall * 0.5,
			Clay.METAL.lightened(0.1 + (i % 2) * 0.1), Basis(Vector3.UP, i * TAU / 8.0 + 0.3))
	# LO SUELTO: una fila de cajas adelante, para pegarles rodando (la R las vuelve a poner).
	var crates := Node3D.new()
	crates.name = "Cajas"
	root.add_child(crates)
	for i in CRATES:
		var crate := RigidBody3D.new()
		crate.mass = CRATE_MASS
		crate.position = Vector3((i - (CRATES - 1) * 0.5) * (CRATE + 2.0), CRATE * 0.5, -15.0)
		crates.add_child(crate)
		Clay.solid(crate, Vector3.ONE * CRATE, Vector3.ZERO, Clay.YELLOW.darkened(0.2 if i % 2 == 0 else 0.35))
	return root


## PONE LA MECA de tipo `kind` enfrente del jefe, con la vida entera, en lugar de la que había: es el blanco de `brain`.
static func swap_mech(brain: BallBrain, kind: Kind) -> void:
	var boss := brain.get_parent() as BallBoss
	var root := boss.get_parent()
	var tree := root.get_tree()
	if brain.target != null and is_instance_valid(brain.target):
		# Como la saca la Meca (Mech.rebuild_all): si se la poseía, se la suelta; los muñecos de su cabina, también.
		var old := brain.target as Mech
		brain.target = null
		if old.keys != null and old.keys.driving:
			SandboxPossession.of(tree).release()
		if old.cabin != null:
			old.cabin.free_dummies()
		old.queue_free()
		# LA NUEVA NACE CUANDO LA VIEJA YA NO ESTÁ: nacida encimada con la vieja (o con sus brazos con músculos), el motor
		# la despedía a lo bruto (pasó: salió volando a 340 m). Sacada del árbol antes de tiempo, algo suyo pedía su
		# lugar y fallaba.
		await tree.physics_frame
		await tree.physics_frame
	# Lo suelto que haya quedado donde va a nacer (las cajas desparramadas) se saca, por lo mismo.
	var room := BoxShape3D.new()
	room.size = Vector3(30.0, 40.0, 30.0)
	var cleared := false
	for body in AreaStrike.loose_in(root.get_world_3d().direct_space_state, room,
			Transform3D(Basis(), (root as Node3D).global_transform * (TARGET_AT + Vector3.UP * 20.0))):
		body.collision_layer = 0
		body.collision_mask = 0
		body.queue_free()
		cleared = true
	if cleared:
		await tree.physics_frame
	var shape: Dictionary = KINDS[kind]
	var mech := Mech.new()
	mech.arms_kind = shape["arms"]
	mech.kinematic = shape["kinematic"]
	mech.has_cabin = shape["cabin"]
	mech.transform = Transform3D(Basis(Vector3.UP, PI), TARGET_AT + Vector3.UP * Mech.standing_height())
	root.add_child(mech)
	# Se llama sola (por sus brazos); acá, por su tipo.
	mech.name = "Meca %s" % KIND_NAMES[kind]
	Health.attach(mech, MECH_HEALTH)
	brain.target = mech
	brain.landed = 0
	brain.last_hit = ""
	for bars: FightBars in root.find_children("*", "FightBars", false, false):
		bars.mech = mech
