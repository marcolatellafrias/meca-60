extends Node3D

## LA CABINA REDONDA, MAQUETA DE ARCILLA, POR FUERA Y POR DENTRO (15/11/2026, el usuario: «si queremos ir con este
## approach más cilíndrico, no podemos tener tableros en el piso y todos los elementos van a pasar a ser cosas de las
## sillas… dos círculos concéntricos… un anillo parcial… la tarima sea un escalón todo alrededor… el exterior es un
## cilindro suave… bajar el techo… una base extra de la misma forma cilíndrica… abajo de la zona habitable… y abajo de
## este disco extra vaya recién las piernas»).
##   · LA CAJA: adentro, de 12 lados (la misma superficie que la cuadrada de hoy); afuera, un cilindro liso. El frente
##     (cinco lados, 150°), de vidrio de piso a techo. Techo bajo.
##   · DEBAJO, UN DISCO del mismo radio, chato, por donde baja el ascensor; y recién debajo, las piernas y los brazos de
##     la meca de verdad (una meca sin cabina, con la caja escondida y esta piel encima).
##   · LAS SILLAS, solas (el usuario: «sacale los tableros y los hologramas a las sillas»): nada en el piso ni contra
##     las paredes; el anillo de la caja queda libre.
##   · LA TARIMA, chica, centrada, baja, con un escalón todo alrededor; arriba, el movimiento y, atrás, el ascensor.
##   · Atrás, en las paredes, los kits, las dos municiones y la batería.
##   tools/godot_ventana.sh res://tests/round_cabin_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const SIDES := 12
## El radio de adentro, a los vértices (la misma superficie que 6,14 × 6,14 m), y el de afuera, liso.
const R := 3.55
const OUTER := 3.75
const CLEAR := 2.3
const SLAB := 0.22
const BASE_TALL := 1.0
const PLATFORM_R := 1.35
const PLATFORM_TALL := 0.3
const STEP_R := 1.65
const LIFT_R := 0.5
const LIFT_AT := 0.7

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
var _eye: Camera3D = null
var _title: Label = null
var _mech := Node3D.new()
var _real: Mech = null
var _glass_paint := StandardMaterial3D.new()
var _roof: Array[Node3D] = []
var _left: Array[Node3D] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	# LA MECA DE VERDAD, sin cabina: sus piernas y sus brazos. Su caja, del tamaño de esta (14 celdas por lado, 3,8 m de
	# radio; el alto de la cabina, las losas y el disco), para que los hombros y la pelvis caigan donde van.
	var form := CabinGrid.current()
	form.across = 14
	form.height_cells = roundi((BASE_TALL + CLEAR + SLAB * 2.0 - CabinGrid.SLAB * 2.0) / CabinGrid.CELL)
	CabinGrid.shape(form)
	_real = Mech.new()
	_real.has_cabin = false
	_real.arms_kind = Mech.Arms.POSE
	_real.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_real)
	await get_tree().create_timer(2.5).timeout
	_real.freeze = true
	if _real.label != null:
		_real.label.visible = false
	# Su caja lisa y la franja del frente, escondidas: la piel es la de acá.
	for part in _real.look.get_children():
		if part is MeshInstance3D and (part as MeshInstance3D).mesh is BoxMesh:
			(part as MeshInstance3D).visible = false
	_real.look.add_child(_mech)
	_mech.position.y = -CabinGrid.HALF_HEIGHT + BASE_TALL + SLAB
	_glass_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass_paint.roughness = 0.15
	_build()
	var shots: Array = []
	_glass_paint.albedo_color = GLASS_OUTSIDE
	_title.text = "1. Afuera, de frente"
	_look(Vector3(-15.0, 0.0, -24.0), Vector3(0.0, -4.0, 0.0), 45.0)
	shots.append(await _grab())
	_title.text = "2. Afuera, de costado"
	_look(Vector3(-28.0, -2.0, -5.0), Vector3(0.0, -4.0, 0.0), 42.0)
	shots.append(await _grab())
	_glass_paint.albedo_color = GLASS_INSIDE
	_title.text = "3. Adentro, desde atrás del movimiento"
	_look(Vector3(0.6, 1.9, 2.9), Vector3(-0.2, 0.9, -3.0), 85.0)
	shots.append(await _grab())
	_title.text = "4. Adentro, desde la silla del brazo izquierdo"
	_look(Vector3(-0.85, 1.75, -1.55), Vector3(-2.6, 1.0, -4.6), 80.0)
	shots.append(await _grab())
	_title.text = "5. Adentro, hacia atrás"
	_look(Vector3(-2.4, 1.7, -1.2), Vector3(0.6, 0.7, 3.0), 85.0)
	shots.append(await _grab())
	for part in _roof:
		part.visible = false
	_title.text = "6. Desde arriba, sin techo"
	_look(Vector3(-1.5, 11.0, 4.0), Vector3(0.0, 0.0, -0.3), 50.0)
	shots.append(await _grab())
	_title.text = "7. Desde arriba, de costado, sin techo"
	_look(Vector3(-7.5, 7.0, 3.0), Vector3(0.0, 0.0, -0.5), 50.0)
	shots.append(await _grab())
	_glass_paint.albedo_color = GLASS_OUTSIDE
	for part in _roof:
		part.visible = true
	_title.text = "8. Afuera, desde atrás"
	_look(Vector3(14.0, 0.0, 23.0), Vector3(0.0, -4.0, 0.0), 45.0)
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


## ── LA MECA (el origen del nodo, en el piso de la cabina) ────────────────────────────────────────────────────────

func _build() -> void:
	var apothem := R * cos(PI / SIDES)
	# El piso y el techo: discos lisos del radio de afuera.
	_keep_left(_disc(OUTER, SLAB, -SLAB * 0.5, FLOOR))
	var roof := _disc(OUTER, SLAB, CLEAR + SLAB * 0.5, METAL)
	_roof.append(roof)
	# La piel de afuera: metal atrás, vidrio adelante (150°, cinco lados de adentro).
	var glass_half := deg_to_rad(75.0)
	_keep_left(_band(apothem + 0.02, OUTER, glass_half, TAU - glass_half, 0.0, CLEAR, METAL))
	var glass := _band(OUTER - 0.03, OUTER, -glass_half, glass_half, 0.0, CLEAR, Color.WHITE)
	glass.material_override = _glass_paint
	_keep_left(glass)
	# Adentro, los lados de metal, planos (los siete de atrás).
	for i in range(3, 10):
		_facet(i, apothem)
	# Debajo, el disco macizo, y la junta.
	_keep_left(_disc(OUTER - 0.05, BASE_TALL, -SLAB - BASE_TALL * 0.5, DARK_METAL))
	_keep_left(_disc(OUTER + 0.06, 0.12, -SLAB, METAL.darkened(0.25)))
	# La tarima, su escalón y el ascensor.
	_prism(STEP_R, PLATFORM_TALL * 0.5, PLATFORM_TALL * 0.25, DECK.darkened(0.08))
	_prism(PLATFORM_R, PLATFORM_TALL, PLATFORM_TALL * 0.5, DECK)
	var lift := _prism(LIFT_R, 0.04, PLATFORM_TALL + 0.02, LIFT)
	lift.position.z = LIFT_AT
	# Las sillas con su anillo: tres adelante, el movimiento arriba.
	# Los tres de adelante siguen la curva: cada uno en su lado, mirando hacia afuera (el usuario: «si es cilíndrico…
	# quedamos en que siguen al cilindro»).
	for i in [-1, 0, 1]:
		var angle: float = TAU * i / SIDES
		_post(_at(apothem - 0.95, angle, 0.0), -angle)
	_post(Vector3(0.0, PLATFORM_TALL, -0.45), 0.0)
	# Atrás, en las paredes: los kits en los cuatro lados de los costados de atrás; las municiones y la batería en el
	# de atrás de todo.
	for i in [4, 5, 7, 8]:
		_on_wall(i, apothem, 0.0, Vector2(0.6, 0.6), 0.6, KIT)
	_on_wall(6, apothem, -0.55, Vector2(0.6, 0.6), 1.2, AMMO)
	_on_wall(6, apothem, 0.55, Vector2(0.6, 0.6), 1.2, AMMO)
	_on_wall(6, apothem, 0.0, Vector2(0.4, 0.5), 0.6, BATTERY)


## Un disco liso de `radius`, de `tall`, centrado a la altura `y`.
func _disc(radius: float, tall: float, y: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = tall
	mesh.radial_segments = 64
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = Clay.material(color)
	part.position.y = y
	_mech.add_child(part)
	return part


## Un prisma de 12 lados (radio a los vértices `radius`), con un lado plano al frente.
func _prism(radius: float, tall: float, y: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = tall
	mesh.radial_segments = SIDES
	mesh.rings = 0
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = Clay.material(color)
	part.position.y = y
	part.rotation_degrees.y = 180.0 / SIDES
	_mech.add_child(part)
	return part


## Una banda de cilindro de `r0` a `r1`, de los ángulos `a0` a `a1` (0 al frente, positivo a la derecha), de `y0` a
## `y1`: las caras de adentro y de afuera, las tapas y los cantos.
func _band(r0: float, r1: float, a0: float, a1: float, y0: float, y1: float, color: Color) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := maxi(int((a1 - a0) / TAU * 64.0), 2)
	for k in steps:
		var b0 := a0 + (a1 - a0) * k / steps
		var b1 := a0 + (a1 - a0) * (k + 1) / steps
		for r: float in [r0, r1]:
			_quad(tool, _at(r, b0, y0), _at(r, b1, y0), _at(r, b1, y1), _at(r, b0, y1))
		_quad(tool, _at(r0, b0, y1), _at(r0, b1, y1), _at(r1, b1, y1), _at(r1, b0, y1))
		_quad(tool, _at(r0, b0, y0), _at(r0, b1, y0), _at(r1, b1, y0), _at(r1, b0, y0))
	for b: float in [a0, a1]:
		_quad(tool, _at(r0, b, y0), _at(r1, b, y0), _at(r1, b, y1), _at(r0, b, y1))
	tool.generate_normals()
	var part := MeshInstance3D.new()
	part.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	part.material_override = paint
	_mech.add_child(part)
	return part


func _at(r: float, angle: float, y: float) -> Vector3:
	return Vector3(sin(angle) * r, y, -cos(angle) * r)


func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		tool.add_vertex(point)


## Un lado plano de adentro (el `i`, 0 el del frente, a la derecha), de metal, de piso a techo.
func _facet(i: int, apothem: float) -> void:
	var angle := TAU * i / SIDES
	var width := 2.0 * R * sin(PI / SIDES)
	var part := Clay.box(_mech, Vector3(width, CLEAR, 0.08), _at(apothem + 0.04, angle, CLEAR * 0.5), METAL.lightened(0.08))
	part.rotation.y = -angle
	if sin(angle) < -0.2:
		_left.append(part)


## Una caja colgada de la pared del lado `i`, corrida `shift` a lo largo, a la altura `y`.
func _on_wall(i: int, apothem: float, shift: float, size: Vector2, y: float, color: Color) -> void:
	var angle := TAU * i / SIDES
	var along := Vector3(cos(angle), 0, sin(angle))
	var part := Clay.box(_mech, Vector3(size.x, size.y, 0.12), _at(apothem - 0.02, angle, y + size.y * 0.5) + along * shift,
		color)
	part.rotation.y = -angle


## UN PUESTO: la silla y el que se sienta, nada más, girado `turn` (mirando al frente con 0).
func _post(at: Vector3, turn: float) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = turn
	_mech.add_child(holder)
	Clay.box(holder, Vector3(0.55, 0.12, 0.5), Vector3(0, 0.45, 0.05), SEAT)
	Clay.box(holder, Vector3(0.55, 0.65, 0.1), Vector3(0, 0.8, 0.3), SEAT)
	Clay.cylinder(holder, 0.06, 0.4, Vector3(0, 0.2, 0.05), DARK_METAL)
	# El que se sienta: el cuerpo, la cabeza y los muslos.
	Clay.box(holder, Vector3(0.4, 0.6, 0.25), Vector3(0, 0.85, 0.15), PERSON)
	Clay.sphere(holder, 0.13, Vector3(0, 1.3, 0.12), PERSON)
	Clay.box(holder, Vector3(0.36, 0.14, 0.45), Vector3(0, 0.56, -0.12), PERSON)


## Lo que se esconde al cortarla de costado: de cada pieza larga, nada (el corte se hace escondiendo enteras las del
## lado izquierdo). Las lisas (discos, piel) se esconden enteras: el corte deja ver adentro.
func _keep_left(part: Node3D) -> void:
	_left.append(part)


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _mech.global_transform * from
	_eye.look_at(_mech.global_transform * to, Vector3.UP)


func _save(shots: Array) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	for index in shots.size():
		(shots[index] as Image).save_png("%s/redonda_%d.png" % [_folder, index + 1])
	print("CAPTURAS ", _folder)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
