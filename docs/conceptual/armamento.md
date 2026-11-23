# El armamento de la meca

**Borrador** (14/11/2026), módulo Tableros y controles. Ver [[la-meca]], [[recursos]], [[tripulacion]].

Salió de un brainstorm de 44 ideas. El usuario eligió **pocas para la primera versión** («una versión mínima con dos o
tres alternativas de cada cosa y empezar a probar rápido para ver si funciona o no»). Las que quedaron afuera no se
descartaron: vuelven si hacen falta.

## Cambio de rumbo: habilidades por zonas (22/11/2026)
**Manda sobre lo de abajo.** El usuario: «no es buena práctica que el mecha pueda hacer daño fuera de su zona de visión…
todas las habilidades tienen una hitbox». Se deja «se va por la física» y se toma la alternativa de **ataques discretos,
tipo hechizos**: skillshots en cono, línea o círculo, con alcance, que se ven antes de salir. Sin músculos en los brazos.
**Pendiente:** si hay ataques básicos que peguen seguro y sin energía, con la proximidad como riesgo; y que los ataques del
jefe sigan la misma regla.

## Lo fijo y lo que se cambia
- **La meca en sí sale de su semilla y no se cambia**: los brazos y las piernas cambian un poco de diseño, y eso la hace
  más rápida, más lenta, etc. Es permanente, como un personaje.
- **Los agregados se cambian**: lo que va en la punta de cada brazo, lo montado en el brazo, lo de la espalda, el
  propulsor y la munición.

## La regla de los efectos: universales
**No hay jefes de un elemento al que le convenga una munición** (el usuario: «lo que no quiero es empezar a hacer cosas
tipo, este boss es de tal elemento… quiero que… sean como universales»). Cada cosa tiene su punto fuerte contra
cualquiera, y lo que se elige es **qué usar en qué momento**, no qué equipar antes de salir.

## Los puestos
- **Un puño con un objeto y un arma (15/11/2026, para este experimento):** la meca lleva de un lado el cañón y del otro
  **una mano con una espada** (reemplaza al taladro). El usuario: el cañón se aprende (palanca, inercia, física) y el
  taladro era «apretar un botón o dos»; la espada es «la que más expresión tiene», y en mano, «más antropocéntrico».
  Pensarlo **como hechizos, pero con la física y los controles torpes encima**: modos estocada (se carga), tajo (el
  gesto se dibuja con una palanca y el brazo lo sigue con inercia, llega tarde y se pasa) y guardia. La espada es un
  objeto que la mano agarra: puede soltarla. Paneles en 2D pixelado (grises, pantallas negro y verde), con la forma de
  la iteración 41: tramo arriba, cajas en los parantes, módulos abajo sobre una franja común con la energía.
- **El mouse, sentado (15/11/2026):** la cámara queda trabada al frente y el cursor anda libre por el tablero. **Una
  palanca se agarra manteniendo el clic izquierdo**: el mouse la mueve; al soltar, el cursor vuelve a estar libre y la
  palanca queda donde quedó. **Mientras se la tiene, el clic derecho es el gatillo de su bocha**: en el movimiento,
  saltar (en el aire, levitar); en el cañón, disparar (mantenido carga el súper); en la espada, la estocada (mantenida
  carga). El tajo sale de mover la palanca de la hoja. Se fueron los botones de salto, levitar, gatillo y golpe, y la
  pantalla del gesto (se ve en el vidrio). **Una mano, un control a la vez**: para cambiar de modo hay que soltar.
- **Controles en radio alrededor de la silla, mirados en 3D (15/11/2026, a probar):** como la cabina de Getter Robo de
  las referencias del usuario: brazos con controles y pantallitas alrededor de la silla, la cámara libre con tope (no
  se mira atrás), sólo clic izquierdo. **Agarrar un control que apunta (cañón, espada) hace de la cámara la mira**; el
  brazo la sigue con su resorte. Uno que no apunta (caminar) mueve sólo la palanca, con la cámara quieta.
- **La regla de los ataques, una sola para todos (el usuario, 15/11/2026):** se aprieta el botón del ataque, **se carga
  un tiempo fijo y sale solo**. No depende de agarrar ni de soltar nada: agarrar el control sólo apunta. Cada ataque tiene
  su demora (el súper, más larga), y quien lo maneja no decide cuándo sale: apunta para que, cuando salga, dé.
- **Los modos del cañón, así (el usuario, 15/11/2026; reemplazan a simple, ráfaga, barrido y súper):**
  *Corrección del usuario (15/11/2026): el barrido y el súper se cargan **mientras se los aprieta**: cuanto más, más
  fuerte (un súper a medias o al máximo); por eso sólo esos dos llevan barra. La ráfaga, no.*
  1. **Ráfaga**: tiros seguidos; se prende o se apaga (un botón que se traba) y se apunta agarrando el control.
  2. **Barrido**: se carga; después hay que agarrar el control y moverlo, y dura un tiempo.
  3. **Súper**: se carga; se agarra el control, se apunta y tira una sola vez, muy fuerte.
- **La espada, dos modos (el usuario, 15/11/2026; la guardia se va):**
  1. **Tajo**: se agarra el control y se lo mueve directamente, **con menos sensibilidad** (el `drag_gain` de los
     controles de character-parametric: cuánto mouse lleva un recorrido entero; el mouse se lee como intención).
  2. **Estocada certera**: como el súper del cañón: se aprieta, se carga, se apunta y apuñala.
- **Tres pasajeros, sin espalda (15/11/2026, lo último; manda sobre lo de abajo):** la meca cuadrada tiene tres
  sillas, las tres adelante. **Izquierda, el brazo izquierdo; derecha, el derecho; al medio, el movimiento.** Se fue la
  silla de la tarima. **Las armas de la espalda desaparecen** (la ametralladora y los misiles; el usuario: «desaparecen»).
  Los puestos dejan de ir en un tablero en el piso y pasan a la silla (cómo, sin decidir: el anillo de la maqueta de
  Interior o los módulos de ahora sostenidos por la silla). Lo de abajo sobre la espalda y el reparto queda como historia.
- **Cada brazo es de una persona**: su punta y lo montado en él son una sola unidad que maneja ella.
- **Otra maneja el movimiento y otra, la espalda.**
- **Dónde se sienta cada uno, con cuatro** (14/11/2026, lo definió el usuario con la sesión Interior, para la cabina cuadrada de la meca grande, borrada el
17/11/2026): la
  cabina es de 3 × 3 módulos y un piso alto, con un entrepiso al fondo. **Adelante, a la izquierda, el brazo izquierdo; a
  la derecha, el derecho; al medio, la espalda. Arriba, en el entrepiso, el movimiento** (el usuario, 14/11/2026: el de
  atrás, con las escaleras, se lee con más jerarquía, y el que mueve es el que ve lo global, así que va más lejos del
  vidrio; antes iba al revés). Bajo el entrepiso, a nivel del piso, la carga de munición y el cambio de batería.
- **El reparto por cantidad** (14/11/2026; las tareas de pie —recargar, la batería, los kits— las hace el que se levanta):
  - **Con cuatro**: el movimiento (arriba) con el ascensor y eyectarse; la espalda (adelante, al medio) con sus dos armas
    y el escudo; un jugador por brazo.
  - **Con tres**: el movimiento con el ascensor, eyectarse **y el escudo** (elige entre esquivar y aguantar); cada brazo
    suma un arma de la espalda (el izquierdo la ametralladora, el derecho el lanzamisiles). El usuario: con el
    movimiento cargando también la espalda, los brazos quedaban «medios deshilachados».
  - **Con dos**: **uno adelante, al medio, y el otro atrás** (el usuario, 15/11/2026: ya no los dos adelante con un hueco
    entre medio). El movimiento con el ascensor, eyectarse y el escudo; **el otro, los dos brazos y la espalda**: cuando
    tira un misil deja los brazos, mientras el otro sigue moviendo. *Antes la espalda iba con el que mueve, que tendría
    que dejar de moverse para tirar. La espalda en automático se descartó: le quita expresión.*
- Con menos jugadores, cada uno maneja más cosas, pero más simples; con más, menos cosas, con más libertad.

## Energía y munición: dos dinámicas
**Los brazos gastan energía; la espalda gasta munición** (el usuario, 14/11/2026: «hace que los distintos armamentos
tengan una especie de dinámica distinta»).
- **La munición se gasta y hay que ir a buscarla al mapa.**
- **La energía es la estamina de la meca, una sola para todos**: se gasta, se vacía y se recarga sola. **Coordinarse en
  cómo se usa es la idea básica del juego**: no se pueden hacer muchos dashes y todos los ataques a la vez.
- **Sin energía, la meca queda aturdida un rato.**
- **El máximo baja de a poco con el uso**, como una batería de auto o de celular que pierde capacidad: es el cardio de
  una pelea larga.
- **Cambiar la batería** le devuelve el máximo y además **la llena al instante**: también se usa como estrategia.

## El tablero mínimo: lo que tienen todos los puestos
- **El nivel de la energía** (y su máximo).
- **Un dibujo de la meca en su posición de ese momento**: adentro, sentado, se pierde la noción de cómo está la meca en el
  espacio.

## El movimiento: te conectás (14/11/2026)
*15/11/2026: el usuario lo replanteó para la meca de tres (hoy, la base de la jaula: ver [[meca-jaula]]): sentado, la cámara trabada al frente
y clic en el tablero; una palanca de dos ejes que queda trabada, y el dash, el salto y levitar en botones aparte.*
**El que maneja se conecta** (un casco, unos guantes) y **sus controles de a pie pasan a la meca**: WASD, el mouse,
Shift el dash, y agacharse y saltar con las mismas teclas que a pie. Su cuerpo queda quieto mientras está conectado
(el usuario: «todos los mismos controles que te dan cuando estás a pie, pero en la meca… uno ya los aprende
instintivamente»). Con controles físicos se haría una cosa a la vez y no sería fluido. Cómo se ve, todavía tentativo.
- **Secundarios del puesto**: **el ascensor** y **eyectarse**. Eyectarse no puede estar libre siempre: sería la forma
  rápida de bajar, en vez del ascensor. Abierto: cuándo se habilita.
- **El dibujo de la meca va en una pantalla**, no en un holograma, y **la energía en un tablero inclinado** hacia el que
  va sentado.
- **Descartado**: repartir la energía entre piernas y brazos (el gasto ya lo reparte solo: un ataque fuerte te deja
  sin dash; es la estamina de un juego de a pie), avisar a la tripulación, anclarse, agacharse aparte.

## Las roturas y los recursos (14/11/2026)
**La versión más simple**: se reparan **tres sistemas** (el movimiento y cada brazo), y aparte están **la batería** y
**la munición**.
- **Cada sistema se rompe a medias**: rinde peor siendo **más difícil de manejar o más lento**, no haciendo menos daño
  (con menos daño se lo deja de usar). Que se vea. **Romperse del todo no**: dejaría al que lo maneja sin nada que
  hacer más que arreglarlo.
- **Se repara con un kit de reparación**, un recurso del mapa, **uno por sistema**: se pone en **el módulo de ese
  sistema**, en las paredes de los costados (los brazos y el movimiento). **Sin minijuegos** y sin salir a la fachada.
- **La espalda no se rompe**: ya tiene su límite, la munición, y arreglar algo en el techo no se entiende. Su munición
  también se carga desde un módulo.
- **La batería es de toda la meca**: la energía (ver arriba).
- **Los brazos los elige la tripulación**, iguales o distintos (dos sierras, por ejemplo): no es obligatorio que sean
  distintos. Lo que hay que buscar es que **dos brazos iguales o parecidos se potencien** y no sean dos controles para
  lo mismo.
- **El casco, aparte y también reparable** (14/11/2026): la salud de la meca; por debajo de un nivel, explota. Se
  repara con su kit, como los sistemas. *Cambia lo que decía [[la-meca]] («no hay vida»), como ya lo cambió el jefe bola.*

## Los huecos de la cabina (14/11/2026)
Aparte de los tableros de los puestos y sus secundarios (el ascensor, eyectarse), la cabina tiene **siete huecos de
recursos**, cubos de 63 cm (ver [[recursos]]):
- **Cuatro de reparación**: el casco, el movimiento, el brazo izquierdo y el derecho.
- **Dos de munición**, uno por cada arma de la espalda.
- **Uno de batería**, la de toda la meca.
- **El kit de reparación es uno solo** y sirve en cualquiera de los cuatro huecos de reparación: lo que se decide es
  dónde ponerlo. Es la única excepción a «cada hueco acepta sólo su tipo».
- **Un golpe daña donde pega**: un brazo, ese brazo; las piernas o una caída, el movimiento; la caja, el casco. Nada
  se cuenta dos veces, y cubrirse con un brazo cuida el casco a costa del brazo.

## Los brazos: cómo se manejan (14/11/2026, abierto)
- **Botones discretos para las acciones** (cargar más fuerte, y más habilidades), **y un solo modo que captura el
  mouse: apuntar**. El brazo no se conecta como el movimiento: con controles sueltos no es tedioso.
- **El control es poco y en 2D** (14/11/2026; el usuario: «difícil de controlar algo en 3 dimensiones moviendo un mouse
  en 2»): el mouse elige **adónde** (adónde va la piña, el tiro, lo que se arroja), y el jugador elige **cuándo** y
  **cuánto carga**. Nada de seguir trayectorias o costuras con el mouse. **La habilidad es manejar un brazo físico difícil
  y sincronizarse con los otros.**
- **Un solo tipo de piña**: el daño sale del contacto y del impulso que lleva; con una animación más simple o más
  compleja según la carga. Varias piñas de un mismo puño no tienen gracia.
- **Los ataques tocan el equilibrio y la energía**: además de gastar, pueden desequilibrar a la meca un momento (más
  expuesta) o moverla (el cañón muy fuerte la tira para atrás).
- **Agarrar al jefe y a los jugadores, todavía no**; agarrar objetos del mapa y arrojarlos, quizás para empezar.
- **El orden** (el usuario): primero el brainstorm de armas; después cómo se manejan; recién después los controles de
  las cabinas.
- **El camino que se prueba: un híbrido**. Las acciones son discretas; las ejecuta el brazo con músculos (la inercia, el
  peso; roto, los músculos más flojos: apunta peor). Hoy es demasiado lento: un experimento de la sesión Meca lo hace más
  rápido **sin que deje de sentirse físico**. **Sin topes al impulso que le da a lo suelto** (ya se probó y se
  descartó: «empezamos a pelear con el motor de físicas y nunca termina bien»).

## Las armas de brazo: lo que quedó del segundo brainstorm (14/11/2026)
- **El puño es uno**, con **modificadores**: de resorte (más alcance), cohete (más velocidad), eléctrico. Siguen
  funcionando como un puño.
- **La maza**: reemplaza a la mano.
- **Sierra circular, motosierra y taladro.**
- **La hoja**, con variantes de la misma hoja: caliente, en llamas, eléctrica, con sierra.
- **A distancia, con energía**: el cañón de energía, el rayo, el arco eléctrico y **el lanzallamas** (en el brazo, con
  energía: en la espalda se sentiría peor).
- **Quizás**: la garra, el imán (potencial, pero un gimmick), el gancho con cable (hace lo mismo que el resorte).
- **No**: el martillo neumático (quizás un puño neumático, más adelante), la lanza retráctil.
- **Cada tipo ataca con su animación**: una espada no pega como un puño.
- **Los brazos no se cubren**: eso lo hace el escudo (abajo).

## El escudo de fuerza (14/11/2026)
**Uno solo, global**: un campo semitransparente que envuelve a toda la meca y se prende de a momentos. **Depende del
timing**: prenderlo **gasta un golpe de energía**, y mantenerlo gasta un poco más por cada segundo.
- *Descartado*: cubrirse apuntando un brazo (muy finicky, y ningún brazo cubre todas las zonas); escudos por zonas o
  parry por zonas (desde adentro de la cabina no se lee si un misil va al torso o al brazo).
- **El parry**: prendido justo antes del impacto, el golpe de energía del arranque es menor o no se cobra. Así no castiga
  tanto.
- **Lo maneja quien ve lo global**: la espalda con cuatro, el movimiento con tres y con dos.
- **Cambió el 18/11/2026: el escudo es un brazo** (ver [[meca-jaula]], `ShieldTip`): un escudo físico que lleva un brazo
  en lugar de un arma, y frena lo que viene de frente. Se mantienen el timing, el golpe de energía al levantarlo y el
  parry; se abandonan «global» y «lo maneja el que ve lo global». El usuario descartó cómo se veía el campo global en
  todas sus formas, y prefirió el canje: «si querés tener un escudo vas a tener un arma menos».

## El puesto: holograma, botones y estado (15/11/2026)
**Reemplaza a los paneles que se traen** (abajo). Probado el primero, el usuario: «no es el camino este». Cada silla
tiene **módulos fijos**, que no van atados a la silla, y se arma con los que le tocan:
- **El holograma, adelante**, sube desde el tablero del frente. **Es uno solo y es la mira**: un vidrio de luz entre el
  sentado y el parabrisas, con la mira dibujada encima. Lo que muestra cambia según el sistema elegido (el alcance del
  brazo, lo que está a tiro, la carga, la munición de la espalda).
- **Los botones, a los costados**, en paneles inclinados hacia el sentado: un módulo más rectangular. Cambian **qué**
  maneja el holograma y **cómo** (el modo); todo lo que no sea mover el mouse y hacer clic.
- **La pantalla de estado**, un módulo más cúbico: **el estado de todos los subsistemas de esa silla juntos**, para no
  tener que cambiar de sistema para ver cómo está cada uno. La del movimiento muestra el estado general de la meca: el
  casco, el movimiento y los dos brazos, la energía y su máximo, y la meca en contorno con su inclinación.
- **Cómo se usa**: sentado, el mouse para los costados gira el cuerpo entero sobre la silla, y para arriba o abajo
  inclina la cabeza y un poco la columna. **Mirar un botón y hacer clic lo aprieta; mirar el holograma y hacer clic toma
  el control** (el mouse apunta); **E lo suelta**. **El clic derecho es el escudo**, apuntando o no: el parry es reflejo
  y no se puede soltar la mira para ir a buscar un botón.
- **Los casos**:
  - **El puño**: el holograma muestra el alcance y resalta lo que está a tiro; mantener el clic carga. **Un solo tipo de
    piña** (el agachado y dónde pega ya hacen de uppercut); a lo sumo, la piña fuerte con otra animación.
  - **El agarre**: los objetos agarrables, en otro color en el holograma; se resaltan al mirarlos si están a tiro.
  - **El cañón de energía, con modos en botones**: tiros cortos y rayo que barre se sostienen con el clic (cuánto se
    aprieta no carga); **el súper tiro sí carga**. Es el que mejor encaja con los botones.
  - **La espalda**: un botón elige entre las dos armas; la munición se ve en el holograma. **El misil guiado como en
    Half-Life**: se sigue mirando por el holograma y el misil va adonde apunta la mira.
  - **Con dos jugadores**, el que tiene los dos brazos y la espalda elige con botones qué maneja el holograma: es el caso
    que más justifica el sistema.
  - **El movimiento**, aparte: es el único que mueve su silla arriba y abajo (la meca mira para arriba o para abajo),
    así que su silla acepta esa inclinación. Después.
- **Iteración 2** (15/11/2026; el usuario: iterar sobre la disposición 1, una sola maqueta, `tests/seat_station_look`):
  - **La energía está en todos los hologramas, siempre**: se calcula antes de cada acción.
  - **Módulos parejos**: un cubo (más grande, 28 cm) y rectángulos de su mismo ancho y fondo y la mitad de alto.
  - **Eyectar es un rectángulo bajo el cubo de estado**, con el botón al frente. *En el apoyabrazos, no*: los brazos
    van apoyados en reposo, y apretarlo se vería raro.
  - **De taller, no futurista**: chapa pintada, botones de baquelita, lamparitas. El holograma sigue siendo holograma.
  - **La letra del juego** (`StrokeFont`, copiada de character-parametric) en todo lo escrito.
- **Botones extra, sólo el ascensor** (en la silla del movimiento). **Eyectarse lo tienen todos, bajo un vidrio.**
  *Descartados*: el gatillo de la batería, el selector de munición, el cambio de herramienta, la flecha al enemigo en la
  pantalla de estado, la sierra con botón de encendido (una sierra con el brazo retraído no tiene sentido), arrojar el
  disco (ir a buscarlo complica; que se recargue invita al abuso), y que el holograma de un brazo roto titile: alcanza
  con que el brazo tenga menos fuerza, y su estado se ve en la pantalla de estado.

## Los brazos: la mano de base y una herramienta (15/11/2026)
**Cada brazo tiene la mano de base** (empujar, arrojar cosas) **y una herramienta** (sierra, taladro, hoja, cañón,
garra…). **Las herramientas no se repiten**: la tienda vende un solo ejemplar de cada una y la tripulación elige en qué
brazo va (lo de la tienda es de [[progresion]]). La sierra sola era monotemática: el que la manejaba se aburría.

## La progresión: física, con la alternativa anotada (15/11/2026)
**Se va por la física**: la progresión está en la habilidad, en qué tan bien se pelea y en los cosméticos; **cada
herramienta es una forma distinta de jugar**. La variedad va hacia los costados: herramientas distintas, una de cada
una, la meca por semilla, los enemigos y las arenas. Mejoras, a lo sumo chicas y que cambien la física (un puño más
pesado pega más pero llega más lento), en un rango corto para no volver a pelear con el motor. El «especial» de cada
herramienta sale del uso (la carga, el taladro que se clava si se sostiene), no de un botón de habilidad.

**La alternativa, por si se pivotea** (el usuario: «deja anotada la alternativa por si en un futuro quiero pivotear»):
- **Mejoras por arma**: cada herramienta sube de nivel. Aprovecha que no es contra jugadores sino contra máquinas.
- **Ataques discretos, tipo hechizos**: muchas variantes de cada arma con ataques propios (el taladro común y un súper
  taladro que arma un aura alrededor). Da más progresión y más horas, y se vuelve más estratégico, pero deja de ser
  físico. Los roles se pisan (el daño en área de los brazos le quita lugar al artillero) y la coordinación pasa a ser
  manejar tiempos de recarga. **Mezclar los dos, no**: el hechizo siempre convendría más y la física quedaría de adorno.

## Los paneles de la silla (14/11/2026, reemplazado)
*Reemplazado por el puesto con holograma y botones (arriba); queda como registro de lo probado.*
Los brazos y la espalda **no se manejan agarrando controles de un tablero** (como en character-parametric: mirar el
volante, agarrarlo y levantar la vista al parabrisas). **Se manejan con paneles que se traen**:
- **Clic en un panel lo abre** delante del que está sentado y le toma el mouse; **Escape lo cierra**. Sin teclas para
  cambiar de brazo ni la ruedita.
- **Los paneles están en una zona fija adelante**, no pegados a la silla: si el sentado se da vuelta a mirar la cabina,
  no lo persiguen ni le tapan la vista. Pueden seguir un poco la vista, con poca sensibilidad.
- **Con un panel abierto se mira al frente**, adonde va el brazo; la vista apenas acompaña (con tope), nunca termina
  mirando para el otro lado.
- **Cómo son**: un brazo articulado y, al medio, un cristal (con marco o sin bordes) donde se ve, superpuesta, la
  información de ese sistema: la carga, las balas, lo caliente.
- **Botones discretos** para cosas como cambiar el modo de un brazo, o teclas reservadas como las del movimiento.
- **La espalda también tiene su física**: el mega misil que tira la meca para atrás, el misil guiado que se lleva con el
  mouse.
- **El movimiento** quizás no sea un panel: otro sabor (la silla misma, el casco). Abierto.
- *Se pierde* que alguien de pie te toque los controles.

## La base mínima para empezar (14/11/2026)
**Un arma por puesto**, y sobre eso se diseñan los tableros, **de a uno** (el usuario: «prefiero empezar de a uno»),
empezando por el del movimiento.
- **Brazo izquierdo**: la sierra.
- **Brazo derecho**: el puño, con un cañón de energía.
- **La espalda**: una ametralladora y un lanzamisiles. **La ametralladora pasa a la espalda**: los brazos son sólo de
  energía (láser y cosas así), y lo de munición va atrás.
- **El movimiento**: sólo andar, girar y los dashes.
- **Todos los tableros** llevan el nivel de energía y **la meca dibujada en 3D, sólo su contorno** (el holograma de líneas
  de la ciencia ficción).

## Primera versión
**La punta del brazo** (es la mano, o la reemplaza):
1. **Puño**: pega y **agarra** (un poste, un auto, un jugador para subirlo). La mano que agarra es el mismo puño.
2. **Puño de resorte**: la muñeca se estira y pega de lejos.
3. **Sierra circular**: corta seguido mientras está apoyada. No agarra.
4. **Taladro**: tarda en entrar, pero atraviesa la guardia. No agarra.

**Montado en el brazo** (la mano sigue estando):
5. **Cañón de muñeca**: un tiro fuerte y lento.
6. **Ametralladora de antebrazo**: muchos tiros flojos.

**La espalda**:
7. **Láser que barre**: una línea que se mueve despacio y corta una zona.
8. **Misil guiado**: uno solo que se va llevando con el mouse, como el lanzacohetes de Half-Life.
9. **Cañón pesado**: de largo alcance y recto, con un retroceso que empuja a la propia meca.
10. **Salva de misiles**: muchos chicos que caen repartidos en una zona.

**Los efectos de la munición**:
11. **Impacto**: empuja.
12. **Eléctrico**: aturde. El jefe deja lo que estaba haciendo.
13. **Zona que queda**: un lugar que hace daño mientras se está adentro.

**El propulsor**:
14. **De dashes**: dashea más fácil.
15. **De dashes y planeo**: el mismo, mejorado. Además deja planear en el aire, bajando de a poco para buscar otro
    ángulo.

## La munición elige el efecto
**El arma dice cómo sale el tiro y la munición, qué hace.** Los tipos de munición se consiguen en el mapa (los raros,
más difíciles) y se carga el que conviene en ese momento. Encaja con los cubos de [[recursos]]: la caja de munición
que se trae dice su tipo.

## Abierto
- **Apuntar un brazo**: los brazos atacan con movimientos predefinidos, que el jugador no mueve directamente. Hace falta
  una interfaz para decirles adónde.
- **El misil guiado**: la interfaz para llevarlo.
- **Qué armas usan munición con efecto**, y cuáles no (¿el láser va con batería?).
- **De quién es la espalda.**
- **Con qué empezar a probar.**
