package objects;

import flixel.FlxBasic;

import data.ObjectData;
import data.Song;
import game.PlayState;

class BackgroundChart extends FlxBasic
{
	static var noteAnims:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

	public var notes:Array<BackgroundChartNote> = [];
	public var sustains:Array<BackgroundChartNote> = [];
	public var singers:Array<Character> = [];

	override public function new(singers:Array<Character>, id:String, difficulty:String, ?ignoreMustHit:Bool = true)
	{
		super();
		this.singers = singers;

		var song:SongData = Song.loadSong(id, difficulty, false);
		var sections:Array<SectionData> = song.notes;
		for (section in sections)
		{
			for (note in section.sectionNotes)
			{
				var newNote:BackgroundChartNote = { strumTime: note[0], column: Std.int(note[1]), sustainLength: note[2], anim: noteAnims[Std.int(note[1]) % noteAnims.length] };
				if ((!ignoreMustHit && section.mustHitSection) || (ignoreMustHit && song.useMustHit && section.camOn == 0))
				{
					if (newNote.column >= song.columnDivisions.length / 2)
						newNote.column -= Std.int(song.columnDivisions.length / 2);
					else
						newNote.column += Std.int(song.columnDivisions.length / 2);
				}

				if (note.length > 3 && Paths.jsonExists("notetypes/" + note[3]))
				{
					var typeData:NoteTypeData = cast Paths.json("notetypes/" + note[3]);
					if (typeData.animationSuffix != null)
						newNote.anim += typeData.animationSuffix;
				}

				notes.push(newNote);
				if (newNote.sustainLength > 0)
					sustains.push(newNote);
			}
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (PlayState.instance.countdownStarted && (notes.length > 0 || sustains.length > 0))
		{
			var poppers:Array<BackgroundChartNote> = [];
			for (n in notes)
			{
				if (Conductor.songPosition >= n.strumTime)
				{
					for (s in singers)
					{
						s.holdTimer = Conductor.beatLength;
						s.playAnim(n.anim, true);
					}
					poppers.push(n);
				}
			}

			for (p in poppers)
				notes.remove(p);

			poppers = [];
			for (n in sustains)
			{
				if (Conductor.songPosition >= n.strumTime)
				{
					for (s in singers)
					{
						s.holdTimer = Conductor.stepLength;
						s.sustain = true;
					}
					if (Conductor.songPosition >= n.strumTime + n.sustainLength)
					{
						for (s in singers)
							s.sustainEnd();
						poppers.push(n);
					}
				}
			}

			for (p in poppers)
				sustains.remove(p);
		}
	}
}