class_name ToolMech
extends Mech

## LA MECA DE TRES (15/11/2026): UNA MECA DE EJEMPLO CON ELEMENTOS CONCRETOS, para cerrar los controles de los tres
## pasajeros (el usuario: «hagamos un ejemplo de una mecha con elementos concretos… vamos a ir cerrando entonces todos
## los controles que van a tener los tres pasajeros»). Por ahora se maneja entera poseyéndola desde afuera (la O; «si yo
## poseo la meca y aprieto los botones necesarios, puedo hacer funcionar todos los controles»): los puestos de adentro
## son de otra sesión. Es la meca de siempre (Mech), cinemática, con la cabina cuadrada de tres, y:
##   · EL BRAZO IZQUIERDO, EL CAÑÓN DE ENERGÍA (CannonTip) en lugar del antebrazo: cuatro modos, apuntado con una
##     palanca que el brazo sigue tarde.
##   · EL BRAZO DERECHO, EL TALADRO (DrillTip): se carga y se descarga.
##   Los dos discretos, con la placa del acorazado (ver `loadout`, ArmLoadout; otra meca puede llevar otros).
##   · LA ENERGÍA COMÚN (MechEnergy): la gastan los dos brazos, el dash y levitar.
##   · LEVITAR: el vuelo de la cinemática (propulsores en las pantorrillas, atrás; no se modelan), gastando energía.
##   · LAS FUNDAS DE BLINDAJE (ArmorPlates) en las piernas.
##   · SUS TECLAS (ToolMechKeys), en lugar de las de siempre.

var energy := MechEnergy.new()
## LO QUE MANEJAN SUS TECLAS, de lo que lleva en los brazos (ver `_build_arms`; lo que no lleva, nada): el cañón, lo que
## gira (el taladro o la sierra) y el brazo de las piñas (el primero sin ninguno de los dos).
var cannon: CannonTip = null
var drill: SpinTip = null
var melee: MechArm = null


func _init() -> void:
	super()
	kinematic = true
	arms_kind = Arms.POSE


func _ready() -> void:
	add_child(energy)
	super()
	name = "Meca de tres"


func _build() -> void:
	super()
	# Sus teclas, en lugar de las de siempre.
	keys.queue_free()
	remove_child(keys)
	keys = ToolMechKeys.new()
	keys.mech = self
	add_child(keys)
	# Las piernas arman sus piezas al entrar al árbol: las placas, después.
	_dress.call_deferred()


## LAS PLACAS DE BLINDAJE de las piernas (otra meca puede llevar otras; ver CageMech).
func _dress() -> void:
	ArmorPlates.dress_legs(self)


## LOS BRAZOS, los de siempre con lo que dice `loadout`; y de ahí, lo que manejan sus teclas.
func _build_arms() -> void:
	super()
	cannon = tip_of(CannonTip) as CannonTip
	drill = tip_of(SpinTip) as SpinTip
	melee = null
	for arm in arms:
		if melee == null and not (arm.tip is CannonTip or arm.tip is SpinTip):
			melee = arm
	ArmPoseIdeas.apply(self)


func default_loadout() -> Array[ArmLoadout]:
	return ToolMech.default_arms()


## Lo suyo: el cañón a la izquierda y el taladro a la derecha, discretos, con placa.
static func default_arms() -> Array[ArmLoadout]:
	return [ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.CANNON, true),
		ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.DRILL, true)]


func _arm_energy() -> MechEnergy:
	return energy


func possess_status() -> String:
	var line := "energía %s" % energy.bar()
	var tools := PackedStringArray()
	for arm in arms:
		if arm.tip != null and arm.tip.status() != "":
			tools.append(arm.tip.status())
	if not tools.is_empty():
		line += "\n" + " · ".join(tools)
	line += "\n" + super()
	return line
