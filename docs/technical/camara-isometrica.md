# La cámara isométrica y las teclas compartidas

`game/iso/`. El cambio de rumbo del 22/11/2026 (el usuario: «todos tienen que poder ver lo mismo… la meca por completo, y
todos tienen que tener acceso a todos los controles»). Vale en **la partida** y en **la fila Cámara isométrica** del
sandbox; el resto del sandbox sigue en primera persona.

## La cámara (`IsoView`, `IsoSettings`, `IsoPanel`)
- Sigue al jugador local, con el mismo ángulo y zoom arriba o abajo de la meca.
- **60° de inclinación, con perspectiva (30° de apertura) y sin giro** (el usuario, 22/11/2026, después de comparar seis
  ángulos): ya no es isométrica en sentido estricto, aunque el código conserva el nombre. Se leen los ataques en el piso
  y se sigue viendo la meca.
- **F1 de su fila**: ortográfica o perspectiva, zoom, inclinación, giro, apertura y corte. «Guardar» aplica. El archivo
  (`game/iso/iso_settings.tres`) es del usuario.
- **Lo que tapa no se dibuja** (sólo para esta cámara): lo que empieza más arriba que el corte, y las paredes entre el
  personaje (o lo que tiene alrededor) y la cámara. Las mecas, los personajes y lo bajo, como las consolas, no se esconden.

## El personaje
- WASD camina **según la pantalla** y el personaje mira hacia donde camina. El mouse no mira ni usa.
- **E** usa lo que está cerca y adelante (`InteractionDetector._iso_pick`): subirse a la meca, las consolas y los botones,
  con su contorno. La meca cuenta entera: el puesto no importa.
- Agarrar, arrojar y mirar arriba y abajo **no están resueltos** en esta cámara: quedan para decidir.

## Las teclas de la meca (`MechCrew`, `MechCrewHud`)
- Yendo arriba: **WASD** la mueve según la pantalla y **las flechas ← →** giran su frente. Las piernas buscan siempre ese
  frente (`BodyLegs.pivot_feet`).
- **Una tecla apretada por dos o más no anda para nadie**. La cuenta la lleva el host y la reparte; lo que resulta se
  escribe en `MechCockpit`, como los tableros.
- **Los cuadrados**: blancos y planos; azul si la tecla anda, rojo si está bloqueada. **Alt** muestra el mouse sin frenar
  el juego (`UIState.peek_mouse`), y pasarlo por un cuadrado dice qué hace.

## Los maniquíes
`MechCabin.dummies_on`, apagado: ni la partida ni el sandbox los sientan. En la fila Meca jaula, la **Y** los prende.

## Cómo se prueba
- `tests/iso_crew_check.tscn`: subirse, mover, bloquear, girar y bajarse.
- `tests/iso_base_look.tscn`: la partida de uno, de la esclusa a la arena, usando la E.
- `tests/iso_net_check.tscn`: el bloqueo con dos instancias (`--host-local` y `--join-local`).
