class_name MechShield
extends Node

## EL ESCUDO: LA MECÁNICA (18/11/2026; el diseño, docs/conceptual/armamento.md, «El escudo de fuerza»). Lo que se ve es el
## escudo físico de un brazo (ShieldTip, `tip`): SIN UN BRAZO DE ESCUDO NO HAY ESCUDO (el usuario: «si querés tener un
## escudo vas a tener un arma menos»). Mientras se mantiene `held` (el mando de ese brazo, la Q poseyéndola o en el modo
## manejo):
##   · DOS COSTOS, COMO MANÁ (22/11/2026; F3, pestaña Escudo: DashSettings.shield_cast y shield_hold): uno al activarlo y otro
##     por segundo mientras se mantiene, para que convenga predecir el golpe. Sin energía para activarlo, no sale; si se
##     acaba manteniéndolo, SE CORTA y hay que soltar y volver a apretar. Prendido, el brazo lo levanta (`tip.up`).
##   · FRENA LO QUE VIENE DE FRENTE: lo decide ToolMech.block_hit, que llama quien pega una vez por golpe.
##   · EL PARRY, APAGADO DE ENTRADA (`shield_parry`): devolvía el costo de activarlo a quien lo prendía justo a tiempo, y eso
##     anula el costo inicial. Cada golpe frenado, un destello donde pegó.
## *Hasta el 18/11/2026 era un campo que envolvía a la meca (una burbuja; se probaron también una cáscara pegada al
## cuerpo, una pantalla de frente y una caja): el usuario los descartó a todos. Están en el commit 20227d6.*

const PARRY := 0.3
const FLASH := Color(0.85, 0.9, 1.0)
## EL ARCO QUE SE VE: su alto (m) y en cuántos tramos se curva. Su radio y su abertura son los de su zona (MechSkills.shield).
const ARC_HIGH := 5.0
const ARC_STEPS := 28

## Lo que se pide: mantenido.
var held := false
## Si está prendido (y el brazo lo tiene levantado).
var on := false
var energy: MechEnergy = null
## El escudo del brazo (ver ToolMech._build_arms); sin él, no hay escudo.
var tip: ShieldTip = null
## HACIA DÓNDE LO APUNTA EL MOUSE (mundo, plano; 22/11/2026, tecla V, MechCrew). Con esto no hace falta un brazo de escudo.
var way := Vector3.ZERO
var _arc: MeshInstance3D = null
var _arc_drawn := Vector2.ZERO
var _held_was := false
var _since := 0.0
var _refunded := false


func _ready() -> void:
	name = "Escudo"


func _physics_process(delta: float) -> void:
	var asked := held and (tip != null or way.length() > 0.1)
	if asked and not _held_was and not on and energy != null and energy.spend(DashSettings.current.shield_cast / MechEnergy.UNIT):
		on = true
		_since = 0.0
		_refunded = false
	_held_was = asked
	if on:
		_since += delta
		if not asked or not energy.drain(DashSettings.current.shield_hold / MechEnergy.UNIT, delta):
			on = false
	if tip != null:
		tip.up = on
	_show_arc()


## EL ARCO DE LUZ, parado sobre el borde de su zona, del lado adonde apunta.
func _show_arc() -> void:
	var aimed := on and way.length() > 0.1
	if aimed and _arc == null:
		_arc = MeshInstance3D.new()
		var paint := EnergyBolt.shine(MechSkills.TINT)
		paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		paint.albedo_color.a = 0.45
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		_arc.material_override = paint
		_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_arc.top_level = true
		add_child(_arc)
	if _arc == null:
		return
	_arc.visible = aimed
	if not aimed:
		return
	var zone := MechSkills.shield()
	var shape := Vector2(zone["size"], zone["length"])
	if shape != _arc_drawn:
		_arc_drawn = shape
		_arc.mesh = MechShield._arc_mesh(shape.x, shape.y)
	var body := get_parent() as Node3D
	var at := body.global_position
	if body is BalanceBody:
		at.y = (body as BalanceBody).support.y
	_arc.global_transform = Transform3D(Basis.looking_at(way.normalized(), Vector3.UP), at)


## UNA BANDA CURVA, hacia −Z: `half` grados a cada lado, a `radius` metros del centro y de ARC_HIGH de alto.
static func _arc_mesh(half: float, radius: float) -> ArrayMesh:
	var points := PackedVector3Array()
	for index in ARC_STEPS:
		var a := deg_to_rad(-half + half * 2.0 * index / ARC_STEPS)
		var b := deg_to_rad(-half + half * 2.0 * (index + 1) / ARC_STEPS)
		var low_a := Vector3(sin(a), 0.0, -cos(a)) * radius
		var low_b := Vector3(sin(b), 0.0, -cos(b)) * radius
		var up := Vector3.UP * ARC_HIGH
		points.append_array(PackedVector3Array([low_a, low_b, low_b + up, low_a, low_b + up, low_a + up]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## UN GOLPE FRENADO (lo avisa ToolMech.block_hit, con dónde pegó si lo sabe): el destello y, si fue justo después de
## prenderlo, el parry.
func stopped(at := Vector3.INF) -> void:
	if at.is_finite() and is_inside_tree():
		EnergyBolt.flash(get_tree().current_scene, at, 0.5, FLASH)
		var sounds_node := MechSounds.of(self)
		if sounds_node != null:
			sounds_node.play_at(MechSounds.SHIELD_BLOCK, at)
	if DashSettings.current.shield_parry and on and _since <= PARRY and not _refunded and energy != null:
		_refunded = true
		energy.level = minf(energy.level + DashSettings.current.shield_cast / MechEnergy.UNIT, MechEnergy.capacity())
