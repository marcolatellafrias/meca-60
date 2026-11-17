class_name BossSettingsPanel
extends KnobsPanel

## EL PANEL DE TODOS LOS JEFES (F2 en la fila del Luchador; ver BossSettings): hoy, la escala de todos los jefes, en
## vivo. Como todos los paneles de perillas (KnobsPanel): borrador, «Guardar» y «Volver a lo guardado».

const LABELS := {"scale": "escala de todos los jefes (1: la maqueta)"}


func setup_panel() -> void:
	panel_width = 360.0
	setup_knobs("jefes", "TODOS LOS JEFES")


func knobs() -> Resource:
	return BossSettings.current


func fresh() -> Resource:
	return BossSettings.new()


func saved_path() -> String:
	return BossSettings.SAVED


func note() -> String:
	return "lo que sale de su cuerpo escala con él; las zonas, en cada poder"


func sections() -> Array[Dictionary]:
	return [{"title": "TODOS LOS JEFES", "target": draft(), "labels": LABELS,
		"include": PackedStringArray(["Todos los jefes"]), "headers": false, "defaults": BossSettings.new()}]
