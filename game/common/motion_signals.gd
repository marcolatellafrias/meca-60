class_name MotionSignals
extends RefCounted

## LAS SEÑALES DE LA LOCOMOCIÓN DE UN CUERPO (18/11/2026): lo que lee la tabla de animación procedural
## (ProceduralBoneAnimator) para mover huesos o piezas. Es la parte común: cada cuerpo tiene su manera de calcularlas
## (los personajes, LocomotionSignals, con sus dos pies y su IK; la meca y los jefes, la suya con sus patas) y las
## escribe acá en cada paso. Todas normalizadas por el largo de pierna, así la escala del cuerpo no importa.
## El usuario: «los personajes tienen un sistema en el que abstrae varios ciclos… y después usa eso para mover ciertos
## huesos… tal vez sea buena idea abstraer este sistema y reutilizarlo para la meca». *Es sólo dibujo: no se sincroniza
## por la red; cada máquina la saca de lo que sí viaja (dónde está, la velocidad, si pisa).*

## El paso: su arco (0 → 1 → 0 mientras un pie está en el aire) y su largo (por largo de pierna).
var step_progress: float = 0.0
var step_length_norm: float = 0.0
## La velocidad de costado en el espacio del cuerpo (x a la derecha, y adelante negativo como z), suavizada (m/s).
var horizontal_velocity_smooth: Vector2 = Vector2.ZERO
## Cuánto se separan los pies (x de costado, y adelante y atrás), por largo de pierna, de 0 a 1.
var foot_spread_norm: Vector2 = Vector2.ZERO
## Dónde está cada pie respecto del cuerpo (por largo de pierna), si el cuerpo tiene izquierdo y derecho.
var left_foot_local_norm: Vector2 = Vector2.ZERO
var right_foot_local_norm: Vector2 = Vector2.ZERO
## Un pie adelante del otro y abiertos de costado, con signo (−1 a 1).
var foot_spread_unified: Vector2 = Vector2.ZERO
## Qué tan rápido va, de 0 a 1.
var speed_norm: float = 0.0


## La velocidad vertical (m/s). Cada cuerpo dice de dónde sale.
func vertical_velocity() -> float:
	return 0.0
