// EL VIDRIO DE LA CÁPSULA DE LA MECA JAULA (16/11/2026, el usuario: «el tinteo del vidrio celeste no me gusta, pero…
// tiene que tener un tinteo porque no quiero que sea transparente… haría como manchas… con ruido, pero sutil… el tinteo…
// más verdoso y más sutil… así se nota que hay un vidrio, pero no veo todo de ese color»).
//   · CASI TRANSPARENTE: un tinte verdoso muy leve (`tint`, `clear_alpha`).
//   · MANCHAS MUY SUTILES («el ruido muy sutil también»): ruido 3D en el espacio de la malla (no hacen falta UV), sólo donde pasa un umbral; ahí el vidrio se
//     ensucia un poco (más opaco, más oscuro —«debería ser más oscuro»—, más áspero). Nada de mapas de normales: es color y brillo.
shader_type spatial;
render_mode blend_mix, cull_disabled, specular_schlick_ggx;

uniform vec3 tint : source_color = vec3(0.62, 0.74, 0.6);
uniform float clear_alpha : hint_range(0.0, 1.0) = 0.2;
uniform float smudge_alpha : hint_range(0.0, 1.0) = 0.3;
uniform float smudge_scale = 5.0;
uniform float smudge_threshold : hint_range(0.0, 1.0) = 0.5;
// LAS MANCHAS, PIXELADAS («las manchas de ruido las haría pixeladas, para que tengan un poco más de estilo»): el ruido
// se lee en una grilla de `pixel` metros, así se ven en cuadraditos.
uniform float pixel = 0.035;
// EL DEGRADÉ (en prueba, tests/glass_tint_look; el usuario: «un shader de gradiente para el vidrio para que al medio se
// vea más»): 0, parejo; 1, según el ángulo con el frente de la cápsula (`center`, `forward`: claro adelante, teñido
// hacia los bordes); 2, según la pantalla (claro en el medio de lo que se mira); 3, según lo de costado que se lo mira.
// El tinte va de `clear_alpha` (lo claro) a `edge_alpha` (lo teñido); `spread`, cuánto ocupa lo claro.
uniform int gradient = 1;
uniform float edge_alpha : hint_range(0.0, 1.0) = 0.45;
uniform float spread : hint_range(0.05, 2.0) = 0.6;
uniform vec3 center = vec3(0.0);
uniform vec3 forward = vec3(0.0, 0.0, -1.0);

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float total = 0.0;
	float weight = 0.5;
	for (int i = 0; i < 4; i++) {
		total += weight * noise(p);
		p *= 2.03;
		weight *= 0.5;
	}
	return total;
}

void fragment() {
	vec3 cell = (floor(local_pos / pixel) + 0.5) * pixel;
	float smudge = step(smudge_threshold + 0.1, fbm(cell * smudge_scale));
	ALBEDO = mix(tint, vec3(0.16, 0.19, 0.16), smudge * 0.6);
	float edge = 0.0;
	if (gradient == 1) {
		edge = smoothstep(0.0, spread, acos(clamp(dot(normalize(local_pos - center), forward), -1.0, 1.0)) / 1.5708);
	} else if (gradient == 2) {
		edge = smoothstep(0.0, spread, length(SCREEN_UV - vec2(0.5)) * 2.0);
	} else if (gradient == 3) {
		edge = smoothstep(0.0, spread, 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))));
	}
	ALPHA = mix(clear_alpha, edge_alpha, edge) + smudge * smudge_alpha;
	ROUGHNESS = mix(0.06, 0.3, smudge);
	SPECULAR = 0.6;
}
