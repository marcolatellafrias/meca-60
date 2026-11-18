extends Node

## LAS PIERNAS DE LA JAULA HOY, CASO POR CASO (con ventana, unos 30 segundos de video; la base para comparar los cambios
## del movimiento común, ver docs/technical/movimiento-comun.md): la meca jaula manejada por código pasa por cada caso
## que el usuario dijo que mirar —arrancar, frenar, doblar de golpe, girar en el lugar, ir de costado, el dash, saltar
## y aterrizar, levitar y bajar agachada en el aire—, con la cámara de costado y un cartel con el caso. Se graba con
## --write-movie:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/piernas.avi --fixed-fps 30 res://tests/cage_legs_movie.tscn
## Imprime, caminando, qué parte del tiempo no tenía ningún pie en el aire (la pausa que vio el usuario: «paso, paso,
## pausa») y cuántos pasos dio; y la caja al caminar: cuánto sube con el paso y cuánto se inclina de costado (y de frente,
## que no tiene que inclinarse); y cuánto fueron recogidas las piernas en cada caso (en el dash, levitando y en picada sí;
## en un salto común, no).

var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _cam_at := Vector3.ZERO
var _first := true
## Desde dónde mira la cámara (relativo a la meca): de costado; yendo de costado, de frente (para ver la inclinación).
var _cam_from := Vector3(17.0, 4.0, 5.0)
## Caminando: cuánto tiempo, y cuánto sin ningún pie en el aire (s).
var _walking := 0.0
var _paused := 0.0
## La caja al caminar (las capas del esqueleto: la cintura y el torso): lo más que subió (m) y lo más que se inclinó de costado yendo de costado y
## yendo de frente (°).
var _bob := 0.0
var _lean_side := 0.0
var _lean_ahead := 0.0
## Cuánto tiempo fueron recogidas las piernas en cada caso (KinematicMover.tucks), por cartel (s).
var _tucked := {}


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	# Una grilla en el piso, para ver si los pies patinan.
	for i in range(-30, 31):
		Clay.box(ground, Vector3(0.05, 0.02, 600), Vector3(i * 2.0, 0.01, 0), Color(0.7, 0.68, 0.64))
		Clay.box(ground, Vector3(600, 0.02, 0.05), Vector3(0, 0.01, i * 2.0), Color(0.7, 0.68, 0.64))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	_mech = CageMech.new()
	_mech.scripted = true
	_mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
	add_child(_mech)
	_mech.label.visible = false
	_eye = Camera3D.new()
	_eye.fov = 50.0
	add_child(_eye)
	_eye.make_current()
	await _run("parada", 1.0, Vector2.ZERO)
	await _run("arranca y camina", 2.5, Vector2(0.0, 1.0))
	await _run("frena", 1.5, Vector2.ZERO)
	await _run("dobla de golpe: adelante", 1.2, Vector2(0.0, 1.0))
	await _run("dobla de golpe: a la derecha", 1.2, Vector2(1.0, 0.0))
	await _run("dobla de golpe: atrás", 1.2, Vector2(0.0, -1.0))
	await _run("frena", 1.0, Vector2.ZERO)
	await _turn_in_place(2.5)
	_cam_from = Vector3(4.0, 4.0, 17.0)
	await _run("de costado", 3.0, Vector2(-1.0, 0.0))
	await _run("frena", 1.0, Vector2.ZERO)
	_cam_from = Vector3(17.0, 4.0, 5.0)
	await _dash()
	await _jump(false, false)
	await _jump(true, false)
	await _jump(false, true)
	await _run("parada", 1.0, Vector2.ZERO)
	print("caminando: sin ningún pie en el aire el %.0f %% del tiempo · %d pasos" % [100.0 * _paused / maxf(_walking, 0.01),
		_mech.legs.steps_taken])
	var tucked := ""
	for label: String in _tucked:
		tucked += " %s %.2f s ·" % [label, _tucked[label]]
	print("recogidas:%s" % tucked.trim_suffix(" ·"))
	print("la caja al caminar: sube hasta %.2f m · de costado se inclina %.1f° · de frente %.1f°" % [_bob, _lean_side,
		_lean_ahead])
	get_tree().quit()


## `seconds` segundos pidiendo `move` (en el espacio de la meca), con el cartel `label`.
func _run(label: String, seconds: float, move: Vector2) -> void:
	_title.text = label
	var clock := 0.0
	while clock < seconds:
		_mech.move = move
		var delta := await _tick()
		clock += delta
		# Caminando de verdad (ya arrancó, en el piso): ¿algún pie en el aire?
		# Las capas del esqueleto (MechSkeleton): la cintura sube y baja, el torso se inclina sobre ella.
		var lean := absf(rad_to_deg(_mech.skeleton.torso.transform.basis.get_euler().z))
		_bob = maxf(_bob, _mech.skeleton.waist.position.y)
		if move.x != 0.0:
			_lean_side = maxf(_lean_side, lean)
		elif move.y != 0.0 and clock > 0.6:
			_lean_ahead = maxf(_lean_ahead, lean)
		if move != Vector2.ZERO and clock > 0.5 and _mech.grounded and _mech.support_speed.length() > 1.0:
			_walking += delta
			if int(_mech.legs.get("_swing")) < 0:
				_paused += delta


func _turn_in_place(seconds: float) -> void:
	_title.text = "gira en el lugar"
	var from := _mech.aim_yaw
	var clock := 0.0
	while clock < seconds:
		_mech.move = Vector2.ZERO
		_mech.aim_yaw = from + PI * clampf(clock / (seconds * 0.7), 0.0, 1.0)
		clock += await _tick()


func _dash() -> void:
	_title.text = "dash de costado"
	_mech.move = Vector2(1.0, 0.0)
	_mech.dash = true
	await _tick()
	_mech.dash = false
	var clock := 0.0
	while clock < 1.6:
		_mech.move = Vector2(1.0, 0.0) if clock < 0.4 else Vector2.ZERO
		clock += await _tick()


## SALTA Y ATERRIZA; `fly`: en el aire suelta y vuelve a apretar (levita) un rato; `dive`: en lo alto se agacha (baja
## rápido).
func _jump(fly: bool, dive: bool) -> void:
	_title.text = "levita" if fly else ("salta y baja agachada" if dive else "salta y aterriza")
	_mech.move = Vector2.ZERO
	_mech.jump = true
	await _tick()
	await _tick()
	_mech.jump = false
	var clock := 0.0
	while clock < (3.4 if fly else 2.4):
		if fly:
			_mech.jump = clock > 0.35 and clock < 1.8
		if dive:
			_mech.crouch = clock > 0.3 and not _mech.grounded
		clock += await _tick()
	_mech.jump = false
	_mech.crouch = false


## Un paso: la cámara de costado sigue a la meca, suave.
func _tick() -> float:
	await get_tree().physics_frame
	var delta := 1.0 / Engine.physics_ticks_per_second
	if not _tucked.has(_title.text):
		_tucked[_title.text] = 0.0
	if _mech.mover.tucks():
		_tucked[_title.text] += delta
	var at := _mech.mover.global_position + Vector3.UP * 2.6
	_cam_at = at if _first else _cam_at.lerp(at, 1.0 - exp(-3.0 * delta))
	_first = false
	_eye.global_transform = Transform3D(Basis(), _cam_at + _cam_from).looking_at(_cam_at, Vector3.UP)
	return delta
