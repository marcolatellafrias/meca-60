extends Node3D

## LEVANTARSE DEL RAGDOLL CON LA MEZCLA COMÚN (con o sin ventana, unos 20 segundos): la vuelta del ragdoll es la misma
## para los personajes y para la meca (RagdollBlend).
##   · LOS PERSONAJES: uno de cada arquetipo recibe un golpe que lo tira, y se mide que se levante (RagdollUtil: la
##     mezcla común más sus piernas por IK) y cuánto quedan los cuerpos de sus huesos al terminar.
##   · LA MECA JAULA: muere de un golpe (PartsRagdoll), se le devuelve la vida y se levanta (PartsRagdoll.get_up): se
##     mide que vuelva a andar, que cada malla vuelva a su hueso (el esqueleto, conectado: ver mech_skeleton_check) y
##     que no quede ningún pedazo. Hoy la meca no se levanta en el juego: queda lista para cuando se use.
## Con --write-movie, un video (la cámara mira a la meca).
##   godot --headless --path . res://tests/ragdoll_rise_check.tscn

var _eye: Camera3D = null


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	_eye = Camera3D.new()
	add_child(_eye)
	_eye.make_current()
	await _people()
	await _mech()
	get_tree().quit()


## LOS PERSONAJES: un golpe que los tira, y hasta que se levantan.
func _people() -> void:
	var people: Array[BoneInstantiator] = []
	var index := 0
	for archetype: int in PeopleArchetype.ROW_ORDER:
		people.append(PeopleArchetype.spawn(self, archetype as EntityArchetype.Archetype, Vector3(-30.0 + index * 3.0,
			0.0, 20.0), 0.0))
		index += 1
	_eye.global_transform = Transform3D(Basis(), Vector3(-25.0, 4.0, 32.0)).looking_at(Vector3(-25.0, 1.0, 20.0))
	await _wait(1.5)
	for person in people:
		person.char_rigidbody.hit(Vector3(0.0, 0.0, 1200.0))
	var fell := {}
	var rose_at := {}
	var clock := 0.0
	while clock < 9.0:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		for person in people:
			if person._is_ragdolling():
				fell[person] = true
			elif fell.has(person) and not rose_at.has(person) and not person.ragdoll_util.is_recovering:
				rose_at[person] = clock
	for person in people:
		var gap := 0.0
		var rag := person.ragdoll_util
		for bone: CustomBone in rag._bodies:
			var rb: RigidBody3D = rag._bodies[bone]
			if is_instance_valid(rb):
				gap = maxf(gap, rb.global_position.distance_to(bone.global_position))
		print("%s: %s · %s · al terminar, los cuerpos a %.3f m de sus huesos" % [person.name,
			"se cayó" if fell.has(person) else "NO SE CAYÓ",
			("se levantó a los %.1f s" % rose_at[person]) if rose_at.has(person) else "NO SE LEVANTÓ", gap])


## LA MECA: muere, revive y se levanta.
func _mech() -> void:
	var mech := CageMech.new()
	mech.scripted = true
	mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
	add_child(mech)
	mech.label.visible = false
	Health.attach(mech, 100.0)
	_eye.global_transform = Transform3D(Basis(), Vector3(13.0, 5.0, 9.0)).looking_at(Vector3(0.0, 1.5, -4.0))
	await _wait(1.0)
	HitReaction.land(mech, 1000.0, "prueba", HitReaction.Kind.KNOCKDOWN, Vector3.FORWARD, 8.0, mech.global_position)
	await _follow(mech, 3.0)
	var ragdoll := PartsRagdoll.of(mech)
	var pieces := ragdoll.bodies.size() if ragdoll != null else 0
	print("la meca: murió en %d pedazos · anda %s" % [pieces, mech.can_process()])
	if ragdoll == null:
		return
	Health.of(mech).left = Health.of(mech).full
	ragdoll.get_up(0.8)
	await _follow(mech, 2.0)
	var clock := 0.0
	var left := get_tree().get_nodes_in_group(PartsRagdoll.GROUP).filter(func(n: Node) -> bool:
		return not n.is_queued_for_deletion()).size()
	var skeleton := mech.skeleton
	var worst := 0.0
	for side in 2:
		worst = maxf(worst, skeleton.thighs[side].global_position.distance_to(skeleton.hips[side].global_position))
		worst = maxf(worst, skeleton.uppers[side].global_position.distance_to(skeleton.shoulders[side].global_position))
	var thigh_piece: Node3D = mech.legs.get("_legs")[0].get("_thigh")
	print("la meca: se levantó · anda %s · se ve %s · pedazos que quedan %d · el muslo cuelga de su hueso %s · uniones a %.3f m" % [
		mech.can_process(), mech.visible, left, thigh_piece.get_parent() == skeleton.thighs[0], worst])
	# Que vuelva a caminar.
	var from := mech.mover.global_position
	clock = 0.0
	while clock < 1.5:
		mech.move = Vector2(0.0, 1.0)
		await _follow(mech, 1.0 / Engine.physics_ticks_per_second)
		clock += 1.0 / Engine.physics_ticks_per_second
	mech.move = Vector2.ZERO
	print("la meca: caminó %.1f m después de levantarse" % mech.mover.global_position.distance_to(from))


## La cámara sigue a la meca (a su tronco, si está desarmada) `seconds` s.
func _follow(mech: Mech, seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		var ragdoll := PartsRagdoll.of(mech)
		var at := mech.global_position
		if ragdoll != null and not ragdoll.bodies.is_empty() and is_instance_valid(ragdoll.bodies[0]):
			at = ragdoll.bodies[0].global_position
		_eye.global_transform = Transform3D(Basis(), at + Vector3(9.0, 4.0, 7.0)).looking_at(at, Vector3.UP)
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
