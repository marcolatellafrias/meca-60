class_name MechBrain
extends RefCounted

## EL RIVAL SIN PILOTO: maneja una meca con las mismas palancas que un jugador (la marcha, el giro del torso, adónde
## apunta, cargar y soltar los brazos); no hace trampa con la física. Es el sparring para probar cómo se sienten las
## peleas (el usuario, el 11/11/2026: «otra meca que le pueda pegar y se caiga y se levante… un modo para que se vuelva
## agro y me empiece a pegar»).
##   QUIETO: no hace nada. Una bolsa de arena que se tambalea, se cae y se levanta.
##   AGRESIVO: camina hacia el otro, le gira el torso encima y, cuando está a tiro, carga un brazo un rato y lo suelta,
##     a veces doblándolo en gancho. Se afirma si se está por caer.

enum Mode { STILL, AGGRESSIVE }

const NAMES := {Mode.STILL: "quieto", Mode.AGGRESSIVE: "agresivo"}
## Más cerca que esto, retrocede; más lejos que esto, se acerca (entre centros, en metros).
const CLOSE := 12.0
const FAR := 15.0
const STRIKE_RANGE := 18.0

var mode := Mode.STILL
var target: Mech = null
var _rng := RandomNumberGenerator.new()
var _arm: MechArm = null
var _charge_for := 0.0
var _clock := 0.0
var _hook := 0.0
var _hook_left := 0.0
var _rest := 1.0


func _init() -> void:
	_rng.randomize()


## Mueve las palancas de `mech` por este paso.
func think(mech: Mech, delta: float) -> void:
	mech.throttle = 0.0
	mech.steer = 0.0
	mech.braced = false
	if mode == Mode.STILL or target == null or mech.state != Mech.State.STANDING:
		_arm = null
		return
	var to := target.global_position - mech.global_position
	to.y = 0.0
	var distance := to.length()
	if distance < 0.01:
		return
	mech.torso_aim = atan2(-to.x, -to.z)
	mech.aim_point = target.torso.global_transform * Vector3(0.0, MechTorso.floor_y(1) + 1.0, 0.0)
	var forward := -mech.global_basis.z
	forward.y = 0.0
	var off := forward.normalized().signed_angle_to(to / distance, Vector3.UP)
	mech.steer = clampf(off * 2.0, -1.0, 1.0)
	if absf(off) < 0.6:
		if distance > FAR:
			mech.throttle = 1.0
		elif distance < CLOSE:
			mech.throttle = -0.7
	mech.braced = mech.stability.length() > 0.55
	_fight(mech, distance, delta)


func _fight(mech: Mech, distance: float, delta: float) -> void:
	if _arm != null:
		_clock += delta
		if _arm.phase == MechArm.Phase.CHARGE:
			if _clock >= _charge_for:
				_arm.let_go(mech.aim_point)
				_hook_left = 0.18
		elif _arm.phase == MechArm.Phase.STRIKE:
			if _hook_left > 0.0:
				_hook_left -= delta
				_arm.bend(Vector2(_hook * delta * 60.0, 0.0))
		else:
			_arm = null
			_rest = _rng.randf_range(0.6, 1.8)
		return
	_rest -= delta
	if _rest > 0.0 or distance > STRIKE_RANGE:
		return
	_arm = mech.left_arm if _rng.randf() < 0.5 else mech.right_arm
	_arm.hold()
	_clock = 0.0
	_charge_for = _rng.randf_range(0.25, 0.9)
	# El gancho va hacia adentro: el brazo izquierdo dobla a la derecha y el derecho a la izquierda.
	_hook = 0.0 if _rng.randf() < 0.5 else -_arm.side * _rng.randf_range(4.0, 9.0)
