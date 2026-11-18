class_name MechShield
extends Node

## EL ESCUDO: LA MECÁNICA (18/11/2026; el diseño, docs/conceptual/armamento.md, «El escudo de fuerza»). Lo que se ve es el
## escudo físico de un brazo (ShieldTip, `tip`): SIN UN BRAZO DE ESCUDO NO HAY ESCUDO (el usuario: «si querés tener un
## escudo vas a tener un arma menos»). Mientras se mantiene `held` (el mando de ese brazo, la Q poseyéndola o en el modo
## manejo):
##   · PRENDERLO GASTA UN GOLPE DE ENERGÍA (`START_COST`), al apretar, y mantenerlo un poco más por segundo
##     (`HOLD_COST`). Sin energía para prenderlo, no prende (hay que volver a apretar); si se vacía manteniéndolo, se
##     apaga y la meca queda aturdida, como siempre (MechEnergy). Prendido, el brazo lo levanta (`tip.up`).
##   · FRENA LO QUE VIENE DE FRENTE: lo decide ToolMech.block_hit, que llama quien pega una vez por golpe.
##   · EL PARRY: el primer golpe frenado hasta `PARRY` s después de prenderlo devuelve lo que costó prenderlo («así no
##     castiga tanto»). Cada golpe frenado, un destello donde pegó.
## *Hasta el 18/11/2026 era un campo que envolvía a la meca (una burbuja; se probaron también una cáscara pegada al
## cuerpo, una pantalla de frente y una caja): el usuario los descartó a todos. Están en el commit 20227d6.*

const START_COST := 0.12
const HOLD_COST := 0.2
const PARRY := 0.3
const FLASH := Color(0.85, 0.9, 1.0)

## Lo que se pide: mantenido.
var held := false
## Si está prendido (y el brazo lo tiene levantado).
var on := false
var energy: MechEnergy = null
## El escudo del brazo (ver ToolMech._build_arms); sin él, no hay escudo.
var tip: ShieldTip = null
var _held_was := false
var _since := 0.0
var _refunded := false


func _ready() -> void:
	name = "Escudo"


func _physics_process(delta: float) -> void:
	var asked := held and tip != null
	if asked and not _held_was and not on and energy != null and energy.spend(START_COST):
		on = true
		_since = 0.0
		_refunded = false
	_held_was = asked
	if on:
		_since += delta
		if not asked or not energy.drain(HOLD_COST, delta):
			on = false
	if tip != null:
		tip.up = on


## UN GOLPE FRENADO (lo avisa ToolMech.block_hit, con dónde pegó si lo sabe): el destello y, si fue justo después de
## prenderlo, el parry.
func stopped(at := Vector3.INF) -> void:
	if at.is_finite() and is_inside_tree():
		EnergyBolt.flash(get_tree().current_scene, at, 0.5, FLASH)
	if on and _since <= PARRY and not _refunded and energy != null:
		_refunded = true
		energy.level = minf(energy.level + START_COST, 1.0)
