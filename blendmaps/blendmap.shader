shader_type canvas_item;
render_mode unshaded;
uniform int border = 4;
uniform sampler2D tex_mesh;
void fragment()
{
	vec2 ps = vec2(1.0 / 1024.0, 1.0 / 1024.0);
	// COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	// vec3 c = texture(tex_mesh, UV).rgb;
	
	vec3 c = texture(tex_mesh, UV).rgb;
	if (length(c) == 0.0) {
		for (int j = -border; j < border + 1; j++) {
			for (int i = -border; i < border + 1; i++) {
				vec3 cn = max(c, texture(tex_mesh, UV + vec2(float(i), float(j)) * ps).rgb);
				c = cn;
			}
		}
	}
	
	COLOR.rgb = c;
	COLOR.a = 1.0;
}
