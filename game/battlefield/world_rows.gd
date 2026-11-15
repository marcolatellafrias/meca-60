class_name WorldRows
extends RefCounted

## LAS FILAS DEL SANDBOX DEL MUNDO (ver SandboxRow, docs/technical/sandbox.md): el mapa de pelea y la base.

static func rows() -> Array[SandboxRow]:
	return [
		SandboxRow.new(SandboxSuper.Id.WORLD, "Mapa de pelea").add(SandboxRow.Build.NEAR, [BattlefieldArchetype.new()]),
		# los paneles de la meca propia, para modificarla desde la base (como en BossRows); F1 queda libre para la base
		SandboxRow.new(SandboxSuper.Id.WORLD, "Base").add(SandboxRow.Build.NEAR, [BaseArchetype.new()]) \
			.panel(KEY_F2, MechRows.KINEMATIC_PANEL, KinematicPanel.new()) \
			.panel(KEY_F3, MechRows.CABIN_PANEL, CabinShapePanel.new()) \
			.panel(KEY_F4, MechRows.LEGS_PANEL, LegsPanel.new()),
	]
