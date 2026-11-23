extends Node

## LAS TECLAS COMPARTIDAS POR LA RED (dos instancias sin ventana):
##   godot --headless res://tests/iso_net_check.tscn --host-local
##   godot --headless res://tests/iso_net_check.tscn --join-local
## Los dos aprietan la W: las dos máquinas tienen que ver 2 y la meca quieta. El host la suelta: queda el otro solo, las
## dos ven 1 y la meca camina, aunque el que aprieta no sea quien la simula. Cada paso espera a ver el anterior.


func _ready() -> void:
	# Esta prueba es de las teclas: no depende de lo que el usuario tenga guardado en el F6.
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	var host := OS.get_cmdline_args().has("--host-local")
	var world := (load("res://game/base/base_world.tscn") as PackedScene).instantiate()
	add_child(world)
	await _wait(6.0)
	var mech := world.get_node("Base/Meca jaula") as CageMech
	var crew := mech.get_node("Tripulacion") as MechCrew
	if host:
		await _until(crew, 1)
		crew._store(1, 1 << MechCrew.W)
		await _measure("HOST", "los dos en la W", mech, crew, 1.2)
		await _wait(0.8)
		crew._store(1, 0)
		await _measure("HOST", "queda uno en la W", mech, crew, 0.8)
		await _until(crew, 0)
	else:
		await _wait(1.0)
		crew._report.rpc_id(1, 1 << MechCrew.W)
		await _until(crew, 2)
		await _measure("OTRO", "los dos en la W", mech, crew, 1.2)
		await _until(crew, 1)
		await _measure("OTRO", "queda uno en la W", mech, crew, 0.8)
		await _wait(0.5)
		crew._report.rpc_id(1, 0)
		await _until(crew, 0)
	await _wait(0.5)
	get_tree().quit()


func _measure(who: String, what: String, mech: CageMech, crew: MechCrew, settle: float) -> void:
	await _wait(settle)
	var from := mech.mover.global_position
	await _wait(0.7)
	print("%s: %s, ve %d, la meca se movió %.3f m" % [who, what, crew.counts[MechCrew.W],
		from.distance_to(mech.mover.global_position)])


func _until(crew: MechCrew, count: int) -> void:
	var left := 20.0
	while crew.counts[MechCrew.W] != count and left > 0.0:
		await _wait(0.05)
		left -= 0.05


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
