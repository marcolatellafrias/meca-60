# Lo traído de character-parametric

`game/character/`, `game/interactables/`, `game/supplies/` (los paquetes), `game/common/`… (ver abajo qué se trajo y dónde se cortó). **Ya es código de la meca**: se edita y se simplifica.

- **El jugador** es el personaje de allá: ente (sin cuerpo, **V** vuela) o cuerpo con **B** (el gordo atlético).
- Agarrar (clic izquierdo), sentarse (**E**), empujar (**R**).
- Fila **Personajes**: los seis arquetipos, que se caen y se levantan (`CharacterGetUp`). Fila **Objetos**: paquetes y
  una silla.

## El cuerpo (13/11/2026)
Seis arquetipos (gordo, musculoso, flaco alto, chico, viejo, gordo atlético), cada uno con sus proporciones y sus
números de juego (peso, fuerza, velocidad). **Nada más**: sin trajes, sombreros ni herramientas de esculpir.
- **La forma de bloques** (`BlockShape`: unos pocos metros por arquetipo, la de fábrica en `FACTORY` o la guardada en
  `block_shapes.tres`) es el cuerpo que se ve (`BlockBody`: cajas y cápsulas) y **de ella salen todas las medidas**
  (`SkeletonSizesUtil`): los huesos, la cadera, los hombros, el alto, la cápsula, la marcha. Encima, la postura y el
  andar del arquetipo (`EntityArchetype`, con lo guardado en `pose_shapes_low.tres`), y al final su tamaño
  (`body_scale`) y la lupa.
- **La cabeza** es una forma low poly (`HeadForm`: ocho lados, una arista por loop cut, sombreado suave) llevada al alto
  de la forma de bloques. El cuello nunca es más ancho que la cabeza donde entra (si no, asomaba como papada).
- **El reposo de cada hueso** (para dónde apunta) es una tabla, `CustomBonesUtil.REST`. *Antes se leía de un modelo de
  Blender, borrado.*
- *El 13/11/2026 cambiaron dos cosas al rehacer las medidas, a propósito: la postura de hombros es el ángulo que pide el
  arquetipo (la cuenta vieja lo multiplicaba por una escala, por error: de 7° a 5° en el gordo), y las cápsulas del
  ragdoll son del ancho de la caja o el miembro de cada hueso.*

## La fila Locomoción (13/11/2026)
Para mirar cómo se mueven: seis parcelas con los seis arquetipos en carriles, que arrancan solas al entrar (K otra vez,
J y U la variante; arriba de cada uno, su velocidad):
1. **Correr y frenar**: aceleran y al final sueltan, frenan apretando para atrás o se dan contra una pared.
2. **Saltar**: una valla de 0,3, 0,6 o 0,9 m, o una viga a la altura de la cabeza que no ven.
3. **Caer de alto**: se tiran corriendo de una plataforma de 2, 4 u 8 m.
4. **Llevar y tirar**: levantan un cubo de 63 cm, lo llevan y lo tiran con la carga elegida.
5. **Atajar**: les tiran un cubo a 5, 8 u 11 m/s, de frente, alto o al costado.
6. **Esquivar barriles**: en zigzag a un costado y al otro de barriles en fila, separados (6,5 m) o juntos (4,5 m), por
   un camino fijo que no ve los barriles (la versión más simple de character-parametric, del 04/11). Corriendo chocan
   con los barriles y se frenan contra ellos (desde el 18/11 chocar no tumba); caminando, separados, pasan los seis.
*Chocar (de a dos, de frente o en ángulo) se fue el 18/11/2026: con choques de cápsula sin caídas no mostraba nada.*

Los maneja **`CharacterActions`**: aprieta los mismos botones que un jugador (moverse, correr, saltar, agarrar, tirar) y
las manos son las del jugador (un `InteractionController` con un ojo en la cabeza). Sigue un camino dado (`follow_path`, persecución pura) pero no lo busca ni esquiva nada. *Viene
de la parcela «Experimentos de locomoción» y de `ExhibitOperator` de character-parametric (unas 3.500 líneas entre los
dos), sin los pasillos de obstáculos, los botones, las sillas de la nave ni los controles.* Sus paneles, traídos de
allá. **Desde el 18/11/2026 son uno solo, el F3** (`LocomotionTuner`), en las filas Personajes y Locomoción: arriba se
elige un arquetipo (caminata, pose, movimiento, equilibrio, salto y cuerpo) o **«todos»** (caerse, llevar, tirar, el
aire, el resorte de los golpes: `LocomotionCommonKnobs`, que era el F1 aparte), con las mismas pestañas de tema.
«Guardar» y «Volver a lo guardado» actúan sobre lo elegido; «Olvidar lo guardado» vuelve al código, sólo por arquetipo.

**Las formas de cabeza, en su fila «Cabezas»** (17 y 18/11/2026). El sistema es el de character-parametric, vivo: cada
forma es una receta de números (`HeadForm`: dos tapas con diámetro, corrimiento y domo, y siete cortes de plantilla que
se prenden de a uno; los anillos son círculos, el frente plano los alinea con la tapa de abajo y el aplanamiento de la
cara es uno para todas) y la malla se arma de esos números (8 lados, sombreado suave). La parcela muestra todas, × 3,
con los arquetipos que usan cada una (`HeadFormsArchetype`), y el F3 las edita en vivo (`HeadFormsPanel`): pestañas
Forma, Cortes y Todas (el aplanamiento), «+ nueva», Guardar, Volver a lo guardado, Olvidar (vuelve a su receta) y Borrar
(sólo las agregadas). Se guardan en `head_forms.tres` (del usuario). Pruebas con captura: `tests/head_forms_look.tscn`,
`tests/head_forms_panel_look.tscn` (no guarda nada).

**El movimiento: velocidad máxima y cuánto tarda en llegar** (17/11/2026, el usuario: «un movimiento puramente
cinemático… sin mecánica de estamina, y solamente con el sistema de velocidad máxima y cuánto tiempo tarda en llegar»).
La cápsula sigue siendo la misma, pero en cada paso se le escribe la velocidad: va hacia la que pide la intención a
ritmo parejo (`top_speed / time_to_top`), para arrancar, frenar y doblar por igual; con `time_to_top` en 0, al instante
(`CharacterRigidBody3D._move`). No hay sprint ni estamina: manteniendo la tecla se gana la velocidad. Por arquetipo, en
el F3: la máxima (`sprint_multiplier`, en veces la de caminar), cuánto tarda (`time_to_top`, que reemplaza a la
aceleración) y el ritmo del paso (`speed`), que no mueve: es la velocidad a la que el paso tiene su largo de caminata, la
referencia de la animación, que sigue cambiando de forma continua con la velocidad como antes. Los de fábrica son lo que tardaba cada uno de quieto al tope antes (gordo, musculoso y flaco alto 4,6 s,
gordo atlético 3,4, chico 2,8, viejo 1,25). Las aceleraciones guardadas en el F3 se ignoran: se vuelven a afinar con
«tarda en llegar». Se fueron las fuerzas de aceleración y frenada, lo de atrás y de costado, la banda del sprint, la
estamina con su barra y **el choque blando entre personajes**: ahora chocan como dos cápsulas. El guion de la fila
Locomoción camina apretando a medias, hasta la velocidad de caminar. Las escaleras no cambiaron: la cápsula sube su
rampa y los pies pisan los escalones (ver Stairs).

**Los golpes son impulsos con nombre** (17/11/2026, el usuario: «el empuje es un impulso, no es una diferencia de
velocidad»). Todo lo que golpea de costado llama a `CharacterRigidBody3D.hit(impulso)`: la R, lo que pega en lo que se
lleva, la red, el choque de la meca. El impulso sobre la masa lo empuja; sobre la firmeza lo inclina con el resorte de
costado; si un solo golpe pasa el umbral, lo tumba y cae hacia donde lo empujaron. Lo medido queda para lo que no tiene
quien lo nombre: el aterrizaje (el resorte vertical; más alto, más hundido) y el objeto suelto que le pega. Paredes,
otros personajes y su propio movimiento ya no cuentan, nada tumba de a poco y aterrizar no tumba (el «ragdoll en el
aire» del F1 sigue, a pedido). Medido con `tests/hit_check.tscn`: 150 N·s tumba al chico y al viejo; 300, además al
flaco alto; los pesados quedan inclinados.

**De costado manda el código; para arriba, la física** (18/11/2026, el usuario: «que la cápsula no la muevan los
objetos… lo de costado sólo programático»; lo eligió viendo los dos sistemas en video, iguales a la vista). La
velocidad horizontal es la suya: lo que camina más el retroceso (`shove`), que suman los golpes con nombre y se frena al
mismo ritmo que su andar; se escribe en cada paso y lo que el motor le cambie de costado se descarta (las paredes igual
frenan), salvo que lo esté tocando un objeto suelto, que entra como `hit` con ese impulso. Lo vertical —gravedad,
salto, piso, el aterrizaje medido— sigue siendo física. Se borraron con esto la medición de costado, las capturas del
panel de impactos, los peatones que pasaban de su camino a la física, el piso que ponía quien los manejaba y los parados
fijos a bordo (unas 210 líneas). Probado con `tests/capsule_side_check.tscn`: escalera, rampa quieto y subiéndola, pared
en diagonal (se desliza mejor que antes) y un cubo que le pega (igual que antes).

**El resorte de los golpes es una pieza común** (18/11/2026, el usuario: «un solo sistema que sea robusto, así no
tenemos que mantener dos codebases»): `game/common/hit_spring.gd` (`HitSpring`), el de costado y el vertical, sacados de
la cápsula para que los usen también la meca propia y los jefes (los adapta la sesión de Jefes, que lleva el sistema
común de movimiento y reacción). La cápsula lo tiene en `spring` y sigue mostrando `impact_xz`, `impact_y` y `hit_xz`
con los nombres de siempre; los números no cambiaron (`tests/hit_check`, `tests/capsule_side_check`).

**En los golpes, sólo el peso distingue** (18/11/2026, el usuario: con el peso alcanza). La firmeza es el peso sobre
60 kg; se fueron las estabilidades de cada arquetipo de cada lado (adelante, atrás, de costado) y los multiplicadores de
estabilidad de las especies, que no usaba nadie. La dureza y el amortiguado del resorte de costado pasaron a ser de
todos, en el F1 (`impact_spring`, `impact_damp`). Con 150 N·s cae sólo el chico (antes también el viejo); con 300,
el flaco alto, el chico y el viejo; los pesados se inclinan menos que antes.

**Pintar caras sobre las cabezas** (18/11/2026, el usuario: «una misma silueta tenga varias pinturas, pero solamente
para esa silueta»). La parcela «Pintar caras» de la fila Cabezas (`HeadPaintArchetype`) muestra la forma elegida (N la
cambia) como un modelo de la herramienta de píxeles (`PixelModel`, ver [[pixel-art]]): las caras de la cabeza son
planas (cada anillo es el mismo octógono agrandado o corrido), así que la herramienta las toma tal cual y se pintan con
su panel, F1 también en esta fila. Cada pintura es un archivo (`game/character/faces/cabeza<forma>_<n>.json`, del
usuario: no se commitea) atado a su forma, con su densidad y su giro: el octógono con una esquina adelante (como
siempre) o con un lado plano adelante (`HeadForm.build_arrays(front_face)`). Lo que guarda va en el F2
(`HeadPaintPanel`): elegir la forma y la pintura, crear una nueva con la densidad (64, 100, 150 o 200 px/m) y el giro
elegidos, duplicar y borrar. En el panel chico sólo J (otra pintura) y N (otra forma), para ver (el usuario: «todas las
cosas que tienen función de guardarse tienen que ir en panel F»). Sombreado suave (`PixelModel.smooth_normals`). A
100 px/m, la cara del frente es de 7 × 7 píxeles. Prueba con captura: `tests/head_paint_look.tscn` (borra lo suyo).

**Los cosméticos de la cara: bigotes y cejas** (18/11/2026, el usuario: «cada forma de cabeza tiene una altura de boca,
una altura de ojos… cuando quiero poner un bigote… lo hago relativo a la altura de boca»). Cada forma tiene
`eye_height` y `mouth_height` (fracción del alto entero, así no cambian al escalar), en la pestaña Rasgos del F3 de la
fila Cabezas. Un cosmético (`FaceCosmetic`, en `game/character/cosmetics/`) es una tira de puntos `(x, arriba del
ancla, medio alto)` desde su ancla (ojos o boca), de punta a punta (un bigote) o espejada en dos (cejas), que se apoya
sobre LA MALLA que se ve (`HeadForm.surface_point` / `surface_normal`: el frente de cada anillo en esa `x`,
interpolado entre anillos) y sale hacia afuera; lo vertical crece con el alto de la cabeza y lo de costado con su ancho
en el ancla, así el mismo calza en todas. Los que hay están en `FaceCosmetics` (cuatro bigotes, cuatro cejas, y las
marcas de las dos alturas). En la parcela «Formas de cabeza», M cambia el bigote, K las cejas y L las marcas, sólo para
ver. Los personajes los llevan (`FaceCosmetics.worn()`, todos el bigote morsa y las cejas gruesas, «como para tener
algo por ahora»): `BlockBody._neck_and_head` los suma como la pieza `face_hair`, pegada al hueso de la cabeza y del
color `FaceCosmetics.HAIR`; en primera persona no se ven. El pelo, después: cuando estén definidos el aplanamiento y la inclinación
de las cabezas. Prueba con captura: `tests/face_cosmetics_look.tscn` (todas las formas, una captura por combinación).

**La silla fija** (18/11/2026, el usuario por la sesión de las armas: «una variante de la silla que sea fija… no se
mueve directamente con la cámara del jugador… se va a limitar a movimiento de cabeza»). `SeatInteractable.fixed` y
`look_cone` (grados de costado y arriba y abajo): sentado en una fija, el cuerpo y la silla que se ve miran al frente de
la silla —la gira otra cosa, como la torreta del artillero con su yugo— (`BoneInstantiator.fixed_seat`, `_apply_look`);
la cámara del jugador mira libre dentro del cono (`PlayerController._cap_seated_look`, `_face_camera`,
`apply_camera_pitch`) y la cabeza gira lo que se aparta del frente, con todo el cabeceo y nada del tronco
(`fixed_seat_look_yaw`, animations.gd). Sin fijar, como siempre. Prueba con captura: `tests/fixed_seat_look.tscn`.

**Lo que cuesta la fila Locomoción** (17/11/2026, diagnóstico; nada arreglado todavía): `tests/locomotion_perf.tscn` arma
las siete escenas juntas (42 personajes, 846 cuerpos rígidos) y mide de a una dimensión. Armarlas: 2,2 s en un cuadro
(el tirón al acercarse). Prendido todo: 8 fps (124 ms por cuadro). Lo que más pesa, en orden: el guion de la cápsula
—el choque blando entre personajes (`_resolve_player_collisions`) recorre a todos contra todos en cada paso, ~30 ms—,
las manos de las acciones (~20 ms), el `_physics_process` del personaje (~30 ms), la pose de cada cuadro (~14 ms) y los
cuerpos del ragdoll, que de pie se mueven con la cápsula en cada paso (~13 ms). Como un paso de física pasa los 16,7
ms, cada cuadro hace varios pasos y todo se multiplica. El dibujo casi no cuenta.

**La fila Locomoción despierta sólo con uno adentro** (17/11/2026): cada escena arma el piso y los obstáculos al
toque, pero a sus personas recién cuando uno entra a su parcela, de a una por paso, y saliendo se duerme
(`LocomotionLab`, DESPIERTA SÓLO CON UNO ADENTRO, por el aviso `entered` del arquetipo). Medido pasando por la fila en
el sandbox (`tests/locomotion_walk_perf.tscn`): de las 55 personas que llegan a armarse, despiertas a la vez quedan las de
la parcela donde uno está más las de la fila Personajes, que está al lado. Lo que sigue lento es **cada persona**:
en el sandbox unos 5 a 8 ms por cuadro cada una (aislada, unos 2,5), y pasando los 16,7 ms la física hace varios pasos
por cuadro y todo se multiplica. *Medido el 18/11/2026 (`tests/person_cost.tscn`): una persona cuesta unos 0,7 ms
por paso —la tabla procedural 0,22, las piernas 0,13, los brazos 0,13, copiar al cuerpo que se ve 0,05; la física,
0,07—: con 1 a 3 jugadores, 1 a 2 ms por cuadro, sin problema; lo del sandbox es la cantidad. El tirón al entrar era
que la escena armaba una persona por paso de física y un cuadro atrasado hacía varios pasos: ahora es una por cuadro
dibujado, y el peor cuadro bajó de unos 300 ms a unos 110 (lo que tarda armar una persona en el sandbox). La primera
persona de toda la sesión tarda 1,2 s (el motor prepara todo la primera vez).*

Pruebas:
- `tests/people_look.tscn` (con ventana, unos 12 segundos): los seis en fila, sus cabezas de cerca, y caminando 3
  segundos (imprime cuánto anduvo cada uno y si quedó de pie). `--cabezas=0.29,0.28,…` prueba altos de cabeza.
- `tests/locomotion_look.tscn` (con ventana, unos 80 segundos): cada escena de la fila Locomoción sola, con capturas;
  imprime la velocidad máxima de cada uno, cuánto anduvo, si se cayó y si tuvo el cubo.
- `tests/sizes_check.tscn` (headless, un segundo): imprime cada medida de los seis y dónde cae cada hueso. **Si un cambio
  no debería cambiar a nadie, correrlo antes y después y comparar**.

Ver también [[red]].

## Qué se trajo y dónde se cortó
El 11/11/2026, de `D:\Godot\character-parametric` (último commit allá: `50a538ef`), pieza por pieza: el personaje, agarrar,
sentarse, los controles de mano, la red (`SessionManager`, `NetSpawner`, `CharacterSpawner`…, con GodotSteam), los
paquetes y su daño (hoy en `game/supplies/`), las partículas, el sistema de sonido, la depuración del personaje
(`DebugPanel`, `TunerPanel`, `PropertyTuner`) y la interfaz (`UIState`, la consola, la pausa, el menú de inicio). Se cortó
en la ciudad, el tránsito, la nave y sus paneles.

**La frontera** (`game/character_port/`: trece piezas vacías con los nombres de allá —`City`, `CarBody`, `CityMap`,
`WeatherTuner`, `Inspector`, `ShipStyle`…— para que lo traído compilara) **se borró el 13/11/2026**, con lo que las
llamaba: el mapa (F2), el clima (F6), el carnero, los ajustes de autos y de tránsito y el inspector vacío de
`PlayerController`, la cámara del tránsito en `CharacterSpawner`, `ModelBox` (el ida y vuelta con Blender de la silla,
sin modelos acá), `WorldSeeds` y `WorldSettings` (las semillas del día y la niebla de la ciudad), los sonidos de la nave y
la ciudad del catálogo, y los paquetes de ciudad que pedía la fila Multijugador. El panel de depuración del jugador
(sólo con sesión de red) pasó de la F1 a la **F9**, la primera de los paneles globales.

**Los comentarios** dicen «el usuario» donde allá decían «el dios del juego», y «la meca» donde describían estar adentro
de algo que se mueve (allá, la nave). Las notas de allá que nombran se citan como `character-parametric:docs/…`.

**El sonido, simple** (13/11/2026, el usuario: «sonido simplificalo»): de unas 1.750 líneas a unas 230. `Sounds` busca
el archivo `assets/audio/<carpeta>/<clave>….ogg` (varios con la misma clave se sortean) y, sin archivo, suena un clic de
prueba; `SoundEntity` declara en `SOUNDS` qué clave suena en cada evento: golpes, loops, y el movimiento de un control
(MOVE_UP, MOVE_DOWN, MOVE_SELF), que se apaga solo al quedar quieto. Se fueron el catálogo, los buses, la mezcla
guardada, las variantes, las listas, las notas, los estados y transiciones, y el archivo que seguía a la mano. Test:
`tests/sound_check.tscn`.

**La animación, ordenada** (13/11/2026, con el usuario): se sacó lo que no es núcleo —los modificadores de caminata, el
de exhibición, la figura y el peatón, lo largo al llevar, lo guardado del agarre, la pose congelada— y `BoneInstantiator`
se partió en piezas (`game/character/pose/`): `CharacterSeating` (sentado y plantado), `CharacterJump` (el salto, agacharse,
echarse atrás al llevar), `CharacterPelvis` (la pelvis y la hundida al pisar) y `CharacterFall` (el ragdoll). La conducta
quedó igual, comparada contra el código de antes (locomoción, andar en la meca, sentarse: `tests/seat_check.tscn`).
Quedan, a pedido: el ragdoll en el aire, el hombro adentro, la respiración y el temblor, la caminata de cada arquetipo,
el agarre del volante y la válvula, y el freno al aterrizar.

**El jugador y lo de prueba, separados** (17/11/2026): `PlayerController` es el jugador —teclado y mouse a la
intención, cámara, HUD, el ente y el vuelo libre—; `PlayerDebug` (sólo con `debug_enabled`) tiene el panel
de depuración (F9), tirarse (G), volver a nacer (P), pasarse al cuerpo que se mira (F), los spawns y el panel de
impactos. *La pose de sostener algo con la mano que figuraba como pendiente no existe: el agarre ya está resuelto
(cubos de tamaño fijo, las manos a los costados de donde se lo agarró).* *Arreglado el 17/11/2026*: a veces, al levantarse del ragdoll, salían cientos de errores «Basis must be normalized».
La recuperación mezclaba bases de huesos (con escala) y de cuerpos compuestos cuadro a cuadro (que se desvían de una
rotación pura) con `Basis.slerp`, que exige rotaciones puras. Ahora toda mezcla pasa por `RagdollUtil._blend`, que toma
sólo el giro de cada base: ninguna base deformada puede llegar a la mezcla.

