class_name GunnerTurret
extends Node3D

## LA TORRETA DEL ARTILLERO (18/11/2026; el usuario: «la silla va a ir junto con los elementos… una silla bien hecha…
## como son los artilleros en la guerra… que le permite a la silla inclinarse hacia arriba o hacia abajo, llevando
## también las cosas que tiene junto a la silla»; de las maquetas de tests/gunner_cradle_look, la de los soportes
## macizos). Va arriba de la torre de la meca de 3 (la arma CageCabin._tower) y es el puesto entero del artillero:
##
##   · EL PLATO (`yaw_node`), que gira de costado sobre la torre, con DOS SOPORTES MACIZOS (una chapa gruesa por lado,
##     la base recta y arriba curva en tres tramos alrededor del tornillo).
##   · LA CUNA (`cradle`), colgada de los dos ejes en las caras de los costados del asiento, que se inclina arriba y abajo
##     y lleva todo: LA SILLA (la pone la cabina en `frame`, FIJA: ver SeatInteractable.fixed), LAS DOS ARMAS en brazos
##     que salen de los tornillos de los ejes, en la línea del eje (la minigun a la derecha, la caja de misiles a la
##     izquierda), EL YUGO entre las rodillas y TRES TABLEROS en brazos articulados, en un cono adelante.
##
## SE APUNTA CON EL YUGO (GunnerYoke): agarrado (clic derecho mantenido), la mirada va al frente y la torreta PERSIGUE
## HACIA DONDE MIRA quien la maneja con un resorte (`aim`); suelto, queda donde quedó. La silla fija hace que el cuerpo
## vaya con la cuna; la cabeza mira libre en su cono. EL GATILLO del yugo y LOS BOTONES de los tableros manejan las armas
## (GunnerWeapons); los aros de los botones muestran lo que tienen (ver «Los tres tableros»).
## *Hasta el 18/11/2026 la torre llevaba un racimo de caños en una horquilla, sólo de dibujo.*
##
## Todo en el espacio de la silla (`frame`, el de la cuna sin inclinar): −Z adelante, la base de la silla en el origen.

## Los ejes de la cuna: a la altura del asiento, en las caras de sus costados (`BOLT_X` del medio).
const PIVOT := Vector3(0.0, 0.42, 0.02)
const BOLT_X := 0.27
## Cuánto se inclina la cuna (grados): para abajo y para arriba.
const PITCH_MIN := -10.0
const PITCH_MAX := 40.0
## EL RESORTE con que persigue la mirada: cuántas veces por segundo oscila, cuánto se frena (1: sin rebote) y lo más
## rápido que gira (grados por segundo).
const TURN_HZ := 1.4
const TURN_DAMPING := 0.85
const TURN_TOP := 140.0
## Cuánto sigue persiguiendo después del último pedido del yugo (s): el yugo pide cada paso mientras se lo agarra.
const AIM_HOLD := 0.15
## Cuánto más grandes van las armas que las de las maquetas.
const WEAPON_SCALE := 1.5

const GUNMETAL := Color(0.24, 0.25, 0.27)
const PLATE := Color(0.5, 0.52, 0.55)
const FORK := Color(0.12, 0.12, 0.13)
const GRAB := Color(0.62, 0.22, 0.18)
const SCREEN := Color(0.05, 0.12, 0.06)
const GREEN := Color(0.35, 0.9, 0.4)
const RED := Color(0.85, 0.2, 0.15)
const AMMO := [Color(0.85, 0.75, 0.3), Color(0.3, 0.6, 0.9), Color(0.85, 0.35, 0.25)]

## El plato que gira, la cuna que se inclina y lo que va en ella (en el espacio de la silla); el yugo.
var yaw_node: Node3D = null
var cradle: Node3D = null
var frame: Node3D = null
var yoke: GunnerYoke = null
## LAS ARMAS: lo que disparan, sus tiempos y su calor.
var weapons: GunnerWeapons = null
## Los botones redondos de los tableros, por acción: sus tramos del aro, su aguja, su botón y si es de un arma.
var _radials := {}
var _heat_fill: Node3D = null
## Los caños de la minigun: giran con `GunnerWeapons.spin`.
var _barrels: Node3D = null
var _skip: Array[RID] = []
## Hacia dónde apunta, en el espacio de lo que la lleva (rad): el giro del plato y la inclinación de la cuna.
var yaw := 0.0
var pitch := 0.0
var _yaw_speed := 0.0
var _pitch_speed := 0.0
var _target_yaw := 0.0
var _target_pitch := 0.0
var _aim_left := 0.0


func _init() -> void:
	name = "Torreta del artillero"
	yaw_node = Node3D.new()
	yaw_node.name = "Plato"
	add_child(yaw_node)
	cradle = Node3D.new()
	cradle.name = "Cuna"
	cradle.position = PIVOT
	yaw_node.add_child(cradle)
	frame = Node3D.new()
	frame.name = "En la cuna"
	frame.position = -PIVOT
	cradle.add_child(frame)
	weapons = GunnerWeapons.new()
	weapons.name = "Armas"
	weapons.turret = self
	add_child(weapons)
	_build()


## APUNTAR HACIA `world_yaw` Y `world_pitch` (rad, como la mirada): lo pide el yugo cada paso mientras se lo agarra; la
## torreta lo persigue con su resorte (ver `_physics_process`).
func aim(world_yaw: float, world_pitch: float) -> void:
	var holder := get_parent() as Node3D
	var front := holder.global_basis * Vector3.FORWARD if holder != null else Vector3.FORWARD
	_target_yaw = wrapf(world_yaw - atan2(-front.x, -front.z), -PI, PI)
	_target_pitch = clampf(world_pitch, deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))
	_aim_left = AIM_HOLD


func _physics_process(delta: float) -> void:
	_aim_left = maxf(_aim_left - delta, 0.0)
	if _aim_left > 0.0:
		_yaw_speed = _spring(angle_difference(yaw, _target_yaw), _yaw_speed, delta)
		_pitch_speed = _spring(_target_pitch - pitch, _pitch_speed, delta)
	else:
		# Suelta: se frena y queda donde quedó.
		_yaw_speed = move_toward(_yaw_speed, 0.0, deg_to_rad(TURN_TOP) * 4.0 * delta)
		_pitch_speed = move_toward(_pitch_speed, 0.0, deg_to_rad(TURN_TOP) * 4.0 * delta)
	yaw = wrapf(yaw + _yaw_speed * delta, -PI, PI)
	pitch = clampf(pitch + _pitch_speed * delta, deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))
	yaw_node.rotation.y = yaw
	cradle.rotation.x = pitch


## UN PASO DEL RESORTE: la velocidad nueva para cerrar `error` (rad), con su tope.
func _spring(error: float, speed: float, delta: float) -> float:
	var omega := TAU * TURN_HZ
	speed += (omega * omega * error - 2.0 * TURN_DAMPING * omega * speed) * delta
	var top := deg_to_rad(TURN_TOP)
	return clampf(speed, -top, top)


## ── LAS ARMAS: DE DÓNDE SALEN Y ADÓNDE APUNTAN (ver GunnerWeapons) ─────────────────────────────────────────────

## Dónde está la minigun y su caja de misiles, en el espacio de la silla.
const GUN_AT := Vector3(0.82, 0.9, PIVOT.z)
const POD_AT := Vector3(-0.8, 0.98, PIVOT.z)
const POD_CELL := 0.11
## Los ojos del artillero, en el espacio de la silla: de ahí sale la mira.
const EYE := Vector3(0.0, 1.15, 0.02)
const AIM_REACH := 300.0


## LA BOCA DE LA MINIGUN (mundo): la punta de los caños, mirando adonde mira la cuna.
func minigun_muzzle() -> Transform3D:
	var tip := GUN_AT + Vector3(0.0, 0.0, -0.76 * WEAPON_SCALE)
	return Transform3D(frame.global_basis.orthonormalized(), frame.global_transform * tip)


## LA BOCA DEL TUBO `index` de la caja de misiles (mundo): de tres por dos, de arriba a la izquierda.
func missile_mouth(index: int) -> Transform3D:
	var column := index % 3
	var row := index / 3
	var spot := Vector3((column - 1) * POD_CELL, (0.5 - row) * POD_CELL, -POD_CELL * 2.5 - 0.02) * WEAPON_SCALE
	return Transform3D(frame.global_basis.orthonormalized(), frame.global_transform * (POD_AT + spot))


## ADÓNDE APUNTA (mundo): lo primero que toca la mira, derecho adelante desde los ojos, o lejos.
func aim_point() -> Vector3:
	var hit := _aim_ray(1 | PhysicsLayers.FIXED)
	if hit.is_empty():
		var eye := frame.global_transform * EYE
		return eye - frame.global_basis.z.normalized() * AIM_REACH
	return hit["position"]


## LO SUELTO QUE ESTÁ EN LA MIRA (un jefe, por la caja donde se le pega), o nada.
func aimed_body() -> Node3D:
	var hit := _aim_ray(1)
	return null if hit.is_empty() else EnergyBolt.struck(hit["collider"])


func _aim_ray(mask: int) -> Dictionary:
	var eye := frame.global_transform * EYE
	var far := eye - frame.global_basis.z.normalized() * AIM_REACH
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye, far, mask, skip()))


## LO QUE LO SUYO NO TIENE QUE TOCAR: la meca que la lleva, con todo lo que choca de ella.
func skip() -> Array[RID]:
	if _skip.is_empty():
		var node: Node = self
		while node != null and not node is BalanceBody:
			node = node.get_parent()
		if node != null:
			_skip.append((node as CollisionObject3D).get_rid())
			for found in node.find_children("*", "CollisionObject3D", true, false):
				_skip.append((found as CollisionObject3D).get_rid())
	return _skip.duplicate()


## ── LO QUE SE VE ─────────────────────────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	# EL PLATO Y LOS SOPORTES (no se inclinan).
	Clay.cylinder(yaw_node, 0.32, 0.06, Vector3(0.0, 0.03, 0.0), GUNMETAL)
	for side: float in [-1.0, 1.0]:
		_support(yaw_node, side * (BOLT_X + 0.07))
	# LA CUNA: los tornillos de los ejes en las caras del asiento; de cada uno, el brazo de su arma.
	for side: float in [-1.0, 1.0]:
		Clay.cylinder(frame, 0.055, 0.1, PIVOT + Vector3(side * (BOLT_X + 0.02), 0.0, 0.0), CageCabin.RIM_COLOR,
			Vector3(0.0, 0.0, 90.0))
	_arm(PIVOT + Vector3(BOLT_X + 0.08, 0.0, 0.0), GUN_AT + Vector3(-0.04, -0.16, 0.08), 1.0)
	_minigun(_holder(GUN_AT))
	_arm(PIVOT + Vector3(-BOLT_X - 0.08, 0.0, 0.0), POD_AT + Vector3(0.08, -0.26, 0.0), -1.0)
	_missiles(_holder(POD_AT), 3, 2, POD_CELL)
	_yoke()
	for spot: Vector3 in [Vector3(0.0, 0.92, -0.52), Vector3(-0.36, 0.82, -0.44), Vector3(0.36, 0.82, -0.44)]:
		var angle := atan2(spot.x, -spot.z)
		var foot := Vector3(signf(spot.x) * 0.2, 0.38, -0.2) if spot.x != 0.0 else Vector3(0.0, 0.62, -0.42)
		var elbow := (foot + spot) * 0.5 + Vector3(spot.x * 0.25, 0.0, -0.06)
		_beam(frame, foot, elbow, 0.02)
		_beam(frame, elbow, spot + Vector3(0.0, -0.06, 0.0), 0.018)
		Clay.sphere(frame, 0.03, elbow, GUNMETAL)
		var board := _panel(spot, angle, 35.0 if spot.x == 0.0 else 45.0)
		if spot.x == 0.0:
			_weapons_board(board)
		elif spot.x < 0.0:
			_ammo_board(board)
		else:
			_state_board(board)


## EL YUGO: una columna desde el borde de adelante del asiento, entre las rodillas, y la barra con las dos manijas, todo
## una pieza (lo que se agarra: GunnerYoke).
func _yoke() -> void:
	var top := Vector3(0.0, 0.6, -0.42)
	_beam(frame, Vector3(0.0, 0.38, -0.22), top, 0.028)
	var grip := StaticBody3D.new()
	grip.name = "Mando"
	grip.position = top
	frame.add_child(grip)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.38, 0.2, 0.1)
	shape.shape = box
	shape.position = Vector3(0.0, 0.1, 0.0)
	grip.add_child(shape)
	yoke = GunnerYoke.new()
	yoke.name = "Control"
	yoke.turret = self
	grip.add_child(yoke)
	yoke.build(box.size)
	var meshes: Array[MeshInstance3D] = [Clay.box(yoke, Vector3(0.32, 0.045, 0.05), Vector3(0.0, 0.06, 0.02), GRAB)]
	for side: float in [-1.0, 1.0]:
		meshes.append(Clay.box(yoke, Vector3(0.045, 0.13, 0.055), Vector3(side * 0.14, 0.12, 0.02), GRAB))
	yoke.highlighted.append_array(meshes)


## Un nodo para un arma en `at`, a la escala de las armas.
func _holder(at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.scale = Vector3.ONE * WEAPON_SCALE
	frame.add_child(holder)
	return holder


## UN BRAZO DE ARMA desde el tornillo `from` hasta `to`, con el codo hacia afuera (`side`).
func _arm(from: Vector3, to: Vector3, side: float) -> void:
	var elbow := Vector3(from.x + side * 0.16, (from.y + to.y) * 0.5, (from.z + to.z) * 0.5 + 0.08)
	_beam(frame, from, elbow, 0.03)
	_beam(frame, elbow, to, 0.028)
	Clay.sphere(frame, 0.045, elbow, GUNMETAL)


## EL SOPORTE DE UN EJE, macizo, en `x`: una chapa gruesa con la base recta (sobre el plato) y la parte de arriba curva
## en tres tramos alrededor del tornillo.
func _support(parent: Node3D, x: float) -> void:
	var points: Array[Vector2] = [Vector2(-0.24, 0.06), Vector2(0.24, 0.06)]
	for k in 4:
		var angle := deg_to_rad(15.0 + k * 50.0)
		points.append(Vector2(PIVOT.z, PIVOT.y) + Vector2(cos(angle), sin(angle)) * 0.11)
	var thick := 0.08
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: float in [-thick * 0.5, thick * 0.5]:
		for k in range(1, points.size() - 1):
			for point: Vector2 in [points[0], points[k], points[k + 1]]:
				tool.add_vertex(Vector3(x + face, point.y, point.x))
	for k in points.size():
		var a := points[k]
		var b := points[(k + 1) % points.size()]
		for corner: Vector3 in [Vector3(-1, a.y, a.x), Vector3(1, a.y, a.x), Vector3(1, b.y, b.x),
				Vector3(-1, a.y, a.x), Vector3(1, b.y, b.x), Vector3(-1, b.y, b.x)]:
			tool.add_vertex(Vector3(x + corner.x * thick * 0.5, corner.y, corner.z))
	tool.generate_normals()
	var plate := MeshInstance3D.new()
	plate.mesh = tool.commit()
	var paint := StandardMaterial3D.new()
	paint.albedo_color = FORK
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	plate.material_override = paint
	parent.add_child(plate)


## LA MINIGUN: el motor atrás, seis caños en rueda con dos aros, y el tambor de munición abajo.
func _minigun(parent: Node3D) -> void:
	Clay.box(parent, Vector3(0.14, 0.14, 0.22), Vector3(0.0, 0.0, 0.06), GUNMETAL)
	Clay.cylinder(parent, 0.075, 0.12, Vector3(0.0, 0.0, -0.1), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
	# Los caños y sus aros giran juntos (`_barrels`).
	_barrels = Node3D.new()
	_barrels.name = "Caños"
	parent.add_child(_barrels)
	for k in 6:
		var angle := TAU * k / 6.0
		var spot := Vector3(cos(angle), sin(angle), 0.0) * 0.045
		Clay.cylinder(_barrels, 0.014, 0.62, spot + Vector3(0.0, 0.0, -0.45), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	for z: float in [-0.42, -0.72]:
		Clay.cylinder(_barrels, 0.068, 0.025, Vector3(0.0, 0.0, z), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
	Clay.cylinder(parent, 0.09, 0.12, Vector3(0.0, -0.17, 0.05), CageCabin.YELLOW.darkened(0.25), Vector3(0.0, 0.0, 90.0))
	Clay.box(parent, Vector3(0.05, 0.12, 0.04), Vector3(0.0, -0.08, -0.02), GUNMETAL)


## LA CAJA DE MISILES: `columns` × `rows` tubos de `cell`, con las bocas adelante (−Z) y la tapa amarilla.
func _missiles(parent: Node3D, columns: int, rows: int, cell: float) -> void:
	var size := Vector3(columns * cell + 0.03, rows * cell + 0.03, cell * 5.0)
	Clay.box(parent, size, Vector3.ZERO, CageCabin.METAL)
	for c in columns:
		for k in rows:
			var spot := Vector3((c - (columns - 1) * 0.5) * cell, (k - (rows - 1) * 0.5) * cell, -size.z * 0.5 - 0.005)
			Clay.cylinder(parent, cell * 0.36, 0.012, spot, CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(parent, cell * 0.2, 0.014, spot, AMMO[2], Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(size.x + 0.01, 0.02, size.z * 0.6), Vector3(0.0, size.y * 0.5 + 0.01, 0.0), CageCabin.YELLOW)


## LOS TRES TABLEROS (18/11/2026; el usuario: «que se sientan como hechizos… muchos indicadores de cooldown… uno radial
## con el botón al medio, que es como funcionaría en la UI de un juego»; la recarga, «el timing de la recarga»; y el
## artillero no repara: «arreglar la nave de un panel de la silla de artillero se siente medio finique»). TODO SON
## BOTONES REDONDOS CON SU ARO (`_radial`): el botón al medio, y alrededor el aro que se llena con el tiempo de recarga;
## en el de cada arma, el aro marca además LA ZONA DE LA RECARGA CON RITMO (una aguja lo recorre y se vuelve a apretar
## en la zona: al instante y más fuerte; si no, lenta).
##   · AL MEDIO, LAS DOS ARMAS: un botón grande por arma (la minigun, gris; los misiles, amarillo): elige el arma, y
##     elegida, recarga. Arriba, la barra del calor de la minigun.
##   · A LA IZQUIERDA, LO DE LA MINIGUN: sobrecarga (el doble de cadencia un rato, el calor sube rápido), perforante (las
##     balas atraviesan) y enfriar (vacía el calor).
##   · A LA DERECHA, LO DE LOS MISILES: salva (los seis), guiado (uno, con el mouse) y fijar (marca un blanco y lo
##     persiguen).
## Los botones son de verdad (se aprietan: GunnerWeapons.press) y los aros, la barra y la aguja muestran lo que pasa
## (`_process`).
const BOARD := Vector2(0.32, 0.22)
const LIT := Color(0.4, 1.0, 0.45)
const OFF := Color(0.08, 0.1, 0.08)
const AMBER := Color(1.0, 0.72, 0.2)
## Los tramos de un aro.
const RING_STEPS := 20


## UN TABLERO en `at`, hacia `angle` (rad, 0 adelante), inclinado `lean` grados mirando al artillero: la chapa, y
## devuelve su cara (donde van las piezas: x a lo ancho, y a lo alto, +Z hacia el artillero).
func _panel(at: Vector3, angle: float, lean: float) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation = Vector3(0.0, -angle, 0.0)
	frame.add_child(holder)
	var face := Node3D.new()
	face.rotation_degrees = Vector3(-lean, 0.0, 0.0)
	holder.add_child(face)
	Clay.box(face, Vector3(BOARD.x, BOARD.y, 0.02), Vector3.ZERO, PLATE)
	return face


## AL MEDIO: LAS ARMAS (ver arriba).
func _weapons_board(face: Node3D) -> void:
	_heat_bar(face, Vector3(0.0, 0.08, 0.012))
	_radial(face, Vector3(-0.075, -0.025, 0.012), 0.05, CageCabin.METAL, "MINIGUN", "minigun")
	_radial(face, Vector3(0.075, -0.025, 0.012), 0.05, CageCabin.YELLOW, "MISILES", "misiles")


## A LA IZQUIERDA: LO DE LA MINIGUN (ver arriba).
func _ammo_board(face: Node3D) -> void:
	_radial(face, Vector3(-0.1, 0.0, 0.012), 0.036, Color(0.9, 0.45, 0.2), "SOBRECARGA", "sobrecarga")
	_radial(face, Vector3(0.0, 0.0, 0.012), 0.036, Color(0.7, 0.75, 0.85), "PERFORANTE", "perforante")
	_radial(face, Vector3(0.1, 0.0, 0.012), 0.036, Color(0.3, 0.7, 0.95), "ENFRIAR", "enfriar")


## A LA DERECHA: LO DE LOS MISILES (ver arriba).
func _state_board(face: Node3D) -> void:
	_radial(face, Vector3(-0.1, 0.0, 0.012), 0.036, CageCabin.YELLOW, "SALVA", "salva")
	_radial(face, Vector3(0.0, 0.0, 0.012), 0.036, Color(0.85, 0.35, 0.25), "GUIADO", "guiado")
	_radial(face, Vector3(0.1, 0.0, 0.012), 0.036, Color(0.6, 0.85, 0.4), "FIJAR", "fijar")


## LA BARRA DEL CALOR: se llena hacia la derecha (`_heat_fill`, ver `_process`), con la punta roja.
const HEAT_WIDTH := 0.2


func _heat_bar(face: Node3D, at: Vector3) -> void:
	Clay.box(face, Vector3(HEAT_WIDTH, 0.022, 0.012), at, OFF)
	Clay.box(face, Vector3(0.025, 0.022, 0.016), at + Vector3(HEAT_WIDTH * 0.5 - 0.0125, 0.0, 0.003), RED)
	_heat_fill = Node3D.new()
	_heat_fill.position = at + Vector3(-HEAT_WIDTH * 0.5, 0.0, 0.002)
	face.add_child(_heat_fill)
	Clay.box(_heat_fill, Vector3(1.0, 0.018, 0.014), Vector3(0.5, 0.0, 0.0), AMBER)
	_heat_fill.scale = Vector3(0.001, 1.0, 1.0)


## UN BOTÓN REDONDO CON SU ARO en `at` (en la cara), de `radius` (el aro; el botón, la mitad): EL BOTÓN de `tint` al
## medio, que se aprieta (un TouchComponent: GunnerWeapons.press con `action`), y EL ARO en tramos (ver `_process`).
## Abajo, su nombre.
func _radial(face: Node3D, at: Vector3, radius: float, tint: Color, title: String, action: String) -> void:
	Clay.cylinder(face, radius * 1.08, 0.008, at, SCREEN, Vector3(90.0, 0.0, 0.0))
	var body := StaticBody3D.new()
	body.name = "Botón %s" % action
	body.position = at + Vector3(0.0, 0.0, 0.008)
	face.add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(radius * 1.2, radius * 1.2, 0.03)
	shape.shape = box
	body.add_child(shape)
	var button := TouchComponent.new()
	button.name = "Control"
	body.add_child(button)
	button.build(box.size)
	var cap := Clay.cylinder(button, radius * 0.55, 0.022, Vector3.ZERO, tint, Vector3(90.0, 0.0, 0.0))
	button.highlighted.append(cap)
	button.pressed.connect(func() -> void: weapons.press(action))
	var ring: Array[MeshInstance3D] = []
	var step := TAU / RING_STEPS
	for k in RING_STEPS:
		# De arriba, en el sentido del reloj.
		var angle := k * step
		var middle := Vector2(sin(angle + step * 0.5), cos(angle + step * 0.5)) * radius * 0.82
		var piece := Clay.box(face, Vector3(radius * 0.22, radius * 0.24, 0.01), at + Vector3(middle.x, middle.y, 0.006), OFF)
		piece.rotation = Vector3(0.0, 0.0, -(angle + step * 0.5))
		ring.append(piece)
	var needle := Node3D.new()
	needle.position = at + Vector3(0.0, 0.0, 0.012)
	face.add_child(needle)
	Clay.box(needle, Vector3(0.004, radius * 0.4, 0.012), Vector3(0.0, radius * 0.82, 0.0), Color.WHITE)
	needle.visible = false
	_radials[action] = {"ring": ring, "needle": needle, "cap": cap, "tint": tint}
	var label := Label3D.new()
	label.text = title
	label.font_size = 32
	label.pixel_size = radius * 0.012
	label.outline_size = 0
	label.modulate = Color(0.9, 0.92, 0.85)
	label.position = at + Vector3(0.0, -radius * 1.35, 0.012)
	face.add_child(label)


## LO QUE MUESTRAN LOS TABLEROS, cada cuadro: EN CADA ARO, prendido hasta lo que tiene (el arma, lo que le queda
## cargado; una habilidad, lo que lleva de su tiempo de recarga). RECARGANDO un arma, su aro muestra la aguja y LA ZONA en
## ámbar (roja si se trabó). El botón del arma elegida, más claro. Y LA BARRA DEL CALOR (roja trabada).
## A toda vuelta, cuántas vueltas por segundo dan los caños de la minigun.
const BARREL_TURNS := 4.0


func _process(delta: float) -> void:
	if weapons == null:
		return
	if _barrels != null:
		_barrels.rotate_object_local(Vector3.BACK, weapons.spin * TAU * BARREL_TURNS * delta)
	for action: String in _radials:
		var radial: Dictionary = _radials[action]
		var ring: Array = radial["ring"]
		var weapon := 0 if action == "minigun" else (1 if action == "misiles" else -1)
		var reloading := weapon >= 0 and weapons.reloading == weapon
		var ready := weapons.needle if reloading else weapons.ready_of(action)
		for k in ring.size():
			var at := (k + 0.5) / ring.size()
			var paint := _off
			if reloading and at >= GunnerWeapons.ZONE.x and at <= GunnerWeapons.ZONE.y:
				paint = _red if weapons.reload_jammed else _amber
			elif float(k + 1) / ring.size() <= ready + 0.001:
				paint = _lit
			(ring[k] as MeshInstance3D).material_override = paint
		var needle := radial["needle"] as Node3D
		needle.visible = reloading
		if reloading:
			needle.rotation.z = -minf(weapons.needle, 1.0) * TAU
		if weapon >= 0:
			var cap := radial["cap"] as MeshInstance3D
			var tint: Color = radial["tint"]
			cap.material_override = _glow(tint) if weapons.selected == weapon else null
	if _heat_fill != null:
		_heat_fill.scale = Vector3(maxf(weapons.heat, 0.001) * HEAT_WIDTH, 1.0, 1.0)
		var fill := _heat_fill.get_child(0) as MeshInstance3D
		fill.material_override = _red if weapons.jammed else _amber


var _lit := EnergyBolt.shine(LIT)
var _off := _flat(OFF)
var _amber := EnergyBolt.shine(AMBER)
var _red := EnergyBolt.shine(RED)
var _glows := {}


func _flat(color: Color) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	return paint


## El botón del arma elegida: su color, más claro y que brilla.
func _glow(tint: Color) -> StandardMaterial3D:
	if not _glows.has(tint):
		_glows[tint] = EnergyBolt.shine(tint.lightened(0.35))
	return _glows[tint]


## UNA VIGA de `from` a `to`, de `radius`, en `parent`.
func _beam(parent: Node3D, from: Vector3, to: Vector3, radius: float) -> void:
	var piece := Clay.cylinder(parent, radius, from.distance_to(to), (from + to) * 0.5, GUNMETAL)
	var along := (to - from).normalized()
	var side := along.cross(Vector3.FORWARD if absf(along.y) > 0.5 else Vector3.UP).normalized()
	piece.basis = Basis(side, along, side.cross(along))
