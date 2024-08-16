package menus.freeplay;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.events.KeyboardEvent;

import data.Options;
import menus.UINavigation;
import game.PlayState;

using StringTools;

class FreeplaySandbox extends FlxSpriteGroup
{
	public static var characters:Array<String> = ["","",""];
	public static var stage:String = "";
	public static var chartSide:Int = 0;
	public static var playbackRate:Float = 1;
	public static var missLimit:Int = -1;

	public static var characterCount:Int = 3;
	public static var characterLabels:Array<String> = ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"];
	public static var characterList:Array<String> = [];
	public static var characterNames:Map<String, String>;
	public static var stageList:Array<String> = [];
	public static var stageNames:Map<String, String>;
	public static var sideList:Array<String> = ["#freeplay.sandbox.side.0", "#freeplay.sandbox.side.1"];

	public static function character(slot:Int, ?def:String = "")
	{
		if (PlayState.inStoryMode || PlayState.testingChart || slot >= characters.length)
			return def;
		return (characters[slot].trim() == "" ? def : characters[slot]);
	}

	public static function reloadLists()
	{
		var exceptionList:Array<String> = Paths.textData("exceptionList").replace("\r","").replace("\\","/").split("\n");
		characterList = Paths.listFilesSub("data/characters/", ".json");
		stageList = Paths.listFilesSub("data/stages/", ".json");

		var cPoppers:Array<String> = [];
		var sPoppers:Array<String> = [];
		for (e in exceptionList)
		{
			if (e.startsWith("characters/"))
			{
				var filter:String = e.substr("characters/".length);
				var filterMode:Int = 0;
				if (filter.endsWith("*"))
				{
					filter = filter.substr(0, filter.length - 1);
					filterMode = 1;
				}

				for (c in characterList)
				{
					if ((filterMode == 0 && c.toLowerCase() == filter.toLowerCase()) || (filterMode == 1 && c.toLowerCase().startsWith(filter.toLowerCase())))
						cPoppers.push(c);
				}
			}
			else if (e.startsWith("stages/"))
			{
				var filter:String = e.substr("stages/".length);
				var filterMode:Int = 0;
				if (filter.endsWith("*"))
				{
					filter = filter.substr(0, filter.length - 1);
					filterMode = 1;
				}

				for (s in stageList)
				{
					if ((filterMode == 0 && s.toLowerCase() == filter.toLowerCase()) || (filterMode == 1 && s.toLowerCase().startsWith(filter.toLowerCase())))
						sPoppers.push(s);
				}
			}
		}

		for (p in cPoppers)
			characterList.remove(p);

		for (p in sPoppers)
			stageList.remove(p);

		characterList.unshift("");
		stageList.unshift("");
		characterNames = Util.getCharacterNames(characterList);
		stageNames = Util.getStageNames(stageList);
	}

	public static function resetCharacterCount()
	{
		characterCount = 3;
		characterLabels = ["#freeplay.sandbox.character.0", "#freeplay.sandbox.character.1", "#freeplay.sandbox.character.2"];
	}

	public static function setCharacterCount(?c:Int = null, ?l:Array<String> = null)
	{
		if (c == null || l == null)
			resetCharacterCount();
		else
		{
			characterCount = c;
			characterLabels = l.copy();
		}
	}



	var state:FlxState;
	var options:Array<String> = [];
	var font:String = "VCR OSD Mono";
	var curSelected:Int = 0;
	var cursor:FlxText;
	var txtLeft:Array<FlxText> = [];
	var txtRight:Array<FlxText> = [];
	var sideListLang:Array<String>;
	var reloadFunc:Void->Void;
	var exitFunc:Void->Void;
	var nav:UINumeralNavigation;

	override public function new(state:FlxState, reloadFunc:Void->Void, exitFunc:Void->Void, ?font:String = "VCR OSD Mono")
	{
		super();
		this.state = state;
		this.font = font;
		this.reloadFunc = reloadFunc;
		this.exitFunc = exitFunc;

		if (characterCount > characters.length)
		{
			while (characterCount > characters.length)
				characters.push("");
		}

		sideListLang = [];
		for (s in sideList)
			sideListLang.push(Lang.get(s));

		var bg:FlxSprite = new FlxSprite().makeGraphic(800, 280 + (characterCount * 40), FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		screenCenter();

		for (i in 0...characterCount)
			options.push("character" + Std.string(i + 1));
		options.push("stage");
		options.push("side");
		options.push("playbackRate");
		options.push("missLimit");
		options.push("reset");
		options.push("exit");

		for (i in 0...options.length)
		{
			var labelString:String = Lang.get("#freeplay.sandbox." + options[i]);
			if (options[i].startsWith("character"))
			{
				labelString = Lang.get("#freeplay.sandbox.character", [options[i].substr(9)]);
				if (characterLabels != null && characterLabels.length > i)
					labelString = Lang.get(characterLabels[i], [Std.string(i + 1)]);
				if (!labelString.endsWith(":"))
					labelString += ":";
			}

			var txt:FlxText = new FlxText(20, 20 + (i * 40), 0, labelString, 32);
			txt.font = font;
			add(txt);
			txtLeft.push(txt);

			var txt2:FlxText = new FlxText(20, 20 + (i * 40), 0, "", 32);
			txt2.font = font;
			add(txt2);
			txtRight.push(txt2);
		}
		cursor = new FlxText(20, 20, 0, ">", 32);
		cursor.font = font;
		add(cursor);

		nav = new UINumeralNavigation(changeOption, changeSelection, acceptOption, function() {
			state.remove(this);
			state.remove(nav);
			exitFunc();
		}, changeSelection);
		nav.leftClick = nav.accept;
		nav.rightClick = nav.back;
		state.add(nav);

		changeSelection();
	}

	function changeSelection(?v:Int = 0)
	{
		curSelected = Util.loop(curSelected + v, 0, txtRight.length - 1);
		cursor.y = y + 20 + (curSelected * 40);

		for (t in txtLeft)
			t.x = cursor.x;
		txtLeft[curSelected].x += 30;
		updateAllTexts();
	}

	function acceptOption()
	{
		if (options[curSelected].startsWith("character"))
		{
			nav.locked = true;
			new FlxTimer().start(0.001, function(tmr) {
				state.add(new FreeplaySandboxMenu(state, characterList, characterNames, characters[curSelected], function(v) {
					nav.locked = false;
					characters[curSelected] = v;
					updateAllTexts();
				}, function() { nav.locked = false; }, font));
			});
		}
		else
		{
			switch (options[curSelected])
			{
				case "stage":
					nav.locked = true;
					new FlxTimer().start(0.001, function(tmr) {
						state.add(new FreeplaySandboxMenu(state, stageList, stageNames, stage, function(v) {
							nav.locked = false;
							stage = v;
							updateAllTexts();
						}, function() { nav.locked = false; }, font));
					});

				case "reset":
					for (i in 0...characters.length)
						characters[i] = "";
					stage = "";
					chartSide = 0;
					playbackRate = 1;
					missLimit = -1;

					reloadFunc();
					updateAllTexts();

				case "exit":
					state.remove(this);
					state.remove(nav);
					exitFunc();
			}
		}
	}

	function changeOption(?v:Int = 0)
	{
		switch (options[curSelected])
		{
			case "side":
				chartSide = Util.loop(chartSide + v, 0, sideList.length - 1);
				reloadFunc();
				updateAllTexts();

			case "playbackRate":
				if (FlxG.keys.pressed.SHIFT)
					playbackRate += 0.01 * v;
				else
					playbackRate += 0.05 * v;
				playbackRate = Math.round(playbackRate * 100) / 100;
				if (playbackRate < 0.05)
					playbackRate = 0.05;

				updateAllTexts();

			case "missLimit":
				missLimit += v;
				if (missLimit < -1)
					missLimit = -1;

				updateAllTexts();
		}
	}

	function updateAllTexts()
	{
		for (i in 0...characterCount)
		{
			if (characters[i] == "")
				txtRight[i].text = Lang.get("#freeplay.sandbox.default");
			else
				txtRight[i].text = (characterNames.exists(characters[i]) ? characterNames[characters[i]] : characters[i]);
		}
		if (stage == "")
			txtRight[characterCount].text = Lang.get("#freeplay.sandbox.default");
		else
			txtRight[characterCount].text = (stageNames.exists(stage) ? stageNames[stage] : stage);

		txtRight[characterCount + 1].text = sideListLang[chartSide];
		if (curSelected == characterCount + 1)
			txtRight[characterCount + 1].text = "< " + txtRight[characterCount + 1].text + " >";

		txtRight[characterCount + 2].text = Std.string(playbackRate);
		if (curSelected == characterCount + 2)
			txtRight[characterCount + 2].text = "< " + txtRight[characterCount + 2].text + " >";

		txtRight[characterCount + 3].text = Std.string(missLimit);
		if (missLimit < 0)
			txtRight[characterCount + 3].text = Lang.get("#freeplay.sandbox.missLimit.none");
		if (curSelected == characterCount + 3)
			txtRight[characterCount + 3].text = "< " + txtRight[characterCount + 3].text + " >";

		for (t in txtRight)
			t.x = x + members[0].width - 20 - t.width;
	}
}

class FreeplaySandboxMenu extends FlxSpriteGroup
{
	var OGlist:Array<String> = [];
	var list:Array<String> = [];
	var names:Map<String, String>;
	var texts:Array<FlxText> = [];
	var cursor:FlxText;
	var search:FlxText;
	var nav:UINumeralNavigation;
	var returnValue:String = "";

	var curSelected:Int = 0;
	var selOffset:Int = 0;

	override public function new(state:FlxState, _list:Array<String>, _names:Map<String, String>, def:String, acceptFunc:String->Void, exitFunc:Void->Void, ?font:String = "VCR OSD Mono")
	{
		super();

		OGlist = _list.copy();
		list = _list.copy();
		names = _names;

		var bg:FlxSprite = new FlxSprite().makeGraphic(800, 600, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		screenCenter();

		var searchHint:FlxText = new FlxText(20, 20, bg.width - 40, Lang.get("#freeplay.sandbox.searchHint"), 32);
		searchHint.font = font;
		searchHint.alignment = CENTER;
		add(searchHint);

		search = new FlxText(20, 60, 0, "", 32);
		search.font = font;
		add(search);

		for (i in 0...16)
		{
			var txt:FlxText = new FlxText(20, 100 + (i * 30), 0, "", 24);
			txt.font = font;
			add(txt);
			texts.push(txt);
		}
		cursor = new FlxText(20, 100, 0, ">", 24);
		cursor.font = font;
		add(cursor);

		nav = new UINumeralNavigation(null, changeSelection, function() {
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			state.remove(this);
			state.remove(nav);
			acceptFunc(returnValue);
			this.destroy();
		}, function() {
			state.remove(this);
			state.remove(nav);
			exitFunc();
			this.destroy();
		}, changeSelection);
		nav.leftClick = nav.accept;
		nav.rightClick = nav.back;
		state.add(nav);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		if (_list.indexOf(def) > -1)
			curSelected = _list.indexOf(def);
		changeSelection();
	}

	override public function destroy()
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		super.destroy();
	}

	function changeSelection(?v:Int = 0)
	{
		curSelected = Util.loop(curSelected + v, 0, list.length - 1);
		while (curSelected - selOffset >= texts.length)
			selOffset++;
		while (curSelected - selOffset < 0)
			selOffset--;
		cursor.y = y + 100 + ((curSelected - selOffset) * 30);

		for (t in texts)
			t.x = cursor.x;
		texts[curSelected - selOffset].x += 20;

		updateAllTexts();
	}

	function updateAllTexts()
	{
		for (i in 0...texts.length)
		{
			if (i + selOffset < list.length)
				texts[i].text = (names.exists(list[i + selOffset]) ? names[list[i + selOffset]] : list[i + selOffset]);
			else
				texts[i].text = "";
		}
		returnValue = list[curSelected];
	}

	function onKeyDown(e:KeyboardEvent)
	{
		if (Options.keyPressed("ui_accept"))
			return;

		var key:Int = e.keyCode;

		if (key == 8)
		{
			if (search.text.length > 0)
			{
				if (search.text.length > 1)
					search.text = search.text.substring(0, search.text.length - 1);
				else
					search.text = "";
				filterList();
			}
		}
		else if (key == 46)
		{
			search.text = "";
			filterList();
		}
		else
		{
			if (e.charCode == 0)
				return;

			var newText:String = String.fromCharCode(e.charCode);

			if (newText.length > 0)
				search.text += newText;

			filterList();
		}
	}

	function filterList()
	{
		list = [];
		for (l in OGlist)
		{
			var item:String = (names.exists(l) ? names[l] : l);
			if (search.text.trim() == "" || item.toLowerCase().indexOf(search.text.toLowerCase()) > -1)
				list.push(l);
		}
		changeSelection();
	}
}