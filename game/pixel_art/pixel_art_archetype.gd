class_name PixelArtArchetype
extends SeededArchetype

## LA PARCELA DE PINTAR CON PÍXELES (fila «Píxeles», ver docs/pixel-art.md): sobre un banco, un cubo de 63 cm armado
## en código y una caja traída de Blender (`models/caja.glb`), cada uno un PixelModel. Mirando una cara, **F1** abre el
## panel plano de pintar (PixelPaintPanel). **N** cambia la caja por su versión 2 (`caja_v2.glb`: la manija más larga y
## una chapa al frente) CON LA MISMA PINTURA: para ver qué sobrevive a remodelar.

const FOOTPRINT := Vector2(6.0, 5.0)
const MODELS := "res://game/pixel_art/models/"
const BENCH_HEIGHT := 0.75
const SECOND_VERSION := "pixel_art_v2"


func _init() -> void:
	display_name = "Pintar con píxeles"


func max_footprint() -> Vector2:
	return FOOTPRINT


func describe(_seed_value: int) -> PackedStringArray:
	var second := bool(options.get(SECOND_VERSION, false))
	return PackedStringArray([
		"un cubo de 63 cm (código) y una caja de Blender, %d píxeles por cubo" % PixelModel.PIXELS_PER_CELL,
		"F1 pinta la cara que mirás · clic en otra cara la elige",
		"N: la caja %s, con la misma pintura" % ("versión 2 (manija larga, chapa)" if second else "versión 1"),
	])


func keys() -> Array[SandboxKey]:
	return [SandboxKey.toggle(KEY_N, SandboxKey.Weight.NORMAL, "otra versión de la caja (misma pintura)",
		func() -> bool: return bool(options.get(SECOND_VERSION, false)),
		func(parcel: SandboxParcel, on: bool) -> void:
			options[SECOND_VERSION] = on
			parcel.regenerate(parcel.seed_value, false))]


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Pixeles"
	parent.add_child(root)
	var bench := StaticBody3D.new()
	root.add_child(bench)
	Clay.solid(bench, Vector3(2.6, BENCH_HEIGHT, 1.0), Vector3(0, BENCH_HEIGHT * 0.5, 0), Color(0.62, 0.6, 0.56))
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * PixelModel.CELL
	var plain := PixelModel.new().from_mesh(cube, SupplyLook.CRATE, "cubo")
	plain.position = Vector3(-0.6, BENCH_HEIGHT + PixelModel.CELL * 0.5, 0.0)
	root.add_child(plain)
	var file := "caja_v2" if bool(options.get(SECOND_VERSION, false)) else "caja"
	var box := PixelModel.new().from_scene(load(MODELS + file + ".glb") as PackedScene, "caja")
	box.position = Vector3(0.6, BENCH_HEIGHT, 0.0)
	root.add_child(box)
	for model: PixelModel in [plain, box]:
		Clay.shape_box(bench, Vector3(PixelModel.CELL, PixelModel.CELL * 1.05, PixelModel.CELL),
			Vector3(model.position.x, BENCH_HEIGHT + PixelModel.CELL * 0.52, 0.0))
	return root
