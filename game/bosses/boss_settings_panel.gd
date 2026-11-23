class_name BossSettingsPanel
extends KnobsPanel

## EL PANEL DE TODOS LOS JEFES (F2 en la fila del Luchador; ver BossSettings): la escala de todos los jefes y si se ven
## las marcas de aviso en el piso, en vivo. Como todos los paneles de perillas (KnobsPanel): borrador, «Guardar» y «Volver a lo guardado».

const LABELS := {"scale": "escala de todos los jefes (1: la maqueta)",
	"floor_marks": "marcas de aviso en el piso", "attack_range": "ALCANCE DE LOS ATAQUES (m)"}


func setup_panel() -> void:
	panel_width = 360.0
	setup_knobs("jefes", "TODOS LOS JEFES")


func knobs() -> Resource:
	return BossSettings.current


func fresh() -> Resource:
	return BossSettings.new()


func saved_path() -> String:
	return BossSettings.SAVED


## El alcance estira los poderes de los jefes que están peleando.
func applied() -> void:
	for brawler in BrawlerArchetype.brawlers():
		var brain := brawler.get_node_or_null("Cabeza") as BrawlerBrain
		if brain != null:
			brain.refresh_powers()


func note() -> String:
	return "lo que sale de su cuerpo escala con él; las zonas, en cada poder"


func sections() -> Array[Dictionary]:
	return [{"title": "TODOS LOS JEFES", "target": draft(), "labels": LABELS,
		"include": PackedStringArray(["Todos los jefes"]), "headers": false, "defaults": BossSettings.new()}]
