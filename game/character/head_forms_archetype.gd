class_name HeadFormsArchetype
extends SeededArchetype

## ── LAS FORMAS DE CABEZA, A LA VISTA (17/11/2026) ───────────────────────────────────────────────────────────────────
## Lo pidió el usuario: «una parcela… que tenga las formas de las cabezas que tenemos definidas hasta ahora de low poly».
## Todas las ranuras de HeadForms en fila, numeradas, cada una sobre un taco, agrandada `ZOOM` veces para leer la forma,
## con su nombre y los arquetipos que la usan (ver CharacterLooks.head_form_for). La que se está editando en el F3
## (HeadFormsPanel) va de otro color, y todo se rearma en vivo cuando el panel cambia algo (`HeadFormsView.refresh`).
## Es la fila «Cabezas» del sandbox (ver CharacterRows; hasta el 18/11/2026 iba al final de Locomoción).

const ZOOM := 3.0
const GAP := 1.3
const STAND_H := 0.9
const SKIN := Color(0.86, 0.68, 0.55)
const EDITING := Color(0.95, 0.72, 0.35)
const STAND := Color(0.6, 0.58, 0.55)
## Lugar de sobra en la parcela para las formas que se agreguen sin rearmar el sandbox.
const SPARE := 6


static func catalogue() -> Array[SeededArchetype]:
	var row := HeadFormsArchetype.new()
	row.display_name = "Formas de cabeza"
	return [row] as Array[SeededArchetype]


func max_footprint() -> Vector2:
	return Vector2((HeadForms.count() + SPARE) * GAP + 2.0, 6.0)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray(["las formas de cabeza, × %d · F3 las edita" % int(ZOOM)])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var view := HeadFormsView.new()
	view.name = "FormasDeCabeza"
	parent.add_child(view)
	view.refresh()
	return view


## ── LA VITRINA, QUE SE REARMA ───────────────────────────────────────────────────────────────────────────────────
class HeadFormsView:
	extends Node3D

	const GROUP := "head_forms_view"

	func _ready() -> void:
		add_to_group(GROUP)

	func refresh() -> void:
		for child in get_children():
			child.queue_free()
		var users := HeadFormsArchetype._users()
		var total := HeadForms.count()
		for slot in total:
			var x := (slot - (total - 1) * 0.5) * GAP
			var stand := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.8, STAND_H, 0.8)
			stand.mesh = box
			stand.material_override = HeadFormsArchetype._matte(STAND)
			stand.position = Vector3(x, STAND_H * 0.5, 0.0)
			add_child(stand)
			var form := HeadForms.form_for(slot)
			var head := MeshInstance3D.new()
			head.mesh = form.build_mesh()
			head.material_override = HeadFormsArchetype._matte(EDITING if slot == HeadForms.editing else SKIN)
			head.scale = Vector3.ONE * ZOOM
			head.position = Vector3(x, STAND_H, 0.0)
			add_child(head)
			var tag := Label3D.new()
			var who := ", ".join(users.get(slot, [])) if users.has(slot) else ""
			tag.text = "%d. %s%s" % [slot + 1, form.name, ("\n" + who) if not who.is_empty() else ""]
			tag.font_size = 28
			tag.pixel_size = 0.004
			tag.outline_size = 6
			tag.width = 240.0
			tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tag.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			tag.position = Vector3(x, STAND_H + form.total_height() * ZOOM + 0.12, 0.0)
			add_child(tag)


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
