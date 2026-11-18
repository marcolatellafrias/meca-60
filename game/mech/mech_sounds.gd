class_name MechSounds
extends SoundEntity

## LOS SONIDOS DE LA MECA, TODOS EN UN LUGAR (18/11/2026, el usuario: «un sistema único como para todos los sonidos de
## la meca, de evento o de lo que sea… sonidos de disparos, sonidos de aterrizaje…»). No es otro sistema: es una entidad
## que suena (SoundEntity, como los controles y los paquetes), una por meca (`of`), y `SOUNDS` es LA LISTA de lo que
## suena y con qué clave (el archivo `assets/audio/meca/<clave>….ogg`; sin archivo, el clic de prueba: ver Sounds).
## Suena de dos maneras:
##   · LOS GOLPES QUE PASAN EN UN MOMENTO (un tiro, un impacto, un misil que sale) los pide su código: `play_sound`, o
##     `play_at` si es en un punto del mundo. Lo que se dibuja en cada máquina (las balas, los misiles) suena en cada
##     una; lo que está lejos de toda meca (una explosión) usa `loose`.
##   · LO QUE DEPENDE DEL ESTADO (aterrizar, levitar, el escudo, lo que gira, el rayo, cargar el súper, recargar) NO LO
##     PIDE NADIE: esto lo mira cada paso (`_physics_process`) y prende, apaga o afina su loop. Así suena igual en la
##     máquina que la simula y en las que la siguen por la red, y el motor y las armas no saben nada de sonidos.
## *Los avisos de los jefes van aparte (BossSounds, sintetizados), igual que antes.*

## ── LA MECA ──
const LAND := &"land"
const JUMP := &"jump"
const DASH := &"dash"
const LEVITATE := &"levitate"
const EMPTY := &"empty"
## ── LOS BRAZOS ──
const STRIKE_HIT := &"strike_hit"
const SPIN := &"spin"
const SPIN_STRIKE := &"spin_strike"
const SHIELD_UP := &"shield_up"
const SHIELD_HUM := &"shield_hum"
const SHIELD_BLOCK := &"shield_block"
## ── EL CAÑÓN ──
const CANNON_SHOT := &"cannon_shot"
const CANNON_BURST := &"cannon_burst"
const CANNON_BEAM := &"cannon_beam"
const CANNON_CHARGE := &"cannon_charge"
const CANNON_SUPER := &"cannon_super"
## ── EL ARTILLERO ──
const MINIGUN_SPIN := &"minigun_spin"
const MINIGUN_SHOT := &"minigun_shot"
const MINIGUN_JAM := &"minigun_jam"
const MISSILE_LAUNCH := &"missile_launch"
const MISSILE_BLAST := &"missile_blast"
const RELOAD := &"reload"
const RELOAD_GOOD := &"reload_good"
const RELOAD_BAD := &"reload_bad"

## LA LISTA: cada evento, su clave.
const SOUNDS := {
	LAND: &"meca_aterriza",
	JUMP: &"meca_salta",
	DASH: &"meca_dash",
	LEVITATE: &"meca_levita",
	EMPTY: &"meca_sin_energia",
	STRIKE_HIT: &"meca_golpe",
	SPIN: &"meca_gira",
	SPIN_STRIKE: &"meca_gira_golpe",
	SHIELD_UP: &"meca_escudo_sube",
	SHIELD_HUM: &"meca_escudo_zumba",
	SHIELD_BLOCK: &"meca_escudo_para",
	CANNON_SHOT: &"meca_canon_tiro",
	CANNON_BURST: &"meca_canon_rafaga",
	CANNON_BEAM: &"meca_canon_rayo",
	CANNON_CHARGE: &"meca_canon_carga",
	CANNON_SUPER: &"meca_canon_super",
	MINIGUN_SPIN: &"meca_minigun_gira",
	MINIGUN_SHOT: &"meca_minigun_tiro",
	MINIGUN_JAM: &"meca_minigun_traba",
	MISSILE_LAUNCH: &"meca_misil_sale",
	MISSILE_BLAST: &"meca_misil_explota",
	RELOAD: &"meca_recarga",
	RELOAD_GOOD: &"meca_recarga_bien",
	RELOAD_BAD: &"meca_recarga_mal",
}

## Lo que tiene que caer (m/s) para que suene el aterrizaje, y con eso a fondo.
const LAND_SOFT := 3.0
const LAND_HARD := 14.0
## Cuánto más rápido que caminar va un dash (×).
const DASH_OVER := 1.6

var mech: Mech = null
## Cuántas veces sonó cada evento en esta máquina (los golpes y los loops al prenderse; para las pruebas).
static var heard := {}
## evento → dónde suena su loop (ver `sound_anchor`); y los loops pedidos este paso: evento → [dónde, tono, volumen].
var _anchors := {}
var _wishes := {}
var _grounded_was := true
var _falling := 0.0
var _dashing := false
var _stunned_was := false
var _shield_was := false
var _jam_was := false
var _reload_was := -1
var _reload_bad_was := false


## LA DE LA MECA DE `node` (subiendo hasta ella), creada la primera vez; null si no está en una meca.
static func of(node: Node) -> MechSounds:
	var at := node
	while at != null and not at is Mech:
		at = at.get_parent()
	if at == null:
		return null
	for child in at.get_children():
		if child is MechSounds:
			return child as MechSounds
	var sounds_node := MechSounds.new()
	sounds_node.name = "Sonidos"
	sounds_node.mech = at as Mech
	at.add_child(sounds_node)
	return sounds_node


## UN GOLPE de `event` en la meca de `node`, en `at` (o en la meca). Fuera de una meca, nada.
static func hit(node: Node, event: StringName, at: Node3D = null, pitch := 1.0, volume := 1.0) -> void:
	var sounds_node := of(node)
	if sounds_node != null:
		sounds_node.play_sound(event, at, pitch, volume)


## UN GOLPE de `event` en un punto del mundo `point`, sin meca (una explosión lejos): cuelga un punto que se borra solo.
static func loose(event: StringName, point: Vector3, tree: SceneTree, pitch := 1.0, volume := 1.0) -> void:
	if tree == null or tree.current_scene == null:
		return
	var spot := Node3D.new()
	tree.current_scene.add_child(spot)
	spot.global_position = point
	var raw: Variant = SOUNDS.get(event)
	if raw != null:
		heard[event] = int(heard.get(event, 0)) + 1
		Sounds.play(raw, spot, pitch, volume)
	tree.create_timer(SPOT_LIFE).timeout.connect(spot.queue_free)


## Lo que dura un punto de `loose` (s): más que cualquier golpe.
const SPOT_LIFE := 6.0


## UN GOLPE de `event` en el punto del mundo `point`.
func play_at(event: StringName, point: Vector3, pitch := 1.0, volume := 1.0) -> void:
	loose(event, point, get_tree(), pitch, volume)


func sounds() -> Dictionary:
	return SOUNDS


func play_sound(event: StringName, at: Node3D = null, pitch := 1.0, volume := 1.0) -> void:
	heard[event] = int(heard.get(event, 0)) + 1
	super(event, at, pitch, volume)


func sound_anchor(event: StringName) -> Node3D:
	var at: Variant = _anchors.get(event)
	return at as Node3D if is_instance_valid(at) else self


## PIDE EL LOOP de `event` este paso, en `at`, con su tono y su volumen. Si lo piden varios (el taladro y la sierra en
## la misma meca), suena UNO, el más fuerte; lo que nadie pidió este paso se apaga (ver `_apply_holds`).
func hold(event: StringName, on: bool, at: Node3D = null, pitch := 1.0, volume := 1.0) -> void:
	if not on:
		return
	var wish: Array = _wishes.get(event, [])
	if wish.is_empty() or volume > float(wish[2]):
		_wishes[event] = [at, pitch, volume]


## Prende, afina o apaga cada loop según lo pedido este paso.
func _apply_holds() -> void:
	for event: StringName in _loops.keys():
		if not _wishes.has(event):
			stop_sound(event)
	for event: StringName in _wishes:
		var wish: Array = _wishes[event]
		if wish[0] != null:
			_anchors[event] = wish[0]
		if not _loops.has(event):
			heard[event] = int(heard.get(event, 0)) + 1
		start_sound(event)
		for player: Variant in _loops.get(event, []):
			if is_instance_valid(player):
				(player as AudioStreamPlayer3D).pitch_scale = maxf(float(wish[1]), 0.05)
				(player as AudioStreamPlayer3D).volume_db = linear_to_db(maxf(float(wish[2]), 0.0001))
	_wishes.clear()


## ── LO QUE DEPENDE DEL ESTADO ───────────────────────────────────────────────────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(mech):
		return
	_moves()
	_state(mech as ToolMech)
	_apply_holds()


## Lo de la meca con herramientas: la energía, el escudo, lo de los brazos y el artillero.
func _state(tool: ToolMech) -> void:
	if tool == null:
		return
	var stunned := not tool.energy.able()
	if stunned and not _stunned_was:
		play_sound(EMPTY)
	_stunned_was = stunned
	if tool.shield.on and not _shield_was:
		play_sound(SHIELD_UP, _tip_node(tool.guard))
	_shield_was = tool.shield.on
	hold(SHIELD_HUM, tool.shield.on, _tip_node(tool.guard))
	for arm in tool.arms:
		if arm.tip is SpinTip:
			var spinner := arm.tip as SpinTip
			hold(SPIN, spinner.spin > 0.02, spinner.forearm, 0.5 + spinner.spin, 0.3 + 0.7 * spinner.spin)
		elif arm.tip is CannonTip:
			var cannon := arm.tip as CannonTip
			hold(CANNON_BEAM, cannon.beaming(), cannon.forearm)
			hold(CANNON_CHARGE, cannon.mode == CannonTip.Mode.SUPER and cannon.charge > 0.0, cannon.forearm,
				0.6 + 0.8 * cannon.charge)
	if tool.cabin is CageCabin and (tool.cabin as CageCabin).turret != null:
		_gunner((tool.cabin as CageCabin).turret)


## La meca: aterrizar (más fuerte cuanto más caía), saltar, el dash y levitar.
func _moves() -> void:
	var mover := mech.mover
	if mover == null:
		return
	var grounded := mech.grounded
	if not grounded:
		_falling = maxf(-mover.velocity.y, 0.0)
	elif not _grounded_was and _falling >= LAND_SOFT:
		var share := clampf((_falling - LAND_SOFT) / (LAND_HARD - LAND_SOFT), 0.0, 1.0)
		play_sound(LAND, null, lerpf(1.1, 0.8, share), lerpf(0.4, 1.0, share))
	if _grounded_was and not grounded and mover.velocity.y > 1.0:
		play_sound(JUMP)
	_grounded_was = grounded
	var flat := Vector2(mover.velocity.x, mover.velocity.z).length()
	var dashing := flat > mech.kinematic_settings().walk_speed * DASH_OVER
	if dashing and not _dashing:
		play_sound(DASH)
	_dashing = dashing
	hold(LEVITATE, mover.levitating)


## El artillero: la minigun girando, trabarse y la recarga con ritmo.
func _gunner(turret: GunnerTurret) -> void:
	var weapons := turret.weapons
	if weapons == null:
		return
	hold(MINIGUN_SPIN, weapons.spin > 0.02, turret, 0.5 + weapons.spin, 0.2 + 0.6 * weapons.spin)
	if weapons.jammed and not _jam_was:
		play_sound(MINIGUN_JAM, turret)
	_jam_was = weapons.jammed
	if weapons.reloading >= 0 and _reload_was < 0:
		play_sound(RELOAD, turret)
	if weapons.reload_jammed and not _reload_bad_was:
		play_sound(RELOAD_BAD, turret)
	_reload_was = weapons.reloading
	_reload_bad_was = weapons.reload_jammed


func _tip_node(tip: ArmTip) -> Node3D:
	return tip.forearm if tip != null else null
