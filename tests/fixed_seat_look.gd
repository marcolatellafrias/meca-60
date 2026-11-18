extends Node3D

## LA SILLA FIJA (con ventana, unos 10 segundos; ver SeatInteractable.fixed): un maniquí sentado en una silla fija mira a
## un costado y arriba —gira la cabeza, no el cuerpo—, después la silla gira 60° como la torreta —el cuerpo la
## acompaña—; al lado, uno en una silla común, que gira entero. Imprime los rumbos y saca capturas.
##   tools/godot_ventana.sh res://tests/fixed_seat_look.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var ground := StaticBody3D.new()
	add_child(ground)
	Clay.solid(ground, Vector3(20, 1, 20), Vector3(0, -0.5, 0), Color(0.8, 0.78, 0.74))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	add_child(sun)
	var eye := Camera3D.new()
	add_child(eye)
	eye.make_current()
	eye.global_position = Vector3(0.75, 1.6, 3.2)
	eye.look_at(Vector3(0.75, 1.0, 0.0))
	var people: Array[BoneInstantiator] = []
	var seats: Array[SeatInteractable] = []
	for i in 2:
		var seat := (load("res://game/interactables/activatable/working_seat.tscn") as PackedScene).instantiate() as SeatInteractable
		seat.fixed = i == 0
		seat.look_cone = Vector2(70.0, 45.0)
		add_child(seat)
		seat.global_position = Vector3(i * 1.5, 0.0, 0.0)
		seat.rotation.y = PI
		seats.append(seat)
		var bi := PeopleArchetype.spawn(self, EntityArchetype.Archetype.lanky, Vector3(i * 1.5, 0.0, 0.8), 0.0)
		CharacterActions.of(bi)
		people.append(bi)
	await get_tree().create_timer(1.0).timeout
	for i in 2:
		people[i].intent.seat = seats[i]
	await get_tree().create_timer(1.0).timeout
	for i in 2:
		var bi := people[i]
		var front := CharacterIntent.yaw_of(bi.char_rigidbody.frame, -seats[i].global_basis.z)
		bi.intent.look_yaw = front + 0.8
		bi.intent.look_pitch = 0.35
	await get_tree().create_timer(0.8).timeout
	_report("mirando 46° a un costado y arriba", people, seats)
	await _shot("1_mira_al_costado")
	for seat in seats:
		seat.rotation.y += deg_to_rad(60.0)
	await get_tree().create_timer(0.8).timeout
	_report("la silla girada 60°", people, seats)
	await _shot("2_silla_girada")
	get_tree().quit()


func _report(label: String, people: Array[BoneInstantiator], seats: Array[SeatInteractable]) -> void:
	for i in 2:
		var bi := people[i]
		var body := rad_to_deg(angle_difference(seats[i].heading(), bi.char_rigidbody.global_rotation.y))
		print("%s · %s: sentado %s · el cuerpo se aparta %.0f° del frente de la silla · la cabeza gira %.0f°" % [label,
			"FIJA" if seats[i].fixed else "común", bi.is_seated, body, rad_to_deg(bi.fixed_seat_look_yaw())])


func _shot(file_name: String) -> void:
	await get_tree().process_frame
	if not _folder.is_empty():
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_folder, file_name])
