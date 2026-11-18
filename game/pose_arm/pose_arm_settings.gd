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

## *Lo que pesa el puño al pegar y su radio eran de acá hasta el 18/11/2026: hoy son de todos los brazos
## (StrikeSettings).*
