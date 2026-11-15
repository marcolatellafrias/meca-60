# Las filas del sandbox y su código

Cada módulo declara sus filas y sus paneles en su archivo de filas (`MechRows`, `CharacterRows`, `WorldRows`,
`ArtRows`, `SupplyRows`, `NetworkRows`, `BossRows`; ver [[sandbox]]). **Borrar una fila es borrar todo lo de su renglón** (lo
compartido, en la última columna, se queda). Cómo está armado el código, en [[estructura]].

| Fila | Arquetipo | Código propio | Paneles | Tests | Usa (compartido) |
|---|---|---|---|---|---|
| Meca de tres | `ToolMechArchetype` | `game/tool_mech/` entero (`ToolMech`, `ToolMechKeys`, `MechEnergy`, `DrillArm`, `CannonArm`, `EnergyBolt`, `ArmorPlates`) | `KinematicPanel` (F1), `CabinShapePanel` (F2), `PoseArmPanel` (F3), `LegsPanel` (F4) | `tool_mech_look` | la meca entera, `PoseArm` |
| Meca discreta | `MechArchetype` (`Mech.Arms.POSE`) | `game/pose_arm/` | `MechPanel` (F1), `CabinShapePanel` (F2), `PoseArmPanel` (F3) | `mech_fork_look` | la meca (abajo) |
| Meca física | `MechArchetype` (`Mech.Arms.MUSCLE`) | — (sus brazos son los de la fila Brazo) | `MechPanel(MUSCLE)` (F1, sus perillas), `CabinShapePanel` (F2), `MuscleArmPanel` (F3) | `mech_look`, `mech_hands_look` | la meca (abajo), `game/muscle_arm/` |
| Arena de esquivar | `DodgeArenaArchetype` | `game/dodge_arena/` entero | `MechPanel` (F1), `CabinShapePanel` (F2), `PoseArmPanel` (F3) | `dodge_arena_look` | la meca, `game/projectiles/` |
| Meca cinemática | `MechArchetype` (`Mech.Arms.POSE`, cinemática) | `KinematicMover`, `StompFeet` | `KinematicPanel` (F1), `CabinShapePanel` (F2), `PoseArmPanel` (F3) | `mech_kinematic_look` | la meca entera |
| Laboratorio cinemático | `KinematicLabArchetype` | la meca simplificada (`Mech` cinemática, sin brazos ni cabina) | `KinematicPanel` (F1), `CabinShapePanel` (F2) | `kinematic_lab_look`, `kinematic_lab_moves_look` | `AreaStrike.loose_in`, `MechKeys.axis` |
| Mapa de pelea | `BattlefieldArchetype` | `game/battlefield/` (`Battlefield`) | — | `battlefield_check` | la meca, `PackageArchetype`, `Clay`, `Stairs` |
| Base | `BaseArchetype` | `game/base/` entero (`BaseLayout`, `BaseHatch`, `BaseSettings`, `BasePanel`; las terminales: `BaseTerminal`, `TerminalScreen`, `BaseState`, `ArmoryScreen`, `ContractsScreen`) | `BasePanel` (F1, las medidas); de la meca propia: `KinematicPanel` (F2), `CabinShapePanel` (F3), `LegsPanel` (F4) | `base_look`, `base_terminals_look` | la meca, `Clay` |
| Componentes de la armería | `ArmoryPartsArchetype` | `game/base/armory_parts.gd` (`ArmoryParts`, las maquetas de arcilla) | — | `armory_parts_look` | `ArmoryCatalog`, `MechHand`, `MechBody`, `Clay` |
| Brazo | `MuscleArmArchetype` | `game/muscle_arm/` entero | `MuscleArmPanel` (F1) | `muscle_arm_look` | `MechArm`, `MechBody.arm`, `MechHand`, `TestBall`, `Mech.SHOULDER` |
| Cubo con piernas (archivada) | `LeggedCubeArchetype` | `game/archive/line_cube/` entero | `LeggedCubePanel` (F1) | `legged_check` | `MechBody`, `MechLeg`, `Clay`, `TestBall` |
| Personajes | `PeopleArchetype` | `CharacterGetUp` | `LocomotionPanel` (F1) y `LocomotionTuner` (F3), los de la fila Locomoción | `people_look`, `sizes_check` | el personaje |
| Locomoción | `LocomotionLabArchetype` | `game/locomotion_lab/` entero (`LocomotionLab`, `CharacterActions`, los dos paneles) | `LocomotionPanel` (F1) y `LocomotionTuner` (F3), también en Personajes | `locomotion_look` | el personaje, `PeopleArchetype`, `PackageArchetype`, `Clay` |
| Recursos | `ObjectLotArchetype` | `game/supplies/` (`SupplyLook`) | — | `supplies_look` | `PackageArchetype`, el agarre |
| Multijugador | `MultiplayerArchetype` | `SandboxSession` | — | `net_check` | `game/net/` |
| Partículas | `ParticleArchetype` | — | — | — | `game/particles/` |
| Píxeles | `PixelArtArchetype` | `game/pixel_art/` entero, `tools/pixel_art_modelos_prueba.py` | `PixelPaintPanel` (F1) | `pixel_art_look` | `Clay`, `SupplyLook` (colores) |
| Luchador de orugas | `BrawlerArchetype` | `game/bosses/brawler/` entero (`Brawler`, `BrawlerBody`, `BrawlerBrain`, `BrawlerWave`, `BrawlerRock`, `BrawlerHook`, `BrawlerSettings`, `BrawlerPanel`), y de `game/bosses/`: `Health`, `FightBars`, `BossArena`, `HitReaction`, `BossSounds`, `BossHurtbox` | `BrawlerPanel` (F1) | `brawler_look`, `brawler_fight_look`, `brawler_dodge_check`, `brawler_charge_movie`, `hit_reaction_look`, `brawler_shots_check` | `MoveRamp`, `MechKeys.axis`, `Clay`, `PhysicsLayers.FIXED`, `ParticleSystems` |
| Maquetas de jefes | `BossMaquetteArchetype` | `game/bosses/maquettes/` entero (`BossMaquettes`, `HumanoidMaquettes`, `ArmedMaquettes`, `WalkerMaquettes`, `BossMaquetteArchetype`) | — | `boss_maquettes_look` | `Clay` |

## La meca (lo que comparten sus dos filas)
`game/balance_body/` entero (el cuerpo con equilibrio, que comparte con los jefes: `BalanceBody`, `BodyLegs`,
`BodyNozzles`, `BodyMoves`, `BodySettings`) y `game/mech/` entero: `Mech` y sus piezas (`MechCabin`,
`PelvisLift`, `MechLeg`, `MechKeys`, `MechArm`, `MechHand`, `MechBody`), sus dos paneles, su parcela
y `Clay`. Tests: `mech_balance_check` (el equilibrio), `mech_ride_check` (caminar adentro y afuera), `possess_check`.

**Borrar un camino**: la Meca discreta se lleva `game/pose_arm/`; la Meca física, `game/muscle_arm/` y la fila Brazo. En
los dos casos `Mech.arms_kind` queda con un solo valor útil y se puede sacar.

**Borrar la fila Cubo con piernas** (la otra variante de equilibrio, la línea) se lleva `game/archive/line_cube/` entero, sin
tocar nada más.

Ver [[sandbox]] para cómo se arma una fila.
