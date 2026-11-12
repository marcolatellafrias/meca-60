class_name CharacterDebugView

## Estado GLOBAL de los visualizadores de debug de personajes. Los toggles del panel escriben acá y
## esto los aplica a todos los personajes de la escena, no solo al propio.
##
## Es estado estático a propósito. La alternativa —que cada toggle recorra la escena— dejaba afuera a
## los personajes que spawnean DESPUÉS de prender la opción, y a los que se regeneran al respawnear.
## Guardando el estado, `apply_to` se llama también al final de initialize_skeleton y cualquier
## personaje nuevo nace con lo que esté prendido.
##
## Enumerar es gratis: las cápsulas ya están en CharacterRigidBody3D.CHARACTER_GROUP, y el
## BoneInstantiator es su padre.

static var hide_character: bool = false
static var show_capsule:   bool = false
## LA CÁPSULA VISIBLE: roja y semitransparente, del ancho y el alto del cuerpo que se ve —los brazos incluidos—, medida
## de sus mallas (ver `visible_bounds`). No choca con nada: es para ver la escala de una persona, que la de
## colisión, más angosta a propósito, no dice.
static var show_visible_capsule: bool = false
const VISIBLE_CAPSULE_NODE := "VisibleCapsule"
const VISIBLE_CAPSULE_COLOR := Color(0.9, 0.1, 0.08, 0.35)
static var show_skeleton:  bool = false
static var show_colliders: bool = false
static var show_grab_cone: bool = false
static var ragdoll_color:  bool = false
## EL CAMPO DE FUERZA entre personajes (ver ForceFieldGizmo, CharacterRigidBody3D._resolve_player_collisions).
static var show_force_field: bool = false
## Poles, targets, anillos de alcance/zancada y sondeos del raycast de piernas. Apagado por defecto:
## son ayudas de autoría de la marcha y ensucian la vista el resto del tiempo.
static var show_gait_gizmos: bool = false

## LA VISTA BLENDER sobre cada personaje (ver BlenderView): sus triángulos encima del sólido, siguiendo la pose. Es por
## malla, así que no hace falta esconder nada: la ciudad y los autos quedan como están. *Fue el alambre del viewport,
## que dibujaba todo en líneas —las caras de atrás también— y obligaba a esconder la ciudad y pintar de negro al
## personaje para que se leyera.*
static var show_blender: bool = false
## LA VISTA BLENDER EN PAUSA para todos, aunque un personaje la tenga prendida: la piden los F1 de quads mientras están
## abiertos, porque su alambre y éste no se pueden superponer (ver TorsoTuner).
static var blender_paused: bool = false


## LO QUE VE UN PERSONAJE: lo suyo si lo tiene (ver BoneInstantiator.debug_view), si no lo de todos.
static func view_of(bi: BoneInstantiator, what: String, everyone: bool) -> bool:
	return bool(bi.debug_view.get(what, everyone))


## Pausa o devuelve la vista Blender en todos (ver `blender_paused`).
static func pause_blender(tree: SceneTree, paused: bool) -> void:
	blender_paused = paused
	apply_all(tree)

static func toggle_hide_character(tree: SceneTree) -> void:
	hide_character = not hide_character
	apply_all(tree)

static func toggle_capsule(tree: SceneTree) -> void:
	show_capsule = not show_capsule
	apply_all(tree)

## Las dos cápsulas, en ronda: ninguna → la de colisión → la visible → las dos.
static func cycle_capsules(tree: SceneTree) -> void:
	var state := (int(show_capsule) + 2 * int(show_visible_capsule) + 1) % 4
	show_capsule = state & 1 != 0
	show_visible_capsule = state & 2 != 0
	apply_all(tree)


## Lo que ocupa el cuerpo VISIBLE de un personaje, en el espacio de su cápsula: la caja de sus mallas tal como están.
## Vacía si no tiene cuerpo de mallas. ⚠ NO EN EL CUADRO EN QUE NACE: ahí las mallas todavía no tomaron la pose y la
## caja sale de la mitad (medido: el gordo da 0,59 × 0,78 en el cuadro 0 y 1,38 × 1,96 desde el 1); quien mide espera
## un par de cuadros (ver `_build_visible_capsule`, CityModelSim).
static func visible_bounds(bi: BoneInstantiator) -> AABB:
	var out := AABB()
	if not is_instance_valid(bi) or not is_instance_valid(bi.char_rigidbody) or bi.body_visual == null:
		return out
	var meshes = bi.body_visual.get("meshes")
	if not (meshes is Array):
		return out
	var to_local := bi.char_rigidbody.global_transform.affine_inverse()
	var first := true
	for m in meshes:
		var mi := m as MeshInstance3D
		if not is_instance_valid(mi) or not mi.visible or mi.mesh == null:
			continue
		var b := to_local * mi.global_transform * mi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out


## La cápsula visible de un personaje: se arma al prenderla —medida en ese momento— y se va al apagarla.
static func _apply_visible_capsule(bi: BoneInstantiator) -> void:
	if not is_instance_valid(bi.char_rigidbody):
		return
	var old := bi.char_rigidbody.get_node_or_null(VISIBLE_CAPSULE_NODE)
	if not view_of(bi, "visible_capsule", show_visible_capsule):
		if old != null:
			old.queue_free()
		return
	if old != null or bi.has_meta(VISIBLE_CAPSULE_NODE):
		return
	_build_visible_capsule(bi)


## Arma la cápsula visible un par de cuadros después: un personaje que nace con ella prendida todavía no tiene la pose
## (ver `visible_bounds`).
static func _build_visible_capsule(bi: BoneInstantiator) -> void:
	bi.set_meta(VISIBLE_CAPSULE_NODE, true)
	# EL ÁRBOL SE TOMA UNA VEZ: entre cuadro y cuadro el personaje puede irse (un panel que rearma la parcela), y
	# pedirle el árbol a uno liberado frenaba el juego.
	var tree := bi.get_tree()
	for i in 2:
		await tree.process_frame
	if not is_instance_valid(bi):
		return
	bi.remove_meta(VISIBLE_CAPSULE_NODE)
	if not show_visible_capsule or not is_instance_valid(bi.char_rigidbody) 			or bi.char_rigidbody.get_node_or_null(VISIBLE_CAPSULE_NODE) != null:
		return
	var bounds := visible_bounds(bi)
	if bounds.size == Vector3.ZERO:
		return
	var mesh := CapsuleMesh.new()
	mesh.radius = maxf(bounds.size.x, bounds.size.z) * 0.5
	mesh.height = maxf(bounds.size.y, mesh.radius * 2.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = VISIBLE_CAPSULE_COLOR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var view := MeshInstance3D.new()
	view.name = VISIBLE_CAPSULE_NODE
	view.mesh = mesh
	view.material_override = mat
	view.position = bounds.get_center()
	bi.char_rigidbody.add_child(view)

static func toggle_skeleton(tree: SceneTree) -> void:
	show_skeleton = not show_skeleton
	apply_all(tree)

static func toggle_colliders(tree: SceneTree) -> void:
	show_colliders = not show_colliders
	apply_all(tree)

static func toggle_grab_cone(tree: SceneTree) -> void:
	show_grab_cone = not show_grab_cone
	apply_all(tree)

static func toggle_ragdoll_color(tree: SceneTree) -> void:
	ragdoll_color = not ragdoll_color
	apply_all(tree)

static func toggle_force_field(tree: SceneTree) -> void:
	show_force_field = not show_force_field
	apply_all(tree)

static func toggle_gait_gizmos(tree: SceneTree) -> void:
	show_gait_gizmos = not show_gait_gizmos
	apply_all(tree)

static func toggle_blender_view(tree: SceneTree) -> void:
	set_blender_view(tree, not show_blender)


## La vista Blender a un valor EXPLÍCITO: los F1 de quads la apagan mientras están abiertos y la devuelven al cerrar (ver
## TorsoTuner).
static func set_blender_view(tree: SceneTree, value: bool) -> void:
	show_blender = value
	apply_all(tree)


## ── SENTAR UN MANIQUÍ DE ESTUDIO ────────────────────────────────────────────────────────────────
## Para qué: la PIERNA SENTADA es donde más se deforma el cuerpo —la cadera doblada, el muslo apoyado, la
## rodilla en ángulo— y es justo lo que un maniquí parado no puede mostrar.
##
## Vive acá, y no en el panel que lo pide, porque lo piden DOS: la pestaña de pose del afinador de torso
## (un botón que los sienta a todos) y la fila de personajes del sandbox (una de sus tres poses). Que cada
## uno armara su silla es la forma segura de que un día dejen de sentarse igual.
##
## LA SILLA ES LA DEL JUEGO: la escena funcional que usa la nave (`STUDY_SEAT_SCENE`), con su silla programática.
## Afinando contra una silla de mentira, lo que se ajuste acá podría no servir allá.
##
## Y SE SIENTA POR LA PUERTA DE MANIQUÍ del asiento (`SeatInteractable.sit`): el mismo
## camino que un jugador pero sin pasar por el claim, porque un maniquí no es ocupación — es una referencia
## de tamaño. Llamar a `_sit` directo saltearía los dos cuidados que esa puerta trae: el desalojo si llega
## alguien de verdad, y soltar sin borrar.
const STUDY_SEAT_SCENE := "res://game/ship/working_seat.tscn"
## El nombre con el que se la encuentra después. Estable a propósito: es así como quien la puso sabe si
## este maniquí ya está sentado, sin tener que llevar una lista aparte.
const STUDY_SEAT_NAME := "silla_de_prueba"


## UNA SILLA PARA ESTE MANIQUÍ, donde está parado y mirando a donde él mira. Devuelve la silla, o nulo si
## no se pudo (ya había alguien sentado).
##
## LAS MEDIDAS DE LA SILLA SE ESCALAN CON LA LUPA y la silla no se estira: se le pide la mira justo donde
## cae con su altura de reposo ya escalada, así su propio ajuste no tiene nada que corregir. Y la geometría
## que se ve la agranda el asiento (ver SeatInteractable.display_scale), que es el único que sabe en qué
## escala le habla a su visual.
static func seat_manikin(bi: BoneInstantiator) -> SeatInteractable:
	if not is_instance_valid(bi) or bi.get_parent() == null:
		return null
	var scene := load(STUDY_SEAT_SCENE) as PackedScene
	if scene == null:
		return null
	var seat := scene.instantiate() as SeatInteractable
	if seat == null:
		return null
	seat.name = STUDY_SEAT_NAME
	var magnify: float = maxf(bi.size_scale, 0.01)
	seat.display_scale = magnify
	seat.rest_height *= magnify
	seat.seat_area *= magnify
	seat.stand_up_location *= magnify
	# A LA ALTURA DE LA NAVE, con la lupa (22/10/2026, lo pidió el dios del juego: la misma variable, ver StationSeat.make).
	seat.eye_height = ShipStyle.current.seat_eye_height * magnify
	bi.get_parent().add_child(seat)
	seat.global_position = bi.global_position
	seat.global_rotation = Vector3(0.0, bi.global_rotation.y, 0.0)
	bi.intent.seat = seat
	if not seat.sit(bi):
		seat.queue_free()
		return null
	return seat


## Levanta al maniquí y saca la silla.
##
## ⚠ CON `release_occupant_in_place` Y NO CON `_evict_display_occupant`: ese BORRA al maniquí —es lo que pasa en
## la nave cuando alguien de verdad se sienta, donde el maniquí es descartable— y acá el maniquí ES el personaje que se
## está mirando.
## Borrarlo dejaría la parcela vacía hasta el próximo respawn.
static func unseat_manikin(seat: Node) -> void:
	if not is_instance_valid(seat):
		return
	(seat as SeatInteractable).release_occupant_in_place()
	# SACARLA DEL ÁRBOL YA, y no solo `queue_free`: el borrado es diferido, así que la silla se sigue
	# encontrando por nombre el resto del cuadro y quien pregunte "¿este maniquí ya está sentado?" se
	# lleva un sí. Medido: rotar las poses de la fila dos veces en el mismo cuadro dejaba la silla puesta.
	var parent := seat.get_parent()
	if parent != null:
		parent.remove_child(seat)
	seat.queue_free()


static func apply_all(tree: SceneTree) -> void:
	if tree == null:
		return
	for rb in tree.get_nodes_in_group(CharacterRigidBody3D.CHARACTER_GROUP):
		apply_to((rb as Node).get_parent() as BoneInstantiator)

## Y LA SILLA DONDE ESTÁ SENTADO, con la vista Blender si él la tiene (22/10/2026, lo pidió el dios del juego: para
## iterarla), ver SeatInteractable.visual_meshes.
static func apply_seat_view(bi: BoneInstantiator) -> void:
	var seat := bi.current_seat as SeatInteractable
	if not bi.is_seated or not is_instance_valid(seat):
		return
	var blender := view_of(bi, "blender", show_blender) and not blender_paused
	for m in seat.visual_meshes():
		if blender:
			BlenderView.show_on(m)
		else:
			BlenderView.clear_from(m)


## Deja UN personaje en el estado global. La llama initialize_skeleton al final, así el spawn y el
## respawn heredan lo que esté prendido.
static func apply_to(bi: BoneInstantiator) -> void:
	if not is_instance_valid(bi):
		return

	bi.set_character_visible(not hide_character)
	bi.show_grab_cone = show_grab_cone

	# Se aplica acá y no solo en el toggle, así un personaje que spawnea con la vista prendida nace con ella.
	var body: CharacterBodyVisual = bi.body_visual
	var blender := view_of(bi, "blender", show_blender) and not blender_paused
	if is_instance_valid(body):
		for m in body.meshes:
			if not is_instance_valid(m):
				continue
			if blender:
				BlenderView.show_on(m)
			else:
				BlenderView.clear_from(m)
	apply_seat_view(bi)

	if is_instance_valid(bi.char_rigidbody) and is_instance_valid(bi.char_rigidbody.mesh_instance):
		bi.char_rigidbody.mesh_instance.visible = view_of(bi, "capsule", show_capsule)
	_apply_visible_capsule(bi)

	if is_instance_valid(bi.ik_util):
		bi.ik_util.set_gizmos_visible(view_of(bi, "gait_gizmos", show_gait_gizmos))

	if is_instance_valid(bi.ragdoll_util):
		var was: bool = bi.ragdoll_util.debug_ragdoll_color
		bi.ragdoll_util.debug_ragdoll_color = ragdoll_color
		if was and not ragdoll_color:
			bi.ragdoll_util.clear_debug_colors()
	ForceFieldGizmo.apply(bi, show_force_field)

	# Los gizmos se crean recién si hace falta: un personaje con todo apagado no paga nada.
	if show_skeleton or show_colliders or is_instance_valid(bi.skeleton_debug):
		var draw := bi.get_skeleton_debug()
		# EL PROPIO, NO (04/11/2026, el dios del juego: «el esqueleto en primera persona me obstruye»).
		if not draw.pinned:
			draw.set_bones(show_skeleton and not bi.kind.is_local() and PossessionCamera.possessed() != bi)
		draw.set_colliders(show_colliders)
