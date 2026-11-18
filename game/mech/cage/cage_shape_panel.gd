class_name CageShapePanel
extends KnobsPanel

## LA FORMA DE LA MECA JAULA (F2 en su fila; ver CageShape, CageCabin): una pestaña por módulo, y la primera, EL CUERPO:
## el torso (la cuadrada o la redonda) y las perillas de cada uno. Como todos los paneles de perillas (KnobsPanel): se
## mueve un borrador, y «Guardar» o «Volver a lo guardado» rearman las mecas con eso.

const PANEL_WIDTH := 400.0
const LABELS := {
	"crew": "para cuántos: de 1, sólo la cápsula; de 2, sin la torre; de 3, todo",
	"torso": "el torso: la cuadrada (la caja) o la redonda (el cubo chanfleado)",
	"body_size": "la redonda: el talle (0, la cápsula con su marco; 1, el octógono de arriba)",
	"body_chamfer": "la redonda: el chanfle (0, parejo como la cápsula; 1, casi un cubo)",
	"upper_turns": "la redonda: el octógono de arriba gira aparte del torso",
	"bubble_radius": "cápsula: del centro a las caras (m)",
	"glass_smooth": "vidrio liso (si no, facetado)",
	"glass_clear": "vidrio: lo claro, adelante",
	"glass_tint": "vidrio: lo teñido, hacia los bordes (verdoso)",
	"glass_spread": "vidrio: cuánto ocupa lo claro",
	"glass_smudges": "vidrio: cuánto se notan las manchas",
	"glass_pixel": "vidrio: el tamaño de los cuadraditos de las manchas (m)",
	"padding": "la cuadrada: padding de los costados (m)",
	"floor_thick": "la cuadrada: grosor del piso, debajo de la burbuja (m)",
	"ceiling_thick": "la cuadrada: grosor del techo, encima de la burbuja (m)",
	"floor_gap": "margen extra: el piso de la cabina, debajo de la burbuja (m)",
	"seat_height": "altura de la silla: la pelvis sobre el piso (m; nunca con los pies abajo del piso)",
	"rim_width": "marco de la cápsula en la cara: ancho (m; 0, sin marco)",
	"rim_depth": "marco de la cápsula: cuánto sobresale de la cara (m)",
	"pit_radius": "radio del octógono (m)",
	"desk_tilt": "inclinación del tablero (°)",
	"arms_eye": "ojos del de los brazos, sobre su piso (m)",
	"tower_round": "redonda (si no, cuadrada)",
	"tower_width": "ancho (m)",
	"tower_depth": "fondo (m; nunca más que el ancho)",
	"gunner_eye": "ojos del artillero, sobre el piso de arriba (m)",
}
## Los de «Brazos y piernas»: los de la meca grande, más el adelanto de los hombros, que sólo tenía esta. *Hasta el
## 17/11/2026 se tomaban del panel de la forma de la meca grande (CabinShapePanel), borrado con ella.*
const LIMB_LABELS := {
	"arm_length": "largo de los brazos",
	"leg_length": "largo de las piernas",
	"thickness": "ancho (de los dos)",
	"leg_stretch": "cuánto se estiran las piernas paradas",
	"shoulder_out": "cuánto salen los hombros del costado (m)",
	"shoulder_forward": "cuánto se adelantan los hombros (0, al medio; 1, al frente sin salirse)",
}
const TABS: Array[String] = ["El cuerpo", "La cápsula de abajo", "El tablero de arriba", "La torre", "Brazos y piernas"]


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("meca_jaula_forma", "MECA JAULA: LA FORMA")
	_measure()


func knobs() -> Resource:
	return CageShape.current


func fresh() -> Resource:
	return CageShape.new()


func saved_path() -> String:
	return CageShape.SAVED


func applied() -> void:
	Mech.rebuild_all(get_tree())


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab: String in TABS:
		# «Brazos y piernas», con sus nombres (LIMB_LABELS).
		var labels: Dictionary = LIMB_LABELS if tab == "Brazos y piernas" else LABELS
		all.append({"title": tab.to_upper(), "tab": tab, "target": draft(), "labels": labels,
			"include": PackedStringArray([tab]), "headers": false, "defaults": CageShape.new(), "on_change": _measure})
	return all


## Lo que sale de los números, sin rearmar nada.
func _measure() -> void:
	var shape := draft() as CageShape
	if shape == null:
		return
	var pit := CageCabin.pit_of(shape)
	var torso := "redonda" if shape.is_round() else "cuadrada"
	var sunk := " (se hunde %.2f m en el cuerpo)" % shape.octagon_sink() if shape.octagon_sink() > 0.0 else ""
	say("%s: el cuerpo, %.2f m de lado y %.2f de alto · arriba, %.2f m de alto%s · la torre deja %.2f m hasta el pozo" % [
		torso, shape.side(), shape.height(), pit.top(), sunk, shape.upper_back() - pit.rim() - shape.tower_deep()])
