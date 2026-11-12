class_name ModelClick
extends Node

## CLICK EN EL MODELO PARA ABRIR SUS OPCIONES (20/10/2026, lo pidió el dios del juego). Con un panel F abierto el mouse
## está libre; la PARTE del cuerpo que está debajo del mouse se RESALTA, y un click en ella —no en el panel— abre la
## pestaña de esa parte: las pestañas de los paneles del cuerpo SON estas partes (ver TunerPanel.show_part). Por partes grandes y no por piezas: una costura o
## un botón son muy chicos para apuntarles, así que cuentan como la parte sobre la que están.
##
## El rayo es el del inspector (ver CharacterInspectorSource.aim): contra la piel skinneada, como se ve. La parte sale de
## la malla que tocó (ver `MESH_PARTS`) y, si la malla cruza partes —las costuras y los botones del traje van todos en
## una—, del hueso que más la mueve ahí: una costura del pantalón es la pierna y un botón es el torso.

const TORSO := "torso"
const LEGS := "piernas"
## EL PIE, SU PROPIA PARTE (22/10/2026, lo pidió el dios del juego): clickeándolo se abre su pestaña (ver TorsoTuner).
const FEET := "pies"
const ARMS := "brazos"
const BELT := "cinturón"
const FACE := "cara"
## En el orden de las pestañas (ver TunerPanel): de arriba del cuerpo hacia afuera.
const PARTS: Array[String] = [TORSO, ARMS, LEGS, FEET, BELT, FACE]

## Las mallas del cuerpo y su parte (ver ProceduralBodyUtil). Lo del traje va en dos: el torso («suit») y las piernas
## («suit_legs»); las costuras de los brazos van en el brazo, y la mano también (ver TubeHand).
const MESH_PARTS := {"trunk": TORSO, "left_arm": ARMS, "right_arm": ARMS,
	"left_leg": LEGS,
	"right_leg": LEGS, "left_foot": FEET, "right_foot": FEET, "belt": BELT, "belt_pieces": BELT, "name_text": TORSO, "head": FACE, "features": FACE,
	"neck": FACE, "hair": FACE, "face_hair": FACE, "hat": FACE, "face_wear": FACE, "nose": FACE, "suit": TORSO, "suit_legs": LEGS}

## ── AISLAR UNA PARTE ─────────────────────────────────────────────────────────────────────────────
## La parte que se mira sola, o "" (ver TunerPanel, el tilde de aislar): en todos los personajes de muestra se ven sólo
## sus mallas (ver CharacterBodyVisual.study_parts). Se vuelve a aplicar cada cuadro, porque los paneles rearman los
## cuerpos mientras se mueve un número.
static var isolated := ""
var _studying: Array[CharacterBodyVisual] = []

## Hasta dónde llega el rayo, en metros, y cada cuánto se vuelve a tirar mientras el mouse se mueve.
const REACH := 60.0
const HOVER_EVERY := 0.05
## EL RESALTADO: un velo cálido encima de las mallas de la parte (`material_overlay`, así no toca su material).
const HIGHLIGHT := Color(1.0, 0.82, 0.45, 0.28)

var _source := CharacterInspectorSource.new()
var _overlay: StandardMaterial3D = null
var _body: CharacterBodyVisual = null
var _part := ""
## La cinta bajo el mouse: su malla y su anillo (ver `mark_under`), o null y −1.
var _ring_mesh: MeshInstance3D = null
var _ring := -1
var _lit: Array[MeshInstance3D] = []
var _wait := 0.0
var _mouse := Vector2(-1.0, -1.0)


func _ready() -> void:
	_overlay = StandardMaterial3D.new()
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay.albedo_color = HIGHLIGHT
	_overlay.no_depth_test = false


func _process(delta: float) -> void:
	_isolate()
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE or _open_panels().is_empty():
		_hover(null, "")
		return
	_wait -= delta
	var mouse := get_viewport().get_mouse_position()
	if _wait > 0.0 or mouse == _mouse:
		return
	_wait = HOVER_EVERY
	_mouse = mouse
	_aim(mouse)


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return
	var panels := _open_panels()
	if panels.is_empty():
		return
	_aim(click.position)
	if _part.is_empty():
		return
	# ── UN CLICK EN UN LOOP CUT ABRE SU SECCIÓN (22/10/2026, lo pidió el dios del juego) ───────────────────────────────
	# Si cae cerca de una cinta de color (ver `mark_under`, con un margen: una línea es difícil de acertar), la pestaña
	# de su parte, scrolleada hasta la sección de ese color; si no, la pestaña.
	var mark := mark_under()
	for panel in panels:
		if mark.a < 0.0 or not panel.show_loop(_part, true_color(mark)):
			panel.show_part(_part)
	get_viewport().set_input_as_handled()


## EL COLOR DE UNA VUELTA sin desteñir: una apagada se pinta destiñida `IDLE_FADE` hacia el gris (era del F1 del torso,
## borrado el 07/11/2026 con la malla vieja).
static func true_color(color: Color) -> Color:
	if color.a >= 0.99:
		return color
	var grey := Color(0.55, 0.55, 0.55)
	var keep := 1.0 - IDLE_FADE
	return Color((color.r - grey.r * IDLE_FADE) / keep, (color.g - grey.g * IDLE_FADE) / keep,
		(color.b - grey.b * IDLE_FADE) / keep, 1.0)


## Cuánto se destiñe una vuelta apagada.
const IDLE_FADE := 0.6


## EL MARGEN DE UNA CINTA para el click, en fracción del tamaño de su malla: un poco más ancha que lo que se dibuja (ver
## QuadWire.MARK_SHARE).
const PICK_SHARE := 0.03


## LA CINTA DE COLOR MÁS CERCANA al punto del último rayo, si está a menos de `PICK_SHARE`; si no, un color de alfa
## negativo. Mira las aristas de la malla que el alambre pintó como cinta (las de un mismo anillo marcado).
func mark_under() -> Color:
	var none := Color(0.0, 0.0, 0.0, -1.0)
	_ring = -1
	_ring_mesh = null
	var m := _source.hit_mesh()
	var wire := QuadWire.of(m)
	if m == null or wire == null or m.mesh == null:
		return none
	var marks: Dictionary = wire.get_meta(QuadWire.MARKS, {})
	var edges: PackedInt32Array = m.get_meta(ProceduralBodyUtil.GRID_EDGES_META, PackedInt32Array())
	var rings: PackedInt32Array = m.get_meta(ProceduralBodyUtil.VERTEX_RING_META, PackedInt32Array())
	var columns: PackedInt32Array = m.get_meta(ProceduralBodyUtil.VERTEX_COLUMN_META, PackedInt32Array())
	var skinned := _source.hit_skinned()
	if marks.is_empty() or rings.is_empty() or skinned.is_empty():
		return none
	var point := _source.hit_point()
	var best: float = m.mesh.get_aabb().size.length() * PICK_SHARE
	var found := none
	for e in edges.size() / 2:
		var p: int = edges[e * 2]
		var q: int = edges[e * 2 + 1]
		if p >= rings.size() or q >= rings.size() or p >= skinned.size() or q >= skinned.size():
			continue
		if rings[p] != rings[q] or not marks.has(rings[p]):
			continue
		if not columns.is_empty() and (columns[p] < 0 or columns[q] < 0):
			continue
		var on := Geometry3D.get_closest_point_to_segment(point, skinned[p], skinned[q])
		var distance := on.distance_to(point)
		if distance < best:
			best = distance
			found = marks[rings[p]]
			_ring = rings[p]
			_ring_mesh = m
	return found


## Tira el rayo por ese punto de la pantalla y resalta lo que toque.
func _aim(at: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		_hover(null, "")
		return
	var from := camera.project_ray_origin(at)
	if _source.aim(get_tree(), from, from + camera.project_ray_normal(at) * REACH) == null:
		_hover(null, "")
		return
	_hover(_source.hit_body(), section_of(_source.hit_mesh_name(), _source.hit_bone_name()))
	# O UNA CINTA, O LA PARTE (lo pidió el dios del juego): cerca de un loop cut se resalta ese y no la parte.
	mark_under()
	if _ring >= 0:
		_unlight_part()
	_light_ring()


## RESALTA LA CINTA que dejó `mark_under`, y apaga la de antes.
var _lit_ring_mesh: MeshInstance3D = null


func _light_ring() -> void:
	var mesh := _ring_mesh if _ring >= 0 else null
	if is_instance_valid(_lit_ring_mesh) and _lit_ring_mesh != mesh:
		QuadWire.hover(_lit_ring_mesh, -1)
	_lit_ring_mesh = mesh
	if mesh != null:
		QuadWire.hover(mesh, _ring)


## Apaga el velo de la parte, sin olvidarla: el click la sigue usando para elegir la pestaña.
func _unlight_part() -> void:
	for m in _lit:
		if is_instance_valid(m) and m.material_overlay == _overlay:
			m.material_overlay = null
	_lit.clear()


## RESALTA UNA PARTE de un cuerpo (null o "": nada), y apaga la de antes.
func _hover(body: CharacterBodyVisual, part: String) -> void:
	if body == null or part.is_empty():
		_ring = -1
		_light_ring()
	if body == _body and part == _part and not _lit.is_empty() \
			and _lit.all(func(m: MeshInstance3D) -> bool: return is_instance_valid(m)):
		return
	for m in _lit:
		if is_instance_valid(m) and m.material_overlay == _overlay:
			m.material_overlay = null
	_lit.clear()
	_body = body
	_part = part
	if body == null or part.is_empty():
		return
	for m in body.meshes:
		if is_instance_valid(m) and MESH_PARTS.get(String(m.name), "") == part:
			m.material_overlay = _overlay
			_lit.append(m)


## AÍSLA `isolated` en los personajes de muestra, o los devuelve enteros.
func _isolate() -> void:
	if isolated.is_empty():
		for body in _studying:
			if is_instance_valid(body):
				body.show_all_parts()
		_studying.clear()
		return
	var keep: Array = []
	for mesh_name: String in MESH_PARTS:
		if MESH_PARTS[mesh_name] == isolated:
			keep.append(mesh_name)
	var names := PackedStringArray(keep)
	for rb in get_tree().get_nodes_in_group(CharacterRigidBody3D.CHARACTER_GROUP):
		var bi := (rb as Node).get_parent() as BoneInstantiator
		if not is_instance_valid(bi) or not bi.kind.is_exhibit() or not is_instance_valid(bi.body_visual):
			continue
		var body := bi.body_visual
		# Un cuerpo rearmado trae mallas nuevas, que nacen visibles: la regla se vuelve a aplicar.
		if body.studied != names:
			body.study_parts(names)
		else:
			body.refresh_parts()
		if not _studying.has(body):
			_studying.append(body)


## Los paneles abiertos que saben de partes (ver TunerPanel.has_parts).
func _open_panels() -> Array[TunerPanel]:
	var out: Array[TunerPanel] = []
	for child in get_parent().get_children():
		var panel := child as TunerPanel
		if panel != null and panel.visible and panel.has_parts():
			out.append(panel)
	return out


## LA PARTE de lo que tocó el rayo: por su malla y, si la malla cruza partes, por su hueso.
static func section_of(mesh_name: String, bone_name: String) -> String:
	if MESH_PARTS.has(mesh_name):
		return MESH_PARTS[mesh_name]
	var bone := bone_name.to_lower()
	for word in ["head", "neck", "jaw", "eye"]:
		if bone.contains(word):
			return FACE
	for word in ["arm", "hand", "finger", "thumb", "wrist"]:
		if bone.contains(word):
			return ARMS
	for word in ["foot", "toe"]:
		if bone.contains(word):
			return FEET
	for word in ["leg", "knee", "ankle"]:
		if bone.contains(word):
			return LEGS
	return TORSO
