package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class ColorFade
{
	public var shader(default, null):ColorFadeShader;

	public var color(default, set):FlxColor = FlxColor.WHITE;
	public var amount(default, set):Float = 0;

	public function new():Void
	{
		shader = new ColorFadeShader();
		shader.rgb.value = [1, 1, 1];
		shader.amount.value = [0];
	}

	function set_color(val:FlxColor):FlxColor
	{
		color = val;
		shader.rgb.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	function set_amount(val:Float):Float
	{
		amount = val;
		shader.amount.value[0] = val;
		return val;
	}
}

class ColorFadeShader extends FlxShader
{
	@:glFragmentSource('
        #pragma header

        uniform vec3 rgb;
        uniform float amount;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

            color[0] += (rgb[0] - color[0]) * amount * color[3];
            color[1] += (rgb[1] - color[1]) * amount * color[3];
            color[2] += (rgb[2] - color[2]) * amount * color[3];

            gl_FragColor = color;
        }

    ')
	public function new()
	{
		super();
	}
}