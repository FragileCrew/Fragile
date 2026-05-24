package;

import flixel.FlxGame;
import flixel.FlxG;
import flixel.sound.FlxSound;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.display.StageAlign;
import openfl.Lib;
import states.MenuState;

#if desktop
import openfl.display.StageDisplayState;
#end

#if android
import lime.system.System;
import openfl.system.System as OpenFLSystem;
#end

class Main extends Sprite {
    static inline final GAME_WIDTH:Int  = 1280;
    static inline final GAME_HEIGHT:Int = 720;
    static inline final FRAMERATE:Int   = 60;
    static inline final ZOOM:Float      = 1.0;

    public static var instance(default, null):Main;

    public function new() {
        super();
        instance = this;

        var game = new FlxGame(
            GAME_WIDTH,
            GAME_HEIGHT,
            MenuState,
            FRAMERATE,
            FRAMERATE,
            true
        );

        addChild(game);
        postInit();
    }

    function postInit():Void {
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
        Lib.current.stage.align     = StageAlign.TOP_LEFT;
        Lib.current.stage.color     = 0x000000;

        FlxG.autoPause  = false;
        FlxG.fixedTimestep = false;

        FlxG.sound.volume      = 1.0;
        FlxG.sound.volumeUpKeys   = [];
        FlxG.sound.volumeDownKeys = [];
        FlxG.sound.muteKeys       = [];

        FlxG.mouse.useSystemCursor = false;

        #if desktop
        setupDesktop();
        #end

        #if mobile
        setupMobile();
        #end
    }

    #if desktop
    function setupDesktop():Void {
        Lib.current.stage.displayState = StageDisplayState.NORMAL;

        FlxG.keys.preventDefaultKeys = [
            openfl.ui.Keyboard.TAB,
            openfl.ui.Keyboard.SPACE
        ];

        Fragile.initSave();
    }
    #end

    #if mobile
    function setupMobile():Void {
        FlxG.mouse.visible = false;
        Fragile.initSave();
    }
    #end
}

class Fragile {
    public static var version(default, null):String = "1.0.0";
    public static var gameWidth(default, null):Int   = 1280;
    public static var gameHeight(default, null):Int  = 720;

    public static var save(default, null):flixel.util.FlxSave;

    public static function initSave():Void {
        save = new flixel.util.FlxSave();
        save.bind("fragile_save");

        if (save.data.volume == null)     save.data.volume     = 1.0;
        if (save.data.musicVol == null)   save.data.musicVol   = 0.7;
        if (save.data.sfxVol == null)     save.data.sfxVol     = 1.0;
        if (save.data.fullscreen == null) save.data.fullscreen = false;
        if (save.data.chapter == null)    save.data.chapter    = 1;
        if (save.data.deaths == null)     save.data.deaths     = 0;

        FlxG.sound.volume = save.data.volume;

        #if desktop
        if (save.data.fullscreen)
            Lib.current.stage.displayState = openfl.display.StageDisplayState.FULL_SCREEN_INTERACTIVE;
        #end

        save.flush();
    }

    public static function toggleFullscreen():Void {
        #if desktop
        var stage = Lib.current.stage;
        if (stage.displayState == openfl.display.StageDisplayState.FULL_SCREEN_INTERACTIVE) {
            stage.displayState        = openfl.display.StageDisplayState.NORMAL;
            save.data.fullscreen      = false;
        } else {
            stage.displayState        = openfl.display.StageDisplayState.FULL_SCREEN_INTERACTIVE;
            save.data.fullscreen      = true;
        }
        save.flush();
        #end
    }

    public static function recordDeath():Void {
        save.data.deaths++;
        save.flush();
    }

    public static function setChapter(chapter:Int):Void {
        save.data.chapter = chapter;
        save.flush();
    }

    public static function resetSave():Void {
        save.data.chapter  = 1;
        save.data.deaths   = 0;
        save.flush();
    }

    public static function quit():Void {
        #if desktop
        Sys.exit(0);
        #end
        #if android
        lime.system.System.exit(0);
        #end
    }
}
