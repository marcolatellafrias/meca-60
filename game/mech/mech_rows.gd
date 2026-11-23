class_name MechRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LA MECA (ver SandboxRow, docs/technical/sandbox.md): la meca jaula.
## *Hasta el 17/11/2026 había también las de la meca grande —por módulos, del vórtice, de tres, de cápsulas, discreta,
## redonda, física, la arena de esquivar, la cinemática, el laboratorio cinemático, el brazo suelto y, archivado, el cubo
## con piernas—; se borraron con ella (el usuario: «borrar todo el sistema de la meca grande… limitarnos solamente a un
## approach de meca a una escala más humana»). Están en el commit 0bcaeaf.*

static func rows() -> Array[SandboxRow]:
	# La de la fila con equipamiento (F5): el panel sabe de ella qué lleva su meca sin nada guardado.
	var cage := CageMechArchetype.new()
	return [
		# LA MECA JAULA (CageMech, CageCabin; el usuario, 16/11/2026: «empezar a migrar esta meca a algo funcional»): la
		# de tests/cage_ideas_look, chica, cinemática con brazos físicos, con su propio F1 de moverse.
		SandboxRow.new(SandboxSuper.Id.MECH, "Meca jaula") \
			.add(SandboxRow.Build.NEAR, [cage]) \
			.panel(KEY_F1, CAGE_PANEL, CageMovesPanel.new()) \
			.panel(KEY_F2, CAGE_SHAPE_PANEL, CageShapePanel.new()) \
			.panel(KEY_F3, CAGE_ARMS_PANEL, ArmsPanel.new()) \
			.panel(KEY_F4, LEGS_PANEL, LegsPanel.new()) \
			.panel(KEY_F5, EQUIPMENT_PANEL, EquipmentPanel.new(cage)) \
			.panel(KEY_F6, POSES_PANEL, ArmPosesPanel.new()) \
			.panel(KEY_F7, HANDLING_PANEL, CageHandlingPanel.new()),
		# LA CÁMARA ISOMÉTRICA (22/11/2026): la meca, subirse con la E y las teclas compartidas.
		SandboxRow.new(SandboxSuper.Id.MECH, "Cámara isométrica") \
			.add(SandboxRow.Build.NEAR, [IsoArchetype.new()]) \
			.panel(KEY_F1, "la cámara isométrica: proyección, zoom y ángulo", IsoPanel.new()),
	]


const LEGS_PANEL := "las piernas: los pasos (los mismos para todas las mecas)"
const CAGE_PANEL := "la meca jaula: moverse, girar, saltar y volar, el dash, agacharse (sólo ella)"
const CAGE_SHAPE_PANEL := "la meca jaula: la esfera de abajo, el tablero de arriba y la torre (sólo ella)"
const CAGE_ARMS_PANEL := "los brazos: lo rápido de las piñas, en todas las mecas"
## Las poses de los brazos para probar (ArmPosesPanel; temporal).
const POSES_PANEL := "las poses de los brazos para probar: el reposo del palo y del cañón, y el golpe (temporal)"
## Cómo se maneja desde adentro (CageHandlingPanel): lo de mantener apretado los mandos.
const HANDLING_PANEL := "la meca jaula: el manejo desde adentro, la piña cargada (sólo ella)"
## Lo que lleva cada brazo (EquipmentPanel): cada fila el suyo.
const EQUIPMENT_PANEL := "el equipamiento: qué lleva cada brazo, cómo se mueve y su placa (cada fila el suyo)"
