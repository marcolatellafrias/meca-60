extends Node3D

## COSAS PARA AGARRAR EN LA ZONA DEL VIDRIO de la cápsula facetada (16/11/2026, el usuario: «cómo podemos attachear
## objetos que estén en la zona del cristal… no necesariamente que nazcan desde ahí, sino más bien que su objeto
## interactuable está ahí… brazos articulados que salen de una zona opaca, pero que al mirar al cristal se ven y son
## fáciles de agarrar, pero que no obstruyen tanto la visión… varias ideas en clay»). La cápsula de la meca (radio
## `RADIUS`, sobresale un tercio, el vidrio la mitad de adelante) y en cada una otra idea. Cada una: desde la cámara del
## que maneja (el centro) y cortada de costado.
##   tools/godot_ventana.sh res://tests/glass_controls_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const RADIUS := 0.75
const BOX := Vector3(2.0, 2.0, 2.0)
const IDEAS := [
	"1 · dos palancas en brazos articulados desde los costados, abajo de la mirada",
	"2 · un manubrio colgado del marco de arriba",
	"3 · un riel que sigue el vidrio por abajo, con manijas que corren",
	"4 · un yugo que sube desde el hueco del piso",
	"5 · pantallitas en brazos desde arriba, en las esquinas de la vista",
	"6 · un brazo de tijera desde el techo con un tablerito",
	"7 · la 1 robusta (mando de palo) y la 5 colgada del vidrio de arriba",
	"8 · la 1 robusta (mando de consola) y la 5 colgada del vidrio de arriba",
	"9 · los mandos con la base en la cara de vidrio de abajo y adelante",
	"10 · los mandos con la base en las caras de vidrio de costado y adelante",
	"11 · los mandos con la base en la cara de adelante, abajo",
	"12 · los mandos con la base en las esquinas triangulares de abajo y adelante",
]
## Desde la 7, sólo esas (con --ideas=7,8) y cuatro vistas cada una.
var _only: Array[int] = []
const INSIDE := Color(0.72, 0.72, 0.7)
const SHELL := Color(0.6, 0.61, 0.63)
const GLASS := Color(0.62, 0.8, 0.92, 0.3)
const DARK := Color(0.26, 0.27, 0.3)
const METAL := Color(0.5, 0.52, 0.56)
const BODY := Color(0.85, 0.55, 0.35)
const RED := Color(0.8, 0.2, 0.15)
const YELLOW := Color(0.95, 0.75, 0.15)
const SCREEN := Color(0.3, 0.75, 0.55)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--ideas="):
			for n in argument.trim_prefix("--ideas=").split(","):
				_only.append(int(n))
	get_window().size = VIEW
	_stage()
	for index in IDEAS.size():
		var root := Node3D.new()
		root.position = Vector3(0.0, 0.0, index * 40.0)
		add_child(root)
		_capsule(root)
		var idea := Node3D.new()
		idea.position = _center()
		root.add_child(idea)
		_idea(idea, index + 1)
	for index in IDEAS.size():
		if not _only.is_empty() and not _only.has(index + 1):
			continue
		var at := Vector3(0.0, 0.0, index * 40.0)
		var c := at + _center()
		_title.text = IDEAS[index]
		var shots: Array[Image] = []
		_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		_eye.fov = 95.0
		_eye.near = 0.02
		shots.append(await _view(c, c + Vector3(0.0, -0.15, -1.0)))
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.size = 2.4
		_eye.near = 10.0 - 0.02
		shots.append(await _view(c + Vector3(10.0, 0.0, 0.0), c))
		if index + 1 >= 7:
			_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
			_eye.fov = 95.0
			_eye.near = 0.02
			shots.append(await _view(c, c + Vector3(0.7, -0.6, -0.5)))
			shots.append(await _view(c, c + Vector3(-0.8, -0.6, -0.2)))
		if index + 1 >= 9:
			_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
			_eye.size = 2.4
			_eye.near = 10.0 - 0.05
			var top := c + Vector3(0.0, 10.0, 0.0)
			_eye.global_position = top
			_eye.look_at(c, Vector3.FORWARD)
			for i in 4:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			shots.append(get_viewport().get_texture().get_image())
		_save(shots, index + 1)
	get_tree().quit()


## El centro de la cápsula (la cámara), desde el centro del piso de la caja: sobresale un tercio de la cara de adelante.
func _center() -> Vector3:
	return Vector3(0.0, 1.2, -BOX.z * 0.5 + RADIUS * 0.3)


## LA CÁPSULA DE LA MECA: caja, facetas, la mitad de adelante de vidrio liso, y el que maneja (sin brazos ni cabeza: la
## cámara va donde iría su cabeza).
func _capsule(root: Node3D) -> void:
	var c := _center()
	var front := -BOX.z * 0.5
	var inner := SurfaceTool.new()
	inner.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glass := SurfaceTool.new()
	glass.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Dictionary in CageMesh.faceted_sphere():
		var normal: Vector3 = face["normal"]
		if normal.is_equal_approx(Vector3.DOWN):
			continue
		var points: Array = []
		for p: Vector3 in face["points"]:
			points.append(c + p * RADIUS)
		var parts := CageMesh.split_by_z(points, front)
		if (parts[0] as Array).size() >= 3:
			CageMesh.smooth_face(glass, parts[0], c, normal)
		if (parts[1] as Array).size() >= 3:
			CageMesh.face(inner, parts[1], normal)
	_mesh(root, inner, INSIDE)
	_mesh(root, glass, GLASS)
	var box := SurfaceTool.new()
	box.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := BOX * 0.5
	for normal: Vector3 in [Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN]:
		var u := Vector3(normal.y, normal.z, normal.x)
		var v := normal.cross(u)
		var m := Vector3(0.0, half.y, 0.0) + normal * half
		u *= half
		v *= half
		CageMesh.face(box, [m - u - v, m + u - v, m + u + v, m - u + v], normal)
	_mesh(root, box, SHELL)
	var pelvis := c + Vector3(0.0, -0.8, 0.12)
	Clay.box(root, Vector3(0.46, 0.06, 0.46), pelvis + Vector3(0.0, -0.1, -0.04), DARK)
	Clay.box(root, Vector3(0.46, 0.55, 0.06), pelvis + Vector3(0.0, 0.22, 0.2), DARK)
	_limb(root, pelvis, c + Vector3(0.0, -0.3, 0.12), 0.15, BODY)
	for s: float in [-1.0, 1.0]:
		var knee := pelvis + Vector3(s * 0.12, 0.0, -0.42)
		_limb(root, pelvis + Vector3(s * 0.11, 0.0, 0.0), knee, 0.07, BODY)
		_limb(root, knee, knee + Vector3(0.0, -0.46, 0.06), 0.06, BODY)


## CADA IDEA, en el espacio de la cápsula (el origen, la cámara; adelante, −Z).
func _idea(at: Node3D, kind: int) -> void:
	var r := RADIUS
	match kind:
		1:
			for s: float in [-1.0, 1.0]:
				var base := Vector3(s * r * 0.95, -0.25, 0.1)
				var elbow := Vector3(s * 0.55, -0.42, -0.2)
				var grip := Vector3(s * 0.3, -0.4, -0.45)
				_arm(at, [base, elbow, grip])
				_limb(at, grip, grip + Vector3(0.0, 0.16, 0.0), 0.03, DARK)
				Clay.sphere(at, 0.045, grip + Vector3(0.0, 0.18, 0.0), RED)
		2:
			var frame_top := Vector3(0.0, r * 0.95, -r * 0.3)
			for s: float in [-1.0, 1.0]:
				_limb(at, frame_top + Vector3(s * 0.28, 0.0, 0.0), Vector3(s * 0.3, -0.32, -0.42), 0.015, METAL)
			var points: Array[Vector3] = []
			for i in 9:
				var a := lerpf(-0.6, 0.6, i / 8.0)
				points.append(Vector3(sin(a) * 0.5, -0.34, -cos(a) * 0.5))
			for i in range(1, points.size()):
				_limb(at, points[i - 1], points[i], 0.025, DARK)
			for s: float in [-1.0, 1.0]:
				Clay.sphere(at, 0.04, Vector3(s * 0.28, -0.34, -0.42), YELLOW)
		3:
			var rail: Array[Vector3] = []
			for i in 13:
				var a := lerpf(PI * 0.15, PI * 0.85, i / 12.0)
				rail.append(Vector3(cos(a) * r * 0.85, -sin(a) * r * 0.55, -r * 0.6))
			for i in range(1, rail.size()):
				_limb(at, rail[i - 1], rail[i], 0.02, METAL)
			for i: int in [3, 6, 9]:
				Clay.box(at, Vector3(0.08, 0.12, 0.08), rail[i] + Vector3(0.0, 0.05, 0.03), DARK)
				Clay.sphere(at, 0.035, rail[i] + Vector3(0.0, 0.13, 0.03), RED if i == 6 else YELLOW)
		4:
			var foot := Vector3(0.0, -1.2, -0.25)
			var top := Vector3(0.0, -0.45, -0.42)
			_limb(at, foot, top, 0.035, METAL)
			_limb(at, top + Vector3(-0.22, 0.0, 0.0), top + Vector3(0.22, 0.0, 0.0), 0.025, DARK)
			for s: float in [-1.0, 1.0]:
				_limb(at, top + Vector3(s * 0.22, 0.0, 0.0), top + Vector3(s * 0.22, 0.14, 0.0), 0.03, DARK)
			Clay.box(at, Vector3(0.12, 0.06, 0.06), top + Vector3(0.0, 0.04, 0.0), RED)
		5:
			for s: float in [-1.0, 1.0]:
				var base := Vector3(s * r * 0.7, r * 0.7, 0.0)
				var mid := Vector3(s * 0.5, 0.42, -0.25)
				var screen := Vector3(s * 0.42, 0.24, -0.5)
				_arm(at, [base, mid, screen])
				var panel := Node3D.new()
				panel.transform = Transform3D(Basis.looking_at(-screen.normalized(), Vector3.UP), screen)
				at.add_child(panel)
				Clay.box(panel, Vector3(0.2, 0.13, 0.02), Vector3.ZERO, DARK)
				Clay.box(panel, Vector3(0.17, 0.1, 0.01), Vector3(0.0, 0.0, -0.012), SCREEN)
		6:
			var ceiling := Vector3(0.0, r * 0.98, -0.1)
			var hinge := Vector3(0.0, 0.25, -0.3)
			var hold := Vector3(0.0, -0.28, -0.42)
			for s: float in [-1.0, 1.0]:
				_limb(at, ceiling + Vector3(s * 0.1, 0.0, 0.0), hinge + Vector3(-s * 0.1, 0.0, 0.0), 0.015, METAL)
				_limb(at, hinge + Vector3(s * 0.1, 0.0, 0.0), hold + Vector3(-s * 0.1, 0.0, 0.0), 0.015, METAL)
			var panel := Node3D.new()
			panel.transform = Transform3D(Basis.looking_at(-hold.normalized(), Vector3.UP), hold)
			at.add_child(panel)
			Clay.box(panel, Vector3(0.36, 0.2, 0.03), Vector3.ZERO, DARK)
			for i in 3:
				Clay.sphere(panel, 0.025, Vector3((i - 1) * 0.1, 0.03, -0.02), YELLOW if i == 1 else RED)
		7:
			_sticks(at, "palo")
			_glass_screens(at)
		8:
			_sticks(at, "consola")
			_glass_screens(at)
		9:
			_sticks_from(at, func(s: float) -> Array: return [Vector3(s * 0.28, -0.55, -0.51),
				Vector3(0.0, -1.0, -1.0).normalized()])
		10:
			_sticks_from(at, func(s: float) -> Array: return [Vector3(s * 0.6, -0.25, -0.46),
				Vector3(s, 0.0, -1.0).normalized()])
		11:
			_sticks_from(at, func(s: float) -> Array: return [Vector3(s * 0.2, -0.22, -0.75), Vector3.FORWARD])
		12:
			_sticks_from(at, func(s: float) -> Array: return [Vector3(s * 0.42, -0.42, -0.53),
				Vector3(s, -1.0, -1.0).normalized()])


## LA 1, ROBUSTA (el usuario: «algo retráctil y con un control un poco más importante… más bulky… con más botones… uno
## esté retraído y el otro expandido… la base sea un poco más grande»): a cada costado, una base grande atornillada a
## la cara opaca y un brazo grueso de dos tramos; el de la derecha, estirado hacia la zona del vidrio, abajo de la
## mirada; el de la izquierda, plegado contra su base. `grip`: «palo» (un mando vertical con botones, gatillo y un
## hongo arriba) o «consola» (una consola chica que se agarra de arriba, con un palito, botones y una perilla).
func _sticks(at: Node3D, grip: String) -> void:
	var r := RADIUS
	for s: float in [-1.0, 1.0]:
		var base := Vector3(s * r * 0.97, -0.18, 0.05)
		var mount := Node3D.new()
		mount.transform = Transform3D(Basis.looking_at(Vector3(-s, 0.0, 0.0), Vector3.UP), base)
		at.add_child(mount)
		Clay.box(mount, Vector3(0.3, 0.34, 0.05), Vector3.ZERO, DARK)
		Clay.cylinder(mount, 0.09, 0.08, Vector3(0.0, 0.0, -0.05), METAL, Vector3(90.0, 0.0, 0.0))
		var hub := base + Vector3(-s * 0.09, 0.0, 0.0)
		var elbow: Vector3
		var hand: Vector3
		if s > 0.0:
			elbow = Vector3(0.52, -0.38, -0.12)
			hand = Vector3(0.3, -0.42, -0.42)
		else:
			elbow = Vector3(-0.6, -0.36, 0.12)
			hand = Vector3(-0.58, -0.24, -0.06)
		for pair: Array in [[hub, elbow], [elbow, hand]]:
			_limb(at, pair[0], pair[1], 0.035, METAL)
		Clay.sphere(at, 0.055, hub, DARK)
		Clay.sphere(at, 0.05, elbow, DARK)
		var holder := Node3D.new()
		holder.position = hand
		at.add_child(holder)
		Clay.cylinder(holder, 0.05, 0.05, Vector3.ZERO, DARK)
		if grip == "palo":
			Clay.box(holder, Vector3(0.075, 0.2, 0.09), Vector3(0.0, 0.12, 0.0), DARK)
			Clay.cylinder(holder, 0.045, 0.04, Vector3(0.0, 0.24, 0.0), METAL)
			Clay.sphere(holder, 0.03, Vector3(0.0, 0.27, 0.0), RED)
			Clay.box(holder, Vector3(0.03, 0.05, 0.03), Vector3(0.0, 0.14, -0.055), YELLOW)
			for b in 3:
				Clay.sphere(holder, 0.014, Vector3(-s * 0.04, 0.18 - b * 0.035, -0.02), RED if b == 0 else YELLOW)
		else:
			Clay.box(holder, Vector3(0.2, 0.07, 0.15), Vector3(0.0, 0.06, 0.0), DARK)
			Clay.cylinder(holder, 0.012, 0.08, Vector3(0.04 * s, 0.13, 0.01), METAL)
			Clay.sphere(holder, 0.025, Vector3(0.04 * s, 0.17, 0.01), RED)
			for b in 3:
				Clay.cylinder(holder, 0.015, 0.02, Vector3(-s * 0.05, 0.1, -0.04 + b * 0.04), YELLOW if b == 1 else RED)
			Clay.cylinder(holder, 0.03, 0.02, Vector3(-s * 0.02, 0.1, 0.05), Color(0.92, 0.9, 0.84))


## LA 5, COLGADA DEL VIDRIO DE ARRIBA (el usuario: «que salgan del vidrio de arriba inclinado, con brazos mucho más cortos…
## con las pantallitas apuntando hacia el jugador»): de la cara de vidrio inclinada de arriba y adelante, un brazo corto
## y la pantalla mirándolo.
func _glass_screens(at: Node3D) -> void:
	var lean := RADIUS * sqrt(2.0)
	for s: float in [-1.0, 1.0]:
		var anchor := Vector3(s * 0.26, 0.42, 0.42 - lean)
		var screen := anchor + Vector3(0.0, -0.16, 0.02)
		Clay.cylinder(at, 0.04, 0.02, anchor, DARK)
		_limb(at, anchor, screen + Vector3(0.0, 0.06, 0.0), 0.015, METAL)
		var panel := Node3D.new()
		var toward := (Vector3.ZERO - screen).normalized()
		panel.transform = Transform3D(Basis.looking_at(-toward, Vector3.UP), screen)
		at.add_child(panel)
		Clay.box(panel, Vector3(0.2, 0.13, 0.02), Vector3.ZERO, DARK)
		Clay.box(panel, Vector3(0.17, 0.1, 0.01), Vector3(0.0, 0.0, 0.012), SCREEN)


## LOS MANDOS DE LA 7 CON LA BASE EN OTRO LADO (el usuario: «los controles probá poniéndolos en distintas posiciones de
## vidrio y mostrame cómo se ven en corte (sus orígenes)»): `where(lado)` devuelve [la base, la normal de su cara]. El de
## la derecha, estirado hacia abajo de la mirada; el de la izquierda, plegado contra su base.
func _sticks_from(at: Node3D, where: Callable) -> void:
	for s: float in [-1.0, 1.0]:
		var spot: Array = where.call(s)
		var base: Vector3 = spot[0]
		var normal: Vector3 = spot[1]
		var mount := Node3D.new()
		mount.transform = Transform3D(Basis.looking_at(-normal, Vector3.UP if absf(normal.y) < 0.9 else Vector3.BACK), base)
		at.add_child(mount)
		Clay.box(mount, Vector3(0.26, 0.22, 0.05), Vector3.ZERO, DARK)
		Clay.cylinder(mount, 0.08, 0.08, Vector3(0.0, 0.0, -0.05), METAL, Vector3(90.0, 0.0, 0.0))
		var hub := base - normal * 0.09
		var hand := Vector3(0.3, -0.36, -0.38) if s > 0.0 else hub - normal * 0.08 + Vector3(0.0, 0.1, 0.06)
		var elbow := (hub + hand) * 0.5 - normal * 0.08 + Vector3(s * 0.06, -0.04, 0.0)
		_limb(at, hub, elbow, 0.035, METAL)
		_limb(at, elbow, hand, 0.035, METAL)
		Clay.sphere(at, 0.05, hub, DARK)
		Clay.sphere(at, 0.045, elbow, DARK)
		var grip := Node3D.new()
		grip.position = hand
		at.add_child(grip)
		Clay.cylinder(grip, 0.05, 0.05, Vector3.ZERO, DARK)
		Clay.box(grip, Vector3(0.075, 0.2, 0.09), Vector3(0.0, 0.12, 0.0), DARK)
		Clay.cylinder(grip, 0.045, 0.04, Vector3(0.0, 0.24, 0.0), METAL)
		Clay.sphere(grip, 0.03, Vector3(0.0, 0.27, 0.0), RED)
		for b in 3:
			Clay.sphere(grip, 0.014, Vector3(-s * 0.04, 0.18 - b * 0.035, -0.02), RED if b == 0 else YELLOW)


## Un brazo articulado: tramos finos y bolas en las juntas.
func _arm(at: Node3D, points: Array) -> void:
	for i in range(1, points.size()):
		_limb(at, points[i - 1], points[i], 0.022, METAL)
	for p: Vector3 in points:
		Clay.sphere(at, 0.035, p, DARK)


func _limb(root: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var holder := Clay.limb(root, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)


func _mesh(root: Node3D, tool: SurfaceTool, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	root.add_child(mesh)


func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(400, 1, 400), Vector3(0, -2.5, 0), Color(0.82, 0.8, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -140.0, 0.0)
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.86)
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


func _view(from: Vector3, to: Vector3) -> Image:
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array[Image], number: int) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var w := shots[0].get_width()
	var h := shots[0].get_height()
	var sheet := Image.create(w * 2, h * ceili(shots.size() / 2.0), false, shots[0].get_format())
	for index in shots.size():
		sheet.blit_rect(shots[index], Rect2i(Vector2i.ZERO, shots[index].get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/vidrio_%d.png" % [_folder, number]
	sheet.save_png(path)
	print("CAPTURA ", path)
