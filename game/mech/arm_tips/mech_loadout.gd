class_name MechLoadout
extends Resource

## EL EQUIPO DE UNA MECA (16/11/2026; el usuario: «un menú nuevo… en el que vos seleccionás qué cosas tiene equipada esa
## meca y podés guardarla»): lo que lleva cada brazo (ver ArmLoadout) como perillas, para el panel de equipamiento
## (EquipmentPanel). Cada fila de meca del sandbox guarda el suyo (`path_for`, por el nombre de la fila); sin guardar,
## el de la clase de la meca (Mech.default_loadout). Los archivos son del usuario (ver KnobsFile).

const FOLDER := "res://game/mech/arm_tips/saved"

@export_group("Brazo izquierdo")
@export_enum("discreto", "con músculos") var left_motion := 0
@export_enum("puño común", "puño pesado", "palo eléctrico", "taladro", "sierra", "cañón de energía", "escudo") var left_tip := 0
@export var left_plate := false
@export_group("Brazo derecho")
@export_enum("discreto", "con músculos") var right_motion := 0
@export_enum("puño común", "puño pesado", "palo eléctrico", "taladro", "sierra", "cañón de energía", "escudo") var right_tip := 0
@export var right_plate := false

## Los de cada fila, ya leídos (los guarda el panel y los leen las mecas al armarse).
static var _current := {}


## EL EQUIPO DE LA FILA `key`: el guardado o, sin archivo, `defaults`.
static func current(key: String, defaults: Array[ArmLoadout]) -> MechLoadout:
	if not _current.has(key):
		_current[key] = KnobsFile.load_into(MechLoadout.from_arms(defaults), path_for(key))
	return _current[key]


## Dónde se guarda el de la fila `key`.
static func path_for(key: String) -> String:
	return "%s/%s.tres" % [FOLDER, key.to_snake_case()]


static func from_arms(arms: Array[ArmLoadout]) -> MechLoadout:
	var loadout := MechLoadout.new()
	loadout.left_motion = arms[0].motion
	loadout.left_tip = arms[0].tip
	loadout.left_plate = arms[0].plate
	loadout.right_motion = arms[1].motion
	loadout.right_tip = arms[1].tip
	loadout.right_plate = arms[1].plate
	return loadout


## Lo de cada brazo, el izquierdo y el derecho.
func arms() -> Array[ArmLoadout]:
	return [ArmLoadout.of(left_motion as ArmLoadout.Motion, left_tip as ArmLoadout.Tip, left_plate),
		ArmLoadout.of(right_motion as ArmLoadout.Motion, right_tip as ArmLoadout.Tip, right_plate)]
