class_name MuscleArmArchetype
extends SeededArchetype

## LA PARCELA DEL BRAZO CON MÚSCULOS (ver MuscleArm): un torso fijo en el aire, del tamaño del de la meca, con UN
## brazo (el izquierdo, del lado desde donde se llega), para tunearlo solo. Adelante, un BLOQUE suelto sobre un pedestal
## para pegarle; con N, una PARED fija en su lugar, para ver cómo se traba. 1 a 4 tiran las piñas; J/K, una bola liviana o
## pesada contra el brazo (cede y vuelve). F1 abre sus perillas (MuscleArmPanel). Mirándolo, O lo posee: a mano.

const FOOTPRINT := 60.0
const TORSO := 8.0
## A qué altura va el torso (su cara de abajo), como el de la meca parada.
const HEIGHT := 7.4
const BLOCK := Vector3(5.0, 5.0, 2.4)
const BLOCK_MASS := 6000.0
const SLOW := 30.0


func _init() -> void:
	display_name = "Brazo con músculos"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"un brazo de piezas físicas; los músculos persiguen la pose que pide la IK",
		"1 directo · 2 gancho · 3 uppercut · 4 desde arriba · 5 cambia la postura",
		"N pone y saca una pared adelante (se traba)",
		"mirándolo, O lo posee: el mouse lleva la mano",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Brazo con músculos"
	parent.add_child(root)
	# El torso, fijo, sobre un poste.
	var torso := StaticBody3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, HEIGHT + TORSO * 0.5, 0.0)
	root.add_child(torso)
	Clay.solid(torso, Vector3.ONE * TORSO, Vector3.ZERO, Clay.METAL)
	Clay.box(root, Vector3(1.2, HEIGHT, 1.2), Vector3(0, HEIGHT * 0.5, 0), Clay.DARK)
	var arm := MuscleArm.new()
	arm.side = -1.0
	arm.standalone = true
	arm.anchor = torso
	arm.shoulder_local = Vector3(arm.side * Mech.shoulder().x, Mech.shoulder().y, Mech.shoulder().z)
	root.add_child(arm)
	# Adelante del brazo: el pedestal y el bloque suelto, donde llega el directo.
	var ahead := Vector3(arm.shoulder_local.x + 1.8, 0.0, arm.shoulder_local.z - 13.3)
	var stand := StaticBody3D.new()
	stand.name = "Pedestal"
	root.add_child(stand)
	Clay.solid(stand, Vector3(BLOCK.x + 1.0, HEIGHT + 0.6, BLOCK.z + 2.0), ahead + Vector3(0, (HEIGHT + 0.6) * 0.5, 0), Clay.DARK)
	var block := RigidBody3D.new()
	block.name = "Bloque"
	block.mass = BLOCK_MASS
	block.position = ahead + Vector3(0, HEIGHT + 0.6 + BLOCK.y * 0.5, 0)
	root.add_child(block)
	Clay.solid(block, BLOCK, Vector3.ZERO, Clay.RED)
	# La pared fija, más cerca (apagada hasta la N).
	var wall := StaticBody3D.new()
	wall.name = "Pared"
	root.add_child(wall)
	Clay.solid(wall, Vector3(10.0, 12.0, 0.6), Vector3(arm.shoulder_local.x, HEIGHT + 4.0, arm.shoulder_local.z - 12.3),
		Clay.METAL.darkened(0.35))
	_show_wall(wall, false)
	return root


## La pared, puesta o sacada: se ve y se choca, o ninguna de las dos. Va donde el bloque, que se guarda mientras está.
static func _show_wall(wall: StaticBody3D, on: bool) -> void:
	wall.visible = on
	for shape: CollisionShape3D in wall.find_children("*", "CollisionShape3D", true, false):
		shape.disabled = not on
	var block := wall.get_parent().find_child("Bloque", true, false) as RigidBody3D
	if block != null:
		block.visible = not on
		block.freeze = on
		for shape: CollisionShape3D in block.find_children("*", "CollisionShape3D", true, false):
			shape.disabled = on


static func _arm_of(parcel: SandboxParcel) -> MuscleArm:
	var found := parcel.find_children("*", "MuscleArm", true, false)
	return found[0] as MuscleArm if not found.is_empty() else null


func keys() -> Array[SandboxKey]:
	var out := TestBall.keys(self)
	var punch_keys := [KEY_1, KEY_2, KEY_3, KEY_4]
	for index in punch_keys.size():
		var kind := (index + 1) as MechArm.Punch
		out.append(SandboxKey.action(punch_keys[index], SandboxKey.Weight.MAIN if index == 0 else SandboxKey.Weight.NORMAL,
			"piña: %s" % MechArm.NAMES[kind],
			MuscleArmArchetype._punch.bind(kind)).while_seated())
	out.append(SandboxKey.action(KEY_5, SandboxKey.Weight.NORMAL, "postura: normal / cubriéndose",
		MuscleArmArchetype._toggle_cover).while_seated())
	out.append(SandboxKey.action(KEY_N, SandboxKey.Weight.NORMAL, "poner / sacar la pared de adelante",
		MuscleArmArchetype._toggle_wall).while_seated())
	return out


static func _punch(parcel: SandboxParcel, kind: MechArm.Punch) -> void:
	var arm := MuscleArmArchetype._arm_of(parcel)
	if arm != null:
		arm.punch(kind)


static func _toggle_cover(parcel: SandboxParcel) -> void:
	var arm := MuscleArmArchetype._arm_of(parcel)
	if arm != null:
		arm.stance = MechArm.Stance.NORMAL if arm.stance == MechArm.Stance.COVER else MechArm.Stance.COVER


static func _toggle_wall(parcel: SandboxParcel) -> void:
	for wall: StaticBody3D in parcel.find_children("Pared", "StaticBody3D", true, false):
		MuscleArmArchetype._show_wall(wall, not wall.visible)


## DOS BOLAS para tirarle al brazo: una que lo mueve apenas y una que se lo lleva (cede y vuelve).
func ball_shots() -> Array[Dictionary]:
	var arm_mass := MuscleArm.UPPER_MASS + MuscleArm.FOREARM_MASS
	return [
		TestBall.shot("liviana", TestBall.push_for(arm_mass, 4.0, SLOW), SLOW),
		TestBall.shot("pesada", TestBall.push_for(arm_mass, 25.0, SLOW), SLOW),
	]
