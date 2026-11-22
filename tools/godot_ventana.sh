#!/usr/bin/env bash
# GODOT CON VENTANA SIN ROBARLE EL FOCO AL DIOS DEL JUEGO: para las capturas y todo lo que los agentes corren con
# ventana. Cada Godot que se abría le sacaba el teclado de lo que estaba haciendo (lo pidió el 12/10/2026).
#
# Godot no tiene una opción de línea de comandos para abrir sin foco, pero lee `override.cfg` de la carpeta del
# proyecto con que arranca. Ponerlo en el repo también afectaría sus partidas, así que los agentes arrancan desde una
# carpeta propia FUERA del repo —sus carpetas son enlaces (junctions) a las del repo, y `project.godot` se copia en
# cada corrida para que nunca quede viejo— con `display/window/size/no_focus` prendido. Es el mismo proyecto, la
# misma caché de importación; sólo la ventana no toma el foco.
#
#   tools/godot_ventana.sh res://game/debug/snapshot/snapshot.tscn -- --receta=trajes --salida=C:/ruta
#
# Para lo que corre sin ventana (--headless) no hace falta: no abre nada.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && (pwd -W 2>/dev/null || pwd))"
CASCARA="${GODOT_AGENTES:-D:/Godot/agentes/meca-60}"
GODOT="${GODOT_EXE:-D:/Godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"

mkdir -p "$CASCARA"
# Los archivos de la raíz del proyecto, copiados en cada corrida; las carpetas, enlazadas una vez.
for f in "$REPO"/*.godot "$REPO"/*.tres "$REPO"/*.cfg ; do
	[ -f "$f" ] && cp "$f" "$CASCARA/"
done
for d in "$REPO"/*/ "$REPO"/.godot/; do
	name="$(basename "$d")"
	if [ ! -e "$CASCARA/$name" ]; then
		powershell -NoProfile -Command \
			"New-Item -ItemType Junction -Path '$CASCARA/$name' -Target '$REPO/$name' | Out-Null"
	fi
done
# Sin foco y FUERA DE LA PANTALLA: sin foco solo no alcanzaba —la ventana igual aparecía encima de lo que él hacía—.
# El proyecto la abre maximizada (window/size/mode=2), que no se puede mover: acá va en modo ventana, y la mueve
# afuera apenas arranca el autoload AgentWindow (game/debug/agent_window.gd), porque Godot acomoda la posición inicial
# dentro de la pantalla. Fuera de la pantalla se sigue dibujando, así que las capturas salen igual.
printf '[display]\n\nwindow/size/mode=0\nwindow/size/no_focus=true\n\n[agentes]\n\nventana_afuera=true\n' \
	> "$CASCARA/override.cfg"

# UN GODOT COLGADO SE CORTA SOLO: una escena con un error de parseo nunca termina, y cerrarla a mano llevó a un agente a
# matar Godots sin saber de quién eran —el editor del usuario incluido— (12/10/2026). Con este tope nadie tiene que
# matar nada. GODOT_TOPE lo cambia, en segundos.
exec timeout "${GODOT_TOPE:-600}" "$GODOT" --path "$CASCARA" "$@"
