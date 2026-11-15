extends Node3D

## LA CUADRADA CON CHANFLES, MAQUETA DE ARCILLA (15/11/2026, el usuario: «agregar chamfers a las dos esquinas de
## adelante y a las dos de atrás… un cubo con chamfers… el del medio esté más adelantado… el centro escalonado»; de las
## plantas: «mostrame cómo se verían en una nave el 1, 2, 3 y 6»). Sobre la meca de verdad (sus piernas y sus brazos, la
## caja escondida), con la altura chata (la cabina de 2,3 m, el disco de 1 m).
##   · LA CAJA de 6,14 m por dentro con las cuatro esquinas cortadas (`front`, `back`); el disco de abajo, igual.
##   · EL VIDRIO: el frente, los chanfles de adelante y la mitad de adelante de los costados.
##   · EL CENTRO ESCALONADO: la tarima con dos escalones alrededor, de la misma forma; el ascensor adentro, atrás; el
##     movimiento delante.
##   · LA SILLA DEL MEDIO ADELANTE; las de los brazos atrás, giradas `turn` hacia afuera.
##   · LOS KITS en los chanfles de atrás; las municiones y la batería en la pared de atrás.
##   tools/godot_ventana.sh res://tests/chamfer_cabin_look.tscn -- --salida=C:/carpeta --planta=3 [--hombro=2] [--techo=1]
## LA CABEZA (`--techo`, el usuario, 15/11/2026: «a la misma altura que está retraída a los costados… toda esa parte del
## techo sea vidriada también… el final del fondo de todo el techo para que sea más alto… una estética más interesante
## la forma de la cabeza»): el techo de la mitad de adelante, de vidrio; la de atrás, más alta (`RISE`). 1, en escalón,
## con un frente de vidrio entre las dos; 2, el vidrio del techo sube en rampa hasta la mitad y atrás queda plano; 3,
## todo el techo sube hacia atrás. Sin `--techo`, plano. LA TARIMA, octogonal.

const VIEW := Vector2i(1280, 720)
const IN := 3.07
const WALL := 0.24
const CLEAR := 2.3
const DISC := 1.0
const SLAB := 0.22
## Las plantas (las del dibujo): [chanfle de adelante, de atrás, tamaño de la tarima (de centro a costado), z de la del
## medio, x de los brazos, z de los brazos, giro de los brazos (grados)].
const PLANS := {
	1: [0.7, 0.7, 1.15, -2.45, 1.9, -1.95, 0.0],
	2: [1.1, 1.1, 1.15, -2.45, 1.8, -1.85, 20.0],
	3: [1.6, 0.7, 1.15, -2.4, 1.75, -1.75, 45.0],
	4: [1.6, 0.7, 1.15, -2.4, 1.75, -1.7, 0.0],
	5: [1.1, 0.9, 1.05, -2.55, 1.85, -1.5, 30.0],
	6: [0.7, 1.4, 1.15, -2.45, 1.95, -1.9, 15.0],
}
const STEP_TALL := 0.15
const LIFT_R := 0.48
const LIFT_AT := 0.5

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.42, 0.44, 0.47)
const FLOOR := Color(0.62, 0.63, 0.65)
const DECK := Color(0.7, 0.71, 0.73)
const SEAT := Color(0.25, 0.42, 0.7)
const PERSON := Color(0.93, 0.93, 0.93)
const LIFT := Color(0.3, 0.45, 0.75)
const KIT := Color(0.78, 0.27, 0.27)
const BATTERY := Color(0.93, 0.75, 0.16)
const AMMO := Color(0.47, 0.53, 0.32)
const GLASS_OUTSIDE := Color(0.5, 0.66, 0.76, 0.38)
const GLASS_INSIDE := Color(0.6, 0.8, 0.92, 0.14)

var _folder := ""
var _plan := 1
var _eye: Camera3D = null
var _title: Label = null
var _real: Mech = null
var _shell := Node3D.new()
var _glass_paint := StandardMaterial3D.new()
var _roof: Node3D = null
var _head := 0
## Cuánto más alto queda el techo de atrás (m).
const RISE := 0.9


func _ready() -> void:
	var shoulder_out := -1.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--planta="):
			_plan = int(argument.trim_prefix("--planta="))
		if argument.begins_with("--techo="):
			_head = int(argument.trim_prefix("--techo="))
		if argument.begins_with("--hombro="):
			shoulder_out = float(argument.trim_prefix("--hombro="))
	get_window().size = VIEW
	_stage()
	var form := CabinGrid.current()
	form.cell = 13
	form.across = 12
	form.height_cells = roundi((DISC + CLEAR + SLAB * 2.0 - CabinGrid.SLAB * 2.0) / CabinGrid.CELL)
	if shoulder_out >= 0.0:
		form.shoulder_out = shoulder_out
	CabinGrid.apply(form)
	_real = Mech.new()
	_real.has_cabin = false
	_real.arms_kind = Mech.Arms.POSE
	_real.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_real)
	await get_tree().create_timer(2.5).timeout
	_real.freeze = true
	if _real.label != null:
		_real.label.visible = false
	for part in _real.look.get_children():
		if part is MeshInstance3D and (part as MeshInstance3D).mesh is BoxMesh:
			(part as MeshInstance3D).visible = false
	_real.look.add_child(_shell)
	_shell.position.y = -CabinGrid.HALF_HEIGHT + DISC + SLAB
	_glass_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass_paint.roughness = 0.15
	_build(PLANS[_plan])
	var shots: Array = []
	_glass_paint.albedo_color = GLASS_OUTSIDE
	var name_of := "%d%s" % [_plan, "" if _head == 0 else " · techo %d" % _head]
	_title.text = "%s. De frente" % name_of
	_look(Vector3(-13.0, 0.5, -21.0), Vector3(0.0, -3.5, 0.0), 45.0)
	shots.append(await _grab())
	_title.text = "%s. De atrás, de costado" % name_of
	_look(Vector3(16.0, 1.5, 17.0), Vector3(0.0, -3.5, 0.0), 45.0)
	shots.append(await _grab())
	_glass_paint.albedo_color = GLASS_INSIDE
	_title.text = "%s. Adentro, desde atrás" % name_of
	_look(Vector3(0.6, 1.9, IN - 0.5), Vector3(-0.2, 0.7, -3.0), 85.0)
	shots.append(await _grab())
	_roof.visible = false
	_title.text = "%s. Desde arriba, sin techo" % name_of
	_look(Vector3(-1.5, 11.0, 3.5), Vector3(0.0, 0.0, -0.3), 50.0)
	shots.append(await _grab())
	_save(shots)
	get_tree().quit()


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


## ── LA CAJA (el origen, en el piso de la cabina) ─────────────────────────────────────────────────────────────────

## El borde de la caja con sus chanfles, de radio `reach` (de centro a costado), en orden: el frente, el chanfle de
## adelante a la derecha, el costado derecho (partido en el medio), el de atrás a la derecha, la pared de atrás, el de
## atrás a la izquierda, el costado izquierdo (partido), el de adelante a la izquierda.
func _outline(reach: float, front: float, back: float) -> PackedVector2Array:
	var k := reach / IN
	var f := front * k
	var b := back * k
	return PackedVector2Array([Vector2(-reach + f, -reach), Vector2(reach - f, -reach), Vector2(reach, -reach + f),
		Vector2(reach, 0.0), Vector2(reach, reach - b), Vector2(reach - b, reach), Vector2(-reach + b, reach),
		Vector2(-reach, reach - b), Vector2(-reach, 0.0), Vector2(-reach, -reach + f)])


## Los lados de vidrio (de `_outline`): el frente, los chanfles de adelante y la mitad de adelante de los costados.
const GLASS_SIDES := [0, 1, 2, 8, 9]


func _build(plan: Array) -> void:
	var front: float = plan[0]
	var back: float = plan[1]
	var inner := _outline(IN, front, back)
	var outer := _outline(IN + WALL, front, back)
	# El disco de abajo, la junta, el piso y el techo: la misma forma.
	_prism(outer, -SLAB - DISC, -SLAB, DARK_METAL)
	_prism(_outline(IN + WALL + 0.06, front, back), -SLAB - 0.06, -SLAB + 0.06, METAL.darkened(0.25))
	_prism(outer, -SLAB, 0.0, FLOOR)
	_roof = Node3D.new()
	_shell.add_child(_roof)
	_head_roof(outer)
	# Las paredes: metal o vidrio, lado por lado, hasta el techo (que puede subir hacia atrás).
	for i in inner.size():
		var j := (i + 1) % inner.size()
		var a := outer[i]
		var b := outer[j]
		var middle := (a.y + b.y) * 0.5
		var glass: bool = GLASS_SIDES.has(i)
		_panel(a, b, _height(a.y, middle), _height(b.y, middle), _glass_paint if glass else Clay.material(METAL))
	# El centro escalonado, octogonal: dos escalones alrededor y la tarima; el ascensor adentro, atrás.
	var size: float = plan[2]
	_prism(_octagon(size + 0.6), 0.0, STEP_TALL, DECK.darkened(0.1))
	_prism(_octagon(size + 0.3), 0.0, STEP_TALL * 2.0, DECK.darkened(0.05))
	_prism(_octagon(size), 0.0, STEP_TALL * 3.0, DECK)
	Clay.cylinder(_shell, LIFT_R, 0.04, Vector3(0, STEP_TALL * 3.0 + 0.02, LIFT_AT), LIFT)
	# Las sillas: la del medio adelante, los brazos atrás y girados; el movimiento en la tarima.
	_post(Vector3(0.0, 0.0, plan[3]), 0.0)
	var turn := deg_to_rad(plan[6])
	_post(Vector3(-plan[4], 0.0, plan[5]), turn)
	_post(Vector3(plan[4], 0.0, plan[5]), -turn)
	_post(Vector3(0.0, STEP_TALL * 3.0, LIFT_AT - LIFT_R - 0.45), 0.0)
	# Los kits en los chanfles de atrás (dos en cada uno); las municiones y la batería en la pared de atrás.
	for side: float in [-1.0, 1.0]:
		var middle := Vector2(side * (IN - back * 0.5), IN - back * 0.5)
		var out := Vector2(side, 1.0).normalized()
		var along := Vector2(-out.y, out.x)
		for shift: float in [-0.3, 0.3]:
			var spot := middle + along * shift * minf(back / 0.9, 1.0) - out * 0.06
			var kit := Clay.box(_shell, Vector3(0.5, 0.5, 0.12), Vector3(spot.x, 0.7, spot.y), KIT)
			kit.basis = Basis(Vector3.UP, atan2(-along.y, along.x))
	for x: float in [-0.6, 0.6]:
		Clay.box(_shell, Vector3(0.6, 0.6, 0.12), Vector3(x, 1.4, IN - 0.06), AMMO)
	Clay.box(_shell, Vector3(0.4, 0.5, 0.12), Vector3(0.0, 0.6, IN - 0.06), BATTERY)


## Un octógono regular, con un lado al frente, de `reach` de su centro a cada lado.
func _octagon(reach: float) -> PackedVector2Array:
	var corner := reach / cos(PI / 8.0)
	var points := PackedVector2Array()
	for i in 8:
		var angle := PI / 8.0 + TAU * i / 8.0
		points.append(Vector2(sin(angle), -cos(angle)) * corner)
	return points


## LA CABEZA: el alto del techo en `z` (de la cara de adentro del techo), según la variante. `side_z`: en qué mitad
## está la pared que lo pregunta (para el escalón de la 1, que en z = 0 tiene dos altos).
func _height(z: float, side_z: float) -> float:
	var back := (z if absf(z) > 0.001 else side_z) > 0.0
	match _head:
		1:
			return CLEAR + (RISE if back else 0.0)
		2:
			return CLEAR + RISE if back else CLEAR + RISE * clampf((z + IN + WALL) / (IN + WALL), 0.0, 1.0)
		3:
			return CLEAR + RISE * clampf((z + IN + WALL) / (2.0 * (IN + WALL)), 0.0, 1.0)
	return CLEAR


## EL TECHO: la mitad de adelante (z < 0), de vidrio, salvo el plano (sin `--techo`); la de atrás, de metal; los dos
## con el alto de `_height`. En el escalón (la 1), un frente de vidrio entre las dos.
func _head_roof(outer: PackedVector2Array) -> void:
	if _head == 0:
		var flat := _prism(outer, CLEAR, CLEAR + SLAB, METAL)
		flat.reparent(_roof, false)
		return
	for half: float in [-1.0, 1.0]:
		var part := _clip(outer, half)
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tool.set_smooth_group(4294967295)
		var center := Vector2.ZERO
		for point in part:
			center += point
		center /= part.size()
		for i in part.size():
			var a := part[i]
			var b := part[(i + 1) % part.size()]
			for point: Vector2 in [center, a, b]:
				tool.add_vertex(Vector3(point.x, _height(point.y, half), point.y))
		tool.generate_normals()
		var mesh := MeshInstance3D.new()
		mesh.mesh = tool.commit()
		var paint := Clay.material(METAL).duplicate() as StandardMaterial3D
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = _glass_paint if half < 0.0 else paint
		_roof.add_child(mesh)
	if _head == 1:
		var width := IN + WALL
		_panel(Vector2(-width, 0.0), Vector2(width, 0.0), CLEAR + RISE, CLEAR + RISE, _glass_paint, CLEAR)


## La mitad de un polígono convexo: la de adelante (`half` −1, z ≤ 0) o la de atrás (1, z ≥ 0).
func _clip(points: PackedVector2Array, half: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var a_in := a.y * half >= 0.0
		var b_in := b.y * half >= 0.0
		if a_in:
			out.append(a)
		if a_in != b_in:
			out.append(a.lerp(b, a.y / (a.y - b.y)))
	return out


## Una pared fina de `a` a `b` (en planta), del piso (o de `from`) a `top_a` / `top_b` (puede ir inclinada arriba).
func _panel(a: Vector2, b: Vector2, top_a: float, top_b: float, paint: Material, from := 0.0) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(4294967295)
	var p := [Vector3(a.x, from, a.y), Vector3(b.x, from, b.y), Vector3(b.x, top_b, b.y), Vector3(a.x, top_a, a.y)]
	for k: int in [0, 1, 2, 0, 2, 3]:
		tool.add_vertex(p[k])
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	if paint is StandardMaterial3D and not paint == _glass_paint:
		var both := (paint as StandardMaterial3D).duplicate() as StandardMaterial3D
		both.cull_mode = BaseMaterial3D.CULL_DISABLED
		paint = both
	mesh.material_override = paint
	_shell.add_child(mesh)


## Un prisma de borde `points` (convexo, en planta), de `y0` a `y1`: tapas planas y costados con aristas.
func _prism(points: PackedVector2Array, y0: float, y1: float, color: Color) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Plano: cada cara con su arista (el usuario: «shading auto smooth», no suavizado entre la tapa y el costado).
	tool.set_smooth_group(4294967295)
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= points.size()
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		for tri: Array in [[Vector3(center.x, y1, center.y), Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y)],
				[Vector3(center.x, y0, center.y), Vector3(b.x, y0, b.y), Vector3(a.x, y0, a.y)],
				[Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y)],
				[Vector3(a.x, y0, a.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y)]]:
			for point: Vector3 in tri:
				tool.add_vertex(point)
	tool.generate_normals()
	var part := MeshInstance3D.new()
	part.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	part.material_override = paint
	_shell.add_child(part)
	return part


## UN PUESTO: la silla y el que se sienta, mirando al frente girado `turn`.
func _post(at: Vector3, turn: float) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = turn
	_shell.add_child(holder)
	Clay.box(holder, Vector3(0.55, 0.12, 0.5), Vector3(0, 0.45, 0.05), SEAT)
	Clay.box(holder, Vector3(0.55, 0.65, 0.1), Vector3(0, 0.8, 0.3), SEAT)
	Clay.cylinder(holder, 0.06, 0.4, Vector3(0, 0.2, 0.05), DARK_METAL)
	Clay.box(holder, Vector3(0.4, 0.6, 0.25), Vector3(0, 0.85, 0.15), PERSON)
	Clay.sphere(holder, 0.13, Vector3(0, 1.3, 0.12), PERSON)
	Clay.box(holder, Vector3(0.36, 0.14, 0.45), Vector3(0, 0.56, -0.12), PERSON)


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _shell.global_transform * from
	_eye.look_at(_shell.global_transform * to, Vector3.UP)


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
	var path := "%s/chanfle_%d%s.png" % [_folder, _plan, "" if _head == 0 else "_techo_%d" % _head]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
