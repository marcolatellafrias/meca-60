extends Node

## LA ARTILLERÍA, IDEAS PARA ELEGIR (18/11/2026; el usuario: «dos sistemas de artillería, uno que tire balas y otro que
## tire misiles… el que está en artillería tiene un espacio muy chico para 2 cosas de tal calibre… una sola arma que se
## transforma o… se switchea… dos bases distintas para la artillería, una de los dos costados y otra unificada en la
## torre, pero que los cañones o el arma sean el mismo»): la meca jaula, una por idea, en fila, sacando el arma de hoy de
## la torre (CageCabin.gun) y poniendo la de la idea. LAS DOS ARMAS SON SIEMPRE LAS MISMAS (las balas: el racimo de cuatro
## caños de hoy; los misiles: una caja de cuatro tubos); cambia sólo cómo se enganchan. Una hoja, de atrás y de arriba.
##   tools/godot_ventana.sh res://tests/artillery_ideas_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const GAP := 14.0
const IDEAS := [
	"1. hoy: el racimo de caños",
	"2. torre: las dos, lado a lado, en una horquilla",
	"3. torre: una arriba de la otra",
	"4. torre: un tambor que da media vuelta (caños arriba o tubos arriba)",
	"5. torre: un revólver de seis (tres caños, tres tubos), gira un sexto",
	"6. costados del de arriba: caños a la izquierda, misiles a la derecha",
	"7. costados: las dos en una barra de hombro a hombro",
]

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _shots: Array = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
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
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	var mechs: Array[CageMech] = []
	for index in IDEAS.size():
		var mech := CageMech.new()
		mech.scripted = true
		mech.position = Vector3(index * GAP, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
		add_child(mech)
		mech.label.visible = false
		mechs.append(mech)
	await get_tree().create_timer(2.0).timeout
	for index in IDEAS.size():
		_idea(index, mechs[index].cabin as CageCabin)
	await get_tree().create_timer(0.3).timeout
	for found in get_tree().root.find_children("*", "Label3D", true, false):
		(found as Label3D).visible = false
	for index in IDEAS.size():
		# Mirando al arma de hoy (escondida o no): de atrás, a la derecha y de arriba; las de los costados, más lejos.
		var at := (mechs[index].cabin as CageCabin).gun.global_position + Vector3(0.0, -0.2, 0.2)
		var away := Vector3(2.0, 1.1, 2.6) if index < 5 else Vector3(0.8, 2.6, 4.6)
		await _shot(IDEAS[index], at + away, at, 40.0)
	_save()
	get_tree().quit()


## LA IDEA `index` en la cabina `cage`: saca el arma de hoy (menos en la 1) y pone la suya.
func _idea(index: int, cage: CageCabin) -> void:
	if index == 0:
		return
	var turn := cage.gun.get_parent() as Node3D
	var pivot := cage.gun.position
	cage.gun.visible = false
	match index:
		1:
			var cradle := _cradle(turn, pivot, 0.75)
			_bullets(cradle, Vector3(-0.2, 0.0, 0.0))
			_missiles(cradle, Vector3(0.2, 0.0, 0.0))
		2:
			var cradle := _cradle(turn, pivot, 0.45)
			_bullets(cradle, Vector3(0.0, 0.16, 0.0))
			_missiles(cradle, Vector3(0.0, -0.18, 0.0))
		3:
			var cradle := _cradle(turn, pivot, 0.55)
			Clay.cylinder(cradle, 0.24, 0.62, Vector3(0.0, 0.0, -0.05), CageCabin.DARK, Vector3(90.0, 0.0, 0.0))
			# Arriba, la mitad de los caños; abajo, la de los tubos (da media vuelta sobre su largo para cambiar).
			for x: float in [-0.07, 0.07]:
				Clay.cylinder(cradle, 0.035, 0.85, Vector3(x, 0.12, -0.7), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
			for x: float in [-0.08, 0.08]:
				Clay.cylinder(cradle, 0.07, 0.12, Vector3(x, -0.11, -0.4), CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
			Clay.box(cradle, Vector3(0.52, 0.02, 0.66), Vector3(0.0, 0.0, -0.05), CageCabin.YELLOW)
		4:
			var cradle := _cradle(turn, pivot, 0.55)
			Clay.cylinder(cradle, 0.1, 0.5, Vector3(0.0, 0.0, 0.0), CageCabin.DARK, Vector3(90.0, 0.0, 0.0))
			for k in 6:
				var angle := TAU * k / 6.0
				var spot := Vector3(cos(angle), sin(angle), 0.0) * 0.18
				if k % 2 == 0:
					Clay.cylinder(cradle, 0.035, 0.9, spot + Vector3(0.0, 0.0, -0.45), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
				else:
					Clay.cylinder(cradle, 0.075, 0.55, spot + Vector3(0.0, 0.0, -0.1), CageCabin.YELLOW.darkened(0.2), Vector3(90.0, 0.0, 0.0))
					Clay.cylinder(cradle, 0.055, 0.02, spot + Vector3(0.0, 0.0, -0.38), CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
		5, 6:
			_hide_tower(cage)
			# En el espacio de la meca: el cubo es su caja (`size`); a los costados, arriba.
			var mech := cage.mech
			var half := mech.size * 0.5
			# La tapa del cubo: a la altura de la silla del pozo (la de la locomoción) más un poco.
			half.y = mech.to_local((cage.chairs[CageCabin.LOCOMOTION] as Node3D).global_position).y + 0.45
			var y := half.y - 0.3
			if index == 5:
				for s: float in [-1.0, 1.0]:
					var bracket := Node3D.new()
					bracket.position = Vector3(s * (half.x + 0.42), y, 0.0)
					mech.add_child(bracket)
					Clay.box(bracket, Vector3(0.42, 0.12, 0.22), Vector3(-s * 0.21, -0.1, 0.0), CageCabin.DARK)
					if s < 0.0:
						_bullets(bracket, Vector3.ZERO)
					else:
						_missiles(bracket, Vector3.ZERO)
			else:
				var bar := Node3D.new()
				bar.position = Vector3(0.0, half.y + 0.35, 0.0)
				mech.add_child(bar)
				Clay.cylinder(bar, 0.05, half.x * 2.0 + 0.9, Vector3.ZERO, CageCabin.DARK, Vector3(0.0, 0.0, 90.0))
				for s: float in [-1.0, 1.0]:
					Clay.box(bar, Vector3(0.12, 0.35, 0.12), Vector3(s * (half.x - 0.1), -0.18, 0.0), CageCabin.DARK)
				_bullets(bar, Vector3(-(half.x + 0.3), 0.0, 0.0))
				_missiles(bar, Vector3(half.x + 0.3, 0.0, 0.0))


## LA HORQUILLA de la torre, de `wide` de ancho, en `pivot` del plato: devuelve lo que cabecea.
func _cradle(turn: Node3D, pivot: Vector3, wide: float) -> Node3D:
	for s: float in [-1.0, 1.0]:
		Clay.box(turn, Vector3(0.05, 0.3, 0.12), pivot + Vector3(s * (wide * 0.5 + 0.03), -0.1, 0.0), CageCabin.DARK)
	Clay.box(turn, Vector3(wide + 0.1, 0.06, 0.12), pivot + Vector3(0.0, -0.25, 0.0), CageCabin.DARK)
	var cradle := Node3D.new()
	cradle.position = pivot
	turn.add_child(cradle)
	Clay.cylinder(cradle, 0.04, wide + 0.12, Vector3.ZERO, CageCabin.RIM_COLOR, Vector3(0.0, 0.0, 90.0))
	return cradle


## LAS BALAS: el racimo de cuatro caños de hoy, en su caja, con la culata amarilla.
func _bullets(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.3, 0.25, 0.55), at + Vector3(0.0, 0.0, -0.05), CageCabin.DARK)
	for x: float in [-0.06, 0.06]:
		for y: float in [-0.06, 0.06]:
			Clay.cylinder(parent, 0.035, 0.9, at + Vector3(x, y, -0.75), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(0.22, 0.12, 0.1), at + Vector3(0.0, 0.0, 0.27), CageCabin.YELLOW)


## LOS MISILES: una caja de cuatro tubos, con las bocas oscuras adelante y la tapa amarilla.
func _missiles(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.34, 0.34, 0.6), at + Vector3(0.0, 0.0, -0.1), CageCabin.METAL)
	for x: float in [-0.08, 0.08]:
		for y: float in [-0.08, 0.08]:
			Clay.cylinder(parent, 0.06, 0.02, at + Vector3(x, y, -0.41), CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(0.36, 0.04, 0.5), at + Vector3(0.0, 0.19, -0.08), CageCabin.YELLOW)


## Sin artillero en la torre: se esconde la torre con su plato (en la de dos, no hay).
func _hide_tower(cage: CageCabin) -> void:
	(cage.gun.get_parent() as Node3D).visible = false
	(cage.chairs[CageCabin.GUNNER] as Node3D).visible = false
	# El plato de la torre (lo que queda debajo del plato que gira).
	var plate := (cage.gun.get_parent() as Node3D).position - Vector3(0.0, 0.04, 0.0)
	for child in cage.upper.get_children():
		if child is MeshInstance3D and (child as Node3D).position.distance_to(plate) < 0.1:
			(child as Node3D).visible = false
	for child in cage.upper.get_children():
		if child.name == "Torre":
			(child as Node3D).visible = false


## La caja del módulo de arriba sin la torre (en su espacio).
func _upper_box(cage: CageCabin) -> AABB:
	var box := AABB()
	var first := true
	var turn := cage.gun.get_parent()
	for found in cage.upper.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		if mesh.name == "Torre" or turn.is_ancestor_of(mesh) or not mesh.is_visible_in_tree():
			continue
		var local := cage.upper.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box


func _shot(name_of: String, from: Vector3, to: Vector3, fov: float) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	_title.text = name_of
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_shots.append(get_viewport().get_texture().get_image())


func _save() -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(_shots.size() / 2.0), false, first.get_format())
	for index in _shots.size():
		var shot: Image = _shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/artilleria_ideas.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
