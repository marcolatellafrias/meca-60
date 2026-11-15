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


## LA ARMA con una caja de `size` (m) en `center` (local).
func shape(size: Vector3, center: Vector3) -> void:
	Clay.shape_box(self, size, center)


func take_hit(strength: float, at: Vector3, source: String) -> void:
	if owner_of_hits != null and owner_of_hits.has_method("take_hit"):
		owner_of_hits.call("take_hit", strength, at, source)
