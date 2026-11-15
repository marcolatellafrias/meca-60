class_name VortexShape
extends Resource

## LA FORMA DE LA MECA DEL VÓRTICE QUE SE GUARDA (ver VortexCabin.apply, VortexShapePanel), aparte de la de la cuadrada y
## la de la redonda. El usuario, 15/11/2026: «parametrizar todo y agregar opciones para cambiar brazos y piernas solo
## para esta versión… un toggle para sacar los obstáculos del medio, radio general, ancho de escaleras». El cuerpo de
## esta meca (el largo de los brazos y de las piernas) va acá, no en el de todas.

@export_group("El disco")
## El radio de afuera del disco (m).
@export_range(3.0, 10.0, 0.1) var radius := 5.5
## El alto libre de la planta baja, del piso al techo (m).
@export_range(2.3, 5.0, 0.05) var floor_height := 3.0
## EL NÚCLEO DEL MEDIO, en el primer piso: la columna opaca que hace que arriba se camine en anillo. Sin él, arriba es un
## piso entero.
@export var core := true
@export_group("La escalera")
## El ancho de la escalera caracol (m).
@export_range(0.8, 3.0, 0.05) var stair_width := 1.8
@export_group("Brazos y piernas")
## El largo de las piernas y de los brazos, en partes de los de las otras mecas (sólo para esta).
@export_range(0.3, 1.5, 0.05) var legs := 0.6
@export_range(0.3, 1.5, 0.05) var arms := 1.0
