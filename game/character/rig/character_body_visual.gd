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


## Las mallas que dibujan este cuerpo.
var meshes: Array[MeshInstance3D] = []

## El cuerpo entero apagado (panel) y la primera persona. Viven acá porque las dos implementaciones los
## manejaban igual y la regla de visibilidad los compone.
var _hidden := false
var _in_first_person := false


## Copiar el pose del árbol de CustomBone. Una vez por frame, al final del solve.
func sync_from_bones() -> void:
	pass


## Igual, pero leyendo los CUERPOS del ragdoll (CustomBone → RigidBody3D) en vez de los huesos.
func sync_from_ragdoll(_bodies: Dictionary) -> void:
	pass


## Primera persona: esconder lo que el propio jugador no tendría que verse.
func set_first_person(_first_person: bool) -> void:
	pass


## Mostrar/esconder el cuerpo entero.
func set_meshes_visible(value: bool) -> void:
	for m in meshes:
		if is_instance_valid(m):
			m.visible = value


