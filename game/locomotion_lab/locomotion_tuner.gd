class_name LocomotionTuner
extends TunerPanel

## ── LA LOCOMOCIÓN DE CADA ARQUETIPO (03/11/2026, lo pidió el dios del juego) ─────────────────────────────────────────
## «Un panel para cambiar animaciones de caminata de cada personaje y pose. Velocidad, estabilidad, fuerza de salto, todas
## las variantes de locomoción y animación, pero que estén bien separadas, así no se mezclan tantas cosas a la vez.»
## Por arquetipo y guardado; un panel, cinco pestañas, una a la vez:
##   · CAMINATA: el andar del arquetipo (PoseShape, grupo Caminata), todo suyo.
##   · POSE: la postura (PoseShape, grupo Pose) y los modificadores de pose que lleva (WalkModifier).
##   · MOVIMIENTO: la velocidad de caminar, de costado y para atrás, el sprint, la aceleración.
##   · EQUILIBRIO: el peso, la estabilidad de cada lado, el resorte, la caída desde altura, el levantarse.
##   · SALTO: la altura y la carga.
##   · EN EL AIRE: cuánto recoge las piernas, cómo aterriza y cuánto se agacha al cargar el salto.
##   · CUERPO: las medidas de la forma de bloques —largos, anchos y grosores de piernas, torso, brazos, cuello, cabeza y
##     pies— (ver BlockShape).
## Todo es la misma capa (PoseShapes): se prueba en vivo —los de ese arquetipo se rearman al soltar la perilla— y
## «Guardar» la escribe en `pose_shapes_low.tres`. *Traído de character-parametric el 13/11/2026: es el F3 de las filas
## Locomoción y Personajes.* *Reemplaza a la caminata base del F3 de la fila Personajes
## (WalkStyleTuner) y a la pestaña de pose y andar del F1 del torso (TorsoTuner), borrados el 03/11/2026.*

const TAB_WALK := "CAMINATA"
const TAB_POSE := "POSE"
const TAB_MOVE := "MOVIMIENTO"
const TAB_BALANCE := "EQUILIBRIO"
const TAB_JUMP := "SALTO"
## LAS MEDIDAS DEL CUERPO (03/11/2026, lo pidió el dios del juego: «dimensiones del cuerpo, grosores de extremidades»):
## la forma de bloques del arquetipo (BlockShape: largos, anchos, grosores), la misma que se guarda en BlockShapes. Era
## el F1 de la fila Personajes (BlockPanel), que se fue para no tener dos paneles de lo mismo.
const TAB_BODY := "CUERPO"

## ── LOS NOMBRES Y LAS AYUDAS, POR PARTE DEL CUERPO (07/11/2026, el dios del juego: «varias opciones… no están bien
## descritas… balanceo lateral, no dice de qué… muchas cosas que están mal clasificadas»; «color coding… torso, brazos,
## piernas… por subsecciones»; «preferiría que me las describas con los nombres de los huesos reales… lower spine,
## higher spine, chest… esto va para todo») ─────────────────────────────────────────────────────────────────────────
## Cada nombre dice QUÉ PARTE se mueve y CÓMO; la ayuda, QUÉ HUESOS mueve, con su nombre de CustomBonesUtil, y hacia
## dónde (de costado, adelante y atrás, girando). Los que eran de todos van aparte (`WALK_LABELS`), con `walk_`
## adelante (ver EntityArchetype, EL ANDAR QUE ERA DE TODOS).
const LABELS := {
	# La postura (parado).
	"slouch": "cabeza adelante (neck)", "spine_bend": "espalda curvada (chest y lower_spine)",
	"shoulders_forward": "hombros: + adelante / − atrás", "shoulders_drop": "hombros caídos (− levantados)",
	"arm_bentness": "codos flexionados",
	"tremor": "temblor", "breath_depth": "respiración honda", "breath_rate": "respiración rápida",
	"leg_bentness": "rodillas flexionadas", "stance_width": "separación de los pies",
	# El andar.
	"stride_reach": "largo del paso", "step_height": "altura del pie al pisar", "root_bounciness": "se hunde al pisar",
	"shoulder_swing": "hombros que suben y bajan", "arm_swing": "braceo",
	# El resto de las pestañas.
	"speed": "velocidad de caminar", "back_speed_factor": "para atrás (× caminar)",
	"lateral_speed_factor": "de costado (× caminar)", "sprint_multiplier": "corriendo (× caminar)",
	"acceleration": "aceleración", "strength": "fuerza (al llevar algo)", "throw_strength": "fuerza de tiro (y del empujón)",
	"weight": "peso (kg)", "forward_stability": "estabilidad adelante", "backwards_stability": "estabilidad atrás",
	"sideways_stability": "estabilidad de costado", "stability_spring": "qué tan duro se endereza",
	"stability_damp": "cuánto frena el rebote", "landing_tolerance": "aterrizaje que lo tumba (m/s)",
	"time_to_standup": "tarda en levantarse (s)",
	"jump_height": "altura del salto entero (m)", "time_to_max_jump": "tarda en cargarlo (s)",
}

const HELP := {
	"slouch": "Inclina neck adelante y head lo sigue: la cabeza se adelanta. Sólo el cuello. A fondo, un cuarto de vuelta.",
	"spine_bend": "Inclina chest adelante y lower_spine atrás, de contrapeso. higher_spine no se mueve. Deforma el torso.",
	"shoulders_forward": "Gira left_shoulder y right_shoulder: + adelante (encorvado), − atrás (pecho abierto).",
	"shoulders_drop": "Gira left_shoulder y right_shoulder: + caídos (vencido), − levantados (encogido).",
	"arm_bentness": "Parado, cuánto se dobla el codo entre upper_arm y lower_arm: 0 casi recto, 1 bien doblado.",
	"leg_bentness": "Parado, baja lower_spine (la pelvis) y las rodillas se doblan entre higher_leg y lower_leg para que el foot quede en el piso: 0 casi rectas, 1 bien flexionadas.",
	"tremor": "Todo el cuerpo tiembla: un giro mínimo de la raíz, y encima los brazos y el torso, cada parte un poco a destiempo. Los pies no. 1 es el doble del temblor más fuerte de antes.",
	"breath_depth": "Cuánto se abre el pecho al respirar: chest y higher_spine atrás, neck compensa. No cambia el ritmo. 1 es ×5 de lo normal.",
	"breath_rate": "Respira más seguido, sin respirar más hondo: nervioso, agitado. Corriendo se acelera igual encima. 1 es ×3,8 de lo normal.",
	"stance_width": "Dónde se paran los foot, en anchos de cadera: 1 es un pie bajo cada left_hip / right_hip.",
	"stride_reach": "Qué tan lejos de la cadera pisa el foot corriendo a fondo, en largos de pierna; higher_leg y lower_leg lo siguen. Más despacio, el paso se acorta solo.",
	"step_height": "Cuánto sube el foot en el aire: bajo arrastra los pies, alto marcha.",
	"root_bounciness": "Cuánto baja lower_spine —y con él todo lo de arriba— al pisar cada pie: de golpe a la mitad, sigue bajando un poco y vuelve antes de la mitad del paso. 1 es la de referencia, 0 nada.",
	"shoulder_swing": "Inclina left_shoulder y right_shoulder (eje Z): suben y bajan juntos con el paso y se alternan de un lado al otro. Sólo los hombros: el braceo es otra perilla.",
	"arm_swing": "El brazo gira en el hombro adelante y atrás, contrario a la pierna de su lado. upper_arm y lower_arm guardan el doblez del codo todo el braceo, y el codo apunta siempre para el mismo lado. Cuánto se abre del cuerpo es otra perilla («brazo que se abre del cuerpo»).",
	"speed": "La velocidad de caminar, en la escala del arquetipo (× 10 m/s).",
	"acceleration": "Cuánto tarda en llegar a su velocidad: × su peso, así no cambia con el peso.",
	"weight": "Cuánto cuesta moverlo: en un choque, el liviano se lleva el cambio de velocidad. Con la estabilidad es la firmeza, que divide lo que lo inclinan los golpes y la inercia.",
	"landing_tolerance": "El golpe vertical al aterrizar que lo tumba. 9 es caer de unos 4 m; por debajo, el rebote de siempre.",
	"jump_height": "Lo que sube con el salto cargado entero; un toque sin cargar sube el 30 %.",
}

## LO QUE ERA DE TODOS, AHORA DE CADA ARQUETIPO (ver EntityArchetype, EL ANDAR QUE ERA DE TODOS).
const WALK_LABELS := {
	"walk_stride_growth": "el paso se alarga al ir más rápido", "walk_swing_share": "tiempo del pie en el aire",
	"walk_lead": "pisa adelante de la cadera", "walk_bounce_up": "pelvis que sube al despegar",
	"walk_hip_sway": "cadera que se mece de costado", "walk_twist": "columna que gira contra las piernas",
	"walk_spine_bow": "columna que se arquea de costado",
	"walk_spine_roll": "lower_spine que se inclina por el ancho de los pies", "walk_lean": "inclinación con la velocidad",
	"walk_posture_lean": "todo el cuerpo tirado adelante (+) o atrás (−)", "walk_run_elbow": "codo al correr",
	"walk_arm_open": "brazo que se abre del cuerpo",
}

const WALK_HELP := {
	"walk_stride_growth": "0: el mismo paso a cualquier velocidad (corriendo, sólo pasos más seguidos). 1: los mismos pasos por segundo y el paso se alarga.",
	"walk_swing_share": "Qué parte de cada ciclo pasa el foot sin tocar el piso. Más, pasos más flotados.",
	"walk_lead": "Cuánto adelante de la cadera apoya el foot, en pasos.",
	"walk_bounce_up": "Al despegar un pie, lower_spine sube un poco, en largos de pierna (lo que dejan las piernas apoyadas).",
	"walk_hip_sway": "Inclina left_hip y right_hip (eje Z) con cada paso. Sólo la cadera.",
	"walk_twist": "Gira lower_spine, higher_spine y chest al revés que las piernas cada uno lo mismo, y left_hip / right_hip acompañan un poco. Todo el giro de la columna.",
	"walk_spine_bow": "El arco de costado con cada paso: lower_spine se inclina para un lado y higher_spine y chest para el otro.",
	"walk_spine_roll": "lower_spine se inclina de costado según cuánto se separan los pies a lo ancho; más al correr y de costado.",
	"walk_lean": "Inclina lower_spine —y todo lo de arriba— hacia donde va: adelante al avanzar, de costado al ir de costado (− al revés).",
	"walk_posture_lean": "Inclina lower_spine adelante (+) o atrás (−), quieto o caminando, en radianes; las piernas siguen plantadas.",
	"walk_arm_open": "En los extremos de cada paso el brazo gira en el hombro hacia afuera, más corriendo: 0 nada, 1 lo de siempre. No depende del braceo.",
	"walk_run_elbow": "Cuánto más se dobla el codo corriendo: la mano se acerca al hombro (entre upper_arm y lower_arm). Nada hasta su velocidad de caminar y entero a su sprint.",
}

## ── QUÉ USA CADA PERILLA (07/11/2026, el dios del juego: «diferenciar bien… las cosas que usan el ancho entre pies y las
## que usan la profundidad… tal vez con un símbolo… si les hago hover, me dice qué usa para crear la animación») ──────
## Un símbolo en blanco a la derecha del nombre de cada perilla de la caminata (blanco, para que no se confunda con el color de la parte), y al pasar el mouse, qué la mueve. Sin colores nuevos:
## los colores ya son las partes del cuerpo. Sale del código de BoneAnimations: `foot_spread_unified.y` es el largo (un
## pie delante del otro), `.x` el ancho (los pies abiertos a los lados).
const MARKS := {
	"length": ["↕", "largo del paso", "Se mueve con el largo del paso: cuánto está un pie delante del otro. Caminando de frente es lo máximo; corriendo de costado casi no se mueve."],
	"width": ["↔", "ancho del paso", "Se mueve con el ancho del paso: cuánto se abren los pies a los lados. De frente casi nada; corriendo de costado, lo máximo."],
	"both": ["↕↔", "los dos", "Se mueve con el largo del paso (un pie delante del otro) y con el ancho (los pies abiertos a los lados): de frente y de costado."],
	"speed": ["»", "velocidad", "No mira los pies: se mueve con qué tan rápido va."],
	"makes": ["◇", "arma el paso", "No lee el paso: lo hace. Es cómo se mueven las piernas y la pelvis al caminar."],
	"fixed": ["●", "fija", "No se mueve con nada: es una postura, quieto o caminando."],
}
const KNOB_MARKS := {
	"arm_swing": "length", "walk_arm_open": "length", "walk_twist": "length", "walk_spine_bow": "length",
	"walk_spine_roll": "width",
	"walk_hip_sway": "both", "shoulder_swing": "both",
	"walk_lean": "speed", "walk_run_elbow": "speed",
	"stride_reach": "makes", "step_height": "makes", "walk_stride_growth": "makes", "walk_swing_share": "makes",
	"walk_lead": "makes", "root_bounciness": "makes", "walk_bounce_up": "makes",
}


## LAS PARTES DEL CUERPO, de arriba abajo, cada una con su color: el título de su sección, sus nombres y sus ayudas van
## de ese color, en la postura y en el andar. Por parte: las perillas de la postura y las del andar, todas del arquetipo.
const PARTS := [
	{"name": "CABEZA Y CUELLO — neck, head", "color": Color(0.45, 0.85, 0.85), "pose": ["slouch"], "walk": []},
	{"name": "HOMBROS Y BRAZOS — shoulder, upper_arm, lower_arm", "color": Color(0.96, 0.58, 0.72),
		"pose": ["shoulders_forward", "shoulders_drop", "arm_bentness"],
		"walk": ["shoulder_swing", "arm_swing", "walk_arm_open", "walk_run_elbow"]},
	{"name": "TORSO — lower_spine, higher_spine, chest", "color": Color(0.56, 0.74, 1.0),
		"pose": ["spine_bend", "walk_posture_lean"], "walk": ["walk_twist", "walk_spine_bow", "walk_spine_roll", "walk_lean"]},
	{"name": "PELVIS Y CADERA — lower_spine, left_hip, right_hip", "color": Color(0.78, 0.64, 1.0), "pose": [],
		"walk": ["root_bounciness", "walk_hip_sway", "walk_bounce_up"]},
	{"name": "PIERNAS — higher_leg, lower_leg, foot", "color": Color(0.52, 0.86, 0.6),
		"pose": ["leg_bentness", "stance_width"],
		"walk": ["stride_reach", "step_height", "walk_stride_growth", "walk_swing_share", "walk_lead"]},
	{"name": "QUIETO — respira y tiembla (chest, higher_spine, neck; todo el cuerpo)", "color": Color(0.95, 0.8, 0.5),
		"pose": ["breath_depth", "breath_rate", "tremor"], "walk": []},
]
## El gris de los títulos que no son de una parte.
const NOTE_COLOR := Color(0.62, 0.66, 0.72)

## Los arquetipos que se eligen: todos menos el genérico (el dios del juego no lo quiere ver).
var _archetype := EntityArchetype.Archetype.fat_man
var _pose: PoseShape = null
var _base_pose: PoseShape = null
var _code_pose: PoseShape = null
var _block: BlockShape = null
var _block_dirty := false
var _state: Label = null
var _settle := 0.0
const SETTLE_S := 0.15


func setup_panel() -> void:
	var save := new_button("Guardar este arquetipo", _save)
	var forget := new_button("Olvidar lo guardado (volver al código)", _forget)
	setup(UIState.LOCOMOTION_TUNING, "LOCOMOCIÓN", [save, forget] as Array[Button])
	_state = state_label()
	_adopt()


func sections() -> Array[Dictionary]:
	if _pose == null:
		_adopt()
	var labels := LABELS.duplicate()
	labels.merge(WALK_LABELS)
	var help := HELP.duplicate()
	help.merge(WALK_HELP)
	var tooltips := {}
	var marks := {}
	for knob: String in KNOB_MARKS:
		var mark: Array = MARKS[KNOB_MARKS[knob]]
		marks[knob] = mark[0]
		tooltips[knob] = "%s  %s" % [mark[0], mark[2]]
	var common := {"target": _pose, "labels": labels, "help": help, "defaults": _base_pose,
		"code_defaults": _code_pose, "on_change": _changed, "tooltips": tooltips,
		"marks": marks}
	var out: Array[Dictionary] = []
	out.append({"tab": TAB_WALK, "title": _legend(), "color": NOTE_COLOR})
	# LA CAMINATA Y LA POSTURA, UNA SECCIÓN POR PARTE (ver PARTS, UNA PARTE ES UNA SECCIÓN), todo del arquetipo.
	for part: Dictionary in PARTS:
		out.append_array(_part_section(part, TAB_WALK, [[common, "walk", ""]]))
	for part: Dictionary in PARTS:
		out.append_array(_part_section(part, TAB_POSE, [[common, "pose", ""]]))
	out.append_array(_unassigned(common))
	for each: Array in [[TAB_MOVE, PoseShape.MOVE_GROUP, "CÓMO SE MUEVE %s"],
			[TAB_BALANCE, PoseShape.BALANCE_GROUP, "EL EQUILIBRIO de %s"], [TAB_JUMP, PoseShape.JUMP_GROUP, "EL SALTO de %s"]]:
		var section := common.duplicate()
		section["tab"] = each[0]
		section["title"] = str(each[2]) % _name()
		section["include"] = PackedStringArray([each[1]])
		out.append(section)
	for group: String in BlockShape.GROUPS:
		out.append({"tab": TAB_BODY, "title": "%s de %s" % [group.to_upper(), _name()], "target": _block,
			"include": PackedStringArray([group]), "labels": BlockShape.LABELS, "on_change": _block_changed})
	return out


## La leyenda de los símbolos, arriba de la caminata.
static func _legend() -> String:
	var out := PackedStringArray()
	for key: String in MARKS:
		out.append("%s %s" % [MARKS[key][0], MARKS[key][1]])
	return "   ".join(out) + "   — pasá el mouse por un nombre"


## ── UNA PARTE ES UNA SECCIÓN (07/11/2026, el dios del juego: «cuando agregaste más opciones se separaron en dos
## subcategorías separadas, aunque tiene el mismo título… que eso no sea posible por diseño… si agrego una opción, tengo
## que sí o sí ponerlo en su categoría y sí o sí queda junto a las otras») ─────────────────────────────────────────
## Cada parte del cuerpo da UNA sola sección por pestaña, con un título y un color, y adentro un bloque por objeto
## —lo del arquetipo, lo de todos— con un renglón chico que dice de quién es (ver TunerPanel, `blocks`). Lo que decide
## dónde va una perilla es su lista en PARTS y nada más: no hay otra forma de ponerla en el panel.
static func _part_section(part: Dictionary, tab: String, sources: Array) -> Array[Dictionary]:
	var color: Color = part["color"]
	var blocks: Array[Dictionary] = []
	for source: Array in sources:
		var knobs: Array = part[source[1]]
		if knobs.is_empty():
			continue
		var colors := {}
		for knob: String in knobs:
			colors[knob] = color
		var block: Dictionary = (source[0] as Dictionary).duplicate()
		if not str(source[2]).is_empty():
			block["caption"] = source[2]
		block["only"] = PackedStringArray(knobs)
		block["colors"] = colors
		block["headers"] = false
		blocks.append(block)
	if blocks.is_empty():
		return []
	return [{"tab": tab, "title": part["name"], "color": color, "blocks": blocks}] as Array[Dictionary]


## LAS PERILLAS SIN PARTE: las de la caminata y la postura (PoseShape) que no están en ninguna lista de PARTS. Van en
## rojo, al final de CAMINATA, para que una perilla nueva no pueda quedar sin ubicar sin que se vea.
const UNASSIGNED_COLOR := Color(1.0, 0.35, 0.3)


static func _unassigned(common: Dictionary) -> Array[Dictionary]:
	var placed := {}
	for part: Dictionary in PARTS:
		for which: String in ["walk", "pose"]:
			for knob: String in part[which]:
				placed[knob] = true
	var loose := PackedStringArray()
	for knob: String in PoseShape.WALK_KNOBS + PoseShape.POSE_KNOBS:
		if not placed.has(knob):
			loose.append(knob)
	if loose.is_empty():
		return []
	var block: Dictionary = common.duplicate()
	block["only"] = loose
	block["headers"] = false
	return [{"tab": TAB_WALK, "title": "SIN PARTE — agregalas a una lista de PARTS (LocomotionTuner)",
		"color": UNASSIGNED_COLOR, "blocks": [block] as Array[Dictionary]}] as Array[Dictionary]


## ── LA CABECERA (07/11/2026, el dios del juego: «que el arquetipo sea como tabs en vez de una lista vertical y que se
## resalte mejor cuál es el que está seleccionado») ─────────────────────────────────────────────────────────────────
## Arriba de las pestañas de tema: los arquetipos en fila, el elegido pintado. *Un rato hubo también un slider de
## suavizado de cadera y un selector de rebote de pelvis, para todos; quedó lo elegido, fijo (ver BoneInstantiator, LA
## PELVIS, EN DOS CAPAS).*
const PICKED_COLOR := Color(0.95, 0.72, 0.2)


func header() -> Array[Control]:
	var tabs := HFlowContainer.new()
	for value: int in EntityArchetype.Archetype.values():
		if value == EntityArchetype.Archetype.generic:
			continue
		var at := value
		var button := new_button(str(EntityArchetype.Archetype.keys()[value]).replace("_", " "), func() -> void: _pick(at))
		button.focus_mode = Control.FOCUS_NONE
		if value == int(_archetype):
			_paint_picked(button)
		tabs.add_child(button)
	return [tabs, HSeparator.new()] as Array[Control]


## EL ELEGIDO: fondo del color, letra oscura, en todos sus estados.
static func _paint_picked(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PICKED_COLOR
	style.set_corner_radius_all(3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color(0.08, 0.08, 0.1))


func _name() -> String:
	return str(EntityArchetype.Archetype.keys()[int(_archetype)])


func _pick(archetype: int) -> void:
	_archetype = archetype as EntityArchetype.Archetype
	_adopt()
	rebuild()


## LO QUE HAY: el código del arquetipo con lo guardado (o lo que se está probando) encima.
func _adopt() -> void:
	_pose = _default_pose()
	_code_pose = _pose.copy()
	ShapeLayer.apply(_pose, PoseShapes.layer_for(int(_archetype)))
	_base_pose = _pose.copy()
	# EL CUERPO: el que tiene puesto, o el de fábrica, copiado (ver BlockShapes).
	var live := BlockShapes.for_archetype(int(_archetype))
	if live == null:
		live = BlockShape.factory(int(_archetype))
	_block = live.copy() if live != null else BlockShape.new()
	_block_dirty = false
	_refresh_state()


## UNA MEDIDA MOVIDA: el cuerpo pasa a mandar para el arquetipo (sin guardar todavía) y se rearman al quedarse quietos.
func _block_changed() -> void:
	BlockShapes.set_for(int(_archetype), _block)
	_block_dirty = true
	_settle = SETTLE_S
	_refresh_state()


## Lo que dice el CÓDIGO para el arquetipo, sin capa (ver EntityArchetype.create).
func _default_pose() -> PoseShape:
	return PoseShape.from_archetype(EntityArchetype.create(_archetype, false))


## UN NÚMERO MOVIDO: a la capa de prueba, y los de ese arquetipo se rearman al quedarse quieto.
func _changed() -> void:
	PoseShapes.preview[int(_archetype)] = ShapeLayer.of(_pose, _default_pose())
	_settle = SETTLE_S
	_refresh_state()


func _process(delta: float) -> void:
	if _settle <= 0.0:
		return
	_settle -= delta
	if _settle <= 0.0:
		_rebuild_characters()


## LOS DE ESTE ARQUETIPO, rearmados con lo de ahora (donde están, sentados si lo estaban).
func _rebuild_characters() -> void:
	for node in get_tree().get_nodes_in_group(CharacterRigidBody3D.CHARACTER_GROUP):
		var bi := (node as Node).get_parent() as BoneInstantiator
		if is_instance_valid(bi) and bi.entity_instantiation != null \
				and int(bi.entity_instantiation.archetype_type) == int(_archetype):
			bi.initialize_skeleton()


func _save() -> void:
	var ok := PoseShapes.store(int(_archetype), _pose, _default_pose())
	if _block_dirty:
		ok = BlockShapes.store() and ok
		_block_dirty = false
	_refresh_state("guardado" if ok else "NO SE PUDO GUARDAR")


func _forget() -> void:
	PoseShapes.forget(int(_archetype))
	# El cuerpo se olvida en memoria: queda «sin guardar» hasta que Guardar lo escriba (ver BlockShapes.store).
	var had_body := BlockShapes.for_archetype(int(_archetype)) != null
	BlockShapes.forget(int(_archetype))
	_adopt()
	_block_dirty = had_body
	_refresh_state()
	_rebuild_characters()
	rebuild()


func _refresh_state(note := "") -> void:
	if _state == null:
		return
	var what := "lo del código"
	if PoseShapes.preview.has(int(_archetype)) or _block_dirty:
		what = "PRUEBA SIN GUARDAR"
	elif PoseShapes.is_saved(int(_archetype)):
		what = "guardado"
	if not note.is_empty():
		what = "%s · %s" % [note, what]
	_state.text = "%s: %s" % [_name(), what]
