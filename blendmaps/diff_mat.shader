shader_type canvas_item;
render_mode unshaded;

uniform sampler2D model;
uniform sampler2D base;

float sigmoid(float x)
{
	return 1.0 / (1.0 + exp(-x));
}
float reverse_sigmoid(float y)
{
	return log(y / (1.0 - y));
}

void fragment()
{
	vec3 b = textureLod(base, UV, 1.0).rgb;
	vec3 m = textureLod(model, UV, 1.0).rgb;
	if (length(b) > 0.0 && length(m) > 0.0) {
//		vec3 vb = vec3(reverse_sigmoid(b.x), reverse_sigmoid(b.y), reverse_sigmoid(b.z));
//		vec3 vm = vec3(reverse_sigmoid(m.x), reverse_sigmoid(m.y), reverse_sigmoid(m.z));
//		vec3 vd = (vm - vb);
		vec3 vd = (m - b);
//		COLOR = vec4(sigmoid(vd.x), sigmoid(vd.y), sigmoid(vd.z), 1.0);
		COLOR = vec4((vd.x + 1.0) * 0.5, (vd.y + 1.0) * 0.5, (vd.z + 1.0) * 0.5, 1.0);
	} else {
//		COLOR = vec4(sigmoid(0.0), sigmoid(0.0), sigmoid(0.0), 1.0);
		COLOR = vec4(0.5, 0.5, 0.5, 1.0);
	}
}
