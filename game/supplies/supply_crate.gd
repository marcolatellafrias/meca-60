class_name SupplyCrate
extends ActivatableInteractable

## UN PAQUETE (22/11/2026; el usuario: «no va a ser un PD controller cuando lo agarra, sino que simplemente se va a atar las
## manos… como si fuera un objeto cinemático»). No tiene física: cae del tubo con una curva, queda en el piso, y mientras
## se lo lleva va pegado adelante del pecho, con las dos manos en sus costados (`carry_pose`). Quién lo tiene y dónde queda
## lo decide el host (BaseSupplies).

const GROUP := "supply_crates"
const HALF := SupplyLook.H
const FALL := 18.0
const BOUNCE := 0.28
## Dónde va al llevarlo, desde la cadera: adelante y arriba (m).
const CARRY_AHEAD := 0.56
const CARRY_UP := 0.2
const HAND_OUT := 0.02

var id := 0
var kind := SupplyKinds.Kind.BULLETS
## De qué tubo salió y si sigue en su lugar (cuando no, el tubo tira otro).
var tube := -1
var on_pad := false
var carrier: BoneInstantiator = null
var _falling := false
var _speed := Vector3.ZERO
var _rest := Vector3.ZERO


func _init() -> void:
	top_level = true
	add_to_group(GROUP)


## LO ARMA en `at` y, si `to` es otro punto, cae hasta ahí (el piso, en su base).
func setup(crate_id: int, crate_kind: int, at: Vector3, to: Vector3) -> void:
	id = crate_id
	kind = crate_kind as SupplyKinds.Kind
	name = "Paquete %d" % crate_id
	var cube := Node3D.new()
	cube.name = "Cubo"
	add_child(cube)
	SupplyLook.crate(cube, SupplyKinds.body_color(kind), SupplyKinds.tag_color(kind))
	Clay.box(cube, Vector3(SupplyLook.U + 0.012, 0.09, SupplyLook.U + 0.012), Vector3(0.0, -0.17, 0.0),
		SupplyKinds.tag_color(kind))
	var sign := Label3D.new()
	sign.text = SupplyKinds.title(kind)
	sign.font_size = 34
	sign.pixel_size = 0.006
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.no_depth_test = true
	sign.outline_size = 8
	sign.position = Vector3.UP * (HALF + 0.3)
	add_child(sign)
	global_position = at
	land_at(to, at.distance_to(to + Vector3.UP * HALF) > 0.05)


## VA A `to` (el piso): cayendo, o directo.
func land_at(to: Vector3, fall: bool) -> void:
	_rest = to + Vector3.UP * HALF
	_falling = fall
	if fall:
		var flat := Vector3(_rest.x - global_position.x, 0.0, _rest.z - global_position.z)
		var time := sqrt(maxf(2.0 * (global_position.y - _rest.y), 0.01) / FALL)
		_speed = flat / maxf(time, 0.05)
	else:
		global_transform = Transform3D(Basis(), _rest)


func can_interact() -> bool:
	if carrier != null or _falling or BaseSupplies.current == null:
		return false
	var player := DesignSandbox.player_of(get_tree())
	return is_instance_valid(player) and not is_instance_valid(player.carried)


func activate(actor: Node = null) -> void:
	super.activate(actor)
	if BaseSupplies.current != null:
		BaseSupplies.current.ask_take(id)


## LO LLEVA `bi` (null, nadie).
func held_by(bi: BoneInstantiator) -> void:
	carrier = bi
	if bi != null:
		_falling = false
		on_pad = false
		bi.carried = self


## LO PONE ADELANTE DEL PECHO Y ATA LAS MANOS A SUS COSTADOS (lo llama el cuerpo, antes de resolver los brazos).
func carry_pose(bi: BoneInstantiator) -> void:
	var yaw := bi.char_rigidbody.global_rotation.y
	var turn := Basis(Vector3.UP, yaw)
	var ahead := turn * Vector3.FORWARD
	var side := turn * Vector3.RIGHT
	var hip := bi.custom_bones_util.lower_spine.global_position
	var middle := hip + ahead * CARRY_AHEAD + Vector3.UP * CARRY_UP
	global_transform = Transform3D(turn, middle)
	var ik := bi.ik_util
	var reach := HALF + HAND_OUT
	ik.left_arm_ik_target.global_position = middle - side * reach
	ik.right_arm_ik_target.global_position = middle + side * reach
	ik.left_arm_pole.global_position = middle - side * (reach + 0.6) - ahead * 0.5 + Vector3.DOWN * 0.3
	ik.right_arm_pole.global_position = middle + side * (reach + 0.6) - ahead * 0.5 + Vector3.DOWN * 0.3


func _physics_process(delta: float) -> void:
	if not _falling:
		return
	_speed.y -= FALL * delta
	var at := global_position + _speed * delta
	if at.y <= _rest.y:
		at = Vector3(_rest.x, _rest.y, _rest.z)
		if absf(_speed.y) > 2.0:
			_speed = Vector3(0.0, -_speed.y * BOUNCE, 0.0)
		else:
			_speed = Vector3.ZERO
			_falling = false
	global_position = at
