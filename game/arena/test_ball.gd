class_name TestBall
extends RigidBody3D

## UNA BOLA DE PRUEBA para empujar cosas y ver cómo reaccionan: una bola pesada que sale de la cámara, hacia donde se
## mira, a la velocidad de la FUERZA elegida (ver BalanceTestArchetype). Choca de verdad (también con las piezas de un
## muñeco caído, capa 2) y desaparece sola. Si toca algo con `take_hit` (una meca de pelea), le pega como una bala.

const RADIUS := 1.5
const BALL_MASS := 5000.0
const LIFETIME := 12.0
## Las fuerzas, en m/s: de una caricia a un cañonazo.
const SPEEDS := [10.0, 20.0, 30.0, 45.0, 60.0]

var _age := 0.0
var _struck := {}


func _init() -> void:
	name = "Bola"
	mass = BALL_MASS
	continuous_cd = true
	collision_mask = 1 | 2
	# Cae poco, como las balas del cañón: así llega aunque vaya lenta.
	gravity_scale = 0.25
	contact_monitor = true
	max_contacts_reported = 4
	var bouncy := PhysicsMaterial.new()
	bouncy.bounce = 0.1
	bouncy.friction = 0.6
	physics_material_override = bouncy
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	shape.shape = sphere
	add_child(shape)
	Clay.sphere(self, RADIUS, Vector3.ZERO, Clay.YELLOW.darkened(0.2))
	body_entered.connect(_on_body)


## La tira desde la cámara activa, hacia donde mira, con la fuerza `level` (0 a 4).
static func throw_from_camera(scene: Node, level: int) -> TestBall:
	var camera := scene.get_viewport().get_camera_3d()
	if camera == null:
		return null
	var ball := TestBall.new()
	scene.add_child(ball)
	var forward := -camera.global_basis.z
	ball.global_position = camera.global_position + forward * (RADIUS + 1.5)
	ball.linear_velocity = forward * float(SPEEDS[clampi(level, 0, SPEEDS.size() - 1)])
	return ball


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body(body: Node) -> void:
	var target := MechArm.hittable(body)
	if target == null or _struck.has(target.get_instance_id()):
		return
	_struck[target.get_instance_id()] = true
	var speed := linear_velocity.length()
	target.take_hit(speed, linear_velocity.normalized(), speed * MechArm.HIT_PUSH)
