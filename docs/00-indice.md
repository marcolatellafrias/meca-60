# Meca — índice

Juego cooperativo de **1 a 3 jugadores** que manejan **una meca gigante desde adentro**, cada uno desde su puesto,
contra **mecas enemigas** que maneja la computadora. Los personajes y la meca tienen **una sola vida**: si se pierden,
se pierden para siempre. Hecho en Godot 4.5 con Jolt. Todo es tentativo: lo abierto está marcado en cada nota.

## El loop
1. En **la base subterránea** se elige un **contrato**: qué meca enemiga matar. Más riesgo, más paga.
2. Un **elevador** sube la meca a la arena, y se pelea. A veces se suma **otra tripulación**, que ayuda… o traiciona.
3. Hay cuatro finales: **ganar**; **escapar** con la meca rota y sin plata; **eyectarse** antes de que explote y escapar a
   pie; o **morir todos**.
4. Un cartel dice cómo les fue, y se vuelve a la base: mejorar, reparar y practicar.

El detalle, en [[partida]].

## Conceptual (el diseño)
| Nota | Qué tiene |
|---|---|
| [[partida]] | El loop, los cuatro finales, la traición y el fuego amigo. |
| [[tripulacion]] | **De 1 a 3 jugadores** (límite de diseño: la vista de cada puesto); personajes de una sola vida, por semilla; la billetera (abierta). |
| [[dos-paradigmas]] | **Los dos caminos de hoy**: el disco abierto (límite físico, todos hacen todo) y las cabinas separadas (límite de información y estrategia), los dos discretos. |
| [[la-meca]] | La meca como diseño: equilibrio y no estadísticas, una versión por cantidad de jugadores, una sola vida, eyectarse, los dos caminos. |
| [[contratos]] | Las mecas enemigas (dificultad y paga, arquetipos con partes y afijos) y la otra tripulación. |
| [[base]] | La compañía bajo tierra: contratos, mejoras, práctica, reparación (abierta), carga. |
| [[progresion]] | Lo que pasa entre partidas: la plata como lo único continuo, qué vuelve de la arena, el acorazado, la meca nueva, el capitán, los tres puestos de compra. |
| [[interfaz]] | La interfaz: el lenguaje común (una letra, un acento, los botones, el marco), los íconos en pixel art y qué tiene cada estación. |
| [[recursos]] | Los cubos de 63 cm (batería, componente, munición, bomba) y cómo se van a enchufar. |
| [[armamento]] | Las armas y agregados de la primera versión (puntas de brazo, montadas, espalda, propulsores), los efectos universales y la munición que los elige. |

## Técnico (el código de hoy)
| Nota | Qué tiene |
|---|---|
| [[estructura]] | **Cómo está armado el código**: la meca y sus piezas, los brazos, lo traído. La meca grande se borró el 17/11/2026 (está en el commit `0bcaeaf`). |
| [[meca-jaula]] | **La meca, la jaula de las maquetas** (la única desde el 17/11/2026): chica, cinemática con brazos físicos (el cañón en lugar del antebrazo, el palo en el puño pesado), tres cabinas, la energía común, sus teclas, su propio F1 de moverse, la de práctica. |
| [[tableros]] | **Las caras con tablero**: la grilla de 4 cm en cada cara que puede llevar controles (`FaceBoard`), las piezas de character-parametric sobre su base, en la meca jaula. |
| [[brazo]] | Los brazos: lo que se les pide, el físico con músculos y el discreto, y lo que llevan en la punta (el cañón de energía, el taladro, el palo). |
| [[base-comun]] | Lo que comparten la meca propia y los jefes (`BalanceBody`), el motor discreto (`KinematicMover`), los paneles de perillas y el resto en piezas. |
| [[pendulo]] | El modelo de equilibrio físico: el torso es un péndulo y los pies lo siguen (hoy, el de la meca de práctica). |
| [[cuerpo-por-piezas]] | La regla común (acordada, sin hacer): motor del torso discreto o físico, brazos y dibujo, por separado. |
| [[maquetas-jefes]] | Jefes de arcilla, quietos: seis siluetas de jefe humanoide, seis con personalidad (la misma base de cuatro patas, dos brazos con armas distintas y un accesorio en el techo, normales y con ira), dos recorribles (seis y cuatro patas, con pasarelas y baterías detrás de compuertas) y una primera tanda de seis. |
| [[luchador]] | El jefe humanoide: el Luchador sobre orugas. Paso 1: cómo se mueve (orugas con rampas, la cintura aparte, la arena), el horno con la puerta para arriba (el punto débil) y la ira con humo negro. Paso 2: la cabeza, que te rodea y te embiste (abre el horno antes; contra el borde se estrella). |
| [[poderes-jefes]] | Los poderes de los jefes: cada ataque es un poder que se tilda en el panel, con sus pocas variantes y lo que pide del cuerpo; la escala de todos los jefes en una perilla. El plan: piezas que se combinan, fases y el cuerpo modular. |
| [[pelea-jefes]] | Lo común de la pelea con los jefes: la vida por código, las barras y la arena (un círculo del que el jefe no sale); y lo que se aprendió con el jefe bola, borrado el 15/11/2026. |
| [[proyectiles]] | Los proyectiles por red y las zonas que pegan. |
| [[mapa]] | El mapa de pelea: una arena circular con barrios, escaleras y recursos en el borde. |
| [[sucursal]] | La base en el sandbox: el plano 6 en arcilla (elevador, gimnasio, consolas, casilleros). |
| [[escaleras]] | La regla de toda escalera (`Stairs`). |
| [[pixel-art]] | Pintar con píxeles (experimento), cara por cara. |
| [[sandbox]] | **Las buenas prácticas del sandbox**: supercategorías, filas, panel chico o panel F, teclas reservadas. |
| [[filas]] | Cada fila del sandbox y su código (qué borrar si se borra una parcela). |
| [[poseer]] | La O posee lo que mirás, la T cambia la vista. |
| [[red]] | El multijugador. |
| [[personajes-traidos]] | Lo traído de character-parametric: el jugador, agarrar, sentarse. |
| [[analisis-personaje]] | Qué de lo traído necesita la meca y qué no. |

*El 17/11/2026 se borraron, con la meca grande, las notas de la meca péndulo (`meca`), la meca cinemática, el
laboratorio cinemático, la Meca de tres, la meca de cápsulas, la cabina cuadrada (`cabina`), la redonda, los puestos de
adelante (`paneles`) y el cubo de la línea de equilibrio (`cubo`, `cubo-con-piernas`): están en el commit `0bcaeaf`. Lo
que de ellas sigue vivo pasó a [[meca-jaula]], [[brazo]] y [[base-comun]].*

## Organización
- [[modulos]] — **quién es dueño de qué**: las sesiones por módulo, sus carpetas y por dónde se tocan.

## Las reglas de la documentación
- **Conceptual** es el diseño del juego, en `docs/conceptual/`. **Técnico** es cómo está hecho hoy, en
  `docs/technical/`. Una nota nueva va en una de las dos y se anota en esta tabla.
- **Un cambio a un sistema actualiza su nota.** Si un cambio contradice una nota conceptual, se avisa antes.
- **Borrar una parcela borra su código**: su arquetipo, lo que sólo ella usa, sus paneles, sus perillas, sus tests y su
  fila en [[filas]]. Nada queda huérfano.
