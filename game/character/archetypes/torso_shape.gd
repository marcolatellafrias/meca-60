class_name TorsoShape
extends Resource

## LA FORMA DEL TORSO DE UN ARQUETIPO, en cuatro números y en metros.
##
## ── POR QUÉ CUATRO NÚMEROS Y NO LOOP CUTS ───────────────────────────────────────────────────────
## La malla del torso tiene treinta columnas y diecisiete anillos, y eso es a propósito: con esa densidad
## se deforma sin artefactos. Pero las siluetas que se buscan son simples, así que posicionar anillo por
## anillo es trabajo de más para decir "esta caja es más ancha arriba". Entonces no se editan anillos: se
## editan REGLAS, y los anillos salen de ellas.
##
## Esta es la primera regla y la más simple: una CAJA, con su alto, el ancho de cada tapa y su fondo. Las
## curvas y los perfiles autorados salieron de acá a propósito — se van a ir incorporando de a poco, cada
## uno como una regla más sobre esta.
##
## ── Y DE ACÁ CUELGA EL RESTO DEL CUERPO ─────────────────────────────────────────────────────────
## Los cuatro números no describen una malla: describen el TRONCO, y el resto se acomoda solo porque los
## huesos salen de los mismos tamaños (ver SkeletonSizesUtil.create):
##
##   · los BRAZOS cuelgan de las esquinas de ARRIBA   → el hueso de hombro mide `top / 2`
##   · las PIERNAS cuelgan de las esquinas de ABAJO   → el hueso de cadera mide `bottom / 2`
##   · el CUELLO y la cabeza se apoyan en la tapa de arriba → salen del alto de la cadena
##   · la CÁPSULA de física y la cámara miden lo mismo que el tronco
##
## Por eso el panel edita esto y no la malla: mover `top` mueve los hombros, y con ellos los brazos, el
## alcance de agarre y el ancho de la cápsula. Nada de eso hay que reposicionar.
##
## ⚠ SON ANCHOS ENTEROS, no medio-anchos: es lo que uno quiere leer en un panel ("la tapa de arriba mide
## 39 cm"). Quien necesita el medio lo divide, y está escrito en un solo lugar.

## Cómo se llama cada grupo de `@export`. El panel filtra por esto para darle una pestaña a cada uno (ver
## PropertyTuner `include`), así que son parte de la interfaz del recurso y no decoración del inspector.
const SIZES_GROUP := "Medidas"
const EXTRAS_GROUP := "Cuello y pies"
const SHADING_GROUP := "Sombreado"

@export_group("Medidas")

## Del nudo de la cadera al cuello, en metros. Reemplaza al knob `torso_length` (0..1) como fuente de
## verdad: el knob sigue existiendo y es el que da el DEFECTO, pero lo que manda es esto.
@export_range(0.15, 1.0, 0.01, "suffix:m") var height := 0.52

## LAS VUELTAS DE CONTROL, de abajo hacia arriba. Son pocas y tienen nombre; los dieciséis anillos de la
## malla salen de interpolar entre ellas (ver GridPart.from_controls).
##
## Sus `at` son fracciones del tramo, de la tapa de abajo (0) a la de arriba (1), y moverlos ES mover el
## loop cut. Cada una trae sus siete números, así que acá vive TODA la forma del torso: su silueta a lo
## alto, cuán redonda es cada altura, y cuánto se inclina y se arquea cada vuelta.
##
## ⚠ LA TAPA DE ARRIBA NO ES UNA VUELTA APARTE: es la tapa de la última, y la aboveda su `arch`. Lo mismo
## abajo, donde un `arch` positivo hunde la tapa hacia adentro de la pelvis — que es lo que hay que hacer
## con la entrepierna. Por eso no hay un sistema de tapas: es el mismo número.
@export var loops: Array[BodyLoop] = []

## Los nombres, en el orden de la pila. Son el vocabulario del panel y de la tabla del arquetipo: un
## nombre es lo que hace que "la cintura" sea la misma vuelta en todos los personajes.
const NAMES: Array[String] = ["cadera", "cintura", "pecho", "hombros"]

## LAS VUELTAS DE LA PIERNA, de arriba hacia abajo, y las MISMAS PARA LAS DOS. Sus `at` son fracciones del
## tramo de la pierna, de la unión con la pelvis (0) a la punta de abajo (1).
##
## ⚠ LA PRIMERA NO ESTÁ EN LA TABLA, y es a propósito: el arranque de la pierna es su HUELLA sobre la tapa
## de la pelvis —lo que la cadera le permite, ver ProceduralBodyUtil.leg_start_half— y el generador la mete
## adelante de estas. Si estuviera acá sería una perilla muerta: la malla la ignoraría.
##
## Así el reparto queda claro: la cadera decide con qué grosor ARRANCA la pierna, y estas cuatro deciden la
## forma de ahí para abajo.
@export var legs: Array[BodyLoop] = []

const LEG_NAMES: Array[String] = ["muslo", "rodilla", "pantorrilla", "tobillo"]


func _init() -> void:
	if foot_cuts.is_empty():
		foot_cuts = default_foot_cuts()


## LOS DE ARRANQUE: un talón alto, el empeine más alto, y de ahí baja hasta la punta.
static func default_foot_cuts() -> Array[FootCut]:
	return [FootCut.make(0.0, 0.06, 0.04, 0.045), FootCut.make(0.35, 0.075, 0.045, 0.05),
		FootCut.make(0.72, 0.05, 0.05, 0.05), FootCut.make(1.0, 0.035, 0.04, 0.045)] as Array[FootCut]


## ⚠ LA FORMA DEL BRAZO YA NO ESTÁ ACÁ: era su propio arquetipo (ArmShape), borrado el 07/11/2026 con el brazo de esta malla.
## Del brazo, el cuerpo se queda con lo que depende de él —cuánto mide y dónde nace, abajo— y el brazo con su
## grosor a lo largo de ese largo.

## ── TRES NÚMEROS QUE NO SON DE UNA VUELTA ──────────────────────────────────────
## Dónde CUELGAN las piernas y los brazos. Son la ESTANCIA — de cuán abierto para él el personaje está — y
## están aparte del ancho de la vuelta a propósito: una cadera ancha con las piernas juntas y una cadera
## angosta con las piernas abiertas son dos personajes distintos.
## LAS PIERNAS, EN METROS del eje del cuerpo a cada pierna, SUELTAS DE LA CADERA (lo pidió el dios del juego,
## 20/10/2026: las piernas sobresalían de los costados y achicar la cadera las juntaba). Era una fracción del medio-ancho
## de la vuelta de abajo (`leg_stance`), y una capa guardada con ella se pasa a metros al aplicarla (ver
## SkeletonSizesUtil.migrate_stance): sale igual que antes.
@export_range(0.0, 0.4, 0.005, "suffix:m") var leg_spread := 0.1
## CUÁNTO CRECE EL MUSLO HACIA ADENTRO, hacia la ingle, en metros: para achicar el hueco entre las dos piernas. Un solo
## número en vez de ancho y fondo, que era más quisquilloso (lo pidió el dios del juego, 20/10/2026): la vuelta del muslo
## se ensancha eso y se corre hacia adentro la mitad, así que el costado de afuera queda donde estaba. Sigue siendo de
## radio parejo, lados rectos y puntas redondas (ver GridPart.stadium, ProceduralBodyUtil._leg).
@export_range(0.0, 0.2, 0.005, "suffix:m") var thigh_inward := 0.0
## Y CUÁNTO CRECE HACIA ADELANTE, igual: más fondo y corrido adelante la mitad, así que atrás queda donde estaba.
@export_range(0.0, 0.2, 0.005, "suffix:m") var thigh_forward := 0.0
## ── CUÁN METIDAS EN EL TORSO CUELGAN LAS PIERNAS, en metros ─────────────────────────────────────
## Desde la punta de abajo del torso (la de su tapa abombada) hasta el nudo de la cadera, de donde cuelgan. En 0 la
## cadera está en la punta, como era; subiéndolo, las piernas entran en el torso y la columna —que va de la cadera a
## la tapa de arriba, en tres huesos iguales— se acorta pareja, sin achicar el torso que se ve. Lo pidió el dios del
## juego (18/10/2026): «enterrar más las piernas», con las vértebras del mismo tamaño.
@export_range(0.0, 0.5, 0.01, "suffix:m") var leg_sink := 0.0
@export_range(0.0, 1.2, 0.05) var arm_stance := 1.0

## Y LOS LARGOS, en metros: la pierna entera —cadera a tobillo— y el brazo entero —hombro a muñeca—. Cada
## largo se reparte entre sus huesos con la proporción del modelo, así que mover uno no desarma la cadena: la
## rodilla y el codo siguen cayendo donde corresponde. (El largo del cuello está abajo, con su grupo.)
@export_range(0.2, 2.0, 0.01, "suffix:m") var leg_length := 0.9
@export_range(0.2, 2.0, 0.01, "suffix:m") var arm_length := 0.6

## ── EL ENCAJE DEL BRAZO: TRES EJES, Y NO ES POSTURA ─────────────────────────────────────────────
## Dónde NACE la pieza del brazo en este torso. Es AUTORÍA y va en el reposo, así que reubica la pieza y no
## deforma nada — es para que el brazo entre bien en un torso que puede ser ancho, angosto, hondo o chato, y
## con brazos de cualquier grosor.
##
## Es otra cosa que la POSTURA (`PoseShape.shoulders_forward` y `shoulders_drop`), que es pose: esa sí
## deforma el torso y la puede animar la marcha. Una ubica la pieza, la otra mueve al personaje.
##
##   · el eje X es `arm_stance`, acá arriba: cuán AFUERA, en fracción del medio-ancho de los hombros
##   · el eje Y es `arm_drop`: cuán ABAJO del tope del tronco, en metros
##   · el eje Z es `arm_push`: cuán AL FRENTE (negativo, atrás), en metros
##
## ⚠ EL BRAZO ARRANCA ADENTRO DEL PECHO unos centímetros para que la costura no se vea (ver
## ProceduralBodyUtil.ARM_INSET). Empujándolo de más, la cúpula del hombro asoma por la cara del torso.
@export_range(-0.3, 0.5, 0.01, "suffix:m") var arm_drop := 0.0
@export_range(-0.25, 0.25, 0.01, "suffix:m") var arm_push := 0.0
## LOS PARCHES DE LA RODILLA EN ESTE CUERPO (20/10/2026, lo pidió el dios del juego): su ancho y su alto, en metros. Su
## redondez es del traje (ver SuitStyle.knee_roundness).
@export_range(0.02, 0.3, 0.005, "suffix:m") var knee_width := 0.09
@export_range(0.02, 0.3, 0.005, "suffix:m") var knee_height := 0.10

## Dónde cae cada una, en fracción del tramo. Las de las puntas son las puntas (ver BodyLoop.limb_ordered): el muslo,
## el último anillo antes de la cúpula de la cadera, y el tobillo.
const LEG_AT: Array[float] = [0.0, 0.5, 0.75, 1.0]


@export_group("Cuello y pies")

## ── LAS PARTES QUE NO SON TORSO NI MIEMBROS ─────────────────────────────────────────────────────
## El cuello, la cabeza y los pies: tres piezas chicas que antes salían enteras de los radios del arquetipo
## y no se podían tocar. Van juntas porque se afinan juntas —son lo que hace que un personaje se lea como
## una proporción y no como un torso con cosas colgando— y porque ninguna es una pila de vueltas.
##
## Están en METROS y no en parámetros de radio: lo que se lee en un panel es "el cuello mide 12 cm de
## ancho", y el generador las usa tal cual, sin pasarlas por ninguna curva.

## ── EL LARGO DEL CUELLO QUE SE VE, en metros, Y ES UNA SOLA PERILLA ─────────────────────────────
## Es el largo del hueso: nace en la punta del pecho y mide esto, así que la cabeza sube con él.
##
## ⚠ ERAN DOS —este largo y un `neck_sink` de pose que decía cuánto se comía el torso— y se disolvieron en
## una. Mientras el hundimiento era un CORRIMIENTO del hueso para adentro del pecho, las dos decían cosas
## distintas: una el largo del hueso y la otra cuánto de él quedaba tapado. Cuando el hundimiento pasó a
## acortar el hueso (que es lo que hace legible el esqueleto, ver CustomBonesUtil), lo único que salía de
## las dos era su PRODUCTO — dos sliders para mover un número, en dos pestañas distintas.
##
## El defecto sigue siendo la mitad del cuello del modelo (ver SkeletonSizesUtil.NECK_SHARE): la proporción
## de dibujito que este juego usa, y lo que el `neck_sink` por defecto daba.
##
## EL RANGO (20/10/2026, lo pidió el dios del juego): hasta 0,6 m era ridículo, ahora hasta 0,2; y PUEDE SER NEGATIVO,
## porque en cero todavía se ve cuello: el hueso además se alarga hasta el atlas de la cabeza (ver
## SkeletonSizesUtil, `head_drop`), así que un largo negativo se come ese tramo y la cabeza se hunde. El hueso nunca
## queda más corto que `SkeletonSizesUtil.NECK_MIN`.
@export_range(-0.1, 0.2, 0.005, "suffix:m") var neck_length := 0.05

## Ancho del cuello, en metros. Es cuadrado: el mismo de frente que de costado.
@export_range(0.03, 0.4, 0.01, "suffix:m") var neck_width := 0.12

## ESCALA DE LA CABEZA, como múltiplo de lo que mide la forma de cabeza que este cuerpo usa (ver HeadForm). Es por
## ARQUETIPO a propósito: una cabeza es un catálogo compartido —la misma le queda al gordo y al pibe— y lo
## que cambia por cuerpo es cuánto ocupa. 1,3 en un chico es la proporción de dibujito.
@export_range(0.4, 2.5, 0.05, "suffix:×") var head_scale := 1.0
## ── LA ESCALA HORNEADA DE LO QUE NO ES DE ESTA FORMA (22/10/2026, lo pidió el dios del juego) ─────────────────────────
## Aplicar una escala (ver MeasuresPanel, TorsoShapes.baked_layer) multiplica los metros de esta forma —lo del arquetipo
## solo— y ESTO: lo que el cuerpo saca del código (las proporciones del arquetipo sobre el modelo) o de lo compartido con
## otros (la forma de cabeza, el brazo de su ranura), que no se puede multiplicar sin tocar a los demás. El armado escala
## eso y deja los metros de la forma como están (ver SkeletonSizesUtil.create). No se muestra en el F1: es la mitad de una
## escala ya aplicada.
@export var skeleton_scale := 1.0

## ── EL PIE DE CAJA (22/10/2026, lo pidió el dios del juego; ver ProceduralBodyUtil._box_foot) ────────────────────────
## Una caja acostada del talón a la punta, con la suela en el piso: `foot_length` es su largo total y `foot_heel` cuánto
## sale el talón por detrás del eje del tobillo, en metros; `foot_cuts` sus loop cuts, del talón a la punta (ver FootCut).
## (El pie de disco del estilo de antes, con `foot_height` y `toe`, se fue con el high poly.)
@export_range(0.05, 0.6, 0.005, "suffix:m") var foot_length := 0.26
@export_range(0.0, 0.3, 0.005, "suffix:m") var foot_heel := 0.06
@export var foot_cuts: Array[FootCut] = []
## CUÁNTO SE METE LA PIERNA EN EL PIE, en el low poly: en 0 termina al ras del pie, arriba (a la altura de la caja en el
## tobillo); en 1 llega hasta el piso. Como `leg_sink` con el muslo en el torso.
@export_range(0.0, 1.0, 0.01) var leg_into_foot := 0.5
## LA CAÑA DEL ZAPATO: cuántos tramos de la pierna, desde su punta de abajo —metida en el pie—, van del color del zapato
## (lo pidió el dios del juego, 20/10/2026: era un tubo aparte que tapaba la pierna; ver ProceduralBodyUtil._leg).
@export_range(0, 8, 1) var shoe_rings := 3
## DÓNDE ESTÁN LA RODILLA Y EL CODO: cuánto del largo de la pierna (o del brazo) pasa del hueso de arriba al de abajo,
## en fracción de ese largo: + la articulación más abajo (el muslo más largo, la pantorrilla más corta), − más arriba. En 0,
## la proporción del modelo. Mueve el HUESO, y la franja que se deforma —la roja del panel— va con él: lo pidió el dios del
## juego (20/10/2026), que quería correr la franja; correrla sola dejaba el doblez despegado del nudo, que es lo que gira.
## Ver SkeletonSizesUtil, `_split`.
@export_range(-0.2, 0.2, 0.01) var knee_shift := 0.0
@export_range(-0.2, 0.2, 0.01) var elbow_shift := 0.0
## QUÉ TAN ALTA ES LA FRANJA QUE SE DEFORMA en la rodilla y en el codo (la roja del panel): cuánto de cada lado del nudo
## se mezclan los pesos de los dos huesos, en fracción del hueso más corto del nudo. Chica, el doblez es un quiebre; grande,
## una curva larga. Lo pidió el dios del juego (20/10/2026) para el doblez que busca. Era fija (ProceduralBodyUtil.JOINT_BAND).
@export_range(0.02, 0.5, 0.01) var knee_band := 0.30
@export_range(0.02, 0.5, 0.01) var elbow_band := 0.30


## ── LA CURVA DE LA ENTREPIERNA ──────────────────────────────────────────────────────────────────
## Cuánto SUBE la unión entre los dos muslos hacia la pelvis, en fracción de la distancia que hay entre
## ellos: en 0 la entrepierna es una sábana recta de un muslo al otro —como estaba— y subiéndolo se arquea
## hacia arriba, que es la forma de la ingle.
##
## La curva no se queda en la unión: los anillos del filete interpolan del último anillo del tronco a esta
## línea (ver GridPart.pelvis_fill), así que lo que se mueve acá se va diluyendo hacia arriba y la
## deformación llega hasta la vuelta autorada de abajo del torso, que es la próxima que manda.
##
## Es la parte de la malla que más se deforma al abrir las piernas, y por eso es un número y no una
## constante: cuánta tela tiene que haber ahí depende de cuánto se abren y de lo gordo que sea el personaje.
@export_range(0.0, 1.0, 0.05) var crotch_curve := 0.0

## ── LA TAPA DE ABAJO DEL TORSO, ABOMBADA ────────────────────────────────────────────────────────
## Desde que las piernas son piezas aparte (18/10/2026) el torso se cierra abajo con una cúpula, y esto es cuánto
## baja, en fracción del filete de la pelvis (ver SkeletonSizesUtil.pelvis_fall): en 1 la punta de la cúpula llega al
## nudo de la cadera, de donde cuelgan las piernas; en 0 la tapa es plana. `crotch_curve` quedó sin uso con la pelvis.
@export_range(0.0, 2.0, 0.05) var bottom_dome := 1.0


@export_group("Colores")

## ── LA PIEL POR PARTE (ver más abajo, en tono de la piel) ──────────────────────────────────────────────────
## El panel F1. La ROPA no está acá: su color es del traje (ver SuitStyle), así cada color existe en un
## solo lugar (18/10/2026; antes el torso, las piernas, los brazos, los pies y el cinturón tenían el suyo acá).
const COLORS_GROUP := "Colores"
## ── LA PIEL POR PARTE, EN TONO DE LA PIEL (22/10/2026, lo pidió el dios del juego) ───────────────────────────────────
## El cuello, la cabeza, las orejas y las manos: cada una un slider, cuánto más clara (+) o más oscura (−) que la piel
## del personaje (ver CharacterLook.skin), así cambiar la piel en el F4 las mueve a todas. 0, la piel misma. Eran colores
## sueltos, y le ganaban a la piel: elegirla en el F4 no hacía nada.
@export_range(-1.0, 1.0, 0.01) var neck_tone := 0.0
@export_range(-1.0, 1.0, 0.01) var head_tone := 0.0
@export_range(-1.0, 1.0, 0.01) var ears_tone := 0.0
@export_range(-1.0, 1.0, 0.01) var hands_tone := 0.0
## Los campos, en el orden del panel, con su nombre.
const TONE_FIELDS := {"hands_tone": "Manos", "neck_tone": "Cuello", "head_tone": "Cabeza", "ears_tone": "Orejas"}


## EL COLOR DE UNA PARTE: la piel, aclarada hacia el blanco o oscurecida hacia el negro lo que diga su tono.
func tone_color(field: String, skin: Color) -> Color:
	return toned(skin, float(get(field)))


static func toned(skin: Color, tone: float) -> Color:
	var t := clampf(tone, -1.0, 1.0)
	var out := skin.lerp(Color.WHITE, t) if t >= 0.0 else skin.lerp(Color.BLACK, -t)
	out.a = skin.a
	return out


## El tono que, sobre `skin`, da un color del mismo brillo que `color` (para pasar los colores sueltos de antes a tonos).
static func tone_between(skin: Color, color: Color) -> float:
	var v := skin.v
	if color.v >= v:
		return clampf((color.v - v) / maxf(1.0 - v, 0.0001), 0.0, 1.0)
	return clampf(color.v / maxf(v, 0.0001) - 1.0, -1.0, 0.0)
## EL MARRÓN DE LA ARCILLA, de claro (0) a oscuro (1): la única restricción del panel, que elige un TONO y no un color
## (lo pidió el dios del juego, 18/10/2026: «sólo el marrón del clay con distintas shades, para control fino»). Pasa por
## tres puntos, el claro, el de la arcilla de siempre y el oscuro.
const CLAY_LIGHT := Color(0.92, 0.82, 0.70)
const CLAY_MID := Color(0.72, 0.53, 0.40)
const CLAY_DARK := Color(0.28, 0.19, 0.14)


static func clay_shade(t: float) -> Color:
	var f := clampf(t, 0.0, 1.0)
	return CLAY_LIGHT.lerp(CLAY_MID, f * 2.0) if f < 0.5 else CLAY_MID.lerp(CLAY_DARK, (f - 0.5) * 2.0)


static func clay_color(t: float, saturation: float) -> Color:
	var c := clay_shade(t)
	return Color.from_hsv(c.h, clampf(c.s * maxf(saturation, 0.0), 0.0, 1.0), c.v)


@export_group("Elementos")

## ── QUÉ ELEMENTOS LLEVA PUESTOS ESTE ARQUETIPO (pestaña ELEMENTOS del F1) ──────────────────────────
## Lo pidió el dios del juego (18/10/2026) para mirar el cuerpo sin lo de encima: apagados, el traje sigue pintando
## el cuerpo pero no lleva sus detalles (botones, dispositivo, costuras, calcomanías), y el cinturón no se arma.
const ELEMENTS_GROUP := "Elementos"
@export var show_suit_details := true
@export var show_belt := true
## EL PUÑO DE LA MANGA ES DEL PERSONAJE (22/10/2026, lo pidió el dios del juego): si lo lleva, y su alto en metros. Termina
## siempre donde termina la manga y crece hacia el hombro; en 0, el de siempre. Su
## espesor y su color son del traje (ver SuitStyle).
@export var show_sleeve_cuff := true
## LAS MANGAS ARREMANGADAS SON DEL PERSONAJE (22/10/2026, lo pidió el dios del juego: no del traje). En el low poly la
## manga termina en el loop cut del antebrazo de su brazo, así que moverlo arremanga más o menos; sin arremangar, cerca
## de la muñeca, como siempre (ver ProceduralBodyUtil._arm).
@export var rolled_sleeves := false
@export_range(0.0, 0.2, 0.002, "suffix:m") var sleeve_cuff_height := 0.0
## ── DÓNDE VA EL CINTURÓN EN ESTE CUERPO (ver GridPart.draw_band) ─────────────────────────────────
## Su medio, en fracción del alto del torso desde la vuelta de abajo; su alto y su espesor, en metros. Lo pidió el dios
## del juego (18/10/2026): subirlo, bajarlo y engrosarlo por arquetipo. Las bolsitas no cambian: cuelgan de su borde de
## arriba. El defecto es el cinturón de siempre (ver SkeletonSizesUtil.create).
@export_range(-0.2, 1.0, 0.01) var belt_at := 0.14
@export_range(0.01, 0.4, 0.005, "suffix:m") var belt_width := 0.06
@export_range(0.0, 0.08, 0.001, "suffix:m") var belt_thickness := 0.012
## ── EL CIERRE Y SUS BOTONES EN ESTE CUERPO (20/10/2026) ───────────────────────────────────────────
## Lo pidió el dios del juego: dónde termina la franja del cierre y dónde van los botones dependen del CUERPO, no del
## traje —el traje sólo dice cuántos botones (ver SuitStyle.button_count)—. El cierre, desde el cuello en fracción de su
## largo (1 entero, hasta la punta de la tapa de abajo). Los botones de arriba NO dependen del cierre (lo pidió después):
## van entre dos alturas del torso, en fracción de su alto como el cinturón (0 la vuelta de abajo, 1 la de arriba), y
## nunca bajan del cinturón. Y UNO MÁS ABAJO DEL CINTURÓN, a `low_button_at` del tramo que queda entre el borde de abajo
## del cinturón (0) y la vuelta de abajo del torso (1).
@export_range(0.05, 1.0, 0.01) var closure_length := 0.57
@export_range(0.0, 1.0, 0.01) var buttons_top := 0.85
@export_range(0.0, 1.0, 0.01) var buttons_bottom := 0.32
@export_range(0.0, 1.0, 0.01) var low_button_at := 0.5
## LA COSTURA DEL COSTADO, la que da toda la vuelta (ver Suits.COVERALL_SEAMS, `side`): cuántos grados se corre de 90°,
## + hacia atrás y − hacia adelante, en este cuerpo (lo pidió el dios del juego, 20/10/2026). Sigue pasando por las dos
## tapas; el canesú de atrás la sigue.
@export_range(-60.0, 60.0, 1.0, "suffix:°") var side_seam_shift := 0.0
## ── EL DISPOSITIVO DE COMUNICACIÓN DEL PECHO EN ESTE CUERPO (20/10/2026, en lugar del bolsillo) ──────────────────
## Lo pidió el dios del juego: por ahora un cubo, para el blockout. Su medio, en fracción del alto del torso y del
## medio-ancho (+ hacia la derecha del que lo lleva), y su tamaño: del cuerpo, porque dónde cae y cuánto ocupa
## depende del pecho. Ver ProceduralBodyUtil._comm_device.
## (Su altura puede pasar de 1: arriba de la vuelta de arriba sigue por la tapa.)
@export_range(0.0, 1.4, 0.01) var comm_at := 0.78
@export_range(-1.0, 1.0, 0.01) var comm_across := 0.5
## Su TAMAÑO, uno solo (lo pidió el dios del juego): el alto de la caja, en metros; el ancho y el fondo siguen la proporción
## del modelo (ver CommDevice.HALF).
@export_range(0.02, 0.3, 0.005, "suffix:m") var comm_size := 0.086
## EL TAMAÑO DE LA TARJETA DEL NOMBRE en este cuerpo (lo pidió el dios del juego, 20/10/2026): cuánto se agranda o se
## achica entera —placa, franja, broche y letras— sobre las medidas del traje (ver SuitStyle.card_*).
@export_range(0.4, 2.5, 0.05, "suffix:×") var card_scale := 1.0
## Y SU LUGAR, propio (lo pidió el dios del juego): su medio en fracción del alto del torso y del medio-ancho (+ hacia
## la derecha del que lo lleva). De entrada, el del dispositivo de comunicación espejado.
@export_range(0.0, 1.4, 0.01) var card_at := 0.78
@export_range(-1.0, 1.0, 0.01) var card_across := -0.5


@export_group("Sombreado")

## ── CÓMO SE SOMBREA CADA PARTE: SUAVE ENTERA, O PARTIDA POR ÁNGULO ──────────────────────────────
## Apagado es el **auto smooth** de Blender: las normales se parten donde dos caras se encuentran a más de
## 35°, así que una caja tiene sus aristas y una superficie curva se ve suave (ver GridPart.SMOOTH_ANGLE).
## Prendido es el **smooth** entero: ninguna arista se parte y cada punto emite una sola normal.
##
## Es por PARTE porque la elección es de la pieza y no del personaje: una cabeza o un brazo se quieren leer
## redondos a cualquier densidad, y un pie o un torso de caja quieren su arista marcada. Y es una por
## MALLA, no una por volumen: el tronco lleva el torso y las dos piernas en una sola malla. (El brazo y la
## cabeza eligen la suya en su propio arquetipo, ver CharacterLook.head_form; el brazo era ArmShape, borrado.)
##
## El defecto es el auto smooth, que es como se veía el cuerpo antes de que esto se pudiera elegir.
## ⚠ SIN USO DESDE EL 18/10/2026: el cuerpo es suave entero siempre (lo pidió el dios del juego); quedan por lo guardado.
@export var smooth_trunk := false
@export var smooth_feet := false
@export var smooth_neck := false


## LA TABLA DE PIERNA QUE NO OPINA: todas las vueltas del tamaño del arranque, o sea una pierna de sección
## constante. Es el defecto del que parte un arquetipo — el afinado lo pone el que edita el panel.
##
## ⚠ Y DERECHA NO ES UN ATAJO: el arquetipo NO DICE NADA del afinado de la pierna. Sus dos radios de pierna
## —muslo y pantorrilla— salen de la misma fórmula con la misma entrada, así que cualquier proporción entre
## ellos es 1. El 15% de campana que la pierna tenía salía de comparar el radio U de uno con el L del otro,
## que son ejes distintos. Lo que sí varía por arquetipo es el ARRANQUE, porque sale de la cadera.
static func straight_legs(start: Vector2, roundness: float) -> Array[BodyLoop]:
	var out: Array[BodyLoop] = []
	for i in LEG_NAMES.size():
		out.append(BodyLoop.make(LEG_AT[i], start.x * 2.0, start.y * 2.0, roundness))
	return out


## LA FORMA DE SIEMPRE: una caja que se afina de la cadera a los hombros, con las dos vueltas del medio
## justo sobre esa línea — o sea, sin forma propia todavía. Es el defecto del que parte un arquetipo, y es
## exactamente lo que el torso era cuando tenía cuatro números.
static func straight(new_height: float, top: float, bottom: float, depth: float) -> TorsoShape:
	var out := TorsoShape.new()
	out.height = new_height
	out.loops = [] as Array[BodyLoop]
	for i in NAMES.size():
		var f: float = float(i) / float(NAMES.size() - 1)
		var loop := BodyLoop.make(f, lerpf(bottom, top, f), depth, BodyLoop.ROUND)
		out.loops.append(loop)
	return out


## LA CAJA EXACTA, para quien quiera pedirla. Ya no es con lo que nace una vuelta: las cuatro pilas nacen
## en la redondez MÁXIMA (ver BodyLoop.ROUND), y la forma se consigue bajando esquinas desde ahí.
const BOX := 0.0


## La vuelta que se llama así, o null. El panel y las reglas hablan por nombre, nunca por índice.
func loop_named(what: String) -> BodyLoop:
	var at := NAMES.find(what)
	if at < 0 or at >= loops.size():
		return null
	return loops[at]


## El ancho de una vuelta con nombre, en metros. Cero si no está.
func width_of(what: String) -> float:
	var loop := loop_named(what)
	return loop.width if loop != null else 0.0


## El nombre de la vuelta de más arriba y la de más abajo: de ellas cuelgan los brazos y las piernas.
const TOP := "hombros"
const BOTTOM := "cadera"


func copy() -> TorsoShape:
	var out := TorsoShape.new()
	out.height = height
	out.loops = [] as Array[BodyLoop]
	for loop in loops:
		out.loops.append(loop.copy())
	out.legs = [] as Array[BodyLoop]
	for loop in legs:
		out.legs.append(loop.copy())
	out.leg_spread = leg_spread
	out.thigh_inward = thigh_inward
	out.thigh_forward = thigh_forward
	out.leg_sink = leg_sink
	out.arm_stance = arm_stance
	out.smooth_trunk = smooth_trunk
	out.smooth_feet = smooth_feet
	out.smooth_neck = smooth_neck
	out.neck_length = neck_length
	out.leg_length = leg_length
	out.arm_length = arm_length
	out.arm_drop = arm_drop
	out.arm_push = arm_push
	out.neck_width = neck_width
	out.head_scale = head_scale
	out.skeleton_scale = skeleton_scale
	out.foot_length = foot_length
	out.foot_heel = foot_heel
	out.leg_into_foot = leg_into_foot
	out.foot_cuts = [] as Array[FootCut]
	for cut in foot_cuts:
		out.foot_cuts.append(cut.copy())
	out.shoe_rings = shoe_rings
	out.knee_shift = knee_shift
	out.elbow_shift = elbow_shift
	out.knee_band = knee_band
	out.elbow_band = elbow_band
	out.crotch_curve = crotch_curve
	out.bottom_dome = bottom_dome
	out.show_suit_details = show_suit_details
	out.closure_length = closure_length
	out.buttons_top = buttons_top
	out.buttons_bottom = buttons_bottom
	out.low_button_at = low_button_at
	out.side_seam_shift = side_seam_shift
	out.comm_at = comm_at
	out.comm_across = comm_across
	out.comm_size = comm_size
	out.card_scale = card_scale
	out.knee_width = knee_width
	out.knee_height = knee_height
	out.card_at = card_at
	out.card_across = card_across
	out.show_belt = show_belt
	out.show_sleeve_cuff = show_sleeve_cuff
	out.sleeve_cuff_height = sleeve_cuff_height
	out.rolled_sleeves = rolled_sleeves
	out.belt_at = belt_at
	out.belt_width = belt_width
	out.belt_thickness = belt_thickness
	for field: String in TONE_FIELDS:
		out.set(field, get(field))
	return out


## LA FORMA QUE ESTÁ `f` DEL CAMINO ENTRE ÉSTA Y `other`: lo que lleva un personaje que mezcla dos arquetipos (ver
## SkeletonSizesUtil.create). Las vueltas con nombre se mezclan de a pares (ver BodyLoop.blend) —una vuelta que una
## sola de las dos tiene queda como en ésta—, los números en línea recta y los sí o no, los de la más cercana.
func blended(other: TorsoShape, f: float) -> TorsoShape:
	var out := copy()
	for i in mini(loops.size(), other.loops.size()):
		out.loops[i] = loops[i].blend(other.loops[i], f)
	for i in mini(legs.size(), other.legs.size()):
		out.legs[i] = legs[i].blend(other.legs[i], f)
	for i in mini(foot_cuts.size(), other.foot_cuts.size()):
		out.foot_cuts[i] = foot_cuts[i].blend(other.foot_cuts[i], f)
	for field: String in ["height", "leg_spread", "thigh_inward", "thigh_forward", "leg_sink", "arm_stance", "neck_length", "leg_length", "arm_length", "arm_drop",
			"arm_push", "neck_width", "head_scale", "skeleton_scale", "foot_length", "foot_heel", "leg_into_foot", "sleeve_cuff_height", "belt_at", "belt_width", "belt_thickness",
			"crotch_curve", "bottom_dome", "knee_shift", "elbow_shift", "knee_band", "elbow_band", "closure_length", "buttons_top", "buttons_bottom", "low_button_at", "side_seam_shift", "comm_at", "comm_across", "card_scale", "knee_width", "knee_height", "card_at", "card_across",
			"comm_size"]:
		out.set(field, lerpf(float(get(field)), float(other.get(field)), f))
	if f >= 0.5:
		out.show_suit_details = other.show_suit_details
		out.show_belt = other.show_belt
		out.show_sleeve_cuff = other.show_sleeve_cuff
		out.rolled_sleeves = other.rolled_sleeves
		for field: String in TONE_FIELDS:
			out.set(field, other.get(field))
		out.smooth_trunk = other.smooth_trunk
		out.smooth_feet = other.smooth_feet
		out.smooth_neck = other.smooth_neck
	return out


## Para el cartel del panel y para el portapapeles.
func describe() -> String:
	return "alto %.3f · arriba %.3f · abajo %.3f m" % [height, width_of(TOP), width_of(BOTTOM)]
