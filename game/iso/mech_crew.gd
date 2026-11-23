class_name MechCrew
extends Node

## LAS TECLAS COMPARTIDAS DE LA MECA (22/11/2026; el usuario: «si varios jugadores quieren tocar la misma tecla, como que
## se bloquea. Entonces eso promueve la comunicación y la sincronización»). Todos los que van arriba pueden tocar todas:
##   · WASD la mueve según la pantalla, y las piernas siguen apuntando al frente de la meca.
##   · LAS TECLAS VAN POR ZONAS, para que la tripulación se reparta (el usuario: «agrupar teclas en zonas en las que estén
##     cerca en el teclado»): la mano izquierda maneja (WASD y Shift, el dash), el pulgar tira (ESPACIO la ametralladora,
##     C los misiles, y el mouse los encamina, ver MechAim), LAS HABILIDADES VAN EN FILA (Z y X los brazos, C los misiles, V
##     el escudo; el usuario: las flechas arriba y abajo «medio raras») y ← → giran el frente.
##   · UNA TECLA APRETADA POR DOS O MÁS NO ANDA PARA NADIE, hasta que quede uno solo.
## La cuenta la lleva el host y se la dice a todos. Lo que resulta se escribe en MechCockpit, como los tableros.
## CON CLIC (22/11/2026, el F6: MatchSettings; el usuario: «para manejar los controles tengas que hacerles clic en los
## cuadrados»), las teclas no andan y el mouse se ve:
##   · WASD ES UNA PALANCA que se queda donde la dejás. Dos agarrándola se traba.
##   · EL GIRO ES UN INTERRUPTOR: un clic lo deja girando, otro lo para.
##   · LA AMETRALLADORA Y LOS MISILES SE TOMAN: el arma queda de quien la tomó, con la mira en el mouse. El clic en el mundo
##     dispara; el clic derecho o otro clic en su cuadrado la suelta. Se lleva una por persona.
##   · EL ESCUDO ES UN INTERRUPTOR: un clic lo prende (paga su activación), muestra su zona, sigue el mouse de quien lo prendió
##     y gasta mientras dure; otro clic lo apaga, y sin energía se apaga solo.
##   · LO DEMÁS se mantiene apretado con el clic.

const SLOTS: Array[Dictionary] = [
	{"key": KEY_W, "text": "W", "cell": Vector2i(1, 0), "tip": "mover hacia arriba de la pantalla"},
	{"key": KEY_A, "text": "A", "cell": Vector2i(0, 1), "tip": "mover hacia la izquierda de la pantalla"},
	{"key": KEY_S, "text": "S", "cell": Vector2i(1, 1), "tip": "mover hacia abajo de la pantalla"},
	{"key": KEY_D, "text": "D", "cell": Vector2i(2, 1), "tip": "mover hacia la derecha de la pantalla"},
	{"key": KEY_LEFT, "text": "←", "cell": Vector2i(9, 1), "tip": "girar el frente de la meca a la izquierda"},
	{"key": KEY_RIGHT, "text": "→", "cell": Vector2i(10, 1), "tip": "girar el frente de la meca a la derecha"},
	{"key": KEY_Z, "text": "Z", "cell": Vector2i(4, 1), "tip": "brazo izquierdo, al frente: mantener carga, soltar ataca"},
	{"key": KEY_X, "text": "X", "cell": Vector2i(5, 1), "tip": "brazo derecho, al frente: mantener carga, soltar ataca"},
	{"key": KEY_SPACE, "text": "", "cell": Vector2i(4, 2), "span": 4, "tip": "ametralladora (mantener): el mouse la encamina"},
	{"key": KEY_C, "text": "C", "cell": Vector2i(6, 1), "tip": "lanzar un misil: el mouse lo guía al salir y explota al final"},
	{"key": KEY_SHIFT, "text": "⇧", "cell": Vector2i(0, 0), "tip": ""},
	{"key": KEY_CTRL, "text": "Ctrl", "cell": Vector2i(0, 2),
		"tip": "sobrevuelo: mantener, hacia donde caminás; gasta energía mientras dura"},
	{"key": KEY_V, "text": "V", "cell": Vector2i(7, 1), "tip": "escudo (mantener): el mouse elige de qué lado frena"},
]
const W := 0
const A := 1
const S := 2
const D := 3
const LEFT := 4
const RIGHT := 5
const ARM_LEFT := 6
const ARM_RIGHT := 7
const MINIGUN := 8
const MISSILES := 9
const DASH := 10
## EL SOBREVUELO, sólo en la meca que tiene los dos (DashSettings.Style.BOTH); si no, su cuadrado no se ve.
const FLY := 11
const SHIELD := 12
## Las teclas que se apuntan con el mouse (ver MechAim).
const AIMED: Array[int] = [MINIGUN, MISSILES, SHIELD]
## Las que dibujan su zona: también los brazos, que van siempre al frente del torso.
const SHOWN: Array[int] = [ARM_LEFT, ARM_RIGHT, MINIGUN, MISSILES, SHIELD]
const CLICK_TIPS := {
	4: "girar a la izquierda: un clic lo deja girando, otro lo para",
	5: "girar a la derecha: un clic lo deja girando, otro lo para",
	8: "ametralladora: clic la toma; clic en el mundo dispara; clic derecho la suelta",
	9: "misiles: clic los toma; clic en el mundo lanza; clic derecho los suelta",
	12: "escudo: un clic lo prende y sigue tu mouse, otro lo apaga; gasta mientras dura",
}
## Cuántas veces por segundo se manda la palanca mientras se la mueve.
const STICK_RATE := 20.0
## Lo que espera a que el escudo prenda antes de apagar su interruptor (s).
const SHIELD_GRACE := 0.25

var mech: CageMech = null
## Cuántos aprietan cada tecla (en el orden de SLOTS).
var counts := MechCrew._zeros()
## Quién aprieta la ametralladora y los misiles (la máquina; 0, nadie): sus armas siguen su mira (MechAim).
var gun_holder := 0
var missile_holder := 0
## Quién aprieta cada tecla (la máquina; 0, nadie): cada zona sigue la mira de quien la apunta.
var holders := MechCrew._holders()
var aim: MechAim = null
## Los cursores de los otros tripulantes.
var cursors: MechCursors = null
## Si cada brazo y los misiles andaban en el paso anterior: lo que sale una vez por apretada.
var _arm_was := [false, false]
var _missile_was := false

## Lo que aprieta esta máquina (un bit por tecla).
var _mine := 0
## En el host: lo que aprieta cada máquina.
var _held := {}
var _in_use := false
## LO DE LOS CONTROLES DE CLIC, igual en todas las máquinas (lo decide el host).
var stick := Vector2.ZERO
var turning := 0
var gun_taker := 0
var missile_taker := 0
## Quién prendió el escudo (0, apagado).
var shield_by := 0
## Lo que esta máquina tiene apretado con el mouse, y la palanca como la tiene.
var _clicked := 0
var _firing := false
var _my_stick := Vector2.ZERO
var _stick_clock := 0.0
var _was_clicking := false
var _was_aboard := false
var _shield_grace := 0.0
## Si el brazo ya pagó su golpe pesado en esta carga.
var _heavy_paid := [false, false]


func _ready() -> void:
	name = "Tripulacion"
	multiplayer.peer_disconnected.connect(_forget)
	var hud := MechCrewHud.new()
	hud.crew = self
	add_child(hud)
	var bars := MechStatusBars.new()
	bars.crew = self
	add_child(bars)
	var smoke := MechSmoke.new()
	smoke.mech = mech
	mech.add_child.call_deferred(smoke)
	cursors = MechCursors.new()
	cursors.crew = self
	cursors.hud = hud
	add_child(cursors)
	aim = MechAim.new()
	aim.crew = self
	add_child(aim)
	mech.guns.aim = aim


## Si la tecla `slot` anda: la aprieta exactamente uno.
func works(slot: int) -> bool:
	return counts[slot] == 1


## Si esta máquina aprieta alguna de las armas que se encaminan con el mouse.
func aiming_locally() -> bool:
	if clicking():
		var me := multiplayer.get_unique_id()
		return gun_taker == me or missile_taker == me or shield_by == me
	for slot in AIMED:
		if _mine & (1 << slot):
			return true
	return false


## Si la partida se maneja con clic (MatchSettings).
func clicking() -> bool:
	return MatchSettings.current.clicking()


## QUIÉN APUNTA LA HABILIDAD `slot` (la máquina; 0, nadie): con clic, las armas son de quien las tomó.
func aimer_of(slot: int) -> int:
	if clicking():
		if slot == MINIGUN:
			return gun_taker
		if slot == MISSILES:
			return missile_taker
		if slot == SHIELD:
			return shield_by
	return holders[slot]


## HACIA DÓNDE VA LA HABILIDAD DE `slot` (mundo, plano): las que se apuntan, hacia la mira de quien la aprieta; los brazos y
## las que no tienen mira, al frente del torso.
func way_of(slot: int) -> Vector3:
	var aimed := aim != null and AIMED.has(slot)
	var point := aim.point_of(aimer_of(slot)) if aimed else Vector3.INF
	if point.is_finite():
		var to := point - mech.global_position
		to.y = 0.0
		if to.length() > 0.5:
			return to.normalized()
	return Basis(Vector3.UP, mech.yaw()) * Vector3.FORWARD


## LA ZONA DE LA HABILIDAD DE `slot` ahora (vacía, no tiene).
func zone_of(slot: int) -> Dictionary:
	match slot:
		MINIGUN:
			return mech.guns.gun_zone()
		MISSILES:
			return MechSkills.missile()
		SHIELD:
			return MechSkills.shield()
	var index := slot - ARM_LEFT
	if index >= mech.arms.size() or mech.arms[index].tip == null:
		return {}
	return mech.arms[index].tip.zone()


## SI EL JUGADOR DE ESTA MÁQUINA VA ARRIBA, con la cámara isométrica.
func local_aboard() -> bool:
	var player := DesignSandbox.player_of(get_tree())
	if not is_instance_valid(player) or not player.is_seated or not is_instance_valid(player.player_controller):
		return false
	if not is_instance_valid(player.player_controller.iso_view) or mech.cabin == null:
		return false
	return mech.cabin.chairs.has(player.current_seat)


## CADA PASO, ANTES DE QUE LA MECA LEA LO QUE SE LE PIDE (ver CageMechKeys.read).
func apply() -> void:
	_follow_mode()
	_read_mine()
	_watch_shield()
	var used := clicking() and (stick != Vector2.ZERO or turning != 0 or shield_by != 0)
	for count in counts:
		used = used or count > 0
	# Soltaron todo: un paso más, para dejar la meca sin pedidos. Después los tableros quedan libres.
	if used or _in_use:
		_write()
	_in_use = used
	if mech.dasher != null and not mech.net.remote():
		mech.dasher.step(get_physics_process_delta_time(), works(DASH),
			IsoSettings.current.screen_to_world(_screen()).limit_length(1.0), works(FLY))


## Lo que dice el cuadrado de la tecla `slot`: el del dash cambia con su estilo (ver DashSettings).
static func tip_of(slot: int) -> String:
	if MatchSettings.current.clicking() and CLICK_TIPS.has(slot):
		return CLICK_TIPS[slot]
	if slot != DASH:
		return SLOTS[slot]["tip"]
	if DashSettings.current.style != DashSettings.Style.THRUST:
		return "dash: una apretada, hacia donde caminás; gasta energía"
	return "propulsor: mantener, hacia donde caminás; gasta energía mientras dura"


## HACIA DÓNDE PIDEN IR, en la pantalla: las teclas o la palanca.
func _screen() -> Vector2:
	return stick if clicking() else Vector2(_on(D) - _on(A), _on(W) - _on(S))


## CAMBIARON LOS CONTROLES (el F6): nada queda apretado ni tomado.
func _follow_mode() -> void:
	var now := clicking()
	if now == _was_clicking:
		return
	_was_clicking = now
	_clicked = 0
	_firing = false
	if multiplayer.is_server():
		_share(Vector2.ZERO, 0, 0, 0, 0)


func _read_mine() -> void:
	var bits := 0
	var aboard := local_aboard()
	# Al bajarse, suelta el arma que tenía.
	if _was_aboard and not aboard:
		_clicked = 0
		_firing = false
		_ask_or_do_drop(true)
	_was_aboard = aboard
	if aboard and UIState.gameplay_active():
		if clicking():
			bits = _clicked | _fire_bits()
			_send_stick()
		else:
			for slot in SLOTS.size():
				if Input.is_physical_key_pressed(SLOTS[slot]["key"]):
					bits |= 1 << slot
	if bits == _mine:
		return
	_mine = bits
	if multiplayer.is_server():
		_store(multiplayer.get_unique_id(), bits)
	else:
		_report.rpc_id(1, bits)


func _write() -> void:
	if mech.legs != null:
		mech.legs.pivot_feet = true
	var cockpit := (mech.keys as ToolMechKeys).cockpit
	var screen := _screen()
	# La pantalla, en los ejes del torso, que es como la meca entiende `move`.
	var local := Basis(Vector3.UP, -mech.yaw()) * IsoSettings.current.screen_to_world(screen)
	cockpit.move = Vector2(local.x, -local.z).limit_length(1.0)
	# LA AMETRALLADORA FRENA EL AVANCE: sólo caminando hacia el frente del torso (ver DashSettings, «Retroceso»).
	var knobs := DashSettings.current
	if knobs.recoil_on and mech.guns != null and mech.guns.weapons.firing() and cockpit.move.y > 0.0:
		cockpit.move.y *= 1.0 - knobs.minigun_slow
	# EL MINI STUN (MechEnergy, el F3): tampoco gira; las armas de munición, según su opción.
	var able := mech.energy.able()
	var wanted := float(turning) if clicking() else _on(LEFT) - _on(RIGHT)
	var turn := wanted if able else 0.0
	mech.mover.key_turn = turn * deg_to_rad(mech.kinematic_settings().turn_speed)
	_write_arms(cockpit)
	if mech.guns != null:
		var guns_on := able or not DashSettings.current.stun_blocks_guns
		mech.guns.weapons.hold_minigun(works(MINIGUN) and guns_on)
		var launch := works(MISSILES)
		if launch and not _missile_was and guns_on:
			mech.guns.weapons.launch_missile(missile_holder)
		_missile_was = launch


## CADA BRAZO HACE LO SUYO con su tecla: el cañón dispara mientras se mantiene; lo que gira carga y al soltar pega; el
## escudo se levanta mientras se mantiene; un puño o el palo, un golpe por apretada.
func _write_arms(cockpit: MechCockpit) -> void:
	var firing: Array[CannonTip] = []
	var spinning: Array[SpinTip] = []
	var shield := false
	var standing := mech.state == BalanceBody.State.STANDING and mech.energy.able()
	for index in mini(mech.arms.size(), 2):
		var on := works(ARM_LEFT + index)
		var was: bool = _arm_was[index]
		if on:
			mech.arms[index].cast_here = holders[ARM_LEFT + index] == multiplayer.get_unique_id()
		var arm := mech.arms[index]
		if arm.tip is CannonTip:
			var cannon := arm.tip as CannonTip
			cannon.mode = CannonTip.Mode.SUPER
			cannon.overcharge = true
			# Sin verticalidad y sin apuntar: derecho al frente.
			cannon.lever = Vector2.ZERO
			if on:
				firing.append(cannon)
		elif arm.tip is SpinTip:
			if on:
				spinning.append(arm.tip as SpinTip)
			elif was and standing and not mech.net.remote():
				(arm.tip as SpinTip).strike()
		elif arm.tip is ShieldTip:
			shield = shield or on
		else:
			_write_fist(arm, index, on, was, standing)
		_arm_was[index] = on
	cockpit.firing = firing
	cockpit.spinning = spinning
	# EL ESCUDO DE LA V: se apunta con el mouse (MechShield.way).
	var guarding := shield_by != 0 if clicking() else works(SHIELD)
	mech.shield.way = way_of(SHIELD) if guarding else Vector3.ZERO
	cockpit.shield = shield or guarding


## EL PUÑO (o el palo) CARGA EN DOS SEGMENTOS (DashSettings, «Golpes»): apretar paga el golpe; soltar antes del liviano lo
## pierde sin pegar; entre medio sale liviano; llena, paga lo suyo y sale pesado. Sin energía para el pesado, queda en liviano.
func _write_fist(arm: MechArm, index: int, on: bool, was: bool, standing: bool) -> void:
	var knobs := DashSettings.current
	if not standing:
		arm.charging_since = -1.0
		arm.charge_cap = 1.0
	elif on and not was:
		arm.charge_cap = 1.0
		_heavy_paid[index] = false
		arm.charging_since = Time.get_ticks_msec() / 1000.0 if _pay(knobs.fist_cost) else -1.0
	elif on and arm.charging_since >= 0.0:
		# Mientras se carga no se recarga, como el cañón.
		if not mech.net.remote():
			mech.energy.pause_refill()
		if not _heavy_paid[index] and arm_charge(index) >= 1.0:
			_heavy_paid[index] = true
			if not _pay(knobs.fist_heavy_cost):
				arm.charge_cap = knobs.fist_light_share
	elif was and not on and arm.charging_since >= 0.0:
		var share := arm_charge(index)
		arm.charging_since = -1.0
		arm.charge_cap = 1.0
		if share >= knobs.fist_light_share:
			arm.charged_strike(1.0 if share >= 1.0 else 0.0, CageHandling.current.punch_strongest)


## PAGA `cost` (en energía de las perillas). Donde la meca la simula otro, sólo mira si alcanza: el que gasta es el dueño.
func _pay(cost: float) -> bool:
	var amount := cost / MechEnergy.UNIT
	return mech.energy.level >= amount if mech.net.remote() else mech.energy.spend(amount)


## DÓNDE TERMINA CADA SEGMENTO DE LA CARGA DEL BRAZO `index`; vacío, no carga por segmentos.
func arm_marks(index: int) -> PackedFloat32Array:
	if index >= mech.arms.size():
		return PackedFloat32Array()
	var tip := mech.arms[index].tip
	if tip is CannonTip:
		return PackedFloat32Array([1.0 / 3.0, 2.0 / 3.0, 1.0])
	if tip is SpinTip or tip is ShieldTip:
		return PackedFloat32Array()
	return PackedFloat32Array([DashSettings.current.fist_light_share, 1.0])


## CUÁNTO LLEVA CARGADO EL BRAZO `index` (0 a 1), para su barrita: el puño o el cañón.
func arm_charge(index: int) -> float:
	if index >= mech.arms.size():
		return 0.0
	var arm := mech.arms[index]
	if arm.tip is CannonTip:
		return (arm.tip as CannonTip).charge
	if arm.charging_since < 0.0:
		return 0.0
	return clampf((Time.get_ticks_msec() / 1000.0 - arm.charging_since) / CageHandling.current.punch_charge_time, 0.0,
		arm.charge_cap)


## ── LOS CONTROLES DE CLIC ─────────────────────────────────────────────────────────────────────────────────────────

## UN CUADRADO, apretado o soltado (lo llama MechCrewHud).
func click_square(slot: int, on: bool) -> void:
	match slot:
		LEFT, RIGHT:
			if on:
				_ask_or_do_turn(1 if slot == LEFT else -1)
		SHIELD:
			if on:
				if multiplayer.is_server():
					_do_shield(multiplayer.get_unique_id())
				else:
					_ask_shield.rpc_id(1)
		MINIGUN, MISSILES:
			if on:
				if multiplayer.is_server():
					_do_take(multiplayer.get_unique_id(), slot)
				else:
					_ask_take.rpc_id(1, slot)
		_:
			_clicked = _clicked | (1 << slot) if on else _clicked & ~(1 << slot)


## LA PALANCA, agarrada o soltada. Al soltarla manda dónde quedó.
func hold_stick(on: bool) -> void:
	if not on:
		_stick_clock = 0.0
		_send_stick()
	click_square(W, on)


func push_stick(value: Vector2) -> void:
	_my_stick = value


func _send_stick() -> void:
	_stick_clock -= get_physics_process_delta_time()
	if not (_clicked & (1 << W)) or _stick_clock > 0.0 or _my_stick == stick:
		return
	_stick_clock = 1.0 / STICK_RATE
	if multiplayer.is_server():
		_take_stick(multiplayer.get_unique_id(), _my_stick)
	else:
		_ask_stick.rpc_id(1, _my_stick)


func _fire_bits() -> int:
	if _firing and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_firing = false
	if not _firing:
		return 0
	var me := multiplayer.get_unique_id()
	if gun_taker == me:
		return 1 << MINIGUN
	return 1 << MISSILES if missile_taker == me else 0


## EL CLIC EN EL MUNDO: el izquierdo dispara el arma tomada, el derecho la suelta. Los cuadrados se quedan con los suyos.
func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or not clicking() or not UIState.gameplay_active() or not local_aboard():
		return
	if not aiming_locally():
		return
	if button.button_index == MOUSE_BUTTON_LEFT:
		_firing = true
	elif button.button_index == MOUSE_BUTTON_RIGHT:
		_ask_or_do_drop()


func _ask_or_do_turn(way: int) -> void:
	if multiplayer.is_server():
		_do_turn(way)
	else:
		_ask_turn.rpc_id(1, way)


func _ask_or_do_drop(shield_too := false) -> void:
	if multiplayer.is_server():
		_do_drop(multiplayer.get_unique_id(), shield_too)
	else:
		_ask_drop.rpc_id(1, shield_too)


## EN EL HOST: EL INTERRUPTOR DEL ESCUDO SE APAGA SOLO si el escudo no prendió (no alcanzó) o se cortó sin energía.
func _watch_shield() -> void:
	if shield_by == 0 or mech.shield.on:
		_shield_grace = 0.0
		return
	_shield_grace += get_physics_process_delta_time()
	if _shield_grace >= SHIELD_GRACE and multiplayer.is_server():
		_shield_grace = 0.0
		_share(stick, turning, gun_taker, missile_taker, 0)


@rpc("any_peer", "call_remote", "reliable")
func _ask_stick(value: Vector2) -> void:
	if multiplayer.is_server():
		_take_stick(multiplayer.get_remote_sender_id(), value)


@rpc("any_peer", "call_remote", "reliable")
func _ask_turn(way: int) -> void:
	if multiplayer.is_server():
		_do_turn(way)


@rpc("any_peer", "call_remote", "reliable")
func _ask_take(slot: int) -> void:
	if multiplayer.is_server() and (slot == MINIGUN or slot == MISSILES):
		_do_take(multiplayer.get_remote_sender_id(), slot)


@rpc("any_peer", "call_remote", "reliable")
func _ask_drop(shield_too: bool) -> void:
	if multiplayer.is_server():
		_do_drop(multiplayer.get_remote_sender_id(), shield_too)


@rpc("any_peer", "call_remote", "reliable")
func _ask_shield() -> void:
	if multiplayer.is_server():
		_do_shield(multiplayer.get_remote_sender_id())


## EN EL HOST: la palanca la mueve sólo el único que la agarra.
func _take_stick(peer: int, value: Vector2) -> void:
	if counts[W] == 1 and holders[W] == peer:
		_share(value.limit_length(1.0), turning, gun_taker, missile_taker)


func _do_turn(way: int) -> void:
	_share(stick, 0 if turning == way else way, gun_taker, missile_taker)


## EN EL HOST: toma el arma si está libre (y suelta la otra que tuviera); si ya era suya, la suelta.
func _do_take(peer: int, slot: int) -> void:
	var gun := gun_taker
	var launcher := missile_taker
	if slot == MINIGUN:
		if gun == peer:
			gun = 0
		elif gun == 0:
			gun = peer
			launcher = 0 if launcher == peer else launcher
	elif launcher == peer:
		launcher = 0
	elif launcher == 0:
		launcher = peer
		gun = 0 if gun == peer else gun
	_share(stick, turning, gun, launcher)


func _do_drop(peer: int, shield_too := false) -> void:
	_share(stick, turning, 0 if gun_taker == peer else gun_taker, 0 if missile_taker == peer else missile_taker,
		0 if shield_too and shield_by == peer else shield_by)


## EN EL HOST: cualquiera prende o apaga el escudo; apunta quien lo prendió.
func _do_shield(peer: int) -> void:
	_share(stick, turning, gun_taker, missile_taker, 0 if shield_by != 0 else peer)


func _share(new_stick: Vector2, new_turn: int, gun: int, launcher: int, guard := -1) -> void:
	var fresh_guard := shield_by if guard < 0 else guard
	if new_stick == stick and new_turn == turning and gun == gun_taker and launcher == missile_taker \
			and fresh_guard == shield_by:
		return
	if NetFollow.online(self):
		_show_click.rpc(new_stick, new_turn, gun, launcher, fresh_guard)
	else:
		_show_click(new_stick, new_turn, gun, launcher, fresh_guard)


@rpc("authority", "call_local", "reliable")
func _show_click(new_stick: Vector2, new_turn: int, gun: int, launcher: int, guard: int) -> void:
	shield_by = guard
	stick = new_stick
	turning = new_turn
	gun_taker = gun
	missile_taker = launcher


static func _zeros() -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(SLOTS.size())
	return out


static func _holders() -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(SLOTS.size())
	return out


func _on(slot: int) -> float:
	return 1.0 if works(slot) else 0.0


@rpc("any_peer", "call_remote", "reliable")
func _report(bits: int) -> void:
	if multiplayer.is_server():
		_store(multiplayer.get_remote_sender_id(), bits)


func _forget(peer: int) -> void:
	if multiplayer.is_server() and _held.has(peer):
		_store(peer, 0)
	if multiplayer.is_server():
		_do_drop(peer, true)


## EN EL HOST: lo que aprieta `peer`, y la cuenta nueva para todos.
func _store(peer: int, bits: int) -> void:
	_held[peer] = bits
	var fresh := MechCrew._zeros()
	var who_holds := MechCrew._holders()
	var gun := 0
	var launcher := 0
	for who: int in _held:
		var held: int = _held[who]
		for slot in SLOTS.size():
			if held & (1 << slot):
				fresh[slot] += 1
				who_holds[slot] = who
		if held & (1 << MINIGUN):
			gun = who
		if held & (1 << MISSILES):
			launcher = who
	if fresh == counts and who_holds == holders and gun == gun_holder and launcher == missile_holder:
		return
	if NetFollow.online(self):
		_show.rpc(fresh, gun, launcher, who_holds)
	else:
		_show(fresh, gun, launcher, who_holds)


@rpc("authority", "call_local", "reliable")
func _show(fresh: PackedByteArray, gun: int, launcher: int, who_holds: PackedInt32Array) -> void:
	counts = fresh
	holders = who_holds
	gun_holder = gun
	missile_holder = launcher
