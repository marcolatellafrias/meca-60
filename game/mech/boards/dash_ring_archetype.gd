class_name DashRingArchetype
extends PanelArchetype

## LOS OCHO BOTONES DEL DASH, EN CÍRCULO (17/11/2026, el usuario: «8 botones el dash, 8 botones en forma de círculo… tal
## vez no tengas que respetar la grilla porque si no se complica»): UNA pieza de la grilla —un cuadrado de `CELLS`
## celdas, sobre su base (FaceMount)— y adentro, libres de la grilla, ocho botones redondos en círculo con una flecha al
## centro cada uno. El botón `k` es la dirección `k` × 45° desde el frente, en el sentido de las agujas visto desde
## arriba (0 adelante, 2 derecha, 4 atrás, 6 izquierda): «adelante» es el de arriba del tablero.

const CELLS := Vector2i(8, 8)
## El radio del círculo y el tamaño de cada botón, en partes del lado del cuadrado.
const RING := 0.36
const BUTTON := 0.2
const PLATE := Color(0.26, 0.27, 0.3)


func _init() -> void:
	display_name = "Dash"


func cells(_seed_value: int) -> Vector2i:
	return CELLS


## Los ocho botones de uno montado, en orden (ver arriba).
static func buttons_of(root: Node) -> Array[TouchComponent]:
	var out: Array[TouchComponent] = []
	for k in 8:
		var found := root.get_node_or_null("Botón %d/Button/Control" % k) as TouchComponent
		if found != null:
			out.append(found)
	return out


## La dirección del botón `k`, como BalanceBody.move (x a la derecha, y adelante).
static func way(k: int) -> Vector2:
	var angle := TAU * k / 8.0
	return Vector2(sin(angle), cos(angle))


func _build_on(seed_value: int, root: Node3D, area: Vector2) -> void:
	var side := minf(area.x, area.y)
	Clay.cylinder(root, side * 0.47, 0.01, Vector3(0.0, 0.0, 0.005), PLATE, Vector3(90.0, 0.0, 0.0))
	var look := ButtonArchetype.for_control("button", Color(0.9, 0.62, 0.2))
	look.button_cells = Vector2i(2, 2)
	for k in 8:
		var holder := Node3D.new()
		holder.name = "Botón %d" % k
		var at := way(k) * side * RING
		# En el tablero, «adelante» es para arriba (+y) y «derecha» es +x.
		holder.position = Vector3(at.x, at.y, 0.0)
		root.add_child(holder)
		look._build_on(seed_value, holder, Vector2.ONE * side * BUTTON)
