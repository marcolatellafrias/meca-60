class_name PodShape
extends Resource

## LA FORMA DE LA MECA DE CÁPSULAS QUE SE GUARDA (ver PodCabin.apply, PodShapePanel), aparte de las de las otras. El
## usuario, 15/11/2026, de la maqueta 37 de tests/sphere_pods_look: «pasemos esta maqueta de forma paramétrica y
## ordenada al sistema de la nave… cómo se miden los radios en los que van las cápsulas… juntar todo más hacia adelante…
## el radio del cuerpo… el tamaño de la zona cilíndrica». EL CUERPO DE ESTA MECA, con los mismos campos que el de las
## otras (la pestaña «Brazos y piernas», como la del vórtice).

@export_group("El cuerpo")
## El radio del torso (m).
@export_range(3.0, 10.0, 0.1) var radius := 5.8
## El alto de la parte cilíndrica, la pared derecha del medio (m). Las cápsulas, los hombros y los recursos van a su
## mitad.
@export_range(0.0, 8.0, 0.05) var wall := 3.0
## El alto del domo de arriba (m).
@export_range(0.5, 8.0, 0.05) var dome := 3.8
## El borde de abajo, redondeado: su radio (m). El fondo es chato.
@export_range(0.1, 3.0, 0.05) var edge := 0.7
@export_group("Las cápsulas")
## EL RADIAL DE LAS CÁPSULAS: a cuántos grados del frente van las de los costados (la del medio, al frente).
@export_range(10.0, 120.0, 1.0) var pod_step := 45.0
## Cuánto asoman del cuerpo (en partes de su diámetro; 0,25: un cuarto afuera).
@export_range(0.05, 0.8, 0.01) var pod_out := 0.25
## La ventana de vidrio de cada cápsula: su ancho, en grados desde el centro (el resto, opaco).
@export_range(20.0, 85.0, 1.0) var window := 55.0
@export_group("Los hombros")
## EL RADIAL DE LOS HOMBROS: a cuántos grados del frente van, aparte de las cápsulas.
@export_range(20.0, 160.0, 1.0) var shoulder_step := 90.0
@export_group("Brazos y piernas")
@export_enum("chico", "mediano", "grande") var arm_length := 1
@export_enum("chico", "mediano", "grande") var leg_length := 1
## El grosor de brazos y piernas (y articulaciones, manos, pies y pelvis), uno solo para los dos.
@export_enum("chico", "mediano", "grande") var thickness := 1
## Cuánto se estiran las piernas paradas: la distancia de la cadera al tobillo, en partes del largo de la pierna.
@export_range(0.45, 0.9, 0.01) var leg_stretch := 0.64
## Cuánto salen los hombros del costado (m, con el grosor de mediano).
@export_range(0.0, 3.0, 0.05) var shoulder_out := 0.5
