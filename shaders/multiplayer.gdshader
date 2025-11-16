shader_type canvas_item;

const vec3 MAGENTA = vec3(1.0, 0.0, 1.0);
uniform vec3 replacement_color: source_color = vec3(1.0, 0.0, 1.0);
uniform vec4 blink_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float blink_intensity = 0.0;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);

	if (original_color.rgb == MAGENTA) {
		COLOR = vec4(replacement_color, original_color.a);
	} else {
		COLOR = mix(original_color, blink_color, blink_intensity * original_color.a);
	}
}