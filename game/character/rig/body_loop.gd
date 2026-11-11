class_name BodyLoop
extends Resource

## UN LOOP CUT: una vuelta cerrada de la grilla del cuerpo, y los ocho números que la definen por completo.
##
## Es la unidad de autoría de todo el personaje. Una parte es una PILA de estos (ver GridPart): los que el
## arquetipo escribe a mano son unos pocos y tienen nombre —cadera, cintura, pecho, hombros, tapa— y los
## del medio salen de interpolar los siete números entre ellos. Así la tabla autorada queda corta y
## legible, la malla queda densa, y mezclar dos arquetipos es mezclar números.
##
## ── LOS TRES ÚLTIMOS SON LA NOVEDAD: UNA VUELTA NO ES PLANA ──────────────────────────────────────
## `width`, `depth` y `roundness` dicen la forma EN SU PLANO. `tilt_x`, `tilt_z`, `arch_x` y `arch_z` dicen
## su ALTURA punto por punto, y son lo que convierte una caja subdividida en algo orgánico sin agregar un
## solo concepto: una vuelta puede inclinarse y puede arquearse, cada cosa en los dos ejes.
##
## Y EL MISMO ARQUEO ABOVEDA UNA TAPA. No hace falta otro sistema para eso, y es la razón de que la altura
## viva acá y no en un campo aparte: la tapa es la misma vuelta evaluada hacia adentro, así que en el centro
## el arqueo levanta todo lo que suma, en el medio de cada cara lo que diga el del otro eje, y en las
## esquinas nada. Una tapa plana
## es un arqueo en 0, igual que una caja es `roundness = 0`.
##
## ⚠ `at` lo INTERPRETA LA PARTE: en la tabla autorada es una fracción 0..1 del tramo, y lo que recibe
## `GridPart` ya viene en METROS sobre la cadena de huesos. La conversión pasa en un solo lugar, cuando el
## perfil autorado se remuestrea.

## Dónde cae esta vuelta a lo largo del tramo. Mover esto ES mover el loop cut.
@export_range(-0.5, 1.5, 0.05) var at := 0.0

## Su tamaño, en metros y de lado a lado (no medio-ancho: es lo que uno quiere leer en un panel).
@export_range(0.01, 1.2, 0.01, "suffix:m") var width := 0.30
@export_range(0.01, 1.2, 0.01, "suffix:m") var depth := 0.20

## ── CUÁNTO MÁS REDONDO ES EL FRENTE QUE EL FONDO ────────────────────────────────────
## Sumado a `roundness` y solo en el frente: en 0 las cuatro esquinas se muerden igual, en negativo las DOS
## DE ADELANTE se achatan y en positivo se redondean. Entre medio —los costados— pasa de una a la otra, así
## que la sección sigue siendo una curva continua y no una con dos mitades pegadas.
##
## Para qué: la cara de un Mii. La cabeza es cilíndrica, pero el frente —donde van los rasgos— tiende a ser
## PLANO, y eso es lo que hace que un ojo o una boca no se deformen al apoyarse. Con un solo número de
## redondez hay que elegir entre una cabeza redonda con los rasgos estirados o una cuadrada.
##
## ⚠ ES UNA DIFERENCIA Y NO UNA SEGUNDA REDONDEZ ABSOLUTA, y es por lo guardado: lo que un panel guarda es la
## diferencia contra el defecto del código (ver ShapeLayer), así que un campo nuevo que vuelve con el defecto
## DE CLASE le cambiaría la forma a todo lo ya autorado — una vuelta guardada con redondez 1 habría quedado
## redonda atrás y cuadrada adelante sin que nadie lo pidiera. En 0 no cambia nada de nada.
@export_range(-1.0, 1.0, 0.05) var roundness_front := 0.0

## ── SI ESTA VUELTA MANDA ────────────────────────────────────────────────────────────
## Apagada, el anillo sigue existiendo —el conteo de malla es de plantilla y no se toca— pero su forma sale
## de INTERPOLAR entre las vueltas que sí mandan. O sea: se la conserva con sus números para cuando haga
## falta, y mientras tanto no hay que hacerla coincidir con nadie.
##
## Para qué: una forma simple no necesita que las cinco vueltas digan lo mismo, y hacerlas coincidir a mano
## es trabajo que no agrega nada. Apagando las del medio, la pila se comporta como si tuviera solo las puntas
## y las que uno dejó prendidas.
##
## ⚠ LAS PUNTAS NO SE PUEDEN APAGAR: son las TAPAS de la pila, y sin ellas no hay entre qué interpolar. El
## filtro las conserva siempre (ver GridPart._active) y el panel no les muestra la perilla.
@export var active := true

## ── SU FORMA EN EL PLANO: CUÁNTO SE LE MUERDE A LA ESQUINA ──────────────────────────
## De 0 —la caja exacta— a 1 —la elipse—, y lo que mide es cuánto se tira la esquina de la sección hacia el
## centro: 0,5 se la come a mitad de camino de lo que se la come una elipse. La superelipse de la que sale
## la sección se calcula de acá (ver `exponent`).
##
## ⚠ SE GUARDA ASÍ Y NO COMO EL EXPONENTE `n`, y es un arreglo y no un gusto: el exponente NO ES PERCEPTUAL,
## y eso rompía las dos cosas que un número de autoría tiene que poder hacer.
##
##   · ARRASTRARLO. Medido en el torso del generic: de n=64 a n=16 la esquina se mueve 7 mm, de 16 a 8 otros
##     8, y de 4 a 2 cuarenta. Con el exponente en el slider, el 80% del recorrido no hacía nada visible y
##     todo pasaba en el último tramo — el síntoma era "muevo la redondez de los hombros y no pasa nada".
##   · INTERPOLARLO. Interpolar el exponente entre dos vueltas NO interpola la forma: con la vuelta de
##     arriba en elipse y la de abajo en caja, el último anillo se mordía 57 mm y el siguiente 8. Eso es un
##     escalón, no una transición, y es lo contrario de lo que una pila de vueltas interpoladas existe para
##     dar. En mordisco, interpolar es lineal en lo que se ve.
##
## También es con qué dureza cae el arqueo, así que una sección de caja da una bóveda chata y una redonda
## una cúpula suave.
@export_range(0.0, 1.0, 0.05) var roundness := 0.3

## CUÁNTO SE INCLINA, en metros: la altura que gana el borde +X (o +Z) y pierde el opuesto. Un plano de
## alturas sobre la vuelta — hombros que caen, cadera basculada.
@export_range(-0.25, 0.25, 0.01, "suffix:m") var tilt_x := 0.0
@export_range(-0.25, 0.25, 0.01, "suffix:m") var tilt_z := 0.0

## ── CUÁNTO SE CORRE LA VUELTA PARA ADELANTE, en metros (negativo, para atrás) ───────────────────
## La vuelta entera, sin cambiar de forma: lo mismo que el corrimiento de un loop cut de cabeza (ver HeadCut.forward).
## Lo pidió el dios del juego (18/10/2026) para darle curva a un miembro de perfil —la pantorrilla atrás, la rodilla
## adelante— sin inclinar vueltas: un cilindro con sus loop cuts corridos. En 0 no cambia nada.
@export_range(-0.1, 0.1, 0.002, "suffix:m") var forward := 0.0
## ── Y PARA EL COSTADO, en metros: + hacia AFUERA del cuerpo, − hacia adentro ──────────────────────────────────────
## Lo mismo que `forward`, de costado (lo pidió el dios del juego, 20/10/2026, para las piernas y los brazos). Es una
## tabla para los dos lados, así que va espejada: quien arma un miembro lo pasa al costado de ESE lado (ver
## ProceduralBodyUtil._leg). En el torso no se muestra: lo correría entero para un lado.
@export_range(-0.1, 0.1, 0.002, "suffix:m") var sideways := 0.0
## ── CUÁNTO MÁS ARRIBA ESTÁN LOS COSTADOS que el frente y la espalda (− más abajo) ─────────────────────────────────
## Lo pidió el dios del juego (20/10/2026) para la vuelta de la cadera —una cadera que sube a los costados, como el
## borde de un calzón—, y vale para cualquier vuelta del torso. No es el arqueo (`arch_x`, `arch_z`), que curva la
## TAPA: esto mueve el BORDE, gradual alrededor —todo en el medio de cada costado, nada en el medio del frente y de la
## espalda— y gradual a lo largo, porque se interpola con las vueltas vecinas como cualquier otro número. Adentro de una
## tapa va bajando hacia el centro, que no se mueve. Ver GridPart._lift.
## EN FRACCIÓN DE LO QUE HAY HASTA LA VUELTA VECINA hacia ese lado —la de arriba si suben, la de abajo si bajan; si no
## hay, la del otro lado—: en 1 los costados llegan a ella. Era en metros, y no escalaba con el cuerpo: afinado con la
## lupa ×3, a ×1 la cadera se rompía (lo vio el dios del juego). Quien arma el torso lo pasa a metros, `sides_lift`.
@export_range(-1.0, 1.0, 0.01) var sides_rise := 0.0
## Lo mismo en metros, para la malla: lo pone quien arma (ver ProceduralBodyUtil._sides_in_metres). No se guarda.
var sides_lift := 0.0

## CUÁNTO SE ARQUEA, en metros: lo que sube el CENTRO, y las esquinas no se mueven. En una vuelta del
## costado arquea la vuelta; en una tapa, la aboveda.
##
## SON DOS, y es para tener la forma y no solo la cantidad: `arch_x` es el arco A LO ANCHO —la curva que se
## ve de frente— y `arch_z` el arco A LO HONDO, la que se ve de costado. Cada uno es una parábola en su eje
## y se SUMAN: con uno solo sale una bóveda de cañón, que sube en un eje y es recta en el otro; con los dos
## iguales, la cúpula de siempre — el centro sube la suma, y el medio de cada cara sube el del otro eje.
@export_range(-0.3, 0.3, 0.01, "suffix:m") var arch_x := 0.0
@export_range(-0.3, 0.3, 0.01, "suffix:m") var arch_z := 0.0

## ── Y CÓMO SUBE: PARÁBOLA O CÚPULA ─────────────────────────────────────────
## Los dos llegan a lo mismo en el centro y a cero en el borde; lo que cambia es el CAMINO.
##
##   · apagado — PARÁBOLA, `1 − u²`: sube parejo, con la misma curvatura en todo el tramo. Es una almohada.
##   · prendido — CÚPULA, `√(1 − u²)`, un arco de elipse: sube DE GOLPE en los dos bordes y se aplana arriba.
##
## La cúpula no es solo "más llena": llega al canto VERTICAL, o sea continuando la pared, así que la tapa y
## el costado se juntan sin arista. La parábola llega en diagonal y deja un quiebre suave.
##
## ⚠ LO QUE PIDE A CAMBIO ES RESOLUCIÓN. Toda la subida de la cúpula pasa en la primera celda contra el
## borde — con la tapa en 15 celdas, la primera columna ya está a la mitad de la altura total, contra un
## cuarto con la parábola. Con pocas celdas eso se lee facetado justo en el canto.
##
## El perfil NO se interpola entre vueltas —es un sí o un no—: una vuelta del medio toma el de la vuelta de
## control más cercana (ver `blend`).
@export var arch_dome := false

## ── ESTA VUELTA ESTÁ ADENTRO DE UNA BANDA DE MEZCLA ──────────────────────────
## `true` si CAE ADENTRO de la banda de una articulación, sea porque la articulación la puso ahí o porque
## alguien autoró una forma justo ahí (ver GridPart.limb_column). Lo pone el generador y no se guarda: no
## es un `@export` justamente para que no aparezca como una perilla en el panel ni se escriba en el `.tres`.
##
## Para qué: el panel pinta esas vueltas de otro color, así se ve de un vistazo qué parte de la malla está
## ahí para deformar y qué parte para dar forma. Y por eso es la BANDA y no el motivo: lo que se quiere ver
## pintado es la zona que deforma, de punta a punta y sin huecos en el medio.
var at_joint := false

## ── DE QUÉ COLOR SALE ESTE TRAMO ────────────────────────────────────────────────────────────────
## Las caras que van de esta vuelta a la siguiente se pintan de este color (ver GridPart, que corta los vértices
## donde dos caras vecinas difieren, para que el borde sea filoso). Es como una manga se pinta de tela y la mano
## de piel sobre la MISMA malla. Lo pone el generador y no se guarda, igual que `at_joint`: blanco quiere decir
## "el color del material", que es lo que tienen todas las partes que no se pintan.
var color := Color.WHITE


## ── LA REDONDEZ CON LA QUE NACE TODA VUELTA AUTORADA: LA MÁXIMA ─────────────────────
## La elipse. Es el defecto de las cuatro pilas —torso, pierna, brazo y cabeza— y por lo tanto también lo
## que el botón ⟲ de cada fila devuelve mientras nadie haya guardado otra cosa.
##
## Es una decisión de autoría y no un valor neutro: un cuerpo nace redondo y la forma se consigue BAJANDO
## esquinas, que es al revés de como estaba (nacía en caja y había que redondear las cuatro pilas a mano).
## Partir de lo redondo también es partir de lo que no tiene aristas vivas, así que lo primero que se ve es
## la silueta y no el facetado.
const ROUND := 1.0


## LO QUE LOS MIEMBROS Y EL TORSO YA NO USAN (lo pidió el dios del juego, 18/10/2026): las inclinaciones y la
## redondez del frente, en cero aunque estén guardadas; y en los miembros, `cylinder`, la redondez entera y el fondo
## igual al ancho — son cilindros, y su forma es el diámetro, la altura y el corrimiento de cada loop cut.
func plain(cylinder := false) -> void:
	tilt_x = 0.0
	tilt_z = 0.0
	roundness_front = 0.0
	if cylinder:
		roundness = ROUND
		depth = width


static func make(new_at: float, new_width: float, new_depth: float,
		new_roundness: float) -> BodyLoop:
	var out := BodyLoop.new()
	out.at = new_at
	out.width = new_width
	out.depth = new_depth
	out.roundness = new_roundness
	return out


## LOS METROS DE LA VUELTA, por `factor`: sus medidas, inclinaciones, arqueos y corrimientos. Las fracciones —el `at`, la
## redondez, `sides_rise`— no. Es la única lista: la lupa del sandbox la usa en el torso, las piernas y los brazos (ver
## SkeletonSizesUtil._scale_shape), y una medida nueva que falte acá se rompe al cambiar de tamaño.
func scale_metres(factor: float) -> void:
	width *= factor
	depth *= factor
	tilt_x *= factor
	tilt_z *= factor
	arch_x *= factor
	arch_z *= factor
	forward *= factor
	sideways *= factor


func copy() -> BodyLoop:
	var out := BodyLoop.new()
	out.at = at
	out.width = width
	out.depth = depth
	out.roundness_inner = roundness_inner
	out.inner_u = inner_u
	out.roundness = roundness
	out.roundness_front = roundness_front
	out.active = active
	out.tilt_x = tilt_x
	out.tilt_z = tilt_z
	out.forward = forward
	out.sideways = sideways
	out.sides_rise = sides_rise
	out.sides_lift = sides_lift
	out.arch_x = arch_x
	out.arch_z = arch_z
	out.arch_dome = arch_dome
	out.at_joint = at_joint
	out.color = color
	return out


## LA COMBINACIÓN PESADA DE CUATRO VUELTAS, un peso por vuelta. Es lo que llena los anillos que nadie
## autoró: los pesos salen del spline que pasa por las vueltas autoradas (ver GridPart._spline_weights), y
## son cuatro porque una curva suave en un tramo necesita saber qué hay del otro lado de sus dos puntas.
##
## ⚠ LOS TAMAÑOS SE CLAMPEAN y las interpolaciones lineales no lo necesitaban: una curva suave que pasa por
## todos los puntos SE PASA un poco entre dos de ellos —es lo que la hace suave—, y pasarse para abajo de
## cero daría una vuelta dada vuelta. El tope de abajo es un milímetro, el mismo que el panel.
static func mixed(loops: Array[BodyLoop], w: PackedFloat32Array) -> BodyLoop:
	var out := BodyLoop.new()
	# ⚠ EN CERO ANTES DE ACUMULAR: una vuelta nueva NO nace en cero —nace con los defectos del panel,
	# 30 cm de ancho y 20 de fondo— y sumarle encima los pesos le regalaba esos valores a cada anillo. Se
	# vio feo y claro: el torso medía 67 cm de ancho en vez de 37, exactamente 30 de más.
	out.at = 0.0
	out.width = 0.0
	out.depth = 0.0
	out.roundness = 0.0
	out.roundness_front = 0.0
	out.tilt_x = 0.0
	out.tilt_z = 0.0
	out.forward = 0.0
	out.sideways = 0.0
	out.sides_lift = 0.0
	out.arch_x = 0.0
	out.arch_z = 0.0
	for i in 4:
		var l: BodyLoop = loops[i]
		var f: float = w[i]
		out.at += l.at * f
		out.width += l.width * f
		out.depth += l.depth * f
		out.roundness += l.roundness * f
		out.roundness_front += l.roundness_front * f
		out.tilt_x += l.tilt_x * f
		out.tilt_z += l.tilt_z * f
		out.forward += l.forward * f
		out.sideways += l.sideways * f
		out.sides_lift += l.sides_lift * f
		out.arch_x += l.arch_x * f
		out.arch_z += l.arch_z * f
	out.width = maxf(out.width, 0.001)
	out.depth = maxf(out.depth, 0.001)
	out.roundness = clampf(out.roundness, 0.0, 1.0)
	# Los dos discretos salen de la vuelta de control MÁS CERCANA, que es la de más peso de las dos del
	# medio: un perfil de domo no se puede promediar a medias.
	var near: BodyLoop = loops[1] if w[1] >= w[2] else loops[2]
	out.arch_dome = near.arch_dome
	out.at_joint = near.at_joint
	out.active = near.active
	out.color = near.color
	return out


## La vuelta que está `f` del camino entre esta y `other`, en línea recta. Es lo que mezcla dos
## arquetipos; los anillos del medio de una pila usan `mixed`, que además sale suave.
func blend(other: BodyLoop, f: float) -> BodyLoop:
	var out := BodyLoop.new()
	out.at = lerpf(at, other.at, f)
	out.width = lerpf(width, other.width, f)
	out.depth = lerpf(depth, other.depth, f)
	out.roundness = lerpf(roundness, other.roundness, f)
	out.roundness_front = lerpf(roundness_front, other.roundness_front, f)
	out.tilt_x = lerpf(tilt_x, other.tilt_x, f)
	out.tilt_z = lerpf(tilt_z, other.tilt_z, f)
	out.forward = lerpf(forward, other.forward, f)
	out.sideways = lerpf(sideways, other.sideways, f)
	out.sides_lift = lerpf(sides_lift, other.sides_lift, f)
	out.arch_x = lerpf(arch_x, other.arch_x, f)
	out.arch_z = lerpf(arch_z, other.arch_z, f)
	# El perfil es un sí o un no: se queda el de la vuelta más cercana. Lo mismo el "manda", aunque a esta
	# altura ya no decide nada: el filtro corre antes de interpolar (ver GridPart._active).
	out.arch_dome = other.arch_dome if f >= 0.5 else arch_dome
	out.at_joint = other.at_joint if f >= 0.5 else at_joint
	out.active = other.active if f >= 0.5 else active
	return out


## LA REDONDEZ QUE VALE EN ESE PUNTO DE LA SECCIÓN, donde `v` es −1 en el frente y +1 en el fondo (el mismo
## `v` que GridPart.section_point). Es el frente y el fondo mezclándose a lo largo de los costados.
##
## Vive acá y no en el generador porque la consultan dos: la malla del cuerpo y el paño de la cara. Con dos
## fórmulas, el paño se separa de la cabeza en cuanto una de las dos cambie — y el que lo nota es el que ve
## un rasgo flotando.
func roundness_at(v: float) -> float:
	var front: float = (1.0 - clampf(v, -1.0, 1.0)) * 0.5
	return clampf(roundness + roundness_front * front, 0.0, 1.0)


## ── Y LA DE ADENTRO, DE COSTADO (22/10/2026, el antebrazo del low poly) ────────────────────────────────────────────────
## Cuánto más redondos son los dos lados que dan hacia el cuerpo, sumado (`roundness_inner`), y de qué lado de `u` está
## el cuerpo (`inner_u`, +1 o −1; 0: ninguno). No se guardan: los pone quien arma (ver ProceduralBodyUtil._forearm_loops).
var roundness_inner := 0.0
var inner_u := 0.0


## La redondez en el punto `(u, v)` de la sección: la de `roundness_at`, más la de adentro hacia el lado del cuerpo.
func roundness_at_uv(u: float, v: float) -> float:
	if inner_u == 0.0 or roundness_inner == 0.0:
		return roundness_at(v)
	var inside: float = clampf((u * inner_u + 1.0) * 0.5, 0.0, 1.0)
	return clampf(roundness_at(v) + roundness_inner * inside, 0.0, 1.0)


## ── EL GROSOR: UN SOLO NÚMERO PARA EL ANCHO Y EL FONDO ──────────────────────────────────────────
## Propiedad VIRTUAL —no se guarda— que al leerse da el ancho y al escribirse escribe el ancho Y el fondo.
##
## Para qué: hay pilas que no necesitan una sección ovalada. En una pierna, dos números para un muslo son
## uno de más: lo que uno quiere decir es "más gorda", y tener que hacer coincidir ancho con fondo en cuatro
## vueltas es trabajo que no agrega nada. El panel le muestra el grosor a la pierna y ancho y fondo a las
## demás (ver TorsoTuner).
##
## ⚠ NO SE GUARDA, Y ES LO QUE LO HACE SEGURO: el dato siguen siendo `width` y `depth`. Una pierna autorada
## con grosor se puede abrir mañana con los dos números y no se perdió nada, y lo guardado no depende de qué
## perillas muestra el panel hoy. Por eso la usage no lleva `STORAGE` (ver ShapeLayer, que filtra por eso).
##
## SU RANGO es el de un miembro, no el de un torso (20/10/2026, lo pidió el dios del juego: hasta 1,2 m era ridículo):
## de 2 a 40 cm, con pasos de medio centímetro. La pierna más gruesa guardada, la del gordo, mide 27.
func _get_property_list() -> Array[Dictionary]:
	return [{
		"name": "thickness",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.02,0.4,0.005,suffix:m",
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_EDITOR,
	}] as Array[Dictionary]


func _get(property: StringName) -> Variant:
	return width if property == &"thickness" else null


func _set(property: StringName, value: Variant) -> bool:
	if property != &"thickness":
		return false
	width = float(value)
	depth = float(value)
	return true


## Medio-ancho y medio-fondo, que es lo que la geometría necesita.
func half() -> Vector2:
	return Vector2(width * 0.5, depth * 0.5)


## Si esta vuelta colapsó a un PUNTO: el polo de una cúpula. Sus quads degeneran en triángulos y su tapa
## no se dibuja.
func is_point() -> bool:
	return width < 1e-5 and depth < 1e-5


func describe() -> String:
	var out := "en %.3f · %.3f × %.3f m · redondez %.2f" % [at, width, depth, roundness]
	if not (is_zero_approx(tilt_x) and is_zero_approx(tilt_z)):
		out += " · inclinada (%.3f, %.3f)" % [tilt_x, tilt_z]
	if not is_zero_approx(arch_x) or not is_zero_approx(arch_z):
		out += " · arqueada %.3f × %.3f%s" % [arch_x, arch_z, " en cúpula" if arch_dome else ""]
	return out
