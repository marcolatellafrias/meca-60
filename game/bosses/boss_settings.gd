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
static var current := KnobsFile.load_into(BossSettings.new(), SAVED) as BossSettings

@export_group("Todos los jefes")
## La escala de todos los jefes (1: las medidas de la maqueta; el Luchador, 30 m de alto).
@export_range(0.1, 2.0, 0.05) var scale := 0.6
