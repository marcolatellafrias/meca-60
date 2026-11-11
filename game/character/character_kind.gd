class_name CharacterKind
extends RefCounted

## ── QUÉ CLASE DE PERSONAJE ES (03/11/2026) ─────────────────────────────────────────────────────────────────────────
## Un solo personaje para todo —el jugador, el compañero que llega por red, el tripulante de exhibición, la figura quieta
## del sandbox y el ente que lo recorre—, y estas seis respuestas dicen en qué se diferencian. Se le pone a
## `BoneInstantiator.kind` ANTES de agregarlo al árbol, casi siempre con uno de los presets de abajo, y el cuerpo físico
## lee el mismo objeto. Lo pidió el dios del juego: «hay muchas inconsistencias entre ente, dummy, jugador, etc., quiero
## simplificar todos estos sistemas en uno solo, una api con flags». Reemplaza a `is_active`, `is_puppet`, `is_display` y
## `looks_around`. Lo que hace (mirar, moverse, agarrar, sentarse) no está acá: es la intención (ver CharacterIntent).

## QUIÉN LO MANEJA: el teclado y el mouse de esta máquina, la red (lo que hace su dueño en la suya), un guion (ver
## ExhibitOperator) o nadie.
enum Driver { KEYBOARD, NETWORK, SCRIPT, NONE }
## QUÉ SE VE DE ÉL desde afuera de su propia cámara: entero o nada. La primera persona del jugador la decide su cámara
## (ver PlayerController.is_first_person_view), no esto.
enum Shown { WHOLE, NONE }
## CUÁNDO USA LAS MANOS: siempre, sólo sentado (el ente, que maneja los controles de una consola) o nunca.
enum Hands { ALWAYS, SEATED_ONLY, NEVER }
## SU FÍSICA: simulada (la cápsula, los golpes, el ragdoll), puesta por quien lo maneja (la red, el guion: la cápsula va
## donde le dicen) o volando libre.
enum Physics { SIMULATED, FOLLOWS_DRIVER, FREE_FLIGHT }
## CÓMO SE MUEVE cuando se simula: con aceleración, inercia y golpes, o directo —la velocidad que pide, al instante—, que
## es lo cómodo para recorrer y probar (el ente).
enum Motion { PHYSICAL, DIRECT }

var driver := Driver.NONE
var shown := Shown.WHOLE
var hands := Hands.ALWAYS
var physics := Physics.FOLLOWS_DRIVER
var motion := Motion.PHYSICAL
## Si detecta solo su propia caída. Un compañero de red no: su caída llega por red (pero tiene ragdoll, ver
## `has_ragdoll`). Sentado no se cae nunca, sea lo que sea.
var can_fall := false
## Si se lo choca aunque no se simule: el peatón en su camino (ver `pedestrian`).
var touchable := false


static func _make(driver_: Driver, shown_: Shown, hands_: Hands, physics_: Physics, motion_: Motion,
		can_fall_: bool) -> CharacterKind:
	var kind := CharacterKind.new()
	kind.driver = driver_
	kind.shown = shown_
	kind.hands = hands_
	kind.physics = physics_
	kind.motion = motion_
	kind.can_fall = can_fall_
	return kind


## EL JUGADOR de esta máquina.
static func player() -> CharacterKind:
	return _make(Driver.KEYBOARD, Shown.WHOLE, Hands.ALWAYS, Physics.SIMULATED, Motion.PHYSICAL, true)


## UN COMPAÑERO que llega por red: lo pone su dueño.
static func proxy() -> CharacterKind:
	return _make(Driver.NETWORK, Shown.WHOLE, Hands.ALWAYS, Physics.FOLLOWS_DRIVER, Motion.PHYSICAL, false)


## UN TRIPULANTE DE EXHIBICIÓN: lo maneja un guion, no choca ni se agarra, y parado a bordo se puede caer.
static func exhibition() -> CharacterKind:
	return _make(Driver.SCRIPT, Shown.WHOLE, Hands.ALWAYS, Physics.FOLLOWS_DRIVER, Motion.PHYSICAL, true)


## UNA FIGURA del sandbox o de una captura: quieta, para mirarla. Las manos, si quien la arma le pone algo en la
## intención (un paquete entre varios, un control que se aprieta en una captura).
static func figure() -> CharacterKind:
	return _make(Driver.NONE, Shown.WHOLE, Hands.ALWAYS, Physics.FOLLOWS_DRIVER, Motion.PHYSICAL, false)


## UNO DE LA CALLE: simulado como el jugador —se lo choca, se lo agarra, se cae—, pero sin nadie que lo maneje. Es lo que
## nace si nadie elige otra cosa.
static func npc() -> CharacterKind:
	return _make(Driver.NONE, Shown.WHOLE, Hands.ALWAYS, Physics.SIMULATED, Motion.PHYSICAL, true)


## UN PEATÓN EN SU CAMINO (05/11/2026, el dios del juego: «que sigan caminos como los autos, y la física sólo cuando
## algo los saca»): su cápsula la pone su camino (ver Pedestrian), KINEMÁTICA y en la capa 1 como la de un compañero de
## red —se lo choca—, y la cabeza mira hacia donde va. Todavía no se cae: el golpe que lo saca del camino viene después.
static func pedestrian() -> CharacterKind:
	var kind := _make(Driver.SCRIPT, Shown.WHOLE, Hands.ALWAYS, Physics.FOLLOWS_DRIVER, Motion.PHYSICAL, false)
	kind.touchable = true
	return kind


## EL ENTE que recorre el sandbox: el teclado, sin cuerpo a la vista, manos sólo sentado, movimiento directo y sin caerse.
## `flying`, volando libre.
static func ente(flying := false) -> CharacterKind:
	return _make(Driver.KEYBOARD, Shown.NONE, Hands.SEATED_ONLY,
		Physics.FREE_FLIGHT if flying else Physics.SIMULATED, Motion.DIRECT, false)


## ¿Es el jugador de esta máquina?
func is_local() -> bool:
	return driver == Driver.KEYBOARD


## ¿Su cápsula la mueve la física (y no quien lo maneja)?
func simulates() -> bool:
	return physics != Physics.FOLLOWS_DRIVER


## ¿Mira con la cabeza? Todo el que tiene quien lo maneje: la intención trae adónde.
func looks() -> bool:
	return driver != Driver.NONE


## ¿Lleva ragdoll? El que se cae solo, y el compañero de red, al que se lo prende la red.
func has_ragdoll() -> bool:
	return can_fall or driver == Driver.NETWORK


## ¿Lo tocan los demás? Se lo choca, lo apunta el rayo de interacción y se lo agarra: el que se simula, el compañero de
## red y el peatón en su camino (`touchable`). El de exhibición y la figura, no: se los mira y se los atraviesa.
func is_touchable() -> bool:
	return simulates() or driver == Driver.NETWORK or touchable


## ¿Es de exhibición —una figura, un tripulante—? Lo pone quien lo maneja sin red, y no se lo toca (el peatón en su camino
## sí se toca: no es de exhibición).
func is_exhibit() -> bool:
	return not simulates() and driver != Driver.NETWORK and not touchable


## ¿Usa las manos ahora, `seated` o no?
func uses_hands(seated: bool) -> bool:
	return hands == Hands.ALWAYS or (hands == Hands.SEATED_ONLY and seated)
