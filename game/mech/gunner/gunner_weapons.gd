class_name GunnerWeapons
extends Node

## LAS ARMAS DEL ARTILLERO (18/11/2026; el usuario: «hacelos andar»; «que se sientan como hechizos»; «el timing de la
## recarga»; «misiles guiados o misiles con trayectoria… fíjate las variaciones que puedo hacer con eso nomás»): la
## MINIGUN y la CAJA DE MISILES de la torreta (GunnerTurret), con lo que piden sus botones y el gatillo del yugo.
##
##   · EL GATILLO (el clic izquierdo con el yugo agarrado) dispara LA ELEGIDA: la minigun mientras se lo mantiene, los
##     misiles uno por apretada (derecho, salvo lo que pidan sus botones).
##   · LOS DOS BOTONES DE LAS ARMAS: elegir; y la elegida, RECARGAR CON RITMO: una aguja recorre su aro en `RELOAD_TIME`;
##     apretando otra vez con la aguja en LA ZONA (`ZONE`), recarga al instante y lo que se cargó pega más fuerte
##     (`GOOD_STRENGTH`); apretando fuera, se traba y tarda `JAM` más; sin apretar, termina sola al final del aro.
##   · LA MINIGUN SE CALIENTA: cada bala suma calor; llena, se traba hasta enfriarse a `UNJAM_HEAT`.
##   · SUS HABILIDADES, cada una con su tiempo de recarga (el aro se llena):
##       — SOBRECARGA: un rato, el doble de balas por segundo y el doble de calor.
##       — PERFORANTE: las próximas `PIERCE_ROUNDS` balas atraviesan.
##       — ENFRIAR: el calor, a cero.
##       — SALVA: los misiles que queden, todos seguidos.
##       — GUIADO: el próximo misil va adonde apunta la torreta mientras se la mueve.
##       — FIJAR: marca lo que está en la mira; los misiles lo persiguen un rato.
## Todavía no viaja por red: lo dispara y lo ve quien lo maneja.

enum Weapon { MINIGUN, MISSILES }

const MINIGUN_RATE := 14.0
const BELT := 150
const HEAT_PER_SHOT := 0.012
const COOL_RATE := 0.22
const UNJAM_HEAT := 0.35
const SPREAD := 1.2
const TUBES := 6
const MISSILE_GAP := 0.25
const SALVO_GAP := 0.12
## La recarga con ritmo (ver arriba): cuánto tarda la aguja (s), la zona (parte del aro), lo que tarda de más trabada
## (s) y cuánto más fuerte pega lo cargado bien (×).
const RELOAD_TIME := {Weapon.MINIGUN: 2.4, Weapon.MISSILES: 3.0}
const ZONE := Vector2(0.65, 0.8)
const JAM := 1.2
const GOOD_STRENGTH := 1.5
## Las habilidades: su tiempo de recarga (s) y lo que duran.
const COOLDOWNS := {"sobrecarga": 20.0, "perforante": 15.0, "enfriar": 25.0, "salva": 12.0, "guiado": 6.0, "fijar": 10.0}
const OVERCHARGE_TIME := 5.0
const PIERCE_ROUNDS := 40
const LOCK_TIME := 8.0

## La torreta que las lleva (de dónde salen, adónde apunta; la pone ella).
var turret: GunnerTurret = null
var selected := Weapon.MINIGUN
var heat := 0.0
var jammed := false
var belt := BELT
var tubes := TUBES
## Lo cargado bien (la recarga con ritmo): cuánto más fuerte pega, por arma.
var strength := {Weapon.MINIGUN: 1.0, Weapon.MISSILES: 1.0}
## La recarga en curso: de qué arma (-1, ninguna), cuánto va la aguja (0 a 1) y si se trabó.
var reloading := -1
var needle := 0.0
var reload_jammed := false
## Lo que falta de cada tiempo de recarga (s), y lo que dura lo que está andando.
var cooldown := {}
var overcharge_left := 0.0
var pierce_left := 0
var guided_next := false
var locked: Node3D = null
var lock_left := 0.0

var _trigger := false
var _fire_wait := 0.0
var _salvo_left := 0
var _salvo_wait := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for action: String in COOLDOWNS:
		cooldown[action] = 0.0


## EL GATILLO DEL YUGO.
func trigger(pressed: bool) -> void:
	var was := _trigger
	_trigger = pressed
	if pressed and not was and selected == Weapon.MISSILES:
		_fire_missile(false)


## UN BOTÓN DE LOS TABLEROS: el nombre de su acción (ver GunnerTurret, los tableros).
func press(action: String) -> void:
	match action:
		"minigun":
			_weapon_button(Weapon.MINIGUN)
		"misiles":
			_weapon_button(Weapon.MISSILES)
		_:
			if not COOLDOWNS.has(action) or float(cooldown[action]) > 0.0:
				return
			if _ability(action):
				cooldown[action] = COOLDOWNS[action]


## CUÁNTO ESTÁ LISTA una acción (0 a 1: lo que lleva de su tiempo de recarga); las armas, cuánto les queda cargado.
func ready_of(action: String) -> float:
	match action:
		"minigun":
			return float(belt) / BELT
		"misiles":
			return float(tubes) / TUBES
	if not COOLDOWNS.has(action):
		return 0.0
	return 1.0 - float(cooldown[action]) / float(COOLDOWNS[action])


func _weapon_button(weapon: Weapon) -> void:
	if selected != weapon:
		selected = weapon
		_trigger = false
		return
	if reloading == weapon:
		# La segunda apretada: en la zona, listo y más fuerte; fuera, trabada.
		if not reload_jammed and needle >= ZONE.x and needle <= ZONE.y:
			_finish_reload(GOOD_STRENGTH)
		else:
			reload_jammed = true
		return
	if reloading < 0:
		reloading = weapon
		needle = 0.0
		reload_jammed = false


func _finish_reload(power: float) -> void:
	if reloading == Weapon.MINIGUN:
		belt = BELT
	else:
		tubes = TUBES
	strength[reloading] = power
	reloading = -1
	reload_jammed = false


func _ability(action: String) -> bool:
	match action:
		"sobrecarga":
			overcharge_left = OVERCHARGE_TIME
		"perforante":
			pierce_left = PIERCE_ROUNDS
		"enfriar":
			heat = 0.0
			jammed = false
		"salva":
			if tubes <= 0:
				return false
			_salvo_left = tubes
			_salvo_wait = 0.0
		"guiado":
			guided_next = true
		"fijar":
			var target := turret.aimed_body() if turret != null else null
			if target == null:
				return false
			locked = target
			lock_left = LOCK_TIME
	return true


func _physics_process(delta: float) -> void:
	for action: String in cooldown:
		cooldown[action] = maxf(float(cooldown[action]) - delta, 0.0)
	overcharge_left = maxf(overcharge_left - delta, 0.0)
	lock_left = maxf(lock_left - delta, 0.0)
	if lock_left <= 0.0:
		locked = null
	_fire_wait = maxf(_fire_wait - delta, 0.0)
	# EL CALOR: baja solo; trabada, hasta `UNJAM_HEAT`.
	heat = maxf(heat - COOL_RATE * delta, 0.0)
	if jammed and heat <= UNJAM_HEAT:
		jammed = false
	# LA RECARGA: la aguja avanza; al final del aro (más lo trabado), termina sola.
	if reloading >= 0:
		needle += delta / float(RELOAD_TIME[reloading])
		if needle >= 1.0 + (JAM / float(RELOAD_TIME[reloading]) if reload_jammed else 0.0):
			_finish_reload(1.0)
	# LA SALVA.
	if _salvo_left > 0:
		_salvo_wait -= delta
		if _salvo_wait <= 0.0:
			_salvo_wait = SALVO_GAP
			_salvo_left -= 1
			_fire_missile(true)
	if not _trigger or turret == null:
		return
	if selected == Weapon.MINIGUN:
		_fire_minigun()


func _fire_minigun() -> void:
	if jammed or belt <= 0 or reloading == Weapon.MINIGUN or _fire_wait > 0.0:
		return
	var rate := MINIGUN_RATE * (2.0 if overcharge_left > 0.0 else 1.0)
	_fire_wait = 1.0 / rate
	belt -= 1
	heat += HEAT_PER_SHOT * (2.0 if overcharge_left > 0.0 else 1.0)
	if heat >= 1.0:
		heat = 1.0
		jammed = true
	var muzzle := turret.minigun_muzzle()
	var spread := deg_to_rad(SPREAD)
	var aim := muzzle.basis * Basis.from_euler(Vector3(_rng.randf_range(-spread, spread), _rng.randf_range(-spread, spread), 0.0))
	var bullet := GunnerBullet.new()
	bullet.skip = turret.skip()
	bullet.strength = float(strength[Weapon.MINIGUN])
	if pierce_left > 0:
		bullet.pierce = true
		pierce_left -= 1
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform = Transform3D(aim.orthonormalized(), muzzle.origin)
	GunnerFx.muzzle(muzzle.origin, 0.12)


## UN MISIL, del próximo tubo cargado: derecho, guiado (si se lo pidió) o persiguiendo lo fijado. `salvo`: los de la
## salva, sin esperar entre uno y otro.
func _fire_missile(salvo: bool) -> void:
	if turret == null or tubes <= 0 or reloading == Weapon.MISSILES or (not salvo and _fire_wait > 0.0):
		return
	_fire_wait = MISSILE_GAP
	var tube := TUBES - tubes
	tubes -= 1
	var mouth := turret.missile_mouth(tube)
	var missile := GunnerMissile.new()
	missile.skip = turret.skip()
	missile.strength = float(strength[Weapon.MISSILES])
	if is_instance_valid(locked):
		missile.chase = locked
	elif guided_next:
		missile.steer = turret.aim_point
		guided_next = false
	get_tree().current_scene.add_child(missile)
	missile.global_transform = mouth
	GunnerFx.muzzle(mouth.origin, 0.2)
