class_name MechArmsNet
extends Node

## ── LOS BRAZOS Y LA ENERGÍA DE LA MECA POR LA RED (18/11/2026; el usuario: «está bien si querés sincronizar»; «el loop
## online funcionando») ─────────────────────────────────────────────────────────────────────────────────────────────
## El mismo dueño que el motor (BodyNet: `mech.net.authority`, el host o quien la posee). Viaja LO QUE SE PIDE, no lo que
## pasa: cada máquina mueve los brazos, tira los tiros y dibuja con eso, igual que el dueño.
##   · LO QUE SE MANTIENE (`RATE` veces por segundo, sin garantía): la energía (lo que queda y si está aturdida), la
##     guardia, el escudo pedido y lo de cada punta: el cañón (el modo, el gatillo, la palanca), lo que gira (si se
##     carga). Las demás máquinas lo ponen después de leer sus teclas (`after_read`), así lo suyo no lo pisa.
##   · LO QUE PASA UNA VEZ (con garantía): cada piña que sale (cuál, lo rápida y fuerte y por dónde va). En las demás,
##     una piña sólo sale si la manda el dueño (`allows`).
##   · EL DAÑO lo aplica sólo el host (EnergyBolt.lands): cada máquina tira sus tiros y barre sus piñas, y sólo los del
##     host le pegan de verdad. Así un golpe cuenta una vez, sea quien sea el dueño.

const RATE := 20.0

var mech: ToolMech = null
## Para las pruebas: cuántos estados y piñas mandó y recibió.
var sent := 0
var received := 0
var punches_received := 0
var _clock := 0.0
var _last: Array = []
## Mientras pone una piña que mandó el dueño (ver `allows`).
var _applying := false


## EL DE `node` (subiendo hasta su meca), o null.
static func of(node: Node) -> MechArmsNet:
	var at := node
	while at != null and not at is ToolMech:
		at = at.get_parent()
	if at == null:
		return null
	return (at as ToolMech).arms_net


## SI EN ESTA MÁQUINA LA SIGUEN (otro la simula).
func remote() -> bool:
	return mech != null and mech.net != null and mech.net.remote()


## SI UNA PIÑA PUEDE SALIR ACÁ: en el dueño (o sin red), siempre; en las demás, sólo la que mandó el dueño.
func allows() -> bool:
	return _applying or not remote()


## DESPUÉS DE LEER LAS TECLAS, cada paso: el dueño manda lo que se pide; los demás ponen lo último que llegó.
func after_read(delta: float) -> void:
	if mech.net == null or not mech.net.networked():
		return
	if remote():
		if not _last.is_empty():
			_apply(_last)
		return
	_clock -= delta
	if _clock > 0.0:
		return
	_clock = 1.0 / RATE
	_state.rpc(_gather())
	sent += 1


## LO QUE SE PIDE AHORA: [energía, aturdida, guardia, escudo, [lo de cada brazo]].
func _gather() -> Array:
	var tips: Array = []
	for arm in mech.arms:
		if arm.tip is CannonTip:
			var cannon := arm.tip as CannonTip
			tips.append([int(cannon.mode), cannon.trigger, cannon.lever])
		elif arm.tip is SpinTip:
			tips.append([(arm.tip as SpinTip).charging])
		else:
			tips.append([])
	return [mech.energy.level, mech.energy.stunned, mech.covering, mech.shield.held, tips]


func _apply(state: Array) -> void:
	mech.energy.level = float(state[0])
	mech.energy.stunned = float(state[1])
	mech.covering = bool(state[2])
	mech.shield.held = bool(state[3])
	var tips: Array = state[4]
	for index in mini(tips.size(), mech.arms.size()):
		var tip := mech.arms[index].tip
		var asked: Array = tips[index]
		if tip is CannonTip and asked.size() == 3:
			var cannon := tip as CannonTip
			cannon.mode = int(asked[0]) as CannonTip.Mode
			cannon.trigger = bool(asked[1])
			cannon.lever = asked[2]
		elif tip is SpinTip and asked.size() == 1:
			(tip as SpinTip).charging = bool(asked[0])


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _state(state: Array) -> void:
	if multiplayer.get_remote_sender_id() != mech.net.authority:
		return
	received += 1
	_last = state
	_apply(state)


## EL DUEÑO: una piña que acaba de salir de `arm`; se manda al cuadro siguiente, cuando ya tiene su camino y su fuerza.
func announce(arm: MechArm) -> void:
	if _applying or mech.net == null or not mech.net.networked() or remote():
		return
	_send_punch.call_deferred(arm)


func _send_punch(arm: MechArm) -> void:
	var index := mech.arms.find(arm)
	if index < 0 or arm.punching == MechArm.Punch.NONE:
		return
	_punch.rpc(index, int(arm.punching), arm.punch_pace, arm.punch_strength, arm.aimed_path())


@rpc("any_peer", "call_remote", "reliable")
func _punch(index: int, kind: int, pace: float, strength: float, path: Array) -> void:
	if multiplayer.get_remote_sender_id() != mech.net.authority or index >= mech.arms.size():
		return
	punches_received += 1
	var arm := mech.arms[index]
	_applying = true
	arm.punching = MechArm.Punch.NONE
	arm.punch(kind as MechArm.Punch)
	_applying = false
	arm.punch_pace = pace
	arm.punch_strength = strength
	arm.aim_path(path)
	if arm.tip != null:
		arm.tip.on_net_punch()
