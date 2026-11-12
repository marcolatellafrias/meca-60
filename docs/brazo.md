# El brazo con músculos

`game/muscle_arm/` · fila **Brazo** · ver [[filas]]

El primer paso de los brazos físicos de la meca, solo en su fila para tunearlo: un torso fijo en el aire con **un**
brazo. La idea es la de PuppetMaster: **la IK dice la pose; el cuerpo físico la persigue con músculos**.

## Las dos capas
- **La pose que se pide**: dónde quiere el puño (en guardia, a lo largo de una piña, o donde lo lleva el mouse) y, de
  ahí, el codo y la muñeca: la IK del cuerpo de la meca (`MechBody.arm`), la misma del dibujo.
- **El cuerpo físico**: el **brazo** y el **antebrazo** (con la mano en la punta, [[meca-pendulo]] usa la misma) son
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
- **N** pone y saca una pared adelante. **J/K**, una bola liviana o pesada contra el brazo. **R** vuelve a armar todo.
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

## Lo que falta
- Montarlo en la [[meca-pendulo]] (hoy sus brazos son dibujo): ahí el músculo del hombro empuja al torso.
- La mano no cierra el puño ni agarra.
- Que la mano siga mejor lo pedido en la piña (hoy va atrás y llega con látigo): pedirle también velocidad.
