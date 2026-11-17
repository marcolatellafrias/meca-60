class_name MechRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LA MECA (ver SandboxRow, docs/technical/sandbox.md): sus dos caminos, la arena, el brazo suelto y,
## archivado, el cubo con piernas (la otra variante de equilibrio, congelada).

static func rows() -> Array[SandboxRow]:
	var arena := DodgeArenaArchetype.new()
	# Las de las filas con equipamiento (F5): el panel sabe de ellas qué lleva su meca sin nada guardado.
	var cage := CageMechArchetype.new()
	var vortex := MechArchetype.new(Mech.Arms.MUSCLE, false, Mech.Cabin.VORTEX)
	var tool := ToolMechArchetype.new()
	var pods := ToolMechArchetype.new(true)
	var discrete := MechArchetype.new(Mech.Arms.POSE)
	var round := MechArchetype.new(Mech.Arms.POSE, false, Mech.Cabin.ROUND)
	var muscle := MechArchetype.new(Mech.Arms.MUSCLE)
	var kinematic := MechArchetype.new(Mech.Arms.POSE, true)
	return [
		# LA MECA JAULA (CageMech, CageCabin; el usuario, 16/11/2026: «empezar a migrar esta meca a algo funcional»): la
		# de tests/cage_ideas_look, chica, cinemática con brazos físicos, con su propio F1 de moverse.
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca jaula") \
			.add(SandboxRow.Build.NEAR, [cage]) \
			.panel(KEY_F1, CAGE_PANEL, CageMovesPanel.new()) \
			.panel(KEY_F2, CAGE_SHAPE_PANEL, CageShapePanel.new()) \
			.panel(KEY_F3, CAGE_ARMS_PANEL, ArmsPanel.new([ArmsPanel.Kind.POSE, ArmsPanel.Kind.MUSCLE])) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()) \
			.panel(KEY_F5, EQUIPMENT_PANEL, EquipmentPanel.new(cage)) \
			.panel(KEY_F6, POSES_PANEL, ArmPosesPanel.new()),
		# LA MECA POR MÓDULOS, la primera del sandbox (ModulesMaquette; el usuario, 16/11/2026: «pasámelo a esta maqueta
		# a escala real en una parcela al principio del sandbox así veo cómo se siente»): quieta, para recorrerla.
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca por módulos") \
			.add(SandboxRow.Build.NEAR, [ModulesMaquetteArchetype.new()]),
		# EL DISCO DE DOS PISOS CON VÓRTICE, la segunda del sandbox (el usuario, 15/11/2026: «con brazos reales (con
		# física), piernas reales, y torso con física en una parcela al principio del sandbox»).
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca del vórtice") \
			.add(SandboxRow.Build.NEAR, [vortex]) \
			.panel(KEY_F1, MECH_PANEL, MechPanel.new(Mech.Arms.MUSCLE)) \
			.panel(KEY_F2, VORTEX_PANEL, VortexShapePanel.new()) \
			.panel(KEY_F3, MUSCLE_ARMS_PANEL, ArmsPanel.new([ArmsPanel.Kind.MUSCLE])) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()) \
			.panel(KEY_F5, EQUIPMENT_PANEL, EquipmentPanel.new(vortex)),
		# LA MECA DE TRES, una meca de ejemplo con elementos concretos (ToolMech; el usuario, 15/11/2026: «una parcela
		# nueva que esté al principio de todo, al lado de la de vórtice, así la iteramos rápido»).
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca de tres") \
			.add(SandboxRow.Build.NEAR, [tool]) \
			.panel(KEY_F1, KINEMATIC_PANEL, KinematicPanel.new()) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, ArmsPanel.new([ArmsPanel.Kind.POSE])) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()) \
			.panel(KEY_F5, EQUIPMENT_PANEL, EquipmentPanel.new(tool)),
		# LA MECA DE CÁPSULAS (PodMech, PodCabin; el usuario, 15/11/2026: «pasemos esta maqueta de forma paramétrica y
		# ordenada al sistema de la nave»): la 37 de tests/sphere_pods_look, con su forma en el F2.
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca de cápsulas") \
			.add(SandboxRow.Build.NEAR, [pods]) \
			.panel(KEY_F1, KINEMATIC_PANEL, KinematicPanel.new()) \
			.panel(KEY_F2, PODS_PANEL, PodShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, ArmsPanel.new([ArmsPanel.Kind.POSE])) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()) \
			.panel(KEY_F5, EQUIPMENT_PANEL, EquipmentPanel.new(pods)),
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca discreta") \
			.add(SandboxRow.Build.NEAR, [discrete]) \
			.panel(KEY_F1, MECH_PANEL, MechPanel.new()) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, ArmsPanel.new([ArmsPanel.Kind.POSE])) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()) \
			.panel(KEY_F5, EQUIPMENT_PANEL, EquipmentPanel.new(discrete)),
		# LA REDONDA (el usuario, 15/11/2026: «un "fork" en otra parcela»): la discreta con la cabina redonda, con su F2.
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca redonda") \
			.add(SandboxRow.Build.NEAR, [round]) \
			.panel(KEY_F1, MECH_PANEL, MechPanel.new()) \
			.panel(KEY_F2, ROUND_PANEL, RoundShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, ArmsPanel.new([ArmsPanel.Kind.POSE])) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()) \
			.panel(KEY_F5, EQUIPMENT_PANEL, EquipmentPanel.new(round)),
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca física") \
			.add(SandboxRow.Build.NEAR, [muscle]) \
			.panel(KEY_F1, MECH_PANEL, MechPanel.new(Mech.Arms.MUSCLE)) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F3, MUSCLE_ARMS_PANEL, ArmsPanel.new([ArmsPanel.Kind.MUSCLE])) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()) \
			.panel(KEY_F5, EQUIPMENT_PANEL, EquipmentPanel.new(muscle)),
		SandboxRow.new(SandboxSuper.Id.MECH, "Arena de esquivar") \
			.add(SandboxRow.Build.NEAR, [arena]) \
			.panel(KEY_F1, MECH_PANEL, MechPanel.new()) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, ArmsPanel.new([ArmsPanel.Kind.POSE])) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca cinemática") \
			.add(SandboxRow.Build.NEAR, [kinematic]) \
			.panel(KEY_F1, KINEMATIC_PANEL, KinematicPanel.new()) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F3, POSE_ARMS_PANEL, ArmsPanel.new([ArmsPanel.Kind.POSE])) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()) \
			.panel(KEY_F5, EQUIPMENT_PANEL, EquipmentPanel.new(kinematic)),
		SandboxRow.new(SandboxSuper.Id.MECH, "Laboratorio cinemático") \
			.add(SandboxRow.Build.NEAR, [KinematicLabArchetype.new()]) \
			.panel(KEY_F1, KINEMATIC_PANEL, KinematicPanel.new()) \
			.panel(KEY_F2, CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()),
		SandboxRow.new(SandboxSuper.Id.MECH, "Brazo") \
			.add(SandboxRow.Build.NEAR, [MuscleArmArchetype.new()]) \
			.panel(KEY_F1, "el brazo con músculos: el resorte, el freno y la fuerza", ArmsPanel.new([ArmsPanel.Kind.MUSCLE])),
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
const CAGE_PANEL := "la meca jaula: moverse, girar, saltar y volar, el dash, agacharse (sólo ella)"
const CAGE_SHAPE_PANEL := "la meca jaula: la esfera de abajo, el tablero de arriba y la torre (sólo ella)"
const CAGE_ARMS_PANEL := "los brazos: el cañón (discreto) y el palo (con músculos), los de todas las mecas"
## Las poses de los brazos para probar (ArmPosesPanel; temporal).
const POSES_PANEL := "las poses de los brazos para probar: el reposo del palo y del cañón, y el golpe (temporal)"
## Lo que lleva cada brazo (EquipmentPanel): cada fila el suyo.
const EQUIPMENT_PANEL := "el equipamiento: qué lleva cada brazo, cómo se mueve y su placa (cada fila el suyo)"
const KINEMATIC_PANEL := "la meca cinemática: moverse, girar, saltar y volar, el dash, agacharse"
