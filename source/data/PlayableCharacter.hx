package data;

typedef PlayableCharacter =
{
	var unlockCondition:PlayableCharacterUnlockCondition;
	var unlockData:PlayableCharacterUnlockData;
	var freeplayStyle:PlayableCharacterFreeplayStyle;
	var freeplayDJ:PlayableCharacterDJ;
	var charSelect:PlayableCharacterSelect;
}

typedef PlayableCharacterUnlockCondition = 
{
	var type:String;
	var id:String;
	var difficulties:Array<String>;
}

typedef PlayableCharacterUnlockData = 
{
	var name:String;
	var icon:String;
}

typedef PlayableCharacterFreeplayStyle =
{
	var bgAsset:String;
	var selectorAsset:String;
	var numbersAsset:String;
	var capsuleAsset:String;
	var capsuleTextColors:Array<String>;
	var startDelay:Float;
}

typedef PlayableCharacterDJ =
{
	var assetPath:String;
	var animations:Array<PlayableCharacterAnimation>;
	var fistPump:PlayableCharacterDJFistPump;
	var charSelect:PlayableCharacterDJSelect;
	var cartoon:PlayableCharacterDJCartoon;
}

typedef PlayableCharacterAnimation =
{
	var name:String;
	var prefix:String;
	var offsets:Array<Float>;
}

typedef PlayableCharacterDJFistPump =
{
	var introStartFrame:Int;
	var introEndFrame:Int;
	var loopStartFrame:Int;
	var loopEndFrame:Int;
	var introBadStartFrame:Int;
	var introBadEndFrame:Int;
	var loopBadStartFrame:Int;
	var loopBadEndFrame:Int;
}

typedef PlayableCharacterDJSelect =
{
	var transitionDelay:Float;
}

typedef PlayableCharacterDJCartoon =
{
	var soundClickFrame:Int;
	var soundCartoonFrame:Int;
	var loopBlinkFrame:Int;
	var loopFrame:Int;
	var channelChangeFrame:Int;
}

typedef PlayableCharacterSelect =
{
	var position:Null<Int>;
	var playerAtlas:String;
	var gf:PlayableCharacterGF;
}

typedef PlayableCharacterGF =
{
	var assetPath:String;
}