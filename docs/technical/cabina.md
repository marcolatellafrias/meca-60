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
- **La caja es un cubo**: 204 celdas de ancho, de fondo y de alto, **8,03 m** (`CabinGrid.SIZE`). `cube_ok()` lo
  comprueba. **La caja física de la meca es esa**: `Mech.SIZE` es `CabinGrid.SIZE` (lo aceptó el módulo Meca el
  13/11/2026).

## Qué va en cada piso (el caso de 4 jugadores)
- **La planta baja es de servicio**: no tiene asientos ni controles fijos. Ahí van la munición, las baterías y los
  tableros eléctricos (todavía no están), y el **ascensor** ocupa los 2 × 2 módulos del medio: su hueco tiene el radio
  de un módulo menos tres celdas.
- **Los dos pisos de arriba tienen dos asientos cada uno**, en los dos módulos del medio del frente (`SEATS`). **No
  tienen tablero adelante**: el primero, un bloque bajo hasta el antepecho, tapaba la vista para abajo y se sacó (el
  usuario, 13/11/2026). Su altura y su fondo quedan en la grilla como **referencia** para ubicar los controles
  (`DESK_CELLS`, `CONSOLE_CELLS`).
- **El frente es todo vidrio**, de losa a losa: lo único que lo corta son los pisos (el usuario: «toda vidriada por
  ahora… con las divisiones propias de los pisos»). Los parantes, uno en cada línea entre módulos, son de quita y pon
  (`FRONT_POSTS`): falta elegir.
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

Test para mirar: `tests/cabin_grid_look.tscn` (unos 10 segundos, sin el sandbox). Muestra la meca cortada de costado
con las líneas de los módulos, desde arriba y de frente, y escribe las medidas. Caminar adentro y afuera sigue en
`tests/mech_ride_check.tscn`.
