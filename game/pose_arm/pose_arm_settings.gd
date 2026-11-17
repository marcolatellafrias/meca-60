class_name PoseArmSettings
extends Resource

## LAS PERILLAS DEL BRAZO DISCRETO (ver PoseArm): una sola copia para todos (`current`), que arma su panel (ArmsPanel,
## F3 en la fila de la meca jaula). *Hasta el 13/11/2026 eran constantes del código.*

## Se guarda (ver KnobsFile): el F3 tiene «Guardar» y «Volver a lo guardado». El archivo es del usuario.
const SAVED := "res://game/pose_arm/pose_arm_settings.tres"

static var current := KnobsFile.load_into(PoseArmSettings.new(), SAVED) as PoseArmSettings

@export_group("Las piñas")
## Cuánto más rápidas van (×): armarse, pegar y volver.
@export_range(0.2, 3.0, 0.05) var punch_speed := 1.0

@export_group("Al conectar")
## Lo que pesa el puño al pegar (kg): el impulso es esto por su velocidad. Con la caja de 50 t, un directo (unos 35 m/s)
## le cambia la velocidad unos 5 m/s: la inclina sin tirarla.
@export_range(500.0, 40000.0, 500.0) var hit_mass := 7000.0
## El radio del puño que barre su camino (m, en una meca de grosor medio).
@export_range(0.3, 4.0, 0.1) var fist_radius := 1.2
