extends Node

## IR ADENTRO DE LA MECA PÉNDULO, PROBADO POR CÓDIGO (unos 30 segundos): el jugador con cuerpo sube (la U), queda parado
## en el piso del medio, y se mira qué le pasa mientras la meca se corre, salta y se cae. Con ventana, capturas.
##   tools/godot_ventana.sh res://tests/pendulum_ride_check.tscn -- --salida=C:/carpeta
## `--interior=0|1`: la cuadrada con el interior de escaleras o el del centro octogonal (sin eso, el guardado). En el
## octogonal, la tarima y su escalera son la tarima del medio y sus escalones (ver ChamferCabin).

var _folder := ""
var _mech: Mech = null
var _body: RigidBody3D = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--interior="):
			var form := CabinGrid.current()
			form.interior = int(argument.trim_prefix("--interior="))
			CabinGrid.shape(form)
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(sandbox)
	await _frames(10)
	_mech = sandbox.find_children("*", "Mech", true, false)[0] as Mech
	sandbox.toggle_body()
	await _seconds(0.8)
	var player := sandbox.local_player
	_body = player.char_rigidbody
	await _seconds(1.0)
	_mech.cabin.board()
	await _seconds(2.0)
	var floor_at := CabinGrid.floor_top()
	print("SUBIÓ: en el marco %s · la caja no lo ve %s · pies a %.2f m del piso · caído %s" % [
		MotionFrame.frame_of(_body) == _mech.cabin.frame, _mech.cabin._riders.has(_body), _feet() - floor_at, player.ragdoll_util.is_active])
	await _shot("1_adentro")
	# EL ASCENSOR (ver PelvisLift): parado en su piso, baja y sube con él.
	var lift_top := PelvisLift.raised_y()
	player.place_at(_mech.global_transform * Vector3(0.0, lift_top + 0.1, 0.0), _mech.yaw())
	await _seconds(1.2)
	print("EN EL ASCENSOR, arriba: en el marco %s · pies a %.2f m de su piso · caído %s" % [
		MotionFrame.frame_of(_body) == _mech.cabin.frame, _feet() - lift_top, player.ragdoll_util.is_active])
	await _shot("1a_ascensor_arriba")
	_mech.cabin.lift.lower()
	await _seconds(3.2)
	print("BAJÓ: el piso del ascensor a %.2f m (bajado es %.2f) · pies a %.2f m de su piso · en el marco %s · caído %s" % [
		_mech.cabin.lift.position.y, PelvisLift.lowered(), _feet() - _mech.cabin.lift.position.y, MotionFrame.frame_of(_body) == _mech.cabin.frame,
		player.ragdoll_util.is_active])
	await _shot("1a_ascensor_abajo")
	_mech.cabin.lift.up()
	await _seconds(3.2)
	print("SUBIÓ de vuelta: pies a %.2f m del piso de abajo · en el marco %s · caído %s" % [_feet() - lift_top,
		MotionFrame.frame_of(_body) == _mech.cabin.frame, player.ragdoll_util.is_active])
	# LA TARIMA Y SU ESCALERA (ver MechCabin): parado arriba de la tarima; y desde el pie de la escalera de la derecha,
	# caminando hacia atrás, sube a la tarima.
	var octagonal := CabinGrid.chamfered()
	var top_at := CabinGrid.floor_top() + (ChamferCabin.deck_tall() if octagonal else CabinGrid.PLATFORM_HEIGHT)
	var on_top := Vector3(-1.0, top_at + 0.1, CabinGrid.INNER - CabinGrid.TRAMA)
	if octagonal:
		on_top = Vector3(ChamferCabin.deck_reach() * 0.6, top_at + 0.1, 0.0)
	player.place_at(_mech.global_transform * on_top, _mech.yaw())
	await _seconds(1.5)
	print("ARRIBA DE LA TARIMA: en el marco %s · pies a %.2f m de la tarima · caído %s" % [
		MotionFrame.frame_of(_body) == _mech.cabin.frame, _feet() - top_at, player.ragdoll_util.is_active])
	await _shot("1b_tarima")
	var stair_x := CabinGrid.INNER - CabinGrid.STAIR_CELLS * CabinGrid.TRAMA * 0.5
	var foot := Vector3(stair_x, CabinGrid.floor_top() + 0.1, CabinGrid.platform_front() - Stairs.run_for(CabinGrid.PLATFORM_HEIGHT) - 0.6)
	if octagonal:
		foot = Vector3(0.5, CabinGrid.floor_top() + 0.1, -ChamferCabin.deck_foot() - 0.4)
	player.place_at(_mech.global_transform * foot, _mech.yaw() + PI)
	await _seconds(1.0)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	await _seconds(2.6)
	key = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.keycode = KEY_W
	key.pressed = false
	Input.parse_input_event(key)
	await _seconds(0.5)
	print("SUBIÓ LA ESCALERA caminando: quedó a z = %.1f (la tarima empieza en %.1f) · pies a %.2f m de la tarima · caído %s" % [
		_local().z, -ChamferCabin.deck_reach() if octagonal else CabinGrid.platform_front(), _feet() - top_at,
		player.ragdoll_util.is_active])
	await _shot("1c_escalera")
	_mech.cabin.board()
	await _seconds(1.5)
	# LA MECA SE CORRE (empujada 2,5 s): el de adentro va con ella.
	var before := _local()
	var start := _mech.global_position
	for i in 600:
		_mech.apply_central_force(-_mech.global_basis.z * Mech.MASS * 11.0)
		await get_tree().physics_frame
	await _seconds(1.5)
	print("LA MECA SE CORRIÓ %.1f m: el de adentro se movió %.2f m en la cabina · sigue en el marco %s · caído %s" % [
		start.distance_to(_mech.global_position), before.distance_to(_local()), MotionFrame.frame_of(_body) == _mech.cabin.frame,
		player.ragdoll_util.is_active])
	await _shot("2_despues_de_correrse")
	# SALTA.
	before = _local()
	_mech.linear_velocity.y = 12.0
	_mech.airborne = true
	_mech.grounded = false
	await _seconds(3.5)
	print("SALTÓ y aterrizó: el de adentro se movió %.2f m en la cabina · pies a %.2f m del piso · en el marco %s · caído %s" % [
		before.distance_to(_local()), _feet() - floor_at, MotionFrame.frame_of(_body) == _mech.cabin.frame,
		player.ragdoll_util.is_active])
	# SE CAE Y SE RECUPERA.
	_mech.knock(true)
	var clock := 0.0
	while clock < 14.0 and not (_mech.falls > 0 and _mech.state == BalanceBody.State.STANDING):
		await get_tree().physics_frame
		clock += 1.0 / 240.0
	await _seconds(3.0)
	var inside := _local()
	print("SE CAYÓ y se recuperó (%.1f s): el de adentro quedó %s (en la cabina: %.1f, %.1f, %.1f) · en el marco %s · caído %s" % [
		clock, "ADENTRO" if maxf(absf(inside.x), absf(inside.z)) < CabinGrid.HALF and absf(inside.y) < CabinGrid.HALF_HEIGHT else "AFUERA",
		inside.x, inside.y, inside.z, MotionFrame.frame_of(_body) == _mech.cabin.frame, player.ragdoll_util.is_active])
	await _shot("3_despues_de_caerse")
	get_tree().quit()


## Dónde está el de adentro, en el espacio de la meca.
func _local() -> Vector3:
	return _mech.global_transform.affine_inverse() * _body.global_position


## La altura de sus pies, en el espacio de la meca (el centro de su cuerpo menos lo que hay hasta el piso).
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
