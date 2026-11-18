class_name GaitSignals
extends MotionSignals

## LAS SEÑALES DE UN CUERPO CON PATAS (18/11/2026; módulo Jefes, el sistema común): las de la tabla (MotionSignals,
## ProceduralBoneAnimator) sacadas de su marcha (Gait) y de cómo se mueve. Las usan la jaula (BodyLegs) y los jefes con
## patas; los personajes tienen las suyas (LocomotionSignals). Sólo dibujo: salen de lo que viaja por la red.
##   · `step_progress`: el arco del paso (0 → 1 → 0 mientras algún pie está en el aire; el más alto).
##   · `horizontal_velocity_smooth`: la velocidad en los ejes del cuerpo (x a la derecha, y adelante negativo), suavizada.
##   · `speed_norm`: qué tan rápido va, de 0 a 1 (`full_speed`, la de caminar).

## La velocidad que cuenta como del todo (m/s) y qué tan rápido sigue la velocidad (1/s).
var full_speed := 6.0
var smoothing := 8.0


## Las lee de la marcha `gait`, el cuerpo mirando como `facing` y yendo a `velocity` (el mundo).
func read(gait: Gait, facing: Basis, velocity: Vector3, delta: float) -> void:
	var arc := 0.0
	for share: float in gait.swing_share:
		if share >= 0.0:
			arc = maxf(arc, sin(share * PI))
	step_progress = arc
	step_length_norm = gait.stride
	var local := facing.inverse() * Vector3(velocity.x, 0.0, velocity.z)
	var follow := 1.0 - exp(-smoothing * delta)
	horizontal_velocity_smooth = horizontal_velocity_smooth.lerp(Vector2(local.x, local.z), follow)
	speed_norm = clampf(horizontal_velocity_smooth.length() / maxf(full_speed, 0.01), 0.0, 1.0)
