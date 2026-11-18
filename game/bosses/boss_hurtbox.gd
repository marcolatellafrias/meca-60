class_name BossHurtbox
extends RigidBody3D

## DONDE SE LE PEGA A UN JEFE (15/11/2026): una caja que no choca con nada (congelada, sin máscara), en la capa común
## (la 1), que lo sigue. Es la que encuentran los tiros, el rayo y el taladro de la meca de tres (EnergyBolt.lands, del
## módulo Meca): como es un cuerpo suelto, le dicen `take_hit`, y ella se lo pasa a `owner_of_hits` (la cabeza del jefe,
## que decide cuánta vida le saca). *El cuerpo del jefe es lo fijo del mundo (para que lo choquen las mecas), y los tiros
## no miran esa capa: le pasaban de largo.* El empujón (BalanceBody.hit) no la mueve: está congelada.

## A quién le pasa los golpes (tiene `take_hit(strength, at, source)`).
var owner_of_hits: Node = null


func _init() -> void:
	name = "Donde se le pega"
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	collision_layer = 1
	collision_mask = 0


## LA ARMA (o la rearma: otra escala) con una caja de `size` (m) en `center` (local): lo de abajo, que va con el cuerpo.
func shape(size: Vector3, center: Vector3) -> void:
	if _holder == null:
		_holder = CollisionShape3D.new()
		_holder.shape = BoxShape3D.new()
		add_child(_holder)
	(_holder.shape as BoxShape3D).size = size
	_holder.position = center


var _holder: CollisionShape3D = null


## LO DE ARRIBA, QUE SIGUE AL TORSO (18/11/2026, la regla de las cajas de golpe): una caja de `size` (m) con su centro
## en `center`, en los ejes del hueso del torso (sin escala). La pone `follow` en cada paso.
func upper(size: Vector3, center: Vector3) -> void:
	if _upper == null:
		_upper = CollisionShape3D.new()
		_upper.shape = BoxShape3D.new()
		add_child(_upper)
	(_upper.shape as BoxShape3D).size = size
	_upper_center = center


## Lo de arriba, donde está el torso `bone` ahora (su giro, sin escala; el centro, con la escala del hueso). Va DESPUÉS
## de mover la caja (la de arriba cuelga de ella).
func follow(bone: Node3D) -> void:
	if _upper != null:
		_upper.global_transform = Transform3D(bone.global_basis.orthonormalized(), bone.global_transform * _upper_center)


var _upper: CollisionShape3D = null
var _upper_center := Vector3.ZERO


func take_hit(strength: float, at: Vector3, source: String) -> void:
	if owner_of_hits != null and owner_of_hits.has_method("take_hit"):
		owner_of_hits.call("take_hit", strength, at, source)
