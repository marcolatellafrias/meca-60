class_name TunerPanel
extends CanvasLayer

## EL PANEL DE UN AFINADOR — el marco, el scroll, el botón de copiar y el alta en `UIState`. No sabe qué
## afina: cada afinador hereda de acá y solo escribe `sections()`.
##
## Existe porque hay más de uno (clima y nubes en F6, terreno y afueras en F7) y todo lo que los rodea es
## idéntico. Lo único propio de cada uno es QUÉ objetos toca, y eso es una lista de specs.
##
## Estos paneles SÍ se anotan en `UIState`, a diferencia del mapa de F2: hay que arrastrar sliders y abrir
## selectores de color, y para eso el mouse tiene que estar libre. El juego sigue corriendo detrás, así
## que los cambios se ven en vivo.
##
## Nada se guarda en disco. El botón de copiar escupe cada sección con el archivo donde se pega, y lo que
## funcione se copia a mano.
##
## ── LAS PESTAÑAS SON DE LAS SECCIONES, NO DEL PANEL ─────────────────────────────────────────────
## Una sección puede declarar en qué PESTAÑA vive (`"tab"`), y el panel arma la barra con las que
## aparezcan, en el orden en que aparecen. Si ninguna lo declara no hay barra y se ven todas, que es como
## funcionaban los afinadores antes de que uno creciera.
##
## Existe porque el de torsos llegó a trece secciones y ciento cincuenta sliders: scrollear para encontrar
## la vuelta que uno quiere mover es trabajo, y peor, hace creer que el panel es complicado cuando lo que
## pasa es que son seis temas distintos en una lista. Con pestañas, cada tema es una pantalla.
##
## La pestaña elegida se recuerda POR NOMBRE entre rearmados: cambiar de arquetipo rearma los controles, y
## volver a la primera pestaña cada vez obligaría a buscar de nuevo dónde estaba uno.

const MARGIN := 16.0
const WIDTH := 520.0

## ── DE QUÉ LADO DE LA PANTALLA SE ABRE ──────────────────────────────────────────────────────────
## Por defecto a la derecha, que es donde estaban todos. Lo elige QUIEN LO MONTA y no el panel: en el design
## sandbox el borde derecho ya es del menú de categoría —el que dice qué parcela es y qué teclas tiene—, y
## un afinador encima lo tapa justo cuando uno lo necesita, para leer qué tecla hacía qué. Por eso ese mundo
## monta los suyos a la izquierda (ver DesignSandbox._mount_tuners) y el juego los deja donde estaban.
##
## Se lee en `setup`, así que hay que escribirlo ANTES: después el marco ya está anclado.
##
## ⚠ Constantes y no un `enum`: un enum declarado acá se lee desde afuera como `TunerPanel.Side`, y el tipo
## de esta variable es el `Side` de adentro — para GDScript son dos tipos distintos y no deja asignar uno al
## otro ("Cannot assign a value of type TunerPanel.Side to variable side with specified type Side"), con la
## cascada de "Failed to compile depended scripts" en todo lo que usa la clase.
const SIDE_RIGHT := 0
const SIDE_LEFT := 1

const BACKGROUND := Color(0.0, 0.0, 0.0, 0.85)
## El color de un título, salvo que la sección traiga el suyo. Que pueda traerlo es para que un afinador
## ate un grupo de sliders a algo que se ve en el mundo —el panel de torsos le pone a cada vuelta el color
## con el que la pinta sobre el personaje— y no haya que adivinar cuál mueve cuál.
const TITLE_COLOR := Color(0.6, 0.75, 1.0)
## El color de la etiqueta de estado (ver `state_label`).
const STATE_COLOR := Color(0.75, 0.8, 0.9)

## De qué lado se abre (ver arriba). Lo escribe quien lo monta, antes de `setup`.
var side := SIDE_RIGHT
## EL ANCHO, en píxeles: `WIDTH` salvo que el afinador pida otro, antes de `setup` —uno que se usa mirando de lejos lo
## que afina lo quiere angosto (ver ShipStyleTuner)—.
var panel_width := WIDTH

## ── LOCAL A UNA FILA DEL DESIGN SANDBOX ─────────────────────────────────────────────────────────
## `category` es la fila donde ABRE —vacía, en cualquier lado—: parado en otra fila su tecla no hace nada, y CIERRA
## desde cualquier lado, porque con el panel abierto el mouse es del panel y no se puede caminar de vuelta. Así la
## misma F1 es el torso en Personajes y los anchos de calle en la Maqueta. `menu_label` y `menu_key` son cómo lo anota
## el panel de la parcela (ver SandboxPanel). Lo escribe quien lo monta (ver DesignSandbox._mount_tuners).
var category := ""
var menu_label := ""
var menu_key: Key = KEY_NONE
## El mundo que lo montó —el design sandbox—: de él salen la fila y la parcela donde está parado el jugador. Lo escribe
## quien lo monta; afuera del sandbox queda en null.
var sandbox: Node = null
## ── LOS PERSONAJES DE UN PANEL, UNA SOLA PREGUNTA ────────────────────────────────────────────────────────────────
## Todo panel que busca personajes —el maniquí que edita, los que rearma, los que pinta con quads— los pide acá, y no
## recorriendo el grupo de cápsulas por su cuenta. `characters` son los maniquíes del sandbox (`CharacterKind.figure`).
func characters() -> Array[BoneInstantiator]:
	return display_characters(get_tree())


static func display_characters(tree: SceneTree) -> Array[BoneInstantiator]:
	var out: Array[BoneInstantiator] = []
	for rb in tree.get_nodes_in_group(CharacterRigidBody3D.CHARACTER_GROUP):
		var bi := (rb as Node).get_parent() as BoneInstantiator
		if is_instance_valid(bi) and bi.kind.is_exhibit():
			out.append(bi)
	return out


## SI ESTE PANEL SE ACABA DE CERRAR (en el último cambio de UIState): lo que un panel deshace al cerrarse —apagar sus
## quads, volver a mostrar las partes— lo hace sólo si el que se cerró es él, no cada vez que cambia cualquier otro.
var just_closed := false
var _was_visible := false


## ── LA TECLA F, UNA SOLA VEZ ────────────────────────────────────────────────────────────────────
## `menu_key` ABRE sólo donde `_can_open()` —por defecto, en su fila (ver `serves`)— y CIERRA desde cualquier lado: con
## el panel abierto el mouse es del panel, y exigir volver a la parcela para cerrarlo lo dejaría trabado. Abrir cierra a
## los demás paneles de tecla F (ver `toggle_exclusive`). Lo propio de cada panel al abrirse va en `_opened()`.
##
## Estaba copiado en cada panel —quince veces el mismo `_input`, cada uno con su TOGGLE_KEY—, y cada panel nuevo lo
## volvía a copiar. Sin tecla (los afinadores del juego, que abre PlayerController) no hace nada.
##
## ⚠ F8 NO SE PUEDE USAR: es el atajo de Godot para DETENER el juego, y apretarla cerraba el sandbox en vez de abrir
## el panel.
func _input(event: InputEvent) -> void:
	if menu_key == KEY_NONE:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != menu_key:
		return
	if not visible and not _can_open():
		return
	_press()
	get_viewport().set_input_as_handled()


## Si la tecla puede abrirlo acá. Lo pisa el panel que abre por otra cosa que la fila (ver SoundPanel).
func _can_open() -> bool:
	return serves(sandbox)


## Lo que hace la tecla: abrir este cerrando los demás, o cerrarlo.
func _press() -> void:
	toggle_exclusive()
	if visible:
		_opened()


## Lo que el panel hace cada vez que la tecla lo abre —adoptar la parcela, rearmar lo que cambió—.
func _opened() -> void:
	pass


## Un botón del panel: su texto y qué hace.
static func new_button(text: String, pressed: Callable) -> Button:
	var made := Button.new()
	made.text = text
	made.pressed.connect(pressed)
	return made


## LA ETIQUETA DE ESTADO —qué se está viendo: el defecto, una prueba sin guardar, lo guardado—. Va en `into` o, sin él,
## debajo de los botones de arriba (los `extra` de `setup`, que tiene que haber corrido).
func state_label(into: Node = null) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", STATE_COLOR)
	if into != null:
		into.add_child(label)
	else:
		_copy_button.get_parent().add_child(label)
		_copy_button.get_parent().move_child(label, _copy_button.get_index())
	return label


## Si abre parado donde está el jugador de `world` (ver `category`).
func serves(world: Node) -> bool:
	# EN EL SANDBOX, lo decide él: de parcela, de fila o global (ver DesignSandbox.serves_panel).
	if is_instance_valid(world) and world.has_method("serves_panel"):
		return bool(world.call("serves_panel", self))
	if category.is_empty():
		return true
	return is_instance_valid(world) and world.has_method("current_category") \
		and str(world.call("current_category")) == category

var _ui_key := ""
## LA COPIA DE UN PANEL EN OTRA FILA (22/10/2026): el mismo panel montado dos veces con el mismo estilo —el del traje, en
## la fila Trajes y en las de personajes— necesita otra llave, o abrir uno abre los dos. Se pone antes de montarlo.
var ui_copy := ""
var _box: VBoxContainer = null
var _scroll: ScrollContainer = null
var _copy_button: Button = null
var _tabs: TabBar = null
var _header: VBoxContainer = null
## La pestaña elegida, por nombre. Vacío es "la primera".
var _tab_name := ""
var _built := false


## `extra` son botones propios del afinador —regenerar, por ejemplo—, que van arriba de todo junto al de
## copiar.
func setup(ui_key: String, title_text: String, extra: Array[Button] = []) -> void:
	_ui_key = ui_key if ui_copy.is_empty() else "%s@%s" % [ui_key, ui_copy]
	# UN PANEL A LA VEZ: anotado, abrir otro lo cierra (ver UIState.register_panel).
	UIState.register_panel(_ui_key)
	layer = 95  # debajo del panel de debug (100), encima del mapa (90)
	visible = false
	UIState.changed.connect(_on_ui_changed)

	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10

	var frame := PanelContainer.new()
	frame.anchor_bottom = 1.0
	# EL LADO (ver `side`): pegado a un borde o al otro, con el mismo margen y el mismo ancho.
	if side == SIDE_LEFT:
		frame.offset_left = MARGIN
		frame.offset_right = MARGIN + panel_width
	else:
		frame.anchor_left = 1.0
		frame.anchor_right = 1.0
		frame.offset_left = -(MARGIN + panel_width)
		frame.offset_right = -MARGIN
	frame.offset_top = MARGIN
	frame.offset_bottom = -MARGIN
	frame.add_theme_stylebox_override("panel", style)
	add_child(frame)

	var column := VBoxContainer.new()
	frame.add_child(column)

	var title := Label.new()
	# Con tecla, el título dice cuál lo cierra.
	title.text = title_text if menu_key == KEY_NONE else "%s  (%s cierra)" % [title_text, OS.get_keycode_string(menu_key)]
	title.add_theme_color_override("font_color", TITLE_COLOR)
	column.add_child(title)

	for button in extra:
		button.focus_mode = Control.FOCUS_NONE
		column.add_child(button)

	_copy_button = Button.new()
	_copy_button.text = "Copiar todo al portapapeles"
	_copy_button.focus_mode = Control.FOCUS_NONE
	_copy_button.pressed.connect(_copy)
	column.add_child(_copy_button)

	# LA BARRA DE PESTAÑAS va ARRIBA DEL SCROLL y no adentro: es la navegación del panel, así que tiene que
	# quedarse quieta mientras se scrollea lo que muestra. Nace escondida; la prende `rebuild` si alguna
	# sección declara pestaña.
	# LA CABECERA (ver `header`): arriba de la barra de pestañas, quieta como ella.
	_header = VBoxContainer.new()
	column.add_child(_header)
	_tabs = TabBar.new()
	_tabs.visible = false
	_tabs.focus_mode = Control.FOCUS_NONE
	_tabs.tab_changed.connect(_on_tab_changed)
	column.add_child(_tabs)

	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_box)


func toggle() -> void:
	UIState.toggle(_ui_key)


## ABRE ESTE Y CIERRA A LOS DEMÁS PANELES DE TECLA F (ver UIState.open_only). Es lo que usan los afinadores
## del sandbox, donde las teclas F son todas de paneles como estos: así una tecla F siempre hace lo que uno
## espera —mostrar SU panel— en vez de no hacer nada porque había otro abierto.
func toggle_exclusive() -> void:
	if visible:
		UIState.close(_ui_key)
	else:
		UIState.open_only(_ui_key)


## Qué afina este panel: una lista de specs de `PropertyTuner`, cada uno con un `title` que dice en qué
## archivo se pegan sus valores. Lo escribe cada afinador.
func sections() -> Array[Dictionary]:
	return []


## ── LA CABECERA (07/11/2026, el dios del juego: en el de locomoción, «el arquetipo… como tabs» y arriba «un slider de
## suavizado… única de todos los arquetipos») ─────────────────────────────────────────────────────────────────────────
## Controles que van ARRIBA de la barra de pestañas y no adentro del scroll: lo que vale para todas las pestañas —qué
## se está editando, una perilla de todos— y tiene que quedarse a la vista. Se rearma con `rebuild`, así que cada
## llamada devuelve instancias nuevas. Por defecto, nada.
func header() -> Array[Control]:
	return []


func _on_ui_changed() -> void:
	visible = UIState.is_open(_ui_key)
	just_closed = _was_visible and not visible
	_was_visible = visible
	# Se arma la primera vez que se abre, no al spawnear: los controles nacen con el valor que el mundo
	# tiene en ese momento, y un panel que casi nunca se abre no cuesta nada.
	if visible and not _built:
		rebuild()


## REARMA LOS CONTROLES desde cero. La mayoría de los afinadores no lo necesitan —sus objetos son los
## mismos toda la sesión— pero el de torsos cambia de ARQUETIPO, o sea de objeto, y entonces los
## controles viejos apuntan a la forma de otro.
##
## Los hijos se liberan en el acto y no con `queue_free`: si no, los viejos siguen un cuadro más y el
## panel se ve con los controles duplicados. Solo se llama desde un botón o al abrirse, nunca desde el
## `value_changed` de un slider — ahí estaría liberando a quien está emitiendo.
func rebuild() -> void:
	if _box == null:
		return
	_built = true
	# La cabecera, de nuevo (ver `header`): los viejos salen del árbol en el acto y se liberan al final del cuadro, por
	# lo mismo que en `_fill`.
	for child in _header.get_children():
		_header.remove_child(child)
		child.queue_free()
	for control: Control in header():
		_header.add_child(control)
	var all := sections()
	var names := PackedStringArray()
	for section in all:
		var tab := _tab_of(section)
		if not tab.is_empty() and not names.has(tab):
			names.append(tab)
	_tabs.visible = not names.is_empty()
	# La barra se rearma entera y la elegida se busca POR NOMBRE: un arquetipo puede tener otras secciones.
	var wanted := _tab_name
	_tabs.set_block_signals(true)
	_tabs.clear_tabs()
	for n in names:
		_tabs.add_tab(n)
	if not names.is_empty():
		var at: int = maxi(0, names.find(wanted))
		_tabs.current_tab = at
		_tab_name = names[at]
	_tabs.set_block_signals(false)
	_fill(all)


func _on_tab_changed(at: int) -> void:
	_tab_name = _tabs.get_tab_title(at)
	_fill(sections())


## LA PESTAÑA DE UNA SECCIÓN (`"tab"`), o ninguna.
static func _tab_of(section: Dictionary) -> String:
	return str(section.get("tab", ""))


## Dibuja las secciones de la pestaña elegida —todas, si no hay pestañas—. Los hijos viejos SALEN DEL ÁRBOL en el
## acto, así el panel no se ve duplicado ni un cuadro, y se liberan al final del cuadro (`queue_free`).
##
## ⚠ NO SE LIBERAN EN EL ACTO, porque rearmar se llama desde un botón del mismo panel: el botón que se apretó es uno de
## los hijos, y liberarlo mientras emite su señal tira «Attempted to free a locked object (calling or emitting)» y se
## lleva el juego. Pasó en el F4 de los canónicos al elegir una forma de cabeza (16/10/2026), y le podía pasar a
## cualquier panel con un botón que rearma.
func _fill(all: Array[Dictionary]) -> void:
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	for section in all:
		var tab := _tab_of(section)
		if _tabs.visible and not tab.is_empty() and tab != _tab_name:
			continue
		var title := Label.new()
		title.text = str(section["title"])
		title.add_theme_color_override("font_color", section.get("color", TITLE_COLOR) as Color)
		# Un título largo se parte en renglones en vez de estirar el panel.
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_box.add_child(title)
		# LOS BOTONES DE UNA SECCIÓN: lo que esa sección necesita y no es un número — prender la caminata
		# para poder mirarla, por ejemplo. Se crean en `sections()` y los libera el panel, así que cada
		# llamada tiene que devolver instancias nuevas.
		for button: Button in section.get("extra", [] as Array[Button]):
			button.focus_mode = Control.FOCUS_NONE
			_box.add_child(button)
		# LOS CONTROLES PROPIOS de una sección —las filas de toggles de un menú, ver ToggleRow—, que tampoco son un
		# número. Igual que los botones: instancias nuevas en cada llamada a `sections()`.
		for control: Control in section.get("controls", [] as Array[Control]):
			_box.add_child(control)
		# UNA SECCIÓN SIN OBJETO —sólo toggles— no tiene propiedades que leer.
		if section.has("target"):
			PropertyTuner.build(_box, section)
		# ── VARIOS OBJETOS BAJO UN SOLO TÍTULO (07/11/2026, el dios del juego: «se separaron en dos subcategorías
		# separadas, aunque tiene el mismo título… que eso no sea posible por diseño»): `blocks`, una lista de specs de
		# PropertyTuner que van uno debajo del otro, cada uno con su renglón chico (`caption`) que dice de quién es. Así un
		# tema que vive en dos objetos —lo de un arquetipo y lo de todos— es UNA sección, no dos con el mismo nombre.
		for block: Dictionary in section.get("blocks", [] as Array[Dictionary]):
			if block.has("caption"):
				var caption := Label.new()
				caption.text = str(block["caption"])
				caption.add_theme_color_override("font_color", PropertyTuner.GROUP_COLOR)
				caption.add_theme_font_size_override("font_size", PropertyTuner.HELP_FONT_SIZE + 1)
				_box.add_child(caption)
			PropertyTuner.build(_box, block)
		_box.add_child(HSeparator.new())


## El estado entero como texto pegable, sección por sección, con el archivo de destino de cada una.
func _copy() -> void:
	var blocks := PackedStringArray()
	for section in sections():
		# La de sólo botones dice ella misma qué copiar (`dump`); la de varios objetos, cada uno (`blocks`).
		if section.has("blocks"):
			for block: Dictionary in section["blocks"]:
				blocks.append("# %s — %s\n%s" % [section["title"], block.get("caption", ""), PropertyTuner.dump(block)])
			continue
		if not section.has("target") and not section.has("dump"):
			continue
		var text: String = (section["dump"] as Callable).call() if section.has("dump") else PropertyTuner.dump(section)
		blocks.append("# %s\n%s" % [section["title"], text])
	DisplayServer.clipboard_set("\n\n".join(blocks))
	_copy_button.text = "Copiado ✓"
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(_copy_button):
		_copy_button.text = "Copiar todo al portapapeles"
