class_name MechShield
extends Node3D

## EL ESCUDO DE FUERZA (18/11/2026; el diseño, docs/conceptual/armamento.md, «El escudo de fuerza»; el usuario: «el del
## escudo, que tiene que estar en todos»). UNO SOLO, GLOBAL: un campo semitransparente que envuelve a toda la meca
## mientras se mantiene `held` (el botón ESCUDO del de arriba, o la Q poseyéndola o en el modo manejo):
##   · PRENDERLO GASTA UN GOLPE DE ENERGÍA (`START_COST`), al apretar, y mantenerlo un poco más por segundo
##     (`HOLD_COST`). Sin energía para prenderlo, no prende (hay que volver a apretar); si se vacía manteniéndolo, se
##     apaga y la meca queda aturdida, como siempre (MechEnergy).
##   · FRENA TODO GOLPE: quien pega pregunta si se le puede pegar (HitReaction.land → ToolMech.untouchable) y, con el
##     escudo, no.
##   · EL PARRY: el primer golpe frenado hasta `PARRY` s después de prenderlo devuelve lo que costó prenderlo («así no
##     castiga tanto»).
## Se ve el campo, que aparece y se apaga, con un destello en cada golpe frenado.

const START_COST := 0.12
const HOLD_COST := 0.2
const PARRY := 0.3
const TINT := Color(0.45, 0.8, 1.0)
const ALPHA := 0.16
## El campo: su centro desde la meca y su tamaño (m), de los pies a lo alto de la torre y de brazo a brazo.
const CENTER := Vector3(0.0, -0.2, 0.0)
const SIZE := Vector3(7.4, 9.0, 6.0)

## Lo que se pide: mantenido.
var held := false
## Si está prendido.
var on := false
var energy: MechEnergy = null
var _held_was := false
var _since := 0.0
var _refunded := false
var _field: MeshInstance3D = null
var _paint: StandardMaterial3D = null
var _shown := 0.0
var _flash := 0.0


func _ready() -> void:
	name = "Escudo"
	_field = MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.5
	ball.height = 1.0
	_field.mesh = ball
	_field.scale = SIZE
	_field.position = CENTER
	_paint = StandardMaterial3D.new()
	_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	_paint.albedo_color = Color(TINT, 0.0)
	_field.material_override = _paint
	_field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_field.visible = false
	add_child(_field)


func _physics_process(delta: float) -> void:
	if held and not _held_was and not on and energy != null and energy.spend(START_COST):
		on = true
		_since = 0.0
		_refunded = false
	_held_was = held
	if on:
		_since += delta
		if not held or not energy.drain(HOLD_COST, delta):
			on = false


func _process(delta: float) -> void:
	_shown = move_toward(_shown, 1.0 if on else 0.0, delta * 8.0)
	_flash = move_toward(_flash, 0.0, delta * 3.0)
	_field.visible = _shown > 0.0 or _flash > 0.0
	_paint.albedo_color = Color(TINT, ALPHA * _shown + 0.5 * _flash)


## UN GOLPE FRENADO (lo avisa ToolMech.untouchable): el destello y, si fue justo después de prenderlo, el parry.
func stopped() -> void:
	_flash = 1.0
	if on and _since <= PARRY and not _refunded and energy != null:
		_refunded = true
		energy.level = minf(energy.level + START_COST, 1.0)
