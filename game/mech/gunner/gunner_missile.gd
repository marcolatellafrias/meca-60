class_name GunnerMissile
extends Node3D

## UN MISIL DEL ARTILLERO (ver GunnerWeapons): sale despacio de su tubo y acelera hasta `TOP`, con su estela de humo.
## Cómo va:
##   · DERECHO, sin `steer`: por donde salió.
##   · GUIADO: `steer` le dice cada paso adónde ir (adonde apunta la torreta mientras se la mueve) y se tuerce hacia ahí,
##     a lo más `TURN` grados por segundo.
##   · PERSIGUIENDO: `chase`, un nodo (el blanco fijado), se tuerce hacia él igual.
## Al tocar algo —o al cumplir su vida— EXPLOTA: destello, chispas y polvo, y a todo lo suelto en `RADIUS` le da su golpe
## (EnergyBolt.lands), entero en el medio y la mitad en el borde. EN RED cada máquina tiene el suyo (ver GunnerTurret,
## «La red»); el golpe lo aplica sólo el host.

const START := 25.0
const TOP := 85.0
const ACCEL := 140.0
const TURN := 140.0
const LIFE := 5.0
const RADIUS := 4.0
## El golpe de la explosión (kg·m/s) en el medio (ver EnergyBolt.lands).
const IMPULSE := 220000.0
const MASK := 1 | PhysicsLayers.FIXED
const BODY := Color(0.62, 0.6, 0.42)

## Adónde ir (mundo): una función sin argumentos que lo devuelve, o vacía; y el nodo que persigue.
var steer := Callable()
var chase: Node3D = null
var strength := 1.0
var skip: Array[RID] = []
var _speed := START
var _age := 0.0
## Cuántos se dibujaron en esta máquina (para los tests de red).
static var made := 0
var _trail: GPUParticles3D = null


func _ready() -> void:
	made += 1
	Clay.cylinder(self, 0.05, 0.42, Vector3.ZERO, BODY, Vector3(90.0, 0.0, 0.0))
	Clay.sphere(self, 0.05, Vector3(0.0, 0.0, -0.21), Color(0.85, 0.35, 0.25))
	_trail = ParticleSystems.thruster_smoke(ParticleMeshes.Kind.SPHERE, 0.5)
	_trail.position = Vector3(0.0, 0.0, 0.25)
	add_child(_trail)
	_trail.emitting = true


func _physics_process(delta: float) -> void:
	_age += delta
	_speed = minf(_speed + ACCEL * delta, TOP)
	var goal := Vector3.INF
	if is_instance_valid(chase):
		goal = chase.global_position
	elif steer.is_valid():
		goal = steer.call()
	if goal.is_finite():
		var ahead := -global_basis.z
		var wanted := (goal - global_position).normalized()
		var angle := ahead.angle_to(wanted)
		if angle > 0.001:
			var axis := ahead.cross(wanted).normalized()
			if axis.length() > 0.5:
				var turn := minf(angle, deg_to_rad(TURN) * delta)
				global_basis = Basis(axis, turn) * global_basis.orthonormalized()
	var from := global_position
	var to := from - global_basis.z * _speed * delta
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, MASK, skip))
	if not hit.is_empty():
		_explode(hit["position"])
		return
	global_position = to
	if _age > LIFE:
		_explode(global_position)


## EXPLOTA en `at`: lo que se ve, y el golpe a lo suelto del radio.
func _explode(at: Vector3) -> void:
	GunnerFx.blast(at, 1.6)
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = RADIUS
	query.shape = ball
	query.transform = Transform3D(Basis(), at)
	query.collision_mask = 1
	query.exclude = skip
	var struck := {}
	var hits: Array = [] if ProjectileField.is_client(self) else get_world_3d().direct_space_state.intersect_shape(query, 16)
	for found in hits:
		var body := EnergyBolt.struck(found["collider"])
		if body == null or struck.has(body.get_instance_id()):
			continue
		struck[body.get_instance_id()] = true
		var away := body.global_position - at
		var share := 1.0 - 0.5 * clampf(away.length() / RADIUS, 0.0, 1.0)
		EnergyBolt.lands(body, away.normalized() * IMPULSE * share * strength, at, "misil")
	# La estela se queda donde estaba y se apaga sola.
	if is_instance_valid(_trail):
		var keep := _trail.global_transform
		remove_child(_trail)
		get_tree().current_scene.add_child(_trail)
		_trail.global_transform = keep
		_trail.emitting = false
		get_tree().create_timer(_trail.lifetime + 0.5).timeout.connect(_trail.queue_free)
	queue_free()
