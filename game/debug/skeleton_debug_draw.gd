class_name SkeletonDebugDraw
extends Node3D

## Visualizadores de debug del esqueleto, independientes entre sí:
##   · HUESOS         — una línea por hueso + una esfera en cada articulación.
##   · COLISIONADORES — las cápsulas de colisión que usa el ragdoll, con su forma real.
##
## ── LOS HUESOS VAN EN DOS MULTIMESH, Y ESO NO ES UNA OPTIMIZACIÓN PREMATURA ──────────────────────
## Una malla por línea y una por articulación daban 38 MeshInstance3D POR PERSONAJE, y todas con
## `no_depth_test`, que las manda al pase transparente: sin instanciar, sin agrupar y ordenadas una por
## una. Y el toggle las crea para TODOS los personajes de la escena —en la ciudad, uno por peatón—, así
## que prender el esqueleto costaba 38 llamadas de dibujo transparentes por personaje. Con dos MultiMesh
## son DOS por personaje, y el trabajo por frame es el mismo: escribir un transform por hueso.
##
## El LARGO del hueso va en la escala del transform de la instancia, no en la malla. Aparte de ahorrar
## una malla por hueso, resuelve gratis que el brazo cambia de largo al agarrar algo —antes había que
## re-medir y reescribir el BoxMesh de cada línea cada frame—.
##
## Los gizmos NO cuelgan de los CustomBone: son hijos de este nodo y cada frame se les copia el
## transform del hueso. Colgarlos del esqueleto era más corto, pero los hacía rehenes de la
## visibilidad ajena — el ragdoll apaga `lower_spine.visible`, que se lleva puesto todo el subárbol, y
## los gizmos desaparecían al ragdollear. Siendo hijos propios, nada de afuera los puede apagar.
##
## Y la fuente del transform es la misma que usa el cuerpo visible: los huesos parado, los cuerpos
## del ragdoll mientras ragdollea o se levanta (ahí los huesos quedan congelados y lo que se mueve son
## los cuerpos). Así el gizmo muestra siempre dónde está el personaje de verdad.

## ── CADA HUESO CON SU COLOR Y SU NOMBRE ──────────────────────────────────────────────────────────
## Un esqueleto de veintiún huesos todos del mismo verde no se lee: lo que uno pregunta mirándolo es "¿ese
## cortito de arriba es el cuello o es otra cosa?", y sin nombre la respuesta es media hora de medir.
##
## El color sale del ÍNDICE con el paso de la proporción áurea, así que dos huesos consecutivos —que son
## los que se tocan y los que hay que distinguir— caen lejos en el círculo de tonos. Y el nombre va del
## mismo color que su línea: el cartel y el hueso se emparejan por color y no por cercanía, que es lo que
## falla cuando los huesos se cruzan.
const BONE_HUE_STEP := 0.618
const BONE_SATURATION := 0.7
const JOINT_COLOR := Color(1.0, 0.8, 0.15)
const LINE_WIDTH  := 0.012

## EL ALTO DEL CARTEL de cada hueso, EN METROS DE MUNDO. Dos centímetros: en la fila de personajes del
## sandbox, con la lupa en ×3, son seis — y acercándose se leen todos.
##
## ⚠ NO SE USA `fixed_size`, y se probó: con esa bandera `pixel_size` deja de ser tamaño de mundo y pasa a
## otra escala, así que los mismos números daban carteles ENORMES — la pantalla entera se llenaba de colores
## y no se veía nada. Si alguna vez se quiere tamaño constante en pantalla, el valor tiene que bajar unos
## tres órdenes de magnitud y hay que mirarlo con ojos, no deducirlo.
const LABEL_HEIGHT := 0.022
## Y cuánto se corre del hueso, en metros, para no quedar encima de su línea.
const LABEL_OFFSET := 0.02
## LA PRIORIDAD DE DIBUJO de los carteles. Van ENCIMA DE TODO: no alcanza con no testear profundidad,
## porque entre cosas transparentes lo que decide es el orden — y el alambre de quads, la película del paño
## de la cara y las bolitas de las articulaciones son todas transparentes. Con la prioridad al máximo, el
## nombre gana siempre.
const LABEL_PRIORITY := 127

## EL RADIO de la bolita de cada articulación, EN METROS. Grande a propósito: la articulación es lo que
## se mira de un esqueleto, y es lo que hay que poder seguir con el ojo mientras el personaje camina.
##
## Ojo con la unidad si se compara con otros gizmos: `DebugUtil.create_debug_sphere` toma un "size" que
## es una ESCALA sobre una esfera de radio 0.5, o sea que se lee a la mitad. El valor viejo acá era 0.02
## de esos, que daban 1 cm de radio.
const JOINT_RADIUS := 0.025
## Poquísimos lados: con las instancias en un MultiMesh el costo es por INSTANCIA y no por triángulo, así
## que la densidad ya no decide nada de performance — esto es solo cuán redonda se ve la bolita de cerca.
const JOINT_SEGMENTS := 8
const JOINT_RINGS := 4

var bi: BoneInstantiator

var _bones_on: bool = false
## FIJADO POR EL SANDBOX: prendido sólo en una fila (ver CharacterArchetype.show_skeleton_of), así que la vista de debug
## de todos no lo prende ni lo apaga (ver CharacterDebugView.apply_to).
var pinned := false

## EL GRUPO DE LOS DIBUJOS DE DEBUG: lo que cuelga de un nodo de este grupo no es parte de lo que se mira, así que no
## cuenta para medir (ver SandboxParcel._measure_proxy: las líneas del esqueleto nacen en el origen del mundo y estiraban
## la caja de la parcela dos metros, 16/10/2026).
const OVERLAY_GROUP := "debug_overlay"


func _enter_tree() -> void:
	add_to_group(OVERLAY_GROUP)
var _colliders_on: bool = false

## Los huesos: dos MultiMesh y la lista de a qué hueso corresponde cada instancia, en orden.
var _lines: MultiMeshInstance3D = null
var _joints: MultiMeshInstance3D = null
var _bone_refs: Array[CustomBone] = []

## ⚠ LOS CARTELES SÍ SON UN NODO POR HUESO, al contrario de las líneas y las bolitas. No hay `MultiMesh` de
## texto, así que son veintiún `Label3D` por personaje y son la parte cara de esta vista — por eso se crean
## solo con el toggle prendido y se liberan al apagarlo, como todo lo demás de acá.
var _labels: Array[Label3D] = []

## Los colisionadores siguen siendo un nodo por cuerpo: cada cápsula tiene SU radio y SU alto, y eso no
## entra en la escala de una instancia sin deformarle las puntas. Son 19 y es otro toggle.
var _col_nodes: Array[Node3D] = []
var _col_refs:  Array[CustomBone] = []

func is_bones_on() -> bool:     return _bones_on
func is_colliders_on() -> bool: return _colliders_on

func set_bones(value: bool) -> void:
	_bones_on = value
	if is_instance_valid(_lines):
		_lines.queue_free()
	if is_instance_valid(_joints):
		_joints.queue_free()
	_lines = null
	_joints = null
	_bone_refs.clear()
	for label in _labels:
		if is_instance_valid(label):
			label.queue_free()
	_labels.clear()
	if _bones_on:
		_build_bones()

## Qué está prendido: lo lee el personaje para volver a armarlo al rearmarse (ver BoneInstantiator.initialize_skeleton).
func bones_on() -> bool:
	return _bones_on


func colliders_on() -> bool:
	return _colliders_on


func set_colliders(value: bool) -> void:
	_colliders_on = value
	_free_group(_col_nodes, _col_refs)
	if _colliders_on:
		_build_colliders()

## En _physics_process, no en _process: los huesos se resuelven en el frame de física, y leerlos desde
## el frame de render los mostraría un tick atrás.
func _physics_process(_delta: float) -> void:
	_follow_bones()
	_follow(_col_nodes, _col_refs)

## Mientras ragdollea, el hueso está congelado y quien se mueve es su RigidBody3D. Misma regla que
## BoneInstantiator._sync_body_visual.
func _source_transform(bone: CustomBone) -> Transform3D:
	if is_instance_valid(bi) and is_instance_valid(bi.ragdoll_util) \
			and (bi.ragdoll_util.is_active or bi.ragdoll_util.is_recovering):
		var rb: Node3D = bi.ragdoll_util.get_bodies().get(bone)
		if is_instance_valid(rb):
			return rb.global_transform
	return bone.global_transform

func _follow(nodes: Array[Node3D], refs: Array[CustomBone]) -> void:
	for i in nodes.size():
		if is_instance_valid(nodes[i]) and is_instance_valid(refs[i]):
			nodes[i].global_transform = _source_transform(refs[i])

## Un transform por hueso en cada MultiMesh. La línea lleva el largo del hueso en la escala —la malla
## es un cubo de un metro— y por eso se re-mide sola cuando el brazo se estira al agarrar algo.
##
## Las instancias van en coordenadas del MUNDO, que es lo que hace `top_level` en los dos nodos: sin eso
## habría que invertir el transform del padre una vez por frame para nada.
func _follow_bones() -> void:
	if not (is_instance_valid(_lines) and is_instance_valid(_joints)):
		return
	for i in _bone_refs.size():
		var bone := _bone_refs[i]
		if not is_instance_valid(bone):
			continue
		var at := _source_transform(bone)
		var length: float = maxf(bone.capsule_dimensions.y, 0.0001)
		_joints.multimesh.set_instance_transform(i, at)
		_lines.multimesh.set_instance_transform(i, Transform3D(
			at.basis.scaled_local(Vector3(1.0, length, 1.0)),
			at * Vector3(0.0, length * 0.5, 0.0)))
		# EL CARTEL EN EL MEDIO DEL HUESO y corrido de su línea: ahí no lo tapa ni la bolita de la
		# articulación ni el hueso siguiente.
		if i < _labels.size() and is_instance_valid(_labels[i]):
			_labels[i].global_position = at * Vector3(LABEL_OFFSET, length * 0.5, 0.0)

func _build_bones() -> void:
	if not is_instance_valid(bi) or bi.custom_bones_util == null:
		return
	for bone in bi.custom_bones_util.get_all_bones():
		if is_instance_valid(bone):
			_bone_refs.append(bone)
	if _bone_refs.is_empty():
		return

	# La línea es un cubo de UN METRO de alto, centrado: el largo real lo pone la escala de cada
	# instancia, y el medio metro de corrimiento también (ver `_follow_bones`).
	var line_mesh := BoxMesh.new()
	line_mesh.size = Vector3(LINE_WIDTH, 1.0, LINE_WIDTH)
	# EL BLANCO ES A PROPÓSITO: el color lo pone cada INSTANCIA y el material lo multiplica (ver
	# `_multimesh`, donde está la trampa del orden).
	_lines = _multimesh(line_mesh, _flat_material(Color.WHITE, true), _bone_refs.size(), true)
	# UN HUESO, UN TONO (ver `BONE_HUE_STEP`).
	for i in _bone_refs.size():
		_lines.multimesh.set_instance_color(i, bone_color(i))

	# Y EL NOMBRE DE CADA UNO, del mismo color que su línea: el cartel y el hueso se emparejan por color y
	# no por cercanía, que es lo que falla cuando los huesos se cruzan.
	for i in _bone_refs.size():
		var label := Label3D.new()
		label.text = String(_bone_refs[i].name)
		label.modulate = bone_color(i)
		label.font_size = 64
		label.pixel_size = LABEL_HEIGHT / 64.0
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		# Se ve A TRAVÉS DEL CUERPO, igual que las líneas: un nombre que el torso tapa no sirve para
		# identificar el hueso que está atrás. Y ENCIMA DE TODO lo demás (ver `LABEL_PRIORITY`).
		label.no_depth_test = true
		label.render_priority = LABEL_PRIORITY
		label.outline_render_priority = LABEL_PRIORITY - 1
		# El contorno negro es lo que lo hace legible sobre el cuerpo claro y sobre el cielo.
		label.outline_size = 20
		label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		# En coordenadas del mundo, como los dos MultiMesh: el transform se le escribe por frame.
		label.top_level = true
		add_child(label)
		_labels.append(label)

	# LA BOLITA SE ARMA ACÁ y no con `DebugUtil.create_debug_sphere` por el MATERIAL: esa pone
	# `depth_draw_mode = ALWAYS`, que no es lo mismo que no testear profundidad, así que las
	# articulaciones quedaban TAPADAS POR EL CUERPO mientras las líneas —que sí usan `no_depth_test`— se
	# veían por encima. Un esqueleto que se ve a medias es peor que ninguno.
	var ball := SphereMesh.new()
	ball.radius = JOINT_RADIUS
	# Una SphereMesh con el alto distinto del doble del radio sale achatada.
	ball.height = JOINT_RADIUS * 2.0
	ball.radial_segments = JOINT_SEGMENTS
	ball.rings = JOINT_RINGS
	_joints = _multimesh(ball, _flat_material(JOINT_COLOR), _bone_refs.size())

	_follow_bones()


## EL COLOR DE UN HUESO por su orden en la lista. Con el paso de la proporción áurea, dos consecutivos caen
## lejos en el círculo de tonos — y los consecutivos son justamente los que se tocan.
static func bone_color(index: int) -> Color:
	return Color.from_hsv(fmod(float(index) * BONE_HUE_STEP, 1.0), BONE_SATURATION, 1.0)


## Un MultiMeshInstance3D con `count` instancias de `mesh`, en coordenadas del mundo.
## ⚠ `use_colors` SE PRENDE ANTES DE `instance_count`, y ese orden no es un detalle: Godot asigna los
## buffers de la instancia al fijar el conteo, así que prendiéndolo después no hay dónde guardar el color y
## `set_instance_color` no hace nada — las líneas salían todas del color del material (blancas).
func _multimesh(mesh: Mesh, material: Material, count: int,
		per_instance_color := false) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = per_instance_color
	multi.mesh = mesh
	multi.instance_count = count

	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	node.material_override = material
	# Ignora el transform del padre: así los transforms de las instancias son del mundo, que es en lo
	# que vienen los huesos.
	node.top_level = true
	add_child(node)
	return node


func _build_colliders() -> void:
	if not is_instance_valid(bi) or not is_instance_valid(bi.ragdoll_util):
		return
	var bodies := bi.ragdoll_util.get_bodies()
	for bone: CustomBone in bodies:
		var rb: Node = bodies[bone]
		if not (is_instance_valid(bone) and is_instance_valid(rb)):
			continue
		# La forma se LEE del collider real del ragdoll en vez de recalcularse: así el gizmo no puede
		# mentir si mañana cambia la fórmula de RagdollUtil.
		for child in rb.get_children():
			var cs := child as CollisionShape3D
			if cs == null:
				continue
			var caps := cs.shape as CapsuleShape3D
			if caps == null:
				continue
			var holder := Node3D.new()
			add_child(holder)
			holder.add_child(DebugUtil.create_debug_capsule(caps.radius, caps.height, cs.position.y))
			_col_nodes.append(holder)
			_col_refs.append(bone)
			break

func _free_group(nodes: Array[Node3D], refs: Array[CustomBone]) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	nodes.clear()
	refs.clear()

## `per_instance` prende la lectura del color de VÉRTICE, que es por donde un MultiMesh pasa el color de cada
## instancia. Sin eso, `set_instance_color` no cambia nada y todas las líneas salen del color del material.
static func _flat_material(color: Color, per_instance := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color  = color
	mat.shading_mode  = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.vertex_color_use_as_albedo = per_instance
	return mat
