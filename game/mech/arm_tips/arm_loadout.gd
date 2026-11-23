class_name ArmLoadout
extends Resource

## LO QUE LLEVA UN BRAZO DE UNA MECA (16/11/2026): QUÉ VA EN LA PUNTA (ArmTip) y SI LLEVA LA PLACA del acorazado. Lo declara
## cada meca (Mech.loadout, izquierdo y derecho). *Hasta el 22/11/2026 elegía también discreto o con músculos.*

enum Tip { FIST, HEAVY_FIST, POLE, DRILL, SAW, CANNON, SHIELD }

const TIP_NAMES := ["puño común", "puño pesado", "palo eléctrico", "taladro", "sierra", "cañón de energía", "escudo"]

@export var tip := Tip.FIST
@export var plate := false


static func of(what: Tip, plated := false) -> ArmLoadout:
	var loadout := ArmLoadout.new()
	loadout.tip = what
	loadout.plate = plated
	return loadout


## EL BRAZO, sin agregar; lo que gasta, de `energy`.
func make_arm(energy: MechEnergy) -> MechArm:
	var arm: MechArm = PoseArm.new()
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
