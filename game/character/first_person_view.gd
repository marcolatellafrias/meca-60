class_name FirstPersonView
extends RefCounted

## ── DÓNDE VAN LOS OJOS DE UN PERSONAJE (03/11/2026, el usuario aprobó camara-casos.md) ────────────────────────
## Una sola regla para toda cámara de primera persona —la del jugador (PlayerController) y la de quien posee a un
## personaje para mirar por sus ojos (PossessionCamera)—, así ven lo mismo. Cada cámara tiene su propio estado (la pelvis
## lenta, el sacudón suavizado), así que cada una tiene el suyo de éstos.
##
## DOS REGLAS, en el marco de la cápsula:
##   1. EN ALTURA, LA CABEZA, MENOS LO QUE NO ES INFORMACIÓN: la pelvis, más la altura de ojos sobre ella EN REPOSO y con
##      su postura (CustomBonesUtil.posed_rest_eye_above_pelvis). Ninguna inclinación de la columna la mueve —la de
##      correr, la inercia, la deriva, la del agarre, la del lanzamiento, la de mirar arriba sentado—: rotan alrededor de
##      la pelvis y acá no se leen. La pelvis se separa en lo lento —escaleras, desniveles: información, 1:1— y lo que
##      va y viene —el paso, la respiración, el rebote del aterrizaje—, que entra por la perilla del balanceo
##      (`head_bob`, 1 = como estaba). Agacharse y cargar el salto, 1:1 y sin demora.
##   2. LOS GOLPES SÍ, 1:1 (ver EL SACUDÓN DE LOS GOLPES): sigue el giro de la columna que les da la animación, de
##      costado, de frente y en altura.
## Sentado es la misma regla con la pelvis de la silla YA ASENTADA (SeatInteractable.settled_height): sube derecho a su
## altura final, sin pasar por abajo mientras la silla se acomoda. Tirado, en la cabeza del ragdoll; levantándose, de ahí
## a la de parado, suave. El ente es la perilla en 0, no una regla aparte.
## *Antes: la altura exacta de la cabeza animada, con todo adentro; del 03/11/2026 un rato, fija a la silla sentado.*

## LA PERILLA DEL BALANCEO, de 0 a 1, para todos (ver arriba).
static var head_bob := 1.0
## Qué tan rápido sigue la pelvis lenta (1/s): un paso va y viene más rápido que esto; un escalón queda.
const PELVIS_FOLLOW := 3.0

var _pelvis_slow := NAN
## La pelvis de quien no tiene cuerpo físico, sobre su cápsula, fija (ver SIN CUERPO FÍSICO, PEGADO A SU CÁPSULA).
var _capsule_pelvis := NAN
var _eye_above_pelvis := 0.0
var _hit_smooth := Vector2.ZERO
var _capsule: CharacterRigidBody3D = null


## LOS OJOS DE `bi`, en el mundo, con el balanceo `bob` (de 0 a 1). `delta`: el tiempo desde la última vez (0, sin avanzar
## los suavizados).
func eye(bi: BoneInstantiator, delta: float, bob: float) -> Vector3:
	var rb := bi.char_rigidbody
	# Un cuerpo nuevo (se reconstruyó): todo se vuelve a medir, con el rig ya en su reposo.
	if rb != _capsule:
		_capsule = rb
		_pelvis_slow = NAN
		_capsule_pelvis = NAN
		_eye_above_pelvis = 0.0
		_hit_smooth = Vector2.ZERO
	if _eye_above_pelvis <= 0.0:
		_eye_above_pelvis = bi.custom_bones_util.posed_rest_eye_above_pelvis()
	var rd := bi.ragdoll_util
	if is_instance_valid(rd) and rd.is_active and is_instance_valid(rd.head_body):
		_pelvis_slow = NAN
		return rd.head_body.global_position
	var at := _awake_eye(bi, delta, bob)
	if is_instance_valid(rd) and rd.is_recovering and is_instance_valid(rd.head_body):
		var t := 1.0 - clampf(rd._recovery_timer / maxf(rd.recovery_duration, 0.001), 0.0, 1.0)
		return rd.head_body.global_position.lerp(at, smoothstep(0.0, 1.0, t))
	return at


func _awake_eye(bi: BoneInstantiator, delta: float, bob: float) -> Vector3:
	var rb := bi.char_rigidbody
	var axes := rb.global_transform.orthonormalized()
	var at: Vector3
	if bi.is_seated and bi.current_seat is SeatInteractable:
		var seat := bi.current_seat as SeatInteractable
		# Atrás, el de quien está sentado: la silla gira con él (ver BoneInstantiator._seat_forward).
		var up := seat.global_basis.y.normalized()
		var back := axes.basis.z - up * axes.basis.z.dot(up)
		back = back.normalized() if back.length() > 0.001 else seat.global_basis.z.normalized()
		at = seat.global_position + up * (seat.settled_height() + _eye_above_pelvis) + back * seat.pelvis_back_of_centre()
		_pelvis_slow = NAN
	else:
		var spine_local := axes.affine_inverse() * bi.custom_bones_util.lower_spine.global_position
		# Agacharse y cargar el salto: información, sin filtro (ver AnimationModifiers._apply_root_offsets).
		var squat := (bi.anim_mod.squat_y() if is_instance_valid(bi.anim_mod) else 0.0) \
			- AnimationModifiers.crouch_drop(bi) * bi.crouch_t
		# La respiración es balanceo, pero lenta: no la separa el filtro, se la saca entera y vuelve por la perilla.
		var breath := bi.passive_animations.breath_lift() if is_instance_valid(bi.passive_animations) else 0.0
		var rest := spine_local.y - squat - breath
		# SIN CUERPO FÍSICO, PEGADO A SU CÁPSULA (07/11/2026, el usuario: «cuando estoy en modo ente y camino… se
		# me baja la cámara»; ver CharacterRigidBody3D.has_body_physics): el ente es un personaje entero que no se ve, y
		# la pelvis de ese cuerpo baja con los pasos —por la pelvis lenta se colaban hasta 7 cm caminando—. Sus ojos van
		# a una altura fija sobre la cápsula —la de la pelvis en su reposo congelado (ver CustomBonesUtil.freeze_rest)—,
		# más agacharse.
		if not rb.has_body_physics():
			if is_nan(_capsule_pelvis):
				_capsule_pelvis = bi.custom_bones_util.lower_spine.rest_transform.origin.y
			_pelvis_slow = NAN
			var fixed := axes * Vector3(0.0, _capsule_pelvis + squat + _eye_above_pelvis, 0.0)
			return fixed + _hit_sway(bi, fixed, delta)
		if is_nan(_pelvis_slow):
			_pelvis_slow = rest
		elif delta > 0.0:
			_pelvis_slow = lerpf(_pelvis_slow, rest, 1.0 - exp(-PELVIS_FOLLOW * delta))
		at = axes * Vector3(0.0, _pelvis_slow + bob * (rest - _pelvis_slow + breath) + squat + _eye_above_pelvis, 0.0)
	return at + _hit_sway(bi, at, delta)


## ── EL SACUDÓN DE LOS GOLPES (02/11/2026) ─────────────────────────────────────────────────────────────────────────
## Los ojos van con la cabeza cuando un golpe inclina el cuerpo, igual que el cuerpo —el mismo giro de la base de la
## columna que le da la animación (BoneAnimations.IMPACT_LEAN), con el mismo suavizado—, aunque no lo tumbe: el golpe es
## información de juego. Sólo los golpes: la inercia, que inclina el cuerpo todo el viaje, no los mueve (ver
## CharacterRigidBody3D, EL RESORTE EN DOS PARTES). Lo pidió el usuario, igual al del cuerpo para empezar: «lo
## haría igual al sacudón real. Y después en todo caso lo tuiqueo un poco».
func _hit_sway(bi: BoneInstantiator, at: Vector3, delta: float) -> Vector3:
	var pelvis := bi.custom_bones_util.lower_spine
	_hit_smooth = _hit_smooth.lerp(bi.char_rigidbody.hit_xz, clampf(delta * LocomotionSignals.IMPACT_XZ_SMOOTH, 0.0, 1.0))
	if _hit_smooth.is_zero_approx() or not is_instance_valid(pelvis):
		return Vector3.ZERO
	var axes := pelvis.global_basis.orthonormalized()
	var turn := Basis(axes.x, BoneAnimations.IMPACT_LEAN * _hit_smooth.y) \
		* Basis(-axes.z, BoneAnimations.IMPACT_LEAN * _hit_smooth.x)
	var arm := at - pelvis.global_position
	return turn * arm - arm
