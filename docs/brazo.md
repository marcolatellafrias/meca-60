# Los brazos

Ver [[filas]] y [[meca]] (los dos caminos).

## Lo que se le pide a un brazo — `MechArm` (`game/mech/`)
Escrito una vez, para los dos caminos: **las posturas** (normal, cubriéndose, recogido), **las piñas** (unos pocos puntos
por donde pasa el puño, con sus tiempos: se arma, pega, se queda, vuelve), **la pose** (el codo y la muñeca por IK,
`MechBody.arm`) y **la mano**, montada por regla.

## El brazo discreto — `PoseArm` (`game/pose_arm/`) · fila **Meca discreta**
Se dibuja en la pose pedida, sin cuerpos: va exacto, no se traba y atraviesa lo que haya. **Mientras pega**, el puño
barre su camino en el mundo (la regla del puño de la vieja meca de pelea) y a cada cuerpo suelto que toca le da, una vez
por piña, **un impulso** en el punto del golpe: su velocidad por `HIT_MASS` (7 t). A otra meca la empuja en su caja y su
péndulo decide. Medido: un directo conecta a 42 m/s e inclina al cubo 7°, sin tirarlo. Lo fijo no lo frena.

## El brazo con músculos — `MuscleArm` (`game/muscle_arm/`) · filas **Brazo** y **Meca física**

El primer paso de los brazos físicos de la meca, solo en su fila para tunearlo: un torso fijo en el aire con **un**
brazo. La idea es la de PuppetMaster: **la IK dice la pose; el cuerpo físico la persigue con músculos**.

## Las dos capas
- **La pose que se pide**: dónde quiere el puño (en guardia, a lo largo de una piña, o donde lo lleva el mouse) y, de
  ahí, el codo y la muñeca: la IK del cuerpo de la meca (`MechBody.arm`), la misma del dibujo.
- **El cuerpo físico**: el **brazo** y el **antebrazo** (con la mano en la punta, [[meca]] usa la misma) son
  cuerpos sueltos. **El hombro es una bola** y **el codo una bisagra**, como los de verdad. Un **músculo** por
  articulación, con resorte, freno y **fuerza tope**:
  - el del hombro gira el brazo hacia la orientación pedida, incluido el giro sobre su largo, que es el que lleva el
    antebrazo de costado;
  - el del codo sólo dobla, sobre el eje de su bisagra, y empuja al brazo para el otro lado.

## Lo que sale solo
- **Se traba**: contra algo fijo se queda ahí, empujando con su fuerza, y cuando se le pide volver, vuelve.
- **Cede**: si le pegan, se corre y vuelve a su lugar.
- **La fuerza de la piña** es la velocidad a la que llegó la mano: el bloque sale según eso.

## Cómo se prueba
- **1** directo · **2** gancho · **3** uppercut · **4** desde arriba. Cada piña son unos puntos por los que se pide
  que pase el puño, con sus tiempos (se arma atrás, pega, se queda un instante y vuelve a la guardia).
- **N** pone una pared donde está el bloque (y lo guarda), o la saca. **J/K**, una bola liviana o pesada contra el brazo. **R** vuelve a armar todo.
- **F1** las perillas (`MuscleArmSettings`): el resorte, el freno y la fuerza del músculo; cuánto más rápidas las piñas.
- **A mano** ([[poseer]]: mirándolo, **O**): el mouse lleva la mano de costado y arriba y abajo, W/S adelante y atrás.
- `tests/muscle_arm_look.tscn` (unos 30 s, sin el sandbox).

## Lo medido (12/11/2026)
| | |
|---|---|
| En guardia | quieto, la mano a 7 cm de donde se la pide (lo que cede por su peso) |
| Directo | la mano llega a 53 m/s; el bloque de 6 t se corre 2,4 m |
| Gancho / uppercut | 54 / 66 m/s (no le pegan al bloque donde está) |
| Desde arriba | 107 m/s: llega con látigo, demasiado |
| Contra la pared | trabado a 3,6 m de lo pedido; después vuelve a la guardia |
| Un empujón de 18 m/s al antebrazo | cede 0,6 m y vuelve |

## Dos cosas que hubo que aprender
- **La resistencia a girar es muy distinta según el eje**: de punta a punta, grande; sobre su largo, casi nada. El
  músculo mide su fuerza con la de cada eje. Con una sola para todos, la pieza giraba sobre sí misma al tope del motor.
- **El codo tiene que ser bisagra.** Con una bola, el músculo del antebrazo hacía girar al brazo sobre sí mismo sin que
  nada lo frenara.

## La mano
`MechHand` (en `game/mech/`), la misma de la [[meca]]. Dos posturas: **abierta** (en guardia y a mano) y **el
puño** (mientras tira una piña), con las falanges dobladas sobre la palma y el pulgar encima; pasa de una a otra en 0,16
s, con easing. Hacia qué lado cierran los dedos lo dice quien la arma: acá, hacia donde dobla el codo; en la meca
péndulo, hacia adentro del cuerpo. Para mirarla: `tests/hand_look.tscn`.

## Las posturas
Dónde descansa el puño: **normal** (el brazo al costado, la mano abierta), **cubriéndose** (el puño cerrado adelante) y
**recogido** (la mano contra el hombro, cuando lo que lo sostiene se cae). Pasa de una a otra de corrido; después de una
piña vuelve a la que tenga. En el banco, **5** cambia entre normal y cubriéndose.

## Montado
Va solo en su fila o montado en algo que se mueve: la [[meca]] lleva dos. Montado, el músculo del hombro empuja
contra lo que lo sostiene (una piña sacude al torso) y pesa menos.

## Lo que falta
- La mano no agarra.
- Que la mano siga mejor lo pedido en la piña (hoy va atrás y llega con látigo): pedirle también velocidad.
