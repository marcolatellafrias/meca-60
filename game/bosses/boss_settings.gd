class_name BossSettings
extends Resource

## LO COMÚN A TODOS LOS JEFES (17/11/2026): una sola copia (`current`). Hoy, LA ESCALA: el usuario, «poder cambiar
## básicamente la escala total de todos los bosses con un solo slider… se mantienen las proporciones entre brazos y
## torso… las hitbox de los poderes que dependen del tamaño… se escalarían automáticamente… las que son en área… las
## debería poder cambiar yo independientemente». Cada jefe está dibujado en sus medidas de maqueta y va a esta escala:
## su dibujo, su cuerpo y lo que sale de él (la embestida, los puños, los brazos del trompo); las zonas (una onda, el
## cono del lanzallamas, el círculo de la piedra) tienen su propio tamaño en las perillas de cada poder. Se cambia en
## vivo. Va en la pestaña «Todos los jefes» del panel de cada jefe.

const SAVED := "res://game/bosses/boss_settings.tres"
const BASE_RANGE := 13.0
static var current := KnobsFile.load_into(BossSettings.new(), SAVED) as BossSettings

@export_group("Todos los jefes")
## La escala de todos los jefes (1: las medidas de la maqueta; el Luchador, 30 m de alto). EN 0,3 (22/11/2026; el usuario:
## la diferencia con la meca era demasiada, y embestía desde fuera de la vista): el Luchador, unos 9,5 m; la meca, 6.
@export_range(0.1, 2.0, 0.05) var scale := 0.3
## LAS MARCAS EN EL PISO (BossZone): si se ven los avisos de las zonas (la franja, el círculo, el cono). Apagadas, todo
## se lee por las poses y los sonidos del jefe, como en Souls (el usuario: «esto sería algo más que podría o no poner»).
@export var floor_marks := true
## EL ALCANCE DE LOS ATAQUES (m; 22/11/2026, la regla del usuario: «nunca están pasando cosas fuera de mi zona de visión»):
## a cuánto ataca y hasta dónde llega lo que tira. Los valores de cada poder están pensados para `BASE_RANGE`: moviendo
## este número se estiran todas sus distancias y velocidades juntas (BossPower.fit_reach), y los tiempos quedan iguales.
@export_range(6.0, 60.0, 0.5) var attack_range := 13.0


## Cuánto se estiran las distancias de los poderes (1, las de sus perillas).
func reach_share() -> float:
	return attack_range / BASE_RANGE
