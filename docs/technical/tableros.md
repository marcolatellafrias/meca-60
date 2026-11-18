# Las caras con tablero

**Código** de las caras que pueden llevar controles y de los controles traídos de character-parametric (17/11/2026).
El diseño —los tres puestos, los dos modos de mostrar un objeto, los controles de tres botones— está en [[la-meca]].

## Una cara con su grilla — `FaceBoard`
Toda cara plana que puede llevar tablero se describe igual: **dónde está, hacia dónde mira y qué es cada celda**
(`game/mech/boards/face_board.gd`). La celda es **la de los tableros de character-parametric**
(`ProceduralDashboard.CELL`, **4 cm**), así cada componente traído mide lo mismo que allá.

- **La grilla arranca en una esquina de la cara** (`anchor`), no centrada, y **lo que lleva tableros se mide en celdas
  enteras**, como el casco de la nave de character-parametric: así la grilla de una cara **sigue en la de al lado** por
  la arista que comparten (el usuario, 17/11/2026: «las grillas no están coincidiendo»). Lo que no entra entero (las
  puntas de un trapecio, la fila de abajo de la pared del pozo) queda sin pintar.
- **Qué es cada celda**, como `ShipBoardGrid` de la nave: **el marco**, celeste, la vuelta de una celda contra el borde
  (`MARGIN_CELLS`), sin piezas; **la zona de piezas**, verde, donde van los controles; y **nada**, lo que no entra.
- **Pintada en una sola textura por cara** (`view`), como la nave: cada celda de su color, un poco transparente, con su
  rayita. Se ve con **G** en la parcela.
- **La convención, la de los tableros**: la grilla arranca arriba a la izquierda y crece hacia +X y −Y; la cara mira
  hacia +Z, a quien la usa (`frame`). «Arriba» en la cara es lo que sube en el mundo; en un techo, hacia el frente.

**Medida en celdas enteras** (17/11/2026). Las perillas siguen en metros; lo que se arma es lo más cercano que da
celdas enteras:
- **La cápsula** (`CageShape.capsule_radius`): el radio, corrido para que la arista de cada cara cuadrada sea de celdas
  enteras (de a 4,8 cm de radio). Con lo guardado hoy (0,89 m), 0,869 m: caras de 18 × 18 y el cinturón de 36 × 18.
  La caja, el alto y los ojos salen de este radio.
- **El pozo** (`CageShape.pit_apothem`): el apotema, corrido para que el lado de adentro del octógono sea de celdas
  enteras (hoy, 12).
- **El tablero de arriba** (`DeskPit.DEPTH`): 11 celdas de fondo, 44 cm (era 45).

**Quién da sus caras**:
- **La cápsula** (`CageCabin.capsule_boards`): las opacas que no son triángulos ni miran al piso. Salen de las mismas
  caras con que se arma (`CageCabin.capsule_faces`, una sola definición): los costados del cinturón y los de arriba,
  36 × 18; el techo, 18 × 36; los cuatro de la tapa de atrás, 18 × 18.
- **El bloque de arriba** (`CageCabin.upper_boards`, `DeskPit.boards`): las ocho caras del tablero inclinado
  (trapecios de 20 × 11) y las ocho de la pared del pozo (12 × 13). Las dos enganchan en la orilla de adentro, la que
  comparten.

## Las piezas sobre la cara — `FaceMount`
**En celdas sueltas, cada una sobre su base**, como la nave de character-parametric (`ShipKits._clay_block` y
`_component_base`; el usuario, 17/11/2026: «en la nave los placeables tenían como una mini base que ocupaba exactamente
las celdas… y arriba tenía el modelo»; de las dos formas, unidades de módulo o celdas sueltas, eligió celdas sueltas):
- **Cada pieza ocupa sus propias celdas** (las dice su `ComponentArchetype`: el botón 2 × 2, el de encendido 4 × 4, la
  palanca grande 5 × 12, la mediana 4 × 8), donde entre en la zona de piezas sin pisar otra (`can_place`, `place`).
- **Debajo, su base**: una placa de esquinas redondeadas de **exactamente esas celdas**, de 1,8 cm de alto (`RISE`, la
  de la nave para lo que no lleva cable), con su choque. Es lo que se lee como «la pieza ocupa esas celdas»; la pieza
  misma deja su margen encima.
- **Encima, la pieza**, centrada (`PanelArchetype.mount`), con la cara hacia quien usa la cara.
- **La red**: cada pieza se llama por su orden (`pieza_N`), igual en todas las máquinas, y su control sincroniza por su
  camino; el que se une le pide al host cómo están.

*Hasta el 17/11/2026 las ponía el tablero viejo de character-parametric (`ProceduralDashboard`): la caja de cada control
eran sus celdas menos 1 cm de cada lado, sin nada debajo, así que nada llegaba a las rayas. La nave ya no lo usa para sus
piezas (sólo para un botón suelto); sigue acá para los controles armados solos (`ControlArchetype`).*

## Los controles, de character-parametric
Lo esencial, con su lógica intacta (el usuario: «los elementos básicos, interactuables, control rotativo, la inercia de
los controles, dónde se trababa un botón, si era continuo o discreto… estaban bastante bien pensados»):
- **El tablero viejo** (`ProceduralDashboard`, `DashboardPreset`, `DashboardSlot`): ya no pone las piezas de las caras
  (eso es `FaceMount`); queda porque los controles armados solos (`ControlArchetype`) se arman con él.
- **Los controles** (`ControlDefinition`, `TouchComponent`, `OneAxisComponent`, `KnobComponent`, con
  `RotatingComponent` y `TwoAxisComponent`, que ya estaban): continuo o discreto, la inercia, el que se traba, el que
  vuelve solo.
- **Cómo se ven** (`ControlArchetype`: botón, el de encendido, palanca, volante, palanca de dos ejes; `ButtonArchetype`
  con sus parámetros y tapa; `LeverArchetype`; `KeyComponent`, `GuardedButton`, `SafetyCover`; `PanelArchetype`,
  `CellLayout`, `ModelBox`).
- **Recortado**: el catálogo de la nave (las teclas, los telégrafos, las luces, los indicadores, los artefactos) no se
  trajo; `ComponentArchetype` sólo lista lo de arriba. La perilla está, pero sin la rueda que le da sus marcas
  (`RotaryArchetype`). El atril del sandbox es una caja, sin el hueco.
- **El sonido**: la meca simplificó el suyo el 13/11/2026; `SoundEntity` sólo aprendió los eventos que usan los
  controles traídos (apretar, soltar, mover) y toma de cada entrada sus claves, sin las opciones. No hay archivos de
  sonido de botón ni de palanca en ninguno de los dos proyectos: suenan mudos.

## En la meca jaula — `CageBoards`
**Pasó a la meca jaula** (el usuario, 17/11/2026: «está bien ahora el sistema… lo pases a la meca»; se probó antes en
una fila aparte, «Caras con tablero», que se borró): la cabina (`CageCabin`) arma al armarse la grilla de cada cara y,
en algunas, **los controles de verdad de la meca para 3** (17/11/2026, el usuario: «vamos a empezar con la variante de
3»), cada uno sobre su base y **conectado** (`LAYOUT`: el nombre de la cara y sus piezas):
- **Abajo, en la cápsula: los dos brazos y el torso.**
  - **Los dos mandos plegables** (`FoldingArm`, abajo), uno a cada costado del cinturón, adelante. Agarrado con el clic
    derecho mantenido, **el torso persigue la mirada** (`CageMech.steer`) y el **clic izquierdo usa ese brazo**:
    - **El cañón** (el de la izquierda): su gatillo (`MechCockpit.fire`), según el modo que eligen **tres botones**
      en columna justo detrás de su mando, de arriba abajo **ráfaga, barrido y súper**. Ráfaga y barrido, mientras se
      mantiene; el súper carga mientras se mantiene y tira al soltar (`CannonTip`).
    - **El puño** (el de la derecha; el usuario: «el puño lo haría que reemplace el palo por ahora»): **cuanto más se
      mantiene, más lenta y más fuerte la piña** (`MechArm.charged_strike`; en cuánto se carga y lo lenta y lo fuerte
      que sale cargada del todo, en el F7: `CageHandling`). Sin energía, no sale.
  - **Dos pantallas en brazos fijos** (`ScreenArmArchetype`, 3 × 3 celdas en las caras de arriba de la cápsula): la
    **energía** de la meca y la **carga** de lo que se está manteniendo (la piña, o el súper del cañón). Quedan arriba
    a los costados de la vista, mirando a los ojos: se leen agarrando los brazos y mirando al frente (el usuario: «no
    plegable… en una posición que me permita ver su información mientras estoy manejando los brazos y mirando el
    frente»).
- **Arriba, en el pozo: la locomoción.** **La palanca de dos ejes** (caminar), **saltar**, **levitar** (en el aire) y
  **el dash**: ocho botones en círculo (`DashRingArchetype`, 8 × 8 celdas; los botones adentro, libres de la grilla:
  «tal vez no tengas que respetar la grilla porque si no se complica»). El escudo, después.
- **Cada dirección es hacia donde apunta en la meca** (`CageBoards._flat`): la palanca empujada hacia el frente camina
  adelante; el botón del círculo que queda hacia el frente tira el dash adelante. La cara se acuesta sobre el piso
  girándola por su borde horizontal (lo de arriba de la cara va hacia la cara, los ángulos quedan como en ella: los
  ocho del dash a 45°), medido en el mundo: vale en cualquier cara y aunque el módulo de arriba gire aparte.
- **Lo que piden los de arriba lo junta `MechCockpit`** (`ToolMechKeys.cockpit`): cuando nadie la posee, la meca lo
  lee con las mismas reglas de energía que las teclas (el salto, el dash, levitar). Poseyéndola (O), mandan las teclas.
- **La grilla pintada** está apagada: es para ubicar, no de la meca. **L** en la fila de la meca jaula la muestra
  (`CageBoards.show_grid`).
- Se sube con **E** y se usan con clic; cada pieza se encuentra por su nombre (`CageBoards.piece_of`).
- **Cambiar la cápsula o el pozo en el F2 cambia la grilla**: la celda queda en 4 cm y cambia cuántas entran (la
  cápsula, de a una celda por arista); las piezas se vuelven a acomodar solas.
- *Los controles de mentira, los mandos de palo plegables y las pantallitas del que maneja se sacaron: no iban en la
  grilla, y volvieron como brazos de dos articulaciones. Hasta el 17/11/2026 había además palancas y botones de prueba
  sin conectar en casi todas las caras (de tres tamaños).*

## El brazo plegable — `FoldingArm`, `FoldingArmArchetype`
**La segunda forma de mostrar un objeto** (ver [[la-meca]]): en la punta de un brazo de dos articulaciones que sale de
la grilla. **El más simple de las ocho ideas** (el usuario, 17/11/2026: «vamos con la versión más simple»): barras
redondas y rótulas, con **el mando de palo** del que maneja en la punta.
- **Es una pieza** (`FoldingArmArchetype`, 4 × 4 celdas): va en su tablero sobre su base como cualquiera. En la jaula,
  uno en cada costado del cinturón, adelante (`CageBoards.FRONT`, `ROW`).
- **Es un control con modo** (`FoldingArm`, un `ControllableInteractable`): con el **clic izquierdo**, como cualquier
  control, la mano va al mando y nada más. Con el **clic derecho mantenido** entra en su modo: **se trae a la mano**
  (en 0,35 s) y **la mirada va, suave, hacia adelante** (a la cúpula). **Llegada, la mirada queda libre** (el usuario:
  «no se bloquea la cámara… la transición… al soltar mirás libremente»): hacia dónde mira se lo pasa al control
  (`mode_steer`, el giro y la inclinación en el mundo) y el clic izquierdo también (`mode_use`). Al soltarlo, se pliega
  y el clic izquierdo se suelta. Lo dijo el usuario: «lo único que tienen en común con los componentes es que podés
  apuntarlos y hacerle clic y tu mano se va hacia cierto punto».
- **El modo es de todos los controles** (`ControllableInteractable.has_mode`, `enter_mode`, `exit_mode`, `mode_look`,
  `mode_steer`, `mode_use`): cualquiera lo puede tener. El clic derecho lo enruta `InteractionController._set_mode`
  (mientras está, no lo suelta por lejos, y le manda la mirada y el clic izquierdo); la mirada la lleva
  `PlayerController` (`ModePhase`: primero la transición, sin mouse; después libre, **sosteniendo hacia dónde se mira
  en el mundo** mientras la meca gira debajo).
- **En la jaula** (`CageBoards`): la mirada va a `CageMech.steer`, y **el torso la persigue con su resorte** (el giro y
  la inclinación: ver [[meca-jaula]], «Moverse»); el clic izquierdo, al cañón o al puño.
- **Su valor** es 0 plegado y 1 traído, y viaja por red como el de cualquier control.
- **Plegado**, el mando queda a 0,91 m del pecho del que maneja (el alcance es 1 m); traído, a 0,61 m.
- **Más adelante**: que el mando repita la piña o el golpe que se da.

## Test
`tests/cage_cockpit_check.tscn` (unos 20 s, sin el sandbox): los controles de la meca para 3. Encuentra cada pieza, saca
una hoja (desde la cápsula: adelante con las pantallas, el mando del cañón con sus botones, el del puño, los dos
traídos; desde arriba: la palanca, saltar y levitar, el dash) y aprieta cada control como la mano: imprime lo que
camina, las ocho direcciones del dash, el salto, el modo del cañón, la carga del súper y de la piña, cómo sale la piña
y el torso persiguiendo la mirada. Medido el 17/11/2026: el dash a 45° exactos; el salto, 1,9 m; medio segundo
mantenido, la piña sale a 0,71× la velocidad y 1,78× el golpe; pedidos 50° de giro y 20° arriba, **el torso se pasa
hasta 67° y vuelve a 50° en unos 2 s**, y se inclina hasta su tope (8°, un grado de rebote); soltado, se endereza.

`tests/folding_arm_check.tscn` (unos 8 s): la meca jaula, los dos brazos plegados, el derecho en su modo y otra vez
plegándose; imprime cuánto queda cada mando del pecho del que maneja.

`tests/cage_boards_look.tscn` (unos 10 s, sin el sandbox): arma la meca jaula con la grilla a la vista, imprime cada
cara con sus celdas y cuántos controles quedaron, y saca una hoja desde la silla del que maneja (tres), la del de los
brazos (tres) y tres caras de frente y sin perspectiva, para ver que cada pieza cae en sus celdas.
