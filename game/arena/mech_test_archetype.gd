class_name MechTestArchetype
extends SeededArchetype

## LA FILA MECA DEL SANDBOX: la pelea de prueba en una parcela grande (TestArena): la meca y la meca rival. Para
## sentir cómo se maneja una meca de a uno, cómo se siente la pelea y la escala del lugar.

func _init() -> void:
	display_name = "Pelea de prueba"


func max_footprint() -> Vector2:
	return Vector2(TestArena.RADIUS * 2.0 + 4.0, TestArena.RADIUS * 2.0 + 4.0)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"U subirse a la meca (al piso de las piernas)",
		"mirándola, O la posee (T cambia la vista)",
		"E sentarse en un puesto / levantarse / montacargas",
		"N el rival: quieto o agresivo",
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
		{"key": KEY_N, "label": "rival quieto / agresivo", "seated": true,
			"apply": func(parcel: SandboxParcel) -> void: (parcel.root() as TestArena).toggle_rival()},
	]
