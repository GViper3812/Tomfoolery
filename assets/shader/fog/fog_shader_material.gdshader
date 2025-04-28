shader_type spatial;
render_mode blend_mix, unshaded;

uniform sampler2D fog_view;
uniform float alpha_strength = 1.0;

void fragment() {
	float vis = texture(fog_view, UV).r;
	ALBEDO = vec3(0.0);
	ALPHA = (0.98 - vis) * alpha_strength;
}
