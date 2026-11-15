# La cabina sobre su trama

`game/consoles/cabin_grid.gd` (`CabinGrid`) · `game/mech/mech_cabin.gd`, `pelvis_lift.gd` · módulo **Interior** (ver
[[modulos]]) · ver [[meca]]

La cabina sale de **una trama cuadrada y pocas reglas**, como la nave de character-parametric (`ShipGrid`): se cambia un
número y todo lo sigue (el usuario: «con una sola variante parametrizamos… si queremos cambiar las proporciones o algo,
es cuestión de cambiar un valor»).

*Hasta el 14/11/2026 era de módulos de 1,89 m, de varios pisos (tres, de servicio abajo y dos sillas por piso), con una
caja de vidrio que sobresalía, una puerta atrás en cada piso y, a elegir en el F2, una pasarela con escaleras por afuera,
una escalera adentro o el ascensor entre pisos. Se sacó todo de una vez para pasar a la cabina que se diseñó en planta y
en arcilla (el usuario: «yo empezaría eliminando varias cosas de la actual para hacerla más lean, así el traslado es más
limpio»).*

## La trama
- **Una celda chica para todo**: 1/16 del cubo de recurso, **3,94 cm**, casi la de los tableros (4 cm). La pisada de
  toda escalera del juego son 8 de estas celdas (`Stairs.TREAD`).
- **La celda de trama**: **13 celdas chicas (51 cm)**. La planta de adentro es de **12 × 12** celdas de trama
  (**6,14 m**; la de 3 × 3 módulos de antes, justa). Todo ocupa celdas de trama enteras. Ejes: X a la derecha, Y
  arriba, −Z al frente; el origen en el centro de la caja.
- **Un solo piso, de 96 celdas chicas libres (3,78 m)**, entre la losa del piso y la del techo; paredes de 6 celdas y
  losas de 5. La caja de la meca mide **6,62 × 4,17 × 6,62 m** (`CabinGrid.box()`; `Mech` toma su tamaño de ahí).
  *El usuario eligió esta escala entre cuatro maquetas (14/11/2026: celdas de 63 a 50 cm): «me parece demasiado
  grande todo… quisiera… un sentido de escala un poco más acorde».*

## Qué hay adentro (`SquareCabin`)
Una sola cuadrada (el usuario, 15/11/2026, después de ver dos interiores: «dale, hacé todo eso»): la planta 1 de la
maqueta de los chanfles (`tests/chamfer_cabin_look.tscn`) en la meca de verdad. Lo de toda cabina (las sillas, los
maniquíes, ir adentro, las placas con hueco y sus choques) es de `MechCabin`, de la que heredan ésta y la redonda.
- **La caja con las cuatro esquinas cortadas** (`corner_cells`, en celdas chicas; 18: 71 cm; puede ir a 0, y entonces
  los kits pasan a la pared de atrás, a los costados de las municiones).
- **Adelante, el vidrio**: el frente, los chanfles de adelante y los costados hasta donde diga el vidrio de los
  costados; atrás, metal. Paños planos que se tocan justo en las aristas.
- **La cabeza es un perfil** (`SquareCabin._top`): el alto de arriba de la caja según qué tan adelante. Las paredes y
  el techo se parten donde el perfil dobla y donde termina el vidrio, así cada paño es plano. Dos cabezas:
  - **Plana, con el corte**: la arista de arriba del frente cortada a 45° (`chamfer`, en celdas de trama), de vidrio,
    y el techo de vidrio hasta donde se elija (el usuario, 14/11/2026: «toda esa zona de cristal… en la esquina
    superior delantera, tenga un chamfer»).
  - **En rampa** (`CabinGrid.ramp`; el usuario, 15/11/2026, de la maqueta de los chanfles: «me gusta la segunda»):
    sin el corte; **el frente más bajo** (su alto libre, aparte) y **el techo de vidrio que sube** desde él hasta
    donde termina el vidrio de los costados; de ahí hacia atrás, el techo de metal, con el alto de atrás. La caja (la
    que choca con el mundo) es la del alto de atrás.
- **El zócalo** (`CabinGrid.sill`): chapa llena abajo del vidrio del frente y de los costados, en celdas chicas; en 0,
  el vidrio llega al piso (el usuario: «que la base del vidrio tenga como un marco lleno también… subirlo o bajarlo»).
- **El marco del vidrio**, a elegir en el F2: **sin nada**, **sólo las aristas** o **las aristas y los parantes entre
  puestos**, con el grosor de cada uno aparte. La regla: **todo borde de un paño lleva marco**, también donde el vidrio
  se junta con la chapa o con el zócalo (el usuario, 15/11/2026: «yo diría que es con el límite, así tenemos más
  consistencia»), una sola barra por arista. Los parantes, entre la silla del medio y cada brazo: suben por el frente
  y siguen por el vidrio del techo. En los costados, ninguno (el usuario: «solamente el del límite»).
- **Al medio, la tarima octogonal** (`deck_cells`, de su centro a cada lado) con escalones alrededor (`deck_steps`, de
  15 cm de alto y una pisada de escalera); para la cápsula, una rampa de cada lado. **Adentro, corrido atrás
  (`lift_back_cells`), el ascensor**: un hueco redondo y **una plataforma lisa**; su radio es el de la forma o menos,
  si no entra (deja 12 cm de tarima atrás). Dos teclas: **sube** y **baja** (Y / H en el panel chico de las filas de
  la meca, G / X para el que la posee); subida, al ras de la tarima; bajada, a un salto del suelo con la meca
  agachada. Atraviesa la pelvis, como en la redonda: después se arregla. Arriba, delante del ascensor, **el
  movimiento**.
- **Adelante, tres sillas sin tablero** (lo que aprendió la redonda), mirando al frente, **con tres perillas para todas
  las cuadradas** (`CabinGrid.front_seats`; el usuario, 15/11/2026: «qué tan alejada está la izquierda y derecha de la
  del medio, y qué tan offseteada para atrás… así yo lo tuiqueo a mano»): **la del medio, del vidrio**
  (`seat_front_cells`); **los brazos, de ella a cada costado** (`seat_spread_cells`, sin pasarse de la pared) y
  **cuánto más atrás van** (`seat_back_cells`; negativo, más adelante). Todas en celdas chicas. Son las de verdad
  (`working_seat.tscn`), buscan **la altura de los ojos** del que se sienta (`CabinGrid.EYE_HEIGHT`); en la meca con
  brazos se sientan maniquíes en todas menos la del brazo derecho, libre para sentarse uno con E. **Sin puestos por
  ahora**: los de `SeatStation` (sesión Tableros, ver [[paneles]]) se apoyaban en el tablero de antes; vuelven cuando
  pasen a la silla (lo que usan de `CabinGrid`, el alto del tablero y el hueco de cada puesto, queda hasta entonces).
- **Atrás**: dos kits en cada chanfle de atrás; las municiones arriba y la batería al medio en la pared de atrás. *Por
  ahora sólo se ven: los huecos de verdad vienen con los recursos.*
- **Abajo, la pelvis de abajo** (`base_cells`, en celdas chicas; 25: 98 cm; 0, sin): una placa chata con la misma
  planta, debajo del piso, con el hueco del ascensor y una franja oscura en la junta. **Es parte de la caja**
  (`CabinGrid.BASE` entra en `HEIGHT` y el piso queda arriba de ella), así que las piernas salen de abajo de ella. Es
  para maquetar rápido: la pelvis de ahora se va a borrar (el usuario, 15/11/2026: «una segunda pelvis… un cubo como lo
  de arriba, pero más chato y con los mismos chamfers»).
- **Los hombros** van en el medio de cada costado, a 0,6 del alto libre (`CabinGrid.shoulder`).
- **La U del sandbox** sube al jugador al piso, entre la silla del medio y los escalones.

*Hasta el 15/11/2026 hubo otro interior: la caja sin chanfles, la tarima atrás de pared a pared (con el movimiento
arriba) y dos escaleras rectas contra los costados, el tablero corrido con cuatro divisores y una silla en el hueco de
cada puesto, los kits en el frente de la tarima, la munición en la pared de atrás y el ascensor al medio, que podía ser
cuadrado. Se retiró (lo descartó el usuario al ver la redonda: el centro con el ascensor adentro, el paso alrededor y
las sillas sin tablero); con él, las funciones que armaban el vidrio y el marco a mano para cada cabeza.*

## El marco
Adentro se camina: el piso, las paredes, el vidrio, el techo y la tarima (con sus rampas) tienen sus formas de choque
en un cuerpo que no choca con nada, del que el marco de la meca (`MotionFrame`) copia su sombra. El que entra a la caja (o al hueco del ascensor) va en el marco, que lo lleva con la meca.
Probado (`tests/mech_ride_check.tscn`): subir, el ascensor abajo y arriba, pararse en la tarima y **subirla
caminando**. Cuando a la meca la empujan fuerte, el de adentro se cae y queda afuera: pasaba igual con el interior de
antes (lo del empujón, no de la cabina).

## La forma se cambia jugando: el panel F2
En las filas de la meca, **F2** (`CabinShapePanel`), en cuatro pestañas (el corte y el vidrio, en **El vidrio**, con
**su color y cuánto se ve**):
- **La caja**: **la cabeza** (plana con el corte, o en rampa), la celda de trama (en celdas chicas; es **el tamaño
  general**), cuántas celdas por lado (desde 12), el alto libre (en celdas chicas, desde 55), el corte de las esquinas,
  la tarima (su tamaño y sus escalones), el radio del ascensor y lo corrido atrás, y la pelvis de abajo. **Cada cabeza
  muestra sus perillas** (el usuario: «cuando cambie la opción cambien los sliders»): en rampa no están el corte ni el
  vidrio del techo (la rampa llega hasta donde el de los costados) y aparece **el alto del frente**; el alto libre pasa
  a ser **el de atrás**.
- **El vidrio**: el corte, **hasta dónde llega el vidrio de los costados** y **hasta dónde el del techo** (cada uno
  aparte, en celdas de trama desde el frente), el zócalo, su color y cuánto se ve, y el marco.
- **Las sillas**: la altura de los ojos que buscan, y **dónde van las tres de adelante** (la del medio, del vidrio; los
  brazos, a los costados y atrás).
- **Brazos y piernas** (`MechBody.dress`, que no depende de la caja): el largo de los brazos y el de las piernas
  (chico, mediano o grande), el ancho de los dos y cuánto se estiran las piernas paradas.

**Un solo Guardar**: la escribe en `game/consoles/cabin_trama.tres` (no se sube al repositorio), rearma todas las mecas
y es la forma de todas, también al reiniciar. *La forma guardada de antes (`cabin_shape.tres`) ya no se usa.* Abajo, las
medidas que salen y la altura de la caja sobre el piso, que sale de las piernas.

## Los tests
- `tests/cabin_grid_look.tscn` (unos 10 s por forma, sin el sandbox; `--celdas=13,11`): de frente, cortada de costado,
  desde la silla del movimiento y desde arriba sin techo; escribe las medidas. Afuera, también de perfil, de tres cuartos
  de atrás y de frente de cerca. La cabeza: `--cabeza=1 --frente=73 --alto=96 --zocalo=12`; la planta: `--esquinas=0
  --pelvis=25`; las sillas: `--silla_medio=16 --silla_brazos=48 --silla_atras=13`.
- `tests/cabin_shape_check.tscn`: el panel rearma las mecas sin tocar el resto de las parcelas.
- `tests/mech_ride_check.tscn`: caminar adentro, el ascensor, la tarima y sus escalones, con la meca en movimiento.
- `tests/two_cabins_look.tscn`: la maqueta de arcilla de la cabina, en cuatro escalas (de donde salió esta).

## Lo que sigue
- **Los puestos con tres y con dos**: con tres, falta decidir entre dos adelante y uno arriba, o los tres adelante. Con
  dos, **uno adelante, en el puesto del medio, y otro atrás, en el movimiento** (el usuario, 15/11/2026, por la sesión
  Tableros; antes eran los dos adelante con el medio vacío).
- **Los huecos de verdad** (kits, batería, munición), cuando lleguen los recursos.
- **La artillería en los hombros**, sobre un soporte fijo que no gira con la bola (lo mostró la maqueta; es del cuerpo,
  de la sesión Meca).
- Los detalles que se sacaron para simplificar (la estructura del ascensor, las barandas) vuelven después, si hacen
  falta.

## La otra cabina: el disco de dos pisos con vórtice (`VortexCabin`)
El 15/11/2026 el usuario probó otro camino para la meca (maquetas de arcilla: `tests/small_disc_look`, el disco chico
sin techo; `tests/four_cabins_look` y `tests/cabin_pods_look`, la meca de cabinas de a uno; `tests/vortex_disc_look`,
el disco de dos pisos), y pidió el último en la meca de verdad: «ponémelo con brazos reales (con física), piernas
reales, y torso con física en una parcela al principio del sandbox así lo pruebo». Es la fila **Meca del vórtice**, la
primera del sandbox (`Mech.Cabin.VORTEX`, brazos físicos):
- **El vórtice**: la boca debajo del disco y un hueco redondo en el piso de la planta baja (su radio, en el F2); en la
  planta baja no hay nada que tape la vista. El que se para debajo sube chupado (6 m/s, hacia el medio) y queda parado
  al lado del hueco; el que pisa el hueco baja despacio (4 m/s como mucho) hasta el suelo. Después irá una tapa de hojas
  que se abre en círculo.
- **El F2** (VortexShapePanel, guarda en `game/mech/vortex/vortex_shape.tres`, del usuario): el radio, el alto de la
  planta baja, el núcleo de arriba (sí o no), el radio del vórtice, el ancho de la escalera y la pestaña «Brazos y
  piernas» de las otras mecas, pero de esta sola.
- **La planta baja**, cerrada: la máquina, el banco de reparación, el tablero de la energía y las municiones (se ven y
  la máquina y el banco chocan). La **escalera caracol**, pegada a la pared, sube al primer piso por un hueco; se pisa
  una rampa en hélice.
- **El primer piso**, abierto: un anillo alrededor de un núcleo opaco; el borde con su bevel, el manejo adelante, los
  mandos de los brazos a los costados y las ametralladoras en enchufes del borde (sólo se ven). El marco lleva a todos
  hasta 2,6 m sobre el piso.
- **La U** te deja en la planta baja, al lado del hueco del vórtice. Sin sillas ni ascensor (G, X, Y, H no hacen
  nada).
- `tests/vortex_mech_check.tscn`: uno sube por el vórtice, otro baja por el tubo; imprime dónde está cada uno.
