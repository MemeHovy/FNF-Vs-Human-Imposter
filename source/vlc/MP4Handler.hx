package vlc;

import openfl.events.Event;
import flixel.FlxG;
import vlc.bitmap.VlcBitmap;

#if (hxCodec < "2.6.0")
/**
 * Play a video using cpp.
 * Use bitmap to connect to a graphic or use `MP4Sprite`.
 */
class MP4Handler extends VlcBitmap
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;

    public var skippable:Bool = true;

	var pauseMusic:Bool;

	public function new(width:Float = 320, height:Float = 240, autoScale:Bool = true)
	{
		super(width, height, autoScale);

		onVideoReady = onVLCVideoReady;
		onComplete = finishVideo;
		onError = onVLCError;

		FlxG.addChildBelowMouse(this);

		FlxG.stage.addEventListener(Event.ENTER_FRAME, update);

		FlxG.signals.focusGained.add(function()
		{
			resume();
		});
		FlxG.signals.focusLost.add(function()
		{
			pause();
		});
	}

	function update(e:Event)
	{
		if ((FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) && isPlaying && skippable)
			finishVideo();

		if (FlxG.sound.muted || FlxG.sound.volume <= 0)
			volume = 0;
		else
			volume = FlxG.sound.volume + 0.4;
	}

	#if sys
	function checkFile(fileName:String):String
	{
		#if !android
		var pDir = "";
		var appDir = "file:///" + Sys.getCwd() + "/";

		if (fileName.indexOf(":") == -1) // Not a path
			pDir = appDir;
		else if (fileName.indexOf("file://") == -1 || fileName.indexOf("http") == -1) // C:, D: etc? ..missing "file:///" ?
			pDir = "file:///";

		return pDir + fileName;
		#else
		return "file://" + fileName;
		#end
	}
	#end

	function onVLCVideoReady()
	{
		trace("Video loaded!");

		if (readyCallback != null)
			readyCallback();
	}

	function onVLCError()
	{
		// TODO: Catch the error
		throw "VLC caught an error!";
	}

	public function finishVideo()
	{
		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.resume();
        if (PlayState.instance.vocals != null && pauseMusic)
            PlayState.instance.vocals.resume();

		FlxG.stage.removeEventListener(Event.ENTER_FRAME, update);

		dispose();

		if (FlxG.game.contains(this))
		{
			FlxG.game.removeChild(this);

			if (finishCallback != null)
				finishCallback();
		}
	}

	/**
	 * Native video support for Flixel & OpenFL
	 * @param path Example: `your/video/here.mp4`
	 * @param repeat Repeat the video.
	 * @param pauseMusic Pause music until done video.
	 */
	public function playVideo(path:String, ?repeat:Bool = false, pauseMusic:Bool = false)
	{
		this.pauseMusic = pauseMusic;

		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.pause();
        if (PlayState.instance.vocals != null && pauseMusic)
            PlayState.instance.vocals.pause();

		#if sys
		play(checkFile(path));

		this.repeat = repeat ? -1 : 0;
		#else
		throw "Doesn't support sys";
		#end
	}
}
#end