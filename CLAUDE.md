# Meca 60

**Este proyecto es un duplicado independiente de `D:\Godot\meca`** (22/11/2026), hecho para la cámara de 60° y para
simplificar con libertad. No comparte archivos ni GitHub con aquél: nunca leer, escribir ni lanzar nada de esa carpeta.
**Se simplifica de a poco y con el usuario**: los resortes y lo vertical que sirven como animación se quedan hasta que
él decida.

Juego cooperativo de **1 a 3 jugadores** que manejan **una meca a escala humana desde adentro** —la **meca jaula**—
contra **mecas enemigas** (los jefes, que maneja la computadora) en una arena. Cada jugador maneja una parte desde su
puesto, y los tres van apilados y centrados: **abajo la cápsula del que maneja**, **arriba el pozo del de los brazos** y
**atrás la torre del artillero** (para uno, sólo la cápsula; para dos, la cápsula y el pozo). Cuando algo se rompe hay
que reacomodarse, salir afuera a reparar o ir a buscar recursos. Entre peleas, la sucursal: contratos, reparaciones con
plata y cargar la meca. Hecho en **Godot 4.5** (GDScript), física con **Jolt**. Empezado el 11/11/2026; hoy es un
**boceto para probar la idea**, de a uno.

Varias piezas vienen de `D:\Godot\taxi` (el sandbox, las opciones, el lanzador de ventana), que a su vez las trajo de
`D:\Godot\character-parametric`. Y de character-parametric directo, **el personaje, agarrar, sentarse y la red** (con la
pausa y el menú de inicio de allá; el jugador es el personaje de allá) y, el 17/11/2026, **los controles** (botón,
palanca, perilla, volante, la inercia, la red de los controles). Qué se trajo y qué se adaptó, en
`docs/technical/personajes-traidos.md` y `docs/technical/tableros.md`.

*Hasta el 17/11/2026 había una meca grande (de 14 m, con cinco cabinas, la arena de esquivar y el laboratorio
cinemático): se borró entera (el usuario: «limitarnos solamente a un approach de meca a una escala más humana»); está en
el commit `0bcaeaf`.*

**Cambio de rumbo (22/11/2026):** la partida pasa a **cámara isométrica**, todos ven la meca entera y pueden tocar todas
sus teclas, y una tecla apretada por dos se bloquea. Donde lo de abajo hable de puestos, primera persona o mouse, vale
[docs/technical/camara-isometrica.md](docs/technical/camara-isometrica.md). **Las decisiones de diseño las toma el
usuario: preguntar antes y no agregar nada que no pidió.**

## La documentación: `docs/`
Una bóveda de Obsidian, separada en **conceptual** (`docs/conceptual/`: el diseño del juego —el loop, la tripulación, la
meca, los contratos, la base—, tentativo) y **técnico** (`docs/technical/`: cómo está hecho hoy, una nota por sistema y
**una nota con cada fila del sandbox y su código**, [docs/technical/filas.md](docs/technical/filas.md)). **Empezar por
[docs/00-indice.md](docs/00-indice.md)**: el pitch, el loop y la tabla de qué hay en cada nota. **Antes de cambiar una
feature, leer su nota conceptual y la técnica**; si el cambio contradice el diseño, avisar antes. Un cambio a un sistema
actualiza su nota.

**Borrar una parcela borra su código**: su arquetipo, lo que sólo ella usa, sus paneles, sus perillas, sus tests y su
fila en `docs/technical/filas.md` (lo pidió el usuario el 12/11/2026: «me gusta que si borro algo, una parcela, que borra el código
también»). Nada queda huérfano.

## Decisiones tomadas
- **De 1 a 3 jugadores, una sola meca** (17/11/2026): la meca jaula. Más de tres puestos no dejan ver bien; cada puesto
  ve, y van apilados y centrados (ver docs/conceptual/la-meca.md y tripulacion.md).
- **Dos torsos** para la misma meca, a elegir en su F2: **la cuadrada** (la caja de hoy) y **la redonda** (el cuerpo
  de cubo chanfleado como pegamento, con la misma cápsula abajo y el octógono del pozo arriba, que más adelante puede
  girar aparte). Comparten la cápsula, el pozo, la torre, los tableros, los brazos y las piernas.
- **Los controles son de tres botones**: **E** subir y bajar; **clic izquierdo** interactuar; **clic derecho mantenido**
  el modo de un control (la mano va a él, la mirada se va sola adonde se lo maneja). Para jugar solo, más adelante,
  modos que capturan el teclado. Ver docs/conceptual/la-meca.md.
- **Los tableros van en las caras, en una grilla de 4 cm** (`FaceBoard`), y cada pieza sobre su base de exactamente
  sus celdas (`FaceMount`), como la nave de character-parametric; lo que lleva tableros se mide en celdas enteras. Lo
  otro que se muestra va en la punta de un brazo de dos articulaciones (`FoldingArm`). Ver docs/technical/tableros.md.
- **Los brazos de la meca, uno por uno**: cada brazo elige ser discreto (`PoseArm`, se dibuja en su pose) o físico
  (`MuscleArm`, músculos que persiguen la pose) y qué lleva en la punta (puño, puño pesado, palo, taladro, sierra,
  cañón; ver docs/technical/brazo.md). Lo que se le pide a un brazo está una sola vez, en `MechArm`.
- **El cuerpo con equilibrio es la base común de la meca y los jefes** (`BalanceBody`, ver docs/technical/base-comun.md):
  la jaula se mueve cinemática (`KinematicMover`) y la de práctica con el péndulo físico.
- **Toda escalera se arma con `Stairs`** (13/11/2026; ver docs/technical/escaleras.md).
- **El cuerpo de la meca se define una sola vez** (`MechBody`: medidas, piernas, brazos). Sin cabeza.
- Los jefes: **pocos arquetipos hechos a mano**, con **las partes por semilla**, **partes que se rompen** y **afijos**
  encima.
- Entre peleas: la sucursal como oficina, los contratos, los arreglos que cuestan plata y cargar la meca (con espacio
  limitado, sin sistema de peso).

## Cómo se prueba hoy
**El jugador es el personaje de character-parametric**: arranca como ente (sin cuerpo, movimiento directo, **V** o la
**B** corta vuelan) y la **B** larga lo vuelve cuerpo (el gordo atlético: se cae, agarra con el clic izquierdo, se sienta con la **E**, empuja con
la **R**). Sus teclas son las de allá (WASD, espacio, Ctrl, shift, E, R, V); Escape la pausa, que no frena el mundo;
**Tab oculta toda la pantalla**. Las teclas **F** son de los **paneles** (TunerPanel): de parcela y de fila F1–F7,
globales F9–F12. **Antes de agregar una fila, una tecla o un panel, leé `docs/technical/sandbox.md`** (las reglas se
chequean al arrancar).

**Poseer** (`SandboxPossession`): **mirando** la meca, la **O** la posee (las teclas pasan a ella y el jugador se apaga
donde está); **O** otra vez la suelta, y **se acuerda**: **O** sin mirar nada la retoma. Poseyendo, la **T** pasa por
tres vistas: **libre**, **tercera persona** y **primera persona**. Un cartel abajo a la derecha dice qué se posee, la
vista y **sus controles**. Se puede poseer lo que está en el grupo `possessable`.

**La fila Meca jaula** (`CageMech`, `CageCabin`; ver docs/technical/meca-jaula.md): la meca, la de práctica adelante y
cajas para tirarles. **E** sobre la meca sienta en el primer puesto libre (manejo, brazos, artillero; 1–3 cambia);
**U** sube a la cubierta; adentro se camina. Paneles: **F1** cómo se mueve, **F2** su forma (los dos torsos), **F3**
los brazos, **F4** las piernas, **F5** lo que lleva cada brazo, **F6** las poses (temporal). **L** muestra la grilla de
los tableros.

**Las parcelas tienen paredes invisibles** (`SandboxParcel`): las ve lo que se mueve con física y vive en una parcela;
el jugador y la bola pasan.

Más filas: **Recursos** (los cubos de 63 cm, ver docs/conceptual/recursos.md), **Personajes** y **Locomoción** (ver
docs/technical/personajes-traidos.md), **Multijugador** (la red de allá: **H** abre sesión en esta compu y otra
instancia se une con **J**, **G** abre por Steam, **K** va al menú de inicio, **L** sale), **Partículas**, **Píxeles**,
el **Mapa de pelea**, la **Base** (la sucursal) y los **jefes** (el **Luchador de orugas** y las maquetas). Por la red
van los personajes y los objetos de esa parcela; **la meca todavía no**.

## Dónde va cada cosa
**El proyecto se trabaja en módulos, una sesión por módulo, en la misma carpeta y rama**: qué es de quién y por dónde
se tocan, en [docs/modulos.md](docs/modulos.md). Tocar sólo lo propio; commitear sólo los archivos propios.

Por feature: `game/<feature>/` (código y escenas juntos), los tests en `tests/`. La tabla completa, con las reglas que la
ordenan, en [docs/technical/estructura.md](docs/technical/estructura.md).
- `game/mech/` — **la meca**: `Mech` (hereda de `BalanceBody`; agrega la cabina, las teclas y los brazos), `MechCabin`
  (la base de la cabina: el marco por el que se camina adentro), `MechLeg`, `MechKeys` (**el único lugar que lee
  teclas**), `MechArm`, `MechHand`, `MechBody` (medidas e IK), `MechArchetype` (lo común de la parcela) y `Clay` (la
  arcilla de los bocetos). **Lo que se le pide a la meca son variables** (`move`, `sprint`, `crouch`, `jump`, `aim_yaw`,
  y `punch()` en sus brazos): hoy las escriben las teclas; mañana, los controles de los tableros.
  - `game/mech/cage/` — **la meca jaula**: `CageMech`, `CageCabin` (la caja o el cuerpo, la cápsula, el pozo, la torre,
    las sillas), `CageShape` (la forma, el F2), `CageBoards` (sus tableros), `CageBoarding` (subirse con la E),
    `BubbleSeat`, `DeskPit`, `CageMesh`.
  - `game/mech/boards/` — **las caras con tablero**: `FaceBoard`, `FaceMount`, `FoldingArm`.
  - `game/mech/arm_tips/` — **lo que lleva cada brazo en la punta** y el panel de equipo.
- `game/tool_mech/` — `ToolMech` (la energía común, el dash, saltar y levitar), del que hereda la jaula.
- `game/pose_arm/`, `game/muscle_arm/` — los dos brazos.
- `game/balance_body/` — **el cuerpo con equilibrio, la base común de la meca y los jefes**: `BalanceBody`, `BodyLegs`,
  `BodyMoves`, `BodySettings`, `KinematicMover`, `KinematicSettings`.
- `game/interactables/` — agarrar, sentarse y **los controles** (`ControllableInteractable` con su modo, el tablero de
  character-parametric, el botón y la palanca).
- `game/bosses/` — los jefes; `game/base/` — la sucursal; `game/battlefield/` — el mapa de pelea.
- `game/supplies/` — **los recursos**: `SupplyLook`, `PackageArchetype`, `PackageDamage`, `ObjectLotArchetype`.
- `game/sandbox/` — el sandbox de parcelas (ver `docs/technical/sandbox.md`), poseer (`SandboxPossession`), la bola de
  la J (`TestBall`) y la sesión de red del sandbox. Las teclas reservadas, en `SandboxKey.RESERVED`.
- `game/ui/` — la pausa (autoload `PauseMenu`, Escape), el menú de inicio, las Opciones (`GameOptions`), `UIState`
  (dueño del mouse, de los overlays y de la pantalla limpia) y la consola.
- Lo traído de character-parametric: `game/character/`, `game/interactables/`, `game/net/`, `game/common/`,
  `game/debug/`… **Ya es código de la meca** (el usuario, 12/11/2026: «debería ser su propio código además, mejorado,
  simplificado, tailoreado para nuestro caso»): se edita cuando hace falta, y lo que no se usa acá se puede ir sacando.

## Verificación
- **Todo Godot con ventana se lanza con `tools/godot_ventana.sh`** (no le roba el foco al usuario; carpeta de los
  agentes `D:/Godot/agentes/meca-60`).
- **Nunca cerrar un Godot que no sea de los agentes**: sólo los de `--path D:/Godot/agentes/...`.
- Chequeo de compilación: `godot --headless --path . --editor --quit`; los warnings son errores (correrlo dos veces
  después de agregar o borrar clases: la primera puede no ver los errores).
- `tests/cage_mech_look.tscn` (con ventana, unos 15 s, sin el sandbox): la meca jaula; imprime su huella (la caja, el
  hombro, el alto, las sillas, los maniquíes, lo que camina, el palo) y saca una hoja. Si un cambio no debería tocar la
  meca, la huella tiene que dar igual antes y después.
- `tests/cage_boards_look.tscn`: los tableros de la jaula, con la grilla y tres caras de frente.
- `tests/folding_arm_check.tscn`: los brazos plegables, plegados y traídos.
- `tests/cage_boarding_check.tscn`: subirse con la E (en el sandbox entero).
- `tests/sandbox_check.tscn`: las reglas del sandbox (filas, teclas, paneles); dice «SANDBOX OK».
- `tests/supplies_look.tscn`, `tests/pixel_art_look.tscn`, `tests/hand_look.tscn`, `tests/possess_check.tscn`,
  `tests/mech_fall_look.tscn`: los recursos, pintar con píxeles, la mano, poseer y la caída de la meca.
- `tests/net_check.tscn`: dos instancias sin ventana, una con `--host-local` y otra con `--join-local` (antes del
  `--`); cada una dice cuántos jugadores, personajes y objetos compartidos ve.
- `tests/load_all.tscn`: carga todos los scripts del juego y de los tests uno por uno (el chequeo del editor no los
  compila a todos).
