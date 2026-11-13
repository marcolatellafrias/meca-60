# Los jefes: las mecas enemigas

**Trabajo en curso** (13/11/2026). `game/bosses/`, del módulo Meca hasta que arranque el de Jefes (ver [[modulos]]).
Lo que comparten con la meca propia, en [[base-comun]]. El diseño, en [[contratos]] y [[la-meca]].

## El rumbo
El usuario quiere ver **cómo se siente pelear**, no sólo esquivar. Los jefes se arman **de a uno, a mano**, entre los
dos: «prefiero hacer un sistema más o menos e ir haciendo unos bosses de uno a uno». Y después: «propongo hacer el boss
por separado y después en todo caso podemos unirlos». Por eso **el próximo jefe va suelto, con su propio código**. Las
piezas de abajo quedan como un borrador, y se juntan sólo si sirve.

## Las piezas (borrador, suelto a propósito)
Una meca enemiga es el mismo cuerpo con equilibrio que la propia (`BalanceBody`, el péndulo), sin cabinas adentro, sin
puertas, sin controles y sin ascensor. **El torso es libre**, y lo demás **se encaja con un offset** (el usuario: «se
encajan solamente con una variable que es un offset que las pone bien»).
- `BossDesign`: el torso (una caja o redondo), la pelvis, las patas (`legs_offset`), los brazos, lo del pecho
  (`chest_offset`) y la paleta. **No es un catálogo rígido**: cada brazo tiene una **mano** (puño, sierra o taladro) y,
  aparte, algo **montado en el antebrazo** (ametralladora, cohetes, misiles guiados o bombas). «Una ametralladora puede
  ir en el antebrazo y mantener la mano».
- `BossMech`: arma las piezas y **tiene vida**. La meca propia no tiene vida (ver [[la-meca]]). Las piñas de la meca
  propia (`PoseArm`) le sacan vida según la velocidad a la que conectan. Sin vida se cae y no se levanta más
  (`BalanceBody.broken`).
- `BossLegs`: dos patas, cuatro, o seis que salen de los costados (araña). Pisan por grupos que se turnan, con pasos de
  largo fijo. En el aire, las patas cuelgan.
- `BossRolling`: orugas o ruedas.
- `BossArm`: cada ataque tiene tres partes, preparar, hacer y volver.
- `BossChest`: el cañón, que sube y gira despacio hasta tenerte en la mira, o el ojo, que barre el piso con un láser.
- `BossBrain`: elige el blanco y la distancia (de borde a borde) y ataca de a un ataque por vez. Con menos vida, ataca
  más seguido. Corre sólo en el host.
- `BossPalette`: cuatro colores por meca (la cabina, los tubos, las articulaciones y los detalles).
- `BossHealthBar`: la vida, arriba de la pantalla.

## Cómo se esquiva cada ataque
| Se esquiva | Ataques |
|---|---|
| **Saltando** (al ras del piso) | la onda al caer de un salto; la del puño que golpea el piso; el barrido del láser |
| **Agachándose** (una pared alta, `low` en AreaStrike) | la sierra tirada |
| **Cambiando de rumbo** | la ráfaga, que tira a donde vas a estar; los misiles guiados, que te siguen hasta poco antes de caer |
| **Alejándose** | la sierra y el taladro de cerca, que te sacuden mientras estés al alcance; la piña |

**Cada bando no se pega a sí mismo** (`BalanceBody.team`, `AreaStrike.spares`). Antes, el jefe se empujaba solo con
la onda de su propio salto, que nace debajo de él.

Medido el 13/11/2026 con `tests/boss_arena_look`, con la meca propia quieta: las ondas, el láser, la sierra tirada y la
piña la empujan unos 9 m/s y la inclinan 12°, sin tirarla. Agachada, la sierra tirada no la toca. La sierra de cerca la
sacude de a 1,8 m/s. La ráfaga casi no la mueve.

## La Arena del jefe (fila del sandbox)
El mismo redondel que la Arena de esquivar, con el **Jefe de prueba** en el medio (dos piernas, una sierra, un puño con
ametralladora y el ojo láser) y la Meca discreta para poseer con la O.
- **P**: pelea o se queda quieta.
- **K**: el próximo ataque, ya.
- **H**: le saca 25 de vida.
- **U**: sube a la meca propia.
- **R**: vuelve a armar la arena.

## Lo que falta
- El primer jefe de verdad, suelto, armado entre los dos.
- El puño que agarra autos o postes y los tira.
- Que la meca propia reciba daño.
- La red: el cerebro y los ataques corren en el host. Los brazos del jefe no se ven moverse en los clientes, y no está
  probado con dos instancias.
