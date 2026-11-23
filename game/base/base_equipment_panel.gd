class_name BaseEquipmentPanel
extends EquipmentPanel

## EL PANEL DE EQUIPAMIENTO DEL SANDBOX, EN LA PARTIDA (ver BasePanels): el mismo, con el equipo de la meca jaula. Lo abre
## el capitán antes de salir a la arena, y al guardar la meca se rearma en todas las máquinas (BaseSync.equip).


func _init() -> void:
	super(CageMechArchetype.new())


func _can_open() -> bool:
	return BaseState.is_captain(get_tree()) and UIState.gameplay_active() and BasePanels.before_launch()


func applied() -> void:
	if BaseSync.current != null:
		BaseSync.current.equip()
