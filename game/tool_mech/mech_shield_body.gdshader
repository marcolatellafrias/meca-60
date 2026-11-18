shader_type spatial;
// EL ESCUDO PEGADO AL CUERPO (MechShield, estilos «cuerpo» y «frente»): una cáscara un poco más grande que cada pieza
// (`grow`, hacia afuera desde el centro de la pieza), casi transparente de frente y más visible en el borde (fresnel). Un
// golpe frenado la enciende donde pegó: un anillo que se agranda (`hit_wave`) y un brillo en el centro, que se apagan
// (`hit_strength`). En un panel (el de frente), `uv_border` le marca el borde.
render_mode unshaded, cull_back, depth_draw_never, blend_mix, shadows_disabled, world_vertex_coords;

uniform vec4 tint : source_color = vec4(0.45, 0.8, 1.0, 1.0);
uniform float grow = 0.06;
uniform float center_alpha = 0.02;
uniform float rim_alpha = 0.55;
uniform float rim_power = 2.0;
uniform float strength = 1.0;
uniform vec3 hit_point = vec3(0.0, -10000.0, 0.0);
uniform float hit_wave = 0.0;
uniform float hit_strength = 0.0;
uniform float uv_border = 0.0;

varying vec3 world_pos;

void vertex() {
	vec3 out_dir = VERTEX - NODE_POSITION_WORLD;
	if (length(out_dir) > 0.0001) {
		VERTEX += normalize(out_dir) * grow;
	}
	world_pos = VERTEX;
}

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(1.0 - facing, rim_power);
	float glow = mix(center_alpha, rim_alpha, rim);
	if (uv_border > 0.0) {
		float border = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
		glow += (1.0 - smoothstep(0.0, uv_border, border)) * rim_alpha;
	}
	float dist = distance(world_pos, hit_point);
	float ring = 1.0 - smoothstep(0.0, 0.3, abs(dist - hit_wave));
	float core = exp(-dist * 1.2);
	glow += hit_strength * (ring * 0.8 + core * 0.7);
	ALBEDO = mix(tint.rgb, vec3(1.0), clamp(hit_strength * core, 0.0, 0.6));
	ALPHA = clamp(glow * strength, 0.0, 1.0);
}
