shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

void fragment() {
	float horizon = smoothstep(0.05, 0.95, UV.y);
	float haze = sin(UV.x * 14.0 + TIME * 0.08) * sin(UV.y * 9.0 - TIME * 0.05) * 0.025;
	float specks = step(0.995, fract(sin(dot(floor(UV * vec2(110.0, 67.0)), vec2(12.9898, 78.233))) * 43758.5453));
	vec3 deep = vec3(0.004, 0.019, 0.034);
	vec3 upper = vec3(0.015, 0.055, 0.067);
	ALBEDO = mix(deep, upper, horizon * 0.55 + haze) + vec3(0.012, 0.028, 0.034) * specks * 0.22;
}
