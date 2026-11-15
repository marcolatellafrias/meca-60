extends Node3D

## EL DISCO CHICO, MAQUETA DE ARCILLA (15/11/2026, el usuario: «un disco, pero mucho más chico, sin ascensor, y que los
## jugadores… puedan saltar para subirse… un sistema sin asientos y que los jugadores se muevan libremente en ese
## círculo… que sea todo igual en el radio, pero que tenga como un bevel… en el que pueden ir componentes, palancas,
## botones, ametralladoras… hay que probar con varios experimentos de escala»). La meca más chica, de arcilla: el
## disco arriba, el torso, las piernas y los brazos debajo, con las medidas de cada escala. Las personas de verdad
## (las de character-parametric) paradas en el disco, cada una frente a un puesto del borde, y una en el piso al lado.
##   · EL DISCO: el piso de radio `walk` (lo que se camina) y un borde de `RIM` de ancho, alto `RIM_OUT` afuera y
##     `RIM_IN` adentro: la cara de arriba es un bevel que mira hacia el centro, y ahí van los controles.
##   · LOS PUESTOS, repartidos parejo en el borde: el manejo adelante (dos palancas), dos ametralladoras montadas
##     arriba del borde (el caño afuera, las manijas adentro), botoneras, relojes y una manivela atrás.
##   · EL SALTO: del piso hay que pasar el borde, `deck` + `RIM_OUT`; la vista de frente lo dibuja.
##   tools/godot_ventana.sh res://tests/small_disc_look.tscn -- --salida=C:/carpeta --escala=3
##   tools/godot_ventana.sh res://tests/small_disc_look.tscn -- --salida=C:/carpeta --fila   (todas de frente, a escala)

const VIEW := Vector2i(1280, 720)
const RIM := 0.45
const RIM_OUT := 1.0
const RIM_IN := 0.8
const DISC := 0.35
## Las escalas: [radio que se camina (m), alto del piso del disco (m), jugadores].
const SCALES := {
	1: [1.3, 1.3, 3],
	2: [1.6, 1.5, 3],
	3: [1.6, 1.5, 4],
	4: [2.0, 1.9, 3],
	5: [2.0, 1.9, 4],
	6: [2.6, 2.5, 4],
	# El disco de 5,2 m con las piernas más largas (el usuario, 15/11/2026: «quiero seguir experimentando con el disco
	# de 5.2… aumentaría el tamaño de piernas y brazos»; el salto, por ahora, no importa).
	7: [2.6, 3.2, 4],
	8: [2.6, 4.0, 4],
}
## El alto que salta hoy un personaje (PoseShape.jump_height), para comparar.
const JUMP_NOW := 1.12

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const DECK := Color(0.72, 0.73, 0.75)
const RED := Color(0.8, 0.22, 0.18)
const YELLOW := Color(0.93, 0.75, 0.16)
const FACE := Color(0.92, 0.9, 0.84)
const ARC := Color(0.95, 0.45, 0.1)
## Los que se paran en el disco, en orden.
const CREW: Array[EntityArchetype.Archetype] = [EntityArchetype.Archetype.buff, EntityArchetype.Archetype.lanky,
	EntityArchetype.Archetype.fat_athletic, EntityArchetype.Archetype.old]

var _folder := ""
var _scale := 1
var _row := false
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--escala="):
			_scale = int(argument.trim_prefix("--escala="))
		if argument == "--fila":
			_row = true
	get_window().size = VIEW
	_stage()
	if _row:
		await _lineup()
	else:
		await _one(SCALES[_scale])
	get_tree().quit()


## UNA ESCALA: la meca, sus jugadores en el disco, uno en el piso, y cuatro vistas.
func _one(plan: Array) -> void:
	var walk: float = plan[0]
	var deck: float = plan[1]
	var players: int = plan[2]
	var outer := walk + RIM
	var stations := _stations(walk)
	var mech := _mech(walk, deck, stations)
	add_child(mech)
	# Los jugadores, frente a los puestos más importantes (el manejo, las dos armas, la manivela).
	var order := [0]
	for kind: String in ["gun", "gun", "crank", "buttons", "dial"]:
		for index in stations.size():
			if stations[index][1] == kind and not order.has(index):
				order.append(index)
				break
	for i in players:
		var angle: float = stations[order[i]][0]
		var at := Vector3(sin(angle), 0.0, -cos(angle)) * (walk - 0.42) + Vector3(0.0, deck, 0.0)
		PeopleArchetype.spawn(self, CREW[i], at, -angle)
	var beside := Vector3(outer + 1.4, 0.0, -0.6)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, beside,
		-PI * 0.5 - 0.3)
	_jump_arc(beside, Vector3(outer - 0.2, deck, -0.3), deck + RIM_OUT + 0.35)
	await get_tree().create_timer(3.0).timeout
	var size := outer + deck
	var name_of := "%d. Disco de %.1f m · piso a %.1f m · salto %.1f m · %d jugadores" % [_scale, walk * 2.0, deck,
		deck + RIM_OUT, players]
	var shots: Array = []
	for view: Array in [
			[Vector3(-1.5, 1.1, -2.0) * size, Vector3(0.0, deck * 0.65, 0.0), 40.0],
			[Vector3(0.6, 0.35, -3.2) * size, Vector3(0.6, deck * 0.7, 0.0), 40.0],
			[Vector3(0.0, deck + 2.0 + outer * 2.6, 0.4), Vector3(0.0, deck, 0.0), 45.0],
			# Por encima del hombro, desde atrás y afuera del borde.
			[Vector3(walk * 0.45, deck + 2.7, walk + 1.5), Vector3(0.0, deck + 0.4, -walk * 0.3), 62.0]]:
		_title.text = name_of
		_look(view[0], view[1], view[2])
		shots.append(await _grab())
	_save(shots, "disco_%d" % _scale)


## TODAS DE FRENTE, a la misma escala (cámara ortográfica), cada una con una persona parada al lado.
func _lineup() -> void:
	var x := 0.0
	var top := 0.0
	for index: int in SCALES:
		var plan: Array = SCALES[index]
		var outer: float = plan[0] + RIM
		x += outer
		var mech := _mech(plan[0], plan[1], _stations(plan[0]))
		# De frente (desde −Z) la +X queda a la izquierda: hacia −X, para que vayan de 1 a 6 de izquierda a derecha.
		mech.position.x = -x
		add_child(mech)
		PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(-x - outer - 0.6, 0.0, -1.0), -PI * 0.15)
		var tag := Label3D.new()
		tag.text = "%d" % index
		tag.font_size = 160
		tag.outline_size = 30
		tag.modulate = Color.BLACK
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.position = Vector3(-x, plan[1] + RIM_OUT + 1.6, 0.0)
		add_child(tag)
		top = maxf(top, plan[1] + RIM_OUT + 2.4)
		x += outer + 1.6
	await get_tree().create_timer(3.0).timeout
	_title.text = "Las seis escalas, de frente, al lado de una persona"
	# Una tira ancha: sin cielo de sobra.
	get_window().size = Vector2i(1800, 560)
	await get_tree().process_frame
	_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
	_eye.keep_aspect = Camera3D.KEEP_WIDTH
	_eye.size = x + 0.4
	_eye.global_position = Vector3(-x * 0.5 + 0.8, _eye.size * 560.0 / 1800.0 * 0.5 - 0.3, -30.0)
	_eye.look_at(_eye.global_position + Vector3(0.0, 0.0, 1.0), Vector3.UP)
	var shot := await _grab()
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		shot.save_png(_folder + "/disco_fila.png")
		print("CAPTURA ", _folder + "/disco_fila.png")


## LOS PUESTOS: [ángulo desde el frente (0 = −Z, en radianes), tipo], repartidos parejo; ocho si el disco da, si no seis.
func _stations(walk: float) -> Array:
	var kinds: Array = (["drive", "gun", "dial", "buttons", "crank", "buttons", "dial", "gun"] if walk >= 1.9
		else ["drive", "gun", "buttons", "crank", "buttons", "gun"])
	var out: Array = []
	for i in kinds.size():
		out.append([TAU * i / kinds.size(), kinds[i]])
	return out


## ── LA MECA (el origen, en el piso de abajo, en el centro) ───────────────────────────────────────────────────────

func _mech(walk: float, deck: float, stations: Array) -> Node3D:
	var root := Node3D.new()
	var outer := walk + RIM
	var k := outer / 2.0
	var top := Node3D.new()
	top.position.y = deck
	root.add_child(top)
	# El disco: el piso y el borde con su bevel, de una vuelta.
	_revolve(top, PackedVector2Array([Vector2(0.0, 0.0), Vector2(walk, 0.0)]), DECK)
	_revolve(top, PackedVector2Array([Vector2(walk, 0.0), Vector2(walk, RIM_IN), Vector2(outer, RIM_OUT),
		Vector2(outer, -DISC + 0.12), Vector2(outer - 0.15, -DISC), Vector2(0.0, -DISC)]), METAL)
	# Para que las personas se paren: el piso de choque.
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = walk
	cylinder.height = DISC
	shape.shape = cylinder
	shape.position.y = -DISC * 0.5
	floor_body.add_child(shape)
	top.add_child(floor_body)
	for station: Array in stations:
		_station(top, walk, station[0], station[1])
	# SIN TORSO NI PELVIS (el usuario: «sacaría totalmente esa pelvis… que las piernas vayan directamente abajo del
	# disco… no puede ser que haya tanta diferencia entre piernas y el torso… el torso sería el disco»): las piernas
	# salen de abajo del disco y los brazos de su costado, gruesos, a la medida del disco.
	var bottom := -DISC
	for side: float in [-1.0, 1.0]:
		# Las piernas: la cadera metida en el disco, muslo y canilla con la rodilla adelante, y el pie.
		var from := Vector3(side * outer * 0.45, bottom - 0.3 * k, 0.0)
		var foot := Vector3(side * outer * 0.52, -deck + 0.18 * k, 0.0)
		var knee := (from + foot) * 0.5 + Vector3(0.0, 0.0, -0.35 * k)
		Clay.sphere(top, 0.42 * k, from, DARK_METAL)
		_bar(top, from, knee, 0.32 * k, METAL)
		Clay.sphere(top, 0.3 * k, knee, DARK_METAL)
		_bar(top, knee, foot, 0.28 * k, METAL)
		Clay.box(top, Vector3(0.75 * k, 0.36 * k, 1.2 * k), foot + Vector3(0.0, -0.0, -0.2 * k), DARK_METAL)
		# Los brazos: el hombro metido en la pared del disco, el codo afuera, el puño adelante.
		var shoulder := Vector3(side * (outer + 0.16 * k), (RIM_OUT - DISC) * 0.5 - 0.1, 0.0)
		var elbow := shoulder + Vector3(side * 0.35 * k, -deck * 0.45, 0.2 * k)
		var fist := elbow + Vector3(-side * 0.1 * k, -deck * 0.12, -0.8 * k)
		Clay.sphere(top, 0.36 * k, shoulder, DARK_METAL)
		_bar(top, shoulder, elbow, 0.26 * k, METAL)
		Clay.sphere(top, 0.26 * k, elbow, DARK_METAL)
		_bar(top, elbow, fist, 0.24 * k, METAL)
		Clay.box(top, Vector3(0.6, 0.6, 0.65) * k, fist, DARK_METAL)
	return root


## UN PUESTO en el borde, en `angle` (desde el frente): sobre el bevel, o (las ametralladoras) arriba del borde.
func _station(top: Node3D, walk: float, angle: float, kind: String) -> void:
	var outward := Vector3(sin(angle), 0.0, -cos(angle))
	if kind == "gun":
		var gun := Node3D.new()
		gun.position = outward * (walk + RIM * 0.7) + Vector3(0.0, RIM_OUT, 0.0)
		gun.rotation.y = -angle
		top.add_child(gun)
		Clay.cylinder(gun, 0.07, 0.3, Vector3(0.0, 0.15, 0.0), DARK_METAL)
		Clay.box(gun, Vector3(0.24, 0.24, 0.6), Vector3(0.0, 0.4, -0.05), DARK_METAL)
		Clay.cylinder(gun, 0.05, 0.85, Vector3(0.0, 0.42, -0.75), DARK_METAL, Vector3(90.0, 0.0, 0.0))
		Clay.box(gun, Vector3(0.5, 0.3, 0.04), Vector3(0.0, 0.5, -0.38), METAL)
		for side: float in [-1.0, 1.0]:
			Clay.cylinder(gun, 0.03, 0.2, Vector3(side * 0.13, 0.38, 0.3), YELLOW, Vector3(90.0, 0.0, 0.0))
		return
	# Sobre el bevel: `y` sale de la cara, `x` va por el borde.
	var bevel := Vector2(RIM, RIM_OUT - RIM_IN)
	var up := (Vector3.UP * bevel.x - outward * bevel.y).normalized()
	var along := Vector3(cos(angle), 0.0, sin(angle))
	var plate := Node3D.new()
	plate.basis = Basis(along, up, along.cross(up))
	plate.position = outward * (walk + RIM * 0.5) + Vector3(0.0, (RIM_IN + RIM_OUT) * 0.5, 0.0)
	top.add_child(plate)
	match kind:
		"drive":
			for side: float in [-1.0, 1.0]:
				Clay.box(plate, Vector3(0.16, 0.06, 0.24), Vector3(side * 0.2, 0.03, 0.0), DARK_METAL)
				Clay.cylinder(plate, 0.025, 0.42, Vector3(side * 0.2, 0.24, 0.0), DARK_METAL)
				Clay.sphere(plate, 0.06, Vector3(side * 0.2, 0.46, 0.0), RED)
		"buttons":
			Clay.box(plate, Vector3(0.6, 0.04, 0.28), Vector3(0.0, 0.02, 0.0), DARK_METAL)
			for i in 3:
				Clay.cylinder(plate, 0.055, 0.06, Vector3((i - 1) * 0.18, 0.06, 0.0), YELLOW if i == 1 else RED)
		"dial":
			Clay.cylinder(plate, 0.17, 0.05, Vector3(0.0, 0.025, 0.0), FACE)
			Clay.box(plate, Vector3(0.02, 0.02, 0.15), Vector3(0.04, 0.06, -0.04), RED).rotation.y = 0.6
		"crank":
			Clay.box(plate, Vector3(0.12, 0.25, 0.12), Vector3(0.0, 0.12, 0.0), DARK_METAL)
			Clay.cylinder(plate, 0.2, 0.05, Vector3(0.0, 0.25, 0.08), METAL, Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(plate, 0.025, 0.15, Vector3(0.14, 0.32, 0.17), YELLOW, Vector3(90.0, 0.0, 0.0))


## EL SALTO, punteado: de `from` (el piso) a `to` (el disco), pasando a `peak` de alto.
func _jump_arc(from: Vector3, to: Vector3, peak: float) -> void:
	for i in 23:
		var t := i / 22.0
		var at := from.lerp(to, t)
		at.y = lerpf(from.y + 1.0, to.y + 1.0, t) + 4.0 * t * (1.0 - t) * (peak - lerpf(from.y, to.y, 0.5))
		Clay.sphere(self, 0.05, at, ARC)


## Un miembro de `a` a `b`.
func _bar(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var part := Clay.limb(parent, radius, a.distance_to(b), (a + b) * 0.5, color)
	part.basis = Basis.looking_at(b - a, Vector3.RIGHT if absf((b - a).normalized().y) > 0.9 else Vector3.UP)


## UNA VUELTA de un perfil (`r`, `y`): suave alrededor, con aristas en las esquinas del perfil.
func _revolve(parent: Node3D, profile: PackedVector2Array, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 64
	for s in sides:
		var a0 := TAU * s / sides
		var a1 := TAU * (s + 1) / sides
		for p in profile.size() - 1:
			var p0 := profile[p]
			var p1 := profile[p + 1]
			var edge := p1 - p0
			var normal := Vector2(edge.y, -edge.x).normalized()
			var quad := [[p0, a0], [p1, a0], [p1, a1], [p0, a1]]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				var point: Vector2 = quad[corner][0]
				var angle: float = quad[corner][1]
				var out := Vector3(sin(angle), 0.0, -cos(angle))
				tool.set_normal(out * normal.x + Vector3.UP * normal.y)
				tool.add_vertex(out * point.x + Vector3.UP * point.y)
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	parent.add_child(mesh)


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
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.95 else Vector3.FORWARD)


func _save(shots: Array, base: String) -> void:
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
	var path := "%s/%s.png" % [_folder, base]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
