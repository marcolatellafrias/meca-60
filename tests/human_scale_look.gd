extends Node3D

## LA MECA DE TRES A ESCALA HUMANA, MAQUETAS DE ARCILLA (16/11/2026; sigue la numeración de tests/pelvis_platform_look).
## El usuario: «una escala mucho más cercana a algo humano… una meca para 3 que tiene 3 lugares para meterse, uno desde
## abajo, otro desde… el frente y otro… desde atrás. Desde atrás es artillero, de abajo es movimiento y el frente es
## brazos… las cabinas son como más circulares… el de artillería ni siquiera es cabina, va directamente arriba…
## manteniendo brazos y piernas como los actuales… qué formas se te ocurren».
##   · ABAJO, EL QUE MANEJA: se entra por una tapa en la panza, con una escalerita colgando.
##   · ADELANTE, LOS BRAZOS: una burbuja de vidrio al frente, que es la tapa por donde se entra, con agarraderas abajo.
##   · ARRIBA Y ATRÁS, EL ARTILLERO: al aire, sentado detrás de la ametralladora con un escudo; se sube por atrás.
##   · Piernas y brazos con las proporciones de los de hoy, al LIMBS (a la medida de una persona).
##   88 · el huevo: un solo cuerpo ovalado, el que maneja en la mitad de abajo y los brazos en la de arriba;
##   89 · dos esferas: la de abajo para el que maneja, la de arriba (más grande) para los brazos;
##   90 · el tambor: un cilindro acostado para los brazos y una bola colgada entre las caderas para el que maneja;
##   91 · la jaula: abajo una cápsula cerrada; arriba los brazos al aire, dentro de un arco de caños;
##   92 · la bala: una cápsula parada con la punta redonda; el artillero, en un aro sobre la punta.
##   tools/godot_ventana.sh res://tests/human_scale_look.tscn -- --salida=C:/carpeta --variante=88

const VIEW := Vector2i(1280, 720)
const VARIANTS := {
	88: "el huevo",
	89: "dos esferas",
	90: "el tambor y la bola",
	91: "la jaula",
	92: "la bala",
}
const LIMBS := 0.3
const BODY := Color(0.6, 0.61, 0.63)
const DARK := Color(0.3, 0.31, 0.34)
const RIM := Color(0.22, 0.23, 0.25)
const HOLE := Color(0.08, 0.08, 0.1)
const GLASS := Color(0.62, 0.8, 0.92, 0.3)
const JOINT := Color(0.36, 0.375, 0.4)
const SKIN := Color(0.86, 0.66, 0.5)
const SEAT := Color(0.25, 0.42, 0.7)

var _folder := ""
var _variant := 88
var _eye: Camera3D = null
var _title: Label = null
var _bottom := 0.0
## Lo que cada forma deja para el resto: dónde van los hombros (x, y, z del derecho) y lo más alto.
var _shoulder := Vector3.ZERO
var _top := 0.0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
	get_window().size = VIEW
	_stage()
	var body := MechBody.current
	var hip_line := (body.WAIST - body.HIP_DROP) * LIMBS
	_bottom = hip_line + 0.25
	match _variant:
		88: _egg()
		89: _spheres()
		90: _drum()
		91: _cage()
		92: _bullet()
	_legs(hip_line)
	for s: float in [-1.0, 1.0]:
		_arm(Vector3(s * _shoulder.x, _shoulder.y, _shoulder.z), s)
	# Para la escala: una persona al lado, en el suelo.
	_standing(Vector3(-2.2, 0.0, -1.2))
	await get_tree().create_timer(2.0).timeout
	var whole := Vector3(0.0, _top * 0.5, 0.0)
	var k := _top / 5.0
	var shots: Array = []
	_title.text = "%d. %s" % [_variant, VARIANTS[_variant]]
	shots.append(await _view(whole + Vector3(-6.0, 2.5, -8.0) * k, whole, 45.0))
	_title.text = "%d. de atrás" % _variant
	shots.append(await _view(whole + Vector3(6.0, 2.5, 8.0) * k, whole, 45.0))
	_title.text = "%d. de costado" % _variant
	shots.append(await _view(whole + Vector3(-30.0, 0.0, 0.0), whole, 0.0, _top + 1.0))
	_title.text = "%d. de frente" % _variant
	shots.append(await _view(whole + Vector3(0.0, 0.0, -30.0), whole, 0.0, _top + 1.0))
	_title.text = "%d. de abajo: la tapa del que maneja" % _variant
	shots.append(await _view(Vector3(1.8, 0.5, -2.8), Vector3(0.0, _bottom, 0.0), 60.0))
	_title.text = "%d. de cerca, de atrás y arriba: el artillero" % _variant
	shots.append(await _view(Vector3(2.0, _top + 1.8, 3.2), Vector3(0.0, _top - 0.6, 0.0), 55.0))
	_save(shots)
	get_tree().quit()


## ── LAS FORMAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## 88 · EL HUEVO: un solo cuerpo ovalado; el que maneja abajo (ventanita baja), los brazos arriba (la burbuja).
func _egg() -> void:
	var radii := Vector3(1.1, 1.65, 1.1)
	var center := Vector3(0.0, _bottom + radii.y, 0.0)
	_ellipsoid(radii, center, BODY)
	Clay.cylinder(self, 1.11, 0.07, center + Vector3(0.0, -0.15, 0.0), RIM)
	_seated(Vector3(0.0, _bottom + 0.35, 0.05))
	_slit(Vector3(0.0, _bottom + 1.2, -0.95), 0.9)
	_belly(Vector3(0.0, _bottom + 0.02, 0.1))
	var bubble := Vector3(0.0, _bottom + 2.25, -0.72)
	_seated(Vector3(0.0, _bottom + 1.55, -0.1))
	_ellipsoid(Vector3(0.62, 0.62, 0.5), bubble, GLASS)
	_rungs(Vector3(0.0, _bottom + 0.9, -1.08), 3, -1.0)
	_gunner(Vector3(0.0, _bottom + radii.y * 2.0 - 0.15, 0.35))
	_rungs_back(Vector3(0.0, _bottom + 0.8, 1.15), _bottom + radii.y * 2.0)
	_shoulder = Vector3(radii.x + 0.32, _bottom + 2.1, 0.0)
	_top = _bottom + radii.y * 2.0 + 1.2


## 89 · DOS ESFERAS: abajo el que maneja, arriba (más grande) los brazos; un collar entre las dos.
func _spheres() -> void:
	var low := Vector3(0.0, _bottom + 0.95, 0.05)
	var high := Vector3(0.0, _bottom + 2.55, -0.1)
	Clay.sphere(self, 0.95, low, BODY)
	Clay.sphere(self, 1.15, high, BODY)
	Clay.cylinder(self, 0.75, 0.3, Vector3(0.0, _bottom + 1.75, 0.0), RIM)
	_seated(Vector3(0.0, _bottom + 0.35, 0.15))
	_slit(Vector3(0.0, _bottom + 1.2, -0.82), 0.8)
	_belly(Vector3(0.0, _bottom + 0.02, 0.1))
	_seated(Vector3(0.0, _bottom + 1.75, 0.0))
	_ellipsoid(Vector3(0.65, 0.65, 0.5), high + Vector3(0.0, 0.0, -0.75), GLASS)
	_rungs(Vector3(0.0, _bottom + 1.55, -0.9), 3, -1.0)
	_gunner(Vector3(0.0, high.y + 0.95, 0.45))
	_rungs_back(Vector3(0.0, _bottom + 0.9, 1.2), high.y + 1.0)
	_shoulder = Vector3(1.45, high.y - 0.1, -0.1)
	_top = high.y + 1.15 + 1.0


## 90 · EL TAMBOR Y LA BOLA: un cilindro acostado (de lado a lado) para los brazos, con su ventana redonda adelante; la
## bola del que maneja, colgada abajo entre las caderas.
func _drum() -> void:
	var drum := Vector3(0.0, _bottom + 2.0, 0.0)
	Clay.cylinder(self, 1.15, 2.3, drum, BODY, Vector3(0.0, 0.0, 90.0))
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(self, 1.2, 0.12, drum + Vector3(s * 1.15, 0.0, 0.0), RIM, Vector3(0.0, 0.0, 90.0))
	_seated(Vector3(0.0, drum.y - 0.75, 0.0))
	_ellipsoid(Vector3(0.6, 0.6, 0.45), drum + Vector3(0.0, 0.05, -1.0), GLASS)
	_rungs(Vector3(0.0, drum.y - 0.85, -1.2), 2, -1.0)
	var ball := Vector3(0.0, _bottom + 0.2, 0.0)
	Clay.sphere(self, 0.85, ball, DARK.lightened(0.25))
	_seated(Vector3(0.0, ball.y - 0.55, 0.1))
	_slit(Vector3(0.0, ball.y + 0.25, -0.78), 0.7)
	_belly(Vector3(0.0, ball.y - 0.83, 0.1))
	_gunner(Vector3(0.0, drum.y + 1.1, 0.45))
	_rungs_back(Vector3(0.0, drum.y - 0.6, 1.2), drum.y + 1.1)
	_shoulder = Vector3(1.55, drum.y, 0.0)
	_top = drum.y + 1.15 + 1.0


## 91 · LA JAULA: abajo una cápsula cerrada (el que maneja); arriba, los brazos al aire, dentro de un arco de caños,
## con el tablero adelante; el artillero atrás, un escalón más arriba.
func _cage() -> void:
	var pod := Vector3(0.0, _bottom + 0.85, 0.0)
	Clay.cylinder(self, 1.0, 1.4, pod, BODY)
	Clay.sphere(self, 1.0, pod + Vector3(0.0, -0.45, 0.0), BODY)
	_seated(Vector3(0.0, _bottom + 0.2, 0.1))
	_slit(Vector3(0.0, pod.y + 0.3, -0.93), 0.9)
	_belly(Vector3(0.0, _bottom - 0.5, 0.0))
	var deck := pod.y + 0.7
	Clay.cylinder(self, 1.1, 0.12, Vector3(0.0, deck, 0.0), RIM)
	_seated(Vector3(0.0, deck + 0.06, -0.1))
	for angle: float in [-0.9, -0.3, 0.3, 0.9]:
		var foot := Vector3(sin(angle) * 1.0, deck, -cos(angle) * 1.0)
		Clay.segment(Clay.box(self, Vector3.ONE, Vector3.ZERO, RIM), foot, foot + Vector3(0.0, 1.6, 0.6), 0.07)
	Clay.box(self, Vector3(1.6, 0.07, 0.07), Vector3(0.0, deck + 1.6, -0.35), RIM)
	_rungs(Vector3(0.0, pod.y - 0.4, -1.05), 3, -1.0)
	var back := Vector3(0.0, deck + 0.45, 0.85)
	Clay.box(self, Vector3(1.2, 0.45, 0.9), back + Vector3(0.0, -0.22, 0.0), BODY)
	_gunner(back)
	_rungs_back(Vector3(0.0, pod.y - 0.3, 1.35), back.y)
	_shoulder = Vector3(1.3, deck + 0.3, -0.1)
	_top = deck + 1.9


## 92 · LA BALA: una cápsula parada, la punta redonda arriba; la burbuja de los brazos adelante; el artillero en un aro
## sobre la punta, medio cuerpo afuera.
func _bullet() -> void:
	var tall := 2.4
	var center := Vector3(0.0, _bottom + tall * 0.5, 0.0)
	Clay.cylinder(self, 1.05, tall, center, BODY)
	Clay.sphere(self, 1.05, Vector3(0.0, _bottom + tall, 0.0), BODY)
	Clay.cylinder(self, 1.1, 0.1, Vector3(0.0, _bottom + 1.3, 0.0), RIM)
	_seated(Vector3(0.0, _bottom + 0.15, 0.1))
	_slit(Vector3(0.0, _bottom + 1.0, -0.98), 0.9)
	_belly(Vector3(0.0, _bottom - 0.02, 0.1))
	_seated(Vector3(0.0, _bottom + 1.4, 0.0))
	_ellipsoid(Vector3(0.62, 0.62, 0.45), Vector3(0.0, _bottom + 2.15, -0.95), GLASS)
	_rungs(Vector3(0.0, _bottom + 0.6, -1.12), 3, -1.0)
	var ring := Vector3(0.0, _bottom + tall + 0.9, 0.0)
	Clay.cylinder(self, 0.65, 0.2, ring, RIM)
	_gunner(ring + Vector3(0.0, -0.3, 0.1))
	_rungs_back(Vector3(0.0, _bottom + 0.6, 1.12), ring.y)
	_shoulder = Vector3(1.35, _bottom + 1.9, 0.0)
	_top = ring.y + 1.2


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## Un elipsoide de arcilla (o de vidrio) de radios `radii`.
func _ellipsoid(radii: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	mesh.mesh = sphere
	mesh.material_override = Clay.material(color)
	mesh.scale = radii
	mesh.position = at
	add_child(mesh)
	return mesh


## La ventanita baja del que maneja: una ranura oscura.
func _slit(at: Vector3, wide: float) -> void:
	Clay.box(self, Vector3(wide, 0.18, 0.2), at, HOLE)


## LA TAPA DE LA PANZA: un aro y el agujero, y la escalerita que cuelga hasta cerca del suelo.
func _belly(at: Vector3) -> void:
	Clay.cylinder(self, 0.42, 0.06, at, RIM)
	Clay.cylinder(self, 0.34, 0.07, at, HOLE)
	var foot := 0.45
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.04, at.y - foot, 0.04), Vector3(s * 0.2, (at.y + foot) * 0.5, at.z + 0.3), RIM)
	for i in int((at.y - foot) / 0.3):
		Clay.box(self, Vector3(0.4, 0.035, 0.035), Vector3(0.0, foot + 0.3 * i, at.z + 0.3), RIM)


## Agarraderas para trepar (`count`, cada 0,35 m hacia arriba) en una cara.
func _rungs(at: Vector3, count: int, _facing: float) -> void:
	for i in count:
		Clay.box(self, Vector3(0.45, 0.04, 0.08), at + Vector3(0.0, 0.35 * i, 0.0), RIM)


## La escalera de atrás, del artillero: de `at` hasta `to` (alto), separada del cuerpo.
func _rungs_back(at: Vector3, to: float) -> void:
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.04, to - at.y + 0.5, 0.04), Vector3(s * 0.22, (at.y + to + 0.5) * 0.5, at.z), RIM)
	for i in int((to - at.y) / 0.3) + 1:
		Clay.box(self, Vector3(0.44, 0.035, 0.035), Vector3(0.0, at.y + 0.3 * i, at.z), RIM)


## EL ARTILLERO al aire: su asiento, él, la ametralladora (cuatro caños) apuntando adelante y un escudo.
func _gunner(at: Vector3) -> void:
	_seated(at)
	var gun := at + Vector3(0.0, 0.85, -0.75)
	Clay.box(self, Vector3(0.3, 0.25, 0.5), gun + Vector3(0.0, 0.0, 0.1), DARK)
	for x: float in [-0.06, 0.06]:
		for y: float in [-0.06, 0.06]:
			Clay.cylinder(self, 0.035, 0.9, gun + Vector3(x, y, -0.55), RIM, Vector3(90.0, 0.0, 0.0))
	Clay.box(self, Vector3(1.0, 0.55, 0.05), gun + Vector3(0.0, -0.05, -0.2), DARK)


## UN PILOTO SENTADO, de arcilla, mirando adelante (−Z), con su silla: `at`, el piso debajo del asiento.
func _seated(at: Vector3) -> void:
	Clay.box(self, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(self, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), SEAT)
	Clay.box(self, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(self, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(self, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.12, 0.42, 0.12), at + Vector3(side * 0.1, 0.27, -0.28), SKIN)
		Clay.box(self, Vector3(0.1, 0.1, 0.38), at + Vector3(side * 0.24, 0.8, -0.12), SKIN)


## UNA PERSONA PARADA, de arcilla (1,75 m): `at`, el piso entre los pies.
func _standing(at: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.14, 0.85, 0.16), at + Vector3(side * 0.1, 0.425, 0.0), SKIN)
		Clay.box(self, Vector3(0.1, 0.6, 0.1), at + Vector3(side * 0.27, 1.15, 0.0), SKIN)
	Clay.box(self, Vector3(0.4, 0.6, 0.24), at + Vector3(0.0, 1.15, 0.0), SKIN)
	Clay.sphere(self, 0.13, at + Vector3(0.0, 1.62, 0.0), SKIN)


## UN BRAZO de arcilla desde el hombro: el antebrazo hacia adelante.
func _arm(shoulder: Vector3, side: float) -> void:
	var body := MechBody.current
	var upper := body.UPPER_ARM * LIMBS
	var fore := body.FOREARM * LIMBS
	var thick := body.LEG_THICKNESS * LIMBS
	var elbow := shoulder + Vector3(side * 0.25, -1.0, 0.25).normalized() * upper
	var hand := elbow + Vector3(0.0, -0.25, -1.0).normalized() * fore
	Clay.sphere(self, thick * 0.7, shoulder, JOINT)
	_limb(shoulder, elbow, thick * 0.48, Clay.METAL.darkened(0.1))
	Clay.sphere(self, thick * 0.55, elbow, JOINT)
	_limb(elbow, hand, thick * 0.45, Clay.METAL.darkened(0.2))
	Clay.sphere(self, thick * 0.6, hand, JOINT)


## LAS PIERNAS de arcilla.
func _legs(hip_y: float) -> void:
	var body := MechBody.current
	var thick := body.LEG_THICKNESS * LIMBS
	var hip_x := body.HIP_X * LIMBS
	var thigh := body.THIGH * LIMBS
	var foot := body.FOOT_SIZE * LIMBS
	Clay.cylinder(self, thick * 0.43, hip_x * 2.0, Vector3(0.0, hip_y, 0.0), JOINT, Vector3(0.0, 0.0, 90.0))
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * hip_x, hip_y, 0.0)
		var ankle := Vector3(side * (hip_x + 0.3 * LIMBS), thick * 0.33 + foot.y * 0.5, 0.0)
		var span := hip.distance_to(ankle)
		var bend := sqrt(maxf(thigh * thigh - span * span * 0.25, 0.0))
		var knee := (hip + ankle) * 0.5 + Vector3(0.0, 0.0, -bend)
		Clay.sphere(self, thick * 0.62, hip, JOINT)
		_limb(hip, knee, thick * 0.5, Clay.METAL.darkened(0.1))
		Clay.sphere(self, thick * 0.62, knee, JOINT)
		_limb(knee, ankle, thick * 0.5, Clay.METAL.darkened(0.2))
		Clay.sphere(self, thick * 0.53, ankle, JOINT)
		Clay.box(self, foot, Vector3(ankle.x, foot.y * 0.5, ankle.z - 0.4 * LIMBS), JOINT)


func _limb(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var holder := Clay.limb(self, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)


## ── LO DE SIEMPRE ────────────────────────────────────────────────────────────────────────────────────────────────

func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
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
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


## Una vista: con `fov`, en perspectiva; con fov 0, sin perspectiva, de `ortho` de alto.
func _view(from: Vector3, to: Vector3, fov: float, ortho := 0.0) -> Image:
	if fov > 0.0:
		_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		_eye.fov = fov
	else:
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.size = ortho
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.FORWARD)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


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
	var path := "%s/humana_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)
