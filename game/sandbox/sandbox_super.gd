class_name SandboxSuper
extends RefCounted

## LAS SUPERCATEGORÍAS DEL SANDBOX: los bloques grandes en que se ordenan las filas, uno por módulo del proyecto (ver
## docs/modulos.md). Cada fila dice la suya al crearse (`SandboxRow.new(SandboxSuper.Id.MECH, …)`), así que una fila no
## puede quedar sin supercategoría: sin ella no compila. *En character-parametric eran una tabla aparte, por nombre de
## fila, y una fila que nadie anotaba ahí no aparecía donde se la buscaba.*
##
## Cada bloque es contiguo, en el orden de este enum, con su piso apenas teñido y su nombre a la izquierda. Reglas en
## docs/sandbox.md.

enum Id { MECH, INTERIOR, CHARACTERS, WORLD, ART, NETWORK }

const NAMES := {
	Id.MECH: "Meca",
	Id.INTERIOR: "Interior",
	Id.CHARACTERS: "Personajes",
	Id.WORLD: "Mundo",
	Id.ART: "Arte",
	Id.NETWORK: "Red",
}
## El tono de su piso (el matiz, de 0 a 1): separados, para que dos bloques vecinos no se confundan.
const HUES := {
	Id.MECH: 0.08,
	Id.INTERIOR: 0.55,
	Id.CHARACTERS: 0.33,
	Id.WORLD: 0.15,
	Id.ART: 0.8,
	Id.NETWORK: 0.62,
}


static func name_of(id: Id) -> String:
	return str(NAMES[id])


static func hue_of(id: Id) -> float:
	return float(HUES[id])
