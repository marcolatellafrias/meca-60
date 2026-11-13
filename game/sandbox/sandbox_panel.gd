class_name SandboxPanel
extends CanvasLayer

## EL PANEL CHICO: a la derecha, mientras uno está en la zona de una parcela, qué es (categoría, nombre, semilla, lo que
## diga el arquetipo) y qué teclas valen, en bloques: ESTA PARCELA, ESTA FILA y SIEMPRE. Tres colores, nada más:
##   · gris claro   una tecla normal;
##   · ámbar        una principal (`SandboxKey.Weight.MAIN`), primero en su bloque;
##   · celeste      una F, que abre un panel.
## El alcance de una F lo dice el bloque donde está, no un color (ver docs/technical/sandbox.md). Las teclas del sandbox van
## al final, apagadas.
##
## Arriba a la izquierda, en rojo, lo que esté mal en el catálogo (ver SandboxCatalogue.check), en cualquier lado.

const MARGIN := 16.0
const WIDTH := 380.0
const BACKGROUND := Color(0.0, 0.0, 0.0, 0.7)
const NORMAL_COLOR := Color(0.86, 0.87, 0.88)
const MAIN_COLOR := Color(1.0, 0.76, 0.32)
const PANEL_COLOR := Color(0.55, 0.76, 1.0)
const TITLE_COLOR := Color(0.55, 0.56, 0.58)
const HINT_COLOR := Color(0.6, 0.63, 0.68)
const ERROR_COLOR := Color(1.0, 0.45, 0.4)

## Qué es cada renglón de un bloque.
enum Line { NORMAL, MAIN, PANEL }

var _frame: PanelContainer = null
var _text: Label = null
var _keys: RichTextLabel = null
var _errors: Label = null
var _copied_until := 0.0
var _keys_text := ""


func _ready() -> void:
	layer = 90
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_frame = PanelContainer.new()
	_frame.anchor_left = 1.0
	_frame.anchor_right = 1.0
	_frame.offset_left = -(MARGIN + WIDTH)
	_frame.offset_right = -MARGIN
	_frame.offset_top = MARGIN
	_frame.add_theme_stylebox_override("panel", style)
	_frame.visible = false
	add_child(_frame)
	var column := VBoxContainer.new()
	_frame.add_child(column)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(WIDTH - 24.0, 0.0)
	column.add_child(_text)
	column.add_child(HSeparator.new())
	_keys = RichTextLabel.new()
	_keys.bbcode_enabled = true
	_keys.fit_content = true
	_keys.scroll_active = false
	_keys.custom_minimum_size = Vector2(WIDTH - 24.0, 0.0)
	_keys.add_theme_font_size_override("normal_font_size", 14)
	column.add_child(_keys)

	_errors = Label.new()
	_errors.position = Vector2(MARGIN, MARGIN)
	_errors.add_theme_color_override("font_color", ERROR_COLOR)
	_errors.add_theme_font_size_override("font_size", 15)
	_errors.visible = false
	add_child(_errors)


## LO QUE ESTÁ MAL EN EL CATÁLOGO: queda arriba a la izquierda hasta que se arregle.
func show_errors(problems: PackedStringArray) -> void:
	_errors.text = "El sandbox tiene %d problema%s (ver docs/technical/sandbox.md):\n· %s" % [problems.size(),
		"" if problems.size() == 1 else "s", "\n· ".join(problems)]
	_errors.visible = not problems.is_empty()


## LOS BLOQUES: `{title, lines: [{key: Key, text: String, kind: Line}]}`, en orden; uno vacío no se muestra. `hints`, las
## teclas del sandbox, al final.
func show_parcel(parcel: SandboxParcel, blocks: Array[Dictionary], hints: PackedStringArray) -> void:
	_text.text = "\n".join(parcel.info_lines())
	var out := PackedStringArray()
	for block in blocks:
		var lines: Array = block["lines"]
		if lines.is_empty():
			continue
		out.append("[color=#%s]%s[/color]" % [TITLE_COLOR.to_html(false), str(block["title"]).to_upper()])
		for line: Dictionary in lines:
			var color := NORMAL_COLOR
			match int(line["kind"]):
				Line.MAIN:
					color = MAIN_COLOR
				Line.PANEL:
					color = PANEL_COLOR
			out.append("[color=#%s]%s  %s[/color]" % [color.to_html(false), SandboxKey.name_of(line["key"]),
				_escape(str(line["text"]))])
	out.append("[color=#%s][font_size=12]%s[/font_size][/color]" % [HINT_COLOR.to_html(false),
		_escape("\n".join(hints))])
	_keys_text = "\n".join(out)
	_keys.text = _keys_text
	_frame.visible = true


func hide_panel() -> void:
	_frame.visible = false


func copy(parcel: SandboxParcel) -> void:
	DisplayServer.clipboard_set("\n".join(parcel.info_lines()))
	_keys.text = "Copiado ✓\n" + _keys_text
	_copied_until = Time.get_ticks_msec() / 1000.0 + 1.5


func _process(_delta: float) -> void:
	if _copied_until > 0.0 and Time.get_ticks_msec() / 1000.0 > _copied_until:
		_copied_until = 0.0
		_keys.text = _keys_text


static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")
