class_name StrokeLabel
extends MeshInstance3D

## UN TEXTO DIEGÉTICO: lo que está escrito en el mundo, con la letra del juego (ver StrokeFont). Es el reemplazo de
## Label3D para todo lo que no es depuración ni subtítulo: el rótulo de un tablero, la palabra de una placa, el
## carácter de una tecla. Plano o con relieve (`depth`), opaco o brillando (`glow`), y siempre mirando a su +Z.
##
## Cambiar `text` vuelve a pedir la malla, que StrokeFont guarda: dos rótulos iguales comparten la malla, y los
## materiales se comparten por color.

## El alto de una mayúscula, en metros.
@export var height: float = 0.012:
	set(value):
		height = value
		_rebuild()
## El ancho del trazo, en fracción del alto.
@export var stroke_ratio: float = 0.13:
	set(value):
		stroke_ratio = value
		_rebuild()
## Cuánto sale del plano, en metros. 0 = impreso.
@export var depth: float = 0.0:
	set(value):
		depth = value
		_rebuild()
## LO MÁS ANCHO QUE PUEDE SER, en metros; 0 = sin límite. Si el texto no entra, la letra se achica hasta que entre:
## un rótulo nunca se sale de su placa, diga lo que diga y en el idioma que sea.
@export var max_width: float = 0.0:
	set(value):
		max_width = value
		_rebuild()
@export var align: StrokeFont.Align = StrokeFont.Align.CENTER:
	set(value):
		align = value
		_rebuild()
@export var color: Color = Color(0.1, 0.1, 0.1):
	set(value):
		color = value
		_paint()
## Brilla con su color, como el alambre de un nixie.
@export var glow: float = 0.0:
	set(value):
		glow = value
		_paint()
@export var text: String = "":
	set(value):
		text = value
		_rebuild()

static var _materials: Dictionary = {}


## Un rótulo listo: texto, alto y color, alineado al centro.
static func make(p_text: String, p_height: float, p_color: Color, p_depth := 0.0) -> StrokeLabel:
	var label := StrokeLabel.new()
	label.height = p_height
	label.depth = p_depth
	label.color = p_color
	label.text = p_text
	return label


func _ready() -> void:
	set_meta("no_outline", true)
	_rebuild()
	_paint()


func _rebuild() -> void:
	if text.is_empty():
		mesh = null
		return
	var fit := fitted_height()
	mesh = StrokeFont.mesh(text, fit, fit * stroke_ratio, depth, align)


## El alto con el que de verdad se escribe: `height`, o menos si a ese alto no entra en `max_width`.
func fitted_height() -> float:
	if max_width <= 0.0:
		return height
	var width := StrokeFont.measure(text, height).x
	return height if width <= max_width else height * max_width / width


func _paint() -> void:
	material_override = material_for(color, glow)


## El material de la letra, uno por color y brillo para todo el juego.
static func material_for(p_color: Color, p_glow: float) -> StandardMaterial3D:
	var key := "%s|%.2f" % [p_color.to_html(), p_glow]
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = p_color
		m.roughness = 0.6
		if p_glow > 0.0:
			m.emission_enabled = true
			m.emission = p_color
			m.emission_energy_multiplier = p_glow
		_materials[key] = m
	return _materials[key]
