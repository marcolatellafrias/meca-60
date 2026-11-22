class_name IsoSettings
extends Resource

## LAS PERILLAS DE LA CÁMARA ISOMÉTRICA (22/11/2026; el usuario: «quisiera poder cambiar la perspectiva con un menú F…
## para probar ambas, y también jugar con el zoom»). Las mueve su panel (IsoPanel); el archivo es del usuario.

const SAVED := "res://game/iso/iso_settings.tres"

static var current := KnobsFile.load_into(IsoSettings.new(), SAVED) as IsoSettings

@export_group("Cámara")
## Ortográfica (lo lejano se ve del mismo tamaño) o con perspectiva.
@export var orthographic := false
## Cuánto entra de alto en la pantalla (m): el zoom, el mismo en las dos proyecciones.
@export_range(4.0, 80.0, 0.5) var zoom := 22.0
## Lo inclinada hacia abajo (°) y su giro alrededor de la vertical (°). 60° Y SIN GIRO (22/11/2026, elegido por el usuario
## entre seis ángulos): se leen los ataques en el piso y se sigue viendo la meca.
@export_range(10.0, 89.0, 0.1) var pitch := 60.0
@export_range(-180.0, 180.0, 1.0) var yaw := 0.0
## La apertura con perspectiva (°; más baja, más parecida a la ortográfica).
@export_range(5.0, 70.0, 1.0) var fov := 30.0
## Lo alto que se ve sobre el personaje (m): lo que empieza más arriba (un techo, el piso de la arena) no se dibuja.
@export_range(1.0, 30.0, 0.5) var cut := 3.0


## La orientación de la cámara.
func view_basis() -> Basis:
	return Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, -deg_to_rad(pitch))


## UNA DIRECCIÓN DE LA PANTALLA (x a la derecha, y arriba) EN EL PISO DEL MUNDO.
func screen_to_world(way: Vector2) -> Vector3:
	return Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(way.x, 0.0, -way.y)
