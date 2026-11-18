extends Node3D

## QUÉ CUESTA UNA PERSONA, PARTE POR PARTE (unos 15 segundos, sin ventana): `COUNT` personas quietas, de cerca (la pose
## en cada paso). Primero el paso entero (lo que miden los monitores del motor); después la pose, llamada a mano parte
## por parte con su tiempo (las mismas llamadas, en el mismo orden, que BoneInstantiator._solve_pose).
##   godot --headless --path . res://tests/person_cost.tscn

const COUNT := 12
const WINDOW_S := 3.0

var _people: Array[BoneInstantiator] = []
var _parts := {}
var _calls := 0


func _ready() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 20)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	add_child(ground)
	var eye := Camera3D.new()
	add_child(eye)
	eye.make_current()
	eye.global_position = Vector3(COUNT, 2.0, 4.0)
	for i in COUNT:
		var archetype: int = PeopleArchetype.ROW_ORDER[i % PeopleArchetype.ROW_ORDER.size()]
		_people.append(PeopleArchetype.spawn(self, archetype as EntityArchetype.Archetype, Vector3(i * 2.0, 0, 0), 0.0))
	await get_tree().create_timer(1.5).timeout
	await _engine_window("todo prendido")
	for bi in _people:
		bi.set_process(false)
	await _engine_window("sin la pose (_process)")
	for bi in _people:
		bi.set_physics_process(false)
	await _engine_window("además sin el _physics_process del personaje")
	for bi in _people:
		bi.char_rigidbody.set_physics_process(false)
	await _engine_window("además sin el de la cápsula")
	for bi in _people:
		bi.set_physics_process(true)
		bi.char_rigidbody.set_physics_process(true)
	# LA POSE, PARTE POR PARTE: el personaje no la resuelve solo (set_process apagado), la llama esto.
	set_physics_process(true)
	await get_tree().create_timer(WINDOW_S).timeout
	set_physics_process(false)
	print("── LA POSE, por persona y por paso (µs), promedio de %d llamadas ──" % _calls)
	var total := 0.0
	for part: String in _parts:
		var per: float = _parts[part] / maxf(_calls, 1.0)
		total += per
		print("  %-40s %6.0f" % [part, per])
	print("  %-40s %6.0f" % ["TODA LA POSE", total])
	get_tree().quit()


func _engine_window(label: String) -> void:
	var frames := 0
	var physics_us := 0.0
	var process_us := 0.0
	var started := Time.get_ticks_usec()
	while Time.get_ticks_usec() - started < WINDOW_S * 1000000.0:
		await get_tree().process_frame
		frames += 1
		physics_us += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000000.0
		process_us += Performance.get_monitor(Performance.TIME_PROCESS) * 1000000.0
	print("%s: un paso de física %.2f ms · un cuadro de proceso %.2f ms (con %d personas)" % [label,
		physics_us / frames / 1000.0, process_us / frames / 1000.0, COUNT])


func _physics_process(delta: float) -> void:
	for bi in _people:
		_time("entradas de la animación", func() -> void: bi._update_animation_inputs(delta))
		_time("echarse atrás, aire, piso", func() -> void:
			bi.jump.update_carry_lean(delta)
			bi.pelvis.ride_floor(delta)
			bi._update_local_targets_positions())
		_time("ragdoll (de pie)", func() -> void: bi.ragdoll_util.update(delta))
		_time("la marcha (SkeletonSizesUtil.update)", func() -> void:
			bi.skel_sizes_util.update(delta, bi.animation_inputs, bi.entity_instantiation, bi.ik_util))
		_time("brazos que se comprimen", func() -> void: bi.arms_controller.update_arm_compress(bi.jump_squat_t, bi.crouch_t))
		_time("señales (LocomotionSignals)", func() -> void: bi.locomotion_signals.update(delta))
		_time("piernas parado (pasos, rayos, IK)", func() -> void: bi.pelvis.pose_legs_standing())
		_time("bajada de pelvis", func() -> void: bi.pelvis.update_pelvis_drop(delta))
		_time("procedural (tabla, pasivas, modificadores)", func() -> void: bi._pose_procedural(delta))
		_time("brazos (IK)", func() -> void: bi._pose_arms(delta))
		_time("piernas otra vez (repin)", func() -> void: bi.pelvis.repin_legs_standing())
		_time("copiar al ragdoll", func() -> void: bi._sync_ragdoll_bodies())
		_time("copiar al cuerpo que se ve", func() -> void: bi._sync_body_visual())
		_time("FÍSICA: mirar, salto, agacharse, aire", func() -> void:
			bi._apply_look()
			bi.jump.update_jump(delta)
			bi.jump.update_crouch()
			bi.fall.maybe_ragdoll_in_air())
		_time("FÍSICA: copiar al ragdoll", func() -> void: bi._sync_ragdoll_bodies())
		_time("FÍSICA: la cápsula entera", func() -> void: bi.char_rigidbody._physics_process(delta))
	_calls += _people.size()


func _time(part: String, work: Callable) -> void:
	var started := Time.get_ticks_usec()
	work.call()
	_parts[part] = float(_parts.get(part, 0.0)) + float(Time.get_ticks_usec() - started)
