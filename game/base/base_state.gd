class_name BaseState
extends RefCounted

## LO QUE GUARDA LA SUCURSAL ENTRE PARTIDAS (ver docs/conceptual/progresion.md y docs/technical/sucursal.md): la plata de
## la tripulación, el depósito, lo que tiene puesto la meca y el contrato firmado. Vive mientras corre el juego (no se
## guarda a disco). EN RED (BaseSync, docs/technical/flujo-de-partida.md): la copia que manda es la del host; los demás
## reciben una foto entera (`snapshot`/`load_snapshot`) cada vez que cambia. Compra, pone, saca y firma sólo el
## capitán (`is_captain`), que es el host.

signal changed()

## Con lo que arranca la tripulación.
const START_MONEY := 2500

## LOS HUECOS DE LA MECA: cada uno acepta una sola clase de cosa (ver ArmoryCatalog.Kind). Cada brazo tiene su puño, que
## nunca queda vacío (se cambia por otro), y una herramienta encima.
const SLOTS := {
	"fist_left": ArmoryCatalog.Kind.FIST, "fist_right": ArmoryCatalog.Kind.FIST,
	"tool_left": ArmoryCatalog.Kind.ARM_TOOL, "tool_right": ArmoryCatalog.Kind.ARM_TOOL,
	"back_left": ArmoryCatalog.Kind.BACK, "back_right": ArmoryCatalog.Kind.BACK,
	"plate_arm_left": ArmoryCatalog.Kind.PLATE_ARM, "plate_arm_right": ArmoryCatalog.Kind.PLATE_ARM,
	"plate_leg_left": ArmoryCatalog.Kind.PLATE_LEG, "plate_leg_right": ArmoryCatalog.Kind.PLATE_LEG,
}

static var current := BaseState.new()

var money := START_MONEY
## El depósito: ids del catálogo, uno por cosa (las placas se repiten).
var depot: Array[String] = []
## hueco -> id ("" si está vacío; el brazo vacío es la mano de base).
var loadout := {}
## El índice del contrato firmado en ContractsCatalog (-1: ninguno).
var contract := -1


func _init() -> void:
	for slot: String in SLOTS:
		loadout[slot] = ""
	# la meca nueva viene con sus dos puños comunes y su acorazado completo
	loadout["fist_left"] = "fist"
	loadout["fist_right"] = "fist"
	for slot: String in ["plate_arm_left", "plate_arm_right", "plate_leg_left", "plate_leg_right"]:
		loadout[slot] = ArmoryCatalog.plate_for(SLOTS[slot])


## Si la armería todavía lo vende: lo único (las herramientas de brazo y las armas de espalda) se compra una vez.
func in_stock(id: String) -> bool:
	if not ArmoryCatalog.item(id).get("unique", false):
		return true
	return not depot.has(id) and not loadout.values().has(id)


func can_buy(id: String) -> bool:
	return in_stock(id) and money >= int(ArmoryCatalog.item(id).price)


## Compra al depósito.
func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	money -= int(ArmoryCatalog.item(id).price)
	depot.append(id)
	changed.emit()
	return true


func fits(id: String, slot: String) -> bool:
	return SLOTS.has(slot) and int(ArmoryCatalog.item(id).kind) == int(SLOTS[slot])


## Pone en el hueco algo del depósito; lo que había vuelve al depósito.
func equip_from_depot(depot_index: int, slot: String) -> bool:
	if depot_index < 0 or depot_index >= depot.size() or not fits(depot[depot_index], slot):
		return false
	var id: String = depot[depot_index]
	depot.remove_at(depot_index)
	if loadout[slot] != "":
		depot.append(loadout[slot])
	loadout[slot] = id
	changed.emit()
	return true


## Compra y pone de una (arrastrado de la tienda al hueco).
func buy_into(id: String, slot: String) -> bool:
	if not fits(id, slot) or not buy(id):
		return false
	return equip_from_depot(depot.size() - 1, slot)


## Mueve lo de un hueco a otro de la misma clase (de un brazo al otro): se cambian.
func swap_slots(from: String, to: String) -> bool:
	if from == to or loadout[from] == "" or not fits(loadout[from], to):
		return false
	var moved: String = loadout[from]
	loadout[from] = loadout[to]
	loadout[to] = moved
	changed.emit()
	return true


## Si se lo puede sacar a un hueco: el puño no (se lo cambia soltándole otro encima).
func removable(slot: String) -> bool:
	return loadout.get(slot, "") != "" and int(SLOTS[slot]) != ArmoryCatalog.Kind.FIST


## Lo saca del hueco y lo guarda en el depósito.
func unequip(slot: String) -> void:
	if not removable(slot):
		return
	depot.append(loadout[slot])
	loadout[slot] = ""
	changed.emit()


## EL CAPITÁN: el host (sin red, uno mismo). Sólo él compra, pone, saca y firma.
static func is_captain(tree: SceneTree) -> bool:
	return tree.get_multiplayer().is_server()


## LA FOTO ENTERA, para mandarla por la red.
func snapshot() -> Dictionary:
	return {"money": money, "depot": depot.duplicate(), "loadout": loadout.duplicate(), "contract": contract}


func load_snapshot(data: Dictionary) -> void:
	money = int(data.get("money", money))
	depot.assign(data.get("depot", depot))
	loadout = (data.get("loadout", loadout) as Dictionary).duplicate()
	contract = int(data.get("contract", contract))
	changed.emit()


func sign_contract(index: int) -> void:
	contract = index
	changed.emit()
