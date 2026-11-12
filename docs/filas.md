# Las filas del sandbox y su código

Las filas salen de `DesignSandbox.categories()` y sus paneles de `DesignSandbox._mount_tuners()`
(`game/sandbox/design_sandbox.gd`). **Borrar una fila es borrar todo lo de su renglón** (lo compartido, en la última
columna, se queda). Cómo está armado el código, en [[estructura]].

| Fila | Arquetipo | Código propio | Paneles | Tests | Usa (compartido) |
|---|---|---|---|---|---|
| Meca discreta | `MechArchetype` (`Mech.Arms.POSE`) | `game/pose_arm/` | `MechPanel` (F1), `MechKnockPanel` (F2) | `mech_fork_look` | la meca (abajo) |
| Meca física | `MechArchetype` (`Mech.Arms.MUSCLE`) | — (sus brazos son los de la fila Brazo) | `MechPanel` (F1), `MechKnockPanel` (F2) | `mech_look`, `mech_hands_look` | la meca (abajo), `game/muscle_arm/` |
| Brazo | `MuscleArmArchetype` | `game/muscle_arm/` entero | `MuscleArmPanel` (F1) | `muscle_arm_look` | `MechArm`, `MechBody.arm`, `MechHand`, `TestBall`, `Mech.SHOULDER` |
| Cubo con piernas | `LeggedCubeArchetype` | `game/line_cube/` entero | `LeggedCubePanel` (F1), `HoverKnockPanel` (F2) | `legged_check` | `MechBody`, `MechLeg`, `Clay`, `TestBall` |
| Personajes | `PeopleArchetype` | `CharacterGetUp` | — | — | el personaje |
| Objetos | `ObjectLotArchetype` | — | — | — | los objetos |
| Multijugador | `MultiplayerArchetype` | `SandboxSession` | — | `net_check` | `game/net/` |
| Partículas | `ParticleArchetype` | — | — | — | `game/particles/` |

## La meca (lo que comparten sus dos filas)
`game/mech/` entero: `Mech` y sus piezas (`MechCabin`, `MechExterior`, `PelvisLift`, `MechLegs`, `MechLeg`,
`MechNozzles`, `MechMoves`, `MechKeys`, `MechArm`, `MechHand`, `MechBody`), `MechSettings`, sus dos paneles, su parcela
y `Clay`. Tests: `mech_balance_check` (el equilibrio), `mech_ride_check` (caminar adentro y afuera), `possess_check`.

**Borrar un camino**: la Meca discreta se lleva `game/pose_arm/`; la Meca física, `game/muscle_arm/` y la fila Brazo. En
los dos casos `Mech.arms_kind` queda con un solo valor útil y se puede sacar.

**Borrar la fila Cubo con piernas** (la otra variante de equilibrio, la línea) se lleva `game/line_cube/` entero, sin
tocar nada más.

Ver [[sandbox]] para cómo se arma una fila.
