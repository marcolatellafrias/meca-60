class_name CarBody
extends RefCounted

## PIEZA PARA LO TRAÍDO DE CHARACTER-PARAMETRIC (ver LEEME.md de esta carpeta): allá esto es el cuerpo de un auto del tránsito (game/traffic/car_body.gd); los números son los de allá, para los
## deslizadores del panel F1, que acá no
## existe. Sólo está lo que lo traído le pide, sin hacer nada.

static var position_frequency := 2.0
static var position_damping := 0.3
static var thrust := 30.0
static var max_accel := 8.0
static var tilt_frequency := 4.0
static var tilt_damping := 0.25
static var spin_share := 0.3
static var lost_tilt := 1.4
static var lost_distance := 15.0
static var fall_thrust_s := 2.5
