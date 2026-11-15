extends Node3D

## EL DISCO CON CÁPSULAS ARRIBA, MAQUETA DE ARCILLA (15/11/2026, el usuario: «un disco que tenga varias cabinas arriba
## del disco… en forma de cápsula, sin el domo de abajo, solamente el cilindro y la parte de arriba… cuando los jugadores
## se meten ahí, ven la UI de esa cabina… el techo de la meca sí sea caminable… el disco, que es la base, más o menos
## grueso… la pelvis, otro cilindro un poco más chico en diámetro… una cápsula más grande, la de control, al medio, y
## las otras tres alrededor… tal vez una… se le ve que apunta una ametralladora»). Cada cápsula con alguien sentado
## adentro; arriba del disco se camina (una persona de verdad parada ahí y otra en el piso, para la escala).
##   1 · en cruz: la grande al medio, las chicas a la izquierda, a la derecha y atrás;
##   2 · en triángulo: las chicas adelante a cada lado y atrás;
##   3 · la 1 con las cápsulas hundidas hasta la mitad en el disco (más bajas);
##   4 · la 1 con una franja de vidrio alrededor de cada cápsula (se ve al de adentro) y la ametralladora en la derecha;
##   5 · la 1 con el disco más grueso y la pelvis más alta.
##   tools/godot_ventana.sh res://tests/capsule_disc_look.tscn -- --salida=C:/carpeta --variante=1

const VIEW := Vector2i(1280, 720)
const DISC_R := 4.8
const PELVIS_R := 2.7
const BIG := Vector2(1.35, 1.7)
const SMALL := Vector2(0.95, 1.45)
const NAMES := {
	1: "en cruz",
	2: "en triángulo",
	3: "las cápsulas hundidas hasta la mitad",
	4: "con una franja de vidrio, y la ametralladora",
	5: "el disco más grueso y la pelvis más alta",
}

const METAL := Color(0.55, 0.57, 0.6)
const DARK := Color(0.3, 0.31, 0.34)
const DECK := Color(0.68, 0.69, 0.71)
const CAPSULE := Color(0.6, 0.62, 0.66)
const SKIN := Color(0.86, 0.66, 0.5)
const SEAT := Color(0.25, 0.42, 0.7)
const ACCENT := {"walk": Color(0.3, 0.45, 0.75), "arm": Color(0.8, 0.25, 0.2), "gun": Color(0.93, 0.75, 0.16)}

var _folder := ""
var _variant := 1
var _eye: Camera3D = null
var _title: Label = null
var _glass := StandardMaterial3D.new()


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
	get_window().size = VIEW
	_glass.albedo_color = Color(0.65, 0.82, 0.95, 0.2)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass.roughness = 0.1
	_stage()
	var top := _mech()
	await get_tree().create_timer(3.0).timeout
	_title.text = "%d. %s" % [_variant, NAMES[_variant]]
	var shots: Array = []
	for view: Array in [
			[Vector3(-11.0, top + 5.0, -13.0), Vector3(0.0, top - 2.0, 0.0), 45.0],
			[Vector3(11.0, top + 6.0, 12.0), Vector3(0.0, top - 1.5, 0.0), 45.0],
			[Vector3(-17.0, top - 2.0, 0.0), Vector3(0.0, top - 3.0, 0.0), 42.0],
			[Vector3(0.0, top + 12.0, 1.0), Vector3(0.0, top, 0.0), 45.0]]:
		_look(view[0], view[1], view[2])
		shots.append(await _grab())
	_save(shots)
	get_tree().quit()


## LA MECA: devuelve el alto del techo del disco (donde se camina).
func _mech() -> float:
	var thick := 2.4 if _variant == 5 else 1.6
	var pelvis_tall := 2.4 if _variant == 5 else 1.4
	var hip := 4.2
	var pelvis_bottom := hip
	var disc_bottom := pelvis_bottom + pelvis_tall
	var deck := disc_bottom + thick
	# La pelvis: un cilindro más angosto debajo del disco; las piernas salen de ella.
	_cylinder(PELVIS_R, pelvis_bottom, disc_bottom, DARK.lightened(0.2))
	# El disco, con su canto un poco redondeado, y el techo, que se pisa.
	_cylinder(DISC_R, disc_bottom, deck, METAL)
	_cylinder(DISC_R - 0.12, deck, deck + 0.04, DECK)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = DISC_R
	cylinder.height = 0.2
	shape.shape = cylinder
	shape.position.y = deck - 0.06
	floor_body.add_child(shape)
	add_child(floor_body)
	# Una baranda baja en el borde del techo, para que se lea que se camina.
	for i in 24:
		var angle := TAU * i / 24.0
		Clay.cylinder(self, 0.04, 0.9, _out(angle) * (DISC_R - 0.15) + Vector3(0, deck + 0.45, 0), DARK)
	var rail := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = DISC_R - 0.19
	torus.outer_radius = DISC_R - 0.11
	rail.mesh = torus
	rail.material_override = Clay.material(DARK)
	rail.position.y = deck + 0.9
	add_child(rail)
	# Las cápsulas: la grande al medio (el movimiento) y las chicas alrededor (los brazos y la artillería).
	var sunk := 0.8 if _variant == 3 else 0.0
	_capsule(Vector3(0, deck - sunk, 0), BIG, "walk", 0.0)
	var ring := 2.9
	var places: Array = [[-PI * 0.5, "arm"], [PI * 0.5, "arm"], [PI, "gun"]]
	if _variant == 2:
		places = [[-PI / 3.0, "arm"], [PI / 3.0, "arm"], [PI, "gun"]]
	for place: Array in places:
		var angle: float = place[0]
		_capsule(_out(angle) * ring + Vector3(0, deck - sunk, 0), SMALL, place[1], angle)
	_legs(hip)
	_arms(disc_bottom, thick)
	# Una persona de verdad parada en el techo y otra en el piso.
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.lanky, Vector3(1.6, deck + 0.04, -3.2), PI * 0.2)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(DISC_R + 2.5, 0.0, -2.5), -PI * 0.6)
	return deck


## UNA MEDIA CÁPSULA en `base` (el centro de su piso): el cilindro y el techo redondeado, sin el domo de abajo; una
## franja del color de su puesto; adelante, una ventana (en la 4, una franja de vidrio alrededor); alguien sentado
## adentro mirando hacia afuera (`angle`, 0 adelante). En la 4, la del puesto de artillería lleva una ametralladora.
func _capsule(base: Vector3, size: Vector2, role: String, angle: float) -> void:
	var holder := Node3D.new()
	holder.position = base
	holder.rotation.y = -angle
	add_child(holder)
	var radius := size.x
	var tall := size.y
	var band := _variant == 4
	if band:
		# El cilindro en dos partes con una franja de vidrio a la altura de los ojos sentado.
		_cyl_in(holder, radius, 0.0, 0.8, CAPSULE)
		var glass := MeshInstance3D.new()
		var tube := CylinderMesh.new()
		tube.top_radius = radius
		tube.bottom_radius = radius
		tube.height = 0.55
		glass.mesh = tube
		glass.material_override = _glass
		glass.position.y = 0.8 + 0.275
		holder.add_child(glass)
		_cyl_in(holder, radius, 1.35, tall, CAPSULE)
	else:
		_cyl_in(holder, radius, 0.0, tall, CAPSULE)
		# La ventana del frente: un vidrio curvo apenas salido.
		var window := Clay.box(holder, Vector3(radius * 1.1, 0.5, 0.06), Vector3(0, 1.1, -radius - 0.01), Color.WHITE)
		window.material_override = _glass
	var dome := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.4
	sphere.is_hemisphere = true
	dome.mesh = sphere
	dome.material_override = Clay.material(CAPSULE.lightened(0.05))
	dome.position.y = tall
	holder.add_child(dome)
	Clay.cylinder(holder, radius + 0.03, 0.12, Vector3(0, tall - 0.2, 0), ACCENT[role])
	# La escotilla de atrás.
	Clay.box(holder, Vector3(0.7, 1.2, 0.05), Vector3(0, 0.65, radius + 0.01), DARK)
	_seated(holder, Vector3(0, 0.0, 0.15))
	if role == "gun" and _variant == 4:
		Clay.box(holder, Vector3(0.4, 0.4, 0.8), Vector3(0, tall + radius * 0.5, -0.2), DARK)
		Clay.cylinder(holder, 0.08, 1.8, Vector3(0, tall + radius * 0.5, -1.4), DARK, Vector3(90, 0, 0))


## Un piloto sentado mirando adelante (−Z del que lo tiene), con su asiento y el tablero.
func _seated(holder: Node3D, at: Vector3) -> void:
	Clay.box(holder, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(holder, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), SEAT)
	Clay.box(holder, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(holder, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(holder, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	Clay.box(holder, Vector3(0.8, 0.08, 0.3), at + Vector3(0.0, 0.75, -0.6), DARK)


func _legs(hip: float) -> void:
	for side: float in [-1.0, 1.0]:
		var from := Vector3(side * 1.7, hip + 0.2, 0.0)
		var foot := Vector3(side * 2.2, 0.35, 0.0)
		var knee := (from + foot) * 0.5 + Vector3(0, 0, -0.6)
		Clay.sphere(self, 0.85, from, DARK)
		_bar(from, knee, 0.65, METAL)
		Clay.sphere(self, 0.6, knee, DARK)
		_bar(knee, foot, 0.55, METAL)
		Clay.box(self, Vector3(1.5, 0.7, 2.3), foot + Vector3(0, 0, -0.3), DARK)


func _arms(disc_bottom: float, thick: float) -> void:
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector3(side * (DISC_R + 0.4), disc_bottom + thick * 0.5, 0.0)
		var elbow := shoulder + Vector3(side * 0.6, -2.6, 0.4)
		var fist := elbow + Vector3(-side * 0.2, -0.5, -1.8)
		Clay.sphere(self, 0.75, shoulder, DARK)
		_bar(shoulder, elbow, 0.5, METAL)
		Clay.sphere(self, 0.5, elbow, DARK)
		_bar(elbow, fist, 0.45, METAL)
		Clay.box(self, Vector3(1.1, 1.1, 1.2), fist, DARK)


func _out(angle: float) -> Vector3:
	return Vector3(sin(angle), 0.0, -cos(angle))


func _cylinder(radius: float, y0: float, y1: float, color: Color) -> void:
	var part := Clay.cylinder(self, radius, y1 - y0, Vector3(0, (y0 + y1) * 0.5, 0), color)
	(part.mesh as CylinderMesh).radial_segments = 64


func _cyl_in(holder: Node3D, radius: float, y0: float, y1: float, color: Color) -> void:
	var part := Clay.cylinder(holder, radius, y1 - y0, Vector3(0, (y0 + y1) * 0.5, 0), color)
	(part.mesh as CylinderMesh).radial_segments = 48


func _bar(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var part := Clay.limb(self, radius, a.distance_to(b), (a + b) * 0.5, color)
	part.basis = Basis.looking_at(b - a, Vector3.RIGHT if absf((b - a).normalized().y) > 0.9 else Vector3.UP)


func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -40.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	world.environment.ambient_light_energy = 1.0
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.95 else Vector3.FORWARD)


func _save(shots: Array) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first: Image = shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(shots.size() / 2.0), false, first.get_format())
	for index in shots.size():
		var shot: Image = shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/disco_capsulas_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
