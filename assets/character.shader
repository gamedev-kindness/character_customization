shader_type spatial;
uniform sampler2D albedo_texture: hint_albedo;
uniform sampler2D deform: hint_black;
uniform sampler2D normal_deform: hint_black;
uniform float vertex_m = 0.0;
uniform float normal_m = 0.0;

float reverse_sigmoid(float y)
{
	return log(y / (1.0 - y));
}

void vertex()
{
	NORMAL = cross(TANGENT, BINORMAL);
	vec3 diff = textureLod(deform, vec2(UV.x, 1.0-UV.y), 0.0).rgb;
	vec3 diff_normal = texture(normal_deform, UV).rgb;
//	if (length(diff) > 0.0) {
//		diff = vec3(reverse_sigmoid(diff.x), reverse_sigmoid(diff.y), reverse_sigmoid(diff.z));
//	}
	diff = diff - vec3(0.5, 0.5, 0.5);
	if (length(diff_normal) > 0.0) {
		diff_normal = vec3(reverse_sigmoid(diff_normal.x), reverse_sigmoid(diff_normal.y), reverse_sigmoid(diff_normal.z));
	}
	VERTEX = VERTEX + diff * vertex_m;
	NORMAL = NORMAL + diff_normal * normal_m;
}

void fragment()
{
	ALBEDO = texture(albedo_texture, UV).rgb;
}
