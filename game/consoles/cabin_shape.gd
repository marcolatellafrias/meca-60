class_name CabinShape
extends Resource

## LA FORMA DE LA MECA QUE SE GUARDA (ver CabinGrid.apply, CabinShapePanel): la cabina —la celda de la trama, cuántas
## por lado, el alto, el corte del vidrio y el ascensor—, las sillas y el cuerpo —el largo de brazos y piernas, el ancho
## de todo y cuánto se estiran las piernas paradas—.

@export_group("La caja")
## Una celda de la trama, en celdas chicas de 3,9 cm (13: 51 cm).
@export_range(8, 20, 1) var cell := 13
## Cuántas celdas de trama por lado (la planta es cuadrada; siempre par; los tres puestos de adelante piden 12).
@export_range(12, 20, 2) var across := 12
## El alto libre, del piso al techo, en celdas chicas (96: 3,78 m).
@export_range(70, 140, 1) var height_cells := 96
## El corte de la arista de arriba del frente, en celdas de trama.
@export_range(0, 4, 1) var chamfer := 2
## Hasta dónde llega el vidrio de los costados, desde el frente, en celdas de trama (6: la mitad).
@export_range(0, 18, 1) var side_glass := 6
## Hasta dónde llega el vidrio del techo, desde el frente, en celdas de trama (lo mismo que el corte: sólo el corte).
@export_range(0, 20, 1) var roof_glass := 2
## El radio del hueco del ascensor, en celdas de trama.
@export_range(1, 3, 1) var lift_cells := 2
## El alto de la tarima de atrás (m; de a un escalón, 15 cm).
@export_range(0.3, 2.4, 0.15) var platform_height := 1.2
@export_group("Las sillas")
## La altura que buscan igualar las sillas: la de los ojos del que se sienta, sobre el piso (m).
@export_range(0.9, 1.6, 0.01) var eye_height := 1.15
@export_group("Brazos y piernas")
@export_enum("chico", "mediano", "grande") var arm_length := 1
@export_enum("chico", "mediano", "grande") var leg_length := 1
## El grosor de brazos y piernas (y articulaciones, manos, pies y pelvis), uno solo para los dos.
@export_enum("chico", "mediano", "grande") var thickness := 1
## Cuánto se estiran las piernas paradas: la distancia de la cadera al tobillo, en partes del largo de la pierna.
@export_range(0.45, 0.9, 0.01) var leg_stretch := 0.64
