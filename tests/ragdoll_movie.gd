extends Node

## EL RAGDOLL AL MORIR (con ventana, unos 25 segundos de video): la meca jaula y el Luchador se desarman al quedarse sin
## vida (PartsRagdoll.fall_apart, desde Health): un esqueleto de partes unidas en sus puntos, que sale como lo empujó el
## golpe que lo mató (Health.push); los grandes caen más lento. LA JAULA: la mata un golpe fuerte de frente, un empujón
## de costado, y muere sin empujón; EL JEFE: lo mata una piña fuerte. Imprime cuántos pedazos, su
## gravedad y cuánto tardan en quedarse quietos. Se graba con --write-movie:
##   tools/godot_ventana.sh --resolution 960x540 --write-movie C:/carpeta/ragdoll.avi --fixed-fps 30 res://tests/ragdoll_movie.tscn

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
	_boss.put(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(60.0, 0.0, 60.0)))
	_mech.label.visible = false
	# LA JAULA: muere de un golpe fuerte de frente (la tira: hacia atrás y arriba), de un empujón de costado, y sin
	# empujón (se desploma). Cada vez, una jaula nueva.
	await _kill_mech("la jaula: la mata un golpe fuerte de frente (la tira, 16 m)", HitReaction.Kind.KNOCKDOWN,
		Vector3.FORWARD, 16.0, Vector3(0.0, 0.0, 0.0))
	await _kill_mech("la jaula: la mata un empujón de costado (8 m)", HitReaction.Kind.PUSH, Vector3.RIGHT, 8.0,
		Vector3(0.0, 0.0, 30.0))
	await _kill_mech("la jaula: muere sin empujón (se desploma)", HitReaction.Kind.FLINCH, Vector3.ZERO, 0.0,
		Vector3(30.0, 0.0, 0.0))
	# EL JEFE: lo mata una piña fuerte de frente.
	_title.text = "el jefe: lo mata una piña fuerte de frente"
	var boss_at := _boss.global_position
	var far := Vector3(-20.0, 30.0, 75.0) * Brawler.scale()
	_look(boss_at + Vector3.UP * 12.0 * Brawler.scale(), boss_at + far)
	await _wait(0.8)
	Health.of(_boss).left = 1.0
	_brain.take_hit(400000.0, boss_at + Vector3.UP * 12.0 * Brawler.scale() + Vector3.RIGHT * Brawler.box().x * 0.5,
		"golpe")
	await get_tree().physics_frame
	await _watch("el jefe", boss_at + Vector3.UP * 10.0 * Brawler.scale(), boss_at + far, 6.0)
	get_tree().quit()


## Una jaula nueva en `at`, mirando a −z; un golpe del jefe que la mata (HitReaction.land: le saca todo, con `kind`,
## empujándola `distance` m hacia `away`), y los pedazos.
func _kill_mech(label: String, kind: HitReaction.Kind, away: Vector3, distance: float, at: Vector3) -> void:
	_title.text = label
	var mech := CageMech.new()
	mech.scripted = true
	mech.position = at + Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
	add_child(mech)
	mech.label.visible = false
	Health.attach(mech, 100.0)
	var eye_from := at + Vector3(16.0, 6.0, 9.0)
	_look(at + Vector3.UP * 2.0, eye_from)
	await _wait(1.0)
	if kind == HitReaction.Kind.FLINCH:
		Health.of(mech).hurt(1000.0, "prueba")
	else:
		HitReaction.land(mech, 1000.0, "prueba", kind, away, distance, mech.global_position)
	await get_tree().physics_frame
	await _watch("%s" % label, at + Vector3.UP * 1.5 + away * distance * 0.4, eye_from + away * distance * 0.4, 4.0)


## Mira los pedazos de `who` (los cuerpos «Pedazo» nuevos) hasta `seconds`: cuántos, su gravedad y cuándo se aquietan.
func _watch(who: String, at: Vector3, from: Vector3, seconds: float) -> void:
	var pieces: Array = []
	for found in get_tree().get_nodes_in_group(PartsRagdoll.GROUP):
		if not found.has_meta("visto"):
			found.set_meta("visto", true)
			pieces.append(found)
	var still := -1.0
	var clock := 0.0
	while clock < seconds:
		_look(at, from)
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		if OS.get_cmdline_user_args().has("--traza") and not pieces.is_empty() and int(clock * 60) % 15 == 0:
			var core := pieces[0] as RigidBody3D
			print("      %.2f s: tronco en %s, a %s" % [clock, core.global_position, core.linear_velocity])
		var moving := false
		for piece: RigidBody3D in pieces:
			moving = moving or piece.linear_velocity.length() > 0.3
		if still < 0.0 and not moving and clock > 0.3:
			still = clock
	if OS.get_cmdline_user_args().has("--ver"):
		for piece: RigidBody3D in pieces:
			print("    %s en %s, a %.2f m/s, durmiendo %s" % [piece.name, piece.global_position, piece.linear_velocity.length(),
				piece.sleeping])
	print("%s: %d pedazos · gravedad %.2f · quietos a los %.1f s" % [who, pieces.size(),
		(pieces[0] as RigidBody3D).gravity_scale if not pieces.is_empty() else 0.0, still])


func _look(at: Vector3, from: Vector3) -> void:
	_eye.global_transform = Transform3D(Basis(), from).looking_at(at, Vector3.UP)


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
