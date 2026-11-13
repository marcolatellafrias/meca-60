extends Node

## EL ASCENSOR ENTRE PISOS, PROBADO Y PARA MIRARLO (unos 40 segundos): la meca con la estructura del ascensor entre pisos
## (CabinGrid.Structure.LIFT, ver PelvisLift), el jugador con cuerpo parado en el ascensor, que sube parada por parada
## hasta el último piso y baja hasta abajo de todo. Imprime en cada parada dónde quedan sus pies y si va en el marco; con
## ventana, una captura por parada desde una esquina de adelante de ese piso y una desde atrás, afuera.
##   tools/godot_ventana.sh res://tests/mech_lift_floors_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _mech: Mech = null
var _body: RigidBody3D = null
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	CabinGrid.STRUCTURE = CabinGrid.Structure.LIFT
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(sandbox)
	await _frames(10)
	_mech = sandbox.find_children("*", "Mech", true, false)[0] as Mech
	sandbox.toggle_body()
	await _seconds(0.8)
	var player := sandbox.local_player
	_body = player.char_rigidbody
	await _seconds(1.0)
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	_eye = Camera3D.new()
	_eye.far = 500.0
	_eye.fov = 80.0
	add_child(_eye)
	var lift := _mech.cabin.lift
	player.place_at(_mech.global_transform * Vector3(0.6, PelvisLift.raised_y() + 0.1, 0.0), _mech.yaw())
	await _seconds(1.5)
	_eye.make_current()
	print("PARADAS: bajado y los pisos 0 a %d" % PelvisLift.top())
	_report(lift)
	await _view(0, "1. en el ascensor, en el piso 0", "1_piso_0")
	for stop in range(1, PelvisLift.top() + 1):
		lift.up()
		await _arrive(lift)
		_report(lift)
		await _view(stop, "%d. subió al piso %d" % [stop + 1, stop], "%d_piso_%d" % [stop + 1, stop])
	lift.up()
	await _seconds(0.5)
	print("ARRIBA DE TODO, subir otra vez: no se mueve %s (parada %d)" % [not lift.moving(), lift.stop])
	while lift.stop > -1:
		lift.lower()
		await _arrive(lift)
		_report(lift)
	var box := _mech.global_transform
	_eye.global_position = box * Vector3(-16.0, 2.0, 20.0)
	_eye.look_at(box * Vector3(0.0, -2.0, 0.0))
	await _shot("%d. desde atrás: la pared entera, sin escalera; el ascensor bajado" % (PelvisLift.top() + 2),
		"%d_atras" % (PelvisLift.top() + 2))
	get_tree().quit()


func _report(lift: PelvisLift) -> void:
	print("PARADA %d: el piso del ascensor a %.2f m (busca %.2f) · pies a %.2f m de su piso · en el marco %s · caído %s" % [
		lift.stop, lift.position.y, lift.target(), _feet() - lift.position.y,
		MotionFrame.frame_of(_body) == _mech.cabin.frame, _body.get_parent().get("ragdoll_util") != null
		and bool(_body.get_parent().ragdoll_util.is_active)])


func _arrive(lift: PelvisLift) -> void:
	var clock := 0.0
	while lift.moving() and clock < 12.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
	await _seconds(0.8)


## Desde una esquina de adelante del piso `index`, mirando al ascensor.
func _view(index: int, title: String, file_name: String) -> void:
	var box := _mech.global_transform
	_eye.global_position = box * Vector3(-CabinGrid.INNER + 0.4, CabinGrid.ground(index) + 1.9, -CabinGrid.INNER + 0.4)
	_eye.look_at(box * Vector3(0.0, CabinGrid.ground(index) + 0.6, 0.0))
	await _shot(title, file_name)


## La altura de sus pies, en el espacio de la meca.
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


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await _frames(2)
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
