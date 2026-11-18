class_name PoseArm
extends MechArm

## UN BRAZO DISCRETO: EL OTRO CAMINO de los brazos de la meca (13/11/2026; lo que se le pide —posturas, piñas, la pose—,
## en MechArm). El usuario: «si los jefes son NPCs… áreas y zonas que esquivar y más proyectiles… ahí tiene mucho más
## sentido de que los brazos sean discretos»; «tal vez sí puedo hacer que los brazos atraviesen más las paredes… pero la
## caja, la base, no».
##
##   · SE DIBUJA EN LA POSE PEDIDA, sin cuerpos ni músculos: va exacto adonde se lo pide, no se traba y ATRAVIESA lo que
##     haya. Lo que choca de la meca es su caja.
##   · AL CONECTAR, EMPUJA (y a un jefe, le saca vida): el golpe de todos los brazos (MechArm, «El golpe»).
##   · Lo que no se mueve (una pared, el piso) no lo frena ni recibe nada.

## Lo que pesa lo que golpea, su radio y lo rápido de las piñas: perillas (PoseArmSettings, F3). Cómo golpea: MechArm,
## «El golpe».

var _upper: Node3D = null
var _forearm: Node3D = null


func _ready() -> void:
	# Sus piezas van en el mundo: la pose ya viene en el mundo.
	top_level = true
	global_transform = Transform3D()
	_rest = stance_at(stance)
	_upper = Clay.limb(self, measures.LEG_THICKNESS * 0.5, upper_length(), Vector3.ZERO, Clay.METAL.darkened(0.1))
	_forearm = Clay.limb(self, measures.LEG_THICKNESS * 0.5, forearm_length(), Vector3.ZERO, Clay.METAL.darkened(0.2))
	# El hombro y el codo, esferas en la punta de arriba de cada pieza; la mano, en la de abajo del antebrazo.
	Clay.sphere(_upper, measures.LEG_THICKNESS * 0.78, Vector3(0, 0, upper_length() * 0.5), MechBody.JOINT_COLOR)
	Clay.sphere(_forearm, measures.LEG_THICKNESS * 0.66, Vector3(0, 0, forearm_length() * 0.5), MechBody.JOINT_COLOR)
	forearm_skin = _forearm.get_child(0)
	if upper_bone != null:
		MechSkeleton.hang(_upper, upper_bone)
		MechSkeleton.hang(_forearm, forearm_bone)
	_mount_hand(_forearm)
	_place(_target())
	_dress(_upper, _forearm)


func _punch_speed() -> float:
	return PoseArmSettings.current.punch_speed


func _physics_process(delta: float) -> void:
	_advance(delta)
	var pose := _target()
	_place(pose)
	_strike(delta, [anchor.get_rid()])


func _place(pose: Dictionary) -> void:
	if upper_bone != null:
		_reach_bones(pose, anchor.global_basis)
		return
	_upper.global_transform = pose["upper"]
	_forearm.global_transform = pose["forearm"]
