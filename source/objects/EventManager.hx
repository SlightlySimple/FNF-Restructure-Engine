package objects;

import data.Song;
import game.PlayState;

using StringTools;

class EventManager
{
	var onEvent:EventData->Void = null;

	public function new(type:String, typeShort:String)
	{
		var scriptId:String = "EVENT_" + type.replace("/", "_");

		if (type.startsWith(PlayState.songIdShort) && Paths.hscriptExists("data/songs/" + PlayState.songId + "/events/" + typeShort))
			PlayState.instance.hscriptAdd(scriptId, "data/songs/" + PlayState.songId + "/events/" + typeShort);
		else
			PlayState.instance.hscriptAdd(scriptId, "data/events/" + type);
		PlayState.instance.hscriptIdSet(scriptId, "eventType", type);

		onEvent = cast PlayState.instance.hscriptIdGet(scriptId, "onEvent");
	}

	public function doEvent(event:EventData)
	{
		if (onEvent != null)
			onEvent(event);
	}
}