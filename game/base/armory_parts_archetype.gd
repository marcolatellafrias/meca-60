class_name ArmoryPartsArchetype
extends SeededArchetype

## LA PARCELA DE LOS COMPONENTES (ver ArmoryParts): las maquetas de arcilla de todo lo que vende la armería, numeradas y
## en tres filas: lo del brazo, lo de la espalda y las placas.

const SPACING := 9.0
const ROW_GAP := 15.0
const ROWS := [
	["fist", "heavy_fist", "drill", "energy_cannon", "circular_saw"],
	["machine_gun", "missile_launcher", "heavy_cannon"],
	["plate_hull", "plate_arm", "plate_leg"],
]
## A qué alto va lo del brazo (en el aire, sobre un poste).
const ARM_HEIGHT := 4.0
## Los carteles con el número (las capturas de cerca los esconden).
const SIGNS := "armory_parts_signs"


func _init() -> void:
	display_name = "Componentes de la armería"


func max_footprint() -> Vector2:
	return Vector2(SPACING * 5.0 + 6.0, ROW_GAP * 3.0 + 6.0)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"las maquetas de arcilla de lo que vende la armería, a la escala de la meca",
		"adelante, lo del brazo: los dos puños y las tres herramientas · al medio, la espalda · atrás, las placas",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Componentes"
	parent.add_child(root)
	var number := 1
	for row in ROWS.size():
		var ids: Array = ROWS[row]
		for i in ids.size():
			var id: String = ids[i]
			var at := Vector3(((ids.size() - 1) * 0.5 - i) * SPACING, 0.0, (row - 1) * ROW_GAP)
			var piece := ArmoryParts.build(id, root)
			if row == 0 or id == "plate_arm":
				piece.position = at + Vector3(0, ARM_HEIGHT, 0)
				Clay.box(root, Vector3(0.3, ARM_HEIGHT - ArmoryParts.ARM_HALF, 0.3),
					at + Vector3(0, (ARM_HEIGHT - ArmoryParts.ARM_HALF) * 0.5, 0.8), Clay.DARK)
			else:
				piece.position = at + Vector3(0, 1.0 if row == 1 else 0.0, 0)
			var sign := Label3D.new()
			sign.add_to_group(SIGNS)
			sign.text = "%d. %s" % [number, ArmoryCatalog.item(id).name]
			sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sign.font_size = 64
			sign.pixel_size = 0.01
			sign.outline_size = 16
			sign.position = at + Vector3(0, 7.5, 0)
			root.add_child(sign)
			number += 1
	return root
