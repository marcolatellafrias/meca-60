class_name BossShot
extends Node3D

## ALGO QUE UN JEFE LANZA AL MUNDO (17/11/2026): una bomba, un misil, un cascote. La pieza común de los ataques de
## proyectiles (el usuario: «otra también puede ser la de esquivar proyectiles, más con física… tal vez unos poderes
## son físicos, otros kinemáticos, y tener esa flexibilidad»). Vuela y AVISA AL CAER (`landed`, con dónde): lo que pasa
## ahí lo decide el poder que la lanzó (pegar en una zona, largar una onda, otra cosa: «tal vez quiero una onda en el
## piso si golpeo con el puño… pero tal vez quiero una onda… como de un misil»). Dos maneras de volar:
##   · CINEMÁTICA (`launch`): un arco conocido, de dónde sale a dónde cae en tanto tiempo. Se sabe dónde cae: se puede
##     marcar en el piso desde que sale (BossZone).
##   · FÍSICA (`toss`): un cuerpo de verdad que cae con la gravedad y REBOTA en lo fijo; «cae» al cabo de tantos rebotes
##     (o de su mecha, s). No se sabe dónde termina: hay que mirarla.
## *Los proyectiles de la meca propia (Missile, AreaStrike, ProjectileField: por la red y empujando con física) son otro
## sistema, más viejo; cuando se defina la artillería, se juntan.*

signal landed(at: Vector3)

const COLOR := Color(0.2, 0.2, 0.22)
const GLOW := Color(1.0, 0.5, 0.1)

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _flight := 1.0
var _arc := 0.0
var _clock := 0.0
var _body: RigidBody3D = null
var _bounces_left := 0
var _fuse := 0.0
var _done := false


## CINEMÁTICA: de `from` a `to` (el piso) en `flight` s, subiendo `arc` m sobre la recta. `size`, su tamaño (m).
static func launch(parent: Node, from: Vector3, to: Vector3, flight: float, arc: float, size: float) -> BossShot:
	var shot := BossShot.new()
	shot.name = "Proyectil"
	shot._from = from
	shot._to = to
	shot._flight = maxf(flight, 0.05)
	shot._arc = arc
	parent.add_child(shot)
	shot.global_position = from
	shot._dress(shot, size)
	return shot


## FÍSICA: sale de `from` para caer cerca de `to` en `flight` s, y rebota `bounces` veces antes de «caer» (o a los
## `fuse` s). `size`, su tamaño (m).
static func toss(parent: Node, from: Vector3, to: Vector3, flight: float, bounces: int, fuse: float,
		size: float, ignore: Array[PhysicsBody3D] = []) -> BossShot:
	var shot := BossShot.new()
	shot.name = "Proyectil"
	shot._bounces_left = bounces
	shot._fuse = fuse
	parent.add_child(shot)
	shot.global_position = from
	var body := RigidBody3D.new()
	body.top_level = true
	body.collision_layer = 0
	body.collision_mask = PhysicsLayers.FIXED
	body.mass = 500.0
	body.contact_monitor = true
	body.max_contacts_reported = 4
	var bouncy := PhysicsMaterial.new()
	bouncy.bounce = 0.55
	bouncy.friction = 0.6
	body.physics_material_override = bouncy
	var ball := SphereShape3D.new()
	ball.radius = size * 0.5
	var holder := CollisionShape3D.new()
	holder.shape = ball
	body.add_child(holder)
	shot.add_child(body)
	# No rebota contra quien la lanzó (`ignore`).
	for other in ignore:
		if other != null:
			body.add_collision_exception_with(other)
	body.global_position = from
	var time := maxf(flight, 0.1)
	var gravity := Vector3.DOWN * float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	body.linear_velocity = (to - from) / time - gravity * time * 0.5
	body.angular_velocity = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
	body.body_entered.connect(shot._bounced)
	shot._body = body
	shot._dress(body, size)
	return shot


## Dónde está ahora (mundo).
func at() -> Vector3:
	return _body.global_position if _body != null else global_position


## ESTALLA YA, donde está (lo pide quien la lanzó: tocó a alguien).
func burst() -> void:
	if not _done:
		_land(at())


func _dress(on: Node3D, size: float) -> void:
	Clay.sphere(on, size * 0.5, Vector3.ZERO, COLOR)
	var band := Clay.box(on, Vector3(size * 1.05, size * 0.18, size * 1.05), Vector3.ZERO, GLOW)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = GLOW
	paint.emission_enabled = true
	paint.emission = GLOW
	band.material_override = paint


func _physics_process(delta: float) -> void:
	if _done:
		return
	_clock += delta
	if _body != null:
		if _fuse > 0.0 and _clock >= _fuse:
			_land(_body.global_position)
		return
	var t := minf(_clock / _flight, 1.0)
	global_position = _from.lerp(_to, t) + Vector3.UP * _arc * 4.0 * t * (1.0 - t)
	rotate_object_local(Vector3.RIGHT, delta * 4.0)
	if t >= 1.0:
		_land(_to)


func _bounced(_other: Node) -> void:
	if _done:
		return
	_bounces_left -= 1
	if _bounces_left < 0:
		_land(_body.global_position)


func _land(where: Vector3) -> void:
	_done = true
	landed.emit(where)
	queue_free()
