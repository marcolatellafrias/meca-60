class_name MechArm
extends Node3D

## UN BRAZO DE LA MECA: el hombro, colgado del torso a un costado, que apunta hacia donde mira el que lo maneja (con
## topes: no gira para atrás). Cada brazo hace una cosa cuando se lo usa (`use`): el puño de resorte (MechFist) o el
## cañón (MechCannon). Cuando pega o dispara, empuja a la meca (`kick`, en el espacio del torso): eso mueve el equilibrio.
##
## A QUIÉN SE LE PEGA: a cualquier cuerpo que tenga `take_hit(amount, direction, push)` (ver BeastPart).

signal kicked(direction: Vector3, amount: float)

const YAW_LIMIT := deg_to_rad(70.0)
const PITCH_LIMIT := deg_to_rad(45.0)
const AIM_SPEED := 4.0

## El pivote que gira para apuntar; lo que sale del brazo cuelga de acá, hacia −Z.
var pivot: Node3D = null
var _yaw := 0.0
var _pitch := 0.0


func _ready() -> void:
	Clay.sphere(self, 1.2, Vector3.ZERO, Clay.DARK)
	pivot = Node3D.new()
	pivot.name = "Pivote"
	add_child(pivot)
	_build()


## Lo propio de cada brazo, colgado de `pivot`.
func _build() -> void:
	pass


## Apunta hacia `point` (en el mundo), de a poco y con topes.
func aim(point: Vector3, delta: float) -> void:
	var local := global_transform.affine_inverse() * point
	var flat := Vector2(local.x, local.z)
	var yaw := clampf(atan2(-local.x, -local.z), -YAW_LIMIT, YAW_LIMIT)
	var pitch := clampf(atan2(local.y, flat.length()), -PITCH_LIMIT, PITCH_LIMIT)
	var step := 1.0 - exp(-AIM_SPEED * delta)
	_yaw = lerp_angle(_yaw, yaw, step)
	_pitch = lerp_angle(_pitch, pitch, step)
	pivot.rotation = Vector3(_pitch, _yaw, 0.0)


## Hacia dónde apunta, en el mundo.
func pointing() -> Vector3:
	return -pivot.global_basis.z.normalized()


## Pegar o disparar. Devuelve si lo hizo (puede estar recargando).
func use() -> bool:
	return false


## Si está listo para usarse otra vez.
func ready_to_use() -> bool:
	return true


## Lo que tenga `take_hit` en `collider` o en sus padres.
static func hittable(collider: Object) -> Node:
	var node := collider as Node
	while node != null:
		if node.has_method("take_hit"):
			return node
		node = node.get_parent()
	return null
