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
## vaya con la cuna; la cabeza mira libre en su cono. Todavía no dispara (el usuario: primero cómo se siente girar).
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
	var gun := Vector3(0.82, 0.9, PIVOT.z)
	_arm(PIVOT + Vector3(BOLT_X + 0.08, 0.0, 0.0), gun + Vector3(-0.04, -0.16, 0.08), 1.0)
	_minigun(_holder(gun))
	var pod := Vector3(-0.98, 0.98, PIVOT.z)
	_arm(PIVOT + Vector3(-BOLT_X - 0.08, 0.0, 0.0), pod + Vector3(0.08, -0.26, 0.0), -1.0)
	_missiles(_holder(pod), 3, 2, 0.11)
	_yoke()
	for spot: Vector3 in [Vector3(0.0, 0.92, -0.52), Vector3(-0.36, 0.82, -0.44), Vector3(0.36, 0.82, -0.44)]:
		var angle := atan2(spot.x, -spot.z)
		var foot := Vector3(signf(spot.x) * 0.2, 0.38, -0.2) if spot.x != 0.0 else Vector3(0.0, 0.62, -0.42)
		var elbow := (foot + spot) * 0.5 + Vector3(spot.x * 0.25, 0.0, -0.06)
		_beam(frame, foot, elbow, 0.02)
		_beam(frame, elbow, spot + Vector3(0.0, -0.06, 0.0), 0.018)
		Clay.sphere(frame, 0.03, elbow, GUNMETAL)
		_panel(spot, angle, 35.0 if spot.x == 0.0 else 45.0)


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
	for k in 6:
		var angle := TAU * k / 6.0
		var spot := Vector3(cos(angle), sin(angle), 0.0) * 0.045
		Clay.cylinder(parent, 0.014, 0.62, spot + Vector3(0.0, 0.0, -0.45), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	for z: float in [-0.42, -0.72]:
		Clay.cylinder(parent, 0.068, 0.025, Vector3(0.0, 0.0, z), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
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


## UN TABLERO en `at`, hacia `angle` (rad, 0 adelante), inclinado `lean` grados mirando al artillero. Por ahora, sólo se
## ve: la munición por color, dos relojes, el calor y tres recargas.
func _panel(at: Vector3, angle: float, lean: float) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation = Vector3(0.0, -angle, 0.0)
	frame.add_child(holder)
	var tilted := Node3D.new()
	tilted.rotation_degrees = Vector3(-lean, 0.0, 0.0)
	holder.add_child(tilted)
	var w := 0.26
	var h := 0.18
	Clay.box(tilted, Vector3(w, h, 0.02), Vector3.ZERO, PLATE)
	var front := 0.015
	for k in 3:
		Clay.box(tilted, Vector3(w * 0.12, h * 0.16, 0.012), Vector3(-w * 0.32 + k * w * 0.16, -h * 0.28, front), AMMO[k])
	for k in 2:
		Clay.cylinder(tilted, h * 0.13, 0.008, Vector3(-w * 0.3 + k * w * 0.22, h * 0.16, front), SCREEN,
			Vector3(90.0, 0.0, 0.0))
	Clay.box(tilted, Vector3(w * 0.05, h * 0.45, 0.012), Vector3(w * 0.4, -h * 0.12, front), RED)
	for k in 3:
		Clay.box(tilted, Vector3(w * 0.22 * (0.3 + k * 0.3), h * 0.06, 0.012),
			Vector3(w * 0.15 - w * 0.11 * (0.7 - k * 0.3), h * (0.28 - k * 0.12), front), GREEN)


## UNA VIGA de `from` a `to`, de `radius`, en `parent`.
func _beam(parent: Node3D, from: Vector3, to: Vector3, radius: float) -> void:
	var piece := Clay.cylinder(parent, radius, from.distance_to(to), (from + to) * 0.5, GUNMETAL)
	var along := (to - from).normalized()
	var side := along.cross(Vector3.FORWARD if absf(along.y) > 0.5 else Vector3.UP).normalized()
	piece.basis = Basis(side, along, side.cross(along))
