# Cómo se mueve y cómo reacciona un cuerpo (lo común)

El sistema común a la meca propia, los jefes y los personajes (desde el 18/11/2026; lo lleva el módulo Jefes, con la
sesión de las armas —dueña de las piernas de la meca— y Personajes —dueña de su locomoción—). El plan entero y lo que
contestó cada sesión, en la nota compartida `jefes-unificar-movimiento.md`.

El usuario: «los personajes tienen un sistema en el que abstrae varios ciclos… y después usa eso para mover ciertos
huesos… tal vez sea buena idea abstraer este sistema y reutilizarlo para la meca… y de paso así compartimos código».

## El esqueleto de la meca (`MechSkeleton`, game/mech/; 18/11/2026)
El usuario: «la meca debería tener un sistema de huesos similar a las de un humano… todos los huesos deberían estar
conectados». Huesos de verdad (`CustomBone`, los de los personajes: un Node3D con largo que apunta por su +Y), en un
árbol, y LAS PIEZAS DE ARCILLA CUELGAN DE SUS HUESOS:
- cintura (la raíz) → pelvis → caderas (PUNTOS FIJOS) → muslo → canilla → pie;
- cintura → torso (la caja) → hombros (PUNTOS FIJOS) → brazo → antebrazo.

LA PELVIS ES RÍGIDA (el usuario: «los dos huesos de la pelvis… nunca pueden quebrarse… se calculan a partir de dónde
están las piernas»): un solo hueso que se mueve; las caderas cuelgan de él a una distancia fija y nada las escribe (no
son huesos). Lo mismo los hombros, del torso.

Lo arma BalanceBody (`skeleton`, con el hombro de `_shoulder`); el torso sigue a la caja (`_follow_bones`), BodyLegs
escribe la pelvis (`put_pelvis`), MechLeg los huesos de la pierna y MechArm los del brazo (`upper_bone`,
`forearm_bone`). El brazo con músculos sólo GIRA sus huesos como sus cuerpos (`MechSkeleton.aim`): la unión física
cede un poco (18 cm medidos) y el esqueleto no; su dibujo cuelga de los huesos (`move_drawing`) y los cuerpos quedan
para empujar y chocar.

PASO 2a (18/11/2026): LAS PIERNAS CON LA IK COMÚN. BodyLegs dice adónde va cada pie (el punto del piso, hacia dónde
dobla la rodilla, los ejes del pie) y `MechLeg.reach_to` gira los huesos con la IK de los personajes
(`IkUtil.solve_two_bone_ik`, estática desde ese día: una sola IK para todos, sin duplicar código), sin moverlos de donde
nacen. EL RAGDOLL SALE DEL ESQUELETO
(`PartsRagdoll._mech_parts`): un pedazo por hueso, unido a su padre en el origen del hueso; 12 pedazos (el brazo con
músculos, también en dos).

PASO 3 (18/11/2026): EL BRAZO DISCRETO CON LA IK COMÚN. `MechArm._reach_bones`: la IK de los personajes pone el codo
y la muñeca (el codo hacia `elbow_way`), y cada hueso gira sobre su largo hasta su eje del codo (`MechSkeleton.roll`),
que es de donde salen la mano y las placas. Girar el brazo gira también al antebrazo que cuelga de él: se lo deja donde
apuntaba antes de girarlo (sin eso, el antebrazo erraba hasta 16° y el cañón no le pegaba al jefe). Medido: el codo a
3 mm de la cuenta de antes (MechBody.arm), la pieza del antebrazo a 0,06°, y el cañón le saca lo mismo (2,8, 13,2 y 12,0
en tests/brawler_shots_check). El brazo con músculos sigue pidiendo su pose con MechBody.arm (lo que persiguen sus
músculos); sus huesos siguen a sus cuerpos.

PASO 2b (18/11/2026, con Cabinas separadas): LAS CAPAS SON DE LOS HUESOS. El motor pone sólo lo de juego (dónde está,
el rumbo, la caída de espaldas: `KinematicMover.body_place`) en la raíz del esqueleto; encima, la tabla común
(`MechSkeleton.setup_layers`) escribe en la cintura lo vertical (subir con el paso, el pisotón, hundirse al aterrizar)
y en el torso los giros (de costado caminando y con un golpe; adelante y atrás, sólo un golpe). EL NODO DE LA MECA VA
DONDE DICE EL TORSO (`BalanceBody._place_from_bones`), así que la cabina, el marco, las sillas y las excepciones de
choque, que cuelgan de él, lo siguen sin cambiar nada (lo acordó Cabinas separadas). La inclinación de un golpe gira
ahora sobre la cintura y no sobre el piso de los pies. Medido: la caja baja 0,58 m de un salto y 0,87 de 15 m; se
inclina 5,4° con un empujón de 6 m y 14,4° con uno de 16 (antes 15,8°, por el pivote); camina igual (sube 0,09 m, de
costado 5°). Las pruebas de Cabinas, iguales (cage_cockpit_check, seat_lag_check, crew_death_check, la huella).

PASO 5 (18/11/2026): EL JEFE SOBRE EL ESQUELETO. `MechSkeleton` se arma por piezas para cualquier cuerpo: el tronco
(`build_trunk`: la raíz, la cintura, el torso y, si tiene piernas, la pelvis), cada pierna (`add_leg`) y cada brazo
(`add_arm`, para abajo o apuntando a un codo y una muñeca); sus capas, con `layers` (la tabla común). La meca: pelvis,
dos piernas y dos brazos. EL LUCHADOR (BrawlerBody.skeleton): la raíz en las orugas, la cintura a su cadera, el torso
encorvado y dos brazos de codo fijo; lo de arriba cuelga de la cintura, lo encorvado del torso, cada brazo de sus dos
huesos. Sus capas en la tabla: hundirse al aterrizar (la cintura), la inclinación de la pose y la de un golpe y el
temblor de cargar (el torso; la tabla ganó un eje de costado, `POS_X`, que sólo vuelve a su reposo en los huesos que lo
usan); los brazos los gira la pose en el hombro. Su ragdoll sale de los huesos (6 pedazos: las orugas, lo de arriba,
los brazos en dos). Medido: igual que antes (los modos, los seis ataques, los tiros de la meca, el salto; los videos de
los golpes y de la embestida, lado a lado).

`tests/mech_skeleton_check` (sin ventana): caminando, doblando y con una piña, lo más que se separa cada hueso de
donde nace (el muslo de su cadera, la canilla de la punta del muslo, el pie, el brazo de su hombro, el antebrazo) y
que las caderas no se muevan en la pelvis: todo 0 mm, «ESQUELETO OK». La huella de `cage_mech_look` y su hoja, igual.

Por pasos (la nota compartida `jefes-revision-cuerpo-meca.md`): 1. el esqueleto sin cambio visible (HECHO: la pose la
sigue calculando el código de siempre, MechBody, y se escribe en los huesos); 2a. una sola IK sobre los huesos de las
piernas (HECHO); 2b. las capas (caminar, inclinarse, el resorte, hundirse) en la cintura y el torso, con la cabina sobre el torso (con
Cabinas; HECHO); 3. los dos brazos sobre los huesos (HECHO el discreto; el de músculos sigue a sus cuerpos); 4. el ragdoll desde el esqueleto, y su vuelta (con los
personajes); 5. el jefe (HECHO); 6. limpieza.

## Qué viaja por la red y qué se calcula en cada máquina (acordado con el usuario, 18/11/2026)
Como los personajes (character-parametric, «Multiplayer & Sync»): VIAJA LO QUE LA OTRA MÁQUINA NO PUEDE DEDUCIR; lo
deducible se calcula en cada una. LO FÍSICO VIAJA (el motor y la caja de juego); LA ANIMACIÓN (el esqueleto) se calcula
en cada máquina y sólo puede depender de lo que viaja.
- VIAJA SIEMPRE (del dueño, cada paso): dónde está el motor, hacia dónde mira y a qué velocidad va (en el marco de lo
  que la lleva); hacia dónde apunta el torso; cuánto está agachada; el estado (parada, tirada, levantándose y cuánto
  lleva); si dashea, levita o baja en picada; las dos salidas del resorte (la inclinación de un golpe, el hundirse).
- VIAJA COMO EVENTO: una piña (cuál, con cuánta carga), el modo y el gatillo del cañón, el escudo; la muerte, con el
  empujón que la mató.
- EN EL RAGDOLL: viajan el lugar y el giro del tronco; los brazos y las piernas caen como caigan en cada máquina.
- HECHO (18/11/2026) LO QUE VIAJA SIEMPRE, para todo cuerpo con equilibrio: `BodyNet` (game/balance_body/). Un dueño la
  simula (el host, o quien la posee con la O: `take_control`) y manda `KinematicMover.net_state` 20 veces por segundo;
  las demás no simulan el motor: lo ponen entre los dos estados que rodean 100 ms atrás (`KinematicMover.follow`), y el
  esqueleto, las piernas, los pies y el polvo salen igual que en la del dueño. Ver [[red]]. *Faltan los eventos y el
  ragdoll.*
- NO VIAJA: los pasos y los pies (la marcha y los rayos), la IK, el rumbo de la pelvis, el subir y bajar, el pisotón y
  la inclinación de costado, recoger las piernas, el polvo, las chispas, los destellos y los sonidos.
- LAS CAJAS DE GOLPE (la regla, acordada con el usuario y hecha el 18/11/2026):
  1. DONDE SE LE PEGA A ALGO sale sólo de lo que viaja: iguales en todas las máquinas. La meca: un cilindro del piso a
     lo alto de ahora (`KinematicMover.tall_now`, que baja al agacharse: un golpe alto le pasa por arriba); es el mismo
     alto del cilindro de su motor. El jefe (`BossHurtbox`): hasta la cintura va con las orugas, y de la cintura para
     arriba sigue a su torso (`upper` y `follow`, del alto de lo dibujado y el hondo del pecho), que sale de su giro,
     su pose y su resorte (lo que viaja): se le pega donde se lo ve.
  2. CON QUÉ SE PEGA sigue a la animación (el puño, el palo, los brazos del jefe: `Brawler.hit_shapes`): lo decide la
     máquina del que pega.
  3. LA CAJA SÓLIDA (con la que chocan las cajas y la gente) sigue al dibujo.
  Medido en `tests/hit_boxes_check` (sin ventana, unos 10 s): la meca mide 5,45 m parada y 4,22 agachada, y un golpe a
  4,83 m le pega parada y le pasa por arriba agachada. Un rayo de frente a la altura del pecho del jefe encuentra la
  caja a 0,6 m del frente del pecho dibujado quieto, a 0,7 con un golpe que lo inclina 16° y a 1,0 agachado para cavar
  (42°); antes, agachado para cavar, el pecho quedaba 2 m afuera de la caja y los tiros lo atravesaban. Los tiros le
  sacan lo mismo de pie (brawler_shots_check) y sus ataques a la meca, igual (boss_shield_check).
El usuario: el impacto viaja (lo causa un golpe que otra máquina puede no ver); el bobbing al caminar no (sale de la
velocidad, que viaja).

LA VUELTA DEL RAGDOLL, COMÚN CON LOS PERSONAJES (18/11/2026; el usuario: «la capacidad de recuperarse, aunque no haga
falta aún… así hay unificación de código»): la mezcla de cada pedazo hacia su hueso salió de RagdollUtil a
`RagdollBlend` (game/common): la raíz con su lugar y su giro, cada otro con su giro respecto del padre y su lugar sobre
él. Los personajes la usan (y le suman su pelvis que sube desde el piso y sus piernas por IK); la meca, con
`PartsRagdoll.get_up` (el cuerpo vivo se para donde quedó el tronco sin andar todavía, cada pedazo va a su hueso y al
terminar cada malla vuelve a colgar de donde salió). Para eso cada pedazo que sale de un hueso nace con su lugar y su
giro, como en los personajes. HOY LA MECA SÓLO SE DESARMA AL MORIR Y NO SE LEVANTA (el usuario: «todavía no va a entrar
en ragdoll»): queda lista. `tests/ragdoll_rise_check`: los seis arquetipos de personaje se caen y se levantan (de 3,0 a
4,4 s, los cuerpos a menos de 10 cm de sus huesos); la meca muere en 12 pedazos, revive, se levanta (ninguno queda, el
esqueleto a 0 mm) y camina.

## Las piezas (todas son DIBUJO: no se sincronizan, cada máquina las saca de lo que viaja)
1. **La marcha** (`Gait`, game/common/, 18/11/2026): cuándo y adónde pisa cada pata, para 2, 4 o 6. **Un ciclo
   continuo**, como se hace en todos lados: cada grupo de patas (`Gait.pattern`: dos, de a una; cuatro, las
   diagonales; seis, el trípode) tiene su desfase y se reparten el ciclo (`swing_part`: apenas uno pisa, sale el otro,
   con un instante de todos apoyados). El ciclo avanza con lo que anda (uno por `stride` m, o lo que recorre la pata de
   más afuera girando; con topes). Cada pie pisa donde va a estar su lugar a mitad de su apoyo (el lugar al pisar más
   medio apoyo de avance, girado si gira): el apoyo queda centrado y no se corre. Quieto, cada grupo da un paso hasta su
   lugar y el ciclo se para; lo poco corrido no da pasitos (`settle_gap`). Sin BalanceBody. Las rodillas, con la IK común
   (`IkUtil.bend_point`). **Más de meca** (18/11/2026; el usuario: «pasos más largos o cosas así»): el paso de la jaula es el
   doble de largo y más lento, con PISOTÓN (`stomp`: el pie llega alto y adelante y baja de golpe) y al pisar la caja
   se hunde (`GaitSignals.plant`, `LegSettings.stomp_dip`).
   *La primera versión (el mismo día) era la regla de la jaula: un pie sale al quedar un tercio de paso atrás y pisa un
   tercio adelante. Entre un paso y el otro un tercio del ciclo nadie estaba en el aire; el usuario: «hacen paso, paso,
   pausa». Medido en el mismo recorrido: sin ningún pie en el aire el 21 % del tiempo andando, en pausas; ahora el 10 %,
   parejo entre paso y paso.*
   **LA JAULA LA USA** (18/11/2026, con el aviso a las armas): los pasos nuevos de BodyLegs son un Gait de dos caderas
   (los lugares de `MechBody.foot_rest`, el piso de BodyLegs; las perillas del F4, LegSettings). BodyLegs sigue con el
   giro de cada pie, la pelvis, las rodillas, la caída y recogerlas. En `tests/cage_legs_movie`, caminando: sin ningún
   pie en el aire el 20 % del tiempo antes, el 10 % ahora.
   **LOS JEFES CON PATAS LA USAN** (18/11/2026): las piernas «patas» del catálogo de jefes (BossParts.LEGS: dos patas
   y cuatro, con su `walk`: cada cadera, dónde se para su pie, hacia dónde dobla la rodilla, los largos y el paso) son
   `BossLegs` (game/bosses/parts/): EL MISMO ESQUELETO QUE LA MECA (MechSkeleton: el tronco con su pelvis y una pierna
   por pata), la marcha común y la IK común (`IkUtil.solve_two_bone_ik`). El armazón (BossFrame) mide solo a qué
   velocidad lo mueven: quien lo mueva no les dice nada. Las de cuatro pisan las diagonales, con la rodilla arriba y
   afuera, como una araña. En `tests/boss_walk_movie` (con ventana; el mismo recorrido que gait_movie): 29 y 28 pasos,
   ningún pie apoyado se corre y las canillas no se separan de sus muslos (0 mm). PISAN EL PISO DE VERDAD, cada pie a su
   altura: un rayo desde la cadera, contra lo fijo del mundo (lo mismo que frena a la meca); las rodillas lo absorben.
   En la prueba, una tarima de 1,5 m en el camino: los dos pisan arriba a 1,50 m, sin correrse. *Falta: que un jefe con
   patas pelee.*
   **RECOGER LAS PIERNAS** (18/11/2026; las reglas las acordó el usuario): recogidas, de una, en un DASH (en el piso
   también), LEVITANDO y BAJANDO EN PICADA, SUTIL (el usuario: «parecerse a la pose en reposo pero un poco más
   recogida nomás, y con los pies un poco apuntando hacia abajo»: la pose de parada con el pie subido `tuck_lift` de la
   altura de la pierna, 0,25, y la punta `tuck_toes` hacia abajo, 30°; F4, «Recogidas»); en un salto común o una caída,
   cuelgan; al terminar, se plantan debajo de
   las caderas. Lo decide el motor (`KinematicMover.tucks()`), sólo con lo que sabe seguro y NUNCA con los rayos de los
   pies (en un dash de costado en el piso siguen tocando). Las transiciones son instantáneas (el usuario: «para
   simplificar… instantánea por ahora, y después vemos si queda mal»). En `tests/cage_legs_movie`: recogidas 0,35 s en
   el dash, 1,45 s levitando, 0,14 s en picada, y nunca caminando ni en el salto común.
   `tests/gait_movie` (el video: un cuerpo de 4 y uno de 6, arrancar, doblar, frenar, de costado, girar en el lugar,
   correr; imprime la pausa y lo que se corre un pie apoyado). *Falta: usarla en los jefes de patas (BossParts
   «cuatro»).*
2. **Las señales** (`MotionSignals`, game/common/): lo que lee la tabla. La base común; cada cuerpo las calcula a su
   manera (los personajes, `LocomotionSignals`, de sus dos pies; los de patas, `GaitSignals`, de su marcha: el arco del
   paso, la velocidad en sus ejes suavizada). Normalizadas por el largo de pierna. **Hecho.**
3. **Los resortes** (`HitSpring`, game/common/, lo sacó Personajes de su cápsula): golpe y aterrizaje. **Hecho.**
   **CADA CUERPO ES DUEÑO DEL SUYO** (`body_spring`, 18/11/2026): la jaula, en su motor (`KinematicMover.body_spring`);
   el Luchador, en `Brawler.body_spring`. El cuerpo lo actualiza y lo dibuja en `body_place` / `_place_upper`: la
   inclinación (`HitSpring.tilt_degrees()`; la jaula gira sobre el piso de sus pies, después de la caída; el Luchador,
   lo de arriba sobre la cintura) y lo que se hunde (`y`). Sólo dibujo: el motor no se mueve (adentro se camina).
   - **De costado, los golpes**: los pasa quien pega (`HitReaction.sway`). Los ataques del jefe inclinan a la meca
     según cuánto empujan (`SWAY_PER_M`); las piñas de la meca inclinan al jefe según su fuerza (perilla `hit_sway`
     del Luchador, F1, Golpes). Medido: el jefe 4° con una piña floja, 13° con un directo, 16° con un mazazo; la jaula
     5° con un empujón de 6 m y 16° con uno de 16. `tests/hit_sway_movie` (el video).
   - **Vertical, el aterrizaje**: lo mide cada motor (a cuánto bajaba el paso en que tocó el piso; el Luchador, lo más
     rápido de ese paso y el anterior, porque el arco del salto llega un paso antes). La jaula se hunde `land_sink` m
     cayendo a `land_full_speed` m/s (KinematicSettings, grupo Aterrizar; 0,6 m a 20 m/s): 0,40 m de un salto, 0,60 m
     en picada. El Luchador, `LAND_SINK` m de la maqueta a `LAND_FULL` m/s (3 a 80): 1,8 m de un salto de 12 m de
     alto, 3 de uno de 25. `tests/land_spring_movie` (el video).
     **Con peso en el quiebre** (18/11/2026; el usuario: «el peso se siente en el quiebre inicial nada más»; la vuelta,
     «siempre… relativamente snappy, nunca… sluggish»): la jaula sale hacia abajo como un impacto (`HitSpring.land_push`:
     llega justo a lo más hondo, hasta 0,9 m, con cualquier rebote: `_peak_per_speed`) y vuelve en `land_recover` (0,22
     s; el usuario: «un poco más rápida la vuelta») CON RESORTE (`land_bounce`, 0,7; el usuario: «siempre con resorte»).
     Medido: vuelve del fondo en 0,10 s y rebota hasta 0,14 m para arriba. EL LUCHADOR, IGUAL (`LAND_RECOVER` 0,25 s,
     `LAND_BOUNCE` 0,7; el usuario: «en la oruga sigue volviendo más lento»): vuelve en 0,12 s. **Y POLVO** cayendo fuerte (`dust_speed`, 16 m/s: un salto no, en picada
     y de 15 m sí): un anillo a ras del piso que rueda para afuera (`ParticleSystems.landing_dust`, la variación del
     polvo de golpe; fila Partículas). Lo detecta el motor: el paso en que `is_on_floor` pasa a verdadero, con la
     velocidad de caída de antes de moverse.
   *Falta pasar sus salidas a señales de la tabla (hoy los personajes las leen por fórmula en animations.gd).*
4. **La tabla** (`ProceduralBoneAnimator`): cada fila es (qué mueve, en qué eje, qué señal, peso, escala, curva); en
   cada pasada todo vuelve a su reposo y se le suma lo suyo. Ahora mueve **cualquier Node3D** (huesos de un personaje o
   piezas de una meca o un jefe) y lee **cualquier `MotionSignals`**. Quién mueve qué lo dice cada cuerpo (en los
   personajes, animations.gd). **Hecho**; `tests/procedural_node_check` (sin ventana): un torso de arcilla se inclina
   11,5° yendo de costado a 4 m/s y la pelvis baja 0,2 m a mitad de un paso, y vuelven.
   **LA JAULA LA USA** (18/11/2026): BodyLegs tiene sus señales (`GaitSignals`) y dos filas que mueven una pieza sin
   dibujo (`pose_offset`), que el motor compone en la caja (`KinematicMover.body_place`, sobre el piso de la caja): SUBE
   a mitad de cada paso (`LegSettings.bob`, 0,5 m de piernas medianas: 0,15 m en la jaula) y SE INCLINA DE COSTADO según
   la velocidad de costado (`side_lean`, 5° a la de caminar; de frente, nunca). F4, «La caja al caminar». El usuario:
   «una curva leve de subir y bajar la pelvis… le da el feeling de meca»; «adelante y atrás, nunca». En
   `tests/cage_legs_movie`: sube hasta 0,15 m, de costado 5°, de frente 0,3° (el instante de doblar).
5. **Un solo IK de dos huesos** (18/11/2026, la limpieza): `IkUtil.solve_two_bone_ik` sobre huesos y, sin huesos, su
   misma cuenta `IkUtil.bend_point` (las poses de MechBody: lo que persigue el brazo de músculos; las patas de gait_movie). *Se fueron `MechBody.joint` y `Gait.knee`.*

`tests/cage_legs_movie` (con ventana): **el video de base** de las piernas de la jaula hoy, caso por caso (arrancar,
frenar, doblar de golpe, girar en el lugar, de costado, el dash, saltar, levitar, bajar agachada), con una grilla en el
piso para ver si patinan.

Aparte, porque es MOVIMIENTO y no dibujo:
- **El retroceso por golpe** (18/11/2026; el usuario preguntó si era «un impulso con gravedad»): en la meca cinemática,
  `KinematicMover.knock(velocidad)` (o `BalanceBody.knock_back`): una velocidad que se frena sola. En el piso, un roce
  parejo (`knock_friction`, 40 m/s²: recorre v²/2·roce); en el aire se frena de a poco (`knock_drag_air`) y cae con la
  gravedad de siempre, así que si lo levanta sale en curva; contra una pared se corta; se maneja otra vez apoyada y casi
  quieta (`knock_stop`). `shove(metros, _, saltito)` sigue para quien pega en metros: es el impulso que recorre eso en el
  piso. El revoleo del agarre, que tiene que caer en un punto, es otra cosa: `carry`, un camino guionado. *Hasta ese día
  `shove` era un camino guionado, y al terminar la meca seguía deslizándose con la inercia de caminar (en la prueba del
  escudo se iba unos 90 m: por eso el lanzallamas pegaba una sola ráfaga; ahora, quieta, las tres).* Medido en
  `tests/knock_back_movie` (el video): 6 y 16 m en el piso recorren 6,0 y 16,0 m y se maneja a los 0,5 y 0,9 s; tirada
  con saltito y en el aire, unos 14 m en curva; contra una pared, se corta.
- **El ragdoll al morir** (18/11/2026; el usuario: «todos… se caen con ragdoll al morir; los grandes, quizás más lento
  para que se lea la escala»): `PartsRagdoll` (game/common), para los cuerpos de piezas; los personajes siguen con el
  suyo de huesos (RagdollUtil). Lo dispara la vida (`Health`, al morir: `falls_apart`).
  - UN ESQUELETO CONECTADO (el usuario: «todos los huesos deberían estar conectados»): cada parte es un hueso unido a su
    padre en su punto de verdad (ConeTwistJoint3D con límite). La jaula: el tronco con SU CAJA DE VERDAD (la del cuerpo;
    antes envolvía todo su dibujo —cabina, sillas, maniquíes— y quedaba flotando), la pelvis en la cintura, cada pierna
    desde la pelvis (cadera, rodilla, tobillo) y cada brazo en dos (el brazo en el hombro, el antebrazo con la mano y lo
    que lleva en el codo; un brazo sin esas piezas, entero en el hombro): 11 pedazos.
  - CAJAS Y PESO, UNA REGLA: cada pieza de arcilla es su propia caja y pesa por su volumen (`DENSITY`), igual para
    todos; el tronco, con su caja de verdad. Así el torso pesa lo que pesa (la jaula: unos 9.400 kg; un brazo, 700 a
    1.400; un tramo de pierna, 170 a 460). *Antes cada hueso era una caja que envolvía su dibujo: un brazo estirado
    pesaba casi como el torso y lo frenaba (el usuario: «los brazos frenan el torso, que se supone que es mucho más
    pesado»), y el brazo entero era un palo rígido que se veía desconectado.* Las articulaciones doblan más (60°) y casi
    no frenan (`SPIN_DAMP`): lo que pesa manda. El Luchador
    (`Brawler.ragdoll_parts`): las orugas, lo de arriba en la cintura y cada brazo en su hombro (4).
  - SALE COMO LO EMPUJÓ EL GOLPE QUE LO MATÓ (el usuario: «se controla en base al hit»): quien pega dice el empujón
    (`Health.hurt(…, push)`: los ataques del jefe, `HitReaction.push_velocity`, el mismo que el retroceso; las piñas de
    la meca al jefe, por su fuerza, `BrawlerSettings.death_push`). El ragdoll se lleva una parte (`PUSH_SHARE`,
    `LIFT_SHARE`: con todo, rodaba 100 m) y se vuelca hacia allá (lo de arriba, más). Sin empujón, se desploma.
  - Con roce contra el piso, algo de freno, sin chocar entre ellos; los grandes caen más lento (`gravity_for`: la
    jaula, entera; el Luchador, 0,63). El destello del golpe se apaga antes (si no, quedaba blanco). El cuerpo vivo se
    apaga.
  `tests/ragdoll_movie` (el video): la jaula muerta por un golpe fuerte de frente (sale tirada unos 20 m), por un
  empujón de costado y sin empujón; el jefe, por una piña fuerte. *Primera versión: no hay vuelta (para volver a
  pelear se rearma la parcela) y lo que viaja adentro de la jaula no se mira.*

## Lo de la jaula que no hay que pisar
La inclinación al apuntar (`CageMech._tilt`, cabin.rotation.x: la inclinación de costado se suma, no la reemplaza),
`BodyLegs.facing_yaw` (lo lee `CageMech.upper_heading`), las placas sobre `MechLeg._thigh` y `_shin`, la silla de abajo
(las piernas no la atraviesan) y bajar agachado en el aire (`dive_speed`, un caso de «recoger»).
