class_name FaceBoard
extends RefCounted

## UNA CARA QUE PUEDE LLEVAR TABLERO, CON SU GRILLA (17/11/2026, el usuario: «poner la grilla en las caras no
## triangulares de los cubos chanfleados o del hexágono de arriba… las caras que llevan grilla son todas las que pueden
## llegar a tener tablero»). Una cara plana cualquiera —un cuadrado de la cápsula, un trapecio del tablero de arriba— se
## describe igual: DÓNDE ESTÁ, HACIA DÓNDE MIRA y QUÉ ES CADA CELDA. La celda es la de los tableros de
## character-parametric (ProceduralDashboard.CELL, 4 cm), para que cada componente traído mida lo mismo que allá.
##
## LA GRILLA ARRANCA EN UNA ESQUINA DE LA CARA (`anchor`), no centrada (el usuario, 17/11/2026: «las grillas no están
## coincidiendo»), como en la nave de character-parametric, que mide su casco en celdas: quien da las caras las hace de
## celdas enteras (CageShape.capsule_radius, CageShape.pit_apothem, DeskPit.DEPTH), y así la grilla de una cara sigue
## en la de al lado por la arista que comparten. Lo que no entra entero (las puntas de un trapecio, la fila de abajo de
## la pared del pozo) queda sin pintar.
##
## QUÉ ES CADA CELDA (`kind`), como en ShipBoardGrid de la nave:
##   · EL MARCO (`Kind.FRAME`, celeste): la vuelta de `MARGIN_CELLS` celdas contra el borde de la cara. No lleva piezas.
##   · LA ZONA DE PIEZAS (`Kind.MODULES`, verde): lo de adentro, donde van los controles.
##   · NADA (`Kind.NONE`): la celda que no entra entera en la cara.
## SE PINTA EN UNA SOLA TEXTURA por cara (`view`), como la nave (el usuario allá: «por textura y no por elementos… así no
## afecta tanto los FPS»): cada celda de su color, un poco transparente, con su rayita.
##
## LA CONVENCIÓN, la de los tableros (ProceduralDashboard): la grilla arranca en su esquina de arriba a la izquierda y
## crece hacia +X y −Y; la cara mira hacia +Z, a quien la usa. `frame` es esa esquina, en el espacio de quien dio los
## puntos. «Arriba» en la cara es lo que sube en el mundo; en una cara acostada (un techo), lo que va hacia el frente.
##
## Las que la usan dan su lista: la cápsula de la meca jaula (CageCabin.capsule_boards) y el bloque de arriba
## (DeskPit.boards). Las piezas se ponen en su tablero (FaceMount), cada una sobre su base.

enum Kind { NONE, FRAME, MODULES }

## La vuelta de la cara que no lleva piezas, en celdas.
const MARGIN_CELLS := 1
## Los colores de la nave (ShipBoardGrid.COLORS): el marco celeste, la zona de piezas verde.
const COLORS := {Kind.FRAME: Color(0.2, 0.7, 0.9), Kind.MODULES: Color(0.55, 0.9, 0.2)}
## Las celdas, un poco transparentes, y los píxeles de cada una en la textura (el cuadro y su rayita).
const ALPHA := 0.72
const CELL_PIXELS := 8
## Lo que la grilla pintada se despega de la cara.
const LIFT := 0.004
## Un pelito: una esquina sobre el borde cuenta como adentro, y un largo de celdas enteras no pierde la última.
const EPS := 0.0005

## Su nombre, que dice cuál es («cápsula derecha arriba», «tablero adelante»). Va en el nombre de su tablero: igual en
## todas las máquinas, para la red (ver FaceMount).
var name := ""
## La esquina de arriba a la izquierda de la grilla, sobre la cara: x a lo largo, y hacia arriba, z hacia quien la usa.
var frame := Transform3D.IDENTITY
## Columnas y filas de la grilla.
var size := Vector2i.ZERO
## Qué es cada celda: `kinds[columna][fila]` (Kind).
var kinds: Array = []


## LA CARA DE `points` (en orden, en cualquier sentido), que mira hacia `toward` (hacia quien la usa), con la grilla
## enganchada en `anchor` (una esquina de la cara: ahí cae una esquina de celda).
static func from_points(p_name: String, points: Array, toward: Vector3, anchor: Vector3) -> FaceBoard:
	var board := FaceBoard.new()
	board.name = p_name
	var z := toward.normalized()
	var up := Vector3.UP if absf(z.y) < 0.9 else Vector3.FORWARD
	var y := (up - z * up.dot(z)).normalized()
	var x := y.cross(z)
	var on := anchor - z * (anchor - (points[0] as Vector3)).dot(z)
	var flat := PackedVector2Array()
	for p: Vector3 in points:
		flat.append(Vector2((p - on).dot(x), (p - on).dot(y)))
	var low := flat[0]
	var high := flat[0]
	for q in flat:
		low = Vector2(minf(low.x, q.x), minf(low.y, q.y))
		high = Vector2(maxf(high.x, q.x), maxf(high.y, q.y))
	# La grilla son las celdas enteras del enrejado que sale de la esquina y cubren la cara.
	var cell := ProceduralDashboard.CELL
	var first := Vector2i(floori(low.x / cell + EPS), floori(low.y / cell + EPS))
	var last := Vector2i(ceili(high.x / cell - EPS), ceili(high.y / cell - EPS))
	board.size = Vector2i(maxi(last.x - first.x, 0), maxi(last.y - first.y, 0))
	var corner := Vector2(first.x * cell, last.y * cell)
	board.frame = Transform3D(Basis(x, y, z), on + x * corner.x + y * corner.y)
	var inset_list := Geometry2D.offset_polygon(flat, -MARGIN_CELLS * cell + EPS)
	var inset: PackedVector2Array = inset_list[0] if not inset_list.is_empty() else PackedVector2Array()
	for column in board.size.x:
		var cells: Array[int] = []
		for row in board.size.y:
			var kind := Kind.NONE
			if _inside(flat, corner, column, row):
				kind = Kind.MODULES if not inset.is_empty() and _inside(inset, corner, column, row) else Kind.FRAME
			cells.append(kind)
		board.kinds.append(cells)
	return board


## Si la celda (`column`, `row`) entra entera en `area` (en el espacio de la cara, con la grilla en `corner`).
static func _inside(area: PackedVector2Array, corner: Vector2, column: int, row: int) -> bool:
	var cell := ProceduralDashboard.CELL
	var left := corner.x + column * cell + EPS
	var top := corner.y - row * cell - EPS
	var span := cell - 2.0 * EPS
	for q: Vector2 in [Vector2(left, top), Vector2(left + span, top), Vector2(left, top - span),
			Vector2(left + span, top - span)]:
		if not Geometry2D.is_point_in_polygon(q, area):
			return false
	return true


## Qué es la celda `cell` (fuera de la grilla, nada).
func kind_at(cell: Vector2i) -> Kind:
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return Kind.NONE
	return kinds[cell.x][cell.y]


## Cuántas celdas de cada cosa tiene: {Kind: cantidad}.
func counts() -> Dictionary:
	var out := {Kind.NONE: 0, Kind.FRAME: 0, Kind.MODULES: 0}
	for column: Array in kinds:
		for kind: int in column:
			out[kind] += 1
	return out


## Si una pieza de `cells` celdas entra con su esquina de arriba a la izquierda en `cell`: todo en la zona de piezas.
func fits(cell: Vector2i, cells: Vector2i) -> bool:
	for column in range(cell.x, cell.x + cells.x):
		for row in range(cell.y, cell.y + cells.y):
			if kind_at(Vector2i(column, row)) != Kind.MODULES:
				return false
	return true


## LA GRILLA PINTADA, EN UNA SOLA TEXTURA (como ShipBoardGrid.paint de la nave): un cuadro del tamaño de la grilla, apenas
## sobre la cara, con `CELL_PIXELS` por celda y su rayita, cada celda del color de lo que es; lo que no entra, sin pintar.
func view() -> MeshInstance3D:
	var cell := ProceduralDashboard.CELL
	var image := Image.create(maxi(size.x, 1) * CELL_PIXELS, maxi(size.y, 1) * CELL_PIXELS, false, Image.FORMAT_RGBA8)
	for column in size.x:
		for row in size.y:
			var kind: int = kinds[column][row]
			if kind == Kind.NONE:
				continue
			var color: Color = COLORS[kind]
			var square := Rect2i(column * CELL_PIXELS, row * CELL_PIXELS, CELL_PIXELS, CELL_PIXELS)
			image.fill_rect(square, color.darkened(0.3))
			image.fill_rect(square.grow_individual(-1, -1, 0, 0), color)
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.albedo_color = Color(1.0, 1.0, 1.0, ALPHA)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var quad := QuadMesh.new()
	quad.size = Vector2(size) * cell
	var drawn := MeshInstance3D.new()
	drawn.name = "Grilla %s" % name
	drawn.mesh = quad
	drawn.material_override = material
	drawn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	drawn.transform = frame * Transform3D(Basis(), Vector3(size.x * 0.5 * cell, -size.y * 0.5 * cell, LIFT))
	return drawn


## Un nombre de dirección para `normal` (adonde mira la cara desde afuera, en el espacio de la meca: −Z adelante).
static func direction_name(normal: Vector3) -> String:
	var words := PackedStringArray()
	if normal.z < -0.3:
		words.append("adelante")
	elif normal.z > 0.3:
		words.append("atrás")
	if normal.x > 0.3:
		words.append("derecha")
	elif normal.x < -0.3:
		words.append("izquierda")
	if normal.y > 0.3:
		words.append("arriba")
	elif normal.y < -0.3:
		words.append("abajo")
	return " ".join(words) if not words.is_empty() else "medio"
