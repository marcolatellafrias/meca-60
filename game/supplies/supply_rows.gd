class_name SupplyRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LOS RECURSOS (ver SandboxRow, docs/sandbox.md): los cubos sueltos, para agarrarlos. Van con
## el Interior, que es donde se enchufan.

static func rows() -> Array[SandboxRow]:
	return [
		SandboxRow.new(SandboxSuper.Id.INTERIOR, "Recursos").add(SandboxRow.Build.NEAR, [ObjectLotArchetype.new()]),
	]
