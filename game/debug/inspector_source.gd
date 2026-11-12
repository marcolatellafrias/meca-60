class_name InspectorSource
extends RefCounted

## UN RESOLVEDOR DEL INSPECTOR: contesta "qué hay donde apunté".
##
## El inspector (ver Inspector) pone el rayo, la mira, el puntito, el cartel, las capas de resaltado, los
## gestos y el portapapeles. Lo único que NO sabe es qué es lo que se está mirando, y eso lo contesta un
## resolvedor: recibe un rayo y devuelve un `InspectorPick`, o `null` si no le pega a nada.
##
## Hay tres, y resuelven de maneras completamente distintas porque las cosas que identifican lo son:
##
##   · `CityInspectorSource`      — rayo de FÍSICA + el índice de la ciudad. La ciudad tiene colliders y
##                                  está anotada en un índice, así que identificar es preguntar.
##   · `CharacterInspectorSource` — rayo contra la GEOMETRÍA de las mallas del personaje. Un personaje no
##                                  está en ningún índice y sus mallas no tienen colliders.
##   · `ConsoleInspectorSource`   — rayo contra los PRISMAS de las consolas, que el barrido anota: en la nave
##                                  son colliders y en la fila de Tableros del sandbox, mallas sueltas.
##   · `HullInspectorSource`      — rayo contra la GEOMETRÍA del casco de la nave, de a arista y vértice: el casco
##                                  es lo que se está modelando, y se señala para comentarlo.
##
## ⚠ ESTO NO ES UN FRAMEWORK DE INSPECCIÓN DE GEOMETRÍA. Nadie va a querer apuntarle a un vértice de un
## edificio: la topología se mira en el design sandbox y de los personajes, que es donde se la está
## esculpiendo. El resolvedor de personajes es, a propósito, el único que baja a ese nivel de detalle, y
## su costo está acotado a eso (ver su encabezado). Esta clase existe para que el inspector no tenga dos
## caminos escritos adentro, no para abrir una categoría.
##
## Un resolvedor con MODOS (el de personajes: mallas / huesos / caras / vértices) los maneja él: el
## inspector solo le pasa la tecla.

## La cámara desde la que se apunta y el cuerpo del propio jugador, que un resolvedor puede necesitar
## para sacarse a sí mismo del rayo. Los pone el inspector al montarlo.
var camera: Camera3D = null
var owner_body: PhysicsBody3D = null


func configure(new_camera: Camera3D, new_owner_body: PhysicsBody3D) -> void:
	camera = new_camera
	owner_body = new_owner_body


## Qué hay en este rayo. `null` si nada.
func aim(_tree: SceneTree, _from: Vector3, _to: Vector3) -> InspectorPick:
	return null


## Deshacer todo lo que los ganchos de este resolvedor hayan dejado puesto (mallas ocultas, pesos
## pintados). Lo llama el inspector al apagarse, al cambiar de modo y con el gesto de deshacer.
func undo() -> void:
	pass


## Si tiene modos. Si los tiene, `mode_label` nombra el actual y `cycle_mode` pasa al siguiente.
func has_modes() -> bool:
	return false


func mode_label() -> String:
	return ""


func cycle_mode() -> void:
	pass


## EL CUERPO PROPIO NO CUENTA. La cámara vive DENTRO de la cápsula del jugador, así que sin esto el rayo
## se choca con uno mismo: el impacto queda a centímetros, el cartel se va contra el plano cercano y
## parece que desapareciera. Moviéndose los brazos se corren y vuelve, que es exactamente el síntoma raro
## de "quieto no, caminando sí". `InteractionDetector` excluye lo mismo por la misma razón.
func _excludes() -> Array[RID]:
	var out: Array[RID] = []
	if not is_instance_valid(owner_body):
		return out
	out.append(owner_body.get_rid())
	var bi := owner_body.get_parent() as BoneInstantiator
	if is_instance_valid(bi) and is_instance_valid(bi.ragdoll_util):
		for rid: RID in bi.ragdoll_util._ragdoll_rids:
			out.append(rid)
	return out
