class_name ShieldTip
extends ArmTip

## EL ESCUDO (18/11/2026, el usuario: «un brazo sea el que cubre y otro brazo no puede cubrir… si querés tener un escudo
## vas a tener un arma menos»; «hacer un escudo físico opaco y aceptar el trade-off de que va a tapar la pantalla como para
## testear la idea… la mano común con el puño común… que lo agarre con un mango»; «rectangular… un plano… agarrado como
## el centro de la cara de adentro… un mini mango… muy derechito, muy perfecto, se ve raro»). La mano común, SIEMPRE
## CERRADA agarrando un mango corto (donde cierra los dedos, MechHand.grip_on, a lo largo del eje del puño, como el palo)
## con dos pernos hasta el centro de la cara de adentro de un escudo plano rectangular, opaco.
##   · LEVANTADO (`up`, lo pone MechShield mientras está prendido): este brazo, y sólo éste, va a la guardia
##     (Stance.COVER) en `RAISE_TIME` (ver `wanted`). Frena lo que viene de frente: lo decide ToolMech.block_hit.
##   · EL ESCUDO MIRA ADELANTE con un poco del giro de la mano (`NATURAL`): no derechito. Se acomoda en cada cuadro en la
##     mano, sin ser hijo de ella (si copiara todo su giro, la guardia lo dejaba a 45°, como un rombo).
##   · NO ES UN ARMA: no pega (ToolMech no lo toma como el brazo de las piñas) y, por ahora, sólo se ve (no choca).
## La maqueta de la que salió estaba en tests/shield_held_look (commit 3cb12fb).

## El escudo: ancho y alto, grosor, y cuánto adelante del mango va su cara de adentro (m).
const SIZE := Vector2(2.0, 3.2)
const THICK := 0.1
const AHEAD := 0.35
## El mango: su largo (m) y su radio en la medida de la mano (ver MechHand.grip_on).
const HANDLE_LONG := 0.45
const HANDLE_RADIUS := 0.25
## Cuánto toma del giro de la mano (0, derecho mirando adelante; 1, como la mano).
const NATURAL := 0.3
## En cuánto se levanta o se baja (s).
const RAISE_TIME := 0.2
const PLATE_COLOR := Color(0.55, 0.57, 0.6)
const HANDLE_COLOR := Color(0.22, 0.23, 0.25)

## Si está levantado (lo pone MechShield).
var up := false
var _raise := 0.0
var _shield: Node3D = null
var _grip := Vector3.ZERO


func _build() -> void:
	arm.mount_common_hand(forearm)
	var hand := arm._hand
	hand.fist = true
	_grip = hand.grip_on(HANDLE_RADIUS)
	_shield = Node3D.new()
	_shield.name = "Escudo"
	add_child(_shield)
	# En el espacio del escudo: x a lo ancho, y hacia adelante (el grosor), z para arriba; el mango en el origen.
	var bar := Clay.limb(_shield, HANDLE_RADIUS * hand.global_basis.get_scale().x, 1.0, Vector3.ZERO, HANDLE_COLOR)
	Clay.segment(bar, Vector3(0.0, 0.0, -HANDLE_LONG * 0.5), Vector3(0.0, 0.0, HANDLE_LONG * 0.5), 1.0)
	for end: float in [-1.0, 1.0]:
		Clay.box(_shield, Vector3(0.08, AHEAD, 0.08), Vector3(0.0, AHEAD * 0.5, end * HANDLE_LONG * 0.5), HANDLE_COLOR)
	Clay.box(_shield, Vector3(SIZE.x, THICK, SIZE.y), Vector3(0.0, AHEAD + THICK * 0.5, 0.0), PLATE_COLOR)


## Siempre cerrado (agarra el mango); y levantándose o bajándose.
func step(delta: float) -> void:
	if arm._hand != null:
		arm._hand.fist = true
	_raise = move_toward(_raise, 1.0 if up else 0.0, delta / RAISE_TIME)


## LEVANTADO, EL PUÑO VA A LA GUARDIA (sólo este brazo: la de la meca, Mech.covering, mueve los dos).
func wanted(asked: Vector3) -> Vector3:
	if _raise <= 0.0:
		return asked
	return asked.lerp(arm.stance_at(MechArm.Stance.COVER), smoothstep(0.0, 1.0, _raise))


## No pega con el escudo.
func zone() -> Dictionary:
	return {}


func status() -> String:
	return "escudo arriba" if up else "escudo abajo"


func _process(_delta: float) -> void:
	_place()


## EL ESCUDO EN LA MANO: el mango donde cierra los dedos, mirando adelante con un poco del giro de la mano.
func _place() -> void:
	var hand := arm._hand if arm != null else null
	if hand == null or _shield == null or arm.anchor == null:
		return
	var axis := hand.global_basis.y.normalized()
	if axis.y < 0.0:
		axis = -axis
	var along := (hand.global_position - forearm.global_position).normalized()
	var natural := along - axis * along.dot(axis)
	var forward := -arm.anchor.global_basis.z
	forward.y = 0.0
	var normal := forward.normalized().lerp(natural.normalized(), NATURAL).normalized() \
		if natural.length() > 0.001 else forward.normalized()
	var lift := Vector3.UP.lerp(axis, NATURAL)
	lift = (lift - normal * lift.dot(normal)).normalized()
	_shield.global_transform = Transform3D(Basis(normal.cross(lift), normal, lift), hand.to_global(_grip))
