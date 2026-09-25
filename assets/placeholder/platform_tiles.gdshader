// M1-Blockout: selbst erzeugtes Kachelraster für die Plattformoberseite (Bewegungslesbarkeit).
// Kein Produktionsmaterial.
shader_type spatial;
render_mode cull_back;

uniform vec3 base_color : source_color = vec3(0.19, 0.2, 0.23);
uniform vec3 seam_color : source_color = vec3(0.1, 0.105, 0.12);
uniform float tile_size = 1.0;
uniform float seam_width = 0.045;
uniform float variation = 0.07;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell = floor(world_pos.xz / tile_size);
	vec2 local = fract(world_pos.xz / tile_size);
	vec2 d = min(local, 1.0 - local);
	float seam = 1.0 - step(seam_width, min(d.x, d.y));
	vec3 tile = base_color * (1.0 + (hash(cell) - 0.5) * 2.0 * variation);
	ALBEDO = mix(tile, seam_color, seam);
	ROUGHNESS = 0.85;
	METALLIC = 0.15;
}
