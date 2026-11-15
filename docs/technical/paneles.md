# Los paneles de la silla

`game/consoles/seat_panels.gd` (`SeatPanels`), `seat_strip.gd` (`SeatStrip`) · módulo **Tableros y controles** · el
diseño, en [[armamento]] («Los paneles de la silla») · ver [[cabina]]

**El primer caso jugable** (14/11/2026): un panel, el del brazo derecho, en la primera silla de la derecha de la cabina,
y la tira que tienen todos los puestos.

## Cómo se usa
- **Sentado en esa silla, mirando el panel** (plegado a la derecha, sobre su brazo articulado), se ilumina y pide la E.
- **E lo abre**: viene adelante de los ojos y **toma el mouse**. El mouse mueve una mira por la vista del frente (la
  cabeza no se mueve); **clic izquierdo, una piña hacia la mira**. **E lo cierra.** No es Escape porque Escape abre la
  pausa.
- **La tira**, fija adelante y abajo: la energía (vacía: todavía no existe) y la meca en contorno, de frente y de
  costado, inclinada como está.

## Cómo está hecho
- Todo cuelga de la cabina, en una **zona fija delante de la silla**, no de la silla. Sin choques: sólo se ve.
- **A quién le hace caso**: a la cámara que está a los ojos de esa silla, con alguien sentado. Sirve igual para el
  jugador sentado o para un maniquí poseído (ver [[poseer]]).
- **El mouse y la E le llegan antes que al jugador**: un nodo al final de la raíz (`_InputCatcher`), porque `_input` va
  de atrás para adelante. Sólo se queda con la E si el panel está abierto o mirado, y con el mouse si está abierto.
- **La piña**: `MechArm.punch_at(punto)` (de la sesión Meca): un directo hacia el punto, recortado a lo que alcanza. El punto es
  lo primero que encuentra el rayo de la mira (sin la meca), o un punto a 18 m.
- **Se arma con** `SeatPanels.attach(cabin)`, que la cabina llama en `seat_dummies` (sólo la meca con brazos); esa silla
  queda sin maniquí, para sentarse con E (lo hizo la sesión Interior).

Test para mirar: `tests/seat_panels_look.tscn` (unos 12 s, sin el sandbox; sienta un maniquí en la silla): plegado, mirado, abierto con la mira, la
piña desde adentro y desde afuera.

## Falta
- Que la cabeza acompañe un poco a la mira (con poca sensibilidad y tope).
- Mantener para cargar; la energía.
