# La cabina sobre su grilla

`game/consoles/cabin_grid.gd` (`CabinGrid`) · `game/mech/mech_cabin.gd`, `mech_exterior.gd`, `pelvis_lift.gd` · módulo
**Interior** (ver [[modulos]]) · ver [[meca]]

Desde el 13/11/2026 la cabina sale de **una grilla de celdas**, como la nave de character-parametric (`ShipGrid`): se
cambia un número y todo lo sigue (el usuario: «con una sola variante parametrizamos… si queremos cambiar las
proporciones o algo, es cuestión de cambiar un valor»). La idea es poder probar más adelante mecas de otra cantidad de
pisos o de jugadores (de 1 a 4) sin rehacer nada a mano.

## La grilla
- **Una sola celda para todo**: 1/16 del cubo de recurso, **3,94 cm**. Es casi la celda de los tableros de la nave
  (4 cm, del tamaño de la mano), y así el cubo de 63 cm mide 16 × 16 celdas justas: un hueco de recurso encaja en
  cualquier tablero. Todas las medidas de la cabina son celdas enteras.
- **El módulo**: un cuadrado de 3 cubos, de **48 celdas (1,89 m)**. Cada piso es una grilla de **4 × 4 módulos** entre
  sus paredes. La columna 0 es la de la izquierda y la fila 0, la del frente.
- **Tres pisos de 68 celdas** (2,68 m de losa a losa; quedan 2,48 m libres), paredes de 6 celdas y losas de 5.
- **La caja es cuadrada en planta y crece para arriba**: el lado sale de los módulos (`CabinGrid.SIZE`) y el alto, de los
  pisos por el alto de cada uno (`CabinGrid.HEIGHT`). Con la forma de siempre es un cubo de 204 celdas, **8,03 m** (el
  usuario, 13/11/2026: «el formato de cubo… al girar no tiene tantos problemas de colisión. Pero en vertical no tiene
  problema en crecer»). **La caja física de la meca es esa**: `Mech` toma su tamaño de `CabinGrid.SIZE` (lo aceptó el módulo
  Meca el 13/11/2026; desde que la forma cambia jugando, ya no hay `Mech.SIZE`).

## La forma se cambia jugando: el panel F2
En las filas de la meca (Meca discreta, Meca física y la Arena de esquivar), **F2** (`CabinShapePanel`) cambia
**cuántos módulos por lado** (1 a 6), **cuántos pisos** (1 a 5), **el alto de cada piso** (40 a 120 celdas, de losa a
losa), **cuánto sobresale el vidrio** (celdas), **las sillas** y **el cuerpo** (abajo). Lo pidió
el usuario el 13/11/2026, para probar configuraciones («tal vez podremos ver una versión de 2x2 o una de 3x3, siempre
manteniendo el aspect ratio de cubo por ahora»).
- **El alto es libre**: pisos por alto de cada uno; la planta, cuadrada. *Hasta el 13/11/2026 la caja era siempre un
  cubo y el alto de un piso salía de repartir el lado.* El panel avisa si un piso queda tan bajo que no se pasa parado.
- **Un solo Guardar** (13/11/2026: «Probar» se sacó, como en todos los paneles de perillas; ver [[meca]]): la escribe en
  `game/consoles/cabin_shape.tres` (no se sube al repositorio), rearma todas las mecas y es la forma de todas, también
  al reiniciar. Abajo, las medidas que salen, también **la altura de la caja sobre el piso**, que no es una perilla: sale
  del largo y lo estirado de las piernas.
- **El ascensor va en celdas sueltas**, no en módulos: su hueco es un cuarto del ancho de adentro menos tres celdas
  (con 4 × 4, los 2 × 2 del medio). Su jaula no pasa de un piso.
- **El ascensor va con dos teclas, en todas las estructuras** (el usuario: «en todos los modos sean dos teclas y que
  simplemente la de subir… cuando es solamente de planta baja no haga nada»): **sube una parada** y **baja una
  parada**. Las paradas: bajado (debajo de la meca), y los pisos, de la planta baja hasta el último con el ascensor
  entre pisos, o sólo la planta baja con las otras (ahí, subir desde la planta baja no hace nada). Teclas: Y / H en el
  panel chico de las filas de la meca, G / X para el que la posee.
- **El afuera sale de reglas**: un tramo de escalera y un balcón por cada piso de arriba; lo largo de un tramo, de la
  altura del piso. Con pisos bajos avisa si queda poca altura libre.
- **La estructura** (pestaña La estructura, 13/11/2026, hecha por la sesión de la Meca: «es como la estructura», no toca
  controles): por dónde se anda y se sube. El usuario: «variantes de la base… las escaleras de atrás… estén metidas
  adentro y que no tengan esas puertas hacia afuera… la primera variante… sin nada y escaleras adentro».
  - **Afuera** (la de siempre): la pasarela, la escalera de atrás y una puerta atrás en cada piso (`MechExterior`).
  - **Adentro** (`MechInsideStairs`): nada afuera y sin puertas; se entra por el ascensor. Un tramo por piso contra la
    pared de atrás, todos subiendo para el mismo lado, uno encima del otro, y un hueco en la losa de arriba de cada uno.
    Barandas donde hay caída: del lado de adentro de cada tramo y en el borde de cada hueco. **Se baja de costado**: las
    barandas dejan abierto el final de cada tramo, del ancho del carril (1,1 m). *Con 3 módulos por lado adentro hay
    5,7 m y un tramo mide 5,67 (la pisada de toda escalera del juego): va de pared a pared y no queda losa en las
    puntas.* Altura libre sobre los escalones: un piso menos la losa y un escalón (2,33 m con pisos de 68 celdas).
  - **Ascensor entre pisos** (`PelvisLift`, 13/11/2026: «el ascensor no solamente va hasta el piso, sino que sirve
    como para subir entre pisos. Y la escalera la eliminamos por completo»): nada afuera, sin puertas y sin escalera.
    El ascensor de la pelvis sube hasta el último piso; cada losa menos el techo tiene el recorte redondo y la baranda
    de la de abajo, con el paso abierto hacia atrás.
  - Las otras variantes que el usuario tiene pensadas (las pasarelas de los costados, con puertas a los costados)
    vienen después.
- **Los asientos**: dos por piso, a los dos lados del medio del frente, en todos los pisos menos la planta baja (con un
  solo piso, en ése).
- **Las sillas**: la **altura de los ojos** que buscan (m sobre el piso; cada uno se nivela a ella con el ajuste de su
  arquetipo, como en character-parametric: `SeatInteractable.eye_height`) y su **distancia al vidrio** (celdas). *Hasta
  el 13/11/2026 iban a 33 celdas de la pared del frente —lo que ocupaba el primer tablero, ya sacado, más el lugar hasta
  la silla—, y con el vidrio que sobresale quedaban a casi 2 m del vidrio («muy retraídas para atrás»).*
- **El cuerpo** (`MechBody.dress`), que **ya no depende de la caja** (el usuario: «prefiero que no dependa tanto de la
  caja… tamaños discretos, chico, mediano, grande»):
  - **Los hombros**: el **piso** (primero, del medio o último) y el **módulo del costado** (adelante, del medio o
    atrás), a la mitad del alto de ese piso y en el medio de ese módulo. El del medio, si no hay uno justo en el medio,
    es el de abajo (pisos) o el de adelante (módulos) de los dos del medio (`CabinGrid.pick`, `CabinGrid.shoulder`).
  - **El largo de los brazos** y **el de las piernas**, por separado: chico, mediano (el de siempre) o grande (0,75, 1
    y 1,25). El de los brazos estira también las posturas y las piñas; el de las piernas, el paso.
  - **El ancho**, uno para brazos y piernas: el grosor de las piezas, las articulaciones, las manos, el puño, los pies,
    las caderas y la pelvis.
  - **Cuánto se estiran las piernas paradas** (de 0,45 a 0,9 del largo de la pierna, de la cadera al tobillo; 0,64 es
    la de siempre): de ahí y de los largos sale la altura de la caja sobre el piso. El tope de arriba deja la rodilla
    doblada: con la pierna derecha la cuenta de la rodilla no tiene para dónde doblar.
  - Las toberas tienen su tamaño propio, el de siempre.
  Test para mirar: `tests/mech_dress_look.tscn` (unos 40 s): cinco combinaciones, de costado y de frente, y las sillas.

## Qué va en cada piso (el caso de 4 jugadores)
- **La planta baja es de servicio**: no tiene asientos ni controles fijos. Ahí van la munición, las baterías y los
  tableros eléctricos (todavía no están), y el **ascensor** ocupa los 2 × 2 módulos del medio: su hueco tiene el radio
  de un módulo menos tres celdas (ver el panel F2).
- **Los dos pisos de arriba tienen dos asientos cada uno**, en los dos módulos del medio del frente (`seat_floors`, `seat`). **No
  tienen tablero adelante**: el primero, un bloque bajo hasta el antepecho, tapaba la vista para abajo y se sacó (el
  usuario, 13/11/2026). Su altura y su fondo quedan en la grilla como **referencia** para ubicar los controles
  (`DESK_CELLS`, `CONSOLE_CELLS`).
- **Las sillas son las de verdad** (las de las consolas, `working_seat.tscn`) y en la meca con brazos se sientan
  **cuatro maniquíes**, para ver la escala de adentro (`MechCabin.seat_dummies`). La caja maciza no choca con el
  cuerpo de las sillas ni con los maniquíes: los empujaba y se volteaba.
- **El frente es una caja de vidrio que sobresale** (`GLASS_OUT_CELLS`, 12 celdas, 47 cm): vidrio al frente, a los
  costados, arriba y abajo, **sin parantes ni marcos**, más transparente. **Todas las losas son iguales**: el metal
  llega hasta la cara de la caja y lo que sigue hasta el vidrio es vidrio que se pisa (el usuario: «quiero que los tres
  estén alineados»). Así **el de más arriba ve para arriba y el de más abajo,
  para abajo**, y los de adentro ven de costado por las caras del vidrio (el usuario, 13/11/2026: «el vidrio se dobla…
  más visión periférica… que también se doble en la parte de arriba y de abajo»; el fondo, chico, «así está igualado a
  los costados y arriba y abajo»). Los costados de la caja llegan hasta su frente. *Antes: el frente plano todo
  vidrio de losa a losa; y antes, una ventana por módulo con antepecho, dintel y parantes.*
- **Atrás**: la puerta de cada piso (28 × 52 celdas), en el medio.
- **El afuera** (la pasarela, los balcones, la escalera) también se mide en celdas. **La escalera de atrás se arma con
  `Stairs`** (la regla del usuario para toda escalera, ver [[escaleras]]): escalones de unos 15 cm con pisada de 8
  celdas (31,5 cm) para los pies y una rampa invisible para la cápsula; 18 escalones por piso, y la escalera, con sus
  dos descansos, va centrada atrás.
- **El marco copia también las escaleras** (`MotionFrame.cast_shadow`): la rampa de la cápsula entra en la sombra de
  siempre y los escalones en una segunda sombra, en la capa Escalones, que ven sólo los pies y el ragdoll. **Falta
  probar subir y bajar caminando con el personaje.**

## Lo que pidió el usuario y falta
- **Los controles principales**, al frente y al centro de lo que ve el que está sentado: moverse, saltar, los
  propulsores, los dashes, agacharse, la compuerta de abajo y los dos brazos.
- **Los tableros siguen a los costados**: se alcanzan girando y, si quedan lejos, parándose. Hay que aprovechar el
  espacio sin tapar la vista vertical del frente (en la nave de character-parametric los tableros la tapaban). Serán
  **módulos nuevos, discretos**, que se ensamblan sobre la grilla.
- **Duda abierta**: con 4 módulos de ancho y sólo dos personas por piso, cada una alcanza nada más que su módulo del
  frente, y lo de los costados queda lejos. Hay que ver si el ancho, la cantidad de asientos o los tableros lo
  resuelven. Los jugadores siempre van con vista al frente.

Test para mirar: `tests/cabin_grid_look.tscn` (unos 10 segundos por forma, sin el sandbox; `--formas=4x3x12,2x2x12`).
Por cada forma: de frente, cortada de costado, desde un asiento y mirando abajo desde el vidrio; escribe las medidas.
El panel: `tests/cabin_shape_check.tscn` (una parcela con la meca, pasa a 2 × 2 y 2 pisos con «Probar»). Caminar adentro y afuera sigue en
`tests/mech_ride_check.tscn`.

## La cabina que viene: redonda, de 4 × 4 y un piso (en diseño, 14/11/2026)

Todavía no está en el código: se está dibujando en 2D y en arcilla, separada de la meca. Lo decidido hasta ahora:

- **La forma:** 4 × 4 módulos de planta (7,56 m por dentro) y un solo piso de 5,04 m (128 celdas). Por fuera, un
  cilindro liso. Por dentro, un polígono regular de 16 caras inscripto en ese cilindro: la diferencia con el círculo
  son 7 cm y queda dentro de la pared.
- **Una sola trama:** 16 zonas iguales de 22,5° y tres anillos alrededor del ascensor (el borde del paso a 2,6 m, el
  de los tableros a 3,1 m y la pared). Cada cosa ocupa zonas enteras y tiene su forma, sin rincones sobrantes ni topes
  (el usuario: «espacios continuos… evitar espacios residuales o topes»).
  - **Adelante:** un tablero corrido de tres zonas, con una división por puesto.
  - **A cada lado:** una zona libre, que es el paso a la escalera.
  - **Después, la escalera:** dos zonas de la banda (45° dan justo un tramo de 1,2 m), siguiendo las caras.
  - **Atrás, la media luna a 1,2 m:** siete zonas. En el frente de las cinco del medio, de cara al ascensor, van los
    cuatro kits de reparación y la batería, cada brazo de su lado. Las zonas de las puntas quedan libres porque ahí
    llega la escalera.
  - **Arriba, en la pared:** la munición, metida de modo que hacia afuera sólo sobresalga el cubo.
- **Los puestos:**
  - **Con cuatro:** tres adelante (el brazo izquierdo, el movimiento y el brazo derecho) y la espalda arriba, en la
    media luna, con los mandos en los apoyabrazos.
  - **Con tres:** falta decidir entre dos adelante y uno arriba, o los tres adelante con el del medio centrado.
  - **Con dos:** los dos adelante, cada uno en su zona, con la zona del medio en el medio. Falta resolver qué va en esa
    zona; se va a ver al hacer los tableros.
- **El ascensor** sigue en el centro, del suelo a la planta, con 1,3 m de radio.

Las plantas y las maquetas son pruebas sueltas: `tests/bridge_ideas_look.tscn`, `tests/crew_cabin_look.tscn` y
`tests/round_cabin_outside_look.tscn` (las de afuera).
