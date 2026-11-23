class_name IsoPanel
extends KnobsPanel

## EL F1 DE LA FILA CÁMARA ISOMÉTRICA: la proyección, el zoom y el ángulo (IsoSettings). Como todo panel de perillas, se
## mueve un borrador y «Guardar» lo aplica.

const LABELS := {
	"orthographic": "ortográfica (apagada: perspectiva)", "zoom": "zoom: metros de alto en pantalla",
	"pitch": "inclinación (°; 90 es desde arriba)", "yaw": "giro (°)",
	"fov": "apertura con perspectiva (°)",
}


func setup_panel() -> void:
	panel_width = 400.0
	setup_knobs("camara_isometrica", "CÁMARA ISOMÉTRICA")


func knobs() -> Resource:
	return IsoSettings.current


func fresh() -> Resource:
	return IsoSettings.new()


func saved_path() -> String:
	return IsoSettings.SAVED


func note() -> String:
	return "«Guardar» aplica los cambios"


func sections() -> Array[Dictionary]:
	return [{"title": "CÁMARA", "target": draft(), "labels": LABELS, "include": PackedStringArray(["Cámara"]),
		"headers": false, "defaults": IsoSettings.new()}]
