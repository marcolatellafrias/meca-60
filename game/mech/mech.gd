class_name Mech
extends BalanceBody

## LA MECA PROPIA: el cuerpo con equilibrio (ver BalanceBody: la caja, el péndulo, caerse y volver, las piernas, las
## toberas, caminar y saltar), con lo que es sólo suyo:
##   · SquareCabin  la cabina de un piso por dentro, el ascensor (PelvisLift) y el marco que lleva a
##                  los que van adentro.
##   · MechKeys     el teclado y el mouse de quien la posee: escribe LO QUE SE LE PIDE (ver `_think`).
##   · los brazos   MechArm: PoseArm (discretos) o MuscleArm (físicos), según `arms_kind`: los dos caminos. Sin brazos
##                  es la meca de práctica, para pegarle.
## *Hasta el 13/11/2026 el cuerpo y el equilibrio vivían acá; se separaron para compartirlos con los jefes (ver
## docs/technical/base-comun.md).*

## Los brazos que lleva: ninguno (la de práctica, para pegarle), discretos o físicos.
enum Arms { NONE, POSE, MUSCLE }
## LA CABINA QUE LLEVA, una pieza más (ver docs/technical/cuerpo-por-piezas.md): la cuadrada (SquareCabin, CabinGrid) o
## la redonda (RoundCabin, RoundGrid; el usuario, 15/11/2026: «un "fork" en otra parcela»). Lo que cambia con ella se
## pregunta en un solo lugar: `cabin_kit`.
## Y EL DISCO DE DOS PISOS CON VÓRTICE (VortexCabin; el usuario, 15/11/2026: «ponémelo con brazos reales… en una
## parcela al principio del sandbox»): sin sillas ni ascensor.
enum Cabin { SQUARE, ROUND, VORTEX }

const MASS := 50000.0
const NAMES := ["Meca de práctica", "Meca discreta", "Meca física"]
## LOS BRAZOS: el hombro, en el espacio de la caja (`x` del lado derecho): en el medio del costado (ver
## CabinGrid.shoulder), `SHOULDER_OUT` afuera del costado, más con brazos más anchos. *El 12/11/2026 se
## probó en el último tercio, hacia atrás: la postura era más natural, pero el brazo alcanzaba 2,6 m menos hacia
## adelante, y el usuario lo volvió («estaban bien los brazos a la mitad, no me gusta el sacrificio en rango»). Del 13 al
## 14/11/2026 se elegía en el panel F2 (el piso y el módulo); con la cabina de un piso, va en el medio.* Y cuánto pesan los físicos, en partes de lo que pesa el brazo solo (ver
## MuscleArm.weight).
## *Era una constante (1 m); desde el 15/11/2026 se cambia jugando (MechBody.shoulder_out, el F2: «Brazos y piernas»).*


static func shoulder(shape := Cabin.SQUARE) -> Vector3:
	var kit := cabin_kit(shape)
	var body: MechBody = kit["body"]
	return (kit["shoulder"] as Vector3) + Vector3(body.shoulder_out * body.thick, 0.0, 0.0)


## LO QUE CAMBIA CON LA CABINA, en un solo lugar: la caja (`box`), el hombro sin lo que lo corre afuera (`shoulder`), si
## se ven las toberas (`nozzles`; la redonda, sin: el usuario, 15/11/2026: «quitaremos las toberas de abajo… sólo de
## la cilíndrica») y EL CUERPO (`body`, sus medidas: MechBody; el de su F2 en la del vórtice: «opciones para cambiar
## brazos y piernas solo para esta versión»).
static func cabin_kit(shape: Cabin) -> Dictionary:
	if shape == Cabin.ROUND:
		return {"box": RoundGrid.box(), "shoulder": RoundGrid.shoulder(), "nozzles": false, "body": MechBody.current}
	if shape == Cabin.VORTEX:
		return {"box": VortexCabin.box(), "shoulder": VortexCabin.shoulder(), "nozzles": false,
			"body": MechBody.from_shape(VortexCabin.BODY)}
	return {"box": CabinGrid.box(), "shoulder": CabinGrid.shoulder(), "nozzles": true, "body": MechBody.current}


const ARM_WEIGHT := 0.4

## Qué brazos lleva. Se pone antes de agregarla al árbol.
var arms_kind := Arms.POSE
## La postura de los brazos que se le pide: cubriéndose, o normal.
var covering := false

var cabin: MechCabin = null
## La cabina que lleva (ver `Cabin`). Se pone antes de agregarla.
var cabin_shape := Cabin.SQUARE
var keys: MechKeys = null
var arms: Array[MechArm] = []
## CON CABINA (la de siempre) o SIN (LA SIMPLIFICADA: sin cabina, sin escaleras ni ascensor, sin maniquíes; con
## `arms_kind` NONE, sin brazos: la del Laboratorio cinemático). Se pone antes de agregarla.
var has_cabin := true
## La maneja algo que no son sus teclas (un test, un cerebro): no las lee.
var scripted := false


func _init() -> void:
	super()
	mass = MASS
	size = CabinGrid.box()
	hover = measures.WAIST


func _ready() -> void:
	name = NAMES[arms_kind] if has_cabin else "Meca simplificada"
	if knobs == null:
		knobs = Mech.knobs_for(arms_kind)
	var kit := cabin_kit(cabin_shape)
	size = kit["box"]
	show_nozzles = kit["nozzles"]
	measures = kit["body"]
	hover = measures.WAIST
	super()
	add_to_group(SandboxPossession.GROUP)


func _build() -> void:
	keys = MechKeys.new()
	keys.mech = self
	add_child(keys)
	if not has_cabin:
		# LA SIMPLIFICADA: la caja lisa, y una franja al frente para saber hacia dónde mira.
		Clay.box(look, size, Vector3.ZERO, Clay.METAL.darkened(0.1))
		Clay.box(look, Vector3(size.x * 0.6, 0.5, 0.2), Vector3(0.0, size.y * 0.3, -size.z * 0.5 - 0.1), Clay.YELLOW)
		_build_arms()
		return
	match cabin_shape:
		Cabin.ROUND:
			cabin = RoundCabin.new()
		Cabin.VORTEX:
			cabin = VortexCabin.new()
		_:
			cabin = SquareCabin.new()
	cabin.mech = self
	add_child(cabin)
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
		arm.measures = measures
		var at := shoulder(cabin_shape)
		arm.shoulder_local = Vector3(side * at.x, at.y, at.z)
		arm.stance = MechArm.Stance.NORMAL
		add_child(arm)
		arms.append(arm)


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
		fresh.has_cabin = old.has_cabin
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


## LAS PERILLAS DEL CUERPO de una meca con estos brazos: la física tiene las suyas (ver BodySettings.physical).
static func knobs_for(arms: Arms) -> BodySettings:
	return BodySettings.physical if arms == Arms.MUSCLE else BodySettings.current


## A QUÉ ALTURA NACE PARADA (el centro de la caja sobre el piso, m): sus piernas más media caja. Un solo lugar para
## todas las parcelas que la arman. *Estaba copiado en cuatro.*
static func standing_height(shape := Cabin.SQUARE) -> float:
	var kit := cabin_kit(shape)
	return (kit["body"] as MechBody).WAIST + (kit["box"] as Vector3).y * 0.5
