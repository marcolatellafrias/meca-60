class_name FaceStyle
extends Resource

## ── CÓMO SE VEN LOS RASGOS DE TODOS (20/10/2026) ────────────────────────────────────────────────────────────────────
## Lo pidió el dios del juego: los colores y los gruesos de la cara de todos —la línea de la boca, los ojos, las ojeras—
## en su propio panel (F1 en la fila Rasgos, ver FaceStyleTuner), aparte del personaje. Unos son AGNÓSTICOS de la piel (la
## boca, los ojos: un color y listo) y otros RELATIVOS a ella (las ojeras: cuánto más oscuras y menos saturadas que la
## piel de cada uno), pero todos con control. Los lee FaceLayout al armar la cara. Se guarda en el repo, como el shader
## de los personajes (ver CharacterBodyVisual.body_material).

static var path := "res://game/character/face/face_style.tres"

@export_group("Boca")
## EL COLOR DE LA LÍNEA DE LA BOCA (el de los labios es de cada personaje, ver CharacterLook).
@export var mouth_color := Color(0.16, 0.13, 0.12)
## SU MEDIO-GRUESO, en fracción del ancho de la cabeza a la altura de los ojos.
@export_range(0.003, 0.05, 0.0005) var mouth_thick := 0.017

@export_group("Ojos")
@export var eye_white := Color(0.96, 0.95, 0.92)
@export var eye_line := Color(0.10, 0.08, 0.07)
## EL GRUESO DEL BORDE DEL OJO, en fracción del alto de la cabeza (ver FaceFeature.stroke).
@export_range(0.0, 0.03, 0.0005) var eye_stroke := 0.0075

@export_group("Ojeras")
@export var eye_bags := true
## Cuánto más oscuras y menos saturadas que la piel de cada uno (fracciones): relativas a la piel.
@export_range(0.0, 1.0, 0.01) var bag_darken := 0.3
@export_range(0.0, 1.0, 0.01) var bag_desaturate := 0.35
## Dónde y de qué tamaño, en radios del ojo: cuánto más abajo del centro del ojo va su medio, su largo, cuánto baja su
## medio respecto de las puntas y su medio-grueso.
@export_range(0.5, 4.0, 0.01) var bag_drop := 1.55
@export_range(0.2, 4.0, 0.01) var bag_width := 1.6
@export_range(-1.5, 1.5, 0.01) var bag_sag := 0.35
@export_range(0.02, 0.6, 0.005) var bag_thick := 0.13

static var _loaded: FaceStyle = null


static func current() -> FaceStyle:
	if _loaded == null:
		if ResourceLoader.exists(path):
			_loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as FaceStyle
		if _loaded == null:
			_loaded = FaceStyle.new()
	return _loaded


static func store() -> bool:
	return ResourceSaver.save(current(), path) == OK


## TODO LO QUE DECIDE LA CARA, como texto: para la firma de lo que se reusa en borrador (ver ProceduralBodyUtil._reused).
func signature() -> String:
	return "%s|%.4f|%s|%s|%.4f|%s|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f" % [mouth_color.to_html(), mouth_thick, eye_white.to_html(),
		eye_line.to_html(), eye_stroke, eye_bags, bag_darken, bag_desaturate, bag_drop, bag_width, bag_sag, bag_thick]
