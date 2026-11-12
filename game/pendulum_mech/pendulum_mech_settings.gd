class_name PendulumMechSettings
extends PendulumCubeSettings

## LAS PERILLAS DE LA MECA PÉNDULO (ver PendulumMech): las del cubo péndulo en su propia copia, más correr, agacharse,
## saltar y el propulsor. Una sola copia para todos (`tuned`), que arma su panel (PendulumMechPanel, F1 en su fila).

static var tuned := PendulumMechSettings.new()

@export_group("Correr (Shift)")
## Corriendo va hasta esto por la velocidad de caminar. Lo de arriba de la caminata es una banda que se gana —y se
## pierde— a `sprint_accel` de la aceleración de siempre (como el sprint de los personajes de character-parametric).
@export_range(1.0, 4.0, 0.05) var sprint_multiplier := 1.8
@export_range(0.1, 1.0, 0.05) var sprint_accel := 0.5

@export_group("Agacharse (Ctrl)")
## Agachada, el palo del péndulo queda en esta parte de su largo, y camina a esta parte de su velocidad.
@export_range(0.4, 1.0, 0.01) var crouch_rod := 0.68
@export_range(0.1, 1.0, 0.05) var crouch_speed := 0.5
## Cuán rápido sube y baja (partes del largo por segundo).
@export_range(0.2, 6.0, 0.1) var rod_rate := 1.2

@export_group("Saltar (espacio)")
## Mantener carga, soltar salta: cuánto sube el salto entero (m), en cuánto se carga (s), cuánto baja al cargar (parte
## del largo del palo) y con qué parte del salto sale un toque sin cargar.
@export_range(1.0, 60.0, 0.5) var jump_height := 14.0
@export_range(0.1, 3.0, 0.05) var jump_charge_time := 0.9
@export_range(0.5, 1.0, 0.01) var jump_squat := 0.78
@export_range(0.05, 1.0, 0.05) var jump_least := 0.3
## En el aire, cuánto puede cambiar su velocidad de costado (m/s²).
@export_range(0.0, 20.0, 0.5) var air_accel := 2.5

@export_group("El propulsor (espacio en el aire)")
## Cuánto empuja para arriba (m/s²; la gravedad es 9,8), cuánto dura lleno (s) y en cuánto se recarga en el piso (s).
@export_range(5.0, 40.0, 0.5) var thrust := 12.5
@export_range(0.2, 20.0, 0.1) var thrust_time := 2.0
@export_range(0.2, 20.0, 0.1) var thrust_refill := 3.0
