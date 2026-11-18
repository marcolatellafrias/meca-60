extends Node

## EL ESCUDO FÍSICO AGARRADO POR UN MANGO (18/11/2026, el usuario: «hacer un escudo físico opaco y aceptar el trade-off
## de que va a tapar la pantalla como para testear la idea… como base usaría la mano común con el puño común… que lo
## agarre con un mango»; y de las cinco formas: «rectangular… un plano… agarrado como el centro de la cara de adentro…
## un mini mango… muy derechito, muy perfecto, se ve raro»). El brazo derecho con el puño común (discreto), en guardia
## (Mech.covering; la guardia de hoy levanta los dos brazos, así que el cañón se esconde en estas fotos): el puño cierra
## los dedos en un mango corto, y el escudo, un plano rectangular, va delante mirando hacia donde apunta el antebrazo.
## Fotos: de afuera de costado, de frente, de lado (el mango) y desde los ojos del de abajo. Hoja: escudo_fisico.png.
##   tools/godot_ventana.sh res://tests/shield_held_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const GAP := 13.0
const PLATE := Color(0.55, 0.57, 0.6)
const HANDLE := Color(0.22, 0.23, 0.25)
## El escudo: su grosor, cuánto adelante del puño va su cara de atrás (m).
const THICK := 0.1
const AHEAD := 0.35
const SHAPES := ["plano"]
## EL PLANO (18/11/2026, el usuario: «rectangular, pero no como el primero que tiene chamfers… un plano… de esa misma
## proporción… agarrado como el centro de la cara de adentro… un mini mango… no centrado… muy derechito, muy perfecto,
## se ve raro»): ancho y alto (m), la proporción del de torre; el mango, su largo (m) y su radio en la medida de la mano
## (ver MechHand.grip_on).
const FLAT := Vector2(2.0, 3.2)
const HANDLE_LONG := 0.45
const HANDLE_RADIUS := 0.25
## Cuánto toma del giro de la mano (0, derecho mirando adelante; 1, como la mano): un poco, para que no quede perfecto.
## Con todo el giro, la guardia de hoy lo dejaba a 45°, como un rombo.
const NATURAL := 0.3

var _folder := ""
var _eye: Camera3D = null
var _shots: Array = []
var _mechs: Array[CageMech] = []
var _numbers: Array[Label3D] = []


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
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	_eye.near = 0.02
	add_child(_eye)
	_eye.make_current()
	for index in SHAPES.size():
		var mech := CageMech.new()
		mech.scripted = true
		mech.loadout = [ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.CANNON, true),
			ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.FIST, true)]
		mech.position = Vector3((2.0 - index) * GAP, Mech.standing_height(mech.cabin_shape), 0.0)
		add_child(mech)
		_mechs.append(mech)
		var number := Label3D.new()
		number.text = str(index + 1)
		number.font_size = 160
		number.pixel_size = 0.01
		number.outline_size = 24
		number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		number.position = mech.position + Vector3(0.0, 4.3, 0.0)
		add_child(number)
		_numbers.append(number)
	await get_tree().create_timer(0.6).timeout
	for mech in _mechs:
		mech.label.visible = false
		mech.covering = true
		var cabin := mech.cabin as CageCabin
		for seat in CageCabin.SEAT_NAMES.size():
			cabin.evict(seat)
	# En guardia: que el brazo llegue.
	await get_tree().create_timer(1.5).timeout
	var form := CageCabin.shape()
	for index in _mechs.size():
		var mech := _mechs[index]
		var right: MechArm = null
		for arm in mech.arms:
			if mech.to_local(arm.anchor.global_transform * arm.shoulder_local).x > 0.0:
				right = arm
			else:
				for node in arm.find_children("*", "Node3D", true, false):
					(node as Node3D).visible = false
		if index == 0:
			print("PUÑO EN GUARDIA, desde la meca: ", snapped(mech.to_local(right._hand.global_position), Vector3.ONE * 0.01))
		_hold(mech, right, SHAPES[index])
	await get_tree().create_timer(0.3).timeout
	_shots.clear()
	for index in _mechs.size():
		for other in _numbers.size():
			_numbers[other].visible = other == index
		var mech := _mechs[index]
		await _shot(mech.global_position + Vector3(6.5, 1.5, -10.5), mech.global_position + Vector3(0.5, 0.0, -1.0), 50.0)
		for number in _numbers:
			number.visible = false
		await _shot(mech.global_position + Vector3(0.5, 1.0, -12.0), mech.global_position + Vector3(0.5, 0.0, -1.0), 50.0)
		await _shot(mech.global_position + Vector3(9.0, 0.5, -1.5), mech.global_position + Vector3(0.5, 0.0, -2.5), 50.0)
		var cabin := mech.cabin as CageCabin
		var seat := cabin.board_root().global_transform * CageCabin.driver_eye(form)
		await _shot(seat, seat - mech.global_basis.z, 85.0)
	_save("escudo_fisico.png", 2)
	get_tree().quit()


## EL ESCUDO EN EL PUÑO DEL BRAZO `arm`, AGARRADO DEL CENTRO DE SU CARA DE ADENTRO: un mango corto donde el puño cierra
## los dedos (MechHand.grip_on, a lo largo del eje del puño, como el palo), dos pernos hasta el escudo, y el escudo
## delante, mirando adelante con un poco del giro de la mano (`NATURAL`): no derechito. Se cuelga de la mano.
func _hold(mech: CageMech, arm: MechArm, _shape: String) -> void:
	var hand := arm._hand
	var size := hand.global_basis.get_scale().x
	var grip := hand.to_global(hand.grip_on(HANDLE_RADIUS))
	var axis := hand.global_basis.y.normalized()
	if axis.y < 0.0:
		axis = -axis
	var along := (hand.global_position - arm.forearm_skin.global_position).normalized()
	var natural := (along - axis * along.dot(axis)).normalized()
	var forward := -mech.global_basis.z
	var normal := forward.lerp(natural, NATURAL).normalized()
	var up := Vector3.UP.lerp(axis, NATURAL)
	up = (up - normal * up.dot(normal)).normalized()
	var holder := Node3D.new()
	holder.name = "Escudo de prueba"
	mech.add_child(holder)
	holder.global_transform = Transform3D(Basis(normal.cross(up), normal, up), grip)
	# En el espacio del escudo: x a lo ancho, y hacia adelante (el grosor), z para arriba; el mango en el origen.
	var bar := Clay.limb(holder, HANDLE_RADIUS * size, 1.0, Vector3.ZERO, HANDLE)
	Clay.segment(bar, Vector3(0.0, 0.0, -HANDLE_LONG * 0.5), Vector3(0.0, 0.0, HANDLE_LONG * 0.5), 1.0)
	for end: float in [-1.0, 1.0]:
		var post := Clay.box(holder, Vector3(0.08, AHEAD, 0.08), Vector3(0.0, AHEAD * 0.5, end * HANDLE_LONG * 0.5), HANDLE)
		post.name = "Perno"
	Clay.box(holder, Vector3(FLAT.x, THICK, FLAT.y), Vector3(0.0, AHEAD + THICK * 0.5, 0.0), PLATE)
	holder.reparent(hand, true)


func _shot(from: Vector3, to: Vector3, fov: float) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(VIEW.x / 2, VIEW.y / 2, Image.INTERPOLATE_BILINEAR)
	_shots.append(image)


func _save(file: String, columns: int) -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var rows := ceili(_shots.size() / float(columns))
	var sheet := Image.create(first.get_width() * columns, first.get_height() * rows, false, first.get_format())
	for index in _shots.size():
		sheet.blit_rect(_shots[index], Rect2i(Vector2i.ZERO, first.get_size()),
			Vector2i(first.get_width() * (index % columns), first.get_height() * (index / columns)))
	var path := "%s/%s" % [_folder, file]
	sheet.save_png(path)
	print("CAPTURA ", path)
