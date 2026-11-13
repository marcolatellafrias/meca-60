class_name Mech
extends BalanceBody

## LA MECA PROPIA: el cuerpo con equilibrio (ver BalanceBody: la caja, el péndulo, caerse y volver, las piernas, las
## toberas, caminar y saltar), con lo que es sólo suyo:
##   · MechCabin    los tres pisos por dentro, el afuera (MechExterior), el ascensor (PelvisLift) y el marco que lleva a
##                  los que van adentro.
##   · MechKeys     el teclado y el mouse de quien la posee: escribe LO QUE SE LE PIDE (ver `_think`).
##   · los brazos   MechArm: PoseArm (discretos) o MuscleArm (físicos), según `arms_kind`: los dos caminos. Sin brazos
##                  es la meca de práctica, para pegarle.
## *Hasta el 13/11/2026 el cuerpo y el equilibrio vivían acá; se separaron para compartirlos con los jefes (ver
## docs/technical/base-comun.md).*

## Los brazos que lleva: ninguno (la de práctica, para pegarle), discretos o físicos.
enum Arms { NONE, POSE, MUSCLE }

const MASS := 50000.0
const NAMES := ["Meca de práctica", "Meca discreta", "Meca física"]
## LOS BRAZOS: el hombro, en el espacio de la caja (`x` del lado derecho): el piso y el módulo del costado que se
## eligieron (ver CabinGrid.shoulder), `SHOULDER_OUT` afuera del costado, más con brazos más anchos. *El 12/11/2026 se
## probó en el último tercio, hacia atrás: la postura era más natural, pero el brazo alcanzaba 2,6 m menos hacia
## adelante, y el usuario lo volvió («estaban bien los brazos a la mitad, no me gusta el sacrificio en rango»). Desde el
## 13/11/2026 se elige en el panel F2.* Y cuánto pesan los físicos, en partes de lo que pesa el brazo solo (ver
## MuscleArm.weight).
const SHOULDER_OUT := 1.0


static func shoulder() -> Vector3:
	return CabinGrid.shoulder() + Vector3(SHOULDER_OUT * MechBody.thick, 0.0, 0.0)


const ARM_WEIGHT := 0.4

## Qué brazos lleva. Se pone antes de agregarla al árbol.
var arms_kind := Arms.POSE
## La postura de los brazos que se le pide: cubriéndose, o normal.
var covering := false

var cabin: MechCabin = null
var keys: MechKeys = null
var arms: Array[MechArm] = []


func _init() -> void:
	super()
	mass = MASS
	size = CabinGrid.box()
	hover = MechBody.WAIST


func _ready() -> void:
	name = NAMES[arms_kind]
	super()
	add_to_group(SandboxPossession.GROUP)


func _build() -> void:
	cabin = MechCabin.new()
	cabin.mech = self
	add_child(cabin)
	keys = MechKeys.new()
	keys.mech = self
	add_child(keys)
	_build_arms()
	cabin.build_frame()
	if arms_kind != Arms.NONE:
		cabin.seat_dummies.call_deferred()


func _build_arms() -> void:
	if arms_kind == Arms.NONE:
		return
	for side: float in [-1.0, 1.0]:
		var arm: MechArm = null
		if arms_kind == Arms.MUSCLE:
			var muscle := MuscleArm.new()
			muscle.weight = ARM_WEIGHT
			arm = muscle
		else:
			arm = PoseArm.new()
		arm.side = side
		arm.anchor = self
		var at := shoulder()
		arm.shoulder_local = Vector3(side * at.x, at.y, at.z)
		arm.stance = MechArm.Stance.NORMAL
		add_child(arm)
		arms.append(arm)


func _think() -> void:
	keys.read()


## LA POSTURA DE LOS BRAZOS: la elegida parada; recogidos caída y subiendo (se estiran al enderezarse, con las piernas).
## Y el marco: la caja deja de chocar con los que van adentro.
func _after_step(_k: BodySettings, _delta: float) -> void:
	var fallen := state == State.DOWN or state == State.LIFT
	for arm in arms:
		arm.stance = MechArm.Stance.TUCKED if fallen else (MechArm.Stance.COVER if covering else MechArm.Stance.NORMAL)
	cabin.ride()


## ── POSEERLA (ver SandboxPossession): lo atiende su teclado ──────────────────────────────────────────────────────

func possess_name() -> String:
	return String(name)


func possess_controls() -> PackedStringArray:
	return keys.controls()


func possess_status() -> String:
	return moves.status()


func possess_begin() -> void:
	keys.begin()


func possess_end() -> void:
	keys.end()


func possess_camera(first: bool, delta: float) -> Transform3D:
	return keys.camera(first, delta)


## REARMA TODAS LAS MECAS, Y NADA MÁS: cada una se cambia por una nueva igual —sus brazos, si es cinemática, su lugar en
## el piso, hacia dónde mira, parada sobre el piso de su parcela— con la forma y las perillas de ahora. Lo usan los dos
## paneles de la meca al probar y al guardar (el F2, la forma; el F1, las perillas). *Al principio se rearmaba la parcela
## entera, como la R, y lo demás volvía a como nace: en la arena de esquivar, la torre volvía a tirar aunque el panel
## chico dijera que no (lo vio el usuario).* Si se la estaba poseyendo, se la suelta antes; el que iba adentro queda
## donde estaba. *Vivía en el panel del F2 (CabinShapePanel); pasó acá el 13/11/2026, cuando el F1 también lo necesitó.*
static func rebuild_all(tree: SceneTree) -> void:
	for found in tree.root.find_children("*", "Mech", true, false):
		var old := found as Mech
		if old == null or old.is_queued_for_deletion():
			continue
		if old.keys != null and old.keys.driving:
			SandboxPossession.of(tree).release()
		var holder := old.get_parent()
		var fresh := Mech.new()
		fresh.arms_kind = old.arms_kind
		fresh.kinematic = old.kinematic
		# Parada sobre el piso de su parcela (la altura 0 de lo que la tiene, como la arman sus arquetipos).
		fresh.transform = Transform3D(Basis(Vector3.UP, old.yaw()), Vector3(old.position.x, Mech.standing_height(),
			old.position.z))
		old.cabin.free_dummies()
		holder.remove_child(old)
		old.queue_free()
		holder.add_child(fresh)


## A QUÉ ALTURA NACE PARADA (el centro de la caja sobre el piso, m): sus piernas más media caja. Un solo lugar para
## todas las parcelas que la arman. *Estaba copiado en cuatro.*
static func standing_height() -> float:
	return MechBody.WAIST + CabinGrid.HALF_HEIGHT
