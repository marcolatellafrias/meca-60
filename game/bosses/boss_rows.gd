class_name BossRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LOS JEFES (ver SandboxRow, docs/technical/sandbox.md). Con los paneles de la meca que
## pelea (la simplificada; el usuario: «que los paneles para modificar a la meca propia estén también disponibles en la
## categoría del boss»): F2 moverse, F3 la forma, F4 las piernas.

static func rows() -> Array[SandboxRow]:
	return [
		SandboxRow.new(SandboxSuper.Id.BOSSES, "Jefe bola") \
			.add(SandboxRow.Build.NEAR, [BallBossArchetype.new()]) \
			.panel(KEY_F1, "el jefe bola: moverse, girar, saltar, agacharse y los tentáculos", BallBossPanel.new()) \
			.panel(KEY_F2, MechRows.KINEMATIC_PANEL, KinematicPanel.new()) \
			.panel(KEY_F3, MechRows.CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F4, MechRows.LEGS_PANEL, LegsPanel.new()),
		# LAS MAQUETAS (BossMaquettes): jefes de arcilla, quietos, con sus puntos débiles, sus fases y sus ataques de área.
		SandboxRow.new(SandboxSuper.Id.BOSSES, "Maquetas de jefes") 			.add(SandboxRow.Build.NEAR, BossRows.maquettes()),
	]


static func maquettes() -> Array:
	var all := []
	for i in BossMaquettes.ALL.size():
		all.append(BossMaquetteArchetype.new(i))
	return all
