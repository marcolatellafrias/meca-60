class_name MechRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LA MECA (ver SandboxRow, docs/technical/sandbox.md): sus dos caminos, la arena, el brazo suelto y,
## archivado, el cubo con piernas (la otra variante de equilibrio, congelada).

static func rows() -> Array[SandboxRow]:
	var arena := DodgeArenaArchetype.new()
	return [
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca discreta") 			.add(SandboxRow.Build.NEAR, [MechArchetype.new(Mech.Arms.POSE)]) 			.panel(KEY_F1, MECH_PANEL, MechPanel.new()) 			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca física") 			.add(SandboxRow.Build.NEAR, [MechArchetype.new(Mech.Arms.MUSCLE)]) 			.panel(KEY_F1, MECH_PANEL, MechPanel.new()) 			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Arena de esquivar") 			.add(SandboxRow.Build.NEAR, [arena]) 			.panel(KEY_F1, MECH_PANEL, MechPanel.new()) 			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca cinemática") 			.add(SandboxRow.Build.NEAR, [MechArchetype.new(Mech.Arms.POSE, true)]) 			.panel(KEY_F1, KINEMATIC_PANEL, KinematicPanel.new()) 			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Laboratorio cinemático") 			.add(SandboxRow.Build.NEAR, [KinematicLabArchetype.new()]) 			.panel(KEY_F1, KINEMATIC_PANEL, KinematicPanel.new()) 			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Brazo") 			.add(SandboxRow.Build.NEAR, [MuscleArmArchetype.new()]) 			.panel(KEY_F1, "el brazo con músculos: el resorte, el freno y la fuerza", MuscleArmPanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Cubo con piernas").archive() 			.add(SandboxRow.Build.NEAR, [LeggedCubeArchetype.new()]) 			.panel(KEY_F1, "el cubo y sus piernas: los pasos por radio", LeggedCubePanel.new()),
	]


## La forma de la cabina (módulo Interior): cambia todas las mecas.
const CABIN_PANEL := "la cabina: módulos, pisos y el vidrio; guardar cambia todas las mecas"
const MECH_PANEL := "la meca: el péndulo, correr, agacharse, saltar y el propulsor"
const KINEMATIC_PANEL := "la meca cinemática: moverse, girar, saltar y volar, el dash, agacharse"
