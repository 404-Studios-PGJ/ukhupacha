shader_type canvas_item;
uniform vec4 ink : source_color;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float shade = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(ink.rgb * (0.75 + shade * 0.5), tex.a * COLOR.a);
}
