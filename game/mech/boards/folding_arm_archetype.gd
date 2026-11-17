class_name FoldingArmArchetype
extends PanelArchetype

## LA PIEZA DEL BRAZO PLEGABLE (ver FoldingArm): ocupa sus celdas en la grilla de una cara como cualquier pieza, sobre
## su base (FaceMount), y arma encima la rótula que gira, los dos tramos con la rótula del codo y el mando de palo con
## su control. La 1 de tests/folding_arm_ideas_look («la versión más simple»): barras redondas y rótulas; el mando, el
## de palo que tenía el que maneja (hongo rojo arriba, gatillo y tres botones al costado).

const CELLS := Vector2i(4, 4)
const ROD := 0.028
const METAL := Color(0.55, 0.57, 0.6)
const DARK := Color(0.24, 0.25, 0.28)
const RED := Color(0.72, 0.2, 0.15)
const YELLOW := Color(0.88, 0.7, 0.18)

## De qué lado va (1, el brazo de la derecha; −1, el de la izquierda): los botones del mando miran hacia adentro.
var side := 1.0


func _init(p_side := 1.0) -> void:
	side = p_side
	display_name = "Brazo plegable"


func cells(_seed_value: int) -> Vector2i:
	return CELLS


## El FoldingArm de uno montado (la raíz que devuelve `mount`).
static func arm_of(root: Node) -> FoldingArm:
	return root.get_node_or_null("Mando/Control") as FoldingArm


func _build_on(_seed_value: int, root: Node3D, area: Vector2) -> void:
	# La rótula que gira, sobre la base.
	Clay.cylinder(root, minf(area.x, area.y) * 0.32, 0.04, Vector3(0.0, 0.0, 0.02), METAL, Vector3(90.0, 0.0, 0.0))
	var arm := FoldingArm.new()
	arm.name = "Control"
	Clay.sphere(root, 0.05, arm.hub, DARK)
	for i in 2:
		arm.rods.append(Clay.limb(root, ROD, 1.0, Vector3.ZERO, METAL))
	arm.elbow_ball = Clay.sphere(root, 0.045, Vector3.ZERO, DARK)
	# EL MANDO: su cuerpo (lo que se apunta) y el control, con las mallas colgadas de él (se resaltan al manejarlo).
	var grip := StaticBody3D.new()
	grip.name = "Mando"
	root.add_child(grip)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.1, 0.3, 0.11)
	shape.shape = box
	shape.position = Vector3(0.0, 0.13, 0.0)
	grip.add_child(shape)
	grip.add_child(arm)
	arm.piece = root
	arm.build(Vector3(0.1, 0.3, 0.11))
	var meshes: Array[MeshInstance3D] = [
		Clay.cylinder(arm, 0.045, 0.045, Vector3.ZERO, DARK),
		Clay.box(arm, Vector3(0.075, 0.2, 0.09), Vector3(0.0, 0.12, 0.0), DARK),
		Clay.cylinder(arm, 0.045, 0.04, Vector3(0.0, 0.24, 0.0), METAL),
		Clay.sphere(arm, 0.03, Vector3(0.0, 0.27, 0.0), RED),
		Clay.box(arm, Vector3(0.03, 0.05, 0.03), Vector3(0.0, 0.14, -0.055), YELLOW),
	]
	for b in 3:
		meshes.append(Clay.sphere(arm, 0.014, Vector3(-side * 0.04, 0.18 - b * 0.035, -0.02), RED if b == 0 else YELLOW))
	arm.highlighted.append_array(meshes)
	arm._pose()
