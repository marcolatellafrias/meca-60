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
##   · DOS TORSOS (`torso`, 17/11/2026, el usuario: «dos torsos distintos para la meca y que yo pueda irlos cambiando en
##     base a mis necesidades»): LA CUADRADA, la caja de siempre (el padding, el piso y el techo); y LA REDONDA, un cuerpo
##     de cubo chanfleado que es el pegamento entre la cápsula y el módulo de arriba («el cuerpo es como la glue…
##     podés aumentar su tamaño para que los otros módulos encajen bien»): su talle (`body_size`, de la cápsula con su
##     marco al octógono de arriba) y su chanfle (`body_chamfer`). Arriba, en la redonda, el pozo va en un octógono
##     (`octagon_apothem`) que más adelante puede girar aparte. Todo lo demás (la cápsula, el pozo, la torre, los
##     tableros, los brazos y las piernas) es lo mismo en las dos; las medidas del cuerpo (`side`, `height`,
##     `bubble_y`, `side_face_half`) las da cada torso.
## *Hasta el 16/11/2026 la burbuja era una esfera donde iba la persona entera, y su radio salía del cuerpo (1,45 m
## sentado derecho; 0,85 a 1,00 recostado).*

const SAVED := "res://game/mech/cage/cage_shape.tres"
static var current := CageShape.saved()
## PARA CUÁNTOS JUGADORES (18/11/2026, el usuario: «haría la variante de 2 y 1… si yo quiero probar la meca de a 1»; el
## diseño, en docs/conceptual/la-meca.md): 0, 1 o 2, para 1, 2 o 3 jugadores (el número, `players`). De 3, todo; de 2, sin
## la torre del artillero; de 1, sólo la cápsula de abajo, sin el bloque de arriba ni la torre (se maneja con el modo
## manejo, ver CageBoards). NO SE GUARDA: es para probar, y lo cambia la P del panel chico en la parcela de la meca jaula
## (CageMechArchetype.keys); cada vez que arranca, la de 3. *Hasta el 18/11/2026 era una perilla guardada del F2.*
static var crew := 2

@export_group("El cuerpo")
## EL TORSO: la cuadrada (la caja) o la redonda (el cubo chanfleado).
@export_enum("cuadrada", "redonda") var torso := 0
## LA REDONDA: EL TALLE DEL CUERPO, de 0 (su cara de adelante, justo la cápsula con su marco) a 1 (su cara de arriba,
## justo el octógono de arriba); más de 1, más grande.
@export_range(0.0, 1.5, 0.01) var body_size := 1.0
## LA REDONDA: EL CHANFLE, de 0 (parejo: el rombicuboctaedro, como la cápsula) a 1 (el cubo, sin chanfle). Las caras de
## adelante y de arriba quedan del mismo tamaño: el talle no cambia lo que encaja.
@export_range(0.0, 0.95, 0.01) var body_chamfer := 0.0
## LA REDONDA: SI EL OCTÓGONO DE ARRIBA GIRA APARTE DEL TORSO (17/11/2026, el usuario: «le daría la habilidad de girar
## aparte, y que pueda togglearla o no… solamente en la variante esférica»). Hacia dónde mira mientras tanto, lo dice
## CageMech.upper_heading (hoy, hacia donde apuntan las piernas: el usuario lo va a decidir jugando).
@export var upper_turns := false
## LA CUADRADA: el espacio entre la burbuja y los costados (m).
@export_range(0.05, 1.5, 0.01) var padding := 0.35
## LA CUADRADA: el grosor del piso, debajo de la burbuja (m).
@export_range(0.05, 1.5, 0.01) var floor_thick := 0.25
## LA CUADRADA: el grosor del techo, encima de la burbuja (m): sobre él va el módulo de arriba.
@export_range(0.05, 1.5, 0.01) var ceiling_thick := 0.25
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
## EL MARGEN EXTRA: cuánto baja el piso de la cabina por debajo de la burbuja (m; en la cuadrada, nunca más que el
## piso). No cambia el módulo: baja al que va sentado (el usuario, 16/11/2026: «aprovechar el padding de abajo del
## piso… para bajar la silla»).
@export_range(0.0, 1.5, 0.01) var floor_gap := 0.25
## LA ALTURA DE LA SILLA: la pelvis sobre el piso de la cabina (m), la misma para todos. Con un tope por abajo para
## cada uno: el largo de su canilla hasta la suela, así los pies no atraviesan el piso (ver BubbleSeat).
@export_range(0.2, 1.2, 0.01) var seat_height := 0.42
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
## SU TAMAÑO (m): el ancho y el fondo, que son el mismo —la base es siempre cuadrada (o un círculo); el usuario,
## 18/11/2026: «la base de la torre ahora puede no tener cross section cuadrada, cosa que quiero que sea imposible, con
## un solo valor… tamaño debería controlar eso»—. *Hasta ese día eran dos: el ancho y el fondo.*
@export_range(0.5, 1.5, 0.01) var tower_size := 0.8
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
## Cuánto se adelantan los hombros (ver CageCabin.shoulder): 0, al medio de la cara del costado; 1, lo más adelante sin
## salirse de ella. La misma regla en los dos torsos.
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


## ── LAS MEDIDAS DEL CUERPO, LAS DE CADA TORSO ──────────────────────────────────────────────────────────────────────

func is_round() -> bool:
	return torso == 1


## Para cuántos jugadores es (ver `crew`): 1, 2 o 3.
func players() -> int:
	return crew + 1


## El lado del cuerpo, de ancho y de fondo (en la cuadrada, también el del módulo de arriba).
func side() -> float:
	if is_round():
		return 2.0 * body_half()
	return 2.0 * (capsule_radius() + padding)


## El alto del cuerpo; arriba de él va el piso del módulo de arriba. La cuadrada: piso, burbuja y techo (el usuario: «el
## grosor del piso y el techo del módulo de abajo… dos perillas independientes»); la redonda, su cubo.
func height() -> float:
	if is_round():
		return 2.0 * body_half()
	return floor_thick + 2.0 * capsule_radius() + ceiling_thick


## La altura del centro del vidrio, desde el fondo: en la redonda, el centro del cuerpo.
func bubble_y() -> float:
	if is_round():
		return body_half()
	return floor_thick + capsule_radius()


## El piso de la cabina, desde el fondo: debajo de la burbuja lo que diga el margen extra.
func cabin_floor() -> float:
	return maxf(bubble_y() - capsule_radius() - floor_gap, 0.0)


## LA MITAD DEL ANCHO DE LA CARA DEL COSTADO, donde va el hombro (ver CageCabin.shoulder): en la cuadrada, la del cubo;
## en la redonda, la del cuadrado del costado del cubo chanfleado.
func side_face_half() -> float:
	if is_round():
		return body_half() * _chamfer_share()
	return side() * 0.5


## ── LA REDONDA ─────────────────────────────────────────────────────────────────────────────────────────────────────

## La cápsula con su marco, de mitad: hasta el borde de afuera del marco (CageMesh.outline_ring lo corre hacia afuera
## por las puntas del octógono).
func framed_capsule() -> float:
	return capsule_radius() + rim_width * cos(PI / 8.0)


## LO QUE EL OCTÓGONO DE ARRIBA TIENE DE PARED alrededor del tablero del pozo (m).
const OCTAGON_WALL := 0.15


## EL APOTEMA DEL OCTÓGONO DE ARRIBA de la redonda: el borde del tablero del pozo (DeskPit.rim) y su pared.
func octagon_apothem() -> float:
	return pit_apothem() + DeskPit.DEPTH * cos(deg_to_rad(desk_tilt)) + OCTAGON_WALL


## La mitad de la cara de adelante (y de arriba) en partes de la mitad del cuerpo: donde la corta el chanfle de la arista.
func _chamfer_share() -> float:
	return sqrt(2.0) * lerpf(1.0, sqrt(2.0), body_chamfer) - 1.0


## LA MITAD DEL CUERPO REDONDO: la que hace que su cara mida, de mitad, lo de la cápsula con su marco (talle 0) o lo del
## octógono (talle 1).
func body_half() -> float:
	return lerpf(framed_capsule(), octagon_apothem(), body_size) / _chamfer_share()


## CUÁNTO SE HUNDE EL OCTÓGONO EN EL CUERPO, debajo de su cara de arriba: nada si entra en ella; si es más ancho, lo
## que hace falta para que el cuerpo lo cubra (el chanfle de la arista lo abraza).
func octagon_sink() -> float:
	if not is_round():
		return 0.0
	var half := body_half()
	var edge := half * sqrt(2.0) * lerpf(1.0, sqrt(2.0), body_chamfer)
	return maxf(half - (edge - octagon_apothem()), 0.0)


## EL BORDE DE ATRÁS DEL MÓDULO DE ARRIBA, desde el centro (la torre va contra él): el de la caja o el del octógono.
func upper_back() -> float:
	return octagon_apothem() if is_round() else side() * 0.5


## El ancho y el fondo de la torre: los dos, su tamaño.
func tower_wide() -> float:
	return tower_size


func tower_deep() -> float:
	return tower_size
