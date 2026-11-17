class_name ComponentArchetype
extends PanelArchetype

## UN COMPONENTE: la pieza mínima que va montada en un tablero —un CONTROL, que se maneja, o un INDICADOR, que muestra—.
## Viene de character-parametric (17/11/2026, el usuario: «el código de la nave… en los elementos básicos,
## interactuables, control rotativo, la inercia de los controles, dónde se trababa un botón, si era continuo o discreto…
## estaban bastante bien pensados»), con SÓLO LO ESENCIAL: los controles de siempre (ControlArchetype: el botón, el de
## encendido, la palanca, el volante y la de dos ejes), el botón con sus parámetros (ButtonArchetype) y la palanca
## (LeverArchetype). El catálogo de la nave —las teclas, los telégrafos, las luces, los indicadores— no se trajo: se
## suma acá, de a uno, cuando haga falta (docs/technical/panel-pieces.md de character-parametric dice cómo es cada uno).
##
## Cómo se monta y se muestra es de PanelArchetype. Los controles de siempre (ControlArchetype) se arman con su propio
## tablero de un control: por eso pisan `build` y no usan `mount`.


## Los CONTROLES que hay en la meca.
static func controls() -> Array:
	var all: Array = []
	for control: ControlArchetype in ControlArchetype.catalogue():
		if not ["button", "power", "lever"].has(control.key):
			all.append(control)
	all.append_array(ButtonArchetype.primitives())
	all.append_array(LeverArchetype.primitives())
	return all
