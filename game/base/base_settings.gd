class_name BaseSettings
extends Resource

## LAS PERILLAS DE LA BASE (ver BaseLayout y BasePanel, el F1 de la fila Base): una sola copia (`current`). Al guardar,
## la base se vuelve a armar con las medidas nuevas (la meca se queda donde está).

## Se carga de lo guardado con «Guardar» en el F1 (KnobsFile). El archivo es del usuario: no va al repositorio. *El de la
## base para la meca grande (base_settings.tres) quedó de lado: sus medidas eran de 22 m de alto.*
const SAVED := "res://game/base/base_humana.tres"
static var current := KnobsFile.load_into(BaseSettings.new(), SAVED) as BaseSettings

@export_group("Medidas")
## EL ALTO DE LA NAVE (m): el elevador y el gimnasio, hasta el techo con la compuerta. Desde 8, para que la meca jaula
## (≈ 7 m) quepa parada.
@export_range(8.0, 25.0, 0.25) var nave_height := 12.0
## EL FONDO DE LA NAVE (m), que es también el lado del elevador: un cuadrado que crece hacia su lado.
@export_range(6.0, BaseLayout.MAX_DEPTH, 0.25) var nave_depth := 10.0
## LA FRANJA DE LAS CONSOLAS: su ancho (también el largo del gimnasio), su fondo (también el lado de la esclusa) y su
## alto (también el de la esclusa) (m). Desde 11 de ancho: lo que necesitan las consolas, el cuadro y dos casilleros.
@export_range(11.0, BaseLayout.MAX_WIDTH, 0.25) var strip_width := 14.0
@export_range(4.0, BaseLayout.MAX_STRIP, 0.25) var strip_depth := 6.0
@export_range(3.0, 10.0, 0.25) var strip_height := 4.0
## DÓNDE CUELGA LA BOLSA: al medio del gimnasio (para dar vueltas pegándole) o en la punta, contra la pared con su
## margen (para pegarle de un lado).
@export_enum("al medio", "en la punta") var bag_place := 0
