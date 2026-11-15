# Los dos paradigmas de la meca

**Borrador** (15/11/2026, el usuario, después de probar el disco abierto con vórtice). Ver [[la-meca]], [[tripulacion]],
[[armamento]].

## La premisa, en los dos
La fantasía de la meca: **todos los jugadores manejan una parte y todos dependen de todos**, porque la meca es demasiado
compleja para uno. La colaboración es inevitable. Cualquier camino tiene que mantener esa imagen: que se vea y se sienta
una meca.

**Los dos, totalmente discretos (cinemáticos), sin física por ahora**: la física genera muchas situaciones raras y
difíciles de controlar, sumadas a la complejidad propia del juego. Discretos, se pueden probar más cosas con menos
problemas.

Se desarrollan **en paralelo**, una sesión por camino.

## 1. El disco abierto (la Meca del vórtice): el límite es físico
Es la meca de dos pisos sin techo (`VortexCabin`, la fila «Meca del vórtice»), sin sillas: los jugadores se mueven
libres por el disco y usan los controles directo, con clic y arrastre, más torpes y «físicos», como en la nave de
character-parametric.
- **Lo difícil está en el cuerpo y el lugar**: para usar un control hay que estar mirándolo, y entonces no se ve el
  horizonte; otro tiene que decirte cuándo apretar. No chocarse, dividirse bien las tareas, organizarse en el momento.
  Es todo muy emergente.
- **La energía** no deja hacer todas las acciones a la vez: más coordinación.
- **Todos pueden hacer todo**: no hay tiempos muertos («mi brazo no sirve contra este jefe, me quedo esperando»).
- **Las armas montadas se desenchufan y se enchufan en otro lado**; los brazos, que son el ataque principal, tienen que
  estar bien orientados para pegar.
- **El problema**: la fantasía de la meca se pierde un poco (abierta y cilíndrica, no parece tanto una meca), y no se
  desenvuelve tanto para pelear contra jefes. Puede servir más para **otro tipo de juego**: oleadas de monstruos
  (swarm) u objetivos (por ejemplo, llevar algo con los brazos de un lado a otro). Habría que probarlo contra un jefe.
- **Lo abierto**: si se mantienen algunos límites físicos (para caminar en el disco), cómo se piensan.
- Las ideas de la forma del piso de arriba (zonas de tableros, el borde más alto atrás): `tests/vortex_ideas_look`.
- Subir: por ahora el vórtice. Que una mecánica básica no dependa de un truco.

## 2. Las cabinas separadas: el límite es la información y la estrategia
Cada jugador **se mete en su cabina** (con una tecla, sin caminar adentro) y maneja todo con mouse y teclado. Los
jugadores no se ven entre sí, pero **ven todos el mismo lugar, el mismo enemigo**. Lo que los une: **hablarse por voz** y
**sistemas en común** (la energía; quizás el calor).
- **Los puestos tienen que ser fundamentalmente distintos**, para que nunca haya uno esperando sin hacer nada: el brazo
  izquierdo distinto del derecho, los cohetes distintos de los dos; el movimiento ya es distinto de por sí.
- **La estrategia**: qué ataque o qué «poder» usa cada uno y cómo; distintas formas de atacar y de gastar la energía;
  quizás un sistema de calor. Como es discreto y sin física, la complejidad entra por ahí.
- **Las piernas se mueven aparte del torso**: depender de que el de las piernas mire para un lado para poder disparar
  es muy molesto. Que la dependencia del movimiento sea circunstancial, no un sistema. Pero no del todo independientes:
  no puede haber piernas corriendo hacia adelante con el torso girado 180°; hay que ver los límites.
- **Afuera**: las baterías y los repuestos pasan al exterior de la meca. **Se borran las pasarelas.**
- Probablemente se presta más para **pelear contra jefes**.
- Las maquetas de donde sale: `tests/four_cabins_look`, `tests/cabin_pods_look` (cabinas de a uno, sentados, como
  elementos del cuerpo; la de la meca normal, la 1, es la que más se parece).

## Lo que queda de lo anterior
La cabina cuadrada de un piso con escaleras, sillas y ascensor (`SquareCabin`, [[cabina]]) y la redonda siguen en el
sandbox; ninguna de las dos es uno de estos caminos.
