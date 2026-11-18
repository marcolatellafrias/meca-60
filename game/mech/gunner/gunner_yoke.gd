class_name GunnerYoke
extends ControllableInteractable

## EL YUGO DE LA TORRETA DEL ARTILLERO (ver GunnerTurret): una barra con dos manijas, una sola pieza. ES UN CONTROL CON
## MODO (ver ControllableInteractable.has_mode), como los mandos plegables de abajo (FoldingArm): con el clic derecho
## mantenido se agarra, la mirada va al frente de la torreta (`mode_look`) y queda libre, y LA TORRETA PERSIGUE LA
## MIRADA (GunnerTurret.aim, cada paso); al soltarlo, la torreta queda donde quedó. El clic izquierdo, el gatillo
## (GunnerWeapons.trigger).

## La torreta que apunta (la pone quien lo arma).
var turret: GunnerTurret = null


func grip_kind() -> Grip:
	return Grip.WRAP


func has_mode() -> bool:
	return true


func enter_mode() -> void:
	visual_value = 1.0
	_emit_if_changed(1.0)
	# Agarrarlo es tomar la torreta (ver GunnerTurret, «La red»).
	if turret != null:
		turret.take_control()


func exit_mode() -> void:
	visual_value = 0.0
	_emit_if_changed(0.0)
	# Soltar el yugo suelta también el gatillo.
	if turret != null:
		turret.weapons.trigger(false)


## Al agarrarlo, la mirada va al frente de la torreta, a la altura de los ojos.
func mode_look() -> Vector3:
	if turret == null:
		return Vector3.INF
	return turret.frame.global_transform * Vector3(0.0, 1.15, -10.0)


## EL GATILLO: el clic izquierdo con el yugo agarrado (GunnerWeapons.trigger).
func mode_use(pressed: bool) -> void:
	if turret != null:
		turret.weapons.trigger(pressed)


func mode_steer(world_yaw: float, world_pitch: float) -> void:
	if turret != null:
		turret.aim(world_yaw, world_pitch)


## Las dos manijas.
func _setup_handle_points(_size: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		add_handle_point_local(Vector3(side * 0.14, 0.12, 0.0), Vector3.UP)
