class_name GunnerWeapons
extends Node

## LA AMETRALLADORA Y LOS MISILES DE LA MECA (ver MechGuns): cada una con su tecla (MechCrew).
##   · LA AMETRALLADORA ARRANCA (el usuario, 18/11/2026: «tenés que mantener apretado… un rato para que empiece a
##     disparar»): mantenida, los caños toman vuelta (`spin`, en `SPIN_UP` s) y recién a toda vuelta dispara; suelta, se
##     frenan en `SPIN_DOWN` s. Cada bala calienta; llena de calor, se traba hasta enfriarse a `UNJAM_HEAT`.
##   · LOS MISILES salen de a uno por apretada.
##   · VACÍA, CADA UNA SE RECARGA SOLA en su `RELOAD_TIME`.
## Lo simula el dueño de la meca (BodyNet); cada disparo va por MechGuns a todas las máquinas.
## *Hasta el 22/11/2026 eran de la torreta del artillero, con yugo, tableros, recarga con ritmo y seis habilidades
## (sobrecarga, perforante, enfriar, salva, guiado y fijar): están en el commit 5238ff8.*

enum Weapon { MINIGUN, MISSILES }

const MINIGUN_RATE := 14.0
const BELT := 150
const HEAT_PER_SHOT := 0.012
const COOL_RATE := 0.22
const UNJAM_HEAT := 0.35
## Lo que se abre cada bala de costado (°): nunca para arriba o abajo.
const SPREAD := 1.2
const SPIN_UP := 0.9
const SPIN_DOWN := 1.2
const TUBES := 6
const MISSILE_GAP := 0.25
const RELOAD_TIME := {Weapon.MINIGUN: 2.4, Weapon.MISSILES: 3.0}
## LAS PERFORANTES vienen menos por caja.
const PIERCING_BELT := 90

## Las armas montadas (de dónde salen; las pone MechGuns).
var guns: MechGuns = null
var heat := 0.0
## Cuánto giran los caños (0 quietos, 1 a toda vuelta: recién ahí dispara).
var spin := 0.0
var jammed := false
var belt := BELT
var tubes := TUBES
## LO QUE TIENEN CARGADO (SupplyKinds). Lo especial dura una carga: al recargarse sola, vuelve a la común.
var bullet_kind: int = SupplyKinds.Kind.BULLETS
var missile_kind: int = SupplyKinds.Kind.MISSILES
## Lo que le falta a cada recarga (s; 0, ninguna).
var reload_left := {Weapon.MINIGUN: 0.0, Weapon.MISSILES: 0.0}

var _holding := false
var _bullet_wait := 0.0
var _missile_wait := 0.0
var _rng := RandomNumberGenerator.new()


## LE PONEN UN PAQUETE DE MUNICIÓN: carga entera de ese tipo. Lo hace quien la simula.
func load_supply(kind: int) -> void:
	if guns != null and not guns.is_mine():
		return
	if SupplyKinds.is_bullets(kind):
		bullet_kind = kind
		belt = PIERCING_BELT if kind == SupplyKinds.Kind.PIERCING else BELT
		reload_left[Weapon.MINIGUN] = 0.0
	elif SupplyKinds.is_missiles(kind):
		missile_kind = kind
		tubes = TUBES
		reload_left[Weapon.MISSILES] = 0.0


## LA TECLA DE LA AMETRALLADORA, mantenida.
func hold_minigun(pressed: bool) -> void:
	_holding = pressed


## Si alguien mantiene su tecla.
func holding() -> bool:
	return _holding


## LA TECLA DE LOS MISILES: uno por apretada, encaminado por la mira de `launcher` (la máquina que la apretó). En las
## máquinas que la siguen, lo dispara el dueño.
func launch_missile(launcher := 0) -> void:
	if guns == null or not guns.is_mine() or tubes <= 0 or _missile_wait > 0.0:
		return
	_missile_wait = MISSILE_GAP
	var tube := TUBES - tubes
	tubes -= 1
	guns.shoot_missile(guns.missile_mouth(tube), launcher)
	if tubes <= 0:
		reload_left[Weapon.MISSILES] = RELOAD_TIME[Weapon.MISSILES]


## CUÁNTO LLEVA DE SU RECARGA (0 a 1; 0, no se está recargando), para su cuadrado.
func reload_share(weapon: Weapon) -> float:
	var left := float(reload_left[weapon])
	return 0.0 if left <= 0.0 else 1.0 - left / float(RELOAD_TIME[weapon])


## LO QUE VEN LOS DEMÁS en sus cuadrados (lo manda MechGuns): el calor, la munición y las recargas.
func get_state() -> Array:
	return [heat, jammed, belt, tubes, reload_left[Weapon.MINIGUN], reload_left[Weapon.MISSILES], bullet_kind, missile_kind]


func apply_state(state: Array) -> void:
	heat = float(state[0])
	jammed = bool(state[1])
	belt = int(state[2])
	tubes = int(state[3])
	reload_left[Weapon.MINIGUN] = float(state[4])
	reload_left[Weapon.MISSILES] = float(state[5])
	bullet_kind = int(state[6])
	missile_kind = int(state[7])


## Si la ametralladora está tirando balas ahora (a toda vuelta, con balas y sin trabarse).
func firing() -> bool:
	return _holding and spin >= 1.0 and not jammed and belt > 0


## Si alguna se está recargando (para su sonido).
func reloading() -> bool:
	return float(reload_left[Weapon.MINIGUN]) > 0.0 or float(reload_left[Weapon.MISSILES]) > 0.0


func _physics_process(delta: float) -> void:
	spin = clampf(spin + (delta / SPIN_UP if _holding else -delta / SPIN_DOWN), 0.0, 1.0)
	if guns == null or not guns.is_mine():
		return
	_bullet_wait = maxf(_bullet_wait - delta, 0.0)
	_missile_wait = maxf(_missile_wait - delta, 0.0)
	# SE ENFRÍA SÓLO SIN DISPARAR (o trabada). *Hasta el 22/11/2026 se enfriaba siempre, más rápido de lo que calentaba cada
	# bala: a ritmo normal nunca llegaba a trabarse.*
	if not _holding or jammed:
		heat = maxf(heat - COOL_RATE * delta, 0.0)
	if jammed and heat <= UNJAM_HEAT:
		jammed = false
	_reload(Weapon.MINIGUN, delta)
	_reload(Weapon.MISSILES, delta)
	if _holding and spin >= 1.0:
		_fire_minigun()


func _reload(weapon: Weapon, delta: float) -> void:
	var left := float(reload_left[weapon])
	if left <= 0.0:
		return
	left -= delta
	reload_left[weapon] = maxf(left, 0.0)
	if left <= 0.0:
		if weapon == Weapon.MINIGUN:
			belt = BELT
			bullet_kind = SupplyKinds.Kind.BULLETS
		else:
			tubes = TUBES
			missile_kind = SupplyKinds.Kind.MISSILES


func _fire_minigun() -> void:
	if jammed or belt <= 0 or _bullet_wait > 0.0:
		return
	_bullet_wait = 1.0 / MINIGUN_RATE
	belt -= 1
	heat += HEAT_PER_SHOT
	if heat >= 1.0:
		heat = 1.0
		jammed = true
	if belt <= 0:
		reload_left[Weapon.MINIGUN] = RELOAD_TIME[Weapon.MINIGUN]
	var muzzle := guns.minigun_muzzle()
	var spread := deg_to_rad(SPREAD)
	var aim := Basis(Vector3.UP, _rng.randf_range(-spread, spread)) * muzzle.basis
	guns.shoot_bullet(Transform3D(aim.orthonormalized(), muzzle.origin))
