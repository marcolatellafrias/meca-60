# Meca

Juego cooperativo (de 1 a 4 jugadores) de una **meca gigante manejada desde adentro** contra jefes (bichos) en una
arena. Cada jugador maneja una parte de la meca desde su puesto (piernas, brazos…); cuando algo se rompe hay que
reacomodarse, salir afuera a reparar o ir a buscar recursos. Entre peleas, un hangar con oficina: contratos,
reparaciones con plata y cargar la meca. Hecho en **Godot 4.5** (GDScript), física con **Jolt**. Empezado el 11/11/2026;
hoy es un **boceto para probar la idea**, de a uno.

Varias piezas vienen de `D:\Godot\taxi` (el sandbox, las opciones, el lanzador de ventana), que a su vez las trajo de
`D:\Godot\character-parametric`. Y de character-parametric directo, el 11/11/2026, **el personaje, agarrar, sentarse y
la red** (con la pausa y el menú de inicio de allá): el jugador es el personaje de allá. Qué se trajo, qué se adaptó y
dónde se cortó (la ciudad, el tránsito, la nave), en `game/character_port/LEEME.md`.

## Decisiones tomadas
- **Primero validar la pelea, contra otra meca** (11/11/2026): los jefes quedan suspendidos hasta ver si la idea
  funciona. El rival es una meca igual, sin piloto (`MechBrain`), quieta o agresiva.
- La pelea es de **física simplificada, no de estadísticas**: no hay vida, todo es equilibrio. Las piñas se cargan y se
  sueltan, la fuerza sale de la velocidad del puño en el mundo (recorrido + marcha + giro del torso), y el mouse dobla
  la piña que sale. Un golpe de costado o de atrás del torso empuja más. Un brazo que toca un edificio se traba y nada
  más: un efecto extra sólo si sale solo de las reglas.
- Brazos comunes que siempre pegan; las armas (el cañón) van encima del antebrazo. Las piernas caminan para un lado y
  el torso gira aparte, a su velocidad (una mejora futura), sobre la PELVIS, que va con las piernas.
- **El cuerpo de la meca se define una sola vez** (`MechBody`): la meca de pelea y la de equilibrio son el mismo cuerpo.
  Una meca **nace donde vive** (se ubica antes de armarle nada encima), y lo físico montado en ella se mueve con ella.
- Los jefes, cuando vuelvan: **pocos arquetipos hechos a mano**, con **las partes por semilla**, **partes que se
  rompen** y **afijos** encima. Nada de piezas del bicho en la meca ni de sistema Némesis por ahora.
- La meca se arma según cuántos jugadores hay (más adelante, también por semilla: ruedas en vez de piernas, otros
  brazos). Sin cabeza.
- Entre peleas: el hangar como oficina, los contratos, los arreglos que cuestan plata y cargar la meca (con espacio
  limitado, sin sistema de peso).

## Cómo se prueba hoy
**El jugador es el personaje de character-parametric**: arranca como ente (sin cuerpo, movimiento directo, **V** vuela)
y la **B** lo vuelve cuerpo (el gordo atlético: se cae, agarra con el clic izquierdo, se sienta con la **E**, empuja con
la **R**). Sus teclas son las de allá (WASD, espacio, Ctrl, shift, E, R, V); Escape la pausa, que no frena el mundo.
Las teclas **F** son de los **paneles de fila**, como en el sandbox de allá (TunerPanel): abren parado en su fila, a la
izquierda, y el panel de la parcela los anota con su tecla.

En el sandbox, la fila **Meca** («Pelea de prueba»):
- **O** la maneja **desde afuera**: cámara atrás por sobre el hombro (**T** pasa a primera persona en el frente del
  torso). WASD las piernas, el mouse gira el torso, clic izquierdo y derecho cargan (mantener) y pegan (soltar), el
  mouse dobla la piña que sale, Shift se afirma, G el cañón. **O** o **E** vuelve.
- **U** sube a la meca, al piso de las piernas. Adentro se va parado como en la nave de allá (el torso es un marco,
  `MotionFrame`). Los puestos tienen **la silla de allá**: mirándola, **E** se sienta y se levanta; parado en el
  montacargas, **E** lo manda a la otra punta. Sentado:
  - Piernas: W/S camina, A/D gira las piernas, Shift se afirma.
  - Brazos: se apunta mirando, Z/X giran el torso, los clics cargan y pegan, G el cañón.
  - Vigía: una cámara de afuera que gira con el mouse.
  - Desde cualquier puesto (para probar de a uno): flechas caminan, B se afirma, Z/X el torso, F/H los brazos, G cañón.
- **N** el rival quieto o agresivo, **R** otra arena. **V** es el modo creativo del sandbox (volar atravesando).

En su propia fila, **Equilibrio**, la **«Meca de equilibrio»**: una copia de la meca que sólo se tambalea, se cae y se levanta, con el sistema de
equilibrio de los personajes de character-parametric, con dos personas de allá al lado. **J** tira una bola desde la
cámara (una sola bola, que va derecha y no cae; la fuerza es su empuje); **K** pasa por sus tres fuerzas: lo mueve, a
punto de caer y lo tira. **Cada fila dice sus tres** para lo que tiene, con sus umbrales de ahora
(`SeededArchetype.ball_pushes`): la meca de equilibrio con su paso y su caída (`MechDummy.ball_pushes`), el cubo con
su inclinación de caerse (`HoverCube.ball_pushes`) y cada persona con su peso y su firmeza
(`PeopleArchetype.ball_pushes`). Tiene dos agregados al sistema de allá: **el golpe empuja** (la inclinación toma
velocidad en vez de saltar) y **los pasos** (pasada cierta inclinación da un paso hacia donde se va y se recupera
trastabillando). **F1** en la fila Equilibrio abre su panel (`BalancePanel`): todas sus perillas (los agregados, el resorte,
la firmeza por lado, el cuerpo, la caída), que salen de `MechBalanceSettings`.

**Cubo flotante** (11/11/2026): la caída y la recuperación, aparte de la caminata. Un cubo grande, cuerpo físico libre,
que flota como el cuerpo de los personajes de character-parametric antes del 13/03/2026 (un resorte de altura con dos
rayos al piso y un torque que lo endereza): rebota y cabecea solo. Pasado un umbral (inclinación, caída, velocidad de
costado) deja de intentar y cae con física; quieto un rato, **sube** con las toberas de la cara que mira al piso y **se
endereza en el aire** con las de los costados (cuatro por cara, con el humo de propulsor de allá), y vuelve a flotar.
**J/K** la bola (sus fuerzas suponen el golpe en la mitad de arriba: en el centro lo corre sin inclinarlo); **F1** su
panel (`HoverPanel`, perillas en `HoverCubeSettings`). Las piernas, para más adelante, en su propia fila (el
sistema «por radio» de allá, de octubre de 2025).

Más filas: **Personajes** (los seis arquetipos de allá, que se caen y se levantan; también con la bola), **Objetos** (los
paquetes de allá sueltos, para agarrarlos, y una silla) y **Multijugador** (la red de allá: **H** abre sesión en esta
compu y otra instancia se une con **J**, **G** abre por Steam, **K** va al menú de inicio para unirse por código, **L**
sale) y **Partículas** (la de allá: cada sistema en su poste; **M** cambia la malla de toda la fila). Por la red van los
personajes y los objetos de esa parcela; **las mecas todavía no**.

## Dónde va cada cosa
Por feature: `game/<feature>/` (código y escenas juntos), los tests en `tests/`.
- `game/mech/` — **la meca**: `MechBody` (el cuerpo, una sola vez: medidas, partes y postura), `Mech` (la raíz en el suelo, la marcha, el torso que gira aparte, el equilibrio y la
  caída, las palancas, los puestos, el manejo desde afuera y las teclas), `MechBrain` (el rival sin piloto),
  `MechTorso` (el torso de tres pisos con la escalera de incendio atrás; es un marco), `MechSeat` (un puesto: la silla
  de allá y la consola con su nivel de equilibrio), `MechLift` (el montacargas), `MechLeg` (una pierna de la meca de pelea, sólo
  dibujo), `MechArm` (un brazo: la piña cargada, el puño que barre y se traba, el cañón encima con su bala `MechShell`),
  `MechHud` (lo de pantalla para probar), `MechDummy` (la meca de equilibrio: el cuerpo físico, el resorte y el
  muñeco de character-parametric, el empuje y los pasos; sus perillas en `MechBalanceSettings`) y `Clay` (la arcilla de los bocetos). Todo lo que tiene
  `take_hit(amount, direction, push)` recibe golpes.
- `game/arena/` — `TestArena` (el redondel con edificios y las dos mecas, que no se pisan), `MechTestArchetype` (su
  parcela), `BalanceTestArchetype` (la parcela de la meca de equilibrio) y `BalancePanel` (su panel, F1), `TestBall`
  (la bola de la J),
  `PeopleArchetype` (las personas de allá) con `CharacterGetUp` (que se levanten solas) y `ObjectLotArchetype` (el lote
  de objetos).
- `game/hover/` — **el cubo flotante**: `HoverCube` (flotar, dejarse caer, subir y enderezarse con las toberas),
  `HoverCubeSettings` (sus perillas), `HoverPanel` (su F1) y `HoverCubeArchetype` (su parcela).
- `game/sandbox/` — el sandbox de parcelas (`DesignSandbox.categories()` agrega filas, `_mount_tuners` sus paneles F;
  crea al jugador, ver arriba) y la sesión de red del sandbox (`SandboxSession`, `MultiplayerArchetype`). Teclas del sandbox y del jugador: WASD,
  espacio, shift, Ctrl, E, R, C, V, B, F1–F6, Escape; no repetirlas. Sentado (o manejando desde afuera) sólo valen las
  de la meca.
- `game/ui/` — la pausa (autoload `PauseMenu`, Escape, la de allá), el menú de inicio (`main_menu.tscn`), las Opciones
  de la meca (`GameOptions`, `user://opciones.cfg`), `UIState` y la consola.
- Lo traído de character-parametric: `game/character/`, `game/interactables/`, `game/net/`, `game/objects/`,
  `game/common/`, `game/debug/`… y la frontera en `game/character_port/` (ver su LEEME.md). **No se edita**: si cambia
  allá, se vuelve a copiar.

## Verificación
- **Todo Godot con ventana se lanza con `tools/godot_ventana.sh`** (no le roba el foco al usuario; carpeta de los
  agentes `D:/Godot/agentes/meca`).
- **Nunca cerrar un Godot que no sea de los agentes**: sólo los de `--path D:/Godot/agentes/...`.
- Chequeo de compilación: `godot --headless --path . --editor --quit`; los warnings son errores.
- `tests/mech_check.tscn`, **con ventana** (`-- --salida=<carpeta>` para capturas; sin ventana el mouse no queda
  capturado y el giro y las piñas no se miden): maneja desde afuera, gira el torso, pega piñas sin cargar, cargadas y
  un gancho, tira al rival, pasa a primera persona, pone al rival agresivo, traba un brazo contra un edificio y pega
  sentado en los brazos.
- `tests/balance_check.tscn` (headless o con ventana): mira que los pies estén planos, le tira bolas de varias
  fuerzas a la meca de equilibrio en los dos modos (como allá, y con empuje y pasos) e imprime la inclinación, los
  pasos, cuánto retrocedió y si se cayó; con ventana, capturas del trastabillar. Y bolas chicas a las dos personas.
- `tests/hover_check.tscn` (headless o con ventana): el cubo flotante se asienta, las tres bolas, soltarlo de más arriba
  (el rebote), y voltearlo y seguir la recuperación; con ventana, capturas cada medio segundo.
- `tests/player_check.tscn` (con ventana): el jugador es el de allá, la B, subir a la meca, sentarse en la silla,
  caminarla sentado, viajar parado adentro, manejar desde afuera y volver, y agarrar el ropero del lote.
- `tests/net_check.tscn`: dos instancias sin ventana, una con `--host-local` y otra con `--join-local` (antes del
  `--`); cada una dice cuántos jugadores, personajes y objetos compartidos ve.
- `tests/load_all.tscn`: carga todos los scripts uno por uno (el chequeo del editor no los compila a todos).
