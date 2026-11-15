extends Node3D

## QUÉ TAN RÁPIDO RESPONDE EL BRAZO CON MÚSCULOS (sin ventana, unos 20 segundos): las cuatro piñas, cada una con el brazo
## y el bloque recién puestos. Por piña: cuándo llega la mano adonde pega (a menos de 1 m) contra cuándo lo pide el
## guion, a qué velocidad llega, cuánto SE PASA de largo (el látigo), lo más rápido que gira una pieza y que sale el
## bloque (si algo explota). Con «-- --sin-seguir» apaga lo de seguir la velocidad pedida (MuscleArmSettings.follow);
## con «-- --rapidas=2», pide las piñas el doble de rápido.
##   godot --headless --path . res://tests/muscle_arm_speed_check.tscn

const REACHED := 1.0

var _kind := MuscleArmArchetype.new()
var _stage: Node3D = null
var _arm: MuscleArm = null
var _block: RigidBody3D = null


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	add_child(ground)
	if OS.get_cmdline_user_args().has("--sin-seguir"):
		MuscleArmSettings.current.follow = 0.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--rapidas="):
			MuscleArmSettings.current.punch_speed = float(argument.trim_prefix("--rapidas="))
	var k := MuscleArmSettings.current
	print("BRAZO: resorte %.0f · freno %.0f · fuerza tope %.0f · seguir la velocidad %.2f · piñas ×%.2f" % [k.muscle_kp,
		k.muscle_kd, k.muscle_max, k.follow, k.punch_speed])
	for kind: int in [MechArm.Punch.STRAIGHT, MechArm.Punch.HOOK, MechArm.Punch.UPPERCUT, MechArm.Punch.HAMMER]:
		await _fresh()
		await _seconds(1.5)
		var steps: Array = MechArm.PUNCHES[kind]
		var asked := (float(steps[0][0]) + float(steps[1][0])) / k.punch_speed
		var base := _arm.anchor.global_transform
		var shoulder := base * _arm.shoulder_local
		var target := shoulder + base.basis * _arm._local((steps[1][1] as Vector3) * _arm.reach())
		var windup := shoulder + base.basis * _arm._local((steps[0][1] as Vector3) * _arm.reach())
		var way := (target - windup).normalized()
		_arm.punch(kind as MechArm.Punch)
		var clock := 0.0
		var arrived := -1.0
		var past := 0.0
		var spin := 0.0
		var block := 0.0
		while clock < 2.5:
			await get_tree().physics_frame
			clock += 1.0 / Engine.physics_ticks_per_second
			var hand := _arm.forearm.global_transform * Vector3(0, 0, -_arm.forearm_length() * 0.5)
			if arrived < 0.0 and hand.distance_to(target) < REACHED:
				arrived = clock
			if clock < asked + float(steps[2][0]) / k.punch_speed:
				past = maxf(past, (hand - target).dot(way))
			spin = maxf(spin, maxf(_arm.upper.angular_velocity.length(), _arm.forearm.angular_velocity.length()))
			block = maxf(block, _block.linear_velocity.length())
		print("%s: el guion pide llegar a los %.2f s · llegó a los %s · la mano a %.0f m/s · se pasó %.1f m · giro más rápido %.0f rad/s · el bloque a %.1f m/s" % [
			MechArm.NAMES[kind], asked, ("%.2f s" % arrived) if arrived >= 0.0 else "NUNCA", _arm.top_speed, past, spin,
			block])
	get_tree().quit()


func _fresh() -> void:
	if is_instance_valid(_stage):
		_stage.queue_free()
		await get_tree().process_frame
	_stage = _kind.build(0, self)
	_arm = _stage.find_children("*", "MuscleArm", true, false)[0] as MuscleArm
	_block = _stage.find_child("Bloque", true, false) as RigidBody3D


func _seconds(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
