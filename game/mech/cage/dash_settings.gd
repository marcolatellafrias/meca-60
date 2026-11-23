class_name DashSettings
extends Resource

## CÓMO ES EL DASH DE LA MECA (22/11/2026; el usuario: «depende de cómo sea nuestro dash, es cómo va a ser el juego…
## me gustaría poder configurarlo en un panel adentro del juego. Así pruebo distintos estilos»). Lo hace MechDash; se
## cambia con el F3 de la partida (BaseDashPanel). El archivo es del usuario.
##   · LA RÁFAGA: una apretada, casi instantánea, sin teletransportar: recorre `burst_distance` en `burst_time`.
##   · EL PROPULSOR: mientras se mantiene va a `thrust_speed` y gasta energía; al soltar, se acaba.
##   · CON INERCIA, las dos: al terminar, frena hasta caminar en `inertia_time`. Sin inercia, corta en seco.

const SAVED := "res://game/mech/cage/dash_settings.tres"

## LAS DOS (22/11/2026, la tercera prueba de Experiments): Shift la ráfaga y Ctrl el propulsor, cada una con sus perillas.
enum Style { BURST, THRUST, BOTH }

static var current := KnobsFile.load_into(DashSettings.new(), SAVED) as DashSettings

@export_group("Estilo")
@export_enum("ráfaga (una apretada)", "propulsor (mantener)", "las dos (Shift y Ctrl)") var style := 2
@export var inertia := false
@export_range(0.05, 2.0, 0.05) var inertia_time := 0.4

@export_group("Ráfaga")
@export_range(1.0, 25.0, 0.5) var burst_distance := 7.0
@export_range(0.04, 0.6, 0.01) var burst_time := 0.1
@export_range(0.0, 100.0, 1.0) var burst_cost := 20.0
@export_range(0.0, 3.0, 0.05) var burst_cooldown := 0.5
## INTOCABLE (22/11/2026; para el experimento de esquivar por tiempo, Experiments): desde que arranca la ráfaga, cuántos
## segundos ningún golpe la toca (0: nunca). El golpe que la encuentra intocable queda usado, como uno frenado por el
## escudo (HitReaction.blocks), así que no vuelve a pegar al terminar.
@export_range(0.0, 1.0, 0.05) var burst_untouchable := 0.0

@export_group("Propulsor")
@export_range(5.0, 40.0, 0.5) var thrust_speed := 14.0
## Lo que gasta por segundo y lo que pide para arrancar (en energía, como `energy_capacity`).
@export_range(5.0, 200.0, 1.0) var thrust_drain := 45.0
@export_range(0.0, 50.0, 1.0) var thrust_start := 5.0

## EL ESCUDO (la V), DOS COSTOS COMO MANÁ (22/11/2026; el usuario: «incentiva… que calcules y predigas mejor los ataques»): lo
## que gasta al activarse y por segundo mientras se mantiene. Con `shield_parry`, activarlo justo a tiempo devuelve el costo.
@export_group("Escudo")
@export_range(0.0, 100.0, 1.0) var shield_cast := 12.0
@export_range(0.0, 200.0, 1.0) var shield_hold := 20.0
@export var shield_parry := false

## LOS GOLPES POR SEGMENTOS (22/11/2026; el usuario: «que tenga golpe liviano y golpe pesado, si no llega al treshold de
## liviano, se gasta la energía y no se hace el golpe»). EL PUÑO: paga `fist_cost` al apretar; desde `fist_light_share` de su
## carga sale liviano, y al llenarla paga `fist_heavy_cost` y sale pesado. EL CAÑÓN: tres segmentos de `cannon_segment_time`
## s; cada uno se paga al empezarlo, y soltar antes del primero no dispara.
@export_group("Golpes")
@export_range(0.05, 0.95, 0.05) var fist_light_share := 0.35
@export_range(0.0, 100.0, 1.0) var fist_cost := 8.0
@export_range(0.0, 100.0, 1.0) var fist_heavy_cost := 10.0
@export_range(0.1, 3.0, 0.05) var cannon_segment_time := 0.8
@export_range(0.0, 100.0, 1.0) var cannon_segment_cost := 12.0

## EL MINI STUN (22/11/2026; el usuario: «me gusta el trade-off… de jugársela por un super ataque»; «el stun no debería ser
## cuando llega a cero, sino cuando llega a negativo»): el cañón siempre carga al máximo, y si la batería queda en negativo,
## al disparar la meca queda quieta `stun_time` s, sin caminar, girar, dashear ni usar los brazos; con `stun_blocks_guns`,
## tampoco la ametralladora ni los misiles. Ver MechEnergy.
@export_group("Energía")
## LA BATERÍA: cuánta energía entra y cuánta recupera por segundo. Los costos no cambian con ella (un súper a fondo, 36).
@export_range(50.0, 500.0, 5.0) var energy_capacity := 100.0
@export_range(1.0, 40.0, 0.5) var energy_refill := 14.0
@export var stun_on := true
@export_range(0.1, 5.0, 0.05) var stun_time := 1.2
@export var stun_blocks_guns := true

## EL RETROCESO DE LO QUE DISPARA (22/11/2026; el usuario: «si yo tiro un cañonazo muy fuerte, probablemente me tire para
## atrás un poco, y con la minigun también tal vez me haga avanzar menos»). No quita el control: un dash hacia adelante lo
## contrarresta. Metros hacia atrás del cañón cargado a fondo y de un toque, en cuánto se frena, y cuánto menos avanza
## caminando hacia el frente mientras la ametralladora dispara (parte).
@export_group("Retroceso")
@export var recoil_on := true
@export_range(0.0, 15.0, 0.1) var cannon_recoil := 3.0
@export_range(0.0, 5.0, 0.05) var tap_recoil := 0.5
@export_range(0.05, 1.5, 0.05) var recoil_time := 0.35
@export_range(0.0, 1.0, 0.05) var minigun_slow := 0.35


## Las perillas, para mandarlas por la red.
func values() -> Dictionary:
	var out := {}
	for property in get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out[property["name"]] = get(property["name"])
	return out


func load_values(from: Dictionary) -> void:
	for knob: String in from:
		set(knob, from[knob])
