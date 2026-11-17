class_name ToolMech
extends Mech

## LA MECA CON HERRAMIENTAS: LO QUE LA MECA JAULA (CageMech) TRAJO DE LA MECA DE TRES (15/11/2026; el usuario: «hagamos
## un ejemplo de una mecha con elementos concretos… vamos a ir cerrando entonces todos los controles que van a tener
## los tres pasajeros»). Se maneja entera poseyéndola desde afuera (la O; «si yo poseo la meca y aprieto los botones
## necesarios, puedo hacer funcionar todos los controles»). Es la meca de siempre (Mech), cinemática, con:
##   · LO QUE LLEVA EN LOS BRAZOS (ver `loadout`, ArmLoadout): el cañón de energía (CannonTip), lo que gira (el taladro
##     o la sierra, SpinTip) o un brazo de piñas; lo manejan sus teclas.
##   · LA ENERGÍA COMÚN (MechEnergy): la gastan los brazos, el dash y levitar.
##   · LEVITAR: el vuelo de la cinemática, gastando energía.
##   · SUS TECLAS (ToolMechKeys), en lugar de las de siempre.
## *La Meca de tres, su fila (con la cabina cuadrada, el cañón a la izquierda, el taladro a la derecha y las fundas de
## blindaje en las piernas), se borró con la meca grande el 17/11/2026 (está en el commit 0bcaeaf); esto quedó como la
## base de la jaula.*

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


func _build() -> void:
	super()
	# Sus teclas, en lugar de las de siempre.
	keys.queue_free()
	remove_child(keys)
	keys = ToolMechKeys.new()
	keys.mech = self
	add_child(keys)
	# Las piernas arman sus piezas al entrar al árbol: lo que se les pone encima, después.
	_dress.call_deferred()


## LO QUE SE LES PONE ENCIMA A LAS PIERNAS, ya armadas (cada meca lo suyo; ver CageMech). *Hasta el 17/11/2026, las
## fundas de blindaje de la Meca de tres (ArmorPlates).*
func _dress() -> void:
	pass


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
