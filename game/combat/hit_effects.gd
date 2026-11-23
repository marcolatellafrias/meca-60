class_name HitEffects
extends Node

## LO QUE LE DEJA UNA MUNICIÓN ESPECIAL A UN BLANCO (22/11/2026; ver SupplyKinds). Cuelga de cada HitTarget y lo decide el host:
##   · PRENDIDO (`ignite`): sigue perdiendo vida unos segundos, a pulsos, con fuego a la vista.
##   · CARGA ELÉCTRICA (`charge`): cada bala suma; al llenarse lo aturde un momento (`daze` en quien recibe, si sabe) con los
##     rayos de ElectricFx.

const BURN_TIME := 3.0
const BURN_EVERY := 0.4
const BURN_POWER := 0.8
const BURN_STRENGTH := 21000.0
const BURN_COLOR := Color(1.0, 0.5, 0.12)
const SHOCK_FULL := 24
const SHOCK_TIME := 1.4

var target: HitTarget = null
## Para las pruebas: pulsos de fuego y veces que lo aturdió.
var burns := 0
var shocks := 0
var _burning := 0.0
var _clock := 0.0
var _charge := 0
var _fx: ElectricFx = null
var _fx_left := 0.0


func _ready() -> void:
	name = "Efectos"


## LO PRENDE (o le renueva el fuego).
func ignite() -> void:
	_burning = BURN_TIME


## UNA BALA ELÉCTRICA: suma, y al llenarse lo aturde.
func charge() -> void:
	_charge += 1
	if _charge < SHOCK_FULL:
		return
	_charge = 0
	shocks += 1
	if target.receiver != null and target.receiver.has_method("daze"):
		target.receiver.call("daze", SHOCK_TIME)
	if NetFollow.online(self):
		_shock.rpc(SHOCK_TIME)
	else:
		_shock(SHOCK_TIME)


func _physics_process(delta: float) -> void:
	if _burning <= 0.0 or ProjectileField.is_client(self):
		return
	_burning -= delta
	_clock -= delta
	if _clock > 0.0 or not target.alive():
		return
	_clock = BURN_EVERY
	burns += 1
	var at := target.center()
	target.strike("minigun", BURN_POWER, BURN_STRENGTH, at, Vector3.UP)
	if NetFollow.online(self):
		_flame.rpc(at)
	else:
		_flame(at)


func _process(delta: float) -> void:
	if _fx == null:
		return
	_fx_left -= delta
	_fx.on = _fx_left > 0.0


@rpc("authority", "call_local", "unreliable")
func _flame(at: Vector3) -> void:
	var size := target.flat_radius()
	var spot := at + Vector3(randf_range(-size, size), randf_range(0.2, size * 1.6), randf_range(-size, size)) * 0.7
	EnergyBolt.flash(target.get_parent(), spot, 0.45, BURN_COLOR)
	GunnerFx.sparks(spot, 0.3)


@rpc("authority", "call_local", "reliable")
func _shock(seconds: float) -> void:
	if not is_instance_valid(target.anchor):
		return
	if _fx == null:
		var size := target.flat_radius()
		_fx = ElectricFx.attach(target.anchor, Vector3(size, size * 1.4, size), 7)
		_fx.position = Vector3.UP * size * 1.2
	_fx_left = seconds
	_fx.on = true
