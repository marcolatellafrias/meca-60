extends Node

## LA TABLA DE ANIMACIÓN PROCEDURAL SOBRE PIEZAS COMUNES (sin ventana, un instante): un cuerpo de arcilla (una pelvis
## y un torso, Node3D sueltos, no huesos de personaje) con sus señales (una MotionSignals de prueba) y dos filas de la
## tabla: el torso se inclina de costado según la velocidad de costado (H_VEL_X → ROT_Z) y la pelvis sube y baja con el
## paso (STEP_PROGRESS → POS_Y). Imprime la inclinación y la altura yendo de costado, quieto y dando un paso, y que
## vuelvan al reposo.

class TestSignals extends MotionSignals:
	var up := 0.0
	func vertical_velocity() -> float:
		return up


func _ready() -> void:
	var pelvis := Node3D.new()
	add_child(pelvis)
	var torso := Node3D.new()
	torso.position = Vector3(0.0, 1.0, 0.0)
	pelvis.add_child(torso)
	var signals := TestSignals.new()
	var table := ProceduralBoneAnimator.create(signals)
	table.register(torso, ProceduralBoneAnimator.Axis.ROT_Z, ProceduralBoneAnimator.SignalType.H_VEL_X, -0.05)
	table.register(pelvis, ProceduralBoneAnimator.Axis.POS_Y, ProceduralBoneAnimator.SignalType.STEP_PROGRESS, -0.2)
	for case: Array in [["quieto", Vector2.ZERO, 0.0], ["de costado a 4 m/s", Vector2(4.0, 0.0), 0.0],
			["a mitad de un paso", Vector2.ZERO, 1.0], ["quieto otra vez", Vector2.ZERO, 0.0]]:
		signals.horizontal_velocity_smooth = case[1]
		signals.step_progress = case[2]
		table.update()
		print("%s: el torso inclinado %.1f° · la pelvis a %.2f m" % [case[0], rad_to_deg(torso.rotation.z),
			pelvis.position.y])
	get_tree().quit()
