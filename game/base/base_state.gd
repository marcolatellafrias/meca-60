class_name BaseState
extends RefCounted

## LO QUE GUARDA LA SUCURSAL ENTRE PARTIDAS (ver docs/conceptual/progresion.md y docs/technical/sucursal.md): la plata de
## la tripulación, el depósito, lo que tiene puesto la meca y el contrato firmado. Por ahora vive mientras corre el juego
## (no se guarda a disco) y es una sola copia, sin red: la compra la hace el que abre la terminal. Después, el capitán.

signal changed()

## Con lo que arranca la tripulación.
const START_MONEY := 2500

## LOS HUECOS DE LA MECA: cada uno acepta una sola clase de cosa (ver ArmoryCatalog.Kind).
const SLOTS := {
	"arm_left": ArmoryCatalog.Kind.ARM_TOOL, "arm_right": ArmoryCatalog.Kind.ARM_TOOL,
	"back_left": ArmoryCatalog.Kind.BACK, "back_right": ArmoryCatalog.Kind.BACK,
	"plate_hull": ArmoryCatalog.Kind.PLATE_HULL,
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
	# la meca nueva viene con su acorazado completo
	for slot: String in ["plate_hull", "plate_arm_left", "plate_arm_right", "plate_leg_left", "plate_leg_right"]:
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


## Lo saca del hueco y lo guarda en el depósito.
func unequip(slot: String) -> void:
	if loadout.get(slot, "") == "":
		return
	depot.append(loadout[slot])
	loadout[slot] = ""
	changed.emit()


func sign_contract(index: int) -> void:
	contract = index
	changed.emit()
