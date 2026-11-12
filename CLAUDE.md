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

## La documentación: `docs/`
Una bóveda de Obsidian, simple: una nota por sistema y **una nota con cada fila del sandbox y su código**
([docs/filas.md](docs/filas.md)). Empezar por [docs/00-indice.md](docs/00-indice.md). Un cambio a un sistema actualiza
su nota.

**Borrar una parcela borra su código**: su arquetipo, lo que sólo ella usa, sus paneles, sus perillas, sus tests y su
fila en `docs/filas.md` (lo pidió el usuario el 12/11/2026: «me gusta que si borro algo, una parcela, que borra el código
también»). Nada queda huérfano.

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

**Poseer** (12/11/2026, `SandboxPossession`; reemplaza al «manejar desde afuera» que tenía cada cosa): para probar de a
uno lo que en el juego se maneja desde adentro. **Mirando** una meca o un cubo, la **O** lo posee (las teclas pasan a
él y el jugador se apaga donde está); **O** otra vez lo suelta, y **se acuerda**: **O** sin mirar nada lo retoma (así
soltar sirve para moverse a mirar de otro lado y seguir). Poseyendo, la **T** pasa por tres vistas: **libre** (la cámara
del jugador, donde quedó), **tercera persona** y **primera persona**. Un cartel abajo a la derecha dice qué se posee, la
vista y **sus controles**. Se puede poseer lo que está en el grupo `possessable` y contesta `possess_name`,
`possess_controls`, `possess_begin`, `possess_end` y `possess_camera(first, delta)`. Los personajes, todavía no.

En el sandbox, la fila **Meca** («Pelea de prueba»):
- **Poseída** (mirándola, **O**): WASD las piernas, el mouse gira el torso, clic izquierdo y derecho cargan (mantener)
  y pegan (soltar), el mouse dobla la piña que sale, Shift se afirma, G el cañón.
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
sus cuatro tiros (`HoverCubeArchetype.ball_shots`) y cada persona con su peso y su firmeza
(`PeopleArchetype.ball_pushes`). Tiene dos agregados al sistema de allá: **el golpe empuja** (la inclinación toma
velocidad en vez de saltar) y **los pasos** (pasada cierta inclinación da un paso hacia donde se va y se recupera
trastabillando). **F1** en la fila Equilibrio abre su panel (`BalancePanel`): todas sus perillas (los agregados, el resorte,
la firmeza por lado, el cuerpo, la caída), que salen de `MechBalanceSettings`.

**Cubo** (11/11/2026; quedó uno solo el 12/11/2026): la caída y la recuperación, aparte de la caminata. Un cubo grande
que flota con un **resorte vertical** (el del cuerpo de los personajes de character-parametric antes del 13/03/2026) y
**parado no gira**: un golpe nunca le cambia hacia dónde mira. **El golpe lo corre** (el freno del retroceso dice cuánto; manejándolo con la **O**, lo propio tiene su propio freno al soltar) y
**aparte lo inclina** con la línea de equilibrio (cualquier golpe, a cualquier altura; golpes seguidos se suman; se ve
inclinando el dibujo sobre el canto de abajo). Al pasarla **tropieza**: el cuerpo toma esa inclinación y recibe, una
sola vez, el giro justo para que su base quede quieta; de ahí es física y cae para el lado del golpe. Caído pesa un poco
más y se le frena el giro (poco: es física); apenas deja de caer **sube y se endereza a la vez** con sus toberas
(cuatro por cara, con el humo de propulsor de allá): gira tanto como le sobra de altura sobre su punto más bajo, y vuelve a la
línea mirando hacia donde miraba. La parcela es de 60 m. **J/K** cuatro tiros: lenta (30 m/s) o rápida (100 m/s), que
lo voltea o no. **F1** su panel (`HoverPanel`, perillas en `HoverCubeSettings`); **F2** volcarlo, suave y fuerte
(`HoverKnockPanel`). *El cubo que se enderezaba con un torque libre se borró: se torcía con cualquier golpe.*
**Contra qué y dónde** (12/11/2026: con una pared apenas tocada se volteaba): el golpe se mide igual, pero mira los
contactos de la física de ese paso. Contra algo **fijo** (pared, edificio) sólo frena: inclina ×0,25 (`fixed_lean`) y
caminando no lo tira. Contra algo **que se mueve** (la bola) es un golpe entero, que inclina según la **altura** del
contacto (arriba vuelca más) y lo corre **×2,5** (`knock_gain`, el retroceso; al tropezar cae con su velocidad física,
sin el ×2,5). Es el punto medio: la física dice qué fue el golpe, la línea qué hace el cubo.

**Cubo con piernas** (12/11/2026, `LeggedCube`, hereda del cubo): el mismo cubo con una **pelvis** debajo y **dos
piernas** (el cuerpo de la meca, `MechBody`, dibujadas con `MechLeg`), para empezar a ver cómo se mueven. Las piernas
son dibujo: el peso lo lleva el resorte. **O** lo maneja: W/S y A/D las piernas (la pelvis mira hacia donde caminan), el
**mouse gira el torso aparte**, como la meca. **Los pasos, por radio** (el sistema de allá de octubre de 2025): cada pie
queda plantado hasta que su lugar debajo de la cadera, adelantado con la marcha, se aleja más que un radio; ahí da un
paso, de a un pie. **Al caer las piernas se pliegan** (no se achican) con easing y, en cuanto empieza a enderezarse,
se estiran hacia debajo de las caderas: al quedar derecho ya está parado. **F1** su panel
(`LeggedCubePanel`: las perillas del cubo en su propia copia y las de los pasos), **F2** volcarlo, **J/K** las bolas.

**Cubo físico** (12/11/2026, `PhysicalCube`, hereda del cubo; para comparar con la línea): parado **no tiene línea**,
su inclinación es la del cuerpo. Gira de costado y de frente con la física, en Y no (trabado). Flota sobre **cuatro
resortes en las esquinas** de abajo y **los pies** agarran el piso más abajo que el cubo: un golpe corre el cuerpo, los
pies frenan la base y vuelca, más cuanto más arriba pegó. Lo que pide el que lo maneja lo empuja desde el centro
(arrancar no lo cabecea). Pasado `fall_tilt` (35°) cae y se recupera como el cubo. Medido: cae con unos 3,5 m/s
pegando arriba y 4 y pico en el centro; **contra una pared a 8 m/s se cae** (es física: no distingue). **F1** su panel
(`PhysicalCubePanel`, sin las perillas de la línea), **F2** empujarlo arriba, **J/K** cuatro tiros por cambio de
velocidad (1 y 5 m/s).

**Cubo péndulo** (12/11/2026, `PendulumCube`, hereda del cubo las toberas y la recuperación): **el modelo de
equilibrio de la meca**, que no es el de los personajes (colisión 1:1, inclinación del cuerpo de verdad). Un solo cuerpo
físico, el torso, que siempre va adelante; los pies siempre lo siguen. Es un **péndulo invertido** sobre un punto de
apoyo en el piso: caminar empuja al torso (con inercia), y el apoyo lo sigue —**frenar es instantáneo, alcanzarlo lleva
tiempo**—. Una piña saca al torso de arriba de los pies: se inclina y, si no lo alcanzan, cae (arriba vuelca más). Una
pared lo frena y los pies se plantan: **no cae a ninguna velocidad**. Arrancar lo inclina un poco adelante y se nivela
(la opción B; C y D pendientes, ver docs/cubo-pendulo.md). El giro en Y es un motor con fuerza tope (el mouse); las
piernas, IK por radio que siguen al torso, con la pelvis mirando al promedio de los pies. **O** lo maneja (W/S, A/D de
costado, mouse), **F1** su panel, **F2** pegarle arriba, **J/K** cuatro tiros (5 y 14 m/s). Las filas Cubo, Cubo con
piernas y Cubo físico quedan por ahora, para comparar.

**Meca péndulo** (12/11/2026, `PendulumMech`, hereda del cubo péndulo; es donde se sigue puliendo): el mismo equilibrio,
con **tres pisos** por dentro (vidrio y parantes al frente, la puerta atrás, sin escalera todavía), brazos y, poseída:
**Shift corre** (una banda sobre la caminata que se gana y se pierde despacio, como allá), **Ctrl se agacha** (acorta
el palo del péndulo), **espacio** carga y suelta el **salto** (se carga altura) y, en el aire, el **propulsor**. En el
aire va derecha y sin apoyo; aterriza cuando la punta del palo vuelve a tocar. **F1** su panel, **F2** pegarle arriba.
**Sus brazos son físicos**: dos `MuscleArm` (ver Brazo) colgados de los hombros, casi en el medio del costado; **F**
cambia la postura (normal, a los costados; cubriéndose, los puños cerrados adelante), y las piñas van por brazo: clic
izquierdo / derecho el directo, Q / E el gancho, Z / C el uppercut, 1 / 3 desde arriba. Caída, se recogen.
**Adentro se camina** (**U** sube al piso del medio): es un marco (`MotionFrame`) como el torso de la meca de pelea; sus
losas y paredes no chocan con el mundo (eso es de la caja 1:1), son de donde el marco copia su sombra, y la caja deja de
chocar con los que van adentro.

**Brazo** (12/11/2026, `MuscleArm`): el primer paso de los brazos físicos, solo en su fila. La idea de PuppetMaster: la
IK (`MechBody.arm`) dice la pose y el cuerpo físico la persigue con músculos. El brazo y el antebrazo (con la mano) son
cuerpos sueltos; **el hombro es una bola y el codo una bisagra**; un músculo por articulación, con resorte, freno y
fuerza tope (el del hombro gira el brazo, incluido su giro sobre el largo; el del codo sólo dobla y empuja al brazo para
el otro lado). De ahí sale solo que se trabe contra algo fijo, que ceda si le pegan, y que la piña valga la velocidad de
la mano. **1–4** las piñas (directo, gancho, uppercut, desde arriba), **N** una pared, **J/K** bolas, **F1** su panel;
poseído, el mouse lleva la mano. La mano (`MechHand`) es la misma de la meca péndulo: abierta, o **el puño** mientras tira
una piña (pasa de una a otra con easing).

**Las parcelas tienen paredes invisibles** (como allá, `SandboxParcel` LOS BORDES): las ve lo que se mueve con física y
vive en una parcela; el jugador y la bola pasan. Las mecas de pelea, que se mueven por código, le preguntan a su parcela
(`SandboxParcel.holds`): el borde de la arena es el de su parcela.

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
- `game/hover/` — **el cubo**: `HoverCube` (flotar, la línea, tropezar, subir y enderezarse con las toberas),
  `HoverCubeSettings` (sus perillas), `HoverPanel` (su F1), `HoverKnockPanel` (su F2: volcarlo) y `HoverCubeArchetype`
  (su parcela y sus tiros).
- `game/legged_cube/` — **el cubo con piernas**: `LeggedCube` (la pelvis, las piernas, los pasos por radio y el torso
  aparte), `LeggedCubeSettings`, `LeggedCubePanel` (su F1) y `LeggedCubeArchetype`. Usa `game/hover/` y `MechBody`.
- `game/physical_cube/` — **el cubo físico**: `PhysicalCube` (esquinas, pies, torque, caerse), `PhysicalCubeSettings`,
  `PhysicalCubePanel` (su F1) y `PhysicalCubeArchetype`. Usa `game/hover/`.
- `game/pendulum_cube/` — **el cubo péndulo**: `PendulumCube` (el péndulo, el apoyo que sigue al torso, el giro, las
  piernas), `PendulumCubeSettings`, `PendulumCubePanel` (su F1) y `PendulumCubeArchetype`. Usa `game/hover/` y `MechBody`.
- `game/pendulum_mech/` — **la meca péndulo**: `PendulumMech` (los tres pisos, los brazos, correr, agacharse, saltar y el
  propulsor), `PendulumMechSettings`, `PendulumMechPanel` (su F1) y `PendulumMechArchetype`. Usa `game/pendulum_cube/`.
- `game/muscle_arm/` — **el brazo con músculos**: `MuscleArm` (las piezas, las articulaciones, los músculos, las piñas y
  llevarlo a mano), `MuscleArmSettings`, `MuscleArmPanel` (su F1) y `MuscleArmArchetype` (el torso fijo, el bloque y la
  pared). Usa `MechBody.arm` y `MechHand` (la mano, en `game/mech/`).
- `game/sandbox/` — el sandbox de parcelas (`DesignSandbox.categories()` agrega filas, `_mount_tuners` sus paneles F;
  crea al jugador, ver arriba), poseer (`SandboxPossession`: la O, la T y el cartel) y la sesión de red del sandbox (`SandboxSession`, `MultiplayerArchetype`). Teclas del sandbox y del jugador: WASD,
  espacio, shift, Ctrl, E, R, C, V, B, O, T, F1–F6, Escape; no repetirlas. Sentado (o manejando desde afuera) sólo valen las
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
- `tests/hover_check.tscn` (headless o con ventana): el cubo se asienta, los cuatro tiros, los botones de volcar (para
  qué lado cae y cuánto gira), el rebote, y voltearlo y seguir la recuperación; con ventana, capturas cada medio segundo.
- `tests/legged_check.tscn` (headless o con ventana): el cubo con piernas camina, gira las piernas con el torso quieto,
  camina con el torso girado y para atrás, un golpe suave y uno que lo vuelca; cuenta los pasos y lo lejos que queda un
  pie de su lugar; con ventana, capturas.
- `tests/physical_check.tscn` (headless o con ventana): el cubo físico; una escala de empujones en el centro y arriba
  (dónde se cae), sus cuatro tiros, el F2, cuánto cabecea al arrancar y frenar, contra la pared y la recuperación.
- `tests/pendulum_check.tscn` (headless o con ventana, unos 5 minutos): el cubo péndulo; la escala de golpes en el
  centro y arriba, contra la pared a 8, 14 y 20 m/s (no tiene que caer), arrancar y frenar, el giro, un golpe
  descentrado, sus tiros, el F2 y la recuperación.
- `tests/pendulum_look.tscn` (con ventana, unos 10 segundos, sin el sandbox): el cubo péndulo de cerca (las piernas) y
  la caída con la recuperación cuadro a cuadro. Para mirar el aspecto rápido; no mide.
- `tests/pendulum_mech_look.tscn` (con ventana, unos 25 segundos, sin el sandbox): la meca péndulo de frente, de atrás y
  desde el asiento; agacharse, el salto (un toque y cargado), el propulsor y correr, con sus números.
- `tests/pendulum_ride_check.tscn` (con ventana, unos 30 segundos): ir adentro de la meca péndulo; el jugador con cuerpo
  sube, y se mira qué le pasa mientras la meca se corre, salta y se cae.
- `tests/muscle_arm_look.tscn` (con ventana, unos 30 segundos, sin el sandbox): el brazo con músculos; la guardia, las
  cuatro piñas (velocidad de la mano, cuánto corre el bloque), la pared (se traba y vuelve) y un empujón (cede y vuelve).
- `tests/hand_look.tscn` (con ventana, unos 5 segundos): la mano abierta y en puño, de tres lados.
- `tests/possess_check.tscn` (con ventana, unos 15 segundos): poseer; mirar el cubo péndulo, la O, las tres vistas con
  la T, soltar y retomar sin mirar; capturas del cartel.
- `tests/player_check.tscn` (con ventana): el jugador es el de allá, la B, subir a la meca, sentarse en la silla,
  caminarla sentado, viajar parado adentro, manejar desde afuera y volver, y agarrar el ropero del lote.
- `tests/net_check.tscn`: dos instancias sin ventana, una con `--host-local` y otra con `--join-local` (antes del
  `--`); cada una dice cuántos jugadores, personajes y objetos compartidos ve.
- `tests/load_all.tscn`: carga todos los scripts uno por uno (el chequeo del editor no los compila a todos).
