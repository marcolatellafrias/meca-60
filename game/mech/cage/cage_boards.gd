class_name CageBoards
extends RefCounted

## LOS TABLEROS DE LA MECA JAULA, CON LOS CONTROLES DE VERDAD DE LA MECA PARA 3 (17/11/2026, el usuario: «empezar a
## definir con qué controles se maneja… vamos a empezar con la variante de 3»). En cada cara que puede llevar tablero
## —las de la cápsula y las del bloque de arriba (CageCabin.capsule_boards, CageCabin.upper_boards)— su grilla
## (FaceBoard), y en algunas las piezas de verdad, cada una sobre su base (FaceMount), CONECTADAS A LA MECA:
##
##   ABAJO, EN LA CÁPSULA: LOS DOS BRAZOS (y con ellos, el torso).
##   · LOS DOS MANDOS PLEGABLES (FoldingArm), uno en cada costado del cinturón, adelante. Clic derecho mantenido lo
##     agarra: se trae a la mano, la mirada va al frente con una transición y queda libre; EL TORSO PERSIGUE LA MIRADA
##     con su resorte (CageMech.steer; «el torso va a girar… a dónde apuntan inevitablemente tus dos brazos») y el clic
##     izquierdo usa ese brazo:
##       — EL CAÑÓN (el de la izquierda): el gatillo, según el modo que eligen TRES BOTONES al lado de su mando —RÁFAGA y
##         BARRIDO mientras se mantiene, SÚPER carga mientras se mantiene y tira al soltar (CannonTip).
##       — EL PUÑO (el de la derecha): cuanto más se mantiene, más lenta y más fuerte la piña (MechArm.charged_strike;
##         sus perillas, en el F7: CageHandling).
##   · DOS PANTALLAS EN BRAZOS FIJOS (ScreenArmArchetype), arriba en la vista del que maneja: la ENERGÍA de la meca y la
##     CARGA de lo que se está manteniendo («que esté al máximo… hasta que estás cargando… al máximo»).
##   ARRIBA, EN EL POZO: LA LOCOMOCIÓN (lo piden a MechCockpit, que lee la meca con las reglas de energía de siempre).
##   · LA PALANCA DE DOS EJES: hacia dónde camina. · SALTAR. · LEVITAR (en el aire). · EL DASH: ocho botones en círculo
##     (DashRingArchetype), uno por dirección. CADA DIRECCIÓN ES HACIA DÓNDE APUNTA EN LA MECA: la palanca empujada
##     hacia el frente de la meca camina adelante, el botón del círculo que queda hacia el frente tira el dash adelante
##     (se mide en el mundo y se pasa al torso: vale en cualquier cara, y aunque el módulo de arriba gire aparte).
##
## LA GRILLA PINTADA se ve sólo si se pide (`show_grid`, la L de su fila del sandbox): es para ubicar, no de la meca.
## *Hasta el 17/11/2026 había palancas y botones de prueba sin conectar en casi todas las caras, y antes, controles de
## mentira.*

## Lo que va en cada cara: su nombre (FaceBoard.name) y las piezas (ver `_place`).
const LAYOUT := [
	["cápsula izquierda", ["brazo cañón", "modo ráfaga", "modo barrido", "modo súper"]],
	["cápsula derecha", ["brazo puño"]],
	["cápsula izquierda arriba", ["pantalla energía"]],
	["cápsula derecha arriba", ["pantalla carga"]],
	["tablero adelante", ["caminar"]],
	["tablero adelante izquierda", ["saltar"]],
	["tablero adelante derecha", ["levitar"]],
	["tablero derecha", ["dash"]],
]
## LOS MANDOS PLEGABLES Y LAS PANTALLAS van ADELANTE en su cara (`FRONT` celdas de la punta de adelante, en la fila
## `ROW` de arriba). El mando, traído a la mano (`HAND`); las pantallas, arriba a los costados de la vista (`SCREEN_AT`),
## las dos desde los ojos del que maneja, en partes del radio de 0,75 m de la maqueta; la mirada, al frente, a la cúpula
## (`LOOK_AHEAD`).
const FRONT := 2
const ROW := 6
const HAND := Vector3(0.3, -0.42, -0.42)
const SCREEN_AT := Vector3(0.3, 0.13, -0.5)
const LOOK_AHEAD := 3.0
## Los modos del cañón que eligen sus botones: su nombre y su color.
const MODES := {"modo ráfaga": [CannonTip.Mode.BURST, "RÁFAGA", Color(0.9, 0.62, 0.2)],
	"modo barrido": [CannonTip.Mode.BEAM, "BARRIDO", Color(0.35, 0.7, 0.95)],
	"modo súper": [CannonTip.Mode.SUPER, "SÚPER", Color(0.85, 0.3, 0.25)]}
## Lo que marca una grilla pintada (para mostrarlas y esconderlas todas).
const GRID := &"grilla_de_tablero"
## Lo que marca cada pieza puesta: su nombre en `LAYOUT` (para encontrarla: `piece_of`).
const PIECE := &"pieza_de_tablero"

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
	# Lo que se mantiene apretado (la piña), para la pantalla de la carga.
	var held := {"punch_from": -1.0}
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
			_place(key, mount, root, form, held)


## PONE Y CONECTA LA PIEZA `key` en el tablero `mount`.
static func _place(key: String, mount: FaceMount, root: Node3D, form: CageShape, held: Dictionary) -> void:
	var board := mount.board
	var side := signf(-board.frame.basis.z.x)
	var eye := CageCabin.driver_eye(form)
	var k := form.capsule_radius() / 0.75
	match key:
		"brazo cañón", "brazo puño":
			var placed := mount.place(FoldingArmArchetype.new(side), _front(board, FoldingArmArchetype.CELLS))
			if placed == null:
				return
			placed.set_meta(PIECE, key)
			var arm := FoldingArmArchetype.arm_of(placed)
			arm.reach_to(eye + Vector3(HAND.x * side, HAND.y, HAND.z) * k, eye + Vector3.FORWARD * LOOK_AHEAD, root)
			arm.steer = func(world_yaw: float, world_pitch: float) -> void:
				var mech := _mech_of(arm)
				if mech != null:
					mech.steer(world_yaw, world_pitch)
			if key == "brazo cañón":
				arm.use = func(pressed: bool) -> void:
					var cockpit := _cockpit_of(arm)
					if cockpit != null:
						cockpit.fire = pressed
			else:
				arm.use = func(pressed: bool) -> void:
					_punch(_mech_of(arm), pressed, held)
		"pantalla energía", "pantalla carga":
			var energy := key == "pantalla energía"
			var look := ScreenArmArchetype.new("ENERGÍA" if energy else "CARGA",
				Color(0.4, 0.9, 0.5) if energy else Color(0.95, 0.75, 0.25))
			var placed := mount.place(look, _front(board, ScreenArmArchetype.CELLS))
			if placed == null:
				return
			placed.set_meta(PIECE, key)
			var screen := ScreenArmArchetype.screen_of(placed)
			screen.reach_to(eye + Vector3(SCREEN_AT.x * side, SCREEN_AT.y, SCREEN_AT.z) * k, eye, root)
			if energy:
				screen.source = func() -> float:
					var mech := _mech_of(screen)
					return mech.energy.level if mech != null and mech.energy != null else 0.0
			else:
				screen.source = func() -> float: return _charge(_mech_of(screen), held)
		"modo ráfaga", "modo barrido", "modo súper":
			var mode: Array = MODES[key]
			var look := ButtonArchetype.new()
			look.form = ButtonArchetype.Form.RECT
			look.button_cells = Vector2i(5, 2)
			look.color = mode[2]
			look.text = mode[1]
			look.head_size = 0.8
			var placed := _behind_arm(mount, look, MODES.keys().find(key))
			if placed == null:
				return
			placed.set_meta(PIECE, key)
			var button := ButtonArchetype.button_of(placed)
			button.pressed.connect(func() -> void:
				var mech := _mech_of(button)
				if mech != null and mech.cannon != null:
					mech.cannon.mode = mode[0]
					mech.cannon.charge = 0.0)
		"caminar":
			var placed := _spotted(mount, ControlArchetype.of("stick"))
			if placed == null:
				return
			placed.set_meta(PIECE, key)
			for found in placed.find_children("*", "TwoAxisComponent", true, false):
				var stick := found as TwoAxisComponent
				stick.state_changed_2d.connect(func(value: Vector2) -> void:
					var cockpit := _cockpit_of(stick)
					if cockpit != null:
						cockpit.move = _flat(stick, stick.global_basis.x * value.x - stick.global_basis.y * value.y,
							stick.global_basis.z, value.length()))
		"saltar", "levitar":
			var look := ButtonArchetype.power()
			look.latching = false
			look.text = "SALTAR" if key == "saltar" else "LEVITAR"
			look.head_size = 0.7
			var placed := _spotted(mount, look)
			if placed == null:
				return
			placed.set_meta(PIECE, key)
			var button := ButtonArchetype.button_of(placed)
			var jump := key == "saltar"
			button.pressed.connect(func() -> void: _hold(button, jump, true))
			button.released.connect(func() -> void: _hold(button, jump, false))
		"dash":
			var placed := _spotted(mount, DashRingArchetype.new())
			if placed == null:
				return
			placed.set_meta(PIECE, key)
			var buttons := DashRingArchetype.buttons_of(placed)
			for index in buttons.size():
				var button := buttons[index]
				button.pressed.connect(func() -> void:
					var cockpit := _cockpit_of(button)
					if cockpit != null:
						cockpit.dash_way = _flat(button, button.global_position - placed.global_position,
							placed.global_basis.z, 1.0)
						cockpit.dash = true)
				button.released.connect(func() -> void:
					var cockpit := _cockpit_of(button)
					if cockpit != null:
						cockpit.dash = false)


## ── LO QUE HACEN ────────────────────────────────────────────────────────────────────────────────────────────────

## EL PUÑO: al apretar, empieza a cargar; al soltar, la piña cargada (si alcanza la energía).
static func _punch(mech: CageMech, pressed: bool, held: Dictionary) -> void:
	if mech == null or mech.melee == null:
		return
	if pressed:
		held["punch_from"] = Time.get_ticks_msec() / 1000.0
		return
	var from: float = held["punch_from"]
	held["punch_from"] = -1.0
	if from < 0.0 or not mech.energy.able():
		return
	var knobs := CageHandling.current
	var power := clampf((Time.get_ticks_msec() / 1000.0 - from) / knobs.punch_charge_time, 0.0, 1.0)
	mech.melee.charged_strike(power, knobs.punch_slowest, knobs.punch_strongest)


## LA CARGA que muestra su pantalla (0 a 1): la de la piña que se está manteniendo, o la del súper del cañón.
static func _charge(mech: CageMech, held: Dictionary) -> float:
	var from: float = held["punch_from"]
	if from >= 0.0:
		return (Time.get_ticks_msec() / 1000.0 - from) / CageHandling.current.punch_charge_time
	if mech != null and mech.cannon != null and mech.cannon.mode == CannonTip.Mode.SUPER:
		return mech.cannon.charge
	return 0.0


## SALTAR o LEVITAR, apretado o suelto.
static func _hold(from: Node, jump: bool, on: bool) -> void:
	var cockpit := _cockpit_of(from)
	if cockpit == null:
		return
	if jump:
		cockpit.jump = on
	else:
		cockpit.levitate = on


## UNA DIRECCIÓN DEL MUNDO `world` SOBRE UNA CARA (de normal `normal`), en el piso de la meca de `from` (x a la derecha,
## y adelante, como BalanceBody.move), de largo `length`. LA CARA SE ACUESTA SOBRE EL PISO girándola por su borde
## horizontal: lo de arriba de la cara va hacia adelante de quien la mira (hacia la cara), lo de los costados queda a los
## costados, y los ángulos son los de la cara (los ocho del dash, a 45° en el piso también: proyectarlos los apretaba).
static func _flat(from: Node, world: Vector3, normal: Vector3, length: float) -> Vector2:
	var mech := _mech_of(from)
	if mech == null:
		return Vector2.ZERO
	var to_mech := mech.global_basis.inverse()
	var local := to_mech * world
	var face := (to_mech * normal).normalized()
	var flat := Vector3(local.x, 0.0, local.z)
	if absf(face.y) < 0.99:
		var along := Vector3.UP.cross(face).normalized()
		var uphill := face.cross(along)
		var ahead := -Vector3(face.x, 0.0, face.z).normalized()
		flat = along * local.dot(along) + ahead * local.dot(uphill)
	var out := Vector2(flat.x, -flat.z)
	return out.normalized() * length if out.length() > 0.001 else Vector2.ZERO


## ── DÓNDE ───────────────────────────────────────────────────────────────────────────────────────────────────────

## La celda de una pieza de `cells` adelante en su cara (la grilla crece hacia +x de la cara; si eso es hacia atrás, +z,
## adelante es la 0).
static func _front(board: FaceBoard, cells: Vector2i) -> Vector2i:
	var forward_first := board.frame.basis.x.z > 0.0
	return Vector2i(FRONT if forward_first else board.size.x - FRONT - cells.x, ROW)


## LOS BOTONES DE MODO DEL CAÑÓN, en columna justo detrás de su mando (el `index` de arriba abajo, en el orden de `MODES`);
## si no entran, donde se pueda.
static func _behind_arm(mount: FaceMount, made: PanelArchetype, index: int) -> Node3D:
	var board := mount.board
	var cells := made.cells(0)
	var arm := FoldingArmArchetype.CELLS
	var forward_first := board.frame.basis.x.z > 0.0
	var column := FRONT + arm.x + 1 if forward_first else board.size.x - FRONT - arm.x - 1 - cells.x
	var at := Vector2i(column, ROW + index * (cells.y + 1))
	if mount.can_place(made, at):
		return mount.place(made, at)
	return _spotted(mount, made)


## Pone `made` donde entre lo más al medio posible, con una celda de aire alrededor de lo que ya hay.
static func _spotted(mount: FaceMount, made: PanelArchetype) -> Node3D:
	var at := _spot(mount, made)
	if at.x < 0:
		push_warning("[Tableros de la jaula] «%s» no entra en la cara «%s»." % [made.display_name, mount.board.name])
		return null
	return mount.place(made, at)


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


## ── DE QUIÉN ────────────────────────────────────────────────────────────────────────────────────────────────────

static func _mech_of(node: Node) -> CageMech:
	var at := node
	while at != null and not at is CageMech:
		at = at.get_parent()
	return at as CageMech


static func _cockpit_of(node: Node) -> MechCockpit:
	var mech := _mech_of(node)
	if mech == null or not mech.keys is ToolMechKeys:
		return null
	return (mech.keys as ToolMechKeys).cockpit


## La pieza `key` (su nombre en `LAYOUT`) de la cabina `cabin`, o null.
static func piece_of(cabin: CageCabin, key: String) -> Node3D:
	for found in cabin.find_children("*", "Node3D", true, false):
		if found.get_meta(PIECE, "") == key:
			return found as Node3D
	return null


## Muestra o esconde las grillas pintadas de todas las jaulas de `tree`.
static func set_grid_visible(tree: SceneTree, on: bool) -> void:
	show_grid = on
	for cabin in tree.root.find_children("*", "CageCabin", true, false):
		for grid in (cabin as CageCabin).board_root().find_children("*", "MeshInstance3D", true, false):
			if grid.has_meta(GRID):
				(grid as Node3D).visible = on
