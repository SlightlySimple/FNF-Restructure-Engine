#pragma header

		// Modified version of a tilt shift shader from Martin Jonasson (http://grapefrukt.com/)
		// Read http://notes.underscorediscovery.com/ for context on shaders and this file
		// License : MIT

			/*
				Take note that blurring in a single pass (the two for loops below) is more expensive than separating
				the x and the y blur into different passes. This was used where bleeding edge performance
				was not crucial and is to illustrate a point.

				The reason two passes is cheaper?
				   texture2D is a fairly high cost call, sampling a texture.

				   So, in a single pass, like below, there are 3 steps, per x and y.

				   That means a total of 9 "taps", it touches the texture to sample 9 times.

				   Now imagine we apply this to some geometry, that is equal to 16 pixels on screen (tiny)
				   (16 * 16) * 9 = 2304 samples taken, for width * height number of pixels, * 9 taps
				   Now, if you split them up, it becomes 3 for x, and 3 for y, a total of 6 taps
				   (16 * 16) * 6 = 1536 samples

				   That\'s on a *tiny* sprite, let\'s scale that up to 128x128 sprite...
				   (128 * 128) * 9 = 147,456
				   (128 * 128) * 6 =  98,304

				   That\'s 33.33..% cheaper for splitting them up.
				   That\'s with 3 steps, with higher steps (more taps per pass...)

				   A really smooth, 6 steps, 6*6 = 36 taps for one pass, 12 taps for two pass
				   You will notice, the curve is not linear, at 12 steps it\'s 144 vs 24 taps
				   It becomes orders of magnitude slower to do single pass!
				   Therefore, you split them up into two passes, one for x, one for y.
			*/

		vec4 blur13(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
			vec4 color = vec4(0.0);
			vec2 off1 = vec2(1.411764705882353) * direction;
			vec2 off2 = vec2(3.2941176470588234) * direction;
			vec2 off3 = vec2(5.176470588235294) * direction;
			color += texture2D(image, uv) * 0.1964825501511404;
			color += texture2D(image, uv + (off1 / resolution)) * 0.2969069646728344;
			color += texture2D(image, uv - (off1 / resolution)) * 0.2969069646728344;
			color += texture2D(image, uv + (off2 / resolution)) * 0.09447039785044732;
			color += texture2D(image, uv - (off2 / resolution)) * 0.09447039785044732;
			color += texture2D(image, uv + (off3 / resolution)) * 0.010381362401148057;
			color += texture2D(image, uv - (off3 / resolution)) * 0.010381362401148057;
			return color;
		}

    uniform float BLX;
    uniform float BLY;
    uniform float _alpha;

	void main()
    {
			vec4 blurred;

			vec4 blurredShit = blur13(bitmap, openfl_TextureCoordv, openfl_TextureSize.xy, vec2(0.0, BLY / 5.0));
			blurredShit = mix(blur13(bitmap, openfl_TextureCoordv, openfl_TextureSize.xy, vec2(BLX / 5.0, 0.0)), blurredShit, 0.5);
			blurredShit *= _alpha;

			// return the final blurred color
			gl_FragColor = blurredShit;
    }
