extends Node

## LOS ATAQUES CON LAS TECLAS DE LA MECA (con ventana, unos 25 s): en las tres versiones, la ametralladora y los misiles a
## los costados y disparando al frente del torso, sin subir ni bajar; cada brazo con su tecla, con puño, sierra, cañón y
## escudo; el puño siempre cerrado; y una tecla apretada por dos no ataca. Saca una captura por versión. Termina con
## ATAQUES OK o ATAQUES MAL.
##   tools/godot_ventana.sh res://tests/mech_attacks_check.tscn -- --salida=C:/carpeta

const PEER := 999

var _folder := ""
var _bad := 0
var _eye: Camera3D = null


func _ready() -> void:
	# Esta prueba es de las teclas: no depende de lo que el usuario tenga guardado en el F6.
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.72, 0.7, 0.65))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 150.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	_eye = Camera3D.new()
	_eye.fov = 30.0
	_eye.far = 400.0
	add_child(_eye)
	_eye.make_current()
	_run()


func _run() -> void:
	var was_crew := CageShape.crew
	for crew in 3:
		await _version(crew)
	CageShape.crew = was_crew
	await _arms()
	print("ATAQUES OK" if _bad == 0 else "ATAQUES MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _make(left: ArmLoadout.Tip, right: ArmLoadout.Tip) -> CageMech:
	var mech := CageMech.new()
	mech.loadout = [ArmLoadout.of(left), ArmLoadout.of(right)]
	mech.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(150.0)), Vector3(0.0, Mech.standing_height(mech.cabin_shape), 0.0))
	add_child(mech)
	await _wait(0.8)
	return mech


func _version(crew: int) -> void:
	CageShape.crew = crew
	var mech: CageMech = await _make(ArmLoadout.Tip.FIST, ArmLoadout.Tip.HEAVY_FIST)
	var name_of := "para %d" % (crew + 1)
	_check(name_of + ": tiene las dos armas", mech.guns != null and mech.guns.weapons != null)
	_check(name_of + ": %d sillas" % (crew + 1), mech.cabin.chairs.size() == crew + 1)
	var pitch := deg_to_rad(60.0)
	var turn := Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, -pitch)
	_eye.global_transform = Transform3D(turn, mech.global_position + Vector3.DOWN * 1.0 + turn.z * 30.0)
	await _shot("version_%d" % (crew + 1))
	var chew := mech.get_node("Tripulacion") as MechCrew
	var bullets := GunnerBullet.made
	var front := -mech.global_basis.z
	front.y = 0.0
	chew._store(PEER, 1 << MechCrew.MINIGUN)
	await _wait(1.6)
	var seen := _flying_bullet()
	chew._store(PEER, 0)
	_check(name_of + ": la ametralladora dispara", GunnerBullet.made > bullets)
	if seen != null:
		var way := -seen.global_basis.z
		print("%s: bala al frente %.3f, para arriba %.4f" % [name_of, way.dot(front.normalized()), way.y])
		_check(name_of + ": la bala va al frente y plana", way.dot(front.normalized()) > 0.99 and absf(way.y) < 0.001)
	var missiles := GunnerMissile.made
	chew._store(PEER, 1 << MechCrew.MISSILES)
	await _wait(0.15)
	chew._store(PEER, 0)
	await _wait(0.1)
	_check(name_of + ": un misil por apretada", GunnerMissile.made == missiles + 1)
	await _remove(mech)


func _arms() -> void:
	var mech: CageMech = await _make(ArmLoadout.Tip.FIST, ArmLoadout.Tip.HEAVY_FIST)
	var crew := mech.get_node("Tripulacion") as MechCrew
	await _wait(0.5)
	var hand: MechHand = mech.arms[0]._hand
	_check("el puño común está cerrado sin pegar", hand != null and hand.fist and hand._closed > 0.99)
	crew._store(PEER, 1 << MechCrew.ARM_LEFT)
	await _wait(0.5)
	crew._store(PEER, 0)
	await _wait(0.05)
	_check("Z pega con el izquierdo", mech.arms[0].punching != MechArm.Punch.NONE and mech.arms[1].punching == MechArm.Punch.NONE)
	await _wait(1.6)
	crew._store(PEER, 1 << MechCrew.ARM_RIGHT)
	await _wait(0.5)
	crew._store(PEER, 0)
	await _wait(0.05)
	_check("X pega con el derecho", mech.arms[1].punching != MechArm.Punch.NONE)
	await _wait(1.6)
	crew._store(PEER, 1 << MechCrew.ARM_LEFT)
	crew._store(PEER + 1, 1 << MechCrew.ARM_LEFT)
	await _wait(0.15)
	_check("Z apretada por dos no pega", mech.arms[0].punching == MechArm.Punch.NONE)
	crew._store(PEER, 0)
	crew._store(PEER + 1, 0)
	await _wait(0.1)
	await _remove(mech)
	mech = await _make(ArmLoadout.Tip.CANNON, ArmLoadout.Tip.CANNON)
	crew = mech.get_node("Tripulacion") as MechCrew
	crew._store(PEER, 1 << MechCrew.ARM_RIGHT)
	await _wait(0.2)
	var left := mech.arms[0].tip as CannonTip
	var right := mech.arms[1].tip as CannonTip
	_check("con dos cañones, X dispara sólo el derecho", right.trigger and not left.trigger)
	crew._store(PEER, 0)
	await _wait(0.1)
	await _remove(mech)
	mech = await _make(ArmLoadout.Tip.SAW, ArmLoadout.Tip.SHIELD)
	crew = mech.get_node("Tripulacion") as MechCrew
	var saw := mech.arms[0].tip as SpinTip
	crew._store(PEER, (1 << MechCrew.ARM_LEFT) | (1 << MechCrew.ARM_RIGHT))
	await _wait(0.9)
	_check("mantener Z hace girar la sierra", saw.spin > 0.3)
	_check("mantener X levanta el escudo", mech.shield.held)
	crew._store(PEER, 0)
	await _wait(0.1)
	_check("soltar Z tira el golpe", mech.arms[0].punching != MechArm.Punch.NONE)
	_check("soltar X baja el escudo", not mech.shield.held)
	await _remove(mech)


func _press(crew: MechCrew, slot: int) -> void:
	crew._store(PEER, 1 << slot)
	await _wait(0.1)
	crew._store(PEER, 0)
	# El golpe sale al soltar, en el próximo paso de la meca.
	for _i in 3:
		await get_tree().physics_frame


func _flying_bullet() -> GunnerBullet:
	for found in get_tree().root.find_children("*", "GunnerBullet", true, false):
		return found as GunnerBullet
	return null


func _remove(mech: CageMech) -> void:
	remove_child(mech)
	mech.queue_free()
	await _wait(0.1)


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String) -> void:
	if _folder.is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_folder, title])
	await get_tree().physics_frame
