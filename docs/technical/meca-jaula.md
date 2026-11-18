# La meca jaula

`game/mech/cage/` · fila **Meca jaula** (la única meca del sandbox) · ver [[dos-paradigmas]], [[brazo]],
[[base-comun]], [[tableros]], [[armamento]]

**La jaula de las maquetas, hecha meca** (16/11/2026). Sale de `tests/cage_ideas_look`, la 166 (el usuario: «empezar a
migrar esta meca a algo funcional… que camine… que se pueda poseer la meca y que los brazos anden y las piernas anden»).
Es la cabina de la meca (`Mech.Cabin.CAGE`). Se maneja entera poseyéndola (la O; la T cambia la vista) o, **desde el
17/11/2026, desde adentro, con los controles de la variante para 3** (ver [[tableros]]): abajo los brazos y el torso,
arriba la locomoción. Las de 2 y de 1, después.

**Desde el 17/11/2026 es la única meca** (el usuario: «tal vez convenga… borrar todo el sistema de la meca grande…
limitarnos solamente a un approach de meca a una escala más humana, que es la de ahora»). La meca grande —las cabinas
cuadrada, redonda, del vórtice y de cápsulas, la Meca de tres, la discreta, la física, la cinemática, el laboratorio
cinemático, la arena de esquivar, el brazo suelto y el cubo con piernas archivado— se borró con su código, sus tests y
sus notas; está entera en el commit `0bcaeaf`. Lo que la jaula usaba de ella quedó: la meca con herramientas
(`ToolMech`, abajo), los brazos ([[brazo]]), el cuerpo con equilibrio ([[base-comun]]) y la meca de práctica.

## El tamaño y la forma — `CageShape` (F2)
Los brazos y las piernas son **los de sus perillas de «Brazos y piernas» al 30 %** (largos, grosor, cuánto se estiran
las piernas y cuánto salen los hombros; `CageCabin.body`, `MechBody.shrink`). La cabina
**sale de pocas perillas** (`CageShape`, guardadas en `game/mech/cage/cage_shape.tres`; el F2 de su fila,
`CageShapePanel`; el usuario: «controlar el tamaño de la meca y de los módulos sin tener tantos sliders»):
- **El cuerpo: dos torsos** (17/11/2026, el usuario: «dos torsos distintos para la meca y que yo pueda irlos cambiando
  en base a mis necesidades»; `torso`). Comparten la cápsula, el pozo, la torre, los tableros, las sillas, los brazos y
  las piernas; cambia sólo el cuerpo, y cada uno da sus medidas (`side`, `height`, `bubble_y`, `side_face_half`):
  - **La cuadrada**: la caja de siempre (el padding, el piso y el techo).
  - **La redonda**: un **cubo chanfleado** (`CageMesh.chamfered_body`) que es **el pegamento** entre la cápsula y el
    módulo de arriba («el cuerpo es como la glue… podés aumentar su tamaño para que los otros módulos encajen bien»).
    Dos perillas: **el talle** (`body_size`: 0, su cara de adelante es justo la cápsula con su marco; 1, su cara de
    arriba es justo el octógono de arriba; más, más grande) y **el chanfle** (`body_chamfer`: 0, parejo como la
    cápsula; hacia 1, un cubo con las esquinas cortadas). La cápsula va en la cara de adelante, como en la caja. Arriba,
    el pozo de siempre en **un octógono** (`octagon_apothem`: el borde del tablero y 15 cm de pared; `DeskPit.outer_octagon`)
    que, si es más ancho que la cara de arriba, sale de más adentro del cuerpo (`octagon_sink`); más adelante puede girar
    aparte del cuerpo («gira independientemente de esa sección cilíndrica sin que desentone tanto con la parte de
    abajo»). Las medidas: a la medida del octógono, 5,0 m; a la de la cápsula, 4,6 m; con el chanfle a la mitad, 2,9 m.
  - **El hombro, una sola regla** («que el plano de ese cuadrado se centre en ese cuadrado y que el offset… funcione
    ahí»): en el centro de la cara del costado (en la redonda, su cuadrado), adelantado `shoulder_forward` hasta el borde
    de adelante de esa cara.
  - **El octógono de arriba puede girar aparte del torso** (sólo la redonda; `upper_turns`, el interruptor del F2; el
    usuario: «le daría la habilidad de girar aparte, y que pueda togglearla o no»). Por ahora es la base: **todo el
    módulo de arriba cuelga de un pivote** (`CageCabin.upper`: el bloque o el octógono, los tableros de arriba, la silla
    de los brazos y la torre con el artillero) que gira alrededor del eje vertical; **lo que se pisa gira con él**
    (`set_upper_yaw` mueve también sus formas de choque, y el marco por el que se camina las sigue solo). **Hacia dónde
    mira** lo dice un solo lugar, `CageMech.upper_heading`: hoy, hacia donde apuntan las piernas (`BodyLegs.facing_yaw`);
    el usuario lo decide jugando («el torso va a girar mediante controles y la de arriba va a quedar fija apuntando hacia
    adelante. O tal vez… hacia donde apunten las piernas»). Hoy el torso y las piernas giran casi juntos, así que con el
    interruptor prendido casi no se nota: se va a notar cuando el torso gire con sus controles.
  - *La caja física de la meca (la de los golpes) sigue siendo una caja del tamaño del cuerpo también en la redonda (el
    usuario: «el hitbox yo lo dejaría cuadrado por ahora, por simplicidad»).*
- **La cápsula de abajo**: el radio de la cápsula, el vidrio (liso o facetado, su degradé y sus manchas), su marco (ancho y cuánto sale de la cara; un
  anillo, `CageMesh.ring`), el padding de los costados, los grosores del piso
  y del techo, el margen extra (cuánto baja el piso de la cabina por
  debajo de la burbuja, dentro del piso) y la altura de la silla (la pelvis, la misma para todos, con un tope por abajo
  para cada uno: su canilla hasta la suela). El módulo de abajo, y el de arriba, miden de lado
  2 × (radio + padding); el de abajo, de alto, piso + burbuja + techo. Arranca con los de la maqueta 166.
- **El tablero de arriba**: el radio del octógono, la inclinación y los ojos del de los brazos.
- **La torre**: redonda o cuadrada, su ancho y su fondo (nunca más hondo que ancho) y los ojos del artillero. Siempre contra el borde de atrás e independiente
  del octógono: si es más grande de lo que deja, se mete en el pozo y se ve («me voy a dar cuenta… y haré el tamaño de
  la torre más chico»).
- **Brazos y piernas**: **todo se mide desde las esferas** (16/11/2026): la cintura es la esfera del tobillo (su centro
  a su radio del piso, así apoya sin atravesarlo; el pie, más fino, debajo), más las piernas de esa esfera a la de la
  cadera —«cuánto se estiran», en partes del largo, hasta 0,98, que es también el tope de la pierna
  (`MechBody.STRAIGHTEST`)—, más la caída de la cadera. *Era la pestaña de las cabinas de la meca grande; la jaula la
  tiene aparte, con el adelanto de los hombros, desde que nació.*
Todo con mallas de caras propias (`CageMesh`), nada de cajas pegadas.

## La cabina — `CageCabin`
- **Abajo, la caja del que maneja con su cápsula facetada**: un rombicuboctaedro (`CageMesh.faceted_sphere`) alrededor de
  los ojos, sin la cara de abajo (por ahí sale la silla y cuelgan las piernas), con **el cinturón del medio el doble de
  largo hacia adentro** (el usuario: «no se tiene que dar vuelta para tocar controles… el cinturón sea más largo para
  adentro… el doble del cinturón»). **La tapa de adelante es el domo**: sobresale entera de la caja y es la única de
  vidrio; el cinturón empieza en la cara de la caja. **Los tableros de verdad** en sus caras opacas, cada una con su grilla
  (`CageBoards`, ver [[tableros]]): **los dos mandos de los brazos** (plegables: con el clic derecho mantenido se traen
  a la mano y el torso persigue la mirada), los tres botones de modo del cañón y **dos pantallas en brazos fijos** (la
  energía y la carga). **El radio se arma en celdas enteras** de tablero
  (`CageShape.capsule_radius`). *Hasta el 17/11/2026: controles de mentira en el cinturón, los dos mandos de palo a los
  costados (uno estirado, el otro plegado) y dos pantallitas colgadas del vidrio; los mandos volvieron como brazos
  plegables.* El vidrio: degradé (claro adelante, verdoso
  hacia los bordes) y manchas pixeladas (`cage_glass.gdshader`). El que maneja va en la silla de siempre (`BubbleSeat`) y
  **su cámara de primera persona va al centro de la tapa de adelante**. Los hombros, a esa altura.
  *Antes: una esfera entera donde iba la persona, recostada (tests/driver_*_look), una burbuja-ventana (la 166) y la
  cápsula facetada redonda con dos maneras de partir el vidrio (tests/glass_split_look).*
- **Arriba, el bloque lleno con el pozo** (`DeskPit`): un octógono tallado en el medio; la pared de adentro sube hasta
  la orilla del tablero y el tablero inclinado sube hasta lo alto del bloque. Lo alto sale de las perillas: el centro de
  cada cara mira derecho a los ojos. Sin barandas. El tablero y la pared del pozo llevan grilla; hay piezas de verdad en
  las caras de adelante y de los costados (`CageBoards`). El lado del pozo, en celdas enteras (`CageShape.pit_apothem`).
- **Atrás, la torre del artillero**: arriba, el plato que gira con su silla y el arma montada (sólo se ve; `gun`).
- **La espalda del cubo**: el hueco de un recurso, la batería y la mochila del jetpack (sólo se ven).
- Las tres sillas (`CageCabin.SEAT_NAMES`): **arriba la locomoción, atrás el artillero, abajo los brazos** (y con ellos
  el torso); un maniquí en cada una (`MechCabin.seat_dummies`). La U deja en el pozo. *Hasta el 17/11/2026, arriba los
  brazos y abajo el manejo.*
- **La caja no choca con nada de lo suyo** (`build_frame`): ni con las sillas ni con las bases de los tableros y los
  brazos plegables, que van adentro de ella. *Hasta el 17/11/2026, sólo con lo suelto: la jaula es cinemática y lo fijo
  no la toca; la de práctica, física, salía despedida por los 75 cuerpos fijos de sus tableros.*
- *Hasta el 16/11/2026 era una caja de 2 m maquetada a mano, con la cubierta de borde en bisel y la torre metida.*

## Adentro se camina
Como en la meca grande, la cabina es **un marco** (`MotionFrame`, de character-parametric; lo de toda cabina está en
`MechCabin`):
- Las formas de choque de adentro (`interior`) **no chocan con nada**: son de donde el marco copia su **sombra**. El
  piso, las bolas y las paredes de afuera los sigue recibiendo la caja 1:1.
- El que entra al volumen (el cubo de abajo, o el bloque con la torre) pasa a ir **en el marco**: la meca lo lleva con
  ella, y adentro choca sólo con la sombra. **La caja de afuera deja de chocar con él** (`MechCabin.ride`).
- **Todo, como si la meca estuviera quieta** (13/11/2026; el usuario: «una vez que están adentro los personajes y los
  paquetes, es como si estuvieran quietas las cosas… la regla es siempre la misma»): la inercia que se siente es 0; lo
  suelto que entra lo adopta el marco y va clavado mientras está quieto; las sillas giran con la meca.

## La meca — `CageMech`
La meca con herramientas (`ToolMech`, abajo: la energía común, el dash, saltar y levitar) con:
- **El torso discreto y los brazos físicos** (el usuario: «los brazos van a ser físicos y el torso va a ser discreto»):
  la mueve el motor discreto (`KinematicMover`, ver [[base-comun]]).
- **Sus brazos** (`loadout`, ver [[brazo]], «Lo que lleva en la punta»): a la izquierda **el cañón** (`CannonTip`) en
  un brazo discreto, en lugar del antebrazo, con sus cuatro modos y la palanca; a la derecha **el puño pesado**
  (`HEAVY_FIST`) en un brazo con músculos (choca y se traba): pega las piñas de siempre y, desde adentro, **la piña
  cargada** (`MechArm.charged_strike`: más lenta y más fuerte). Los dos con la placa del acorazado. *Hasta el
  17/11/2026, a la derecha el palo (`PoleTip`): el puño pesado agarrando el palo eléctrico, que sólo se veía (el
  usuario: «el puño lo haría que reemplace el palo por ahora»).* *Hasta el 16/11/2026, `CageCannonArm` y
  `PoleArm`; el cañón llevaba además la funda de la Meca de tres, por eso el brazo entero se veía distinto.*
- **Las placas del acorazado** (las de la armería) en las piernas. La pelvis es el cilindro acostado de la maqueta: desde
  el 17/11/2026 la arman las piernas (`BodyLegs`) para toda meca (antes la jaula cambiaba por él el tambor de las
  grandes).
- **Sus teclas** (`CageMechKeys`): las de la meca con herramientas (con el puño, el clic izquierdo un directo y el
  derecho un gancho). La cámara de afuera, más cerca.
- **El torso persigue lo que pide el de abajo** (`steer`): agarrando un mando, hacia dónde mira (el giro y la
  inclinación). La inclinación (`pitch`) inclina la cabina entera —en la redonda, también el octógono de arriba—, no las
  piernas, y el cañón sube y baja con ella.

## La meca con herramientas — `ToolMech` (`game/tool_mech/`)
Lo que la jaula trajo de **la Meca de tres** (15/11/2026, la meca de ejemplo para cerrar los controles de los tres
pasajeros; el usuario: «hagamos un ejemplo de una mecha con elementos concretos… vamos a ir cerrando entonces todos los
controles que van a tener los tres pasajeros que se sienten en las tres sillas»). Su fila, con la cabina cuadrada, el
taladro a la derecha y las fundas de blindaje en las piernas (`ArmorPlates`), se borró con la meca grande; queda como la
base de la jaula: cinemática, con lo que sigue.
- **La energía común — `MechEnergy`**: una sola para todos ([[armamento]]: «la energía es la estamina de la meca»). La
  gastan el dash, el salto, levitar, el taladro y el cañón. Se recarga sola (14 % por segundo) desde 0,8 s después del
  último gasto. **Vacía, la meca queda aturdida 2,5 s**: no camina, no gira, no tira. *El máximo que baja con el uso y
  cambiar la batería, después.*
- **Las piernas**: el movimiento del motor discreto (caminar, girar, agacharse, saltar, el dash con Shift y una
  dirección) y **levitar**, que es su vuelo (espacio otra vez en el aire): la mejora de **propulsores en las
  pantorrillas, atrás**, que no se modelan. El dash, el salto y levitar, además de sus barras, gastan energía.
- **El dash, una decisión** (el usuario, por Jefes: «diseñar todo para un dash… que cueste más energía»): gasta **el
  25 % de la energía común** (primero fue 40 %; el usuario: «me parece mucho… va a estar moviéndose, haciendo
  ataques»). Y entre dash y dash está **la espera** (`dash_cooldown`, en el F1): aunque sobre energía, no salen dos
  seguidos. Shift sólo cobra si el dash sale de verdad (`KinematicMover.dash_ready()`).
- **Lo que manejan sus teclas** (`ToolMech.cannon`, `drill`, `melee`): de lo que lleve en los brazos, el cañón, lo que
  gira (el taladro o la sierra) y el brazo de las piñas (el primero sin ninguno de los dos). Las puntas, en [[brazo]].
- **Las teclas, poseyéndola** (`ToolMechKeys`; la jaula, `CageMechKeys`):
  - **Piernas**: WASD · el mouse gira · Shift con una dirección, dash · espacio salta, y en el aire otra vez, levita ·
    Ctrl se agacha.
  - **Taladro o sierra**: clic derecho mantenido carga · clic izquierdo descarga. **Si no lleva**, el brazo de las
    piñas: clic izquierdo, un directo; clic derecho, un gancho.
  - **Cañón**: las flechas mueven la palanca · 1 simple, 2 ráfaga, 3 barrido, 4 súper · F, el gatillo.
  - Abajo a la derecha, la energía, el modo, la carga del súper y la del taladro.
  - *Hasta el 17/11/2026, G / X subían y bajaban el ascensor de la meca grande.*
- **Desde adentro** (17/11/2026, la variante para 3; ver [[tableros]]): lo que piden la palanca, saltar, levitar y el
  dash lo junta `MechCockpit` (`ToolMechKeys.cockpit`), y cuando nadie la posee la meca lo lee **con las mismas reglas de
  energía** que las teclas; el gatillo del cañón también (`fire`). **Pendiente, a decidir**: el usuario se imaginaba la
  palanca de caminar **trabada donde se la deja** (para seguir caminando mientras se aprieta el dash); hoy vuelve sola al
  medio al soltarla. *Antes se lo imaginaba con la cámara trabada mirando
  al frente; quedó libre, y lo que se limita es cuánto la sigue el torso. Esto cambia lo de [[armamento]] («el
  movimiento: te conectás», el mouse que gira el cuerpo sobre la silla).*

## Moverse, sólo ella — `CageMovesPanel` (F1)
Las perillas del motor discreto (`KinematicSettings`, una pestaña por grupo), **suyas** (`CageMech.MOVES`, guardadas en
`game/mech/cage/cage_moves.tres`; el usuario: «si un panel lo quiero modificar para este mecha, me gustaría que sea
solamente para esta»). Cualquier cuerpo puede llevar las suyas: `BalanceBody.kinematic_knobs` (si no, las de todas,
`KinematicSettings.current`). Sin guardar, nace con las de todas y la velocidad, el salto, el vuelo y el dash a la
mitad. *Hasta el 17/11/2026 heredaba el panel de la Meca cinemática (`KinematicPanel`), borrado con ella.*
- **El giro es un resorte con topes** (pestaña «Girar», 17/11/2026, el usuario: «un poquito de ida y vuelta como
  resorte… con rebote real que mueva la puntería»): el torso persigue lo pedido (`turn_spring`, en Hz) con freno
  (`turn_bounce`: 1, sin pasarse; menos, se pasa y vuelve), sin pasar la velocidad y la aceleración tope de siempre.
  **La inclinación** al mirar arriba o abajo, con el mismo resorte, hasta `pitch_limit` (8°: «un límite bastante
  fuerte»). Arrancan así (1,2 Hz, 0,55, 8°) **como valores del código**: el archivo guardado no escribe lo que es igual
  al código, así que un valor de arranque propio de la jaula se perdía al cargar uno guardado antes.

## El manejo desde adentro — `CageHandlingPanel` (F7)
Lo de mantener apretado los mandos (`CageHandling`, guardado en `game/mech/cage/cage_handling.tres`): **la piña
cargada**, en cuánto se carga del todo (1 s) y, cargada del todo, lo lenta (0,45× la velocidad) y lo fuerte (2,5× el
golpe) que sale.
Los paneles de los brazos (F3) y de las piernas (F4) son los de todas las mecas. Los paneles de la jaula también están
en la fila **Base** (F2 a F4), para cambiarla desde la sucursal.

## La de práctica
Adelante, a 18 m, **una meca sin brazos** (`Mech` con `arms_kind` NONE), con la misma cabina: es la que se usa para
pegarle (N suave, M fuerte, la bola). Es **física**: su equilibrio es [[pendulo]] (con `BodySettings`), así un golpe la
inclina, la tira y la levanta. *Hasta el 17/11/2026 era la de la meca grande (la cuadrada, a escala de la meca grande).*
Medido ese día: un golpe suave la inclina 18° y vuelve; uno fuerte la tira y se levanta sola en unos 4 s.

## Test
`tests/cage_mech_look.tscn` (unos 15 s, sin el sandbox): arma la parcela, la hace caminar, pegar con el palo y tirar
con el cañón, imprime lo que mide y saca una hoja (de afuera, desde los ojos del que maneja, caminando, el palo, el
cañón). Medido el 17/11/2026, antes y después de borrar la meca grande, igual: la caja de 3,08 × 2,48 × 3,08 m, la
cintura a 3,07 m, camina 7,6 m en 2 s y la mano del palo llega a 20 m/s.
Más: `tests/cage_torsos_look` (los dos torsos: la cuadrada, tres redondas y una con el octógono girado a mano, con sus
medidas, de afuera y desde los dos puestos), `tests/cage_boards_look` (los tableros), `tests/folding_arm_check` (los brazos plegables),
`tests/cage_cockpit_check` (los controles de adentro, ver [[tableros]]), `tests/cage_boarding_check` (subirse con la E), `tests/frame_rebuild_check` (rearmarla con gente adentro),
`tests/crouch_time_check`, `tests/feet_ground_check`, `tests/equipment_check`, `tests/arm_tips_look`.

## Subirse con la E — `CageBoarding`
Nadie elige silla (el usuario: «se sientan… apretando en la meca y apretando E, y que se llenen por orden»): apuntando a
la meca, **E** sienta al jugador en el primer puesto libre, en orden: abajo (los brazos), arriba (la locomoción), el
artillero. Un puesto con maniquí
cuenta como libre: el maniquí se va y el jugador ocupa su silla, la de siempre. **Sentado, 1 a 3** (fila o numpad) pasa
a ese puesto si está libre; **E** lo para. Al dejar un puesto vuelve su maniquí. Sentado, se maneja con los controles de
su puesto (ver [[tableros]]); el artillero, todavía nada. Prueba: `tests/cage_boarding_check` (en el sandbox entero).

## Lo que falta
- Las variantes para 2 y para 1 (los modos para jugar solo, ver [[la-meca]]). El escudo.
- Probar jugando los controles para 3 (hoy medidos en `tests/cage_cockpit_check`).
- El puesto del artillero gira con el arma, y la silla gira aparte. Los controles del artillero y su arma.
- Que el súper del cañón y los golpes la muevan (la cinemática todavía no la mueve un golpe propio).
- Los tiros por la red.
