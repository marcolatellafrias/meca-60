# El cuerpo por piezas (la regla común de la meca y los jefes)

**Acordado con el usuario el 14/11/2026; todavía no está hecho.** Lo escribió el módulo Jefes. Del lado de la meca, la
separación es de la Meca ([[base-comun]]); del lado de los jefes, de Jefes ([[pelea-jefes]]). El usuario: «prefiero que se
pueda cambiar cada parte independientemente… el torso puede ser discreto o físico, brazos discretos o físicos, y se
cambian independientemente. Y también tengo el toggle de visualizarlo simplificadamente. Y lo mismo para el boss bola». *El jefe bola se borró el 15/11/2026; la regla vale para los jefes humanoides que siguen.*

## Por qué
Hoy la meca tiene cuatro tipos cerrados (física, mixta, cinemática, simplificada) y los jefes, uno solo cada uno. Cada
combinación nueva pide otra variante más; por ejemplo, el torso discreto con brazos físicos no existe. Con piezas que se
eligen por separado salen todas las combinaciones con menos código.

## Las piezas de un cuerpo
| Pieza | Qué es | Opciones | En la meca | En el Luchador (el jefe que sigue) |
|---|---|---|---|---|
| **Torso** | la forma del cuerpo, que **es su hitbox**: una forma simple (a lo sumo, más adelante, dos) | — | una caja | una caja |
| **Motor del torso** | quién lo mueve | **discreto** (el controlador de personaje del motor contra lo fijo, `KinematicMover`) o **físico** (un cuerpo simulado: el péndulo de `BalanceBody`) | los dos | primero, discreto |
| **Piernas** | los pies que pisan; el cuerpo les dice adónde, y el IK hace el resto | — | sus piernas | las orugas |
| **Brazos** (o armas) | lo que pega | **ninguno**, **discretos** (de pose) o **físicos** (con músculos) | los tres | los suyos, discretos |
| **Dibujo** | cómo se ve | **completo** o **simplificado**: la hitbox más las piernas, sin cabina, brazos ni detalles | los dos | los dos |

Se eligen con tres interruptores (motor, brazos, dibujo). Los tipos de hoy son combinaciones:

| Tipo de hoy | Motor | Brazos | Dibujo |
|---|---|---|---|
| Física | físico | físicos | completo |
| Mixta | físico | discretos | completo |
| Cinemática | discreto | discretos | completo |
| Simplificada | cualquiera | ninguno | simplificado |

La simplificada deja de ser un tipo aparte: es **cualquier cuerpo sin brazos y con el dibujo simplificado**.

## Lo que no cambia según las piezas
- **Lo que se le pide** es igual con los dos motores: `move`, `aim_yaw`, `jump`, `crouch`, `dash`… (y lo de cada cuerpo:
  sus ataques en cada jefe). Lo escriben las teclas de poseer, las consolas o la cabeza del jefe.
- **Lo que mide**, también: si está apoyado, su velocidad, **su punto del piso**, su radio y su alto. Lo necesita quien lo
  pelea (el jefe bola lo calculaba a mano según el motor).
- **Los movimientos discretos usan las curvas** (`MoveCurve`, `MoveRamp`; ver [[base-comun]]): los de un tramo (el dash,
  el salto, una carga) con su curva, y los sostenidos (caminar, rodar) con sus rampas.

## Lo que sí cambia según el motor (ver [[pelea-jefes]])
- **Choque.** Un cuerpo discreto choca sólo con lo fijo del mundo. Por eso lo grande que se mueve y tiene que pararlo,
  como el cuerpo de un jefe, va también en esa capa: es una pared para él, y si se le mete encima, su motor lo saca. Un
  cuerpo físico choca como el cuerpo que es.
- **Golpe.** La vida baja igual, por código. Al físico, además, lo empuja (`BalanceBody.hit`) y su péndulo decide si cae.
  Al discreto, por ahora, sólo la vida.

## El orden
1. La Meca separa en su código el motor del torso, los brazos y el dibujo, **después del commit del Interior**, que está
   cambiando `mech.gd` y `game/mech/` por la cabina nueva.
2. Jefes arma al Luchador en el mismo molde (primero, discreto) y, después, el interruptor de dibujo simplificado y el
   motor físico.
3. En la parcela del jefe, la meca que pelea se elige con los tres interruptores.
