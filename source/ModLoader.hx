#if ALLOW_MODS
package;

import polymod.Polymod;
import sys.FileSystem;
import sys.io.File;
import lime.app.Application;
import lime.graphics.Image;
import PackagesState;

using StringTools;

typedef ModMenus =
{
	var story:String;
	var freeplay:String;
}

class ModLoader
{
	public static var modListFile:String = "modList";
	public static var packageData:ModPackage = null;
	public static var packagePath:String = "";

	public static var modList:Array<Array<Dynamic>>;
	public static var modMetaList:Array<polymod.ModMetadata>;
	public static var modListLoaded:Array<String>;
	public static var modMetaListLoaded:Array<polymod.ModMetadata>;
	public static var modsEnabledByDefault:Bool = true;
	public static var hiddenMods:Array<String> = [];
	public static var modMenus:Map<String, ModMenus> = new Map<String, ModMenus>();

	public static function initMods()
	{
		if (Sys.args().contains("-package") && Sys.args().length > Sys.args().indexOf("-package") + 1)
		{
			if (FileSystem.exists("packages/" + Sys.args()[Sys.args().indexOf("-package") + 1] + "/data.json"))
			{
				packagePath = Sys.args()[Sys.args().indexOf("-package") + 1];
				packageData = PackagesState.loadPackage(packagePath);
			}
			else
				Application.current.window.alert("Unable to find packages/" + Sys.args()[Sys.args().indexOf("-package") + 1] + "/data.json\nLoading default mod list", "Alert");
		}
		else if (Sys.args().contains("-modlist") && Sys.args().length > Sys.args().indexOf("-modlist") + 1)
		{
			if (FileSystem.exists(Sys.args()[Sys.args().indexOf("-modlist") + 1] + ".txt"))
				modListFile = Sys.args()[Sys.args().indexOf("-modlist") + 1];
			else
				Application.current.window.alert("Unable to find " + Sys.args()[Sys.args().indexOf("-modlist") + 1] + ".txt\nLoading default mod list", "Alert");
		}

		modList = [];
		var defaultModList:Array<Array<Dynamic>> = [];
		if (packageData == null)
		{
			if (FileSystem.exists(modListFile + ".txt"))
			{
				var modStringList:Array<String> = File.getContent(modListFile + ".txt").replace("\r","").split("\n");
				for (modString in modStringList)
				{
					if (modString == "!")
						modsEnabledByDefault = false;
					else if (modString.split(",")[1] == "true]")
						modList.push([modString.split("[")[1].split(",")[0], true]);
					else
						modList.push([modString.split("[")[1].split(",")[0], false]);
				}
			}
		}
		else
		{
			if (FileSystem.exists("modList.txt"))
			{
				var modStringList:Array<String> = File.getContent("modList.txt").replace("\r","").split("\n");
				for (modString in modStringList)
				{
					if (modString.split(",")[1] == "true]")
						defaultModList.push([modString.split("[")[1].split(",")[0], true]);
				}
			}

			for (mod in defaultModList)
			{
				if (haxe.Json.parse(File.getContent("mods/" + mod[0] + "/_polymod_meta.json")).allowedInPackages)
					modList.push(mod);
			}

			modsEnabledByDefault = false;
			if (packageData.excludeBase != null)
				PackagesState.excludeBase = packageData.excludeBase;
			if (packageData.allowModTools != null)
				PackagesState.allowModTools = packageData.allowModTools;
			else
				PackagesState.allowModTools = false;
			var modStringList:Array<String> = packageData.mods;
			for (modString in modStringList)
				modList.push([modString, true]);

			if (packageData.windowName != null)
			{
				Application.current.window.title = packageData.windowName;
				Main.windowTitle = packageData.windowName;
			}
			if (FileSystem.exists("packages/" + packagePath + "/icon.png"))
				Application.current.window.setIcon(Image.fromFile("packages/" + packagePath + "/icon.png"));
		}

		var modsInModList:Array<String> = [];
		for (mod in modList)
			modsInModList.push(mod[0]);

		modMetaList = Polymod.scan({});
		var modMetaStrings:Array<String> = [];
		for (mod in modMetaList)
		{
			modMetaStrings.push(mod.id);
			if (!modsInModList.contains(mod.id))
			{
				var startDisabled:Bool = haxe.Json.parse(File.getContent("mods/" + mod.id + "/_polymod_meta.json")).start_disabled;
				if (startDisabled)
					modList.push([mod.id, false]);
				else
					modList.push([mod.id, modsEnabledByDefault]);
			}
		}

		var poppers:Array<Array<Dynamic>> = [];
		for (mod in modList)
		{
			if (!modMetaStrings.contains(mod[0]))
				poppers.push(mod);
		}

		for (p in poppers)
			modList.remove(p);

		saveModlist();

		var loadedMods:Array<String> = [];
		hiddenMods = [];
		for (mod in modList)
		{
			var parsedMetadata:Dynamic = haxe.Json.parse(File.getContent("mods/" + mod[0] + "/_polymod_meta.json"));
			if (mod[1])
				loadedMods.push(mod[0]);
			if (parsedMetadata.hidden)
				hiddenMods.push(mod[0]);
			if (parsedMetadata.menus != null)
			{
				modMenus[mod[0]] = cast parsedMetadata.menus;
				if (modMenus[mod[0]].story == null)
					modMenus[mod[0]].story = mod[0] + "-story";
				if (modMenus[mod[0]].freeplay == null)
					modMenus[mod[0]].freeplay = mod[0] + "-freeplay";
			}
			else
				modMenus[mod[0]] = {story: mod[0] + "-story", freeplay: mod[0] + "-freeplay"};
		}

		if (packageData != null && FileSystem.isDirectory("packages/" + packagePath + "/content"))
			loadedMods.push("../packages/" + packagePath + "/content");

		modMetaListLoaded = Polymod.init({
			modRoot: "mods",
			dirs: loadedMods
		});
		modListLoaded = [];
		for (mod in modMetaListLoaded)
		{
			if (mod.id != null && mod.id.indexOf("../packages") <= -1)
				modListLoaded.push(mod.id);
		}
	}

	public static function getModMetaData(modID:String):polymod.ModMetadata
	{
		for (mod in modMetaList)
		{
			if (mod.id == modID)
				return mod;
		}

		return null;
	}

	public static function saveModlist()
	{
		if (modListFile == "modList" && packageData == null)
			File.saveContent("modList.txt", (modsEnabledByDefault ? "" : "!\n") + modList.join("\n"));
	}
}
#end