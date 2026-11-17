extends Node3D

## ¿LOS PIES DE LA MECA JAULA TOCAN EL PISO? (16/11/2026; el usuario: «cuando se agacha, los pies se bajan, y cuando no se
## agacha están flotando»). Arma la parcela, la deja parada y después agachada, e imprime dónde está el piso (el del que
## la mueve), la cara de abajo de la caja, las caderas, los tobillos y la suela de cada pie.

func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var holder := Node3D.new()
	add_child(holder)
	CageMechArchetype.new().build(0, holder)
	await get_tree().create_timer(2.5).timeout
	var mech: CageMech = holder.find_children("*", "CageMech", true, false)[0]
	mech.scripted = true
	_report(mech, "PARADA")
	mech.crouch = true
	await get_tree().create_timer(1.5).timeout
	_report(mech, "AGACHADA")
	get_tree().quit()


func _report(mech: CageMech, label: String) -> void:
	var m := mech.measures
	var line := "%s · piso %.3f · fondo de la caja %.3f · hover %.3f · cintura %.3f · muslo+canilla %.3f · tobillo %.3f" % [
		label, mech.mover.global_position.y, mech.global_position.y - mech.size.y * 0.5, mech.mover._hover_now(),
		m.WAIST, m.THIGH + m.SHIN, m.ANKLE]
	print(line)
	for found in mech.find_children("*", "MechLeg", true, false):
		var leg := found as MechLeg
		var sole := leg._foot.global_position.y - m.FOOT_SIZE.y * 0.5
		var ball := leg._ankle.global_position.y - m.JOINT_RADIUS * MechBody.ANKLE_SHARE
		print("   pierna: cadera %.3f · tobillo %.3f · suela %.3f · fondo de la esfera del tobillo %.3f · de cadera a tobillo %.2f del largo" % [
			leg._hip.global_position.y, leg._ankle.global_position.y, sole, ball,
			leg._hip.global_position.distance_to(leg._ankle.global_position) / (m.THIGH + m.SHIN)])
