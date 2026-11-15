# Los puestos de adelante

`game/consoles/seat_station.gd` (`SeatStation`) · módulo **Tableros y controles** · el diseño, en [[armamento]] («El
puesto: holograma, botones y estado») · ver [[cabina]]

**Todavía de arcilla** (15/11/2026): se ven en la meca, pero nada funciona. Reemplazan al primer panel jugable, el que
se traía con E y tomaba el mouse para tirar una piña (`SeatPanels`, borrado: el usuario, al probarlo, «no es el camino
este»).

## Qué hay en cada puesto
**Lo lleva la silla** (15/11/2026: sin tablero en el piso; «los puestos van derechos… no vamos a hacer nada raro por
ahora»): una repisa recta delante de las rodillas, sobre un pie al fondo, hija de la silla. Todo mira al frente:
- **Al medio, el holograma**, que sube de una ranura de la repisa. Es la mira, con **la energía siempre** a la izquierda
  (con la raya del máximo que le queda) y el nombre del sistema. Naranja, no celeste: menos futurista.
- **A los costados, módulos parejos**: un cubo de 28 cm (`CUBE`) y rectángulos de su ancho y fondo y la mitad de alto
  (`SLAB`), a cada lado del holograma, derechos.
  - **A la izquierda**: eyectar (un rectángulo, el hongo rojo al frente bajo una tapa de vidrio) y encima **el cubo de
    estado** (una pantalla de fósforo con la meca de frente; la parte rota, punteada).
  - **A la derecha**: los botones de baquelita, con una lamparita sobre el elegido.
  - **Todo lo que se usa va en la cara que mira a la silla**; las otras, vacías.
- **Lo que maneja cada puesto** (`SeatStation.SYSTEMS`, de izquierda a derecha): el brazo izquierdo (piña, agarre,
  sierra), el movimiento al medio (el ascensor; su estado, la meca entera) y el brazo derecho (piña, agarre, cañón).
  Las armas de la espalda se fueron.
- **De taller**: chapa pintada, baquelita, lamparitas. Lo escrito, con la letra del juego (`StrokeFont`, copiada de
  character-parametric).
- **Las pantallas se dibujan una sola vez** (`UPDATE_ONCE`): no cambian, y seis pantallas no cuestan cada cuadro.

## Cómo se arma
`SeatStation.attach(cabin)` pone un puesto en cada una de las tres primeras sillas; la cabina lo llama en `_stations`
(desde `seat_dummies`, sólo la meca con brazos; la cuadrada, de la sesión Interior). La silla del brazo
derecho queda sin maniquí, para sentarse con E y ver la escala.

Test para mirar: `tests/seat_station_look.tscn` (unos 10 s, sin el sandbox): sentado en la silla del brazo derecho, por
encima del hombro con un maniquí sentado, y los tres puestos desde atrás.

## Lo que falta
Que funcione: tomar el control mirando el holograma y haciendo clic (E lo suelta), apretar los botones mirándolos, el
clic derecho como escudo, la energía y el estado de verdad. El puesto del movimiento, con su silla que se inclina.
