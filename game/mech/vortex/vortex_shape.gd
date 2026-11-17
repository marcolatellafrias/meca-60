class_name VortexShape
extends Resource

## LA FORMA DE LA MECA DEL VÓRTICE QUE SE GUARDA (ver VortexCabin.apply, VortexShapePanel), aparte de la de la cuadrada y
## la de la redonda. El usuario, 15/11/2026: «parametrizar todo y agregar opciones para cambiar brazos y piernas solo
## para esta versión… un toggle para sacar los obstáculos del medio, radio general, ancho de escaleras». EL CUERPO DE
## ESTA MECA, con los mismos campos que el de las otras (CabinShape, la pestaña «Brazos y piernas»), guardado acá:
## «simplemente quería reutilizar lo del panel de la meca normal, pero que al guardarse se guarde en otro archivo».
## *Fueron dos perillas continuas (el largo de los brazos y de las piernas, en partes del de las otras) por un rato.*

@export_group("El disco")
## El radio de afuera del disco (m).
@export_range(3.0, 10.0, 0.1) var radius := 5.5
## El alto libre de la planta baja, del piso al techo (m).
@export_range(2.3, 5.0, 0.05) var floor_height := 3.0
## EL NÚCLEO DEL MEDIO, en el primer piso: la columna opaca que hace que arriba se camine en anillo. Sin él, arriba es un
## piso entero.
@export var core := true
## ATRÁS, EL BORDE MÁS ALTO, con un escalón (sólo el borde; el piso queda parejo).
@export var back_raised := true
## El radio del vórtice (m): el hueco del piso de la planta baja por donde te sube. Aparte del núcleo de arriba.
@export_range(0.4, 2.5, 0.05) var vortex_radius := 0.7
@export_group("La escalera")
## El ancho de la escalera caracol (m).
@export_range(0.8, 3.0, 0.05) var stair_width := 1.8
@export_group("Brazos y piernas")
@export_enum("chico", "mediano", "grande") var arm_length := 1
## Chicas: el usuario las pidió más cortas que las de las otras («y piernas más cortas… sólo esta meca»).
@export_enum("chico", "mediano", "grande") var leg_length := 0
## El grosor de brazos y piernas (y articulaciones, manos, pies y pelvis), uno solo para los dos.
@export_enum("chico", "mediano", "grande") var thickness := 1
## Cuánto se estiran las piernas paradas: la distancia de la cadera al tobillo, en partes del largo de la pierna.
@export_range(0.45, 0.98, 0.01) var leg_stretch := 0.64
## Cuánto salen los hombros del costado (m, con el grosor de mediano).
@export_range(0.0, 3.0, 0.05) var shoulder_out := 1.0
