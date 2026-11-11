extends Node

## LA VENTANA DE LOS AGENTES, FUERA DE LA PANTALLA: cuando un agente corre Godot con ventana (las capturas, ver
## tools/godot_ventana.sh), la ventana se va lejos apenas arranca, así no aparece encima de lo que hace el dios del juego
## (lo pidió el 12/10/2026). Godot acomoda la posición inicial dentro de la pantalla, así que no alcanza con pedirla en
## los ajustes: hay que moverla ya creada. Fuera de la pantalla se sigue dibujando, y las capturas salen igual.
##
## Sólo actúa con `agentes/ventana_afuera`, que pone el override.cfg de la carpeta de los agentes: en el juego y en el
## editor no existe, y esto no hace nada. Es el primer autoload, para que la ventana se vaya lo antes posible.

func _enter_tree() -> void:
	if ProjectSettings.get_setting("agentes/ventana_afuera", false):
		DisplayServer.window_set_position(Vector2i(-20000, -20000))
