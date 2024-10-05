#pragma header

uniform sampler2D image;
uniform vec3 rgb;

void main()
{
	vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv);
	vec4 tex2 = flixel_texture2D(image, openfl_TextureCoordv);

	vec4 finalColor = mix(tex, vec4(rgb * tex.a, tex.a), tex2.a);

	gl_FragColor = finalColor;
}