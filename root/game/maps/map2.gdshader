shader_type spatial;
render_mode specular_toon;

uniform sampler2D random;

group_uniforms albedo;
uniform float albedo: hint_range(0.0, 1.0, 0.01) = 1;
uniform sampler2D albedo_texture: filter_nearest;
group_uniforms emission;
uniform float emission: hint_range(0.0, 32.0, 0.01) = 0;
uniform sampler2D emission_texture: filter_nearest;
group_uniforms lighting;
uniform float metallic: hint_range(0.0, 1.0, 0.01) = 0;
uniform float roughness: hint_range(0.0, 1.0, 0.01) = 1;
group_uniforms range;
uniform float view_range = 1;

uniform float distance_fade: hint_range(0.0, 100.0, 0.01) = 0;
group_uniforms scale;
uniform vec2 scale = vec2(1., 1.);
uniform bool is_cubic = false;

void fragment() {
	vec2 true_scale = scale;

	if (is_cubic)
		true_scale *= vec2(3., 2.);

	EMISSION.r = (
		UV.x/4.*cos(TIME)+
		UV.y/4.*sin(TIME)+
		UV.x*-sin(TIME/4.)+
		UV.y*-sin(TIME/4.)+
		sin(TIME));
	EMISSION.g = (
		UV.y/2.*cos(TIME)+
		UV.x/5.*sin(TIME)+
		UV.x*-sin(TIME/2.)+
		UV.x*-sin(TIME/8.)+
		sin(TIME));
	EMISSION.b = (
		UV.y*2.*sin(TIME)+
		UV.x*3.*sin(TIME)+
		UV.x*-cos(TIME/2.)+
		UV.y*-sin(TIME/8.)+
		sin(TIME));
	EMISSION += (1.-max(max(EMISSION.r, EMISSION.g), EMISSION.b))*vec3(1.);
	EMISSION = (1.0+EMISSION)/2.0;

	EMISSION *= texture(emission_texture, UV*true_scale).rgb*emission;
	//ALBEDO = (1.-max(max(EMISSION.r, EMISSION.g), EMISSION.b))*texture(albedo_texture, UV*true_scale).rgb*albedo;
	ALBEDO = (1.-max(max(EMISSION.r, EMISSION.g), EMISSION.b))*vec3(SCREEN_UV.x, SCREEN_UV.y, min(FRAGCOORD.a, 1.))/2.*texture(albedo_texture, UV*true_scale).rgb*albedo;
	ROUGHNESS = (1.-max(max(EMISSION.r, EMISSION.g), EMISSION.b))*roughness;
	METALLIC = (1.-max(max(EMISSION.r, EMISSION.g), EMISSION.b))*metallic;
	
	//ALPHA = min(pow(FRAGCOORD.a*view_range, distance_fade*view_range), 1)+(max(max(EMISSION.r, EMISSION.g), EMISSION.b));
}
