extends Node

## IR ADENTRO DE LA MECA REDONDA, PROBADO POR CÓDIGO (unos 30 segundos; como mech_ride_check, ver RoundCabin): en el
## sandbox, la primera meca se cambia por una redonda; el jugador sube (la U), se para en el piso, en el ascensor (abajo
## y arriba), en la tarima, sube a la tarima caminando y la meca se corre, salta y se cae con él adentro. Con
## ventana, capturas.
##   tools/godot_ventana.sh res://tests/round_ride_check.tscn -- --salida=C:/carpeta

var _folder := ""
var _mech: Mech = null
var _body: RigidBody3D = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(sandbox)
	await _frames(10)
	var old := sandbox.find_children("*", "Mech", true, false)[0] as Mech
	if OS.get_cmdline_user_args().has("--cuadrada"):
		_mech = old
		await _seconds(1.5)
		sandbox.toggle_body()
		await _seconds(0.8)
		_body = sandbox.local_player.char_rigidbody
		await _seconds(1.0)
		_mech.cabin.board()
		await _seconds(2.0)
		await _side_push()
		get_tree().quit()
		return
	_mech = Mech.new()
	_mech.arms_kind = old.arms_kind
	_mech.cabin_shape = Mech.Cabin.ROUND
	_mech.transform = Transform3D(Basis(Vector3.UP, old.yaw()), Vector3(old.position.x,
		Mech.standing_height(Mech.Cabin.ROUND), old.position.z))
	var holder := old.get_parent()
	if old.cabin != null:
		old.cabin.free_dummies()
	holder.remove_child(old)
	old.queue_free()
	holder.add_child(_mech)
	await _seconds(1.5)
	sandbox.toggle_body()
	await _seconds(0.8)
	var player := sandbox.local_player
	_body = player.char_rigidbody
	await _seconds(1.0)
	_mech.cabin.board()
	await _seconds(2.0)
	var floor_at := RoundGrid.floor_top()
	print("SUBIÓ: en el marco %s · la caja no lo ve %s · pies a %.2f m del piso · caído %s" % [
		MotionFrame.frame_of(_body) == _mech.cabin.frame, _mech.cabin._riders.has(_body), _feet() - floor_at,
		player.ragdoll_util.is_active])
	await _shot("1_adentro")
	var lift := _mech.cabin.lift
	var lift_top := lift.raised_at
	player.place_at(_mech.global_transform * Vector3(0.0, lift_top + 0.1, RoundGrid.LIFT_BACK), _mech.yaw())
	await _seconds(1.2)
	print("EN EL ASCENSOR, arriba: en el marco %s · pies a %.2f m de su piso · caído %s" % [
		MotionFrame.frame_of(_body) == _mech.cabin.frame, _feet() - lift_top, player.ragdoll_util.is_active])
	lift.lower()
	await _seconds(4.5)
	print("BAJÓ: el piso del ascensor a %.2f m (bajado es %.2f) · pies a %.2f m de su piso · en el marco %s · caído %s" % [
		lift.position.y, lift.lowered_at, _feet() - lift.position.y, MotionFrame.frame_of(_body) == _mech.cabin.frame,
		player.ragdoll_util.is_active])
	await _shot("2_ascensor_abajo")
	lift.up()
	await _seconds(4.5)
	print("SUBIÓ de vuelta: pies a %.2f m de la tarima · en el marco %s · caído %s" % [_feet() - lift_top,
		MotionFrame.frame_of(_body) == _mech.cabin.frame, player.ragdoll_util.is_active])
	# LA TARIMA, CAMINANDO: desde el piso, delante del escalón, hacia atrás.
	var foot := Vector3(-0.6, floor_at + 0.1, -(RoundGrid.PLATFORM_R + RoundGrid.STEP + 0.8))
	player.place_at(_mech.global_transform * foot, _mech.yaw() + PI)
	await _seconds(1.0)
	_press(KEY_W, true)
	await _seconds(1.2)
	_press(KEY_W, false)
	await _seconds(0.6)
	print("SUBIÓ A LA TARIMA caminando: quedó a z = %.1f · pies a %.2f m del piso (la tarima, %.2f) · caído %s" % [
		_local().z, _feet() - floor_at, RoundGrid.PLATFORM_TALL, player.ragdoll_util.is_active])
	await _shot("3_tarima")
	_mech.cabin.board()
	await _seconds(1.5)
	if OS.get_cmdline_user_args().has("--pared"):
		player.place_at(_mech.global_transform * Vector3(0.0, RoundGrid.floor_top() + 0.1, 2.4), _mech.yaw() + PI)
		await _seconds(1.0)
		_press(KEY_W, true)
		for i in 8:
			await _seconds(0.4)
			print("  pared %d: %s · marco %s" % [i, _local(), MotionFrame.frame_of(_body) == _mech.cabin.frame])
		_press(KEY_W, false)
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("--costado"):
		await _side_push()
		get_tree().quit()
		return
	var before := _local()
	var start := _mech.global_position
	if OS.get_cmdline_user_args().has("--rastro"):
		for way: Vector3 in [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]:
			var from := _mech.global_transform * Vector3(0.0, RoundGrid.floor_top() + 1.0, 0.0)
			var hit := _body.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,
				from + _mech.global_basis * way * 8.0, MotionFrame.LAYER))
			print("  rayo %s: %s" % [way, "nada" if hit.is_empty() else str(_mech.global_transform.affine_inverse() * (hit["position"] as Vector3))])
	for i in (0 if OS.get_cmdline_user_args().has("--sin_empuje") else 600):
		_mech.apply_central_force(-_mech.global_basis.z * Mech.MASS * 11.0)
		await get_tree().physics_frame
		if (i % 40 == 0 or (i > 300 and i < 370 and i % 4 == 0)) and OS.get_cmdline_user_args().has("--rastro"):
			var ahead := _body.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
				_body.global_position, _body.global_position + _mech.global_basis.z * 3.0, MotionFrame.LAYER))
			print("    adelante: %s · capas del cuerpo %d máscara %d" % ["nada" if ahead.is_empty() else
				str(_mech.global_transform.affine_inverse() * (ahead["position"] as Vector3)), _body.collision_layer,
				_body.collision_mask])
			print("  %d: %s · marco %s · caído %s" % [i, _local(), MotionFrame.frame_of(_body) == _mech.cabin.frame, DesignSandbox.player_of(get_tree()).ragdoll_util.is_active])
	await _seconds(1.5)
	print("LA MECA SE CORRIÓ %.1f m: el de adentro se movió %.2f m en la cabina · sigue en el marco %s · caído %s" % [
		start.distance_to(_mech.global_position), before.distance_to(_local()), MotionFrame.frame_of(_body) == _mech.cabin.frame,
		player.ragdoll_util.is_active])
	before = _local()
	_mech.linear_velocity.y = 12.0
	_mech.airborne = true
	_mech.grounded = false
	await _seconds(3.5)
	print("SALTÓ y aterrizó: el de adentro se movió %.2f m en la cabina · pies a %.2f m del piso · en el marco %s · caído %s" % [
		before.distance_to(_local()), _feet() - floor_at, MotionFrame.frame_of(_body) == _mech.cabin.frame,
		player.ragdoll_util.is_active])
	_mech.knock(true)
	var clock := 0.0
	while clock < 14.0 and not (_mech.falls > 0 and _mech.state == BalanceBody.State.STANDING):
		await get_tree().physics_frame
		clock += 1.0 / 240.0
	await _seconds(3.0)
	var inside := _local()
	print("SE CAYÓ y se recuperó (%.1f s): el de adentro quedó %s (en la cabina: %.1f, %.1f, %.1f) · en el marco %s · caído %s" % [
		clock, "ADENTRO" if Vector2(inside.x, inside.z).length() < RoundGrid.OUTER and absf(inside.y) < RoundGrid.HALF_HEIGHT
		else "AFUERA", inside.x, inside.y, inside.z, MotionFrame.frame_of(_body) == _mech.cabin.frame,
		player.ragdoll_util.is_active])
	await _shot("4_despues_de_caerse")
	get_tree().quit()


## Empujada de costado (hacia la izquierda): el de adentro se resbala contra la pared de la derecha.
func _side_push() -> void:
	for i in 600:
		_mech.apply_central_force(-_mech.global_basis.x * Mech.MASS * 11.0)
		await get_tree().physics_frame
		if i % 60 == 0:
			print("  costado %d: %s · marco %s" % [i, _local(), MotionFrame.frame_of(_body) == _mech.cabin.frame])


func _press(code: Key, down: bool) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.keycode = code
	key.pressed = down
	Input.parse_input_event(key)


func _local() -> Vector3:
	return _mech.global_transform.affine_inverse() * _body.global_position


func _feet() -> float:
	var hit := _body.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		_body.global_position, _body.global_position + Vector3.DOWN * 6.0, MotionFrame.LAYER))
	if hit.is_empty():
		return -99.0
	return (_mech.global_transform.affine_inverse() * (hit["position"] as Vector3)).y


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	await _frames(2)
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
