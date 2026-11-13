class_name SandboxKey
extends RefCounted

## UNA TECLA DEL PANEL CHICO: lo que se aprieta parado en una parcela para probar algo. Se arma con una de tres formas,
## y la forma ya dice la buena práctica (ver docs/technical/sandbox.md):
##   · `action`  hace algo una vez (tirar una bola, pegarle, subirse).
##   · `toggle`  prende o apaga algo; el panel muestra «nombre: sí / no» solo.
##   · `cycle`   pasa por POCOS estados (hasta `MAX_CYCLE`); el panel muestra «nombre: el que está».
## Las tres piden la tecla y su PESO (`Weight.MAIN` o `Weight.NORMAL`): las principales salen primero y resaltadas.
##
## LO QUE SE GUARDA NUNCA VA ACÁ: una tecla es una acción transitoria de prueba. Las perillas, los sliders y lo que tiene
## muchas opciones van en un panel F (ver SandboxRow.panel).
##
## LAS TECLAS RESERVADAS (`RESERVED`) son del sandbox en cualquier parcela, y las F son de los paneles: una tecla de
## parcela o de fila que use una de esas no se monta y el sandbox avisa al arrancar (ver SandboxCatalogue.check).

enum Weight { MAIN, NORMAL }

## Más estados que esto en un ciclo ya no es «pocos»: va en un panel F.
const MAX_CYCLE := 8

## LAS TECLAS DEL SANDBOX, en cualquier parcela: lo que hacen, para el panel y para el aviso de choque.
const RESERVED := {
	KEY_W: "caminar", KEY_A: "caminar", KEY_S: "caminar", KEY_D: "caminar",
	KEY_SPACE: "saltar", KEY_SHIFT: "correr", KEY_CTRL: "agacharse", KEY_E: "usar", KEY_ESCAPE: "el menú",
	KEY_R: "regenerar la parcela (o armarla)", KEY_C: "copiar la información", KEY_V: "modo creativo",
	KEY_B: "corta: modo creativo · larga: ente o cuerpo", KEY_I: "el inspector",
	KEY_O: "poseer lo que se mira", KEY_T: "la vista de lo poseído",
}
## Las que se anotan abajo del panel chico, en este orden (las de caminar no hace falta).
const HINTS: Array[Key] = [KEY_R, KEY_C, KEY_B, KEY_V, KEY_O, KEY_I]

## LAS F (ver SandboxRow.panel y SandboxCatalogue.global_panels): las de parcela y de fila van de F1 a F7; las globales,
## de F9 a F12. La F8 nunca: es la de Godot para detener el juego.
const LOCAL_PANEL_KEYS: Array[Key] = [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7]
const GLOBAL_PANEL_KEYS: Array[Key] = [KEY_F9, KEY_F10, KEY_F11, KEY_F12]
const FORBIDDEN := {KEY_F8: "la de Godot para detener el juego"}

var key: Key = KEY_NONE
var weight := Weight.NORMAL
## Si vale también sentado o manejando (bajarse, pegar desde adentro): las demás, sentado, no andan.
var seated := false
## Cuántos estados tiene, si es un ciclo (para el aviso de `MAX_CYCLE`); 0 si no.
var states := 0
var _text: Callable
var _press: Callable


## UNA ACCIÓN: `label` es un texto o un Callable que lo devuelve; `apply(parcel)`.
static func action(p_key: Key, p_weight: Weight, label: Variant, apply: Callable) -> SandboxKey:
	var made := SandboxKey.new()
	made.key = p_key
	made.weight = p_weight
	made._text = (label as Callable) if label is Callable else func() -> String: return str(label)
	made._press = apply
	return made


## UN INTERRUPTOR: `is_on()` dice cómo está y `set_on(parcel, on)` lo cambia.
static func toggle(p_key: Key, p_weight: Weight, name: String, is_on: Callable, set_on: Callable) -> SandboxKey:
	var made := SandboxKey.new()
	made.key = p_key
	made.weight = p_weight
	made._text = func() -> String: return "%s: %s" % [name, "sí" if bool(is_on.call()) else "no"]
	made._press = func(parcel: SandboxParcel) -> void: set_on.call(parcel, not bool(is_on.call()))
	return made


## UN CICLO: `names` son los estados; `index()` dice cuál está y `set_index(parcel, i)` pasa a otro.
static func cycle(p_key: Key, p_weight: Weight, name: String, names: Array, index: Callable,
		set_index: Callable) -> SandboxKey:
	var made := SandboxKey.new()
	made.key = p_key
	made.weight = p_weight
	made.states = names.size()
	made._text = func() -> String:
		return "%s: %s" % [name, str(names[posmod(int(index.call()), maxi(names.size(), 1))])]
	made._press = func(parcel: SandboxParcel) -> void:
		set_index.call(parcel, posmod(int(index.call()) + 1, maxi(names.size(), 1)))
	return made


## Que valga también sentado o manejando.
func while_seated() -> SandboxKey:
	seated = true
	return self


func text() -> String:
	return str(_text.call())


func press(parcel: SandboxParcel) -> void:
	_press.call(parcel)


## Si `keycode` es esta tecla (los números del teclado numérico valen como los de arriba).
func matches(keycode: Key) -> bool:
	return plain(keycode) == key


static func plain(keycode: Key) -> Key:
	if keycode >= KEY_KP_0 and keycode <= KEY_KP_9:
		return (KEY_0 + (keycode - KEY_KP_0)) as Key
	return keycode


static func name_of(keycode: Key) -> String:
	return OS.get_keycode_string(keycode)


## LO QUE ESTÁ MAL DE ESTA TECLA, o vacío: reservada, una F, la F8, o un ciclo largo.
func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if RESERVED.has(key):
		out.append("la tecla %s es del sandbox (%s)" % [name_of(key), RESERVED[key]])
	elif FORBIDDEN.has(key):
		out.append("la tecla %s no se usa: es %s" % [name_of(key), FORBIDDEN[key]])
	elif key in LOCAL_PANEL_KEYS or key in GLOBAL_PANEL_KEYS:
		out.append("la tecla %s es de los paneles F" % name_of(key))
	if states > MAX_CYCLE:
		out.append("«%s» pasa por %d estados: más de %d va en un panel F" % [text(), states, MAX_CYCLE])
	return out
