class_name Crosshair
extends CanvasLayer

## EL PUNTITO DEL CENTRO DE LA PANTALLA: un punto blanco chico, siempre puesto. No es una mira de arma ni
## tiene nada que ver con el modo identificar; está para saber exactamente adónde apunta la cámara —al
## agarrar algo, al apretar un control de la meca, al señalar una pieza—, que sin una referencia en el medio
## se estima mal. Va en el juego y en el design sandbox, el mismo nodo en los dos.
##
## Es una capa propia y no un Control suelto porque un CanvasItem colgado de un Node3D no tiene dónde
## dibujarse. Va por debajo del cartel del identificador (90) y del panel de debug (100).
##
## Se esconde solo mientras haya un overlay abierto (pausa, menús, afinadores): ahí el mouse es un cursor y
## un punto fijo en el medio no significa nada (ver UIState).

## Un punto que se VEA sin tapar lo que hay atrás, que es lo único que tiene que cuidar.
const RADIUS := 5.0
const COLOR := Color(1.0, 1.0, 1.0, 1.0)
## Un borde oscuro, para que no se pierda contra una pared clara.
const EDGE := 2.0
const EDGE_COLOR := Color(0.0, 0.0, 0.0, 0.7)

var _dot: Control = null
## Sin mira (la cámara isométrica, ver PlayerController.set_iso).
var off := false


func _ready() -> void:
	name = "Crosshair"
	layer = 80
	_dot = Control.new()
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dot)
	# ⚠ `set_anchors_preset` sola NO estira nada: cambia los anclajes y reescribe los offsets para CONSERVAR el
	# rectángulo que el control ya tenía, que recién creado es de tamaño cero. Así el puntito se dibujaba en un
	# control de 0 × 0 y no se veía nunca, midiera lo que midiera. La que estira es ésta.
	_dot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dot.draw.connect(_draw_dot)
	_dot.resized.connect(_dot.queue_redraw)


func _process(_delta: float) -> void:
	var on := UIState.gameplay_active() and not off
	if on != visible:
		visible = on


func _draw_dot() -> void:
	var centre := _dot.size * 0.5
	_dot.draw_circle(centre, RADIUS + EDGE, EDGE_COLOR)
	_dot.draw_circle(centre, RADIUS, COLOR)
