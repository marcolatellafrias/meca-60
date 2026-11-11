class_name SuitStyle
extends Resource

## LO EDITABLE DE UN TRAJE: sus colores y sus grosores (panel F1 de la fila «Trajes», ver SuitTuner). Lo pidió
## el dios del juego (18/10/2026): DÓNDE van las costuras, las bandas y los parches lo define el código (ver Suits); cuánto
## miden y de qué color son, el panel. Se guarda la diferencia contra el código, traje por traje (ver SuitStyles).
##
## ── EL COLOR DE LA ROPA ES DEL TRAJE ────────────────────────────────────────────────────────────
## Un color existe en un solo lugar: la ropa —el saco y las mangas, el pantalón, los zapatos, el cinturón, las costuras y
## los parches— es del traje, y la piel —cabeza, orejas, cuello, manos— del personaje (ver TorsoShape.COLOR_FIELDS). Todos
## tonos del marrón de la arcilla (ver TorsoShape.clay_shade), como los del personaje.

const COLORS_GROUP := "Colores"
const SIZES_GROUP := "Grosores"

@export_group("Colores")
@export var cloth_color := Color(0.6, 0.45, 0.35)
## Las mangas, aparte del saco (lo pidió el dios del juego, 18/10/2026). Su defecto es el del saco.
@export var sleeves_color := Color(0.6, 0.45, 0.35)
@export var trousers_color := Color(0.6, 0.45, 0.35)
@export var shoes_color := Color(0.3, 0.2, 0.15)
@export var seam_color := Color(0.4, 0.3, 0.2)
## LAS COSTURAS DE CADA SECCIÓN (20/10/2026, lo pidió el dios del juego): las mangas y el pantalón tienen otro color de
## base que el saco, así que sus costuras van aparte. `seam_color` es la del saco (el torso). Su defecto, la del saco.
@export var sleeves_seam_color := Color(0.4, 0.3, 0.2)
## EL PUÑO DE LA MANGA (21/10/2026, lo pidió el dios del juego). Transparente (alfa 0) es «el de las mangas», que es como
## era: así un traje guardado antes no cambia; elegir un color lo fija (ver Suits.cuff).
@export var cuff_color := Color(0.0, 0.0, 0.0, 0.0)
@export var trousers_seam_color := Color(0.4, 0.3, 0.2)
@export var patch_color := Color(0.7, 0.55, 0.42)
@export var belt_color := Color(0.28, 0.19, 0.14)
## La hebilla del cinturón (ver Buckle), aparte del cuero.
@export var buckle_color := Color(0.58, 0.60, 0.63)
## Las bolsitas del cinturón (ver Pouch): su cuero; la tapa es un poco más oscura y el botón, del color de la hebilla.
@export var pouch_color := Color(0.36, 0.25, 0.18)
@export var button_color := Color(0.30, 0.21, 0.16)
## LA LÍNEA DEL CIERRE (20/10/2026, lo pidió el dios del juego): la del medio del mameluco no es una costura, es la que
## dice dónde cierra; va aparte para tener su color y su ancho (ver Suits, `closure`).
@export var closure_color := Color(0.30, 0.21, 0.16)
## El cuello del mameluco (ver Suits, EL CUELLO DEL MAMELUCO), de su propio color para que resalte (lo pidió el dios del
## juego).
@export var collar_color := Color(0.72, 0.56, 0.44)
## LA TARJETA CON EL NOMBRE (20/10/2026): en el pecho, del lado opuesto al bolsillo y a su altura (ver
## ProceduralBodyUtil._name_card). Su color, y su ancho, alto y relieve en metros.
@export var card_color := Color(0.89, 0.87, 0.82)
## El texto de la tarjeta: su color. El nombre, por ahora uno de muestra (ver Suits.CARD_NAME).
@export var card_text_color := Color(0.22, 0.16, 0.12)
## LA FRANJA DE ARRIBA de la tarjeta, que dice «EMPLEADO» (ver Suits.CARD_STRIPE_TEXT): su color y el de su texto.
@export var card_stripe_color := Color(0.60, 0.41, 0.38)
@export var card_stripe_text_color := Color(0.92, 0.88, 0.80)
## LOS COLORES DEL DISPOSITIVO DE COMUNICACIÓN del pecho (ver CommDevice): tonos de la arcilla, como todos los del traje
## (lo pidió el dios del juego, 20/10/2026), con su tono y su saturación —en 0, grises—. La caja, el metal (el aro de la
## bocina, la antena, el botón), lo oscuro (el fondo de la bocina, el cable), la etiqueta y su texto. Los leds y la punta de
## la antena no: son luces, de su color.
@export var comm_color := TorsoShape.clay_color(0.55, 0.0)
@export var comm_metal_color := TorsoShape.clay_color(0.25, 0.0)
@export var comm_dark_color := TorsoShape.clay_color(1.0, 0.0)
@export var comm_label_color := TorsoShape.clay_color(0.0, 0.6)
@export var comm_ink_color := TorsoShape.clay_color(0.9, 0.6)
## El cable grueso del costado: rojizo, la arcilla bien saturada.
@export var comm_cable_color := TorsoShape.clay_color(0.6, 2.0)

@export_group("Grosores")
## ── EL PATRÓN DE CIRCULITOS (20/10/2026) ─────────────────────────────────────────────────────────
## Lo pidió el dios del juego: un patrón simple, por zona —el saco, las mangas, el pantalón—, cada una con lo suyo:
## el diámetro de los circulitos —0, sin circulitos: es lo que los prende— y cada cuánto van, en metros, y CUÁNTO MÁS
## CLAROS (+) U OSCUROS (−) que la tela son —no un color aparte: un modificador de la base, con un rango corto para
## afinar sin que contrasten de más— (sale del unwrap, ver GridPart._face_uvs, así
## que mide lo mismo en cualquier cuerpo).
@export_range(0.0, 0.1, 0.001, "suffix:m") var torso_dot_size := 0.0
@export_range(0.005, 0.2, 0.001, "suffix:m") var torso_dot_spacing := 0.035
@export_range(-0.3, 0.3, 0.005) var torso_dot_shade := 0.1
@export_range(0.0, 0.1, 0.001, "suffix:m") var arms_dot_size := 0.0
@export_range(0.005, 0.2, 0.001, "suffix:m") var arms_dot_spacing := 0.035
@export_range(-0.3, 0.3, 0.005) var arms_dot_shade := 0.1
@export_range(0.0, 0.1, 0.001, "suffix:m") var legs_dot_size := 0.0
@export_range(0.005, 0.2, 0.001, "suffix:m") var legs_dot_spacing := 0.035
@export_range(-0.3, 0.3, 0.005) var legs_dot_shade := 0.1
## El ancho de las costuras que no dicen el suyo (ver Suits, `width`), en metros.
@export_range(0.001, 0.03, 0.0005, "suffix:m") var seam_width := 0.006
## El ancho de la línea del cierre, en metros.
@export_range(0.001, 0.03, 0.0005, "suffix:m") var closure_width := 0.008
## EL CUELLO DEL MAMELUCO (ver Suits, EL CUELLO DEL MAMELUCO), en metros del genérico: cuánto baja atrás y a los
## costados, cuánto bajan la punta de cada lengüeta y su columna de al lado, y cuántos grados se abren las puntas.
@export_range(0.0, 0.1, 0.001, "suffix:m") var collar_band := 0.025
@export_range(0.0, 0.2, 0.001, "suffix:m") var collar_tongue := 0.060
@export_range(0.0, 0.2, 0.001, "suffix:m") var collar_tongue_side := 0.038
@export_range(0.0, 60.0, 0.5, "suffix:°") var collar_spread := 32.0
@export_range(0.01, 0.2, 0.005, "suffix:m") var card_width := 0.095
@export_range(0.005, 0.1, 0.001, "suffix:m") var card_height := 0.056
@export_range(0.0, 0.01, 0.0005, "suffix:m") var card_thickness := 0.003
## Qué parte del alto de la tarjeta es la franja de arriba (0: sin franja).
@export_range(0.0, 0.6, 0.01) var card_stripe := 0.24
## LOS PARCHES DE LA RODILLA (ver Suits.KNEE_PATCH): su redondez, de rectángulo (0) a elipse (1). Su ancho y su alto
## son del cuerpo (ver TorsoShape.knee_width).
@export_range(0.0, 1.0, 0.05) var knee_roundness := 0.75
## Su espesor, en metros (0: una lámina sin espesor).
@export_range(0.0, 0.02, 0.0005, "suffix:m") var collar_thickness := 0.004
## CUÁNTOS BOTONES lleva el cierre (20/10/2026, lo pidió el dios del juego). Dónde termina el cierre y entre dónde van
## los botones es del cuerpo (ver TorsoShape.closure_length, button_start, button_reach).
## SI EL TRAJE LLEVA BOTONES (22/10/2026, lo pidió el dios del juego): apagado no van, y se guarda cuántos.
@export var show_buttons := true
@export_range(0, 12, 1) var button_count := 5
## El espesor del puño (o del rollo) de la manga, y el alto y el espesor del puño del pantalón, en metros (ver
## GridPart.draw_band).
@export_range(0.0, 0.05, 0.001, "suffix:m") var sleeve_cuff := 0.008
@export_range(0.0, 0.05, 0.001, "suffix:m") var trouser_cuff := 0.009
@export_range(0.0, 0.2, 0.005, "suffix:m") var trouser_cuff_height := 0.045
## El relieve de los parches que no dicen el suyo (ver Suits, `thickness`), en metros.
@export_range(0.0, 0.03, 0.0005, "suffix:m") var patch_thickness := 0.004
## PARA MIRAR EL PIE (de prueba, lo pidió el dios del juego, 20/10/2026): el pie un tono más claro que la caña del zapato,
## para ver dónde termina la pierna y empieza el pie (ver ProceduralBodyUtil._foot). Se apaga acá.
@export var debug_foot_shade := true


func copy() -> SuitStyle:
	return duplicate() as SuitStyle
