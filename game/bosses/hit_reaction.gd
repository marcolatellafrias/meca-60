class_name HitReaction
extends Node

## LO QUE LE HACE UN GOLPE DE UN JEFE A QUIEN RECIBE (15/11/2026), como en los jefes de Souls: el daño lo decide la
## cabeza del jefe (sus zonas de golpe, ver docs/technical/pelea-jefes.md) y acá pasa lo que se ve. Se cuelga solo
## («Reacción») de quien recibe la primera vez. El usuario: «la mecha se hace hacia atrás… pero que sea algo cinemático…
## con un indicador que muestre cuando le pegan un golpe, como que se vuelve blanca por un segundo… una partícula… una
## audio cue».
##   · SIEMPRE: SE PONE BLANCA un momento (un material encima de todas sus mallas), CHISPAS donde pegó y un SONIDO
##     (BossSounds).
##   · LA REACCIÓN (`Kind`), según el ataque: AGUANTA (no se mueve); EMPUJADA, se corre tantos metros, parada; DERRIBADA,
##     sale para atrás con un saltito y cae de espaldas, tirada, y se levanta. Y las del agarre: AGARRADA (la lleva el
##     jefe) y REVOLEADA (vuela en arco y, al caer, derribada).
##   · MOVERLA Y CAERSE LO HACE LA MECA (módulo Meca, a pedido de este; el usuario: «estás peleando contra un sistema de
##     gravedad y IK… arreglalo de raíz»): `BalanceBody.shove` (la corre su motor, sin manejarse) y
##     `BalanceBody.knock_down` (cae, tirada y se levanta; los brazos y las piernas la siguen solos). Acá sólo se le pide.
##     A la física, un impulso: se cae con su física.
## *Antes esto la movía e inclinaba desde afuera, pieza por pieza, después de su paso: se peleaba con sus piernas y sus
## brazos (el torso se salía, los brazos quedaban en el aire).*

enum Kind { FLINCH, PUSH, KNOCKDOWN }
enum State { FREE, HELD, FLYING }

const NODE_NAME := "Reacción"
## El destello (s); empujada, en cuánto se corre (s); derribada, en cuánto sale para atrás (s) y su saltito (m).
const FLASH_TIME := 0.3
const PUSH_TIME := 0.35
const FALL_TIME := 0.5
const FALL_HOP := 3.0
## Lo que se corre la física por cada metro de empuje (m/s).
const PHYSICAL_SPEED := 1.2

## Agarrada o revoleada (lo demás lo sabe la meca).
var state := State.FREE
## Cuántos golpes recibió (para mirar).
var hits := 0

var _target: Node3D = null
var _body: BalanceBody = null
var _clock := 0.0
var _time := 0.0
var _away := Vector3.BACK
var _hold := Vector3.ZERO
var _land_damage := 0.0
var _land_what := ""
var _flash := 0.0
## EL RESORTE DE LOS GOLPES (HitSpring, la pieza común con los personajes): cada golpe lo inclina y vuelve rebotando.
## Sólo dibujo: lo que se inclina lo dice el cuerpo (`hit_tilt`: la jaula, por su motor; un jefe, lo de arriba).
var spring := HitSpring.new()
var _painted: Array[MeshInstance3D] = []
var _white := StandardMaterial3D.new()


## La reacción de `node` (se cuelga la primera vez).
static func of(node: Node3D) -> HitReaction:
	var found := node.get_node_or_null(NODE_NAME) as HitReaction
	if found == null:
		found = HitReaction.new()
		found.name = NODE_NAME
		node.add_child(found)
	return found


## UN GOLPE A `target`: le saca `damage` por `what` y reacciona con `kind`, empujado `distance` m hacia `away` (de
## costado); `at`, dónde pegó (las chispas). Si no se le puede pegar (tirada, agarrada, en el dash), nada: devuelve false.
static func land(target: Node3D, damage: float, what: String, kind: Kind, away: Vector3, distance: float,
		at: Vector3) -> bool:
	var reaction := of(target)
	if reaction.untouchable():
		return false
	var health := Health.of(target)
	if health != null:
		health.hurt(damage, what)
	reaction.react(kind, away, distance, at)
	return true


func _ready() -> void:
	_target = get_parent() as Node3D
	_body = _target as BalanceBody
	# Agarrada, la pone donde la lleva el jefe después de que ella se movió en su paso.
	process_physics_priority = 50
	_white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_white.albedo_color = Color(1, 1, 1, 0)


## Si ahora no se le puede pegar: agarrada, volando, o lo que diga ella (tirada, levantándose, en el dash).
func untouchable() -> bool:
	return state != State.FREE or (_body != null and _body.untouchable())


## SI ALGO SUYO FRENA EL GOLPE (el escudo de la meca: BalanceBody.block_hit). Se pregunta UNA SOLA VEZ POR GOLPE, antes
## de pegar; `at`, dónde pega (el mundo; la onda del escudo sale de ahí). True: el golpe se frenó (el escudo ya lo
## mostró) y se da por usado.
func blocks(at := Vector3.INF) -> bool:
	return _body != null and _body.block_hit(at)


## Si está en el piso, agarrada o volando (el jefe no la frena: pasa).
func down() -> bool:
	return state != State.FREE or (_body != null and _body.state != BalanceBody.State.STANDING)


## LO QUE SE VE Y SE OYE, y la reacción.
func react(kind: Kind, away: Vector3, distance: float, at: Vector3) -> void:
	hits += 1
	show_hit(at, kind == Kind.KNOCKDOWN)
	sway(away * distance * SWAY_PER_M)
	_away = Vector3(away.x, 0.0, away.z).normalized()
	if _away == Vector3.ZERO:
		_away = Vector3.BACK
	if kind == Kind.FLINCH or _body == null:
		return
	if not _kinematic():
		var lift := 0.45 if kind == Kind.KNOCKDOWN else 0.15
		BalanceBody.hit(_body, (_away + Vector3.UP * lift).normalized() * distance * PHYSICAL_SPEED * _body.mass)
		return
	if kind == Kind.PUSH:
		_body.shove(_away * distance, PUSH_TIME)
	else:
		_body.shove(_away * distance, FALL_TIME, FALL_HOP)
		_body.knock_down()


## SE INCLINA CON UN GOLPE de `push` (m/s, en el mundo, hacia donde lo empuja): el resorte (HitSpring), en los ejes del
## cuerpo. No tumba nunca (eso lo decide el ataque: Kind.KNOCKDOWN).
func sway(push: Vector3) -> void:
	var facing := _facing()
	var local := facing.inverse() * Vector3(push.x, 0.0, push.z)
	spring.hit(Vector2(local.x, local.z), 1.0, false)


## Cuánto inclina cada metro de empuje de un ataque (m/s del resorte por m).
const SWAY_PER_M := 0.15
## Cuánto se inclina con el resorte en el borde (°).
const SWAY_DEGREES := 20.0


## Hacia dónde mira el cuerpo (para pasar el golpe a sus ejes).
func _facing() -> Basis:
	if _kinematic():
		return Basis(Vector3.UP, _body.mover.rotation.y)
	if "waist_yaw" in _target:
		return Basis(Vector3.UP, float(_target.get("waist_yaw")))
	return Basis(Vector3.UP, _target.global_rotation.y)


## Sólo lo que se ve y se oye (también para el jefe cuando le pegan).
func show_hit(at: Vector3, heavy: bool) -> void:
	_flash = FLASH_TIME
	_paint(true)
	_sparks(at, heavy)
	BossSounds.play(BossSounds.Kind.KNOCKDOWN if heavy else BossSounds.Kind.HIT, at, _target)


## AGARRADA: la lleva quien la agarró (`hold_at` en cada paso). Sólo la cinemática.
func grab(at: Vector3) -> void:
	hits += 1
	show_hit(at, false)
	BossSounds.play(BossSounds.Kind.GRAB, at, _target)
	if _kinematic():
		state = State.HELD
		_hold = _body.mover.global_position


## AGARRADA, va a `at` (el piso debajo de sus pies).
func hold_at(at: Vector3) -> void:
	_hold = at


## REVOLEADA: de donde está, vuela en arco hasta `to` (el piso) en `time` s, subiendo `arc` m (la mueve ella:
## `shove`); al caer le saca `damage` por `what` y queda derribada.
func fling(to: Vector3, arc: float, time: float, damage: float, what: String) -> void:
	if not _kinematic():
		state = State.FREE
		return
	var from := _body.mover.global_position
	var offset := Vector3(to.x - from.x, 0.0, to.z - from.z)
	state = State.FLYING
	_away = offset.normalized() if offset.length() > 0.01 else Vector3.BACK
	_clock = 0.0
	_time = maxf(time, 0.1)
	_land_damage = damage
	_land_what = what
	_body.shove(offset, _time, arc)


## Suelta todo (para las pruebas).
func clear() -> void:
	state = State.FREE
	_flash = 0.0
	_paint(false)


func _physics_process(delta: float) -> void:
	# EL RESORTE: se endereza solo; lo que inclina lo escribe en el cuerpo (z, para atrás: positivo en x).
	spring.update(delta)
	var tilt := Vector2(spring.hit_xz.y, spring.hit_xz.x) * SWAY_DEGREES
	if _kinematic():
		_body.mover.hit_tilt = tilt
	elif "hit_tilt" in _target:
		_target.set("hit_tilt", tilt)
	if _flash > 0.0:
		_flash -= delta
		_white.albedo_color.a = 0.85 * clampf(_flash / FLASH_TIME, 0.0, 1.0)
		if _flash <= 0.0:
			_paint(false)
	if not _kinematic():
		return
	match state:
		State.HELD:
			_body.put(Transform3D(Basis(Vector3.UP, _body.mover.rotation.y), _hold))
		State.FLYING:
			_clock += delta
			if _clock >= _time:
				state = State.FREE
				var health := Health.of(_target)
				if health != null:
					health.hurt(_land_damage, _land_what)
				# En la caja (tirada, queda lejos de sus pies).
				show_hit(_body.global_position, true)
				_body.knock_down()


func _kinematic() -> bool:
	return _body != null and _body.mover != null


## SE PONE BLANCA (o vuelve): el material encima de todas sus mallas (las que no tenían otro).
func _paint(on: bool) -> void:
	if not on:
		for mesh in _painted:
			if is_instance_valid(mesh) and mesh.material_overlay == _white:
				mesh.material_overlay = null
		_painted.clear()
		return
	_white.albedo_color.a = 0.85
	if not _painted.is_empty():
		return
	for mesh: MeshInstance3D in _target.find_children("*", "MeshInstance3D", true, false):
		if mesh.material_overlay == null and mesh.visible:
			mesh.material_overlay = _white
			_painted.append(mesh)


## CHISPAS en `at` (más, si es fuerte; BossBursts).
func _sparks(at: Vector3, heavy: bool) -> void:
	BossBursts.sparks(_target.get_parent(), at, heavy)
