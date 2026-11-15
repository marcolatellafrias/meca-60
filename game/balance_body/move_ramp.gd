class_name MoveRamp
extends RefCounted

## UNA RAMPA DE UN MOVIMIENTO SOSTENIDO (14/11/2026; base común, con MoveCurve): cuánto de su velocidad tope lleva algo
## que va hacia ella mientras se lo pide (caminar, rodar) y la pierde al soltarlo. SUBE en `up_time` con la curva
## `up_shape` y BAJA en `down_time` con la curva `down_shape`: cada una, de punta a punta; empezando de la mitad, tarda lo
## que le falta. Una bajada larga es la INERCIA: soltando, sigue un rato. Tiempo 0: al instante.
##   · `level`: dónde está (0 a 1; o de −1 a 1 si se le pide para atrás).
## Es continua: cambiar de pedido a mitad de camino no salta, sigue desde donde está.

var level := 0.0


## UN PASO hacia `wanted` (−1 a 1). Devuelve `level`.
func step(delta: float, wanted: float, up_time: float, up_shape: MoveCurve.Shape, down_time: float,
		down_shape: MoveCurve.Shape) -> float:
	wanted = clampf(wanted, -1.0, 1.0)
	if is_equal_approx(level, wanted):
		level = wanted
		return level
	# Subir es alejarse del cero hacia lo pedido (del mismo lado); si no, es bajar hacia lo pedido o hacia el cero.
	var going_up := absf(wanted) > absf(level) and (signf(wanted) == signf(level) or is_zero_approx(level))
	var side := signf(wanted) if going_up else signf(level)
	var size := absf(level)
	if going_up:
		if up_time <= 0.0:
			level = wanted
			return level
		var u := MoveCurve.time_of(up_shape, size) + delta / up_time
		level = side * minf(MoveCurve.share(up_shape, u), absf(wanted))
	else:
		# La bajada va de 1 a 0: lo que lleva es 1 − su curva.
		var floor_size := absf(wanted) if signf(wanted) == signf(level) else 0.0
		if down_time <= 0.0:
			level = side * floor_size
		else:
			var u := MoveCurve.time_of(down_shape, 1.0 - size) + delta / down_time
			level = side * maxf(1.0 - MoveCurve.share(down_shape, u), floor_size)
	return level
