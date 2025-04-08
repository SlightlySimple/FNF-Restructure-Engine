package editors.stage;

import flixel.addons.display.FlxRuntimeShader;
import data.ObjectData;

class StageEditorShader
{
	public var shader:FlxRuntimeShader;
	var data:StageShaderData = null;

	public function new()
	{
	}

	public function setData(_data:StageShaderData)
	{
		if (data == null || data.id != _data.id)
			shader = new FlxRuntimeShader(Paths.shader(_data.id));

		data = _data;
		for (f in Reflect.fields(data.parameters))
		{
			var val:Dynamic = Reflect.field(data.parameters, f);
			if (Std.isOfType(val, Float) || Std.isOfType(val, Int))
				shader.setFloat(f, cast val);
		}
	}
}