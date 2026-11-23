class_name MechDash
extends RefCounted

## EL DASH DE LA MECA, CON UNA SOLA TECLA, HACIA DONDE CAMINA (22/11/2026; ver DashSettings). Cada paso le dice al motor
## (KinematicMover.dash_override) a qué velocidad ir; un golpe que la empuja o la tira lo corta. Lo simula el dueño.

enum Phase { NONE, BURST, THRUST, COAST }

var mech: CageMech = null
var phase := Phase.NONE

var _velocity := Vector3.ZERO
var _left := 0.0
var _wait := 0.0
var _held_was := false
## Se quedó sin energía con el propulsor: no vuelve a arrancar hasta soltar la tecla.
var _spent_out := false
var _coast_rate := 0.0
## Lo que le queda intocable (s; DashSettings.burst_untouchable).
var _untouchable := 0.0


## Si ahora ningún golpe la toca (lo pregunta CageMech.block_hit).
func untouchable() -> bool:
	return _untouchable > 0.0


## UN PASO: `held`, si la tecla del dash anda; `fly_held`, la del sobrevuelo (sólo con las dos, DashSettings.Style.BOTH);
## `way`, hacia dónde camina (en el mundo, de largo 0 a 1).
func step(delta: float, held: bool, way: Vector3, fly_held := false) -> void:
	var knobs := DashSettings.current
	var burst_held := held and knobs.style != DashSettings.Style.THRUST
	var thrust_held := held if knobs.style == DashSettings.Style.THRUST \
		else fly_held and knobs.style == DashSettings.Style.BOTH
	var pressed := burst_held and not _held_was
	_held_was = burst_held
	if not thrust_held:
		_spent_out = false
	_wait = maxf(_wait - delta, 0.0)
	_untouchable = maxf(_untouchable - delta, 0.0)
	if mech.state != BalanceBody.State.STANDING or mech.mover.pushed() or not mech.energy.able():
		phase = Phase.NONE
	# Con las dos, la ráfaga también sale en medio del sobrevuelo.
	if phase == Phase.NONE or phase == Phase.COAST or (phase == Phase.THRUST and knobs.style == DashSettings.Style.BOTH):
		_try_start(knobs, pressed, thrust_held, way)
	match phase:
		Phase.BURST:
			_left -= delta
			if _left <= 0.0:
				_finish(knobs)
		Phase.THRUST:
			if not thrust_held or way.length() < 0.1:
				_finish(knobs)
			elif not mech.energy.drain(knobs.thrust_drain / MechEnergy.UNIT, delta):
				_spent_out = true
				_finish(knobs)
			else:
				_velocity = way.normalized() * knobs.thrust_speed
		Phase.COAST:
			var walking := way * mech.kinematic_settings().walk_speed
			_velocity = _velocity.move_toward(walking, _coast_rate * delta)
			if _velocity.is_equal_approx(walking):
				phase = Phase.NONE
	mech.mover.dash_override = phase != Phase.NONE
	mech.mover.dash_velocity = _velocity


func _try_start(knobs: DashSettings, pressed: bool, thrust_held: bool, way: Vector3) -> void:
	if way.length() < 0.1:
		return
	if pressed and _wait <= 0.0 and mech.energy.spend(knobs.burst_cost / MechEnergy.UNIT):
		phase = Phase.BURST
		_left = knobs.burst_time
		_wait = knobs.burst_time + knobs.burst_cooldown
		_untouchable = knobs.burst_untouchable
		_velocity = way.normalized() * knobs.burst_distance / knobs.burst_time
	elif phase != Phase.THRUST and thrust_held and not _spent_out \
			and mech.energy.level > knobs.thrust_start / MechEnergy.UNIT \
			and mech.energy.spend(knobs.thrust_start / MechEnergy.UNIT):
		phase = Phase.THRUST
		_velocity = way.normalized() * knobs.thrust_speed


## TERMINÓ: con inercia, frena hasta caminar; sin inercia, corta en seco.
func _finish(knobs: DashSettings) -> void:
	if knobs.inertia:
		phase = Phase.COAST
		_coast_rate = _velocity.length() / knobs.inertia_time
	else:
		phase = Phase.NONE
