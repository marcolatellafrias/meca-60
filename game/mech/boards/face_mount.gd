class_name FaceMount
extends Node3D

## EL TABLERO DE UNA CARA: LAS PIEZAS PUESTAS EN SU GRILLA, CADA UNA SOBRE SU BASE (17/11/2026, el usuario: «en la nave
## los placeables tenían como una mini base que ocupaba exactamente las celdas que estaba ocupando y arriba tenía el
## modelo»; y de las dos formas de ubicarlas, «la opción 2»: en celdas sueltas). Como la nave de character-parametric
## (ShipKits._clay_block y _component_base):
##   · CADA PIEZA OCUPA SUS PROPIAS CELDAS (un ComponentArchetype dice cuántas: el botón 2 × 2, el de encendido 4 × 4,
##     la palanca grande 5 × 12), donde entre en la zona de piezas de la cara (FaceBoard.Kind.MODULES), sin pisar otra.
##   · DEBAJO, SU BASE: una placa de esquinas redondeadas de EXACTAMENTE esas celdas, `RISE` de alto (la de la nave para
##     lo que no lleva cable). Es lo que se lee como «la pieza ocupa esas celdas»: la pieza misma deja su margen.
##   · ENCIMA, LA PIEZA, centrada (PanelArchetype.mount), con la cara hacia quien usa la cara.
##
## *Hasta el 17/11/2026 las ponía el tablero viejo de character-parametric (ProceduralDashboard): la caja de cada control
## eran sus celdas menos 1 cm de cada lado y sin nada debajo, así que ni la pieza ni nada llegaba a las rayas.*
##
## LA RED: cada pieza se llama por su orden (`pieza_N`), igual en todas las máquinas, y así el control de adentro
## sincroniza por su camino (ver ControllableInteractable). El que se une le pide al host cómo están (lo mismo que hacía
## ProceduralDashboard).

## El alto de la base: el de la nave para las piezas chicas (ShipKits.SMALL_RISE).
const RISE := 0.018
## Las esquinas de la base.
const CORNER := 0.01
const BASE_COLOR := Color(0.2, 0.21, 0.23)

var board: FaceBoard = null
var _taken := {}
var _count := 0


## EL TABLERO DE `p_board`, ya puesto en su esquina (FaceBoard.frame).
static func of(p_board: FaceBoard) -> FaceMount:
	var made := FaceMount.new()
	made.board = p_board
	made.name = "Tablero %s" % p_board.name
	made.transform = p_board.frame
	return made


func _ready() -> void:
	# El que se une: que el host le diga cómo están sus controles (los que alguien movió).
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		_request_control_states.rpc_id(1)


## Si `piece` entra con su esquina de arriba a la izquierda en `cell`: en la zona de piezas y sin pisar otra.
func can_place(piece: PanelArchetype, cell: Vector2i) -> bool:
	var cells := piece.cells(0)
	if not board.fits(cell, cells):
		return false
	for column in range(cell.x, cell.x + cells.x):
		for row in range(cell.y, cell.y + cells.y):
			if _taken.has(Vector2i(column, row)):
				return false
	return true


## Si la celda `cell` ya tiene una pieza.
func is_taken(cell: Vector2i) -> bool:
	return _taken.has(cell)


## PONE `piece` con su esquina de arriba a la izquierda en `cell`, sobre su base. Devuelve la raíz de la pieza (la de
## PanelArchetype.mount), o null si no entra.
func place(piece: PanelArchetype, cell: Vector2i) -> Node3D:
	if not can_place(piece, cell):
		push_warning("[Tablero] «%s» no entra en la cara «%s» en %s." % [piece.display_name, board.name, cell])
		return null
	var cells := piece.cells(0)
	for column in range(cell.x, cell.x + cells.x):
		for row in range(cell.y, cell.y + cells.y):
			_taken[Vector2i(column, row)] = true
	var slot := Node3D.new()
	slot.name = "pieza_%d" % _count
	_count += 1
	add_child(slot)
	var area := Vector2(cells) * ProceduralDashboard.CELL
	var middle := Vector3(cell.x * ProceduralDashboard.CELL + area.x * 0.5, -(cell.y * ProceduralDashboard.CELL + area.y * 0.5), 0.0)
	# LA BASE: exactamente sus celdas, con su choque.
	var base := StaticBody3D.new()
	base.name = "Base"
	base.position = middle + Vector3(0.0, 0.0, RISE * 0.5)
	slot.add_child(base)
	var plate := MeshInstance3D.new()
	plate.mesh = RoundedSlab.mesh(area, CORNER, RISE)
	plate.material_override = MeshKit.material(BASE_COLOR, 0.7)
	base.add_child(plate)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(area.x, area.y, RISE)
	shape.shape = box
	base.add_child(shape)
	# LA PIEZA, centrada encima.
	var top := Node3D.new()
	top.name = "Encima"
	top.position = Vector3(0.0, 0.0, RISE)
	slot.add_child(top)
	var root := piece.mount(0, top, cell)
	root.name = "Pieza"
	return root


## Los controles de sus piezas, en orden (el mismo en todas las máquinas).
func controls() -> Array[ControllableInteractable]:
	var out: Array[ControllableInteractable] = []
	for found in find_children("*", "ControllableInteractable", true, false):
		out.append(found as ControllableInteractable)
	return out


@rpc("any_peer", "reliable")
func _request_control_states() -> void:
	if not multiplayer.is_server():
		return
	var states: Array = []
	for control in controls():
		states.append(control.get_sync_state())
	_receive_control_states.rpc_id(multiplayer.get_remote_sender_id(), states)


@rpc("authority", "reliable", "call_remote")
func _receive_control_states(states: Array) -> void:
	var mine := controls()
	for i in mini(mine.size(), states.size()):
		if states[i] != null:
			mine[i].apply_sync_state(states[i])
