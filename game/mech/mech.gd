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
## docs/base-comun.md).*

## Los brazos que lleva: ninguno (la de práctica, para pegarle), discretos o físicos.
enum Arms { NONE, POSE, MUSCLE }

const SIZE := CabinGrid.SIZE
const MASS := 50000.0
const NAMES := ["Meca de práctica", "Meca discreta", "Meca física"]
## LOS BRAZOS: el hombro, en el espacio de la caja (`x` del lado derecho), casi en el medio del costado. *El 12/11/2026
## se probó en el último tercio, hacia atrás: la postura era más natural, pero el brazo alcanzaba 2,6 m menos hacia
## adelante, y el usuario lo volvió («estaban bien los brazos a la mitad, no me gusta el sacrificio en rango»).* Y cuánto
## pesan los físicos, en partes de lo que pesa el brazo solo (ver MuscleArm.weight).
const SHOULDER := Vector3(SIZE * 0.5 + 1.0, 1.9, -0.4)
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
	size = Vector3.ONE * SIZE


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
		arm.shoulder_local = Vector3(side * SHOULDER.x, SHOULDER.y, SHOULDER.z)
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
