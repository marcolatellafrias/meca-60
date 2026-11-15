class_name EnergyBolt
extends Node3D

## UN TIRO DEL CAÑÓN DE ENERGÍA: una bola de luz que va derecho a `speed`, y lo primero suelto que toca recibe UN
## IMPULSO (`push`, en kg·m/s) hacia donde iba; a una meca, por su puerta (BalanceBody.hit). Lo fijo la apaga. Se
## dibuja estirada a lo largo de su camino, y al pegar deja un destello.
## *Sólo local: todavía no va por la red (los proyectiles de verdad, ProjectileField).*

const MASK := 1
## Cuánto vive como mucho (s).
const LIFE := 1.6

var speed := 140.0
var push := 60000.0
var radius := 0.3
var color := Color(1.0, 0.55, 0.15)
## Lo que no toca (la meca que tira).
var exclude: Array[RID] = []

var _life := 0.0


func _ready() -> void:
	top_level = true
	var glow := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(radius * 2.0, speed * 0.03)
	glow.mesh = mesh
	glow.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	glow.material_override = shine(color)
	add_child(glow)


func _physics_process(delta: float) -> void:
	_life += delta
	var from := global_position
	var to := from - global_basis.z * speed * delta
	var query := PhysicsRayQueryParameters3D.create(from, to, MASK, exclude)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var body := struck(hit["collider"])
		if body != null:
			BalanceBody.hit(body, -global_basis.z * push, (hit["position"] as Vector3) - body.global_position)
		flash(get_parent(), hit["position"], radius * 3.0, color)
		queue_free()
		return
	global_position = to
	if _life > LIFE:
		queue_free()


## A QUIÉN LE PEGA lo que toca un tiro: si es una pieza de una meca (un pie, una tobera), a la meca; si no, a lo que
## sea suelto. Lo fijo, a nadie.
static func struck(collider: Object) -> RigidBody3D:
	var node := collider as Node
	while node != null:
		if node is BalanceBody:
			return node as RigidBody3D
		node = node.get_parent()
	return collider as RigidBody3D


## Un material que brilla, sin sombra.
static func shine(tint: Color) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = tint
	paint.emission_enabled = true
	paint.emission = tint
	return paint


## UN DESTELLO en `at` que se agranda y se apaga en un instante.
static func flash(parent: Node, at: Vector3, size: float, tint: Color) -> void:
	if parent == null:
		return
	var spark := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = size
	ball.height = size * 2.0
	spark.mesh = ball
	var paint := shine(tint)
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark.material_override = paint
	parent.add_child(spark)
	spark.global_position = at
	var fade := spark.create_tween()
	fade.set_parallel(true)
	fade.tween_property(spark, "scale", Vector3.ONE * 2.0, 0.25)
	fade.tween_property(paint, "albedo_color:a", 0.0, 0.25)
	fade.chain().tween_callback(spark.queue_free)
