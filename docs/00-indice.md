# Meca — índice

Juego cooperativo de **1 a 4 jugadores** que manejan **una meca gigante desde adentro**, cada uno desde su puesto,
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
| [[tripulacion]] | Cuántos jugadores; personajes de una sola vida, por semilla; la billetera (abierta). |
| [[dos-paradigmas]] | **Los dos caminos de hoy**: el disco abierto (límite físico, todos hacen todo) y las cabinas separadas (límite de información y estrategia), los dos discretos. |
| [[la-meca]] | La meca como diseño: equilibrio y no estadísticas, una versión por cantidad de jugadores, una sola vida, eyectarse, los dos caminos. |
| [[contratos]] | Las mecas enemigas (dificultad y paga, arquetipos con partes y afijos) y la otra tripulación. |
| [[base]] | La compañía bajo tierra: contratos, mejoras, práctica, reparación (abierta), carga. |
| [[progresion]] | Lo que pasa entre partidas: la plata como lo único continuo, qué vuelve de la arena, el acorazado, la meca nueva, el capitán, los tres puestos de compra. |
| [[recursos]] | Los cubos de 63 cm (batería, componente, munición, bomba) y cómo se van a enchufar. |
| [[armamento]] | Las armas y agregados de la primera versión (puntas de brazo, montadas, espalda, propulsores), los efectos universales y la munición que los elige. |

## Técnico (el código de hoy)
| Nota | Qué tiene |
|---|---|
| [[estructura]] | **Cómo está armado el código**: la meca y sus piezas, los dos caminos, lo congelado, lo traído. |
| [[meca]] | La meca péndulo: la caja con tres pisos, correr, agacharse, saltar y volar, y los dos caminos. |
| [[pendulo]] | El modelo de equilibrio: el torso es un péndulo y los pies lo siguen. |
| [[meca-cinematica]] | La meca de siempre movida a mano, y la regla de adentro: todo como si la meca estuviera quieta. |
| [[laboratorio-cinematico]] | El experimento del cubo cinemático contra cajas sueltas: cuatro formas de tratar lo suelto, medidas. |
| [[base-comun]] | Lo que comparten la meca propia y los jefes (`BalanceBody`), y el resto en piezas. |
| [[cuerpo-por-piezas]] | La regla común (acordada, sin hacer): motor del torso discreto o físico, brazos y dibujo, por separado. |
| [[meca-de-tres]] | **La meca de ejemplo**: la cabina de tres, el cañón de energía de cuatro modos, el taladro, la energía común y las placas, manejados poseyéndola. |
| [[meca-jaula]] | **La jaula de las maquetas, hecha meca**: chica, cinemática con brazos físicos (el cañón en lugar del antebrazo, el palo en el puño pesado), tres cabinas, su propio F1 de moverse. |
| [[meca-de-capsulas]] | **La meca sin interior**: el torso macizo con una cápsula empotrada por puesto, el radial de cápsulas y hombros, la forma en el F2. |
| [[brazo]] | Los brazos: lo que se les pide, el físico con músculos y el discreto. |
| [[cabina]] | La cabina sobre su grilla (módulo Interior): celdas, módulos, pisos y asientos. |
| [[paneles]] | Los puestos de adelante (módulo Tableros y controles): el holograma con la mira y la energía, los botones, eyectar y el cubo de estado; todavía de arcilla. |
| [[maquetas-jefes]] | Jefes de arcilla, quietos: seis siluetas de jefe humanoide, seis con personalidad (la misma base de cuatro patas, dos brazos con armas distintas y un accesorio en el techo, normales y con ira), dos recorribles (seis y cuatro patas, con pasarelas y baterías detrás de compuertas) y una primera tanda de seis. |
| [[luchador]] | El jefe humanoide: el Luchador sobre orugas. Paso 1: cómo se mueve (orugas con rampas, la cintura aparte, la arena), el horno con la puerta para arriba (el punto débil) y la ira con humo negro. Paso 2: la cabeza, que te rodea y te embiste (abre el horno antes; contra el borde se estrella). |
| [[pelea-jefes]] | Lo común de la pelea con los jefes: la vida por código, las barras y la arena (un círculo del que el jefe no sale); y lo que se aprendió con el jefe bola, borrado el 15/11/2026. |
| [[proyectiles]] | Los proyectiles por red y la arena de esquivar. |
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
| [[cubo]] · [[cubo-con-piernas]] | La otra variante de equilibrio (la línea), archivada. |

## Organización
- [[modulos]] — **quién es dueño de qué**: las sesiones por módulo, sus carpetas y por dónde se tocan.

## Las reglas de la documentación
- **Conceptual** es el diseño del juego, en `docs/conceptual/`. **Técnico** es cómo está hecho hoy, en
  `docs/technical/`. Una nota nueva va en una de las dos y se anota en esta tabla.
- **Un cambio a un sistema actualiza su nota.** Si un cambio contradice una nota conceptual, se avisa antes.
- **Borrar una parcela borra su código**: su arquetipo, lo que sólo ella usa, sus paneles, sus perillas, sus tests y su
  fila en [[filas]]. Nada queda huérfano.
