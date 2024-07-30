package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class ColorFade extends FlxShader
{
	public var shader:ColorFade;

	public var color(default, set):FlxColor = FlxColor.WHITE;
	public var amount(default, set):Float = 0;

	function set_color(val:FlxColor):FlxColor
	{
		color = val;
		rgb.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return val;
	}

	function set_amount(val:Float):Float
	{
		amount = val;
		_amount.value[0] = val;
		return val;
	}

	@:glFragmentSource('
        #pragma header

        uniform vec3 rgb;
        uniform float _amount;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

            color[0] += (rgb[0] - color[0]) * _amount * color[3];
            color[1] += (rgb[1] - color[1]) * _amount * color[3];
            color[2] += (rgb[2] - color[2]) * _amount * color[3];

            gl_FragColor = color;
        }

    ')

	public function new()
	{
		super();
		shader = this;

		rgb.value = [1, 1, 1];
		_amount.value = [0];
	}
}