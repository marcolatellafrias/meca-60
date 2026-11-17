extends Node3D

## EL QUE MANEJA, RECOSTADO: LAS DOS QUE QUEDARON, SUELTAS Y EN LA MECA (16/11/2026, el usuario: «mostrame 1 y 2, y cómo
## quedarían en la meca también»). Maquetas de arcilla del más alto (flaco largo):
##   1 · LOS OJOS EN EL EJE DEL VIDRIO: la 6 de tests/recline_pose_look (como en gravedad cero, la espalda y la cabeza
##       apoyadas en la pared), con la cabeza a la altura del centro: la mirada pasa por el medio del círculo, más atrás.
##   2 · LOS OJOS EN EL CENTRO, LA CABEZA SIN APOYAR: la cadera en una cuna contra la pared y la cabeza en un apoyacabezas
##       con su brazo; el cuerpo a medio doblar.
## Cada una con el radio más chico en que entra. En la meca: la de verdad (CageMech) con ese radio, sin la silla de
## ahora, con la maqueta en su lugar.
##   tools/godot_ventana.sh res://tests/driver_pose_look.tscn -- --salida=C:/carpeta --opcion=1

const VIEW := Vector2i(1280, 720)
const NECK := 0.22
const SPINE := [0.2, 0.2, 0.18]
const THIGH := 0.5
const SHIN := 0.48
const FOOT := 0.24
const BACK := 0.12
const HEAD := 0.13
const CLEAR := 0.07
const BODY := Color(0.85, 0.55, 0.35)
const PAD := Color(0.35, 0.3, 0.28)
const SHELL := Color(0.6, 0.61, 0.63)
const GLASS := Color(0.62, 0.8, 0.92, 0.3)
const DARK := Color(0.3, 0.31, 0.34)
const RED := Color(0.78, 0.18, 0.15)
const NAMES := {1: "1 · los ojos en el eje del vidrio, la cabeza apoyada", 2: "2 · los ojos en el centro, la cabeza sin apoyar"}

var _folder := ""
var _option := 1
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--opcion="):
			_option = int(argument.trim_prefix("--opcion="))
	get_window().size = VIEW
	_stage()
	var radius := _radius()
	# Suelta, lejos de la meca.
	var alone := Node3D.new()
	alone.position = Vector3(0.0, 2.0, 300.0)
	add_child(alone)
	_sphere(alone, radius)
	_figure(alone, radius)
	# En la meca, con ese radio.
	var form := CageShape.current
	form.sphere_radius = radius
	var holder := Node3D.new()
	add_child(holder)
	CageMechArchetype.new().build(0, holder)
	var mech: CageMech = null
	for found in holder.find_children("*", "CageMech", true, false):
		mech = found
	mech.scripted = true
	await get_tree().create_timer(2.0).timeout
	var cabin := mech.cabin as CageCabin
	cabin.evict(CageCabin.DRIVER)
	cabin.chairs[CageCabin.DRIVER].visible = false
	var inside := Node3D.new()
	inside.position = Vector3(0.0, CageCabin.bottom() + form.floor_thick + radius, -form.side() * 0.5)
	cabin.add_child(inside)
	_figure(inside, radius)
	await get_tree().create_timer(0.5).timeout
	var title := "%s · esfera de %.2f m, módulo de %.2f m" % [NAMES[_option], radius, form.side()]
	print(title)
	_title.text = title
	var shots: Array[Image] = []
	_eye.near = 10.0 - 0.32
	shots.append(await _view(alone.position + Vector3(10.0, 0.0, 0.0), alone.position + Vector3(0.0, -0.2, 0.0), 0.0, 3.0))
	_eye.near = 0.05
	shots.append(await _view(alone.position + Vector3(-2.4, 1.4, -3.6), alone.position + Vector3(0.0, -0.4, 0.0), 50.0))
	var at := mech.global_position
	var forward := -mech.global_basis.z
	var right := mech.global_basis.x
	shots.append(await _view(at + forward * 7.0 - right * 4.5 + Vector3.UP * 1.5, at + Vector3.UP * 0.3, 50.0))
	_eye.near = 20.0 - 0.32
	var side := at + right * 20.0
	shots.append(await _view(side + Vector3.UP * 0.6, at + Vector3.UP * 0.6, 0.0, 6.5))
	_save(shots)
	get_tree().quit()


## EL RADIO MÁS CHICO en que entra la opción.
func _radius() -> float:
	if _option == 2:
		var far := 0.12
		var shape := _centered()
		for key: String in ["neck", "hip", "knee", "ankle", "toe"]:
			far = maxf(far, (shape[key] as Vector2).length())
		for p: Vector2 in shape["chain"]:
			far = maxf(far, p.length())
		return snappedf(far + 0.14, 0.01)
	var radius := 0.7
	while radius < 2.0:
		var shape := _leaning(radius)
		var inside := true
		for key: String in ["knee", "ankle", "toe"]:
			inside = inside and (shape[key] as Vector2).length() <= radius - CLEAR
		if inside:
			return radius
		radius += 0.01
	return radius


## LA 1: la espalda y la cabeza por la pared, la cabeza a la altura del centro; las piernas como en gravedad cero.
## En el plano del medio (adelante, arriba), con el centro de la esfera en el origen.
func _leaning(radius: float) -> Dictionary:
	var along := radius - BACK
	var angle := PI
	var head := Vector2(-(radius - HEAD), -0.02)
	var chain: Array[Vector2] = []
	for length: float in [NECK] + SPINE:
		angle += 2.0 * asin(minf(length / (2.0 * along), 1.0))
		chain.append(Vector2(cos(angle), sin(angle)) * along)
	var hip := chain[chain.size() - 1]
	var knee := hip + _dir(20.0, THIGH)
	var ankle := knee + _dir(20.0 - 50.0, SHIN)
	return {"eye": head + Vector2(0.09, 0.02), "head": head, "chain": chain, "hip": hip, "knee": knee,
		"ankle": ankle, "toe": ankle + _dir(20.0 - 50.0 + 90.0, FOOT), "neck": chain[0]}


## LA 2: los ojos en el centro; la columna a medio doblar hacia atrás y abajo; las piernas como en gravedad cero.
func _centered() -> Dictionary:
	var eye := Vector2.ZERO
	var neck := eye + _dir(-90.0 - 18.0, 0.28)
	var chain: Array[Vector2] = [neck]
	var point := neck
	var angle := -90.0 - 32.0
	for length: float in SPINE:
		point += _dir(angle, length)
		chain.append(point)
		angle += 10.0
	var knee := point + _dir(22.0, THIGH)
	var ankle := knee + _dir(22.0 - 48.0, SHIN)
	return {"eye": eye, "head": eye + Vector2(-0.06, 0.02), "chain": chain, "hip": point, "knee": knee,
		"ankle": ankle, "toe": ankle + _dir(22.0 - 48.0 + 90.0, FOOT), "neck": neck}


## LA MAQUETA de la opción en `parent` (su origen, el centro de la esfera; adelante, −Z), con su silla.
func _figure(parent: Node3D, radius: float) -> void:
	var shape := _leaning(radius) if _option == 1 else _centered()
	var chain: Array[Vector2] = shape["chain"]
	var head: Vector2 = shape["head"]
	var eye: Vector2 = shape["eye"]
	var hip: Vector2 = shape["hip"]
	Clay.sphere(parent, 0.12, _at(head, 0.0), BODY)
	var previous := head
	for k in chain.size():
		_limb(parent, _at(previous, 0.0), _at(chain[k], 0.0), 0.06 if k == 0 else 0.15, BODY)
		previous = chain[k]
	if _option == 1:
		# El acolchado: una tira sobre la pared, de la cabeza a la cadera.
		var pad: Array[Vector2] = [head]
		pad.append_array(chain)
		for k in range(1, pad.size()):
			_limb(parent, _at(pad[k - 1].normalized() * (radius - 0.03), 0.0),
				_at(pad[k].normalized() * (radius - 0.03), 0.0), 0.05, PAD, 0.5)
	else:
		# La cuna de la cadera, contra la pared, y el apoyacabezas en su brazo.
		var wall := hip.normalized() * (radius - 0.02)
		_limb(parent, _at(hip + hip.normalized() * 0.1, 0.0), _at(wall, 0.0), 0.05, DARK)
		Clay.box(parent, Vector3(0.45, 0.08, 0.45), _at(hip + Vector2(0.0, -0.14), 0.0), PAD)
		var rest := head + Vector2(-0.16, 0.0)
		Clay.box(parent, Vector3(0.3, 0.22, 0.08), _at(rest, 0.0), PAD)
		_limb(parent, _at(rest + Vector2(-0.04, 0.0), 0.0), _at(Vector2(-radius + 0.02, rest.y), 0.0), 0.04, DARK)
	for s: float in [-1.0, 1.0]:
		var x := s * 0.11
		_limb(parent, _at(hip, x), _at(shape["knee"], x), 0.075, BODY)
		_limb(parent, _at(shape["knee"], x), _at(shape["ankle"], x), 0.06, BODY)
		_limb(parent, _at(shape["ankle"], x), _at(shape["toe"], x), 0.045, BODY)
		var shoulder: Vector2 = shape["neck"]
		var hand := eye + Vector2(0.45, -0.42)
		var elbow := (shoulder + hand) * 0.5 + Vector2(-0.05, -0.1)
		_limb(parent, _at(shoulder, s * 0.2), _at(elbow, s * 0.26), 0.05, BODY)
		_limb(parent, _at(elbow, s * 0.26), _at(hand, s * 0.2), 0.045, BODY)
	Clay.box(parent, Vector3(0.7, 0.04, 0.25), _at(eye + Vector2(0.5, -0.46), 0.0), DARK)
	var reach := sqrt(maxf(radius * radius - eye.y * eye.y, 0.0))
	_limb(parent, _at(eye, 0.0), _at(Vector2(reach, eye.y), 0.0), 0.008, RED)


func _sphere(parent: Node3D, radius: float) -> void:
	for part: Array in [[PI * 0.5, PI, SHELL], [0.0, PI * 0.5, GLASS]]:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		CageMesh.sphere_band(tool, Vector3.ZERO, radius, part[0], part[1], false)
		var mesh := MeshInstance3D.new()
		mesh.mesh = tool.commit()
		var paint := Clay.material(part[2]).duplicate() as StandardMaterial3D
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = paint
		parent.add_child(mesh)
	Clay.sphere(parent, 0.03, Vector3.ZERO, RED)


func _at(p: Vector2, x: float) -> Vector3:
	return Vector3(x, p.y, -p.x)


func _dir(degrees: float, length: float) -> Vector2:
	var a := deg_to_rad(degrees)
	return Vector2(cos(a), sin(a)) * length


func _limb(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color, flat := 1.0) -> void:
	var holder := Clay.limb(parent, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)
	if flat != 1.0:
		holder.scale = Vector3(3.0, flat, 1.0)


func _stage() -> void:
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
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


func _view(from: Vector3, to: Vector3, fov: float, ortho := 0.0) -> Image:
	if fov > 0.0:
		_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		_eye.fov = fov
	else:
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.size = ortho
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array[Image]) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var w := shots[0].get_width()
	var h := shots[0].get_height()
	var sheet := Image.create(w * 2, h * 2, false, shots[0].get_format())
	for index in shots.size():
		sheet.blit_rect(shots[index], Rect2i(Vector2i.ZERO, shots[index].get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/pose_meca_%d.png" % [_folder, _option]
	sheet.save_png(path)
	print("CAPTURA ", path)
