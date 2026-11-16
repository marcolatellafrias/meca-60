class_name MechRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LA MECA (ver SandboxRow, docs/technical/sandbox.md): sus dos caminos, la arena, el brazo suelto y,
## archivado, el cubo con piernas (la otra variante de equilibrio, congelada).

static func rows() -> Array[SandboxRow]:
	var arena := DodgeArenaArchetype.new()
	return [
		# EL DISCO DE DOS PISOS CON VÓRTICE, la primera del sandbox (el usuario, 15/11/2026: «con brazos reales (con
		# física), piernas reales, y torso con física en una parcela al principio del sandbox»).
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca del vórtice") \
			.add(SandboxRow.Build.NEAR, [MechArchetype.new(Mech.Arms.MUSCLE, false, Mech.Cabin.VORTEX)]) \
			.panel(KEY_F1, MECH_PANEL, MechPanel.new(Mech.Arms.MUSCLE)) \
			.panel(KEY_F2, VORTEX_PANEL, VortexShapePanel.new()) \
			.panel(KEY_F3, MUSCLE_ARMS_PANEL, MuscleArmPanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		# LA MECA DE TRES, una meca de ejemplo con elementos concretos (ToolMech; el usuario, 15/11/2026: «una parcela
		# nueva que esté al principio de todo, al lado de la de vórtice, así la iteramos rápido»).
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca de tres") \
			.add(SandboxRow.Build.NEAR, [ToolMechArchetype.new()]) \
			.panel(KEY_F1, KINEMATIC_PANEL, KinematicPanel.new()) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, PoseArmPanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		# LA MECA DE CÁPSULAS (PodMech, PodCabin; el usuario, 15/11/2026: «pasemos esta maqueta de forma paramétrica y
		# ordenada al sistema de la nave»): la 37 de tests/sphere_pods_look, con su forma en el F2.
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca de cápsulas") \
			.add(SandboxRow.Build.NEAR, [ToolMechArchetype.new(true)]) \
			.panel(KEY_F1, KINEMATIC_PANEL, KinematicPanel.new()) \
			.panel(KEY_F2, PODS_PANEL, PodShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, PoseArmPanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca discreta") \
			.add(SandboxRow.Build.NEAR, [MechArchetype.new(Mech.Arms.POSE)]) \
			.panel(KEY_F1, MECH_PANEL, MechPanel.new()) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, PoseArmPanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		# LA REDONDA (el usuario, 15/11/2026: «un "fork" en otra parcela»): la discreta con la cabina redonda, con su F2.
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca redonda") \
			.add(SandboxRow.Build.NEAR, [MechArchetype.new(Mech.Arms.POSE, false, Mech.Cabin.ROUND)]) \
			.panel(KEY_F1, MECH_PANEL, MechPanel.new()) \
			.panel(KEY_F2, ROUND_PANEL, RoundShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, PoseArmPanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca física") \
			.add(SandboxRow.Build.NEAR, [MechArchetype.new(Mech.Arms.MUSCLE)]) \
			.panel(KEY_F1, MECH_PANEL, MechPanel.new(Mech.Arms.MUSCLE)) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F3, MUSCLE_ARMS_PANEL, MuscleArmPanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Arena de esquivar") \
			.add(SandboxRow.Build.NEAR, [arena]) \
			.panel(KEY_F1, MECH_PANEL, MechPanel.new()) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, PoseArmPanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca cinemática") \
			.add(SandboxRow.Build.NEAR, [MechArchetype.new(Mech.Arms.POSE, true)]) \
			.panel(KEY_F1, KINEMATIC_PANEL, KinematicPanel.new()) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, PoseArmPanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Laboratorio cinemático") \
			.add(SandboxRow.Build.NEAR, [KinematicLabArchetype.new()]) \
			.panel(KEY_F1, KINEMATIC_PANEL, KinematicPanel.new()) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Brazo") \
			.add(SandboxRow.Build.NEAR, [MuscleArmArchetype.new()]) \
			.panel(KEY_F1, "el brazo con músculos: el resorte, el freno y la fuerza", MuscleArmPanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Cubo con piernas").archive() \
			.add(SandboxRow.Build.NEAR, [LeggedCubeArchetype.new()]) \
			.panel(KEY_F1, "el cubo y sus piernas: los pasos por radio", LeggedCubePanel.new()),
	]


## La forma de la cabina (módulo Interior): cambia todas las mecas.
const CABIN_PANEL := "la cabina: módulos, pisos y el vidrio; guardar cambia todas las mecas"
const VORTEX_PANEL := "la meca del vórtice: el radio, los pisos, el núcleo, la escalera, y sus brazos y piernas"
const PODS_PANEL := "la meca de cápsulas: el torso, los radiales de las cápsulas y los hombros, y sus brazos y piernas"
const ROUND_PANEL := "la cabina redonda: el radio, el alto, el disco, la tarima, el ascensor y el vidrio"
const MECH_PANEL := "la meca: moverse, el equilibrio, las piernas, saltar y caerse (cada variante las suyas)"
const LEGS_PANEL := "las piernas: los pasos (los mismos para todas las mecas)"
const POSE_ARMS_PANEL := "los brazos discretos: lo rápido de las piñas y cuánto empujan"
const MUSCLE_ARMS_PANEL := "los brazos con músculos: el resorte, el freno y la fuerza"
const KINEMATIC_PANEL := "la meca cinemática: moverse, girar, saltar y volar, el dash, agacharse"
