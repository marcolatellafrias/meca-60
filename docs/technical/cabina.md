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

## Qué hay adentro (`MechCabin`)
- **Adelante, el vidrio, sin marcos**: el frente y los costados hasta la mitad, de piso a techo, y la arista de arriba
  del frente cortada a 45° (**dos celdas de trama**), también de vidrio. Paños planos que se tocan justo en las aristas
  (el usuario: «toda esa zona de cristal… el suelo no… en la esquina superior delantera, tenga un chamfer»). Atrás,
  la pared y la mitad de atrás de los costados, de metal.
- **El marco del vidrio** (`MechCabin._frame`), a elegir en el F2: **sin nada**, **sólo las aristas** o **las aristas y
  los parantes entre puestos**, con el grosor de las aristas y el de los parantes aparte. La regla de las aristas:
  **todo borde de un paño lleva marco**, también donde el vidrio se junta con la chapa o con el piso (el usuario,
  15/11/2026: «yo diría que es con el límite, así tenemos más consistencia»). Los parantes van en las divisiones del
  tablero (suben por el frente, doblan por el corte y siguen por el vidrio del techo) y en el medio de cada costado:
  donde nadie mira. Las ideas que se descartaron están en `tests/glass_frame_ideas_look.tscn`.
- **Adelante, un tablero corrido** de pared a pared, de una celda de fondo, con **tres puestos de cuatro celdas**: el
  brazo izquierdo, la espalda al medio y el brazo derecho (`front_seats`).
- **Atrás, una tarima de 1,2 m**, de pared a pared y dos celdas de fondo: arriba, al medio, **el movimiento**
  (`top_seat`), que ve a todos y por el vidrio por encima de ellos. El puesto de atrás se lee con más jerarquía y el que
  mueve la meca es el que ve todo (el usuario, 14/11/2026).
- **Dos escaleras rectas**, contra las paredes de los costados, de dos celdas de ancho, que suben a la tarima. Se arman
  con `Stairs` (la regla de toda escalera, ver [[escaleras]]): escalones para los pies y una rampa para la cápsula.
- **En el frente de la tarima, de cara al ascensor**: los cuatro kits de reparación y la batería, parejos entre las dos
  escaleras, la batería al medio. **Arriba, en la pared de atrás**: la munición de cada arma de la espalda; desde afuera
  sólo sobresale el cubo. *Por ahora sólo se ven: los huecos de verdad vienen con los recursos.*
- **Las sillas** son las de verdad (`working_seat.tscn`), mirando al frente, en el orden de `MechCabin.POSTS`. Buscan
  igualar **la altura de los ojos** del que se sienta (`CabinGrid.EYE_HEIGHT`). En la meca con brazos se sientan
  maniquíes en todas menos la del brazo derecho, que queda libre para sentarse uno con E: ahí está **el primer panel
  jugable** (`SeatPanels`, ver [[paneles]]).
- **El ascensor en el medio**, aparte de la trama de los puestos: un hueco redondo de **dos celdas de trama de radio
  (1,02 m)** en el piso, y **una plataforma lisa**, sin parantes, aro ni baranda (el usuario: «solamente una plataforma
  sin toda la estructura metálica… después vamos a los detalles»). Dos teclas: **sube** y **baja** (Y / H en el panel
  chico de las filas de la meca, G / X para el que la posee); subida, al ras del piso; bajada, a un salto del suelo con
  la meca agachada.
- **Los hombros** van en el medio de cada costado, a 0,6 del alto libre (`CabinGrid.shoulder`).
- **La U del sandbox** sube al jugador al piso, entre las sillas de adelante y el ascensor.

## El marco
Adentro se camina: el piso, las paredes, el vidrio, el tablero y la tarima tienen sus formas de choque en un cuerpo que
no choca con nada, del que el marco de la meca (`MotionFrame`) copia su sombra; los escalones y las rampas de las
escaleras también se copian. El que entra a la caja (o al hueco del ascensor) va en el marco, que lo lleva con la meca.
Probado (`tests/mech_ride_check.tscn`): subir, el ascensor abajo y arriba, pararse en la tarima, **subir la escalera
caminando** y que la meca se corra, salte y se caiga con uno adentro.

## La forma se cambia jugando: el panel F2
En las filas de la meca, **F2** (`CabinShapePanel`), en cuatro pestañas (el corte y el vidrio, en **El vidrio**, con
**su color y cuánto se ve**):
- **La caja**: la celda de trama (en celdas chicas; es **el tamaño general**), cuántas celdas por lado (desde 12: menos,
  no entran los tres puestos), el alto libre (en celdas chicas), el corte del vidrio, **hasta dónde llega el vidrio de
  los costados** y **hasta dónde el del techo** (cada uno aparte, en celdas de trama desde el frente; los dos, por lo
  menos hasta el corte), el radio del ascensor y **el alto de la tarima** (de a un escalón; las escaleras lo siguen).
  Las sillas, los kits, la batería y la munición se acomodan solos (los kits, de 1,2 celdas de trama o menos si no
  entran; la munición, de 1,6).
- **Las sillas**: la altura de los ojos que buscan.
- **Brazos y piernas** (`MechBody.dress`, que no depende de la caja): el largo de los brazos y el de las piernas
  (chico, mediano o grande), el ancho de los dos y cuánto se estiran las piernas paradas.

**Un solo Guardar**: la escribe en `game/consoles/cabin_trama.tres` (no se sube al repositorio), rearma todas las mecas
y es la forma de todas, también al reiniciar. *La forma guardada de antes (`cabin_shape.tres`) ya no se usa.* Abajo, las
medidas que salen y la altura de la caja sobre el piso, que sale de las piernas.

## Los tests
- `tests/cabin_grid_look.tscn` (unos 10 s por forma, sin el sandbox; `--celdas=13,11`): de frente, cortada de costado,
  desde la silla del movimiento y desde arriba sin techo; escribe las medidas.
- `tests/cabin_shape_check.tscn`: el panel rearma las mecas sin tocar el resto de las parcelas.
- `tests/mech_ride_check.tscn`: caminar adentro, el ascensor, la tarima y la escalera, con la meca en movimiento.
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
