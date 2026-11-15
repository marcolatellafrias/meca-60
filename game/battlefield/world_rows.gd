class_name WorldRows
extends RefCounted

## LAS FILAS DEL SANDBOX DEL MUNDO (ver SandboxRow, docs/technical/sandbox.md): el mapa de pelea y la base.

static func rows() -> Array[SandboxRow]:
	return [
		SandboxRow.new(SandboxSuper.Id.WORLD, "Mapa de pelea").add(SandboxRow.Build.NEAR, [BattlefieldArchetype.new()]),
		SandboxRow.new(SandboxSuper.Id.WORLD, "Base").add(SandboxRow.Build.NEAR, [BaseArchetype.new()]),
	]
