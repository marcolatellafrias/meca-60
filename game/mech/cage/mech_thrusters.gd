class_name MechThrusters
extends Node3D

## LOS DOS PROPULSORES DE LA ESPALDA (22/11/2026; el usuario: que se vea cuando dashea o hace el sobrevuelo). Dos toberas
## fijas al torso con su llama: un golpe corto en la ráfaga, sostenida en el sobrevuelo. La llama sale de LO RÁPIDO QUE VA
## la meca, así se ve igual en todas las máquinas sin mandar nada por la red.

const COLOR := Color(0.24, 0.25, 0.27)
const FLAME := Color(1.0, 0.55, 0.12)
## Cuánto más que caminar tiene que ir para que se prenda, y cuánto sigue prendida al frenar (s).
const FAST := 1.5
const HOLD := 0.16
const RADIUS := 0.34
const LONG := 0.65
const FLAME_LONG := 2.2
const FLAME_RATE := 18.0

var mech: CageMech = null
var _flames: Array[MeshInstance3D] = []
var _last := Vector3.INF
var _lit := 0.0
var _size := 0.0


func _init() -> void:
	name = "Propulsores"


func _ready() -> void:
	var box := CageCabin.box()
	var high := CageCabin.shoulder().y
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = FLAME
	var cone := CylinderMesh.new()
	cone.top_radius = 0.03
	cone.bottom_radius = RADIUS * 0.8
	cone.height = 1.0
	cone.radial_segments = 12
	cone.material = paint
	for side: float in [-1.0, 1.0]:
		# El eje de los cilindros (+Y) hacia atrás de la meca (+Z).
		var holder := Node3D.new()
		holder.position = Vector3(side * box.x * 0.26, high, box.z * 0.5 + LONG * 0.5)
		holder.rotation.x = PI * 0.5
		add_child(holder)
		Clay.cylinder(holder, RADIUS, LONG, Vector3.ZERO, COLOR)
		var flame := MeshInstance3D.new()
		flame.mesh = cone
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flame.visible = false
		holder.add_child(flame)
		_flames.append(flame)


func _physics_process(delta: float) -> void:
	var at := mech.global_position
	at.y = 0.0
	var speed := 0.0 if _last == Vector3.INF else at.distance_to(_last) / delta
	_last = at
	var going := mech.state == BalanceBody.State.STANDING and speed > mech.kinematic_settings().walk_speed * FAST
	_lit = HOLD if going else maxf(_lit - delta, 0.0)


func _process(delta: float) -> void:
	_size = move_toward(_size, 1.0 if _lit > 0.0 else 0.0, FLAME_RATE * delta)
	for flame in _flames:
		flame.visible = _size > 0.01
		flame.scale = Vector3(1.0, maxf(_size * FLAME_LONG, 0.01), 1.0)
		flame.position.y = LONG * 0.5 + _size * FLAME_LONG * 0.5
