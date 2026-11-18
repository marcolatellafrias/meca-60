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
##     izquierdo usa SU BRAZO, según lo que lleve (`_arm_use`; lo que lleva cada uno se elige en el F5):
##       — EL CAÑÓN: el gatillo, según el modo que eligen TRES BOTONES al lado del mando de la izquierda —RÁFAGA y
##         BARRIDO mientras se mantiene, SÚPER carga mientras se mantiene y tira al soltar (CannonTip).
##       — EL PUÑO (o el palo): cuanto más se mantiene, más lenta y más fuerte la piña (MechArm.charged_strike; sus
##         perillas, en el F7: CageHandling).
##       — EL ESCUDO (ShieldTip): mientras se mantiene, levantado; frena lo que viene de frente (MechShield,
##         ToolMech.block_hit). El canje: un arma menos.
##       — EL TALADRO O LA SIERRA (SpinTip): mientras se mantiene, toma velocidad gastando energía; al soltar, el
##         directo, más fuerte cuanto más giraba. *Hasta el 18/11/2026 no se cargaban desde acá y nunca giraban.*
##   · DOS PANTALLAS EN BRAZOS FIJOS (ScreenArmArchetype), arriba en la vista del que maneja: la ENERGÍA de la meca y la
##     CARGA de lo que se está manteniendo («que esté al máximo… hasta que estás cargando… al máximo»).
##   ARRIBA, EN EL POZO: LA LOCOMOCIÓN (lo piden a MechCockpit, que lee la meca con las reglas de energía de siempre).
##   · EN EL TABLERO DE ADELANTE, DOS PALANCAS DE PALO NEGRO Y PUNTA ROJA (ControlArchetype.DRIVE_LEVER, DRIVE_STICK;
##     el usuario: «una que es de aceleración… y la otra… XZ, que se trabe y que decida para dónde ir»): a la izquierda
##     EL ACELERADOR (cuánto; adelante, más) y a la derecha LA DE DIRECCIÓN (hacia dónde; QUEDA DONDE SE LA DEJA, y cerca
##     del medio no pide nada: `DEAD`). Camina hacia donde apunta la de dirección, a lo que diga el acelerador.
##   · SALTAR adelante a la izquierda y LEVITAR (en el aire) adelante a la derecha: dos controles distintos (el usuario:
##     «nos da más variedad»). EL DASH, UN BOTÓN, en el tablero de la derecha, del lado de la de dirección: hacia donde
##     apunta ella (al medio, no sale). Con las dos palancas no entra en el de adelante, ni con levitar en el suyo.
##     AGACHAR, en el tablero de la izquierda: apoyada, se agacha; EN EL AIRE, BAJA RÁPIDO, como un dash hacia abajo
##     (KinematicSettings.dive_speed; el usuario: «nos ahorramos un botón»). *Hasta el 18/11/2026 había además un botón
##     ESCUDO al lado de saltar: el escudo pasó al brazo del de abajo.*
##   · LA PANTALLA DEL PROPULSOR (la barra de levitar, KinematicMover.fly_fuel: se gasta levitando y se llena apoyada), en
##     un brazo fijo corto al lado de levitar, abajo a la derecha de la vista del de arriba (`PIT_SCREEN_AT`). *Primero
##     salía de la pared del pozo: un palo de 1,2 m que cruzaba la vista.*
##   HACIA DÓNDE APUNTA ES EN LA MECA: la de dirección empujada hacia el frente de la meca va adelante (se mide en el
##   mundo y se pasa al torso: vale en cualquier cara, y aunque el módulo de arriba gire aparte; ver `_flat`).
##   *Hasta el 17/11/2026 (el mismo día) la palanca de dos ejes caminaba sola y volvía al medio al soltarla, y el dash
##   eran ocho botones en círculo, uno por dirección.*
##
## LA GRILLA PINTADA se ve sólo si se pide (`show_grid`, la L de su fila del sandbox): es para ubicar, no de la meca.
## *Hasta el 17/11/2026 había palancas y botones de prueba sin conectar en casi todas las caras, y antes, controles de
## mentira.*

## Lo que va en cada cara: su nombre (FaceBoard.name) y las piezas (ver `_place`).
const LAYOUT := [
	["cápsula izquierda", ["brazo izquierdo", "modo ráfaga", "modo barrido", "modo súper"]],
	["cápsula derecha", ["brazo derecho"]],
	["cápsula izquierda arriba", ["pantalla energía"]],
	["cápsula derecha arriba", ["pantalla carga"]],
	["tablero adelante", ["palancas"]],
	["tablero adelante izquierda", ["saltar"]],
	["tablero adelante derecha", ["levitar", "pantalla propulsor"]],
	["tablero derecha", ["dash"]],
	["tablero izquierda", ["agachar"]],
]
## LA MECA DE 1 (CageShape.crew; sin el bloque de arriba): además, EL MANEJO (DriveHandle), que sale del costado izquierdo
## de la cápsula con el codo abajo: entra a la vista por abajo, como los mandos. *Primero salía del techo, y su palo
## cruzaba el medio de la vista.*
const SOLO := [["cápsula izquierda", ["manejo"]]]
## Las teclas del modo manejo para los modos del cañón (los de sus tres botones).
const SOLO_MODES := {KEY_1: CannonTip.Mode.BURST, KEY_2: CannonTip.Mode.BEAM, KEY_3: CannonTip.Mode.SUPER}
## LOS MANDOS PLEGABLES Y LAS PANTALLAS van ADELANTE en su cara (`FRONT` celdas de la punta de adelante, en la fila
## `ROW` de arriba). El mando, traído a la mano (`HAND`); las pantallas, arriba a los costados de la vista (`SCREEN_AT`),
## las dos desde los ojos del que maneja, en partes del radio de 0,75 m de la maqueta; la mirada, al frente, a la cúpula
## (`LOOK_AHEAD`).
const FRONT := 2
const ROW := 6
const HAND := Vector3(0.3, -0.42, -0.42)
const SCREEN_AT := Vector3(0.3, 0.13, -0.5)
const LOOK_AHEAD := 3.0
## La pantalla del propulsor, desde los ojos del de arriba (m): abajo a la derecha de la vista, apenas arriba del
## tablero (que empieza 0,58 m más abajo que los ojos).
const PIT_SCREEN_AT := Vector3(0.38, -0.3, -0.62)
## Los botones que se mantienen (el texto y el color): lo que piden mientras se aprietan (ver `_hold`).
const HOLDS := {"saltar": ["SALTAR", Color(0.3, 0.8, 0.4)], "levitar": ["LEVITAR", Color(0.3, 0.8, 0.4)],
	"agachar": ["AGACHAR", Color(0.45, 0.62, 0.85)]}
## Los modos del cañón que eligen sus botones: su nombre y su color.
const MODES := {"modo ráfaga": [CannonTip.Mode.BURST, "RÁFAGA", Color(0.9, 0.62, 0.2)],
	"modo barrido": [CannonTip.Mode.BEAM, "BARRIDO", Color(0.35, 0.7, 0.95)],
	"modo súper": [CannonTip.Mode.SUPER, "SÚPER", Color(0.85, 0.3, 0.25)]}
## La palanca de dirección más cerca del medio que esto no pide nada (parte de su recorrido).
const DEAD := 0.2
## Lo que marca una grilla pintada (para mostrarlas y esconderlas todas).
const GRID := &"grilla_de_tablero"
## Lo que marca cada pieza puesta: su nombre en `LAYOUT` (las dos palancas, «acelerador» y «dirección»), para
## encontrarla: `piece_of`.
const PIECE := &"pieza_de_tablero"

## Si se ven las grillas pintadas: las de ahora y las que se armen.
static var show_grid := false


## LA GRILLA Y LAS PIEZAS en `root` (el fondo de la caja de la cabina, CageCabin.board_root) de la forma `form`.
## Los de arriba (el tablero y el pozo) cuelgan de `upper_root` (el módulo de arriba, que puede girar: ver
## CageCabin.upper), en el mismo espacio que `root`; sin `with_upper` (la meca de 1), no hay.
static func dress(root: Node3D, form: CageShape, upper_root: Node3D = null, with_upper := true) -> void:
	var wanted := {}
	for entry: Array in LAYOUT + ([] if with_upper else SOLO):
		wanted[entry[0]] = (wanted.get(entry[0], []) as Array) + (entry[1] as Array)
	var top := upper_root if upper_root != null else root
	var faces: Array = []
	for board: FaceBoard in CageCabin.capsule_boards(form):
		faces.append([board, root])
	if with_upper:
		for board: FaceBoard in CageCabin.upper_boards(form):
			faces.append([board, top])
	# Lo de los controles que se lee de varios: desde cuándo se mantiene la piña (para la pantalla de la carga), hacia
	# dónde apunta la palanca de dirección y cuánto el acelerador (para caminar y el dash).
	var state := {"punch_from": -1.0, "way": Vector2.ZERO, "throttle": 0.0}
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
			_place(key, mount, root, form, state)


## PONE Y CONECTA LA PIEZA `key` en el tablero `mount`.
static func _place(key: String, mount: FaceMount, root: Node3D, form: CageShape, state: Dictionary) -> void:
	var board := mount.board
	var side := signf(-board.frame.basis.z.x)
	var eye := CageCabin.driver_eye(form)
	var k := form.capsule_radius() / 0.75
	match key:
		"brazo izquierdo", "brazo derecho":
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
			arm.use = func(pressed: bool) -> void: _arm_use(arm, side, pressed, state)
		"manejo":
			var look := FoldingArmArchetype.new(1.0)
			look.drive = true
			var placed := _spotted(mount, look)
			if placed == null:
				return
			placed.set_meta(PIECE, key)
			var handle := FoldingArmArchetype.arm_of(placed) as DriveHandle
			handle.reach_to(eye + Vector3(0.0, HAND.y, HAND.z) * k, eye + Vector3.FORWARD * LOOK_AHEAD, root)
			handle.steer = func(world_yaw: float, world_pitch: float) -> void:
				var mech := _mech_of(handle)
				if mech != null:
					mech.steer(world_yaw, world_pitch)
			handle.use = func(pressed: bool) -> void: _arm_use(handle, -1.0, pressed, state)
			handle.use_alt = func(pressed: bool) -> void: _arm_use(handle, 1.0, pressed, state)
			handle.drive = func(active: bool) -> void: _drive_keys(handle, active, state)
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
				screen.source = func() -> float: return _charge(_mech_of(screen), state)
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
		"palancas":
			var pair := _pair(mount, ControlArchetype.of(ControlArchetype.DRIVE_LEVER),
				ControlArchetype.of(ControlArchetype.DRIVE_STICK))
			if pair.is_empty():
				return
			pair[0].set_meta(PIECE, "acelerador")
			pair[1].set_meta(PIECE, "dirección")
			for found in pair[0].find_children("*", "OneAxisComponent", true, false):
				var lever := found as OneAxisComponent
				# Arriba en su tablero (adelante) es el mínimo: ver ControlArchetype.DRIVE_LEVER.
				lever.state_changed.connect(func(value: float) -> void:
					state["throttle"] = 1.0 - value
					_walk(lever, state))
			for found in pair[1].find_children("*", "TwoAxisComponent", true, false):
				var stick := found as TwoAxisComponent
				stick.state_changed_2d.connect(func(value: Vector2) -> void:
					# Los ejes del tablero, de la base: los de la palanca se inclinan con ella y torcían la dirección.
					var board_axes := stick.get_parent_node_3d().global_basis
					var world := board_axes.x * value.x - board_axes.y * value.y
					state["way"] = _flat(stick, world, board_axes.z, 1.0) if value.length() >= DEAD else Vector2.ZERO
					_walk(stick, state))
		"saltar", "levitar", "agachar":
			var look := ButtonArchetype.power()
			look.latching = false
			look.text = HOLDS[key][0]
			look.color = HOLDS[key][1]
			look.head_size = 0.7
			var placed := _spotted(mount, look)
			if placed == null:
				return
			placed.set_meta(PIECE, key)
			var button := ButtonArchetype.button_of(placed)
			button.pressed.connect(func() -> void: _hold(button, key, true))
			button.released.connect(func() -> void: _hold(button, key, false))
		"pantalla propulsor":
			var placed := _spotted(mount, ScreenArmArchetype.new("PROPULSOR", Color(0.4, 0.75, 0.95)))
			if placed == null:
				return
			placed.set_meta(PIECE, key)
			var screen := ScreenArmArchetype.screen_of(placed)
			var top_eye := CageCabin.pit_eye(form)
			screen.reach_to(top_eye + PIT_SCREEN_AT, top_eye, mount.get_parent_node_3d())
			screen.source = func() -> float:
				var mech := _mech_of(screen)
				return mech.mover.fly_fuel if mech != null and mech.mover != null else 0.0
		"dash":
			var look := ButtonArchetype.power()
			look.latching = false
			look.color = Color(0.9, 0.62, 0.2)
			look.text = "DASH"
			look.head_size = 0.7
			var placed := _spotted(mount, look)
			if placed == null:
				return
			placed.set_meta(PIECE, key)
			var button := ButtonArchetype.button_of(placed)
			button.pressed.connect(func() -> void:
				var cockpit := _cockpit_of(button)
				if cockpit != null:
					cockpit.dash_way = state["way"]
					cockpit.dash = true)
			button.released.connect(func() -> void:
				var cockpit := _cockpit_of(button)
				if cockpit != null:
					cockpit.dash = false)


## ── LO QUE HACEN ────────────────────────────────────────────────────────────────────────────────────────────────

## LO QUE HACE EL BRAZO DE ESE LADO (`side`: −1 el izquierdo, 1 el derecho) con el clic, según lo que lleve: el cañón
## dispara (su gatillo, MechCockpit.fire); el escudo se levanta mientras se mantiene (MechCockpit.shield; queda en
## `state`, así el teclado del modo manejo no lo pisa); el puño o el palo, la piña cargada (`_punch`).
static func _arm_use(from: Node, side: float, pressed: bool, state: Dictionary) -> void:
	var mech := _mech_of(from)
	var cockpit := _cockpit_of(from)
	if mech == null or cockpit == null:
		return
	var arm := _arm_on(mech, side)
	if arm == null:
		return
	if arm.tip is CannonTip:
		cockpit.fire = pressed
	elif arm.tip is ShieldTip:
		state["shield"] = pressed
		cockpit.shield = pressed
	elif arm.tip is SpinTip:
		# EL TALADRO Y LA SIERRA: mantenido, toma velocidad (gastando energía); al soltar, el directo (SpinTip).
		var spinner := arm.tip as SpinTip
		cockpit.spinning.erase(spinner)
		if pressed:
			cockpit.spinning.append(spinner)
		else:
			spinner.strike()
	elif arm == mech.melee:
		_punch(mech, pressed, state)


## El brazo de ese lado de la meca (por dónde está su hombro).
static func _arm_on(mech: CageMech, side: float) -> MechArm:
	for arm in mech.arms:
		if signf(mech.to_local(arm.anchor.global_transform * arm.shoulder_local).x) == signf(side):
			return arm
	return null


## EL PUÑO: al apretar, empieza a cargar; al soltar, la piña cargada (si alcanza la energía).
static func _punch(mech: CageMech, pressed: bool, state: Dictionary) -> void:
	if mech == null or mech.melee == null:
		return
	if pressed:
		state["punch_from"] = Time.get_ticks_msec() / 1000.0
		mech.melee.charging_since = state["punch_from"]
		return
	var from: float = state["punch_from"]
	state["punch_from"] = -1.0
	mech.melee.charging_since = -1.0
	if from < 0.0 or not mech.energy.able():
		return
	var knobs := CageHandling.current
	var power := clampf((Time.get_ticks_msec() / 1000.0 - from) / knobs.punch_charge_time, 0.0, 1.0)
	mech.melee.charged_strike(power, knobs.punch_slowest, knobs.punch_strongest)


## LA CARGA que muestra su pantalla (0 a 1): la de la piña que se está manteniendo, o la del súper del cañón.
static func _charge(mech: CageMech, state: Dictionary) -> float:
	var from: float = state["punch_from"]
	if from >= 0.0:
		return (Time.get_ticks_msec() / 1000.0 - from) / CageHandling.current.punch_charge_time
	if mech != null:
		for arm in mech.arms:
			if arm.tip is SpinTip and (arm.tip as SpinTip).charging:
				return (arm.tip as SpinTip).spin
	if mech != null and mech.cannon != null and mech.cannon.mode == CannonTip.Mode.SUPER:
		return mech.cannon.charge
	return 0.0


## EL TECLADO EN EL MODO MANEJO (la meca de 1, DriveHandle), mientras `active`: WASD camina (relativo al torso), espacio
## salta y en el aire otra vez levita, Shift tira el dash hacia donde camina, Ctrl agacha (en el aire, baja rápido), Q
## el escudo, y 1, 2 y 3 los modos del cañón (`SOLO_MODES`). Lo pide a MechCockpit, como los controles de la de 3.
static func _drive_keys(from: Node, active: bool, state: Dictionary) -> void:
	var cockpit := _cockpit_of(from)
	if cockpit == null:
		return
	var live := active and UIState.gameplay_active()
	var move := Vector2(MechKeys.axis(KEY_D, KEY_A), MechKeys.axis(KEY_W, KEY_S)).limit_length(1.0) if live \
		else Vector2.ZERO
	cockpit.move = move
	cockpit.jump = live and Input.is_physical_key_pressed(KEY_SPACE)
	cockpit.dash = live and Input.is_physical_key_pressed(KEY_SHIFT)
	cockpit.dash_way = move.normalized() if move.length() > 0.1 else Vector2.ZERO
	cockpit.crouch = live and Input.is_physical_key_pressed(KEY_CTRL)
	cockpit.shield = (live and Input.is_physical_key_pressed(KEY_Q)) or bool(state.get("shield", false))
	var mech := _mech_of(from)
	if not live or mech == null or mech.cannon == null:
		return
	for code: Key in SOLO_MODES:
		if Input.is_physical_key_pressed(code) and mech.cannon.mode != SOLO_MODES[code]:
			mech.cannon.mode = SOLO_MODES[code]
			mech.cannon.charge = 0.0


## CAMINAR: hacia donde apunta la palanca de dirección, a lo que diga el acelerador.
static func _walk(from: Node, state: Dictionary) -> void:
	var cockpit := _cockpit_of(from)
	if cockpit != null:
		cockpit.move = (state["way"] as Vector2) * float(state["throttle"])


## SALTAR, LEVITAR o AGACHAR (`what`, ver `HOLDS`), apretado o suelto.
static func _hold(from: Node, what: String, on: bool) -> void:
	var cockpit := _cockpit_of(from)
	if cockpit == null:
		return
	match what:
		"saltar":
			cockpit.jump = on
		"levitar":
			cockpit.levitate = on
		"agachar":
			cockpit.crouch = on


## UNA DIRECCIÓN DEL MUNDO `world` SOBRE UNA CARA (de normal `normal`), en el piso de la meca de `from` (x a la derecha,
## y adelante, como BalanceBody.move), de largo `length`. LA CARA SE ACUESTA SOBRE EL PISO girándola por su borde
## horizontal: lo de arriba de la cara va hacia adelante de quien la mira (hacia la cara), lo de los costados queda a los
## costados, y los ángulos son los de la cara (45° en una cara inclinada son 45° en el piso: proyectarlos los apretaba).
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


## LAS DOS PALANCAS, UNA AL LADO DE LA OTRA: `left` a la izquierda de quien mira el tablero, con una celda de aire entre
## las dos y centradas en alto, lo más al medio posible. Devuelve [la de la izquierda, la de la derecha], o nada si no
## entran.
static func _pair(mount: FaceMount, left: PanelArchetype, right: PanelArchetype) -> Array[Node3D]:
	var board := mount.board
	# La grilla crece hacia +x de la cara: si eso es hacia la derecha de la meca, la de la izquierda va primero.
	var left_first := board.frame.basis.x.x > 0.0
	var west := left if left_first else right
	var east := right if left_first else left
	var a := west.cells(0)
	var b := east.cells(0)
	var drop := (a.y - b.y) / 2
	var center := Vector2(board.size) * 0.5
	var best := Vector2i(-1, -1)
	var best_far := INF
	for column in board.size.x:
		for row in board.size.y:
			var at_west := Vector2i(column, row)
			var at_east := Vector2i(column + a.x + 1, row + drop)
			if not mount.can_place(west, at_west) or not mount.can_place(east, at_east) \
					or _crowded(mount, at_west, a) or _crowded(mount, at_east, b):
				continue
			var top := minf(at_west.y, at_east.y)
			var bottom := maxf(at_west.y + a.y, at_east.y + b.y)
			var far := (Vector2((column + at_east.x + b.x) * 0.5, (top + bottom) * 0.5) - center).length()
			if far < best_far:
				best = at_west
				best_far = far
	var out: Array[Node3D] = []
	if best.x < 0:
		push_warning("[Tableros de la jaula] Las dos palancas no entran en la cara «%s»." % board.name)
		return out
	var placed_west := mount.place(west, best)
	var placed_east := mount.place(east, Vector2i(best.x + a.x + 1, best.y + drop))
	out.append(placed_west if left_first else placed_east)
	out.append(placed_east if left_first else placed_west)
	return out


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
