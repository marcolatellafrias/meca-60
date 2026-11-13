class_name SandboxCatalogue
extends RefCounted

## EL CATÁLOGO DEL SANDBOX: las filas de todos los módulos y los paneles F globales, y el chequeo de las reglas.
##
## Cada módulo declara sus filas en su archivo (ver SandboxRow); acá sólo se lo nombra, una línea por módulo. El orden de
## las filas en el piso no sale de acá sino de su supercategoría (ver SandboxSuper).

static func rows() -> Array[SandboxRow]:
	var out: Array[SandboxRow] = []
	out.append_array(MechRows.rows())
	out.append_array(SupplyRows.rows())
	out.append_array(CharacterRows.rows())
	out.append_array(WorldRows.rows())
	out.append_array(ArtRows.rows())
	out.append_array(NetworkRows.rows())
	return out


## LOS PANELES F GLOBALES: abren en cualquier lado. `{key, label, panel}`, de F9 a F12 (ver SandboxKey).
static func global_panels() -> Array[Dictionary]:
	return []


## ── LAS REGLAS (ver docs/technical/sandbox.md) ─────────────────────────────────────────────────────────────────────────────
## Lo que está mal en el catálogo, una línea por problema; vacío si está todo bien. El sandbox lo muestra al arrancar y
## no monta lo que choca; `tests/sandbox_check.tscn` falla si hay algo.
static func check(all_rows: Array[SandboxRow], globals: Array[Dictionary]) -> PackedStringArray:
	var out := PackedStringArray()
	var names := {}
	for row in all_rows:
		if row.name.strip_edges().is_empty():
			out.append("una fila de %s sin nombre" % SandboxSuper.name_of(row.super_id))
		elif names.has(row.name):
			out.append("dos filas se llaman «%s»" % row.name)
		names[row.name] = true
		if row.parcels.is_empty():
			out.append("fila «%s»: no tiene parcelas" % row.name)
		out.append_array(_check_keys(row))
		out.append_array(_check_panels(row))
	var taken := {}
	for entry in globals:
		var f_key: Key = entry["key"]
		if not f_key in SandboxKey.GLOBAL_PANEL_KEYS:
			out.append("el panel global «%s» usa %s: los globales van de F9 a F12" % [entry["label"],
				SandboxKey.name_of(f_key)])
		if taken.has(f_key):
			out.append("dos paneles globales usan %s" % SandboxKey.name_of(f_key))
		taken[f_key] = true
	return out


## Las teclas de cada parcela junto con las de su fila: ninguna reservada, ni F, ni repetida.
static func _check_keys(row: SandboxRow) -> PackedStringArray:
	var out := PackedStringArray()
	for made in row.keys:
		for problem in made.problems():
			out.append("fila «%s»: %s" % [row.name, problem])
	for entry in row.parcels:
		var archetype: SeededArchetype = entry["archetype"]
		var seen := {}
		var mains := 0
		var all: Array[SandboxKey] = archetype.keys()
		all.append_array(row.keys)
		for made in all:
			for problem in made.problems():
				out.append("«%s»: %s" % [archetype.display_name, problem])
			if seen.has(made.key):
				out.append("«%s»: la tecla %s está dos veces" % [archetype.display_name, SandboxKey.name_of(made.key)])
			seen[made.key] = true
			if made.weight == SandboxKey.Weight.MAIN:
				mains += 1
		if mains > 3:
			out.append("«%s»: %d teclas principales; más de tres ya no se distinguen" % [archetype.display_name, mains])
	return out


## Los paneles F de la fila: de F1 a F7, y dos que pueden abrir en el mismo lugar no comparten tecla.
static func _check_panels(row: SandboxRow) -> PackedStringArray:
	var out := PackedStringArray()
	var row_keys := {}
	var parcel_keys := {}
	var archetypes: Array = row.parcels.map(func(entry: Dictionary) -> SeededArchetype: return entry["archetype"])
	for entry in row.panels:
		var f_key: Key = entry["key"]
		var archetype: SeededArchetype = entry["archetype"]
		if not f_key in SandboxKey.LOCAL_PANEL_KEYS:
			out.append("fila «%s»: el panel «%s» usa %s; los de fila y de parcela van de F1 a F7" % [row.name,
				entry["label"], SandboxKey.name_of(f_key)])
		if archetype == null:
			if row_keys.has(f_key):
				out.append("fila «%s»: dos paneles usan %s" % [row.name, SandboxKey.name_of(f_key)])
			row_keys[f_key] = true
		else:
			if not archetypes.has(archetype):
				out.append("fila «%s»: el panel «%s» es de una parcela que no está en la fila" % [row.name,
					entry["label"]])
			var mine := "%d:%d" % [archetype.get_instance_id(), f_key]
			if parcel_keys.has(mine):
				out.append("«%s»: dos paneles usan %s" % [archetype.display_name, SandboxKey.name_of(f_key)])
			parcel_keys[mine] = f_key
	for mine: String in parcel_keys:
		if row_keys.has(parcel_keys[mine]):
			out.append("fila «%s»: un panel de parcela usa %s, que ya es de un panel de la fila" % [row.name,
				SandboxKey.name_of(parcel_keys[mine])])
	return out
