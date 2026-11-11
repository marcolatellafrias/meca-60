class_name MechArm
extends Node3D

## UN BRAZO DE LA MECA, de brazo común: hombro, brazo, codo, antebrazo y puño, colgado de un costado del torso (el nodo
## está en el hombro y no gira: su espacio es el del torso). Lo que se mueve es el puño; el codo sale solo (ver
## MechLeg.joint). Un brazo puede llevar EL CAÑÓN encima del antebrazo (`has_cannon`): el brazo sigue pegando igual.
##
## ── LA PIÑA ─────────────────────────────────────────────────────────────────────────────────────────────────────
## Lo pidió el usuario el 11/11/2026: «un golpe… que se carga con un tiempo y se suelta, y después se mueve la
## trayectoria, y que el daño de ese golpe dependa también de la velocidad con la que viene el cuerpo».
##   GUARDIA: el puño espera adelante, a la altura del pecho.
##   CARGAR (`hold`): el puño se va para atrás, hacia el hombro. Cuanto más se carga, más atrás va y más fuerte acelera.
##   SOLTAR (`let_go`): el puño sale hacia el punto apuntado ACELERANDO, no a una velocidad fija: la velocidad sale del
##     recorrido. De muy cerca pega flojo; cargado (más recorrido, más empuje) pega fuerte.
##   DOBLAR (`bend`): mientras viaja, el mouse lo empuja de costado o hacia arriba. El brazo tiene largo fijo: estirado,
##     el puño ya no sigue de largo y gira alrededor del hombro, así que doblar a tiempo da un gancho.
##   LO QUE TOCA: el puño barre su camino y se frena en lo primero que toca. Si eso tiene `take_hit` (otra meca), le
##     pega con la velocidad del puño EN EL MUNDO, que suma la marcha de la meca y el giro del torso. Un edificio lo traba
##     y nada más: no hay un empujón inventado (el usuario: sólo si sale solo de las reglas).

signal kicked(direction: Vector3, amount: float)

enum Phase { GUARD, CHARGE, STRIKE, RECOVER }

const UPPER := 5.5
const FOREARM := 5.5
const REACH := UPPER + FOREARM - 0.05
const CLOSEST := 2.5
const FIST_RADIUS := 1.2
## Dónde espera el puño y adónde va al cargar del todo (en el espacio del hombro, para el brazo izquierdo: `x` se da
## vuelta del otro lado).
const GUARD_POSE := Vector3(1.8, 0.3, -5.5)
const WINDUP_POSE := Vector3(-0.8, -1.2, -2.0)
const CHARGE_TIME := 0.8
## Cuánto acelera el puño al salir, sin carga y con la carga llena (m/s²), y lo más rápido que va.
const ACCEL_LOW := 90.0
const ACCEL_HIGH := 190.0
const TOP_SPEED := 70.0
const STRIKE_TIME := 0.55
## A qué velocidad va el puño a la guardia, a cargar y de vuelta (m/s).
const MOVE_SPEED := 22.0
## Cuánto dobla la piña cada píxel de mouse (m/s).
const BEND := 0.35
## Cuánto empuja el equilibrio del otro cada m/s del puño al pegar.
const HIT_PUSH := 0.1
## Cuánto se va el peso de la meca hacia adelante al soltar una piña cargada del todo.
const LEAN := 0.6
const CANNON_RELOAD := 0.7
const CANNON_KICK := 0.8
const NAMES := {Phase.GUARD: "guardia", Phase.CHARGE: "cargando", Phase.STRIKE: "pegando", Phase.RECOVER: "volviendo"}

## −1 el izquierdo, 1 el derecho.
var side := -1.0
var has_cannon := false
var glove_color := Clay.RED
var phase := Phase.GUARD
var charge := 0.0
## Los cuerpos propios que el puño atraviesa (el torso, el montacargas) y el torso, para que las balas no lo toquen.
var exclude: Array[RID] = []
var own_body: PhysicsBody3D = null
## La última piña: a qué velocidad pegó (0 si no pegó) y si se trabó contra algo que no se golpea.
var last_hit_speed := 0.0
var jammed := false

var _fist := Vector3.ZERO
var _velocity := Vector3.ZERO
var _drive := Vector3.FORWARD
var _clock := 0.0
var _last_global := Vector3.ZERO
var _reload := 0.0
var _sphere := SphereShape3D.new()
var _upper: MeshInstance3D = null
var _forearm: MeshInstance3D = null
var _elbow: MeshInstance3D = null
var _glove: Node3D = null
var _cannon: Node3D = null
var _barrel: Node3D = null


func _ready() -> void:
	_sphere.radius = FIST_RADIUS
	Clay.sphere(self, 1.3, Vector3.ZERO, Clay.DARK)
	_upper = Clay.box(self, Vector3.ONE, Vector3.ZERO, Clay.METAL.darkened(0.1))
	_forearm = Clay.box(self, Vector3.ONE, Vector3.ZERO, Clay.METAL.darkened(0.25))
	_elbow = Clay.sphere(self, 0.9, Vector3.ZERO, Clay.DARK)
	_glove = Node3D.new()
	_glove.name = "Puño"
	add_child(_glove)
	Clay.box(_glove, Vector3(2.0, 2.0, 2.2), Vector3.ZERO, glove_color)
	Clay.box(_glove, Vector3(2.2, 0.5, 1.2), Vector3(0, 0.6, -0.6), glove_color.darkened(0.3))
	if has_cannon:
		_cannon = Node3D.new()
		_cannon.name = "Cañón"
		add_child(_cannon)
		_barrel = Node3D.new()
		_cannon.add_child(_barrel)
		Clay.box(_cannon, Vector3(1.4, 1.0, 2.6), Vector3.ZERO, Clay.DARK)
		Clay.cylinder(_barrel, 0.4, 3.6, Vector3(0, 0, -2.6), Clay.DARK, Vector3(90, 0, 0))
		Clay.cylinder(_barrel, 0.55, 0.5, Vector3(0, 0, -4.3), Clay.DARK.darkened(0.3), Vector3(90, 0, 0))
	_fist = _pose(GUARD_POSE)
	_last_global = global_transform * _fist
	_draw()


func _pose(pose: Vector3) -> Vector3:
	return Vector3(pose.x * -side, pose.y, pose.z)


## Empieza a cargar (el clic apretado). Se puede cargar desde la guardia o mientras vuelve.
func hold() -> void:
	if phase == Phase.STRIKE or phase == Phase.CHARGE:
		return
	phase = Phase.CHARGE
	charge = 0.0


## Suelta la piña hacia `aim` (en el mundo). Sin cargar antes, no hace nada.
func let_go(aim: Vector3) -> void:
	if phase != Phase.CHARGE:
		return
	phase = Phase.STRIKE
	_clock = 0.0
	_velocity = Vector3.ZERO
	_drive = (to_local(aim) - _fist).normalized()
	last_hit_speed = 0.0
	jammed = false
	kicked.emit(global_basis * _drive, LEAN * charge)


## Dobla la piña que va saliendo: `amount` en píxeles de mouse (x a la derecha, y para arriba), visto desde atrás del
## puño.
func bend(amount: Vector2) -> void:
	if phase != Phase.STRIKE:
		return
	var right := _drive.cross(Vector3.UP)
	if right.length_squared() < 0.01:
		right = Vector3.RIGHT
	right = right.normalized()
	var up := right.cross(_drive).normalized()
	_velocity += (right * amount.x + up * amount.y) * BEND


## Corta lo que esté haciendo (la meca se cae).
func cancel() -> void:
	if phase == Phase.CHARGE or phase == Phase.STRIKE:
		phase = Phase.RECOVER
		_velocity = Vector3.ZERO


func is_striking() -> bool:
	return phase == Phase.STRIKE


## Dispara el cañón hacia `aim` (en el mundo), si lo tiene y está cargado. Devuelve si disparó.
func fire(aim: Vector3) -> bool:
	if not has_cannon or _reload > 0.0:
		return false
	_reload = CANNON_RELOAD
	var muzzle := _barrel.global_transform * Vector3(0, 0, -4.8)
	var direction := (aim - muzzle).normalized()
	var shell := MechShell.new()
	get_tree().current_scene.add_child(shell)
	if own_body != null:
		shell.add_collision_exception_with(own_body)
	shell.launch(muzzle, direction)
	_barrel.position.z = 1.2
	kicked.emit(-direction, CANNON_KICK)
	return true


func cannon_ready() -> bool:
	return has_cannon and _reload <= 0.0


func _physics_process(delta: float) -> void:
	_reload = maxf(_reload - delta, 0.0)
	if _barrel != null:
		_barrel.position.z = move_toward(_barrel.position.z, 0.0, 3.0 * delta)
	var wanted := _fist
	match phase:
		Phase.GUARD:
			wanted = _fist.move_toward(_pose(GUARD_POSE), MOVE_SPEED * delta)
		Phase.CHARGE:
			charge = minf(charge + delta / CHARGE_TIME, 1.0)
			wanted = _fist.move_toward(_pose(GUARD_POSE).lerp(_pose(WINDUP_POSE), charge), MOVE_SPEED * delta)
		Phase.RECOVER:
			wanted = _fist.move_toward(_pose(GUARD_POSE), MOVE_SPEED * 0.7 * delta)
			if wanted.is_equal_approx(_pose(GUARD_POSE)):
				phase = Phase.GUARD
		Phase.STRIKE:
			_clock += delta
			if _fist.length() < REACH - 0.1:
				_velocity += _drive * lerpf(ACCEL_LOW, ACCEL_HIGH, charge) * delta
			else:
				_velocity *= exp(-4.0 * delta)
			_velocity = _velocity.limit_length(TOP_SPEED)
			wanted = _fist + _velocity * delta
			if _clock > STRIKE_TIME:
				phase = Phase.RECOVER
				_velocity = Vector3.ZERO
	_move_to(_within_reach(wanted), delta)
	_draw()


## El brazo tiene largo fijo: el puño no pasa de `REACH` ni se mete en el hombro. Estirado, lo que iba hacia afuera se
## pierde y queda lo de costado: así gira.
func _within_reach(point: Vector3) -> Vector3:
	var length := point.length()
	if length > REACH:
		var radial := point / length
		if phase == Phase.STRIKE:
			_velocity -= radial * maxf(_velocity.dot(radial), 0.0)
		return radial * REACH
	if length < CLOSEST:
		return point.normalized() * CLOSEST if length > 0.001 else Vector3(0, 0, -CLOSEST)
	return point


## EL PUÑO BARRE SU CAMINO en el mundo, desde donde estaba el paso anterior (así cuenta lo que se movió la meca), y se
## frena en lo primero que toca.
func _move_to(wanted: Vector3, delta: float) -> void:
	var from := _last_global
	var to := global_transform * wanted
	var motion := to - from
	if motion.length() > 0.001:
		var space := get_world_3d().direct_space_state
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = _sphere
		query.transform = Transform3D(Basis(), from)
		query.motion = motion
		query.exclude = exclude
		var fractions := space.cast_motion(query)
		var safe := fractions[0]
		var unsafe := fractions[1]
		# [0, 0]: ya estaba metido en algo al empezar (la meca se le vino encima); lo deja salir en vez de pegarlo ahí.
		if unsafe < 1.0 and not (safe == 0.0 and unsafe == 0.0):
			query.transform = Transform3D(Basis(), from + motion * unsafe)
			query.motion = Vector3.ZERO
			var info := space.get_rest_info(query)
			_touch(info, motion / maxf(delta, 0.0001), from + motion * unsafe)
			to = from + motion * safe
			wanted = global_transform.affine_inverse() * to
	_fist = wanted
	_last_global = global_transform * _fist


## Lo que pasa cuando el puño toca algo: si va pegando y eso se golpea, le pega; si no, se traba. Vuelve a la guardia.
func _touch(info: Dictionary, world_velocity: Vector3, at: Vector3) -> void:
	if phase != Phase.STRIKE:
		return
	var target: Node = null
	if not info.is_empty():
		target = MechArm.hittable(instance_from_id(int(info["collider_id"])))
	if target != null:
		var direction := world_velocity.normalized()
		var speed := world_velocity.length()
		target.take_hit(speed, direction, speed * HIT_PUSH)
		last_hit_speed = speed
		MechShell.flash(get_tree().current_scene, at)
	else:
		jammed = true
	phase = Phase.RECOVER
	_velocity = Vector3.ZERO


func _draw() -> void:
	var elbow := MechLeg.joint(Vector3.ZERO, _fist, UPPER, FOREARM, Vector3(side, -0.8, 0.5))
	var wrist := _fist.normalized() * minf(_fist.length(), UPPER + FOREARM - 0.01)
	Clay.segment(_upper, Vector3.ZERO, elbow, 1.3)
	Clay.segment(_forearm, elbow, wrist, 1.1)
	_elbow.position = elbow
	var along := (wrist - elbow).normalized()
	var up := Vector3.UP if absf(along.dot(Vector3.UP)) < 0.95 else Vector3.BACK
	_glove.transform = Transform3D(Basis.looking_at(along, up), _fist)
	if _cannon != null:
		_cannon.transform = Transform3D(Basis.looking_at(along, up), elbow.lerp(wrist, 0.45) + Vector3.UP * 1.1)


## Lo que tenga `take_hit` en `collider` o en sus padres.
static func hittable(collider: Object) -> Node:
	var node := collider as Node
	while node != null:
		if node.has_method("take_hit"):
			return node
		node = node.get_parent()
	return null
