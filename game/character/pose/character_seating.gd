class_name CharacterSeating
extends RefCounted

## LO SENTADO Y LO PLANTADO: las piernas en la silla (sus ejes, los pies y las rodillas, la cápsula clavada al asiento)
## y los pies clavados en un piso que se mueve. Una pieza de BoneInstantiator (ver su comentario): se partió el
## 13/11/2026; el estado público sigue en el personaje (`bi`).

var bi: BoneInstantiator = null
## Targets de las piernas sentadas, cacheados por _pose_legs_seated para que _repin_legs_seated
## re-resuelva contra los MISMOS. Ver _solve_frame.
var seated_left_foot:  Vector3 = Vector3.ZERO
var seated_right_foot: Vector3 = Vector3.ZERO
var seated_left_pole:  Vector3 = Vector3.ZERO
var seated_right_pole: Vector3 = Vector3.ZERO
## Cuánto de la tibia llega el pie sentado: casi entera (ver `_pose_legs_seated`).
const SEATED_SHIN_REACH := 0.995
## Lo más que se mete la pantorrilla para atrás, sentado (ver `_pose_legs_seated`).
const SEATED_MAX_TUCK := deg_to_rad(55.0)
## Cuánto baja la punta de los pies, sentado (ver `_repin_legs_seated`).
const SEATED_FOOT_POINT := deg_to_rad(18.0)
## Parado a bordo ES IGUAL QUE SENTADO, sólo que las piernas van al piso en vez de a la silla (el usuario: «la inclinación del root bone por inercia o por impacto sucede también cuando están parados; la única
## diferencia es que están con las piernas en el piso en vez de la silla»). La cápsula va fija en su punto de la meca y
## girada con ella (ver CharacterRigidBody3D.ride); los pies, CLAVADOS en dos puntos del piso de la meca guardados en el
## marco de la cápsula (`plant_feet`), así nada de lo que recuerda queda en el mundo. Sin rayos contra el casco —que en
## las maquetas se mueve a mano y salta de a pasos— y sin pasos: el piso lo dice la meca. La pelvis sí baja lo que haga
## falta para alcanzarlos (la respiración la sube unos centímetros), como en tierra. Lo de arriba —la inclinación por inercia o por golpes, la respiración, los brazos— es lo de siempre.
var planted_feet: Array[Vector3] = []


func _init(owner: BoneInstantiator) -> void:
	bi = owner


## Sentado, la cápsula va clavada sobre el asiento, en la línea de su arriba (ver LOS EJES DE LA SILLA). Corre en cada
## paso de física, no sólo al resolver la pose (ver «Cuándo se resuelve la pose»): la altura la lleva el asiento
## (SeatInteractable._carry_occupant).
func pin_capsule_to_seat() -> void:
	var seat_pos : Vector3 = bi.current_seat.global_position
	var up := seat_up()
	bi.char_rigidbody.global_position = seat_pos + up * (bi.char_rigidbody.global_position - seat_pos).dot(up)


## Sentado, todo se arma en los ejes del asiento y no en los del mundo: su arriba, y adelante —para donde mira el que
## está sentado, sobre el plano del asiento—. La meca cabecea y se ladea, y con la vertical del mundo la pelvis se
## despegaba de la silla (medido: 12 cm para atrás con 20° de cabeceo, 11 cm de costado con 20° de alabeo) y las piernas
## y los pies quedaban armados para un piso derecho. Lo vio el usuario cuando la tripulación dejó de congelarse.
func seat_up() -> Vector3:
	return bi.current_seat.global_basis.y.normalized()


func seat_forward() -> Vector3:
	var up := seat_up()
	var forward := -bi.char_rigidbody.global_transform.basis.z
	forward -= up * forward.dot(up)
	return forward.normalized() if forward.length() > 0.001 else -bi.current_seat.global_basis.z.normalized()


## Donde va la base de la columna: arriba del asiento su alto, y atrás lo que dice la silla.
func seat_pelvis_point() -> Vector3:
	return bi.current_seat.global_position + seat_up() * bi.current_seat.height \
		- seat_forward() * bi.current_seat.pelvis_back_of_centre()


## Piernas sentadas: plegadas hacia adelante, sin piso ni marcha. Cachea los targets porque
## _repin_legs_seated re-resuelve contra los mismos — recalcularlos después de que los overrides de
## brazos inclinaron el spine arrastraría los pies con el torso.
func pose_legs_seated() -> void:
	var forward := seat_forward()
	var down := -seat_up()

	# ── SENTADO DERECHO (22/10/2026, lo pidió el usuario): el muslo recto hacia adelante, horizontal, desde donde
	# nace (el hueso del muslo), y la pantorrilla a 90°, recta para abajo. Antes la pantorrilla iba un poco para atrás y
	# el pie quedaba corto (0,85 de la tibia). Un pelo menos que la tibia entera, para que la IK no quede en el borde.
	var left_hip  := bi.custom_bones_util.left_higher_leg.global_position
	var right_hip := bi.custom_bones_util.right_higher_leg.global_position
	var left_knee  := left_hip  + forward * bi.skel_sizes_util.higher_leg_size.y
	var right_knee := right_hip + forward * bi.skel_sizes_util.higher_leg_size.y
	# LOS PIES ADENTRO (28/10/2026, lo pidió el usuario: «que los pies los meta un poquito para adentro de la
	# silla, como en la vida real»): si las rodillas quedan más adelante que lo de siempre, la pantorrilla se va para
	# atrás justo eso, y el pie vuelve a caer donde caía, bajo el borde del asiento.
	var shin_length := bi.skel_sizes_util.lower_leg_size.y * SEATED_SHIN_REACH
	var past: float = bi.current_seat.knees_past_edge(bi.skel_sizes_util.higher_leg_size.y)
	var tuck := asin(clampf(past / shin_length, 0.0, sin(SEATED_MAX_TUCK)))
	var shin := (down * cos(tuck) - forward * sin(tuck)) * shin_length
	seated_left_foot  = left_knee  + shin
	seated_right_foot = right_knee + shin
	seated_left_pole  = left_knee  + forward
	seated_right_pole = right_knee + forward

	repin_legs_seated()
	bi.ik_util.left_leg_current_target.global_position  = seated_left_foot
	bi.ik_util.right_leg_current_target.global_position = seated_right_foot


func is_planted() -> bool:
	return planted_feet.size() == 2 and is_instance_valid(bi.char_rigidbody) and bi.char_rigidbody._riding


## CLAVA LOS PIES en el piso que pasa por `floor_point` (un punto del mundo), cada uno bajo su cadera, separados como su
## marcha (`raycast_stance_offset`) y con el tobillo a su alto sobre el piso (`ankle_height`). Se guardan en el marco de
## la cápsula.
func plant_feet(floor_point: Vector3) -> void:
	planted_feet.clear()
	if not is_instance_valid(bi.char_rigidbody):
		return
	var body := bi.char_rigidbody.global_transform
	var ankle_local := body.affine_inverse() * (floor_point + body.basis.y.normalized() * bi.skel_sizes_util.ankle_height)
	for left: bool in [true, false]:
		var side := -1.0 if left else 1.0
		planted_feet.append(Vector3(side * bi.skel_sizes_util.raycast_stance_offset, ankle_local.y, 0.0))


## Los blancos de los pies, en sus puntos de la meca: de ellos mide la bajada de pelvis y a ellos van las piernas.
func place_planted_targets() -> void:
	var body := bi.char_rigidbody.global_transform.orthonormalized()
	bi.ik_util.left_leg_current_target.global_position = body * planted_feet[0]
	bi.ik_util.right_leg_current_target.global_position = body * planted_feet[1]


## Las piernas a sus pies clavados, con la rodilla adelante y los pies planos sobre el piso de la meca.
func pose_legs_planted() -> void:
	place_planted_targets()
	var body := bi.char_rigidbody.global_transform.orthonormalized()
	var forward := -body.basis.z
	var up := body.basis.y
	var tilt := Basis(Quaternion(Vector3.UP, up))
	var flat := tilt.inverse() * forward
	var yaw := atan2(-flat.x, -flat.z)
	for left: bool in [true, false]:
		var foot := body * planted_feet[0 if left else 1]
		var upper := bi.custom_bones_util.left_higher_leg if left else bi.custom_bones_util.right_higher_leg
		var lower := bi.custom_bones_util.left_lower_leg if left else bi.custom_bones_util.right_lower_leg
		bi.ik_util.solve_two_bone_ik(upper, lower, foot, foot + up * bi.skel_sizes_util.leg_height * 0.5 + forward)
		var bone: CustomBone = bi.custom_bones_util.left_foot if left else bi.custom_bones_util.right_foot
		if is_instance_valid(bone):
			bone.global_basis = tilt * IkUtil.level_basis(left, yaw)


## Re-resuelve el IK de las piernas sentadas contra los targets ya cacheados (los huesos se movieron
## porque algo tocó el spine después de plantarlas).
func repin_legs_seated() -> void:
	bi.ik_util.solve_two_bone_ik(bi.custom_bones_util.left_higher_leg,  bi.custom_bones_util.left_lower_leg,  seated_left_foot,  seated_left_pole)
	bi.ik_util.solve_two_bone_ik(bi.custom_bones_util.right_higher_leg, bi.custom_bones_util.right_lower_leg, seated_right_foot, seated_right_pole)
	# LOS PIES, NIVELADOS (22/10/2026: el usuario los vio en posiciones raras al sentarse): sentado nadie los
	# nivelaba (ver IkUtil._level_foot) y colgaban rígidos de la tibia, con su inclinación. Planos, mirando adonde mira.
	# CON LA PUNTA UN POCO PARA ABAJO (29/10/2026, lo pidió el usuario: «ahora están como muy rígidos y es medio
	# poco natural la pose»): `SEATED_FOOT_POINT`, girados sobre el eje de costado del cuerpo.
	# Nivelados con el asiento (ver LOS EJES DE LA SILLA): armados como en un piso derecho y llevados a su inclinación.
	var tilt := Basis(Quaternion(Vector3.UP, seat_up()))
	var flat := tilt.inverse() * seat_forward()
	var yaw := atan2(-flat.x, -flat.z)
	var point := Basis(Basis(Vector3.UP, yaw) * Vector3.RIGHT, -SEATED_FOOT_POINT)
	for left: bool in [true, false]:
		var foot: CustomBone = bi.custom_bones_util.left_foot if left else bi.custom_bones_util.right_foot
		if is_instance_valid(foot):
			foot.global_basis = tilt * point * IkUtil.level_basis(left, yaw)
