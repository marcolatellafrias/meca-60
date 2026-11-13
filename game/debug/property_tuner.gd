class_name PropertyTuner
extends RefCounted

## ARMA UN AFINADOR LEYENDO LAS PROPIEDADES EXPORTADAS DE UN OBJETO. No sabe de clima ni de nubes: le
## pasas un objeto con `@export`s y te devuelve un control por propiedad, ya conectado.
##
## Existe para que no pueda volver a pasar lo que pasaba antes: los controles se escribian a mano, uno
## por uno, y varios quedaron apuntando a campos que ya no se aplicaban —perillas que no hacian nada—.
## Aca no hay lista a mano: lo que se ve es lo que el objeto expone, y lo que se toca es lo que se aplica.
##
## Todo entra por un `spec`, un Diccionario con:
##   target     el objeto a afinar
##   include    nombres de grupo a mostrar; vacio muestra todo. Filtra por el grupo mas interno: si la
##              propiedad esta en un subgrupo manda el subgrupo, si no manda el grupo.
##   skip       nombres de propiedad que maneja el juego y no la mano
##   ranges     nombre de propiedad -> [min, max] que reemplaza al declarado, SOLO para el slider: el
##              valor guardado no se toca. Es para cuando el `@export_range` de un addon es honesto
##              para su escala y absurdo para la nuestra
##   labels     nombre de propiedad -> como se lo llama en el panel; el que no esta se muestra con su
##              nombre de codigo. Es SOLO la etiqueta: `dump()` sigue escupiendo el nombre real, que
##              es el que se pega en el archivo
##   as_index   nombre de propiedad -> EN CUANTOS PASOS se divide su tramo. La propiedad sigue siendo una
##              fraccion de 0 a 1, pero lo que elige es un ANILLO, que es un entero: el slider se mueve de
##              anillo en anillo y la etiqueta dice "7 / 16" en vez de 0,438. Un slider continuo sobre algo
##              que la malla redondea igual es una perilla que miente — se arrastra y no pasa nada hasta
##              que cruza el medio de un paso (ver GridPart._snapped)
##   help       nombre de propiedad -> una linea de que hace, que se dibuja debajo del control
##   colors     nombre de propiedad -> el color de su nombre y de su ayuda, para agrupar de un vistazo (subiendo y
##              cayendo, en el aire; las partes del cuerpo, ver LocomotionTuner). Con `code_defaults`, el número que
##              todavía es el del código va del mismo color apagado, y el que alguien movió, entero
##   marks      nombre de propiedad -> un símbolo en blanco a la derecha de su nombre (ver LocomotionTuner, QUÉ USA CADA PERILLA)
##   tooltips   nombre de propiedad -> lo que dice al pasar el mouse por su nombre y por su símbolo
##   headers    false: sin los renglones «── grupo» (una sección que ya dice de qué es, armada con `only`)
##   defaults   UN OBJETO DEL MISMO TIPO con los valores a los que vuelve el boton de cada fila. Es la
##              LINEA DE BASE del afinador —lo que el panel adopto al abrirse— y no el default de la
##              clase: el ancho con el que nace un `BodyLoop` es 0,30 m, que no es el ancho que ese
##              hombro tendria que tener. Sin esto, el boton usa el valor con el que nace el tipo, y si
##              tampoco se puede averiguar, no hay boton.
##   on_change  se llama despues de cada escritura; puede ser vacia si el objeto se relee solo
##   name_width el ancho de la columna de nombres, si no es `NAME_WIDTH`; con uno propio, un nombre largo se parte en
##              renglones (un panel angosto, ver ShipStyleTuner)
##
## `dump()` usa el mismo spec, asi lo que se copia al portapapeles no puede desincronizarse de lo que se
## ve. El formato es `nombre = valor` de GDScript, que tambien es el de un `.tres`: se pega tal cual en
## el archivo de donde salio.

## ── EL COLOR DE UNA FILA QUE TODAVÍA NO TOCÓ NADIE ──────────────────────────────────────────────
## Gris apagado para el número que vale lo que el CÓDIGO dice, y el color normal para el que alguien movió.
##
## Para qué: guardar un arquetipo escribe TODO lo que el panel edita, así que después no hay forma de saber
## si un número está ahí porque se lo eligió o porque venía puesto. Con esto se ve de un vistazo cuánto de
## lo que uno está mirando es autoría propia — que es la pregunta que uno se hace justo antes de guardar.
##
## Se compara contra el defecto DEL CÓDIGO y no contra lo guardado (que es a donde vuelve el botón ⟲): son
## dos preguntas distintas, y la de "¿esto lo decidí yo?" se contesta contra el código.
const DEFAULT_COLOR := Color(0.45, 0.47, 0.52)
const AUTHORED_COLOR := Color(0.86, 0.88, 0.92)

const GROUP_COLOR := Color(0.55, 0.55, 0.55)
const HELP_COLOR := Color(0.62, 0.66, 0.72)
const HELP_FONT_SIZE := 11
const NAME_WIDTH := 200.0

## Un slider lineal sobre un rango de 100 a 1.000.000 es inusable: toda la banda que sirve a escala de
## ciudad vive en el primer medio por ciento del recorrido. Cuando el rango llega a cuatro cifras Y
## abarca dos ordenes de magnitud o mas, el slider guarda un `t` de 0 a 1 y el valor se mapea con una
## curva. El archivo sigue guardando el numero real: la curva es solo como se lo agarra.
const CURVED_MIN_MAX := 1000.0
const CURVED_RATIO := 100.0

## Los unicos tipos que saben afinarse a mano. Todo lo demas que un objeto exporte —texturas, shaders,
## arrays, vectores— se ignora, que es lo que deja que `include` sea generoso sin llenar el panel.
const TUNABLE := [TYPE_BOOL, TYPE_COLOR, TYPE_FLOAT, TYPE_INT]
## LOS TEXTOS, sólo donde una sección los pide (`spec["strings"]`): un campo para escribir. Opt-in y no en `TUNABLE`
## porque los otros afinadores exportan textos que no son para tocar a mano, y aparecerían de golpe.


## La marca de la fila de un color: el selector y el campo del hex (ver `_control`).
const COLOR_ROW := "color_row"
## EL CAMPO DEL NÚMERO de un slider, guardado en el slider (ver `_number_field`).
const NUMBER_FIELD := "number_field"


## ── UNA VUELTA QUE NO MANDA SE PLIEGA (22/10/2026, lo pidió el usuario) ─────────────────────────────────────────
## Si el objeto tiene el interruptor `active` (una vuelta, un loop cut, ver BodyLoop.active) y está apagado, se muestra
## sólo el interruptor: sus números no hacen nada y ocupaban lugar. Prenderlo o apagarlo rearma su sección en el lugar.
const ACTIVE := "active"
## La marca de la caja propia de una sección así (ver `build`): sus filas van adentro.
const SECTION_BOX := "section_box"


## Un control por propiedad, dentro de `box`.
static func build(box: VBoxContainer, spec: Dictionary) -> void:
	if not _has_toggle(spec):
		_build_rows(box, spec)
		return
	var own := VBoxContainer.new()
	own.set_meta(SECTION_BOX, true)
	own.add_theme_constant_override("separation", box.get_theme_constant("separation"))
	box.add_child(own)
	_build_toggled(own, spec)


## Si la sección muestra su interruptor: `active`, u otro que diga la sección (`toggle`: varias secciones que son campos
## de un mismo objeto).
static func _has_toggle(spec: Dictionary) -> bool:
	for prop in _properties(spec):
		if str(prop["name"]) == _toggle_of(spec) and int(prop["type"]) == TYPE_BOOL:
			return true
	return false


static func _toggle_of(spec: Dictionary) -> String:
	return str(spec.get("toggle", ACTIVE))


## Arma la sección en su propia caja, y cuando el interruptor cambia, la rearma (después del cuadro: el control que se
## está tocando es de esa caja).
static func _build_toggled(own: VBoxContainer, spec: Dictionary) -> void:
	var target: Object = spec["target"]
	var on_change: Callable = spec.get("on_change", Callable())
	var was := bool(target.get(_toggle_of(spec)))
	var watched := spec.duplicate()
	watched["on_change"] = func() -> void:
		if on_change.is_valid():
			on_change.call()
		if bool(target.get(_toggle_of(spec))) != was and is_instance_valid(own):
			(func() -> void:
				if not is_instance_valid(own):
					return
				for child in own.get_children():
					own.remove_child(child)
					child.queue_free()
				_build_toggled(own, spec)).call_deferred()
	_build_rows(own, watched, true)


static func _build_rows(box: VBoxContainer, spec: Dictionary, fold := false) -> void:
	var target: Object = spec["target"]
	var help: Dictionary = spec.get("help", {})
	var labels: Dictionary = spec.get("labels", {})
	var on_change: Callable = spec.get("on_change", Callable())
	var group := ""
	for prop in _properties(spec, fold):
		var section := str(prop["group"])
		if section != group and spec.get("headers", true):
			group = section
			var header := Label.new()
			header.text = "── " + group
			header.add_theme_color_override("font_color", GROUP_COLOR)
			box.add_child(header)

		var prop_name := str(prop["name"])
		var label := Label.new()
		label.text = str(labels.get(prop_name, prop_name))
		var colors: Dictionary = spec.get("colors", {})
		if colors.has(prop_name):
			label.add_theme_color_override("font_color", colors[prop_name] as Color)
		var tooltips: Dictionary = spec.get("tooltips", {})
		if tooltips.has(prop_name):
			label.tooltip_text = str(tooltips[prop_name])
			label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.custom_minimum_size = Vector2(float(spec.get("name_width", NAME_WIDTH)), 0.0)
		if spec.has("name_width"):
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var row := HBoxContainer.new()
		row.add_child(label)
		var marks: Dictionary = spec.get("marks", {})
		if marks.has(prop_name):
			var mark := Label.new()
			mark.text = str(marks[prop_name])
			mark.add_theme_color_override("font_color", Color.WHITE)
			mark.tooltip_text = label.tooltip_text
			mark.mouse_filter = Control.MOUSE_FILTER_PASS
			row.add_child(mark)
		# EL TINTE SE REPINTA EN CADA CAMBIO, y por eso se mete en el `on_change` de ESTA fila: así vale
		# para los seis tipos de control sin tocar ninguno —todos pasan por `_write`— y el gris se va en el
		# mismo cuadro en que uno arrastra el slider, no en el próximo rearmado del panel.
		var row_spec := spec.duplicate()
		row_spec["on_change"] = func() -> void:
			_tint(label, spec, prop)
			if on_change.is_valid():
				on_change.call()
		var control := _control(row_spec, prop, label)
		_tint(label, spec, prop)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var revert := _revert_button(row_spec, prop, control, label)
		# ── UN SLIDER VA EN SU PROPIO RENGLÓN, A TODO EL ANCHO (lo pidió el usuario, 20/10/2026: al lado del nombre
		# quedaban muy angostos para manejarlos): arriba el nombre y el botón de volver, abajo el slider y su número.
		if control is HSlider:
			label.custom_minimum_size = Vector2.ZERO
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if revert != null:
				row.add_child(revert)
			var under := HBoxContainer.new()
			under.add_child(control)
			if control.has_meta(NUMBER_FIELD):
				under.add_child(control.get_meta(NUMBER_FIELD) as LineEdit)
			var both := VBoxContainer.new()
			both.add_theme_constant_override("separation", 0)
			both.add_child(row)
			both.add_child(under)
			box.add_child(both)
		else:
			row.add_child(control)
			if revert != null:
				row.add_child(revert)
			box.add_child(row)

		if help.has(prop_name):
			var note := Label.new()
			note.text = str(help[prop_name])
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			# DEL COLOR DE SU FILA, más apagado (ver `colors`).
			var tone: Color = (spec.get("colors", {}) as Dictionary).get(prop_name, HELP_COLOR)
			note.add_theme_color_override("font_color", tone.lerp(HELP_COLOR, 0.45))
			note.add_theme_font_size_override("font_size", HELP_FONT_SIZE)
			box.add_child(note)


## Las mismas propiedades como texto pegable.
static func dump(spec: Dictionary) -> String:
	var target: Object = spec["target"]
	var lines := PackedStringArray()
	for prop in _properties(spec):
		lines.append("%s = %s" % [prop["name"], var_to_str(target.get(prop["name"]))])
	return "\n".join(lines)


# ── Lectura de la lista de propiedades ───────────────────────────────────────────────────────────

## Las propiedades exportadas que pasan el filtro, cada una con el grupo en el que cayo. El grupo se
## arrastra de los marcadores que Godot intercala en la lista; un grupo nuevo borra el subgrupo.
static func _properties(spec: Dictionary, fold := false) -> Array[Dictionary]:
	var target: Object = spec["target"]
	var include: PackedStringArray = spec.get("include", PackedStringArray())
	var skip: PackedStringArray = spec.get("skip", PackedStringArray())
	var out: Array[Dictionary] = []
	var group := ""
	var subgroup := ""
	for prop in target.get_property_list():
		var usage: int = prop["usage"]
		if usage & PROPERTY_USAGE_GROUP:
			group = str(prop["name"])
			subgroup = ""
			continue
		if usage & PROPERTY_USAGE_SUBGROUP:
			subgroup = str(prop["name"])
			continue
		if not (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or not (usage & PROPERTY_USAGE_EDITOR):
			continue
		var section := subgroup if not subgroup.is_empty() else group
		if not include.is_empty() and not include.has(section):
			continue
		if skip.has(str(prop["name"])):
			continue
		# `only`: estas propiedades y ninguna otra, en el orden de la lista —para armar secciones por tema con lo que el
		# objeto tiene repartido en otros grupos—.
		if spec.has("only") and not (spec["only"] as PackedStringArray).has(str(prop["name"])):
			continue
		# Los tipos que no se afinan a mano (texturas, shaders, arrays, vectores) se caen ACA y no en el
		# armado de controles, para que `build` y `dump` vean exactamente la misma lista: si no, el boton
		# de copiar escupe cosas que el panel no muestra y que no se pegan en ningun lado.
		if not TUNABLE.has(int(prop["type"])) and not (int(prop["type"]) == TYPE_STRING and spec.get("strings", false)):
			continue
		out.append({"name": prop["name"], "type": prop["type"], "hint": prop["hint"],
			"hint_string": prop["hint_string"], "group": section})
	# APAGADA, SÓLO SU INTERRUPTOR (ver `ACTIVE`).
	if fold and not bool(target.get(_toggle_of(spec))):
		var only_toggle: Array[Dictionary] = []
		for prop in out:
			if str(prop["name"]) == _toggle_of(spec):
				only_toggle.append(prop)
		if not only_toggle.is_empty():
			return only_toggle
	return out


# ── Armado de controles ──────────────────────────────────────────────────────────────────────────

## El control que le corresponde al tipo (`_properties` ya garantizo que es uno de `TUNABLE`). `label`
## muestra el valor vivo al lado del nombre.
static func _control(spec: Dictionary, prop: Dictionary, label: Label) -> Control:
	var target: Object = spec["target"]
	var on_change: Callable = spec.get("on_change", Callable())
	var prop_name := str(prop["name"])
	var shown := str(spec.get("labels", {}).get(prop_name, prop_name))
	var type := int(prop["type"])
	if type == TYPE_STRING:
		var field := LineEdit.new()
		field.text = str(target.get(prop_name))
		field.text_changed.connect(func(text: String) -> void: _write(target, prop_name, text, on_change))
		return field
	if type == TYPE_BOOL:
		var check := CheckButton.new()
		check.button_pressed = bool(target.get(prop_name))
		check.focus_mode = Control.FOCUS_NONE
		check.toggled.connect(func(on: bool) -> void: _write(target, prop_name, on, on_change))
		return check
	if type == TYPE_COLOR:
		# EL SELECTOR Y UN CAMPO PARA PEGAR EL COLOR (lo pidió el usuario, 16/10/2026): «#c8a080», «c8a080» o
		# «200, 160, 128» (o de 0 a 1). Mover el selector escribe el hex en el campo.
		var row := HBoxContainer.new()
		row.set_meta(COLOR_ROW, true)
		var picker := ColorPickerButton.new()
		picker.custom_minimum_size = Vector2(0.0, 24.0)
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.color = target.get(prop_name)
		var hex := LineEdit.new()
		hex.custom_minimum_size = Vector2(96.0, 0.0)
		hex.placeholder_text = "#hex o r, g, b"
		hex.text = "#" + picker.color.to_html(false)
		picker.color_changed.connect(func(c: Color) -> void:
			hex.text = "#" + c.to_html(false)
			_write(target, prop_name, c, on_change))
		hex.text_submitted.connect(func(text: String) -> void:
			var parsed: Variant = parse_color(text)
			if parsed is Color:
				picker.color = parsed
				hex.text = "#" + (parsed as Color).to_html(false)
				_write(target, prop_name, parsed, on_change))
		row.add_child(picker)
		row.add_child(hex)
		return row
	if int(prop["hint"]) == PROPERTY_HINT_ENUM:
		var options := OptionButton.new()
		# Un enum tipado llega como "NOMBRE:valor,..."; se muestra el nombre.
		for item in str(prop["hint_string"]).split(","):
			options.add_item(item.get_slice(":", 0))
		options.selected = int(target.get(prop_name))
		options.item_selected.connect(func(i: int) -> void: _write(target, prop_name, i, on_change))
		return options

	# Sin rango declarado va un campo con flechas: inventarle un maximo a algo como `cloud_ceiling`
	# seria mentir, y un slider necesita dos extremos.
	var limits := _range(prop, spec)
	if limits.is_empty():
		var spin := SpinBox.new()
		spin.min_value = -1000000.0
		spin.max_value = 1000000.0
		spin.step = 1.0 if type == TYPE_INT else 0.001
		spin.value = float(target.get(prop_name))
		spin.value_changed.connect(func(v: float) -> void: _write(target, prop_name, v, on_change))
		return spin

	var low := limits[0]
	var high := limits[1]
	var value := float(target.get(prop_name))
	var slider := HSlider.new()
	if _is_curved(low, high):
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.001
		slider.value = _to_t(value, low, high)
		label.text = _value_text(spec, prop, value)
		var curved_field := _number_field(spec, prop, slider, label, value)
		slider.value_changed.connect(func(t: float) -> void:
			var mapped := _bounded(spec, prop_name, _from_t(t, low, high))
			slider.set_value_no_signal(_to_t(mapped, low, high))
			label.text = _value_text(spec, prop, mapped)
			curved_field.text = _number_text(spec, prop, mapped)
			_write(target, prop_name, mapped, on_change))
		return slider
	slider.min_value = low
	slider.max_value = high
	slider.step = limits[2]
	slider.value = value
	label.text = _value_text(spec, prop, value)
	var field := _number_field(spec, prop, slider, label, value)
	slider.value_changed.connect(func(v: float) -> void:
		var held := _bounded(spec, prop_name, v)
		if not is_equal_approx(held, v):
			slider.set_value_no_signal(held)
		label.text = _value_text(spec, prop, held)
		field.text = _number_text(spec, prop, held)
		_write(target, prop_name, held, on_change))
	return slider


## ── LOS TOPES QUE DEPENDEN DE OTROS NÚMEROS ───────────────────────────────────────────────────────
## `spec["bounds"]`, si está, es `func(nombre) -> Vector2 o null`: entre qué valores puede estar esa propiedad AHORA,
## con las demás como están —la altura de una vuelta de un miembro, entre sus dos vecinas (ver TorsoTuner)—. El
## slider frena ahí y lo escrito a mano también. Se pregunta en cada movimiento, así que nunca queda viejo.
static func _bounded(spec: Dictionary, prop_name: String, value: float) -> float:
	var bounds: Callable = spec.get("bounds", Callable())
	if not bounds.is_valid():
		return value
	var limits: Variant = bounds.call(prop_name)
	return clampf(value, (limits as Vector2).x, (limits as Vector2).y) if limits is Vector2 else value


## ── EL NÚMERO, ESCRITO A MANO ────────────────────────────────────────────────────────────────────
## Lo pidió el usuario (20/10/2026): al lado de cada slider, un campo con su número para escribirlo, copiarlo y
## pegarlo (Ctrl+C, Ctrl+V). Al dar Enter o salir del campo se escribe EXACTO —como el botón de volver, ver `_restore`—,
## dentro del rango del slider y de sus topes; uno que no se lee como número vuelve a lo que había.
static func _number_field(spec: Dictionary, prop: Dictionary, slider: HSlider, label: Label,
		value: float) -> LineEdit:
	var field := LineEdit.new()
	field.custom_minimum_size = Vector2(64.0, 0.0)
	field.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	field.text = _number_text(spec, prop, value)
	field.select_all_on_focus = true
	var commit := func() -> void:
		var target: Object = spec["target"]
		var prop_name := str(prop["name"])
		var typed := field.text.strip_edges().replace(",", ".")
		if not typed.is_valid_float():
			field.text = _number_text(spec, prop, float(target.get(prop_name)))
			return
		var number := typed.to_float()
		var count := steps_of(spec, prop_name)
		if count > 0:
			number /= float(count)
		var limits := _range(prop, spec)
		number = _bounded(spec, prop_name, clampf(number, limits[0], limits[1]))
		# Salir del campo sin cambiar nada no rearma a nadie.
		if is_equal_approx(number, float(target.get(prop_name))):
			field.text = _number_text(spec, prop, number)
			return
		_restore(spec, prop, slider, label, number)
		field.release_focus()
	field.text_submitted.connect(func(_text: String) -> void: commit.call())
	field.focus_exited.connect(func() -> void: commit.call())
	slider.set_meta(NUMBER_FIELD, field)
	return field


## EL NÚMERO SOLO, como va en el campo: en anillos si el tramo se cuenta en anillos (ver `as_index`).
static func _number_text(spec: Dictionary, prop: Dictionary, value: float) -> String:
	var count := steps_of(spec, str(prop["name"]))
	if count > 0:
		return str(roundi(value * float(count)))
	var limits := _range(prop, spec)
	if limits.size() >= 2 and _is_curved(limits[0], limits[1]):
		return "%.1f" % value
	return "%.3f" % value


## EL NOMBRE Y EL VALOR de una fila, que es lo que dice la etiqueta. Esta en un solo lugar porque lo
## escriben dos: el slider mientras se arrastra y el boton de volver.
static func _value_text(spec: Dictionary, prop: Dictionary, value: float) -> String:
	var prop_name := str(prop["name"])
	var shown := str(spec.get("labels", {}).get(prop_name, prop_name))
	# LO QUE SIGNIFICA EL NÚMERO, al lado (lo pidió el usuario, 07/11/2026: «altura de piso en celdas debería tener una
	# label de cuánto sería eso en metros»): `readouts` del spec, {propiedad: Callable(valor) -> String}. Se reescribe con el
	# número, mientras se arrastra.
	var readout: Callable = (spec.get("readouts", {}) as Dictionary).get(prop_name, Callable())
	if readout.is_valid():
		shown = "%s  (%s)" % [shown, str(readout.call(value))]
	# UN TRAMO CONTADO EN ANILLOS SE LEE COMO ENTERO: "7 / 16" dice algo, 0,438 no dice nada.
	var count := steps_of(spec, prop_name)
	if count > 0:
		return "%s  %d / %d" % [shown, roundi(value * float(count)), count]
	var limits := _range(prop, spec)
	if limits.size() >= 2 and _is_curved(limits[0], limits[1]):
		return "%s  %.1f" % [shown, value]
	return "%s  %.3f" % [shown, value]


## ── VOLVER UN NUMERO A SU LUGAR ──────────────────────────────────────────────────────────────────
## Un boton por fila, al lado del control. Existe porque afinar es probar: se arrastra un slider a ver que
## pasa, no gusta, y volverlo a donde estaba a ojo es imposible —un slider no tiene marcas y el paso es de
## milimetros—. Con el boton, probar no cuesta nada.
##
## A QUE VALOR VUELVE: al de `defaults` si la seccion trae uno (la linea de base del afinador, ver arriba),
## y si no, al valor con el que NACE el tipo —que para un arqueo o una inclinacion es cero, porque su
## neutro es cero—. El numero esta en el tooltip: un boton que no dice adonde lleva da miedo apretarlo.
static func _revert_button(spec: Dictionary, prop: Dictionary, control: Control,
		label: Label) -> Button:
	var target: Object = spec["target"]
	var prop_name := str(prop["name"])
	var to: Variant = _default_of(spec, target, prop_name)
	if to == null:
		return null
	var button := Button.new()
	button.text = "↺"
	button.tooltip_text = "volver a %s" % str(to)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: _restore(spec, prop, control, label, to))
	return button


## El valor al que vuelve una propiedad, o null si no se puede saber.
##
## El segundo camino —instanciar el tipo y preguntarle— vale solo para recursos y objetos sueltos: el
## target de los otros afinadores es un NODO del mundo (el cielo, el terreno), y uno nuevo no se crea para
## leerle un default. La instancia se guarda: es una por script, no una por fila.
static var _fresh: Dictionary = {}

static func _default_of(spec: Dictionary, target: Object, prop_name: String) -> Variant:
	var defaults: Object = spec.get("defaults", null) as Object
	if defaults != null:
		return defaults.get(prop_name)
	var script := target.get_script() as GDScript
	if script == null or not script.can_instantiate():
		return null
	var base := script.get_instance_base_type()
	if base != "Resource" and base != "RefCounted":
		return null
	var key := script.resource_path
	if not _fresh.has(key):
		_fresh[key] = script.new()
	return (_fresh[key] as Object).get(prop_name)


## Devuelve el valor EXACTO a la propiedad, y acomoda el control para que lo muestre.
##
## ⚠ EL VALOR SE ESCRIBE A MANO Y NO A TRAVES DEL SLIDER, y es la unica forma correcta: un slider REDONDEA
## AL PASO, y las lineas de base no caen en la grilla del paso —el ancho de cadera de un arquetipo son
## 0,258 m y el paso es de 5 mm—. Pasando por el slider, "volver" dejaba la cadera en 0,260: apretar el
## boton y guardar le cambiaba 2 mm al arquetipo. Ahora el dato es exacto y lo redondeado es la POSICION
## de la perilla, que es lo mismo que pasa mientras uno arrastra; la etiqueta dice el valor de verdad.
static func _restore(spec: Dictionary, prop: Dictionary, control: Control, label: Label,
		to: Variant) -> void:
	var target: Object = spec["target"]
	var prop_name := str(prop["name"])
	var on_change: Callable = spec.get("on_change", Callable())
	if control is LineEdit:
		(control as LineEdit).text = str(to)
	elif control is CheckButton:
		(control as CheckButton).set_pressed_no_signal(bool(to))
	elif control is ColorPickerButton:
		(control as ColorPickerButton).color = to
	elif control.has_meta(COLOR_ROW):
		(control.get_child(0) as ColorPickerButton).color = to
		(control.get_child(1) as LineEdit).text = "#" + (to as Color).to_html(false)
	elif control is OptionButton:
		(control as OptionButton).selected = int(to)
	elif control is SpinBox:
		(control as SpinBox).set_value_no_signal(float(to))
	elif control is HSlider:
		var slider := control as HSlider
		var limits := _range(prop, spec)
		var curved: bool = limits.size() >= 2 and _is_curved(limits[0], limits[1])
		slider.set_value_no_signal(_to_t(float(to), limits[0], limits[1]) if curved
			else float(to))
		label.text = _value_text(spec, prop, float(to))
		if slider.has_meta(NUMBER_FIELD):
			(slider.get_meta(NUMBER_FIELD) as LineEdit).text = _number_text(spec, prop, float(to))
	_write(target, prop_name, to, on_change)


## `[min, max, step]` de un `@export_range`, o vacio si no lo tiene. `spec["ranges"]` puede reemplazar los
## dos extremos: un slider esta limitado por sus PIXELES, no por su paso, asi que un rango diez veces mas
## grande que la banda util no se arregla afinando el step. Y `spec["as_index"]` pisa el PASO: si el tramo
## se cuenta en anillos, el paso es un anillo.
##
## Cuando el rango no declara paso —y el addon de nubes no lo declara NUNCA— hay que inventarle uno, y
## el obvio, un doscientosavo del rango, miente: `clouds_density` va de 0 a 20, asi que el paso daba 0,1
## y el valor mas chico que se podia poner era exactamente 0,1, con toda la banda translucida de abajo
## fuera de alcance. Va un paso fino, y de que igual se lea se encarga el numero al lado del slider.
static func _range(prop: Dictionary, spec: Dictionary) -> PackedFloat64Array:
	if int(prop["hint"]) != PROPERTY_HINT_RANGE:
		return PackedFloat64Array()
	var parts := str(prop["hint_string"]).split(",")
	if parts.size() < 2:
		return PackedFloat64Array()
	var low := float(parts[0])
	var high := float(parts[1])
	var ranges: Dictionary = spec.get("ranges", {})
	if ranges.has(str(prop["name"])):
		var override: Array = ranges[str(prop["name"])]
		low = float(override[0])
		high = float(override[1])
	var fine := 1.0 if int(prop["type"]) == TYPE_INT else 0.001
	var step := float(parts[2]) if parts.size() > 2 else fine
	var count := steps_of(spec, str(prop["name"]))
	if count > 0:
		step = 1.0 / float(count)
	return PackedFloat64Array([low, high, step])


## EN CUANTOS PASOS se cuenta esta propiedad, o 0 si es continua (ver `as_index`). El tramo contado es
## SIEMPRE el 0..1, no el rango declarado: el `at` de una vuelta puede pasarse de los dos extremos —asi
## arranca una parte adentro de su vecina— y el anillo 0 sigue siendo el 0.
static func steps_of(spec: Dictionary, prop_name: String) -> int:
	return int((spec.get("as_index", {}) as Dictionary).get(prop_name, 0))


# ── Sliders curvos (ver CURVED_MIN_MAX) ──────────────────────────────────────────────────────────

static func _is_curved(low: float, high: float) -> bool:
	if low < 0.0 or high < CURVED_MIN_MAX:
		return false
	return high / maxf(low, high / 100000.0) >= CURVED_RATIO


## Geometrica si el minimo es positivo. Si arranca en cero no hay logaritmo posible, asi que va una
## cubica, que tambien reparte casi todo el recorrido en la parte baja y deja llegar al cero exacto.
static func _from_t(t: float, low: float, high: float) -> float:
	if low <= 0.0:
		return high * t * t * t
	return low * pow(high / low, t)


static func _to_t(value: float, low: float, high: float) -> float:
	if low <= 0.0:
		return pow(clampf(value / high, 0.0, 1.0), 1.0 / 3.0)
	return clampf(log(maxf(value, low) / low) / log(high / low), 0.0, 1.0)


## PINTA LA FILA según si su número es todavía el del código o ya lo movió alguien (ver `DEFAULT_COLOR`).
##
## Sin `code_defaults` en la sección no pinta nada: los afinadores que no tienen un "defecto del código" que
## ofrecer —el de clima, el de terreno— siguen exactamente como estaban.
static func _tint(label: Label, spec: Dictionary, prop: Dictionary) -> void:
	var code: Object = spec.get("code_defaults", null) as Object
	if code == null or not is_instance_valid(code):
		return
	var prop_name := str(prop["name"])
	var mine: Variant = (spec["target"] as Object).get(prop_name)
	var theirs: Variant = code.get(prop_name)
	var same: bool = _same(mine, theirs)
	# CON COLOR PROPIO (ver `colors`): el mismo color, apagado si es el del código.
	var own: Dictionary = spec.get("colors", {})
	if own.has(prop_name):
		var tone: Color = own[prop_name]
		label.add_theme_color_override("font_color", tone.lerp(DEFAULT_COLOR, 0.55) if same else tone)
		return
	label.add_theme_color_override("font_color", DEFAULT_COLOR if same else AUTHORED_COLOR)


## Dos valores son el mismo, con holgura para los flotantes: lo que vuelve de un `.tres` pasó por texto, así
## que un número guardado puede volver con una diezmilésima de diferencia y eso no es autoría de nadie. Es
## la misma regla con la que se guarda la diferencia (ver ShapeLayer._same), y está acá porque este archivo
## no puede depender de esa clase: lo usan afinadores que no tienen capa.
static func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) == TYPE_FLOAT and typeof(b) == TYPE_FLOAT:
		return absf(float(a) - float(b)) < 0.0001
	return a == b


## UN COLOR ESCRITO A MANO: «#rrggbb», «rrggbb» o tres números separados por comas o espacios —de 0 a 255, o de 0 a
## 1 si ninguno pasa de 1—. Null si no se entiende. Opaco: un hex pegado no trae transparencia.
static func parse_color(text: String, alpha := 1.0) -> Variant:
	var clean := text.strip_edges()
	var parts := clean.replace(",", " ").split(" ", false)
	if parts.size() == 3:
		var values: Array[float] = []
		for part in parts:
			if not part.is_valid_float():
				return null
			values.append(float(part))
		var scale := 255.0 if values.max() > 1.0 else 1.0
		return Color(values[0] / scale, values[1] / scale, values[2] / scale, alpha)
	var html := clean.trim_prefix("#")
	if html.length() == 6 and html.is_valid_html_color():
		var out := Color.html(html)
		out.a = alpha
		return out
	return null


static func _write(target: Object, prop_name: String, value: Variant, on_change: Callable) -> void:
	target.set(prop_name, value)
	if on_change.is_valid():
		on_change.call()
