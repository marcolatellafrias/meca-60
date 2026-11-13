class_name ThrusterFlame
extends Node3D

## LA LLAMA DE UNA TOBERA (13/11/2026): conos de pocos lados, con un degradé de la boca a la punta, que tiemblan y se
## estiran con lo que empuja (`throttle`). Lo pidió el usuario: «se crea como con un cono, pero que cambia y que tiene
## varios segmentos y tiene un poco de gradiente». Sale hacia su −Z (como los emisores de ParticleSystems): orientarla
## es del que la cuelga. El humo va aparte (ParticleSystems.thruster_smoke).
##
## HAY VARIAS, PARA ELEGIR (`Style`, `style` para todas): salen de técnicas de llamas de propulsor estilizadas
## (godotshaders.com: «Jet Engine Thrustler», «Engine flame», «Futuristic Jet Thruster», CC0; las bandas toon, de un
## fuego estilizado de itch.io; los diamantes de choque, de cómo arma Kerbal Space Program sus escapes). Ninguna usa
## texturas: el ruido se calcula en el shader.
##   · GRADIENT    dos conos, uno adentro del otro: el de adentro casi blanco, el de afuera naranja y transparente.
##   · TOON        bandas de color planas (blanco, amarillo, naranja) que el ruido corre y recorta.
##   · NOISE       un cono que el ruido que corre hacia la punta va comiendo, con los bordes suaves.
##   · DIAMONDS    una vaina naranja y adentro, en fila, rombos brillantes que se agrandan con el empuje.
##   · WOBBLE      la silueta misma tiembla: los vértices se mueven con ruido, más hacia la punta.

enum Style { GRADIENT, TOON, NOISE, DIAMONDS, WOBBLE }
const NAMES := ["conos con degradé", "bandas toon", "ruido que corre", "diamantes de choque", "silueta que tiembla"]

## La de todas las toberas (se lee al armarlas).
static var style := Style.GRADIENT

## El largo con todo (m), cuánto queda con poco, el ancho en la boca, los lados de los conos y cuánto tiembla.
const LENGTH := 2.4
const LEAST := 0.35
const RADIUS := 0.62
const SIDES := 8
const FLICKER := 0.14

## Lo que comparten los shaders: `along` (0 en la boca, 1 en la punta), el ruido y los tres colores.
const COMMON := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 mouth : source_color;
uniform vec4 middle : source_color;
uniform vec4 tip : source_color;
uniform float height = 1.0;
uniform float seed = 0.0;
varying float along;
varying vec3 local;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
vec4 ramp(float t) { return t < 0.5 ? mix(mouth, middle, t * 2.0) : mix(middle, tip, t * 2.0 - 1.0); }
"""

const GRADIENT_CODE := """
void vertex() { along = clamp(VERTEX.y / height + 0.5, 0.0, 1.0); }
void fragment() { vec4 c = ramp(along); ALBEDO = c.rgb; ALPHA = c.a; }
"""

const TOON_CODE := """
void vertex() { along = clamp(VERTEX.y / height + 0.5, 0.0, 1.0); local = VERTEX; }
void fragment() {
	float angle = atan(local.x, local.z);
	float n = noise(vec2(angle * 1.5 + seed, along * 4.0 - TIME * 6.0)) * 0.6
		+ noise(vec2(angle * 3.0 - seed, along * 8.0 - TIME * 9.0)) * 0.4;
	float heat = 1.0 - along - n * 0.45;
	if (heat < 0.05) { discard; }
	vec3 color = heat > 0.55 ? mouth.rgb : (heat > 0.3 ? middle.rgb : tip.rgb);
	ALBEDO = color;
	ALPHA = 1.0;
}
"""

const NOISE_CODE := """
void vertex() { along = clamp(VERTEX.y / height + 0.5, 0.0, 1.0); local = VERTEX; }
void fragment() {
	float angle = atan(local.x, local.z);
	float n = noise(vec2(angle * 2.0 + seed, along * 5.0 - TIME * 7.0));
	float edge = clamp(abs(dot(NORMAL, VIEW)) * 1.3 + 0.15, 0.0, 1.0);
	float body = smoothstep(0.0, 0.35, (1.0 - pow(along, 0.8)) - n * 0.55);
	vec4 c = ramp(along);
	ALBEDO = mix(c.rgb, mouth.rgb, body * 0.4);
	ALPHA = body * edge * c.a;
}
"""

const WOBBLE_CODE := """
void vertex() {
	along = clamp(VERTEX.y / height + 0.5, 0.0, 1.0);
	float angle = atan(VERTEX.x, VERTEX.z);
	float n = noise(vec2(angle * 1.2 + seed, along * 3.0 - TIME * 8.0)) - 0.5;
	VERTEX.xz *= 1.0 + n * 0.9 * along;
	VERTEX.y += n * 0.25 * along * height;
}
void fragment() {
	vec4 c = ramp(along);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
"""

## Cuánto empuja, de 0 a 1: el largo y si se ve.
var throttle := 0.0
## Cuál es esta (por defecto, la de todas).
var shape := -1

var _parts: Array[Node3D] = []
var _clock := 0.0


func _ready() -> void:
	if shape < 0:
		shape = style
	var seed := randf() * 100.0
	match shape:
		Style.GRADIENT:
			_cone(GRADIENT_CODE, 1.0, 1.0, Color(1.0, 0.75, 0.3, 0.85), Color(1.0, 0.45, 0.12, 0.6),
				Color(0.9, 0.2, 0.05, 0.0), seed)
			_cone(GRADIENT_CODE, 0.55, 0.6, Color(1.0, 1.0, 0.9, 1.0), Color(1.0, 0.85, 0.45, 0.85),
				Color(1.0, 0.6, 0.2, 0.0), seed)
		Style.TOON:
			_cone(TOON_CODE, 1.0, 1.0, Color(1.0, 0.97, 0.8), Color(1.0, 0.78, 0.25), Color(0.95, 0.4, 0.1), seed)
		Style.NOISE:
			_cone(NOISE_CODE, 1.0, 1.0, Color(1.0, 0.95, 0.75, 1.0), Color(1.0, 0.6, 0.18, 0.9),
				Color(0.85, 0.2, 0.05, 0.4), seed)
			_cone(GRADIENT_CODE, 0.45, 0.45, Color(1.0, 1.0, 0.95, 1.0), Color(1.0, 0.9, 0.6, 0.8),
				Color(1.0, 0.7, 0.3, 0.0), seed)
		Style.DIAMONDS:
			_cone(GRADIENT_CODE, 1.0, 1.0, Color(1.0, 0.6, 0.2, 0.55), Color(1.0, 0.4, 0.1, 0.35),
				Color(0.9, 0.2, 0.05, 0.0), seed)
			for index in 3:
				_diamond(index, seed)
		Style.WOBBLE:
			_cone(WOBBLE_CODE, 1.0, 1.0, Color(1.0, 0.85, 0.45, 0.95), Color(1.0, 0.5, 0.15, 0.75),
				Color(0.9, 0.2, 0.05, 0.0), seed, 4)
			_cone(WOBBLE_CODE, 0.5, 0.55, Color(1.0, 1.0, 0.92, 1.0), Color(1.0, 0.85, 0.5, 0.9),
				Color(1.0, 0.65, 0.25, 0.0), seed + 7.0, 3)
	visible = false


## Un cono de la boca (ancho) a la punta (nada), de `wide` del ancho y `long` del largo, con su shader.
func _cone(code: String, wide: float, long: float, mouth: Color, middle: Color, tip: Color, seed: float,
		rings := 3) -> void:
	var mesh := CylinderMesh.new()
	# El cilindro va sobre su Y, que el giro lleva a −Z: abajo (la boca) ancho, arriba (la punta) nada.
	mesh.top_radius = 0.0
	mesh.bottom_radius = RADIUS * wide
	mesh.height = LENGTH * long
	mesh.radial_segments = SIDES
	mesh.rings = rings
	mesh.cap_top = false
	mesh.cap_bottom = false
	_part(mesh, code, mouth, middle, tip, seed, Vector3(0, 0, -mesh.height * 0.5))


## UN ROMBO de los diamantes de choque: dos conos punta con punta, en fila a lo largo de la llama.
func _diamond(index: int, seed: float) -> void:
	var size := RADIUS * (0.42 - index * 0.08)
	for half: float in [1.0, -1.0]:
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0 if half > 0.0 else size
		mesh.bottom_radius = size if half > 0.0 else 0.0
		mesh.height = size * 1.4
		mesh.radial_segments = 6
		mesh.rings = 1
		var center := -LENGTH * (0.2 + index * 0.24)
		_part(mesh, GRADIENT_CODE, Color(1.0, 1.0, 0.92, 1.0), Color(1.0, 0.92, 0.6, 1.0), Color(1.0, 0.8, 0.4, 1.0),
			seed, Vector3(0, 0, center - half * mesh.height * 0.5))


func _part(mesh: Mesh, code: String, mouth: Color, middle: Color, tip: Color, seed: float, at: Vector3) -> void:
	var shader := Shader.new()
	shader.code = COMMON + code
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("mouth", mouth)
	material.set_shader_parameter("middle", middle)
	material.set_shader_parameter("tip", tip)
	material.set_shader_parameter("height", (mesh as CylinderMesh).height)
	material.set_shader_parameter("seed", seed)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	part.rotation_degrees = Vector3(-90, 0, 0)
	part.position = at
	var holder := Node3D.new()
	holder.add_child(part)
	add_child(holder)
	_parts.append(holder)


func _process(delta: float) -> void:
	visible = throttle > 0.02
	if not visible:
		return
	_clock += delta
	for index in _parts.size():
		# Cada pieza tiembla a su ritmo: se estira y se encoge un poco, y se angosta cuando se estira.
		var shake := 1.0 + FLICKER * (sin(_clock * (31.0 + index * 7.0)) * 0.6 + sin(_clock * (53.0 + index * 11.0)) * 0.4)
		var long := (LEAST + (1.0 - LEAST) * throttle) * shake
		_parts[index].scale = Vector3(1.0 / sqrt(shake), 1.0 / sqrt(shake), long)
