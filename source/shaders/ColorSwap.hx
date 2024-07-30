package shaders;

// stolen from base with some mods to make it more versatile

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class ColorSwap extends FlxShader
{
	public var shader:ColorSwap;

	public var h(default, set):Float = 0;
	public var s(default, set):Float = 0;
	public var v(default, set):Float = 0;
	public var hAdd(default, set):Bool = true;
	public var sAdd(default, set):Bool = false;
	public var vAdd(default, set):Bool = false;
	public var useHueLimit(default, set):Bool = false;
	public var hueLimitA(default, set):Float = 0;
	public var hueLimitB(default, set):Float = 0;

	public function setHSV(vals:Array<Float>)
	{
		h = vals[0];
		s = vals[1];
		v = vals[2];
	}

	function set_h(val:Float):Float
	{
		h = val;
		_h.value[0] = val;
		return val;
	}

	function set_s(val:Float):Float
	{
		s = val;
		_s.value[0] = val;
		return val;
	}

	function set_v(val:Float):Float
	{
		v = val;
		_v.value[0] = val;
		return val;
	}

	function set_hAdd(val:Bool):Bool
	{
		hAdd = val;
		_hAdd.value = [val];
		return val;
	}

	function set_sAdd(val:Bool):Bool
	{
		sAdd = val;
		_sAdd.value = [val];
		return val;
	}

	function set_vAdd(val:Bool):Bool
	{
		vAdd = val;
		_vAdd.value = [val];
		return val;
	}

	function set_useHueLimit(val:Bool):Bool
	{
		useHueLimit = val;
		_useHueLimit.value = [val];
		return val;
	}

	function set_hueLimitA(val:Float):Float
	{
		hueLimitA = val;
		_hueLimitA.value[0] = val;
		return val;
	}

	function set_hueLimitB(val:Float):Float
	{
		hueLimitB = val;
		_hueLimitB.value[0] = val;
		return val;
	}

	@:glFragmentSource('
		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;
		uniform sampler2D bitmap;

		uniform bool hasTransform;
		uniform bool hasColorTransform;

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
		{
			vec4 color = texture2D(bitmap, coord);

			if (!hasTransform)
			{
				return color;
			}

			if (color.a == 0.0)
			{
				return vec4(0.0, 0.0, 0.0, 0.0);
			}

			if (!hasColorTransform)
			{
				return color * openfl_Alphav;
			}

			color = vec4(color.rgb / color.a, color.a);

			mat4 colorMultiplier = mat4(0);
			colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
			colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
			colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
			colorMultiplier[3][3] = openfl_ColorMultiplierv.w;

			color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);

			if (color.a > 0.0)
			{
				return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			}

			return vec4(0.0, 0.0, 0.0, 0.0);
		}

        uniform float _h;
        uniform float _s;
        uniform float _v;
        uniform bool _hAdd;
        uniform bool _sAdd;
        uniform bool _vAdd;
        uniform bool _useHueLimit;
        uniform float _hueLimitA;
        uniform float _hueLimitB;

        vec3 rgb2hsv(vec3 c)
        {
            vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
            vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }

        vec3 hsv2rgb(vec3 c)
        {
            vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        void main()
        {
			if (_h != 0.0 || _hAdd == false || _s != 0.0 || _v != 0.0)
			{
				vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

				vec4 swagColor = vec4(rgb2hsv(vec3(color[0], color[1], color[2])), color[3]);
				float oldH = swagColor[0];

				if (_hAdd)
					swagColor[0] += _h;
				else
					swagColor[0] = _h;

				if (_sAdd || swagColor[1] <= 0.0)
					swagColor[1] += _s;
				else
					swagColor[1] *= _s + 1.0;

				if (_vAdd)
					swagColor[2] += _v * color[3];
				else if (_v > 0.0)
					swagColor[2] += _v * (1.0 - swagColor[2]) * color[3];
				else
					swagColor[2] += _v * swagColor[2];

				color = vec4(hsv2rgb(vec3(swagColor[0], swagColor[1], swagColor[2])), swagColor[3]);

				if (_useHueLimit && (oldH < _hueLimitA || oldH > _hueLimitB))
					gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
				else
					gl_FragColor = color;
			}
			else
				gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
        }

    ')

	@:glVertexSource('
		attribute float openfl_Alpha;
		attribute vec4 openfl_ColorMultiplier;
		attribute vec4 openfl_ColorOffset;
		attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;

		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform mat4 openfl_Matrix;
		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;

		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;

		void main(void)
		{
			openfl_Alphav = openfl_Alpha;
			openfl_TextureCoordv = openfl_TextureCoord;

			if (openfl_HasColorTransform)
			{
				openfl_ColorMultiplierv = openfl_ColorMultiplier;
				openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
			}

			gl_Position = openfl_Matrix * openfl_Position;

			openfl_Alphav = openfl_Alpha * alpha;

			if (hasColorTransform)
			{
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}
		}')

	public function new()
	{
		super();

		shader = this;
		_h.value = [h];
		_s.value = [s];
		_v.value = [v];
		_hAdd.value = [hAdd];
		_sAdd.value = [sAdd];
		_vAdd.value = [vAdd];
		_useHueLimit.value = [useHueLimit];
		_hueLimitA.value = [hueLimitA];
		_hueLimitB.value = [hueLimitB];
	}
}