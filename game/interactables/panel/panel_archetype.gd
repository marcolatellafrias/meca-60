class_name PanelArchetype
extends SeededArchetype

## LO QUE SE MONTA EN UN TABLERO: la base común de los COMPONENTES (ComponentArchetype) y los ARTEFACTOS
## (ArtifactArchetype). Ver docs/conceptual/interactables.md, Componentes y artefactos.
##
## Todo lo que va en un tablero se mide en celdas (ProceduralDashboard.CELL), y la convención es la del
## tablero, para que lo que se arma acá entre en uno sin traducir nada: la grilla crece hacia +X y −Y desde su
## esquina de arriba a la izquierda, y la cara mira a +Z, hacia quien la usa.
##
## Dice dos cosas: CUÁNTAS CELDAS ocupa con una semilla (`cells`) y CÓMO SE ARMA en ellas (`mount`). En el
## sandbox, `build` lo pone solo en un atril.

## El atril del sandbox: alto del poste y cuánto se inclina la placa hacia arriba.
const STAND_HEIGHT := 1.05
const STAND_TILT_DEG := 30.0

## LA TINTA QUE SE LEE SOBRE EL TABLERO donde se monta (transparente, no se sabe): la pone quien la monta y sabe sobre
## qué —el reparto de una zona (ver ZoneLayout.mount): oscura sobre la elevada plateada, clara sobre las otras—. Lo
## escrito por la pieza sobre el tablero, alrededor de ella (las marcas de una perilla), la usa.
var board_ink := Color(0.0, 0.0, 0.0, 0.0)


## Cuántas celdas ocupa el individuo `seed_value` (ancho, alto).
func cells(_seed_value: int) -> Vector2i:
	return Vector2i(2, 2)


## Arma el individuo `seed_value` en el tablero `panel`, en el rectángulo de celdas que empieza en `cell`. Devuelve
## su raíz, que queda en el centro del rectángulo sobre la superficie del tablero.
func mount(seed_value: int, panel: Node3D, cell: Vector2i) -> Node3D:
	return mount_half(seed_value, panel, cell * 2)


## LO QUE OCUPA EN MEDIAS CELDAS: las celdas por dos, salvo la pieza que se ajusta a la media celda —una rampita, que
## mide lo que su texto— (ver la grilla de media celda, CellLayout). Lo usan el reparto, los cantos y `mount_half`.
func half_cells(seed_value := 0) -> Vector2i:
	return cells(seed_value) * 2


## Lo mismo, empezando en `half`, en medias celdas: lo de adentro de un artefacto va en la grilla de media celda (ver
## CellLayout).
func mount_half(seed_value: int, panel: Node3D, half: Vector2i) -> Node3D:
	var size := half_cells(seed_value)
	var root := Node3D.new()
	root.name = display_name
	var area := Vector2(size) * ProceduralDashboard.CELL * 0.5
	# Las cuentas, como las de `rect_centre`: con una celda entera sale exactamente lo mismo.
	root.position = Vector3(half.x * ProceduralDashboard.CELL * 0.5 + area.x * 0.5,
		-(half.y * ProceduralDashboard.CELL * 0.5 + area.y * 0.5), 0.0)
	panel.add_child(root)
	_build_on(seed_value, root, area)
	return root


## Lo que arma cada uno, centrado en el origen de `root` y con la cara a +Z. `area` es el rectángulo en
## metros, sin margen: cada uno deja el suyo.
func _build_on(_seed_value: int, _root: Node3D, _area: Vector2) -> void:
	pass


## El centro de un rectángulo de celdas, en el espacio del tablero (ver ProceduralDashboard._spawn).
static func rect_centre(cell: Vector2i, size: Vector2i) -> Vector3:
	var area := Vector2(size) * ProceduralDashboard.CELL
	return Vector3(cell.x * ProceduralDashboard.CELL + area.x * 0.5, -(cell.y * ProceduralDashboard.CELL + area.y * 0.5), 0.0)


# ── La muestra del sandbox ───────────────────────────────────────────────────────────────────────

func max_footprint() -> Vector2:
	return Vector2(1.0, 1.0)


## En el sandbox, solo en un atril con una celda de aire alrededor.
func build(seed_value: int, parent: Node3D) -> Node3D:
	var plate_cells := cells(seed_value) + Vector2i(2, 2)
	var root := stand(parent, plate_cells)
	var panel := Node3D.new()
	panel.name = "Panel"
	panel.transform = stand_grid(plate_cells)
	root.add_child(panel)
	mount(seed_value, panel, Vector2i(1, 1))
	return root


## UN ATRIL: una placa inclinada de `plate_cells` celdas a la altura de la mano, colgada de `parent`. Devuelve su raíz; lo
## que vaya encima se monta en `stand_grid`.
static func stand(parent: Node3D, plate_cells: Vector2i) -> Node3D:
	var root := Node3D.new()
	root.name = "Stand"
	parent.add_child(root)
	var material := StandardMaterial3D.new()
	material.albedo_color = ControlArchetype.BASE_COLOR.darkened(0.4)
	# La placa mira a -Z, como todo en el sandbox, inclinada hacia arriba.
	var plate := plate_frame()
	var plate_size := Vector2(plate_cells) * ProceduralDashboard.CELL + Vector2(0.08, 0.08)
	# Sin poste: la placa flota a la altura de la mano. El poste del medio molestaba y no aportaba nada.
	_stand_box(root, Vector3(plate_size.x, plate_size.y, 0.04), plate * Transform3D(Basis(), Vector3(0, 0, -0.02)),
		material)
	return root


## Dónde está la placa del atril, con la cara a +Z: arriba del poste, mirando a -Z e inclinada hacia arriba.
static func plate_frame() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, deg_to_rad(-STAND_TILT_DEG)),
		Vector3(0.0, STAND_HEIGHT, 0.0))


## EL TABLERO DE LA PLACA, en el espacio del atril: la grilla arranca en su esquina superior izquierda, así que va
## corrida media placa para quedar centrada.
static func stand_grid(plate_cells: Vector2i) -> Transform3D:
	return plate_frame() * Transform3D(Basis(),
		Vector3(-plate_cells.x * 0.5, plate_cells.y * 0.5, 0.0) * ProceduralDashboard.CELL)


static func _stand_box(parent: Node3D, size: Vector3, xf: Transform3D, material: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = material
	mi.transform = xf
	parent.add_child(mi)


## Una malla del cubo unitario del componente, escalada a `size` con el pivote en el centro de su cara de
## atrás —sobre el tablero—, con los colores de sus vértices.
static func instance(unit: UnitMesh, size: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = unit.build_mesh(size, ControlArchetype.ON_PANEL)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	mi.material_override = material
	return mi


## Un generador de números de la semilla, siempre el mismo para la misma semilla y el mismo componente: dos
## componentes con la misma semilla no salen iguales porque cada uno mezcla su nombre.
##
## ⚠ POR AHORA LA SEMILLA NO VARÍA NADA (`SEEDS_VARY`): cada componente y cada artefacto sale siempre igual, de un
## solo tamaño. Las variantes multiplicaban la complejidad antes de saber qué piezas valen la pena; se vuelven a
## prender acá, de a una pieza o todas, cuando se decida. Lo que cada pieza elegiría sigue escrito en su `variant`.
func rng_for(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s/%d" % [display_name, seed_value if SEEDS_VARY else 0])
	return rng


const SEEDS_VARY := false


## CAE CON LA GRAVEDAD: lo que está APOYADO y no atornillado —un libro, un mapa— y se caería de una pared vertical o de
## un voladizo que mira para abajo. Quien coloca piezas lo respeta: algo así va solo donde la cara mira lo bastante
## para arriba (ver `rests_on`). Lo demás está fijo al tablero y va en cualquier cara. Por ahora, solo el manual y el
## mapa.
var falls_with_gravity := false

## Cuánto tiene que mirar para arriba una cara, como mínimo, para que se le apoye algo que cae: el coseno de su
## ángulo con la vertical. A 45° (un atril) sí; a 80° (casi derecha), a 90° (una pared) o mirando abajo, no.
const MIN_REST_UP := 0.5


## Si esta pieza puede ir en una cara cuya normal es `face_normal` (en el mundo, o en cualquier marco con +Y arriba).
func rests_on(face_normal: Vector3) -> bool:
	return not falls_with_gravity or face_normal.normalized().y >= MIN_REST_UP


## SE VE DE FRENTE: lo que se LEE mirándolo de cara —una aguja, una pantalla de osciloscopio, un tubo, un número—, y
## de canto no dice nada. Quien coloca piezas lo respeta (ver `reads_on`): en una cara inclinada, derecha o que mira
## para abajo va siempre; EN UNA CARA PLANA QUE MIRA PARA ARRIBA, solo si queda bastante más abajo que el ojo de quien
## la usa, porque si no se la ve de canto. El escritorio de un atril sentado sirve; el estante a la altura del
## antepecho, o la tapa de algo de pie a la altura de los ojos, no.
var seen_from_front := false

## Cuánto tiene que mirar para arriba una cara para contar como plana (el coseno de su ángulo con la vertical), y cuánto
## más abajo que el ojo tiene que quedar una cara plana para que lo que se ve de frente se lea.
const FLAT_UP := 0.9
const FRONT_VIEW_DROP := 0.35


## Si esta pieza se lee en una cara de normal `face_normal`, a `height` del piso, usada con el ojo a `eye` del piso (ver
## `seen_from_front`).
func reads_on(face_normal: Vector3, height: float, eye: float) -> bool:
	if not seen_from_front or face_normal.normalized().y < FLAT_UP:
		return true
	return height <= eye - FRONT_VIEW_DROP


## ── LA REGLA DE LAS GRILLAS: CADA PIEZA VA DONDE VA SU USO ───────────────────────────────────────────────
## La decidió el usuario el 12/10/2026 —«debería ser foolproof, no se deberían poder poner cosas donde no van»—
## (ver docs/technical/ship-hull.md, The grid rule). Cada pieza dice PARA QUÉ ES (`use`) y cada tablero QUÉ LLEVA (su
## meta "use", ver ConsoleSection.board_use); quien coloca le pregunta a `board_takes`, y lo que no va ahí no entra.
##   · CONSTANT — lo que se maneja todo el tiempo: el volante, la palanca de dos ejes, el mando de helicóptero, la
##     palanca de cambios, el volante de auto.
##   · OCCASIONAL — todo lo demás que se toca: botones, palancas, perillas, manivelas, válvulas, el teléfono, los cables,
##     el mapa y el manual. Es lo que es una pieza si no dice otra cosa.
##   · INDICATOR — sólo se lee.
##   · COSMETIC — no se usa: adorna.
enum Use { CONSTANT, OCCASIONAL, INDICATOR, COSMETIC }

## QUÉ LLEVA CADA TABLERO, por su uso (ver ConsoleSection.board_use): la única definición, para todo el que coloca.
const BOARD_TAKES := {
	"constant": [Use.CONSTANT, Use.OCCASIONAL, Use.INDICATOR],
	"occasional": [Use.OCCASIONAL, Use.INDICATOR],
	"standing": [Use.OCCASIONAL, Use.INDICATOR],
	"cosmetic": [Use.COSMETIC, Use.INDICATOR, Use.OCCASIONAL],
	"indicators": [Use.INDICATOR],
}


## Para qué es esta pieza. Lo pisa quien es otra cosa que de uso ocasional.
func use() -> Use:
	return Use.OCCASIONAL


## SE MANEJA CON LAS DOS MANOS —el volante, el mando—: va centrado frente a la silla, nunca a un costado ni en una
## faceta en diagonal. Quien coloca lo pone sólo así (ver DashboardShapeArchetype._place_in_front).
func two_handed() -> bool:
	return false


## Si un tablero de uso `board_use` lleva una pieza de uso `piece_use`. Un tablero sin uso (una chapa suelta, el
## atril del sandbox) lleva cualquier cosa. *Lo plano admite también lo ocasional (lo decidió el usuario el
## 12/10/2026, por la radio comprada, que va en su lugar cosmético plano).*
static func board_takes(board_use: String, piece_use: Use) -> bool:
	return board_use.is_empty() or not BOARD_TAKES.has(board_use) or (BOARD_TAKES[board_use] as Array).has(piece_use)


## SI ESTA PIEZA VA EN UN TABLERO de uso `board_use`: su uso, y además LO QUE SE APOYA Y CAE CON LA GRAVEDAD —el mapa,
## el manual— NO VA EN LO PLANO, sino en un atril inclinado, como dice la regla de las grillas.
func goes_on(board_use: String) -> bool:
	if falls_with_gravity and board_use == "cosmetic":
		return false
	return board_takes(board_use, use())


## Uno al azar de `options`.
static func pick(rng: RandomNumberGenerator, options: Array) -> Variant:
	return options[rng.randi() % options.size()]
