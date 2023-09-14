package shaders;

import flixel.system.FlxAssets.FlxShader;

class ColorInvert
{
	public var shader(default, null):ColorInvertShader;

	public var amount(default, set):Float = 0;

	public function new():Void
	{
		shader = new ColorInvertShader();
		shader.amount.value = [0];
	}

	function set_amount(val:Float):Float
	{
		amount = val;
		shader.amount.value[0] = val;
		return val;
	}
}

class ColorInvertShader extends FlxShader
{
	@:glFragmentSource('
        #pragma header

        uniform float amount;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

            color[0] = (color[0] * (1 - (amount * color[3]))) + ((1 - color[0]) * (amount * color[3]));
            color[1] = (color[1] * (1 - (amount * color[3]))) + ((1 - color[1]) * (amount * color[3]));
            color[2] = (color[2] * (1 - (amount * color[3]))) + ((1 - color[2]) * (amount * color[3]));

            gl_FragColor = color;
        }

    ')
	public function new()
	{
		super();
	}
}