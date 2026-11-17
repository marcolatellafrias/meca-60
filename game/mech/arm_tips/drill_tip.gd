class_name DrillTip
extends SpinTip

## EL TALADRO (ver SpinTip): un collar y un cono que gira, apuntando a lo largo del antebrazo, en vez de la mano.

const BIT := Color(0.62, 0.6, 0.55)


func _build() -> void:
	var thick := arm.measures.thick
	var holder := Node3D.new()
	holder.position = Vector3(0.0, 0.0, -arm.forearm_length() * 0.5)
	holder.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	forearm.add_child(holder)
	Clay.cylinder(holder, 0.75 * thick, 0.5 * thick, Vector3(0.0, 0.25 * thick, 0.0), MechBody.JOINT_COLOR)
	_spinner = Node3D.new()
	_axis = Vector3.UP
	holder.add_child(_spinner)
	var cone := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.6 * thick
	mesh.height = 2.4 * thick
	mesh.radial_segments = 6
	cone.mesh = mesh
	cone.material_override = Clay.material(BIT)
	cone.position = Vector3(0.0, (0.5 + 1.2) * thick, 0.0)
	_spinner.add_child(cone)
	# Una aleta, para que se vea girar.
	Clay.box(_spinner, Vector3(1.3 * thick, 0.12 * thick, 0.12 * thick), Vector3(0.0, 1.0 * thick, 0.0), BIT.darkened(0.4))
