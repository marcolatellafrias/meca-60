class_name CabinShape
extends Resource

## LA FORMA DE LA CABINA QUE SE GUARDA (ver CabinGrid.shape, CabinShapePanel): módulos por lado, pisos y cuánto
## sobresale el vidrio del frente (celdas).

@export_range(1, 6, 1) var modules := 4
@export_range(1, 5, 1) var floors := 3
@export_range(0, 48, 1) var glass_out := 12
