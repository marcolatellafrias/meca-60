class_name RoundShape
extends Resource

## LA FORMA DE LA MECA REDONDA QUE SE GUARDA (ver RoundGrid.apply, RoundShapePanel). Aparte de la de la cuadrada
## (CabinShape): cambiar una no toca la otra.

@export_group("La caja")
## Cuántos lados tiene adentro (afuera es un cilindro liso).
@export_range(8, 16, 2) var sides := 12
## El radio de adentro, del centro a un vértice (m). 3,55: la superficie de la cuadrada de 6,14 m.
@export_range(2.5, 9.0, 0.05) var radius := 3.55
## El alto libre de la cabina, del piso al techo (m).
@export_range(2.0, 4.0, 0.05) var clear_height := 2.3
## El alto del disco de abajo, entre la cabina y las piernas (m; 0, sin disco).
@export_range(0.0, 3.0, 0.05) var disc_height := 1.0
## EL DOMO: el techo termina en una media esfera de metal (sin vidrio), abierta por dentro (el usuario, 15/11/2026:
## «que el disco principal termine en forma de domo arriba (sin cristal obvio)… que el interior sea más espacioso»; «lo
## haría media esfera»). Su alto es el radio de afuera.
@export var dome := false
@export_group("La tarima y el ascensor")
## El radio de la tarima del medio, a un vértice (m), y su alto (m; el escalón de alrededor, la mitad).
@export_range(0.8, 5.0, 0.05) var platform_radius := 1.35
@export_range(0.15, 0.9, 0.05) var platform_height := 0.3
## El radio del ascensor (m) y cuánto va corrido hacia atrás desde el centro (m). *Atraviesa la pelvis: se arregla
## después (el usuario, 15/11/2026: «que atraviese por ahora»).*
@export_range(0.3, 2.0, 0.01) var lift_radius := 0.5
@export_range(0.0, 3.0, 0.05) var lift_back := 0.7
@export_group("El vidrio")
## Cuántos lados del frente son de vidrio, desde el piso.
@export_range(1, 9, 2) var glass_sides := 5
## EL ALTO DEL VISOR: hasta dónde sube el vidrio desde el piso (m); arriba, hasta el techo, metal. Para subir el techo
## sin subir el visor (el usuario, 15/11/2026: «otro factor que sea alto del visor delantero, así puedo aumentar el
## techo, sin subir el visor»). Más alto que el techo, de piso a techo.
@export_range(0.8, 5.0, 0.05) var visor_height := 2.3
@export var glass_color := Color(0.6, 0.8, 0.92)
@export_range(0.02, 0.9, 0.01) var glass_opacity := 0.14
