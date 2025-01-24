package objects;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import objects.Note;

class Strumline extends FlxSpriteGroup
{
	public var strumNotes:FlxTypedSpriteGroup<StrumNote>;
	public var notes:FlxTypedSpriteGroup<Note>;
	public var sustainNotes:FlxTypedSpriteGroup<SustainNote>;
	public var noteSplashes:FlxSpriteGroup;
	public var sustainSplashes:FlxSpriteGroup;

	override public function new()
	{
		super();

		strumNotes = new FlxTypedSpriteGroup<StrumNote>();
		add(strumNotes);

		sustainNotes = new FlxTypedSpriteGroup<SustainNote>();
		add(sustainNotes);

		notes = new FlxTypedSpriteGroup<Note>();
		add(notes);

		sustainSplashes = new FlxSpriteGroup();
		add(sustainSplashes);

		var sustainSplash:FlxSprite = new FlxSprite();
		sustainSplashes.add(sustainSplash);
		sustainSplash.kill();

		noteSplashes = new FlxSpriteGroup();
		add(noteSplashes);

		var noteSplash:FlxSprite = new FlxSprite();
		noteSplashes.add(noteSplash);
		noteSplash.kill();
	}

	public function refreshPosition()
	{
		x = strumNotes.members[0].x;
		strumNotes.forEachAlive(function(note:StrumNote) { note.x -= x; });
	}
}