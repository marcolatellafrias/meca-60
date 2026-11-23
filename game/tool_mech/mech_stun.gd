class_name MechStun
extends Node

## EL ESTADO DE STUN DE LA MECA (22/11/2026; el usuario: «formalizar el estado de stuneado… que baje los brazos y se note como
## electrificado… y luego podemos reusar ese efecto»). Cualquier cosa la aturde con `hit(segundos)`: el súper del cañón
## pagado de más (MechEnergy.settle), una bolita eléctrica de un jefe, y lo que venga.
##   · LO QUE DURA es `MechEnergy.stunned`: ya frena caminar, girar, los golpes y el dash, y ya viaja por la red.
##   · LO QUE SE VE, en todas las máquinas: los brazos caen y tiemblan (`MechArm.limp`) y le saltan rayos (ElectricFx).
##   · POR LA RED lo aplica el dueño de la meca: el host le pide a él (`hit`).

const NODE_NAME := "Aturdimiento"
## En cuánto caen los brazos y en cuánto vuelven (s).
const ARMS_DOWN := 0.14
const ARMS_UP := 0.35
const SPARK_OUT := 0.45

var mech: ToolMech = null
var _fx: ElectricFx = null


func _ready() -> void:
	name = NODE_NAME


## Si está aturdida ahora.
func active() -> bool:
	return mech != null and not mech.energy.able()


## LA ATURDE `seconds` segundos (si ya estaba, se queda con lo más largo).
func hit(seconds: float) -> void:
	if mech.net != null and mech.net.networked() and mech.net.remote():
		_take.rpc_id(mech.net.authority, seconds)
	else:
		mech.energy.stun(seconds)


@rpc("any_peer", "call_remote", "reliable")
func _take(seconds: float) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		mech.energy.stun(seconds)


func _process(delta: float) -> void:
	if mech == null:
		return
	var down := active()
	for arm in mech.arms:
		arm.limp = move_toward(arm.limp, 1.0 if down else 0.0, delta / (ARMS_DOWN if down else ARMS_UP))
	if down and _fx == null:
		_fx = ElectricFx.attach(mech, _box())
	if _fx != null:
		_fx.on = down


func _box() -> Vector3:
	var form := CageCabin.shape()
	return Vector3(form.side() * 0.5 + SPARK_OUT, form.height() * 0.5 + SPARK_OUT, form.side() * 0.5 + SPARK_OUT)
