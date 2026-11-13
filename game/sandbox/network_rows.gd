class_name NetworkRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LA RED (ver SandboxRow, docs/technical/sandbox.md): abrir y unirse a una sesión.

static func rows() -> Array[SandboxRow]:
	return [
		SandboxRow.new(SandboxSuper.Id.NETWORK, "Multijugador").add(SandboxRow.Build.NEAR, [MultiplayerArchetype.new()]),
	]
