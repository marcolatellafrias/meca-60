extends Node
## UIState (autoload). Único dueño del mouse_mode y de qué overlays están abiertos por
## encima del gameplay (pausa, menú, consola, panel de debug). El gameplay solo está
## "activo" cuando no hay ningún overlay: ahí se captura el mouse. Cualquier overlay
## libera el mouse y bloquea el input de gameplay — player_controller y la cápsula
## consultan gameplay_active() antes de leer input. No frena la simulación (co-op: el
## mundo sigue). Ver character-parametric:docs/technical/ui.md.
##
## LA PANTALLA LIMPIA (`hide_screen`; Tab en el sandbox, 17/11/2026, el usuario: «una tecla especial reservada al
## sandbox para ocultar toda la ui»): no se dibuja nada de 2D. Se apaga en la ventana misma (`canvas_cull_mask`), no
## panel por panel: así vale para todos los paneles, los carteles y los rótulos, también los que se armen mañana con
## un CanvasLayer suelto, sin que ninguno tenga que heredar ni anotarse. Las pantallas de adentro de las mecas (sus
## propios SubViewport) y los carteles 3D siguen. Abrir cualquier overlay (una F, la pausa, la consola) la devuelve:
## lo que pide el mouse se tiene que ver.

const PAUSE := "pause"
const MENU := "menu"
const CONSOLE := "console"
const DEBUG := "debug"
## Los afinadores: vista (F3) y clima y nubes (F6). Se anotan acá —y no como el
## mapa, que no se anota— porque hay que arrastrar sliders y abrir selectores: necesitan el mouse libre.
const VIEW := "view"
const TUNER := "tuner"
## EL PERSONAJE CANÓNICO DE LA PARCELA: la forma de su cabeza (F4 en la fila Personajes, ver CharacterLookPanel).
const CHARACTER_LOOK := "character_look"
## LAS FORMAS DE CABEZA: el F3 de la fila «Cabezas» (ver HeadFormsPanel).
const HEAD_FORMS := "head_forms"
## LOS ANCHOS DE CALLE DE LA MAQUETA (F1 en su fila del sandbox, ver StreetTuner).
const STREETS := "streets"
## LA LOCOMOCIÓN DE CADA ARQUETIPO: caminata, pose, movimiento, equilibrio y salto (F3 en la fila Personajes y F2 en los
## Experimentos de locomoción del sandbox, ver LocomotionTuner).
const LOCOMOTION_TUNING := "locomotion_tuning"
## EL LOOK DE LAS SUPERFICIES (F1 en su fila del sandbox, ver SurfaceTuner).
const SURFACES := "surfaces"
## DE CUÁNTOS JUGADORES ES LA NAVE (F3 en la fila Nave, ver ShipFlatPanel).
const SHIP_FLAT := "ship_flat"
## EL SHADER DE LA NAVE: el degradé, la sombra y el brillo (F1 en la fila Nave por fuera, ver ShipShadingTuner).
const SHIP_SHADING := "ship_shading"
## LA EXPERIMENTACIÓN DE MÓDULOS: el módulo de la parcela (F1), ver ExperimentPanel.
const EXPERIMENT_MODULE := "experiment_module"

## ── LOS PANELES DE TECLA F: UNO SOLO A LA VEZ ───────────────────────────────────────────────────
## Todos viven pegados al mismo borde de la pantalla y todos se quedan con el mouse, así que dos abiertos
## son dos paneles encimados y ningún camino obvio para volver — y encima hay que acordarse de con qué tecla
## se cerraba cada uno.
##
## Antes esto se resolvía de a pares: cada panel preguntaba por los otros antes de abrirse ("no abro si está
## abierto el de cabezas, ni el de rasgos, ni..."), y eso es una lista que hay que actualizar en N lugares
## cada vez que aparece un panel — con el resultado de que apretar F2 con un panel de F1 abierto NO HACÍA
## NADA, que se lee como una tecla rota. La regla ahora es una sola y vive acá: ABRIR UNO CIERRA A LOS
## DEMÁS (ver `open_only` y TunerPanel.toggle_exclusive), así que cualquier tecla F siempre hace lo que uno
## espera — muestra su panel— sin importar qué había abierto.
##
## Lo que decide CUÁL panel abre una tecla compartida sigue siendo de cada panel: F1 es de tres y abre el
## que corresponde a la fila donde uno está parado (ver TunerPanel.serves). Eso es otra pregunta.
## EL EDITOR VECTORIAL DE LOS RASGOS EXTRA (F2 en la fila Rasgos, ver FeatureEditor).
const FEATURE_EDITOR := "feature_editor"
## LOS RASGOS DE TODOS: la boca, los ojos y las ojeras (F1 en la fila Rasgos, ver FaceStyleTuner).
const FACE_STYLE := "face_style"
## LAS MEDIDAS DEL PERSONAJE: su altura y una escala para aplicar (F7 en la fila Personajes, ver MeasuresPanel).
const MEASURES := "measures"
## LOS SONIDOS DE UNA PARCELA: soltar archivos, sus claves y la mezcla del ambiente (F1 en la fila Sonidos, ver SoundPanel).
const SOUNDS := "sounds"
## LAS PARCELAS ARCHIVADAS: desarchivarlas (F10 en cualquier fila, ver ArchivePanel).
const ARCHIVE := "archive"
## LA GRILLA DE LA CARA del edificio donde uno está (F1 en la fila Edificios, ver FaceGridTuner).
const FACE_GRID := "face_grid"
## LOS PARADIGMAS DE LA MANZANA: escalonado y callejones, para probar y guardar (F3 en la fila Edificios, ver ParadigmPanel).
const PARADIGMS := "paradigms"
## LOS PUENTES: la escala del puente de caños, rearmando sólo los puentes (F5 en la fila Edificios, ver BridgeTuner).
const BRIDGES := "bridges"
## CÓMO SE APRIETA UN BOTÓN: con el puño o con el dedo (F1 en la fila Botones del sandbox, ver PressPanel).
const PRESS := "press"
## UNA PIEZA DE FACHADA: crearla y medirla en celdas (+ en la fila Piezas de fachada, ver FacadePieceTuner).
const FACADE_PIECE := "facade_piece"
## LA MAQUETA DE BLOQUES: la forma, las terrazas en rojo, los puentes de prueba y las zonas de plazas (F1 en la fila
## Bloques, ver MassingTuner).
const MASSING := "massing"
const GENERATION := "generation"
## LA ESCALA DE LA CIUDAD DEL MAPA Y EL RADAR (F1 en la fila Escalas, ver ScaleTuner).
const SCALES := "scales"
## LA NAVEGACIÓN: qué mapa lleva la meca (F2 en las filas Nave y Escalas, ver NavigationTuner).
const NAVIGATION := "navigation"
## LA SILLA: abrir y traer de Blender cada sección (F1 en la fila Nave, ver SeatPanel).
const SEAT := "seat"
## EL CUERPO DEL SANDBOX: ser ente o cuerpo, y con qué arquetipo (F9 desde cualquier parte, ver BodyPanel).
const BODY := "body"
## LA EXAGERACIÓN DE LA CAÍDA («todos» en el F3 de Locomoción, ver LocomotionCommonKnobs).
const LOCOMOTION := "locomotion"
## LOS PANELES DE TECLA F SE ANOTAN SOLOS al montarse (ver `register_panel` y TunerPanel.setup) (lo pidió el usuario, 07/11/2026: «puedo abrir varios paneles en simultáneo… cuando abro uno, no es que se cierre el anterior, sino que se apila… debería ser una regla que se enforcea automáticamente en el sistema de paneles»): así
## `open_only` cierra a TODOS, también al que se agregue mañana. *Hasta entonces era una lista escrita a mano (`PANELS`), y
## el panel que no estaba en ella ni cerraba a los otros ni lo cerraban: se apilaban.*
var _panels: Dictionary = {}

signal changed()

## layer(String) -> true. Un overlay está abierto si su clave está presente.
var _open: Dictionary = {}

## Si la pantalla está limpia (ver `hide_screen`).
var screen_hidden := false

func _ready() -> void:
	_refresh()

func open(layer: String) -> void:
	if _open.has(layer):
		return
	_open[layer] = true
	_show_screen()
	_refresh()

func close(layer: String) -> void:
	if not _open.has(layer):
		return
	_open.erase(layer)
	_refresh()

func toggle(layer: String) -> void:
	if _open.has(layer):
		close(layer)
	else:
		open(layer)

## ABRE ESTE PANEL Y CIERRA A LOS DEMÁS DE TECLA F (ver `register_panel`). Los otros overlays —pausa, menú, consola,
## el panel de debug— no se tocan: no son paneles de tecla F y no compiten por el mismo borde de pantalla.
##
## Se cierra y se abre en una sola pasada, con un solo `changed`: cada panel se entera por esa señal, y
## emitiéndola una vez por cierre el que se está abriendo vería un cuadro con los dos estados mezclados.
func open_only(layer: String) -> void:
	for other: String in _open.keys():
		if other != layer and is_panel(other):
			_open.erase(other)
	_open[layer] = true
	_show_screen()
	_refresh()


## ANOTA UN PANEL DE TECLA F: desde ahora `open_only` lo cierra cuando se abre otro (lo llama TunerPanel.setup).
func register_panel(layer: String) -> void:
	_panels[layer.get_slice("@", 0)] = true


## SI ES UN PANEL DE TECLA F: uno anotado, o la copia de uno (`suit@personaje`, ver TunerPanel.ui_copy), que es el mismo
## panel montado en otra fila.
func is_panel(layer: String) -> bool:
	return _panels.has(layer.get_slice("@", 0))


## Si hay algún panel de tecla F abierto.
func any_panel_open() -> bool:
	for layer: String in _open:
		if is_panel(layer):
			return true
	return false

## LA PANTALLA LIMPIA (ver arriba): ocultarla cierra los paneles de tecla F —no se verían y tendrían el mouse—; con
## otro overlay abierto (la pausa, la consola, una terminal) no se oculta.
func hide_screen(hidden: bool) -> void:
	if hidden:
		for layer: String in _open:
			if not is_panel(layer):
				return
		for layer: String in _open.keys():
			_open.erase(layer)
	screen_hidden = hidden
	get_viewport().canvas_cull_mask = 0 if hidden else 0xFFFFFFFF
	_refresh()


func _show_screen() -> void:
	if screen_hidden:
		screen_hidden = false
		get_viewport().canvas_cull_mask = 0xFFFFFFFF


func is_open(layer: String) -> bool:
	return _open.has(layer)

## True cuando no hay ningún overlay abierto: el mouse está capturado y el input de
## gameplay fluye.
func gameplay_active() -> bool:
	return _open.is_empty()

func _refresh() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _open.is_empty() else Input.MOUSE_MODE_VISIBLE
	changed.emit()
