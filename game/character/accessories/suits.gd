class_name Suits
extends RefCounted

## LOS TRAJES: una categoría aparte del cuerpo, para que cualquiera los vista —así un peatón reusa los mismos cuerpos
## que los pasajeros—. Pedidos por el dios del juego el 10/10/2026, y vueltos a definir de cero el 18/10/2026:
##
##   · EL MAMELUCO DE LA SUCURSAL: de una pieza, el mismo para las tres empresas (el dios del juego unificó los tres
##     diseños). `employee(empresa)`.
##   · ATENDEDOR DE NEGOCIO: camisa clara arremangada, y pantalón.
##   · PEATÓN: traje oscuro.
##
## (LO QUE EL TRAJE LE DIBUJABA AL CUERPO —las costuras, las bandas, los parches, los botones, el cuello, la tarjeta y el
## dispositivo del pecho— se borró el 07/11/2026 con la malla vieja del personaje; vive en la etiqueta de git
## `malla-personaje-archivada`. Quedan los trajes como datos: sus nombres, sus colores del código —que lee SuitStyles—,
## la manga y el cinturón que llevan.)

const NAMES: Array[String] = ["mameluco de la sucursal", "atendedor de negocio", "peatón", "mameluco low poly"]
## EL MAMELUCO, UNO PARA LAS TRES EMPRESAS (20/10/2026, lo pidió el dios del juego): eran tres copias del mismo, una por
## empresa, y había que mantenerlas; quedó la de Fletes Lamborra, que era donde se venía modificando (su estilo guardado
## sigue en el mismo número). Los colores de cada empresa vendrán como variaciones de éste, cuando el de arcilla esté.
## `employee(empresa)` y `COMPANY_COUNT` quedan para entonces.
const EMPLOYEE := 0
const COMPANY_COUNT := 1
const SHOPKEEPER := 1
const PEDESTRIAN := 2
## EL MAMELUCO LOW POLY (21/10/2026, lo pidió el dios del juego para el low poly): el mismo
## mameluco, con los detalles de menos geometría (dibujados por la malla vieja, borrada el 07/11/2026).
const COVERALL_LOW_POLY := 3

## LOS BOTONES DEL MAMELUCO: cuántos lleva de entrada (ver SuitStyle.button_count).
const COVERALL_BUTTONS := {"count": 5, "size": 0.018, "across": 0.02, "thickness": 0.006}

## ── EL CINTURÓN DEL TRAJE (20/10/2026) ───────────────────────────────────────────────────────────────────────
## Lo pidió el dios del juego: los mamelucos de las compañías lo llevan SIEMPRE. El cinturón sigue siendo una pieza
## aparte (ver Belts), que otro traje puede reusar; el traje sólo dice cuál (`belt_piece` en DEFS; `belt` es su color). Un traje que nombra
## uno lo pone en cualquier personaje que lo vista, gane lo que gane el look (ver BoneInstantiator); sin traje, o con
## uno que no nombra, vale el del personaje.
static func belt_for(index: int, chosen: int) -> int:
	if valid(index) and (DEFS[index] as Dictionary).has("belt_piece"):
		return int(DEFS[index]["belt_piece"])
	return chosen


## ── CADA TRAJE ──────────────────────────────────────────────────────────────────────────────────
## Sus colores del código (ver SuitStyles.code: tonos del marrón de la arcilla, ver TorsoShape.clay_shade), la manga y
## el espesor de su puño.
const COVERALL := {"cloth": Color(0.55, 0.43, 0.34), "trousers": Color(0.55, 0.43, 0.34), "shoes": Color(0.26, 0.18, 0.13),
	"seam": Color(0.38, 0.27, 0.20), "patch": Color(0.72, 0.56, 0.44), "belt": Color(0.28, 0.19, 0.14),
	"button": Color(0.30, 0.21, 0.16), "sleeve": Sleeve.LONG,
	"buttons": COVERALL_BUTTONS, "belt_piece": 0}
## El low poly: el mameluco con su cinturón low poly (ver Belts).
const COVERALL_LOW := {"cloth": Color(0.55, 0.43, 0.34), "trousers": Color(0.55, 0.43, 0.34),
	"shoes": Color(0.26, 0.18, 0.13), "seam": Color(0.38, 0.27, 0.20), "patch": Color(0.72, 0.56, 0.44),
	"belt": Color(0.28, 0.19, 0.14), "button": Color(0.30, 0.21, 0.16), "sleeve": Sleeve.LONG,
	"buttons": COVERALL_BUTTONS, "belt_piece": 1,
	"copy_of": EMPLOYEE, "style_overrides": {"buckle_color": Color(0.70, 0.71, 0.72), "card_thickness": 0.0,
		# EL DISPOSITIVO: grises de metal, sin el rojo (lo pidió el dios del juego: sutil, pero que se lea metálico por
		# sus colores; en marrones se veía casi negro).
		"comm_color": Color(0.52, 0.53, 0.55), "comm_metal_color": Color(0.70, 0.71, 0.73),
		"comm_dark_color": Color(0.30, 0.31, 0.33)}}

## ── LAS MANGAS ──────────────────────────────────────────────────────────────────────────────────
## Qué manga lleva un traje: LARGA, tela hasta la muñeca, con un puño; REMANGADA, hasta abajo del codo, con el rollo.
## *Hasta el 07/11/2026 vivía en ArmShape, el brazo de la malla archivada, que se borró.*
enum Sleeve {LONG, ROLLED}


const DEFS := [
	COVERALL,
	{"cloth": Color(0.90, 0.80, 0.68), "trousers": Color(0.50, 0.36, 0.27), "shoes": Color(0.36, 0.25, 0.18),
		"seam": Color(0.70, 0.55, 0.43), "belt": Color(0.30, 0.20, 0.15), "sleeve": Sleeve.ROLLED,
		"sleeve_cuff": 0.016},
	{"cloth": Color(0.36, 0.25, 0.19), "trousers": Color(0.33, 0.23, 0.17), "shoes": Color(0.26, 0.18, 0.13),
		"seam": Color(0.26, 0.18, 0.13), "belt": Color(0.26, 0.18, 0.13), "sleeve": Sleeve.LONG},
	COVERALL_LOW,
]


## EL MAMELUCO DE UNA EMPRESA, por su número en Employee.COMPANIES.
static func employee(company: int) -> int:
	return EMPLOYEE + clampi(company, 0, COMPANY_COUNT - 1)


static func valid(index: int) -> bool:
	return index >= 0 and index < DEFS.size()

