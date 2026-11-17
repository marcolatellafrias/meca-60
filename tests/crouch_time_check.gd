extends Node3D

## CUÁNTO TARDA EN AGACHARSE LA MECA JAULA (16/11/2026; el usuario: «tarda muchísimo más que 0,5»): arma la parcela,
## pide agacharse y mide, cada décima de reloj, lo agachado del que la mueve (KinematicMover.crouched) y la altura de la
## caja, y cuántos pasos de física corrieron de verdad por segundo (el proyecto pide 240): si no llegan, el juego va en
## cámara lenta y todo tarda más.

func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var holder := Node3D.new()
	add_child(holder)
	CageMechArchetype.new().build(0, holder)
	await get_tree().create_timer(2.0).timeout
	var mech: CageMech = holder.find_children("*", "CageMech", true, false)[0]
	mech.scripted = true
	var k := mech.kinematic_settings()
	print("PERILLAS: ritmo %.2f · parte %.2f · las de la jaula: %s" % [k.crouch_rate, k.crouch_share, k == CageMech.MOVES])
	var start := Time.get_ticks_msec()
	var steps_at := Engine.get_physics_frames()
	mech.crouch = true
	for i in 30:
		await get_tree().create_timer(0.1, true, false, true).timeout
		var wall := (Time.get_ticks_msec() - start) / 1000.0
		print("reloj %.2f s · pasos de física por s %d · cuadros por s %d · agachada %.2f · caja a %.3f m" % [wall,
			roundi((Engine.get_physics_frames() - steps_at) / maxf(wall, 0.001)), roundi(Engine.get_frames_per_second()),
			mech.mover.crouched, mech.global_position.y])
	get_tree().quit()
