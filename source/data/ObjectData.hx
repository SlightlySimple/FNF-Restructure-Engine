package data;

import objects.HealthIcon;

// Characters

typedef CharacterData =
{
	var ?parent:String;
	var ?script:String;
	var asset:String;
	var ?tileCount:Array<Int>;
	var position:Array<Int>;
	var camPosition:Array<Int>;
	var scale:Array<Float>;
	var fixes:Null<Int>;
	var antialias:Bool;
	var ?offsetAlign:Array<String>;
	var animations:Array<CharacterAnimation>;
	var firstAnimation:String;
	var idles:Array<String>;
	var ?healthbarColor:Array<Int>;
	var ?danceSpeed:Null<Float>;
	var ?gameOverCharacter:String;
	var ?gameOverSFX:String;
	var ?camPositionGameOver:Array<Int>;
	var ?deathCounterText:String;
	var flip:Null<Bool>;
	var facing:String;
	var icon:String;
}

typedef CharacterAnimation =
{
	var name:String;
	var ?asset:String;
	var ?prefix:String;
	var ?fps:Null<Int>;
	var ?loop:Null<Bool>;
	var ?flipX:Null<Bool>;
	var ?flipY:Null<Bool>;
	var ?loopedFrames:Null<Int>;
	var ?sustainFrame:Null<Int>;
	var ?indices:Array<Int>;
	var ?offsets:Array<Int>;
	var ?next:String;
	var ?important:Null<Bool>;
}

typedef CharacterCamPosition =
{
	var x:Float;
	var y:Float;
	var abs:Bool;
}

// Health Icons

typedef HealthIconData =
{
	var ?asset:String;
	var ?frames:Array<Int>;
	var antialias:Null<Bool>;
	var scale:Array<Float>;
	var ?flip:Array<Bool>;
	var ?centered:Null<Bool>;
	var offset:Null<Int>;
	var ?animations:Array<StageAnimation>;
	var ?swapTo:String;
	var ?stack:Array<IconStack>;
}

typedef IconStack =
{
	var ?sprite:HealthIcon;
	var ?id:String;
	var position:Array<Float>;
	var scale:Float;
}

// Stages

typedef StageData =
{
	var ?parent:String;
	var ?script:String;
	var ?searchDirs:Array<String>;
	var fixes:Null<Int>;
	var characters:Array<StageCharacter>;
	var camZoom:Null<Float>;
	var camFollow:Array<Int>;
	var bgColor:Array<Int>;
	var pixelPerfect:Null<Bool>;
	var pieces:Array<StagePiece>;
}

typedef StageCharacter =
{
	var position:Array<Int>;
	var ?layer:Null<Int>;
	var ?camPosition:Array<Int>;
	var ?camPosAbsolute:Null<Bool>;
	var flip:Bool;
	var ?scale:Array<Float>;
	var ?scrollFactor:Array<Float>;
}

typedef StagePiece =
{
	var ?id:String;
	var type:String;
	var asset:String;
	var ?tileCount:Array<Int>;
	var ?scriptClass:String;
	var ?scriptParameters:Dynamic;
	var position:Array<Int>;
	var ?scale:Array<Float>;
	var ?align:String;
	var ?scrollFactor:Array<Float>;
	var ?flip:Array<Bool>;
	var ?tile:Array<Bool>;
	var ?visible:Null<Bool>;
	var ?animations:Array<StageAnimation>;
	var ?firstAnimation:String;
	var ?updateHitbox:Null<Bool>;
	var ?idles:Array<String>;
	var ?beatAnimationSpeed:Null<Float>;
	var layer:Null<Int>;
	var antialias:Bool;
	var ?color:Array<Int>;
	var ?alpha:Null<Float>;
	var ?blend:String;
}

typedef StageAnimation =
{
	var name:String;
	var prefix:String;
	var fps:Int;
	var loop:Bool;
	var ?indices:Array<Int>;
	var ?offsets:Array<Int>;
}

// Notes

typedef NoteTypeData =
{
	var noteskinOverride:String;
	var noteskinOverrideSustain:String;
	var ?animation:String;
	var ?animationMiss:String;
	var animationSuffix:String;
	var hitSound:String;
	var hitSoundVolume:Null<Float>;
	var placeSound:String;
	var healthValues:NoteHealthValues;
	var p1ShouldMiss:Bool;
	var p2ShouldMiss:Bool;
	var noSustains:Null<Bool>;
	var ?singers:Array<Int>;
	var ?alwaysSplash:Null<Bool>;
	var ?splashMin:Null<Int>;
}

typedef NoteHealthValues =
{
	var judgements:Array<Float>;
	var miss:Float;
}

typedef ScrollSpeed =
{
	var startTime:Float;
	var startPosition:Float;
	var speed:Float;
}

typedef BackgroundChartNote =
{
	var strumTime:Float;
	var sustainLength:Float;
	var column:Int;
	var anim:String;
	var ?holdEndAnim:String;
}

// Weeks

typedef WeekData =
{
	var image:String;
	var title:String;
	var characters:Array<Array<Dynamic>>;
	var ?color:Array<Int>;
	var ?banner:String;
	var ?difficulties:Array<String>;
	var ?difficultiesLocked:Array<String>;
	var songs:Array<WeekSongData>;
	var startsLocked:Bool;
	var startsLockedInFreeplay:Null<Bool>;
	var weekToUnlock:String;
	var hiddenWhenLocked:Bool;
	var ?condition:String;
	var ?hscript:String;
}

typedef WeekSongData =
{
	var songId:String;
	var ?variant:String;
	var ?icon:String;
	var ?iconNew:String;
	var ?difficulties:Array<String>;
	var ?characters:Null<Int>;
	var ?characterLabels:Array<String>;
	var ?title:String;
	var ?hscript:String;
	var ?albums:Array<Array<String>>;
}

typedef WeekCharacterData =
{
	var asset:String;
	var position:Array<Int>;
	var scale:Array<Float>;
	var antialias:Bool;
	var animations:Array<CharacterAnimation>;
	var firstAnimation:String;
	var idles:Array<String>;
	var ?danceSpeed:Null<Float>;
	var flip:Null<Bool>;
	var matchColor:Null<Bool>;
}

// Freeplay

typedef FavoriteSongData =
{
	var song:WeekSongData;
	var title:String;
	var artist:String;
	var group:String;
}

// UI Skins

typedef UISkin =
{
	var countdown:Array<UISprite>;
	var countdownSounds:Array<String>;
	var judgements:Array<UISprite>;
	var combo:UISprite;
	var numbers:Array<UISprite>;
	var antialias:Bool;
}

typedef UISprite =
{
	var asset:String;
	var scale:Array<Float>;
	var ?animation:String;
	var ?loop:Bool;
	var ?fps:Int;
	var ?antialias:Null<Bool>;
}