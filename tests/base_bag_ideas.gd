extends Node3D

## LA BOLSA, IDEAS PARA ELEGIR (ver BaseBag; unos 10 s, sin el sandbox): la bolsa low poly con las tapas chanfleadas,
## cuatro maneras de colgarla (con la chapa al techo) y cuatro de atarla al techo (con la soga gruesa). Una captura de
## cada una, de costado y un poco de abajo, como se la ve desde el piso.
##   tools/godot_ventana.sh res://tests/base_bag_ideas.tscn -- --salida=C:/carpeta

const CEILING := 8.0
const SPACING := 7.0
const RADIUS := 0.9
const LOW := 1.0
const HIGH := 4.6

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0), BaseLayout.FLOOR_COLOR)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	var ideas: Array[Node3D] = []
	for i in 4:
		ideas.append(_one(Vector3(i * SPACING, 0, 0), i, BaseBag.Mount.PLATE))
	for i in 4:
		ideas.append(_one(Vector3(i * SPACING, 0, 12.0), BaseBag.Rope.THICK, i))
	var eye := Camera3D.new()
	eye.fov = 55.0
	add_child(eye)
	eye.make_current()
	await get_tree().create_timer(1.0).timeout
	for i in ideas.size():
		# sólo ésta a la vista
		for other in ideas:
			other.visible = other == ideas[i]
		var at := (ideas[i].get_meta("at") as Vector3) + Vector3(0, 4.2, 0)
		eye.global_position = at + Vector3(-3.5, -1.6, -7.5)
		eye.look_at(at)
		await _shot("bolsa_%d" % (i + 1))
	get_tree().quit()


## Una idea: el techo (una losa), la pared para el brazo, la bolsa, lo que la cuelga y cómo se ata.
func _one(at: Vector3, rope: int, mount: int) -> Node3D:
	var idea := Node3D.new()
	add_child(idea)
	idea.set_meta("at", at)
	var top := at + Vector3(0, CEILING - (0.5 if mount == BaseBag.Mount.BEAM else 0.0) - 0.4, 0)
	if mount == BaseBag.Mount.WALL_ARM:
		top.y = CEILING - 1.0 - 0.11 - 0.25
	Clay.box(idea, Vector3(SPACING - 0.6, 0.3, 6.0), at + Vector3(0, CEILING + 0.15, 0), BaseLayout.WALL_COLOR)
	var wall_x := at.x + 2.8
	if mount == BaseBag.Mount.WALL_ARM:
		Clay.box(idea, Vector3(0.3, CEILING, 6.0), Vector3(wall_x + 0.15, CEILING * 0.5, at.z), BaseLayout.WALL_COLOR)
	var bag_top := at + Vector3(0, HIGH, 0)
	BaseBag.bag(idea, RADIUS, HIGH - LOW, at + Vector3(0, (LOW + HIGH) * 0.5, 0), BaseLayout.BAG_COLOR)
	BaseBag.rope(idea, rope as BaseBag.Rope, top, bag_top, RADIUS)
	BaseBag.mount(idea, mount as BaseBag.Mount, top, CEILING, wall_x)
	return idea


func _shot(file: String) -> void:
	await get_tree().create_timer(0.4).timeout
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/" + file + ".png")
		print("CAPTURA ", _folder + "/" + file + ".png")
