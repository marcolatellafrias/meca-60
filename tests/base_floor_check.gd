extends Node

## EL PISO DE LA BASE, A UNA SOLA ALTURA (con ventana, unos 12 s): mide con rayos todo lo caminable y lista las alturas que
## encuentra (lo más alto que 20 cm cuenta como mueble, no como piso), y hace cruzar la meca el borde del ascensor, de ida y
## de vuelta. Termina con PISO OK o PISO MAL.

const STEP := 0.1
const FURNITURE := 0.2

var _bad := 0


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	SessionManager.host()
	var world := (load("res://game/base/base_world.tscn") as PackedScene).instantiate() as BaseWorld
	add_child(world)
	_run(world)


func _run(world: BaseWorld) -> void:
	await _wait(2.0)
	var mech := world.get_node("Base/Meca jaula") as CageMech
	_scan(mech)
	var edge := BaseLayout.at(BaseLayout.ELEVATOR - BaseLayout.HATCH_INSET, BaseLayout.NAVE * 0.5).x
	var keys := mech.keys as ToolMechKeys
	await _drive(mech, keys, Vector3.RIGHT, edge + 3.0, "de ida")
	await _drive(mech, keys, Vector3.LEFT, edge - 3.0, "de vuelta")
	keys.cockpit.move = Vector2.ZERO
	# ARRIBA, LA PLATAFORMA A RAS DE LA ARENA, y la meca sale.
	var elevator := world.get_node("Base").find_child("Ascensor", true, false) as BaseElevator
	# Sin el jefe: acá se mide el piso, y despierto le pega a la meca.
	elevator.arrived.disconnect(world._wake_boss)
	elevator.launch()
	await elevator.arrived
	await _wait(1.3)
	await _drive(mech, keys, Vector3.RIGHT, edge + 3.0, "a la arena")
	await _drive(mech, keys, Vector3.LEFT, edge - 3.0, "de la arena al ascensor")
	var top_y := mech.mover.global_position.y
	await _drive(mech, keys, Vector3.RIGHT, edge + 16.0, "lejos en la arena")
	await _wait(0.5)
	print("lejos: la meca en x=%.1f, y=%.3f (arriba estaba en %.3f), en el piso %s" % [mech.mover.global_position.x,
		mech.mover.global_position.y, top_y, mech.grounded])
	_check("lejos sigue a la misma altura", absf(mech.mover.global_position.y - top_y) < 0.01 and mech.grounded)
	keys.cockpit.move = Vector2.ZERO
	print("PISO OK" if _bad == 0 else "PISO MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _scan(mech: CageMech) -> void:
	var space := mech.get_world_3d().direct_space_state
	var heights := {}
	var zones: Array[Rect2] = [Rect2(0.3, 0.3, BaseLayout.LENGTH - 0.6, BaseLayout.NAVE - 0.3),
		Rect2(BaseLayout.ELEVATOR + 0.2, BaseLayout.NAVE, BaseLayout.LENGTH + BaseLayout.strip - BaseLayout.ELEVATOR - 0.5,
			BaseLayout.strip - 0.2)]
	for zone in zones:
		var x := zone.position.x
		while x < zone.end.x:
			var z := zone.position.y
			while z < zone.end.y:
				var at := BaseLayout.at(x, z)
				var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.6, at + Vector3.DOWN * 0.3,
					PhysicsLayers.FIXED)
				var hit := space.intersect_ray(query)
				if not hit.is_empty() and float(hit.position.y) <= FURNITURE:
					var level := snappedf(float(hit.position.y), 0.001)
					heights[level] = int(heights.get(level, 0)) + 1
				z += STEP
			x += STEP
	print("alturas del piso (m → puntos): ", heights)
	_check("todo el piso a la misma altura", heights.size() == 1)


func _drive(mech: CageMech, keys: ToolMechKeys, way: Vector3, goal: float, what: String) -> void:
	var left := 6.0
	var slowest := INF
	var clock := 0.0
	while (goal - mech.mover.global_position.x) * way.x > 0.0 and left > 0.0:
		var local := Basis(Vector3.UP, -mech.yaw()) * way
		keys.cockpit.move = Vector2(local.x, -local.z)
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		left -= delta
		clock += delta
		if clock > 0.3:
			slowest = minf(slowest, Vector2(mech.mover.get_real_velocity().x, mech.mover.get_real_velocity().z).length())
	print("%s: llegó %s en %.2f s, lo más lento %.2f m/s" % [what, left > 0.0, clock, slowest])
	_check("la meca cruza " + what, left > 0.0 and slowest > 3.0)


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
