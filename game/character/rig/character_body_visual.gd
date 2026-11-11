class_name CharacterBodyVisual
extends Node3D

## LO QUE SE VE DE UN PERSONAJE. El rig lógico de `CustomBone`s no dibuja nada: es una jerarquía de
## Node3D que la IK, el animador procedural y el ragdoll mueven. Quién la DIBUJA es `ProceduralBodyUtil`, las partes
## generadas por código, skinneadas: el único cuerpo desde el 18/10/2026 (el de cápsulas por hueso y el modelo de Blender
## skineado se borraron, ver docs/technical/character-history.md).
##
## Las dos llamadas que el pipeline hace por frame son `sync_from_bones()` (normal) y
## `sync_from_ragdoll()` (mientras el personaje está caído) — la segunda existe porque durante el
## ragdoll los huesos quedan congelados y lo que se mueve son los RigidBody3D por hueso.

## EL COLOR DEL CUERPO, y el material con el que se dibuja cualquiera de los dos.
##
## Vive acá y no en una implementación porque es una decisión de ESTILO: el crema y lo mate valen igual
## para las cápsulas sueltas y para las partes generadas, y tenerlo escrito dos veces es la forma segura
## de que un día dejen de ser el mismo personaje.
##
## El crema no es blanco puro a propósito: deja margen antes de quemarse con el sol de la ciudad
## (`light_energy` 1.1–1.35), y sus propias sombras se leen como sombra y no como gris sucio.
const BODY_COLOR := Color(0.88, 0.85, 0.78)


## Cuánto brilla una malla del cuerpo: MATE a propósito —rugosidad casi al máximo—. En una maqueta lo que
## tiene que leerse es la forma, y un brillo que se mueve con la cámara compite con eso.
const BODY_ROUGHNESS := 0.95


## El material de una malla del cuerpo: el color, recibiendo luz y mate. Un `StandardMaterial3D`, sin shader propio
## (29/10/2026, el dios del juego borró los dos shaders toon: «después, en todo caso, más adelante, si quiero poner un
## shader, lo hago»).
##
## `vertex_color` es para una malla PINTADA —una manga de tela y una mano de piel en la misma malla, ver
## GridPart.is_painted—: el material va en blanco y el color sale de cada vértice (lineal, ver FaceFeatureMesh).
## `face`, los rasgos pintados de una cara (ver FaceTexture), encima del color, en la segunda coordenada de textura.
##
## UNO POR COMBINACIÓN, COMPARTIDO: no se lo puede mutar, es el de todos los que piden lo mismo.
static func body_material(color: Color = BODY_COLOR, vertex_color := false, face: Texture2D = null) -> Material:
	var key := "%s|%s|%d" % [color, vertex_color, face.get_instance_id() if face != null else 0]
	var cached: Material = _materials.get(key)
	if cached != null:
		return cached
	var made := StandardMaterial3D.new()
	made.albedo_color = color
	made.roughness = BODY_ROUGHNESS
	made.vertex_color_use_as_albedo = vertex_color
	if face != null:
		made.detail_enabled = true
		made.detail_albedo = face
		made.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		made.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
		made.texture_repeat = false
	_materials[key] = made
	return made


static var _materials: Dictionary = {}


## Las mallas que dibujan este cuerpo. Las recorre el wireframe del panel de debug.
var meshes: Array[MeshInstance3D] = []

## ── QUÉ PARTES SE VEN, Y POR QUÉ ES DEL CUERPO ────────────────────────────────────────────────────
## `studied` es la parte que se está mirando SOLA (la aislada); `_hidden_parts` son las que se escondieron
## a mano. Los pone el inspector (ver CharacterInspectorSource) y los lee el propio cuerpo.
##
## ⚠ TIENE QUE VIVIR ACÁ y no en el inspector, y eso se vio como un bug: cualquier toggle del panel vuelve
## a pasar por `set_meshes_visible` / `set_first_person` —prender el alambre, mostrar la cápsula, cambiar de
## cámara— y ahí se decide quién se ve. Con el estado afuera, aislar el torso y prender el alambre le
## devolvía todas las partes: dos sistemas escribiendo `visible` sin saber uno del otro. Ahora hay UNA
## regla, `part_shown`, y todo el mundo la consulta.
## LAS PARTES AISLADAS. Es una LISTA y no una sola: el sujeto de un estudio puede ser más de una malla —la
## cabeza con la tinta de sus rasgos es UNA cosa que se mira junta (ver FeatureArchetype)— y con un solo
## nombre la fila de rasgos mostraba una cara sin ojos.
var studied := PackedStringArray()
var _hidden_parts: Dictionary = {}

## EL GRUPO EN EL QUE SE ANOTA TODO CUERPO, para poder hablarle a todos a la vez. Hoy lo usa el tilde por
## malla del panel (ver `set_part_hidden`), que es de todos y no de un personaje.
const GROUP := "character_body"

## ── LAS PARTES QUE EL PANEL ESCONDE, QUE SON DE TODOS ───────────────────────────────────────────
## Por NOMBRE DE MALLA y ESTÁTICO: lo pone el panel de formas con un tilde por malla y vale para todos los
## cuerpos a la vez. Eso es el pedido y es lo que lo hace servir: para modelar se mira el mismo cambio en
## los seis arquetipos de la fila, y esconder el brazo de uno por uno no alcanza.
##
## Es APARTE de `_hidden_parts` —lo que el inspector esconde apuntando, que es de ese personaje— porque son
## dos herramientas distintas: apagar el brazo de todos no tiene que borrar lo que alguien aisló apuntando,
## ni al revés. La regla las compone (ver `part_shown`).
static var hidden_everywhere: Dictionary = {}


## El cuerpo entero apagado (panel) y la primera persona. Viven acá porque las dos implementaciones los
## manejaban igual y la regla de visibilidad los compone.
var _hidden := false
var _in_first_person := false


## TODO CUERPO SE ANOTA EN SU GRUPO, y ninguna de las dos implementaciones define `_ready`, así que esto
## vale para las dos sin que ninguna tenga que acordarse de llamar a `super`.
func _ready() -> void:
	add_to_group(GROUP)


## Mirar UNA parte sola. `""` sale del aislamiento.
func study_part(part_name: String) -> void:
	study_parts(PackedStringArray() if part_name.is_empty() else PackedStringArray([part_name]))


## Mirar UN CONJUNTO de partes y nada más. Una lista vacía sale del aislamiento. Aislar limpia lo escondido
## a mano: es un estado nuevo, no una capa encima de otro.
func study_parts(names: PackedStringArray) -> void:
	studied = names
	_hidden_parts.clear()
	refresh_parts()


func hide_part(part_name: String) -> void:
	_hidden_parts[part_name] = true
	refresh_parts()


func show_all_parts() -> void:
	studied = PackedStringArray()
	_hidden_parts.clear()
	refresh_parts()


## LA REGLA, en un solo lugar: una parte se ve si no está escondida —ni a mano en este cuerpo ni por el
## tilde que vale para todos— y, si hay una aislada, es ella.
func part_shown(part_name: String) -> bool:
	if _hidden_parts.has(part_name) or hidden_everywhere.has(part_name):
		return false
	return studied.is_empty() or studied.has(part_name)


## Vuelve a aplicar la regla. Pasa por `set_first_person` porque ese es el único lugar que decide malla por
## malla en cada implementación.
func refresh_parts() -> void:
	set_first_person(_in_first_person)


## Copiar el pose del árbol de CustomBone. Una vez por frame, al final del solve.
func sync_from_bones() -> void:
	pass


## Igual, pero leyendo los CUERPOS del ragdoll (CustomBone → RigidBody3D) en vez de los huesos.
func sync_from_ragdoll(_bodies: Dictionary) -> void:
	pass


## Primera persona: esconder lo que el propio jugador no tendría que verse.
func set_first_person(_first_person: bool) -> void:
	pass


## Mostrar/esconder el cuerpo entero (toggle del panel de debug).
func set_meshes_visible(value: bool) -> void:
	for m in meshes:
		if is_instance_valid(m):
			m.visible = value


