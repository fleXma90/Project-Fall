// M2D.1-Blockout: selbst geschriebener Tiefenschein unter der aktuellen Ebene (Glut im Nebel).
// Additiv, unbeleuchtet, ohne Tiefe schreiben; kein Produktionsmaterial.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 glow_color : source_color = vec3(1.0, 0.36, 0.09);
uniform float intensity = 0.045;
uniform float drift = 0.04;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	float falloff = 1.0 - smoothstep(0.0, 0.75, d);
	float n = noise(world_pos.xz * 0.12 + vec2(TIME * drift, -TIME * drift * 0.7));
	n = n * 0.7 + noise(world_pos.xz * 0.35 - TIME * drift) * 0.3;
	// Fleckige Glutnester statt gleichmäßiger Fläche: überwiegend dunkel.
	float nests = smoothstep(0.55, 0.9, n);
	ALBEDO = glow_color * intensity * falloff * (0.15 + 1.6 * nests);
}
