shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform float opacity : hint_range(0.0, 1.0) = 0.0;
uniform float tail_phase = 0.0;
uniform vec4 silhouette_color : source_color = vec4(0.11, 0.25, 0.30, 1.0);

void fragment() {
	float x = UV.x;
	float y = UV.y - 0.5;
	float sway = sin(x * 11.0 + tail_phase) * 0.035 * (1.0 - smoothstep(0.28, 0.78, x));
	float girth = mix(0.025, 0.19, smoothstep(0.06, 0.60, x));
	girth *= 1.0 - smoothstep(0.75, 0.97, x) * 0.66;
	float body = (1.0 - smoothstep(girth - 0.015, girth + 0.015, abs(y - sway))) * smoothstep(0.06, 0.18, x) * (1.0 - smoothstep(0.95, 1.0, x));
	float top_fin = step(0.44, x) * step(x, 0.67) * step(-0.34 + (x - 0.44) * 0.72, y) * step(y, -0.12);
	float lower_fin = step(0.52, x) * step(x, 0.76) * step(0.10, y) * step(y, 0.32 - (x - 0.52) * 0.56);
	float tail = step(x, 0.18) * step(abs(y - sway), 0.27 - x * 0.88);
	float silhouette = max(max(body, top_fin), max(lower_fin, tail));
	float eye = 1.0 - smoothstep(0.006, 0.016, length(vec2((x - 0.87) * 1.2, y + 0.025)));
	ALBEDO = silhouette_color.rgb + vec3(0.02, 0.04, 0.045) * sin(UV.x * 22.0 + TIME * 0.25);
	EMISSION = vec3(0.20, 0.50, 0.53) * eye * opacity * 0.45;
	ALPHA = clamp(silhouette * opacity + eye * opacity * 0.65, 0.0, 1.0);
}
