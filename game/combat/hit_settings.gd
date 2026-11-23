class_name HitSettings
extends Resource

## LAS FICHAS DE LOS GOLPES (22/11/2026; el usuario: «tener más control sobre si yo le hago daño al boss enemigo y le hago
## knockback»): cada ataque dice por código tres cosas, en lugar de un impulso físico:
##   · DAÑO: lo que baja la vida.
##   · QUIEBRE: lo que desgasta el aguante del blanco.
##   · EMPUJE: los metros que lo corre, SÓLO SI ESE GOLPE LE ROMPE EL AGUANTE, y menos cuanto más pesa.
## Los valores son a fondo, o por pulso en la ametralladora: lo cargado los multiplica (HitCard). Se cambian con el F4 de la
## partida (BaseHitPanel); el archivo es del usuario.

const SAVED := "res://game/combat/hit_settings.tres"

static var current := KnobsFile.load_into(HitSettings.new(), SAVED) as HitSettings

@export_group("Zonas")
## EL ALCANCE DE LAS HABILIDADES (m): el largo de la más larga. Los de abajo son partes de éste (ver MechSkills): si cambia
## la cámara, se mueve sólo este número.
@export_range(4.0, 40.0, 0.5) var skill_range := 14.0
## El puño: cono (medio ángulo, °) y largo.
@export_range(5.0, 90.0, 1.0) var fist_half := 45.0
@export_range(0.1, 1.0, 0.01) var fist_reach := 0.46
## El palo: línea (ancho y largo).
@export_range(0.05, 1.0, 0.01) var pole_width := 0.18
@export_range(0.1, 1.0, 0.01) var pole_reach := 0.43
## El taladro y la sierra: cono corto.
@export_range(5.0, 90.0, 1.0) var spin_half := 35.0
@export_range(0.1, 1.0, 0.01) var spin_reach := 0.25
## El cañón: línea; de un toque y cargado a fondo.
@export_range(0.05, 1.0, 0.01) var cannon_width := 0.11
@export_range(0.1, 1.0, 0.01) var cannon_short := 0.64
@export_range(0.1, 1.0, 0.01) var cannon_long := 1.0
## La ametralladora: línea (ancho y largo), como el cañón.
@export_range(0.02, 1.0, 0.01) var minigun_width := 0.07
@export_range(0.1, 1.0, 0.01) var minigun_reach := 1.0
## El misil: hasta dónde vuela, el radio de la explosión y cuánto se lo puede guiar al salir (s).
@export_range(0.1, 1.0, 0.01) var missile_reach := 1.0
@export_range(0.05, 1.0, 0.01) var missile_radius := 0.21
@export_range(0.0, 2.0, 0.05) var missile_guide := 0.45
## El escudo: lo que frena a cada lado de donde apunta (°) y hasta dónde se dibuja.
@export_range(10.0, 180.0, 5.0) var shield_half := 60.0
@export_range(0.1, 1.0, 0.01) var shield_reach := 0.35

@export_group("Puño")
@export_range(0.0, 200.0, 0.5) var fist_damage := 10.0
@export_range(0.0, 200.0, 0.5) var fist_stagger := 15.0
@export_range(0.0, 15.0, 0.1) var fist_push := 0.6

@export_group("Cañón")
@export_range(0.0, 300.0, 0.5) var cannon_damage := 40.0
@export_range(0.0, 300.0, 0.5) var cannon_stagger := 60.0
@export_range(0.0, 15.0, 0.1) var cannon_push := 2.5

@export_group("Ametralladora")
@export_range(0.0, 20.0, 0.1) var minigun_damage := 1.2
@export_range(0.0, 20.0, 0.1) var minigun_stagger := 1.0
@export_range(0.0, 2.0, 0.05) var minigun_push := 0.0

@export_group("Misil")
@export_range(0.0, 200.0, 0.5) var missile_damage := 18.0
@export_range(0.0, 200.0, 0.5) var missile_stagger := 25.0
@export_range(0.0, 15.0, 0.1) var missile_push := 1.0

@export_group("Taladro y sierra")
@export_range(0.0, 200.0, 0.5) var spin_damage := 14.0
@export_range(0.0, 200.0, 0.5) var spin_stagger := 20.0
@export_range(0.0, 15.0, 0.1) var spin_push := 0.5

@export_group("Puntería")
## Cuánto corre la mira con el mouse (1: acompaña al mouse en la pantalla).
@export_range(0.1, 4.0, 0.05) var aim_sensitivity := 1.0
## Lo que giran la ametralladora y los misiles (°/s): dan la vuelta entera.
@export_range(10.0, 720.0, 5.0) var gun_turn := 120.0
## La velocidad tope del misil (m/s) y lo que dobla (°/s).
@export_range(10.0, 120.0, 1.0) var missile_speed := 14.0
@export_range(10.0, 540.0, 5.0) var missile_turn := 360.0

@export_group("La bolsa")
## Su aguante, cuánto espera sin recibir golpes para recuperarlo (s) y a qué ritmo (por segundo).
@export_range(10.0, 1000.0, 5.0) var bag_poise := 100.0
@export_range(0.0, 10.0, 0.1) var poise_wait := 1.5
@export_range(1.0, 300.0, 1.0) var poise_refill := 40.0
## Lo que pesa para el empuje (1, normal; 2, la mitad de metros).
@export_range(0.25, 10.0, 0.05) var bag_weight := 1.0
