class_name CharacterJump
extends RefCounted

## EL SALTO CARGADO, AGACHARSE Y ECHARSE ATRÁS AL LLEVAR: lo que la intención pide y el cuerpo hace de a poco. Una pieza
## de BoneInstantiator (se partió el 13/11/2026); lo que leen otros —`jump_squat_t`, `crouch_t`, `carry_lean`,
## `taking_off`— sigue en el personaje (`bi`).
##
## EL SALTO: al apretar el salto (`intent.jump`) parado en el piso, sin agacharse ni sentarse, empieza a cargar —la pelvis
## baja, `jump_squat_t`— hasta `time_to_max_jump`; al soltarlo salta, de 30 % a 100 % de su `jump_height` según lo cargado
## (la carga interpola ALTURA, no impulso: así la barra es lineal con lo que se ve saltar, y un toque sin cargar sigue
## siendo un saltito útil). Si en el medio deja de poder (en el aire, agachado), se cancela. El mismo para el teclado y el
## guion. Con movimiento directo (el ente) no hay carga: salta ya (ver PlayerController).
##
## AGACHARSE (ver CharacterIntent.crouch): baja en `AnimationModifiers.CROUCH_S` y achica la cápsula al terminar de bajar;
## al pararse, la cápsula vuelve ya. Agachado camina más lento —con movimiento directo, `DIRECT_CROUCH_SPEED`—. Sentado
## o volando libre no se agacha. Un proxy de red no: le llega `crouch_t`.

## Lo que tarda en echarse atrás o adelante con el tiro (s): rápido, es un golpe.
const THROW_LEAN_S := 0.06
const TAKE_OFF_MAX_S := 0.3
const DIRECT_CROUCH_SPEED := 0.45
const CROUCH_SPEED := 0.6

var bi: BoneInstantiator = null
var charge := 0.0
var jump_charging := false
var jump_release_left := 0.0
var taking_off_t := 0.0
var crouched := false


func _init(owner: BoneInstantiator) -> void:
	bi = owner


## Lo cargado, de 0 a 1 (la barra del HUD).
func jump_charge() -> float:
	var arch := bi.entity_archetype
	return charge / maxf(arch.time_to_max_jump, 0.001) if arch != null else 0.0


## LO QUE SE ECHA ATRÁS CON LO QUE LLEVA, ahora (ver LocomotionCommon, EL CUERPO SE ECHA ATRÁS): hacia `carry_lean`, a su
## ritmo. Lleva algo si su agarre es una caja que alguien sostiene.
func update_carry_lean(delta: float) -> void:
	var tuning := LocomotionCommon.base()
	var want := Vector2.ZERO
	var grab := bi.intent.grab as GrabbableInteractable if bi.intent != null else null
	var holding := is_instance_valid(grab) and grab.box_half != Vector3.ZERO and grab.hold_count() > 0 \
		and not bi.is_seated and is_instance_valid(bi.char_rigidbody)
	# EL TIRO (ver LocomotionCommon, TIRAR): al cargar se echa atrás, al empujar se va adelante, alejándose del paquete y
	# hacia él; más rápido que llevar.
	var throwing := holding and is_instance_valid(bi.anim_mod) and bi.anim_mod.throw_with_box
	if throwing:
		var away_box := Vector2(0.0, 1.0)
		var from := grab.get_parent() as Node3D
		if is_instance_valid(from):
			var local := bi.char_rigidbody.global_basis.orthonormalized().inverse() \
				* (bi.char_rigidbody.global_position - from.global_position)
			if Vector2(local.x, local.z).length() > 0.05:
				away_box = Vector2(local.x, local.z).normalized()
		want += away_box * tuning.throw_lean(bi.anim_mod)
	if tuning.carry_lean_mode != 0 and holding:
		var body := grab.get_parent() as RigidBody3D
		var share := 1.0
		if tuning.carry_lean_by_weight and is_instance_valid(body):
			share = clampf(GrabbableInteractable.load_of(body.mass, maxf(grab.total_strength(),
				bi.entity_archetype.strength if bi.entity_archetype != null else 1.0)), 0.0, 1.0)
		if tuning.carry_lean_mode == 2:
			var v := bi.char_rigidbody.linear_velocity
			var top: float = maxf(bi.entity_archetype.speed * bi.entity_archetype.sprint_multiplier \
				* CharacterRigidBody3D.SPEED_SCALE, 0.01) if bi.entity_archetype != null else 1.0
			share *= clampf(Vector2(v.x, v.z).length() / top, 0.0, 1.0)
		# Alejándose del paquete: del paquete hacia el cuerpo, en los ejes de la cápsula; si no, hacia atrás.
		var away := Vector2(0.0, 1.0)
		if tuning.carry_lean_away and is_instance_valid(body):
			var local := bi.char_rigidbody.global_basis.orthonormalized().inverse() \
				* (bi.char_rigidbody.global_position - body.global_position)
			if Vector2(local.x, local.z).length() > 0.05:
				away = Vector2(local.x, local.z).normalized()
		want += away * deg_to_rad(tuning.carry_lean_deg) * share
	var pace := minf(tuning.carry_lean_s, THROW_LEAN_S) if throwing else tuning.carry_lean_s
	bi.carry_lean = bi.carry_lean.lerp(want, 1.0 - exp(-delta / maxf(pace, 0.01) * 3.0))
	bi.carry_lean_share = clampf(bi.carry_lean.length() / maxf(deg_to_rad(tuning.carry_lean_deg), 0.001), 0.0, 1.0)


func update_jump(delta: float) -> void:
	if bi.taking_off:
		taking_off_t += delta
		if not is_instance_valid(bi.char_rigidbody) or not bi.char_rigidbody.is_grounded or taking_off_t > TAKE_OFF_MAX_S:
			bi.taking_off = false
	if bi._jump_pending >= 0.0:
		jump_release_left -= delta
		if jump_release_left <= 0.0:
			if is_instance_valid(bi.char_rigidbody) and bi.char_rigidbody.is_grounded:
				bi.char_rigidbody.jump_to_height(bi._jump_pending)
				bi.taking_off = true
				taking_off_t = 0.0
			bi._jump_pending = -1.0
	var want := bi.intent.jump
	var pressed := want and not bi._jump_was
	bi._jump_was = want
	if not is_instance_valid(bi.char_rigidbody) or not bi.kind.simulates() or bi.entity_archetype == null:
		return
	var rb := bi.char_rigidbody
	# Con un salto pendiente (ver EL SALTO SALE AL TERMINAR DE SOLTAR LA CARGA) no carga otro: si no, volver a apretar en
	# esos 0,08 s reiniciaba el pendiente y el salto nunca salía (medido: el dummy de «subir y bajar» apretaba y soltaba
	# un cuadro sí y uno no hasta chocar el escalón).
	var can := rb.is_grounded and not bi.is_seated and bi.crouch_t < 0.5 and not rb.creative_mode \
		and bi.kind.motion == CharacterKind.Motion.PHYSICAL and rb.input_enabled and bi._jump_pending < 0.0
	if pressed and can:
		jump_charging = true
	if not jump_charging:
		return
	if not can:
		cancel_jump()
		return
	var arch := bi.entity_archetype
	if want:
		charge = minf(charge + delta, arch.time_to_max_jump)
		bi.jump_squat_t = jump_charge()
		return
	bi._jump_pending = lerpf(arch.jump_height * 0.3, arch.jump_height, jump_charge())
	jump_release_left = bi.JUMP_RELEASE_S
	cancel_jump()


func update_crouch() -> void:
	if not is_instance_valid(bi.char_rigidbody) or not bi.kind.simulates():
		return
	var rb := bi.char_rigidbody
	var want := bi.intent.crouch and not bi.is_seated and not rb.creative_mode
	if want == crouched:
		return
	crouched = want
	var tw := bi.create_tween()
	tw.tween_property(bi, "crouch_t", 1.0 if want else 0.0, AnimationModifiers.CROUCH_S)
	if want:
		tw.tween_callback(func() -> void: rb.set_crouched(true))
	else:
		rb.set_crouched(false)
	var slow := DIRECT_CROUCH_SPEED if bi.kind.motion == CharacterKind.Motion.DIRECT else CROUCH_SPEED
	rb.crouch_speed_factor = slow if want else 1.0


func cancel_jump() -> void:
	jump_charging = false
	charge = 0.0
	bi.create_tween().tween_property(bi, "jump_squat_t", 0.0, bi.JUMP_RELEASE_S)
