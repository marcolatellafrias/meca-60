class_name ObjectLotArchetype
extends SeededArchetype

## EL LOTE DE OBJETOS: los paquetes de character-parametric SUELTOS, para agarrarlos, llevarlos, tirarlos y romperlos
## (clic izquierdo, como allá), y una silla de allá para sentarse (E). Es el lote de prueba de la sucursal de allá
## (BranchLot): la fila de paquetes de allá los muestra congelados, para mirarlos. Cada paquete es el cuerpo que arma
## `PackageArchetype.build_body`, el mismo del juego. R los vuelve a poner en su lugar.

const FOOTPRINT := Vector2(14.0, 10.0)
const CHAIR_SCENE := "res://game/ship/working_seat.tscn"


func _init() -> void:
	display_name = "Lote de objetos"


func max_footprint() -> Vector2:
	return FOOTPRINT


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"los paquetes de character-parametric, sueltos",
		"clic izquierdo agarra · E se sienta · R los acomoda",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Lote"
	parent.add_child(root)
	var kinds := PackageArchetype.catalogue()
	# En dos filas, de izquierda a derecha.
	var per_row := ceili(kinds.size() / 2.0)
	for i in kinds.size():
		var kind := kinds[i] as PackageArchetype
		var body := kind.build_body()
		var column := i % per_row
		var row := i / per_row
		body.position = Vector3(-FOOTPRINT.x * 0.5 + 1.5 + column * (FOOTPRINT.x - 3.0) / maxf(per_row - 1, 1),
			kind.rest_height(), -1.5 + row * 3.5)
		root.add_child(body)
	var chair := (load(CHAIR_SCENE) as PackedScene).instantiate() as SeatInteractable
	chair.eye_height = ShipStyle.current.seat_eye_height
	chair.position = Vector3(0.0, 0.0, FOOTPRINT.y * 0.5 - 1.0)
	chair.rotation.y = PI
	root.add_child(chair)
	return root
