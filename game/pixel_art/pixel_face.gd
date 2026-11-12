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
	return origin + right * ((x + 0.5) * pixel) - up * ((y + 0.5) * pixel)


func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height and mask[y * width + x] == 1
