# Las filas del sandbox y su código

Las filas salen de `DesignSandbox.categories()` y sus paneles de `DesignSandbox._mount_tuners()`
(`game/sandbox/design_sandbox.gd`). **Borrar una fila es borrar todo lo de su renglón** (lo compartido, en la última
columna, se queda).

| Fila | Arquetipo | Código propio | Paneles | Tests | Usa (compartido) |
|---|---|---|---|---|---|
| Meca | `MechTestArchetype` | `game/mech/` (menos `MechBody`, `MechDummy`, `MechBalanceSettings`), `TestArena` | — | `mech_check`, `player_check` | `MechBody`, `Clay` |
| Equilibrio | `BalanceTestArchetype` | `MechDummy`, `MechBalanceSettings` | `BalancePanel` (F1) | `balance_check` | `MechBody`, `TestBall`, personas |
| Cubo | `HoverCubeArchetype` | `game/hover/` entero | `HoverPanel` (F1), `HoverKnockPanel` (F2) | `hover_check` | `TestBall`, `MechBody.tilt`, `Clay` |
| Cubo con piernas | `LeggedCubeArchetype` | `game/legged_cube/` entero | `LeggedCubePanel` (F1), `HoverKnockPanel` (F2) | `legged_check` | `game/hover/` (hereda del cubo), `MechBody`, `MechLeg` |
| Cubo físico | `PhysicalCubeArchetype` | `game/physical_cube/` entero | `PhysicalCubePanel` (F1), `HoverKnockPanel` (F2) | `physical_check` | `game/hover/` (hereda del cubo), `TestBall` |
| Cubo péndulo | `PendulumCubeArchetype` | `game/pendulum_cube/` entero | `PendulumCubePanel` (F1), `HoverKnockPanel` (F2) | `pendulum_check` | `game/hover/` (hereda del cubo), `MechBody`, `MechLeg`, `TestBall` |
| Meca péndulo | `PendulumMechArchetype` | `game/pendulum_mech/` entero | `PendulumMechPanel` (F1), `HoverKnockPanel` (F2) | `pendulum_mech_look` | `game/pendulum_cube/` (hereda del cubo péndulo), `MechBody` |
| Brazo | `MuscleArmArchetype` | `game/muscle_arm/` entero | `MuscleArmPanel` (F1) | `muscle_arm_look` | `MechBody.arm`, `MechHand`, `TestBall`, `PendulumMech.SHOULDER` |
| Personajes | `PeopleArchetype` | `CharacterGetUp` | — | — | lo traído de character-parametric |
| Objetos | `ObjectLotArchetype` | — | — | `player_check` (el ropero) | objetos traídos |
| Multijugador | `MultiplayerArchetype` | `SandboxSession` | — | `net_check` | `game/net/` |
| Partículas | `ParticleArchetype` | — | — | — | `game/particles/` |

El cubo con piernas, el cubo físico y el cubo péndulo heredan del cubo: borrar la fila Cubo obliga a dejar `game/hover/` para ellos, o
borrarlas también.

Ver [[sandbox]] para cómo se arma una fila.
