class_name ArmoryParts
extends RefCounted

## LOS COMPONENTES DE LA ARMERÍA EN ARCILLA (ver ArmoryCatalog y docs/technical/sucursal.md): maquetas de forma, una por
## cosa que se vende, a la escala de la meca (el antebrazo de MechBody, la mano de MechHand). Lo pidió el usuario el
## 15/11/2026: «empecemos a hacer maquetas de clay de todos los componentes».
##
## Cada una se arma en el marco de su soporte:
##   · LO DEL BRAZO, en el del ANTEBRAZO: su centro en el origen, el largo por Z y la mano hacia −Z; +Y arriba y +X
##     afuera (es un brazo derecho). El puño es la mano de la meca cerrada; la herramienta se le suma sin taparlo: el
##     taladro arriba del antebrazo, el cañón abajo y la sierra afuera, al costado del puño.
##   · LO DE LA ESPALDA, sobre su montura: el origen en el techo, el caño hacia −Z.
##   · LAS PLACAS, sobre la parte que cubren (que la maqueta también dibuja).

const STEEL := Color(0.68, 0.7, 0.72)
const PLATE := Color(0.6, 0.62, 0.62)
const ENERGY := Color(0.55, 0.8, 0.85)
const FOREARM_COLOR := Color(0.47, 0.49, 0.52)
## El antebrazo y la mano de la meca, en su medida base.
const FOREARM := 5.5
const ARM_HALF := 1.05


## Arma la maqueta de `id` (ver ArmoryCatalog) colgada de `parent`, con su soporte.
static func build(id: String, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = id
	parent.add_child(root)
	match id:
		"fist", "heavy_fist", "drill", "energy_cannon", "circular_saw":
			_forearm(root, id == "heavy_fist")
			match id:
				"drill": _drill(root)
				"energy_cannon": _energy_cannon(root)
				"circular_saw": _saw(root)
		"machine_gun", "missile_launcher", "heavy_cannon":
			_back_mount(root)
			match id:
				"machine_gun": _machine_gun(root)
				"missile_launcher": _missile_launcher(root)
				"heavy_cannon": _heavy_cannon(root)
		"plate_hull": _hull_plate(root)
		"plate_arm": _arm_plate(root)
		"plate_leg": _leg_plate(root)
	return root


## ── EL BRAZO ────────────────────────────────────────────────────────────────────────────────────────────────────

## El antebrazo y la mano cerrada. El puño pesado es la misma mano, más grande, con un pinche (un cono) en cada nudillo.
static func _forearm(root: Node3D, heavy: bool) -> void:
	Clay.limb(root, ARM_HALF, FOREARM, Vector3.ZERO, FOREARM_COLOR)
	Clay.sphere(root, ARM_HALF * 1.25, Vector3(0, 0, FOREARM * 0.5), MechBody.JOINT_COLOR)
	var hand := MechHand.build(root, 1.0)
	hand.fist = true
	hand.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0, -FOREARM * 0.5))
	if not heavy:
		return
	hand.scale = Vector3.ONE * 1.3
	# los nudillos: donde cada dedo sale de la palma, al frente
	for finger in 4:
		var y := (finger - 1.5) * MechHand.FINGER_RADIUS * 2.2
		_cone(hand, 0.17, 0.5, Vector3(0, y, -MechHand.PALM.z - MechHand.FINGER_RADIUS - 0.2), Vector3(-90, 0, 0),
			Clay.DARK.lightened(0.15))


## EL TALADRO: arriba del antebrazo, la mecha pasa por encima del puño.
static func _drill(root: Node3D) -> void:
	var y := ARM_HALF + 0.55
	Clay.cylinder(root, 0.6, 4.2, Vector3(0, y, -0.4), Clay.METAL.darkened(0.1), Vector3(90, 0, 0))
	Clay.box(root, Vector3(0.7, 0.5, 2.0), Vector3(0, ARM_HALF + 0.1, 0.2), MechBody.JOINT_COLOR)
	Clay.cylinder(root, 0.78, 0.5, Vector3(0, y, -2.7), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	_cone(root, 0.55, 3.0, Vector3(0, y, -4.45), Vector3(-90, 0, 0), STEEL)
	# la espiral, en anillos que se achican hacia la punta
	for i in 4:
		var t := i / 4.0
		Clay.cylinder(root, lerpf(0.55, 0.18, t) + 0.06, 0.1, Vector3(0, y, -3.2 - t * 2.4), STEEL.darkened(0.25),
			Vector3(90, 0, 18))


## EL CAÑÓN DE ENERGÍA: abajo del antebrazo, con tres bobinas que se ven de lejos.
static func _energy_cannon(root: Node3D) -> void:
	var y := -ARM_HALF - 0.5
	Clay.box(root, Vector3(1.2, 0.9, 3.4), Vector3(0, y, 0.2), Clay.METAL.darkened(0.12))
	Clay.cylinder(root, 0.34, 3.8, Vector3(0, y, -3.2), Clay.DARK, Vector3(90, 0, 0))
	for z: float in [-2.1, -2.8, -3.5]:
		Clay.cylinder(root, 0.55, 0.22, Vector3(0, y, z), ENERGY, Vector3(90, 0, 0))
	Clay.cylinder(root, 0.46, 0.35, Vector3(0, y, -5.0), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	# el cable que le lleva la energía, por el costado
	Clay.box(root, Vector3(0.22, 0.22, 3.0), Vector3(0.7, y + 0.35, 0.8), Clay.DARK)


## LA SIERRA: un disco al costado de afuera, adelante del puño, con su brazo y su motor.
static func _saw(root: Node3D) -> void:
	var x := ARM_HALF + 0.45
	var at := Vector3(x + 0.35, 0.2, -4.0)
	Clay.box(root, Vector3(0.35, 0.6, 3.6), Vector3(x, 0.2, -2.0), Clay.METAL.darkened(0.1))
	Clay.cylinder(root, 0.6, 0.8, Vector3(x, 0.2, -4.0), MechBody.JOINT_COLOR, Vector3(0, 0, 90))
	Clay.cylinder(root, 1.8, 0.1, at, STEEL, Vector3(0, 0, 90))
	Clay.cylinder(root, 0.4, 0.3, at + Vector3(0.15, 0, 0), Clay.DARK, Vector3(0, 0, 90))
	var teeth := 20
	for i in teeth:
		var angle := TAU * i / teeth
		var tooth := Clay.box(root, Vector3(0.1, 0.24, 0.3), at + Vector3(0, cos(angle), sin(angle)) * 1.85,
			STEEL.darkened(0.3))
		tooth.basis = Basis(Vector3.RIGHT, -angle)
	# la guarda: un cuarto de vuelta arriba y atrás, para que se lea de qué lado corta
	for i in 5:
		var angle := lerpf(0.1, PI * 0.6, i / 4.0)
		var guard := Clay.box(root, Vector3(0.5, 0.15, 0.9), at + Vector3(0.05, cos(angle), sin(angle)) * 2.1,
			Clay.METAL.darkened(0.05))
		guard.basis = Basis(Vector3.RIGHT, -angle)


## ── LA ESPALDA ──────────────────────────────────────────────────────────────────────────────────────────────────

## Un pedazo del techo de la meca y la torreta que gira.
static func _back_mount(root: Node3D) -> void:
	Clay.box(root, Vector3(4.0, 1.0, 4.0), Vector3(0, -0.5, 0), FOREARM_COLOR)
	Clay.cylinder(root, 0.9, 0.4, Vector3(0, 0.2, 0), MechBody.JOINT_COLOR)


static func _machine_gun(root: Node3D) -> void:
	var y := 1.1
	Clay.box(root, Vector3(1.3, 1.1, 2.4), Vector3(0, y, 0.3), Clay.METAL.darkened(0.08))
	for i in 6:
		var angle := TAU * i / 6.0
		Clay.cylinder(root, 0.12, 3.4, Vector3(cos(angle) * 0.3, y + sin(angle) * 0.3, -2.6), Clay.DARK,
			Vector3(90, 0, 0))
	for z: float in [-1.4, -2.5, -4.1]:
		Clay.cylinder(root, 0.48, 0.18, Vector3(0, y, z), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	# la caja de munición al costado y la cinta que entra
	Clay.box(root, Vector3(1.0, 1.1, 1.4), Vector3(1.3, y - 0.1, 0.6), Color(0.42, 0.45, 0.4))
	Clay.box(root, Vector3(0.6, 0.12, 0.7), Vector3(0.75, y + 0.35, 0.3), Clay.DARK)


static func _missile_launcher(root: Node3D) -> void:
	var y := 1.35
	Clay.box(root, Vector3(2.6, 1.8, 2.8), Vector3(0, y, 0), Clay.METAL.darkened(0.08))
	for row in 2:
		for column in 3:
			var at := Vector3((column - 1) * 0.8, y + (row - 0.5) * 0.8, -1.41)
			Clay.cylinder(root, 0.3, 0.06, at, Clay.DARK, Vector3(90, 0, 0))
			# la punta del misil asomando, roja para que se lea
			_cone(root, 0.24, 0.45, at + Vector3(0, 0, -0.1), Vector3(-90, 0, 0), Clay.RED)
	Clay.box(root, Vector3(2.7, 0.15, 2.9), Vector3(0, y + 0.95, 0), MechBody.JOINT_COLOR)


static func _heavy_cannon(root: Node3D) -> void:
	var y := 1.3
	Clay.box(root, Vector3(1.6, 1.5, 2.6), Vector3(0, y, 0.7), Clay.METAL.darkened(0.08))
	Clay.cylinder(root, 0.5, 7.0, Vector3(0, y, -3.6), Clay.METAL.darkened(0.2), Vector3(90, 0, 0))
	Clay.cylinder(root, 0.62, 1.4, Vector3(0, y, -0.9), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	# el freno de boca
	Clay.box(root, Vector3(1.3, 0.75, 1.0), Vector3(0, y, -7.3), MechBody.JOINT_COLOR)
	# los dos amortiguadores del retroceso, abajo del caño
	for x: float in [-0.35, 0.35]:
		Clay.cylinder(root, 0.17, 2.4, Vector3(x, y - 0.55, -1.0), STEEL.darkened(0.2), Vector3(90, 0, 0))


## ── LAS PLACAS ──────────────────────────────────────────────────────────────────────────────────────────────────

## La placa del casco: una plancha al frente de la caja, con los cantos doblados hacia atrás y remaches.
static func _hull_plate(root: Node3D) -> void:
	Clay.box(root, Vector3(6.0, 4.0, 4.0), Vector3(0, 2.0, 0), FOREARM_COLOR)
	var front := -2.15
	Clay.box(root, Vector3(4.4, 3.0, 0.3), Vector3(0, 2.0, front), PLATE)
	for side: float in [-1.0, 1.0]:
		var wing := Clay.box(root, Vector3(1.0, 3.0, 0.3), Vector3(side * 2.55, 2.0, front + 0.25), PLATE)
		wing.basis = Basis(Vector3.UP, side * deg_to_rad(-30.0))
	_rivets(root, [Vector3(-1.9, 3.2, front - 0.17), Vector3(1.9, 3.2, front - 0.17), Vector3(-1.9, 0.8, front - 0.17),
		Vector3(1.9, 0.8, front - 0.17)])


## La placa de brazo: una teja sobre el antebrazo (arriba y afuera), como un brazal.
static func _arm_plate(root: Node3D) -> void:
	_forearm(root, false)
	var length := 3.6
	Clay.box(root, Vector3(1.7, 0.25, length), Vector3(0, ARM_HALF + 0.15, 0.3), PLATE)
	var outer := Clay.box(root, Vector3(0.25, 1.5, length), Vector3(ARM_HALF + 0.12, 0.45, 0.3), PLATE)
	outer.basis = Basis(Vector3.BACK, deg_to_rad(-12.0))
	var corner := Clay.box(root, Vector3(0.8, 0.25, length), Vector3(ARM_HALF * 0.75, ARM_HALF, 0.3), PLATE)
	corner.basis = Basis(Vector3.BACK, deg_to_rad(-45.0))
	_rivets(root, [Vector3(-0.6, ARM_HALF + 0.3, -1.2), Vector3(-0.6, ARM_HALF + 0.3, 1.8),
		Vector3(ARM_HALF + 0.27, 0.3, -1.2), Vector3(ARM_HALF + 0.27, 0.3, 1.8)])


## La placa de pierna: una canillera al frente de la canilla y la rodillera.
static func _leg_plate(root: Node3D) -> void:
	var shin := 4.4
	var half := ARM_HALF
	var leg := Clay.limb(root, half, shin, Vector3(0, shin * 0.5 + 0.7, 0), FOREARM_COLOR)
	leg.basis = Basis(Vector3.RIGHT, PI * 0.5)
	Clay.sphere(root, half * 1.25, Vector3(0, shin + 0.7, 0), MechBody.JOINT_COLOR)
	Clay.box(root, Vector3(2.2, 0.7, 3.4), Vector3(0, 0.35, -0.4), MechBody.JOINT_COLOR)
	Clay.box(root, Vector3(1.7, 3.2, 0.3), Vector3(0, 2.8, -half - 0.15), PLATE)
	for side: float in [-1.0, 1.0]:
		var wing := Clay.box(root, Vector3(0.6, 3.2, 0.25), Vector3(side * 0.95, 2.8, -half + 0.05), PLATE)
		wing.basis = Basis(Vector3.UP, side * deg_to_rad(-40.0))
	var knee := Clay.box(root, Vector3(1.6, 1.2, 0.35), Vector3(0, shin + 0.75, -half - 0.35), PLATE)
	knee.basis = Basis(Vector3.RIGHT, deg_to_rad(-15.0))
	_rivets(root, [Vector3(-0.55, 4.1, -half - 0.32), Vector3(0.55, 4.1, -half - 0.32),
		Vector3(-0.55, 1.5, -half - 0.32), Vector3(0.55, 1.5, -half - 0.32)])


## ── AYUDAS ──────────────────────────────────────────────────────────────────────────────────────────────────────

## Un cono (la punta hacia +Y antes de girarlo `rotation_deg`).
static func _cone(parent: Node3D, radius: float, height: float, at: Vector3, rotation_deg: Vector3,
		color: Color) -> MeshInstance3D:
	var part := Clay.cylinder(parent, radius, height, at, color, rotation_deg)
	(part.mesh as CylinderMesh).top_radius = 0.0
	(part.mesh as CylinderMesh).radial_segments = 10
	return part


static func _rivets(parent: Node3D, points: Array) -> void:
	for point: Vector3 in points:
		Clay.sphere(parent, 0.1, point, Clay.DARK)
