class_name HeadFormsArchetype
extends SeededArchetype

## ── LAS FORMAS DE CABEZA, A LA VISTA (17/11/2026) ───────────────────────────────────────────────────────────────────
## Lo pidió el usuario: «una parcela al lado de lo de experimento de locomoción que tenga las formas de las cabezas que
## tenemos definidas hasta ahora de low poly». Las diez ranuras de HeadForms en fila, numeradas, cada una sobre un taco,
## agrandada `ZOOM` veces para leer la forma, con su nombre y los arquetipos que la usan (ver CharacterLooks.head_form_for).
## Sólo para mirar: no edita nada (en character-parametric eso era la fila «Formas de cabeza», que no se trajo).

const ZOOM := 3.0
const GAP := 1.3
const STAND_H := 0.9
const SKIN := Color(0.86, 0.68, 0.55)
const STAND := Color(0.6, 0.58, 0.55)


static func catalogue() -> Array[SeededArchetype]:
	var row := HeadFormsArchetype.new()
	row.display_name = "Formas de cabeza"
	return [row] as Array[SeededArchetype]


func max_footprint() -> Vector2:
	return Vector2(HeadForms.SLOTS * GAP + 2.0, 6.0)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray(["las %d formas de cabeza, × %d" % [HeadForms.SLOTS, int(ZOOM)]])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "FormasDeCabeza"
	parent.add_child(root)
	var users := _users()
	for slot in HeadForms.SLOTS:
		var x := (slot - (HeadForms.SLOTS - 1) * 0.5) * GAP
		var stand := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.8, STAND_H, 0.8)
		stand.mesh = box
		stand.material_override = _matte(STAND)
		stand.position = Vector3(x, STAND_H * 0.5, 0.0)
		root.add_child(stand)
		var form := HeadForms.form_for(slot)
		var head := MeshInstance3D.new()
		head.mesh = form.build_mesh()
		head.material_override = _matte(SKIN)
		head.scale = Vector3.ONE * ZOOM
		head.position = Vector3(x, STAND_H, 0.0)
		root.add_child(head)
		var tag := Label3D.new()
		tag.text = "%d. %s%s" % [slot + 1, form.name, ("\n" + ", ".join(users.get(slot, []))) if users.has(slot) else ""]
		tag.font_size = 40
		tag.pixel_size = 0.004
		tag.outline_size = 8
		tag.width = 260.0
		tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tag.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		tag.position = Vector3(x, STAND_H + form.total_height() * ZOOM + 0.15, 0.0)
		root.add_child(tag)
	return root


## Ranura → los nombres de los arquetipos que la usan.
static func _users() -> Dictionary:
	var out := {}
	for archetype: int in PeopleArchetype.ROW_ORDER:
		var slot := CharacterLooks.head_form_for(archetype)
		if not out.has(slot):
			out[slot] = []
		(out[slot] as Array).append(String(EntityArchetype.Archetype.keys()[archetype]).capitalize())
	return out


static func _matte(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
