class_name CageShape
extends Resource

## LA FORMA DE LA MECA JAULA QUE SE GUARDA (ver CageCabin, el F2 de su fila: CageShapePanel). Pocas perillas y todo lo
## demás sale de ellas (16/11/2026, el usuario: «controlar el tamaño de la meca y de los módulos sin tener tantos
## sliders»). Los valores de arranque son los de la maqueta 166 de tests/cage_ideas_look («buscar inspiración ahí para
## setear los tamaños»):
##   · ABAJO, LA CAJA DEL QUE MANEJA CON LA BURBUJA AL FRENTE: la burbuja es una ventana (su radio y cuánto sobresale de
##     la cara); el que maneja va sentado adentro de la caja, en la silla de siempre, y lo opaco de los costados le
##     queda a mano. El ancho (y el fondo, y el lado del módulo de arriba) es 2 × (radio + padding); el alto, piso +
##     burbuja + techo. Los hombros, en el centro de cada costado sin el piso ni el techo: a la altura del vidrio.
##   · LA CÁMARA DEL QUE MANEJA, en el centro de su cápsula.
##   · ARRIBA, EL BLOQUE LLENO CON EL POZO (DeskPit): el radio del octógono, la inclinación del tablero y los ojos del de
##     los brazos sobre su piso.
##   · ATRÁS, LA TORRE DEL ARTILLERO, siempre contra el borde de atrás: redonda o cuadrada, su ancho y su fondo (nunca
##     más hondo que ancho) y los ojos del artillero sobre el piso de arriba. Si es más grande de lo que deja el
##     octógono, se mete en el pozo: se ve.
## *Hasta el 16/11/2026 la burbuja era una esfera donde iba la persona entera, y su radio salía del cuerpo (1,45 m
## sentado derecho; 0,85 a 1,00 recostado).*

const SAVED := "res://game/mech/cage/cage_shape.tres"
static var current := CageShape.saved()

@export_group("La cápsula de abajo")
## LA CÁPSULA FACETADA del que maneja (ver CageCabin._capsule): del centro (los ojos) a sus caras (m).
@export_range(0.5, 1.5, 0.01) var bubble_radius := 0.75
## EL VIDRIO, liso (normales de esfera) o facetado.
@export var glass_smooth := true
## LO QUE TIÑE EL VIDRIO (verdoso; ver cage_glass.gdshader), con degradé (el usuario: «vamos con la 2»): claro adelante
## (`glass_clear`) y teñido hacia los bordes de la cápsula (`glass_tint`); `glass_spread`, cuánto ocupa lo claro. Y lo
## que se notan sus manchas pixeladas, y el tamaño de sus cuadraditos (m).
@export_range(0.0, 0.6, 0.01) var glass_clear := 0.04
@export_range(0.0, 0.8, 0.01) var glass_tint := 0.45
@export_range(0.05, 2.0, 0.01) var glass_spread := 0.8
@export_range(0.0, 0.6, 0.01) var glass_smudges := 0.3
@export_range(0.01, 0.15, 0.005) var glass_pixel := 0.035
## El espacio entre la burbuja y los costados (m).
@export_range(0.05, 1.5, 0.01) var padding := 0.35
## El grosor del piso, debajo de la burbuja (m).
@export_range(0.05, 1.5, 0.01) var floor_thick := 0.25
## EL MARGEN EXTRA: cuánto baja el piso de la cabina por debajo de la burbuja, dentro del piso (m; nunca más que el
## piso). No cambia el módulo: baja al que va sentado (el usuario, 16/11/2026: «aprovechar el padding de abajo del
## piso… para bajar la silla»).
@export_range(0.0, 1.5, 0.01) var floor_gap := 0.25
## LA ALTURA DE LA SILLA: la pelvis sobre el piso de la cabina (m), la misma para todos. Con un tope por abajo para
## cada uno: el largo de su canilla hasta la suela, así los pies no atraviesan el piso (ver BubbleSeat).
@export_range(0.2, 1.2, 0.01) var seat_height := 0.42
## El grosor del techo, encima de la burbuja (m): sobre él va el módulo de arriba.
@export_range(0.05, 1.5, 0.01) var ceiling_thick := 0.25
## EL MARCO DE LA BURBUJA (el de la maqueta 166): un anillo sobre la cara, centrado en el borde del vidrio; su ancho y
## cuánto sobresale de la cara (m). Con ancho 0, no hay marco.
@export_range(0.0, 0.4, 0.005) var rim_width := 0.09
@export_range(0.0, 0.3, 0.005) var rim_depth := 0.05
@export_group("El tablero de arriba")
## El apotema del pozo octogonal (m), del centro a la pared de adentro.
@export_range(0.4, 1.5, 0.01) var pit_radius := 0.6
## La inclinación de las caras del tablero (° sobre la horizontal).
@export_range(15.0, 80.0, 1.0) var desk_tilt := 45.0
## Los ojos del de los brazos, sobre el piso de arriba (m).
@export_range(1.0, 1.9, 0.01) var arms_eye := 1.38
@export_group("La torre")
## Redonda; si no, cuadrada.
@export var tower_round := false
## Su ancho y su fondo (m); el fondo nunca pasa del ancho.
@export_range(0.3, 2.5, 0.01) var tower_width := 1.2
@export_range(0.2, 2.5, 0.01) var tower_depth := 0.56
## Los ojos del artillero, sobre el piso de arriba (m): la torre llega a esa altura menos lo de uno sentado.
@export_range(1.6, 4.0, 0.01) var gunner_eye := 2.75
## LOS CAMPOS DEL CUERPO (los de la pestaña «Brazos y piernas» de la meca grande, borrada el 17/11/2026; ver
## MechBody.from_shape), y el cuerpo que sale de ellos, achicado al 30 % (CageCabin.body).
@export_group("Brazos y piernas")
@export_enum("chico", "mediano", "grande") var arm_length := 1
@export_enum("chico", "mediano", "grande") var leg_length := 1
## El grosor de brazos y piernas (y articulaciones, manos, pies y pelvis), uno solo para los dos.
@export_enum("chico", "mediano", "grande") var thickness := 1
## Cuánto se estiran las piernas paradas: la distancia de la cadera al tobillo, en partes del largo de la pierna.
@export_range(0.45, 0.98, 0.01) var leg_stretch := 0.64
## Cuánto salen los hombros del costado (m de la meca grande, con el grosor de mediano; se achica con el cuerpo).
@export_range(0.0, 3.0, 0.05) var shoulder_out := 0.0
## Cuánto se adelantan los hombros (ver CageCabin.shoulder): 0, al medio del costado; 1, lo más adelante sin salirse de
## la caja.
@export_range(0.0, 1.0, 0.01) var shoulder_forward := 0.0


static func saved() -> CageShape:
	if ResourceLoader.exists(SAVED):
		return KnobsFile.load_into(CageShape.new(), SAVED) as CageShape
	return CageShape.new()


## ── MEDIDA EN CELDAS DE TABLERO (17/11/2026, el usuario: «las grillas no están coincidiendo»; ver FaceBoard) ─────────
## Como el casco de la nave de character-parametric, lo que lleva tableros se mide en celdas enteras (4 cm,
## ProceduralDashboard.CELL): así la grilla de una cara sigue en la de al lado. Las perillas siguen en metros; lo que
## se arma es lo más cercano que da celdas enteras.

## EL RADIO DE LA CÁPSULA QUE SE ARMA: el de la perilla (`bubble_radius`), corrido para que la arista de cada cara
## cuadrada —2r / (1 + √2)— sea de celdas enteras (de a 4,8 cm de radio).
func capsule_radius() -> float:
	var cell := ProceduralDashboard.CELL
	var edge := maxf(roundf(2.0 * bubble_radius / (1.0 + sqrt(2.0)) / cell), 1.0)
	return edge * cell * (1.0 + sqrt(2.0)) * 0.5


## EL APOTEMA DEL POZO QUE SE ARMA: el de la perilla (`pit_radius`), corrido para que el lado de adentro del octógono
## —2a · tan(22,5°)— sea de celdas enteras.
func pit_apothem() -> float:
	var cell := ProceduralDashboard.CELL
	var edge := maxf(roundf(2.0 * pit_radius * tan(PI / 8.0) / cell), 1.0)
	return edge * cell / (2.0 * tan(PI / 8.0))


## El lado del módulo de abajo (y del de arriba), de ancho y de fondo.
func side() -> float:
	return 2.0 * (capsule_radius() + padding)


## El alto del módulo de abajo: piso, burbuja y techo (el usuario: «el grosor del piso y el techo del módulo de abajo…
## dos perillas independientes»).
func height() -> float:
	return floor_thick + 2.0 * capsule_radius() + ceiling_thick


## El piso de la cabina, desde el fondo: debajo de la burbuja lo que diga el margen extra.
func cabin_floor() -> float:
	return maxf(floor_thick - floor_gap, 0.0)


## La altura del centro del vidrio, desde el fondo.
func bubble_y() -> float:
	return floor_thick + capsule_radius()


## El fondo de la torre: nunca más que su ancho.
func tower_deep() -> float:
	return minf(tower_depth, tower_width)
