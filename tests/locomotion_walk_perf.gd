extends Node

## PASAR POR LA FILA LOCOMOCIÓN EN EL SANDBOX (con ventana, unos 40 segundos; ver LocomotionLab, DESPIERTA SÓLO CON
## UNO ADENTRO): el jugador se para en cada parcela de la fila, una por una, y en cada una se mide el peor cuadro al
## llegar (el tirón) y el promedio de los cuadros que siguen.
##   tools/godot_ventana.sh res://tests/locomotion_walk_perf.tscn

const STAY_S := 3.0


func _ready() -> void:
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(sandbox)
	await get_tree().create_timer(1.5).timeout
	var parcels: Array[SandboxParcel] = []
	for node in sandbox.find_children("*", "SandboxParcel", true, false):
		var parcel := node as SandboxParcel
		if parcel.category == "Locomoción" or (parcel.category == "Personajes" and parcels.is_empty()):
			parcels.append(parcel)
	print("PARCELAS: %d" % parcels.size())
	# PRIMERO, EL SANDBOX SOLO: el jugador lejos de todo, arriba.
	sandbox.local_player.place_at(Vector3(0.0, 400.0, -400.0), 0.0)
	await _stay("lejos de todo")
	for parcel in parcels:
		sandbox.local_player.place_at(parcel.global_position, 0.0)
		await _stay("%s / %s" % [parcel.category, parcel.archetype.display_name])
	get_tree().quit()


func _stay(label: String) -> void:
	if true:
		var worst := 0.0
		var frames := 0
		var spent := 0.0
		var started := Time.get_ticks_usec()
		var last := started
		while Time.get_ticks_usec() - started < STAY_S * 1000000.0:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			var ms := (now - last) / 1000.0
			last = now
			worst = maxf(worst, ms)
			if now - started > 1000000.0:
				frames += 1
				spent += ms
		var awake := 0
		var people := get_tree().root.find_children("*", "BoneInstantiator", true, false)
		for person in people:
			if (person as Node).can_process():
				awake += 1
		print("  %s: peor cuadro %.0f ms · después, %.1f ms por cuadro (%.0f fps) · personas despiertas %d de %d" % [label,
			worst, spent / maxi(frames, 1), 1000.0 * frames / maxf(spent, 1.0), awake, people.size()])
