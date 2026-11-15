class_name BaseSettings
extends Resource

## LAS PERILLAS DE LA BASE (ver BaseLayout y BasePanel, el F1 de la fila Base): una sola copia (`current`). Al guardar,
## la base se vuelve a armar con las medidas nuevas (la meca se queda donde está).

## Se carga de lo guardado con «Guardar» en el F1 (KnobsFile). El archivo es del usuario: no va al repositorio.
const SAVED := "res://game/base/base_settings.tres"
static var current := KnobsFile.load_into(BaseSettings.new(), SAVED) as BaseSettings

@export_group("Medidas")
## EL ALTO DE LA NAVE (m): el elevador y el gimnasio, hasta el techo con la compuerta. Desde 16, para que la bolsa
## (de 7 a 15 m) tenga de dónde colgar.
@export_range(16.0, 45.0, 0.5) var nave_height := 22.0
## LA FRANJA DE LAS CONSOLAS: su fondo y su alto (m). El usuario, 15/11/2026: con 5 m «sigue quedando muy chico» al
## lado de la nave; que se pueda probar.
@export_range(6.0, BaseLayout.MAX_STRIP, 0.5) var strip_depth := 12.0
@export_range(3.5, 20.0, 0.25) var strip_height := 5.0
