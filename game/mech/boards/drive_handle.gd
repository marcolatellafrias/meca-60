class_name DriveHandle
extends FoldingArm

## EL MANEJO DE LA MECA DE 1 (18/11/2026; el usuario: «haría la variante de 2 y 1… si yo quiero probar la meca de a 1»;
## el diseño, «los modos, para jugar solo», en docs/conceptual/la-meca.md). Un brazo plegable (FoldingArm) con un
## manubrio, que sale del costado de la cápsula con el codo abajo. CON UN CLIC SE TRAE Y QUEDA TRABADO (`latches_mode`) hasta la E; mientras:
##   · la mirada es libre y el torso la persigue (`steer`, como con los mandos de los brazos);
##   · el clic izquierdo y el derecho usan los dos brazos (`use`, `use_alt`);
##   · EL TECLADO MANEJA LA MECA (`drive`, cada paso, con si sigue en el modo: lo arma CageBoards).
## Al soltarlo se pliega y suelta todo lo que estaba apretado.

var use_alt := Callable()
var drive := Callable()
var _driving := false


func _init() -> void:
	# El codo, abajo y hacia adentro: el brazo no cruza la vista.
	brought_pole = Vector3(0.0, -0.6, 0.6)


func latches_mode() -> bool:
	return true


func enter_mode() -> void:
	super()
	_driving = true


func exit_mode() -> void:
	super()
	_driving = false
	if use_alt.is_valid():
		use_alt.call(false)
	if drive.is_valid():
		drive.call(false)


func mode_use_alt(pressed: bool) -> void:
	if use_alt.is_valid():
		use_alt.call(pressed)


## Las dos manos, en las dos empuñaduras del manubrio.
func _setup_handle_points(_size: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		add_handle_point_local(Vector3(side * 0.17, 0.12, 0.0), Vector3.UP)


func _physics_process(_delta: float) -> void:
	if _driving and drive.is_valid():
		drive.call(true)
