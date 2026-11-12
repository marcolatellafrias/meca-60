class_name LeggedCubeSettings
extends HoverCubeSettings

## LAS PERILLAS DEL CUBO CON PIERNAS (ver LeggedCube): las del cubo (flotar, moverse, la línea, tropezar, caído,
## recuperarse) en su propia copia, más las de las piernas. Una sola copia para todos (`shared`), que arma su panel
## (LeggedCubePanel, F1 en la fila Cubo con piernas).

static var shared := LeggedCubeSettings.new()

@export_group("Las piernas (pasos por radio)")
## Un pie da un paso cuando su lugar de descanso (debajo de la cadera, adelantado con la marcha) se aleja de él más que
## esto (m).
@export_range(0.3, 8.0, 0.1) var step_radius := 2.5
## Cuánto se adelanta ese lugar con la marcha (segundos de la velocidad de ahora): con más, los pasos caen más adelante
## y son más largos.
@export_range(0.0, 1.5, 0.05) var step_lead := 0.35
## Cuánto dura un paso (s) y cuánto sube el pie en el medio (m).
@export_range(0.1, 1.5, 0.05) var step_time := 0.4
@export_range(0.0, 4.0, 0.1) var step_height := 1.4

@export_group("Las piernas al caer")
## Cuánto tardan en recogerse al tropezar y en estirarse al enderezarse (s).
@export_range(0.05, 1.5, 0.05) var fold_time := 0.3
@export_range(0.05, 1.5, 0.05) var unfold_time := 0.25
