package objects;

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

		noteSplashes = new FlxSpriteGroup();
		add(noteSplashes);
	}

	public function refreshPosition()
	{
		x = strumNotes.members[0].x;
		strumNotes.forEachAlive(function(note:StrumNote) { note.x -= x; });
	}
}