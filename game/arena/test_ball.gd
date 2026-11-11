class_name TestBall
extends RigidBody3D

## UNA BOLA DE PRUEBA para empujar cosas y ver cómo reaccionan: sale de la cámara, hacia donde se mira, a la velocidad
## de la FUERZA elegida. Choca de verdad (también con las piezas de un muñeco caído, capa 2) y desaparece sola. Si toca
## algo con `take_hit` (una meca de pelea), le pega como una bala.
##
## DOS BOLAS: la GRANDE, de 5 t, para la meca, y la CHICA, de 8 kg (una bola de bowling y un poco más), para las
## personas: con la grande, cualquier persona sale volando. La fuerza y la bola son una sola para todas las parcelas
## (ver `parcel_options`): J tira, K y L la fuerza, M la bola.

const RADIUS := 1.5
const BALL_MASS := 5000.0
const SMALL_RADIUS := 0.25
const SMALL_MASS := 8.0
const LIFETIME := 12.0
## Las fuerzas, en m/s: de una caricia a un cañonazo.
const SPEEDS := [10.0, 20.0, 30.0, 45.0, 60.0]

## Lo elegido, para todas las parcelas.
static var level := 2
static var small := false

var _age := 0.0
var _struck := {}


func _init() -> void:
	name = "Bola"
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
	body_entered.connect(_on_body)


func _ready() -> void:
	var radius := SMALL_RADIUS if small else RADIUS
	mass = SMALL_MASS if small else BALL_MASS
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	add_child(shape)
	Clay.sphere(self, radius, Vector3.ZERO, Clay.YELLOW.darkened(0.2))


## La tira desde la cámara activa, hacia donde mira, con la fuerza `force` (0 a 4) y la bola elegida.
static func throw_from_camera(scene: Node, force: int) -> TestBall:
	var camera := scene.get_viewport().get_camera_3d()
	if camera == null:
		return null
	var ball := TestBall.new()
	scene.add_child(ball)
	var forward := -camera.global_basis.z
	ball.global_position = camera.global_position + forward * ((SMALL_RADIUS if small else RADIUS) + 1.0)
	ball.linear_velocity = forward * float(SPEEDS[clampi(force, 0, SPEEDS.size() - 1)])
	return ball


## Las teclas de la bola, para cualquier parcela que las quiera.
static func parcel_options() -> Array[Dictionary]:
	return [
		{"key": KEY_J, "label": func() -> String: return "tirar una bola %s (fuerza %d de %d: %d m/s)" % [
				"chica" if small else "grande", level + 1, SPEEDS.size(), roundi(float(SPEEDS[level]))],
			"apply": func(parcel: SandboxParcel) -> void: TestBall.throw_from_camera(parcel, level)},
		{"key": KEY_K, "label": "menos fuerza",
			"apply": func(_parcel: SandboxParcel) -> void: level = maxi(level - 1, 0)},
		{"key": KEY_L, "label": "más fuerza",
			"apply": func(_parcel: SandboxParcel) -> void: level = mini(level + 1, SPEEDS.size() - 1)},
		{"key": KEY_M, "label": func() -> String: return "bola %s (cambiar)" % ("chica, 8 kg" if small else "grande, 5 t"),
			"apply": func(_parcel: SandboxParcel) -> void: small = not small},
	]


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
