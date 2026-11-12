class_name City
extends Node3D

## PIEZA PARA LO TRAÍDO DE CHARACTER-PARAMETRIC (ver LEEME.md de esta carpeta): allá esto es la ciudad (game/city/core/city.gd), que acá no
## existe. Sólo está lo que lo traído le pide, sin hacer nada.

enum DebugPalette { BUILDING, DISTRICT }

var building_debug_view := false
var building_debug_palette := DebugPalette.BUILDING
