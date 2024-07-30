package shaders;

import flixel.system.FlxAssets.FlxShader;

class ColorInvert extends FlxShader
{
	public var shader:ColorInvert;

	public var amount(default, set):Float = 0;

	function set_amount(val:Float):Float
	{
		amount = val;
		_amount.value[0] = val;
		return val;
	}

	@:glFragmentSource('
        #pragma header

        uniform float _amount;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

            color[0] = (color[0] * (1.0 - (_amount * color[3]))) + ((1.0 - color[0]) * (_amount * color[3]));
            color[1] = (color[1] * (1.0 - (_amount * color[3]))) + ((1.0 - color[1]) * (_amount * color[3]));
            color[2] = (color[2] * (1.0 - (_amount * color[3]))) + ((1.0 - color[2]) * (_amount * color[3]));

            gl_FragColor = color;
        }

    ')

	public function new()
	{
		super();
		shader = this;

		_amount.value = [0];
	}
}