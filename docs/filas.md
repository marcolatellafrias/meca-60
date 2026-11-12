# Las filas del sandbox y su código

Las filas salen de `DesignSandbox.categories()` y sus paneles de `DesignSandbox._mount_tuners()`
(`game/sandbox/design_sandbox.gd`). **Borrar una fila es borrar todo lo de su renglón** (lo compartido, en la última
columna, se queda).

| Fila | Arquetipo | Código propio | Paneles | Tests | Usa (compartido) |
|---|---|---|---|---|---|
| Meca discreta | `PendulumMechArchetype` (`physical` no) | `game/pose_arm/` | `PendulumMechPanel` (F1), `HoverKnockPanel` (F2) | `mech_fork_look` | la meca (abajo), `MechArm` |
| Meca física | `PendulumMechArchetype` (`physical` sí) | — (sus brazos son los de la fila Brazo) | `PendulumMechPanel` (F1), `HoverKnockPanel` (F2) | `pendulum_mech_look`, `mech_hands_look` | la meca (abajo), `game/muscle_arm/`, `MechArm` |
| Brazo | `MuscleArmArchetype` | `game/muscle_arm/` entero | `MuscleArmPanel` (F1) | `muscle_arm_look` | `MechArm`, `MechBody.arm`, `MechHand`, `TestBall`, `PendulumMech.SHOULDER` |
| Cubo con piernas | `LeggedCubeArchetype` | `game/legged_cube/` entero | `LeggedCubePanel` (F1), `HoverKnockPanel` (F2) | `legged_check` | `game/hover/` (hereda del cubo), `MechBody`, `MechLeg` |
| Personajes | `PeopleArchetype` | `CharacterGetUp` | — | — | el personaje |
| Objetos | `ObjectLotArchetype` | — | — | — | los objetos |
| Multijugador | `MultiplayerArchetype` | `SandboxSession` | — | `net_check` | `game/net/` |
| Partículas | `ParticleArchetype` | — | — | — | `game/particles/` |

## Lo que comparten las dos mecas (no es de ninguna fila)
- `game/pendulum_mech/` entero: `PendulumMech`, `MechExterior`, `PelvisLift`, sus perillas, su panel y su parcela.
  Tests: `pendulum_ride_check`.
- `game/pendulum_cube/`: `PendulumCube`, **el modelo de equilibrio** (y el cubo al que se le pega en las dos filas), con
  sus perillas, y el panel y la parcela de los que heredan los de la meca. Tests: `pendulum_check`, `pendulum_look`,
  `possess_check`.
- `game/hover/`: `HoverCube`, la base de todos los cubos (flotar, caer, recuperarse, la cabina, poseer), con sus
  perillas, sus paneles y su parcela.
- `game/mech/`: `MechBody`, `MechArm`, `MechLeg`, `MechHand`, `Clay`.

**Borrar un camino**: la Meca discreta se lleva `game/pose_arm/`; la Meca física, `game/muscle_arm/` y la fila Brazo.
En los dos casos `PendulumMech.physical_arms` y el `physical` de su parcela dejan de hacer falta.

**Borrar la fila Cubo con piernas** (la otra variante de equilibrio, la línea) se lleva `game/legged_cube/`; de
`HoverCube` se podría sacar entonces la línea de equilibrio, que el péndulo no usa.

Ver [[sandbox]] para cómo se arma una fila.
