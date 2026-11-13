class_name BossRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LOS JEFES (ver SandboxRow, docs/technical/sandbox.md).

static func rows() -> Array[SandboxRow]:
	return [
		SandboxRow.new(SandboxSuper.Id.BOSSES, "Jefe bola") \
			.add(SandboxRow.Build.NEAR, [BallBossArchetype.new()]) \
			.panel(KEY_F1, "el jefe bola: moverse, girar, saltar, agacharse y los tentáculos", BallBossPanel.new()),
	]
