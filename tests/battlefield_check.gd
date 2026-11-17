extends Node3D

## EL MAPA DE PELEA, CON LA MECA (con ventana, ~70 segundos, sin el sandbox): arma el mapa (Battlefield) y su parcela,
## y maneja la meca por una vuelta de puntos por el campo libre (caminando y corriendo, con un salto), y al final la
## manda contra el muro del borde. Imprime cada tramo (si llegó, cuánto tardó) y al final si se cayó, si se trabó
## (pidiéndole moverse, quieta más de 3 s), la altura más baja y lo más lejos del centro que llegó (no puede pasar el
## muro). Con `--salida=`, capturas: de arriba, desde la meca y un barrio con sus escaleras.
##   tools/godot_ventana.sh res://tests/battlefield_check.tscn -- --salida=C:/carpeta

## La vuelta: [x, z, corre, salta al llegar].
## Dentro del centro libre (unos 60 m de radio para la meca: más allá están los autos, los recursos y las escaleras de
## los barrios).
const ROUTE := [[45.0, 30.0, false, false], [50.0, -25.0, true, false], [10.0, -55.0, false, true],
	[-45.0, -35.0, true, false], [-50.0, 25.0, false, false], [0.0, 45.0, true, false]]
## La carrera contra el muro va por un hueco entre dos barrios (grados).
const WALL_RUN := 70.0
const LEG_TIMEOUT := 16.0
const REACHED := 8.0

var _folder := ""
var _mech: Mech
var _eye: Camera3D
var _stuck_for := 0.0
var _worst_stuck := 0.0
var _lowest := INF
var _farthest := 0.0
var _driving := false
var _route_stuck := 0.0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 500.0
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	var root := BattlefieldArchetype.new().build(0, self)
	for mech: Mech in root.find_children("*", "Mech", true, false):
		if mech.arms_kind != Mech.Arms.NONE:
			_mech = mech
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await get_tree().create_timer(2.0).timeout
	await _shoot_views()
	await _climb(Battlefield.LOW, Vector3(400, 0, 0))
	await _climb(Battlefield.TALL, Vector3(440, 0, 0))
	_driving = true
	_mech.keys.driving = true
	_press(KEY_W, true)
	var leg := 0
	for point: Array in ROUTE:
		leg += 1
		var target := Vector2(point[0], point[1])
		var started := Time.get_ticks_msec()
		_press(KEY_SHIFT, point[2])
		var reached := false
		while (Time.get_ticks_msec() - started) / 1000.0 < LEG_TIMEOUT:
			var here := Vector2(_mech.global_position.x, _mech.global_position.z)
			var toward := target - here
			if toward.length() < REACHED:
				reached = true
				break
			_mech.aim_yaw = atan2(-toward.x, -toward.y)
			await get_tree().physics_frame
		print("TRAMO %d hacia (%.0f, %.0f): %s en %.1f s · quedó en (%.1f, %.1f, %.1f) · estado %s" % [leg, target.x,
			target.y, "llegó" if reached else "NO LLEGÓ", (Time.get_ticks_msec() - started) / 1000.0,
			_mech.global_position.x, _mech.global_position.y, _mech.global_position.z, BalanceBody.State.keys()[_mech.state]])
		if not reached:
			_touching()
		if point[3]:
			_press(KEY_W, false)
			_press(KEY_SPACE, true)
			await get_tree().create_timer(0.8).timeout
			_press(KEY_SPACE, false)
			await get_tree().create_timer(3.0).timeout
			_press(KEY_W, true)
			print("SALTO: estado %s" % BalanceBody.State.keys()[_mech.state])
	_route_stuck = _worst_stuck
	# Contra el muro, corriendo: no tiene que salirse.
	_press(KEY_SHIFT, true)
	var wall_started := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - wall_started) / 1000.0 < 14.0:
		_mech.aim_yaw = atan2(-cos(deg_to_rad(WALL_RUN)), -sin(deg_to_rad(WALL_RUN)))
		await get_tree().physics_frame
	_driving = false
	_press(KEY_W, false)
	_press(KEY_SHIFT, false)
	_mech.keys.driving = false
	print("MURO: a %.1f m del centro (el muro empieza a %.0f) · estado %s" % [
		Vector2(_mech.global_position.x, _mech.global_position.z).length(), Battlefield.RADIUS,
		BalanceBody.State.keys()[_mech.state]])
	print("RESUMEN: caídas %d · trabada en la vuelta como mucho %.1f s (contra el muro, %.1f) · altura más baja del centro %.1f m · lo más lejos del centro %.1f m"
		% [_mech.falls, _route_stuck, _worst_stuck, _lowest, _farthest])
	get_tree().quit()


func _physics_process(delta: float) -> void:
	if _mech == null:
		return
	_lowest = minf(_lowest, _mech.global_position.y)
	_farthest = maxf(_farthest, Vector2(_mech.global_position.x, _mech.global_position.z).length())
	if _driving:
		var flat := Vector2(_mech.linear_velocity.x, _mech.linear_velocity.z).length()
		_stuck_for = _stuck_for + delta if flat < 1.0 and _mech.move != Vector2.ZERO else 0.0
		_worst_stuck = maxf(_worst_stuck, _stuck_for)
		_eye.global_position = _mech.global_position + _mech.global_basis * Vector3(0, 10, 32)
		_eye.look_at(_mech.global_position + _mech.global_basis * Vector3(0, 2, -30))


func _shoot_views() -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = 40.0
	_eye.global_position = Vector3(0, 330, 200)
	_eye.look_at(Vector3(0, 0, 10))
	await _save("mapa_arriba")
	_eye.fov = 60.0
	_eye.global_position = Vector3(Battlefield.SPAWN.x, 17, Battlefield.SPAWN.y + 30.0)
	_eye.look_at(Vector3(0, 8, -40))
	await _save("mapa_desde_la_meca")
	# Un barrio de cerca, a la altura de una persona parada en el campo.
	var barrio := Battlefield.on_ring(Battlefield.RADIUS - 85.0, 20.0)
	var face := Battlefield.on_ring(Battlefield.RADIUS - 20.0, 20.0)
	_eye.global_position = Vector3(barrio.x, 1.7, barrio.y)
	_eye.look_at(Vector3(face.x, 12.0, face.y))
	await _save("mapa_barrio")


func _save(file: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [_folder, file]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)


## Una tecla apretada o soltada, como si fuera el teclado (MechKeys lee las teclas físicas).
func _press(key: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = down
	Input.parse_input_event(event)


## SUBIR UNA ESCALERA DE INCENDIO: un edificio suelto de `height` (lejos del mapa) y un muñeco con el tamaño de una
## persona (una cápsula de 1,8 m que, como la del personaje, pisa el piso y la RAMPA, no los escalones) que sigue el
## zigzag: cada tramo, el descanso, el otro carril, y al final el techo. En cada paso mide LO QUE PISARÍAN LOS PIES (el
## piso y los escalones) respecto del piso de la cápsula (el piso y la rampa), justo debajo de ella: tiene que quedar
## entre 0 y un escalón por encima (ver Stairs). Imprime a qué altura llegó y ese rango.
func _climb(height: float, at: Vector3) -> void:
	var holder := StaticBody3D.new()
	add_child(holder)
	Clay.solid(holder, Vector3(60, 1, 60), at + Vector3(0, -0.5, 0), Battlefield.GROUND)
	var size := Vector2(22, 18)
	var piece := Battlefield.building(holder, Vector2(at.x, at.z), Vector2(0, 1), size, height, Battlefield.TONES[0], true)
	var walker := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	walker.add_child(shape)
	walker.collision_mask = 1 | PhysicsLayers.RAMP
	walker.floor_max_angle = deg_to_rad(40.0)
	walker.floor_snap_length = 0.4
	add_child(walker)
	var flights := maxi(1, roundi(height / Battlefield.STORY))
	var run := Stairs.run_for(height / flights)
	var face := size.y * 0.5
	var path: Array[Vector3] = []
	for i in flights:
		var lane := i % 2
		var direction := 1.0 if lane == 0 else -1.0
		var z := face + Battlefield.LANE * (lane + 0.5)
		if i == 0:
			walker.global_position = piece.global_transform * Vector3(-run * 0.5 - 1.5, 1.0, z)
		var turn := direction * (run * 0.5 + Battlefield.LANDING * 0.5)
		path.append(Vector3(turn, 0, z))
		var next := face + Battlefield.LANE * ((1 - lane) + 0.5)
		path.append(Vector3(turn, 0, next if i < flights - 1 else face - 3.0))
	var reached := 0
	var lowest := INF
	var highest := -INF
	for point in path:
		var goal := piece.global_transform * point
		var started := Time.get_ticks_msec()
		while (Time.get_ticks_msec() - started) / 1000.0 < 12.0:
			var flat := Vector2(goal.x - walker.global_position.x, goal.z - walker.global_position.z)
			if flat.length() < 0.3:
				reached += 1
				break
			var step := flat.normalized() * 3.0
			walker.velocity = Vector3(step.x, walker.velocity.y - 9.8 * get_physics_process_delta_time(), step.y)
			walker.move_and_slide()
			await get_tree().physics_frame
			var feet := _floor_below(walker.global_position, 1 | PhysicsLayers.FEET)
			var body := _floor_below(walker.global_position, 1 | PhysicsLayers.RAMP)
			if is_finite(feet) and is_finite(body):
				lowest = minf(lowest, feet - body)
				highest = maxf(highest, feet - body)
	var top := walker.global_position.y - 0.9
	print("ESCALERA de %.0f m (%d tramos de %d escalones): llegó a %d de %d puntos · los pies de la cápsula a %.2f m · %s · los pies pisarían de %.2f a %.2f m sobre la cápsula (tiene que ser de 0 a %.2f)" % [
		height, flights, Stairs.steps_for(height / flights), reached, path.size(), top,
		"ARRIBA DEL TECHO" if absf(top - height) < 0.2 else "NO LLEGÓ AL TECHO", lowest, highest, Stairs.RISE])
	if not _folder.is_empty() and DisplayServer.get_name() != "headless" and height == Battlefield.TALL:
		_eye.global_position = piece.global_transform * Vector3(-14, 9, 26)
		_eye.look_at(piece.global_transform * Vector3(0, 6, 9))
		await _save("escalera_30m")
	walker.queue_free()
	holder.queue_free()


## La altura del primer piso que encuentra un rayo hacia abajo desde un poco arriba de `from`, viendo `mask`.
func _floor_below(from: Vector3, mask: int) -> float:
	var ray := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 0.5, from + Vector3.DOWN * 3.0, mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return INF if hit.is_empty() else (hit["position"] as Vector3).y


## QUÉ TOCA LA CAJA DE LA MECA (un poco agrandada): para saber contra qué se trabó.
func _touching() -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = _mech.size + Vector3.ONE
	query.shape = box
	query.transform = _mech.global_transform
	var own: Array[RID] = [_mech.get_rid()]
	for part: CollisionObject3D in _mech.find_children("*", "CollisionObject3D", true, false):
		own.append(part.get_rid())
	query.exclude = own
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 16):
		var thing := hit["collider"] as Node3D
		print("  TOCA: %s (%s) en (%.1f, %.1f, %.1f)" % [thing.name, thing.get_class(), thing.global_position.x,
			thing.global_position.y, thing.global_position.z])
	var down := PhysicsRayQueryParameters3D.create(_mech.global_position, _mech.global_position + Vector3.DOWN * 30.0)
	down.exclude = own
	var ground := get_world_3d().direct_space_state.intersect_ray(down)
	if not ground.is_empty():
		print("  ABAJO: %s a %.1f m" % [(ground["collider"] as Node).name, (ground["position"] as Vector3).y])
