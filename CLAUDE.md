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
- **Todo es equilibrio, no estadísticas**: no hay vida. La caja de la meca es **un cuerpo físico 1:1** (los jugadores
  caminan adentro y por afuera): se mueve sólo con fuerzas e impulsos, nunca por código. Vale para caminar, saltar,
  los propulsores y los dashes.
- **El equilibrio es un péndulo** (12/11/2026, en `Mech`): el torso siempre va adelante y un punto de apoyo en el
  piso lo sigue. Una piña saca al torso de arriba de los pies (se inclina y, si no lo alcanzan, cae); una pared lo frena
  y los pies se plantan (no cae a ninguna velocidad). La otra variante, la línea de equilibrio, queda en la fila Cubo
  con piernas por si se vuelve a ella.
- **DOS CAMINOS, BIFURCADOS** (13/11/2026: «bifurcar el progreso… un approach más físico o más discreto»). Comparten
  todo —el péndulo, los pisos, el afuera, el ascensor, las piernas— menos los brazos:
  - **Meca discreta** (el más probable): peleas contra jefes NPC, con zonas que esquivar y proyectiles. Los brazos
    (`PoseArm`) se dibujan en su pose, atraviesan lo que haya y, al conectar, le dan un impulso a lo que tocan.
  - **Meca física**: arena entre dos grupos de jugadores. Los brazos (`MuscleArm`) son cuerpos con músculos que chocan,
    se traban y ceden.
  Lo que se le pide a un brazo (posturas, piñas, la pose) está una sola vez, en `MechArm`. Los límites de cada camino
  moldean sus features; lo común (consolas, reparación, energía) se hace una vez.
- **El cuerpo de la meca se define una sola vez** (`MechBody`: medidas, piernas, brazos). Sin cabeza.
- Los jefes, cuando lleguen: **pocos arquetipos hechos a mano**, con **las partes por semilla**, **partes que se
  rompen** y **afijos** encima. Nada de piezas del bicho en la meca ni de sistema Némesis por ahora.
- Entre peleas: el hangar como oficina, los contratos, los arreglos que cuestan plata y cargar la meca (con espacio
  limitado, sin sistema de peso).
- **Falta**: las consolas, la reparación, la energía, propulsores laterales y dashes.
- *Borrado el 13/11/2026: la meca de pelea vieja con su rival (de ahí salió la regla del puño que barre su camino, hoy
  en `PoseArm`), la meca de equilibrio, el cubo físico y las filas Cubo y Cubo péndulo (sus clases quedan: son la base
  de la meca).*

## Cómo se prueba hoy
**El jugador es el personaje de character-parametric**: arranca como ente (sin cuerpo, movimiento directo, **V** vuela)
y la **B** lo vuelve cuerpo (el gordo atlético: se cae, agarra con el clic izquierdo, se sienta con la **E**, empuja con
la **R**). Sus teclas son las de allá (WASD, espacio, Ctrl, shift, E, R, V); Escape la pausa, que no frena el mundo.
Las teclas **F** son de los **paneles de fila** (TunerPanel): abren parado en su fila, a la izquierda, y el panel de la
parcela los anota con su tecla.

**Poseer** (`SandboxPossession`): para probar de a uno lo que en el juego se maneja desde adentro. **Mirando** una meca
o un cubo, la **O** lo posee (las teclas pasan a él y el jugador se apaga donde está); **O** otra vez lo suelta, y **se
acuerda**: **O** sin mirar nada lo retoma. Poseyendo, la **T** pasa por tres vistas: **libre**, **tercera persona** y
**primera persona** (sentado adentro). Un cartel abajo a la derecha dice qué se posee, la vista y **sus controles**. Se
puede poseer lo que está en el grupo `possessable` y contesta `possess_name`, `possess_controls`, `possess_begin`,
`possess_end` y `possess_camera(first, delta)`. Los personajes, todavía no.

Las filas del sandbox (el detalle, en `docs/filas.md`):

**Meca discreta** y **Meca física** (`Mech`; una fila por camino, misma parcela con otros brazos, `Mech.Arms`): el péndulo con **tres pisos** de paredes de verdad (vidrio y parantes al frente, la puerta atrás),
brazos, y una **meca de práctica adelante, sin brazos, para pegarle**. Poseída: W/S y A/D, el mouse gira el torso; **Shift corre**, **Ctrl
se agacha** (acorta el palo del péndulo), **espacio** carga y suelta el **salto** y, en el aire, el **propulsor**. **F**
cambia la postura de los brazos (normal, a los costados; cubriéndose, los puños cerrados adelante), y las piñas van por
brazo: clic izquierdo / derecho el directo, Q / E el gancho, Z / C el uppercut, 1 / 3 desde arriba. Caída, se recogen.
**F1** su panel, **F2** pegarle arriba y el ascensor, **J/K** los tiros.
**Afuera** (`MechExterior`): la pasarela en U de planta baja y, atrás, dos tramos paralelos con un balcón por piso
(armado de superficies pisables, con la altura libre medida y las barandas donde hay caída). **El ascensor de la
pelvis** (`PelvisLift`): la pelvis es un tambor redondo, la losa de abajo tiene un recorte con su baranda, y un piso
redondo con cuatro parantes baja hasta quedar a un salto del suelo con la meca agachada; **G** poseída o el botón del
**F2** lo mueven. **Adentro y afuera se camina** (**U** sube al piso del medio): es un marco (`MotionFrame`, en `MechCabin`); sus losas
y paredes no chocan con el mundo (eso es de la caja 1:1), son de donde el marco copia su sombra, y la caja deja de
chocar con los que van adentro. **El rayo al piso saltea lo que se mueve** (una persona en el ascensor no es piso).

**Brazo** (`MuscleArm`): el brazo físico, solo en su fila. La idea de PuppetMaster: la IK (`MechBody.arm`) dice la pose
y el cuerpo físico la persigue con músculos. El brazo y el antebrazo (con la mano) son cuerpos sueltos; **el hombro es
una bola y el codo una bisagra**; un músculo por articulación, con resorte, freno y fuerza tope. De ahí sale solo que se
trabe contra algo fijo, que ceda si le pegan, y que la piña valga la velocidad de la mano. **1–4** las piñas, **N** una
pared, **J/K** bolas, **F1** su panel; poseído, el mouse lleva la mano. La mano (`MechHand`) es izquierda o derecha, una
el espejo de la otra, montada por regla (el pulgar hacia donde dobla el codo, la palma hacia el cuerpo).

**Cubo con piernas** (`LeggedCube`, en `game/line_cube/`, hereda de `HoverCube`): **la otra variante de equilibrio, la línea** (no el péndulo), que
se guarda por si se vuelve a ella. El cubo flota con un resorte vertical y parado no gira; un golpe lo corre y aparte lo
inclina con la línea de equilibrio; al pasarla tropieza, cae con física y se recupera con toberas. Con pelvis, dos
piernas de dibujo (pasos por radio) y el torso que gira aparte. **F1** su panel, **F2** volcarlo, **J/K** las bolas.

**Las parcelas tienen paredes invisibles** (`SandboxParcel`): las ve lo que se mueve con física y vive en una parcela;
el jugador y la bola pasan.

**Recursos** (13/11/2026, `SupplyLook`; ver docs/recursos.md): lo que se trae a la meca, sueltos para agarrarlos. **Todos son
un cubo de 63 cm** que se agarra igual: la batería, el componente eléctrico, la caja de misiles, la caja de balas y la
bomba (dinamita); al fondo, fijos, los cubos de la meca que muestran la munición que queda. Todavía no se enchufan en
nada: la mecánica acordada (el indicador, acomodarse solo, un tipo por hueco, sacar el viejo antes, el gastado se
desvanece) está en la nota.

Más filas: **Personajes** (los seis arquetipos de allá, que se caen y se levantan; también con la bola), **Multijugador** (la red de allá: **H** abre sesión en esta
compu y otra instancia se une con **J**, **G** abre por Steam, **K** va al menú de inicio para unirse por código, **L**
sale) y **Partículas** (cada sistema en su poste; **M** cambia la malla de toda la fila). Por la red van los personajes
y los objetos de esa parcela; **las mecas todavía no**.

## Dónde va cada cosa
Por feature: `game/<feature>/` (código y escenas juntos), los tests en `tests/`. La tabla completa, con las reglas que la
ordenan y lo que todavía se le critica, en [docs/estructura.md](docs/estructura.md).
- `game/mech/` — **la meca, una clase con sus piezas aparte** (aplanada el 13/11/2026; antes eran tres clases apiladas):
  `Mech` (el cuerpo físico y su equilibrio, el péndulo; llama a sus piezas en orden), `MechCabin` (los pisos, el marco;
  con `MechExterior` y `PelvisLift`), `MechLegs` (la pelvis y las piernas, con `MechLeg`), `MechNozzles` (las toberas:
  levantarse y el propulsor), `MechMoves` (caminar, correr, agacharse, saltar: **acá van los dashes**), `MechKeys` (**el
  único lugar que lee teclas**, y la cámara de poseer), `MechArm` (lo que se le pide a un brazo), `MechHand`,
  `MechBody` (medidas e IK), `MechSettings` (todas las perillas), `MechPanel` y `MechKnockPanel` (F1 y F2),
  `MechArchetype` (la parcela de las dos filas) y `Clay` (la arcilla de los bocetos).
  **Lo que se le pide a la meca son variables** (`move`, `sprint`, `crouch`, `jump`, `aim_yaw`, `covering`, y `punch()`
  en sus brazos): hoy las escribe `MechKeys`; mañana, las consolas o un jefe. Nada más lee teclas.
- `game/pose_arm/` — **el brazo discreto**: `PoseArm` (se dibuja en la pose; el puño barre su camino y da un impulso).
- `game/muscle_arm/` — **el brazo físico**: `MuscleArm` (las piezas, las articulaciones, los músculos y llevarlo a
  mano), `MuscleArmSettings`, `MuscleArmPanel` (su F1) y `MuscleArmArchetype` (el torso fijo, el bloque y la pared).
- `game/line_cube/` — **la otra variante de equilibrio, la línea, congelada y aparte**: `HoverCube` (flotar con resorte,
  la línea, tropezar, recuperarse) y `LeggedCube` (pelvis, piernas, torso aparte), con sus perillas, paneles y parcela.
  No comparte nada con la meca salvo `MechBody`, `MechLeg` y `Clay`. No se toca salvo que se vuelva a ella.
- `game/supplies/` — **los recursos**: `SupplyLook` (el dibujo de cada cubo, lo que se lleva y lo que va en la meca). El
  cuerpo que se agarra lo arma `PackageArchetype` (`game/objects/`), cuyo catálogo son hoy esos cinco cubos.
- `game/arena/` — `TestBall` (la bola de la J), `PeopleArchetype` (las personas de allá) con `CharacterGetUp` (que se
  levanten solas) y `ObjectLotArchetype` (el lote de recursos).
- `game/sandbox/` — el sandbox de parcelas (`DesignSandbox.categories()` agrega filas, `_mount_tuners` sus paneles F;
  crea al jugador), poseer (`SandboxPossession`) y la sesión de red del sandbox (`SandboxSession`,
  `MultiplayerArchetype`). Teclas del sandbox y del jugador: WASD, espacio, shift, Ctrl, E, R, C, V, B, O, T, F1–F6,
  Escape; no repetirlas. Poseyendo sólo valen las de lo poseído.
- `game/ui/` — la pausa (autoload `PauseMenu`, Escape), el menú de inicio (`main_menu.tscn`), las Opciones
  (`GameOptions`, `user://opciones.cfg`), `UIState` y la consola.
- Lo traído de character-parametric: `game/character/`, `game/interactables/`, `game/net/`, `game/objects/`,
  `game/common/`, `game/debug/`… y la frontera en `game/character_port/` (ver su LEEME.md). **Ya es código de la meca**
  (el usuario, 12/11/2026: «debería ser su propio código además, mejorado, simplificado, tailoreado para nuestro
  caso»): se edita cuando hace falta, y lo que no se usa acá se puede ir sacando.

## Verificación
- **Todo Godot con ventana se lanza con `tools/godot_ventana.sh`** (no le roba el foco al usuario; carpeta de los
  agentes `D:/Godot/agentes/meca`).
- **Nunca cerrar un Godot que no sea de los agentes**: sólo los de `--path D:/Godot/agentes/...`.
- Chequeo de compilación: `godot --headless --path . --editor --quit`; los warnings son errores.
- `tests/legged_check.tscn` (headless o con ventana): el cubo con piernas camina, gira las piernas con el torso quieto,
  camina con el torso girado y para atrás, un golpe suave y uno que lo vuelca; cuenta los pasos y lo lejos que queda un
  pie de su lugar; con ventana, capturas.
- `tests/mech_balance_check.tscn` (headless o con ventana, unos 5 minutos): el equilibrio de la meca, sola en su parcela; la escala de golpes en el
  centro y arriba, contra la pared a 8, 14 y 20 m/s (no tiene que caer), arrancar y frenar, el giro, un golpe
  descentrado, sus tiros, el F2 y la recuperación.
- `tests/mech_look.tscn` (con ventana, unos 100 segundos, sin el sandbox): la meca física de frente, de atrás y
  desde el asiento; agacharse, el salto (un toque y cargado), el propulsor y correr, con sus números.
- `tests/mech_ride_check.tscn` (con ventana, unos 30 segundos): ir adentro y afuera de la meca; el jugador con cuerpo
  sube, y se mira qué le pasa mientras la meca se corre, salta y se cae.
- `tests/mech_fork_look.tscn` (con ventana, unos 25 segundos, sin el sandbox): las dos filas de la meca lado a lado; la
  discreta le tira un directo y un gancho a su cubo e imprime a cuánto conectó y cuánto lo inclinó.
- `tests/mech_hands_look.tscn` (con ventana, unos 10 segundos): las manos de la meca física, en reposo y cubriéndose.
- `tests/muscle_arm_look.tscn` (con ventana, unos 30 segundos, sin el sandbox): el brazo con músculos; la guardia, las
  cuatro piñas (velocidad de la mano, cuánto corre el bloque), la pared (se traba y vuelve) y un empujón (cede y vuelve).
- `tests/supplies_look.tscn` (con ventana, unos 5 segundos, sin el sandbox): el lote de recursos; imprime de cada cubo su
  caja, su peso y sus seis puntos de agarre.
- `tests/hand_look.tscn` (con ventana, unos 5 segundos): la mano abierta y en puño, de tres lados.
- `tests/possess_check.tscn` (con ventana, unos 15 segundos): poseer; mirar la meca, la O, las tres vistas con
  la T, soltar y retomar sin mirar; capturas del cartel.
- `tests/net_check.tscn`: dos instancias sin ventana, una con `--host-local` y otra con `--join-local` (antes del
  `--`); cada una dice cuántos jugadores, personajes y objetos compartidos ve.
- `tests/load_all.tscn`: carga todos los scripts del juego y de los tests uno por uno (el chequeo del editor no los compila a todos).
