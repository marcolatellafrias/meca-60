shader_type spatial;
// EL CAMPO DEL ESCUDO DE FUERZA (MechShield): casi transparente donde se lo mira de frente y más visible en el borde
// (fresnel), con las caras planas si es low poly y, si se pide, las aristas marcadas (el color de cada vértice es su
// coordenada baricéntrica: ver MechShield.icosphere). `strength` lo prende, lo apaga y hace el destello.
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.45, 0.8, 1.0, 1.0);
uniform float center_alpha = 0.16;
uniform float rim_alpha = 0.16;
uniform float rim_power = 2.5;
uniform float line_alpha = 0.0;
uniform float line_width = 0.04;
uniform float flat_facets = 0.0;
uniform float strength = 1.0;

void fragment() {
	vec3 n = normalize(NORMAL);
	if (flat_facets > 0.5) {
		n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	}
	float facing = abs(dot(n, normalize(VIEW)));
	float rim = pow(1.0 - facing, rim_power);
	float alpha = mix(center_alpha, rim_alpha, rim);
	float edge = 1.0 - smoothstep(0.0, line_width, min(COLOR.r, min(COLOR.g, COLOR.b)));
	alpha += edge * line_alpha;
	ALBEDO = mix(tint.rgb, vec3(1.0), edge * line_alpha * 0.4);
	ALPHA = clamp(alpha * strength, 0.0, 1.0);
}
