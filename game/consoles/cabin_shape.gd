class_name CabinShape
extends Resource

## LA FORMA DE LA MECA QUE SE GUARDA (ver CabinGrid.apply, CabinShapePanel): la cabina —la celda de la trama, cuántas
## por lado, el alto, el ascensor y el vidrio (su corte, hasta dónde llega y su color)—, las sillas y el cuerpo —el largo de brazos y piernas, el ancho
## de todo y cuánto se estiran las piernas paradas—.

@export_group("La caja")
## LA CABEZA: plana, con el corte arriba del frente (la de siempre), o EN RAMPA: el frente más bajo y el techo de vidrio
## que sube desde él hasta donde termina el vidrio de los costados; de ahí hacia atrás, el techo de metal, alto (el
## usuario, 15/11/2026, de la maqueta de los chanfles, la cabeza 2: «me gusta la segunda… como una opción más, no como
## reemplazo»). Cada una muestra sus perillas en el F2.
@export_enum("plana con el corte", "en rampa") var head := 0
## EL CORTE de las cuatro esquinas, de cada lado de la esquina, por dentro, en celdas chicas (18: 71 cm;
## 0, sin corte: los kits pasan a la pared de atrás).
@export_range(0, 40, 1) var corner_cells := 18
## LA PELVIS DE ABAJO, una placa chata con la misma planta, debajo del piso; de abajo de ella salen las
## piernas. Su alto, en celdas chicas (25: 98 cm; 0, sin). Para maquetar rápido: la pelvis de ahora se va a borrar (el
## usuario, 15/11/2026: «una segunda pelvis… un cubo como lo de arriba, pero más chato y con los mismos chamfers… recién
## a partir de abajo… van a salir las piernas»).
@export_range(0, 60, 1) var base_cells := 25
## Una celda de la trama, en celdas chicas de 3,9 cm (13: 51 cm).
@export_range(8, 20, 1) var cell := 13
## Cuántas celdas de trama por lado (la planta es cuadrada; siempre par; los tres puestos de adelante piden 12).
@export_range(12, 20, 2) var across := 12
## El alto libre, del piso al techo, en celdas chicas (96: 3,78 m).
@export_range(55, 140, 1) var height_cells := 96
## EN RAMPA: el alto libre del frente, la parte de vidrio rebajada, en celdas chicas (73: 2,88 m). El de atrás, el de
## metal, es `height_cells`. No pasa del de atrás.
@export_range(40, 140, 1) var front_height_cells := 73
## El radio del hueco del ascensor, en celdas chicas de 3,9 cm (26: 1,02 m; va al medio del piso, sin pasarse de las sillas de adelante). *Hasta el
## 15/11/2026 iba en celdas de trama (`lift_cells`, de 1 a 3): de a 51 cm, muy grueso (el usuario: «¿por qué no puedo
## controlarlo mediante celdas?»).*
@export_range(4, 60, 1) var lift_radius := 26
@export_group("El vidrio")
## El corte de la arista de arriba del frente, en celdas de trama.
@export_range(0, 4, 1) var chamfer := 2
## Hasta dónde llega el vidrio de los costados, desde el frente, en celdas de trama (6: la mitad).
@export_range(0, 18, 1) var side_glass := 6
## Hasta dónde llega el vidrio del techo, desde el frente, en celdas de trama (lo mismo que el corte: sólo el corte).
@export_range(0, 20, 1) var roof_glass := 2
## EL ZÓCALO: chapa llena abajo del vidrio, del frente y de los costados, en celdas chicas (0: el vidrio llega al piso).
## El usuario, 15/11/2026: «que la base del vidrio tenga como un marco lleno también… subirlo o bajarlo».
@export_range(0, 40, 1) var sill_cells := 0
## El color del vidrio y cuánto se ve (0, nada; 1, opaco).
@export var glass_color := Color(0.6, 0.8, 0.92)
@export_range(0.02, 0.9, 0.01) var glass_opacity := 0.12
## EL MARCO DEL VIDRIO: nada, sólo las aristas (todo borde de un paño, también donde se junta con la chapa), o las
## aristas y los parantes entre puestos. El grosor de cada uno, aparte (m).
@export_enum("sin nada", "sólo las aristas", "aristas y parantes entre puestos") var frame_kind := 1
@export_range(0.03, 0.3, 0.01) var edge_thickness := 0.12
@export_range(0.03, 0.3, 0.01) var post_thickness := 0.08
@export_group("Las sillas")
## La altura que buscan igualar las sillas: la de los ojos del que se sienta, sobre el piso (m).
@export_range(0.9, 1.6, 0.01) var eye_height := 1.15
## DÓNDE VAN LAS TRES DE ADELANTE, en celdas chicas (ver CabinGrid.front_seats; el usuario, 15/11/2026: «qué tan alejada
## está la izquierda y derecha de la del medio, y qué tan offseteada para atrás… así yo lo tuiqueo a mano»): la del
## medio, del vidrio (16: 63 cm); y los brazos, de ella a cada costado (48: 1,89 m), en la misma línea. *Hasta el
## 15/11/2026 los brazos podían ir más atrás (`seat_back_cells`); con tres pasajeros, van en línea.*
@export_range(8, 60, 1) var seat_front_cells := 16
@export_range(15, 90, 1) var seat_spread_cells := 48
@export_group("Brazos y piernas")
@export_enum("chico", "mediano", "grande") var arm_length := 1
@export_enum("chico", "mediano", "grande") var leg_length := 1
## El grosor de brazos y piernas (y articulaciones, manos, pies y pelvis), uno solo para los dos.
@export_enum("chico", "mediano", "grande") var thickness := 1
## Cuánto se estiran las piernas paradas: la distancia de la cadera al tobillo, en partes del largo de la pierna.
@export_range(0.45, 0.9, 0.01) var leg_stretch := 0.64
## CUÁNTO SALEN LOS HOMBROS del costado de la caja (m, con el grosor de mediano; más con brazos más anchos). Con poco,
## la bola del hombro se mete en la cabina y tapa lo de las paredes (el usuario, 15/11/2026: «qué tanto se offsetean…
## los hombros… del torso… la bola esa clipea por sobre las paredes»).
@export_range(0.0, 3.0, 0.05) var shoulder_out := 1.0
