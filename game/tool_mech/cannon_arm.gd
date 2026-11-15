class_name CannonArm
extends PoseArm

## EL CAÑÓN DE ENERGÍA, el brazo a distancia de la Meca de tres (el usuario, 15/11/2026: «un cañón que dispare, que tenga
## varios modos de disparo… simple, varios disparos chicos, uno que barra y otro que sea un super disparo… el brazo del
## cañón… no sea físico en el sentido de con músculos… pero que sí se controle con una palanca y que no sea tan
## controlable… que se mueva como el de los músculos, pero sin la colisión»):
##   · LA PALANCA (`lever`, grados: x a la derecha, y arriba) dice adónde apuntar y QUEDA DONDE LA DEJARON. El brazo NO
##     va exacto: lo sigue UN RESORTE CON FRENO (`_aim`, `_aim_speed`), que llega tarde y se pasa un poco, como el de
##     músculos; atraviesa todo (es un brazo discreto).
##   · CADA TIRO LO PATEA para arriba (y un poco de costado): el retroceso. El súper tiro, mucho.
##   · LOS CUATRO MODOS (`mode`), con el gatillo (`trigger`, mantenido):
##       SIMPLE   un tiro mediano por apretada.
##       RÁFAGA   mientras se mantiene, tiros chicos seguidos, un poco abiertos.
##       BARRIDO  mientras se mantiene, un rayo que empuja lo que toca; se barre moviendo la palanca.
##       SÚPER    mientras se mantiene, carga (en SUPER_TIME); al soltar, un tiro grande según la carga.
##   Todo gasta la energía de la meca.
## *Que el súper tiro tire a la meca para atrás, después (a la cinemática todavía no la mueve un golpe).*

enum Mode { SIMPLE, BURST, BEAM, SUPER }
const MODE_NAMES := ["simple", "ráfaga", "barrido", "súper"]

## LA PALANCA: hasta dónde (grados) y a qué velocidad la mueven las teclas (grados por segundo).
const LEVER_YAW := 35.0
const LEVER_UP := 30.0
const LEVER_DOWN := -35.0
const LEVER_SPEED := 45.0
## EL RESORTE que sigue a la palanca: lo duro y el freno (con estos, llega en medio segundo y se pasa un poco).
const STIFF := 28.0
const DAMP := 4.5
## Lo que se estira el brazo apuntando (partes de lo que mide estirado): casi derecho, así el caño (en el antebrazo)
## mira adonde apunta. Doblado, el antebrazo apuntaba para arriba.
const STRETCH := 0.995

## SIMPLE: lo que gasta, lo que espera entre tiros (s), lo que empuja y la patada (grados por segundo).
const SIMPLE_COST := 0.06
const SIMPLE_WAIT := 0.3
const SIMPLE_PUSH := 70000.0
const SIMPLE_KICK := 70.0
## RÁFAGA.
const BURST_COST := 0.012
const BURST_WAIT := 0.09
const BURST_PUSH := 15000.0
const BURST_KICK := 14.0
const BURST_SPREAD := 1.5
## BARRIDO: lo que gasta y empuja por segundo, y hasta dónde llega (m).
const BEAM_COST := 0.32
const BEAM_PUSH := 150000.0
const BEAM_RANGE := 90.0
## SÚPER: en cuánto carga a fondo (s), lo que gasta por segundo cargando (y ya cargado), lo mínimo para tirar, lo que
## empuja a fondo y la patada a fondo.
const SUPER_TIME := 1.2
const SUPER_COST := 0.3
const SUPER_HOLD_COST := 0.08
const SUPER_MIN := 0.15
const SUPER_PUSH := 600000.0
const SUPER_KICK := 260.0

const GLOW := Color(1.0, 0.55, 0.15)

var mode := Mode.SIMPLE
## Lo piden quienes la manejan: el gatillo apretado, y la palanca (grados).
var trigger := false
var lever := Vector2(0.0, -5.0)
## De dónde saca la energía (la de la meca).
var energy: MechEnergy = null
## La carga del súper tiro (0 a 1).
var charge := 0.0

var _aim := Vector2(0.0, -5.0)
var _aim_speed := Vector2.ZERO
var _wait := 0.0
var _trigger_was := false
var _barrel := 0.0
var _beam: MeshInstance3D = null
var _ball: MeshInstance3D = null


func _ready() -> void:
	super()
	ArmorPlates.sleeve(_upper, measures.LEG_THICKNESS, upper_length())
	ArmorPlates.sleeve(_forearm, measures.LEG_THICKNESS, forearm_length())
	_beam = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 0.35, 1.0)
	_beam.mesh = box
	_beam.material_override = EnergyBolt.shine(GLOW)
	_beam.visible = false
	add_child(_beam)
	_ball = MeshInstance3D.new()
	_ball.mesh = SphereMesh.new()
	_ball.material_override = EnergyBolt.shine(GLOW)
	_ball.visible = false
	add_child(_ball)


## EL CAÑÓN en vez de la mano: una caja, el caño y un aro que brilla en la boca.
func _mount_hand(forearm: Node3D) -> void:
	var thick := measures.thick
	var tip := -forearm_length() * 0.5
	Clay.box(forearm, Vector3(1.1, 1.1, 1.4) * thick, Vector3(0.0, 0.0, tip - 0.7 * thick), MechBody.JOINT_COLOR)
	Clay.cylinder(forearm, 0.32 * thick, 1.8 * thick, Vector3(0.0, 0.0, tip - 2.3 * thick), Clay.METAL.darkened(0.35),
		Vector3(90.0, 0.0, 0.0))
	var ring := Clay.cylinder(forearm, 0.4 * thick, 0.15 * thick, Vector3(0.0, 0.0, tip - 3.2 * thick), GLOW,
		Vector3(90.0, 0.0, 0.0))
	ring.material_override = EnergyBolt.shine(GLOW)
	_barrel = 3.3 * thick


## MUEVE LA PALANCA (`way`: x a la derecha, y arriba, de −1 a 1) este paso. Queda donde la dejan.
func move_lever(way: Vector2, delta: float) -> void:
	lever += way * LEVER_SPEED * delta
	lever.x = clampf(lever.x, -LEVER_YAW, LEVER_YAW)
	lever.y = clampf(lever.y, LEVER_DOWN, LEVER_UP)


## DÓNDE SE PIDE EL PUÑO: adonde apunta el resorte, el brazo casi estirado (como `STANCES`: x hacia afuera de su lado).
func _wanted() -> Vector3:
	var yaw := deg_to_rad(_aim.x)
	var pitch := deg_to_rad(_aim.y)
	var way := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	var length := (upper_length() + forearm_length()) * STRETCH
	return Vector3(side * way.x, way.y, way.z) * length


func _physics_process(delta: float) -> void:
	# EL RESORTE: el brazo persigue a la palanca, con su freno.
	_aim_speed += ((lever - _aim) * STIFF - _aim_speed * DAMP) * delta
	_aim += _aim_speed * delta
	super(delta)
	_fire(delta)


## LA BOCA del caño y hacia dónde mira (mundo).
func muzzle() -> Transform3D:
	var forearm := _forearm.global_transform
	var tip := forearm.origin - forearm.basis.z * (forearm_length() * 0.5 + _barrel)
	return Transform3D(forearm.basis, tip)


## EL GATILLO, según el modo.
func _fire(delta: float) -> void:
	_wait = maxf(_wait - delta, 0.0)
	var pressed := trigger and not _trigger_was
	var released := _trigger_was and not trigger
	_trigger_was = trigger
	var beaming := false
	match mode:
		Mode.SIMPLE:
			if pressed and _wait <= 0.0 and energy.spend(SIMPLE_COST):
				_shot(0.0, 140.0, SIMPLE_PUSH, 0.35)
				_kick(SIMPLE_KICK)
				_wait = SIMPLE_WAIT
		Mode.BURST:
			if trigger and _wait <= 0.0 and energy.spend(BURST_COST):
				_shot(BURST_SPREAD, 160.0, BURST_PUSH, 0.18)
				_kick(BURST_KICK)
				_wait = BURST_WAIT
		Mode.BEAM:
			beaming = trigger and energy.drain(BEAM_COST, delta)
			if beaming:
				_beam_step(delta)
		Mode.SUPER:
			if trigger:
				var cost := SUPER_COST if charge < 1.0 else SUPER_HOLD_COST
				if energy.drain(cost, delta):
					charge = minf(charge + delta / SUPER_TIME, 1.0)
				else:
					charge = 0.0
			elif released and charge >= SUPER_MIN:
				_shot(0.0, 110.0, SUPER_PUSH * charge, 0.5 + 0.6 * charge)
				_kick(SUPER_KICK * charge)
				charge = 0.0
			else:
				charge = 0.0
	_beam.visible = beaming
	_ball.visible = mode == Mode.SUPER and charge > 0.0
	if _ball.visible:
		_ball.global_position = muzzle().origin
		_ball.scale = Vector3.ONE * (0.4 + 1.6 * charge)


## UN TIRO desde la boca, abierto hasta `spread` grados.
func _shot(spread: float, speed: float, push: float, radius: float) -> void:
	var from := muzzle()
	var turn := Basis(Vector3.UP, deg_to_rad(randf_range(-spread, spread))) * Basis(Vector3.RIGHT,
		deg_to_rad(randf_range(-spread, spread)))
	var bolt := EnergyBolt.new()
	bolt.speed = speed
	bolt.push = push
	bolt.radius = radius
	bolt.color = GLOW
	bolt.exclude = [anchor.get_rid()]
	anchor.get_parent().add_child(bolt)
	bolt.global_transform = Transform3D(from.basis * turn, from.origin)
	EnergyBolt.flash(anchor.get_parent(), from.origin, radius * 2.0, GLOW)


## EL RETROCESO: una patada para arriba (grados por segundo) y un poco de costado.
func _kick(strength: float) -> void:
	_aim_speed += Vector2(randf_range(-0.25, 0.25) * strength, strength)


## EL RAYO este paso: hasta lo primero que toca (o su alcance), y lo que toca, empujado.
func _beam_step(delta: float) -> void:
	var from := muzzle()
	var way := -from.basis.z
	var query := PhysicsRayQueryParameters3D.create(from.origin, from.origin + way * BEAM_RANGE, EnergyBolt.MASK,
		[anchor.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var end := from.origin + way * BEAM_RANGE
	if not hit.is_empty():
		end = hit["position"]
		var body := EnergyBolt.struck(hit["collider"])
		if body != null:
			EnergyBolt.lands(body, way * BEAM_PUSH * delta, end, "rayo")
	var length := from.origin.distance_to(end)
	_beam.global_transform = Transform3D(from.basis * Basis.from_scale(Vector3(1.0, 1.0, length)), (from.origin + end) * 0.5)
	_kick(randf_range(-6.0, 6.0))
