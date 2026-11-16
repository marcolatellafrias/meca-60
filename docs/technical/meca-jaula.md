# La meca jaula

`game/mech/cage/` · fila **Meca jaula** (la primera del sandbox) · ver [[dos-paradigmas]], [[meca-de-tres]],
[[meca-de-capsulas]], [[armamento]]

**La jaula de las maquetas, hecha meca** (16/11/2026). Sale de `tests/cage_ideas_look`, la 166 (el usuario: «empezar a
migrar esta meca a algo funcional… que camine… que se pueda poseer la meca y que los brazos anden y las piernas anden»).
Es una cabina más de la meca (`Mech.Cabin.CAGE`), como la de cápsulas. **Primer paso**: se maneja entera poseyéndola
(la O; la T cambia la vista). Las tres cabinas, subirse con la E y los controles de cada puesto vienen después.

## El tamaño
Es **chica**: las cabinas a la medida de una persona y **los brazos y las piernas de la meca de siempre al 30 %**
(`CageCabin.LIMBS`; `MechBody.scaled`, que achica todas las medidas y los factores del ancho, el alcance y el paso).
La caja de la meca es la cápsula de abajo: 2 × 1,78 × 2 m, sobre la cintura a 2,22 m.

## La cabina — `CageCabin`
- **Abajo, el que maneja**: la caja con la burbuja de vidrio al frente (la 144), el piso y la tapa de la panza. Desde su
  silla se mira en primera persona.
- **Arriba, el de los brazos**, sentado en la cubierta, dentro del borde con bisel; adelante, sus controles (sólo se ven).
- **Atrás, el artillero**: la torre metida en la planta, el plato que gira con su silla y el arma montada en su
  horquilla (sólo se ve; `gun`, para cuando sea funcional).
- **La espalda**: el hueco de un recurso, la batería y la mochila del jetpack con el bisel (la 129). Sólo se ven.
- Las tres sillas: brazos, artillero y manejo; un maniquí en las dos primeras. La U deja en la cubierta.
- **Los hombros**, en el módulo de abajo: a los costados de la caja, a la altura del centro de la ventana (los de la 166).
  Sin hombreras todavía.

## La meca — `CageMech`
La Meca de tres (`ToolMech`: la energía común, el dash, saltar y levitar) con:
- **El torso discreto y los brazos físicos** (el usuario: «los brazos van a ser físicos y el torso va a ser discreto»).
- **El cañón, brazo izquierdo** (`CageCannonArm`): el de la Meca de tres, con sus cuatro modos y la palanca, pero **en
  lugar del antebrazo**, del codo hasta donde terminaría el puño. Es el brazo discreto que sigue la palanca con un
  resorte (no choca), como en la de tres.
- **El palo, brazo derecho** (`PoleArm`): un brazo con músculos (`MuscleArm`, choca y se traba) con el puño pesado
  siempre cerrado agarrando el palo eléctrico. Pega las piñas de siempre; el palo sólo se ve (no choca).
- **Las placas del acorazado** (las de la armería) en los brazos y las piernas, y la pelvis cilíndrica de la maqueta.
- **Sus teclas** (`CageMechKeys`): las de la de tres, y el palo con el clic izquierdo (directo) y el derecho (gancho). La
  cámara de afuera, más cerca.

## Moverse, sólo ella — `CageMovesPanel` (F1)
Las perillas de la cinemática (`KinematicSettings`), **suyas** (`CageMech.MOVES`, guardadas en
`game/mech/cage/cage_moves.tres`; el usuario: «si un panel lo quiero modificar para este mecha, me gustaría que sea
solamente para esta»). Cualquier cuerpo puede llevar las suyas: `BalanceBody.kinematic_knobs` (si no, las de todas).
Sin guardar, nace con las de las otras y la velocidad, el salto, el vuelo y el dash a la mitad.
Los paneles de los brazos con músculos y de las piernas son los de todas: no están en su fila.

## Test
`tests/cage_mech_look.tscn` (unos 15 s, sin el sandbox): arma la parcela, la hace caminar, pegar con el palo y tirar
con el cañón, imprime lo que mide y saca una hoja (de afuera, desde los ojos del que maneja, caminando, el palo, el
cañón).

## Lo que falta
- Las tres cabinas funcionales: subirse con la E a cada una y manejar su parte desde ahí.
- Los controles de cada puesto, el arma del artillero, que el palo haga algo propio.
