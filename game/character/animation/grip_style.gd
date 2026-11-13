class_name GripStyle
extends Resource

## ── CÓMO AGARRA LA MANO, LO QUE SE PRUEBA EN EL F1 (29/10/2026, sesión de siluetas de los personajes) ─────────────────
## Las perillas de la animación de las manos que el usuario quiere probar en vez de decidir de antemano («esto es
## el típico caso de panel F»). Las lee ArmsController; las mueve el F1 de la fila Agarre del sandbox (ver PressPanel).
## *Hasta el 13/11/2026 se podían guardar desde un panel (GripSettings); acá no había nada guardado.*
##
## UNA POR FAMILIA de lo que se agarra (el usuario: «el volante y la valve… se utilizan de forma distinta y tienen
## distintos parámetros para cambio de mano y todo eso»): la válvula lo dice con su marca (`FAMILY_META`, ver
## ValveArchetype); lo demás que gira, el volante.

const FAMILY_META := "grip_family"
const WHEEL := "volante"
const VALVE := "válvula"

static var families := _saved_families()


## Las dos familias, como acá. EL VOLANTE, SIN VOLVER A AGARRAR (30/10/2026,
## el usuario: «el volante es como el del Cybertruck, que tiene hasta cierto tope y no da vueltas… que el volante
## directamente no tenga cambio de manos, porque nunca va a pasar de ese ángulo máximo»): las manos quedan en sus puntos
## de punta a punta del recorrido.
static func _saved_families() -> Dictionary:
	return {WHEEL: _steering(), VALVE: _valve()}


## La de la válvula, de arranque: vuelve a agarrar pasados 90° (30/10/2026, el usuario: «aumentamos el rango de
## cambio de mano… el doble de lo que es ahora»; era 45°).
static func _valve() -> GripStyle:
	var out := GripStyle.new()
	out.regrip_angle = 90.0
	return out


## El del volante, de arranque: sin volver a agarrar.
static func _steering() -> GripStyle:
	var out := GripStyle.new()
	out.regrip = false
	return out

## ── VOLVER A AGARRAR (lo que gira con varios puntos) ──────────────────────────────────────────────────────────────
## Las manos quedan pegadas a su punto y giran con el aro; prendido, cuando una recorrió más de `regrip_angle` alrededor
## del centro desde donde lo tomó, suelta y toma el punto más cómodo de su lado —mano sobre mano, como se gira un timón—.
@export var regrip := true
## Cuánto gira una mano con el aro antes de volver a agarrar, en grados (se cuenta en puntos del aro, redondeado).
@export_range(10.0, 180.0, 1.0, "suffix:°") var regrip_angle := 45.0
## DESDE DÓNDE SE CUENTA (30/10/2026, el usuario: «pensá en varios paradigmas»; ver ArmsController._regrip):
##   0. DESDE SU COSTADO: la mano arranca en su costado y gira con el aro hasta el ángulo; ahí vuelve a su costado.
##   1. CENTRADO EN SU COSTADO: el mismo arco, la mitad antes y la mitad después de su costado: el brazo se aparta la
##      mitad de su lugar natural.
##   2. DESDE DONDE AGARRÓ: como el 0, desde donde la mano agarró por primera vez y no desde su costado.
@export_enum("desde su costado", "centrado en su costado", "desde donde agarró") var regrip_from := 0


## La familia de `thing`: la de su marca, o el volante si gira; "" si no es de ninguna.
static func family_of(thing: Node) -> String:
	if thing == null:
		return ""
	if thing.has_meta(FAMILY_META):
		return str(thing.get_meta(FAMILY_META))
	return WHEEL if thing is RotatingComponent else ""


## Lo que vale para `thing`: lo de su familia, o null si no tiene.
static func of(thing: Node) -> GripStyle:
	return families.get(family_of(thing)) as GripStyle
