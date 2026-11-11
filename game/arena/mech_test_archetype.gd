class_name MechTestArchetype
extends SeededArchetype

## LA FILA MECA DEL SANDBOX: la pelea de prueba en una parcela grande (TestArena): la meca y el bicho de prueba. Para
## sentir cómo se maneja una meca de a uno, cómo se siente pegarle a algo grande y la escala del lugar.

func _init() -> void:
	display_name = "Pelea de prueba"


func max_footprint() -> Vector2:
	return Vector2(TestArena.RADIUS * 2.0 + 4.0, TestArena.RADIUS * 2.0 + 4.0)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"U subirse a la meca (al piso de las piernas)",
		"E sentarse en un puesto / levantarse / montacargas",
		"Sentado: flechas caminan · B se afirma · F puño · G cañón",
		"N otro bicho (otra semilla)",
	])


func build(seed_value: int, parent: Node3D) -> Node3D:
	var arena := TestArena.new()
	arena.name = "Arena"
	parent.add_child(arena)
	arena.build(seed_value)
	return arena


func parcel_options() -> Array[Dictionary]:
	return [
		{"key": KEY_U, "label": "subirse a la meca",
			"apply": func(parcel: SandboxParcel) -> void: (parcel.root() as TestArena).mech.board()},
		{"key": KEY_N, "label": "otro bicho",
			"apply": func(parcel: SandboxParcel) -> void: (parcel.root() as TestArena).new_beast(randi() & 0x7fffffff)},
	]
