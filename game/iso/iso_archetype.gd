class_name IsoArchetype
extends MechArchetype

## LA PARCELA PARA PROBAR LA CÁMARA ISOMÉTRICA (22/11/2026): la meca jaula y la cámara, que vale sólo adentro de la
## parcela. E mirando la meca sube; arriba, WASD la mueve y las flechas giran su frente.

const SIDE := 60.0


func _init() -> void:
	display_name = "Cámara isométrica"


func max_footprint() -> Vector2:
	return Vector2(SIDE, SIDE)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"adentro de esta parcela la cámara es isométrica; WASD camina según la pantalla",
		"cerca de la meca y mirándola, E sube; arriba, WASD la mueve y las flechas giran su frente",
		"Alt muestra el mouse: pasalo por los cuadrados para ver qué hace cada tecla",
	])


func default_loadout() -> Array[ArmLoadout]:
	return CageMech.default_arms()


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = display_name
	parent.add_child(root)
	var mech := CageMech.new()
	mech.equipment = CageMechArchetype.ROW
	mech.position = Vector3(0.0, Mech.standing_height(mech.cabin_shape), 0.0)
	root.add_child(mech)
	var view := IsoView.new()
	view.zone = Rect2(-SIDE * 0.5, -SIDE * 0.5, SIDE, SIDE)
	root.add_child(view)
	return root
