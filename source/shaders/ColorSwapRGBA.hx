package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class ColorSwapRGBA extends FlxShader
{
	public var shader:ColorSwapRGBA;

	public function reset(colorVals:Array<String>, colors:Array<FlxColor>)
	{
		if (colorVals.length == colors.length)
		{
			for (i in 0...colorVals.length)
			{
				switch (colorVals[i])
				{
					case "r": r.value = [colors[i].redFloat, colors[i].greenFloat, colors[i].blueFloat];
					case "ir": ir.value = [colors[i].redFloat, colors[i].greenFloat, colors[i].blueFloat];
					case "g": g.value = [colors[i].redFloat, colors[i].greenFloat, colors[i].blueFloat];
					case "ig": ig.value = [colors[i].redFloat, colors[i].greenFloat, colors[i].blueFloat];
					case "b": b.value = [colors[i].redFloat, colors[i].greenFloat, colors[i].blueFloat];
					case "ib": ib.value = [colors[i].redFloat, colors[i].greenFloat, colors[i].blueFloat];
				}
			}
		}
	}

	@:glFragmentSource('
        #pragma header

        uniform vec3 r;
        uniform vec3 g;
        uniform vec3 b;
        uniform vec3 ir;
        uniform vec3 ig;
        uniform vec3 ib;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            vec3 newColor = vec3(0.0, 0.0, 0.0);
			newColor[0] = (r[0] * color[0]) + (ir[0] * (1.0 - color[0])) + (g[0] * color[1]) + (ig[0] * (1.0 - color[1])) + (b[0] * color[2]) + (ib[0] * (1.0 - color[2]));
			newColor[1] = (r[1] * color[0]) + (ir[1] * (1.0 - color[0])) + (g[1] * color[1]) + (ig[1] * (1.0 - color[1])) + (b[1] * color[2]) + (ib[1] * (1.0 - color[2]));
			newColor[2] = (r[2] * color[0]) + (ir[2] * (1.0 - color[0])) + (g[2] * color[1]) + (ig[2] * (1.0 - color[1])) + (b[2] * color[2]) + (ib[2] * (1.0 - color[2]));

            gl_FragColor = vec4(newColor, color[3]);
        }

    ')

	public function new(colorVals:Array<String>, colors:Array<FlxColor>)
	{
		super();
		shader = this;

		r.value = [0, 0, 0];
		g.value = [0, 0, 0];
		b.value = [0, 0, 0];
		ir.value = [0, 0, 0];
		ig.value = [0, 0, 0];
		ib.value = [0, 0, 0];
		reset(colorVals, colors);
	}
}