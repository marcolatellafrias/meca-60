class_name SkeletonSizesUtil

## CUÁNTO MÁS GRANDE ES ESTE PERSONAJE, como múltiplo de lo que pide su arquetipo. 1 = tal cual.
##
## ── POR QUÉ ACÁ Y NO UNA ESCALA DE NODO ────────────────────────────────────────────────────────
## Escalar el nodo del personaje NO funciona, y se midió: el torso y la cabeza escalan 3× exactos pero las
## piernas no —la IK planta los pies en coordenadas del mundo a alturas que no escalan, así que el
## personaje se hunde—. Y escalar solo el nodo del CUERPO da el muñeco de Michelin: las mallas crecen
## alrededor de poses de hueso que siguen en 1×, así que cada parte queda como un globo.
##
## Acá no hay nada que compensar. TODO lo que mide el personaje sale de este objeto —los largos de hueso,
## la cadera, el alcance del pie, la altura de pelvis, la altura del paso, los targets de reposo de la IK—
## y la marcha se deriva por frame de `foot_reach` (ver `_update_gait`), así que multiplicar esto una vez
## agranda el personaje ENTERO con sus mecanismos: pasos más largos, pelvis más alta, cápsula más grande.
## Lo único que hay que acompañar son las constantes en METROS de quien consume esto (hoy: las costuras de
## `ProceduralBodyUtil`), y para eso está este campo — el resto son fracciones y escalan solas.
##
## ⚠ LA LUPA DEL SANDBOX LO USA HOY (ver CharacterArchetype.MAGNIFY) y la ESCALA DE CUERPO del arquetipo lo
## va a usar después. Es la misma palanca; la diferencia que viene es que la escala de cuerpo NO se lleva
## la cabeza (el efecto "cuerpo grande, cabeza chica"), así que ese día `_scale_to` toma dos factores.
var size_scale : float = 1.0
## QUÉ ARQUETIPO ES este cuerpo (ver EntityArchetype.Archetype), −1 si no se sabe. Lo pregunta lo que se elige por cuerpo
## al armar la malla: los rasgos extra que lleva (ver FaceFeatures.for_body).
var archetype : int = -1

var leg_height : float
var torso_height : float
var head_height : float
var hips_width : float
## CUÁNTO BAJA LA BASE DE LA COLUMNA por debajo del nudo de la cadera del tronco, en metros: es el alto del
## filete de la pelvis (ver ProceduralBodyUtil.PELVIS_DROP).
##
## ── Y ESTO ES LO QUE HACE QUE LA PIERNA SE ESTIRE LO QUE EL ARQUETIPO PIDE ──────────────────────
## El `lower_spine` se COME este tramo: nace ahí abajo y mide su parte del torso más esto, así que su base
## —de donde cuelgan las caderas— cae justo donde la malla arranca las piernas, y el hueso de la cadera sale
## HORIZONTAL (su largo es la estancia, sin hipotenusa).
##
## Antes el pivote de la pelvis estaba en el nudo de la cadera y la cadera se giraba hacia abajo para llegar
## al filete. Medido: el muslo nacía 5,8 cm bajo el pivote, así que la pierna solo podía estirarse al 93,6%
## cuando el arquetipo pedía 99,5% — con `leg_bentness = 0` la rodilla daba 41,7° en vez de 12°, y el slider
## de flexión movía al personaje de altura en vez de doblarle la rodilla.
var pelvis_fall : float
## CUÁNTO BAJA LA TAPA ABOMBADA DE ABAJO DEL TORSO, desde su vuelta de abajo (ver TorsoShape.bottom_dome). La cadera
## está `leg_sink` arriba de su punta, así que `pelvis_fall` —de la cadera a la vuelta de abajo— es esto menos eso, y
## puede ser negativo: la vuelta de abajo, por debajo de la cadera.
var bottom_drop : float
## ── EL ENCAJE DEL BRAZO, en metros: cuánto baja y cuánto se adelanta el nacimiento del brazo respecto del
## tope del tronco (ver TorsoShape, que explica los tres ejes). Son OFFSETS y no giros, así que el hombro
## sigue horizontal y su largo es la envergadura pedida; y van en el REPOSO, así que reubican la pieza del
## brazo y no deforman el torso — eso lo hace la POSTURA, que es pose.
var arm_sink : float
var arm_push : float
## CUÁNTO DEL CUELLO DEL MODELO SE VE, como fracción, y es el DEFECTO del largo del cuello — no una perilla
## (ver TorsoShape.neck_length, que es la perilla y cuenta la historia). La mitad: el modelo trae un cuello
## anatómico y este juego usa la proporción de dibujito, la cabeza apoyada sobre los hombros. Un cuello
## corto es una proporción, no un error de medida.
const NECK_SHARE := 0.5
## CUÁNTO SE ARQUEA LA TAPA DE ARRIBA sobre el último anillo del torso (ver TorsoShape). NO alarga el hueso
## del pecho: el cuello nace en el tope de la malla y se mete para adentro, así que el domo y la cabeza
## ocupan el mismo tramo y lo que vale para el alto total es el que sobresalga más.
var torso_dome : float
var shoulders_width : float
## Largo de la cadena del brazo (hombro→muñeca) en metros. Reemplaza a `EntityArchetype.reach`, que
## ya no existe: el largo del brazo sale del rango del modelo, no de un número autorado.
var arm_reach : float
## Hasta dónde llega a agarrar, en metros: `arm_reach × arm_stretch × 0.97`. Reemplaza a
## `reach × reach_multiplier` con la misma división de responsabilidades — largo del brazo y cuánto
## estira son DOS variables de arquetipo independientes. Ver "The arm reach problem" en el doc.
var interaction_reach : float
## Cuánto estira el brazo este personaje al agarrar, en múltiplos de su reposo. Sale del arquetipo,
## ya clampeado al rango que se esculpió en Blender.
var arm_stretch : float
## Altura total del personaje, en metros. Es un RESULTADO (pierna + torso + cabeza), no una entrada.
var total_height : float

## LA FORMA DEL TORSO de este personaje, en metros y ya escalada (ver TorsoShape). De los cuatro números
## salen el alto de la cadena, el hueso de hombro —o sea dónde cuelgan los brazos— y el de cadera —o sea
## dónde cuelgan las piernas y cuán separados quedan los pies—.
##
## Es una COPIA: lo guardado es un recurso compartido y acá se lo escala por `size_scale`.
var torso_shape: TorsoShape = null

## Y LA MISMA FORMA SIN LO QUE EL PANEL GUARDÓ: la que el arquetipo describe por sí solo. Es la BASE sobre la
## que se aplica la capa guardada (ver ShapeLayer), y el panel la necesita para dos cosas que de otro lado no
## salen: mostrar el defecto y calcular qué hay que guardar —la diferencia contra esto—.
var torso_default: TorsoShape = null

## Y LA FORMA DE LA CABEZA de este personaje, en metros y ya escalada (ver HeadForm): una de las formas de cabeza (ver
## HeadForms), la que su arquetipo canónico tiene elegida (ver CharacterLook.head_form) salvo que el que lo arma fuerce
## otra.
##
## De acá sale el largo del hueso de la cabeza —su alto entero, los dos domos incluidos—, así que la altura total y la
## cápsula la siguen.
var head_form: HeadForm = null
## ── LA FORMA DE BLOQUES (31/10/2026, ver BlockShape) ──────────────────────────────────────────────────────────────
## La que dio los huesos, con la malla archivada; null con el sistema viejo. Sus números son metros sin lupa: los del
## personaje son esos por `block_unit` (la lupa, ver `size_scale`).
var block_shape: BlockShape = null
var block_unit := 1.0
## La muñeca de la mano de tubos, en metros (ver TubeHand.REFERENCE_WIDTH).
var hand_width := 0.1

## QUÉ MANGA LLEVA (ver Suits.Sleeve). La va a decidir el traje; hasta que haya trajes es la larga, y el
## sandbox la cambia para mostrar las dos (ver BoneInstantiator.sleeve).
var sleeve: int = Suits.Sleeve.LONG

## QUÉ LLEVA ENCIMA: un sombrero (ver Hats) y un cinturón (ver Belts), o -1 para nada. Los cosméticos de persona son
## del empleado y se compran (ver people.md); hasta que ese circuito exista nadie lleva nada en el juego, y el sandbox
## los fuerza para mostrarlos (ver BoneInstantiator.hat).
var hat: int = -1
var belt: int = -1
## Y LO QUE LLEVA EN LA CARA (ver FaceWear), o -1: la pipa, el cigarrillo, los lentes.
var face_wear := PackedInt32Array()
## EL TRAJE (ver Suits), o -1: el cuerpo como sale, en crema con las mangas de tela.
var suit: int = -1
## LA POSE DE LA BOCA (ver FaceLayout.MOUTHS), −1 la plana, y LOS LABIOS: más de 0, con labios (ver
## BoneInstantiator.mouth).
var mouth: int = -1
var lips: float = -1.0
var lip_color := FaceLayout.LIP_COLOR
## LA PIEL (ver CharacterLook.skin); transparente es el crema de siempre.
var skin := Color(0, 0, 0, 0)
## LAS CEJAS Y LA BARBA (ver FaceHair), −1 nada, y el color del pelo.
var brows: int = -1
var brow_tilt := 0.0
## Los ojos y las arrugas de cada uno (ver FaceLayout.features, `look`), y la nariz (ver Noses).
var face_look := {}
var nose: int = -1
## EL PEINADO (ver Hair), −1 pelado.
var hair: int = -1
var beard: int = -1
var hair_color := FaceHair.DEFAULT_COLOR

var head_size: Vector3
## CUÁNTO BAJA TODO LO DE LA CABEZA en el marco de su hueso, por el atlas de su forma (ver HeadForm.atlas), en metros: lo
## que el cuello se alargó.
var head_drop := 0.0
## ── DÓNDE NACE EL CUELLO: EN LA SUPERFICIE DE LA TAPA DE ARRIBA ─────────────────────────────────────
## Corrimiento desde la punta del pecho, en ejes del cuerpo (−Z es el frente), hasta el punto de la tapa donde la
## superficie mira hacia donde apunta el cuello (ver `neck_anchor_on`). Derecho, es la cima del domo, así que abombar
## la tapa sube la cabeza sola; encorvado, el punto baja por la curva hacia adelante y lo que queda atrás se lee como
## joroba. Lo pidió el dios del juego (18/10/2026): que la tapa abombada y la joroba no choquen.
var neck_anchor := Vector3.ZERO
var neck_size: Vector3
var chest_size: Vector3
var higher_spine_size: Vector3
var lower_spine_size: Vector3
var higher_leg_size: Vector3
var lower_leg_size: Vector3
var foot_size: Vector3
var upper_arm_size: Vector3
var lower_arm_size: Vector3
var shoulder_width: Vector3
var hip_size: Vector3
var raycast_stance_offset: float

# ── MARCHA ────────────────────────────────────────────────────────────────────────────────────────
# Todo esto se deriva del knob `stride` del arquetipo. Ver technical/character-animation.md.

## Extensión máxima de la cadena de la pierna, en fracción de su largo. Es el TECHO de la IK: pasado
## esto, `BoneInstantiator._update_pelvis_drop` considera que el pie no llega y baja la pelvis.
##
## ⚠ TIENE QUE SER ≥ STAND_EXTENSION_STRAIGHT, o la pose de reposo es inalcanzable por definición.
## Estuvo en 0.95 contra un reposo de 0.99, y el efecto era el opuesto al buscado: **parado y quieto**
## el déficit daba 3.8 cm, la pelvis bajaba sola, y `root_bounciness` lo exageraba hasta 4.9 cm. O
## sea que todo lo que `leg_bentness` pidiera por encima de 0.95 se descartaba, y el arquetipo que
## pedía la pierna MÁS RECTA terminaba siendo el más flexionado, por generar el mayor déficit.
##
## Esa es la razón de que sea 0.99 y no un número "cómodo": el margen para terreno irregular ya lo da
## la caída de pelvis, que existe justo para eso. Este techo no tiene que aportar margen, tiene que
## dejar que el reposo se cumpla.
const MAX_EXTENSION := 0.995
## Extensión de la pierna PARADO, en fracción de su largo. NO es un margen de seguridad (la pelvis ya
## baja sola cuando no llega): es la GARANTÍA de que la pierna alcanza el piso estando parado. Subirlo
## hacia 1.0 endereza la pierna y acerca el reposo al modelo, a cambio de trabar antes en terreno
## irregular.
## Cuánto de su largo usa la pierna estando parada. Es lo que fija la FLEXIÓN DE RODILLA en reposo, y
## el arquetipo elige dónde cae dentro de esta banda con `leg_bentness`.
##
##   0.995 → ~12°      0.99 → 16°      0.985 → 20°      0.97 → 28°      0.95 → 37°      0.90 → ~52°
##
## La curva es MUY poco lineal cerca del tope —el último 1% de largo vale 16° de rodilla—, así que un
## paso chico acá se ve mucho. Subió de 0.99 a 0.995 porque con 16° todos los arquetipos se leían
## agachados incluso con `leg_bentness = 0`, que es el piso del knob: no había forma de enderezarlos
## desde el arquetipo. Cuesta ~4 mm de altura a cada uno y nada más.
##
## ⚠ SUBIRLO OBLIGA A SUBIR `MAX_EXTENSION` con él. Si el reposo pide más extensión de la que la IK
## permite, la pose es inalcanzable y la pelvis baja sola para compensar — y el efecto es al revés de
## lo que uno espera: cuanto MÁS derecho pide un arquetipo, más se agacha. Ya pasó una vez.
##
## ⚠ El techo NO puede acercarse a 1.0, y no es un margen de seguridad: es **la garantía de que la
## pierna llega al piso estando parada**. Con la pierna estirada al 100% el objetivo de la IK queda
## justo en el límite del alcance, cualquier irregularidad del terreno lo deja fuera, y el pie se pliega
## hacia su objetivo aéreo — el personaje flota y no da un paso. Ver technical/character-animation.md.
const STAND_EXTENSION_STRAIGHT := 0.995
const STAND_EXTENSION_BENT := 0.90

## Excursión máxima del pie desde la cadera, en fracción del largo de pierna, mapeada desde `stride`.
## Ya NO se deriva de la altura de pelvis: es al revés — se elige la zancada y la pelvis baja lo que
## haga falta (ver BoneInstantiator._update_pelvis_drop). El tope existe para que la bajada no se
## vaya de rango, no por geometría.
## EL FONDO DEL TORSO POR DEFECTO, en fracción de su ancho de arriba. Es solo el defecto: en cuanto el
## panel guarda una forma, el fondo es un número propio (ver TorsoShape.depth).
const TORSO_DEPTH_SHARE := 0.55

## HASTA DÓNDE SE AGARRA, en múltiplos del brazo ya estirado. Arriba de 1 se alcanza un poco más lejos de lo que el
## brazo da, y en el límite la mano queda a unos centímetros de lo que agarra; es lo que hace que sentado se llegue
## a los controles del tablero sin tener que pegarle la silla encima (ver StationSeat.SETBACK). Abajo de 1 la mano
## siempre toca, pero hay que estar encima de todo.
##
## ERA 1,2 Y SE SUBIÓ A 1,4, medido: sentado en la silla de estación, al NIÑO —el de menos alcance— la interacción le
## llegaba a 0,96 m del pecho, y el borde de arriba del atril, en el medio, le queda a 0,95: llegaba justo, y a las
## esquinas de un tablero ancho no llegaba. Con 1,4 llega a 1,12 (el genérico de 1,13 a 1,32). Que el brazo se estire
## de más a la vista se compensa después, con el torso; por ahora pesa más llegar.
const GRAB_REACH_FACTOR := 1.4
## ── EL ALCANCE PARA INTERACTUAR, EL MISMO PARA TODOS (04/11/2026, propuesto al dios del juego y aprobado: «la
## distancia de interacción es algo como muy fundamental… que se iguale en todos») ───────────────────────────────────
## En metros del personaje sin lupa: de él salen las tres distancias del agarre (ver InteractionController.set_reach). El
## largo del brazo queda para la vista: lo que se lleva va a la distancia de todos (LocomotionCommon.hold_reach) y los codos
## se doblan más o menos. Con 1,25 el kid sentado llega al borde de arriba del atril (le hace falta 0,95) y a las
## esquinas de un tablero ancho. *Antes, el brazo estirado por GRAB_REACH_FACTOR: de 1,12 el kid a 1,32 el genérico; lo
## sigue usando sólo el cuerpo viejo, sin forma de bloques.*
## SE REGULA EN LA F1 de los experimentos (04/11/2026, el dios del juego: «setear una variable que sea alcance máximo…
## que los elementos de más abajo haya que agacharse para alcanzarlos»): LocomotionCommon.interaction_reach, de todos.

## ── LA ZANCADA MANDA (03/11/2026, lo pidió el dios del juego) ─────────────────────────────────────────────────────
## El paso caminando mide `stride` × `STEP_LEGS` piernas (de un pie al otro), y los pasos por segundo son la
## consecuencia: velocidad / paso. SIN TECHO: un paso corto a mucha velocidad son pasitos rápidos; para calmarlos, la
## velocidad de caminar (pestaña Movimiento). Con 0,8 el genérico, con su 0,95, pisa casi lo mismo que antes.
## *Antes: el paso salía de la velocidad y una cadencia fija (1,9 pasos/s), con un techo de 4,5 pasos/s que, si el
## alcance lo pedía, alargaba el paso; todos caminaban pegados al techo y la zancada no cambiaba nada (medido: de 0 a 3,
## el mismo paso en los siete arquetipos).*
const STEP_LEGS := 0.8
## LA ZANCADA MÁS CORTA: con 0 el paso no avanza nunca y los pies se deslizan sin pisar.
const MIN_STRIDE := 0.1
## LA ZANCADA MÁS CORTA de 0 a 1 (ver EntityArchetype.stride_reach), por lo mismo: con 0 los pies se deslizarían.
const MIN_STRIDE_REACH := 0.03
## Duty factor: fracción del ciclo que el pie pasa APOYADO. Caminando >0.5 (siempre hay un pie en el
## piso, y hay doble apoyo); corriendo <0.5 (hay fase de vuelo con los dos pies en el aire).
const DUTY_WALK := 0.62
const DUTY_RUN  := 0.40

## Excursión del pie desde la cadera CAMINANDO, en metros (ver LA ZANCADA MANDA). Es una ELECCIÓN (sale de la zancada),
## no una consecuencia de la altura de pelvis: la pelvis se acomoda para que el pie llegue. La usan la altura del arco y
## el umbral del paso de quieto.
var foot_reach: float
## LA ZANCADA, DE 0 A 1 (ver EntityArchetype.stride_reach), y el largo de pierna contra el que se mide (m): lo que la
## pierna alcanza estirada.
var stride_reach := 0.5
var leg_reach := 0.0
## El ciclo entero caminando (dos pasos), en metros: lo que avanza el cuerpo mientras cada pie da su paso.
var walk_stride: float
## EXCURSIÓN del pie de este frame (A, metros): cuánto se adelanta/atrasa el pie respecto de la
## cadera. El pie pisa en +A y despega en −A, así que su recorrido en el marco del cuerpo es 2A.
var current_excursion: float
## ZANCADA de este frame (S, metros): lo que avanza el cuerpo en un ciclo completo de un pie.
## Durante el apoyo (fracción D del ciclo) el pie está fijo en el mundo, o sea que en el marco del
## cuerpo retrocede D·S; y ese recorrido tiene que ser exactamente 2A ⇒ **S = 2A/D**. De ahí sale la
## cadencia: f = v/S. No es un parámetro libre — se deriva de la geometría y del duty.
var current_stride: float
var current_duty: float
## Velocidad de este frame en fracción de la máxima (0 quieto, 1 a fondo). Es la `t` de la que salen
## el duty y la excursión; se publica para que el modelo de marcha por disparo derive de LA MISMA
## cuenta su radio, en vez de tener una segunda definición de "qué tan rápido va".
var current_speed_t: float = 0.0
## CUÁNTO SE CORRE PARA ADELANTE el lugar donde pisa, en metros, sobre lo que pide el ciclo (ver WalkStyle.lead): corre los
## dos extremos del apoyo, así que no hace patinar al pie.
var current_lead: float = 0.0
## El adelanto del estilo que no corre nada: el de siempre (ver `_update_gait`).
const LEAD_BASE := 0.25
## El hueso del cuello más corto que se arma, en metros: lo que deja un largo de cuello negativo (ver
## TorsoShape.neck_length).
const NECK_MIN := 0.005

var step_height: float
## Altura del TOBILLO sobre el piso, o sea el grosor de pie/zapato. Sale del modelo (en Blender la
## planta apoya en 0). Es lo que separa "el pie apoya" de "el tobillo toca el piso".
var ankle_height: float
## Altura de la pelvis parado, en metros sobre el piso. Sale del modelo (ReferenceRig).
var standing_pelvis_height: float
var distance_from_ground: float
var raycast_leg_length: float
var pole_distance: float
var axis_weight_lateral:  float = 0.6
var axis_weight_forward:  float = 0.8
var axis_weight_backward: float = 1.0

## ── SLOUCH: SOLO HACIA ADELANTE ───────────────────────────────────────────────────────────────────
## El encorvado es `chest` y `neck` inclinándose hacia adelante, y nada más.
##
## Antes era una **S**: `higher_spine` se arqueaba hacia ATRÁS (+0.6 rad) y `chest`/`neck` hacia
## adelante (−0.6), así que los hombros quedaban casi en su lugar y lo único que se veía encorvado era
## la cabeza. Mucha maquinaria para poca lectura, y difícil de tunear porque los dos términos se
## cancelaban entre sí. Ahora los grados que se piden son los grados que se ven.
##
## Los máximos bajaron al sacar el contra-arqueo: sin nada que compense, el 0.6 del pecho inclinaba el
## torso entero 34°. `chest` 0.35 (20°) + `neck` 0.45 (26°) acumulan 46° en la cabeza, que es un
## encorvado marcado sin doblar al personaje al medio.
##
## LOS DOS ARRANCAN EN CERO. El cuello tenía un piso de 0.2 rad que compensaba el reposo del modelo
## viejo; el esqueleto se re-posicionó para que **derecho sea la postura natural**, así que ese piso
## dejó de tener sentido y además ensuciaría un futuro parámetro de largo de cuello.
## EL ENCORVADO ES SOLO EL CUELLO, en radianes: `slouch` lo inclina hacia adelante y nada más.
##
## ── POR QUÉ UN SOLO HUESO ───────────────────────────────────────────────────────────────────────
## Era pecho adelante + lumbar atrás de contrapeso + cuello adelante, tres giros que se compensaban entre
## sí: el resultado dependía de los tres y afinarlo era mover tres números para ver uno. Y con el cuello
## CORTO a propósito (ver TorsoShape.neck_length), inclinarlo solo a él ya lee como hombros encogidos y
## cabeza adelantada — el encorvado entero, de dibujito, con un hueso.
var slouchiness_neck: float

## ── LA CURVA DE LA ESPALDA, en radianes, y NO es el encorvado ───────────────────────────────────
## El pecho se va para adelante y la lumbar para ATRÁS de contrapeso. Sin el contrapeso se lee desbalanceado
## —todo el cuerpo volcado, como si estuviera por caerse—: un encorvado real no es el torso rotando entero,
## es la lumbar arqueándose hacia atrás para sostener el peso del pecho que se fue adelante.
##
## Es la vieja repartición de `slouch` entre tres huesos, de vuelta pero con su propio nombre y en su propia
## variable (`EntityArchetype.spine_bend`): `slouch` quedó siendo el cuello y nada más, que es lo que da la
## postura de dibujito. Y ahora van como POSTURA DE POSE (ver CustomBone.set_local_posture), no de reposo,
## así que a diferencia de la vieja **sí deforman el torso**.
##
## Los topes son los que tenía: 0,42 rad de pecho (24°) y 0,10 de lumbar. No hace falta que la lumbar sea
## mucho porque no compite en ángulo sino en POSICIÓN — inclinarla corre el punto donde arranca el resto del
## torso, y a 0,10 son unos dos centímetros de pecho hacia atrás.
const SPINE_BEND_CHEST_MAX := 0.42
const SPINE_BEND_LOWER_MAX := 0.10
var spine_bend_chest: float
var spine_bend_lower: float

## CUÁNTO MÁS QUE EL FILETE tiene que medir la lumbar como piso (ver el reparto de la columna): un 5% de
## margen, para que el último anillo del filete le pese a ella y no a la vértebra de arriba.
const SPINE_FILLET_MARGIN := 1.05

## EL TOPE DEL ENCORVADO: **un cuarto de vuelta, literal**. A fondo el cuello queda HORIZONTAL, apuntando
## al frente, con la cabeza apoyada adelante del pecho en vez de arriba. Es la postura de dibujito a fondo.
##
## Pasó por dos versiones antes: 26° —lo que el cuello llevaba cuando el encorvado se repartía entre tres
## huesos, y como único hueso se leía como nada— y una cuenta geométrica que lo llevaba al 90% de la cara
## del pecho (59° en el genérico), que sigue siendo poco para lo que se busca. Es un número de diseño y no
## una consecuencia, así que ahora se escribe.
##
## ⚠ LA CABEZA NO HEREDA LA INCLINACIÓN, y por eso 90° no la deja mirando el piso: el reposo de cada hueso
## se escribe GLOBAL y se baja a local contra el reposo acumulado del padre (ver CustomBone.create), así que
## la cabeza se queda derecha mientras el cuello se tumba.
const NECK_SLOUCH_MAX := PI * 0.5
## CONTRAPESO: la lumbar se va para ATRÁS (pitch positivo, al revés que los otros dos).
##
## Sin esto el encorvado se lee desbalanceado, todo el cuerpo volcado hacia adelante, como si estuviera
## por caerse. Un encorvado real no es el torso rotando entero: es la lumbar arqueándose hacia atrás
## para sostener el peso del pecho que se fue adelante.
##
## No hace falta que sea mucho porque no compite con el pecho en ángulo, sino en POSICIÓN: inclinar la
## lumbar no gira nada de lo que está arriba —cada hueso tiene su reposo global propio— solo corre el
## punto donde arranca el resto del torso. A 0.10 rad son ~2 cm de pecho hacia atrás.
##
## ── POSTURA DE HOMBRO, en radianes ────────────────────────────────────────────────────────────────
## Salen de sus propios knobs de arquetipo (`shoulders_forward` / `shoulders_drop`), NO del slouch.
##
## Los dos son giros sobre ejes del MUNDO y van espejados entre lados, así que las dos articulaciones
## se mueven juntas en vez de rotar el torso: `forward` sobre la vertical, `drop` sobre el eje frontal.
##
## Los topes son chicos a propósito. Los hombros no "se cierran" mucho aunque la espalda esté vencida,
## y pasarse acá se lee como brazos cruzados y no como postura.
##
## ⚠ NO pasan por `lerp_range`, que clampea a 0..1: acá el knob es un factor CON SIGNO. Negativo es una
## postura tan válida como positiva —hombros atrás y pecho abierto, o hombros levantados— y clamparla
## a cero las perdía sin avisar.
const SHOULDER_FORWARD_MAX := 0.12
const SHOULDER_DROP_MAX := 0.10
var shoulder_forward: float
var shoulder_drop: float

var arm_openness_angle: float
var arm_bentness: float
## Hacia dónde apunta el codo, 0..1 (0 = adentro, 0.5 = atrás, 1 = afuera). Constante por ahora:
## era por arquetipo y se simplificó mientras se cierra el personaje genérico.
const ELBOW_POLE_DIRECTION := 0.7
var left_arm_tip_rest_local: Vector3
var right_arm_tip_rest_local: Vector3
var left_arm_pole_rest_local: Vector3
var right_arm_pole_rest_local: Vector3

var left_arm_shoulder_rest_local: Vector3
var right_arm_shoulder_rest_local: Vector3


var raycast_start_y_offset: float = 0.0

const CONST_HEAD_HEIGHT    := 0.378
const CONST_HEAD_RADIUS_XZ := 0.19

# ── LARGOS DE HUESO: EL MODELO DE BLENDER MANDA ───────────────────────────────────────────────────
# Todos los largos salen de rangos medidos del modelo, NO de `height` × proporciones. El arquetipo
# solo aporta un 0..1 por cadena (legs_length / arms_length / torso_length) y acá se convierte a
# metros. Consecuencia buscada: `height` deja de ser una entrada y pasa a ser un RESULTADO — ver
# `total_height`. Si un arquetipo quisiera un largo fuera del rango, gana el rango.
#
# SOLO QUEDA EL TORSO ACÁ. El brazo y la pierna ya tienen sus dos extremos autorados en Blender y
# pasan por `authored_chain`: para ellos el modelo es el 0.0 y el 1.0 es el modelo × factor.
#
# Para el torso el esquema sigue siendo provisorio: el largo esculpido es el 0.5 y los extremos son
# factores sobre él, hasta que estén modelados. El largo esculpido se LEE DEL RIG — no se transcribe.
# Antes eran constantes copiadas de un volcado, y quedaban viejas en silencio en cuanto se re-exportaba
# el modelo: el rig lógico seguía pidiendo las proporciones de la versión anterior y el espejo estiraba
# la malla para cumplirlas. Ver "The reference rig" en technical/character-body.md.
const LENGTH_MIN_FACTOR := 0.65
const LENGTH_MAX_FACTOR := 1.30

## ── BRAZO: LA BANDA DEL ARQUETIPO DENTRO DEL RANGO DE BLENDER ─────────────────────────────────────
## El brazo ya NO usa el esquema provisorio de arriba: tiene sus dos extremos autorados, el 0.0 es el
## modelo tal cual viene y el 1.0 es ese modelo × ARM_MODEL_FACTOR.
##
## Pero `arms_length` del arquetipo NO mapea a 0..1 completo, y no es un descuido: en Blender el 1.0
## es "brazo totalmente extendido alcanzando", no "personaje de brazos largos" — son cosas distintas.
## Con factor ×4 la distinción deja de ser teórica: un personaje parado con el brazo en 1.0 mediría
## 1.49 m de hombro a muñeca. Así que el arquetipo elige PROPORCIÓN DE CUERPO dentro de esta banda, y
## el agarre es lo único que empuja por encima de ella.
##
## Calibrada contra hombro→PUNTA DE LOS DEDOS, no contra hombro→muñeca. La mano son 0.158 m más allá
## de la muñeca y es lo que se ve; medir solo la cadena daba un brazo que en pantalla llegaba casi a
## la rodilla.
##
## EL PISO ES 0.00 y es el brazo tal cual se esculpió en Blender: no hay nada más corto. Ahí vive
## `kid`, y para eso se acortó la base del brazo en Blender (0.471 → 0.330). Antes de ese re-baseo el
## chico tenía los brazos proporcionalmente MÁS LARGOS que cualquiera, y no había número acá que lo
## arreglara.
##
## EL TECHO NO ES A OJO, SE DERIVA. El brazo más largo, estirado al máximo por el agarre, tiene que
## caer JUSTO en el máximo autorado en Blender — ni más (con la malla de Blender el correctivo se
## clampeaba y se veía de goma) ni mucho menos (se desperdicia rango esculpido). Eso es:
##
##     cadena(ext) · stretch = cadena_modelo · F        ⇒  ext = (F/stretch − 1) / (F − 1)
##
## Con F = 4 y stretch = 2 da exactamente 1/3, o sea que el arquetipo más largo tiene el DOBLE del
## brazo del modelo y estirado llega al ×4 justo. Antes esto era un número puesto a mano (0.09, después
## 0.15) y `lanky` se pasaba un 3%.
##
## ⚠ SUBIR EL TECHO ALARGA A TODOS, porque `arms_length` es una fracción de la banda. Cada vez que se
## mueve hay que re-pinchar el `arms_length` de los arquetipos para que solo cambie el que se quiere
## cambiar. Con el techo en 1/3 la cuenta es directa: `k = largo_deseado / cadena_modelo − 1`.
##
## ⚠ Estos números dependen de `rig.arm_chain`, que sale del .glb. Si se remodela el brazo en Blender,
## HAY QUE REVISAR ESTA BANDA: ya pasó — la cadena creció de 0.372 a 0.471 en un remodelado y un
## recorte del 12%% acá terminó dando un brazo más largo que antes.
##
## Calibrada contra hombro→PUNTA DE LOS DEDOS: la mano son 0.180 m más allá de la muñeca y es lo que
## se ve.
const ARM_EXT_MIN := 0.00
## El estirón para el que se dimensiona la banda. Es el `arm_stretch` que usan todos los arquetipos;
## `MAX_ARM_STRETCH` es aparte y es solo un tope de seguridad.
##
## SUBIR ESTO ACORTA EL BRAZO MÁS LARGO POSIBLE, y bajarlo lo alarga: la banda se dimensiona para que
## el brazo al tope, estirado `DESIGN_ARM_STRETCH` veces, no pase de lo esculpido (`ARM_MODEL_FACTOR`).
##
## Bajó de 2.0 a 1.85 para darle brazos más largos al `lanky`, que ya estaba clavado en
## `arms_length = 1.0`. **No costó alcance**: su `arm_stretch` ya venía clampeado por
## `authored_max / new_arm_length`, así que el techo de agarre —que es `rig.arm_chain × 4 × 0.97`, o
## sea 1.282 m— es el mismo de antes. Lo único que cambió es cómo se reparte entre largo y estirón.
##
## ⚠ CAMBIARLO RE-MAPEA `arms_length` DE LOS SEIS. Si volvés a tocarlo, hay que recalibrar los seis
## valores con `t = (escala_deseada - 1) / (ARM_MODEL_FACTOR / DESIGN_ARM_STRETCH - 1)` o a todos les
## cambia el brazo de rebote.
const DESIGN_ARM_STRETCH := 1.85
const ARM_EXT_MAX := (ReferenceRig.ARM_MODEL_FACTOR / DESIGN_ARM_STRETCH - 1.0) / (ReferenceRig.ARM_MODEL_FACTOR - 1.0)



## El parámetro de radio del cuello de un arquetipo. Lo piden dos: el tamaño del hueso y el defecto del
## ancho autorado (ver TorsoShape.neck_width), y tienen que decir lo mismo.
static func neck_radius_of(stats: EntityArchetype) -> float:
	return lerp_range(0.05, 0.12, stats.muscularity)


## Extensión máxima del brazo en reposo, en fracción de su cadena.
##
## NUNCA 1.0: a extensión total el codo queda colineal, el plano de flexión se indefine y la torsión de
## la mano sale arbitraria — resuelta por una cuenta en espacio mundo, o sea distinta según hacia dónde
## mire el personaje. Fue el bug de las manos dadas vuelta.
##
## Es el PISO de la flexión: con `arm_bentness = 0` el codo se queda con lo que este tope deje.
##   0.97 → 28°     0.985 → 20°     0.99 → 16°     1.0 → 0° y roto
## En 0.985 el codo sigue claramente fuera del eje, así que el pole tiene plano definido y sobra
## margen. Si alguna vez vuelven a aparecer manos dadas vuelta, este es el primer sospechoso.
const ARM_REST_EXTENSION := 0.99

## Techo ABSOLUTO del estiramiento, en múltiplos del largo en reposo. Es una red de seguridad, no la
## perilla: quien elige cuánto estira cada personaje es `EntityArchetype.arm_stretch`. Esto solo
## impide que un arquetipo pida un brazo fuera del rango que se esculpió en Blender, donde el shape
## key ya no tiene con qué corregir la silueta y la malla sí se ve de goma.
##
## 2.5 sobre el genérico (escala 1.54) da 0.98 del rango autorado — o sea justo el borde del ×4.
const MAX_ARM_STRETCH := 2.5

## UN LARGO GUARDADO, mezclado: el de la capa del primer arquetipo y el de la del segundo al peso de la mezcla; lo que una
## capa no dice, el del código (ver `create`). Sin mezcla, el del primero.
static func _mixed(layer: Dictionary, other: Dictionary, key: String, code: float, mix: float) -> float:
	var own := float(layer.get(key, code))
	if mix <= 0.0:
		return own
	return lerpf(own, float(other.get(key, code)), mix)


## `scale` agranda el personaje entero sin tocar su arquetipo. Ver `size_scale`.
## `head_slot` fuerza una forma de cabeza (ver HeadForms) en vez de la de su arquetipo canónico (ver
## CharacterLook.head_form); −1 deja la del arquetipo.
static func create(inst: EntityInstantiation, scale: float = 1.0,
		head_slot: int = -1) -> SkeletonSizesUtil:
	var skelSizes = SkeletonSizesUtil.new()
	var entityStats := inst.arch_final
	var rig := ReferenceRig.get_rig()

	# Las tres cadenas paramétricas: 0..1 del arquetipo → metros, dentro del rango del modelo.
	var new_leg_height   := leg_chain_for(rig, entityStats.legs_length)
	var new_torso_height := torso_chain_for(rig, entityStats.torso_length)
	var new_arm_length   := arm_chain_for(rig, lerp_range(ARM_EXT_MIN, ARM_EXT_MAX, entityStats.arms_length))
	# Cuánto se aparta esta pierna de la del modelo: escala lo que se lee del rig (estancia, tobillo).
	var leg_scale: float = new_leg_height / rig.leg_chain if rig.leg_chain > 0.0 else 1.0
	# Todavía sin parametrizar (fase 3): quedan en el largo esculpido.
	# Todavía sin parametrizar (fase 3): quedan en el largo esculpido, leído del rig.
	var new_head_height       := rig.neck_len + rig.head_len
	# El hueso de hombro y el de cadera están horizontales en el modelo, así que alargarlos mueve el brazo
	# y la pierna hacia AFUERA sin bajarlos — `upper.arm` y `higher.leg` son hijos y los siguen gratis
	# (con `Inherit Scale = None`, para que se corran sin engordarse).
	#
	# Las escalas de esqueleto van ENCIMA de la masa, no en vez de ella: la masa ensancha desde el modelo
	# y esto escala el hueso. Compuestas, un chico gordito es más ancho que un chico flaco y los dos
	# siguen dentro de un esqueleto de chico. Y como los dos huesos son horizontales, brazo y pierna se
	# van con ellos: no hay costura que arreglar ni escultura que hacer.
	var new_hips_width        := authored_chain(rig.hip_len, ReferenceRig.HIPS_MODEL_FACTOR, entityStats.fat) * entityStats.hips_scale
	var new_shoulders_width   := authored_chain(rig.shoulder_len, ReferenceRig.FRAME_MODEL_FACTOR, entityStats.muscle) * entityStats.shoulders_scale

	# ── LO QUE EL PANEL GUARDÓ MANDA, Y TIENE QUE LLEGAR ACÁ ──────────────────────────
	# Los largos de pierna, brazo y torso no son solo huesos: de ellos salen la MARCHA (zancada, excursión,
	# alcance del pie), el ALCANCE DE AGARRE y el alto de la cápsula. Si la forma guardada se aplicara más
	# abajo —donde se arman los huesos— el personaje caminaría con las medidas del arquetipo y se vería con
	# las del panel. Así que se leen primero y pisan los números derivados.
	#
	# SE LEEN DE LA CAPA y no de una forma: lo guardado es la DIFERENCIA contra el defecto del arquetipo (ver
	# ShapeLayer), así que un largo que el archivo no menciona se queda con el del código. Leyendo la forma
	# entera, un campo agregado después del guardado volvía con el defecto de la CLASE y le cambiaba las
	# medidas al personaje — al gordo le ponía 0,9 m de pierna en vez de sus 0,942.
	var layer := TorsoShapes.layer_for(int(inst.archetype_type))
	# ── UNA MEZCLA DE DOS ARQUETIPOS MEZCLA TAMBIÉN SU FORMA ────────────────────────────────────
	# Lo pidió el dios del juego (11/10/2026): la mezcla mezclaba las medidas —los knobs de `arch_final`— y se quedaba
	# con la forma guardada del primero, así que un flaco alto mezclado con un musculoso era un flaco alto. Ahora los
	# largos guardados y la forma entera de los dos se mezclan al mismo peso (ver TorsoShape.blended). La cabeza y el
	# brazo siguen siendo los que la semilla elige para el primero.
	var mix: float = inst.archetype_blend
	var other_layer: Dictionary = TorsoShapes.layer_for(int(inst.secondary_archetype_type)) if mix > 0.0 else {}
	# (Hasta el 07/11/2026 el gordo atlético sin forma guardada tomaba la mitad de la del gordo y la mitad de la del
	# musculoso; desde entonces tiene la suya guardada, que es esa mezcla.)
	# ⚠ LOS TRES LARGOS SE GUARDAN EN SUS DOS VERSIONES, y hace falta: lo que el arquetipo DICE va a la forma
	# por defecto —la base de lo que Olvidar devuelve y de la diferencia que se guarda— y lo que la capa pide
	# va a los huesos y a la marcha. Derivando la base con el valor ya pisado, el defecto del panel pasaba a
	# ser lo guardado: Olvidar no devolvía nada y, peor, la diferencia contra sí mismo era vacía — el próximo
	# guardado borraba el alto autorado sin avisar.
	var code_torso_height := new_torso_height
	var code_leg_height := new_leg_height
	var code_arm_length := new_arm_length
	new_torso_height = _mixed(layer, other_layer, "height", new_torso_height, mix)
	new_leg_height = _mixed(layer, other_layer, "leg_length", new_leg_height, mix)
	new_arm_length = _mixed(layer, other_layer, "arm_length", new_arm_length, mix)
	# (LOS QUE LA CAPA DICE ya llevan adentro la escala horneada, como la forma: ver más abajo, LA ESCALA HORNEADA.)
	var baked_layer_scale := maxf(float(layer.get("skeleton_scale", 1.0)), 0.01)
	if layer.has("height"):
		new_torso_height /= baked_layer_scale
	if layer.has("leg_length"):
		new_leg_height /= baked_layer_scale
	if layer.has("arm_length"):
		new_arm_length /= baked_layer_scale

	skelSizes.arm_reach = new_arm_length
	# Alcance de interacción: hasta dónde puede agarrar, derivado del brazo y no autorado. El 0.97 es
	# el GRAB_MIN_BEND_FACTOR de ArmsController — con ese techo el brazo nunca se estira más de
	# MAX_ARM_STRETCH veces su largo esculpido.
	# El estirón nunca puede pedir más brazo del que se esculpió: con la malla de Blender, pasado
	# `cadena_modelo × F` el correctivo se clampeaba en 1 y la malla se estiraba sin nada que corrigiera
	# la silueta — se veía de goma.
	# El tope sale del MODELO, no de una constante, así que no puede quedar viejo cuando se re-esculpe.
	# Con la banda derivada de arriba esto no llega a activarse; está para que no pueda volver a pasar.
	var authored_max := rig.arm_chain * ReferenceRig.ARM_MODEL_FACTOR
	skelSizes.arm_stretch = minf(minf(entityStats.arm_stretch, MAX_ARM_STRETCH),
		authored_max / maxf(new_arm_length, 0.001))
	skelSizes.interaction_reach = new_arm_length * skelSizes.arm_stretch * GRAB_REACH_FACTOR
	# `height` ya no es una entrada: es esto. Lo lee la cápsula, la cámara y el panel de debug.
	skelSizes.total_height = new_leg_height + new_torso_height + new_head_height

	skelSizes.leg_height      = new_leg_height
	skelSizes.torso_height    = new_torso_height
	skelSizes.head_height     = new_head_height
	skelSizes.hips_width      = new_hips_width
	# La estancia sale del MODELO, no del ancho de cadera. Si el pie en reposo no cae donde el modelo lo
	# tiene, la tibia queda girada respecto de él y el pie —que cuelga rígido de la tibia— hereda ese
	# giro: eran los pies apuntando para adentro. `stance_width` queda como multiplicador encima.
	# LA ESTANCIA ES EL ANCHO DE CADERA, literalmente. En el modelo la pierna es vertical —la punta de
	# `hip.L` y `foot.L` comparten X exacto—, así que el pie cae justo debajo de la articulación y no hay
	# nada más que calcular.
	#
	# Antes era `foot_rest_x * leg_scale`, de cuando la pierna venía inclinada en el modelo y el pie no
	# caía bajo la cadera. Ese `leg_scale` hacía que **alargar la pierna separara los pies**: el genérico,
	# con la pierna a 1.59×, se paraba con 0.411 m entre pies contra los 0.2585 del modelo.
	skelSizes.raycast_stance_offset = new_hips_width * inst.arch_final.stance_width
	skelSizes.shoulders_width = new_shoulders_width

	if entityStats.has_neck:
		var neck_radius := neck_radius_of(entityStats)
		skelSizes.neck_size = Vector3(neck_radius, new_head_height * entityStats.head_neck_ratio, neck_radius)
		skelSizes.head_size = Vector3(CONST_HEAD_RADIUS_XZ, new_head_height * (1.0 - entityStats.head_neck_ratio), CONST_HEAD_RADIUS_XZ * 0.75)
	else:
		skelSizes.neck_size = Vector3.ZERO
		skelSizes.head_size = Vector3(CONST_HEAD_RADIUS_XZ, new_head_height, CONST_HEAD_RADIUS_XZ * 0.85)

	var chest_u_radius : float = lerp_range(0.16, 0.45, entityStats.muscularity)
	var chest_l_radius : float = lerp_range(0.16, 0.45, entityStats.muscularity)
	skelSizes.chest_size = Vector3(chest_u_radius, new_torso_height * 0.3, chest_l_radius)

	var higher_spine_u_radius : float = lerp_range(0.1, 0.3, entityStats.fatness)
	var higher_spine_l_radius : float = lerp_range(0.1, 0.3, entityStats.fatness)
	skelSizes.higher_spine_size = Vector3(higher_spine_u_radius, new_torso_height * 0.25, higher_spine_l_radius)


	var lower_spine_u_radius : float = lerp_range(0.1, 0.35, entityStats.fatness)
	var lower_spine_l_radius : float = lerp_range(0.1, 0.35, entityStats.fatness)
	skelSizes.lower_spine_size = Vector3(lower_spine_u_radius, new_torso_height * 0.2, lower_spine_l_radius)

	var shoulder_u_radius : float = lerp_range(0.08, 0.2, entityStats.muscularity)
	var shoulder_l_radius : float = lerp_range(0.08, 0.25, entityStats.muscularity)
	skelSizes.shoulder_width = Vector3(shoulder_u_radius, new_shoulders_width, shoulder_l_radius)

	var arm_total := new_arm_length
	var upper_arm_u_radius : float = lerp_range(0.06, 0.2, entityStats.muscularity)
	var upper_arm_l_radius : float = lerp_range(0.06, 0.23, entityStats.muscularity)
	skelSizes.upper_arm_size = Vector3(upper_arm_u_radius, arm_total * 0.45, upper_arm_l_radius)
	var lower_arm_u_radius : float = lerp_range(0.06, 0.13, entityStats.muscularity)
	var lower_arm_l_radius : float = lerp_range(0.06, 0.18, entityStats.muscularity)
	skelSizes.lower_arm_size = Vector3(lower_arm_u_radius, arm_total * 0.55, lower_arm_l_radius)

	var higher_leg_u_radius : float = lerp_range(0.06, 0.2, entityStats.fatness)
	var higher_leg_l_radius : float = lerp_range(0.06, 0.23, entityStats.fatness)
	skelSizes.higher_leg_size = Vector3(higher_leg_u_radius, new_leg_height * 0.45, higher_leg_l_radius)
	var lower_leg_u_radius : float = lerp_range(0.06, 0.2, entityStats.fatness)
	var lower_leg_l_radius : float = lerp_range(0.06, 0.23, entityStats.fatness)
	skelSizes.lower_leg_size = Vector3(lower_leg_u_radius, new_leg_height * 0.55, lower_leg_l_radius)
	skelSizes.foot_size = Vector3(0.1, new_leg_height * 0.2, 0.1)
	var hip_u_radius : float = lerp_range(0.1, 0.2, entityStats.fatness)
	var hip_l_radius : float = lerp_range(0.1, 0.2, entityStats.fatness)
	skelSizes.hip_size = Vector3(hip_u_radius, new_hips_width, hip_l_radius)

	# ⚠ ESTE BLOQUE ES EL QUE MANDA. El `.y` de cada Vector3 ES el largo del hueso: `CustomBone.length`
	# lee `capsule_dimensions.y` y nada más. Lo que se haya puesto arriba en el `.y` se pisa acá.
	#
	# Los radios (.x/.z) NO se tocan: son la forma de la cápsula del CustomBone, que ya no se dibuja.
	# Hueso hoja = no estira malla, así que `foot_size` se queda con su fórmula derivada.
	#
	# El hombro decía `rig.shoulder_len` —el largo crudo del modelo— y por eso ni `muscle` ni la escala
	# de esqueleto llegaban NUNCA al hueso: se calculaban, se guardaban en `shoulders_width`, y el hueso
	# seguía midiendo lo mismo en todos los personajes. La cadera sí usaba su valor derivado; el hombro
	# quedó atrás. Cualquier campo nuevo tiene que llegar hasta ACÁ o no existe.
	skelSizes.lower_spine_size.y  = _share(rig, "lower_spine",  new_torso_height, rig.torso_chain)
	skelSizes.higher_spine_size.y = _share(rig, "higher_spine", new_torso_height, rig.torso_chain)
	skelSizes.chest_size.y        = _share(rig, "chest",        new_torso_height, rig.torso_chain)
	skelSizes.neck_size.y         = rig.neck_len if entityStats.has_neck else 0.0
	skelSizes.head_size.y         = rig.head_len if entityStats.has_neck else new_head_height
	skelSizes.shoulder_width.y    = new_shoulders_width
	skelSizes.upper_arm_size.y    = _share(rig, "left_upper_arm",  new_arm_length, rig.arm_chain)
	skelSizes.lower_arm_size.y    = _share(rig, "left_lower_arm",  new_arm_length, rig.arm_chain)
	skelSizes.hip_size.y          = new_hips_width
	skelSizes.higher_leg_size.y   = _share(rig, "left_higher_leg", new_leg_height, rig.leg_chain)
	skelSizes.lower_leg_size.y    = _share(rig, "left_lower_leg",  new_leg_height, rig.leg_chain)

	# ── LA FORMA DEL TORSO MANDA, Y DE ELLA CUELGA EL RESTO DEL CUERPO ─────────────────
	# Una pila de vueltas de control con nombre (ver TorsoShape). El arquetipo trae el DEFECTO —derivado de
	# sus propios knobs, así que sin nada guardado el personaje es el que era— y lo que el panel del
	# sandbox guardó lo reemplaza.
	#
	# Se aplica ACÁ y no en el generador de malla, y es toda la gracia: de esto salen los HUESOS. Los
	# brazos cuelgan de las esquinas de la vuelta de arriba y las piernas de la huella de la de abajo, así
	# que mover un ancho mueve los hombros, los brazos, el alcance de agarre, la estancia, la cápsula y
	# —ahora— el GROSOR DE LAS PIERNAS, que es el de su huella. Un panel que editara la malla tendría que
	# mover todo eso a mano.
	var chest_radius: float = radius_for(chest_u_radius)
	var default_top: float = 2.0 * maxf(new_shoulders_width * 0.5, chest_radius)
	var shape := TorsoShape.straight(code_torso_height, default_top, 2.0 * new_hips_width,
		default_top * TORSO_DEPTH_SHARE)
	# EL DEFECTO DE LA TABLA DE PIERNAS: la huella que la cadera permite, derecho hasta abajo. El afinado y
	# el grosor de verdad los da el panel; esto es de donde parte (ver TorsoShape.straight_legs).
	#
	# El arranque se calcula con la MISMA cuenta que la malla (`leg_start_half`) y no con una copia, porque
	# si las dos no dan el mismo numero la primera vuelta pega un salto contra la huella.
	var leg_start := ProceduralBodyUtil.leg_start_half(2.0 * new_hips_width,
		default_top * TORSO_DEPTH_SHARE)
	shape.legs = TorsoShape.straight_legs(leg_start, BodyLoop.ROUND)
	# Y LOS LARGOS, que en el defecto son los del arquetipo: así el panel abre con los
	# números que el personaje ya tenía y lo primero que se arrastra no pega un salto.
	# EL CUELLO QUE SE VE ES LA MITAD DEL QUE TRAE EL MODELO (ver `NECK_SHARE`): la cabeza se apoya sobre
	# los hombros en vez de asomar sobre un tubo.
	shape.neck_length = rig.neck_len * NECK_SHARE if entityStats.has_neck else 0.0
	# EL CUELLO, LA CABEZA Y LOS PIES: el defecto es exactamente lo que el generador calculaba de los radios
	# del arquetipo, traído acá porque ahora es un dato que el panel edita (ver TorsoShape).
	shape.neck_width = 2.0 * radius_for(neck_radius_of(entityStats)) * 0.68
	shape.head_scale = 1.0
	# EL CINTURÓN DE SIEMPRE, como números del cuerpo (ver TorsoShape.belt_at): su banda en fracciones del alto del torso,
	# y el espesor que le daba su despegue de la sección, en metros.
	var belt_band: Array = (Belts.DEFS[0] as Dictionary)["band"]
	shape.belt_at = Belts.line()
	shape.belt_width = (float(belt_band[1]) - float(belt_band[0])) * shape.height
	shape.belt_thickness = float(belt_band[2]) * shape.width_of(TorsoShape.BOTTOM) * 0.5
	shape.leg_length = code_leg_height
	shape.arm_length = code_arm_length
	# LA ESTANCIA DE LAS PIERNAS, en metros: lo que daba la fracción de siempre sobre la cadera del arquetipo.
	shape.leg_spread = shape.width_of(TorsoShape.BOTTOM) * 0.5 * LEG_STANCE
	# Y ACÁ SE APLICA LA CAPA, sobre la forma que el arquetipo describe. Lo que la capa no diga queda como el
	# código lo puso: no hay tabla que pueda volver vacía ni campo que pueda volver con el defecto de clase.
	skelSizes.torso_default = shape.copy()
	ShapeLayer.apply(shape, layer)
	migrate_stance(shape, layer)
	if mix > 0.0:
		var other: TorsoShape = skelSizes.torso_default.copy()
		ShapeLayer.apply(other, other_layer)
		migrate_stance(other, other_layer)
		shape = shape.blended(other, mix)
	# SIN INCLINACIONES NI FRENTE REDONDO, y las piernas cilindros (ver BodyLoop.plain): se ignora lo guardado.
	for loop: BodyLoop in shape.loops:
		loop.plain()
	for loop: BodyLoop in shape.legs:
		loop.plain(true)
	skelSizes.torso_shape = shape
	# LA ESCALA HORNEADA (ver TorsoShape.skeleton_scale): lo que el código y lo compartido dan se escala con ella al final
	# (ver `_scale_to`), y los metros de la forma —que ya la llevan adentro— se dividen acá para que ese final los deje
	# como están. Lo que se calcula entre los dos, mezcla de los dos, queda en la misma escala: es lineal.
	var baked := maxf(shape.skeleton_scale, 0.01)
	if not is_equal_approx(baked, 1.0):
		_scale_shape(shape, 1.0 / baked)
		_scale_shape(skelSizes.torso_default, 1.0 / baked)
		scale *= baked

	# Lo que la forma redefine. El hueso de hombro y el de cadera son MEDIO-anchos —miden del eje a la
	# esquina— y los de la forma son anchos enteros, que es lo que se lee en un panel.
	# ── EL DOMO NO ALARGA EL PECHO, Y ES UN CAMBIO DE CRITERIO ──────────────────────────────────
	# La tapa de arriba se arquea `arch_x + arch_z` sobre el último anillo (ver BodyLoop). Ese domo se le
	# SUMABA al hueso del pecho, para que el cuello naciera arriba de él y no enterrado.
	#
	# Ya no: con el cuello corto a propósito (ver TorsoShape.neck_length), que el domo lo empuje para arriba es lo
	# contrario de lo que se busca — medido en el gordo, un domo de 0,208 dejaba el nacimiento del cuello
	# 20,8 cm ARRIBA del último anillo del torso y 7,8 cm arriba de los hombros, así que el cuello salía de
	# la nada en vez de salir del cuerpo.
	#
	# Ahora la cadena termina EN EL TOPE DE LA MALLA: la punta del pecho es el único punto del que salen el
	# cuello y los dos hombros, y lo corto que sea el cuello lo decide su perilla. El domo sigue contando para el ALTO TOTAL, que es lo otro
	# que pedía el caso original: un torso abovedado ocupa más de lo que su alto dice (ver `total_height`).
	var top_loop: BodyLoop = shape.loop_named(TorsoShape.TOP)
	var dome: float = maxf(top_loop.arch_x + top_loop.arch_z, 0.0) if top_loop != null else 0.0
	skelSizes.torso_height = shape.height
	skelSizes.torso_dome = dome
	skelSizes.shoulders_width = shape.width_of(TorsoShape.TOP) * 0.5 * shape.arm_stance
	# LA PIERNA CUELGA DEL CENTRO DE SU HUELLA, no de la esquina de la tapa. La huella es un rectángulo de
	# celdas pegado al borde (ver ProceduralBodyUtil.LEG_FOOTPRINT), y su centro cae un poco más adentro;
	# con el hueso en la esquina, el primer tramo de la pierna salía en diagonal desde el agujero hasta el
	# hueso. La estancia es un cuerpo más angosto de caderas que antes, y es correcto: las piernas ahora
	# nacen DE la tapa en vez de estar metidas en ella.
	skelSizes.hips_width = shape.leg_spread
	skelSizes.raycast_stance_offset = skelSizes.hips_width * entityStats.stance_width
	skelSizes.shoulder_width.y = skelSizes.shoulders_width
	# LA BASE DE LA COLUMNA BAJA HASTA EL FONDO DEL FILETE DE LA PELVIS: ahí nace el muslo y ahí arranca su
	# malla, así que ahí tiene que estar el pivote. Se lo come el `lower_spine`, que mide su parte del torso
	# más el filete; las otras dos vértebras no cambian, así que la cadena sigue terminando en el mismo
	# lugar y el cuello y la cabeza no se mueven.
	# Y LAS PIERNAS METIDAS (ver TorsoShape.leg_sink): la cadera sube desde la punta de la tapa de abajo, así que la
	# vuelta de abajo queda más cerca de ella —o por debajo— y la columna, que nace en la cadera, se acorta.
	# LA TAPA DE ABAJO ES COMO LA DE ARRIBA (20/10/2026): la arquean las opciones de la vuelta de abajo (ver
	# ProceduralBodyUtil._trunk). Lo que baja en el centro es su arqueo. Un arquetipo sin arqueo abajo —todos, los que
	# venían de antes— lo saca de su `bottom_dome` de siempre: la mitad en cada eje, con el perfil de cúpula.
	var bottom_loop: BodyLoop = shape.loops[0] if not shape.loops.is_empty() else null
	if bottom_loop != null and is_zero_approx(bottom_loop.arch_x) and is_zero_approx(bottom_loop.arch_z):
		var legacy: float = shape.width_of(TorsoShape.BOTTOM) * 0.5 * ProceduralBodyUtil.PELVIS_DROP * shape.bottom_dome
		bottom_loop.arch_x = legacy * 0.5
		bottom_loop.arch_z = legacy * 0.5
		bottom_loop.arch_dome = true
	skelSizes.bottom_drop = (bottom_loop.arch_x + bottom_loop.arch_z) if bottom_loop != null else 0.0
	skelSizes.pelvis_fall = skelSizes.bottom_drop - shape.leg_sink
	skelSizes.hip_size.y = skelSizes.hips_width
	# ── LAS TRES VÉRTEBRAS MIDEN LO MISMO ──────────────────────────────────────────────────────
	# Un tercio de la cadena cada una, y la cadena es el torso autorado más el filete de la pelvis. Era el
	# reparto del MODELO (lumbar 0,39 · alta 0,29 · pecho 0,31 del torso, medido), que viene de cómo está
	# esculpido el .glb y no de nada que el personaje necesite.
	#
	# Iguales es una decisión de diseño: tres eslabones del mismo largo doblan parejo y son más fáciles de
	# razonar — mover un número del torso mueve las tres por igual.
	#
	# ⚠ LA LUMBAR TIENE UN PISO: su base está en el nudo de la cadera y el filete de la pelvis ocupa su
	# primer tramo (ver `pelvis_fall`), así que tiene que cubrirlo o los anillos del filete le pesarían a la
	# vértebra de arriba. Con una cadera enorme y un torso corto el tercio no alcanza, y ahí el piso manda y
	# las otras dos se reparten lo que queda — de ahí el "intentan" medir lo mismo.
	# (Se reparten más abajo, con el encaje del brazo ya sabido: ver LA COLUMNA TERMINA A LA ALTURA DE LOS HOMBROS.)
	# EL CUELLO Y LOS LARGOS, de la forma: cada largo se reparte entre sus huesos con la proporción del
	# modelo, así que mover uno no desarma la cadena — la rodilla y el codo caen donde corresponde.
	# EL CUELLO MIDE LO QUE LA FORMA DICE, y nada más: nace en la punta del pecho y ese es todo su largo
	# (ver TorsoShape.neck_length, que cuenta por qué esto era una multiplicación de dos perillas).
	skelSizes.neck_size.y = shape.neck_length if entityStats.has_neck else 0.0
	var arm := _split(_share(rig, "left_upper_arm", shape.arm_length, rig.arm_chain),
		_share(rig, "left_lower_arm", shape.arm_length, rig.arm_chain), shape.elbow_shift)
	skelSizes.upper_arm_size.y = arm.x
	skelSizes.lower_arm_size.y = arm.y
	var leg := _split(_share(rig, "left_higher_leg", shape.leg_length, rig.leg_chain),
		_share(rig, "left_lower_leg", shape.leg_length, rig.leg_chain), shape.knee_shift)
	skelSizes.higher_leg_size.y = leg.x
	skelSizes.lower_leg_size.y = leg.y
	# Y DÓNDE CUELGAN LOS BRAZOS: el hombro nace `arm_drop` más abajo del tope del tronco, como un OFFSET y
	# no como un giro, así que sigue horizontal y su largo es la envergadura pedida. Es para poder
	# emparejarlos con un torso al que se le cambió el alto sin tocar el arquetipo.
	# ── Y LA CÚPULA DEL BRAZO SE APOYA SOLA EN LA TAPA (lo pidió el dios del juego, 18/10/2026) ─────────
	# Su punta queda al ras de la superficie de la tapa de arriba a la altura de ese brazo, con la curva incluida (ver
	# `shoulder_cap_height`), así que en 0 los brazos siempre se leen como hombros, abombe uno lo que abombe. La caída
	# (`arm_drop`) se suma a eso: es un corrimiento desde el apoyo, no desde la punta del pecho.
	skelSizes.arm_sink = ProceduralBodyUtil.ARM_INSET - shoulder_cap_height(shape) + shape.arm_drop
	skelSizes.arm_push = shape.arm_push
	# ── LA COLUMNA TERMINA A LA ALTURA DE LOS HOMBROS (22/10/2026, lo pidió el dios del juego) ─────────────────────────
	# Los dos hombros salen horizontales, como una sola línea, hasta donde cuelga cada brazo: así que la punta del pecho
	# va a esa altura, `arm_sink` debajo del tope de la malla (arriba, si el brazo se apoya sobre una tapa abovedada), y
	# las tres vértebras se reparten la cadena. La malla del tronco no cambia: va en metros (ver ProceduralBodyUtil._trunk),
	# y el cuello sigue naciendo en la tapa (ver `neck_anchor`, que lo compensa).
	var chain_total: float = maxf(shape.height + skelSizes.pelvis_fall - skelSizes.arm_sink, 0.05)
	var third: float = chain_total / 3.0
	var lower: float = maxf(third, maxf(skelSizes.pelvis_fall, 0.0) * SPINE_FILLET_MARGIN)
	var rest_pair: float = maxf(chain_total - lower, 0.0) * 0.5
	skelSizes.lower_spine_size.y = lower
	skelSizes.higher_spine_size.y = rest_pair if lower > third else third
	skelSizes.chest_size.y = rest_pair if lower > third else third

	# ── Y LA CABEZA: UNA FORMA DE CABEZA ───────────────────────────────────────────────
	# La que el arquetipo canónico tiene elegida (ver CharacterLooks.head_form_for), o la forzada. La escala de cabeza
	# del CUERPO (`TorsoShape.head_scale`: cuánto ocupa la cabeza en este arquetipo, 1,3 en el niño) se le aplica a una
	# copia, así la forma guardada no se toca.
	skelSizes.archetype = int(inst.archetype_type)
	var slot := head_slot if head_slot >= 0 else CharacterLooks.head_form_for(skelSizes.archetype)
	skelSizes.head_form = HeadForms.form_for(slot).scaled(shape.head_scale)
	# ── EL ATLAS: LA CABEZA GIRA DESDE ADENTRO ──────────────────────────────────────────────────
	# El cuello se alarga hasta el atlas de la forma (ver HeadForm.atlas) y todo lo de la cabeza baja eso mismo en el
	# marco de su hueso (`head_drop`, lo leen los dos cuerpos), así que la cabeza queda donde estaba y gira desde adentro.
	# Sin cuello no hay qué alargar.
	if entityStats.has_neck:
		skelSizes.head_drop = skelSizes.head_form.atlas * skelSizes.head_form.total_height()
		skelSizes.neck_size.y += skelSizes.head_drop
		# UN LARGO NEGATIVO se come el tramo del atlas, pero el hueso no se da vuelta (ver TorsoShape.neck_length).
		skelSizes.neck_size.y = maxf(skelSizes.neck_size.y, NECK_MIN)
	# EL ALTO DE LA CABEZA ES EL LARGO DE SU HUESO, igual que el del torso es el de su cadena: del fondo del domo de
	# abajo a la punta del de arriba.
	# ── Y TERMINA DONDE TERMINA LA MALLA (22/10/2026, lo pidió el dios del juego) ─────────────────────────────────────
	# El hueso nace en el atlas, `head_drop` arriba del fondo de la cabeza (ver arriba), así que con el alto entero se
	# pasaba de la coronilla eso mismo (con la H se veía salir de la cabeza). Mide del atlas a la coronilla.
	skelSizes.head_size.y = maxf(skelSizes.head_form.total_height() - skelSizes.head_drop, 0.01)
	# ⚠ UN CUELLO INCLINADO APORTA MENOS ALTO, y a 90° no aporta nada: lo que sube es su proyección
	# vertical. Sin el coseno, un personaje encorvado a fondo mediría diez centímetros más de lo que ocupa y
	# la cápsula le quedaría grande. (Lo que el torso se come del cuello ya está descontado de su largo.)
	skelSizes.head_height = cos(skelSizes.slouchiness_neck) * skelSizes.neck_size.y \
		+ skelSizes.head_form.total_height() - skelSizes.head_drop
	# EL ALTO TOTAL, de la planta a la coronilla: la pierna, el filete de la pelvis —que es cuerpo y está
	# abajo del nudo de la cadera—, el torso con su domo, y el cuello con la cabeza. El largo del cuello ES
	# el que se ve (ver TorsoShape.neck_length), así que no hay nada que descontar acá.
	# ── EL ALTO TOTAL: EL DOMO Y LA CABEZA COMPITEN, NO SE SUMAN ───────────────────────────────
	# El cuello nace en el tope de la malla y metido para adentro, así que la cabeza y el domo de la tapa
	# ocupan EL MISMO TRAMO: lo alto es lo que sobresalga más. Sumándolos, un torso con domo de 20 cm daba
	# un personaje 20 cm más alto de lo que se ve.
	skelSizes.total_height = shape.leg_length + skelSizes.pelvis_fall + shape.height \
		+ maxf(dome, skelSizes.head_height)
	skelSizes.raycast_leg_length = new_leg_height

	# ── Marcha: de la zancada deseada sale la altura de pelvis, y de ahí el alcance ───────────────
	# La cadena de la pierna (fémur 0.45 + tibia 0.55) mide exactamente new_leg_height. Con la cadera
	# INVERTIDO respecto de como era: antes se elegía la altura de pelvis y de ahí salía el alcance del
	# pie. Ahora se elige el alcance (la zancada) y la pelvis BAJA lo que haga falta, frame a frame,
	# midiendo si las piernas llegan (BoneInstantiator._update_pelvis_drop).
	#
	# Y la altura PARADO sale del modelo, no de una fracción del largo de pierna: en Blender la planta
	# está en 0, así que la Y del hueso raíz es literalmente a qué altura se para el personaje. Con eso
	# el reposo del juego coincide con Blender por construcción, incluida la flexión que hayas modelado
	# y el grosor de pie/zapato (que no se deduce del esqueleto, pero se mide porque el modelo apoya en
	# 0). Se escala con el largo de pierna para que un arquetipo de piernas cortas baje proporcional.
	#
	# Antes había además un margen de seguridad (STAND_EXTENSION) para que un pie en un escalón no
	# trabara la rodilla. Quedó redundante: la pelvis ya baja sola cuando las piernas no llegan, así que
	# el margen estático solo agachaba al personaje de gratis, siempre.
	# La pelvis parada se DERIVA, no se copia del modelo. Copiarla fue el error anterior: el modelo la
	# tiene a 0.8885 sobre una cadena de 0.863, o sea que la pierna no llegaba al piso ni estirada del
	# todo — el personaje flotaba y nunca daba un paso. Del modelo sale solo la altura de TOBILLO (el
	# grosor de pie/zapato, que ningún hueso puede decir), y encima va lo que la pierna alcanza.
	# ALTURA DEL TOBILLO SOBRE EL PISO: es el grosor del zapato, y NO escala con nada.
	#
	# ⚠ Este número tiene que coincidir con lo que hace la MALLA, no con lo que sería ideal. Se ajustó
	# contra la malla de Blender, que ya no existe: ahí el pie no estiraba con la pierna, así que su
	# zapato era RÍGIDO y medía 3 cm en todos los personajes.
	#
	# Estaba multiplicado por `leg_scale`, o sea asumiendo que el pie crecía con la pierna. El resultado
	# era que la IK plantaba el tobillo más arriba de lo que la suela baja y **todos los personajes
	# flotaban**: 18 mm el genérico, 25 el lanky, proporcional al estirado de su pierna.
	#
	# Si algún día el pie escala (entra a una cadena, o se le da su propio factor), este número tiene
	# que volver a escalar CON ÉL.
	skelSizes.ankle_height = rig.ankle_rest_height
	var stand_extension := lerp_range(STAND_EXTENSION_STRAIGHT, STAND_EXTENSION_BENT, entityStats.leg_bentness)
	skelSizes.standing_pelvis_height = skelSizes.ankle_height + new_leg_height * stand_extension
	skelSizes.distance_from_ground = new_leg_height - skelSizes.standing_pelvis_height
	skelSizes.set_stride(new_leg_height, inst.stride)
	skelSizes.current_duty = DUTY_WALK
	skelSizes.current_excursion = 0.0
	skelSizes.current_stride = 0.0

	skelSizes.step_height = new_leg_height * inst.step_height
	skelSizes.pole_distance = new_leg_height
	skelSizes.raycast_start_y_offset = new_leg_height * 0.35

	# EL ENCORVADO DEL CUELLO, hasta el cuarto de vuelta (ver `NECK_SLOUCH_MAX`).
	skelSizes.slouchiness_neck         = lerp_range(0.0, NECK_SLOUCH_MAX, entityStats.slouch)
	# Y LA CURVA DE LA ESPALDA, que es otra cosa y otra variable: el pecho se va adelante y la lumbar atrás
	# de contrapeso (ver EntityArchetype.spine_bend). Van como POSTURA DE POSE, así que deforman el torso.
	skelSizes.spine_bend_chest         = lerp_range(0.0, SPINE_BEND_CHEST_MAX, entityStats.spine_bend)
	skelSizes.spine_bend_lower         = lerp_range(0.0, SPINE_BEND_LOWER_MAX, entityStats.spine_bend)
	# EL CUELLO NACE EN LA TAPA (ver `neck_anchor`): con el encorvado ya sabido, que es lo que elige el punto. La
	# cabeza sube lo que el punto sube, así que el alto de la cabeza y el total lo cuentan.
	var top_cap: BodyLoop = shape.loop_named(TorsoShape.TOP) if shape != null else null
	if entityStats.has_neck and top_cap != null:
		skelSizes.neck_anchor = neck_anchor_on(top_cap, skelSizes.slouchiness_neck)
		var before: float = maxf(skelSizes.torso_dome, skelSizes.head_height)
		skelSizes.head_height += skelSizes.neck_anchor.y
		skelSizes.total_height += maxf(skelSizes.torso_dome, skelSizes.head_height) - before
		# Y SE MIDE DESDE LA PUNTA DEL PECHO, que está a la altura de los hombros y no en el tope de la malla (ver LA
		# COLUMNA TERMINA A LA ALTURA DE LOS HOMBROS): el cuello nace en el mismo lugar de la tapa. El alto no cambia.
		skelSizes.neck_anchor.y += skelSizes.arm_sink
	skelSizes.shoulder_forward         = clampf(entityStats.shoulders_forward, -1.0, 1.0) * SHOULDER_FORWARD_MAX
	skelSizes.shoulder_drop            = clampf(entityStats.shoulders_drop, -1.0, 1.0) * SHOULDER_DROP_MAX

	skelSizes.arm_openness_angle   = lerp_range(0.0, -PI * 0.25, entityStats.arm_openness)
	skelSizes.arm_bentness         = entityStats.arm_bentness

	# ── LOS HUESOS SALEN DE LA FORMA DE BLOQUES (31/10/2026, ver BlockShape) ──────────────────────────────────────────
	# Lo de arriba se sigue calculando, y la forma de bloques pisa lo que el esqueleto, la marcha y el alcance leen. La
	# guardada, o la de fábrica (ver BlockShape.FACTORY).
	var baked_scale := maxf(shape.skeleton_scale, 0.01) if shape != null else 1.0
	var blocks := BlockShapes.for_archetype(skelSizes.archetype)
	if blocks == null:
		blocks = BlockShape.factory(skelSizes.archetype)
	if blocks == null:
		push_error("[SkeletonSizesUtil] El arquetipo %d no tiene cuerpo de bloques (ver BlockShape.FACTORY)." % skelSizes.archetype)
		blocks = BlockShape.new()
	blocks.apply_to(skelSizes, inst, baked_scale)

	skelSizes.left_arm_tip_rest_local   = _compute_arm_tip_local(true,  skelSizes)
	skelSizes.right_arm_tip_rest_local  = _compute_arm_tip_local(false, skelSizes)
	skelSizes.left_arm_pole_rest_local  = _compute_arm_pole_local(true,  skelSizes)
	skelSizes.right_arm_pole_rest_local = _compute_arm_pole_local(false, skelSizes)

	skelSizes.left_arm_shoulder_rest_local  = _compute_arm_shoulder_local(true,  skelSizes)
	skelSizes.right_arm_shoulder_rest_local = _compute_arm_shoulder_local(false, skelSizes)

	# EL TAMAÑO DEL ARQUETIPO (ver EntityArchetype.body_scale) por encima de la lupa.
	skelSizes._scale_to(scale * entityStats.body_scale)
	return skelSizes


## ── EL RADIO DE UN PARÁMETRO DE RADIO DEL ARQUETIPO, en metros ────────────────────────────────────
## La curva con la que el arquetipo da sus radios (`radio = BASE_R·escala + RADIUS_GAIN·parámetro`), medida del `bone.glb`
## de marzo: los radios del arquetipo están afinados contra ella. Vivía en la cápsula del cuerpo de huesos, que se borró
## el 18/10/2026 (ver docs/technical/character-history.md); la curva sigue siendo de dónde salen los defectos.
const BASE_R := 0.05
const RADIUS_GAIN := 0.45


static func radius_for(param: float, scale: float = 1.0) -> float:
	return BASE_R * scale + RADIUS_GAIN * maxf(param, 0.0)


## CUÁNTO SUBE LA TAPA DE ARRIBA a la altura del hombro, sobre la vuelta de arriba: el arqueo en ese punto —`arch_x`
## por su perfil a lo ancho, en la fracción del medio-ancho donde cae el brazo (`arm_stance`), más `arch_z` entero,
## que es lo que levanta la línea del medio de costado (ver GridPart._lift)—.
static func shoulder_cap_height(shape: TorsoShape) -> float:
	var top: BodyLoop = shape.loop_named(TorsoShape.TOP)
	if top == null:
		return 0.0
	var u: float = clampf(shape.arm_stance, 0.0, 1.0)
	var profile: float = sqrt(maxf(1.0 - u * u, 0.0)) if top.arch_dome else 1.0 - u * u
	return maxf(top.arch_x * profile + top.arch_z, 0.0)


## EL PUNTO DE LA TAPA DE ARRIBA DE DONDE SALE UN CUELLO INCLINADO `angle` hacia adelante, como corrimiento desde
## el centro de la vuelta de arriba (ver `neck_anchor`). Se busca sobre la línea del medio, de atrás a adelante: la
## altura de la tapa ahí es la del arqueo (ver GridPart._lift: `arch_x` entero más `arch_z` por su perfil), y el
## punto es donde su pendiente da `angle` — la normal mira hacia donde apunta el cuello.
##
## Con la tapa plana la pendiente es cero en todos lados y el punto saltaría al borde con el primer grado de
## encorvado; para que el slider no salte, la cuenta usa un arqueo mínimo (`CAP_MIN_ARCH`) — sólo para buscar el
## punto, no para su altura. Más allá del borde de adelante no se busca: a fondo, el cuello sale del borde del pecho.
const CAP_MIN_ARCH := 0.03


static func neck_anchor_on(top: BodyLoop, angle: float) -> Vector3:
	var half_depth: float = top.depth * 0.5
	var v := 0.0
	if angle > 1e-4:
		var slope: float = tan(minf(angle, PI * 0.5 - 1e-3)) * half_depth / maxf(top.arch_z, CAP_MIN_ARCH)
		# La pendiente de cada perfil (ver GridPart._arch_profile) despejada: parábola 1 − v², cúpula √(1 − v²).
		v = -slope / sqrt(1.0 + slope * slope) if top.arch_dome else -slope * 0.5
		v = maxf(v, -1.0)
	var profile: float = sqrt(maxf(1.0 - v * v, 0.0)) if top.arch_dome else 1.0 - v * v
	var height: float = top.arch_x + top.arch_z * profile
	return Vector3(0.0, maxf(height, 0.0), v * half_depth - top.forward)


## MULTIPLICA TODO LO QUE ESTÁ EN METROS, y nada más. Ver `size_scale`.
##
## Va al FINAL y no en cada cuenta a propósito: todo lo de arriba es lineal en las seis cadenas derivadas,
## así que escalar el resultado da exactamente lo mismo que escalar las entradas, y de esta forma es una
## lista que se puede leer y auditar de un saque. Lo que NO está en esta lista son fracciones y
## multiplicadores —`arm_stretch`, el duty, las encorvaduras, los pesos de eje— y escalar uno de esos
## sería cambiar el personaje, no su tamaño.
##
## Con factor 1 no toca nada: el camino del juego es el de siempre, bit por bit.
## LOS METROS DE UNA FORMA DE TORSO, escalados: su alto, sus largos, y los anchos, fondos, inclinaciones y
## arqueos de sus dos pilas de vueltas. La redondez y el `at` son fracciones y no se tocan.
static func _scale_shape(shape: TorsoShape, factor: float) -> void:
	if shape == null:
		return
	shape.height *= factor
	shape.neck_length *= factor
	shape.leg_length *= factor
	shape.leg_spread *= factor
	shape.thigh_inward *= factor
	shape.thigh_forward *= factor
	shape.foot_length *= factor
	shape.sleeve_cuff_height *= factor
	shape.foot_heel *= factor
	for cut in shape.foot_cuts:
		cut.scale_metres(factor)
	shape.leg_sink *= factor
	shape.arm_length *= factor
	shape.arm_drop *= factor
	shape.arm_push *= factor
	shape.neck_width *= factor
	shape.belt_width *= factor
	shape.belt_thickness *= factor
	shape.comm_size *= factor
	shape.knee_width *= factor
	shape.knee_height *= factor
	for stack: Array[BodyLoop] in [shape.loops, shape.legs]:
		for loop in stack:
			loop.scale_metres(factor)


func _scale_to(factor: float) -> void:
	if is_equal_approx(factor, 1.0):
		return
	size_scale = factor

	leg_height *= factor
	torso_height *= factor
	head_height *= factor
	hips_width *= factor
	shoulders_width *= factor
	arm_reach *= factor
	interaction_reach *= factor
	total_height *= factor

	head_size *= factor
	neck_size *= factor
	head_drop *= factor
	block_unit *= factor
	hand_width *= factor
	neck_anchor *= factor
	chest_size *= factor
	higher_spine_size *= factor
	lower_spine_size *= factor
	higher_leg_size *= factor
	lower_leg_size *= factor
	foot_size *= factor
	upper_arm_size *= factor
	lower_arm_size *= factor
	shoulder_width *= factor
	hip_size *= factor

	raycast_stance_offset *= factor
	# Los tres son METROS (ver arriba); las encorvaduras son radianes y no escalan.
	pelvis_fall *= factor
	bottom_drop *= factor
	arm_sink *= factor
	arm_push *= factor
	# LA FORMA Y SU DEFECTO, las dos: el panel lee el defecto para mostrarlo y para calcular qué guardar, así
	# que tienen que estar en la misma escala.
	_scale_shape(torso_shape, factor)
	_scale_shape(torso_default, factor)
	if head_form != null:
		head_form = head_form.scaled(factor)
	foot_reach *= factor
	walk_stride *= factor
	leg_reach *= factor
	current_excursion *= factor
	current_stride *= factor
	step_height *= factor
	ankle_height *= factor
	standing_pelvis_height *= factor
	distance_from_ground *= factor
	raycast_leg_length *= factor
	pole_distance *= factor
	raycast_start_y_offset *= factor

	shoulder_forward *= factor
	shoulder_drop *= factor

	left_arm_tip_rest_local *= factor
	right_arm_tip_rest_local *= factor
	left_arm_pole_rest_local *= factor
	right_arm_pole_rest_local *= factor
	left_arm_shoulder_rest_local *= factor
	right_arm_shoulder_rest_local *= factor


## DONDE QUEDA EL HOMBRO respecto del PIVOTE de la pelvis, siguiendo la cadena hueso por hueso. Es la
## entrada del reposo del brazo, y tiene que decir lo mismo que el rig armado o el brazo nace en otro lado.
##
## El `lower_spine` ya trae el filete de la pelvis adentro (ver `pelvis_fall`), así que su largo es
## exactamente lo que hay del pivote a la vértebra siguiente. Ninguna de las tres se inclina: el encorvado
## pasó a ser solo el cuello.
##
## ⚠ Y LA POSTURA DE HOMBRO SE APLICA ACÁ TAMBIÉN. Es pose, no reposo (ver CustomBone.posture), pero el
## reposo del BRAZO tiene que estar donde el hombro mira: si el hueso gira y el target se queda en el punto
## neutro, la IK le tira la mano para atrás y el brazo pelea con el hombro en vez de seguirlo. Se gira todo
## el tramo que cuelga del tope del pecho, que es el mismo pivote sobre el que gira el hueso.
##
## ⚠ ESTA CUENTA NO LA CHEQUEA EL COMPILADOR. Este archivo entra en una dependencia cíclica, así que Godot
## resuelve sus miembros a mano alzada: leer un campo que ya no existe pasa el chequeo de compilación y
## revienta recién al correr (pasó con `slouchiness_chest`, y el síntoma fueron los brazos 16 cm más juntos).
static func _compute_arm_shoulder_local(left: bool, s: SkeletonSizesUtil) -> Vector3:
	return _chest_tip_local(s) + CustomBonesUtil.shoulder_posture(left, s) * _shoulder_arm_local(left, s)


## El tope del pecho respecto del pivote de la pelvis: la cadena entera de la columna.
static func _chest_tip_local(s: SkeletonSizesUtil) -> Vector3:
	return Vector3(0, s.lower_spine_size.y + s.higher_spine_size.y + s.chest_size.y, 0)


## Del tope del pecho al nacimiento del brazo, SIN la postura: el hueso de hombro.
## ── Y LLEGA HASTA DONDE CUELGA EL BRAZO (22/10/2026, lo pidió el dios del juego) ──────────────────────────────────────
## De costado su envergadura, y al frente el ENCAJE del brazo (`arm_push`); su altura (`arm_sink`) la da la punta del
## pecho, que está ahí (ver LA COLUMNA TERMINA A LA ALTURA DE LOS HOMBROS), así que los dos hombros son una línea. El encaje
## era sólo de la malla, que se armaba corrida de sus huesos: en el gordo, 10,7 cm, y con la H el esqueleto se veía afuera
## del cuerpo. Ahora el brazo nace en la punta del hombro y su malla va sobre sus huesos; nunca se desconectan (ver
## CustomBonesUtil).
static func _shoulder_arm_local(left: bool, s: SkeletonSizesUtil) -> Vector3:
	return Vector3(-s.shoulder_width.y if left else s.shoulder_width.y, 0.0, -s.arm_push)

static func _compute_arm_tip_local(left: bool, s: SkeletonSizesUtil) -> Vector3:
	var sign_x := -1.0 if left else 1.0
	# El techo es la CADENA por ARM_REST_EXTENSION, nunca la cadena entera: a extensión total el codo
	# queda colineal, el plano de flexión se indefine y la torsión sale arbitraria — o sea la mano dada
	# vuelta, distinta según hacia dónde mire el personaje. La constante existía y estaba documentada,
	# pero no la leía nadie.
	#
	# Y los radios de cápsula (.x/.z) que se sumaban acá ya no van: eran del sistema viejo, donde el
	# brazo eran dos cápsulas dibujadas y la punta caía sobre la superficie de la última. Con la malla
	# de Blender no representan nada, y sumaban ~0.10 m a un target que la cadena tiene que poder
	# alcanzar: con el brazo corto pedían MÁS que el largo del brazo, y lo dejaban colineal siempre.
	var arm_length := (s.upper_arm_size.y + s.lower_arm_size.y) * ARM_REST_EXTENSION
	var actual_distance: float = lerp(arm_length, 0.0, s.arm_bentness)
	var arm_dir := Basis(Vector3.FORWARD, s.arm_openness_angle * sign_x) * Vector3.DOWN
	# TODO EL TRAMO GIRA CON LA POSTURA, no solo el hombro: el brazo cuelga del hueso girado (ver
	# `_compute_arm_shoulder_local`).
	return _chest_tip_local(s) + CustomBonesUtil.shoulder_posture(left, s) \
		* (_shoulder_arm_local(left, s) + arm_dir * actual_distance)

static func _compute_arm_pole_local(left: bool, s: SkeletonSizesUtil) -> Vector3:
	var sign_x := -1.0 if left else 1.0
	var arm_dir := Basis(Vector3.FORWARD, s.arm_openness_angle * sign_x) * Vector3.DOWN
	var posture := CustomBonesUtil.shoulder_posture(left, s)
	var elbow := _chest_tip_local(s) + posture \
		* (_shoulder_arm_local(left, s) + arm_dir * s.upper_arm_size.y)

	var backward := Vector3(0, 0, 1)
	var outward  := Vector3(sign_x, 0, 0)
	var pole_dir: Vector3
	if ELBOW_POLE_DIRECTION >= 0.5:
		pole_dir = backward.lerp(outward,  (ELBOW_POLE_DIRECTION - 0.5) * 2.0).normalized()
	else:
		pole_dir = backward.lerp(-outward, (0.5 - ELBOW_POLE_DIRECTION) * 2.0).normalized()

	return elbow + pole_dir * s.upper_arm_size.y * 0.8 + Vector3(0, 0, 0.5)


## ── AL ATERRIZAR, LOS PASOS VUELVEN A ARRANCAR (04/11/2026, el dios del juego: «cuando aterrizás, las piernas vuelven
## a estar como en su posición de caminata con la aceleración que trae… deberían volver a posición neutra y empezar a
## acelerar de vuelta») ──────────────────────────────────────────────────────────────────────────────────────────────
## El paso sale de la velocidad (ver LA ZANCADA MANDA), y en el aire el cuerpo la conserva: al tocar el piso el paso era
## el de esa velocidad, de golpe. Con esto, la velocidad que mira el paso se corta a cero en el aire y, desde que toca el
## piso, vuelve a la de verdad en `LocomotionCommon.landing_steps_s` (de todos; 0, apagado): pasitos cortos que se alargan.
## Sólo los pasos; el cuerpo, igual (para que también frene, ver LocomotionCommon.landing_brake). *Hasta el
## 05/11/2026 era un interruptor de la F1 y subía hasta la velocidad MÁXIMA de carrera en 0,6 s, así que a la de verdad
## llegaba en un cuarto de segundo y casi no se veía (el dios del juego: «no sé si lo noto tanto… es muy sutil»).*
## Lo que tiene que estar en el aire (s) para contar como un salto o una caída: corriendo, el piso parpadea unos cuadros,
## y cada parpadeo cortaba el paso a cero.
const AIR_MIN_S := 0.12
var _gait_share := 1.0
var _air_time := 0.0


func update(delta: float, inputs: AnimationInputs, inst: EntityInstantiation, ik_util: IkUtil) -> void:
	_air_time = _air_time + delta if not inputs.grounded else 0.0
	var restart := LocomotionCommon.base().landing_steps_s
	if restart <= 0.0:
		_gait_share = 1.0
	elif _air_time > AIR_MIN_S:
		_gait_share = 0.0
	else:
		_gait_share = minf(_gait_share + delta / restart, 1.0)
	_update_gait(inputs, inst.arch_final, ik_util.style if ik_util.style != null else WalkStyle.plain())
	ik_util.advance_gait(delta, self, inputs)

## EL PASO DE `stride` en una pierna de `leg` (ver LA ZANCADA MANDA): el ciclo caminando y la excursión caminando.
func set_stride(leg: float, stride: float) -> void:
	stride_reach = clampf(stride, 0.0, 1.0)
	leg_reach = leg * MAX_EXTENSION
	# Hasta el primer paso (ver `_update_gait`), con el estilo y el sprint de siempre.
	_set_walk_stride(WalkStyle.plain(), 2.2)


## EL PASO DE LA ZANCADA DE 0 A 1 (ver EntityArchetype.stride_reach): el ciclo a la velocidad de caminar —`walk_stride`—
## tal que, a toda velocidad (`sprint` veces la de caminar), el pie llegue a `stride_reach` largos de pierna de la
## cadera. El ciclo crece con la velocidad por `(v / caminar) ^ crecimiento` y el apoyo baja al de correr, así que se
## despeja de ahí. `foot_reach` es la excursión caminando.
func _set_walk_stride(ws: WalkStyle, sprint: float) -> void:
	var walk_duty := clampf(1.0 - ws.swing_share, 0.05, 0.95)
	var top_duty := minf(DUTY_RUN, walk_duty)
	var top_cycle := 2.0 * maxf(stride_reach, MIN_STRIDE_REACH) * leg_reach / maxf(top_duty, 0.01)
	walk_stride = top_cycle / maxf(pow(maxf(sprint, 1.0), maxf(ws.stride_growth, 0.0)), 0.001) * ws.stride_scale
	foot_reach = walk_stride * walk_duty * 0.5


## Excursión, duty y zancada de este frame, en función de la velocidad (ver LA ZANCADA MANDA). El ciclo es el de
## caminar por `(v / caminar) ^ crecimiento` (el del estilo, ver WalkStyle.stride_growth): llega a cero parado —así
## quieto no hay pasos—, es el de la perilla a la velocidad de caminar y se alarga corriendo. El duty baja de caminata a
## carrera: >0.5 hay doble apoyo, <0.5 hay fase de vuelo; «cuánto vuela el pie» es lo que no es apoyo, al caminar; el
## adelanto corre el lugar donde pisa. La excursión sale del ciclo y del apoyo (`A = S·D/2`) para que el pie apoyado
## no patine.
func _update_gait(inputs: AnimationInputs, entity_stats: EntityArchetype, ws: WalkStyle) -> void:
	var instant_speed := Vector2(inputs.velocity.x, inputs.velocity.z).length() * _gait_share
	var max_speed: float = entity_stats.speed * entity_stats.sprint_multiplier * CharacterRigidBody3D.SPEED_SCALE
	var t: float = clamp(instant_speed / max(max_speed, 0.01), 0.0, 1.0)
	current_speed_t   = t
	var walk_duty: float = clampf(1.0 - ws.swing_share, 0.05, 0.95)
	current_duty      = lerp_range(walk_duty, minf(DUTY_RUN, walk_duty), t)
	# Llega a CERO parado, sin piso: con un piso el pie apuntaba a un objetivo adelantado incluso a velocidad ~0 —la
	# dirección está normalizada—, el paso de asentamiento aterrizaba fuera de su propio umbral y volvía a dispararse:
	# pasitos infinitos.
	var walk_speed: float = maxf(entity_stats.speed * CharacterRigidBody3D.SPEED_SCALE, 0.01)
	_set_walk_stride(ws, entity_stats.sprint_multiplier)
	current_stride    = walk_stride * pow(instant_speed / walk_speed, maxf(ws.stride_growth, 0.0))
	# NUNCA MÁS LEJOS QUE LA PIERNA (ver EntityArchetype.stride_reach): más rápido que el sprint (el turbo del ente) el
	# paso no pasa de un largo de pierna.
	current_excursion = minf(current_stride * current_duty * 0.5, leg_reach)
	current_lead      = (ws.lead - LEAD_BASE) * current_stride

static func lerp_range(min_val: float, max_val: float, t: float) -> float:
	return min_val + (max_val - min_val) * clamp(t, 0.0, 1.0)

## Interpolación en DOS TRAMOS sobre tres valores autorales: 0.0 → 0.5 → 1.0.
##
## No es un lerp de dos puntos porque **el 0.5 no es el punto medio**: es el personaje genérico tal
## como fue esculpido, y los extremos se modelan a mano sin obligación de quedar simétricos. Esa
## asimetría ES el control artístico — con un lerp de dos extremos, el genérico saldría del promedio
## en vez de salir del modelo.
## Largo de una cadena CON LOS DOS EXTREMOS AUTORADOS EN BLENDER: el modelo es el 0.0 y el 1.0 es ese
## modelo × factor. Es la MISMA cuenta que hace el driver de Blender — si las dos se separan, el
## preview de Blender miente. Su inversa la usa el agarre para despejar cuánto puede estirar el brazo.
static func authored_chain(model_len: float, factor: float, t: float) -> float:
	return model_len * (1.0 + (factor - 1.0) * t)

static func arm_chain_for(rig: ReferenceRig, ext: float) -> float:
	return authored_chain(rig.arm_chain, ReferenceRig.ARM_MODEL_FACTOR, ext)

static func leg_chain_for(rig: ReferenceRig, t: float) -> float:
	return authored_chain(rig.leg_chain, ReferenceRig.LEGS_MODEL_FACTOR, t)

static func torso_chain_for(rig: ReferenceRig, t: float) -> float:
	return authored_chain(rig.torso_chain, ReferenceRig.TORSO_MODEL_FACTOR, t)

## Largo de una cadena TODAVÍA SIN AUTORAR (solo el torso): el esculpido es el 0.5 y los extremos son
## factores provisorios sobre él. Brazo y pierna ya no pasan por acá — ver authored_chain.
static func _chain(sculpted: float, t: float) -> float:
	return lerp_three(sculpted * LENGTH_MIN_FACTOR, sculpted, sculpted * LENGTH_MAX_FACTOR, t)

## Largo de UN hueso dentro de una cadena ya escalada: la cadena repartida en la misma proporción que
## tiene en el modelo. Se lee del rig en runtime por la misma razón que las cadenas — transcribirlo
## fue exactamente el bug: el muslo estaba al 0.4592 de la pierna cuando el modelo lo tiene al 0.3810,
## así que la rodilla quedaba 7 cm fuera de lugar y el pie no caía donde la IK lo mandaba.
## LA ESTANCIA DE LAS PIERNAS DE ANTES (ver TorsoShape.leg_spread): una capa guardada cuando era una fracción de la
## cadera, sin el número en metros, se pasa a metros con la cadera que esa capa le dejó a la forma. Sale igual que antes.
const LEG_STANCE := 0.55


static func migrate_stance(shape: TorsoShape, layer: Dictionary) -> void:
	if layer.has("leg_stance") and not layer.has("leg_spread"):
		shape.leg_spread = shape.width_of(TorsoShape.BOTTOM) * 0.5 * float(layer["leg_stance"])


## LA RODILLA O EL CODO CORRIDOS (ver TorsoShape.knee_shift): `shift` del largo entero pasa del hueso de arriba al de
## abajo, sin cambiar el total, y ninguno de los dos queda más corto que `SPLIT_MIN` del total.
static func _split(upper: float, lower: float, shift: float) -> Vector2:
	var total := upper + lower
	var moved: float = clampf(upper + shift * total, total * SPLIT_MIN, total * (1.0 - SPLIT_MIN))
	return Vector2(moved, total - moved)


const SPLIT_MIN := 0.25


static func _share(rig: ReferenceRig, field: String, chain: float, rig_chain: float) -> float:
	if rig_chain <= 0.0:
		return 0.0
	return chain * float(rig.lengths.get(field, 0.0)) / rig_chain

static func lerp_three(lo: float, mid: float, hi: float, t: float) -> float:
	var c := clampf(t, 0.0, 1.0)
	if c <= 0.5:
		return lo + (mid - lo) * (c * 2.0)
	return mid + (hi - mid) * ((c - 0.5) * 2.0)

## La inversa de lerp_three: dado un largo en metros, qué valor 0..1 lo produce. La usa el agarre
## para despejar "necesito un brazo de tanto, ¿qué arms_length es eso?" y clampear en 1.0.
static func inverse_lerp_three(lo: float, mid: float, hi: float, value: float) -> float:
	if value <= mid:
		if absf(mid - lo) < 0.0001:
			return 0.5
		return clampf(0.5 * (value - lo) / (mid - lo), 0.0, 1.0)
	if absf(hi - mid) < 0.0001:
		return 0.5
	return clampf(0.5 + 0.5 * (value - mid) / (hi - mid), 0.0, 1.0)
