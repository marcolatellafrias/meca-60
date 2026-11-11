class_name MechFist
extends MechArm

## EL PUÑO DE RESORTE, como los brazos de ARMS: el guante sale disparado hacia adelante estirando un resorte, pega en lo
## primero que toca y vuelve. Tarda en ir y volver, así que hay que pegar a tiempo. Al tirarlo, el peso se va para
## adelante: la meca se inclina hacia donde pegó (ver MechArm.kicked).

const REST := 3.0
const REACH := 17.0
const OUT_TIME := 0.22
const HOLD_TIME := 0.12
const BACK_TIME := 0.5
const DAMAGE := 25.0
const PUSH := 1.4
const KICK := 1.5

var _glove: Node3D = null
var _spring: MeshInstance3D = null
var _area: Area3D = null
var _clock := -1.0
var _extension := REST
var _hit := {}


func _build() -> void:
	Clay.box(pivot, Vector3(1.4, 1.4, 2.6), Vector3(0, 0, -1.3), Clay.METAL.darkened(0.1))
	_spring = Clay.cylinder(pivot, 0.35, 1.0, Vector3.ZERO, Clay.YELLOW, Vector3(90, 0, 0))
	_glove = Node3D.new()
	_glove.name = "Guante"
	pivot.add_child(_glove)
	Clay.sphere(_glove, 1.4, Vector3.ZERO, Clay.RED)
	Clay.box(_glove, Vector3(1.6, 1.2, 1.0), Vector3(0, 0, 0.9), Clay.RED.darkened(0.3))
	_area = Area3D.new()
	_area.monitoring = true
	_area.monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.8
	shape.shape = sphere
	_area.add_child(shape)
	_glove.add_child(_area)
	_place()


func ready_to_use() -> bool:
	return _clock < 0.0


func use() -> bool:
	if _clock >= 0.0:
		return false
	_clock = 0.0
	_hit.clear()
	kicked.emit(pointing(), KICK)
	return true


func _physics_process(delta: float) -> void:
	if _clock < 0.0:
		return
	_clock += delta
	var going := _clock < OUT_TIME + HOLD_TIME
	if _clock < OUT_TIME:
		_extension = lerpf(REST, REACH, ease(_clock / OUT_TIME, 0.4))
	elif going:
		_extension = REACH
	elif _clock < OUT_TIME + HOLD_TIME + BACK_TIME:
		_extension = lerpf(REACH, REST, ease((_clock - OUT_TIME - HOLD_TIME) / BACK_TIME, 2.0))
	else:
		_extension = REST
		_clock = -1.0
	_place()
	if going:
		_strike()


## Lo que toca el guante mientras sale: le pega una vez por golpe, y el guante se frena ahí.
func _strike() -> void:
	for body in _area.get_overlapping_bodies():
		var target := MechArm.hittable(body)
		if target == null or _hit.has(target.get_instance_id()):
			continue
		_hit[target.get_instance_id()] = true
		target.take_hit(DAMAGE, pointing(), PUSH)
		_clock = maxf(_clock, OUT_TIME)


func _place() -> void:
	_glove.position = Vector3(0, 0, -_extension)
	var length := maxf(_extension - 2.6, 0.1)
	_spring.scale = Vector3(1.0, length, 1.0)
	_spring.position = Vector3(0, 0, -2.6 - length * 0.5)
