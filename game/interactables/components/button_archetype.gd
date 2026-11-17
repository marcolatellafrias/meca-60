class_name ButtonArchetype
extends ComponentArchetype

## EL BOTÓN SIN LEYENDA (Era 3, iteración 4, ver docs/planes-maestros/plan-maestro-de-nave/componentes.md): el botón de
## apretar sin nada escrito, con sus parámetros. Los botones con leyenda son la tecla (ver KeyArchetype).
##
##   · LA FORMA (`form`): redondo, cuadrado, rectangular u ovalado. El redondo y el cuadrado siguen siéndolo en cualquier
##     caja; el rectangular y el ovalado se estiran con ella.
##   · EL TAMAÑO: las celdas que ocupa (`button_cells`), libres, y cuánto de su caja ocupa la cabeza (`head_size`).
##   · LA CABEZA (`head`): plana, abombada, cóncava —con el borde levantado alrededor— o de hongo —un tallo angosto y un
##     sombrero que sobresale—, de `head_from` a `head_to` en el alto de la caja.
##   · Con o sin ARO de metal alrededor (`bezel`), su COLOR, y lo mismo que la tecla: que se TRABE (`latching`), con LUZ
##     ADENTRO (`lit`: se prende mientras está hundido) y con TAPA de seguridad (`covered`).
##   · TEXTO EN LA CABEZA, opcional (`text`; paso 7 del framework, lo pidió el usuario el 12/10/2026): se ajusta
##     al tamaño de la cabeza —un redondo grande puede decir NO PRESIONAR— y la tinta sale sola, oscura sobre un color
##     claro y clara sobre uno oscuro.
##
## Es PARAMÉTRICO por ahora: si pasa a tener modelos hechos a mano se decide después de ver cómo lo usan los
## científicos. Los botones de los tableros —los estilos «button» y «power» de ControlArchetype— son este botón con sus
## parámetros de siempre (`for_control`), y salen igual que antes. El de peligro queda aparte (DangerButtonArchetype).

enum Form { ROUND, SQUARE, RECT, OVAL }
enum Head { FLAT, DOMED, CUPPED, MUSHROOM }

const FORM_NAMES: Array[String] = ["redondo", "cuadrado", "rectangular", "ovalado"]
const HEAD_NAMES: Array[String] = ["plana", "abombada", "cóncava", "de hongo"]
## EL ZÓCALO, del alto de un cuarto de la caja, y EL ARO, que sube de ahí hasta acá y es más grande que la cabeza.
const PLINTH := 0.25
const BEZEL_TO := 0.4
const BEZEL_GROW := 0.3
## Cuántos lados tiene lo redondo, y cuánto se redondean las esquinas de lo cuadrado (fracción del medio lado) y en
## cuántos puntos cada una: los mismos que lo redondo.
const SEGMENTS := 16
const CORNER := 0.3
const CORNER_STEPS := 4
## El sombrero del hongo: cuánto más ancho que la cabeza, y qué tan angosto es el tallo.
const MUSHROOM_CAP := 1.25
const MUSHROOM_STEM := 0.55

var form := Form.ROUND
var head := Head.FLAT
var head_size := 0.7
var head_from := 0.2
var head_to := 0.65
var bezel := false
var color := Color(0.85, 0.35, 0.25)
var button_cells := ProceduralDashboard.BUTTON
var latching := false
var lit := false
var covered := false
var text := ""


func _init() -> void:
	display_name = "Botón"


## Lo que ocupa de su caja la cabeza del botón de las compuertas: la del de encendido (0,5 de 4 celdas) en 3 celdas.
const DOOR_HEAD := 0.66


## EL BOTÓN DE LOS TABLEROS, el del estilo `style` de ControlArchetype con su color: el de siempre, y el de encendido
## —más chico, más alto y con aro—.
static func for_control(style: String, p_color: Color) -> ButtonArchetype:
	var b := ButtonArchetype.new()
	b.color = p_color
	if style == "power" or style == ControlArchetype.DOOR:
		b.head_size = 0.5
		b.head_from = 0.3
		b.head_to = 0.8
		b.bezel = true
	# El de las compuertas, más chico en celdas: la cabeza ocupa más de su caja (ver ControlArchetype.DOOR).
	if style == ControlArchetype.DOOR:
		b.head_size = DOOR_HEAD
	return b


## EL BOTÓN DE ENCENDIDO de los tableros y los artefactos: el de siempre, verde, de su tamaño, que se traba.
static func power() -> ButtonArchetype:
	var b := for_control("power", Color(0.3, 0.8, 0.4))
	b.button_cells = ProceduralDashboard.POWER_BUTTON
	b.latching = true
	return b


## LOS BOTONES DEL SANDBOX, una variante cada uno (van juntos en una parcela, ver ComponentArchetype.in_parcels): los
## dos de los tableros y algunos de lo que se puede variar.
static func primitives() -> Array:
	var out: Array = []
	var plain := for_control("button", Color(0.85, 0.35, 0.25))
	out.append_array([plain, power()])
	for spec: Array in [
			[Form.SQUARE, Head.DOMED, true, Color(0.2, 0.32, 0.6), Vector2i(3, 3), false, false],
			[Form.RECT, Head.FLAT, false, Color(0.95, 0.66, 0.2), Vector2i(5, 2), false, true],
			[Form.OVAL, Head.CUPPED, true, Color(0.12, 0.12, 0.13), Vector2i(4, 3), true, false],
			[Form.ROUND, Head.MUSHROOM, false, Color(0.9, 0.08, 0.05), Vector2i(4, 4), false, false]]:
		var b := ButtonArchetype.new()
		b.form = spec[0]
		b.head = spec[1]
		b.bezel = spec[2]
		b.color = spec[3]
		b.button_cells = spec[4]
		b.latching = spec[5]
		b.lit = spec[6]
		if b.head == Head.MUSHROOM:
			b.head_size = 0.62
		out.append(b)
	# CON TEXTO EN LA CABEZA: el redondo grande que dice no presionar, el rectangular con luz que arranca y el cuadrado
	# con una letra.
	for spec: Array in [[Form.ROUND, Head.FLAT, true, Color(0.82, 0.12, 0.08), Vector2i(5, 5), false, "NO PRESIONAR"],
			[Form.RECT, Head.FLAT, false, Color(0.95, 0.66, 0.2), Vector2i(5, 2), true, "ARRANQUE"],
			[Form.SQUARE, Head.DOMED, true, Color(0.85, 0.82, 0.74), Vector2i(3, 3), false, "A"]]:
		var b := ButtonArchetype.new()
		b.form = spec[0]
		b.head = spec[1]
		b.bezel = spec[2]
		b.color = spec[3]
		b.button_cells = spec[4]
		b.lit = spec[5]
		b.text = spec[6]
		b.head_size = 0.8
		out.append(b)
	return out


func cells(_seed_value: int) -> Vector2i:
	return button_cells


func describe(_seed_value: int) -> PackedStringArray:
	var traits := PackedStringArray(["se traba" if latching else "momentáneo"])
	if lit:
		traits.append("con luz")
	if covered:
		traits.append("con tapa: se levanta con E")
	return PackedStringArray(["%d × %d celdas · %s" % [button_cells.x, button_cells.y, variant_name()],
		" · ".join(traits)])


func variant_name() -> String:
	return "%s, cabeza %s%s%s" % [FORM_NAMES[form], HEAD_NAMES[head], ", con aro" if bezel else "",
		(", «%s»" % text) if not text.is_empty() else ""]


## La TouchComponent de uno montado (la raíz que devuelve `mount`).
static func button_of(root: Node) -> TouchComponent:
	return root.get_node_or_null("Button/Control") as TouchComponent


func _build_on(seed_value: int, root: Node3D, area: Vector2) -> void:
	var size := Vector3(area.x - 2.0 * ProceduralDashboard.CONTROL_MARGIN, area.y - 2.0 * ProceduralDashboard.CONTROL_MARGIN,
		ProceduralDashboard.CONTROL_DEPTH)
	var body := StaticBody3D.new()
	body.name = "Button"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	collision.position = Vector3(0.0, 0.0, size.z * 0.5)
	body.add_child(collision)
	root.add_child(body)
	body.add_child(instance(base_unit(size), size))
	# Con luz o con tapa, el andar de una tecla (ver KeyComponent); si no, el de un botón de tablero.
	var touch: TouchComponent
	if covered:
		touch = GuardedButton.new()
	elif lit:
		touch = KeyComponent.new()
	else:
		touch = TouchComponent.new()
	touch.name = "Control"
	touch.grid_size = cells(seed_value)
	touch.is_toggle = latching
	body.add_child(touch)
	touch.build(size)
	var cap := instance(moving_unit(size), size)
	touch.add_child(cap)
	touch.highlighted.append(cap)
	if lit:
		var key := touch as KeyComponent
		key.light_material = cap.material_override as StandardMaterial3D
		key.light_color = color
	if not text.is_empty():
		touch.add_child(_head_text(size))
	if covered:
		add_cover(root, touch as GuardedButton, size)


## EL TEXTO DE LA CABEZA: centrado arriba de ella, de las letras más grandes que entren a lo ancho de su cara, con la
## tinta que se lee sobre su color.
func _head_text(size: Vector3) -> StrokeLabel:
	var half := _half(size, head_size)
	var wide := half.x * 2.0 * size.x * (0.72 if form == Form.ROUND or form == Form.OVAL else 0.85)
	var tall := half.y * 2.0 * size.y
	var top := head_to
	match head:
		Head.CUPPED:
			top = head_to - (head_to - head_from) * 0.22
		Head.MUSHROOM:
			wide *= MUSHROOM_CAP
	var letter := minf(tall * 0.32, wide / maxf(StrokeFont.measure(text, 1.0).x, 0.001))
	var ink := Color(0.1, 0.09, 0.08) if color.get_luminance() > 0.45 else Color(0.95, 0.92, 0.84)
	var label := StrokeLabel.make(text, letter, ink)
	label.name = "HeadText"
	label.position.z = top * size.z + 0.0008
	return label


# ── Las mallas, en el cubo de la caja ────────────────────────────────────────────────────────────

## LA BASE, lo que no se mueve: el zócalo y, si tiene, el aro de metal alrededor de la cabeza.
func base_unit(size: Vector3) -> UnitMesh:
	var m := UnitMesh.new()
	m.add_box(Vector3(0.0, 0.0, 0.0), Vector3(1.0, 1.0, PLINTH), ControlArchetype.BASE_COLOR)
	if bezel:
		_prism(m, _half(size, minf(head_size + BEZEL_GROW, 0.96)), PLINTH, BEZEL_TO, ControlArchetype.BASE_COLOR.lightened(0.2))
	return m


## LA CABEZA, lo que se hunde.
func moving_unit(size: Vector3) -> UnitMesh:
	var m := UnitMesh.new()
	var half := _half(size, head_size)
	var rise := head_to - head_from
	match head:
		Head.FLAT:
			_prism(m, half, head_from, head_to, color)
		Head.DOMED:
			var shoulder := head_from + rise * 0.45
			_stack(m, half, [Vector2(1.0, head_from), Vector2(1.0, shoulder), Vector2(0.93, shoulder + (head_to - shoulder) * 0.45),
				Vector2(0.72, shoulder + (head_to - shoulder) * 0.82)], head_to, color)
		Head.CUPPED:
			_stack(m, half, [Vector2(1.0, head_from), Vector2(1.0, head_to), Vector2(0.84, head_to)], head_to - rise * 0.22,
				color)
		Head.MUSHROOM:
			var neck := head_from + rise * 0.4
			var brim := neck + (head_to - neck) * 0.35
			_stack(m, half, [Vector2(MUSHROOM_STEM, head_from), Vector2(MUSHROOM_STEM, neck), Vector2(MUSHROOM_CAP, neck),
				Vector2(MUSHROOM_CAP, brim), Vector2(MUSHROOM_CAP * 0.82, brim + (head_to - brim) * 0.7)], head_to, color)
	return m


## MEDIA CABEZA en el cubo, de una que ocupa `share` de la caja `size`: el redondo y el cuadrado, del lado corto en los
## dos ejes, así siguen siéndolo en una caja que no es cuadrada; el rectangular y el ovalado, de cada lado.
func _half(size: Vector3, share: float) -> Vector2:
	if form == Form.RECT or form == Form.OVAL:
		return Vector2(share, share) * 0.5
	var side := share * minf(size.x, size.y)
	return Vector2(side / size.x, side / size.y) * 0.5


## Una pieza recta de la forma del botón, de media medida `half`, de `z0` a `z1`: un cilindro o una caja, como siempre.
func _prism(m: UnitMesh, half: Vector2, z0: float, z1: float, c: Color) -> void:
	var lo := Vector3(0.5 - half.x, 0.5 - half.y, z0)
	var hi := Vector3(0.5 + half.x, 0.5 + half.y, z1)
	if form == Form.ROUND or form == Form.OVAL:
		m.add_cylinder_z(lo, hi, c, SEGMENTS)
	else:
		m.add_box(lo, hi, c)


## UNA PILA DE ANILLOS con el contorno del botón: cada uno, (escala del contorno, alto en el cubo), unidos por sus
## costados; arriba, una tapa en abanico hasta `apex` en el medio —más bajo que el último anillo, cóncava; más alto,
## abombada—. Un anillo a la misma altura que el anterior es una cara plana: hacia abajo si crece (debajo del sombrero
## del hongo), hacia arriba si achica (el borde de la cóncava).
func _stack(m: UnitMesh, half: Vector2, rings: Array, apex: float, c: Color) -> void:
	var outline := _outline()
	var previous: Array[Vector3] = []
	var previous_ring := Vector2.ZERO
	for ring: Vector2 in rings:
		var points: Array[Vector3] = []
		for p in outline:
			points.append(Vector3(0.5 + p.x * half.x * ring.x, 0.5 + p.y * half.y * ring.x, ring.y))
		if not previous.is_empty():
			var flat := is_equal_approx(ring.y, previous_ring.y)
			var facing := Vector3(0.0, 0.0, -1.0 if ring.x > previous_ring.x else 1.0)
			var inside := Vector3(0.5, 0.5, (ring.y + previous_ring.y) * 0.5)
			for i in points.size():
				var j := (i + 1) % points.size()
				if flat:
					m.add_quad_facing(previous[i], previous[j], points[j], points[i], facing, c)
				else:
					m.add_quad(previous[i], previous[j], points[j], points[i], inside, c)
		previous = points
		previous_ring = ring
	var top := Vector3(0.5, 0.5, apex)
	for i in previous.size():
		m.add_tri_facing(previous[i], previous[(i + 1) % previous.size()], top, Vector3(0.0, 0.0, 1.0), c)


## EL CONTORNO, en [−1, 1]: un círculo en lo redondo y lo ovalado; en lo cuadrado y lo rectangular, un cuadrado de
## esquinas redondeadas, con los mismos puntos.
func _outline() -> Array[Vector2]:
	var out: Array[Vector2] = []
	if form == Form.ROUND or form == Form.OVAL:
		for i in SEGMENTS:
			out.append(Vector2.from_angle(TAU * float(i) / float(SEGMENTS)))
		return out
	for corner in 4:
		var centre := Vector2(1.0 - CORNER, 1.0 - CORNER).rotated(PI * 0.5 * float(corner))
		for s in CORNER_STEPS:
			var a := PI * 0.5 * (float(corner) + float(s) / float(CORNER_STEPS - 1))
			out.append(centre + Vector2.from_angle(a) * CORNER)
	return out


## ── LA TAPA DE SEGURIDAD (de KeyArchetype.add_cover, de character-parametric) ──────────────────────────
const COVER_PAD := 0.006
const COVER_RISE := 1.7


static func add_cover(root: Node3D, button: GuardedButton, size: Vector3) -> void:
	var hinge := Node3D.new()
	hinge.name = "Hinge"
	hinge.position = Vector3(0.0, size.y * 0.5 + COVER_PAD, 0.0)
	root.add_child(hinge)
	var cover_size := Vector3(size.x + 2.0 * COVER_PAD, size.y + 2.0 * COVER_PAD, size.z * COVER_RISE)
	var cover_at := Vector3(0.0, -cover_size.y * 0.5, cover_size.z * 0.5)
	var cover_body := StaticBody3D.new()
	cover_body.name = "Cover"
	var cover_shape := CollisionShape3D.new()
	var cover_box := BoxShape3D.new()
	cover_box.size = cover_size
	cover_shape.shape = cover_box
	cover_shape.position = cover_at
	cover_body.add_child(cover_shape)
	hinge.add_child(cover_body)
	var cover := SafetyCover.new()
	cover.name = "Control"
	cover.hinge = hinge
	cover_body.add_child(cover)
	button.cover = cover
	var plastic := StandardMaterial3D.new()
	plastic.albedo_color = Color(0.75, 0.88, 1.0, 0.22)
	plastic.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plastic.cull_mode = BaseMaterial3D.CULL_DISABLED
	plastic.roughness = 0.05
	var shell := MeshInstance3D.new()
	var shell_box := BoxMesh.new()
	shell_box.size = cover_size
	shell.mesh = shell_box
	shell.material_override = plastic
	shell.position = cover_at
	cover.add_child(shell)
