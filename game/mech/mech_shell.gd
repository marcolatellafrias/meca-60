class_name MechShell
extends RigidBody3D

## UNA BALA DEL CAÑÓN: una bola pesada que cae un poco. Al tocar algo le pega si se deja (ver MechArm.hittable), hace un
## fogonazo y desaparece.

const SPEED := 140.0
const DAMAGE := 14.0
const PUSH := 0.7
const LIFETIME := 4.0

var _age := 0.0


func _init() -> void:
	name = "Bala"
	mass = 40.0
	gravity_scale = 0.3
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 1
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.45
	shape.shape = sphere
	add_child(shape)
	Clay.sphere(self, 0.45, Vector3.ZERO, Clay.DARK.darkened(0.4))
	body_entered.connect(_on_body)


func launch(at: Vector3, direction: Vector3) -> void:
	global_position = at
	linear_velocity = direction * SPEED


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body(body: Node) -> void:
	var target := MechArm.hittable(body)
	if target != null:
		target.take_hit(DAMAGE, linear_velocity.normalized(), PUSH)
	MechShell.flash(get_parent(), global_position)
	queue_free()


## Un fogonazo que crece y se apaga.
static func flash(parent: Node, at: Vector3) -> void:
	if parent == null:
		return
	var burst := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	burst.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.7, 0.2, 0.9)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.6, 0.1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	burst.material_override = material
	parent.add_child(burst)
	burst.global_position = at
	var tween := burst.create_tween().set_parallel(true)
	tween.tween_property(burst, "scale", Vector3.ONE * 3.0, 0.3)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
	tween.chain().tween_callback(burst.queue_free)
