#pragma header

uniform sampler2D image;
uniform float fadeAmount;

void main()
{
	vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv);
	vec4 tex2 = flixel_texture2D(image, openfl_TextureCoordv);

	vec4 finalColor = mix(tex, vec4(tex2.rgb, tex.a), fadeAmount);

	gl_FragColor = finalColor;
}