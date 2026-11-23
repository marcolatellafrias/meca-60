# La cámara isométrica y las teclas compartidas

`game/iso/`. El cambio de rumbo del 22/11/2026 (el usuario: «todos tienen que poder ver lo mismo… la meca por completo, y
todos tienen que tener acceso a todos los controles»). Vale en **la partida** y en **la fila Cámara isométrica** del
sandbox; el resto del sandbox sigue en primera persona.

## La cámara (`IsoView`, `IsoSettings`, `IsoPanel`)
- Sigue al jugador local, con el mismo ángulo y zoom arriba o abajo de la meca.
- **60° de inclinación, con perspectiva (30° de apertura)** (el usuario, 22/11/2026, después de comparar seis ángulos): ya
  no es isométrica en sentido estricto, aunque el código conserva el nombre. Se leen los ataques en el piso y se sigue
  viendo la meca. **Girada 180°**, para que las consolas de la base den de frente.
- **F1 de su fila**: ortográfica o perspectiva, zoom, inclinación, giro y apertura. «Guardar» aplica. El archivo
  (`game/iso/iso_settings.tres`) es del usuario.
- **La cámara no esconde nada** (22/11/2026; el usuario pidió eliminarlo porque distraía): el mapa se diseña para no tapar
  desde este ángulo (ver [[sucursal]]).

## El personaje
- WASD camina **según la pantalla** y el personaje **mira al mouse**, cada uno por su lado (22/11/2026). A pie el cursor
  se ve y no sale de la ventana; arriba de la meca se esconde, salvo con Alt. El clic todavía no hace nada.
- **E o clic izquierdo** (el clic, sólo a pie) usan lo que está cerca y adelante, o sea hacia donde apunta el mouse
  (`InteractionDetector._iso_pick`): subirse a la meca, las consolas y los botones, con su contorno. La meca cuenta
  entera: el puesto no importa.
- Agarrar, arrojar y mirar arriba y abajo **no están resueltos** en esta cámara: quedan para decidir.

## Sin aceleración (22/11/2026)
El personaje (`time_to_top`, en cada arquetipo) y la meca jaula (`start_time` y `stop_time`, en `cage_moves.tres`) van en
0: arrancan y frenan al instante. Ninguno tiene sprint; el personaje siempre va a su velocidad máxima, de 3,6 a 8 m/s
según el cuerpo, y la meca a 7 m/s. **Efecto conocido:** el retroceso horizontal de un golpe al personaje frena al mismo
ritmo, así que hoy se corta en el acto.

## Las teclas de la meca (`MechCrew`, `MechCrewHud`)
- Yendo arriba: **WASD** la mueve según la pantalla y **las flechas ← →** giran su frente. Las piernas buscan siempre ese
  frente (`BodyLegs.pivot_feet`).
- **← → giran parejo**, sin resorte ni inercia (`KinematicMover.key_turn`, a la velocidad de giro del F1).
- **Por zonas del teclado** (22/11/2026): la izquierda maneja (WASD, Shift), **Z** y **X** son los brazos, **C** los
  misiles, **V** el escudo y **Espacio** la ametralladora; ← → giran el frente. **Ningún ataque usa el clic.**
- **Una tecla apretada por dos o más no anda para nadie**. La cuenta la lleva el host y la reparte; lo que resulta se
  escribe en `MechCockpit`, como los tableros.
- **Los cuadrados**: blancos y planos; azul si la tecla anda, rojo si está bloqueada. **Alt** muestra el mouse sin frenar
  el juego (`UIState.peek_mouse`), y pasarlo por un cuadrado dice qué hace.

## Los ataques (22/11/2026)
- **SON ZONAS** (`MechSkills`; ver [[armamento]]): mientras se mantiene la tecla, la zona se dibuja en azul en el piso, sólo para quien la usa; al salir
  pega a lo que esté adentro. **Los brazos (Z, X) van siempre al frente del torso, sin apuntar** (22/11/2026: girar con el
  mouse quedaba raro en el torso; quizás vuelva). La ametralladora, el misil y el escudo siguen al mouse. Con los valores de arranque: puño, cono de 90° y 6,4 m; palo, línea de 6 m;
  taladro y sierra, cono de 3,5 m; cañón, línea de 9 m (a fondo, 14); ametralladora, línea de 1 m de ancho desde su torreta, hasta el círculo de 14 m; misil, se guía
  0,45 s, vuela hasta 14 m y explota en 3 m de radio.
- **Un solo alcance** (F4, pestaña Zonas, «ALCANCE DE TODAS»): los largos y anchos son partes de ese número. No sigue al
  zoom solo, para que la cámara no cambie el balance; el panel dice cuánto se ve con la cámara de ahora.
- **El escudo (V, boceto):** un arco de luz; el mouse elige de qué lado frena (60° a cada lado). **Dos costos, como maná** (F3,
  pestaña Escudo): 12 al activarlo y 20 por segundo al mantenerlo. Sin energía se corta, con su zona, y hay que volver a
  apretar. El parry que devolvía el costo queda apagado. Sin hacer todavía (idea del usuario): que se active con un delay.
- **En la base hay Shift (ráfaga) y Ctrl (sobrevuelo)**, para probar todo; cada contrato de prueba después pone lo suyo.
- **Z** el brazo izquierdo y **X** el derecho, cada uno según lo que lleva: un puño o el palo pegan una vez por apretada,
  el cañón dispara mientras se mantiene, lo que gira carga y pega al soltar, y el escudo se levanta mientras se mantiene.
- **Espacio** la ametralladora (mantener: primero toman vuelta los caños) y **C** un misil por apretada. Están a los
  costados de **las tres versiones** de la meca (`MechGuns`), siempre horizontales.
- **El mouse las encamina, sin clic** (`MechAim`): apretando una de las dos, o con un misil propio volando, el mouse mueve
  un cuadrado en el piso, relativo a la meca. La ametralladora gira sola hacia él (120°/s, hasta 120° a cada lado) y al
  soltarla vuelve al frente. Cada misil sale al frente y dobla hacia la mira de quien lo lanzó; frena para doblar, así un
  blanco cerca y al costado no le queda adentro de la curva. Perillas: pestaña **Puntería** del F4. Prueba:
  `tests/mech_guide_check.tscn`.
- **Mantener carga, soltar ataca** (puño, palo y cañón), con una barrita arriba de su cuadrado. El puño pega más fuerte y
  más lento hasta su tope (`CageHandling`); un toque es el golpe normal. El cañón gasta energía mientras carga y **nunca
  corta la carga** (`CannonTip.overcharge`); un toque es el tiro simple.
- **La regla de la energía** (`MechEnergy`; el usuario, 22/11/2026): **en cero, sólo no hay energía**: lo que la gasta no
  anda, y se sigue caminando y disparando lo de munición. **En negativo, stun**: sólo se llega cargando el cañón de más, la
  deuda se ve en rojo y el stun (1,2 s) viene al disparar. En la pestaña Energía del F3: prenderlo o apagarlo, cuánto dura
  y si también frena la ametralladora y los misiles.
- **La ametralladora se calienta** mientras dispara (barrita arriba de Espacio): llena, se traba hasta enfriarse. El tiempo
  que tardan en girar los caños no se muestra.
- **La munición**, en una etiqueta gris dentro de Espacio y C (no es una tecla): dice cuántas quedan y, recargando, se llenan hacia arriba. Vacías, se
  recargan solas.
- **Con batería negativa no se empieza otra carga**: primero hay que volver a cero.
- **La batería** (F3, pestaña Energía): capacidad (arranca en 100) y recarga por segundo (14). Los costos son absolutos
  (un súper a fondo, 36; una ráfaga, 20), así que una batería más grande rinde más. La idea del usuario, para probar: más
  capacidad y recarga más lenta, como el maná, para que valga la pena ir a buscar baterías.
- **El retroceso** (F3, pestaña Retroceso; `KinematicMover.add_recoil`): el cañón sale siempre horizontal y empuja la meca
  hacia atrás (3 m a fondo, 0,5 m de un toque), sin quitarle el control, así que un propulsor al frente lo contrarresta.
  La ametralladora disparando hace avanzar un 35 % menos hacia el frente del torso.
- **Para hablar con el usuario, sin hacer:** munición finita.
- **El artillero quedó sólo con su silla.** La torreta, el yugo, sus tableros, la recarga con ritmo y las seis habilidades
  están en el commit `5238ff8`.
- Prueba: `tests/mech_attacks_check.tscn`.

## Los golpes (`game/combat/`; 22/11/2026)
- **Fichas** (`HitCard`, `HitSettings`; F4 de la partida): cada arma dice daño, quiebre y empuje. Lo cargado las escala.
- **Blancos planos** (`HitTarget`): un círculo en el piso. Las formas (línea, círculo, cono) lo tocan sin importar la
  altura del tiro. El cañón pega con el ancho que se ve; el misil explota en un círculo de 4 m.
- **La ametralladora es una sola zona**: un cono desde el centro del torso (45 m, ±4°), hacia donde esté girada, que da
  10 pulsos por segundo al primer blanco a la vista. Las balas sólo se ven y terminan en él. Las armas de los costados
  convergen a la línea del centro.
- **La bolsa**: número de daño (los pulsos se suman), barra de aguante y una hamaca con tope; la física ya no decide nada.
  El empuje sólo ocurre al romperle el aguante, y menos cuanto más pesa.
- **El jefe** ya se toca con estas formas, pero su daño sigue saliendo del impulso de siempre: falta pasarlo a las fichas.
- Las piñas siguen detectando con la esfera que barre la mano. Prueba: `tests/hit_system_check.tscn`.

## El dash (`MechDash`, `DashSettings`; 22/11/2026)
- **Con el estilo «las dos»** (el contrato de prueba `mixto`): **Shift** la ráfaga y **Ctrl** el sobrevuelo; la ráfaga
  también sale en medio del sobrevuelo. El cuadrado de Ctrl sólo se ve en ese estilo.
- **Shift**, hacia donde camina; sin caminar no sale. La energía se ve en una barra junto a los cuadrados, roja si la meca
  quedó aturdida.
- **F3 de la partida** (`BaseDashPanel`): el estilo y sus números. «Guardar» lo aplica en todas las máquinas.
- **Ráfaga**: una apretada, casi instantánea y sin teletransportar (7 m en 0,1 s). Gasta de una vez y tiene espera.
- **Propulsor**: mientras se mantiene va a 14 m/s y gasta energía; al soltar o al llegar a cero, se acaba.
- **Con o sin inercia**, en los dos: con inercia frena hasta caminar; sin ella, corta en seco.
- **La ráfaga puede ser intocable** un rato desde que arranca (`burst_untouchable`; 0, nunca): para el experimento de
  esquivar por tiempo, ver [[experimentos]].
- **F5 de la partida**: el panel del jefe, para ajustar los experimentos.
- Sin hacer todavía (ideas del usuario): más daño al pegar propulsándose y contrarrestar un retroceso con el propulsor.
- Prueba: `tests/mech_dash_check.tscn`; el video, `tests/mech_dash_movie.tscn`.

## Los maniquíes
`MechCabin.dummies_on`, apagado: ni la partida ni el sandbox los sientan. En la fila Meca jaula, la **Y** los prende.

## Cómo se prueba
- `tests/iso_crew_check.tscn`: subirse, mover, bloquear, girar y bajarse.
- `tests/iso_base_look.tscn`: la partida de uno, de la esclusa a la arena, usando la E.
- `tests/iso_net_check.tscn`: el bloqueo con dos instancias (`--host-local` y `--join-local`).

## El zoom según dónde estés (22/11/2026)
Arriba de la meca se ve más (`MatchSettings.zoom_aboard`, 29) que a pie (`zoom_foot`, 22), con un paso suave. Se cambia en el F6 de la partida. Por debajo de 16 no cambia nada: la cámara ya está en su distancia mínima (`IsoView.MIN_AWAY`). En el sandbox sigue valiendo el zoom de su panel.

## Los cursores de la tripulación (22/11/2026)
Arriba de la meca se ven los cursores de los demás que tengan el mouse a la vista (`MechCursors`), con su nombre y un color que es el mismo en todas las máquinas. No viaja el píxel sino lo que señala: el punto del tablero de cuadrados o el punto del piso relativo a la meca. Con teclas el mouse está capturado, así que sólo se comparte mientras se mantiene Alt.

## La salud y la energía, arriba (22/11/2026)
En la partida toda la tripulación ve, también a pie, **la salud arriba a la izquierda y la energía arriba a la derecha** (`MechStatusBars`). Antes de la pelea la meca todavía no tiene vida, así que su barra se ve llena.

La barra de energía baja al instante y atrás queda un tramo ámbar con lo gastado: espera 0,45 s y después se achica. Lo que se gasta de a poco, como el escudo o el sobrevuelo, no lo vuelve a frenar.

## Quién ve las zonas (22/11/2026)
La zona en el piso de una habilidad de la meca la ve **sólo quien la está usando y sólo mientras la usa** (`MechAim._preview`): mantener un brazo, tener tomada un arma o tener prendido el escudo. El destello de la zona al pegar una piña también es sólo de quien la tiró. Lo demás sigue a la vista de todos: los tiros, las explosiones y el arco del escudo.
