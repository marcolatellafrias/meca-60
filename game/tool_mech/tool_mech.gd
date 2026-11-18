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
##   · EL ESCUDO (MechShield, 18/11/2026): si un brazo lleva el escudo (ShieldTip), levantado frena lo que viene de
##     frente, gastando energía; sin brazo de escudo, no hay escudo.
##   · SUS TECLAS (ToolMechKeys), en lugar de las de siempre.
## *La Meca de tres, su fila (con la cabina cuadrada, el cañón a la izquierda, el taladro a la derecha y las fundas de
## blindaje en las piernas), se borró con la meca grande el 17/11/2026 (está en el commit 0bcaeaf); esto quedó como la
## base de la jaula.*

var energy := MechEnergy.new()
var shield := MechShield.new()
## LO QUE MANEJAN SUS TECLAS, de lo que lleva en los brazos (ver `_build_arms`; lo que no lleva, nada): el cañón, lo que
## gira (el taladro o la sierra) y el brazo de las piñas (el primero sin ninguno de los dos).
var cannon: CannonTip = null
var drill: SpinTip = null
var melee: MechArm = null
## El escudo de un brazo (ShieldTip), o null: sin él, no hay escudo.
var guard: ShieldTip = null
## LO QUE FRENA EL ESCUDO: lo que viene de este ángulo del frente del torso, a cada lado (°).
const GUARD_HALF := 75.0


func _init() -> void:
	super()
	kinematic = true
	arms_kind = Arms.POSE


func _ready() -> void:
	add_child(energy)
	shield.energy = energy
	add_child(shield)
	super()


## UN GOLPE FRENADO POR EL ESCUDO (BalanceBody.block_hit, una vez por golpe: lo llama quien pega): si está levantado y el
## golpe viene de frente (`GUARD_HALF`; sin saber de dónde, cuenta como de frente), el destello y el parry. Lo de atrás
## o de los costados entra: el escudo es de un brazo («algo que se cubre de frente… la dirección en la que está mirando
## importa»). *Hasta el 18/11/2026 el escudo era un campo global: frenaba todo y además la hacía intocable.*
func block_hit(at := Vector3.INF) -> bool:
	if not shield.on or not _from_front(at):
		return super(at)
	shield.stopped(at)
	return true


func _from_front(at: Vector3) -> bool:
	if not at.is_finite():
		return true
	var toward := at - global_position
	toward.y = 0.0
	var ahead := -global_basis.z
	ahead.y = 0.0
	if toward.length() < 0.01 or ahead.length() < 0.01:
		return true
	return rad_to_deg(ahead.angle_to(toward)) <= GUARD_HALF


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
	guard = tip_of(ShieldTip) as ShieldTip
	shield.tip = guard
	melee = null
	for arm in arms:
		if melee == null and not (arm.tip is CannonTip or arm.tip is SpinTip or arm.tip is ShieldTip):
			melee = arm
	ArmPoseIdeas.apply(self)


func _arm_energy() -> MechEnergy:
	return energy


func possess_status() -> String:
	var line := "energía %s%s" % [energy.bar(), " · ESCUDO" if shield.on else ""]
	var tools := PackedStringArray()
	for arm in arms:
		if arm.tip != null and arm.tip.status() != "":
			tools.append(arm.tip.status())
	if not tools.is_empty():
		line += "\n" + " · ".join(tools)
	line += "\n" + super()
	return line
