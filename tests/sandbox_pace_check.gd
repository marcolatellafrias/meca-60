extends Node

## EL SANDBOX ENTERO, ¿VA A TIEMPO? (16/11/2026; el usuario: la meca jaula «tarda muchísimo más que 0,5» en agacharse,
## y sola tarda 0,5 de reloj: tests/crouch_time_check). Arma el sandbox (game/sandbox/sandbox.tscn), espera que nazca y
## mide cuántos pasos de física corren por segundo de reloj (el proyecto pide 240; con menos, todo va en cámara lenta) y
## cuántos cuadros; después agacha la meca jaula y mide cuánto tarda de reloj.

func _ready() -> void:
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate()
	add_child(sandbox)
	await get_tree().create_timer(8.0, true, false, true).timeout
	for i in 3:
		var t0 := Time.get_ticks_msec()
		var p0 := Engine.get_physics_frames()
		var f0 := Engine.get_process_frames()
		await get_tree().create_timer(2.0, true, false, true).timeout
		var wall := (Time.get_ticks_msec() - t0) / 1000.0
		print("SANDBOX: pasos de física por s %d · cuadros por s %d" % [roundi((Engine.get_physics_frames() - p0) / wall),
			roundi((Engine.get_process_frames() - f0) / wall)])
	var found := get_tree().root.find_children("*", "CageMech", true, false)
	if found.is_empty():
		print("SIN MECA JAULA")
		get_tree().quit()
		return
	var mech := found[0] as CageMech
	mech.scripted = true
	var start := Time.get_ticks_msec()
	mech.crouch = true
	while mech.mover.crouched < 0.999 and Time.get_ticks_msec() - start < 10000:
		await get_tree().process_frame
	print("AGACHADA ENTERA EN %.2f s de reloj" % ((Time.get_ticks_msec() - start) / 1000.0))
	get_tree().quit()
