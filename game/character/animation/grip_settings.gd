class_name GripSettings
extends Resource

## ── LO GUARDADO DEL F1 DE LA FILA AGARRE (29/10/2026, sesión de siluetas de los personajes) ───────────────────────────
## Lo pidió el usuario: «el panel ese para cambiar las cosas, el volante y eso, ¿tienen opción de guardado?…
## agrégasela». Cómo se aprieta (TubeHand.press_with) y cómo vuelven a agarrar el volante y la válvula (GripStyle), en
## `PATH`. Lo escribe el botón Guardar del panel (ver PressPanel); lo leen TubeHand y GripStyle al arrancar. Sin
## archivo, lo del código.
##
## ⚠ El archivo es del usuario (lo escribe el panel cuando él guarda): no se commitea a mano.

const PATH := "res://game/character/animation/grip_settings.tres"

@export var press_with := 0
@export var wheel: GripStyle = null
@export var valve: GripStyle = null


## Lo guardado, o null si no hay.
static func saved() -> GripSettings:
	if not ResourceLoader.exists(PATH):
		return null
	return ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GripSettings


## GUARDA lo que está puesto ahora. Verdadero si salió bien.
static func store() -> bool:
	var out := GripSettings.new()
	out.press_with = TubeHand.press_with
	out.wheel = (GripStyle.families[GripStyle.WHEEL] as GripStyle).duplicate() as GripStyle
	out.valve = (GripStyle.families[GripStyle.VALVE] as GripStyle).duplicate() as GripStyle
	return ResourceSaver.save(out, PATH) == OK
