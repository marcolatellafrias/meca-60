class_name FaceFeature
extends Resource

## UN RASGO FACIAL —un ojo, un tramo de la boca, un extra— como CAMINO VECTORIAL más dónde va y de qué tamaño. Los
## ojos y la boca de todos los arma FaceLayout con caminos como estos; los extra los dibuja el dios del juego.
##
## ── LO QUE SE AUTORA ES EL CAMINO, NO LA MALLA ──────────────────────────────────────────────────
## El rasgo es una curva con nodos y manijas (Bézier cúbica: el modelo de un `path` de SVG sin lo exótico —
## una cúbica expresa una recta y una cuadrática). La malla sale de MUESTREAR cada segmento en una cantidad
## FIJA de pasos (ver FaceFeatureMesh.CURVE_STEPS), que es exactamente lo que el cuerpo hace con sus loop
## cuts: pocos números autorados, conteo de malla de plantilla.
##
## Eso es lo que deja la puerta abierta al editor de rasgos in-game: el editor edita NODOS Y MANIJAS —estos
## mismos números— y la malla se regenera, igual que arrastrar un loop cut rehace el cuerpo. No hay un
## formato intermedio ni una conversión que mantener.
##
## La fidelidad es la que se pidió: con 8 pasos por segmento, un círculo de cuatro cúbicas tiene 32 lados y
## el error sobre un ojo de 1 cm es de una décima de milímetro.
##
## ── LAS COORDENADAS SON DE LA CARA, NO DEL PAÑO ─────────────────────────────────────────────────
## `at_u` es fracción del MEDIO-ANCHO DEL FRENTE a esa altura (±1 es justo el borde de lo que el paño toca) y
## `at_v` es fracción del ALTO de la cabeza (0 el mentón, 1 la coronilla).
##
## No son coordenadas del paño y es a propósito: el paño mide siempre lo mismo —está dimensionado para la
## cara más grande—, así que el mismo punto del paño caía en la frente de una cabeza de
## 20 cm y ARRIBA DE LA CORONILLA en una de 10. En coordenadas de la cara, "al 30% del alto y al 50% del
## ancho" quiere decir lo mismo en las dos — que es la promesa entera del sistema. Lo que el paño aporta es
## lo que solo él sabe: dónde apoya cada punto del contorno y hacia dónde mira la superficie ahí.

## ── EL CONTORNO, COMO NÚMEROS PLANOS ────────────────────────────────────────────────────────────
## Tres entradas por nodo y en este orden: POSICIÓN, MANIJA DE ENTRADA y MANIJA DE SALIDA, las dos manijas
## relativas al nodo. Es lo mismo que guarda un `Curve2D` de Godot, y de hecho `curve()` arma uno con esto
## para muestrear — pero lo que se guarda son los números.
##
## ⚠ Y ES POR UNA RAZÓN CONCRETA: lo que el panel guarda es la DIFERENCIA contra el defecto del código (ver
## ShapeLayer), y ese mecanismo SALTEA las propiedades que son objetos. Guardando un `Curve2D` exportado, la
## forma autorada no se guardaría nunca — y la forma es justo lo que el editor va a escribir. Un
## `PackedVector2Array` se guarda, se compara y se diferencia como cualquier otro número.
##
## Las posiciones van en la CAJA PROPIA del rasgo, de −0,5 a 0,5: un rasgo normalizado se mueve y se escala
## sin tocarle un nodo, que es lo que lo vuelve un catálogo.
@export var nodes := PackedVector2Array()

## Si el contorno CIERRA (y por lo tanto puede rellenarse). El último nodo NO repite al primero: cerrar es
## este sí o no, y el que muestrea agrega el segmento que falta (ver FaceFeatureMesh._tessellate).
@export var closed := true
## SI ES UN POLÍGONO CHICO, un tramo de una línea (ver FaceLayout._quad): sus lados rectos no se parten al muestrear (ver
## FaceFeatureMesh._tessellate). No se guarda: lo pone quien lo arma.
var small_polygon := false

## Si se rellena lo de adentro del contorno. Un ojo sí —el blanco—, una boca de una línea no.
@export var filled := true

## El color del relleno y el del contorno. Son colores planos: el estilo del juego no tiene degradados.
@export var fill_color := Color(1.0, 1.0, 1.0)
@export var stroke_color := Color(0.08, 0.07, 0.09)

## EL GROSOR DEL CONTORNO, en fracción del alto de la cabeza. Relativo y no en milímetros para que un rasgo
## se vea igual en una cabeza chica y en una grande — la misma razón por la que el tamaño también lo es.
@export_range(0.0, 0.06, 0.001) var stroke := 0.012

## ── DÓNDE VA, EN COORDENADAS DE LA CARA ─────────────────────────────────────────────────────────
## `at_u`: 0 es el centro de la cara y ±1 el borde de lo que el paño toca a esa altura.
@export_range(-1.0, 1.0, 0.01) var at_u := 0.0
## `at_v`: 0 es el mentón y 1 la coronilla.
@export_range(0.0, 1.0, 0.01) var at_v := 0.5

## EL TAMAÑO, en fracción del alto de la cabeza y EN LOS DOS EJES CON LA MISMA UNIDAD: así un círculo sale
## círculo en una cara angosta y en una ancha. Si el eje x fuera relativo al ancho, la misma forma saldría
## aplastada en una cabeza flaca.
@export_range(0.01, 0.6, 0.005) var size_x := 0.1
@export_range(0.01, 0.6, 0.005) var size_y := 0.1

## SI SE DIBUJA TAMBIÉN ESPEJADO del otro lado. Un par de ojos es UN ojo autorado y su espejo: así los dos
## son el mismo dato y no pueden quedar desparejos.
@export var mirror := false

## ── LO QUE SÓLO TIENE UN RASGO EXTRA ────────────────────────────────────────────────────────────
## Los extra —arrugas, una nariz, lo que el dios del juego cree desde el editor vectorial (ver FeatureEditor y
## FaceFeatures.extras)— no tienen ranura ni defecto del código: tienen un NOMBRE, un ANCLA y QUÉ CUERPOS LOS LLEVAN.
## En los ojos y la boca (ver FaceLayout), estos tres números no se usan.

const ANCHOR_EYES := 0
const ANCHOR_MOUTH := 1
const ANCHOR_NOSE := 2
const ANCHOR_NAMES: Array[String] = ["los ojos", "la boca", "la nariz"]
const ALL_BODIES := 0x3f

## El nombre con el que se lo nombra en el editor y en su parcela.
@export var feature_name := ""

## DE QUÉ CUELGA (11/10/2026: sólo de los ojos, la boca o la nariz): en un extra, `at_u` y `at_v` son el CORRIMIENTO
## desde ese punto, en las mismas unidades de la cara, así que si se mueven los ojos lo que cuelga de ellos los sigue.
## La nariz no es un rasgo: es un punto fijo en el medio de la cara, entre los ojos y la boca (ver
## FaceFeatures.anchor_point).
@export var anchor := ANCHOR_NOSE

## QUÉ CUERPOS LO LLEVAN, un bit por arquetipo (era como el permiso de los brazos de antes): una
## arruga es del viejo, no del niño. Al crearlo, todos.
@export var bodies := ALL_BODIES

## SI SU RELLENO VA ENCIMA DE LOS OTROS RELLENOS, un pelo más afuera de la cara: la línea de la boca sobre los labios
## (ver FaceLayout.mouth, FaceFeatureMesh.LAYER_DETAIL).
@export var on_top := false

## Desde el 15/10/2026 todo rasgo es un camino: los ojos con pupila y las bocas con dientes, que eran estructuras con
## formas que se cambiaban (EyeShapes, MouthPoses), se borraron con los gestos viejos (ver FaceLayout).
const KIND_PATH := 0
@export var kind := KIND_PATH


## ── UN CÍRCULO COMO CUATRO CÚBICAS ──────────────────────────────────────────────────────────────
## Con las manijas en `4/3 · (√2 − 1) = 0,5523` del radio, que es la aproximación de siempre: el error
## máximo contra el círculo exacto es de 0,02% del radio. No es una elección estética, es LA constante con
## la que todo editor vectorial dibuja un círculo, y por eso el rasgo que salga del editor va a ser este.
static func circle_nodes() -> PackedVector2Array:
	const K := 0.5522847498307936 * 0.5
	var out := PackedVector2Array()
	var at := [Vector2(0.0, 0.5), Vector2(0.5, 0.0), Vector2(0.0, -0.5), Vector2(-0.5, 0.0)]
	var along := [Vector2(K, 0.0), Vector2(0.0, -K), Vector2(-K, 0.0), Vector2(0.0, K)]
	for i in at.size():
		out.append(at[i] as Vector2)
		out.append(-(along[i] as Vector2))
		out.append(along[i] as Vector2)
	return out


## EL CAMINO COMO `Curve2D`, para muestrearlo: los números de `nodes` armados en la curva de Godot, que ya
## trae la matemática de la cúbica. Se arma al vuelo y no se guarda (ver la nota de `nodes`).
##
## Si el camino CIERRA se le agrega al final una copia del primer nodo: así el segmento que cierra se
## muestrea igual que todos los demás, sin un caso especial.
func curve() -> Curve2D:
	var out := Curve2D.new()
	var count: int = nodes.size() / 3
	for i in count:
		out.add_point(nodes[i * 3], nodes[i * 3 + 1], nodes[i * 3 + 2])
	if closed and count >= 2:
		out.add_point(nodes[0], nodes[1], nodes[2])
	return out


func copy() -> FaceFeature:
	var out := FaceFeature.new()
	out.nodes = nodes.duplicate()
	out.closed = closed
	out.filled = filled
	out.fill_color = fill_color
	out.stroke_color = stroke_color
	out.stroke = stroke
	out.at_u = at_u
	out.at_v = at_v
	out.size_x = size_x
	out.size_y = size_y
	out.mirror = mirror
	out.feature_name = feature_name
	out.anchor = anchor
	out.bodies = bodies
	out.kind = kind
	out.on_top = on_top
	return out


## UN RASGO EXTRA NUEVO, como lo crea el editor: sin trazo todavía, colgado de la nariz, sin corrimiento, con una caja
## de un cuarto del alto de la cabeza, una línea oscura sin relleno, y lo llevan todos los cuerpos.
static func new_extra(new_name: String) -> FaceFeature:
	var out := FaceFeature.new()
	out.feature_name = new_name
	out.anchor = ANCHOR_NOSE
	out.nodes = PackedVector2Array()
	out.closed = false
	out.filled = false
	out.stroke_color = Color(0.10, 0.07, 0.07)
	out.stroke = 0.012
	out.at_u = 0.0
	out.at_v = 0.0
	out.size_x = 0.25
	out.size_y = 0.25
	out.mirror = false
	out.bodies = ALL_BODIES
	return out


## Si este cuerpo lo lleva (ver `bodies`).
func worn_by(archetype: int) -> bool:
	return archetype < 0 or (bodies & (1 << archetype)) != 0


## Para el cartel del panel y para el portapapeles.
func describe() -> String:
	return "%d nodos · en (%+.2f, %.2f) · %.3f × %.3f del alto · %s%s" \
		% [nodes.size() / 3, at_u, at_v, size_x, size_y,
			"relleno + contorno" if filled else "solo contorno",
			" · espejado" if mirror else ""]
