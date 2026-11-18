extends Node

## EL ATERRIZAJE CON EL RESORTE (con ventana, unos 25 segundos de video): al caer, la caja se hunde y vuelve rebotando
## (el resorte vertical de HitSpring, común con los personajes), sólo como dibujo: el motor no baja. LA JAULA salta en el
## lugar sin resorte (para comparar) y con él, cae en picada agachada (KinematicSettings.dive_speed) y cae de 15 m (las
## dos últimas, fuerte: levantan polvo, ParticleSystems.landing_dust); después EL JEFE
## salta (Brawler.jump) y cae sobre sus orugas. A media velocidad. Imprime cuánto se hundió cada vez. Se graba con --write-movie:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/aterrizar.avi --fixed-fps 30 res://tests/land_spring_movie.tscn

var _boss: Brawler = null
var _brain: BrawlerBrain = null
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
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
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var parent := Node3D.new()
	add_child(parent)
	BrawlerArchetype.thinking = false
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	_brain = _boss.get_node("Cabeza") as BrawlerBrain
	_eye = Camera3D.new()
	_eye.fov = 50.0
	add_child(_eye)
	_eye.make_current()
	await _wait(1.0)
	_mech = _brain.target as Mech
	_mech.scripted = true
	_mech.label.visible = false
	_brain._label.visible = false
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, 60.0)))
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -10.0)))
	var at := _mech.mover.global_position
	_look(at + Vector3.UP * 4.0, Vector3(19.0, 5.0, -5.0) + at)
	await _wait(1.0)
	# A MEDIA VELOCIDAD, para que se vea el hundirse (el video dura el doble).
	Engine.time_scale = 0.5
	var k := _mech.kinematic_settings()
	var sink := k.land_sink
	k.land_sink = 0.0
	await _jump_mech("la jaula: un salto, SIN resorte", false)
	k.land_sink = sink
	await _jump_mech("la jaula: un salto, con resorte (%.2f m a %.0f m/s)" % [k.land_sink, k.land_full_speed], false)
	await _jump_mech("la jaula: cae en picada, agachada", true)
	# De 15 m de alto (se la pone ahí y cae).
	_title.text = "la jaula: cae de 15 m"
	_mech.put(Transform3D(Basis(Vector3.UP, PI), _mech.mover.global_position + Vector3.UP * 15.0))
	await _land_mech(_title.text, false, 3.2)
	# EL JEFE: salta 30 m adelante (de la maqueta, en su escala).
	var from := _boss.global_position
	_look(from + Vector3(0.0, 14.0, 0.0) * Brawler.scale(), from + Vector3(95.0, 30.0, 0.0) * Brawler.scale())
	await _wait(0.8)
	for arc: float in [12.0, 25.0]:
		_title.text = "el jefe: un salto de %.0f m de alto" % arc
		var spot := _boss.global_position + Vector3(0.0, 0.0, 15.0 if arc < 20.0 else -15.0) * Brawler.scale()
		_boss.jump(spot, 1.0, arc * Brawler.scale())
		var deepest := 0.0
		var clock := 0.0
		while clock < 3.0:
			await get_tree().physics_frame
			clock += 1.0 / Engine.physics_ticks_per_second
			deepest = maxf(deepest, _boss.body_spring.y)
		print("%s: se hundió %.2f m (de la maqueta)" % [_title.text, deepest * Brawler.LAND_SINK])
	get_tree().quit()


func _jump_mech(label: String, dive: bool) -> void:
	_title.text = label
	_mech.jump = true
	await _wait(0.1)
	_mech.jump = false
	await _land_mech(label, dive, 3.4)


## Hasta que cae y se repone (`seconds`): cuánto se hundió y si levantó polvo.
func _land_mech(label: String, dive: bool, seconds: float) -> void:
	var dust := _mech.mover.dust_raised
	var deepest := 0.0
	var deepest_at := 0.0
	var back_at := -1.0
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_mech.crouch = dive and clock > 0.25 and not _mech.grounded
		var y := _mech.mover.body_spring.y
		if y > deepest:
			deepest = y
			deepest_at = clock
		elif deepest > 0.05 and back_at < 0.0 and y < deepest * 0.1:
			back_at = clock
	_mech.crouch = false
	print("%s: se hundió %.2f m%s%s" % [label, deepest * _mech.kinematic_settings().land_sink,
		" · levantó polvo" if _mech.mover.dust_raised > dust else "",
		" · volvió en %.2f s" % ((back_at - deepest_at) * Engine.time_scale) if back_at > 0.0 else ""])
	await _wait(0.6)


func _look(at: Vector3, from: Vector3) -> void:
	_eye.global_transform = Transform3D(Basis(), from).looking_at(at, Vector3.UP)


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
