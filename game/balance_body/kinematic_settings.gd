class_name KinematicSettings
extends Resource

## LAS PERILLAS DE MOVERSE DE LA MECA CINEMÁTICA (ver KinematicMover), una pestaña por grupo en su panel. Cada meca puede
## llevar las suyas (BalanceBody.kinematic_knobs): la jaula lleva las propias (CageMech.MOVES, su F1: CageMovesPanel);
## `current` es la copia de las que no llevan (y de donde la jaula arranca si no guardó nada). TODO EN METROS Y
## SEGUNDOS: cada movimiento se define por lo que hace, no por fuerzas («movimiento más discreto y menos físico»). Las
## piernas (sus pasos) son las de la meca, con sus perillas (BodySettings) y su largo (el F2).
## Se guarda (ver KnobsFile, KnobsPanel). El archivo es del usuario.
## *Eran las del cubo del Laboratorio (PillarSettings) hasta el 13/11/2026, cuando el cubo se reemplazó por la meca.
## Hasta el 17/11/2026 `current` era la de la Meca cinemática y la simplificada del Laboratorio, con su panel
## (KinematicPanel); se borraron con la meca grande.*

const SAVED := "res://game/balance_body/kinematic_settings.tres"

static var current := KnobsFile.load_into(KinematicSettings.new(), SAVED) as KinematicSettings

@export_group("Moverse")
## UNA velocidad, y CON PESO (el usuario, 15/11/2026: «más de esquivar y momentum»): tarda `start_time` (s) en llegar a
## ella y `stop_time` (s) en frenar de ella; cambiar de dirección cuesta como frenar (0: al instante). Sin correr: para
## esquivar está el dash. En el aire no se maneja, pero sigue con el impulso que traía (de caminar o de un dash: el
## usuario, 15/11/2026: «el dash es algo que sucede y listo… seguiría con el impulso»). *Hasta el 15/11/2026, un solo
## tiempo para las dos cosas, y en el aire se frenaba en seco. Las configuraciones de un toque (instantánea, con peso…)
## eran del F1 de la Meca cinemática, borrada el 17/11/2026.*
@export_range(1.0, 30.0, 0.5) var walk_speed := 8.0
@export_range(0.0, 2.0, 0.05) var start_time := 0.3
@export_range(0.0, 3.0, 0.05) var stop_time := 0.6

@export_group("Girar")
## Velocidad tope (grados por segundo) y aceleración tope (grados por segundo al cuadrado).
@export_range(10.0, 360.0, 5.0) var turn_speed := 90.0
@export_range(10.0, 1000.0, 10.0) var turn_accel := 140.0
## EL RESORTE DEL GIRO (17/11/2026, el usuario: «si lo giro muy rápido… termina haciendo un poquito de ida y vuelta como
## resorte… que no sea libre con el mouse… la gracia de los límites que tiene la meca»): con `turn_spring` (Hz) en más de
## 0, el torso persigue lo pedido como un resorte con freno —con la velocidad y la aceleración tope de arriba—, y con
## `turn_bounce` debajo de 1 se pasa y vuelve (más bajo, más rebote): el rebote mueve la puntería. En 0, el giro de
## siempre (sin resorte). ARRANCA CON RESORTE Y UN POCO DE REBOTE: los valores del código son los de la meca (las únicas
## que se mueven con esto); van acá y no en cada meca porque el archivo guardado no escribe lo que es igual al código, y
## al cargarlo eso vuelve al código.
@export_range(0.0, 6.0, 0.05) var turn_spring := 1.2
@export_range(0.1, 1.0, 0.01) var turn_bounce := 0.55
## LA INCLINACIÓN DEL TORSO al mirar arriba o abajo, con el mismo resorte: el tope (°; 0, no se inclina). Sutil: el
## usuario, «con un límite bastante fuerte, porque si no el de arriba se inclinaría muchísimo y se desorientaría».
@export_range(0.0, 30.0, 0.5) var pitch_limit := 8.0

@export_group("Saltar y volar")
## EL SALTO: sube `jump_height` (m) en `jump_time` (s), y baja igual. La gravedad sale de esos dos números.
@export_range(1.0, 30.0, 0.5) var jump_height := 8.0
@export_range(0.1, 2.0, 0.05) var jump_time := 0.6
## EL VUELO (espacio otra vez, en el aire): sube a `fly_speed` (m/s) mientras se mantiene y queda barra; la barra dura
## `fly_time` volando y se llena en `fly_refill`, sólo apoyado.
@export_range(1.0, 30.0, 0.5) var fly_speed := 8.0
@export_range(0.2, 10.0, 0.1) var fly_time := 2.0
@export_range(0.2, 10.0, 0.1) var fly_refill := 3.0
## BAJAR RÁPIDO (18/11/2026, el usuario: «usar el botón de agachar cuando estás en el aire para bajar más rápido… como
## un dash, pero hacia abajo… nos ahorramos un botón»): agachada en el aire, baja por lo menos a `dive_speed` (m/s) y le
## gana al vuelo; si ya cae más rápido, sigue cayendo. En 0, agacharse en el aire no hace nada más.
@export_range(0.0, 60.0, 0.5) var dive_speed := 20.0

@export_group("Dash")
## EL DASH (Shift, con una dirección), UN EMPUJÓN CON INERCIA (el usuario, 15/11/2026: «más de esquivar y momentum»):
## sale disparada y se va frenando sola en `dash_time` (s) hasta la velocidad de caminar, recorriendo unos
## `dash_distance` (m), y de ahí sigue caminando con su peso (sin freno en seco). Mientras dura no la afecta la gravedad,
## y la dirección SE TUERCE hacia donde se pide, a lo más `dash_steer` grados por segundo. Gasta `dash_cost` de su barra, que se llena sola en `dash_refill` (s).
## 18 m (15/11/2026, desde el módulo Jefes, con el sí del usuario): con 12 un dash solo nunca esquivaba la embestida del
## Luchador, que mide 24 m de ancho (ver docs/technical/luchador.md).
@export_range(1.0, 40.0, 0.5) var dash_distance := 18.0
@export_range(0.05, 1.5, 0.05) var dash_time := 0.35
@export_range(0.0, 720.0, 5.0) var dash_steer := 90.0
@export_range(0.05, 1.0, 0.05) var dash_cost := 0.35
@export_range(0.2, 20.0, 0.1) var dash_refill := 3.0
## LA ESPERA ENTRE DASHES (s), desde que termina uno: mientras corre, no sale otro aunque haya barra (el usuario,
## 15/11/2026, por el módulo Jefes: «me parece mala práctica hacer varios dashes seguidos… preferiría que haya un delay
## mínimo entre dashes, y diseñar todo para un dash, así es más consciente la esquivada»).
@export_range(0.0, 5.0, 0.05) var dash_cooldown := 1.0

@export_group("Caerse")
## DERRIBADA (KinematicMover.knock_down; 15/11/2026, desde el módulo Jefes, con el sí del usuario: «los brazos están
## mega bugueados cuando se cae… arreglalo de raíz»): SIEMPRE DE ESPALDAS, la pose de reposo de una pieza; cae en
## `fall_time` (s) hasta `fall_lie` (°), queda tirada `down_time` (s) y se levanta en `rise_time` (s). Animado, no físico.
@export_range(0.1, 2.0, 0.05) var fall_time := 0.5
@export_range(30.0, 90.0, 1.0) var fall_lie := 90.0
@export_range(0.0, 5.0, 0.1) var down_time := 1.1
@export_range(0.1, 3.0, 0.05) var rise_time := 0.8

@export_group("Aterrizar")
## AL ATERRIZAR SE HUNDE (sólo dibujo: la caja baja y las piernas se doblan; el resorte vertical de HitSpring la devuelve;
## módulo Jefes, 18/11/2026): `land_sink` m cayendo a `land_full_speed` m/s o más (un salto cae a 2·alto/tiempo); menos
## rápido, menos. 0, no se hunde.
@export_range(0.0, 3.0, 0.05) var land_sink := 0.9
@export_range(2.0, 80.0, 1.0) var land_full_speed := 20.0
## CON PESO (el usuario: «se debería sentir más el peso»): baja de golpe y vuelve despacio, sin rebotar; en `land_recover`
## s está de vuelta.
@export_range(0.1, 3.0, 0.05) var land_recover := 0.8
## EL POLVO (ParticleSystems.landing_dust, un anillo a ras del piso): cayendo a `dust_speed` m/s o más (un salto cae a
## 2·alto/tiempo; en picada, a `dive_speed`). 0, nunca.
@export_range(0.0, 80.0, 1.0) var dust_speed := 16.0

@export_group("Agacharse")
## Agachada, la altura de la caja que le queda (parte de la de parada) y a qué ritmo cambia (partes por segundo).
@export_range(0.3, 1.0, 0.05) var crouch_share := 0.6
## *Era 0,5 (2 s para agacharse entera) hasta el 16/11/2026; el usuario: «agacharse dura… extremadamente larga».*
@export_range(0.1, 5.0, 0.05) var crouch_rate := 2.0
