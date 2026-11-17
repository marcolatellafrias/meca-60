# La meca jaula

`game/mech/cage/` · fila **Meca jaula** (la primera del sandbox) · ver [[dos-paradigmas]], [[meca-de-tres]],
[[meca-de-capsulas]], [[armamento]]

**La jaula de las maquetas, hecha meca** (16/11/2026). Sale de `tests/cage_ideas_look`, la 166 (el usuario: «empezar a
migrar esta meca a algo funcional… que camine… que se pueda poseer la meca y que los brazos anden y las piernas anden»).
Es una cabina más de la meca (`Mech.Cabin.CAGE`), como la de cápsulas. **Primer paso**: se maneja entera poseyéndola
(la O; la T cambia la vista). Las tres cabinas, subirse con la E y los controles de cada puesto vienen después.

## El tamaño y la forma — `CageShape` (F2)
Los brazos y las piernas son **los de sus perillas de «Brazos y piernas» al 30 %** (la misma pestaña del F2 que las
otras mecas: largos, grosor, cuánto se estiran las piernas y cuánto salen los hombros; `CageCabin.body`,
`MechBody.shrink`). La cabina
**sale de pocas perillas** (`CageShape`, guardadas en `game/mech/cage/cage_shape.tres`; el F2 de su fila,
`CageShapePanel`; el usuario: «controlar el tamaño de la meca y de los módulos sin tener tantos sliders»):
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
Todo con mallas de caras propias (`CageMesh`), nada de cajas pegadas.

## La cabina — `CageCabin`
- **Abajo, la caja del que maneja con su cápsula facetada**: un rombicuboctaedro (`CageMesh.faceted_sphere`) alrededor de
  los ojos, sin la cara de abajo (por ahí sale la silla y cuelgan las piernas), con **el cinturón del medio el doble de
  largo hacia adentro** (el usuario: «no se tiene que dar vuelta para tocar controles… el cinturón sea más largo para
  adentro… el doble del cinturón»). **La tapa de adelante es el domo**: sobresale entera de la caja y es la única de
  vidrio; el cinturón empieza en la cara de la caja. **Los tableros de verdad** en sus caras opacas, cada una con su grilla
  (`CageBoards`, ver [[tableros]]); arriba, sin palancas. **Dos brazos plegables** con el mando de palo, uno en cada
  costado adelante: con el clic derecho mantenido se traen a la mano (`FoldingArm`). **El radio se arma en celdas enteras** de tablero
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
- Las tres sillas: brazos, artillero y manejo; un maniquí en las dos primeras. La U deja en el pozo.
- *Hasta el 16/11/2026 era una caja de 2 m maquetada a mano, con la cubierta de borde en bisel y la torre metida.*

## La meca — `CageMech`
La Meca de tres (`ToolMech`: la energía común, el dash, saltar y levitar) con:
- **El torso discreto y los brazos físicos** (el usuario: «los brazos van a ser físicos y el torso va a ser discreto»).
- **Sus brazos** (`loadout`, ver [[brazo]], «Lo que lleva en la punta»): a la izquierda **el cañón** (`CannonTip`) en
  un brazo discreto, en lugar del antebrazo, con sus cuatro modos y la palanca; a la derecha **el palo** (`PoleTip`) en
  un brazo con músculos (choca y se traba): el puño pesado siempre cerrado agarrando el palo eléctrico. Pega las piñas de
  siempre; el palo sólo se ve (no choca). Los dos con la placa del acorazado. *Hasta el 16/11/2026, `CageCannonArm` y
  `PoleArm`; el cañón llevaba además la funda de la Meca de tres, por eso el brazo entero se veía distinto.*
- **Las placas del acorazado** (las de la armería) en las piernas, y la pelvis cilíndrica de la maqueta.
- **Sus teclas** (`CageMechKeys`): las de la de tres (con el palo, el clic izquierdo un directo y el derecho un gancho).
  La cámara de afuera, más cerca.

## Moverse, sólo ella — `CageMovesPanel` (F1)
Las perillas de la cinemática (`KinematicSettings`), **suyas** (`CageMech.MOVES`, guardadas en
`game/mech/cage/cage_moves.tres`; el usuario: «si un panel lo quiero modificar para este mecha, me gustaría que sea
solamente para esta»). Cualquier cuerpo puede llevar las suyas: `BalanceBody.kinematic_knobs` (si no, las de todas).
Sin guardar, nace con las de las otras y la velocidad, el salto, el vuelo y el dash a la mitad.
Los paneles de los brazos con músculos y de las piernas son los de todas: no están en su fila.

## Test
`tests/cage_mech_look.tscn` (unos 15 s, sin el sandbox): arma la parcela, la hace caminar, pegar con el palo y tirar
con el cañón, imprime lo que mide y saca una hoja (de afuera, desde los ojos del que maneja, caminando, el palo, el
cañón).

## Subirse con la E — `CageBoarding`
Nadie elige silla (el usuario: «se sientan… apretando en la meca y apretando E, y que se llenen por orden»): apuntando a
la meca, **E** sienta al jugador en el primer puesto libre, en orden: manejo, brazos, artillero. Un puesto con maniquí
cuenta como libre: el maniquí se va y el jugador ocupa su silla, la de siempre. **Sentado, 1 a 3** (fila o numpad) pasa
a ese puesto si está libre; **E** lo para. Al dejar un puesto vuelve su maniquí. Las sillas no manejan nada todavía: la
meca se sigue manejando poseyéndola (O). Prueba: `tests/cage_boarding_check` (en el sandbox entero).

## Lo que falta
- Que las palancas y los botones de los tableros manejen algo (hoy sólo se mueven).
- Que cada puesto maneje lo suyo desde su silla (hoy se maneja poseyéndola).
- El puesto del artillero gira con el arma, y la silla gira aparte.
- Los controles de cada puesto, el arma del artillero, que el palo haga algo propio.
