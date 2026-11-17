class_name WorldRows
extends RefCounted

## LAS FILAS DEL SANDBOX DEL MUNDO (ver SandboxRow, docs/technical/sandbox.md): el mapa de pelea y la base.

static func rows() -> Array[SandboxRow]:
	return [
		SandboxRow.new(SandboxSuper.Id.WORLD, "Mapa de pelea").add(SandboxRow.Build.NEAR, [BattlefieldArchetype.new()]),
		# F1 las medidas de la base; F2 a F4, los paneles de la meca propia (la jaula), para modificarla desde la base
		SandboxRow.new(SandboxSuper.Id.WORLD, "Base").add(SandboxRow.Build.NEAR, [BaseArchetype.new()]) \
			.panel(KEY_F1, "la base: el alto de la nave, el fondo y el alto de la franja de las consolas", BasePanel.new()) \
			.panel(KEY_F2, MechRows.CAGE_PANEL, CageMovesPanel.new()) \
			.panel(KEY_F3, MechRows.CAGE_SHAPE_PANEL, CageShapePanel.new()) \
			.panel(KEY_F4, MechRows.LEGS_PANEL, LegsPanel.new()),
		SandboxRow.new(SandboxSuper.Id.WORLD, "Componentes de la armería").add(SandboxRow.Build.NEAR,
			[ArmoryPartsArchetype.new()]),
	]
