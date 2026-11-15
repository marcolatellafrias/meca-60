extends Node3D

## EL DISCO DE DOS PISOS CON VÓRTICE, MAQUETA DE ARCILLA (15/11/2026, el usuario: «maqueta uno de 2 pisos con vórtice,
## pero el vórtice solamente te pasa de piso a planta baja, y desde planta baja hasta el primer piso es con una escalera
## caracol que sigue la forma del círculo… abajo estén todas las salas de reparación, máquinas y todo eso, y arriba las
## armas, los movimientos… el ascenso no lo haría de vidrio, lo haría algo más opaco, así no pueden ver a través»).
##   · EL VÓRTICE: una columna opaca en el centro, con la boca abajo del disco; te chupa del suelo y te deja en la planta
##     baja por su puerta.
##   · LA PLANTA BAJA, cerrada: la máquina, el banco de reparación, el tablero de la energía y las municiones; la
##     escalera caracol pegada a la pared sube al primer piso por un hueco del piso de arriba.
##   · EL PRIMER PISO, abierto: un anillo alrededor de un núcleo opaco (no se cruza por el medio); el borde con su bevel,
##     el manejo adelante, los mandos de los brazos a los costados, las ametralladoras en enchufes del borde (se sacan y
##     se ponen en otro) y el hueco de la escalera atrás, que deja un paso angosto.
##   tools/godot_ventana.sh res://tests/vortex_disc_look.tscn -- --salida=C:/carpeta [--agachada]

const VIEW := Vector2i(1280, 720)
const OUTER := 3.2
const WALK := 2.75
const RIM_OUT := 1.0
const RIM_IN := 0.8
const WALL := 0.15
## El núcleo de arriba y el tubo del vórtice (radios).
const CORE := 0.85
const TUBE := 0.7
## La planta baja: alto libre; las losas.
const CLEAR := 2.3
const SLAB := 0.25
## La escalera: de qué ángulo a cuál (desde el frente, hacia la derecha), cuántos escalones, y su franja (radios).
const STAIR_FROM := deg_to_rad(60.0)
const STAIR_TO := deg_to_rad(250.0)
const STEPS := 14
const STAIR_IN := 1.9
const STAIR_OUT := 2.7
## Desde qué escalón hace falta el hueco arriba (para pasar la cabeza).
const HOLE_FROM_STEP := 4
## Alto de la planta baja sobre el suelo: parada y agachada.
const STANDING := 3.6
const CROUCHED := 2.5

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const DECK := Color(0.72, 0.73, 0.75)
const LOW_FLOOR := Color(0.6, 0.58, 0.55)
const STAIR := Color(0.62, 0.55, 0.42)
const VORTEX := Color(0.36, 0.3, 0.5)
const RED := Color(0.8, 0.22, 0.18)
const YELLOW := Color(0.93, 0.75, 0.16)
const AMMO := Color(0.47, 0.53, 0.32)
const FACE := Color(0.92, 0.9, 0.84)

var _folder := ""
var _crouched := false
var _eye: Camera3D = null
var _title: Label = null
var _upper := Node3D.new()
var _wall_paint := StandardMaterial3D.new()
var _upstairs: Array[Node3D] = []
var _floor0 := 0.0
var _floor1 := 0.0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument == "--agachada":
			_crouched = true
	get_window().size = VIEW
	_wall_paint.albedo_color = METAL
	_wall_paint.roughness = 0.85
	_wall_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	_stage()
	_floor0 = CROUCHED if _crouched else STANDING
	_floor1 = _floor0 + CLEAR + SLAB
	add_child(_upper)
	_build()
	# Los jugadores: tres arriba (el manejo, el brazo izquierdo, la ametralladora de la izquierda) y uno abajo, en el banco.
	for crew: Array in [[0.0, EntityArchetype.Archetype.buff], [deg_to_rad(290.0), EntityArchetype.Archetype.lanky],
			[deg_to_rad(320.0), EntityArchetype.Archetype.fat_athletic]]:
		var angle: float = crew[0]
		_upstairs.append(PeopleArchetype.spawn(self, crew[1], _out(angle) * (WALK - 0.42) + Vector3(0, _floor1, 0), -angle))
	var bench := deg_to_rad(300.0)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.old, _out(bench) * 2.0 + Vector3(0, _floor0, 0), -bench)
	# Uno en el suelo: abajo de la boca del vórtice si está agachada; si no, al costado.
	var ground_at := Vector3(0.0, 0.0, 0.0) if _crouched else Vector3(OUTER + 1.6, 0.0, -1.2)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, ground_at, PI * 0.5 if _crouched else -PI * 0.6)
	await get_tree().create_timer(3.0).timeout
	var shots: Array = []
	var top := _floor1 + 1.0
	if _crouched:
		for view: Array in [
				["agachada: uno abajo de la boca del vórtice", Vector3(2.5, 1.4, 10.0), Vector3(0.0, 1.6, 0.0), 40.0],
				["agachada, de tres cuartos, atrás", Vector3(9.0, 6.0, 10.0), Vector3(0.0, 2.2, 0.0), 45.0]]:
			_title.text = view[0]
			_look(view[1], view[2], view[3])
			shots.append(await _grab())
		_save(shots, "vortice_agachada")
		get_tree().quit()
		return
	for view: Array in [
			["de tres cuartos, adelante", Vector3(-10.0, top + 3.0, -12.0), Vector3(0.0, top * 0.55, 0.0), 45.0],
			["el primer piso, desde arriba", Vector3(0.0, top + 11.0, 0.5), Vector3(0.0, _floor1, 0.0), 45.0],
			["el primer piso, desde la escalera", Vector3(-0.9, _floor1 + 1.65, 2.3), Vector3(0.6, _floor1 + 0.7, -2.5), 75.0]]:
		_title.text = view[0]
		_look(view[1], view[2], view[3])
		shots.append(await _grab())
	# La planta baja, en corte: sin el primer piso y con la pared medio transparente.
	_upper.visible = false
	for person in _upstairs:
		person.visible = false
	_wall_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_wall_paint.albedo_color = Color(METAL, 0.2)
	for view: Array in [
			["la planta baja, desde arriba (sin el primer piso)", Vector3(0.0, _floor0 + 10.0, 0.5),
				Vector3(0.0, _floor0, 0.0), 45.0],
			["la planta baja, de costado (la pared en corte)", Vector3(-8.0, _floor0 + 3.5, -5.0),
				Vector3(0.0, _floor0 + 1.0, 0.0), 45.0]]:
		_title.text = view[0]
		_look(view[1], view[2], view[3])
		shots.append(await _grab())
	_upper.visible = true
	for person in _upstairs:
		person.visible = true
	_wall_paint.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_wall_paint.albedo_color = METAL
	_title.text = "adentro de la planta baja"
	_look(_out(deg_to_rad(40.0)) * 1.8 + Vector3(0, _floor0 + 1.7, 0), _out(deg_to_rad(285.0)) * 2.2
		+ Vector3(0, _floor0 + 0.7, 0), 80.0)
	shots.append(await _grab())
	_save(shots, "vortice")
	get_tree().quit()


func _out(angle: float) -> Vector3:
	return Vector3(sin(angle), 0.0, -cos(angle))


## ── LA MECA ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	var bottom := _floor0 - SLAB
	var inner_wall := OUTER - WALL
	# La planta baja: el fondo y la pared (la pared se hace transparente en el corte) y el piso de adentro.
	_revolve(self, PackedVector2Array([Vector2(0.0, bottom), Vector2(OUTER - 0.15, bottom), Vector2(OUTER, bottom + 0.15),
		Vector2(OUTER, _floor1)]), _wall_paint)
	_revolve(self, PackedVector2Array([Vector2(inner_wall, _floor1 - SLAB), Vector2(inner_wall, _floor0)]), _wall_paint)
	_revolve(self, PackedVector2Array([Vector2(inner_wall, _floor0), Vector2(0.0, _floor0)]), _paint(LOW_FLOOR))
	_solid_disc(inner_wall, _floor0)
	# El primer piso: el borde con su bevel, la losa (con el hueco de la escalera) y el núcleo.
	_revolve(_upper, PackedVector2Array([Vector2(OUTER, _floor1), Vector2(OUTER, _floor1 + RIM_OUT),
		Vector2(WALK, _floor1 + RIM_IN), Vector2(WALK, _floor1)]), _paint(METAL))
	var hole_from := STAIR_FROM + (STAIR_TO - STAIR_FROM) * HOLE_FROM_STEP / STEPS
	_slab(0.0, STAIR_IN, 0.0, TAU)
	_slab(STAIR_IN, STAIR_OUT, STAIR_TO, hole_from + TAU)
	_slab(STAIR_OUT, inner_wall, 0.0, TAU)
	_revolve(_upper, PackedVector2Array([Vector2(STAIR_IN, _floor1), Vector2(STAIR_IN, _floor1 - SLAB)]), _paint(METAL),
		hole_from, STAIR_TO)
	_revolve(_upper, PackedVector2Array([Vector2(STAIR_OUT, _floor1 - SLAB), Vector2(STAIR_OUT, _floor1)]), _paint(METAL),
		hole_from, STAIR_TO)
	_solid_disc(WALK, _floor1)
	# La baranda del hueco, del lado de adentro.
	var posts := 8
	for i in posts + 1:
		var angle := lerpf(hole_from, STAIR_TO, float(i) / posts)
		Clay.cylinder(_upper, 0.03, 1.0, _out(angle) * (STAIR_IN + 0.05) + Vector3(0, _floor1 + 0.5, 0), DARK_METAL)
	_revolve(_upper, PackedVector2Array([Vector2(STAIR_IN + 0.08, _floor1 + 1.0), Vector2(STAIR_IN + 0.08, _floor1 + 0.94)]),
		_paint(DARK_METAL), hole_from, STAIR_TO)
	# El núcleo de arriba: opaco, con una tapa.
	_revolve(_upper, PackedVector2Array([Vector2(CORE, _floor1), Vector2(CORE, _floor1 + 1.9), Vector2(CORE - 0.15,
		_floor1 + 2.05), Vector2(0.0, _floor1 + 2.05)]), _paint(DARK_METAL.lightened(0.15)))
	# El vórtice: la boca acampanada abajo del disco y el tubo hasta el techo de la planta baja, con su puerta.
	_revolve(self, PackedVector2Array([Vector2(1.3, bottom - 0.3), Vector2(TUBE + 0.12, bottom - 0.05),
		Vector2(TUBE + 0.12, _floor1 - SLAB)]), _paint(VORTEX))
	_revolve(self, PackedVector2Array([Vector2(1.15, bottom - 0.3), Vector2(TUBE, bottom - 0.05)]),
		_paint(VORTEX.darkened(0.5)))
	# La corriente que chupa, del suelo a la boca: lo único que se ve a través (es aire).
	var pull := StandardMaterial3D.new()
	pull.albedo_color = Color(0.6, 0.5, 0.9, 0.18)
	pull.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pull.cull_mode = BaseMaterial3D.CULL_DISABLED
	pull.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_revolve(self, PackedVector2Array([Vector2(1.0, 0.02), Vector2(1.1, bottom - 0.3)]), pull)
	var door_at := deg_to_rad(330.0)
	var door := Clay.box(self, Vector3(0.75, 1.9, 0.06), _out(door_at) * (TUBE + 0.14) + Vector3(0, _floor0 + 0.95, 0),
		Color(0.12, 0.1, 0.16))
	door.rotation.y = -door_at
	# La escalera caracol, pegada a la pared.
	var rise := (_floor1 - _floor0) / STEPS
	var sweep := (STAIR_TO - STAIR_FROM) / STEPS
	for i in STEPS:
		var angle := STAIR_FROM + sweep * (i + 0.5)
		var middle := (STAIR_IN + STAIR_OUT) * 0.5
		var step := Clay.box(self, Vector3(middle * sweep + 0.06, 0.12, STAIR_OUT - STAIR_IN),
			_out(angle) * middle + Vector3(0, _floor0 + rise * (i + 1) - 0.06, 0), STAIR)
		step.rotation.y = -angle
		Clay.cylinder(self, 0.04, rise * (i + 1), _out(angle) * (STAIR_IN + 0.06) + Vector3(0, _floor0 + rise * (i + 1)
			* 0.5, 0), DARK_METAL)
	_lower_rooms()
	for station: Array in [[0.0, "drive"], [deg_to_rad(70.0), "arm"], [deg_to_rad(290.0), "arm"],
			[deg_to_rad(40.0), "gun"], [deg_to_rad(320.0), "gun"], [deg_to_rad(100.0), "socket"],
			[deg_to_rad(180.0), "socket"], [deg_to_rad(255.0), "socket"]]:
		_station(station[0], station[1])
	_body()


## LA PLANTA BAJA: la máquina adelante, el banco de reparación, el tablero de la energía y las cajas de municiones.
func _lower_rooms() -> void:
	var at := func(degrees: float, reach: float, y: float) -> Vector3:
		return _out(deg_to_rad(degrees)) * reach + Vector3(0, _floor0 + y, 0)
	# La máquina: un bloque con caños.
	var engine := Clay.box(self, Vector3(1.6, 1.5, 0.9), at.call(0.0, 2.35, 0.75), DARK_METAL.lightened(0.1))
	engine.rotation.y = 0.0
	for x: float in [-0.5, 0.0, 0.5]:
		Clay.cylinder(self, 0.08, 0.9, at.call(0.0, 2.35, 1.95) + Vector3(x, 0, 0), METAL)
	Clay.cylinder(self, 0.25, 0.4, at.call(0.0, 1.75, 0.9), RED, Vector3(90, 0, 0))
	# El banco de reparación, con piezas encima.
	var bench_at: Vector3 = at.call(300.0, 2.6, 0.45)
	var bench := Clay.box(self, Vector3(1.4, 0.9, 0.6), bench_at, Color(0.5, 0.42, 0.32))
	bench.rotation.y = -deg_to_rad(300.0)
	Clay.box(self, Vector3(0.3, 0.2, 0.3), bench_at + Vector3(0, 0.55, 0), METAL)
	Clay.cylinder(self, 0.1, 0.3, bench_at + Vector3(0.35, 0.6, 0.1), DARK_METAL)
	# El tablero de la energía, en la pared: tres palancas (piernas, brazos, armas).
	var panel_at: Vector3 = at.call(340.0, OUTER - WALL - 0.08, 1.3)
	var panel := Clay.box(self, Vector3(1.0, 0.9, 0.12), panel_at, DARK_METAL)
	panel.rotation.y = -deg_to_rad(340.0)
	for i in 3:
		var lever := Clay.cylinder(panel, 0.03, 0.4, Vector3((i - 1) * 0.3, 0.0, 0.22), YELLOW, Vector3(90, 0, 0))
		lever.position.y = (i - 1) * 0.12
	# Las municiones.
	for i in 4:
		var crate := Clay.box(self, Vector3(0.6, 0.45, 0.45), at.call(265.0 - i * 9.0, 2.55, 0.225 + (0.45 if i == 3 else 0.0)),
			AMMO)
		crate.rotation.y = -deg_to_rad(265.0 - i * 9.0)


## UN PUESTO del primer piso, en el borde: el manejo, los mandos de un brazo, una ametralladora en su enchufe, o un
## enchufe vacío.
func _station(angle: float, kind: String) -> void:
	var outward := _out(angle)
	if kind == "gun" or kind == "socket":
		Clay.box(_upper, Vector3(0.45, 0.06, 0.45), outward * (WALK + 0.32) + Vector3(0, _floor1 + RIM_OUT - 0.03, 0),
			YELLOW.darkened(0.3)).rotation.y = -angle
		if kind == "socket":
			return
		var gun := Node3D.new()
		gun.position = outward * (WALK + 0.32) + Vector3(0.0, _floor1 + RIM_OUT, 0.0)
		gun.rotation.y = -angle
		_upper.add_child(gun)
		Clay.cylinder(gun, 0.07, 0.3, Vector3(0.0, 0.15, 0.0), DARK_METAL)
		Clay.box(gun, Vector3(0.24, 0.24, 0.6), Vector3(0.0, 0.4, -0.05), DARK_METAL)
		Clay.cylinder(gun, 0.05, 0.85, Vector3(0.0, 0.42, -0.75), DARK_METAL, Vector3(90.0, 0.0, 0.0))
		Clay.box(gun, Vector3(0.5, 0.3, 0.04), Vector3(0.0, 0.5, -0.38), METAL)
		for side: float in [-1.0, 1.0]:
			Clay.cylinder(gun, 0.03, 0.2, Vector3(side * 0.13, 0.38, 0.3), YELLOW, Vector3(90.0, 0.0, 0.0))
		return
	var bevel := Vector2(OUTER - WALK, RIM_OUT - RIM_IN)
	var up := (Vector3.UP * bevel.x - outward * bevel.y).normalized()
	var along := Vector3(cos(angle), 0.0, sin(angle))
	var plate := Node3D.new()
	plate.basis = Basis(along, up, along.cross(up))
	plate.position = outward * (WALK + bevel.x * 0.5) + Vector3(0.0, _floor1 + (RIM_IN + RIM_OUT) * 0.5, 0.0)
	_upper.add_child(plate)
	match kind:
		"drive":
			for side: float in [-1.0, 1.0]:
				Clay.box(plate, Vector3(0.16, 0.06, 0.24), Vector3(side * 0.2, 0.03, 0.0), DARK_METAL)
				Clay.cylinder(plate, 0.025, 0.42, Vector3(side * 0.2, 0.24, 0.0), DARK_METAL)
				Clay.sphere(plate, 0.06, Vector3(side * 0.2, 0.46, 0.0), RED)
		"arm":
			Clay.box(plate, Vector3(0.7, 0.05, 0.3), Vector3(0.0, 0.025, 0.0), DARK_METAL)
			for side: float in [-1.0, 1.0]:
				Clay.cylinder(plate, 0.04, 0.3, Vector3(side * 0.22, 0.17, 0.0), DARK_METAL)
				Clay.box(plate, Vector3(0.1, 0.1, 0.18), Vector3(side * 0.22, 0.34, 0.0), RED)
			Clay.cylinder(plate, 0.13, 0.04, Vector3(0.0, 0.04, 0.0), FACE)


## EL CUERPO: las piernas de abajo del disco y los brazos del costado de la planta baja, gruesos.
func _body() -> void:
	var bottom := _floor0 - SLAB
	var k := 1.6
	var crouch := _crouched
	for side: float in [-1.0, 1.0]:
		var from := Vector3(side * OUTER * 0.45, bottom - 0.3 * k, 0.0)
		var foot := Vector3(side * OUTER * (0.75 if crouch else 0.52), 0.18 * k, 0.0)
		var knee := (from + foot) * 0.5 + Vector3(side * (0.9 if crouch else 0.0), 0.0, -(1.4 if crouch else 0.35) * k)
		Clay.sphere(self, 0.42 * k, from, DARK_METAL)
		_bar(from, knee, 0.32 * k, METAL)
		Clay.sphere(self, 0.3 * k, knee, DARK_METAL)
		_bar(knee, foot, 0.28 * k, METAL)
		Clay.box(self, Vector3(0.75 * k, 0.36 * k, 1.2 * k), foot + Vector3(0.0, 0.0, -0.2 * k), DARK_METAL)
		var shoulder := Vector3(side * (OUTER + 0.16 * k), _floor0 + 1.2, 0.0)
		var elbow := shoulder + Vector3(side * 0.35 * k, -minf(2.4, _floor0 + 0.6), 0.2 * k)
		var fist := elbow + Vector3(-side * 0.1 * k, 0.1 if crouch else -0.4, -0.8 * k)
		Clay.sphere(self, 0.36 * k, shoulder, DARK_METAL)
		_bar(shoulder, elbow, 0.26 * k, METAL)
		Clay.sphere(self, 0.26 * k, elbow, DARK_METAL)
		_bar(elbow, fist, 0.24 * k, METAL)
		Clay.box(self, Vector3(0.6, 0.6, 0.65) * k, fist, DARK_METAL)


## Una losa del primer piso, de `r0` a `r1`, entre dos ángulos.
func _slab(r0: float, r1: float, from: float, to: float) -> void:
	_revolve(_upper, PackedVector2Array([Vector2(r1, _floor1 - SLAB), Vector2(r1, _floor1), Vector2(r0, _floor1),
		Vector2(r0, _floor1 - SLAB), Vector2(r1, _floor1 - SLAB)]), _paint(DECK), from, to)


## Un piso de choque redondo de radio `radius`, con la cara de arriba en `y`.
func _solid_disc(radius: float, y: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 0.2
	shape.shape = cylinder
	shape.position.y = y - 0.1
	body.add_child(shape)
	add_child(body)


func _paint(color: Color) -> StandardMaterial3D:
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	return paint


## Un miembro de `a` a `b`.
func _bar(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var part := Clay.limb(self, radius, a.distance_to(b), (a + b) * 0.5, color)
	part.basis = Basis.looking_at(b - a, Vector3.RIGHT if absf((b - a).normalized().y) > 0.9 else Vector3.UP)


## UNA VUELTA (o un tramo, de `from` a `to`) de un perfil (`r`, `y`): suave alrededor, con aristas en el perfil.
func _revolve(parent: Node3D, profile: PackedVector2Array, paint: Material, from := 0.0, to := TAU) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := maxi(4, ceili(64.0 * (to - from) / TAU))
	for s in sides:
		var a0 := lerpf(from, to, float(s) / sides)
		var a1 := lerpf(from, to, float(s + 1) / sides)
		for p in profile.size() - 1:
			var p0 := profile[p]
			var p1 := profile[p + 1]
			var edge := p1 - p0
			var normal := Vector2(edge.y, -edge.x).normalized()
			var quad := [[p0, a0], [p1, a0], [p1, a1], [p0, a1]]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				var point: Vector2 = quad[corner][0]
				var out := _out(quad[corner][1])
				tool.set_normal(out * normal.x + Vector3.UP * normal.y)
				tool.add_vertex(out * point.x + Vector3.UP * point.y)
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
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
	_title.add_theme_font_size_override("font_size", 38)
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
