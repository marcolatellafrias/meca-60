class_name Mech
extends BalanceBody

## LA MECA PROPIA: el cuerpo con equilibrio (ver BalanceBody: la caja, el péndulo, caerse y volver, las piernas, las
## toberas, caminar y saltar), con lo que es sólo suyo:
##   · CageCabin    la cabina jaula: el que maneja abajo, el de los brazos arriba y el artillero atrás, y el marco que
##                  lleva a los que van adentro.
##   · MechKeys     el teclado y el mouse de quien la posee: escribe LO QUE SE LE PIDE (ver `_think`).
##   · los brazos   MechArm: PoseArm (discretos) o MuscleArm (físicos), cada uno el suyo (ver `loadout`). Sin brazos es
##                  la meca de práctica, para pegarle.
## *Hasta el 13/11/2026 el cuerpo y el equilibrio vivían acá; se separaron para compartirlos con los jefes (ver
## docs/technical/base-comun.md). Hasta el 17/11/2026 llevaba también las cabinas de la meca grande —la cuadrada, la
## redonda, la del vórtice y la de cápsulas—, las toberas que se ven y la simplificada sin cabina; se borraron con ella
## (el usuario: «limitarnos solamente a un approach de meca a una escala más humana»; están en el commit 0bcaeaf).*

## Los brazos que lleva: ninguno (la de práctica, para pegarle) o los de su `loadout`.
## *Hasta el 17/11/2026 había también MUSCLE, la meca física de la meca grande: hoy cada brazo elige cómo se mueve.*
enum Arms { NONE, POSE }
## LA CABINA QUE LLEVA, una pieza más (ver docs/technical/cuerpo-por-piezas.md): la jaula (CageCabin; el usuario,
## 16/11/2026: «empezar a migrar esta meca a algo funcional»), la de las maquetas de tests/cage_ideas_look, chica, con
## brazos y piernas al 30 %. Lo que cambia con ella se pregunta en un solo lugar: `cabin_kit`.
enum Cabin { CAGE }

const MASS := 50000.0
## LOS BRAZOS: el hombro, en el espacio de la caja (`x` del lado derecho), lo da la cabina (CageCabin.shoulder), más lo
## que los corre afuera (MechBody.shoulder_out, el F2: «Brazos y piernas»). Y cuánto pesan los físicos, en partes de lo
## que pesa el brazo solo (ver MuscleArm.weight).


static func shoulder(shape := Cabin.CAGE) -> Vector3:
	var kit := cabin_kit(shape)
	var body: MechBody = kit["body"]
	return (kit["shoulder"] as Vector3) + Vector3(body.shoulder_out * body.thick, 0.0, 0.0)


## LO QUE CAMBIA CON LA CABINA, en un solo lugar: la caja (`box`), el hombro sin lo que lo corre afuera (`shoulder`) y EL
## CUERPO (`body`, sus medidas: MechBody, las de su F2 achicadas; ver CageCabin.body).
static func cabin_kit(_shape := Cabin.CAGE) -> Dictionary:
	return {"box": CageCabin.box(), "shoulder": CageCabin.shoulder(), "body": CageCabin.body()}


const ARM_WEIGHT := 0.4

## Qué brazos lleva. Se pone antes de agregarla al árbol.
var arms_kind := Arms.POSE
## LO QUE LLEVA CADA BRAZO (ver ArmLoadout), el izquierdo y el derecho: cómo se mueve, qué va en la punta y si lleva
## placa. Puesto a mano (un test), manda. Vacío: lo guardado en el panel de equipamiento para su fila (`equipment`, ver
## MechLoadout) o, sin fila, lo de su clase (`default_loadout`). Se pone antes de agregarla.
var loadout: Array[ArmLoadout] = []
## LA FILA DEL SANDBOX DE LA QUE ES (su nombre; la pone su arquetipo): de ahí sale su equipo guardado. Vacía, ninguno.
var equipment := ""
## La postura de los brazos que se le pide: cubriéndose, o normal.
var covering := false

var cabin: MechCabin = null
## La cabina que lleva (ver `Cabin`). Se pone antes de agregarla.
var cabin_shape := Cabin.CAGE
var keys: MechKeys = null
var arms: Array[MechArm] = []
## La maneja algo que no son sus teclas (un test, un cerebro): no las lee.
var scripted := false


func _init() -> void:
	super()
	mass = MASS
	size = CageCabin.box()
	hover = measures.WAIST


func _ready() -> void:
	name = "Meca de práctica" if arms_kind == Arms.NONE else "Meca"
	var kit := cabin_kit(cabin_shape)
	size = kit["box"]
	measures = kit["body"]
	hover = measures.WAIST
	super()
	add_to_group(SandboxPossession.GROUP)


func _build() -> void:
	keys = MechKeys.new()
	keys.mech = self
	add_child(keys)
	cabin = CageCabin.new()
	cabin.mech = self
	add_child(cabin)
	_build_arms()
	cabin.build_frame()
	if arms_kind != Arms.NONE:
		cabin.seat_dummies.call_deferred()


func _build_arms() -> void:
	if arms_kind == Arms.NONE:
		return
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		var arm := (_loadout_now()[index] as ArmLoadout).make_arm(ARM_WEIGHT, _arm_energy())
		arm.side = side
		arm.anchor = self
		arm.measures = measures
		var at := shoulder(cabin_shape)
		arm.shoulder_local = Vector3(side * at.x, at.y, at.z)
		arm.stance = MechArm.Stance.NORMAL
		if skeleton != null:
			arm.upper_bone = skeleton.uppers[index]
			arm.forearm_bone = skeleton.forearms[index]
		add_child(arm)
		arms.append(arm)


## EL HOMBRO DERECHO para el esqueleto: el de su cabina (ver `shoulder`).
func _shoulder() -> Vector3:
	return Mech.shoulder(cabin_shape)


## LO QUE LLEVAN LOS BRAZOS AL ARMARLA (ver `loadout`).
func _loadout_now() -> Array[ArmLoadout]:
	if loadout.size() == 2:
		return loadout
	if equipment != "":
		return MechLoadout.current(equipment, default_loadout()).arms()
	return default_loadout()


## LO QUE LLEVA SU CLASE, sin nada guardado: los dos con el puño común, discretos, sin placa.
func default_loadout() -> Array[ArmLoadout]:
	return Mech.fists()


static func fists() -> Array[ArmLoadout]:
	return [ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.FIST), ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.FIST)]


## De dónde sacan la energía los brazos (sin energía propia, nada: lo que la gasta no anda; ver ToolMech).
func _arm_energy() -> MechEnergy:
	return null


## LA PUNTA DE LA CLASE `kind` del primer brazo que la lleve (o nada).
func tip_of(kind: Script) -> ArmTip:
	for arm in arms:
		if arm.tip != null and is_instance_of(arm.tip, kind):
			return arm.tip
	return null


func _think() -> void:
	if not scripted:
		keys.read()


## LA POSTURA DE LOS BRAZOS: la elegida parada; recogidos caída y subiendo (se estiran al enderezarse, con las piernas).
## Y el marco: la caja deja de chocar con los que van adentro.
func _after_step(_k: BodySettings, _delta: float) -> void:
	var fallen := state == State.DOWN or state == State.LIFT
	for arm in arms:
		arm.stance = MechArm.Stance.TUCKED if fallen else (MechArm.Stance.COVER if covering else MechArm.Stance.NORMAL)
	if cabin != null:
		cabin.ride()


## ── POSEERLA (ver SandboxPossession): lo atiende su teclado ──────────────────────────────────────────────────────

func possess_name() -> String:
	return String(name)


func possess_controls() -> PackedStringArray:
	return keys.controls()


func possess_status() -> String:
	if kinematic:
		return "dash %s   vuelo %s\n%.1f m/s%s · acható %d" % [BodyMoves._bar(mover.dash_fuel), BodyMoves._bar(mover.fly_fuel),
			mover.speed(), "" if grounded else " · en el aire", mover.flattened + (stomp.flattened if stomp != null else 0)]
	return moves.status()


func possess_begin() -> void:
	keys.begin()


func possess_end() -> void:
	keys.end()


func possess_camera(first: bool, delta: float) -> Transform3D:
	return keys.camera(first, delta)


## REARMA TODAS LAS MECAS, Y NADA MÁS: cada una se cambia por una nueva igual —sus brazos, si es cinemática, su lugar en
## el piso, hacia dónde mira, parada sobre el piso de su parcela— con la forma y las perillas de ahora. Lo usan los
## paneles de la meca al probar y al guardar (el F2, la forma; el F1, las perillas). *Al principio se rearmaba la
## parcela entera, como la R, y lo demás volvía a como nace (lo vio el usuario).* Si se la estaba poseyendo, se la
## suelta antes; el que iba adentro queda donde estaba. *Vivía en el panel del F2; pasó acá el 13/11/2026, cuando el F1
## también lo necesitó.*
static func rebuild_all(tree: SceneTree) -> void:
	for found in tree.root.find_children("*", "Mech", true, false):
		var old := found as Mech
		if old == null or old.is_queued_for_deletion():
			continue
		if old.keys != null and old.keys.driving:
			SandboxPossession.of(tree).release()
		var holder := old.get_parent()
		# La misma clase (una subclase, como la meca jaula, sigue siendo ella).
		var fresh := old.get_script().new() as Mech
		fresh.arms_kind = old.arms_kind
		fresh.loadout = old.loadout
		fresh.equipment = old.equipment
		fresh.kinematic = old.kinematic
		fresh.cabin_shape = old.cabin_shape
		# Parada sobre el piso de su parcela (la altura 0 de lo que la tiene, como la arman sus arquetipos).
		fresh.transform = Transform3D(Basis(Vector3.UP, old.yaw()), Vector3(old.position.x,
			Mech.standing_height(old.cabin_shape),
			old.position.z))
		if old.cabin != null:
			old.cabin.free_dummies()
		holder.remove_child(old)
		old.queue_free()
		holder.add_child(fresh)


## A QUÉ ALTURA NACE PARADA (el centro de la caja sobre el piso, m): sus piernas más media caja. Un solo lugar para
## todas las parcelas que la arman. *Estaba copiado en cuatro.*
static func standing_height(shape := Cabin.CAGE) -> float:
	var kit := cabin_kit(shape)
	return (kit["body"] as MechBody).WAIST + (kit["box"] as Vector3).y * 0.5
