class_name ArmLoadout
extends Resource

## LO QUE LLEVA UN BRAZO DE UNA MECA (16/11/2026; el usuario: «el cañón… reemplazar antebrazo»; «discreto o con
## músculos… cada uno lo elige»; la placa, «la que tiene el brazo del puño»): CÓMO SE MUEVE (discreto, PoseArm, o con
## músculos, MuscleArm), QUÉ VA EN LA PUNTA (ArmTip) y SI LLEVA LA PLACA del acorazado. Lo declara cada meca
## (Mech.loadout, izquierdo y derecho); es lo que va a elegir y guardar el panel de equipamiento.

enum Motion { POSE, MUSCLE }
enum Tip { FIST, HEAVY_FIST, POLE, DRILL, SAW, CANNON, SHIELD }

const MOTION_NAMES := ["discreto", "con músculos"]
const TIP_NAMES := ["puño común", "puño pesado", "palo eléctrico", "taladro", "sierra", "cañón de energía", "escudo"]

@export var motion := Motion.POSE
@export var tip := Tip.FIST
@export var plate := false


static func of(how: Motion, what: Tip, plated := false) -> ArmLoadout:
	var loadout := ArmLoadout.new()
	loadout.motion = how
	loadout.tip = what
	loadout.plate = plated
	return loadout


## EL BRAZO, sin agregar: los músculos pesan `weight` (ver MuscleArm.weight); lo que gasta, de `energy`.
func make_arm(weight: float, energy: MechEnergy) -> MechArm:
	var arm: MechArm = null
	if motion == Motion.MUSCLE:
		var muscle := MuscleArm.new()
		muscle.weight = weight
		arm = muscle
	else:
		arm = PoseArm.new()
	arm.tip = make_tip()
	arm.tip.energy = energy
	arm.plated = plate
	return arm


func make_tip() -> ArmTip:
	match tip:
		Tip.HEAVY_FIST:
			return HeavyFistTip.new()
		Tip.POLE:
			return PoleTip.new()
		Tip.DRILL:
			return DrillTip.new()
		Tip.SAW:
			return SawTip.new()
		Tip.CANNON:
			return CannonTip.new()
		Tip.SHIELD:
			return ShieldTip.new()
	return ArmTip.new()
