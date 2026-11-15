extends Node

## LAS DOS CABINAS EN PRUEBA, EN UNA MECA DE ARCILLA, DE AFUERA Y DE ADENTRO (14/11/2026, el usuario: «solamente me
## mantendría con dos sistemas de prueba. El primero, cuadrado… y el segundo, que es el cilíndrico. Quisiera verlos a
## ambos en Meca, tanto de afuera como de adentro… al cilíndrico… un tramo del cilindro hecho cristal, pero al cuadrado
## lo haría como toda esa zona de cristal… y que en la parte de arriba, en la esquina superior delantera, tenga un
## chamfer»; antes: «el vidrio vaya hasta el techo… el lanzamisiles y el ametrallador… debería tener un poco más de
## jerarquía… con los asientos y todo adentro»).
## Las dos: 4 × 4 módulos (7,56 m por dentro), un piso de 5,04 m, el ascensor al medio. Adelante, la espalda al medio y
## un brazo a cada lado; atrás, en la tarima de 1,2 m, el movimiento; en el frente de la tarima, los cuatro kits y la
## batería; arriba, la munición. Una hoja por cabina: de frente, de atrás, desde la silla de arriba y desde arriba sin
## techo.
## LA ESCALA (el usuario, 14/11/2026: «me parece demasiado grande todo… el salto de 4 módulos… a 3x3 es mucho…
## variar el tamaño de la celda… bajar la altura»): la cuadrada se arma en varios tamaños de celda de la trama (12 × 12
## celdas) y de alto, con la gente, las sillas y los cubos de siempre. Tres hojas, una por vista, con todas las escalas.
##   tools/godot_ventana.sh res://tests/two_cabins_look.tscn -- --salida=C:/carpeta

var IN := 3.78
const WALL := 0.24
var TALL := 5.04
const FLOOR := 6.4
const UP := 1.2
## Las escalas que se comparan: [celda, alto].
const SCALES := [[0.63, 5.04], [0.58, 4.6], [0.53, 4.2], [0.5, 3.8]]
var C := 0.63
const METAL := Color(0.52, 0.54, 0.57)
const DARK := Color(0.22, 0.23, 0.25)
const TRIM := Color(0.38, 0.4, 0.43)
const GLASS := Color(0.55, 0.75, 0.85, 0.16)
const DECK := Color(0.6, 0.62, 0.65)
const STEP := Color(0.72, 0.74, 0.77)
const DESK := Color(0.3, 0.32, 0.35)
const SEAT := Color(0.25, 0.42, 0.7)
const PERSON := Color(0.93, 0.93, 0.93)
const KIT := Color(0.78, 0.27, 0.27)
const BATTERY := Color(0.93, 0.75, 0.16)
const AMMO := Color(0.47, 0.53, 0.32)
const LIFT := Color(0.3, 0.45, 0.75)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _roof: Array[Node3D] = []
## El vidrio, uno solo para todos los paños: más oscuro en las fotos de afuera, para que se lea su forma (el usuario:
## «hacerlo un poco más oscuro en las fotos de afuera… porque no se distingue tanto»), y claro adentro.
var _glass_paint := StandardMaterial3D.new()
const GLASS_OUTSIDE := Color(0.16, 0.24, 0.3, 0.72)
const GLASS_INSIDE := Color(0.55, 0.75, 0.85, 0.16)


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1000, 720)
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(16, 10)
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var ground := Node3D.new()
	add_child(ground)
	Clay.box(ground, Vector3(300, 1, 300), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.88)
	world.environment.ambient_light_energy = 0.95
	add_child(world)
	_eye = Camera3D.new()
	add_child(_eye)
	_eye.make_current()
	_glass_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass_paint.roughness = 0.2
	var outside: Array[Image] = []
	var inside: Array[Image] = []
	var above: Array[Image] = []
	for scale: Array in SCALES:
		C = scale[0]
		TALL = scale[1]
		IN = 6 * C
		var name_of := "celda de %d cm · %.2f m por dentro · %.2f m de alto" % [roundi(C * 100), IN * 2, TALL]
		var holder := Node3D.new()
		add_child(holder)
		_roof.clear()
		_body(holder, IN + WALL)
		_square(holder)
		_glass_paint.albedo_color = GLASS_OUTSIDE
		outside.append(await _view(name_of, Vector3(-16.0, 11.0, -20.0), Vector3(0, FLOOR + 1.0, 0), 45.0))
		_glass_paint.albedo_color = GLASS_INSIDE
		inside.append(await _view(name_of + " · desde la silla del movimiento", Vector3(0, FLOOR + UP + 1.25, IN - C),
			Vector3(0, FLOOR + 1.2, -IN), 80.0))
		for part in _roof:
			part.visible = false
		above.append(await _view(name_of + " · sin techo", Vector3(-3.0, FLOOR + 14.0, -6.5), Vector3(0, FLOOR, 0.3), 50.0))
		holder.queue_free()
		await get_tree().process_frame
	_save(outside, "escala_afuera")
	_save(inside, "escala_adentro")
	_save(above, "escala_arriba")
	get_tree().quit()


## ── LA MECA ──────────────────────────────────────────────────────────────────────────────────────────────────────

## Las piernas, la pelvis redonda con el ascensor y los brazos listos para pelear (los hombros, a los costados de la
## cabina, a media altura).
func _body(holder: Node3D, half: float) -> void:
	Clay.cylinder(holder, 1.9, 1.5, Vector3(0, FLOOR - 0.9, 0), TRIM)
	Clay.cylinder(holder, 1.7, 0.12, Vector3(0, FLOOR - 1.65, 0), LIFT)
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * 2.4, FLOOR - 1.3, 0.3)
		Clay.sphere(holder, 0.95, hip, DARK)
		var knee := hip + Vector3(side * 0.4, -2.5, -1.5)
		_limb(holder, hip, knee, 0.8)
		Clay.sphere(holder, 0.85, knee, DARK)
		var ankle := Vector3(side * 2.9, 0.7, 0.6)
		_limb(holder, knee, ankle, 0.72)
		Clay.box(holder, Vector3(1.7, 0.5, 2.8), Vector3(side * 2.9, 0.25, 0.2), DARK)
		var shoulder := Vector3(side * (half + 1.0), FLOOR + TALL * 0.63, 0.4)
		Clay.box(holder, Vector3(1.0, 1.6, 1.6), Vector3(side * (half + 0.45), FLOOR + TALL * 0.63, 0.4), TRIM)
		_shoulder_mount(holder, side, half)
		Clay.sphere(holder, 1.1, shoulder, METAL)
		var elbow := shoulder + Vector3(side * 0.6, -2.4, -0.4)
		_limb(holder, shoulder, elbow, 0.72)
		Clay.sphere(holder, 0.75, elbow, METAL)
		var wrist := elbow + Vector3(-side * 0.5, 0.6, -2.6)
		_limb(holder, elbow, wrist, 0.66)
		Clay.box(holder, Vector3(1.3, 1.3, 1.3), wrist + Vector3(0, 0, -0.5), DARK)


func _limb(holder: Node3D, from: Vector3, to: Vector3, radius: float) -> void:
	var limb := Clay.cylinder(holder, radius, from.distance_to(to), Vector3.ZERO, METAL)
	limb.transform = Transform3D(MechBody.segment(from, to, Vector3.UP).basis * Basis(Vector3.RIGHT, PI * 0.5),
		(from + to) * 0.5)


## LA ARTILLERÍA EN LOS HOMBROS (el usuario: «que tanto el lanzamisiles como la ametralladora… vayan en los hombros…
## una mini estructura arriba… que no giren junto con la bola del hombro, sino que estén estáticos»): sobre el bloque
## de cada hombro, un soporte fijo (dos patas y una base) que pasa por encima de la bola; encima, el lanzamisiles a la
## izquierda y la ametralladora a la derecha.
func _shoulder_mount(holder: Node3D, side: float, half: float) -> void:
	var x := side * (half + 0.75)
	var top := FLOOR + TALL * 0.63 + 1.55
	for z: float in [-0.35, 1.15]:
		Clay.box(holder, Vector3(0.3, 1.0, 0.3), Vector3(side * (half + 0.3), FLOOR + TALL * 0.63 + 1.0, z), TRIM)
	Clay.box(holder, Vector3(1.9, 0.3, 2.0), Vector3(x, top, 0.4), TRIM)
	Clay.cylinder(holder, 0.75, 0.25, Vector3(x, top + 0.27, 0.4), DARK)
	if side < 0.0:
		var pod := Vector3(x, top + 1.25, 0.3)
		Clay.box(holder, Vector3(2.0, 1.7, 2.4), pod, METAL)
		for row in 2:
			for column in 2:
				var mouth := Clay.cylinder(holder, 0.27, 0.1, pod + Vector3(-0.45 + column * 0.9, -0.4 + row * 0.8, -1.22), DARK)
				mouth.rotation_degrees.x = 90.0
	else:
		var gun := Vector3(x, top + 0.95, 0.4)
		Clay.box(holder, Vector3(1.5, 1.1, 1.9), gun, METAL)
		for offset: float in [-0.3, 0.3]:
			var barrel := Clay.cylinder(holder, 0.14, 2.8, gun + Vector3(offset, 0.1, -2.3), DARK)
			barrel.rotation_degrees.x = 90.0


## LA ARTILLERÍA, CON JERARQUÍA: un lomo macizo atrás del techo, que es parte del cuerpo, y encima, sobre dos bases
## que giran, el lanzamisiles (izquierda) y la ametralladora (derecha), grandes.
func _artillery(holder: Node3D, width: float) -> void:
	var top := FLOOR + TALL
	var back := 1.9
	_roof_part(Clay.box(holder, Vector3(width, 1.0, 2.6), Vector3(0, top + 0.5, back), TRIM))
	for side: float in [-1.0, 1.0]:
		_roof_part(Clay.cylinder(holder, 1.1, 0.35, Vector3(side * 1.9, top + 1.18, back), DARK))
	var pod := Vector3(-1.9, top + 2.35, back - 0.2)
	_roof_part(Clay.box(holder, Vector3(2.6, 2.0, 2.8), pod, METAL))
	for row in 2:
		for column in 3:
			var mouth := Clay.cylinder(holder, 0.26, 0.1, pod + Vector3(-0.8 + column * 0.8, -0.45 + row * 0.9, -1.42), DARK)
			mouth.rotation_degrees.x = 90.0
			_roof_part(mouth)
	var gun := Vector3(1.9, top + 2.0, back)
	_roof_part(Clay.box(holder, Vector3(1.9, 1.3, 2.2), gun, METAL))
	for side: float in [-0.4, 0.4]:
		var barrel := Clay.cylinder(holder, 0.16, 3.2, gun + Vector3(side, 0.1, -2.6), DARK)
		barrel.rotation_degrees.x = 90.0
		_roof_part(barrel)


func _roof_part(node: Node3D) -> void:
	_roof.append(node)


## ── LA CUADRADA ──────────────────────────────────────────────────────────────────────────────────────────────────

## 12 × 12 celdas de 63 cm. TODA LA ZONA DE ADELANTE ES VIDRIO: el frente y los costados hasta la mitad, de piso a
## techo (el piso no), y la esquina de arriba adelante cortada en diagonal, también de vidrio.
func _square(holder: Node3D) -> void:
	var outer := IN + WALL
	var chamfer := 2 * C
	var base := FLOOR
	# El piso, con el lugar del ascensor.
	Clay.box(holder, Vector3(outer * 2, 0.3, outer * 2), Vector3(0, base - 0.15, 0), METAL)
	Clay.cylinder(holder, 2 * C, 0.03, Vector3(0, base + 0.02, 0), LIFT)
	# Lo de metal: la pared de atrás y la mitad de atrás de los costados; el techo, de donde termina el corte hasta atrás.
	var front := -IN - 0.12
	var side_x := IN + 0.12
	Clay.box(holder, Vector3(outer * 2, TALL, WALL), Vector3(0, base + TALL * 0.5, IN + WALL * 0.5), METAL)
	for side: float in [-1.0, 1.0]:
		Clay.box(holder, Vector3(WALL, TALL, IN + WALL), Vector3(side * (IN + WALL * 0.5), base + TALL * 0.5, (IN + WALL) * 0.5), METAL)
	var roof_from := front + chamfer
	_roof_part(Clay.box(holder, Vector3(outer * 2, 0.3, IN + WALL - roof_from), Vector3(0, base + TALL - 0.15,
		(roof_from + IN + WALL) * 0.5), METAL))
	# EL VIDRIO, EN PAÑOS EXACTOS Y SIN MARCOS: el frente hasta el corte, el corte a 45° de arista a arista, y cada
	# costado de adelante con su esquina cortada igual. Todos se tocan justo en las aristas.
	var y0 := base
	var y1 := base + TALL
	var yc := base + TALL - chamfer
	_pane(holder, [Vector3(-side_x, y0, front), Vector3(side_x, y0, front), Vector3(side_x, yc, front), Vector3(-side_x, yc, front)])
	_roof_part(_pane(holder, [Vector3(-side_x, yc, front), Vector3(side_x, yc, front), Vector3(side_x, y1, front + chamfer),
		Vector3(-side_x, y1, front + chamfer)]))
	for side: float in [-1.0, 1.0]:
		var x := side * side_x
		_pane(holder, [Vector3(x, y0, front), Vector3(x, y0, 0.0), Vector3(x, y1, 0.0), Vector3(x, y1, front + chamfer),
			Vector3(x, yc, front)])
	# Adentro: el tablero corrido de adelante, de tres puestos (una celda de fondo).
	Clay.box(holder, Vector3(IN * 2, 0.8, C), Vector3(0, base + 0.4, -IN + C * 0.5), DESK)
	for x: float in [-2 * C, 2 * C]:
		Clay.box(holder, Vector3(0.04, 0.82, C), Vector3(x, base + 0.41, -IN + C * 0.5), Color(0.6, 0.6, 0.65))
	for x: float in [-4 * C, 0.0, 4 * C]:
		_seat(holder, Vector3(x, base, -IN + 1.5 * C + 0.2), "brazo izquierdo" if x < 0 else ("espalda" if x == 0 else "brazo derecho"))
	# Atrás: la tarima de dos celdas de fondo, de pared a pared, a 1,2 m; las dos escaleras contra los costados.
	Clay.box(holder, Vector3(IN * 2, UP, 2 * C), Vector3(0, base + UP * 0.5, IN - C), DECK)
	for side: float in [-1.0, 1.0]:
		_straight_stairs(holder, Vector3(side * (IN - C), base, 0.0), Vector3(side * (IN - C), base + UP, 4 * C), 2 * C)
	# En el frente de la tarima, de cara al ascensor: los kits y la batería (de izquierda a derecha de la meca).
	# Parejos entre las dos escaleras (que ocupan las dos celdas de cada punta), con medio paso libre al lado de cada una.
	var free := (IN - 2 * C) * 2
	for index in 5:
		var x := -free * 0.5 + free * (index + 0.5) / 5.0
		var color: Color = BATTERY if index == 2 else KIT
		Clay.box(holder, Vector3(0.6, 0.6, 0.08), Vector3(x, base + 0.32, IN - 2 * C - 0.03), color)
	_seat(holder, Vector3(0, base + UP, IN - C), "movimiento")
	# Arriba, la munición, metida en la pared de atrás: sólo sobresale el cubo.
	for x: float in [-2.5 * C, 2.5 * C]:
		Clay.box(holder, Vector3(C + 0.15, C + 0.15, C), Vector3(x, base + UP + C * 0.5 + 0.1, IN + WALL + C * 0.5 - 0.1), METAL)
		Clay.box(holder, Vector3(C * 0.9, C * 0.9, 0.08), Vector3(x, base + UP + C * 0.5 + 0.1, IN + 0.02), AMMO)



func _straight_stairs(holder: Node3D, from: Vector3, to: Vector3, width: float) -> void:
	var steps := 8
	for i in steps:
		var z := from.z + (to.z - from.z) * (i + 0.5) / steps
		var top := from.y + (to.y - from.y) * (i + 1) / steps
		var depth := absf(to.z - from.z) / steps
		Clay.box(holder, Vector3(width, top - from.y, depth), Vector3(from.x, from.y + (top - from.y) * 0.5, z), STEP)


## ── LA REDONDA ───────────────────────────────────────────────────────────────────────────────────────────────────

## Por fuera, un cilindro; por dentro, las 16 zonas. El vidrio: un tramo del cilindro, de piso a techo, de punta a punta
## de las escaleras (202,5°).
func _round(holder: Node3D) -> void:
	var base := FLOOR
	Clay.cylinder(holder, IN + WALL, 0.3, Vector3(0, base - 0.15, 0), METAL)
	Clay.cylinder(holder, 1.3, 0.03, Vector3(0, base + 0.02, 0), LIFT)
	Clay.cylinder(holder, 1.24, 2.0, Vector3(0, base + 1.0, 0), Color(LIFT, 0.12))
	_wall_arc(holder, 101.25, 258.75, METAL)
	_glass_arc(holder, IN + 0.12, -101.25, 101.25, FLOOR, FLOOR + TALL)
	_roof_part(Clay.cylinder(holder, IN + WALL + 0.05, 0.3, Vector3(0, base + TALL + 0.15, 0), METAL))
	Clay.cylinder(holder, IN + WALL + 0.1, 0.3, Vector3(0, base + 0.15, 0), TRIM)
	# Adentro: el tablero corrido de tres zonas, adelante.
	for zone in 3:
		var a := -22.5 + 22.5 * zone
		_zone_box(holder, a, 3.1, IN, base, 0.8, DESK)
	for zone in 3:
		var a := -22.5 + 22.5 * zone
		_seat_at(holder, a, 2.85, base, ["brazo izquierdo", "espalda", "brazo derecho"][zone])
	# Las escaleras: dos zonas de la banda cada una, ocho escalones que siguen las caras.
	for side: float in [-1.0, 1.0]:
		for i in 8:
			var a := side * (56.25 + 45.0 * (i + 0.5) / 8.0)
			_zone_box(holder, a, 2.6, IN, base, UP * (i + 1) / 8.0, STEP, 45.0 / 8.0)
	# La media luna: siete zonas a 1,2 m; en el frente de las cinco del medio, los kits y la batería.
	for zone in 7:
		_zone_box(holder, 112.5 + 22.5 * zone, 2.6, IN, base, UP, DECK)
	for item: Array in [[135.0, KIT], [157.5, KIT], [180.0, BATTERY], [202.5, KIT], [225.0, KIT]]:
		var a := deg_to_rad(float(item[0]))
		var r := 2.6 * cos(deg_to_rad(11.25)) - 0.04
		var cube := Clay.box(holder, Vector3(C * 0.9, C * 0.9, 0.08), Vector3(sin(a) * r, base + C * 0.5, -cos(a) * r), item[1])
		cube.rotation.y = -a
	_seat(holder, Vector3(0, base + UP, 3.2), "movimiento")
	# Arriba, la munición metida en la pared: sólo sobresale el cubo.
	for deg: float in [135.0, 225.0]:
		var a := deg_to_rad(deg)
		var r := IN + WALL + C * 0.5 - 0.1
		var pocket := Clay.box(holder, Vector3(C + 0.15, C + 0.15, C), Vector3(sin(a) * r, base + UP + C * 0.5 + 0.1, -cos(a) * r), METAL)
		pocket.rotation.y = -a
	_artillery(holder, 6.0)


## Un tramo de pared redonda, de `a0` a `a1` grados (0, el frente), de piso a techo.
func _wall_arc(holder: Node3D, a0: float, a1: float, color: Color, thick := WALL) -> void:
	var pieces := int(absf(a1 - a0) / 5.0)
	for i in pieces:
		var a := deg_to_rad(a0 + (a1 - a0) * (i + 0.5) / pieces)
		var r := IN + thick * 0.5 + (0.1 if thick < WALL else 0.0)
		var width := deg_to_rad(absf(a1 - a0) / pieces) * r + 0.03
		var piece := Clay.box(holder, Vector3(width, TALL, thick), Vector3(sin(a) * r, FLOOR + TALL * 0.5, -cos(a) * r), color)
		piece.rotation.y = -a


## Un paño de vidrio plano, con sus esquinas en orden (un abanico desde la primera).
func _pane(holder: Node3D, corners: Array) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a: Vector3 = corners[0]
	var normal := ((corners[1] as Vector3) - a).cross((corners[2] as Vector3) - a).normalized()
	for i in range(1, corners.size() - 1):
		for v: Vector3 in [a, corners[i], corners[i + 1]]:
			tool.set_normal(normal)
			tool.add_vertex(v)
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	mesh.material_override = _glass_paint
	holder.add_child(mesh)
	return mesh


## Un tramo de vidrio liso, curvo (una sola pieza, sin juntas), de `a0` a `a1` grados.
func _glass_arc(holder: Node3D, radius: float, a0: float, a1: float, y0: float, y1: float) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 48
	for i in steps:
		var b0 := deg_to_rad(a0 + (a1 - a0) * i / steps)
		var b1 := deg_to_rad(a0 + (a1 - a0) * (i + 1) / steps)
		var p0 := Vector3(sin(b0) * radius, 0, -cos(b0) * radius)
		var p1 := Vector3(sin(b1) * radius, 0, -cos(b1) * radius)
		for v: Vector3 in [p0 + Vector3.UP * y0, p1 + Vector3.UP * y0, p1 + Vector3.UP * y1, p0 + Vector3.UP * y0,
				p1 + Vector3.UP * y1, p0 + Vector3.UP * y1]:
			tool.set_normal(Vector3(v.x, 0, v.z).normalized())
			tool.add_vertex(v)
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := StandardMaterial3D.new()
	paint.albedo_color = GLASS
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	holder.add_child(mesh)


## Una zona de la trama (de `span` grados, centrada en `a`) entre los anillos `r0` y `r1`, de `tall` de alto.
func _zone_box(holder: Node3D, a_deg: float, r0: float, r1: float, base: float, tall: float, color: Color, span := 22.5) -> void:
	var a := deg_to_rad(a_deg)
	var mid := (r0 + r1) * 0.5
	var width := 2.0 * mid * tan(deg_to_rad(span) * 0.5) + 0.02
	var piece := Clay.box(holder, Vector3(width, tall, r1 - r0), Vector3(sin(a) * mid, base + tall * 0.5, -cos(a) * mid), color)
	piece.rotation.y = -a


func _seat_at(holder: Node3D, a_deg: float, r: float, base: float, role: String) -> void:
	var a := deg_to_rad(a_deg)
	var pivot := Node3D.new()
	pivot.position = Vector3(sin(a) * r, base, -cos(a) * r)
	pivot.rotation.y = -a
	holder.add_child(pivot)
	_seat(pivot, Vector3.ZERO, role)


## UNA SILLA mirando al frente (−z), con alguien sentado.
func _seat(holder: Node3D, at: Vector3, role: String) -> void:
	var color: Color = {"brazo izquierdo": Color(0.85, 0.35, 0.3), "brazo derecho": Color(0.3, 0.6, 0.9),
		"espalda": Color(0.75, 0.5, 0.85), "movimiento": Color(0.4, 0.8, 0.4)}[role]
	Clay.box(holder, Vector3(0.6, 0.45, 0.6), at + Vector3(0, 0.225, 0), SEAT)
	Clay.box(holder, Vector3(0.6, 0.8, 0.12), at + Vector3(0, 0.85, 0.27), color)
	Clay.box(holder, Vector3(0.42, 0.65, 0.3), at + Vector3(0, 0.78, 0.05), PERSON)
	Clay.cylinder(holder, 0.13, 0.26, at + Vector3(0, 1.25, 0.03), PERSON)
	if role == "movimiento":
		for side: float in [-1.0, 1.0]:
			Clay.box(holder, Vector3(0.2, 0.62, 0.65), at + Vector3(side * 0.42, 0.31, -0.08), DESK)


func _view(title: String, from: Vector3, to: Vector3, fov: float) -> Image:
	_title.text = title
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array[Image], file: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var w := shots[0].get_width()
	var h := shots[0].get_height()
	var sheet := Image.create(w * 2, h * 2, false, shots[0].get_format())
	for index in shots.size():
		sheet.blit_rect(shots[index], Rect2i(Vector2i.ZERO, shots[index].get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/%s.png" % [_folder, file]
	sheet.save_png(path)
	print("CAPTURA ", path)
