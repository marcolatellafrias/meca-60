class_name PillarSettings
extends Resource

## LAS PERILLAS DEL CUBO CINEMÁTICO (ver KinematicPillar): una sola copia (`current`), la que muestra su panel F1, una
## pestaña por grupo. TODO EN METROS Y SEGUNDOS: cada movimiento se define por lo que hace, no por fuerzas (13/11/2026;
## el usuario: «movimiento más discreto y menos físico»).

static var current := PillarSettings.new()

@export_group("Moverse")
## UNA velocidad, y el TIEMPO PARA LLEGAR a ella, el mismo para arrancar y para frenar (0: al instante). Sin correr: para
## esquivar está el dash. En el aire no se mueve de costado: el salto es sólo vertical («luego lo complejizamos si
## queremos»). Las configuraciones de un toque, en el F1 (PillarPanel).
@export_range(1.0, 30.0, 0.5) var walk_speed := 8.0
@export_range(0.0, 2.0, 0.05) var reach_time := 0.0

@export_group("Girar")
## Velocidad tope (grados por segundo) y aceleración tope (grados por segundo al cuadrado).
@export_range(10.0, 360.0, 5.0) var turn_speed := 90.0
@export_range(10.0, 1000.0, 10.0) var turn_accel := 140.0

@export_group("Saltar y volar")
## EL SALTO: sube `jump_height` (m) en `jump_time` (s), y baja igual. La gravedad sale de esos dos números.
@export_range(1.0, 30.0, 0.5) var jump_height := 8.0
@export_range(0.1, 2.0, 0.05) var jump_time := 0.6
## EL VUELO (espacio otra vez, en el aire): sube a `fly_speed` (m/s) mientras se mantiene y queda barra; la barra dura
## `fly_time` volando y se llena en `fly_refill`, sólo apoyado.
@export_range(1.0, 30.0, 0.5) var fly_speed := 8.0
@export_range(0.2, 10.0, 0.1) var fly_time := 2.0
@export_range(0.2, 10.0, 0.1) var fly_refill := 3.0

@export_group("Dash")
## EL DASH (Shift, con una dirección): recorre `dash_distance` (m) en `dash_time` (s), en línea recta; mientras dura no
## lo afectan ni las teclas ni la gravedad. Gasta `dash_cost` de su barra, que se llena sola en `dash_refill` (s).
@export_range(1.0, 40.0, 0.5) var dash_distance := 12.0
@export_range(0.05, 1.5, 0.05) var dash_time := 0.35
@export_range(0.05, 1.0, 0.05) var dash_cost := 0.35
@export_range(0.2, 20.0, 0.1) var dash_refill := 3.0

@export_group("Agacharse")
## Agachado, el largo de pierna que le queda (parte) y a qué ritmo cambia (partes por segundo).
@export_range(0.3, 1.0, 0.05) var crouch_share := 0.6
@export_range(0.1, 3.0, 0.05) var crouch_rate := 0.5

@export_group("Pies")
## LAS PIERNAS: su alto (m: a cuánto del piso va la cara de abajo de la caja) y cuánto se separan los pies del medio.
@export_range(2.0, 12.0, 0.5) var leg_height := 6.0
@export_range(0.5, 4.0, 0.1) var stance := 1.8
## LOS PASOS: un pie sale cuando quedó a más de medio `step_length` de su lugar, tarda `step_time` y sube `step_height`.
## Con pasos más cortos en el tiempo, el pie va más rápido y patea más fuerte.
@export_range(1.0, 10.0, 0.25) var step_length := 4.0
@export_range(0.1, 1.5, 0.05) var step_time := 0.3
@export_range(0.0, 4.0, 0.1) var step_height := 1.5
