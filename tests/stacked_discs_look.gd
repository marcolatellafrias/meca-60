extends Node3D

## LA MECA DE DISCOS APILADOS, MAQUETA DE ARCILLA DEL EXTERIOR (16/11/2026; sigue la numeración de tests/modules_look).
## El usuario: «algo tengo que sacrificar… una nave que sea por discos apilados y cada persona tiene su propio disco… si
## querés ir de un disco a otro, cada disco tiene… su mini plataforma alrededor, o sea, pasarela, y se sube por la
## escalerita tipo vertical… las paredes de cada cilindro, además de la rendija… en la parte de atrás… los componentes…
## a lo sumo… un disco que sea de dos personas… las dos manejen los brazos… quiero maquetar el exterior para ver cómo
## queda la plataforma y ver si es viable».
##   · Cada disco: un cilindro con su rendija (el que maneja, arriba, la tiene alrededor; los demás, adelante) y su
##     puerta atrás, al lado de la escalera.
##   · Cada uno con su PASARELA alrededor, a la altura de su piso, con baranda; la ESCALERA vertical atrás, de pasarela a
##     pasarela (la de arriba tiene el hueco donde llega).
##   · De abajo hacia arriba: artillería, los brazos, el que maneja. Piernas y brazos al 70 % de los de hoy.
##   78 · tres discos iguales: el del medio, de dos personas, con un brazo a cada lado;
##   79 · tres discos, cada uno más chico hacia arriba (la pasarela de arriba cae sobre el techo del de abajo);
##   80 · cuatro discos iguales, uno por persona: el brazo izquierdo y el derecho en discos distintos;
##   81 · tres discos, el del medio (los brazos) más ancho que los otros dos.
##   tools/godot_ventana.sh res://tests/stacked_discs_look.tscn -- --salida=C:/carpeta --variante=78

const VIEW := Vector2i(1280, 720)
## radii: el radio de cada disco, de abajo hacia arriba; roles: qué es cada uno; arms: en qué disco va cada brazo
## (izquierdo, derecho).
const VARIANTS := {
	78: {"name": "tres discos iguales, los brazos al medio", "radii": [1.7, 1.7, 1.7],
		"roles": ["gunner", "arms", "driver"], "arms": [1, 1]},
	79: {"name": "tres discos, más chicos hacia arriba", "radii": [2.3, 1.85, 1.4],
		"roles": ["gunner", "arms", "driver"], "arms": [1, 1]},
	80: {"name": "cuatro discos iguales, uno por persona", "radii": [1.5, 1.5, 1.5, 1.5],
		"roles": ["gunner", "arm", "arm", "driver"], "arms": [1, 2]},
	81: {"name": "tres discos, el de los brazos más ancho", "radii": [1.5, 2.1, 1.4],
		"roles": ["gunner", "arms", "driver"], "arms": [1, 1]},
	82: {"name": "tres discos iguales, más anchos, escalera adentro", "radii": [2.2, 2.2, 2.2],
		"roles": ["gunner", "arms", "driver"], "arms": [1, 1], "inside": true},
	83: {"name": "tres discos iguales, aún más anchos, escalera adentro", "radii": [2.6, 2.6, 2.6],
		"roles": ["gunner", "arms", "driver"], "arms": [1, 1], "inside": true},
}
## 82 y 83 (el usuario: «¿y si hacemos la primera opción pero con escaleras en el interior, y sin pasarelas? (y más
## diámetro)»): los discos huecos, sin pasarelas ni puertas; adentro, la escalera vertical atrás, de piso a piso por una
## tapa. Se miran también en corte (sin la mitad izquierda).
const INNER_WALL := 0.15
const DISC_TALL := 2.3
const WALKWAY := 0.75
const WALKWAY_THICK := 0.08
const RAIL := 1.0
const SEGMENTS := 36
## La escalera: hacia atrás (ángulo desde el frente, en el sentido de las agujas mirando desde arriba).
const LADDER_ANGLE := PI
const LADDER_WIDTH := 0.5
const LIMBS := 0.7

const COLORS := {"gunner": Color(0.66, 0.6, 0.56), "arms": Color(0.57, 0.62, 0.56), "arm": Color(0.57, 0.62, 0.56),
	"driver": Color(0.55, 0.59, 0.65)}
const WALK_COLOR := Color(0.5, 0.5, 0.5)
const RIM := Color(0.22, 0.23, 0.25)
const SLIT := Color(0.12, 0.14, 0.17)
const JOINT := Color(0.36, 0.375, 0.4)
const SKIN := Color(0.86, 0.66, 0.5)

var _folder := ""
var _variant := 78
var _plan: Dictionary = {}
var _eye: Camera3D = null
var _title: Label = null
var _bottom := 0.0
var _floors: Array[float] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
	get_window().size = VIEW
	_plan = VARIANTS[_variant]
	_stage()
	var body := MechBody.current
	var hip_line := (body.WAIST - body.HIP_DROP) * LIMBS
	_bottom = hip_line + 0.66
	_build()
	_legs(hip_line)
	await get_tree().create_timer(2.0).timeout
	var radii: Array = _plan["radii"]
	var high := _bottom + DISC_TALL * radii.size()
	var k := high / 10.0
	var whole := Vector3(0.0, high * 0.5, 0.0)
	var shots: Array = []
	_title.text = "%d. %s" % [_variant, _plan["name"]]
	shots.append(await _view(whole + Vector3(-9.0, 4.0, -12.0) * k, whole, 45.0))
	_title.text = "%d. de atrás" % _variant if _plan.get("inside", false) else "%d. de atrás: las escaleras" % _variant
	shots.append(await _view(whole + Vector3(9.0, 3.0, 12.0) * k, whole, 45.0))
	_title.text = "%d. de costado" % _variant
	shots.append(await _view(whole + Vector3(-40.0, 0.0, 0.0), whole, 0.0, high + 1.5))
	if _plan.get("inside", false):
		for part in _left:
			part.visible = false
		_title.text = "%d. el corte (sin la mitad izquierda)" % _variant
		shots.append(await _view(whole + Vector3(-40.0, 0.0, 0.0), whole, 0.0, high + 1.5))
		_title.text = "%d. el corte, de cerca" % _variant
		shots.append(await _view(Vector3(-7.0, _floors[1] + 2.0, -3.0), Vector3(0.0, _floors[1] + 0.8, 0.3), 55.0))
		for part in _left:
			part.visible = true
		var r_in: float = radii[1]
		_title.text = "%d. adentro, al pie de la escalera de los brazos" % _variant
		var eye_in := Vector3(0.4, _floors[1] + 1.85, r_in - 0.5)
		shots.append(await _view(eye_in, eye_in + Vector3(-0.2, -0.35, -1.0), 85.0))
		_save(shots)
		get_tree().quit()
		return
	_title.text = "%d. de cerca, de atrás" % _variant
	var mid_floor := _floors[1]
	shots.append(await _view(Vector3(4.5, mid_floor + 2.5, 6.5), Vector3(0.0, mid_floor + 0.5, 0.0), 50.0))
	_title.text = "%d. parado en la pasarela del medio" % _variant
	var r: float = radii[1]
	var eye := Vector3(sin(3.0) * (r + WALKWAY * 0.5), mid_floor + 1.65, -cos(3.0) * (r + WALKWAY * 0.5))
	var ahead := Vector3(sin(1.9) * (r + WALKWAY * 0.5), mid_floor + 1.2, -cos(1.9) * (r + WALKWAY * 0.5))
	shots.append(await _view(eye, ahead, 80.0))
	_title.text = "%d. de arriba" % _variant
	shots.append(await _view(Vector3(0.0, high + 30.0, 0.01), Vector3(0.0, high, 0.0), 0.0, 9.0 + k * 3.0))
	_save(shots)
	get_tree().quit()


## ── LOS DISCOS ───────────────────────────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	if _plan.get("inside", false):
		_build_inside()
		return
	var radii: Array = _plan["radii"]
	var roles: Array = _plan["roles"]
	for i in radii.size():
		_floors.append(_bottom + DISC_TALL * i)
	for i in radii.size():
		var r: float = radii[i]
		var y := _floors[i]
		var role: String = roles[i]
		Clay.cylinder(self, r, DISC_TALL - 0.06, Vector3(0.0, y + DISC_TALL * 0.5, 0.0), COLORS[role])
		Clay.cylinder(self, r + 0.04, 0.1, Vector3(0.0, y + DISC_TALL - 0.03, 0.0), RIM)
		# La rendija: el que maneja, alrededor; los demás, adelante. A la altura de los ojos de alguien sentado.
		var slit_y := y + 1.2
		var spread := PI if role == "driver" else deg_to_rad(55.0)
		_arc(r + 0.01, slit_y, 0.32, 0.12, -spread, spread, SLIT)
		# La puerta, atrás, al costado de la escalera.
		var door := LADDER_ANGLE - 0.55
		var at := Vector3(sin(door) * (r + 0.02), y + 0.95, -cos(door) * (r + 0.02))
		var leaf := Clay.box(self, Vector3(0.8, 1.9, 0.08), at, RIM)
		leaf.basis = Basis(Vector3.UP, PI - door)
		# La pasarela, a la altura del piso, con su baranda; con el hueco de la escalera que llega de abajo.
		var hole := i > 0
		_walkway(r, y, hole)
		# La escalera, atrás, de esta pasarela a la de arriba (la última, hasta su techo).
		if i < radii.size() - 1:
			_ladder(r + 0.35, y + WALKWAY_THICK, _floors[i + 1] + WALKWAY_THICK)
	# Los brazos: el izquierdo y el derecho, cada uno en su disco, del costado.
	var arm_discs: Array = _plan["arms"]
	var body := MechBody.current
	for side in 2:
		var s := -1.0 if side == 0 else 1.0
		var disc: int = arm_discs[side]
		var r: float = radii[disc]
		var thick := body.LEG_THICKNESS * LIMBS
		_arm(Vector3(s * (r + thick * 0.72), _floors[disc] + DISC_TALL * 0.55, 0.0), s)
	# La gente: una en la pasarela del medio, una subiendo la escalera y una en el suelo.
	var r1: float = radii[1]
	_standing(Vector3(sin(2.4) * (r1 + WALKWAY * 0.5), _floors[1] + WALKWAY_THICK, -cos(2.4) * (r1 + WALKWAY * 0.5)))
	var r0: float = radii[0]
	_standing(Vector3(0.0, _floors[0] + 0.9, r0 + 0.65))
	_standing(Vector3(-5.5, 0.0, -2.0))


## LOS DISCOS HUECOS (82, 83): pared en segmentos (la de la izquierda se esconde en el corte), piso con su tapa,
## techo; la rendija afuera; adentro, la gente sentada y la escalera atrás, de piso a piso.
var _left: Array[Node3D] = []


func _build_inside() -> void:
	var radii: Array = _plan["radii"]
	var roles: Array = _plan["roles"]
	for i in radii.size():
		_floors.append(_bottom + DISC_TALL * i)
	var step := TAU / SEGMENTS
	for i in radii.size():
		var r: float = radii[i]
		var y := _floors[i]
		var role: String = roles[i]
		var color: Color = COLORS[role]
		# El piso (en el de abajo, la panza) y, arriba de todo, el techo.
		Clay.cylinder(self, r, 0.2, Vector3(0.0, y + 0.1, 0.0), color.darkened(0.25))
		# El de arriba, un DOMO (el usuario: «el último de arriba hacelo en forma de domo»): se esconde entero en el
		# corte; su rendija, alrededor, a la altura de los ojos.
		if role == "driver":
			var dome := MeshInstance3D.new()
			var cap := SphereMesh.new()
			cap.radius = r
			cap.height = r
			cap.is_hemisphere = true
			dome.mesh = cap
			dome.material_override = Clay.material(color)
			dome.position = Vector3(0.0, y + 0.2, 0.0)
			add_child(dome)
			_left.append(dome)
			Clay.cylinder(self, r + 0.04, 0.1, Vector3(0.0, y + 0.05, 0.0), RIM)
			var band := sqrt(r * r - 1.0 * 1.0)
			_arc(band + 0.01, y + 1.2, 0.3, 0.12, -PI, PI, SLIT)
			Clay.box(self, Vector3(0.9, 0.03, 0.9), Vector3(0.0, y + 0.215, r - 0.55), RIM)
			_ladder(r - 0.55, _floors[i - 1] + 0.2, y + 0.2)
			_seated(Vector3(0.0, y + 0.2, -0.4))
			continue
		# La pared, en segmentos.
		for k in SEGMENTS:
			var a := step * (k + 0.5)
			var mid := r - INNER_WALL * 0.5
			var piece := Clay.box(self, Vector3(INNER_WALL, DISC_TALL - 0.2, 2.0 * r * sin(step * 0.5) + 0.02),
				Vector3(sin(a) * mid, y + 0.2 + (DISC_TALL - 0.2) * 0.5, -cos(a) * mid), color)
			piece.basis = Basis(Vector3.UP, PI * 0.5 - a)
			if sin(a) < -0.01:
				_left.append(piece)
		Clay.cylinder(self, r + 0.04, 0.1, Vector3(0.0, y + 0.05, 0.0), RIM)
		var spread := PI if role == "driver" else deg_to_rad(55.0)
		_arc(r + 0.01, y + 1.2, 0.32, 0.12, -spread, spread, SLIT)
		# La tapa del piso (de los de arriba) y la escalera desde el piso de abajo.
		var ladder_r := r - 0.55
		if i > 0:
			Clay.box(self, Vector3(0.9, 0.03, 0.9), Vector3(0.0, y + 0.215, ladder_r), RIM)
			_ladder(ladder_r, _floors[i - 1] + 0.2, y + 0.2)
		# La gente sentada: uno al medio; en el de los brazos, dos, uno a cada lado.
		var seats: Array = [Vector3(-0.75, 0.0, -0.4), Vector3(0.75, 0.0, -0.4)] if role == "arms" 			else [Vector3(0.0, 0.0, -0.4)]
		for seat: Vector3 in seats:
			_seated(Vector3(seat.x, y + 0.2, seat.z))
	var arm_discs: Array = _plan["arms"]
	var body := MechBody.current
	var thick := body.LEG_THICKNESS * LIMBS
	for side in 2:
		var s := -1.0 if side == 0 else 1.0
		var disc: int = arm_discs[side]
		var r: float = radii[disc]
		var before := get_child_count()
		_arm(Vector3(s * (r + thick * 0.72), _floors[disc] + DISC_TALL * 0.55, 0.0), s)
		if s < 0.0:
			for c in range(before, get_child_count()):
				_left.append(get_child(c))
	# Uno subiendo la escalera del de los brazos, y uno en el suelo.
	var r1: float = radii[1]
	_standing(Vector3(0.0, _floors[1] + 0.2, r1 - 0.25))
	_standing(Vector3(-6.0, 0.0, -2.0))


## UN PILOTO SENTADO, de arcilla, mirando adelante (−Z), con su silla y su tablero: `at`, el piso debajo del asiento.
func _seated(at: Vector3) -> void:
	Clay.box(self, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), Color(0.25, 0.42, 0.7))
	Clay.box(self, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), Color(0.25, 0.42, 0.7))
	Clay.box(self, Vector3(0.08, 0.42, 0.08), at + Vector3(0.0, 0.21, 0.05), RIM)
	Clay.box(self, Vector3(0.9, 0.1, 0.35), at + Vector3(0.0, 0.75, -0.6), RIM)
	Clay.box(self, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(self, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(self, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.12, 0.42, 0.12), at + Vector3(side * 0.1, 0.27, -0.28), SKIN)
		Clay.box(self, Vector3(0.1, 0.1, 0.38), at + Vector3(side * 0.24, 0.8, -0.12), SKIN)


## Un arco de cajas finitas pegadas a la pared (la rendija): de `from` a `to` (ángulos desde el frente).
func _arc(radius: float, y: float, tall: float, depth: float, from: float, to: float, color: Color) -> void:
	var count := maxi(int((to - from) / (TAU / SEGMENTS)), 1)
	var step := (to - from) / count
	for k in count:
		var a := from + step * (k + 0.5)
		var box := Clay.box(self, Vector3(depth, tall, 2.0 * radius * sin(step * 0.5) + 0.02),
			Vector3(sin(a) * radius, y, -cos(a) * radius), color)
		box.basis = Basis(Vector3.UP, PI * 0.5 - a)
		if sin(a) < -0.01:
			_left.append(box)


## LA PASARELA alrededor de un disco de radio `r`, a la altura `y`: el piso en segmentos y la baranda de afuera (postes
## y pasamanos); con `hole`, sin piso ni baranda donde llega la escalera.
func _walkway(r: float, y: float, hole: bool) -> void:
	var mid := r + WALKWAY * 0.5
	var outer := r + WALKWAY
	var step := TAU / SEGMENTS
	for k in SEGMENTS:
		var a := step * (k + 0.5)
		var gap := absf(wrapf(a - LADDER_ANGLE, -PI, PI)) < LADDER_WIDTH / mid
		var turn := Basis(Vector3.UP, PI * 0.5 - a)
		if not (hole and gap):
			var plank := Clay.box(self, Vector3(WALKWAY, WALKWAY_THICK, 2.0 * mid * sin(step * 0.5) + 0.02),
				Vector3(sin(a) * mid, y + WALKWAY_THICK * 0.5, -cos(a) * mid), WALK_COLOR)
			plank.basis = turn
		if gap:
			continue
		var rail := Clay.box(self, Vector3(0.05, 0.05, 2.0 * outer * sin(step * 0.5) + 0.02),
			Vector3(sin(a) * outer, y + RAIL, -cos(a) * outer), RIM)
		rail.basis = turn
		if k % 3 == 0:
			Clay.box(self, Vector3(0.04, RAIL, 0.04), Vector3(sin(a) * outer, y + RAIL * 0.5, -cos(a) * outer), RIM)


## LA ESCALERA vertical, atrás, a `radius` del centro: de `from` a `to` (alturas).
func _ladder(radius: float, from: float, to: float) -> void:
	var at := Vector3(sin(LADDER_ANGLE) * radius, 0.0, -cos(LADDER_ANGLE) * radius)
	var turn := Basis(Vector3.UP, PI * 0.5 - LADDER_ANGLE)
	for s: float in [-1.0, 1.0]:
		var side := turn * Vector3(0.0, 0.0, s * LADDER_WIDTH * 0.5)
		Clay.box(self, Vector3(0.05, to - from + 1.0, 0.05), at + side + Vector3(0.0, (from + to + 1.0) * 0.5, 0.0), RIM)
	var rungs := int((to - from) / 0.3)
	for i in rungs:
		var rung := Clay.box(self, Vector3(0.04, 0.04, LADDER_WIDTH), at + Vector3(0.0, from + 0.3 * (i + 1), 0.0), RIM)
		rung.basis = turn


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


## LAS PIERNAS de arcilla, con la columna hasta el disco de abajo.
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
	var path := "%s/discos_%d.png" % [_folder, _variant]
	sheet.save_png(path)
	print("CAPTURA ", path)
