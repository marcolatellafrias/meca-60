class_name HoverCubeArchetype
extends SeededArchetype

## LA PARCELA DEL CUBO FLOTANTE (ver HoverCube): el cubo flotando en el medio, para tirarle bolas (J tira, K pasa por las
## tres fuerzas, ver TestBall) y mirar cómo rebota, cómo se cae y cómo se recupera con sus propulsores. F1 abre su panel
## (HoverPanel). R lo vuelve a poner, flotando.

const FOOTPRINT := 30.0


func _init() -> void:
	display_name = "Cubo flotante"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"flota con un resorte de altura y un torque que lo endereza",
		"(el cuerpo de character-parametric antes del 13/03/2026)",
		"se cae con física y se recupera con propulsores",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Cubo flotante"
	parent.add_child(root)
	var cube := HoverCube.new()
	# Nace donde flota, mirando hacia donde uno llega (−X).
	cube.transform = Transform3D(Basis(Vector3.UP, PI * 0.5),
		Vector3(0.0, HoverCubeSettings.current.hover_height + HoverCube.SIZE * 0.5, 0.0))
	root.add_child(cube)
	return root


func parcel_options() -> Array[Dictionary]:
	return TestBall.parcel_options()
