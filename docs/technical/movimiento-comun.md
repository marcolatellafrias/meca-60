# Cómo se mueve y cómo reacciona un cuerpo (lo común)

El sistema común a la meca propia, los jefes y los personajes (desde el 18/11/2026; lo lleva el módulo Jefes, con la
sesión de las armas —dueña de las piernas de la meca— y Personajes —dueña de su locomoción—). El plan entero y lo que
contestó cada sesión, en la nota compartida `jefes-unificar-movimiento.md`.

El usuario: «los personajes tienen un sistema en el que abstrae varios ciclos… y después usa eso para mover ciertos
huesos… tal vez sea buena idea abstraer este sistema y reutilizarlo para la meca… y de paso así compartimos código».

## Las piezas (todas son DIBUJO: no se sincronizan, cada máquina las saca de lo que viaja)
1. **La marcha** (`Gait`, game/common/, 18/11/2026): cuándo y adónde pisa cada pata, para 2, 4 o 6. **Un ciclo
   continuo**, como se hace en todos lados: cada grupo de patas (`Gait.pattern`: dos, de a una; cuatro, las
   diagonales; seis, el trípode) tiene su desfase y se reparten el ciclo (`swing_part`: apenas uno pisa, sale el otro,
   con un instante de todos apoyados). El ciclo avanza con lo que anda (uno por `stride` m, o lo que recorre la pata de
   más afuera girando; con topes). Cada pie pisa donde va a estar su lugar a mitad de su apoyo (el lugar al pisar más
   medio apoyo de avance, girado si gira): el apoyo queda centrado y no se corre. Quieto, cada grupo da un paso hasta su
   lugar y el ciclo se para; lo poco corrido no da pasitos (`settle_gap`). Sin BalanceBody. Trae el IK de dos huesos
   (`Gait.knee`).
   *La primera versión (el mismo día) era la regla de la jaula: un pie sale al quedar un tercio de paso atrás y pisa un
   tercio adelante. Entre un paso y el otro un tercio del ciclo nadie estaba en el aire; el usuario: «hacen paso, paso,
   pausa». Medido en el mismo recorrido: sin ningún pie en el aire el 21 % del tiempo andando, en pausas; ahora el 10 %,
   parejo entre paso y paso.*
   **LA JAULA LA USA** (18/11/2026, con el aviso a las armas): los pasos nuevos de BodyLegs son un Gait de dos caderas
   (los lugares de `MechBody.foot_rest`, el piso de BodyLegs; las perillas del F4, LegSettings). BodyLegs sigue con el
   giro de cada pie, la pelvis, las rodillas, la caída y recogerlas. En `tests/cage_legs_movie`, caminando: sin ningún
   pie en el aire el 20 % del tiempo antes, el 10 % ahora.
   `tests/gait_movie` (el video: un cuerpo de 4 y uno de 6, arrancar, doblar, frenar, de costado, girar en el lugar,
   correr; imprime la pausa y lo que se corre un pie apoyado). *Falta: usarla en los jefes de patas (BossParts
   «cuatro»); «recoger» (dash, aire).*
2. **Las señales** (`MotionSignals`, game/common/): lo que lee la tabla. La base común; cada cuerpo las calcula a su
   manera (los personajes, `LocomotionSignals`, de sus dos pies). Normalizadas por el largo de pierna. **Hecho.**
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
   *Falta pasar sus salidas a señales de la tabla (hoy los personajes las leen por fórmula en animations.gd).*
4. **La tabla** (`ProceduralBoneAnimator`): cada fila es (qué mueve, en qué eje, qué señal, peso, escala, curva); en
   cada pasada todo vuelve a su reposo y se le suma lo suyo. Ahora mueve **cualquier Node3D** (huesos de un personaje o
   piezas de una meca o un jefe) y lee **cualquier `MotionSignals`**. Quién mueve qué lo dice cada cuerpo (en los
   personajes, animations.gd). **Hecho**; `tests/procedural_node_check` (sin ventana): un torso de arcilla se inclina
   11,5° yendo de costado a 4 m/s y la pelvis baja 0,2 m a mitad de un paso, y vuelven.
5. **Un solo IK de dos huesos**: `Gait.knee` (lo usan las patas de la marcha). *Falta que lo usen la jaula y los
   personajes.*

`tests/cage_legs_movie` (con ventana): **el video de base** de las piernas de la jaula hoy, caso por caso (arrancar,
frenar, doblar de golpe, girar en el lugar, de costado, el dash, saltar, levitar, bajar agachada), con una grilla en el
piso para ver si patinan.

Aparte, porque es MOVIMIENTO y no dibujo: el retroceso por golpe (una velocidad que se frena sola, con la gravedad de
siempre) y el ragdoll al morir, para todos. *Falta.*

## Lo de la jaula que no hay que pisar
La inclinación al apuntar (`CageMech._tilt`, cabin.rotation.x: la inclinación de costado se suma, no la reemplaza),
`BodyLegs.facing_yaw` (lo lee `CageMech.upper_heading`), las placas sobre `MechLeg._thigh` y `_shin`, la silla de abajo
(las piernas no la atraviesan) y bajar agachado en el aire (`dive_speed`, un caso de «recoger»).
