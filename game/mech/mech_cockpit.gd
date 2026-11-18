class_name MechCockpit
extends RefCounted

## LO QUE LE PIDEN A LA MECA LOS CONTROLES DE ADENTRO (17/11/2026, el usuario: «empezar a definir con qué controles se
## maneja la nave… la locomoción sería básicamente con una palanca XZ… otra saltar… 8 botones el dash… otra para
## levitar»). Los escriben los controles de los tableros (ver CageBoards) y los lee ToolMechKeys.read cuando nadie la
## posee, con las mismas reglas de energía que las teclas. Las direcciones, como `BalanceBody.move`: relativas al torso
## (x a la derecha, y adelante).

## Caminar (la palanca de dos ejes).
var move := Vector2.ZERO
## El salto (apoyada) y levitar (en el aire): mantenidos.
var jump := false
var levitate := false
## El dash: mientras se aprieta un botón del dash, hacia `dash_way`.
var dash := false
var dash_way := Vector2.ZERO
var crouch := false
## El escudo de fuerza, mantenido (MechShield).
var shield := false
## El gatillo del cañón (el mando del cañón, clic izquierdo mantenido): lo que hace, según su modo (CannonTip).
var fire := false
