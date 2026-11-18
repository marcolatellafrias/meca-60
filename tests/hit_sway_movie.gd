extends Node

## LOS GOLPES CON EL RESORTE (con ventana, unos 20 segundos de video): el resorte de los golpes (HitSpring, común con los
## personajes) inclina lo que recibe y lo devuelve rebotando, sólo como dibujo. Primero EL JEFE (el Luchador) recibe
## piñas de la meca —un directo, un mazazo, y de costado— (BrawlerBrain.take_hit); después LA JAULA recibe empujones
## del jefe —de frente y de costado— (HitReaction.land). Se graba con --write-movie:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/golpes.avi --fixed-fps 30 res://tests/hit_sway_movie.tscn

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
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, 0.0)))
	_mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -40.0)))
	# EL JEFE (mira hacia −z, a la meca).
	_look(_boss.global_position + Vector3.UP * 9.0, Vector3(34.0, 14.0, -14.0))
	await _wait(1.0)
	var size := Brawler.box()
	var chest := _boss.global_position + Vector3.UP * size.y * 0.55
	await _hit_boss("el jefe: una piña floja (40.000)", chest + Vector3.FORWARD * size.z * 0.5, 40000.0)
	await _hit_boss("el jefe: un directo al alcance máximo (130.000)", chest + Vector3.FORWARD * size.z * 0.5, 130000.0)
	await _hit_boss("el jefe: un mazazo (340.000)", chest + Vector3.FORWARD * size.z * 0.5, 340000.0)
	await _hit_boss("el jefe: un directo de costado", chest + Vector3.RIGHT * size.x * 0.5, 130000.0)
	# LA JAULA (mira hacia +z, al jefe).
	var at := _mech.mover.global_position
	_look(at + Vector3.UP * 2.5, Vector3(16.0, 5.0, -6.0) + at)
	await _wait(0.8)
	await _hit_mech("la jaula: un empujón de frente (6 m)", Vector3.BACK * -1.0, 6.0)
	await _hit_mech("la jaula: un empujón de costado (6 m)", Vector3.RIGHT, 6.0)
	await _hit_mech("la jaula: un empujón fuerte de frente (16 m)", Vector3.BACK * -1.0, 16.0)
	get_tree().quit()


func _hit_boss(label: String, at: Vector3, strength: float) -> void:
	_title.text = label
	_brain.take_hit(strength, at, "golpe")
	Health.of(_boss).left = Health.of(_boss).full
	await _wait(2.0)


func _hit_mech(label: String, away: Vector3, distance: float) -> void:
	_title.text = label
	HitReaction.of(_mech).clear()
	HitReaction.land(_mech, 0.0, "prueba", HitReaction.Kind.PUSH, away, distance, _mech.global_position)
	var at := _mech.mover.global_position
	var clock := 0.0
	var most := 0.0
	while clock < 2.2:
		most = maxf(most, rad_to_deg(_mech.global_basis.y.angle_to(Vector3.UP)))
		# La cámara la sigue de costado (se corre con el empujón).
		var now := _mech.mover.global_position
		at = at.lerp(now, 0.1)
		_look(at + Vector3.UP * 2.5, Vector3(16.0, 5.0, -6.0) + at)
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
	print("%s: la caja se inclinó hasta %.1f°" % [label, most])


func _look(at: Vector3, from: Vector3) -> void:
	_eye.global_transform = Transform3D(Basis(), from).looking_at(at, Vector3.UP)


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
