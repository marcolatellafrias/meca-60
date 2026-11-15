# Los puestos de adelante

`game/consoles/seat_station.gd` (`SeatStation`) · módulo **Tableros y controles** · el diseño, en [[armamento]] («El
puesto: holograma, botones y estado») · ver [[cabina]]

**Todavía de arcilla** (15/11/2026): se ven en la meca, pero nada funciona. Reemplazan al primer panel jugable, el que
se traía con E y tomaba el mouse para tirar una piña (`SeatPanels`, borrado: el usuario, al probarlo, «no es el camino
este»).

## Qué hay en cada puesto
Va en el hueco del tablero de cada puesto de adelante abierto (`CabinGrid.OPEN_POSTS`), mirando a su silla:
- **Al medio, el holograma**, que sube de una ranura del tablero. Es la mira, con **la energía siempre** a la izquierda
  (con la raya del máximo que le queda) y el nombre del sistema. Naranja, no celeste: menos futurista.
- **A los costados, módulos parejos**: un cubo de 28 cm (`CUBE`) y rectángulos de su ancho y fondo y la mitad de alto
  (`SLAB`), contra los costados del hueco (`CabinGrid.hole_cells`) y girados hacia la silla.
  - **A la izquierda**: eyectar (un rectángulo, el hongo rojo al frente bajo una tapa de vidrio) y encima **el cubo de
    estado** (una pantalla de fósforo con la meca de frente; la parte rota, punteada).
  - **A la derecha**: los botones de baquelita, con una lamparita sobre el elegido.
  - **Todo lo que se usa va en la cara que mira a la silla**; las otras, vacías.
- **Lo que maneja cada puesto** (`SeatStation.SYSTEMS`, en el orden de `MechCabin.POSTS`): el brazo izquierdo (piña,
  agarre, sierra), la espalda (ametralladora, misiles) y el brazo derecho (piña, agarre, cañón).
- **De taller**: chapa pintada, baquelita, lamparitas. Lo escrito, con la letra del juego (`StrokeFont`, copiada de
  character-parametric).
- **Las pantallas se dibujan una sola vez** (`UPDATE_ONCE`): no cambian, y seis pantallas no cuestan cada cuadro.

## Cómo se arma
`SeatStation.attach(cabin)`, que la cabina llama en `seat_dummies` (sólo la meca con brazos). La silla del brazo
derecho queda sin maniquí, para sentarse con E y ver la escala.

Test para mirar: `tests/seat_station_look.tscn` (unos 10 s, sin el sandbox): sentado en la silla del brazo derecho, por
encima del hombro con un maniquí sentado, y los tres puestos desde atrás.

## Lo que falta
Que funcione: tomar el control mirando el holograma y haciendo clic (E lo suelta), apretar los botones mirándolos, el
clic derecho como escudo, la energía y el estado de verdad. El puesto del movimiento, con su silla que se inclina.
