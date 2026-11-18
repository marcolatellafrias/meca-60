class_name LegsPanel
extends KnobsPanel

## EL PANEL DE LAS PIERNAS (F4 en las filas de la meca): los pasos (LegSettings), los mismos para todas las mecas. Como
## todos los paneles de perillas (KnobsPanel): se mueve un borrador, y «Guardar» o «Volver a lo guardado» rearman las
## mecas.

## *El ancho era el del panel del cubo (HoverPanel), borrado con él el 17/11/2026.*
const PANEL_WIDTH := 420.0
const LABELS := {
	"knee_out": "rodillas hacia afuera (parte de adelante)", "knee_out_crouched": "rodillas hacia afuera, agachada",
	"stride": "largo del paso (m, piernas medianas)", "lift": "cuánto sube el pie (m, piernas medianas)",
	"fastest": "el paso más rápido (s)", "slowest": "el paso más lento (s)",
	"bob": "la caja sube a mitad del paso (m, piernas medianas)", "side_lean": "de costado se inclina (°)",
	"tuck_lift": "recogidas: suben (parte de la pierna)", "tuck_toes": "recogidas: la punta abajo (°)",
	"stomp": "pisotón: baja de golpe (0 a 1)", "stomp_dip": "al pisar se hunde (m, piernas medianas)",
}


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("piernas", "PIERNAS: LOS PASOS")


func knobs() -> Resource:
	return LegSettings.current


func fresh() -> Resource:
	return LegSettings.new()


func saved_path() -> String:
	return LegSettings.SAVED


func applied() -> void:
	Mech.rebuild_all(get_tree())


func note() -> String:
	return "el largo y la altura son de piernas medianas: se escalan con el largo de las piernas (F2)"


func sections() -> Array[Dictionary]:
	return [{"title": "LegSettings (game/balance_body/leg_settings.gd)", "target": draft(), "labels": LABELS,
		"defaults": LegSettings.new()}]
