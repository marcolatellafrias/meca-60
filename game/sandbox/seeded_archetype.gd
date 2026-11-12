class_name SeededArchetype
extends RefCounted

## UN ARQUETIPO CON SEMILLA: lo que ocupa una parcela del sandbox. El arquetipo dice QUÉ es (un pasajero humano, uno
## robot) y la semilla varía el individuo dentro de esa clase. Es la misma idea que en character-parametric, sin nada
## de lo que allá creció encima: una parcela por arquetipo, R para otra semilla, y el panel que dice qué es.

## Cómo se llama en el panel y en la parcela.
var display_name := "sin nombre"
## Las opciones de su fila, compartidas por los arquetipos de una fila (como allá, en character-parametric: los paquetes
## de allá las usan).
var options: Dictionary = {}


## Cuánto puede llegar a ocupar en el suelo (ancho, profundidad), con CUALQUIER semilla. La parcela se mide con esto
## una sola vez: regenerar no mueve la grilla.
func max_footprint() -> Vector2:
	return Vector2(4.0, 4.0)


## Arma el individuo `seed_value` colgado de `parent`, centrado en su origen y apoyado en y = 0, y devuelve su raíz.
func build(_seed_value: int, _parent: Node3D) -> Node3D:
	return null


## Lo que el panel muestra de este individuo: pocas líneas cortas. El nombre y la semilla los pone el panel.
func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray()


## LAS TECLAS DE SU FILA (como allá): las de la primera parcela de la fila valen para toda la fila; `apply(parcels)` recibe
## sus parcelas. Leen y escriben `options`, que la fila comparte.
func category_options() -> Array[Dictionary]:
	return []


## Las teclas propias de esta parcela: `{"key": KEY_X, "label": String o Callable, "apply": Callable(parcel)}`. No
## pueden repetir las del sandbox (WASD, espacio, shift, ctrl, R, C, T, Enter, Escape). Con `"seated": true` la tecla
## vale también sentado (manejando): sentado, las demás no andan (ver DesignSandbox._input).
func parcel_options() -> Array[Dictionary]:
	return []


## LAS TRES FUERZAS DE LA BOLA para lo que hay en esta parcela (ver TestBall): el empuje (N·s) que lo mueve, el que lo
## deja a punto de caerse y el que lo tira, con sus umbrales de ahora. Vacío: sin bola.
func ball_pushes() -> Array[float]:
	return []


## LOS TIROS DE LA BOLA de esta parcela (ver TestBall): `{name, push, speed}`. Por defecto, los tres empujes de
## `ball_pushes` a la velocidad de siempre; una fila puede tener los suyos (el cubo flotante: lentos y rápidos).
func ball_shots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var pushes := ball_pushes()
	for i in pushes.size():
		out.append(TestBall.shot(str(TestBall.NAMES[mini(i, TestBall.NAMES.size() - 1)]), pushes[i]))
	return out


## Cuando uno entra o sale de la parcela.
func entered(_parcel: SandboxParcel, _inside: bool) -> void:
	pass
