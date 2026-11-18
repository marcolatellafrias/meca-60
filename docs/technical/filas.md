# Las filas del sandbox y su código

Cada módulo declara sus filas y sus paneles en su archivo de filas (`MechRows`, `CharacterRows`, `WorldRows`,
`ArtRows`, `SupplyRows`, `NetworkRows`, `BossRows`; ver [[sandbox]]). **Borrar una fila es borrar todo lo de su renglón** (lo
compartido, en la última columna, se queda). Cómo está armado el código, en [[estructura]].

| Fila | Arquetipo | Código propio | Paneles | Tests | Usa (compartido) |
|---|---|---|---|---|---|
| Meca jaula | `CageMechArchetype` | `game/mech/cage/` entero (`CageCabin`, `CageMech`, `CageMechKeys`, `CageMovesPanel`, `CageShapePanel`, `CageBoarding`, `CageBoards`…) | `CageMovesPanel` (F1), `CageShapePanel` (F2), `ArmsPanel` (F3, discretos y con músculos), `LegsPanel` (F4), `EquipmentPanel` (F5, el equipo de sus brazos), `ArmPosesPanel` (F6, temporal) | `cage_mech_look`, `cage_boards_look`, `folding_arm_check`, `cage_boarding_check` | la meca entera (abajo) |
| Mapa de pelea | `BattlefieldArchetype` | `game/battlefield/` (`Battlefield`) | — | `battlefield_check` | la meca (la jaula), `PackageArchetype`, `Clay`, `Stairs` |
| Base | `BaseArchetype` | `game/base/` entero (`BaseLayout`, `BaseHatch`, `BaseSettings`, `BasePanel`; las terminales: `BaseTerminal`, `TerminalScreen`, `BaseState`, `ArmoryScreen`, `ContractsScreen`) | `BasePanel` (F1, las medidas); de la meca propia: `CageMovesPanel` (F2), `CageShapePanel` (F3), `LegsPanel` (F4) | `base_look`, `base_terminals_look` | la meca (la jaula), `Clay` |
| Componentes de la armería | `ArmoryPartsArchetype` | `game/base/armory_parts.gd` (`ArmoryParts`, las maquetas de arcilla) | — | `armory_parts_look` | `ArmoryCatalog`, `MechHand`, `MechBody`, `Clay` |
| Personajes | `PeopleArchetype` | `CharacterGetUp` | `LocomotionTuner` (F3: cada arquetipo y «todos»), el de la fila Locomoción | `people_look`, `sizes_check` | el personaje |
| Cabezas | `HeadFormsArchetype` (la vitrina de las formas) | `HeadFormsPanel` | `HeadFormsPanel` (F3: editar, agregar, el aplanamiento de todas) | `head_forms_look`, `head_forms_panel_look` | `HeadForm`, `HeadForms` |
| Locomoción | `LocomotionLabArchetype` | `game/locomotion_lab/` entero (`LocomotionLab`, `CharacterActions`, el panel y `LocomotionCommonKnobs`) | `LocomotionTuner` (F3: cada arquetipo y «todos»), también en Personajes | `locomotion_look` | el personaje, `PeopleArchetype`, `PackageArchetype`, `Clay` |
| Recursos | `ObjectLotArchetype` | `game/supplies/` (`SupplyLook`) | — | `supplies_look` | `PackageArchetype`, el agarre |
| Multijugador | `MultiplayerArchetype` | `SandboxSession` | — | `net_check` | `game/net/` |
| Partículas | `ParticleArchetype` | — | — | — | `game/particles/` |
| Píxeles | `PixelArtArchetype` | `game/pixel_art/` entero, `tools/pixel_art_modelos_prueba.py` | `PixelPaintPanel` (F1) | `pixel_art_look` | `Clay`, `SupplyLook` (colores) |
| Luchador de orugas | `BrawlerArchetype` | `game/bosses/brawler/` entero (`Brawler`, `BrawlerBody`, `BrawlerBrain`, `BrawlerWave`, `BrawlerRock`, `BrawlerHook`, `BrawlerFlame`, `BrawlerSettings`, `BrawlerPanel`), y de `game/bosses/`: `Health`, `FightBars`, `BossArena`, `HitReaction`, `BossSounds`, `BossHurtbox`, `BossBursts`, `BossSettings`, `BossSettingsPanel`, `BossMode`, `BossZone`, `BossShot` y `powers/` (`BossPower` y los seis poderes) | `BrawlerPanel` (F1, de la parcela), `BossSettingsPanel` (F7) | `brawler_look`, `brawler_fight_look`, `brawler_dodge_check`, `brawler_charge_movie`, `hit_reaction_look`, `brawler_shots_check`, `boss_modes_check`, `boss_panel_look` | la meca (la jaula, su blanco), `MoveRamp`, `MechKeys.axis`, `Clay`, `PhysicsLayers.FIXED`, `ParticleSystems` |
| Taller de jefes | `BossWorkshopArchetype` | `game/bosses/parts/` entero (`BossParts`, `BossRecipe`, `BossFrame`) | `BossSettingsPanel` (F7) | `boss_parts_look` | `Clay`, `BossSettings`, los poderes (`BossPower.needs`) |
| Maquetas de jefes | `BossMaquetteArchetype` | `game/bosses/maquettes/` entero (`BossMaquettes`, `HumanoidMaquettes`, `ArmedMaquettes`, `WalkerMaquettes`, `BossMaquetteArchetype`) | — | `boss_maquettes_look` | `Clay` |

## La meca (lo que usan la jaula, el Mapa de pelea, la Base y el Luchador)
`game/balance_body/` entero (el cuerpo con equilibrio, que comparte con los jefes: `BalanceBody`, el motor discreto
`KinematicMover`, `BodyLegs`, `BodyNozzles`, `BodyMoves`, `BodySettings`, `LegsPanel`), `game/mech/` entero (`Mech` y sus
piezas: `MechCabin`, `MechLeg`, `MechKeys`, `MechArm`, `MechHand`, `MechBody`; `MechArchetype`, las reglas de toda
parcela con la meca; las puntas de los brazos, `arm_tips/`; los tableros, `boards/`; `ArmsPanel`, `KnobsPanel`;
`Clay`), `game/tool_mech/` (`ToolMech`, `ToolMechKeys`, `MechEnergy`, `EnergyBolt`), `game/pose_arm/` y
`game/muscle_arm/` (los dos brazos). Tests: `possess_check`, `equipment_check`, `arm_tips_look`, `hand_look`.

*Hasta el 17/11/2026 había también las filas de la meca grande —Meca por módulos, Meca del vórtice, Meca de tres, Meca
de cápsulas, Meca discreta, Meca redonda, Meca física, Arena de esquivar, Meca cinemática, Laboratorio cinemático, Brazo
y Cubo con piernas (archivada)—; se borraron con su código y sus tests (commit 0bcaeaf).*

Ver [[sandbox]] para cómo se arma una fila.
