shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;

uniform vec3 velocity = vec3(0.);
uniform vec3 rotation = vec3(0.);

group_uniforms motion_blur;
uniform bool MOTION_BLUR_ENABLED = true;
uniform int SAMPLE_COUNT : hint_range(0, 128, 1) = 4;
uniform float INTENSITY: hint_range(0, 2, .01) = 1.;
uniform bool CORRECTION = true;
uniform bool ALTERNATIVE_CORRECTION = false;
uniform float LINEAR_INTENSITY = 1.;
uniform float RADIAL_INTENSITY = 1.;
uniform float MOTION_SEEKNESS = .25;


vec4 motion_blur_fragment(in vec2 _SCREEN_UV)
{
	vec2 offset = vec2(0.);
	offset += vec2(velocity.x, velocity.y) * LINEAR_INTENSITY;
	offset += vec2(rotation.y, rotation.x) * RADIAL_INTENSITY;
	if (velocity.z <= 0.)
		offset += (_SCREEN_UV*2.-1.)*((-.5*velocity.z)/(velocity.z-1.));
	else
		offset += (_SCREEN_UV*2.-1.)*velocity.z;
	if (CORRECTION)
	{
		vec2 correction = vec2(sign(offset.x)/2.+.5, sign(offset.y)/2.+.5);
		correction = vec2(
			(correction.x * (1.-_SCREEN_UV.x) + (1.-correction.x) * _SCREEN_UV.x), 
			(correction.y * (1.-_SCREEN_UV.y) + (1.-correction.y) * _SCREEN_UV.y)
		);
		if (ALTERNATIVE_CORRECTION)
		{
			offset.x = offset.x * correction.x * (correction.y/2.+.5);
			offset.y = offset.y * correction.y * (correction.x/2.+.5);
		} else {
			offset.x = offset.x * correction.x;
			offset.y = offset.y * correction.y;
		};
	}
	vec4 out_color = texture(SCREEN_TEXTURE, _SCREEN_UV);
	for (int i=SAMPLE_COUNT; i>0; i--)
	{
		vec2 uv = _SCREEN_UV + offset * (float(i)/float(SAMPLE_COUNT))*MOTION_SEEKNESS;
		uv = vec2(clamp(uv.x, 0, 1), clamp(uv.y, 0, 1));
		out_color += texture(SCREEN_TEXTURE, uv) * INTENSITY;
		out_color /= 1.+INTENSITY;
	}
	out_color += texture(SCREEN_TEXTURE, _SCREEN_UV) * INTENSITY;
	out_color /= 1.+INTENSITY;
	return out_color;
}


void fragment() {
	if (MOTION_BLUR_ENABLED)
		COLOR = motion_blur_fragment(SCREEN_UV);
	else
		texture(SCREEN_TEXTURE, SCREEN_UV);
}
