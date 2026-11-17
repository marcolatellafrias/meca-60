class_name CannonTip
extends ArmTip

## EL CAÑÓN DE ENERGÍA EN LUGAR DEL ANTEBRAZO (el usuario, 15/11/2026: «un cañón que dispare, que tenga varios modos de
## disparo… simple, varios disparos chicos, uno que barra y otro que sea un super disparo… que sí se controle con una
## palanca y que no sea tan controlable… que se mueva como el de los músculos, pero sin la colisión»; de la meca jaula:
## «el cañón… debería reemplazar el antebrazo… que quede con el cañón el mismo largo que tendría con el puño»; y el
## 16/11/2026, que todas lo lleven así: «reemplazar antebrazo»):
##   · LA FORMA (la de la maqueta, tests/cage_ideas_look, 147 a 173): sin el cilindro del antebrazo; desde el codo, un
##     cuello y el caño gris oscuro con dos aros y la boca, armado en la medida de la meca entera y achicado al ancho de
##     ésta. El antebrazo no lleva placa.
##   · LA PALANCA (`lever`, grados: x a la derecha, y arriba) dice adónde apuntar y QUEDA DONDE LA DEJARON. El brazo NO
##     va exacto: lo sigue UN RESORTE CON FRENO (`_aim`, `_aim_speed`), que llega tarde y se pasa un poco. Mientras tanto
##     no importan las posturas ni las piñas: el brazo va adonde apunta, casi estirado.
##   · CADA TIRO LO PATEA para arriba (y un poco de costado): el retroceso. El súper tiro, mucho.
##   · LOS CUATRO MODOS (`mode`), con el gatillo (`trigger`, mantenido):
##       SIMPLE   un tiro mediano por apretada.
##       RÁFAGA   mientras se mantiene, tiros chicos seguidos, un poco abiertos.
##       BARRIDO  mientras se mantiene, un rayo que empuja lo que toca; se barre moviendo la palanca.
##       SÚPER    mientras se mantiene, carga (en SUPER_TIME); al soltar, un tiro grande según la carga.
##   Todo gasta la energía de la meca.
## *Hasta el 16/11/2026 eran dos brazos discretos: CannonArm (la Meca de tres y la de cápsulas: una caja y un caño fino
## después del antebrazo, con fundas de chapa) y CageCannonArm (la jaula: éste, en lugar del antebrazo).*
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
## Lo que se estira el brazo apuntando (partes de lo que mide estirado): casi derecho, así el caño mira adonde apunta.
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
## La carga del súper tiro (0 a 1).
var charge := 0.0

## Lo que se estira apuntando (ver STRETCH); lo cambian las maquetas de reposo (tests/arm_rest_look).
var stretch := STRETCH

var _aim := Vector2(0.0, -5.0)
var _aim_speed := Vector2.ZERO
var _wait := 0.0
var _trigger_was := false
## Lo que va de la punta de la pieza del antebrazo a la boca (m).
var _barrel := 0.0
var _beam: MeshInstance3D = null
var _ball: MeshInstance3D = null


func _build() -> void:
	if arm.forearm_skin != null:
		arm.forearm_skin.visible = false
	var k := arm.measures.thick
	var holder := Node3D.new()
	holder.name = "Cañón"
	holder.scale = Vector3.ONE * k
	forearm.add_child(holder)
	var elbow := arm.forearm_length() * 0.5 / k
	var muzzle_at := ArmoryParts.TIP - 1.4
	Clay.cylinder(holder, 1.15, 1.0, Vector3(0, 0, elbow - 0.9), Clay.METAL.darkened(0.1), Vector3(90, 0, 0))
	var from := elbow - 1.4
	var to := muzzle_at + 0.8
	Clay.cylinder(holder, 1.45, from - to, Vector3(0, 0, (from + to) * 0.5), ArmoryParts.CANNON_COLOR, Vector3(90, 0, 0))
	for z: float in [from - 0.6, (from + to) * 0.5]:
		Clay.cylinder(holder, 1.55, 0.25, Vector3(0, 0, z), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	Clay.cylinder(holder, 1.05, 0.8, Vector3(0, 0, muzzle_at + 0.4), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	Clay.cylinder(holder, 0.6, 0.1, Vector3(0, 0, muzzle_at - 0.02), Clay.DARK, Vector3(90, 0, 0))
	# Los tiros salen de la boca (ver `muzzle`: el largo más allá de la punta del antebrazo).
	_barrel = -muzzle_at * k - arm.forearm_length() * 0.5
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


func plates_forearm() -> bool:
	return false


## MUEVE LA PALANCA (`way`: x a la derecha, y arriba, de −1 a 1) este paso. Queda donde la dejan.
func move_lever(way: Vector2, delta: float) -> void:
	lever += way * LEVER_SPEED * delta
	lever.x = clampf(lever.x, -LEVER_YAW, LEVER_YAW)
	lever.y = clampf(lever.y, LEVER_DOWN, LEVER_UP)


## DÓNDE SE PIDE EL PUÑO: adonde apunta el resorte, el brazo casi estirado (como MechArm.STANCES: x hacia afuera de su
## lado).
func wanted(_asked: Vector3) -> Vector3:
	var yaw := deg_to_rad(_aim.x)
	var pitch := deg_to_rad(_aim.y)
	var way := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	var length := (arm.upper_length() + arm.forearm_length()) * stretch
	return Vector3(arm.side * way.x, way.y, way.z) * length


## EL RESORTE (el brazo persigue a la palanca, con su freno) y EL GATILLO.
func step(delta: float) -> void:
	_aim_speed += ((lever - _aim) * STIFF - _aim_speed * DAMP) * delta
	_aim += _aim_speed * delta
	_fire(delta)


func status() -> String:
	return "cañón: %s%s" % [MODE_NAMES[mode], (" %s" % BodyMoves._bar(charge)) if mode == Mode.SUPER else ""]


## LA BOCA del caño y hacia dónde mira (mundo).
func muzzle() -> Transform3D:
	var piece := forearm.global_transform
	var end := piece.origin - piece.basis.z * (arm.forearm_length() * 0.5 + _barrel)
	return Transform3D(piece.basis, end)


## EL GATILLO, según el modo.
func _fire(delta: float) -> void:
	_wait = maxf(_wait - delta, 0.0)
	var pressed := trigger and not _trigger_was
	var released := _trigger_was and not trigger
	_trigger_was = trigger
	var beaming := false
	match mode:
		Mode.SIMPLE:
			if pressed and _wait <= 0.0 and energy != null and energy.spend(SIMPLE_COST):
				_shot(0.0, 140.0, SIMPLE_PUSH, 0.35)
				_kick(SIMPLE_KICK)
				_wait = SIMPLE_WAIT
		Mode.BURST:
			if trigger and _wait <= 0.0 and energy != null and energy.spend(BURST_COST):
				_shot(BURST_SPREAD, 160.0, BURST_PUSH, 0.18)
				_kick(BURST_KICK)
				_wait = BURST_WAIT
		Mode.BEAM:
			beaming = trigger and energy != null and energy.drain(BEAM_COST, delta)
			if beaming:
				_beam_step(delta)
		Mode.SUPER:
			if trigger:
				var cost := SUPER_COST if charge < 1.0 else SUPER_HOLD_COST
				if energy != null and energy.drain(cost, delta):
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
	bolt.exclude = [arm.anchor.get_rid()]
	arm.anchor.get_parent().add_child(bolt)
	bolt.global_transform = Transform3D(from.basis * turn, from.origin)
	EnergyBolt.flash(arm.anchor.get_parent(), from.origin, radius * 2.0, GLOW)


## EL RETROCESO: una patada para arriba (grados por segundo) y un poco de costado.
func _kick(strength: float) -> void:
	_aim_speed += Vector2(randf_range(-0.25, 0.25) * strength, strength)


## EL RAYO este paso: hasta lo primero que toca (o su alcance), y lo que toca, empujado.
func _beam_step(delta: float) -> void:
	var from := muzzle()
	var way := -from.basis.z
	var query := PhysicsRayQueryParameters3D.create(from.origin, from.origin + way * BEAM_RANGE, EnergyBolt.MASK,
		[arm.anchor.get_rid()])
	var hit_info := get_world_3d().direct_space_state.intersect_ray(query)
	var end := from.origin + way * BEAM_RANGE
	if not hit_info.is_empty():
		end = hit_info["position"]
		var body := EnergyBolt.struck(hit_info["collider"])
		if body != null:
			EnergyBolt.lands(body, way * BEAM_PUSH * delta, end, "rayo")
	var length := from.origin.distance_to(end)
	_beam.global_transform = Transform3D(from.basis * Basis.from_scale(Vector3(1.0, 1.0, length)), (from.origin + end) * 0.5)
	_kick(randf_range(-6.0, 6.0))
