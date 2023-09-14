package;

import haxe.io.Path;
import lime.ui.FileDialog;
import sys.io.File;

class FileBrowser
{
	public var saveCallback:String->Void = null;
	public var loadCallback:String->Void = null;
	public var failureCallback:Void->Void = null;
	public var label:String = null;

	var content:String;

	public function new()
	{
	}

	public function save(filename:String, content:String)
	{
		this.content = content;

		var fileDialog = new FileDialog();
		fileDialog.onSelect.add(onSaveComplete);
		fileDialog.onCancel.add(onCancel);
		fileDialog.browse(SAVE, Path.extension(filename), filename, label);
	}

	public function load(?filterType:String = "json")
	{
		var fileDialog = new FileDialog();
		fileDialog.onSelect.add(onLoadComplete);
		fileDialog.onCancel.add(onCancel);
		fileDialog.browse(OPEN, filterType, null, label);
	}

	function onSaveComplete(path:String)
	{
		File.saveContent(path, content);

		if (saveCallback != null)
			saveCallback(path);
	}

	function onLoadComplete(path:String)
	{
		if (path == null)
		{
			if (failureCallback != null)
				failureCallback();
		}
		else if (loadCallback != null)
			loadCallback(path);
	}

	function onCancel()
	{
		if (failureCallback != null)
			failureCallback();
	}
}