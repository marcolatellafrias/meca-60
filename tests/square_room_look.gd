extends Node3D

## LA MECA CUADRADA CON CUARTO COMÚN Y VÓRTICE, MAQUETA DE ARCILLA (15/11/2026; sigue la numeración de
## tests/square_niches_look). El usuario: «acceder desde abajo… ya en esta versión cuadrada me parece medio rebuscada,
## así que volvería a la idea del vórtice… vamos a tener que volver a hacer espacio interior… para poner los 7
## módulos… la parte de atrás va a quedar solamente para cosas de reparaciones… el vórtice te lleva al centro de la zona
## común… si estás adentro de una cabina y querés salir, salís del otro lado adentro… para bajar, un botón… subir, sólo
## por proximidad… una compuerta… que se abre de varios pedazos… como un círculo que se va abriendo».
##   · ADELANTE, las tres cabinas en fila (la pecera de la 45: vidrio al frente, entre ellas y a los costados de las de
##     afuera), cada una con su puerta atrás, al cuarto.
##   · EL CUARTO COMÚN, detrás: el vórtice en el medio del piso, con su compuerta IRIS (hojas que giran y abren un círculo
##     desde el centro; acá, a medio abrir); LOS 7 MÓDULOS en las paredes de los costados, a una altura; LAS
##     REPARACIONES en la pared de atrás (el banco, una pieza rota, el tablero de herramientas).
##   · ARRIBA, LA CÁPSULA del movimiento, sin pisar las cabinas: se sube del cuarto por una escalerita.
##   · Sin brazos (sólo los hombros), con las piernas al 45 % de las de hoy (la 63).
##   65 · la caja más honda (6 m): el cuarto entra entero, el domo arriba de su frente;
##   66 · las cabinas más chicas y la caja de 5 m;
##   67 · el domo sobre un cuello, fuera del cuarto: se sube por un hueco del techo.
## Cada hoja: de afuera; el plano (de arriba, sin techo); el corte (de costado, sin la pared de la izquierda); el cuarto
## desde atrás y arriba; desde el vórtice, recién llegado; y desde la cápsula de arriba.
##   tools/godot_ventana.sh res://tests/square_room_look.tscn -- --salida=C:/carpeta --variante=65

const VIEW := Vector2i(1280, 720)
## deep, tall: el fondo y el alto de la caja (m); cell: la cabina (ancho, alto, fondo); neck: el domo arriba del techo.
const VARIANTS := {
	65: {"name": "caja más honda, el domo arriba del cuarto", "deep": 6.0, "tall": 3.3, "cell": Vector3(1.4, 2.0, 1.6),
		"neck": false},
	66: {"name": "cabinas más chicas, caja de 5 m", "deep": 5.0, "tall": 3.2, "cell": Vector3(1.25, 1.8, 1.3),
		"neck": false},
	67: {"name": "el domo sobre un cuello, fuera del cuarto", "deep": 5.0, "tall": 3.0, "cell": Vector3(1.4, 2.0, 1.6),
		"neck": true},
	68: {"name": "la mochila con el succionador, sin domo", "deep": 4.6, "tall": 3.0, "cell": Vector3(1.4, 2.0, 1.6),
		"neck": false, "pack": true},
}
## LA MOCHILA (la 68): ancho, fondo y cuánto baja por debajo de la panza; las toberas, en la cara de atrás.
const PACK := Vector3(2.0, 0.0, 1.3)
const PACK_DROP := 1.2
const NOZZLE := 0.26
const GAP := 0.08
const SIDE := 0.12
const SILL := 0.45
const ROOF := 0.35
const WALL := 0.15
const POD := 0.9
const MODULE := 0.63
const MODULE_HEIGHT := 1.1
const VORTEX := 0.75
const BLADES := 8
const LIMBS := 0.45

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const FLOOR := Color(0.68, 0.69, 0.71)
const JOINT := Color(0.36, 0.375, 0.4)
const RIM := Color(0.22, 0.23, 0.25)
const SKIN := Color(0.86, 0.66, 0.5)
const SEAT := Color(0.25, 0.42, 0.7)
const VORTEX_COLOR := Color(0.45, 0.35, 0.65, 0.25)
const MODULE_COLORS := [Color(0.72, 0.42, 0.36), Color(0.72, 0.42, 0.36), Color(0.48, 0.5, 0.36),
	Color(0.36, 0.55, 0.38), Color(0.48, 0.5, 0.36), Color(0.72, 0.42, 0.36), Color(0.72, 0.42, 0.36)]

var _folder := ""
var _variant := 65
var _plan: Dictionary = {}
var _eye: Camera3D = null
var _title: Label = null
var _glass := StandardMaterial3D.new()
## Lo que se esconde en el plano (el techo y el domo) y en el corte (la pared de la izquierda y lo que va en ella).
var _roof: Array[Node3D] = []
var _left: Array[Node3D] = []
## Las medidas de la caja (se llenan en `_ready`).
var _cell := Vector3.ZERO
var _size := Vector3.ZERO
var _bottom := 0.0
## Dónde quedan las cosas para las vistas: el piso, el vórtice, el ojo del de arriba.
var _floor_y := 0.0
var _vortex_at := Vector3.ZERO
var _top_eye := Vector3.ZERO


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
	get_window().size = VIEW
	_plan = VARIANTS[_variant]
	_glass.albedo_color = Color(0.7, 0.85, 0.95, 0.18)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass.roughness = 0.1
	_stage()
	_cell = _plan["cell"]
	_size = Vector3(_cell.x * 3.0 + GAP * 2.0 + SIDE * 2.0, float(_plan["tall"]), float(_plan["deep"]))
	var body := MechBody.current
	var hip_line := (body.WAIST - body.HIP_DROP) * LIMBS
	_bottom = hip_line + 0.66
	_floor_y = _bottom + SILL
	_box()
	_legs(hip_line)
	print("CAJA ", _size, " · PANZA ", _bottom, " · PISO ", _floor_y, " · LIBRE ", _size.y - SILL - ROOF)
	await get_tree().create_timer(3.0).timeout
	var shots: Array = []
	var mid := _bottom + _size.y * 0.5
	_title.text = "%d. %s" % [_variant, _plan["name"]]
	shots.append(await _view(Vector3(-9.0, mid + 4.0, -12.0), Vector3(0.0, mid - 1.0, 0.0), 45.0))
	var pack: bool = _plan.get("pack", false)
	if pack:
		_title.text = "%d. de atrás: la mochila" % _variant
		shots.append(await _view(Vector3(9.0, mid + 3.0, 13.0), Vector3(0.0, mid - 1.2, 1.0), 45.0))
		_title.text = "%d. de abajo y atrás: la boca del succionador" % _variant
		shots.append(await _view(Vector3(4.0, 1.2, 9.0), Vector3(0.0, _bottom - 1.0, 2.5), 50.0))
	# EL PLANO: de arriba, sin techo ni domo, sin perspectiva.
	_show(_roof, false)
	_title.text = "%d. el plano (de arriba, sin techo)" % _variant
	shots.append(await _view(Vector3(0.0, mid + 30.0, 0.01), Vector3(0.0, mid, 0.0), 0.0, maxf(_size.z, _size.x) + 2.5))
	_show(_roof, true)
	# EL CORTE: de costado, sin la pared de la izquierda.
	_show(_left, false)
	_title.text = "%d. el corte (de costado, sin la pared izquierda)" % _variant
	var span := _size.z + (PACK.z if pack else 0.0)
	var aim := Vector3(0.0, mid - (0.6 if pack else -0.4), PACK.z * 0.5 if pack else 0.0)
	shots.append(await _view(aim + Vector3(-30.0, 0.0, 0.0), aim, 0.0, span + 2.5))
	_show(_left, true)
	# EL CUARTO desde atrás y arriba, sin techo.
	_show(_roof, false)
	_title.text = "%d. el cuarto, desde atrás (sin techo)" % _variant
	shots.append(await _view(Vector3(3.5, _floor_y + 6.5, _size.z * 0.5 + 4.0), Vector3(0.0, _floor_y, -0.3), 55.0))
	_show(_roof, true)
	if pack:
		_title.text = "%d. recién subido, desde la mochila" % _variant
		var arrived := Vector3(0.0, _floor_y + 1.62, _size.z * 0.5 + 0.35)
		shots.append(await _view(arrived, arrived + Vector3(0.0, -0.2, -1.0), 80.0))
	else:
		_title.text = "%d. desde el vórtice, recién llegado" % _variant
		var eye := _vortex_at + Vector3(0.0, 1.62, 0.3)
		shots.append(await _view(eye, eye + Vector3(0.0, -0.15, -1.0), 80.0))
		_title.text = "%d. desde la cápsula de arriba" % _variant
		shots.append(await _view(_top_eye, _top_eye + Vector3(0.0, -0.25, -1.0), 80.0))
	_save(shots)
	get_tree().quit()


## ── LA CAJA ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _box() -> void:
	var half := _size * 0.5
	var front := -half.z
	var back := half.z
	var top := _bottom + _size.y
	var ceiling := top - ROOF
	var row := _cell.x * 3.0 + GAP * 2.0
	var cells_back := front + _cell.z
	# El piso (la losa de abajo) y el techo.
	# El piso es sólido: la gente del cuarto se para en él.
	var slab := StaticBody3D.new()
	Clay.solid(slab, Vector3(_size.x, SILL, _size.z), Vector3(0.0, _bottom + SILL * 0.5, 0.0), METAL)
	add_child(slab)
	Clay.box(self, Vector3(_size.x - 0.02, 0.04, _size.z - 0.02), Vector3(0.0, _floor_y + 0.02, 0.0), FLOOR)
	_roof.append(Clay.box(self, Vector3(_size.x, ROOF, _size.z), Vector3(0.0, top - ROOF * 0.5, 0.0), METAL))
	# Sobre las cabinas, hasta el techo: el dintel de adelante.
	var header := ceiling - (_floor_y + _cell.y)
	if header > 0.01:
		Clay.box(self, Vector3(_size.x, header, _cell.z), Vector3(0.0, _floor_y + _cell.y + header * 0.5,
			front + _cell.z * 0.5), METAL)
	# LAS TRES CABINAS: vidrio al frente, entre ellas y a los costados de las de afuera; atrás, su pared con la puerta.
	var names := ["brazo izquierdo", "artillero", "brazo derecho"]
	for index in 3:
		var x := (index - 1) * (_cell.x + GAP)
		_cabin(Vector3(x, _floor_y, front), index)
	_pane(Vector3(row, _cell.y, 0.04), Vector3(0.0, _floor_y + _cell.y * 0.5, front + 0.02))
	for s: float in [-1.0, 1.0]:
		_pane(Vector3(0.05, _cell.y, _cell.z), Vector3(s * (_cell.x + GAP) * 0.5, _floor_y + _cell.y * 0.5,
			front + _cell.z * 0.5))
		var side_glass := _pane(Vector3(0.04, _cell.y, _cell.z), Vector3(s * (half.x - 0.02), _floor_y + _cell.y * 0.5,
			front + _cell.z * 0.5))
		for z: float in [0.06, _cell.z - 0.06]:
			var post := Clay.box(self, Vector3(SIDE, _cell.y, 0.12), Vector3(s * (row + SIDE) * 0.5,
				_floor_y + _cell.y * 0.5, front + z), METAL)
			if s < 0.0:
				_left.append(post)
		if s < 0.0:
			_left.append(side_glass)
	var _unused := names
	# LAS PAREDES DEL CUARTO: los costados (la de la izquierda se esconde en el corte) y la de atrás.
	var room := back - cells_back
	var wall_tall := ceiling - _floor_y
	for s: float in [-1.0, 1.0]:
		var wall := Clay.box(self, Vector3(WALL, wall_tall, room), Vector3(s * (half.x - WALL * 0.5),
			_floor_y + wall_tall * 0.5, cells_back + room * 0.5), METAL)
		if s < 0.0:
			_left.append(wall)
		# El hombro, en el medio del costado del cuarto (sin brazo).
		var radius := 2.1 * LIMBS * 0.78 * 1.3
		var shoulder := Clay.sphere(self, radius, Vector3(s * (half.x + radius * 0.75), _floor_y + wall_tall * 0.6,
			cells_back + room * 0.45), JOINT)
		if s < 0.0:
			_left.append(shoulder)
	var pack: bool = _plan.get("pack", false)
	if pack:
		# La pared de atrás con el paso a la mochila: el cuarto sigue derecho y ahí se quiebra hacia abajo.
		var door := PACK.x - WALL * 2.0
		var jamb := (_size.x - door) * 0.5
		for s: float in [-1.0, 1.0]:
			var piece := Clay.box(self, Vector3(jamb, wall_tall, WALL), Vector3(s * (door + jamb) * 0.5,
				_floor_y + wall_tall * 0.5, back - WALL * 0.5), METAL)
			if s < 0.0:
				_left.append(piece)
		Clay.box(self, Vector3(door, wall_tall - 2.3, WALL), Vector3(0.0, _floor_y + 2.3 + (wall_tall - 2.3) * 0.5,
			back - WALL * 0.5), METAL)
		_pack(back, top)
		_modules(cells_back, back, 3, 3)
		PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(-1.1, _floor_y + 0.04, back - 1.3), PI * 0.8)
		PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(half.x - 1.2, _floor_y + 0.04,
			lerpf(cells_back + 0.4, back - 0.4, 0.5)), -PI * 0.5)
		return
	Clay.box(self, Vector3(_size.x, wall_tall, WALL), Vector3(0.0, _floor_y + wall_tall * 0.5, back - WALL * 0.5), METAL)
	# LOS 7 MÓDULOS: en las paredes de los costados, a una altura (4 a la izquierda, 3 a la derecha).
	var spots: Array = []
	for i in 4:
		spots.append([-1.0, lerpf(cells_back + 0.6, back - 0.9, (i + 0.5) / 4.0)])
	for i in 3:
		spots.append([1.0, lerpf(cells_back + 0.6, back - 0.9, (i + 0.5) / 3.0)])
	for i in spots.size():
		var s: float = spots[i][0]
		var z: float = spots[i][1]
		var at := Vector3(s * (half.x - WALL - MODULE * 0.5 + 0.05), _floor_y + MODULE_HEIGHT, z)
		var cube := Clay.box(self, Vector3.ONE * MODULE, at, MODULE_COLORS[i])
		var socket := Clay.box(self, Vector3(0.06, MODULE + 0.16, MODULE + 0.16), Vector3(s * (half.x - WALL - 0.03),
			at.y, z), RIM)
		if s < 0.0:
			_left.append(cube)
			_left.append(socket)
	# LAS REPARACIONES, en la pared de atrás: el banco, una pieza rota encima y el tablero de herramientas.
	Clay.box(self, Vector3(2.4, 0.9, 0.7), Vector3(0.0, _floor_y + 0.45, back - WALL - 0.35), DARK_METAL)
	var broken := Clay.box(self, Vector3(0.6, 0.35, 0.45), Vector3(-0.4, _floor_y + 1.08, back - WALL - 0.4),
		Color(0.62, 0.5, 0.36))
	broken.rotation_degrees = Vector3(0.0, 20.0, 12.0)
	Clay.box(self, Vector3(2.2, 1.0, 0.05), Vector3(0.0, _floor_y + 1.75, back - WALL - 0.03), Color(0.5, 0.42, 0.32))
	for i in 5:
		Clay.box(self, Vector3(0.06, 0.4, 0.04), Vector3(-0.8 + i * 0.4, _floor_y + 1.75, back - WALL - 0.07), RIM)
	# EL VÓRTICE, en el medio del cuarto: el iris en el piso, el tubo por la losa y la columna hasta el suelo.
	_vortex_at = Vector3(0.0, _floor_y, cells_back + room * 0.55)
	_iris(_vortex_at)
	Clay.cylinder(self, VORTEX + 0.08, SILL, Vector3(_vortex_at.x, _bottom + SILL * 0.5, _vortex_at.z), RIM)
	var column := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = VORTEX
	shaft.bottom_radius = VORTEX * 1.3
	shaft.height = _bottom
	column.mesh = shaft
	var swirl := StandardMaterial3D.new()
	swirl.albedo_color = VORTEX_COLOR
	swirl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	swirl.cull_mode = BaseMaterial3D.CULL_DISABLED
	column.material_override = swirl
	column.position = Vector3(_vortex_at.x, _bottom * 0.5, _vortex_at.z)
	add_child(column)
	# LA GENTE DEL CUARTO: uno recién llegado al lado del vórtice, otro en el banco, otro en los módulos.
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, _vortex_at + Vector3(1.0, 0.04, 0.3), PI)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(0.6, _floor_y + 0.04, back - WALL - 1.0), 0.0)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(half.x - 1.2, _floor_y + 0.04,
		spots[5][1]), -PI * 0.5)
	# LA CÁPSULA DE ARRIBA.
	_dome(Vector3(0.0, top, cells_back + 0.6 if not _plan["neck"] else cells_back + 0.9))


## LA MOCHILA, pegada atrás: un cajón que va del techo hasta más abajo de la panza, abierto abajo (la boca del
## succionador, sin piezas que se muevan). Adentro, la columna que chupa hasta el nivel del piso del cuarto; en la cara
## de atrás, las cuatro toberas apuntando hacia atrás.
func _pack(back: float, top: float) -> void:
	var low := _bottom - PACK_DROP
	var high := top - 0.15
	var tall := high - low
	var z := back + PACK.z * 0.5
	for s: float in [-1.0, 1.0]:
		var side := Clay.box(self, Vector3(WALL, tall, PACK.z), Vector3(s * (PACK.x - WALL) * 0.5, low + tall * 0.5, z),
			METAL)
		if s < 0.0:
			_left.append(side)
	Clay.box(self, Vector3(PACK.x, tall, WALL), Vector3(0.0, low + tall * 0.5, back + PACK.z - WALL * 0.5), METAL)
	# Adelante, por debajo de la caja, la mochila se cierra contra la panza.
	Clay.box(self, Vector3(PACK.x, _bottom - low, WALL), Vector3(0.0, low + (_bottom - low) * 0.5, back + WALL * 0.5),
		METAL)
	_roof.append(Clay.box(self, Vector3(PACK.x, WALL, PACK.z), Vector3(0.0, high - WALL * 0.5, z), METAL))
	# La boca de abajo: un marco oscuro.
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(PACK.x + 0.1, 0.12, 0.1), Vector3(0.0, low + 0.06, z + s * (PACK.z * 0.5)), RIM)
		var post := Clay.box(self, Vector3(0.1, 0.12, PACK.z + 0.1), Vector3(s * PACK.x * 0.5, low + 0.06, z), RIM)
		if s < 0.0:
			_left.append(post)
	# El succionador: la columna que chupa, del suelo hasta el piso del cuarto.
	var column := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = (PACK.z - WALL * 2.0) * 0.48
	shaft.bottom_radius = shaft.top_radius * 1.3
	shaft.height = _floor_y
	column.mesh = shaft
	var swirl := StandardMaterial3D.new()
	swirl.albedo_color = VORTEX_COLOR
	swirl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	swirl.cull_mode = BaseMaterial3D.CULL_DISABLED
	column.material_override = swirl
	column.position = Vector3(0.0, _floor_y * 0.5, z)
	add_child(column)
	# Las toberas: cuatro, en la cara de atrás, apuntando hacia atrás.
	for x: float in [-0.5, 0.5]:
		for y: float in [high - 0.55, high - 1.45]:
			var at := Vector3(x, y, back + PACK.z)
			Clay.cylinder(self, NOZZLE * 1.15, 0.12, at + Vector3(0.0, 0.0, 0.06), RIM, Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(self, NOZZLE, 0.45, at + Vector3(0.0, 0.0, 0.3), DARK_METAL, Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(self, NOZZLE * 0.7, 0.04, at + Vector3(0.0, 0.0, 0.54), Color(0.08, 0.08, 0.09),
				Vector3(90.0, 0.0, 0.0))


## LOS MÓDULOS, en las paredes de los costados, a una altura: `left` a la izquierda y `right` a la derecha.
func _modules(from: float, to: float, left: int, right: int) -> void:
	var half_x := _size.x * 0.5
	for side: float in [-1.0, 1.0]:
		var count := left if side < 0.0 else right
		for i in count:
			var z := lerpf(from + 0.3, to - 0.3, (i + 0.5) / count)
			var at := Vector3(side * (half_x - WALL - MODULE * 0.5 + 0.05), _floor_y + MODULE_HEIGHT, z)
			var cube := Clay.box(self, Vector3.ONE * MODULE, at, MODULE_COLORS[(i + (0 if side < 0.0 else 3)) % 7])
			var socket := Clay.box(self, Vector3(0.06, MODULE + 0.16, MODULE + 0.16), Vector3(side * (half_x - WALL - 0.03),
				at.y, z), RIM)
			if side < 0.0:
				_left.append(cube)
				_left.append(socket)


## UNA CABINA: el piso oscuro, la silla y el piloto mirando al frente, el tablero, y atrás su pared con la puerta.
func _cabin(at: Vector3, index: int) -> void:
	var seat_at := at + Vector3(0.0, 0.0, _cell.z * 0.55)
	_seated(seat_at)
	Clay.box(self, Vector3(_cell.x * 0.7, 0.1, 0.35), seat_at + Vector3(0.0, 0.75, -0.6), RIM)
	# Atrás: la pared con la puerta (un hueco de 0,7 m al medio).
	var back := at.z + _cell.z
	var door := 0.7
	var side := (_cell.x - door) * 0.5
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(side, _cell.y, 0.08), Vector3(at.x + s * (door + side) * 0.5, at.y + _cell.y * 0.5, back),
			DARK_METAL)
	Clay.box(self, Vector3(door, 0.3, 0.08), Vector3(at.x, at.y + _cell.y - 0.15, back), DARK_METAL)
	var _unused := index


## LA COMPUERTA IRIS del vórtice: un aro y `BLADES` hojas que giran sobre el borde y dejan un círculo en el medio (acá,
## a medio abrir).
func _iris(at: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = VORTEX
	torus.outer_radius = VORTEX + 0.12
	ring.mesh = torus
	ring.material_override = Clay.material(RIM)
	ring.position = at + Vector3(0.0, 0.04, 0.0)
	add_child(ring)
	var open := VORTEX * 0.45
	for i in BLADES:
		var angle := TAU * i / BLADES
		var blade := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(VORTEX * 0.95, 0.03, VORTEX - open + 0.25)
		blade.mesh = mesh
		blade.material_override = Clay.material(DARK_METAL if i % 2 == 0 else METAL)
		var out := Vector3(sin(angle), 0.0, cos(angle))
		blade.position = at + Vector3(0.0, 0.05 + 0.005 * i, 0.0) + out * (open + (VORTEX - open) * 0.5 + 0.08)
		blade.basis = Basis(Vector3.UP, angle + 0.45)
		add_child(blade)


## LA CÁPSULA DE ARRIBA: la esfera opaca con la mitad de afuera de vidrio (PodCabin.capsule), su aro, el piloto y cómo
## se sube del cuarto: una escalerita (o, sobre un cuello, por un hueco del techo).
func _dome(at: Vector3) -> void:
	var center := at
	if _plan["neck"]:
		center = at + Vector3(0.0, POD * 0.85, 0.0)
		var neck := Clay.cylinder(self, POD * 0.7, POD * 0.9, at + Vector3(0.0, POD * 0.4, 0.0), DARK_METAL)
		_roof.append(neck)
	var shell := MeshInstance3D.new()
	shell.mesh = PodCabin.capsule(POD, 95.0)
	shell.position = center
	add_child(shell)
	_roof.append(shell)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = POD + 0.02
	torus.outer_radius = POD + 0.16
	ring.mesh = torus
	ring.material_override = Clay.material(RIM)
	ring.position = center
	add_child(ring)
	_roof.append(ring)
	var floor_at := center + Vector3(0.0, -POD * 0.8, 0.0)
	var pilot := Node3D.new()
	add_child(pilot)
	_seated(floor_at + Vector3(0.0, 0.0, 0.15), pilot)
	_roof.append(pilot)
	_top_eye = floor_at + Vector3(0.0, 1.2, -0.1)
	# La escalerita: del piso del cuarto hasta el piso de la cápsula, atrás de ella.
	var foot := Vector3(center.x, _floor_y, center.z + POD * 0.6)
	var high := floor_at.y
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.05, high - _floor_y, 0.05), Vector3(s * 0.25, (_floor_y + high) * 0.5, foot.z), RIM)
	var rungs := int((high - _floor_y) / 0.3)
	for i in rungs:
		Clay.box(self, Vector3(0.5, 0.04, 0.04), Vector3(0.0, _floor_y + 0.3 * (i + 1), foot.z), RIM)


## Un paño de vidrio, una caja finita.
func _pane(size: Vector3, at: Vector3) -> MeshInstance3D:
	var pane := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	pane.mesh = mesh
	pane.material_override = _glass
	pane.position = at
	add_child(pane)
	return pane


## UN PILOTO SENTADO, de arcilla, mirando adelante (−Z), con su asiento: `at`, el piso debajo del asiento.
func _seated(at: Vector3, parent: Node3D = self) -> void:
	Clay.box(parent, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(parent, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), SEAT)
	Clay.box(parent, Vector3(0.08, 0.42, 0.08), at + Vector3(0.0, 0.21, 0.05), DARK_METAL)
	Clay.box(parent, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(parent, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(parent, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(parent, Vector3(0.12, 0.42, 0.12), at + Vector3(side * 0.1, 0.27, -0.28), SKIN)
		Clay.box(parent, Vector3(0.1, 0.1, 0.38), at + Vector3(side * 0.24, 0.8, -0.12), SKIN)


## LAS PIERNAS (al 45 % de las de hoy): la pelvis (un tubo), la columna a la caja, las caderas, la rodilla adelante, el
## pie.
func _legs(hip_y: float) -> void:
	var body := MechBody.current
	var thick := body.LEG_THICKNESS * LIMBS
	var hip_x := body.HIP_X * LIMBS
	var thigh := body.THIGH * LIMBS
	var foot := body.FOOT_SIZE * LIMBS
	Clay.cylinder(self, thick * 0.43, hip_x * 2.0, Vector3(0.0, hip_y, 0.0), JOINT, Vector3(0.0, 0.0, 90.0))
	Clay.cylinder(self, thick * 0.48, _bottom - hip_y + 0.2, Vector3(0.0, (_bottom + hip_y) * 0.5, 0.0), JOINT)
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

func _show(parts: Array[Node3D], on: bool) -> void:
	for part in parts:
		part.visible = on


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
	var path := "%s/cuarto_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)
