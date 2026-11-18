class_name StrikeSettings
extends Resource

## LOS GOLPES DE TODOS LOS BRAZOS (ver MechArm, «El golpe»): una sola copia para todos (`current`), la pestaña «Golpes»
## del panel de brazos (ArmsPanel, F3). Lo pidió el usuario el 18/11/2026: «o atraviesa o es físico y golpea la parte de
## con física… el puño o el palo»; «cuando estás en reposo colisiona o no… un toggle independiente»; «tal vez quiera
## hacer de que colisionen… el puño y el palo, pero no el arma. O tal vez quiero que colisione todo»; «una cantidad de
## perillas o toggles que no sea excesiva». *Hasta ese día el peso y el radio eran del brazo discreto (PoseArmSettings),
## y había dos interruptores sueltos: atravesar (del de músculos) y frenarse donde pega (del discreto).*
##
## QUÉ CHOCA: nunca el brazo ni el antebrazo; sólo LO QUE GOLPEA, en la punta del antebrazo —el puño, el palo (ver
## ArmTip.solid_shapes)—. En un brazo con músculos choca de verdad (con el mundo y con los jefes: lo frena, y empuja con
## su fuerza); en uno discreto, que no tiene cuerpo, se frena donde pega (ver MechArm.stuck). Lo que saca vida es lo
## mismo choque o no: lo que barre la punta.
##
## Se guarda (ver KnobsFile): el F3 tiene «Guardar» y «Volver a lo guardado». El archivo es del usuario.

const SAVED := "res://game/mech/arm_tips/strike_settings.tres"

static var current := KnobsFile.load_into(StrikeSettings.new(), SAVED) as StrikeSettings

@export_group("Al pegar")
## Lo que pesa lo que golpea (kg): el empujón es esto por su velocidad. Con la caja de 50 t, un directo (unos 35 m/s)
## le cambia la velocidad unos 5 m/s: la inclina sin tirarla.
@export_range(500.0, 40000.0, 500.0) var hit_mass := 7000.0
## El radio de lo que barre su camino para pegar (m, en una meca de grosor medio).
@export_range(0.3, 4.0, 0.1) var fist_radius := 1.2

@export_group("Qué choca")
## LO QUE GOLPEA CHOCA (el puño, el palo); apagado, atraviesa todo y sólo deja el destello donde pegó.
@export var strikes_collide := true
## Y CHOCA TAMBIÉN SIN ATACAR (quieto o caminando cerca de algo); apagado, sólo mientras tira un golpe.
@export var collide_at_rest := true
## EL CAÑÓN TAMBIÉN (si va en un brazo con músculos): apagado, el brazo del cañón atraviesa siempre.
@export var weapon_collides := false
