class_name MechShield
extends Node3D

## EL ESCUDO DE FUERZA (18/11/2026; el diseño, docs/conceptual/armamento.md, «El escudo de fuerza»; el usuario: «el del
## escudo, que tiene que estar en todos»). UNO SOLO, GLOBAL: un campo semitransparente que envuelve a toda la meca
## mientras se mantiene `held` (el botón ESCUDO del de arriba, o la Q poseyéndola o en el modo manejo):
##   · PRENDERLO GASTA UN GOLPE DE ENERGÍA (`START_COST`), al apretar, y mantenerlo un poco más por segundo
##     (`HOLD_COST`). Sin energía para prenderlo, no prende (hay que volver a apretar); si se vacía manteniéndolo, se
##     apaga y la meca queda aturdida, como siempre (MechEnergy).
##   · FRENA TODO GOLPE: quien pega pregunta si se le puede pegar (HitReaction.land → ToolMech.untouchable) y, con el
##     escudo, no; y avisa el golpe frenado una vez por golpe (ToolMech.block_hit → `stopped`).
##   · EL PARRY: el primer golpe frenado hasta `PARRY` s después de prenderlo devuelve lo que costó prenderlo («así no
##     castiga tanto»).
## SE VE el campo (mech_shield.gdshader), que aparece y se apaga, con un destello en cada golpe frenado. CÓMO SE VE está
## en prueba (`look`, 18/11/2026; el usuario: «no me gusta para nada cómo se ve… una esfera… más low poly… un shader
## interesante en vez de un color plano… muy sutil»; las maquetas, tests/shield_looks_look).

const START_COST := 0.12
const HOLD_COST := 0.2
const PARRY := 0.3
const TINT := Color(0.45, 0.8, 1.0)
## El campo entero: su centro desde la meca y su tamaño (m), de los pies a lo alto de la torre y de brazo a brazo.
const CENTER := Vector3(0.0, -0.2, 0.0)
const SIZE := Vector3(7.4, 9.0, 6.0)
## El campo sólo del torso: la caja con lo de arriba (en la de 3, hasta la torre).
const TORSO_CENTER := Vector3(0.0, 0.7, 0.0)
const TORSO_SIZE := Vector3(5.0, 5.6, 5.0)
const SHADER := preload("res://game/tool_mech/mech_shield.gdshader")
const BODY_SHADER := preload("res://game/tool_mech/mech_shield_body.gdshader")
## El golpe frenado, en los estilos pegados: el anillo crece a `HIT_SPEED` m/s y se apaga en `HIT_TIME` s.
const HIT_SPEED := 4.0
const HIT_TIME := 0.7
## El de frente: un panel curvo delante del torso (m): su radio, cuánto abre a cada lado (°), de dónde a dónde de alto.
const PANEL_RADIUS := 2.9
const PANEL_OPEN := 55.0
const PANEL_LOW := -2.4
const PANEL_HIGH := 2.2

## CÓMO SE VE: `style`, de dónde sale:
##   · "burbuja": una esfera; `torso` (sólo el torso, si no la meca entera), `facets` (−1, lisa; 0 a 2, low poly: el
##     icosaedro subdividido), `lines` (las aristas marcadas).
##   · "cuerpo": PEGADO AL CUERPO, una cáscara un poco más grande que cada pieza de afuera (`grow`, m), como el de Halo o
##     el Pulse Armor de Armored Core 6: no ocupa lugar ni deja nada afuera. El golpe lo enciende donde pegó.
##   · "frente": UNA PANTALLA CURVA delante del torso, que gira e inclina con él, como la de Reinhardt (Overwatch). Cambia
##     la regla de que es global: atrás no cubre.
## `center` y `rim`: lo visible donde se lo mira de frente y en el borde. Lo de hoy, la burbuja plana.
var look := {"style": "burbuja", "torso": false, "facets": -1, "center": 0.16, "rim": 0.16, "lines": 0.0,
	"grow": 0.06}

## Lo que se pide: mantenido.
var held := false
## Si está prendido.
var on := false
var energy: MechEnergy = null
var _held_was := false
var _since := 0.0
var _refunded := false
var _field: MeshInstance3D = null
var _paint: ShaderMaterial = null
var _body_paint: ShaderMaterial = null
var _skin: Array[GeometryInstance3D] = []
var _skin_on := false
var _panel: MeshInstance3D = null
var _hit_t := 99.0
var _shown := 0.0
var _flash := 0.0


func _ready() -> void:
	name = "Escudo"
	_field = MeshInstance3D.new()
	_paint = ShaderMaterial.new()
	_paint.shader = SHADER
	_field.material_override = _paint
	_field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_field.visible = false
	add_child(_field)
	dress()


## ARMA EL CAMPO como dice `look` (se puede volver a llamar después de cambiarlo).
func dress() -> void:
	var style := str(look.get("style", "burbuja"))
	_body_paint = ShaderMaterial.new()
	_body_paint.shader = BODY_SHADER
	_body_paint.set_shader_parameter("tint", TINT)
	_body_paint.set_shader_parameter("center_alpha", float(look["center"]))
	_body_paint.set_shader_parameter("rim_alpha", float(look["rim"]))
	_body_paint.set_shader_parameter("grow", float(look.get("grow", 0.06)) if style == "cuerpo" else 0.0)
	_body_paint.set_shader_parameter("uv_border", 0.04 if style == "frente" else 0.0)
	_set_skin(false)
	if _panel != null:
		_panel.queue_free()
		_panel = null
	var facets := int(look["facets"])
	if facets < 0:
		var ball := SphereMesh.new()
		ball.radius = 0.5
		ball.height = 1.0
		_field.mesh = ball
	else:
		_field.mesh = MechShield.icosphere(facets)
	var torso: bool = look["torso"]
	_field.scale = TORSO_SIZE if torso else SIZE
	_field.position = TORSO_CENTER if torso else CENTER
	_paint.set_shader_parameter("tint", TINT)
	_paint.set_shader_parameter("center_alpha", float(look["center"]))
	_paint.set_shader_parameter("rim_alpha", float(look["rim"]))
	_paint.set_shader_parameter("line_alpha", float(look["lines"]))
	_paint.set_shader_parameter("flat_facets", 1.0 if facets >= 0 else 0.0)


func _physics_process(delta: float) -> void:
	if held and not _held_was and not on and energy != null and energy.spend(START_COST):
		on = true
		_since = 0.0
		_refunded = false
	_held_was = held
	if on:
		_since += delta
		if not held or not energy.drain(HOLD_COST, delta):
			on = false


func _process(delta: float) -> void:
	_shown = move_toward(_shown, 1.0 if on else 0.0, delta * 8.0)
	_flash = move_toward(_flash, 0.0, delta * 3.0)
	_hit_t += delta
	var showing := _shown > 0.0 or _flash > 0.0
	var style := str(look.get("style", "burbuja"))
	_field.visible = showing and style == "burbuja"
	_paint.set_shader_parameter("strength", _shown + 2.0 * _flash)
	_set_skin(showing and style == "cuerpo")
	if style == "frente":
		if _panel == null:
			_build_panel()
		if _panel != null:
			_panel.visible = showing
	_body_paint.set_shader_parameter("strength", maxf(_shown, _flash))
	_body_paint.set_shader_parameter("hit_wave", _hit_t * HIT_SPEED)
	_body_paint.set_shader_parameter("hit_strength", clampf(1.0 - _hit_t / HIT_TIME, 0.0, 1.0))


## UN GOLPE FRENADO (lo avisa ToolMech.block_hit, con dónde pegó si lo sabe): el destello, la onda en los estilos
## pegados y, si fue justo después de prenderlo, el parry.
func stopped(at := Vector3.INF) -> void:
	_flash = 1.0
	if at.is_finite():
		_hit_t = 0.0
		_body_paint.set_shader_parameter("hit_point", at)
	if on and _since <= PARRY and not _refunded and energy != null:
		_refunded = true
		energy.level = minf(energy.level + START_COST, 1.0)


## LA CÁSCARA PEGADA AL CUERPO: el material de encima (material_overlay) en cada pieza de afuera de la meca, o nada.
## Lo de adentro no (los tableros, las sillas, la cápsula por dentro, la grilla).
func _set_skin(on_now: bool) -> void:
	if on_now == _skin_on:
		return
	_skin_on = on_now
	if on_now and _skin.is_empty():
		_skin = _outer_meshes()
	for mesh in _skin:
		if is_instance_valid(mesh):
			mesh.material_overlay = _body_paint if on_now else null


func _outer_meshes() -> Array[GeometryInstance3D]:
	var mech := get_parent()
	var out: Array[GeometryInstance3D] = []
	for found in mech.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		if mesh.name == "Cápsula" or mesh.has_meta(&"grilla_de_tablero"):
			continue
		var inside := false
		var at := mesh.get_parent()
		while at != null and at != mech:
			if at is FaceMount or at is SeatInteractable or at is MechShield:
				inside = true
				break
			at = at.get_parent()
		if not inside:
			out.append(mesh)
	return out


## LA PANTALLA DE FRENTE: un tramo de cilindro delante del torso, colgado de la cabina (gira e inclina con ella), de los
## dos lados (se ve también desde adentro).
func _build_panel() -> void:
	var mech := get_parent() as Mech
	if mech == null or mech.cabin == null:
		return
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 16
	for side: float in [1.0, -1.0]:
		for i in steps:
			for corner: Array in [[0, 0], [1, 0], [1, 1], [0, 0], [1, 1], [0, 1]]:
				var u: float = (i + int(corner[0])) / float(steps)
				var v: float = float(corner[1])
				if side < 0.0:
					u = 1.0 - u
				var angle := deg_to_rad(lerpf(-PANEL_OPEN, PANEL_OPEN, u))
				var out := Vector3(sin(angle), 0.0, -cos(angle))
				tool.set_uv(Vector2(u, v))
				tool.set_normal(out * side)
				tool.add_vertex(out * PANEL_RADIUS + Vector3.UP * lerpf(PANEL_LOW, PANEL_HIGH, v))
	_panel = MeshInstance3D.new()
	_panel.name = "Escudo de frente"
	_panel.mesh = tool.commit()
	_panel.material_override = _body_paint
	_panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mech.cabin.add_child(_panel)
	_panel.global_transform = mech.global_transform


## UNA ESFERA LOW POLY de diámetro 1: el icosaedro subdividido `subdivisions` veces, con las caras sueltas y el color de
## cada vértice en su coordenada baricéntrica (el shader marca las aristas con eso).
static func icosphere(subdivisions: int) -> ArrayMesh:
	var t := (1.0 + sqrt(5.0)) * 0.5
	var points: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	var faces: Array = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6],
		[7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7],
		[9, 8, 1],
	]
	var triangles: Array = []
	for face: Array in faces:
		triangles.append([points[face[0]].normalized(), points[face[1]].normalized(), points[face[2]].normalized()])
	for i in subdivisions:
		var finer: Array = []
		for tri: Array in triangles:
			var a: Vector3 = tri[0]
			var b: Vector3 = tri[1]
			var c: Vector3 = tri[2]
			var ab := ((a + b) * 0.5).normalized()
			var bc := ((b + c) * 0.5).normalized()
			var ca := ((c + a) * 0.5).normalized()
			finer.append_array([[a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]])
		triangles = finer
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Color] = [Color(1, 0, 0), Color(0, 1, 0), Color(0, 0, 1)]
	for tri: Array in triangles:
		for k in 3:
			var p: Vector3 = tri[k]
			tool.set_color(corners[k])
			tool.set_normal(p)
			tool.add_vertex(p * 0.5)
	return tool.commit()
