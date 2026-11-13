class_name LocomotionPanel
extends TunerPanel

## ── EL F1 DE LA FILA LOCOMOCIÓN: LO DE TODOS LOS ARQUETIPOS (de character-parametric, traído el 13/11/2026; allá el
## usuario eligió «dos paneles» con las mismas pestañas) ───────────────────────────────────────────────────
## Lo que vale igual para todos (ver LocomotionCommon), con las pestañas del F3 de Personajes, que es lo de cada arquetipo
## (ver LocomotionTuner): si algo es del salto, está en la pestaña SALTO de uno o del otro. Cada sección, una lista de sus
## números (`SECTIONS`): lo que decide dónde va un número es esa lista, y uno que no esté en ninguna sale en rojo, al final.
## En vivo para todos; un solo «Guardar». *Hasta entonces sus pestañas eran el cuerpo, llevar algo, echarse atrás, tirar y
## en el aire, guardadas en tres archivos, y la caída, la frenada y el alcance se elegían con botones.*

## [pestaña, título, color, números].
const SECTIONS := [
	[LocomotionTuner.TAB_POSE, "ECHARSE ATRÁS CON LO QUE LLEVA — lower_spine, higher_spine, chest", Color(0.56, 0.74, 1.0),
		["carry_lean_mode", "carry_lean_by_weight", "carry_lean_away", "carry_lean_deg", "carry_lean_s",
		"carry_lean_spread", "carry_lean_hips"]],
	[LocomotionTuner.TAB_MOVE, "LLEVAR ALGO: DÓNDE VA", Color(0.96, 0.58, 0.72),
		["hold_drop_deg", "hold_drop_fade_deg", "hold_reach", "chest_clear"]],
	[LocomotionTuner.TAB_MOVE, "LLEVAR ALGO: EL CONO Y EL PESO", Color(0.96, 0.58, 0.72),
		["carry_cone_deg", "carry_cone_at_fall", "heavy_softness"]],
	[LocomotionTuner.TAB_MOVE, "LLEVAR ALGO: DE A VARIOS Y LO LARGO", Color(0.96, 0.58, 0.72),
		["share_shift_speed", "long_alone_sags", "sag_max_deg", "lab_long_by_end"]],
	[LocomotionTuner.TAB_MOVE, "TIRAR Y EMPUJAR", Color(0.95, 0.75, 0.45),
		["throw_charge_s", "throw_lean_deg", "throw_draw", "throw_push_s", "throw_extend", "throw_follow_deg",
		"throw_per_arm", "push_per_arm"]],
	[LocomotionTuner.TAB_MOVE, "EL ALCANCE PARA INTERACTUAR", Color(0.62, 0.66, 0.72), ["interaction_reach"]],
	[LocomotionTuner.TAB_BALANCE, "LA CAÍDA Y EL ATERRIZAJE", Color(0.78, 0.64, 1.0),
		["impact_fall_linear", "landing_brake", "ragdoll_in_air", "ragdoll_speed"]],
	[LocomotionTuner.TAB_JUMP, "PASAR AL AIRE", Color(0.62, 0.66, 0.72), ["blend_s"]],
	[LocomotionTuner.TAB_JUMP, "EN EL AIRE: TORSO — lower_spine", Color(0.56, 0.74, 1.0),
		["torso_on", "torso_apex_deg", "torso_fall_deg", "torso_fall_s", "torso_follow_s"]],
	[LocomotionTuner.TAB_JUMP, "EN EL AIRE: PIERNAS — higher_leg, lower_leg, foot", Color(0.52, 0.86, 0.6),
		["legs_on", "legs_still_bend", "legs_fast_bend", "legs_fall_s"]],
	[LocomotionTuner.TAB_JUMP, "EN EL AIRE: BRAZOS — upper_arm, lower_arm", Color(0.96, 0.58, 0.72),
		["arms_on", "apex_front_deg", "apex_out_deg", "apex_bend", "arms_fall_s", "fall_front_deg", "fall_out_deg",
		"fall_bend"]],
	[LocomotionTuner.TAB_JUMP, "DESPEGUE Y ATERRIZAJE", Color(0.78, 0.64, 1.0),
		["jump_squat", "landing_depth", "landing_steps_s"]],
	[LocomotionTuner.TAB_BODY, "EL HOMBRO", Color(0.96, 0.58, 0.72), ["shoulder_inside"]],
]

## Los que cambian los huesos: moverlos rearma a todos los personajes.
const REBUILDS := ["shoulder_inside", "interaction_reach"]

## Cómo se llama cada número en el panel.
const LABELS := {
	# Pose.
	"carry_lean_mode": "echarse atrás con lo que lleva", "carry_lean_by_weight": "según el peso",
	"carry_lean_away": "alejándose del paquete (si no, hacia atrás)", "carry_lean_deg": "lo más que se echa atrás (°)",
	"carry_lean_s": "tarda en echarse atrás (s)", "carry_lean_spread": "dónde se dobla: 0 la cadera, 1 la espalda",
	"carry_lean_hips": "la cadera adelante, hacia el paquete (m)",
	# Movimiento.
	"hold_drop_deg": "cuánto abajo de la mirada (°)", "hold_drop_fade_deg": "mirando abajo, se desvanece a (°)",
	"hold_reach": "a qué distancia del pecho (m)", "chest_clear": "el tope del pecho (m)",
	"carry_cone_deg": "el cono para soltarlo (°)", "carry_cone_at_fall": "lo que queda del cono a punto de caer",
	"heavy_softness": "lo pesado se lleva más blando (×)",
	"share_shift_speed": "qué tan rápido se muda el punto (m/s)", "long_alone_sags": "la larga, solo, se vence",
	"sag_max_deg": "lo más que se vence (°)",
	"lab_long_by_end": "en los experimentos, lo largo se agarra de la punta (si no, de lo ancho)",
	"throw_charge_s": "tarda en cargar entero (s)", "throw_lean_deg": "se echa atrás al cargar (°)",
	"throw_draw": "la caja viene al pecho (de la distancia de llevar)", "throw_push_s": "dura el empujón (s)",
	"throw_extend": "las manos la empujan hasta (m más)", "throw_follow_deg": "se va adelante al soltar (°)",
	"throw_per_arm": "tiro: N·s por cada 1 de fuerza de brazos",
	"push_per_arm": "empujón: m/s por cada 1 de fuerza de brazos",
	"interaction_reach": "alcance desde la punta del pecho (m)",
	# Equilibrio.
	"impact_fall_linear": "exageración de la caída (× el empujón)", "landing_brake": "al aterrizar, frena el cuerpo",
	"ragdoll_in_air": "se tira en el aire cayendo rápido", "ragdoll_speed": "a cuánta velocidad de caída (m/s)",
	# Salto.
	"blend_s": "tarda en pasar del piso al aire, y de vuelta (s)",
	"torso_on": "prendido", "legs_on": "prendido", "arms_on": "prendido",
	"torso_apex_deg": "en el aire: inclinación (°; adelante +, atrás −)",
	"torso_fall_s": "cayendo: termina de cambiar (s después de la cima)",
	"torso_fall_deg": "cayendo: inclinación (°; adelante +, atrás −)", "torso_follow_s": "suavizado (s)",
	"legs_still_bend": "quieto en el aire: flexión (0 recta, 1 doblada)",
	"legs_fast_bend": "al despegar y cayendo: flexión (0 recta, 1 doblada)",
	"legs_fall_s": "cayendo: tarda en volver a la de despegar (s después de la cima)",
	"apex_front_deg": "en el aire: adelante (0° colgando, 90° horizontal)",
	"apex_out_deg": "en el aire: afuera (0° pegado, 90° horizontal)", "apex_bend": "en el aire: quiebre (0 recto, 1 doblado)",
	"arms_fall_s": "cayendo: termina de cambiar (s después de la cima)",
	"fall_front_deg": "cayendo: adelante (0° colgando, 90° horizontal)",
	"fall_out_deg": "cayendo: afuera (0° pegado, 90° horizontal)", "fall_bend": "cayendo: quiebre (0 recto, 1 doblado)",
	"jump_squat": "cuánto se agacha al cargar (× el de siempre)", "landing_depth": "cuánto se hunde al aterrizar (× el de siempre)",
	"landing_steps_s": "pasitos cortos: tardan en volver al paso normal (s; 0, sin)",
	# Cuerpo.
	"shoulder_inside": "hombro metido en el torso",
}
const HELP := {
	"blend_s": "Todo lo de EN EL AIRE entra así al despegar y sale así al aterrizar.",
	"arms_fall_s": "En el aire, desde que despega hasta la cima; cayendo, lo de abajo. Caer de 3 m tarda unos 0,8 s.",
	"impact_fall_linear": "Cuántas veces el empujón que recibió sale el que cae. 1 es la física tal cual.",
	"interaction_reach": "Con 1,00 el botón más bajo (a 0,2 m) pide agacharse a los seis. Cambiarlo rearma a todos.",
	"shoulder_inside": "Prendido, la mitad del domo del brazo adentro del torso; apagado, el brazo rozando. Rearma a todos.",
}
## LO DE EN EL AIRE Y LO DE CAYENDO, de dos colores (05/11/2026, el usuario: «hay mucho texto… un color coding»).
const APEX_COLOR := Color(0.8, 0.6, 1.0)
const FALL_COLOR := Color(0.45, 0.9, 0.5)
const AIR_APEX := ["torso_apex_deg", "legs_still_bend", "apex_front_deg", "apex_out_deg", "apex_bend"]
const AIR_FALL := ["torso_fall_deg", "torso_fall_s", "legs_fall_s", "arms_fall_s", "fall_front_deg", "fall_out_deg",
	"fall_bend"]
const UNASSIGNED_COLOR := Color(1.0, 0.35, 0.3)


var _state: Label = null


func setup_panel() -> void:
	var save := TunerPanel.new_button("Guardar todo el panel", func() -> void:
		if _state != null:
			_state.text = "guardado" if LocomotionCommon.store() else "NO SE PUDO GUARDAR")
	setup(UIState.LOCOMOTION, "LO DE TODOS LOS ARQUETIPOS", [save] as Array[Button])
	_state = state_label()


func sections() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var placed := {}
	for each: Array in SECTIONS:
		var knobs: Array = each[3]
		var colors := {}
		for knob: String in knobs:
			placed[knob] = true
			colors[knob] = FALL_COLOR if AIR_FALL.has(knob) else (APEX_COLOR if AIR_APEX.has(knob) else each[2])
		out.append(_section(each[0], each[1], each[2], knobs, colors))
	# LOS QUE NO ESTÁN EN NINGUNA SECCIÓN, en rojo: un número nuevo no puede quedar sin ubicar sin que se vea.
	var loose := []
	for prop in LocomotionCommon.new().get_property_list():
		var field := str(prop["name"])
		if int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE and int(prop["usage"]) & PROPERTY_USAGE_EDITOR \
				and not placed.has(field):
			loose.append(field)
	if not loose.is_empty():
		out.append(_section(LocomotionTuner.TAB_BODY, "SIN SECCIÓN — agregalos a SECTIONS (LocomotionPanel)",
			UNASSIGNED_COLOR, loose, {}))
	return out


func _section(tab: String, title: String, color: Color, knobs: Array, colors: Dictionary) -> Dictionary:
	var rebuilds := false
	for knob: String in knobs:
		rebuilds = rebuilds or REBUILDS.has(knob)
	return {"tab": tab, "title": title, "color": color, "target": LocomotionCommon.base(),
		"only": PackedStringArray(knobs), "headers": false, "labels": LABELS, "help": HELP, "colors": colors,
		"defaults": LocomotionCommon.new(), "on_change": _changed_rebuilding if rebuilds else _dirty}


## TODOS LOS PERSONAJES, rearmados (el hombro y el alcance cambian sus huesos).
func _changed_rebuilding() -> void:
	_dirty()
	for node in get_tree().get_nodes_in_group(CharacterRigidBody3D.CHARACTER_GROUP):
		var bi := (node as Node).get_parent() as BoneInstantiator
		if is_instance_valid(bi) and bi.entity_instantiation != null:
			bi.initialize_skeleton()


## ALGO CAMBIÓ Y NO SE GUARDÓ.
func _dirty() -> void:
	if _state != null:
		_state.text = "probando, sin guardar (Guardar todo el panel lo deja)"
