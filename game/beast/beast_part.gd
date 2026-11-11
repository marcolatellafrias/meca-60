class_name BeastPart
extends StaticBody3D

## UNA PARTE DEL BICHO que se puede romper: el cuerpo, un tentáculo, un ojo, un cuerno. Tiene su vida (`health`); cada
## golpe le saca y empuja al bicho (ver TestBeast.push). Al llegar a cero SE ROMPE: se suelta y cae como un pedazo
## suelto, y el bicho la pierde. Encima, un número con su vida, para probar.
##
## Las mallas de la parte cuelgan de acá; el choque es una sola caja o esfera que pone quien la arma.

signal broken(part: BeastPart)

var part_name := "parte"
var health := 50.0
var max_health := 50.0
var beast: Node = null
var _label: Label3D = null
var _flash := 0.0
var _materials: Array[StandardMaterial3D] = []


func setup(p_name: String, p_health: float, p_beast: Node, label_height: float) -> void:
	part_name = p_name
	health = p_health
	max_health = p_health
	beast = p_beast
	_label = Label3D.new()
	_label.font_size = 48
	_label.pixel_size = 0.012
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, label_height, 0)
	_label.modulate = Color(1.0, 0.95, 0.6)
	_label.outline_size = 12
	add_child(_label)
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var own := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		mesh.material_override = own
		_materials.append(own)
	_refresh()


func is_broken() -> bool:
	return health <= 0.0


## Un golpe: le saca vida, se pone roja un momento y empuja al bicho hacia `direction`.
func take_hit(amount: float, direction: Vector3, push: float) -> void:
	if is_broken():
		return
	health = maxf(health - amount, 0.0)
	_flash = 0.25
	if beast != null and beast.has_method("push"):
		beast.push(direction, push)
	_refresh()
	if is_broken():
		_break()


func _process(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash = maxf(_flash - delta, 0.0)
	for material in _materials:
		material.emission_enabled = _flash > 0.0
		material.emission = Color(1.0, 0.2, 0.1) * (_flash * 4.0)


func _refresh() -> void:
	_label.text = "%s %d" % [part_name, ceili(health)]


## SE ROMPE: un pedazo suelto con las mismas mallas cae al suelo; la parte deja de chocar y de verse.
func _break() -> void:
	var chunk := RigidBody3D.new()
	chunk.name = "Pedazo de " + part_name
	chunk.mass = 500.0
	get_tree().current_scene.add_child(chunk)
	chunk.global_transform = global_transform
	for child in get_children():
		if child is MeshInstance3D:
			var copy := (child as MeshInstance3D).duplicate() as MeshInstance3D
			chunk.add_child(copy)
		elif child is CollisionShape3D:
			chunk.add_child((child as CollisionShape3D).duplicate())
	chunk.linear_velocity = Vector3(randf_range(-3, 3), 4.0, randf_range(-3, 3))
	chunk.angular_velocity = Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2))
	visible = false
	collision_layer = 0
	collision_mask = 0
	_label.visible = false
	broken.emit(self)
