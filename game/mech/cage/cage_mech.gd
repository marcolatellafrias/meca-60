class_name CageMech
extends ToolMech

## LA MECA JAULA (ver CageCabin; el usuario, 16/11/2026: «empezar a migrar esta meca a algo funcional… que camine… que
## poder cambiar su velocidad… lo primero… que se pueda poseer la meca y que los brazos anden y las piernas anden»). La
## Meca de tres (ToolMech: la energía común, sus teclas, levitar) con:
##   · EL TORSO DISCRETO, LOS BRAZOS FÍSICOS (el usuario: «los brazos van a ser físicos y el torso va a ser discreto»):
##     cinemática, a la izquierda EL CAÑÓN en lugar del antebrazo (CageCannonArm) y a la derecha EL PALO en el puño
##     pesado, un brazo con músculos (PoleArm).
##   · LA CABINA JAULA, chica, con brazos y piernas al 30 % (CageCabin.BODY).
##   · SUS PROPIAS PERILLAS DE MOVERSE (`MOVES`, el F1 de su fila: CageMovesPanel; el usuario: «si un panel lo quiero
##     modificar para este mecha, me gustaría que sea solamente para esta, porque los otros se van a sentir muy
##     distintos»).
##   · LAS PLACAS DEL ACORAZADO (las de la armería, tres caras de octógono) en los brazos y las piernas, y la pelvis
##     cilíndrica de la maqueta.

const SAVED_MOVES := "res://game/mech/cage/cage_moves.tres"
## Lo que se achican, al nacer sin guardar, las distancias y velocidades de las de siempre: es más chica.
const START_SHRINK := 0.5
static var MOVES := CageMech.load_moves()

var pole: PoleArm = null


## LAS PERILLAS DE MOVERSE: las guardadas; si no hay, las de las otras mecas con las distancias achicadas.
static func load_moves() -> KinematicSettings:
	if ResourceLoader.exists(SAVED_MOVES):
		return KnobsFile.load_into(KinematicSettings.new(), SAVED_MOVES) as KinematicSettings
	var moves := KinematicSettings.new()
	KnobsFile.copy(moves, KinematicSettings.current)
	for knob: String in ["walk_speed", "jump_height", "fly_speed", "dash_distance"]:
		moves.set(knob, float(moves.get(knob)) * START_SHRINK)
	return moves


func _init() -> void:
	super()
	cabin_shape = Cabin.CAGE
	kinematic_knobs = MOVES


func _ready() -> void:
	super()
	name = "Meca jaula"
	# El cartel de lo que mide, a su escala: el de las grandes la tapaba entera.
	label.pixel_size = 0.006


func _build() -> void:
	super()
	# Sus teclas, en lugar de las de la Meca de tres.
	keys.queue_free()
	remove_child(keys)
	keys = CageMechKeys.new()
	keys.mech = self
	add_child(keys)


## LOS DOS BRAZOS: el cañón a la izquierda y el palo a la derecha, armados como los de siempre (ver Mech._build_arms).
func _build_arms() -> void:
	cannon = CageCannonArm.new()
	cannon.energy = energy
	pole = PoleArm.new()
	pole.weight = ARM_WEIGHT
	var at := Mech.shoulder(cabin_shape)
	for pair: Array in [[cannon, -1.0], [pole, 1.0]]:
		var arm: MechArm = pair[0]
		var side: float = pair[1]
		arm.side = side
		arm.anchor = self
		arm.measures = measures
		arm.shoulder_local = Vector3(side * at.x, at.y, at.z)
		arm.stance = MechArm.Stance.NORMAL
		add_child(arm)
		arms.append(arm)


## LAS PLACAS DE LAS PIERNAS (al frente del muslo y de la canilla) y LA PELVIS: un cilindro acostado de cadera a cadera,
## en lugar del tambor de las grandes.
func _dress() -> void:
	var ahead := global_basis * Vector3.FORWARD
	for found in find_children("*", "MechLeg", true, false):
		var leg := found as MechLeg
		CageMech.plate(leg._thigh, ahead, measures.thick, float(MechBody.BASE["THIGH"]) * 0.75)
		CageMech.plate(leg._shin, ahead, measures.thick, float(MechBody.BASE["SHIN"]) * 0.8)
	if legs != null and legs._pelvis != null:
		legs._pelvis.mesh = null
		Clay.cylinder(legs._pelvis, measures.LEG_THICKNESS * 0.55, measures.HIP_X * 2.0 - measures.LEG_THICKNESS * 0.9,
			Vector3(0.0, measures.PELVIS_SIZE.y * 0.5 - measures.HIP_DROP, 0.0), MechBody.JOINT_COLOR, Vector3(0.0, 0.0, 90.0))


## UNA PLACA DEL ACORAZADO (tres caras de octógono, ArmoryParts._wrap) sobre `piece` (su largo sobre Z), del lado que
## mira a `toward` (mundo), armada en la medida de la meca entera (`length`) y achicada a `k`.
static func plate(piece: Node3D, toward: Vector3, k: float, length: float) -> void:
	var holder := Node3D.new()
	holder.name = "Placa"
	holder.scale = Vector3.ONE * k
	piece.add_child(holder)
	ArmoryParts._wrap(holder, Transform3D(ArmoryParts._facing(piece, toward), Vector3.ZERO), length)
