class_name PoseArm
extends MechArm

## UN BRAZO DISCRETO: EL OTRO CAMINO de los brazos de la meca (13/11/2026; lo que se le pide —posturas, piñas, la pose—,
## en MechArm). El usuario: «si los jefes son NPCs… áreas y zonas que esquivar y más proyectiles… ahí tiene mucho más
## sentido de que los brazos sean discretos»; «tal vez sí puedo hacer que los brazos atraviesen más las paredes… pero la
## caja, la base, no».
##
##   · SE DIBUJA EN LA POSE PEDIDA, sin cuerpos ni músculos: va exacto adonde se lo pide, no se traba y ATRAVIESA lo que
##     haya. Lo que choca de la meca es su caja.
##   · AL CONECTAR, EMPUJA: mientras PEGA (ver MechArm.stage), el puño barre su camino en el mundo —la regla del puño de
##     la vieja meca de pelea: desde donde estaba el paso anterior, así cuenta lo que se movió la meca—, y a cada cuerpo
##     suelto que toca le da, una vez por piña, UN IMPULSO en el punto del golpe: la velocidad del puño por lo que pesa (PoseArmSettings).
##     A otra meca la empuja en su caja, y su péndulo decide si se inclina o se cae: la misma regla de equilibrio de
##     siempre (el usuario: sí, que el golpe empuje al que lo recibe).
##   · Lo que no se mueve (una pared, el piso) no lo frena ni recibe nada.

## Lo que pesa el puño al pegar, su radio y lo rápido de las piñas: perillas (PoseArmSettings, F3).
## Con qué choca el puño: el mundo (la capa 1).
const HIT_MASK := 1
## Más que esto en un paso no es un puño que se mueve: es la meca que reapareció (m).
const JUMP := 30.0

## La última piña: a qué velocidad conectó (0 si no tocó nada) y a qué.
var last_hit_speed := 0.0
var last_hit: Node = null

var _upper: Node3D = null
var _forearm: Node3D = null
var _last_fist := Vector3.ZERO
var _has_last := false
var _struck := {}
var _sphere := SphereShape3D.new()


func _ready() -> void:
	# Sus piezas van en el mundo: la pose ya viene en el mundo.
	top_level = true
	global_transform = Transform3D()
	_sphere.radius = PoseArmSettings.current.fist_radius * MechBody.thick
	_rest = stance_at(stance)
	_upper = Clay.limb(self, MechBody.LEG_THICKNESS * 0.5, MechBody.UPPER_ARM, Vector3.ZERO, Clay.METAL.darkened(0.1))
	_forearm = Clay.limb(self, MechBody.LEG_THICKNESS * 0.5, MechBody.FOREARM, Vector3.ZERO, Clay.METAL.darkened(0.2))
	# El hombro y el codo, esferas en la punta de arriba de cada pieza; la mano, en la de abajo del antebrazo.
	Clay.sphere(_upper, MechBody.LEG_THICKNESS * 0.78, Vector3(0, 0, MechBody.UPPER_ARM * 0.5), MechBody.JOINT_COLOR)
	Clay.sphere(_forearm, MechBody.LEG_THICKNESS * 0.66, Vector3(0, 0, MechBody.FOREARM * 0.5), MechBody.JOINT_COLOR)
	_mount_hand(_forearm)
	_place(_target())


func punch(kind: Punch) -> bool:
	if not super(kind):
		return false
	_struck.clear()
	last_hit_speed = 0.0
	last_hit = null
	return true


func _punch_speed() -> float:
	return PoseArmSettings.current.punch_speed


func _physics_process(delta: float) -> void:
	_advance(delta)
	var pose := _target()
	_place(pose)
	_sweep(pose, delta)


func _place(pose: Dictionary) -> void:
	_upper.global_transform = pose["upper"]
	_forearm.global_transform = pose["forearm"]


## EL PUÑO BARRE SU CAMINO en el mundo, desde donde estaba el paso anterior, y le pega a lo suelto que toca.
func _sweep(pose: Dictionary, delta: float) -> void:
	var forearm: Transform3D = pose["forearm"]
	var fist: Vector3 = (pose["wrist"] as Vector3) - forearm.basis.z * MechHand.length() * MechBody.thick * 0.5
	var motion := fist - _last_fist
	if _has_last and stage() == Stage.STRIKE and motion.length() > 0.001 and motion.length() < JUMP:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = _sphere
		query.transform = Transform3D(Basis(), _last_fist)
		query.motion = motion
		query.collision_mask = HIT_MASK
		query.exclude = [anchor.get_rid()]
		var space := get_world_3d().direct_space_state
		# Lo que no se golpea se saltea y se sigue barriendo: el brazo atraviesa.
		for attempt in 6:
			var fractions := space.cast_motion(query)
			if fractions[1] >= 1.0:
				break
			query.transform = Transform3D(Basis(), _last_fist + motion * fractions[1])
			query.motion = Vector3.ZERO
			var info := space.get_rest_info(query)
			query.transform = Transform3D(Basis(), _last_fist)
			query.motion = motion
			if info.is_empty():
				break
			var body := instance_from_id(int(info["collider_id"])) as RigidBody3D
			if body != null and not _struck.has(body.get_instance_id()):
				_hit(body, info["point"], motion / delta)
			query.exclude = query.exclude + [info["rid"]]
	_last_fist = fist
	_has_last = true


## LE PEGA a `body` en `at` con el puño yendo a `velocity` (mundo): un impulso, una vez por piña.
func _hit(body: RigidBody3D, at: Vector3, velocity: Vector3) -> void:
	_struck[body.get_instance_id()] = true
	BalanceBody.hit(body, velocity * PoseArmSettings.current.hit_mass, at - body.global_position)
	last_hit_speed = velocity.length()
	last_hit = body
