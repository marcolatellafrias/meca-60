class_name AnimationModifiers
extends Node

var bi: BoneInstantiator

const JUMP_SQUAT_Y    := -0.3
const JUMP_SQUAT_Z    :=  0.13
const JUMP_SQUAT_TILT :=  0.3
## LA AGACHADA, UNA SOLA MEDIDA (04/11/2026, el dios del juego, mirando «agacharse en el lugar»: «los personajes podrían
## agacharse mucho más»): la cadera baja `CROUCH_SHARE` del largo de SU pierna (`crouch_drop`), y lo mismo el pecho —de
## donde sale el alcance, ver BoneInstantiator.get_interaction_origin— y la cámara (FirstPersonView); la cápsula queda
## en `CharacterRigidBody3D.CROUCH_CAPSULE` de su alto. *Hasta entonces la pose bajaba 30 cm fijos para todos (−0,3),
## el alcance el 35 % de la pierna y la cápsula el 55 %: tres medidas que no coincidían.*
const CROUCH_SHARE    :=  0.55
## LO QUE TARDA EN AGACHARSE Y EN PARARSE (s), el jugador y los dummies (04/11/2026, el dios del juego: «es como casi
## inmediata… aumentaría un poquito la duración»; era 0,12).
const CROUCH_S        :=  0.25
const CROUCH_Z        :=  0.2
const CROUCH_TILT     :=  0.45
const THROW_CHARGE_TILT: float = 0.3
const THROW_PUSH_TILT:   float = 0.48
const THROW_PUSH_DECAY:  float = 2.5

var jump_squat_t:    float = 0.0
var crouch_t:        float = 0.0
var throw_t:         float = 0.0
var throw_push_t:    float = 0.0
var throw_world_dir: Vector3 = Vector3.FORWARD
## EL TIRO DE UNA CAJA (ver LocomotionCommon, TIRAR): con una caja en las manos el pecho no se tuerce acá —lo echa atrás y
## adelante el echarse atrás de llevar, que el tope del pecho sigue— y las manos se quedan en la caja. Lo cargado al
## soltar (`throw_from`) y desde cuándo empuja.
var throw_with_box := false
var throw_from := 0.0
var _push_elapsed := 0.0

var is_seated: bool = false

## Cuánto tiene que bajar la pelvis, en metros, para que las dos piernas alcancen sus pies. Lo mide
## BoneInstantiator._update_pelvis_drop cada frame y acá solo se aplica. Siempre ≥ 0.
var pelvis_drop: float = 0.0


func _ready() -> void:
	bi = get_parent() as BoneInstantiator

func apply(delta: float) -> void:
	if not is_instance_valid(bi):
		return
	if throw_push_t > 0.0:
		throw_push_t = max(0.0, throw_push_t - delta * THROW_PUSH_DECAY)
		_push_elapsed += delta
	elif throw_t <= 0.0:
		throw_with_box = false
	_apply_root_offsets()
	_apply_postures()


## LAS POSTURAS PERSISTENTES de los huesos que la lleven (ver CustomBone.posture) — los dos hombros, la
## lumbar y el pecho con la curva de la espalda, y la cabeza quedándose derecha.
##
## VA ACÁ Y POR FRAME, y no es una elección: la capa procedural reescribe cada hueso registrado desde su
## reposo en cada cuadro (ver ProceduralBoneAnimation.update), así que una postura escrita una sola vez se
## borra en el siguiente. Y va DESPUÉS de ese reseteo y ANTES de la IK de brazos, así que el balanceo de la
## marcha se compone encima de la postura y el brazo se resuelve desde el hombro ya colocado.
##
## ⚠ PERO NO TODOS LOS HUESOS CON POSTURA LOS RESETEA ESA CAPA, y multiplicar sobre lo que haya solo está
## bien si alguien los dejó en su reposo primero. La capa procedural solo resetea a los que tiene
## REGISTRADOS, y quiénes son depende del personaje: la cabeza sigue la cámara en el jugador y en el proxy,
## y en un maniquí del sandbox no la maneja nadie. Ahí la misma postura se le aplicaba de nuevo cada cuadro:
## medido, 18,3° de compensación daban 128° a los siete cuadros — la cabeza girando sola.
##
## Y no se le pregunta a la capa quién maneja: se le pregunta AL HUESO si está tal cual lo dejamos. Si lo
## está, nadie lo reseteó y se parte del reposo; si no, hay animación del cuadro encima y se compone sobre
## ella. Es una comparación y no una lista que haya que mantener al día, y se resuelve en el cuadro, que es
## cuando la respuesta puede cambiar — registrarse y desregistrarse pasa en vivo (ver
## Animations.refresh_camera_animations).
func _apply_postures() -> void:
	if bi.custom_bones_util == null:
		return
	for bone in bi.custom_bones_util.postured:
		if not is_instance_valid(bone):
			continue
		var posed: Basis = bone.posture * bone.rest_transform.basis
		bone.transform.basis = posed if bone.transform.basis.is_equal_approx(posed) 			else bone.posture * bone.transform.basis

func _apply_root_offsets() -> void:
	if is_seated:
		return
	# La bajada geométrica va con el mismo signo que agacharse: las tres razones para bajar la pelvis
	# se suman en un solo número. Ver technical/character-animation.md (ajuste de pelvis).
	var y          := squat_y()                      - crouch_drop(bi) * crouch_t - pelvis_drop
	var squat      := jump_squat_t * LocomotionCommon.base().jump_squat
	var z          := JUMP_SQUAT_Z    * squat + CROUCH_Z    * crouch_t
	# Y LA POSE TIRADA ADELANTE O ATRÁS (ver WalkStyle.posture_lean): con el mismo signo que agacharse.
	var tilt       := JUMP_SQUAT_TILT * squat + CROUCH_TILT * crouch_t + bi.walk_style.posture_lean
	var throw_tilt := 0.0 if throw_with_box else -THROW_CHARGE_TILT * throw_t + THROW_PUSH_TILT * throw_push_t
	var spine      := bi.custom_bones_util.lower_spine
	spine.position.z += z
	spine.position.y += y
	spine.transform.basis *= Basis(Vector3.RIGHT, -(tilt + throw_tilt))

## Lo que baja la cadera agachado del todo (m; ver LA AGACHADA).
static func crouch_drop(who: BoneInstantiator) -> float:
	if who == null or who.skel_sizes_util == null:
		return 0.3
	return who.skel_sizes_util.leg_height * CROUCH_SHARE


## LO QUE BAJA LA PELVIS AL CARGAR EL SALTO, ahora: lo de todos (LocomotionCommon, Despegue). La lee también la cámara (ver
## FirstPersonView). *Hasta el 05/11/2026 además por lo de su arquetipo.*
func squat_y() -> float:
	return JUMP_SQUAT_Y * jump_squat_t * LocomotionCommon.base().jump_squat


func trigger_throw_push(world_dir: Vector3, with_box := false) -> void:
	throw_world_dir = world_dir
	throw_from      = throw_t
	throw_with_box  = with_box
	throw_push_t    = 1.0
	throw_t         = 0.0
	_push_elapsed   = 0.0

func set_throw_charge(t: float, world_dir: Vector3, with_box := false) -> void:
	throw_t         = t
	throw_world_dir = world_dir
	throw_with_box  = with_box

func cancel_throw() -> void:
	throw_t = 0.0
	if throw_push_t <= 0.0:
		throw_with_box = false

## Lo que va del empujón, de 0 a 1 en `LocomotionCommon.throw_push_s` (y 1 después); −1 si no está empujando.
func throw_push_progress() -> float:
	if throw_push_t <= 0.0:
		return -1.0
	return clampf(_push_elapsed / maxf(LocomotionCommon.base().throw_push_s, 0.001), 0.0, 1.0)

func reset() -> void:
	jump_squat_t = 0.0
	crouch_t     = 0.0
	throw_t      = 0.0
	throw_push_t = 0.0
	throw_with_box = false
