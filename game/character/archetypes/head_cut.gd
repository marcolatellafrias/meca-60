class_name HeadCut
extends Resource

## UN LOOP CUT DE LA CABEZA (ver HeadForm): un anillo entre las dos tapas que, prendido, empuja la forma.
##
## Como en el creador de cuerpos (ver BodyLoop.active), los cortes son de plantilla —siempre los mismos siete, en los
## mismos lugares por defecto— y lo que se decide es CUÁLES MANDAN. Uno apagado sigue guardado con sus números, y la
## forma pasa por él interpolada entre los que sí mandan. Así una forma simple es las dos tapas y nada más, y uno
## prende un corte sólo donde la curva tiene que hacer algo.

## SI ESTE CORTE MANDA. Apagado, la forma pasa de largo (interpolada) y sus números quedan guardados.
@export var active := false
## DÓNDE CAE, en fracción del cilindro: 0 la tapa de abajo, 1 la de arriba.
@export_range(0.02, 0.98, 0.01) var at := 0.5
## SU DIÁMETRO, en metros: el anillo es un círculo (ver HeadForm, «las secciones son círculos»).
@export_range(0.03, 0.4, 0.001, "suffix:m") var width := 0.16
## CUÁNTO SE CORRE HACIA ADELANTE (positivo) o hacia atrás, en metros: el mentón que sale, la nuca que cae.
@export_range(-0.08, 0.08, 0.001, "suffix:m") var forward := 0.0


func copy() -> HeadCut:
	var out := HeadCut.new()
	out.active = active
	out.at = at
	out.width = width
	out.forward = forward
	return out
