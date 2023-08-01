shader_type canvas_item;

void fragment() {
	float t = TIME/3.;
	vec4 color = vec4(-sin(t)+.5, sin(t)+.5, cos(t)+.5, 1.);
	color *= (.5+sin(t/.2)/4.);
	color += vec4(0., 0., 0., 1);
	color *= texture(TEXTURE, UV);
	COLOR = color;
}
