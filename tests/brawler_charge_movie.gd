extends Node

## EL VIDEO DE LA PELEA (para mandárselo al usuario): el Luchador contra la meca cinemática, con una cámara que sigue a
## los dos de costado, y después el choque contra el borde. Primero sólo arranca el piso y lo tira (`ROCKS` s), después
## todos los ataques. La meca esquiva un ataque sí y otro no (la embestida con un dash cuando le faltan 38 m; la onda del
## golpe al piso, saltando cuando le faltan 20 m; la piedra, caminando de costado desde que la tira). Se graba con
## --write-movie:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/pelea.avi --fixed-fps 30 res://tests/brawler_charge_movie.tscn

const FIGHT := 40.0
const ROCKS := 20.0

var _boss: Brawler = null
var _brain: BrawlerBrain = null
var _eye: Camera3D = null
var _title: Label = null
var _cam_at := Vector3.ZERO
var _cam_from := Vector3.ZERO
var _first := true
var _dodged := -1


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	_title.position = Vector2(20, 462)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
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
	world.environment.glow_enabled = true
	add_child(world)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = true
	BrawlerArchetype.mech_kind = BrawlerArchetype.Kind.KINEMATIC
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	_brain = _boss.get_node("Cabeza") as BrawlerBrain
	# El letrero de su cabeza se pisa con su barra: lo dice el de abajo.
	_brain._label.visible = false
	_eye = Camera3D.new()
	_eye.far = 2000.0
	_eye.fov = 60.0
	add_child(_eye)
	_eye.make_current()
	var mech := _brain.target as Mech
	await _run(mech, 0.5)
	mech.scripted = true
	BrawlerBrain.moves = BrawlerBrain.Moves.THROW
	await _run(mech, ROCKS)
	BrawlerBrain.moves = BrawlerBrain.Moves.ALL
	await _run(mech, FIGHT)
	# CONTRA EL BORDE.
	var crashes := _brain.crashes
	var arena := _boss.arena
	_brain.awake = false
	mech.put(Transform3D(Basis(), Vector3(0.0, Mech.standing_height(), -(arena.radius - 8.0))))
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, -(arena.radius - 75.0))))
	Health.of(mech).left = BrawlerArchetype.MECH_HEALTH
	_first = true
	await _run(mech, 0.3)
	_brain.awake = true
	var clock := 0.0
	while _brain.crashes == crashes and clock < 20.0:
		clock += await _tick(mech)
	await _run(mech, 3.5)
	get_tree().quit()


func _run(mech: Mech, seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		clock += await _tick(mech)


func _tick(mech: Mech) -> float:
	await get_tree().physics_frame
	var delta := 1.0 / Engine.physics_ticks_per_second
	var ground := mech.mover.global_position if mech.mover != null else mech.global_position
	if mech.scripted:
		var to_boss := _boss.global_position - ground
		mech.aim_yaw = atan2(-to_boss.x, -to_boss.z)
		mech.move = Vector2.ZERO
		mech.dash = false
		mech.jump = false
		_dodge(mech, ground, to_boss)
		# Que no se termine la pelea: con poca vida, vuelve a llenarse.
		if Health.of(mech).left < 30.0:
			Health.of(mech).left = BrawlerArchetype.MECH_HEALTH
	# LA CÁMARA: de costado a la línea entre los dos, más lejos cuanto más separados.
	var line := ground - _boss.global_position
	line.y = 0.0
	var gap := line.length()
	var side := line.normalized().cross(Vector3.UP) if gap > 1.0 else Vector3.RIGHT
	var at := (_boss.global_position + ground) * 0.5 + Vector3.UP * 12.0
	var from := at + side * (gap * 0.75 + 55.0) + Vector3.UP * (25.0 + gap * 0.2) - line.normalized() * 15.0
	var follow := 1.0 if _first else 1.0 - exp(-2.5 * delta)
	_first = false
	_cam_at = _cam_at.lerp(at, follow)
	_cam_from = _cam_from.lerp(from, follow)
	_eye.global_transform = Transform3D(Basis(), _cam_from).looking_at(_cam_at, Vector3.UP)
	_title.text = _brain.stage + "\na %.0f m · el jefe a %.0f m/s · la meca %s este ataque" % [gap, absf(_boss.speed),
		"esquiva" if _dodging() else "no esquiva"]
	return delta


## Un ataque sí y otro no.
func _dodging() -> bool:
	return (_brain.charges + _brain.slams + _brain.throws) % 2 == 0


func _dodge(mech: Mech, ground: Vector3, to_boss: Vector3) -> void:
	# La piedra: desde que la tiró hasta que cae, caminando de costado.
	if not _brain._rocks.is_empty() and (_brain.charges + _brain.slams + _brain.throws) % 2 == 1:
		mech.move = Vector2(1.0, 0.0)
	var attack := _brain.charges + _brain.slams + _brain.throws
	if not _dodging() or _dodged == attack:
		return
	if _brain.stage.contains("¡arranca!") and to_boss.length() - Brawler.BOX.z * 0.5 < 38.0:
		_dodged = attack
		mech.move = Vector2(1.0, 0.0)
		mech.dash = true
	for wave in _brain._waves:
		if is_instance_valid(wave) and wave.launched and wave.way.dot(ground - wave.origin) - wave.front < 24.0:
			_dodged = attack
			mech.jump = true
