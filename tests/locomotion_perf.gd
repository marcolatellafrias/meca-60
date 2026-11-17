extends Node3D

## QUÉ CUESTA LA FILA LOCOMOCIÓN (con ventana, unos 40 segundos; diagnóstico del 17/11/2026: «cada vez que paso por
## arriba de la parcela de locomoción se me tilda»). Arma las escenas de la fila una al lado de la otra, como el sandbox
## al acercarse, y mide:
##   · EL TIRÓN: cuánto tarda en armarse cada escena (todo junto, en un cuadro, como al acercarse).
##   · EL CUADRO, de a una dimensión por vez: todo prendido; sin los cuerpos del ragdoll en la física; sin la pose de cada cuadro (el `_process` de cada
##     personaje); además sin su `_physics_process`; y sin personajes.
##   tools/godot_ventana.sh res://tests/locomotion_perf.tscn

const WINDOW_S := 3.0
const SETTLE_S := 2.0


func _ready() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 200)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 40.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var eye := Camera3D.new()
	add_child(eye)
	eye.make_current()
	eye.global_position = Vector3(90.0, 40.0, 60.0)
	eye.look_at(Vector3(90.0, 0.0, 0.0))
	await _frames(5)
	print("── EL TIRÓN: armar cada escena ──")
	var x := 0.0
	var total := 0
	for row in LocomotionLabArchetype.catalogue():
		var holder := Node3D.new()
		holder.position.x = x
		add_child(holder)
		var started := Time.get_ticks_usec()
		row.build(0, holder)
		await get_tree().process_frame  # el _ready de la escena arma los personajes
		var spent := Time.get_ticks_usec() - started
		total += spent
		print("  %s: %d ms" % [row.display_name, spent / 1000])
		x += 30.0
	print("  TODAS: %d ms · personajes %d · cuerpos rígidos %d" % [total / 1000, _people().size(), _count("RigidBody3D")])
	await _seconds(SETTLE_S)
	print("── EL CUADRO (promedios de %.0f s) ──" % WINDOW_S)
	await _measure("todo prendido")
	for bi in _people():
		for body: RigidBody3D in bi.ragdoll_util._bodies.values():
			body.process_mode = Node.PROCESS_MODE_DISABLED
	await _measure("sin los cuerpos del ragdoll en la física (de pie no se usan)")
	for bi in _people():
		bi.set_process(false)
	await _measure("sin la pose de cada cuadro (_process de los personajes)")
	for bi in _people():
		bi.set_physics_process(false)
	await _measure("además sin su _physics_process")
	for bi in _people():
		for child in bi.get_children():
			if child is CharacterActions:
				(child as CharacterActions).process_mode = Node.PROCESS_MODE_DISABLED
	await _measure("además sin las acciones (el guion y sus manos)")
	for bi in _people():
		bi.char_rigidbody.set_physics_process(false)
	await _measure("además sin el guion de la cápsula")
	for bi in _people():
		bi.visible = false
	for label in find_children("*", "Label3D", true, false):
		(label as Node3D).visible = false
	await _measure("además invisibles (sin dibujarlos)")
	for bi in _people():
		bi.queue_free()
	await _seconds(0.5)
	await _measure("sin personajes")
	get_tree().quit()


func _measure(label: String) -> void:
	var frames := 0
	var process_us := 0.0
	var physics_us := 0.0
	var started := Time.get_ticks_usec()
	var worst := 0.0
	var last := started
	while Time.get_ticks_usec() - started < WINDOW_S * 1000000.0:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		frames += 1
		process_us += Performance.get_monitor(Performance.TIME_PROCESS) * 1000000.0
		physics_us += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000000.0
	var elapsed := (Time.get_ticks_usec() - started) / 1000000.0
	print("  %s: %.0f fps · cuadro %.1f ms (peor %.0f) · proceso %.1f ms · física %.1f ms · objetos de física activos %d · dibujos %d" % [
		label, frames / elapsed, elapsed * 1000.0 / frames, worst, process_us / frames / 1000.0,
		physics_us / frames / 1000.0, Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])


func _people() -> Array[BoneInstantiator]:
	var out: Array[BoneInstantiator] = []
	for node in find_children("*", "BoneInstantiator", true, false):
		if not node.is_queued_for_deletion():
			out.append(node as BoneInstantiator)
	return out


func _count(type: String) -> int:
	return find_children("*", type, true, false).size()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
