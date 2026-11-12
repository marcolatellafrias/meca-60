class_name PixelFace
extends RefCounted

## UNA CARA RECTA DE UN MODELO, lista para pintarla con píxeles (ver PixelFaces, que las detecta, y PixelModel): los
## triángulos vecinos que están en un mismo plano, con su grilla de píxeles. La grilla es un rectángulo apoyado en el
## plano: `origin` es su esquina de ARRIBA A LA IZQUIERDA mirando la cara de afuera, `right` y `up` sus ejes. El píxel
## (x, y) crece a la derecha y hacia abajo, como en una imagen. Todo en el espacio del modelo.

var normal := Vector3.UP
var origin := Vector3.ZERO
var right := Vector3.RIGHT
var up := Vector3.FORWARD
## El tamaño de su grilla, en píxeles.
var width := 1
var height := 1
## Dónde está su rectángulo en el atlas (sin contar el borde de un píxel que lo rodea).
var at := Vector2i.ZERO
## Sus triángulos (tres puntos cada uno) y el color de material de cada triángulo.
var triangles := PackedVector3Array()
var colors := PackedColorArray()
## LA CARA ESTIRADA (ver PixelFaces.stretch): en vez de una grilla de píxeles cuadrados apoyada en el plano, la grilla
## se estira entre sus CUATRO ESQUINAS (arriba a la izquierda y en sentido horario; un triángulo repite su punta). Todos
## los píxeles se tocan, ninguno queda cortado, y se deforman con la cara.
var stretched := false
var corners := PackedVector3Array()
## Quién es la cara (dirección y centro), para recordar su modo entre armados.
var key := ""
## Su contorno: pares de puntos.
var outline := PackedVector3Array()
## Por píxel (y · width + x): si la cara lo toca, y su color de base (el del material).
var mask := PackedByteArray()
var base := PackedColorArray()


## Un punto de la cara, en píxeles de su grilla.
func local(point: Vector3, pixel: float) -> Vector2:
	var offset := point - origin
	return Vector2(offset.dot(right), -offset.dot(up)) / pixel


## El centro del píxel (x, y), en el espacio del modelo.
func centre(x: int, y: int, pixel: float) -> Vector3:
	if stretched:
		return spot((x + 0.5) / width, (y + 0.5) / height)
	return origin + right * ((x + 0.5) * pixel) - up * ((y + 0.5) * pixel)


## Un punto de la cara estirada: `u` de izquierda a derecha y `v` de arriba abajo, de 0 a 1.
func spot(u: float, v: float) -> Vector3:
	return corners[0].lerp(corners[1], u).lerp(corners[3].lerp(corners[2], u), v)


## El píxel donde cae un punto de la cara (el más cercano si cae justo afuera).
func pixel_at(point: Vector3, pixel: float) -> Vector2i:
	if not stretched:
		var flat := local(point, pixel)
		return Vector2i(clampi(floori(flat.x), 0, width - 1), clampi(floori(flat.y), 0, height - 1))
	var probe := local(point, pixel)
	var best := Vector2i.ZERO
	var nearest := INF
	for y in height:
		for x in width:
			var a := local(spot(float(x) / width, float(y) / height), pixel)
			var b := local(spot(float(x + 1) / width, float(y) / height), pixel)
			var c := local(spot(float(x + 1) / width, float(y + 1) / height), pixel)
			var d := local(spot(float(x) / width, float(y + 1) / height), pixel)
			if Geometry2D.point_is_inside_triangle(probe, a, b, c) or Geometry2D.point_is_inside_triangle(probe, a, c, d):
				return Vector2i(x, y)
			var distance := probe.distance_to(local(centre(x, y, pixel), pixel))
			if distance < nearest:
				nearest = distance
				best = Vector2i(x, y)
	return best


func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height and mask[y * width + x] == 1
