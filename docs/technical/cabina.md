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

## Dos interiores: con chanfles (el de ahora) o con escaleras
Desde el 15/11/2026 la cuadrada tiene **dos interiores**, a elegir en el F2 (`CabinShape.interior`). El primero que se
arma es **el del centro octogonal con chanfles** (`ChamferCabin`, el usuario: «tiene que ser en realidad la nueva que
hicimos… con chamfers y tarima octogonal»): la planta 1 de la maqueta de los chanfles (`tests/chamfer_cabin_look.tscn`)
en la meca de verdad.
- **La caja con las cuatro esquinas cortadas** (`corner_cells`, en celdas chicas; 18: 71 cm; puede ir a 0, y entonces
  los kits pasan a la pared de atrás, a los costados de las municiones). Adelante, el vidrio: el
  frente, los chanfles de adelante y los costados hasta donde diga el vidrio de los costados, con el zócalo abajo.
  Atrás, metal. **La cabeza es un perfil** (`ChamferCabin._top`, la plana con el corte o la rampa): las paredes y el
  techo se parten donde el perfil dobla y donde termina el vidrio, así cada paño es plano. El marco sigue la misma
  regla (todo borde de un paño), una sola barra por arista; los parantes, entre la silla del medio y cada brazo.
- **Al medio, la tarima octogonal** (`deck_cells`, de su centro a cada lado) con escalones alrededor (`deck_steps`, de
  15 cm de alto y una pisada de escalera); para la cápsula, una rampa de cada lado. **Adentro, corrido atrás
  (`lift_back_cells`), el ascensor**, redondo: su radio es el de la forma o menos, si no entra (deja 12 cm de tarima
  atrás). Atraviesa la pelvis, como en la redonda: después se arregla. Arriba, delante del ascensor, el movimiento.
- **Adelante, tres sillas sin tablero** (lo que aprendió la redonda): la del medio a 1,2 celdas de trama del vidrio;
  los brazos un paso atrás (2,2) y a 2,3 de los costados. **Sin puestos por ahora**: los de `SeatStation` (sesión
  Tableros) se apoyan en el tablero.
- **Atrás**: dos kits en cada chanfle de atrás; las municiones arriba y la batería al medio en la pared de atrás.
- **Abajo, la pelvis de abajo** (`base_cells`, en celdas chicas; 25: 98 cm; 0, sin): una placa chata con la misma
  planta, debajo del piso, con el hueco del ascensor y una franja oscura en la junta. **Es parte de la caja**
  (`CabinGrid.BASE` entra en `HEIGHT` y el piso queda arriba de ella), así que las piernas salen de abajo de ella. Es
  para maquetar rápido: la pelvis de ahora se va a borrar (el usuario, 15/11/2026: «una segunda pelvis… un cubo como lo
  de arriba, pero más chato y con los mismos chamfers»). El alto libre baja ahora hasta 55 celdas (2,17 m).
- Las placas con hueco y sus choques (`_plate`, `_ring_shapes`, `_convex`) son de `MechCabin`; las usan la redonda y
  ésta.

El otro, **el de la tarima atrás con escaleras**, es el de abajo.

## Qué hay adentro con escaleras (`MechCabin`)
- **Adelante, el vidrio, sin marcos**: el frente y los costados hasta la mitad, de piso a techo, y la arista de arriba
  del frente cortada a 45° (**dos celdas de trama**), también de vidrio. Paños planos que se tocan justo en las aristas
  (el usuario: «toda esa zona de cristal… el suelo no… en la esquina superior delantera, tenga un chamfer»). Atrás,
  la pared y la mitad de atrás de los costados, de metal.
- **O la cabeza en rampa** (`CabinGrid.ramp`, a elegir en el F2; el usuario, 15/11/2026, de la maqueta de los chanfles:
  «me gusta la segunda… como una opción más, no como reemplazo»): sin el corte; **el frente más bajo** (su alto libre,
  aparte) y **el techo de vidrio que sube** desde él hasta donde termina el vidrio de los costados; de ahí hacia atrás, el
  techo de metal, con el alto de siempre (el de atrás). Los costados de vidrio, con el borde de arriba inclinado. La
  caja (la que choca con el mundo) es la del alto de atrás.
- **El zócalo** (`CabinGrid.sill`, con las dos cabezas): chapa llena abajo del vidrio del frente y de los costados, en
  celdas chicas; en 0, el vidrio llega al piso (el usuario: «que la base del vidrio tenga como un marco lleno también…
  subirlo o bajarlo»). El marco de abajo va sobre él.
- **El marco del vidrio** (`MechCabin._frame`), a elegir en el F2: **sin nada**, **sólo las aristas** o **las aristas y
  los parantes entre puestos**, con el grosor de las aristas y el de los parantes aparte. La regla de las aristas:
  **todo borde de un paño lleva marco**, también donde el vidrio se junta con la chapa o con el piso (el usuario,
  15/11/2026: «yo diría que es con el límite, así tenemos más consistencia»). Los parantes van en las divisiones del
  tablero (suben por el frente, doblan por el corte y siguen por el vidrio del techo): donde nadie mira. En los
  costados, ninguno: sólo el marco del límite con la chapa (el usuario: «solamente el del límite»). Las ideas que se descartaron están en `tests/glass_frame_ideas_look.tscn`.
- **Adelante, el tablero de los tres puestos** (el brazo izquierdo, la espalda al medio y el brazo derecho): una franja
  de pared a pared, de una celda de fondo, y **cuatro divisores** que salen hacia atrás hasta 2,5 celdas, todos de una
  celda de ancho, también los de las puntas contra la pared (el usuario, 15/11/2026, por la sesión Tableros: «es
  exactamente eso»; de las puntas a la mitad, «queda raro»). Entre ellos, **el hueco de cada puesto** (lo que dejan los
  divisores, repartido en tres: con 12 celdas por lado, de 2,67), con la silla adentro, en su medio (`front_seats`). Un
  puesto cerrado se rellena hasta la punta de los divisores y queda parejo (`CabinGrid.OPEN_POSTS`; todavía no lo cambia
  nada: con dos jugadores, abierto sólo el del medio). Los módulos de cada puesto van en la franja (sesión Tableros).
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
  maniquíes en todas menos la del brazo derecho, que queda libre para sentarse uno con E. En cada hueco abierto
  va **el puesto** (`SeatStation`, de la sesión Tableros, ver [[paneles]]).
- **El ascensor en el medio**, aparte de la trama de los puestos: un hueco redondo (o cuadrado) de **26 celdas chicas
  de radio (1,02 m)** en el piso, y **una plataforma lisa**, sin parantes, aro ni baranda (el usuario: «solamente una plataforma
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
  menos hasta el corte), el radio del ascensor (en celdas chicas: de a 3,9 cm), **si es cuadrado** (el hueco, la plataforma y la pelvis; si no, redondos) y **el alto de
  la tarima** (de a un escalón; las escaleras lo siguen). Arriba, **la cabeza**: plana con el corte, o en rampa.
  **Cada cabeza muestra sus perillas** (el usuario: «cuando cambie la opción cambien los sliders»): en rampa no están
  el corte ni el vidrio del techo (la rampa llega hasta donde el de los costados) y aparece **el alto del frente**; el
  alto libre pasa a ser **el de atrás**. El zócalo, en **El vidrio**. Y **el interior**: con escaleras, o el centro
  octogonal con chanfles; cada uno con lo suyo (el octogonal no tiene el alto de la tarima de atrás ni el ascensor
  cuadrado; tiene el corte de las esquinas, la tarima, los escalones y lo corrido del ascensor).
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
  desde la silla del movimiento y desde arriba sin techo; escribe las medidas. Afuera, también de perfil, de tres cuartos
  de atrás y de frente de cerca. La cabeza: `--cabeza=1 --frente=73 --alto=96 --zocalo=12`.
- `tests/cabin_shape_check.tscn`: el panel rearma las mecas sin tocar el resto de las parcelas.
- `tests/mech_ride_check.tscn`: caminar adentro, el ascensor, la tarima y la escalera, con la meca en movimiento
  (`--interior=0|1`; en el octogonal, la tarima del medio y sus escalones). Con los dos interiores, el de adentro se
  cae cuando a la meca la empujan fuerte: es lo de siempre, no del interior.
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
