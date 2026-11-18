class_name GaitSignals
extends MotionSignals

## LAS SEÑALES DE UN CUERPO CON PATAS (18/11/2026; módulo Jefes, el sistema común): las de la tabla (MotionSignals,
## ProceduralBoneAnimator) sacadas de su marcha (Gait) y de cómo se mueve. Las usan la jaula (BodyLegs) y los jefes con
## patas; los personajes tienen las suyas (LocomotionSignals). Sólo dibujo: salen de lo que viaja por la red.
##   · `step_progress`: el arco del paso (0 → 1 → 0 mientras algún pie está en el aire; el más alto).
##   · `horizontal_velocity_smooth`: la velocidad en los ejes del cuerpo (x a la derecha, y adelante negativo), suavizada.
##   · `speed_norm`: qué tan rápido va, de 0 a 1 (`full_speed`, la de caminar).
##   · `plant`: el golpe de pisar (1 cuando un pie pisa, y se apaga en `plant_time` s): para que el cuerpo se hunda.

## La velocidad que cuenta como del todo (m/s) y qué tan rápido sigue la velocidad (1/s).
var full_speed := 6.0
var smoothing := 8.0
var plant := 0.0
var plant_time := 0.12
var _down_was: Array[bool] = []


## Las lee de la marcha `gait`, el cuerpo mirando como `facing` y yendo a `velocity` (el mundo).
func read(gait: Gait, facing: Basis, velocity: Vector3, delta: float) -> void:
	var arc := 0.0
	plant *= exp(-delta / maxf(plant_time, 0.001))
	if _down_was.size() != gait.swing_share.size():
		_down_was.resize(gait.swing_share.size())
		_down_was.fill(true)
	for leg in gait.swing_share.size():
		var share: float = gait.swing_share[leg]
		if share >= 0.0:
			arc = maxf(arc, sin(share * PI))
		elif not _down_was[leg]:
			plant = 1.0
		_down_was[leg] = share < 0.0
	step_progress = arc
	step_length_norm = gait.stride
	var local := facing.inverse() * Vector3(velocity.x, 0.0, velocity.z)
	var follow := 1.0 - exp(-smoothing * delta)
	horizontal_velocity_smooth = horizontal_velocity_smooth.lerp(Vector2(local.x, local.z), follow)
	speed_norm = clampf(horizontal_velocity_smooth.length() / maxf(full_speed, 0.01), 0.0, 1.0)
