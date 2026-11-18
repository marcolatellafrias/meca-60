extends Node

## EL ESQUELETO DE LA MECA, CONECTADO (sin ventana, unos 10 segundos): la meca jaula camina, dobla y tira una piña, y en
## cada paso se mide lo más que se separan los huesos de donde tienen que nacer (MechSkeleton): el muslo de su cadera
## (un punto fijo de la pelvis), la canilla de la punta del muslo, el pie de la punta de la canilla, el brazo de su
## hombro (un punto fijo del torso) y el antebrazo de la punta del brazo. Y que las caderas no se muevan respecto de la
## pelvis (la pelvis rígida: el usuario, «nunca pueden quebrarse»). Imprime «ESQUELETO OK» si todo queda a menos de 1 cm.
##   godot --headless --path . res://tests/mech_skeleton_check.tscn

const TOLERANCE := 0.01

var _worst := {}


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var mech := CageMech.new()
	mech.scripted = true
	mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
	add_child(mech)
	var skeleton := mech.skeleton
	var hip_rest: Array[Vector3] = [skeleton.hips[0].position, skeleton.hips[1].position]
	var clock := 0.0
	var punched := false
	while clock < 6.0:
		mech.move = Vector2(0.0, 1.0) if clock < 2.5 else (Vector2(1.0, 0.0) if clock < 4.0 else Vector2.ZERO)
		mech.aim_yaw += 0.6 / Engine.physics_ticks_per_second if clock > 1.0 and clock < 3.0 else 0.0
		if clock > 4.2 and not punched:
			punched = true
			for arm in mech.arms:
				arm.punch(MechArm.Punch.STRAIGHT)
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		for side in 2:
			_measure("muslo en su cadera", skeleton.thighs[side].global_position, skeleton.hips[side].global_position)
			_measure("canilla en la punta del muslo", skeleton.shins[side].global_position,
				_end(skeleton.thighs[side]))
			_measure("pie en la punta de la canilla", skeleton.feet[side].global_position, _end(skeleton.shins[side]))
			_measure("brazo en su hombro (%s)" % ("izq" if side == 0 else "der"), skeleton.uppers[side].global_position,
				skeleton.shoulders[side].global_position)
			_measure("antebrazo en la punta del brazo (%s)" % ("izq" if side == 0 else "der"), skeleton.forearms[side].global_position,
				_end(skeleton.uppers[side]))
			_measure("cadera fija en la pelvis", skeleton.hips[side].position, hip_rest[side])
	var ok := true
	for what: String in _worst:
		var gap: float = _worst[what]
		ok = ok and gap < TOLERANCE
		print("%s: lo más que se separó, %.4f m" % [what, gap])
	print("ESQUELETO OK" if ok else "ESQUELETO: HAY HUESOS SUELTOS")
	get_tree().quit()


## La punta de un hueso (a lo largo de su +Y).
static func _end(bone: CustomBone) -> Vector3:
	return bone.global_transform * Vector3(0.0, bone.length, 0.0)


func _measure(what: String, a: Vector3, b: Vector3) -> void:
	_worst[what] = maxf(float(_worst.get(what, 0.0)), a.distance_to(b))
