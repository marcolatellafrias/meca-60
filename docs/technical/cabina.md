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
losa) y **cuánto sobresale el vidrio** (celdas). Lo pidió
el usuario el 13/11/2026, para probar configuraciones («tal vez podremos ver una versión de 2x2 o una de 3x3, siempre
manteniendo el aspect ratio de cubo por ahora»).
- **El alto es libre**: pisos por alto de cada uno; la planta, cuadrada. *Hasta el 13/11/2026 la caja era siempre un
  cubo y el alto de un piso salía de repartir el lado.* El panel avisa si un piso queda tan bajo que no se pasa parado.
- **Probar** rearma todas las mecas con esa forma, sin guardar; **Guardar** la escribe en
  `game/consoles/cabin_shape.tres` (no se sube al repositorio) y es la forma de todas las mecas, también al reiniciar.
- **El ascensor va en celdas sueltas**, no en módulos: su hueco es un cuarto del ancho de adentro menos tres celdas
  (con 4 × 4, los 2 × 2 del medio). Su jaula no pasa de un piso.
- **El afuera sale de reglas**: un tramo de escalera y un balcón por cada piso de arriba; lo largo de un tramo, de la
  altura del piso. Con pisos bajos avisa si queda poca altura libre.
- **Los asientos**: dos por piso, a los dos lados del medio del frente, en todos los pisos menos la planta baja (con un
  solo piso, en ése).
- **Las piernas y los brazos van en proporción a la caja** (el usuario: «si achico el cubo de 4x4 a 2x2, se achicarían a
  la mitad los brazos y las piernas»): un solo factor, el lado de la caja sobre el de siempre (8,03 m), en
  `MechBody.scale_to`. Escala las medidas del cuerpo (cintura, caderas, muslos, canillas, grosor, pies, brazos), las
  posturas y las piñas de los brazos, las manos, el puño, el hombro, las toberas, el ascensor bajado y, de las perillas
  (BodySettings), la altura, el paso y lo que sube el pie. Lo demás (velocidades, salto, fuerzas, la masa) no cambia.
  Lo pidió el usuario al módulo Interior el 13/11/2026; el código es del módulo Meca. *El botón de cada perilla del F1
  vuelve al valor del código, que es el de la caja de siempre.*

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
