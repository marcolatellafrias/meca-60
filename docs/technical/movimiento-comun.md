# Cómo se mueve y cómo reacciona un cuerpo (lo común)

El sistema común a la meca propia, los jefes y los personajes (desde el 18/11/2026; lo lleva el módulo Jefes, con la
sesión de las armas —dueña de las piernas de la meca— y Personajes —dueña de su locomoción—). El plan entero y lo que
contestó cada sesión, en la nota compartida `jefes-unificar-movimiento.md`.

El usuario: «los personajes tienen un sistema en el que abstrae varios ciclos… y después usa eso para mover ciertos
huesos… tal vez sea buena idea abstraer este sistema y reutilizarlo para la meca… y de paso así compartimos código».

## Las piezas (todas son DIBUJO: no se sincronizan, cada máquina las saca de lo que viaja)
1. **La marcha**: cuándo y adónde pisa cada pata (2, 4 o 6; grupos alternada, diagonal, trípode; pisar o recoger).
   *Falta.*
2. **Las señales** (`MotionSignals`, game/common/): lo que lee la tabla. La base común; cada cuerpo las calcula a su
   manera (los personajes, `LocomotionSignals`, de sus dos pies). Normalizadas por el largo de pierna. **Hecho.**
3. **Los resortes** (`HitSpring`): golpe y aterrizaje, como dos señales más. Los saca Personajes. *En curso.*
4. **La tabla** (`ProceduralBoneAnimator`): cada fila es (qué mueve, en qué eje, qué señal, peso, escala, curva); en
   cada pasada todo vuelve a su reposo y se le suma lo suyo. Ahora mueve **cualquier Node3D** (huesos de un personaje o
   piezas de una meca o un jefe) y lee **cualquier `MotionSignals`**. Quién mueve qué lo dice cada cuerpo (en los
   personajes, animations.gd). **Hecho**; `tests/procedural_node_check` (sin ventana): un torso de arcilla se inclina
   11,5° yendo de costado a 4 m/s y la pelvis baja 0,2 m a mitad de un paso, y vuelven.
5. **Un solo IK de dos huesos.** *Falta.*

Aparte, porque es MOVIMIENTO y no dibujo: el retroceso por golpe (una velocidad que se frena sola, con la gravedad de
siempre) y el ragdoll al morir, para todos. *Falta.*

## Lo de la jaula que no hay que pisar
La inclinación al apuntar (`CageMech._tilt`, cabin.rotation.x: la inclinación de costado se suma, no la reemplaza),
`BodyLegs.facing_yaw` (lo lee `CageMech.upper_heading`), las placas sobre `MechLeg._thigh` y `_shin`, la silla de abajo
(las piernas no la atraviesan) y bajar agachado en el aire (`dive_speed`, un caso de «recoger»).
