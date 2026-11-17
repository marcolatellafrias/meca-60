class_name CageBoards
extends RefCounted

## LOS TABLEROS DE LA MECA JAULA (17/11/2026, el usuario: «está bien ahora el sistema… lo pases a la meca»; se probó
## antes aparte, en la fila «Caras con tablero»): en cada cara que puede llevar tablero —las de la cápsula y las del
## bloque de arriba (CageCabin.capsule_boards, CageCabin.upper_boards)— su grilla (FaceBoard), y en algunas, piezas de
## verdad de character-parametric en celdas sueltas, cada una sobre su base (FaceMount). POR AHORA, PALANCAS Y BOTONES
## (el usuario: «me quedaría con palancas y botones por ahora»; «varios tamaños discretos de componentes… por ahora
## están bien dejarlos así, pero en un futuro los voy a querer cambiar para pulirlos más»). Todavía no manejan nada.
##
## LOS BRAZOS PLEGABLES (FoldingArm; el usuario, 17/11/2026: «vamos con la versión más simple… el toggle y posición
## inicial, posición plegada»): uno en cada costado del cinturón, ADELANTE (`ARM_FROM_FRONT` celdas de la punta de
## adelante, `ARM_ROW` filas de arriba), con el mando de palo. Plegados contra su cara; con el clic derecho mantenido se
## traen a la mano (`HAND`, desde los ojos del que maneja, en partes del radio de 0,75 m de la maqueta) y la mirada se va
## adelante, a la cúpula (`LOOK_AHEAD`).
const ARM_FROM_FRONT := 2
const ARM_ROW := 6
const HAND := Vector3(0.3, -0.42, -0.42)
const LOOK_AHEAD := 3.0

## LA GRILLA PINTADA se ve sólo si se pide (`show_grid`, la L de su fila del sandbox): es para ubicar, no de la meca.
## *Hasta el 17/11/2026 la cabina tenía controles de mentira (sólo se veían) en las caras del cinturón y en tres del
## tablero de arriba, y los mandos de palo plegable del que maneja con sus pantallitas: no iban en la grilla y vuelven
## como brazos de dos articulaciones.*

## Lo que va en cada cara: su nombre (FaceBoard.name) y las piezas (ver `piece`), lo más al medio que entren, con una
## celda de aire entre ellas. ARRIBA, SÓLO LO QUE NO SOBRESALE (el usuario, 16/11/2026: «arriba debería haber cosas que
## no sobresalgan solamente»): en las caras de arriba de la cápsula, botones; las palancas, en los costados.
const LAYOUT := [
	["cápsula derecha", ["brazo", "palanca", "palanca", "botón", "botón", "botón", "encendido"]],
	["cápsula izquierda", ["brazo", "palanca", "botón", "botón", "botón", "botón"]],
	["cápsula derecha arriba", ["botón", "botón", "botón", "botón", "encendido"]],
	["cápsula izquierda arriba", ["botón", "botón", "botón"]],
	["tablero adelante", ["palanca mediana", "botón", "botón"]],
	["tablero adelante derecha", ["palanca mediana", "botón", "botón"]],
	["tablero adelante izquierda", ["encendido", "botón", "botón"]],
	["tablero derecha", ["botón", "botón", "botón"]],
	["tablero izquierda", ["botón", "botón", "botón", "botón"]],
]
## Lo que marca una grilla pintada (para mostrarlas y esconderlas todas).
const GRID := &"grilla_de_tablero"

## Si se ven las grillas pintadas: las de ahora y las que se armen.
static var show_grid := false


## LA GRILLA Y LAS PIEZAS en `root` (el fondo de la caja de la cabina, CageCabin.board_root) de la forma `form`.
## Los de arriba (el tablero y el pozo) cuelgan de `upper_root` (el módulo de arriba, que puede girar: ver
## CageCabin.upper), en el mismo espacio que `root`.
static func dress(root: Node3D, form: CageShape, upper_root: Node3D = null) -> void:
	var wanted := {}
	for entry: Array in LAYOUT:
		wanted[entry[0]] = entry[1]
	var top := upper_root if upper_root != null else root
	var faces: Array = []
	for board: FaceBoard in CageCabin.capsule_boards(form):
		faces.append([board, root])
	for board: FaceBoard in CageCabin.upper_boards(form):
		faces.append([board, top])
	for pair: Array in faces:
		var board: FaceBoard = pair[0]
		var holder: Node3D = pair[1]
		if board.size.x <= 0 or board.size.y <= 0:
			continue
		var grid := board.view()
		grid.visible = show_grid
		grid.set_meta(GRID, true)
		holder.add_child(grid)
		if not wanted.has(board.name):
			continue
		var mount := FaceMount.of(board)
		holder.add_child(mount)
		for key: String in wanted[board.name]:
			if key == "brazo":
				_arm(root, form, mount)
				continue
			var made := piece(key)
			var at := _spot(mount, made)
			if at.x < 0:
				push_warning("[Tableros de la jaula] «%s» no entra en la cara «%s»." % [key, board.name])
				continue
			mount.place(made, at)


## EL BRAZO PLEGABLE de la cara de `mount`: adelante, y traído a la mano de su lado.
static func _arm(root: Node3D, form: CageShape, mount: FaceMount) -> void:
	var board := mount.board
	var side := signf(-board.frame.basis.z.x)
	var made := FoldingArmArchetype.new(side)
	# La columna de adelante: la grilla crece hacia +x de la cara; si eso es hacia atrás (+z), adelante es la 0.
	var forward_first := board.frame.basis.x.z > 0.0
	var column := ARM_FROM_FRONT if forward_first else board.size.x - ARM_FROM_FRONT - FoldingArmArchetype.CELLS.x
	var placed := mount.place(made, Vector2i(column, ARM_ROW))
	if placed == null:
		return
	var arm := FoldingArmArchetype.arm_of(placed)
	var eye := CageCabin.driver_eye(form)
	var k := form.capsule_radius() / 0.75
	arm.reach_to(eye + Vector3(HAND.x * side, HAND.y, HAND.z) * k, eye + Vector3.FORWARD * LOOK_AHEAD, root)


## Muestra o esconde las grillas pintadas de todas las jaulas de `tree`.
static func set_grid_visible(tree: SceneTree, on: bool) -> void:
	show_grid = on
	for cabin in tree.root.find_children("*", "CageCabin", true, false):
		for grid in (cabin as CageCabin).board_root().find_children("*", "MeshInstance3D", true, false):
			if grid.has_meta(GRID):
				(grid as Node3D).visible = on


## LA PIEZA `key`: las palancas de LeverArchetype (la grande, 5 × 12; la mediana, 4 × 8) y los botones de ButtonArchetype
## (el de siempre, 2 × 2; el de encendido, 4 × 4, que se traba).
static func piece(key: String) -> PanelArchetype:
	match key:
		"palanca":
			return LeverArchetype.new(LeverArchetype.Size.LARGE)
		"palanca mediana":
			return LeverArchetype.new(LeverArchetype.Size.MEDIUM)
		"encendido":
			return ButtonArchetype.power()
	return ButtonArchetype.for_control("button", Color(0.85, 0.35, 0.25))


## Donde entra `made` lo más al medio posible, con una celda de aire alrededor de lo que ya hay; (−1, −1) si no entra.
static func _spot(mount: FaceMount, made: PanelArchetype) -> Vector2i:
	var cells := made.cells(0)
	var board := mount.board
	var best := Vector2i(-1, -1)
	var best_far := INF
	var center := Vector2(board.size) * 0.5
	for column in board.size.x - cells.x + 1:
		for row in board.size.y - cells.y + 1:
			var at := Vector2i(column, row)
			if not mount.can_place(made, at) or _crowded(mount, at, cells):
				continue
			var far := (Vector2(at) + Vector2(cells) * 0.5 - center).length()
			if far < best_far:
				best = at
				best_far = far
	return best


## Si alrededor de `at` (una celda de aire) ya hay otra pieza.
static func _crowded(mount: FaceMount, at: Vector2i, cells: Vector2i) -> bool:
	for column in range(at.x - 1, at.x + cells.x + 1):
		for row in range(at.y - 1, at.y + cells.y + 1):
			if mount.is_taken(Vector2i(column, row)):
				return true
	return false
