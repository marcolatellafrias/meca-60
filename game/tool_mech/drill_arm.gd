class_name DrillArm
extends PoseArm

## EL TALADRO, el brazo de cuerpo a cuerpo de la Meca de tres (el usuario, 15/11/2026: «con el clic derecho… lo cargas y
## con el otro clic… lo usas, porque no lo puedes usar de una porque tarda en agarrar velocidad… su propia barra, y
## mientras más tiempo lo cargas… más energía gasta»). Es un brazo discreto (PoseArm) con una mecha en vez de mano:
##   · CARGAR (`charging`, mantenido): la mecha toma velocidad (`spin`, de 0 a 1, en SPIN_UP) y gasta energía de a poco,
##     más cuanto más rápido gira. Suelto, se va frenando sola.
##   · DESCARGAR (`strike`): un golpe derecho al frente, sin apuntar (es cinemático: el directo de siempre). Lo que toca
##     recibe el impulso de la piña por lo que giraba la mecha al tirarlo; después de pegar, gira mucho menos.

## En cuánto llega a girar a fondo cargando, y en cuánto se frena sola (s).
const SPIN_UP := 1.4
const SPIN_DOWN := 3.0
## Lo que gasta cargando (por segundo): lo de base, más lo que crece con lo que gira. Y lo que gasta el golpe.
const CHARGE_COST := 0.06
const SPIN_COST := 0.3
const STRIKE_COST := 0.04
## Lo mínimo que tiene que girar para pegar, y por cuánto multiplica el empujón del directo, de quieta a fondo.
const MIN_SPIN := 0.15
const PUSH_STILL := 0.4
const PUSH_FULL := 2.6
## Cuántas vueltas por segundo da a fondo (sólo se ve).
const TURNS := 9.0
const BIT := Color(0.62, 0.6, 0.55)

## Lo pide quien la maneja: cargando o no.
var charging := false
## Cuánto gira (0 a 1).
var spin := 0.0
## De dónde saca la energía (la de la meca).
var energy: MechEnergy = null

var _bit: Node3D = null
## Lo que giraba al tirar el golpe de ahora.
var _strike_spin := 0.0


func _ready() -> void:
	super()
	ArmorPlates.sleeve(_upper, measures.LEG_THICKNESS, upper_length())
	ArmorPlates.sleeve(_forearm, measures.LEG_THICKNESS, forearm_length())


## LA MECHA en vez de la mano: un collar y un cono que gira, apuntando a lo largo del antebrazo.
func _mount_hand(forearm: Node3D) -> void:
	var thick := measures.thick
	var holder := Node3D.new()
	holder.position = Vector3(0.0, 0.0, -forearm_length() * 0.5)
	holder.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	forearm.add_child(holder)
	Clay.cylinder(holder, 0.75 * thick, 0.5 * thick, Vector3(0.0, 0.25 * thick, 0.0), MechBody.JOINT_COLOR)
	_bit = Node3D.new()
	holder.add_child(_bit)
	var cone := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.6 * thick
	mesh.height = 2.4 * thick
	mesh.radial_segments = 6
	cone.mesh = mesh
	cone.material_override = Clay.material(BIT)
	cone.position = Vector3(0.0, (0.5 + 1.2) * thick, 0.0)
	_bit.add_child(cone)
	# Una aleta, para que se vea girar.
	Clay.box(_bit, Vector3(1.3 * thick, 0.12 * thick, 0.12 * thick), Vector3(0.0, 1.0 * thick, 0.0), BIT.darkened(0.4))


func _physics_process(delta: float) -> void:
	if charging and energy != null and energy.drain(CHARGE_COST + SPIN_COST * spin, delta):
		spin = minf(spin + delta / SPIN_UP, 1.0)
	else:
		charging = false
		spin = maxf(spin - delta / SPIN_DOWN, 0.0)
	if _bit != null:
		_bit.rotate_y(spin * TURNS * TAU * delta)
	super(delta)


## DESCARGA: el directo, si gira lo suficiente y alcanza la energía. Devuelve si pegó.
func strike() -> bool:
	if punching != Punch.NONE or spin < MIN_SPIN or energy == null or not energy.spend(STRIKE_COST):
		return false
	_strike_spin = spin
	if not punch(Punch.STRAIGHT):
		return false
	spin *= 0.3
	return true


func _hit(body: RigidBody3D, at: Vector3, velocity: Vector3) -> void:
	_struck[body.get_instance_id()] = true
	var push := lerpf(PUSH_STILL, PUSH_FULL, _strike_spin)
	BalanceBody.hit(body, velocity * PoseArmSettings.current.hit_mass * push, at - body.global_position)
	last_hit_speed = velocity.length()
	last_hit = body
