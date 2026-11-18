class_name HeadPaintArchetype
extends SeededArchetype

## ── PINTAR CARAS SOBRE LAS CABEZAS LOW POLY (18/11/2026) ────────────────────────────────────────────────────────────
## Lo pidió el usuario: «poder en una forma de cara pintar yo a mano varias caras distintas y ver cómo quedan»; «una
## misma silueta tenga varias pinturas, pero solamente para esa silueta»; la resolución «de cada cara guardada… volver
## atrás a otra versión guardada vieja sin el problema de tener miedo a perder una resolución». Una parcela de la fila
## «Cabezas»: la forma elegida (ver HeadForms), grande, como un modelo pintable de la herramienta de píxeles (ver
## PixelModel, docs/technical/pixel-art.md): sus caras son planas (cada anillo es el mismo octógono agrandado o corrido),
## así que la herramienta las toma tal cual y se pintan con su panel (F1, PixelPaintPanel), mirando una cara.
##
## UNA PINTURA es un archivo de la herramienta (`faces/cabeza<forma>_<n>.json`) con su densidad, su giro y sus
## píxeles: está atada a su forma de cabeza (los píxeles se anclan a la posición de cada cara). Cada forma puede tener
## varias. El GIRO (`front_face`): el octógono con una esquina adelante, como siempre, o con un lado plano adelante (ver
## HeadForm.build_arrays). La densidad y el giro se eligen para la pintura nueva (K, Y) y quedan guardados con ella.
## El sombreado es suave, como en el juego.

const FOLDER := "res://game/character/faces/"
const SKIN := Color(0.86, 0.68, 0.55)
## Lo grande que se ve (la cabeza mide unos 25 cm).
const ZOOM := 4.0
const STAND_H := 0.9
## Las densidades para probar, en píxeles por metro de la cabeza de verdad (el mundo usa unos 25).
const DENSITIES := [64, 100, 150, 200]

## La forma que se pinta, la pintura elegida (índice en `paintings()`) y cómo nace la próxima.
var head_slot := 0
var painting := 0
var new_density := 1
var new_front_face := true


static func catalogue() -> Array[SeededArchetype]:
	var row := HeadPaintArchetype.new()
	row.display_name = "Pintar caras"
	return [row] as Array[SeededArchetype]


func max_footprint() -> Vector2:
	return Vector2(6.0, 6.0)


func describe(_seed_value: int) -> PackedStringArray:
	var names := paintings()
	var current := "ninguna (U crea una)" if names.is_empty() else names[clampi(painting, 0, names.size() - 1)]
	var data := PixelModel.peek(FOLDER, current) if not names.is_empty() else {}
	var lines := PackedStringArray(["forma %d · pintura: %s" % [head_slot + 1, current]])
	if not data.is_empty():
		lines.append("%d px/m · %s" % [_per_meter(int(data.get("pixels_per_cell", 0))),
			"lado adelante" if bool((data.get("extra", {}) as Dictionary).get("front_face", false)) else "esquina adelante"])
	lines.append("mirá una cara y F1 la pinta")
	return lines


## LAS PINTURAS DE LA FORMA ELEGIDA, por nombre (sin «.json»), en orden.
func paintings() -> PackedStringArray:
	var out := PackedStringArray()
	var prefix := _prefix()
	for file in DirAccess.get_files_at(FOLDER):
		if file.begins_with(prefix) and file.ends_with(".json"):
			out.append(file.trim_suffix(".json"))
	out.sort()
	return out


func _prefix() -> String:
	return "cabeza%d_" % (head_slot + 1)


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "PintarCaras"
	parent.add_child(root)
	var stand := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, STAND_H, 1.0)
	stand.mesh = box
	stand.material_override = HeadFormsArchetype._matte(HeadFormsArchetype.STAND)
	stand.position = Vector3(0.0, STAND_H * 0.5, 0.0)
	root.add_child(stand)
	# SIN PINTURAS TODAVÍA, nace la primera (con lo elegido para la nueva): siempre se pinta una que tiene nombre.
	if paintings().is_empty():
		_make_painting()
	var names := paintings()
	painting = clampi(painting, 0, names.size() - 1)
	var name_for_paint := names[painting]
	var data := PixelModel.peek(FOLDER, name_for_paint)
	var model := PixelModel.new()
	model.folder = FOLDER
	model.smooth_normals = true
	model.pixels_per_cell = int(data.get("pixels_per_cell", _per_cell(int(DENSITIES[new_density]))))
	var front := bool((data.get("extra", {}) as Dictionary).get("front_face", new_front_face))
	model.from_mesh(HeadForms.form_for(head_slot).build_mesh(front), SKIN, name_for_paint)
	model.extra["front_face"] = front
	model.scale = Vector3.ONE * ZOOM
	model.position = Vector3(0.0, STAND_H, 0.0)
	root.add_child(model)
	return root


## Densidad por metro ↔ por cubo de 63 cm (la unidad de PixelModel).
static func _per_cell(per_meter: int) -> int:
	return maxi(1, roundi(per_meter * PixelModel.CELL))


static func _per_meter(per_cell: int) -> int:
	return roundi(per_cell / PixelModel.CELL)


## ── LAS TECLAS ──────────────────────────────────────────────────────────────────────────────────────────────────
func keys() -> Array[SandboxKey]:
	return [
		SandboxKey.action(KEY_J, SandboxKey.Weight.MAIN, func() -> String: return "otra pintura de esta forma",
			func(parcel: SandboxParcel) -> void:
				painting += 1
				if painting >= paintings().size():
					painting = 0
				_rebuild(parcel)),
		SandboxKey.action(KEY_U, SandboxKey.Weight.MAIN, func() -> String:
				return "pintura nueva (%d px/m, %s)" % [DENSITIES[new_density],
					"lado adelante" if new_front_face else "esquina adelante"],
			func(parcel: SandboxParcel) -> void: _create(parcel)),
		SandboxKey.action(KEY_N, SandboxKey.Weight.MAIN, func() -> String: return "otra forma de cabeza (%d)" % (head_slot + 1),
			func(parcel: SandboxParcel) -> void:
				head_slot = (head_slot + 1) % HeadForms.count()
				painting = 0
				_rebuild(parcel)),
		SandboxKey.cycle(KEY_K, SandboxKey.Weight.NORMAL, "densidad de la nueva (px/m)", DENSITIES,
			func() -> int: return new_density,
			func(_parcel: SandboxParcel, i: int) -> void: new_density = i),
		SandboxKey.toggle(KEY_Y, SandboxKey.Weight.NORMAL, "la nueva con un lado adelante", func() -> bool: return new_front_face,
			func(_parcel: SandboxParcel, on: bool) -> void: new_front_face = on),
		SandboxKey.action(KEY_X, SandboxKey.Weight.NORMAL, func() -> String: return "borrar esta pintura",
			func(parcel: SandboxParcel) -> void: _delete(parcel)),
	] as Array[SandboxKey]


## UNA PINTURA NUEVA de la forma elegida, con la densidad y el giro elegidos, guardada en el acto (vacía, del color de
## la piel) para que exista y se pueda elegir.
func _create(parcel: SandboxParcel) -> void:
	painting = paintings().find(_make_painting())
	_rebuild(parcel)


## La crea y la guarda; devuelve su nombre.
func _make_painting() -> String:
	var taken := paintings()
	var n := 1
	while taken.has("%s%d" % [_prefix(), n]):
		n += 1
	var model := PixelModel.new()
	model.folder = FOLDER
	model.smooth_normals = true
	model.pixels_per_cell = _per_cell(int(DENSITIES[new_density]))
	model.extra = {"front_face": new_front_face}
	model.from_mesh(HeadForms.form_for(head_slot).build_mesh(new_front_face), SKIN, "%s%d" % [_prefix(), n])
	model.save()
	model.free()
	return "%s%d" % [_prefix(), n]


func _delete(parcel: SandboxParcel) -> void:
	var names := paintings()
	if names.is_empty():
		return
	painting = clampi(painting, 0, names.size() - 1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FOLDER + names[painting] + ".json"))
	painting = maxi(painting - 1, 0)
	_rebuild(parcel)


func _rebuild(parcel: SandboxParcel) -> void:
	parcel.regenerate(parcel.seed_value)
