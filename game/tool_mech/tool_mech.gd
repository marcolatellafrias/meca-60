class_name ToolMech
extends Mech

## LA MECA DE TRES (15/11/2026): UNA MECA DE EJEMPLO CON ELEMENTOS CONCRETOS, para cerrar los controles de los tres
## pasajeros (el usuario: «hagamos un ejemplo de una mecha con elementos concretos… vamos a ir cerrando entonces todos
## los controles que van a tener los tres pasajeros»). Por ahora se maneja entera poseyéndola desde afuera (la O; «si yo
## poseo la meca y aprieto los botones necesarios, puedo hacer funcionar todos los controles»): los puestos de adentro
## son de otra sesión. Es la meca de siempre (Mech), cinemática, con la cabina cuadrada de tres, y:
##   · EL BRAZO IZQUIERDO, EL CAÑÓN DE ENERGÍA (CannonArm): cuatro modos, apuntado con una palanca que el brazo sigue
##     tarde.
##   · EL BRAZO DERECHO, EL TALADRO (DrillArm): se carga y se descarga.
##   · LA ENERGÍA COMÚN (MechEnergy): la gastan los dos brazos, el dash y levitar.
##   · LEVITAR: el vuelo de la cinemática (propulsores en las pantorrillas, atrás; no se modelan), gastando energía.
##   · LAS PLACAS DE BLINDAJE (ArmorPlates) en los brazos y las piernas.
##   · SUS TECLAS (ToolMechKeys), en lugar de las de siempre.

var energy := MechEnergy.new()
var cannon: CannonArm = null
var drill: DrillArm = null


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


## LOS DOS BRAZOS: el cañón a la izquierda y el taladro a la derecha, armados como los de siempre (ver Mech._build_arms).
func _build_arms() -> void:
	cannon = CannonArm.new()
	cannon.energy = energy
	var right := _right_arm()
	var at := Mech.shoulder(cabin_shape)
	for pair: Array in [[cannon, -1.0], [right, 1.0]]:
		var arm: MechArm = pair[0]
		var side: float = pair[1]
		arm.side = side
		arm.anchor = self
		arm.measures = measures
		arm.shoulder_local = Vector3(side * at.x, at.y, at.z)
		arm.stance = MechArm.Stance.NORMAL
		add_child(arm)
		arms.append(arm)


## EL BRAZO DERECHO: el taladro (otra meca puede llevar otro; ver PodMech).
func _right_arm() -> MechArm:
	drill = DrillArm.new()
	drill.energy = energy
	return drill


func possess_status() -> String:
	var line := "energía %s" % energy.bar()
	line += "\ncañón: %s%s" % [CannonArm.MODE_NAMES[cannon.mode],
		(" %s" % BodyMoves._bar(cannon.charge)) if cannon.mode == CannonArm.Mode.SUPER else ""]
	if drill != null:
		line += " · taladro %s" % BodyMoves._bar(drill.spin)
	line += "\n" + super()
	return line
