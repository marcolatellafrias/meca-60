class_name CageMech
extends ToolMech

## LA MECA JAULA (ver CageCabin; el usuario, 16/11/2026: «empezar a migrar esta meca a algo funcional… que camine… que
## poder cambiar su velocidad… lo primero… que se pueda poseer la meca y que los brazos anden y las piernas anden»). La
## meca con herramientas (ToolMech, lo que quedó de la Meca de tres: la energía común, sus teclas, levitar) con:
##   · EL TORSO DISCRETO, LOS BRAZOS FÍSICOS (el usuario: «los brazos van a ser físicos y el torso va a ser discreto»):
##     cinemática, a la izquierda EL CAÑÓN en lugar del antebrazo (CannonTip, discreto) y a la derecha EL PALO en el
##     puño pesado (PoleTip), un brazo con músculos (ver `loadout`, ArmLoadout).
##   · LA CABINA JAULA, chica, con brazos y piernas al 30 % (CageCabin.body).
##   · SUS PROPIAS PERILLAS DE MOVERSE (`MOVES`, el F1 de su fila: CageMovesPanel; el usuario: «si un panel lo quiero
##     modificar para este mecha, me gustaría que sea solamente para esta, porque los otros se van a sentir muy
##     distintos»).
##   · LAS PLACAS DEL ACORAZADO (las de la armería, tres caras de octógono) en los brazos y las piernas. (La pelvis
##     cilíndrica de la maqueta la arman las piernas, BodyLegs, desde el 17/11/2026: es la de toda meca.)

const SAVED_MOVES := "res://game/mech/cage/cage_moves.tres"
## Lo que se achican, al nacer sin guardar, las distancias y velocidades de las de siempre: es más chica.
const START_SHRINK := 0.5
static var MOVES := CageMech.load_moves()


## LAS PERILLAS DE MOVERSE: las guardadas; si no hay, las de las otras mecas con las distancias achicadas.
static func load_moves() -> KinematicSettings:
	if ResourceLoader.exists(SAVED_MOVES):
		return KnobsFile.load_into(KinematicSettings.new(), SAVED_MOVES) as KinematicSettings
	var moves := KinematicSettings.new()
	KnobsFile.copy(moves, KinematicSettings.current)
	for knob: String in ["walk_speed", "jump_height", "fly_speed", "dash_distance"]:
		moves.set(knob, float(moves.get(knob)) * START_SHRINK)
	return moves


func _init() -> void:
	super()
	cabin_shape = Cabin.CAGE
	kinematic_knobs = MOVES


func _ready() -> void:
	super()
	name = "Meca jaula"
	# El cartel de lo que mide, a su escala: el de las grandes la tapaba entera.
	label.pixel_size = 0.006


## ── EL MÓDULO DE ARRIBA, APARTE DEL TORSO (la redonda con `CageShape.upper_turns`; ver CageCabin.upper) ─────────────
## Cada paso, el octógono de arriba mira a `upper_heading`, gire como gire el torso. Apagado, va con el torso.
func _after_step(k: BodySettings, delta: float) -> void:
	super(k, delta)
	var form := CageCabin.shape()
	if form.is_round() and form.upper_turns and cabin is CageCabin:
		(cabin as CageCabin).set_upper_world_yaw(upper_heading())


## ADÓNDE MIRA EL MÓDULO DE ARRIBA CUANDO GIRA APARTE (el giro en Y del mundo). EL ÚNICO LUGAR DE LA REGLA (el usuario,
## 17/11/2026: «el torso va a girar mediante controles y la de arriba va a quedar fija apuntando hacia adelante. O tal vez
## debería apuntar hacia donde apunten las piernas… lo decidiría mejor… cuando empiece a hacer experimentos de
## gameplay»): hoy, hacia donde apuntan las piernas (la pelvis, BodyLegs.facing_yaw).
func upper_heading() -> float:
	return legs.facing_yaw if legs != null else yaw()


func _build() -> void:
	super()
	# Sus teclas, en lugar de las de la meca con herramientas.
	keys.queue_free()
	remove_child(keys)
	keys = CageMechKeys.new()
	keys.mech = self
	add_child(keys)
	# SUBIRSE CON LA E: el primer puesto libre, por orden (ver CageBoarding).
	var boarding := CageBoarding.new()
	boarding.cabin = cabin as CageCabin
	add_child(boarding)


## AL POSEERLA SE TOMA EL PUESTO DEL QUE MANEJA: su maniquí se va, y vuelve al soltarla (ver CageCabin.evict).
func possess_begin() -> void:
	super()
	(cabin as CageCabin).evict(CageCabin.DRIVER)


func possess_end() -> void:
	super()
	(cabin as CageCabin).seat_back(CageCabin.DRIVER)


func default_loadout() -> Array[ArmLoadout]:
	return CageMech.default_arms()


## Lo suyo: el cañón a la izquierda (discreto) y el palo a la derecha (con músculos), los dos con placa.
static func default_arms() -> Array[ArmLoadout]:
	return [ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.CANNON, true),
		ArmLoadout.of(ArmLoadout.Motion.MUSCLE, ArmLoadout.Tip.POLE, true)]


## LAS PLACAS DE LAS PIERNAS (al frente del muslo y de la canilla).
## *Hasta el 17/11/2026 acá se cambiaba también la pelvis: el tambor de las grandes por el cilindro acostado de cadera a
## cadera; hoy lo arman así las piernas (BodyLegs) para toda meca.*
func _dress() -> void:
	var ahead := global_basis * Vector3.FORWARD
	for found in find_children("*", "MechLeg", true, false):
		var leg := found as MechLeg
		ArmoryParts.plate(leg._thigh, ahead, measures.thick, float(MechBody.BASE["THIGH"]) * 0.75)
		ArmoryParts.plate(leg._shin, ahead, measures.thick, float(MechBody.BASE["SHIN"]) * 0.8)
