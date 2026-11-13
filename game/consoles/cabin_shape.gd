class_name CabinShape
extends Resource

## LA FORMA DE LA MECA QUE SE GUARDA (ver CabinGrid.apply, CabinShapePanel): la cabina —módulos por lado, pisos, el alto
## de cada piso y cuánto sobresale el vidrio del frente, en celdas—, las sillas y el cuerpo —dónde van los hombros, el
## largo de brazos y piernas, el ancho de todo y cuánto se estiran las piernas paradas—.

@export_group("La caja")
@export_range(1, 6, 1) var modules := 4
@export_range(1, 5, 1) var floors := 3
@export_range(40, 120, 1) var floor_cells := 68
@export_range(0, 48, 1) var glass_out := 12
@export_group("La estructura")
## POR DÓNDE SE ANDA Y SE SUBE (13/11/2026, el usuario: «variantes de la base… que podría cambiar en un panel F de forma
## de la meca»): AFUERA, la pasarela de planta baja, la escalera de atrás y una puerta atrás en cada piso (MechExterior);
## ADENTRO, sin nada afuera ni puertas, y la escalera adentro, contra la pared de atrás (MechInsideStairs). En las dos se
## entra también por el ascensor.
@export_enum("afuera: pasarela y escalera de atrás", "adentro: escalera contra la pared de atrás") var structure := 0
@export_group("Las sillas")
## La altura que buscan igualar las sillas: la de los ojos del que se sienta, sobre el piso (m).
@export_range(0.9, 1.6, 0.01) var eye_height := 1.15
## De la silla (su centro) al vidrio del frente, en celdas.
@export_range(10, 80, 1) var seat_gap := 26
@export_group("Los hombros")
## Los hombros: en qué piso (a la mitad de su alto) y en qué módulo del costado. El del medio, si no hay uno justo en el
## medio, es el de abajo (pisos) o el de adelante (módulos) de los dos del medio.
@export_enum("primero", "del medio", "último") var arm_floor := 1
@export_enum("adelante", "del medio", "atrás") var arm_along := 1
@export_group("Brazos y piernas")
@export_enum("chico", "mediano", "grande") var arm_length := 1
@export_enum("chico", "mediano", "grande") var leg_length := 1
## El grosor de brazos y piernas (y articulaciones, manos, pies y pelvis), uno solo para los dos.
@export_enum("chico", "mediano", "grande") var thickness := 1
## Cuánto se estiran las piernas paradas: la distancia de la cadera al tobillo, en partes del largo de la pierna.
@export_range(0.45, 0.9, 0.01) var leg_stretch := 0.64
