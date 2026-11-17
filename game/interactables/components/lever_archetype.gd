class_name LeverArchetype
extends ComponentArchetype

## LA PALANCA UNIFICADA (paso 7 del framework, ver docs/planes-maestros/plan-maestro-de-nave/framework-tableros.md):
## la que reemplaza a la palanca de dos brazos de los tableros, que era horrible —dos topes, muy corta, sin jerarquía—.
## Lo decidió el usuario el 12/10/2026:
##
##   · ES AUTORIAL: la forma la modela él en Blender sobre la caja que escribe `write_box` (ver ModelBox,
##     docs/technical/model-boxes.md); mientras no hay modelo, se ve el boceto de código. La pieza del modelo que se
##     mueve se llama «mueve»; lo demás queda quieto.
##   · TRES TAMAÑOS POR JERARQUÍA (`size`): la GRANDE, la del control directo de la nave (altura, acelerador), larga;
##     la MEDIANA; la CHICA. La grande y la chica tienen además subvariantes con PARADAS intermedias.
##   · LO PARAMÉTRICO, SÓLO LAS PARADAS (`stops`): sin paradas es continua; con dos o más, se traba en cada una y cada
##     una lleva su etiqueta EN EL TAMBOR, que es grande para que entren.
##   · TRES AGARRES (`grip`): de BOLA, NORMAL —un mango derecho en la punta del palo— o de ACELERADOR —un brazo chato
##     y una empuñadura gorda atravesada—.
##   · Y LA DE YUGO (`yoke`), como la de la foto que mandó: dos brazos gruesos a los costados de un tambor quieto,
##     unidos por un travesaño, con el mango arriba, de un gris tranquilo. Sólo con paradas.
##
## Por ahora es lluvia de ideas: después de las eras de los científicos viene la SÍNTESIS, que limita las formas para que
## cada una diga cómo se usa (ver el estado, Decisiones).
##
## Se maneja como toda palanca de un eje (ver OneAxisComponent): se arrastra la empuñadura, va de punta a punta de sus
## celdas; la primera parada es la de arriba.

enum Size { SMALL, MEDIUM, LARGE }
enum Grip { BALL, NORMAL, THROTTLE }

const SIZE_NAMES: Array[String] = ["chica", "mediana", "grande"]
const GRIP_NAMES: Array[String] = ["de bola", "normal", "de acelerador"]
## Las celdas de la palanca de cada tamaño: la grande, larga.
const CELLS: Array[Vector2i] = [Vector2i(3, 6), Vector2i(4, 8), Vector2i(5, 12)]
## El color de la empuñadura por jerarquía: la grande, roja; las otras, negras. El yugo, de un gris tranquilo.
const GRIPS: Array[Color] = [Color(0.1, 0.1, 0.11), Color(0.1, 0.1, 0.11), Color(0.78, 0.16, 0.1)]
const YOKE := Color(0.36, 0.38, 0.4)
const HANDLE := Color(0.08, 0.08, 0.09)
## El alto de las letras de sus etiquetas, por tamaño.
const LABEL_HEIGHTS: Array[float] = [0.008, 0.011, 0.014]
const METAL := Color(0.6, 0.61, 0.63)
const HOUSING := Color(0.2, 0.2, 0.22)
const SLOT := Color(0.05, 0.05, 0.06)
const INK := Color(0.9, 0.86, 0.74)
## Dónde viven sus modelos (ver ModelBox), uno por tamaño y agarre (`model_key`): «palanca_grande_acelerador».
const MODEL_AREA := "componentes"
const GRIP_SLUGS: Array[String] = ["bola", "normal", "acelerador"]
const MODEL_MOVES := "mueve"

var size := Size.LARGE
var stops: Array[String] = []
var grip := Grip.BALL
var yoke := false


func _init(p_size := Size.LARGE, p_stops: Array[String] = [], p_grip := Grip.BALL, p_yoke := false) -> void:
	size = p_size
	stops = p_stops
	grip = p_grip
	yoke = p_yoke
	display_name = "Palanca"


## LAS VARIANTES: la grande continua y con cinco paradas, la mediana, la chica continua y con tres paradas, de bola y
## normales; y la de yugo, grande, con tres paradas.
static func primitives() -> Array:
	var five: Array[String] = ["PARE", "1/4", "1/2", "3/4", "TODA"]
	var three: Array[String] = ["SUBE", "—", "BAJA"]
	var out: Array = []
	for kind: Grip in [Grip.BALL, Grip.NORMAL, Grip.THROTTLE]:
		out.append(LeverArchetype.new(Size.LARGE, [], kind))
		out.append(LeverArchetype.new(Size.LARGE, five, kind))
		out.append(LeverArchetype.new(Size.MEDIUM, [], kind))
		out.append(LeverArchetype.new(Size.SMALL, [], kind))
		out.append(LeverArchetype.new(Size.SMALL, three, kind))
	out.append(LeverArchetype.new(Size.LARGE, three, Grip.NORMAL, true))
	return out


func variant_name() -> String:
	var out := SIZE_NAMES[size] + (", de yugo" if yoke else ", " + GRIP_NAMES[grip])
	if not stops.is_empty():
		out += ", %d paradas" % stops.size()
	return out


func use() -> Use:
	return Use.CONSTANT if size == Size.LARGE else Use.OCCASIONAL


func cells(_seed_value: int) -> Vector2i:
	return CELLS[size]


func describe(_seed_value: int) -> PackedStringArray:
	var line := "%d × %d celdas · %s" % [cells(0).x, cells(0).y, variant_name()]
	var traits := PackedStringArray(["continua" if stops.is_empty() else "se traba en: " + " · ".join(stops)])
	if ModelBox.has_model(MODEL_AREA, model_key()):
		traits.append("modelo hecho a mano")
	return PackedStringArray([line, " · ".join(traits)])


## La OneAxisComponent de una montada (la raíz que devuelve `mount`).
static func lever_of(root: Node) -> OneAxisComponent:
	return root.get_node_or_null("Lever/Control") as OneAxisComponent


func _build_on(_seed_value: int, root: Node3D, area: Vector2) -> void:
	var margin := ProceduralDashboard.CONTROL_MARGIN
	var w := area.x - 2.0 * margin
	var h := area.y - 2.0 * margin
	var box := Vector3(w, h, 0.06)
	var body := StaticBody3D.new()
	body.name = "Lever"
	root.add_child(body)
	var lever := OneAxisComponent.new()
	lever.name = "Control"
	# La de yugo es sólo de paradas: sin decir, dos.
	var marks: Array[String] = stops.duplicate()
	if yoke and marks.size() < 2:
		marks = ["", ""]
	if marks.size() >= 2:
		var at: Array[float] = []
		for i in marks.size():
			at.append(float(i) / float(marks.size() - 1))
		lever.positions = at
	body.add_child(lever)
	lever.build(box)
	var arm := lever.arm_length
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(w, h, arm * 0.6)
	shape.shape = collider
	shape.position = Vector3(0.0, 0.0, arm * 0.3)
	body.add_child(shape)
	_dress(body, lever, box)


## LA PALANCA DE LOS TABLEROS (el estilo «lever» de ControlArchetype, ver ControlArchetype.dress): la que arma
## ProceduralDashboard —la altura y el acelerador de la nave, las de los tableros de muestra— es esta, vestida sobre su
## control ya armado. El tamaño sale de lo alto: desde `LARGE_FROM` es la grande, con el agarre de acelerador —la del
## control directo de la nave—; si no, la mediana, de bola.
const LARGE_FROM := 0.28

static func dress_control(body: Node3D, lever: OneAxisComponent, box: Vector3) -> void:
	var large := box.y >= LARGE_FROM
	var piece := LeverArchetype.new(Size.LARGE if large else Size.MEDIUM, [], Grip.THROTTLE if large else Grip.BALL)
	piece._dress(body, lever, box)


## LO QUE SE VE, sobre el control `lever` ya armado en `body`, de la caja `box`: el tambor, lo que se mueve, el modelo
## si lo hay y las etiquetas de las paradas.
func _dress(body: Node3D, lever: OneAxisComponent, box: Vector3) -> void:
	var w := box.x
	var arm := lever.arm_length
	var radius := drum_radius(w)
	var slot := _housing(body, w, radius)
	if yoke:
		_yoke(lever, w, arm, radius)
	else:
		_moving(lever, w, arm, OneAxisComponent.grip_radius(box))
	_use_model(body, lever)
	if stops.size() >= 2:
		_drum_labels(body, radius, slot, w)


## EL RADIO DEL TAMBOR de una palanca de `w` de ancho: grande, para que entren las etiquetas.
static func drum_radius(w: float) -> float:
	return clampf(w * 0.32, 0.018, 0.05)


## EL TAMBOR: un cilindro acostado a lo ancho, medio hundido en el tablero, y abajo su chapa. En la de palo, partido
## por la RANURA por donde sale el brazo; en la de yugo, entero, entre sus brazos. Devuelve el ancho de la ranura.
func _housing(body: Node3D, w: float, radius: float) -> float:
	var slot := 0.0 if yoke else radius * 0.35
	var length := w * (0.7 if yoke else 0.9)
	var plate := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(w, radius * 2.4, 0.006)
	plate.mesh = slab
	plate.material_override = MeshKit.material(HOUSING.darkened(0.2), 0.6)
	plate.position.z = 0.003
	body.add_child(plate)
	var pieces: Array = [[0.0, length]] if yoke else [[-1.0, (length - slot) * 0.5], [1.0, (length - slot) * 0.5]]
	for piece: Array in pieces:
		var half := MeshInstance3D.new()
		var tube := CylinderMesh.new()
		tube.top_radius = radius
		tube.bottom_radius = radius
		tube.height = piece[1]
		tube.radial_segments = 32
		half.mesh = tube
		half.material_override = MeshKit.material(HOUSING, 0.5)
		half.rotation.z = PI * 0.5
		half.position.x = float(piece[0]) * (slot + tube.height) * 0.5
		body.add_child(half)
	if not yoke:
		var inside := MeshInstance3D.new()
		var core := CylinderMesh.new()
		core.top_radius = radius * 0.8
		core.bottom_radius = radius * 0.8
		core.height = slot
		inside.mesh = core
		inside.material_override = MeshKit.material(SLOT, 0.9)
		inside.rotation.z = PI * 0.5
		body.add_child(inside)
	return slot


## LO QUE SE MUEVE en la de palo, según su agarre: sale del eje hacia +Z del control.
func _moving(lever: OneAxisComponent, w: float, arm: float, grip_radius: float) -> void:
	var metal := MeshKit.material(METAL, 0.3)
	var paint := MeshKit.material(GRIPS[size], 0.4)
	var shaft := clampf(w * 0.05, 0.003, 0.007)
	var parts: Array[MeshInstance3D] = []
	if grip == Grip.THROTTLE:
		# De acelerador: un brazo chato que se afina y una empuñadura gorda, redondeada, atravesada.
		parts.append(_box(lever, Vector3(0.0, 0.0, arm * 0.45), Vector3(shaft * 3.2, shaft * 1.6, arm * 0.9), metal))
		var handle := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = grip_radius * 1.35
		capsule.height = w * 0.6
		handle.mesh = capsule
		handle.material_override = paint
		handle.rotation.z = PI * 0.5
		handle.position.z = arm
		lever.add_child(handle)
		parts.append(handle)
	elif grip == Grip.NORMAL:
		# Normal: el palo derecho y un mango gordo en la punta, a lo largo del palo, con la punta redonda.
		var sleeve := arm * 0.3
		parts.append(_cylinder(lever, Vector3(0.0, 0.0, (arm - sleeve * 0.5) * 0.5), shaft, shaft, arm - sleeve * 0.5,
			PI * 0.5, Vector3.RIGHT, metal))
		parts.append(_cylinder(lever, Vector3(0.0, 0.0, arm), grip_radius * 1.05, grip_radius * 0.85, sleeve, PI * 0.5,
			Vector3.RIGHT, paint))
		parts.append(_sphere(lever, Vector3(0.0, 0.0, arm + sleeve * 0.5), grip_radius * 1.05, paint))
	else:
		# De bola: el palo que se afina y la bola en la punta.
		parts.append(_cylinder(lever, Vector3(0.0, 0.0, arm * 0.5), shaft * 0.7, shaft, arm, PI * 0.5, Vector3.RIGHT,
			metal))
		parts.append(_sphere(lever, Vector3(0.0, 0.0, arm), grip_radius * 1.45, paint))
	# El cubo del eje, adentro de la ranura.
	parts.append(_cylinder(lever, Vector3.ZERO, shaft * 1.6, shaft * 1.6, shaft * 3.0, PI * 0.5, Vector3.BACK, metal))
	lever.highlighted.append_array(parts)


## LA DE YUGO, como la de la foto, gruesa y de colores tranquilos: dos brazos a los costados del tambor, que giran en sus
## cubos; un travesaño; arriba,
## la barra de metal y el mango negro parado en el medio.
func _yoke(lever: OneAxisComponent, w: float, arm: float, radius: float) -> void:
	var paint := MeshKit.material(YOKE, 0.45)
	var metal := MeshKit.material(METAL, 0.25)
	var black := MeshKit.material(HANDLE, 0.4)
	var side := w * 0.42
	var thick := clampf(w * 0.11, 0.009, 0.022)
	var top := arm * 0.8
	var parts: Array[MeshInstance3D] = []
	for sx: float in [-1.0, 1.0]:
		parts.append(_box(lever, Vector3(sx * side, 0.0, top * 0.5), Vector3(thick, thick * 1.6, top), paint))
		# El cubo redondo donde gira el brazo, al costado del tambor.
		parts.append(_cylinder(lever, Vector3(sx * side, 0.0, 0.0), radius * 0.55, radius * 0.55, thick * 1.2, PI * 0.5,
			Vector3.BACK, paint))
	parts.append(_box(lever, Vector3(0.0, 0.0, top * 0.6), Vector3(side * 2.0, thick * 1.1, thick * 0.9), paint))
	parts.append(_cylinder(lever, Vector3(0.0, 0.0, top), thick * 0.75, thick * 0.75, side * 2.0 + thick * 2.0,
		PI * 0.5, Vector3.BACK, metal))
	var handle := arm - top + arm * 0.12
	parts.append(_cylinder(lever, Vector3(0.0, 0.0, top + handle * 0.5), thick * 0.8, thick * 0.6, handle, PI * 0.5,
		Vector3.RIGHT, black))
	parts.append(_sphere(lever, Vector3(0.0, 0.0, top + handle), thick * 0.8, black))
	lever.highlighted.append_array(parts)


## LAS ETIQUETAS EN EL TAMBOR: cada una sobre su curva, donde pasa el brazo en esa parada —al lado de la ranura en la de
## palo, al medio del tambor en la de yugo—.
func _drum_labels(body: Node3D, radius: float, slot: float, w: float) -> void:
	var height := minf(LABEL_HEIGHTS[size], radius * 0.4)
	for i in stops.size():
		var angle := deg_to_rad(-OneAxisComponent.SWEEP_HALF_DEG + 2.0 * OneAxisComponent.SWEEP_HALF_DEG
			* float(i) / float(stops.size() - 1))
		var out := Vector3(0.0, -sin(angle), cos(angle))
		var up := Vector3(0.0, cos(angle), sin(angle))
		var label := StrokeLabel.make(stops[i], height, INK)
		var x := 0.0
		if not yoke:
			x = minf(slot * 0.5 + radius * 0.15 + StrokeFont.measure(stops[i], height).x * 0.5, w * 0.42)
		label.transform = Transform3D(Basis(Vector3.RIGHT, up, out), Vector3(x, 0.0, 0.0) + out * (radius + 0.0006))
		body.add_child(label)


## EL MODELO EN LUGAR DEL BOCETO, si lo hay (ver ModelBox): la pieza «mueve» con la palanca, lo demás quieto en su
## cuerpo; la caja es la del boceto (ver `write_box`). Sin pieza «mueve», queda el boceto.
func _use_model(body: Node3D, lever: OneAxisComponent) -> void:
	if not ModelBox.has_model(MODEL_AREA, model_key()):
		return
	var sketch := _sketch(body)
	var bounds := _bounds(body, sketch)
	var loaded := Node3D.new()
	var model := ModelBox.load_into(loaded, MODEL_AREA, model_key(), bounds.size, _model_material)
	var parts: Dictionary = model.get("parts", {})
	if not parts.has(MODEL_MOVES):
		push_warning("[Palanca] el modelo %s no tiene una pieza «%s»: se queda el boceto." % [model_key(),
			MODEL_MOVES])
		loaded.free()
		return
	for mesh in sketch:
		mesh.get_parent().remove_child(mesh)
		mesh.queue_free()
	lever.highlighted.clear()
	var frame := Transform3D(Basis(Vector3.UP, PI), bounds.get_center())
	for part_name: String in parts:
		var piece := parts[part_name] as MeshInstance3D
		var at := frame * piece.transform
		piece.get_parent().remove_child(piece)
		piece.transform = at
		if part_name == MODEL_MOVES:
			# Lo que se mueve va en el control: el modelo está parado, que es el control sin girar.
			lever.add_child(piece)
			lever.highlighted.append(piece)
		else:
			body.add_child(piece)
	loaded.free()


## Las mallas del boceto de un cuerpo: todas menos las etiquetas.
static func _sketch(body: Node3D) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for node in body.find_children("*", "MeshInstance3D", true, false):
		if not node is StrokeLabel:
			out.append(node as MeshInstance3D)
	return out


static func _bounds(body: Node3D, meshes: Array[MeshInstance3D]) -> AABB:
	var out := AABB()
	var first := true
	for mesh in meshes:
		var box := _relative(mesh, body) * mesh.get_aabb()
		out = box if first else out.merge(box)
		first = false
	return out


static func _model_material(color: Color) -> Material:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


## SU MODELO: uno por tamaño y agarre —o de yugo—, «palanca_grande_acelerador».
func model_key() -> String:
	return "palanca_%s_%s" % [SIZE_NAMES[size], "yugo" if yoke else GRIP_SLUGS[grip]]


## Su modelo de Blender (ver SeededArchetype.model_refs): en el sandbox, F4 lo abre y F5 lo trae.
func model_refs(_seed_value: int) -> Array[Dictionary]:
	return [{"area": MODEL_AREA, "key": model_key(), "title": "Palanca " + variant_name(), "write": write_box}]


## ESCRIBE SU CAJA (ver ModelBox), con el boceto en reposo —la palanca parada, derecha— y sus puntos: el eje, sobre el
## que gira, y la mano, donde se agarra. Sin paradas ni etiquetas: el modelo es la forma. Devuelve dónde la escribió.
func write_box() -> String:
	var shape := LeverArchetype.new(size, [] as Array[String], grip, yoke)
	var reference := Node3D.new()
	var holder := Node3D.new()
	reference.add_child(holder)
	shape._build_on(0, holder, Vector2(shape.cells(0)) * ProceduralDashboard.CELL)
	var body := holder.get_node("Lever") as Node3D
	var lever := lever_of(holder)
	lever.rotation = Vector3.ZERO
	var bounds := _bounds(body, _sketch(body))
	holder.transform = Transform3D(Basis(Vector3.UP, PI), bounds.get_center()).affine_inverse() 		* body.transform.affine_inverse()
	var points := {"eje": holder.transform * body.transform.origin,
		"mano": holder.transform * body.transform * Vector3(0.0, 0.0, lever.arm_length)}
	var path := ModelBox.write_box(MODEL_AREA, model_key(), "Palanca " + variant_name(), bounds.size,
		ProceduralDashboard.CELL, points, reference)
	reference.free()
	return path


static func _cylinder(parent: Node3D, at: Vector3, top: float, base: float, length: float, angle: float, axis: Vector3,
		material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = top
	tube.bottom_radius = base
	tube.height = length
	tube.radial_segments = 16
	mi.mesh = tube
	mi.material_override = material
	mi.basis = Basis(axis, angle)
	mi.position = at
	parent.add_child(mi)
	return mi


static func _sphere(parent: Node3D, at: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = radius
	ball.height = radius * 2.0
	mi.mesh = ball
	mi.material_override = material
	mi.position = at
	parent.add_child(mi)
	return mi


static func _box(parent: Node3D, at: Vector3, size_of: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size_of
	mi.mesh = box
	mi.material_override = material
	mi.position = at
	parent.add_child(mi)
	return mi


## Dónde está `node` en el espacio de `ancestor` (de BoardWiring, de character-parametric).
static func _relative(node: Node3D, ancestor: Node3D) -> Transform3D:
	var out := Transform3D.IDENTITY
	var at: Node = node
	while at != null and at != ancestor:
		if at is Node3D:
			out = (at as Node3D).transform * out
		at = at.get_parent()
	return out
