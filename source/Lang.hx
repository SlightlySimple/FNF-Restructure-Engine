package;

import data.Options;

using StringTools;

class Lang
{
	static var lang:Map<String, String>;

	public static function init()
	{
		lang = new Map<String, String>();

		var langFile:Array<String> = [];
		for (f in Paths.listFiles("data/lang/", ".txt"))
		{
			for (l in Paths.raw("data/lang/" + f + ".txt").replace("\r","").split("\n"))			// Don't try to load a "censored" lang file, as we use a replacement system instead
				langFile.push(l);
		}

		for (l in langFile)
		{
			if (!l.trim().startsWith("//"))
			{
				var k:String = "";
				var v:String = "";

				var startInd:Int = 0;
				var state:Int = 0;

				for (i in 0...l.length)
				{
					var c:String = l.charAt(i);
					var c2:String = "";
					if (i > 0)
						c2 = l.charAt(i-1);

					if (c == "\"")
					{
						switch (state)
						{
							case 0: startInd = i+1; state = 1;
							case 1: k = l.substring(startInd, i); state = 2;
							case 2: startInd = i+1; state = 3;
							case 3: if (c2 != "\\") { v = l.substring(startInd, i); state = 4; }
						}
					}
				}

				if (state == 4 && k.trim().length > 0)
					lang[k.trim()] = v.replace("\\\"", "\"").replace("\\n", "\n");
			}
		}
	}

	public static function get(k:String, rep:Array<String> = null)
	{
		if (!k.startsWith("#"))
			return k;

		var trueK:String = k.substr(1);
		if (!Options.options.naughtiness && lang.exists(trueK + "Censor"))
			trueK += "Censor";

		if (lang.exists(trueK))
		{
			var v:String = lang[trueK];
			if (rep != null && rep.length > 0)
			{
				for (i in 0...rep.length)
					v = v.replace("%s"+Std.string(i+1), rep[i]);
			}
			return v;
		}

		return k;
	}

	public static function getNoHash(k:String, rep:Array<String> = null)
	{
		var trueK:String = k.toLowerCase();
		if (!Options.options.naughtiness && lang.exists(trueK + "Censor"))
			trueK += "Censor";

		if (lang.exists(trueK))
		{
			var v:String = lang[trueK];
			if (rep != null && rep.length > 0)
			{
				for (i in 0...rep.length)
					v = v.replace("%s"+Std.string(i+1), rep[i]);
			}
			return v;
		}

		return k;
	}
}