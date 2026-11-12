class_name ForceFieldGizmo
extends MeshInstance3D

## ── EL CAMPO DE FUERZA ENTRE PERSONAJES, A LA VISTA (03/11/2026, lo pidió el dios del juego) ─────────────────────────
## Los personajes no se chocan rígido entre sí: se atraviesan, y cuando uno se acerca a otro y se tocan —sus cápsulas,
## en el plano, a menos que la suma de sus radios—, el que se acerca sale despedido una vez, según su velocidad de
## acercamiento y las masas (ver CharacterRigidBody3D._resolve_player_collisions). Contra las paredes, el piso y los
## autos NO es esto: ahí la cápsula choca rígido, de verdad, y el golpe se mide.
##
## Esto dibuja ese campo: un ANILLO EN EL PISO del radio de la cápsula —dos anillos que se tocan son dos personajes que se
## empujan— y, en cada empujón, el anillo se enciende y sale una FLECHA con el cambio de velocidad que le dio (1 m de
## flecha por m/s), que se apaga en `FADE_S`. Se prende con CharacterDebugView.show_force_field.

const NODE := "CampoDeFuerza"
const IDLE := Color(0.25, 0.8, 1.0, 0.8)
const HIT := Color(1.0, 0.45, 0.1, 0.95)
const FADE_S := 0.6

var _rb: CharacterRigidBody3D
var _mesh := ImmediateMesh.new()
var _mat := StandardMaterial3D.new()


## Lo pone o lo saca en `bi`.
static func apply(bi: BoneInstantiator, on: bool) -> void:
	var rb := bi.char_rigidbody
	if not is_instance_valid(rb):
		return
	var current := rb.get_node_or_null(NODE)
	if on and current == null:
		var gizmo := ForceFieldGizmo.new()
		gizmo.name = NODE
		gizmo._rb = rb
		rb.add_child(gizmo)
	elif not on and current != null:
		current.queue_free()


func _ready() -> void:
	mesh = _mesh
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.no_depth_test = true
	material_override = _mat


func _process(_delta: float) -> void:
	if not is_instance_valid(_rb):
		return
	var age := float(Time.get_ticks_msec() - _rb.last_field_push_ms) / 1000.0
	var glow := clampf(1.0 - age / FADE_S, 0.0, 1.0)
	var color := IDLE.lerp(HIT, glow)
	var feet := _rb.global_position + Vector3.UP * (_rb._capsule_stand_y_offset - _rb._capsule_stand_height * 0.5 + 0.03)
	global_transform = Transform3D(Basis.IDENTITY, feet)
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var radius := _rb._capsule_radius
	var steps := 32
	# Tres anillos juntos, para que se lea de lejos; encendido, más anchos.
	for ring in 3:
		var r := radius * (1.0 - 0.04 * ring * (1.0 + glow))
		for i in steps:
			var a := TAU * i / steps
			var b := TAU * (i + 1) / steps
			_mesh.surface_set_color(color)
			_mesh.surface_add_vertex(Vector3(cos(a), 0.0, sin(a)) * r)
			_mesh.surface_set_color(color)
			_mesh.surface_add_vertex(Vector3(cos(b), 0.0, sin(b)) * r)
	if glow > 0.0 and _rb.last_field_push.length() > 0.01:
		var push := _rb.last_field_push
		var tip := Vector3(push.x, 0.0, push.z)
		var side := tip.cross(Vector3.UP).normalized() * 0.12
		var back := -tip.normalized() * 0.2
		var hit := Color(HIT, glow)
		for seg: Array in [[Vector3.ZERO, tip], [tip, tip + back + side], [tip, tip + back - side]]:
			_mesh.surface_set_color(hit)
			_mesh.surface_add_vertex(seg[0])
			_mesh.surface_set_color(hit)
			_mesh.surface_add_vertex(seg[1])
	_mesh.surface_end()
