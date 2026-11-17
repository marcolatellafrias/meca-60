class_name SawTip
extends SpinTip

## LA SIERRA CIRCULAR (ver SpinTip; el usuario, 16/11/2026: «agregaría la sierra también»): la de la armería
## (ArmoryParts.saw_frame y saw_disc), un disco grande parado en el eje del antebrazo con su horquilla, saliendo de la
## boca; el disco gira. Se carga y se descarga como el taladro.


func _build() -> void:
	var k := arm.measures.thick
	_mouth()
	# La maqueta se arma para el antebrazo de la armería (su punta en ArmoryParts.TIP): se corre a la punta de éste.
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * k
	holder.position = Vector3(0, 0, -arm.forearm_length() * 0.5 - (0.3 + ArmoryParts.TIP) * k)
	forearm.add_child(holder)
	_spinner = Node3D.new()
	_spinner.position = ArmoryParts.saw_frame(holder)
	_axis = Vector3.RIGHT
	holder.add_child(_spinner)
	ArmoryParts.saw_disc(_spinner)


func _hit_name() -> String:
	return "sierra"
