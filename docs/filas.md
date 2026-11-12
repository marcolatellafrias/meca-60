# Las filas del sandbox y su código

Las filas salen de `DesignSandbox.categories()` y sus paneles de `DesignSandbox._mount_tuners()`
(`game/sandbox/design_sandbox.gd`). **Borrar una fila es borrar todo lo de su renglón** (lo compartido, en la última
columna, se queda).

| Fila | Arquetipo | Código propio | Paneles | Tests | Usa (compartido) |
|---|---|---|---|---|---|
| Meca | `MechTestArchetype` | `game/mech/` (menos `MechBody`, `MechDummy`, `MechBalanceSettings`), `TestArena` | — | `mech_check`, `player_check` | `MechBody`, `Clay` |
| Equilibrio | `BalanceTestArchetype` | `MechDummy`, `MechBalanceSettings` | `BalancePanel` (F1) | `balance_check` | `MechBody`, `TestBall`, personas |
| Cubo | `HoverCubeArchetype` | `game/hover/` entero | `HoverPanel` (F1), `HoverKnockPanel` (F2) | `hover_check` | `TestBall`, `MechBody.tilt`, `Clay` |
| Personajes | `PeopleArchetype` | `CharacterGetUp` | — | — | lo traído de character-parametric |
| Objetos | `ObjectLotArchetype` | — | — | `player_check` (el ropero) | objetos traídos |
| Multijugador | `MultiplayerArchetype` | `SandboxSession` | — | `net_check` | `game/net/` |
| Partículas | `ParticleArchetype` | — | — | — | `game/particles/` |

Ver [[sandbox]] para cómo se arma una fila.
