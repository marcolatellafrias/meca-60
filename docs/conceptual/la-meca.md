# La meca (diseño)

**Borrador** (13/11/2026). Cómo está hecha hoy, en [[meca-jaula]], [[pendulo]] y [[brazo]] (desde el 17/11/2026, una sola meca, la jaula, a
escala humana; la meca grande se borró). Ver [[partida]].

## Qué es
Una meca gigante **manejada desde adentro**: cada jugador opera una parte desde su puesto (piernas, brazos…). Cuando
algo se rompe, hay que reacomodarse, salir afuera a reparar o ir a buscar recursos (ver [[recursos]]).

## Ya decidido
- **Todo es equilibrio, no estadísticas**: no hay vida. Una piña la saca de arriba de sus pies, y puede caerse.
- **Hay una versión por cantidad de jugadores, de 1 a 3** (ver [[tripulacion]]), como la nave de
  character-parametric. **Depende del host** de la partida. Los tres puestos van **apilados y centrados**, y cada uno
  ve bien (17/11/2026):
  - **Para uno**: sólo **la cápsula de adentro**, la de abajo, sin el puesto de arriba ni la torreta; las armas del
    artillero, si las tiene, en otro lugar.
  - **Para dos**: la cápsula y **el anillo de arriba** (el pozo con el tablero inclinado).
  - **Para tres**: además, **la torreta del artillero** arriba de todo.

  **Cuanto más repartidas están las armas, más control hay sobre cada pieza**; con menos jugadores, cada sistema se
  simplifica para que lo maneje una persona (los modos, abajo). Se ajusta probando.
- **La escala es la chica**, la de la meca jaula (17/11/2026).

## Los controles: tres botones y los modos
Lo decidió el usuario el 17/11/2026, tentativo hasta probarlo:
- **E** para subirse a la meca y para bajarse.
- **Clic izquierdo** interactúa: aprieta un botón, mueve una palanca.
- **Clic derecho mantenido** agarra un componente para usarlo: la mirada va al frente con una transición y **queda
  libre**, y el **clic izquierdo** lo usa (disparar, atacar). Sirve para manejar los brazos desde abajo: **el torso
  persigue la mirada con un resorte**, no 1:1 (el usuario: «que la cámara sea libre y que lo que se limita sea qué tanto
  se mueve el torso yendo a ese target… se siente responsive y pesado»). *Primero se pensó con la cámara trabada.*
- **La ruedita del mouse** no se usa por ahora (los componentes de character-parametric la leen; queda).
- **Los modos, para jugar solo**: un modo en el que se entra y del que se sale. Adentro, captura el teclado y los dos
  clics para ese sistema (caminar con WASD y un brazo en cada clic); afuera, se mira libre el puesto y se tocan otras
  cosas. Así cada sistema baja su complejidad para uno, sin volverse un shooter común: los sistemas siguen siendo
  varios, y muchos pasan al teclado. **El primero, hecho (18/11/2026): el manejo de la meca de 1**, todo al teclado (el
  usuario: «todo el teclado»). Con un clic en su manubrio se entra y queda trabado; la E lo suelta. Ver [[meca-jaula]].

## Los controles para 3 (17/11/2026, hechos; el código en [[tableros]])
- **Abajo, en la cápsula: los dos brazos y el torso.** Un mando por brazo: **el cañón** (tres botones eligen ráfaga,
  barrido o súper; el clic izquierdo dispara, barre o carga) y **el puño** (cuanto más se mantiene, más lenta y más
  fuerte la piña). Agarrando cualquiera, el torso sigue la mirada. Dos pantallas: la energía y la carga.
- **Arriba, en el pozo: la locomoción.** Dos palancas de palo negro y punta roja: **el acelerador** (cuánto) y **la de
  dirección** (hacia dónde; queda donde se la deja). Saltar, levitar —con la pantalla del propulsor, que se gasta y se
  recarga— y **el dash, un botón**, hacia donde apunta la de dirección. **Agachar**: en el aire, baja rápido (un dash
  hacia abajo).
- **El escudo es un brazo**, el del de abajo, si lo lleva: el canje es un arma menos. Se levanta con el mando de ese
  brazo y frena lo que viene de frente. Ver [[meca-jaula]].
- **Atrás, el artillero**: lo lleva la sesión de las armas, con la artillería.

## Para 2 y para 1 (18/11/2026, hechos)
- **De a 2**: lo mismo, sin la torre del artillero.
- **De a 1**: sólo la cápsula, y todo al teclado en el modo manejo (WASD, los dos clics para los brazos, espacio,
  Shift, Ctrl, Q para el escudo si un brazo lo lleva, 1 a 3 para los modos del cañón).

## Cómo se muestra un objeto en un puesto
Dos formas (17/11/2026; el código, en [[tableros]]):
1. **En una cara**, sobre su grilla: cada cara que puede llevar tablero —las no triangulares de la cápsula, el tablero
   inclinado y la pared del pozo de arriba— tiene la suya.
2. **En la punta de un brazo de dos articulaciones**, que sale de una celda de la grilla o de otro lado (el piso del
   artillero). **Fijo**, quieto en su pose, o **plegable**: se trae cuando se usa ese componente y se pliega con él
   cuando no. Hechos los dos en la jaula: los mandos de los brazos, plegables; las pantallas, fijas.

## Lo que se va a probar, en parcelas aparte
En orden (el usuario: «estos experimentos los haría separados, así vemos bien las cosas, y después le agregamos a la
meca»):
1. La grilla en las caras y los controles de verdad: **hecho y pasado a la meca jaula**, ver [[tableros]].
2. El brazo de dos articulaciones: **el plegable, hecho** (el más simple, con el mando de palo; se trae con el clic
   derecho mantenido y la mirada se va adelante), ver [[tableros]]. **El fijo, también** (las pantallas de la cápsula).
3. La zona del artillero: un disco chato (quizás hexagonal) del que salen brazos con lo suyo, que se pliegan si tapan.
4. **Las dos formas del torso**, a elegir jugando: la **cuadrada** de hoy (la cápsula adentro y el bloque de arriba;
   girar el torso gira también el puesto de arriba) y la **redonda** (el cuerpo como una esfera chanfleada con la
   cápsula más chica al medio y arriba el octógono extruido, que puede girar aparte o no). Primeras maquetas en arcilla,
   las dos para 1, 2 y 3, sobre las piernas y los brazos de la jaula: `tests/torso_shapes_look`.
   **Un solo idioma para las dos cápsulas** (17/11/2026, el usuario: «son como dos esferas distintas»): o todo cubo
   chanfleado (arriba, el tazón de la misma cápsula: cuatro cuadrados inclinados de tablero y cuatro triángulos), o todo
   en anillos de ocho planos (la cápsula de abajo hecha como el pozo de arriba). Con las dos cápsulas del mismo tamaño,
   el cuerpo redondo a la medida de la cápsula calza en las dos caras. Maquetas: `tests/capsule_language_look`.
   **Por ahora** (el usuario, 17/11/2026): la cuadrada como está, y la redonda con el cuerpo y la cápsula de cubo
   chanfleado (la cápsula alargada de hoy) y arriba el octógono con el pozo de ocho tableros inclinados (lo que más lugar
   da para controles); el cuerpo es el pegamento: se agranda o se le cambia el chanfle para que los módulos encajen.
   Las formas de encajar: `tests/round_torso_fit_look`. *Más adelante, quizás, arriba el tazón de cuatro cuadrados.*
5. Manejarla de a 1, de a 2 y de a 3: **hecho** (arriba), falta probarlo jugando.
6. Atrás, la batería y el hueco de recursos, pasados a la grilla (hoy van a mano; sin apuro).
- **Una sola vida, como los personajes**: si se rompe del todo, se pierde para siempre. La siguiente sale **distinta**:
  otras armas, otros controles por defecto, otras características (velocidad, energía y lo que se defina).
- **Avisa antes de explotar** y da tiempo para **eyectarse** (ver [[partida]], los finales).
- **Dos caminos** para los brazos, todavía abiertos: **discretos** (contra mecas enemigas, con zonas que esquivar y
  proyectiles; el más probable) y **físicos** (que chocan, se traban y ceden).

## Abierto
- Las roturas: qué se rompe y cómo se ve.
- La energía, los misiles y los ataques.
- La reparación (ver [[base]]).
- Qué cambia exactamente de una meca a la siguiente.
