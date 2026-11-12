class_name InspectorPick
extends RefCounted

## LO QUE EL INSPECTOR SABE DE LO QUE ESTÁ MIRANDO, y es TODO lo que sabe.
##
## Un resolvedor (ver InspectorSource) contesta un `InspectorPick` por frame y el inspector lo dibuja sin
## preguntar de qué es: no sabe si es una manzana, una malla, una cara o un hueso. Esa es la frontera —
## lo que hace que agregar una cosa inspeccionable nueva no toque una línea del inspector.
##
## ── LOS GANCHOS SON LA API ───────────────────────────────────────────────────────────────────────
## `on_show` / `on_hide` / `on_press` son lo que convierte esto en algo más que un cartel. Un elemento
## dice "cuando me resalten, hacé esto" y el inspector lo llama; no hay un modo del inspector que sepa
## pintar pesos. El hueso del personaje trae un `on_show` que pinta sus pesos sobre la malla y un
## `on_hide` que la devuelve, y el inspector solo nota que cambió la `key`.
##
## `on_show` corre UNA VEZ, cuando este pick pasa a ser el resaltado (o sea cuando cambia `key`), no por
## frame. `on_hide` corre al dejar de serlo, al apagar el inspector y al cambiar de modo: lo que un
## gancho ensucia tiene que volver solo, porque la alternativa es un personaje roto hasta el respawn.
##
## ── LA GEOMETRÍA VIENE EN COORDENADAS DEL MUNDO ──────────────────────────────────────────────────
## Cinco capas, de atrás hacia adelante, y ninguna es obligatoria: el objeto que CONTIENE a lo apuntado
## (relleno oscuro y/o líneas), lo APUNTADO (relleno más claro y sus aristas), y los PUNTOS, que son
## para lo que es demasiado chico para rellenar — un vértice se marca con un diamante, no pintándolo.

## La identidad de lo apuntado. El inspector compara contra la del frame anterior para no rearmar las
## mallas de resaltado por frame y para saber cuándo correr los ganchos. Dos cosas distintas NO pueden
## compartir key: en el sandbox hay varias ciudades y varios personajes, así que lleva de quién es.
var key := ""

## Si la geometría SE MUEVE. Un personaje camina —la ciudad no— y entonces las capas hay que rearmarlas
## por frame aunque la key no cambie. Para lo quieto, rearmarlas sería tirar trabajo a la basura.
var live := false

## Dónde va el puntito, y de ahí cuelga el cartel: donde uno apuntó si eso tiene sentido (una cara, un
## vértice), el centro de la pieza si lo que importa es la pieza entera.
var centre := Vector3.ZERO

## Cuánto medir el puntito y el cartel respecto de lo normal. Existe por el design sandbox: sobre una
## muestra de ciudad a 1:25 una esfera de 35 cm tapa media manzana, y sobre un vértice, la malla entera.
var marker_scale := 1.0

## El cartel in-world, una línea por renglón. El inspector le agrega la distancia.
var lines: Array[String] = []

## La versión larga y plana para pegar en un chat: todo lo del cartel más lo que haga falta para
## reproducirlo sin estar mirando (la seed, los ids crudos, dónde pegó el rayo).
var report := ""

## Qué hace el botón con esto, para que el cartel de abajo lo diga. Vacío = no hace nada.
var action := ""

## RAYOS X o ESTUDIO, y es lo que decide si esto sirve para ENCONTRAR algo o para MIRARLO.
##
## Con rayos X (lo de siempre) las capas no testean profundidad: se ve la pieza aunque esté tapada, que es
## justo lo que hace falta para identificar una manzana atrás de un edificio.
##
## Para analizar geometría es al revés. Un alambre sin profundidad muestra las aristas de la cara de
## adelante Y las de la de atrás, superpuestas, y eso no se puede leer — es el "veo todos los lados a la
## vez" de siempre. En estudio las capas SÍ testean profundidad, así que la superficie tapa sus propias
## aristas de atrás y queda el sólido con el alambre encima, como el modo sólido de Blender.
##
## El inspector además las LEVANTA un poco hacia la cámara, porque una arista dibujada exactamente sobre
## la superficie que la contiene pelea con ella y sale punteada.
var xray := true

var parent_fill := PackedVector3Array()
var parent_lines := PackedVector3Array()
var target_fill := PackedVector3Array()
var target_lines := PackedVector3Array()
## Triángulos ya armados de los diamantes que marcan puntos sueltos (ver el encabezado).
var dots := PackedVector3Array()

var on_show := Callable()
var on_hide := Callable()
## El botón. Se la llama con UN ARGUMENTO, `alternate: bool`, que dice si el gesto vino con el modificador
## apretado: el elemento decide qué significa su acción alternativa. Es así y no un cuarto gancho porque
## "la otra cosa que hago" es del elemento, igual que la primera — la malla aisla o esconde, y el modo de
## loop cuts que viene va a abrir sus opciones por el mismo camino.
var on_press := Callable()
