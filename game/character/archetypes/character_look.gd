class_name CharacterLook
extends Resource

## EL ASPECTO DE UN PERSONAJE: lo que no sale del cuerpo sino que se le elige —la forma de la cabeza y la piel— y la
## semilla del individuo. Uno por arquetipo (ver CharacterLooks).
##
## *Vino de character-parametric con trajes, sombreros, cinturones, lentes y pipa; en la meca se sacaron el 13/11/2026
## (el usuario: «me quiero quedar con la versión simplificada, sin traje ni sombrero»). Lo guardado de entonces se
## ignora al cargar (ver `_set`). La cara (la boca, los labios, los ojos, las cejas, las arrugas, la nariz, el pelo y la
## barba) se borró el mismo día: el usuario la rehace de cero, quizá pintada con píxeles.*

## Los labios cuando se los pone: más de 0 es con labios (ver FaceLayout.mouth).
const LIPS := 0.014

## LA SEMILLA DEL INDIVIDUO dentro de su arquetipo (ver EntityInstantiation.debug_seed): la edad, el color, la cabeza y
## el brazo que la semilla elige entre los permitidos.
@export var seed := 1
## LA FORMA DE LA CABEZA (ver HeadForms), −1 la de arranque de su arquetipo (ver CharacterLooks.DEFAULT_HEAD_FORMS).
## La comparten todos los de su arquetipo, no sólo el canónico (ver CharacterLooks.head_form_for); se elige con el panel
## de la fila Personajes (ver CharacterLookPanel).
@export var head_form := -1
## EL COLOR DE LA PIEL; transparente es el crema de siempre (ver CharacterBodyVisual.BODY_COLOR). El de los concept
## arts del 12/10/2026 es durazno. UNO SOLO PARA TODOS, el del gordo (02/11/2026, el dios del juego: «que use el mismo
## color base para todos. El color base del gordo me gusta»): también el de quien no tiene aspecto guardado.
@export var skin := Color(0.94921875, 0.7426483, 0.5450592, 1)


## SE LO PONE A UN PERSONAJE ANTES DE ARMARLO: todo es una entrada de la construcción (ver BoneInstantiator), así que
## va antes del `add_child`. La semilla no: es del que arma, que sabe de qué arquetipo es.
func dress(bi: BoneInstantiator) -> void:
	bi.skin = skin


## LO GUARDADO DE ANTES que ya no existe se acepta y se ignora, para que los aspectos guardados sigan cargando: lo que
## se llevaba puesto y la cara (sacados el 13/11/2026).
func _set(property: StringName, _value: Variant) -> bool:
	return property in [&"face_wear", &"eye_wear", &"mouth_wear", &"hat", &"belt", &"suit", &"mouth", &"lips",
		&"lip_color", &"brows", &"brow_tilt", &"eye_shape", &"eye_tilt", &"crow_feet", &"forehead_lines", &"nasolabial",
		&"nose", &"hair", &"hairdo", &"beard", &"hair_color", &"bones"]
