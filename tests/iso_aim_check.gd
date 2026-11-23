extends Node

## A PIE, MIRAR AL MOUSE Y CAMINAR CON LAS TECLAS (con ventana, unos 8 s): apunta a un costado y camina hacia arriba de la
## pantalla, después hacia abajo; el rumbo no se mueve y la velocidad es la misma. Apuntando a la meca, la E sube; arriba, el
## mouse no gira a nadie. No toca el mouse de verdad: la cámara de prueba dice dónde está. Termina con APUNTAR OK o MAL.

class FakeView extends IsoView:
	var at := Vector2.ZERO

	func pointer() -> Vector2:
		return at


var local_player: BoneInstantiator = null
var _bad := 0


func _ready() -> void:
	# Esta prueba es de las teclas: no depende de lo que el usuario tenga guardado en el F6.
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	add_to_group("character_spawner")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var mech := CageMech.new()
	mech.position = Vector3(0.0, Mech.standing_height(mech.cabin_shape), 0.0)
	add_child(mech)
	var view := FakeView.new()
	add_child(view)
	local_player = (load("res://game/character/player.tscn") as PackedScene).instantiate() as BoneInstantiator
	local_player.kind = CharacterKind.player()
	add_child(local_player)
	local_player.place_at(Vector3(8.0, 0.0, 8.0), 0.0)
	_run(view, mech)


func _run(view: FakeView, mech: CageMech) -> void:
	await _wait(1.0)
	var body := local_player.char_rigidbody
	_check("a pie el mouse se ve", Input.mouse_mode == Input.MOUSE_MODE_CONFINED)
	await _point(view, body.global_position + Vector3(6.0, 0.0, 0.0))
	var east := -body.global_basis.z
	_check("mira hacia el mouse", east.dot(Vector3.RIGHT) > 0.98)
	var speeds: Array[float] = []
	for action: String in ["move_forward", "move_backward"]:
		# En `screen_to_world`, y positiva es arriba de la pantalla.
		var want := IsoSettings.current.screen_to_world(Vector2(0.0, 1.0 if action == "move_forward" else -1.0))
		Input.action_press(action)
		await _wait(0.2)
		await _point(view, body.global_position + Vector3(6.0, 0.0, 0.0))
		var moving := Vector3(body.linear_velocity.x, 0.0, body.linear_velocity.z)
		Input.action_release(action)
		speeds.append(moving.length())
		print("%s: %.2f m/s, alineado %.3f, mirando al este %.3f" % [action, moving.length(), moving.normalized().dot(want),
			(-body.global_basis.z).dot(Vector3.RIGHT)])
		_check(action + " va según la pantalla", moving.length() > 1.0 and moving.normalized().dot(want) > 0.98)
		_check(action + " no cambia hacia dónde mira", (-body.global_basis.z).dot(Vector3.RIGHT) > 0.97)
		await _wait(0.2)
	_check("misma velocidad para los dos lados", absf(speeds[0] - speeds[1]) < 0.05)
	local_player.place_at(Vector3(2.4, 0.0, 0.0), PI * 0.5)
	await _wait(0.3)
	await _point(view, mech.mover.global_position)
	await _wait(0.2)
	_check("apuntando a la meca, la E la tiene a tiro",
		local_player.player_controller.interaction_controller.detector.get_hovered() is CageBoarding)
	local_player.intent.activate = true
	await _wait(0.8)
	_check("subido", local_player.is_seated)
	_check("arriba el mouse se esconde", Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	print("APUNTAR OK" if _bad == 0 else "APUNTAR MAL (%d)" % _bad)
	get_tree().quit(_bad)


## Pone el mouse de prueba sobre `world`, a la altura del pecho.
func _point(view: FakeView, world: Vector3) -> void:
	var at := world
	at.y = local_player.get_interaction_origin().y
	view.at = view.unproject_position(at)
	await _wait(0.15)


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
