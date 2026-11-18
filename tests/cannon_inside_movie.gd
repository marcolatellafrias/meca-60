extends Node

## EL CAÑÓN DE ENERGÍA DESDE ADENTRO (18/11/2026; ver CageBoards, CannonTip): la meca jaula frente al Luchador quieto, a
## `GAP` m. Como lo haría el que maneja: agarra el mando del brazo del cañón, elige el modo con sus tres botones y aprieta
## el clic (`use`): ráfaga mantenida, barrido mantenido moviendo el torso, súper cargado y soltado. Imprime cuánta vida le
## sacó cada uno y cuánta energía quedó. Mitad desde los ojos del que maneja, mitad de afuera. Se graba:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/canon.avi --fixed-fps 30 res://tests/cannon_inside_movie.tscn

const GAP := 30.0

var _boss: Brawler = null
var _mech: CageMech = null
var _eye: Camera3D = null
var _title: Label = null
var _inside := true


func _ready() -> void:
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
	add_child(world)
	_eye = Camera3D.new()
	_eye.near = 0.02
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 10)
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = false
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	await _wait(1.0)
	_mech = (_boss.get_node("Cabeza") as BrawlerBrain).target as CageMech
	_mech.label.visible = false
	for found in root.find_children("*", "Label3D", true, false):
		if not (found as Node).get_parent() is StaticBody3D:
			(found as Label3D).visible = false
	_boss.put(Transform3D(Basis(), Vector3.ZERO))
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -GAP)))
	await _wait(1.0)
	var cabin := _mech.cabin as CageCabin
	for seat in CageCabin.SEAT_NAMES.size():
		cabin.evict(seat)
	await _wait(0.5)
	var handle := FoldingArmArchetype.arm_of(CageBoards.piece_of(cabin, "brazo izquierdo"))
	handle.enter_mode()
	await _wait(0.6)
	print("cañón en el brazo izquierdo: %s" % (_mech.cannon != null))
	await _stage("ráfaga: el clic mantenido 2 s", "modo ráfaga", func() -> void:
		handle.use.call(true)
		await _wait(2.0)
		handle.use.call(false)
		await _wait(0.6))
	await _stage("barrido: mantenido, girando el torso", "modo barrido", func() -> void:
		handle.use.call(true)
		var front := _mech.global_basis * Vector3.FORWARD
		var yaw := atan2(-front.x, -front.z)
		for k in 60:
			handle.steer.call(yaw + deg_to_rad(10.0) * sin(k * 0.1), 0.0)
			await get_tree().physics_frame
		handle.use.call(false)
		await _wait(0.6))
	_inside = false
	await _stage("súper: cargar 1,4 s y soltar", "modo súper", func() -> void:
		handle.use.call(true)
		await _wait(1.4)
		handle.use.call(false)
		await _wait(1.5))
	print("SONIDOS: ", MechSounds.heard)
	get_tree().quit()


## UN PASO: aprieta el botón de su modo, hace lo suyo e imprime cuánta vida le sacó y la energía que quedó.
func _stage(name_of: String, button: String, act: Callable) -> void:
	_title.text = name_of
	var cabin := _mech.cabin as CageCabin
	ButtonArchetype.button_of(CageBoards.piece_of(cabin, button)).pressed.emit()
	await get_tree().physics_frame
	var before := Health.of(_boss).left
	await act.call()
	print("%-40s modo %-8s le sacó %5.1f · energía %.2f" % [name_of, CannonTip.MODE_NAMES[_mech.cannon.mode],
		before - Health.of(_boss).left, _mech.energy.level])


func _physics_process(_delta: float) -> void:
	if _mech == null:
		return
	var cabin := _mech.cabin as CageCabin
	if _inside:
		var eye := cabin.board_root().global_transform * CageCabin.driver_eye(CageCabin.shape())
		_eye.fov = 80.0
		_eye.global_position = eye
		_eye.look_at(eye - _mech.global_basis.z * 5.0 - Vector3.UP * 0.4, Vector3.UP)
	else:
		var at := _mech.global_position
		_eye.fov = 55.0
		_eye.global_position = at + _mech.global_basis * Vector3(-7.0, 3.0, 5.0)
		_eye.look_at(at + _mech.global_basis * Vector3(0.0, 1.0, -14.0), Vector3.UP)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
