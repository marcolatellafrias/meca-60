extends Node3D

## LA MECA POR MÓDULOS, MAQUETA DE ARCILLA (16/11/2026; sigue la numeración de tests/square_room_look). El usuario:
## «4 tipos de módulos… se conectan entre sí… el lobby, que es rectangular… el de control general… una forma de ver a
## su alrededor… arriba de los otros… la de artillería… la del brazo… más a los costados… desde la pared lateral… salen
## los brazos… desde el lobby se tiene que poder entrar a todas las zonas… el que maneja la locomoción tiene que ir al
## medio, y el de la artillería también… posición escalonada… el módulo del artillero es más largo que el módulo de
## cabeza, y va abajo… si hay una meca de 2… el módulo de artillero… y los dos brazos… no va a tener los hombros
## ensanchados… empecemos… la de 2 y la de 4».
##   · EL ARTILLERO, al medio y abajo, el más largo: asoma adelante de la cabeza (el escalón).
##   · LA CABEZA, arriba del artillero, vidriada de los cuatro lados; se sube del lobby por una escalera y una tapa.
##   · LOS BRAZOS (sólo con 4): a los costados del artillero, con vidrio entre ellos; el brazo sale de su pared de afuera.
##   · EL LOBBY, atrás, abierto a todos; tres módulos de recursos por pared; al fondo, la mochila con el succionador.
##   69 · 4 jugadores, la cabeza sobre la cola del artillero;   70 · 4 jugadores, la cabeza sobre el lobby (más escalón);
##   71 · 2 jugadores, como la 69;                              72 · 2 jugadores, como la 70.
##   tools/godot_ventana.sh res://tests/modules_look.tscn -- --salida=C:/carpeta --variante=69

const VIEW := Vector2i(1280, 720)
## arms: si hay módulos de brazo; head: dónde empieza la cabeza (z, adelante es −z); arm_front: hasta dónde llegan
## adelante los módulos de brazo.
const VARIANTS := {
	69: {"name": "4 jugadores, la cabeza sobre la cola del artillero", "arms": true, "head": -1.6, "arm_front": -1.8},
	70: {"name": "4 jugadores, la cabeza sobre el lobby", "arms": true, "head": 0.3, "arm_front": -2.2},
	71: {"name": "2 jugadores, la cabeza sobre la cola del artillero", "arms": false, "head": -1.6, "arm_front": 0.0},
	72: {"name": "2 jugadores, la cabeza sobre el lobby", "arms": false, "head": 0.3, "arm_front": 0.0},
	73: {"name": "bloqueo de 4", "block": true},
	74: {"name": "bloqueo de 4, con la gente adentro", "block": true, "hollow": true},
	75: {"name": "hacia un cubo, piernas y brazos al 55 %", "cube": true, "limbs": 0.55},
	76: {"name": "hacia un cubo, piernas y brazos al 65 %", "cube": true, "limbs": 0.65},
	77: {"name": "hacia un cubo, piernas y brazos al 75 %", "cube": true, "limbs": 0.75},
}
## Las medidas de los módulos (m): el ancho del artillero y de cada brazo, el largo del artillero, la cabeza (largo,
## alto), el alto de los de abajo, el lobby (largo) y lo que asoma a los costados del artillero cuando no hay brazos.
const GUNNER_WIDTH := 1.6
const GUNNER_LONG := 3.0
const ARM_WIDTH := 1.5
const HEAD_LONG := 2.2
const HEAD_TALL := 1.7
const TALL := 2.0
const LOBBY_LONG := 3.2
const NARROW_SIDE := 0.5
const SILL := 0.4
const ROOF := 0.15
const WALL := 0.12
const HATCH := 0.8
const MODULE := 0.63
const MODULE_HEIGHT := 1.1
const PACK := Vector3(2.0, 0.0, 1.3)
const PACK_DROP := 1.2
const NOZZLE := 0.26
var _limbs := 0.45

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const FLOOR := Color(0.68, 0.69, 0.71)
const JOINT := Color(0.36, 0.375, 0.4)
const RIM := Color(0.22, 0.23, 0.25)
const SKIN := Color(0.86, 0.66, 0.5)
const SEAT := Color(0.25, 0.42, 0.7)
const SUCTION := Color(0.45, 0.35, 0.65, 0.25)
## Los colores de cada módulo, en el piso, para que se lean en el plano.
const GUNNER_COLOR := Color(0.72, 0.5, 0.4)
const HEAD_COLOR := Color(0.45, 0.6, 0.75)
const ARM_COLOR := Color(0.55, 0.65, 0.45)
const MODULE_COLORS := [Color(0.72, 0.42, 0.36), Color(0.48, 0.5, 0.36), Color(0.36, 0.55, 0.38),
	Color(0.72, 0.42, 0.36), Color(0.48, 0.5, 0.36), Color(0.36, 0.55, 0.38)]

var _folder := ""
var _variant := 69
var _plan: Dictionary = {}
var _eye: Camera3D = null
var _title: Label = null
var _glass := StandardMaterial3D.new()
## Lo que se esconde en el plano (techos y la cabeza) y en el corte (lo de la mitad izquierda).
var _roof: Array[Node3D] = []
var _left: Array[Node3D] = []
var _bottom := 0.0
var _floor_y := 0.0
var _head_eye := Vector3.ZERO


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
	_limbs = float(_plan.get("limbs", _limbs))
	var body := MechBody.current
	var hip_line := (body.WAIST - body.HIP_DROP) * _limbs
	_bottom = hip_line + 0.66
	_floor_y = _bottom + SILL
	if _plan.get("cube", false):
		await _cube_blockout(hip_line)
		return
	if _plan.get("hollow", false):
		await _hollow_blockout(hip_line)
		return
	if _plan.get("block", false):
		await _blockout(hip_line)
		return
	_build()
	_legs(hip_line, 0.6)
	await get_tree().create_timer(3.0).timeout
	var shots: Array = []
	var mid := _floor_y + 1.0
	_title.text = "%d. %s" % [_variant, _plan["name"]]
	shots.append(await _view(Vector3(-10.0, mid + 4.5, -12.0), Vector3(0.0, mid - 1.2, 0.0), 45.0))
	_title.text = "%d. de atrás" % _variant
	shots.append(await _view(Vector3(10.0, mid + 3.5, 13.0), Vector3(0.0, mid - 1.2, 0.5), 45.0))
	_show(_left, false)
	_title.text = "%d. el corte (de costado, sin la mitad izquierda)" % _variant
	var aim := Vector3(0.0, mid - 0.2, 0.9)
	shots.append(await _view(aim + Vector3(-30.0, 0.0, 0.0), aim, 0.0, 9.5))
	_show(_left, true)
	_show(_roof, false)
	_title.text = "%d. el plano (de arriba, sin techos ni cabeza)" % _variant
	var top := Vector3(0.0, mid, 0.9)
	shots.append(await _view(top + Vector3(0.0, 30.0, 0.01), top, 0.0, 10.0))
	_show(_roof, true)
	_title.text = "%d. desde el fondo del lobby" % _variant
	var lobby_half := GUNNER_WIDTH * 0.5 + (ARM_WIDTH if _plan["arms"] else NARROW_SIDE)
	var lobby_eye := Vector3(lobby_half - 0.4, _floor_y + 1.62, LOBBY_LONG - 0.3)
	shots.append(await _view(lobby_eye, Vector3(0.0, _floor_y + 1.2, -3.0), 80.0))
	_title.text = "%d. desde la cabeza" % _variant
	shots.append(await _view(_head_eye, _head_eye + Vector3(0.0, -0.12, -1.0), 80.0))
	_save(shots)
	get_tree().quit()


## ── EL BLOQUEO (la 73) ─────────────────────────────────────────────────────────────────────────────────────────
## El usuario (16/11): «un bloqueo… sin vidrieras, solo los módulos (cada uno con un color distinto)… la de 4… el
## vestíbulo es más angosto… sin contar el ancho de los hombros… la cabeza… más atrás, que no esté arriba de
## artillería… artillería… más corta pero más ancha… 2 personas una al lado de la otra… (mismo ancho de vestíbulo)… los
## brazos se acceden desde las paredes laterales del vestíbulo… mostrame piernas y brazos».
## Cajas macizas: ARTILLERÍA adelante, del ancho del vestíbulo y corta; el VESTÍBULO detrás; los BRAZOS pegados a sus
## costados (se entra por sus paredes), con el brazo saliendo de afuera; la CABEZA arriba de la parte de atrás del
## vestíbulo; la MOCHILA al fondo.
const BLOCK_WIDTH := 2.6
const BLOCK_GUNNER_LONG := 1.8
const BLOCK_LOBBY_LONG := 3.4
const BLOCK_ARM := Vector2(1.5, 1.8)
const BLOCK_HEAD := Vector2(1.6, 2.0)
const BLOCK_GUNNER_COLOR := Color(0.85, 0.5, 0.3)
const BLOCK_LOBBY_COLOR := Color(0.7, 0.7, 0.66)
const BLOCK_ARM_COLOR := Color(0.45, 0.7, 0.4)
const BLOCK_HEAD_COLOR := Color(0.4, 0.6, 0.85)
const BLOCK_PACK_COLOR := Color(0.55, 0.42, 0.7)


func _blockout(hip_line: float) -> void:
	var top := _floor_y + TALL + ROOF
	var tall := top - _bottom
	var mid_y := _bottom + tall * 0.5
	var half := BLOCK_WIDTH * 0.5
	Clay.box(self, Vector3(BLOCK_WIDTH, tall, BLOCK_GUNNER_LONG), Vector3(0.0, mid_y, -BLOCK_GUNNER_LONG * 0.5),
		BLOCK_GUNNER_COLOR)
	Clay.box(self, Vector3(BLOCK_WIDTH, tall, BLOCK_LOBBY_LONG), Vector3(0.0, mid_y, BLOCK_LOBBY_LONG * 0.5),
		BLOCK_LOBBY_COLOR)
	var arm_z := BLOCK_LOBBY_LONG * 0.5
	for s: float in [-1.0, 1.0]:
		var x := s * (half + BLOCK_ARM.x * 0.5)
		Clay.box(self, Vector3(BLOCK_ARM.x, tall, BLOCK_ARM.y), Vector3(x, mid_y, arm_z), BLOCK_ARM_COLOR)
		_arm(Vector3(s * (half + BLOCK_ARM.x + 0.35), _floor_y + 1.3, arm_z), s)
	var head_tall := HEAD_TALL + ROOF
	Clay.box(self, Vector3(BLOCK_HEAD.x, head_tall, BLOCK_HEAD.y), Vector3(0.0, top + head_tall * 0.5,
		BLOCK_LOBBY_LONG - BLOCK_HEAD.y * 0.5), BLOCK_HEAD_COLOR)
	var low := _bottom - PACK_DROP
	Clay.box(self, Vector3(PACK.x, top - low, PACK.z), Vector3(0.0, (top + low) * 0.5, BLOCK_LOBBY_LONG + PACK.z * 0.5),
		BLOCK_PACK_COLOR)
	for x: float in [-0.5, 0.5]:
		for y: float in [top - 0.55, top - 1.4]:
			Clay.cylinder(self, NOZZLE, 0.45, Vector3(x, y, BLOCK_LOBBY_LONG + PACK.z + 0.22), DARK_METAL,
				Vector3(90.0, 0.0, 0.0))
	var hip_z := (-BLOCK_GUNNER_LONG + BLOCK_LOBBY_LONG + PACK.z) * 0.5
	_legs(hip_line, hip_z)
	# Una persona al lado, para la escala.
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(-4.5, 0.05, -1.5), 0.0)
	await get_tree().create_timer(3.0).timeout
	var shots: Array = []
	var aim := Vector3(0.0, _bottom, 1.0)
	_title.text = "%d. %s" % [_variant, _plan["name"]]
	shots.append(await _view(aim + Vector3(-10.0, 6.0, -12.0), aim + Vector3(0.0, -0.8, 0.0), 45.0))
	_title.text = "%d. de atrás" % _variant
	shots.append(await _view(aim + Vector3(10.0, 5.0, 13.0), aim + Vector3(0.0, -0.8, 0.0), 45.0))
	_title.text = "%d. de costado" % _variant
	shots.append(await _view(aim + Vector3(-30.0, -0.5, 0.0), aim + Vector3(0.0, -0.5, 0.0), 0.0, 10.0))
	_title.text = "%d. de frente" % _variant
	shots.append(await _view(aim + Vector3(0.0, -0.5, -30.0), aim + Vector3(0.0, -0.5, 0.0), 0.0, 10.0))
	_title.text = "%d. de arriba" % _variant
	shots.append(await _view(aim + Vector3(0.0, 30.0, 0.01), aim, 0.0, 11.0))
	_title.text = "%d. de abajo y adelante" % _variant
	shots.append(await _view(aim + Vector3(-5.0, -3.5, -9.0), aim + Vector3(0.0, 0.5, 0.0), 55.0))
	_save(shots)
	get_tree().quit()


## ── EL BLOQUEO HUECO (la 74) ───────────────────────────────────────────────────────────────────────────────────
## El usuario: «mostrame personas usando los módulos, la escala no me es suficiente con el tipo al lado, no sé cómo lo
## visualizarías sin poner cristales». Los mismos módulos de la 73, pero huecos, con paredes del color de cada uno, y se
## miran EN CORTE: sin techos, sin la mitad izquierda, sin las paredes de adelante. Adentro: los dos asientos de
## artillería (uno ocupado), uno por brazo, el de la cabeza, y gente parada en el vestíbulo; los pasos son huecos en las
## paredes (artillería y los brazos, al vestíbulo; la cabeza, por una tapa y una escalera).
const DOOR := 0.9
var _front: Array[Node3D] = []
var _head_parts: Array[Node3D] = []


func _hollow_blockout(hip_line: float) -> void:
	var half := BLOCK_WIDTH * 0.5
	var top := _floor_y + TALL + ROOF
	var arm_z := BLOCK_LOBBY_LONG * 0.5
	var head_from := BLOCK_LOBBY_LONG - BLOCK_HEAD.y
	var hatch := Rect2(-HATCH * 0.5, head_from + 1.2, HATCH, HATCH)
	# ARTILLERÍA: atrás, una puerta al vestíbulo.
	_shell(0.0, -BLOCK_GUNNER_LONG, 0.0, BLOCK_WIDTH, _floor_y, TALL, BLOCK_GUNNER_COLOR, {"back": "door"}, false,
		Rect2())
	for x: float in [-0.62, 0.62]:
		_chair(Vector3(x, _floor_y, -BLOCK_GUNNER_LONG + 0.95), x < 0.0)
	# EL VESTÍBULO: abierto adelante a artillería, puertas a los brazos y a la mochila; la tapa de la cabeza arriba.
	_shell(0.0, 0.0, BLOCK_LOBBY_LONG, BLOCK_WIDTH, _floor_y, TALL, BLOCK_LOBBY_COLOR,
		{"front": "none", "left": "door", "right": "door", "back": "door"}, false, hatch)
	# LOS BRAZOS: su pared de adentro es la puerta del vestíbulo; el brazo sale de la de afuera.
	for s: float in [-1.0, 1.0]:
		var x := s * (half + BLOCK_ARM.x * 0.5)
		var open := {"right": "none"} if s < 0.0 else {"left": "none"}
		_shell(x, arm_z - BLOCK_ARM.y * 0.5, arm_z + BLOCK_ARM.y * 0.5, BLOCK_ARM.x, _floor_y, TALL, BLOCK_ARM_COLOR,
			open, s < 0.0, Rect2())
		var pilot := Node3D.new()
		add_child(pilot)
		_seated(Vector3(x, _floor_y, arm_z - 0.1), pilot)
		if s < 0.0:
			_left.append(pilot)
		_arm(Vector3(s * (half + BLOCK_ARM.x + 0.35), _floor_y + 1.3, arm_z), s)
	# LA CABEZA: sobre el fondo del vestíbulo, con la tapa detrás del asiento.
	var before := _roof.size()
	_shell(0.0, head_from, BLOCK_LOBBY_LONG, BLOCK_HEAD.x, top + 0.06, HEAD_TALL, BLOCK_HEAD_COLOR, {}, false, hatch)
	var pilot_head := Node3D.new()
	add_child(pilot_head)
	_seated(Vector3(0.0, top + 0.06, head_from + 0.95), pilot_head)
	_head_parts.append(pilot_head)
	_head_eye = Vector3(0.0, top + 0.06 + 1.3, head_from + 1.05)
	var _unused := before
	# La escalera, del piso del vestíbulo a la tapa.
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.05, TALL + ROOF, 0.05), Vector3(s * 0.25, _floor_y + (TALL + ROOF) * 0.5,
			hatch.position.y + 0.05), RIM)
	for i in int((TALL + ROOF) / 0.3):
		Clay.box(self, Vector3(0.5, 0.04, 0.04), Vector3(0.0, _floor_y + 0.3 * (i + 1), hatch.position.y + 0.05), RIM)
	# LA MOCHILA, maciza, con sus toberas.
	var low := _bottom - PACK_DROP
	Clay.box(self, Vector3(PACK.x, top - low, PACK.z), Vector3(0.0, (top + low) * 0.5, BLOCK_LOBBY_LONG + PACK.z * 0.5),
		BLOCK_PACK_COLOR)
	for x: float in [-0.5, 0.5]:
		for y: float in [top - 0.55, top - 1.4]:
			Clay.cylinder(self, NOZZLE, 0.45, Vector3(x, y, BLOCK_LOBBY_LONG + PACK.z + 0.22), DARK_METAL,
				Vector3(90.0, 0.0, 0.0))
	_legs(hip_line, (-BLOCK_GUNNER_LONG + BLOCK_LOBBY_LONG + PACK.z) * 0.5)
	# GENTE PARADA en el vestíbulo: una entrando al brazo derecho, otra recién subida de la mochila.
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(0.75, _floor_y + 0.04, arm_z - 0.2),
		-PI * 0.5)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(0.7, _floor_y + 0.04,
		BLOCK_LOBBY_LONG - 0.7), PI * 0.8)
	await get_tree().create_timer(3.0).timeout
	var shots: Array = []
	var aim := Vector3(0.0, _floor_y + 0.6, 0.8)
	_title.text = "%d. %s" % [_variant, _plan["name"]]
	shots.append(await _view(aim + Vector3(-8.0, 4.0, -10.0), aim + Vector3(0.0, -0.6, 0.0), 45.0))
	_show(_roof, false)
	_title.text = "%d. sin techos" % _variant
	shots.append(await _view(aim + Vector3(-6.0, 8.0, -7.0), aim, 45.0))
	_show(_roof, true)
	_show(_front, false)
	_title.text = "%d. de frente, sin las paredes de adelante" % _variant
	shots.append(await _view(aim + Vector3(0.0, 0.4, -30.0), aim + Vector3(0.0, 0.4, 0.0), 0.0, 4.6))
	_show(_front, true)
	_show(_left, false)
	_title.text = "%d. el corte (de costado, sin la mitad izquierda)" % _variant
	shots.append(await _view(aim + Vector3(-30.0, 0.4, 0.0), aim + Vector3(0.0, 0.4, 0.0), 0.0, 5.0))
	_show(_left, true)
	_show(_roof, false)
	_show(_head_parts, false)
	_title.text = "%d. el plano (sin techos ni cabeza)" % _variant
	shots.append(await _view(aim + Vector3(0.0, 30.0, 0.01), aim, 0.0, 7.5))
	_show(_roof, true)
	_show(_head_parts, true)
	_title.text = "%d. desde el fondo del vestíbulo" % _variant
	var eye := Vector3(-0.85, _floor_y + 1.62, BLOCK_LOBBY_LONG - 0.25)
	shots.append(await _view(eye, Vector3(0.3, _floor_y + 1.0, -BLOCK_GUNNER_LONG), 80.0))
	_save(shots)
	get_tree().quit()


## UN MÓDULO HUECO: piso sólido, techo (con un hueco `hole` si lo tiene) y cuatro paredes; `open` dice, por pared
## ("front", "back", "left", "right"), si es "wall" (por defecto), "door" (un hueco de DOOR al medio) o "none".
## Las paredes de la izquierda van al corte; las de adelante, a la vista de frente; todo, si `left_all`.
func _shell(x: float, z0: float, z1: float, width: float, floor_y: float, tall: float, color: Color, open: Dictionary,
		left_all: bool, hole: Rect2) -> void:
	var long := z1 - z0
	var z := (z0 + z1) * 0.5
	var head := floor_y > _floor_y + 0.5
	var parts: Array[Node3D] = []
	var under := floor_y - (_bottom if not head else floor_y - 0.1)
	var slab := StaticBody3D.new()
	Clay.solid(slab, Vector3(width, under, long), Vector3(x, floor_y - under * 0.5, z), color.darkened(0.15))
	add_child(slab)
	parts.append(slab)
	var floor_pieces: Array[Node3D] = []
	if head:
		slab.visible = false
		_slab(Rect2(x - width * 0.5, z0, width, long), floor_y - 0.05, 0.1, hole, color.darkened(0.15), floor_pieces)
	parts.append_array(floor_pieces)
	var roof_pieces: Array[Node3D] = []
	_slab(Rect2(x - width * 0.5, z0, width, long), floor_y + tall + ROOF * 0.5, ROOF,
		hole if not head else Rect2(), color, roof_pieces)
	_roof.append_array(roof_pieces)
	parts.append_array(roof_pieces)
	for side in ["front", "back", "left", "right"]:
		var kind: String = open.get(side, "wall")
		if kind == "none":
			continue
		var along_x: bool = side == "front" or side == "back"
		var span := width if along_x else long
		var gap := DOOR if kind == "door" else 0.0
		var piece_long := (span - gap) * 0.5 if gap > 0.0 else span
		var offsets: Array = [-(gap + piece_long) * 0.5, (gap + piece_long) * 0.5] if gap > 0.0 else [0.0]
		for offset: float in offsets:
			var at := Vector3.ZERO
			var size := Vector3.ZERO
			if along_x:
				var wz := z0 + WALL * 0.5 if side == "front" else z1 - WALL * 0.5
				at = Vector3(x + offset, floor_y + tall * 0.5, wz)
				size = Vector3(piece_long, tall, WALL)
			else:
				var wx := x - width * 0.5 + WALL * 0.5 if side == "left" else x + width * 0.5 - WALL * 0.5
				at = Vector3(wx, floor_y + tall * 0.5, z + offset)
				size = Vector3(WALL, tall, piece_long)
			var wall := Clay.box(self, size, at, color)
			parts.append(wall)
			if side == "front":
				_front.append(wall)
			if side == "left" and x <= 0.01:
				_left.append(wall)
			elif along_x and x <= 0.01 and at.x < 0.0 and not left_all:
				pass
	if left_all:
		for part in parts:
			if part is Node3D:
				_left.append(part)
	if head:
		_head_parts.append_array(parts)


## UNA SILLA de artillería: con piloto (`taken`) o vacía, con su tablero adelante.
func _chair(at: Vector3, taken: bool) -> void:
	if taken:
		_seated(at)
		return
	Clay.box(self, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(self, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), SEAT)
	Clay.box(self, Vector3(0.08, 0.42, 0.08), at + Vector3(0.0, 0.21, 0.05), DARK_METAL)
	Clay.box(self, Vector3(0.9, 0.1, 0.35), at + Vector3(0.0, 0.75, -0.6), RIM)


## ── HACIA UN CUBO (75 a 77) ────────────────────────────────────────────────────────────────────────────────────
## El usuario: «tenemos algo parecido a una "cruz" visto desde arriba… intentar que se parezca más a un cubo, y agrandar
## piernas y brazos… el largo del vestíbulo sea dos módulos de brazos de profundidad, y los módulos de brazos los haría
## pegados al límite con artillería y atrás de ellos irían sus módulos con su respectiva munición y con su lugar de
## recarga desde vestíbulo (no se pueden acceder… sólo estéticos para balancear a la meca)… entre vestíbulo y
## succionador… que sea continuo».
##   · el vestíbulo, de dos brazos de largo; los brazos adelante, pegados a artillería; atrás de cada uno su MUNICIÓN,
##     maciza, con la boca de recarga del lado del vestíbulo;
##   · el succionador sigue al vestíbulo de su mismo ancho, sin pared en el medio: el piso se termina y abajo, la boca;
##   · las tres variantes cambian sólo la escala de piernas y brazos (largo y grosor).
const AMMO_COLOR := Color(0.85, 0.72, 0.3)


func _cube_blockout(hip_line: float) -> void:
	var half := BLOCK_WIDTH * 0.5
	var top := _floor_y + TALL + ROOF
	var lobby_long := BLOCK_ARM.y * 2.0
	var arm_z := BLOCK_ARM.y * 0.5
	# La cabeza, alineada con los brazos (encima del frente del vestíbulo), sin escalera ni tapa por ahora.
	var head_from := 0.0
	var hatch := Rect2()
	# ARTILLERÍA.
	_shell(0.0, -BLOCK_GUNNER_LONG, 0.0, BLOCK_WIDTH, _floor_y, TALL, BLOCK_GUNNER_COLOR, {"back": "door"}, false,
		Rect2())
	for x: float in [-0.62, 0.62]:
		_chair(Vector3(x, _floor_y, -BLOCK_GUNNER_LONG + 0.95), x < 0.0)
	# EL VESTÍBULO: sin paredes propias a los costados (las arma abajo) ni atrás (sigue en el succionador).
	_shell(0.0, 0.0, lobby_long, BLOCK_WIDTH, _floor_y, TALL, BLOCK_LOBBY_COLOR,
		{"front": "none", "left": "none", "right": "none", "back": "none"}, false, hatch)
	for s: float in [-1.0, 1.0]:
		var wx := s * (half - WALL * 0.5)
		var door_from := arm_z - DOOR * 0.5
		var pieces: Array[Node3D] = []
		pieces.append(Clay.box(self, Vector3(WALL, TALL, door_from), Vector3(wx, _floor_y + TALL * 0.5, door_from * 0.5),
			BLOCK_LOBBY_COLOR))
		var rest := lobby_long - (arm_z + DOOR * 0.5)
		pieces.append(Clay.box(self, Vector3(WALL, TALL, rest), Vector3(wx, _floor_y + TALL * 0.5,
			lobby_long - rest * 0.5), BLOCK_LOBBY_COLOR))
		# La boca de recarga de la munición, del lado del vestíbulo, y una caja de balas al pie.
		var mouth_z := BLOCK_ARM.y * 1.5
		pieces.append(Clay.box(self, Vector3(0.06, 0.7, 0.9), Vector3(s * (half - WALL - 0.03), _floor_y + 1.1, mouth_z),
			RIM))
		pieces.append(Clay.box(self, Vector3(0.04, 0.5, 0.7), Vector3(s * (half - WALL - 0.07), _floor_y + 1.1, mouth_z),
			AMMO_COLOR.darkened(0.3)))
		pieces.append(Clay.box(self, Vector3(0.5, 0.35, 0.6), Vector3(s * (half - WALL - 0.35), _floor_y + 0.175,
			mouth_z + 0.1), AMMO_COLOR))
		if s < 0.0:
			_left.append_array(pieces)
	# LOS BRAZOS, adelante; atrás de cada uno, SU MUNICIÓN maciza.
	var shoulder_out := half + BLOCK_ARM.x
	for s: float in [-1.0, 1.0]:
		var x := s * (half + BLOCK_ARM.x * 0.5)
		var open := {"right": "none"} if s < 0.0 else {"left": "none"}
		_shell(x, 0.0, BLOCK_ARM.y, BLOCK_ARM.x, _floor_y, TALL, BLOCK_ARM_COLOR, open, s < 0.0, Rect2())
		var pilot := Node3D.new()
		add_child(pilot)
		_seated(Vector3(x, _floor_y, arm_z - 0.1), pilot)
		var ammo := Clay.box(self, Vector3(BLOCK_ARM.x, top - _bottom, BLOCK_ARM.y), Vector3(x, (top + _bottom) * 0.5,
			BLOCK_ARM.y * 1.5), AMMO_COLOR)
		if s < 0.0:
			_left.append(pilot)
			_left.append(ammo)
		var thick := MechBody.current.LEG_THICKNESS * _limbs
		_arm(Vector3(s * (shoulder_out + thick * 0.45), _floor_y + 1.2, arm_z), s)
	# LA CABEZA, alineada con los brazos.
	_shell(0.0, head_from, BLOCK_ARM.y, BLOCK_HEAD.x, top + 0.06, HEAD_TALL, BLOCK_HEAD_COLOR, {}, false, hatch)
	var pilot_head := Node3D.new()
	add_child(pilot_head)
	_seated(Vector3(0.0, top + 0.06, head_from + 0.95), pilot_head)
	_head_parts.append(pilot_head)
	# EL SUCCIONADOR, continuo con el vestíbulo: su mismo ancho, sin pared en el medio, sin piso; abajo, la boca.
	var low := _bottom - PACK_DROP
	var pack_z := lobby_long + PACK.z * 0.5
	for s: float in [-1.0, 1.0]:
		var side := Clay.box(self, Vector3(WALL, top - low, PACK.z), Vector3(s * (half - WALL * 0.5), (top + low) * 0.5,
			pack_z), BLOCK_PACK_COLOR)
		if s < 0.0:
			_left.append(side)
	Clay.box(self, Vector3(BLOCK_WIDTH, top - low, WALL), Vector3(0.0, (top + low) * 0.5,
		lobby_long + PACK.z - WALL * 0.5), BLOCK_PACK_COLOR)
	Clay.box(self, Vector3(BLOCK_WIDTH, _bottom - low, WALL), Vector3(0.0, (_bottom + low) * 0.5, lobby_long + WALL * 0.5),
		BLOCK_PACK_COLOR)
	_roof.append(Clay.box(self, Vector3(BLOCK_WIDTH, ROOF, PACK.z), Vector3(0.0, top - ROOF * 0.5, pack_z),
		BLOCK_PACK_COLOR))
	var column := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = (PACK.z - WALL * 2.0) * 0.48
	shaft.bottom_radius = shaft.top_radius * 1.3
	shaft.height = _floor_y
	column.mesh = shaft
	var swirl := StandardMaterial3D.new()
	swirl.albedo_color = SUCTION
	swirl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	swirl.cull_mode = BaseMaterial3D.CULL_DISABLED
	column.material_override = swirl
	column.position = Vector3(0.0, _floor_y * 0.5, pack_z)
	add_child(column)
	for x: float in [-0.7, 0.7]:
		for y: float in [top - 0.55, top - 1.4]:
			Clay.cylinder(self, NOZZLE, 0.45, Vector3(x, y, lobby_long + PACK.z + 0.22), DARK_METAL,
				Vector3(90.0, 0.0, 0.0))
	_legs(hip_line, (-BLOCK_GUNNER_LONG + lobby_long + PACK.z) * 0.5)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(0.7, _floor_y + 0.04, arm_z + 0.1),
		-PI * 0.5)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(-0.75, _floor_y + 0.04,
		BLOCK_ARM.y * 1.5 + 0.1), PI * 0.5)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(-6.5, 0.05, -2.0), 0.0)
	await get_tree().create_timer(3.0).timeout
	var shots: Array = []
	var high := top + HEAD_TALL + ROOF
	var k := high / 8.0
	var whole := Vector3(0.0, high * 0.5, 1.2)
	_title.text = "%d. %s" % [_variant, _plan["name"]]
	shots.append(await _view(whole + Vector3(-11.0, 4.0, -13.0) * k, whole, 45.0))
	_title.text = "%d. de atrás" % _variant
	shots.append(await _view(whole + Vector3(11.0, 3.0, 13.0) * k, whole, 45.0))
	var aim := Vector3(0.0, _floor_y + 0.6, 1.0)
	_show(_roof, false)
	_title.text = "%d. sin techos" % _variant
	shots.append(await _view(aim + Vector3(-6.0, 8.0, -7.0), aim, 50.0))
	_show(_roof, true)
	_show(_front, false)
	_title.text = "%d. de frente, sin las paredes de adelante" % _variant
	shots.append(await _view(whole + Vector3(0.0, 0.0, -40.0), whole, 0.0, high + 1.0))
	_show(_front, true)
	_show(_left, false)
	_title.text = "%d. el corte (de costado, sin la mitad izquierda)" % _variant
	shots.append(await _view(whole + Vector3(-40.0, 0.0, 0.0), whole, 0.0, high + 1.0))
	_show(_left, true)
	_show(_roof, false)
	_show(_head_parts, false)
	_title.text = "%d. el plano (sin techos ni cabeza)" % _variant
	shots.append(await _view(aim + Vector3(0.0, 30.0, 0.01), aim, 0.0, 9.0 + _limbs * 4.0))
	_show(_roof, true)
	_show(_head_parts, true)
	_save(shots)
	get_tree().quit()


## ── LOS MÓDULOS ──────────────────────────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	var arms: bool = _plan["arms"]
	var gunner_half := GUNNER_WIDTH * 0.5
	var lobby_half := gunner_half + (ARM_WIDTH if arms else NARROW_SIDE)
	var top := _floor_y + TALL + ROOF
	# EL ARTILLERO: del frente (−GUNNER_LONG) hasta el lobby (z 0).
	var side_kind := "glass" if arms else "wall"
	_cell(0.0, -GUNNER_LONG, 0.0, GUNNER_WIDTH, TALL, side_kind, side_kind, GUNNER_COLOR, false)
	_seated(Vector3(0.0, _floor_y, -GUNNER_LONG + 0.8))
	if arms:
		for s: float in [-1.0, 1.0]:
			var x := s * (gunner_half + ARM_WIDTH * 0.5)
			var front: float = _plan["arm_front"]
			_cell(x, front, 0.0, ARM_WIDTH, TALL, "wall" if s < 0.0 else "glass", "glass" if s < 0.0 else "wall",
				ARM_COLOR, s < 0.0)
			var pilot := Node3D.new()
			add_child(pilot)
			_seated(Vector3(x, _floor_y, front + 0.8), pilot)
			if s < 0.0:
				_left.append(pilot)
			_arm(Vector3(s * (lobby_half + 0.35), _floor_y + 1.3, front * 0.5), s)
	else:
		for s: float in [-1.0, 1.0]:
			_arm(Vector3(s * (gunner_half + 0.35), _floor_y + 1.3, -GUNNER_LONG * 0.45), s)
	# EL LOBBY: de z 0 a LOBBY_LONG, abierto adelante a los módulos; atrás, el paso a la mochila.
	var lobby_end := LOBBY_LONG
	var slab := StaticBody3D.new()
	Clay.solid(slab, Vector3(lobby_half * 2.0, SILL, LOBBY_LONG), Vector3(0.0, _bottom + SILL * 0.5, LOBBY_LONG * 0.5),
		METAL)
	add_child(slab)
	Clay.box(self, Vector3(lobby_half * 2.0 - 0.02, 0.03, LOBBY_LONG), Vector3(0.0, _floor_y + 0.015,
		LOBBY_LONG * 0.5), FLOOR)
	for s: float in [-1.0, 1.0]:
		var wall := Clay.box(self, Vector3(WALL, TALL, LOBBY_LONG), Vector3(s * (lobby_half - WALL * 0.5),
			_floor_y + TALL * 0.5, LOBBY_LONG * 0.5), METAL)
		if s < 0.0:
			_left.append(wall)
		if not arms:
			# Sin brazos, el lobby asoma un poco a los costados del artillero: su pared de adelante.
			var cheek := Clay.box(self, Vector3(NARROW_SIDE, TALL, WALL), Vector3(s * (gunner_half + NARROW_SIDE * 0.5),
				_floor_y + TALL * 0.5, WALL * 0.5), METAL)
			if s < 0.0:
				_left.append(cheek)
	# El techo del lobby, con la tapa de la cabeza.
	var head_from: float = _plan["head"]
	var hatch_z := maxf(head_from + HEAD_LONG - 0.6, 0.6)
	var hatch := Rect2(-HATCH * 0.5, hatch_z - HATCH * 0.5, HATCH, HATCH)
	_slab(Rect2(-lobby_half, 0.0, lobby_half * 2.0, LOBBY_LONG), top - ROOF * 0.5, ROOF, hatch, METAL, _roof)
	# Los módulos de recursos: tres por pared.
	for s: float in [-1.0, 1.0]:
		for i in 3:
			var z := lerpf(0.4, lobby_end - 0.4, (i + 0.5) / 3.0)
			var at := Vector3(s * (lobby_half - WALL - MODULE * 0.5 + 0.05), _floor_y + MODULE_HEIGHT, z)
			var cube := Clay.box(self, Vector3.ONE * MODULE, at, MODULE_COLORS[i + (0 if s < 0.0 else 3)])
			if s < 0.0:
				_left.append(cube)
	# La pared de atrás con el paso a la mochila.
	var door := PACK.x - WALL * 2.0
	var jamb := lobby_half - door * 0.5
	for s: float in [-1.0, 1.0]:
		var piece := Clay.box(self, Vector3(jamb, TALL, WALL), Vector3(s * (door * 0.5 + jamb * 0.5),
			_floor_y + TALL * 0.5, lobby_end - WALL * 0.5), METAL)
		if s < 0.0:
			_left.append(piece)
	Clay.box(self, Vector3(door, TALL - 1.9, WALL), Vector3(0.0, _floor_y + 1.9 + (TALL - 1.9) * 0.5,
		lobby_end - WALL * 0.5), METAL)
	_pack(lobby_end, top)
	# LA CABEZA, arriba, vidriada de los cuatro lados, con su tapa en el piso y la escalera desde el lobby.
	_head(head_from, top, hatch)
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.05, TALL + ROOF, 0.05), Vector3(s * 0.25, _floor_y + (TALL + ROOF) * 0.5,
			hatch_z + HATCH * 0.5 - 0.05), RIM)
	for i in int((TALL + ROOF) / 0.3):
		Clay.box(self, Vector3(0.5, 0.04, 0.04), Vector3(0.0, _floor_y + 0.3 * (i + 1), hatch_z + HATCH * 0.5 - 0.05), RIM)
	# LA GENTE DEL LOBBY.
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(-lobby_half + 1.3, _floor_y + 0.04,
		LOBBY_LONG * 0.55), PI * 0.5)
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(0.5, _floor_y + 0.04, 0.5), PI)


## UN MÓDULO DE ABAJO: piso sólido de color (el de su función), techo, frente de vidrio y sus dos costados ("wall",
## "glass" u "open"); atrás, abierto al lobby. `left_all`: todo él se esconde en el corte.
func _cell(x: float, z0: float, z1: float, width: float, tall: float, left: String, right: String, color: Color,
		left_all: bool) -> void:
	var long := z1 - z0
	var z := (z0 + z1) * 0.5
	var parts: Array[Node3D] = []
	var slab := StaticBody3D.new()
	Clay.solid(slab, Vector3(width, SILL, long), Vector3(x, _bottom + SILL * 0.5, z), METAL)
	add_child(slab)
	parts.append(Clay.box(self, Vector3(width - 0.04, 0.03, long - 0.04), Vector3(x, _floor_y + 0.015, z),
		color.lightened(0.25)))
	var roof := Clay.box(self, Vector3(width, ROOF, long), Vector3(x, _floor_y + tall + ROOF * 0.5, z), METAL)
	_roof.append(roof)
	parts.append(roof)
	parts.append(_pane(Vector3(width, tall, 0.04), Vector3(x, _floor_y + tall * 0.5, z0 + 0.02)))
	for s: float in [-1.0, 1.0]:
		var kind := left if s < 0.0 else right
		var wx := x + s * (width * 0.5 - WALL * 0.5)
		var piece: Node3D = null
		if kind == "wall":
			piece = Clay.box(self, Vector3(WALL, tall, long), Vector3(wx, _floor_y + tall * 0.5, z), METAL)
		elif kind == "glass":
			piece = _pane(Vector3(0.04, tall, long), Vector3(wx, _floor_y + tall * 0.5, z))
		var post := Clay.box(self, Vector3(WALL, tall, 0.12), Vector3(wx, _floor_y + tall * 0.5, z0 + 0.06), METAL)
		if s < 0.0 and x <= 0.0:
			if piece != null:
				_left.append(piece)
			_left.append(post)
	if left_all:
		for part in parts:
			_left.append(part)


## LA CABEZA: de `from` a `from + HEAD_LONG`, sobre el techo (`top`), vidriada de los cuatro lados.
func _head(from: float, top: float, hatch: Rect2) -> void:
	var z := from + HEAD_LONG * 0.5
	var y := top + 0.1
	var parts: Array[Node3D] = []
	var floor_parts: Array[Node3D] = []
	_slab(Rect2(-GUNNER_WIDTH * 0.5, from, GUNNER_WIDTH, HEAD_LONG), y - 0.05, 0.1, hatch, HEAD_COLOR.lightened(0.2),
		floor_parts)
	parts.append_array(floor_parts)
	parts.append(Clay.box(self, Vector3(GUNNER_WIDTH, ROOF, HEAD_LONG), Vector3(0.0, y + HEAD_TALL + ROOF * 0.5, z),
		METAL))
	parts.append(_pane(Vector3(GUNNER_WIDTH, HEAD_TALL, 0.04), Vector3(0.0, y + HEAD_TALL * 0.5, from)))
	parts.append(_pane(Vector3(GUNNER_WIDTH, HEAD_TALL, 0.04), Vector3(0.0, y + HEAD_TALL * 0.5, from + HEAD_LONG)))
	for s: float in [-1.0, 1.0]:
		var pane := _pane(Vector3(0.04, HEAD_TALL, HEAD_LONG), Vector3(s * GUNNER_WIDTH * 0.5, y + HEAD_TALL * 0.5, z))
		parts.append(pane)
		for corner: float in [from, from + HEAD_LONG]:
			var post := Clay.box(self, Vector3(0.1, HEAD_TALL, 0.1), Vector3(s * (GUNNER_WIDTH * 0.5 - 0.05),
				y + HEAD_TALL * 0.5, corner), RIM)
			parts.append(post)
			if s < 0.0:
				_left.append(post)
		if s < 0.0:
			_left.append(pane)
	# El marco negro de abajo, como pidió para el domo.
	parts.append(Clay.box(self, Vector3(GUNNER_WIDTH + 0.06, 0.12, HEAD_LONG + 0.06), Vector3(0.0, y + 0.06, z), RIM))
	var pilot := Node3D.new()
	add_child(pilot)
	_seated(Vector3(0.0, y, from + 0.7), pilot)
	parts.append(pilot)
	_head_eye = Vector3(0.0, y + 1.3, from + 0.85)
	_roof.append_array(parts)


## Una losa (`area` en x y z) con un hueco (`hole`), a la altura `y` y de grosor `thick`, en cuatro pedazos.
func _slab(area: Rect2, y: float, thick: float, hole: Rect2, color: Color, into: Array[Node3D]) -> void:
	var cut := area.intersection(hole)
	if cut.size.x <= 0.0 or cut.size.y <= 0.0:
		into.append(_flat(area, y, thick, color))
		return
	into.append(_flat(Rect2(area.position.x, area.position.y, area.size.x, cut.position.y - area.position.y), y, thick,
		color))
	into.append(_flat(Rect2(area.position.x, cut.end.y, area.size.x, area.end.y - cut.end.y), y, thick, color))
	into.append(_flat(Rect2(area.position.x, cut.position.y, cut.position.x - area.position.x, cut.size.y), y, thick,
		color))
	into.append(_flat(Rect2(cut.end.x, cut.position.y, area.end.x - cut.end.x, cut.size.y), y, thick, color))


func _flat(area: Rect2, y: float, thick: float, color: Color) -> Node3D:
	if area.size.x <= 0.001 or area.size.y <= 0.001:
		var empty := Node3D.new()
		add_child(empty)
		return empty
	return Clay.box(self, Vector3(area.size.x, thick, area.size.y), Vector3(area.get_center().x, y,
		area.get_center().y), color)


## LA MOCHILA, pegada atrás (como la 68): abierta abajo, con el succionador y las cuatro toberas apuntando atrás.
func _pack(back: float, top: float) -> void:
	var low := _bottom - PACK_DROP
	var high := top
	var tall := high - low
	var z := back + PACK.z * 0.5
	for s: float in [-1.0, 1.0]:
		var side := Clay.box(self, Vector3(WALL, tall, PACK.z), Vector3(s * (PACK.x - WALL) * 0.5, low + tall * 0.5, z),
			METAL)
		if s < 0.0:
			_left.append(side)
	Clay.box(self, Vector3(PACK.x, tall, WALL), Vector3(0.0, low + tall * 0.5, back + PACK.z - WALL * 0.5), METAL)
	Clay.box(self, Vector3(PACK.x, _bottom - low, WALL), Vector3(0.0, low + (_bottom - low) * 0.5, back + WALL * 0.5),
		METAL)
	_roof.append(Clay.box(self, Vector3(PACK.x, ROOF, PACK.z), Vector3(0.0, high - ROOF * 0.5, z), METAL))
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(PACK.x + 0.1, 0.12, 0.1), Vector3(0.0, low + 0.06, z + s * (PACK.z * 0.5)), RIM)
		var post := Clay.box(self, Vector3(0.1, 0.12, PACK.z + 0.1), Vector3(s * PACK.x * 0.5, low + 0.06, z), RIM)
		if s < 0.0:
			_left.append(post)
	var column := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = (PACK.z - WALL * 2.0) * 0.48
	shaft.bottom_radius = shaft.top_radius * 1.3
	shaft.height = _floor_y
	column.mesh = shaft
	var swirl := StandardMaterial3D.new()
	swirl.albedo_color = SUCTION
	swirl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	swirl.cull_mode = BaseMaterial3D.CULL_DISABLED
	column.material_override = swirl
	column.position = Vector3(0.0, _floor_y * 0.5, z)
	add_child(column)
	for x: float in [-0.5, 0.5]:
		for y: float in [high - 0.55, high - 1.4]:
			var at := Vector3(x, y, back + PACK.z)
			Clay.cylinder(self, NOZZLE * 1.15, 0.12, at + Vector3(0.0, 0.0, 0.06), RIM, Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(self, NOZZLE, 0.45, at + Vector3(0.0, 0.0, 0.3), DARK_METAL, Vector3(90.0, 0.0, 0.0))


## UN BRAZO, de arcilla (al _limbs de los de hoy), desde el hombro en la pared de afuera: el antebrazo hacia adelante.
func _arm(shoulder: Vector3, side: float) -> void:
	var body := MechBody.current
	var upper := body.UPPER_ARM * _limbs
	var fore := body.FOREARM * _limbs
	var thick := body.LEG_THICKNESS * _limbs
	var elbow := shoulder + Vector3(side * 0.25, -1.0, 0.25).normalized() * upper
	var hand := elbow + Vector3(0.0, -0.25, -1.0).normalized() * fore
	var parts: Array[Node3D] = []
	parts.append(Clay.sphere(self, thick * 0.7, shoulder, JOINT))
	parts.append(_limb(shoulder, elbow, thick * 0.48, Clay.METAL.darkened(0.1)))
	parts.append(Clay.sphere(self, thick * 0.55, elbow, JOINT))
	parts.append(_limb(elbow, hand, thick * 0.45, Clay.METAL.darkened(0.2)))
	parts.append(Clay.sphere(self, thick * 0.6, hand, JOINT))
	if side < 0.0:
		_left.append_array(parts)


## UN PILOTO SENTADO, de arcilla, mirando adelante (−Z), con su asiento y su tablero: `at`, el piso debajo del asiento.
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
	Clay.box(parent, Vector3(0.9, 0.1, 0.35), at + Vector3(0.0, 0.75, -0.6), RIM)


## LAS PIERNAS (al _limbs de las de hoy), con las caderas en `z`.
func _legs(hip_y: float, z: float) -> void:
	var body := MechBody.current
	var thick := body.LEG_THICKNESS * _limbs
	var hip_x := body.HIP_X * _limbs
	var thigh := body.THIGH * _limbs
	var foot := body.FOOT_SIZE * _limbs
	Clay.cylinder(self, thick * 0.43, hip_x * 2.0, Vector3(0.0, hip_y, z), JOINT, Vector3(0.0, 0.0, 90.0))
	Clay.cylinder(self, thick * 0.48, _bottom - hip_y + 0.2, Vector3(0.0, (_bottom + hip_y) * 0.5, z), JOINT)
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * hip_x, hip_y, z)
		var ankle := Vector3(side * (hip_x + 0.3 * _limbs), thick * 0.33 + foot.y * 0.5, z)
		var span := hip.distance_to(ankle)
		var bend := sqrt(maxf(thigh * thigh - span * span * 0.25, 0.0))
		var knee := (hip + ankle) * 0.5 + Vector3(0.0, 0.0, -bend)
		Clay.sphere(self, thick * 0.62, hip, JOINT)
		_limb(hip, knee, thick * 0.5, Clay.METAL.darkened(0.1))
		Clay.sphere(self, thick * 0.62, knee, JOINT)
		_limb(knee, ankle, thick * 0.5, Clay.METAL.darkened(0.2))
		Clay.sphere(self, thick * 0.53, ankle, JOINT)
		Clay.box(self, foot, Vector3(ankle.x, foot.y * 0.5, ankle.z - 0.4 * _limbs), JOINT)


func _limb(a: Vector3, b: Vector3, radius: float, color: Color) -> Node3D:
	var holder := Clay.limb(self, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)
	return holder


## ── LO DE SIEMPRE ────────────────────────────────────────────────────────────────────────────────────────────────

func _pane(size: Vector3, at: Vector3) -> MeshInstance3D:
	var pane := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	pane.mesh = mesh
	pane.material_override = _glass
	pane.position = at
	add_child(pane)
	return pane


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
	var path := "%s/modulos_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)
