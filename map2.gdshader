shader_type spatial;
render_mode blend_mul;

//void vertex() {
//}

void fragment() {
	float x = FRAGCOORD.a;
	x = 1.-exp(-pow(x/.01, 1.))*1.;
	//vec3 color = vec3(SCREEN_UV.x-SCREEN_UV.y/2., SCREEN_UV.y-SCREEN_UV.x/2., 1);
	//color.b -= color.x+color.y;
	vec3 color = vec3(.5);
	ALBEDO = x*color;
	ALBEDO *= 2.;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
