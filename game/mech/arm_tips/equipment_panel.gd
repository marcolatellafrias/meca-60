class_name EquipmentPanel
extends KnobsPanel

## EL EQUIPAMIENTO DE LA MECA (F5 de las filas de mecas; 16/11/2026, el usuario: «un menú nuevo, que ya que los brazos
## están unificados en todas las mecas, va a afectar a todas las mecas… en el que vos seleccionás qué cosas tiene
## equipada esa meca y podés guardarla»): el mismo panel en todas las filas, y cada fila guarda el suyo (MechLoadout, por
## el nombre de la fila). Por brazo: qué lleva en la punta y si lleva la placa
## del acorazado. Como todos los de perillas (KnobsPanel): se mueve un borrador, y «Guardar» o «Volver a lo guardado»
## lo escriben y rearman las mecas.

const PANEL_WIDTH := 380.0
const LABELS := {
	"left_tip": "en la punta", "left_plate": "con la placa del acorazado",
	"right_tip": "en la punta", "right_plate": "con la placa del acorazado",
}
const ARMS: Array[String] = ["Brazo izquierdo", "Brazo derecho"]

## La fila (su nombre: dónde se guarda) y lo que lleva su meca sin nada guardado.
var key := ""
var defaults: Array[ArmLoadout] = []


func _init(archetype: MechArchetype = null) -> void:
	if archetype != null:
		key = archetype.display_name
		defaults = archetype.default_loadout()


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("equipamiento_" + key.to_snake_case(), "%s: EL EQUIPAMIENTO" % key.to_upper())


func note() -> String:
	return "guardar rearma la meca con lo elegido (sólo esta fila)"


func knobs() -> Resource:
	return MechLoadout.current(key, defaults)


func fresh() -> Resource:
	return MechLoadout.from_arms(defaults)


## Al guardar, la carpeta se crea si falta.
func saved_path() -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MechLoadout.FOLDER))
	return MechLoadout.path_for(key)


func applied() -> void:
	Mech.rebuild_all(get_tree())


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for arm: String in ARMS:
		all.append({"title": arm.to_upper(), "target": draft(), "labels": LABELS, "include": PackedStringArray([arm]),
			"headers": false, "defaults": fresh()})
	return all
