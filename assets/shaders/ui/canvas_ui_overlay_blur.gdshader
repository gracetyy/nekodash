// UI overlay blur used for modal presentation above gameplay.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float blur_strength : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float dim_alpha : hint_range(0.0, 1.0, 0.01) = 0.34;
uniform vec3 dim_tint = vec3(0.22, 0.18, 0.25);

void fragment() {
	vec2 step_uv = SCREEN_PIXEL_SIZE * blur_strength;
	vec4 center = textureLod(screen_texture, SCREEN_UV, 0.0);
	vec4 sample_x1 = textureLod(screen_texture, SCREEN_UV + vec2(step_uv.x, 0.0), 0.0);
	vec4 sample_x2 = textureLod(screen_texture, SCREEN_UV - vec2(step_uv.x, 0.0), 0.0);
	vec4 sample_y1 = textureLod(screen_texture, SCREEN_UV + vec2(0.0, step_uv.y), 0.0);
	vec4 sample_y2 = textureLod(screen_texture, SCREEN_UV - vec2(0.0, step_uv.y), 0.0);

	vec4 blurred = (center * 0.36) + ((sample_x1 + sample_x2 + sample_y1 + sample_y2) * 0.16);
	vec3 tinted = mix(blurred.rgb, dim_tint, dim_alpha);
	COLOR = vec4(tinted, 1.0);
}
