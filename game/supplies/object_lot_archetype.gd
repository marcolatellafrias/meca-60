class_name ObjectLotArchetype
extends SeededArchetype

## EL LOTE DE RECURSOS: los recursos de la meca SUELTOS (ver SupplyLook y PackageArchetype.catalogue), para agarrarlos,
## llevarlos y tirarlos (clic izquierdo), cada uno el cuerpo que arma `PackageArchetype.build_body`. Al fondo, FIJOS, los
## dos cubos que van en la meca y muestran la munición que les queda: los misiles y las balas. Y una silla para sentarse
## (E). R los vuelve a poner en su lugar. *Todavía no se enchufan en nada: eso es lo que sigue (ver docs/conceptual/recursos.md).*

const FOOTPRINT := Vector2(10.0, 9.0)
const CHAIR_SCENE := "res://game/interactables/activatable/working_seat.tscn"


func _init() -> void:
	display_name = "Lote de recursos"


func max_footprint() -> Vector2:
	return FOOTPRINT


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"los recursos de la meca, sueltos: batería, componente eléctrico, cajas de misiles y de balas, bomba",
		"al fondo, fijos: los misiles y las balas como van en la meca",
		"clic izquierdo agarra · E se sienta · R los acomoda",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Lote"
	parent.add_child(root)
	var kinds := PackageArchetype.catalogue()
	# En una fila, de izquierda a derecha, con la cara de lectura hacia donde uno llega (+Z).
	for i in kinds.size():
		var kind := kinds[i] as PackageArchetype
		var body := kind.build_body()
		body.position = Vector3((i - (kinds.size() - 1) * 0.5) * 1.3, kind.rest_height(), 0.0)
		root.add_child(body)
	# LOS QUE VAN EN LA MECA, fijos sobre un banco: los misiles (quedan seis) y las balas (a medias).
	var bench := StaticBody3D.new()
	bench.position = Vector3(0.0, 0.0, -2.0)
	root.add_child(bench)
	Clay.solid(bench, Vector3(2.4, 0.9, 0.7), Vector3(0, 0.45, 0), Color(0.62, 0.6, 0.56))
	for index in 2:
		var cube := Node3D.new()
		cube.position = Vector3((index - 0.5) * 1.1, 0.9 + SupplyLook.H, 0.0)
		bench.add_child(cube)
		Clay.shape_box(bench, Vector3.ONE * SupplyLook.U, cube.position)
		if index == 0:
			SupplyLook.missiles(cube, 6)
		else:
			SupplyLook.belt(cube, 11)
	var chair := (load(CHAIR_SCENE) as PackedScene).instantiate() as SeatInteractable
	chair.eye_height = SeatInteractable.STATION_EYE_HEIGHT
	chair.position = Vector3(0.0, 0.0, FOOTPRINT.y * 0.5 - 1.0)
	chair.rotation.y = PI
	root.add_child(chair)
	return root
