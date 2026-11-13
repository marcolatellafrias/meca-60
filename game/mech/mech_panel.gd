class_name MechPanel
extends KnobsPanel

## EL PANEL DE LA MECA (F1 en sus filas): todas sus perillas (BodySettings), y vuelven a lo del código con el botón de
## cada una. Como todos los paneles de perillas (KnobsPanel): se mueve un borrador, y «Guardar» o «Volver a lo
## guardado» rearman las mecas con eso. La altura de la caja no está acá: sale del cuerpo (el F2).

const PANEL_WIDTH := 420.0
const LABELS := {
	"walk_speed": "caminar: velocidad (m/s)", "walk_accel": "caminar: cuánto tarda en arrancar (m/s²)",
	"walk_brake": "caminar: freno al soltar (m/s²)",
	"pivot_kp": "agarre al apoyo: resorte", "pivot_kd": "agarre al apoyo: freno",
	"upright_kp": "músculo que la quiere derecha", "upright_kd": "freno del músculo",
	"fall_tilt": "se cae inclinada más de (°)",
	"feet_accel": "pies: cuánto aceleran para alcanzarla (m/s²)", "feet_speed": "pies: velocidad tope (m/s)",
	"feet_react": "pies: qué tan rápido reaccionan (1/s)",
	"feet_catch": "pies: cuánto buscan ponerse debajo (1/s)",
	"turn_speed": "giro: velocidad tope (°/s)", "yaw_force": "giro: fuerza para girar (rad/s²)",
	"yaw_hold": "giro: freno contra que la giren (rad/s²)", "yaw_grip": "giro: qué tan firme sigue al mouse",
	"step_reach": "el pie pisa adelante de su lugar (m, piernas medianas)", "step_fastest": "el paso más rápido (s)",
	"step_slowest": "el paso más lento (s)", "step_height": "cuánto sube el pie (m, piernas medianas)",
	"settle_gap": "quieta, acomoda un pie a más de (m, piernas medianas)", "settle_turn": "o girado más de (°)",
	"turn_per_step": "lo más que gira un paso (°)", "knee_out": "rodillas hacia afuera (parte)",
	"knee_out_crouched": "agachada, rodillas hacia afuera (parte)",
	"fold_time": "se recogen al caer en (s)", "unfold_time": "se estiran al enderezarse en (s)",
	"sprint_multiplier": "correr: hasta cuántas veces la caminata", "sprint_accel": "correr: aceleración en la banda (parte)",
	"crouch_rod": "agachada: largo del palo (parte)", "crouch_speed": "agachada: velocidad (parte)",
	"rod_rate": "cuán rápido sube y baja (por s)",
	"jump_height": "salto entero (m)", "jump_charge_time": "el salto se carga en (s)",
	"jump_squat": "cargando baja hasta (parte del palo)", "jump_least": "un toque sin cargar salta (parte)",
	"air_accel": "en el aire, cambia de costado (m/s²)",
	"air_gravity": "en el aire pesa (veces)", "fall_extra": "y bajando, además (veces)",
	"dash_speed": "dash: suma (m/s)", "dash_lift": "dash: sube a (m/s)", "dash_cost": "dash: gasta del propulsor",
	"dash_count": "dashes por salto",
	"thrust": "propulsor: empuje (m/s²)", "thrust_time": "propulsor: dura (s)", "thrust_refill": "propulsor: se recarga en (s)",
	"fall_gravity": "gravedad caída (veces)", "ground_spin_damp": "freno del giro caída (1/s)",
	"limp_time": "tirada, antes de recuperarse (s)",
	"settle_speed": "se recupera más lento que (m/s)", "settle_spin": "y girando menos que (rad/s)",
	"nozzle_push": "empuje de cada tobera (m/s²)", "lift_share": "sube hasta esta parte de la altura",
	"lift_kp": "resorte de subir", "lift_kd": "freno de subir", "right_kp": "resorte de enderezarse",
	"right_kd": "freno de enderezarse", "upright_done": "derecha con menos de (°)",
	"knock_soft": "pegarle suave, N (m/s arriba)", "knock_strong": "pegarle fuerte, M (m/s arriba)",
}


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("meca", "MECA")


func knobs() -> Resource:
	return BodySettings.current


func fresh() -> Resource:
	return BodySettings.new()


func saved_path() -> String:
	return BodySettings.SAVED


## Rearma todas las mecas con las perillas nuevas.
func applied() -> void:
	Mech.rebuild_all(get_tree())


func note() -> String:
	return "el paso es el de piernas medianas: se escala con el largo de las piernas (F2)"


func sections() -> Array[Dictionary]:
	return [{"title": "BodySettings (game/balance_body/body_settings.gd)", "target": draft(), "labels": LABELS,
		"defaults": BodySettings.new()}]
