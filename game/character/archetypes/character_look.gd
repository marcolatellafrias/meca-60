class_name CharacterLook
extends Resource

## EL ASPECTO DE UN PERSONAJE: lo que no sale del cuerpo sino que se le elige —la pose de la boca, los labios, lo que
## lleva en la cara, el sombrero, el cinturón, el traje— y la semilla del individuo. Todo como índices de sus catálogos
## (ver FaceLayout, FaceWear, Hats, Belts, Suits), −1 para nada.
##
## Lo pidió el dios del juego (11/10/2026) para LOS SEIS CANÓNICOS de la fila Personajes: un individuo fijo por
## arquetipo, con el aspecto que él controla, para igualar sus concept arts (ver CharacterLooks). Los extra de la cara
## no van acá: cada extra ya dice qué cuerpos lo llevan (ver FaceFeature.bodies).

## Los labios cuando se los pone: más de 0 es con labios (ver FaceLayout.mouth).
const LIPS := 0.014

## LA SEMILLA DEL INDIVIDUO dentro de su arquetipo (ver EntityInstantiation.debug_seed): la edad, el color, la cabeza y
## el brazo que la semilla elige entre los permitidos.
@export var seed := 1
## LA FORMA DE LA CABEZA (ver HeadForms), −1 la de arranque de su arquetipo (ver CharacterLooks.DEFAULT_HEAD_FORMS).
## La comparten todos los de su arquetipo, no sólo el canónico (ver CharacterLooks.head_form_for); se elige con el panel
## de la fila Personajes (ver CharacterLookPanel).
@export var head_form := -1
## LA POSE DE LA BOCA (ver FaceLayout.MOUTHS): plana, enojada, triste, semiabierta, ancha o angosta.
@export var mouth := FaceLayout.PLAIN
## LOS LABIOS: su grosor, 0 sin labios; el de siempre es `LIPS` (ver FaceLayout.mouth). Y su color. Se eligen en el F4,
## pestaña Accesorios (lo pidió el dios del juego, 16/10/2026; antes era la tecla J, sí o no).
@export_range(0.0, 0.04, 0.001) var lips := 0.0
@export var lip_color := FaceLayout.LIP_COLOR
## LO QUE LLEVA EN LA CARA, uno por lugar (ver FaceWear.Slot): en los ojos (lentes) y en la boca (pipa, cigarrillo). El
## número es el de FaceWear.NAMES; −1, nada.
@export var eye_wear := -1
@export var mouth_wear := -1
@export var hat := -1
@export var belt := -1
@export var suit := -1
## EL COLOR DE LA PIEL; transparente es el crema de siempre (ver CharacterBodyVisual.BODY_COLOR). El de los concept
## arts del 12/10/2026 es durazno. UNO SOLO PARA TODOS, el del gordo (02/11/2026, el dios del juego: «que use el mismo
## color base para todos. El color base del gordo me gusta»): también el de quien no tiene aspecto guardado.
@export var skin := Color(0.94921875, 0.7426483, 0.5450592, 1)
## LAS CEJAS Y LA BARBA (ver FaceHair), −1 nada, y EL COLOR DEL PELO.
@export var brows := -1
## LA INCLINACIÓN DE LAS CEJAS, en grados: + la punta de afuera arriba (enojado), − abajo (triste). Las cejas del catálogo
## son neutras (ver FaceHair, 22/10/2026).
@export_range(-35.0, 35.0, 0.5) var brow_tilt := 0.0
## LOS OJOS (22/10/2026): su forma (ver FaceLayout.EYE_SHAPES) y su inclinación en grados, + la punta de afuera arriba.
@export var eye_shape := 0
@export_range(-30.0, 30.0, 0.5) var eye_tilt := 0.0
## LAS ARRUGAS (ver FaceLayout, «LAS ARRUGAS»), cada una prendida o no.
@export var crow_feet := false
@export var forehead_lines := false
@export var nasolabial := false
## LA NARIZ (ver Noses), −1 sin.
@export var nose := -1
## EL PEINADO (ver Hair), −1 pelado.
## (`hairdo` desde el 22/10/2026: quedó un solo peinado, ver Hair; lo guardado como `hair` se pasa en `_set`.)
@export var hairdo := -1
@export var beard := -1
@export var hair_color := FaceHair.DEFAULT_COLOR

## ── LO DEL CUERPO, QUE LLEVA TODO EL ARQUETIPO ──────────────────────────────────────────────────
## Lo pidió el dios del juego (15/10/2026) para el panel del canónico (F4, ver CharacterLookPanel). Como la forma de la
## cabeza, no es sólo del canónico: lo lee el armado de cada personaje de ese arquetipo (ver SkeletonSizesUtil.create,
## BoneInstantiator).
##
## LOS HUESOS: grupo (ver BoneShape.GROUPS) → BoneShape. El que no está, como el código.
@export var bones: Dictionary = {}


## SE LO PONE A UN PERSONAJE ANTES DE ARMARLO: todo es una entrada de la construcción (ver BoneInstantiator), así que
## va antes del `add_child`. La semilla no: es del que arma, que sabe de qué arquetipo es.
func dress(bi: BoneInstantiator) -> void:
	bi.mouth = mouth
	bi.lips = lips
	bi.lip_color = lip_color
	bi.face_wear = worn_on_face()
	bi.hat = hat
	bi.belt = belt
	bi.suit = suit
	bi.skin = skin
	bi.brows = brows
	bi.brow_tilt = brow_tilt
	bi.face_look = {"eye_shape": eye_shape, "eye_tilt": eye_tilt, "crow_feet": crow_feet,
		"forehead_lines": forehead_lines, "nasolabial": nasolabial}
	bi.nose = nose
	bi.hair = hairdo
	bi.beard = beard
	bi.hair_color = hair_color


## ── UN ASPECTO SORTEADO ─────────────────────────────────────────────────────────────────────────
## Lo de la fila Gente (ver PeopleArchetype): todo al azar con la semilla menos el traje, que es de la fila. Qué TIPO de
## traje: uno de `DRAWN_SUITS`; si es de empresa, cuál de las tres lo decide la semilla.
const DRAWN_SUITS: Array[String] = ["empresa", "negocio", "peatón", "sin traje"]
const DRAWN_COMPANY := 0
const DRAWN_SHOP := 1
const DRAWN_PEDESTRIAN := 2
const DRAWN_NONE := 3
## Las chances, de 0 a 1. El sombrero sólo de peatón o sin traje: los empleados no llevan salvo que lo compren
## (decidido el 10/10/2026).
const DRAWN_LIPS := 0.4
const DRAWN_FACE_WEAR := 0.35
const DRAWN_BELT := 0.2
const DRAWN_HAT_PEDESTRIAN := 0.6
const DRAWN_HAT_PLAIN := 0.3


static func drawn(seed_value: int, suit_kind: int) -> CharacterLook:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "aspecto"])
	var out := CharacterLook.new()
	out.seed = seed_value
	out.mouth = rng.randi_range(0, FaceLayout.MOUTHS.size() - 1)
	out.lips = LIPS if rng.randf() < DRAWN_LIPS else 0.0
	out.mouth_wear = _drawn_in(rng, FaceWear.Slot.MOUTH)
	out.eye_wear = _drawn_in(rng, FaceWear.Slot.EYES)
	out.belt = rng.randi_range(0, Belts.DRAWN_COUNT - 1) if rng.randf() < DRAWN_BELT else -1
	var company := rng.randi_range(0, Suits.COMPANY_COUNT - 1)
	var hat_chance := 0.0
	match suit_kind:
		DRAWN_COMPANY:
			out.suit = Suits.EMPLOYEE + company
		DRAWN_SHOP:
			out.suit = Suits.SHOPKEEPER
		DRAWN_PEDESTRIAN:
			out.suit = Suits.PEDESTRIAN
			hat_chance = DRAWN_HAT_PEDESTRIAN
		_:
			hat_chance = DRAWN_HAT_PLAIN
	out.hat = rng.randi_range(0, Hats.NAMES.size() - 1) if rng.randf() < hat_chance else -1
	return out


## El renglón que lo cuenta, para los paneles del sandbox.
func describe() -> String:
	return "cabeza %d · boca %s · %s · cara: %s · sombrero: %s · cinturón: %s · traje: %s" % [head_form + 1, FaceLayout.mouth_names()[mouth],
		"con labios" if lips > 0.0 else "sin labios", _worn_names(), _name(Hats.NAMES, hat),
		_name(Belts.NAMES, belt), _name(Suits.NAMES, suit)]


## LO QUE LLEVA EN LA CARA, todos los lugares juntos: lo que el cuerpo arma (ver BoneInstantiator.face_wear).
func worn_on_face() -> PackedInt32Array:
	var out := PackedInt32Array()
	for index in [eye_wear, mouth_wear]:
		if index >= 0 and index < FaceWear.NAMES.size():
			out.append(index)
	return out


func _worn_names() -> String:
	var names := PackedStringArray()
	for index in worn_on_face():
		names.append(FaceWear.NAMES[index])
	return ", ".join(names) if not names.is_empty() else "nada"


## Uno de un lugar, o nada, con la chance de siempre.
static func _drawn_in(rng: RandomNumberGenerator, slot: int) -> int:
	var options := FaceWear.in_slot(slot)
	if options.is_empty() or rng.randf() >= DRAWN_FACE_WEAR:
		return -1
	return options[rng.randi_range(0, options.size() - 1)]


## EL ASPECTO GUARDADO ANTES DE LOS LUGARES (22/10/2026) tenía un solo `face_wear`: se lo pasa al lugar que le toca.
func _set(property: StringName, value: Variant) -> bool:
	# EL PEINADO GUARDADO ANTES DEL 22/10/2026 era un número de los cinco de entonces: sólo quedó la mata blanca, el 2.
	if property == &"hair":
		hairdo = 0 if int(value) == 2 else -1
		return true
	if property != &"face_wear":
		return false
	var index := int(value)
	if index >= 0 and index < FaceWear.NAMES.size():
		if FaceWear.SLOT_OF[index] == FaceWear.Slot.EYES:
			eye_wear = index
		else:
			mouth_wear = index
	return true


static func _name(names: Array[String], index: int) -> String:
	return names[index] if index >= 0 and index < names.size() else "nada"
