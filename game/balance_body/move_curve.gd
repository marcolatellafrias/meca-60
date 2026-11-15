class_name MoveCurve
extends RefCounted

## LAS CURVAS DE LOS MOVIMIENTOS DISCRETOS (14/11/2026; base común: la usan la meca y los jefes). El usuario: «si yo hago
## un dash… y lo tengo activado con easing, que haga easing… que puedan tener solamente los movimientos discretos, que ya
## tienen duración y velocidad… y distancia».
##
## UNA CURVA ES LA FORMA EN EL TIEMPO de un movimiento que ya tiene sus números (cuánto, en cuánto): va de 0 a 1 en el
## tiempo y en lo que hace. Sirve para las dos clases de movimiento discreto:
##   · DE UN TRAMO (el dash, el salto, una carga): recorren `distance` en `duration`. `share` dice qué parte del recorrido
##     va hecha y `rate`, a qué velocidad va en ese momento (ver `velocity`).
##   · SOSTENIDOS (caminar, rodar): van hacia una velocidad mientras se pide, y la pierden al soltar. Ver MoveRamp, que usa
##     estas mismas curvas para subir y para bajar.
## LINEAL es lo de siempre (parejo). Las otras le dan peso: ARRANCA LENTO, FRENA AL FINAL, o LAS DOS.

enum Shape { LINEAR, EASE_IN, EASE_OUT, EASE_IN_OUT }

const NAMES := ["lineal", "arranca lento", "frena al final", "arranca lento y frena al final"]


## Qué parte va hecha (0 a 1) a la parte `u` del tiempo (0 a 1).
static func share(shape: Shape, u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	match shape:
		Shape.EASE_IN:
			return u * u
		Shape.EASE_OUT:
			return 1.0 - (1.0 - u) * (1.0 - u)
		Shape.EASE_IN_OUT:
			return u * u * (3.0 - 2.0 * u)
	return u


## A qué ritmo va (la derivada de `share`; en promedio, 1): por cuánto multiplicar la velocidad pareja.
static func rate(shape: Shape, u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	match shape:
		Shape.EASE_IN:
			return 2.0 * u
		Shape.EASE_OUT:
			return 2.0 * (1.0 - u)
		Shape.EASE_IN_OUT:
			return 6.0 * u * (1.0 - u)
	return 1.0


## UN TRAMO: la velocidad (m/s) a los `elapsed` segundos de un movimiento que recorre `distance` en `duration`.
static func velocity(shape: Shape, distance: float, duration: float, elapsed: float) -> float:
	var span := maxf(duration, 0.0001)
	return distance / span * rate(shape, elapsed / span)


## La parte del tiempo `u` a la que la curva lleva hecha la parte `done` (la inversa de `share`).
static func time_of(shape: Shape, done: float) -> float:
	done = clampf(done, 0.0, 1.0)
	match shape:
		Shape.LINEAR:
			return done
		Shape.EASE_IN:
			return sqrt(done)
		Shape.EASE_OUT:
			return 1.0 - sqrt(1.0 - done)
	# Las demás, buscando (sube siempre).
	var low := 0.0
	var high := 1.0
	for i in 20:
		var middle := (low + high) * 0.5
		if share(shape, middle) < done:
			low = middle
		else:
			high = middle
	return (low + high) * 0.5
