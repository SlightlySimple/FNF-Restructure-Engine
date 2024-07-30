#pragma header

uniform vec2 size;
uniform vec4 color;

void main()
{
	vec4 sample = flixel_texture2D(bitmap, openfl_TextureCoordv);
	if (sample.a == 0.) {
		float w = size.x / openfl_TextureSize.x;
		float h = size.y / openfl_TextureSize.y;

		if (flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x + w, openfl_TextureCoordv.y)).a != 0.
		|| flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x - w, openfl_TextureCoordv.y)).a != 0.
		|| flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y + h)).a != 0.
		|| flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y - h)).a != 0.)
			sample = color;
	}
	gl_FragColor = sample;
}