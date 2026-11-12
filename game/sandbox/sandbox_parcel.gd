class_name SandboxParcel
extends Node3D

## UNA PARCELA DEL SANDBOX: un arquetipo, su semilla actual y el individuo armado encima. Alrededor, la zona de
## interacción (un marco): estando adentro, el panel muestra la parcela y valen sus teclas. El tamaño sale del
## `max_footprint` del arquetipo una sola vez.

const PLANE_LIFT := 0.002
const FRAME_LIFT := 0.01
const FRAME_WIDTH := 0.08
const PARCEL_COLOR := Color(0.74, 0.72, 0.68)
const FRAME_COLOR := Color(0.55, 0.53, 0.5)
const LABEL_COLOR := Color(0.3, 0.29, 0.27)

var archetype: SeededArchetype = null
var category := ""
var seed_value := 0
var size := Vector2.ZERO
## Cuánto sale la zona de interacción alrededor de la parcela, igual en los cuatro lados.
var interact_pad := 0.0

var _root: Node3D = null


func setup(p_archetype: SeededArchetype, p_category: String, p_size: Vector2, p_pad: float, p_seed: int) -> void:
	archetype = p_archetype
	category = p_category
	size = p_size
	interact_pad = p_pad
	name = "%s · %s" % [category, archetype.display_name]
	_draw()
	regenerate(p_seed)


## Lo que armó el arquetipo, o null.
func root() -> Node3D:
	return _root if is_instance_valid(_root) else null


## (`_flash`: el destello de la parcela que se rearma, de allá; acá no hay destello.)
func regenerate(p_seed: int, _flash := true) -> void:
	seed_value = p_seed
	if is_instance_valid(_root):
		_root.queue_free()
	_root = archetype.build(seed_value, self)


## La zona de interacción, en el plano XZ del mundo.
func interaction_rect() -> Rect2:
	var half := size * 0.5 + Vector2.ONE * interact_pad
	return Rect2(Vector2(global_position.x, global_position.z) - half, half * 2.0)


func contains(at: Vector3) -> bool:
	return interaction_rect().has_point(Vector2(at.x, at.z))


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray([
		"%s · %s" % [category, archetype.display_name],
		"semilla %d" % seed_value,
	])
	lines.append_array(archetype.describe(seed_value))
	return lines


func _draw() -> void:
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	plane.mesh = mesh
	plane.material_override = _flat(PARCEL_COLOR)
	plane.position.y = PLANE_LIFT
	add_child(plane)

	# El marco de la zona de interacción: cuatro tiras.
	var outer := size + Vector2.ONE * interact_pad * 2.0
	for side in 4:
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		var along_x := side < 2
		box.size = Vector3(outer.x if along_x else FRAME_WIDTH, 0.005, FRAME_WIDTH if along_x else outer.y)
		strip.mesh = box
		strip.material_override = _flat(FRAME_COLOR)
		var sign_side := -1.0 if side % 2 == 0 else 1.0
		strip.position = Vector3(0.0 if along_x else sign_side * outer.x * 0.5, FRAME_LIFT,
			sign_side * outer.y * 0.5 if along_x else 0.0)
		add_child(strip)

	var label := Label3D.new()
	label.text = archetype.display_name
	label.font_size = 64
	label.pixel_size = 0.004
	label.modulate = LABEL_COLOR
	label.outline_size = 0
	label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	label.position = Vector3(0.0, FRAME_LIFT + 0.01, size.y * 0.5 + interact_pad * 0.5)
	add_child(label)


static func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


## Lo que suma a la máscara de choque de quien vive en una parcela (lo piden los personajes de character-parametric, cuyas
## parcelas tienen bordes que los atajan). Acá las parcelas no tienen bordes: nada.
static func bound_mask(_node: Node) -> int:
	return 0
