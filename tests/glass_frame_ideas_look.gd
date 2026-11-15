extends Node3D

## LA ESTRUCTURA DEL VIDRIO DE LA CABINA, IDEAS EN ARCILLA (15/11/2026, el usuario: «varias proposiciones en clay de
## cómo podemos hacer la estructura metálica del vidrio… no debería obstruir la visión… algo que groundee un poco más
## el diseño… sin que parezca algo tan fantasioso»). Una meca de verdad, con la cabina guardada, y cada idea como
## barras de arcilla encima del vidrio. Dos hojas numeradas: de afuera (el vidrio oscuro, para que se lea) y desde la
## silla del movimiento, arriba atrás (lo que tapa).
##   tools/godot_ventana.sh res://tests/glass_frame_ideas_look.tscn -- --salida=C:/carpeta
## `--claro`: sólo la 1 y la 2, con el vidrio claro y sin lo de adentro (el usuario: «enclarecer un poco el vidrio y tal
## vez ocultar temporalmente el interior»), de frente, del otro costado y de adentro: una fila por idea.

const VIEW := Vector2i(1280, 720)
const FRAME := Color(0.36, 0.38, 0.41)
const GLASS_OUTSIDE := Color(0.16, 0.24, 0.3, 0.72)
const GLASS_CLEAR := Color(0.7, 0.85, 0.95, 0.18)
const IDEAS := [
	"Sólo las aristas",
	"Aristas y parantes entre puestos",
	"Zócalo bajo el tablero",
	"Paños enmarcados de tren",
	"Costillas por afuera",
	"Postes gruesos de excavadora",
	"Bridas abulonadas",
	"Reja sobre el corte",
	"Cruces en los costados",
]

var _folder := ""
var _clear := false
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _holder: Node3D = null
var _glass: Array[MeshInstance3D] = []

## Las medidas de la caja (en el espacio de la cabina), del vidrio de afuera.
var h := 0.0
var y0 := 0.0
var y1 := 0.0
var yc := 0.0
var f := 0.0
var cut := 0.0
var side_to := 0.0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument == "--claro":
			_clear = true
	get_window().size = VIEW
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
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
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 44)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 12)
	layer.add_child(_title)
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.POSE
	_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_mech)
	await get_tree().create_timer(2.5).timeout
	_mech.freeze = true
	if _mech.label != null:
		_mech.label.visible = false
	h = CabinGrid.HALF
	y0 = CabinGrid.floor_top()
	y1 = CabinGrid.HALF_HEIGHT
	cut = CabinGrid.CHAMFER * CabinGrid.TRAMA
	yc = y1 - cut
	f = -h
	side_to = CabinGrid.line(CabinGrid.SIDE_GLASS)
	for part in _mech.cabin.get_children():
		if part is MeshInstance3D and part.name.begins_with("Vidrio"):
			_glass.append(part)
	if _clear:
		await _clear_sheet()
		get_tree().quit()
		return
	var outside: Array = []
	var inside: Array = []
	for index in IDEAS.size():
		_holder = Node3D.new()
		_mech.cabin.add_child(_holder)
		call("_idea_%d" % (index + 1))
		_title.text = "%d. %s" % [index + 1, IDEAS[index]]
		_paint_glass(GLASS_OUTSIDE)
		_show_dummies(true)
		_look(Vector3(-7.5, 1.0, -9.5), Vector3(0.0, -0.2, -0.5), 38.0)
		outside.append(await _grab())
		_paint_glass(CabinGrid.GLASS_COLOR)
		_show_dummies(false)
		var top := CabinGrid.top_seat()
		_look(top + Vector3(0.6, 1.3, 0.3), Vector3(-0.8, y0 + 1.6, f), 80.0)
		inside.append(await _grab())
		_holder.free()
	_save(outside, "estructura_afuera")
	_save(inside, "estructura_adentro")
	get_tree().quit()


## La 1 y la 2, claras y sin lo de adentro: de frente, del otro costado y de adentro.
func _clear_sheet() -> void:
	for part in _mech.cabin.get_children():
		if part is Node3D and not _glass.has(part) and not part is PelvisLift:
			(part as Node3D).visible = false
	_show_dummies(false)
	_paint_glass(GLASS_CLEAR)
	var shots: Array = []
	for index in 2:
		_holder = Node3D.new()
		_mech.cabin.add_child(_holder)
		call("_idea_%d" % (index + 1))
		_title.text = "%d. %s" % [index + 1, IDEAS[index]]
		_look(Vector3(-7.5, 1.0, -9.5), Vector3(0.0, -0.2, -0.5), 38.0)
		shots.append(await _grab())
		_title.text = "%d. de frente, del otro lado" % (index + 1)
		_look(Vector3(5.5, 0.2, -10.0), Vector3(0.0, 0.0, -1.0), 40.0)
		shots.append(await _grab())
		_title.text = "%d. de adentro" % (index + 1)
		var top := CabinGrid.top_seat()
		_look(top + Vector3(0.6, 1.3, 0.3), Vector3(-0.8, y0 + 1.6, f), 80.0)
		shots.append(await _grab())
		_holder.free()
	_save(shots, "estructura_1_y_2")


## ── LAS IDEAS ────────────────────────────────────────────────────────────────────────────────────────────────────

## 1. Sólo las aristas de la zona de vidrio: un perfil cuadrado en cada una.
func _idea_1() -> void:
	_edges(0.12)


## 2. Las aristas y un parante en cada división de los puestos (detrás de la raya del tablero, donde no hay nadie
## mirando) y uno en el medio de cada costado.
func _idea_2() -> void:
	_edges(0.12)
	for x in _post_lines():
		_profile(x, 0.09)
	for side: float in [-1.0, 1.0]:
		_side_post(side, (f + cut + side_to) * 0.5, 0.09)


## 3. Un zócalo de metal hasta el alto del tablero (lo de abajo no se ve igual), y las aristas de arriba.
func _idea_3() -> void:
	_edges(0.12)
	var tall := CabinGrid.DESK_HEIGHT
	Clay.box(_holder, Vector3(h * 2.0, tall, 0.08), Vector3(0, y0 + tall * 0.5, f - 0.02), FRAME)
	for side: float in [-1.0, 1.0]:
		Clay.box(_holder, Vector3(0.08, tall, side_to - f), Vector3(side * (h + 0.02), y0 + tall * 0.5, (f + side_to) * 0.5),
			FRAME)
	_bar(Vector3(-h, y0 + tall, f - 0.03), Vector3(h, y0 + tall, f - 0.03), 0.1)


## 4. Paños enmarcados, como un tren: parantes finos cada tres celdas y un travesaño a la altura del tablero.
func _idea_4() -> void:
	_edges(0.1)
	var step := 3
	var index := step
	while index < CabinGrid.ACROSS:
		_profile(CabinGrid.line(index), 0.06)
		index += step
	for side: float in [-1.0, 1.0]:
		var z := f + cut + (side_to - f - cut) * 0.5
		_side_post(side, z, 0.06)
		_bar(Vector3(side * h, y0 + CabinGrid.DESK_HEIGHT, f), Vector3(side * h, y0 + CabinGrid.DESK_HEIGHT, side_to), 0.06)
	_bar(Vector3(-h, y0 + CabinGrid.DESK_HEIGHT, f), Vector3(h, y0 + CabinGrid.DESK_HEIGHT, f), 0.06)


## 5. Costillas por afuera, como un tranvía o un invernadero: en cada división de los puestos y en las esquinas, una
## costilla que sube por el frente, dobla por el corte y sigue por el techo hasta atrás, parada hacia afuera.
func _idea_5() -> void:
	_edges(0.08)
	var xs: Array[float] = [-h + 0.07, h - 0.07]
	xs.append_array(_post_lines())
	for x in xs:
		var deep := 0.22
		_fin(Vector3(x, y0, f), Vector3(x, yc, f), Vector3.FORWARD, deep)
		_fin(Vector3(x, yc, f), Vector3(x, y1, f + cut), Vector3(0, 1, -1).normalized(), deep)
		_fin(Vector3(x, y1, f + cut), Vector3(x, y1, h), Vector3.UP, deep)


## 6. Postes gruesos de excavadora en las cuatro esquinas del vidrio, un umbral pesado abajo y nada más.
func _idea_6() -> void:
	for side: float in [-1.0, 1.0]:
		_bar(Vector3(side * h, y0, f), Vector3(side * h, yc, f), 0.26)
		_bar(Vector3(side * h, yc, f), Vector3(side * h, y1, f + cut), 0.26)
		_bar(Vector3(side * h, y0, side_to), Vector3(side * h, y1, side_to), 0.22)
		_bar(Vector3(side * h, y0, f), Vector3(side * h, y0, side_to), 0.2)
	_bar(Vector3(-h, y0, f), Vector3(h, y0, f), 0.26)
	_bar(Vector3(-h, y1, f + cut), Vector3(h, y1, f + cut), 0.16)


## 7. Bridas abulonadas: un borde chato y ancho alrededor de cada paño, con bulones.
func _idea_7() -> void:
	for pair in _edge_list():
		_flat(pair[0], pair[1], pair[2], 0.2)
		_bolts(pair[0], pair[1], pair[2])


## 8. Una reja de protección sobre el corte, como el techo de una excavadora, y las aristas.
func _idea_8() -> void:
	_edges(0.12)
	var normal := Vector3(0, 1, -1).normalized()
	var bars := 7
	for index in bars:
		var x := -h + h * 2.0 * (index + 0.5) / bars
		_bar(Vector3(x, yc, f) + normal * 0.12, Vector3(x, y1, f + cut) + normal * 0.12, 0.05)
	_bar(Vector3(-h, yc, f) + normal * 0.12, Vector3(h, yc, f) + normal * 0.12, 0.06)
	_bar(Vector3(-h, y1, f + cut) + normal * 0.12, Vector3(h, y1, f + cut) + normal * 0.12, 0.06)


## 9. El frente limpio, con las aristas, y una cruz de refuerzo en cada costado.
func _idea_9() -> void:
	_edges(0.12)
	for side: float in [-1.0, 1.0]:
		var x := side * h
		var a := Vector3(x, y0, f + 0.05)
		var b := Vector3(x, y1, side_to)
		var c := Vector3(x, y0, side_to)
		var d := Vector3(x, yc + (y1 - yc) * 0.5, f + cut * 0.5)
		_bar(a, b, 0.08)
		_bar(c, d, 0.08)


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## Las aristas de la zona de vidrio, de a pares, con la normal de afuera (para las bridas).
func _edge_list() -> Array:
	var all := [
		[Vector3(-h, y0, f), Vector3(h, y0, f), Vector3.FORWARD],
		[Vector3(-h, yc, f), Vector3(h, yc, f), Vector3(0, 0.4, -1).normalized()],
		[Vector3(-h, y1, f + cut), Vector3(h, y1, f + cut), Vector3(0, 1, -0.4).normalized()],
	]
	for side: float in [-1.0, 1.0]:
		var out := Vector3(side, 0, 0)
		all.append([Vector3(side * h, y0, f), Vector3(side * h, yc, f), (out + Vector3.FORWARD).normalized()])
		all.append([Vector3(side * h, yc, f), Vector3(side * h, y1, f + cut), (out + Vector3(0, 1, -1)).normalized()])
		all.append([Vector3(side * h, y1, f + cut), Vector3(side * h, y1, side_to), (out + Vector3.UP).normalized()])
		all.append([Vector3(side * h, y0, f), Vector3(side * h, y0, side_to), out])
		all.append([Vector3(side * h, y0, side_to), Vector3(side * h, y1, side_to), out])
	return all


func _edges(thick: float) -> void:
	for pair in _edge_list():
		_bar(pair[0], pair[1], thick)


## Las líneas de las divisiones de los puestos (las rayas del tablero).
func _post_lines() -> Array[float]:
	return CabinGrid.post_lines()


## Un parante del frente en `x`: sube por el frente y dobla por el corte.
func _profile(x: float, thick: float) -> void:
	_bar(Vector3(x, y0, f), Vector3(x, yc, f), thick)
	_bar(Vector3(x, yc, f), Vector3(x, y1, f + cut), thick)


## Un parante del costado en `z`, de piso a techo (o hasta el corte).
func _side_post(side: float, z: float, thick: float) -> void:
	var top := y1 if z >= f + cut else yc + (z - f)
	_bar(Vector3(side * h, y0, z), Vector3(side * h, top, z), thick)


## Una barra cuadrada de `a` a `b`. (Su arriba, cualquiera que no sea a lo largo: con UP, las barras paradas no se veían.)
func _bar(a: Vector3, b: Vector3, thick: float) -> void:
	var up := Vector3.UP if absf((b - a).normalized().y) < 0.9 else Vector3.FORWARD
	_piece(a, b, Vector3(thick, thick, a.distance_to(b) + thick), (a + b) * 0.5, up)


## Una costilla: una placa de `deep` parada hacia `out`, de `a` a `b`.
func _fin(a: Vector3, b: Vector3, out: Vector3, deep: float) -> void:
	_piece(a, b, Vector3(0.07, deep, a.distance_to(b) + 0.07), (a + b) * 0.5 + out * deep * 0.5, out)


## Una brida: un borde chato de `wide`, apoyado en el vidrio.
func _flat(a: Vector3, b: Vector3, out: Vector3, wide: float) -> void:
	_piece(a, b, Vector3(wide, 0.04, a.distance_to(b) + wide * 0.5), (a + b) * 0.5 + out * 0.02, out)


func _bolts(a: Vector3, b: Vector3, out: Vector3) -> void:
	var count := maxi(int(a.distance_to(b) / 0.32), 1)
	var across := (b - a).normalized().cross(out).normalized()
	for index in count + 1:
		var at := a.lerp(b, float(index) / count) + out * 0.05
		for way: float in [-1.0, 1.0]:
			Clay.box(_holder, Vector3(0.04, 0.04, 0.04), at + across * way * 0.065, Color(0.5, 0.52, 0.55))


## Una caja larga de `a` a `b`, con su `up` hacia `out`.
func _piece(a: Vector3, b: Vector3, size: Vector3, at: Vector3, out: Vector3) -> void:
	var along := (b - a).normalized()
	var up := (out - along * out.dot(along)).normalized()
	var piece := Clay.box(_holder, size, at, FRAME)
	piece.basis = Basis(up.cross(along), up, along)


## ── LA CÁMARA ────────────────────────────────────────────────────────────────────────────────────────────────────

func _paint_glass(color: Color) -> void:
	for pane in _glass:
		(pane.material_override as StandardMaterial3D).albedo_color = color


func _show_dummies(on: bool) -> void:
	for dummy in find_children("*", "BoneInstantiator", true, false):
		(dummy as Node3D).visible = on


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _mech.cabin.global_transform * from
	_eye.look_at(_mech.cabin.global_transform * to, Vector3.UP)


## Tres columnas, a un tercio.
func _save(shots: Array, file: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first: Image = shots[0]
	var w := first.get_width() / 3
	var h_shot := first.get_height() / 3
	var sheet := Image.create(w * 3, h_shot * ceili(shots.size() / 3.0), false, first.get_format())
	for index in shots.size():
		var shot: Image = shots[index]
		shot.resize(w, h_shot, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 3), h_shot * (index / 3)))
	var path := "%s/%s.png" % [_folder, file]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
