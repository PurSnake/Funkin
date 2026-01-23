package;

import lime.system.System;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import funkin.ui.FullScreenScaleMode;
import funkin.Preferences;
import funkin.PlayerSettings;
import funkin.util.logging.CrashHandler;
import funkin.ui.debug.FunkinDebugDisplay;
import funkin.ui.debug.FunkinDebugDisplay.DebugDisplayMode;
import funkin.save.Save;
#if hxvlc
import hxvlc.util.Handle;
#end
import openfl.display.Sprite;
import openfl.display.MovieClip;
import openfl.events.Event;
import openfl.Lib;
import openfl.media.Video;
import openfl.net.NetStream;
import funkin.util.WindowUtil;

using funkin.util.AnsiUtil;

/*
  import flixel.FlxG;
  import flixel.FlxGame;
  import flixel.FlxState;
  import funkin.util.logging.CrashHandler;
  import funkin.save.Save;
  import haxe.ui.Toolkit;
  import haxe.io.Path;
  import openfl.display.Sprite;

  import openfl.events.Event;
  import openfl.Lib;
  import openfl.text.TextField;
  import openfl.text.TextFormat;
  import sys.FileSystem;
  import funkin.ui.FullScreenScaleMode;
  import lime.app.Application;
  import openfl.utils.Assets;
  import openfl.display.BitmapData; */
class Main extends flixel.FlxGame
{
  public static var mainInstance(default, null):Sprite;
  public static var applicationScreen(get, never):MovieClip;

  @:noCompletion inline static function get_applicationScreen()
    return Lib.current;

  public static function main():Void
  {
    startGame();
  }

  var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
  var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
  var initialState:Class<FlxState> = funkin.InitState; // The FlxState the game starts with.
  var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
  var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.

  public static var debugDisplay:FunkinDebugDisplay;

  public static function startGame():Void
  {
    // Set the current working directory for Android and iOS devices
    #if android
    // On Android use External Files Dir.
    Sys.setCwd(haxe.io.Path.addTrailingSlash(extension.androidtools.content.Context.getExternalFilesDir()));
    #elseif ios
    // On iOS use Documents Dir.
    Sys.setCwd(haxe.io.Path.addTrailingSlash(lime.system.System.documentsDirectory));
    #end

    // We need to make the crash handler LITERALLY FIRST so nothing EVER gets past it.
    CrashHandler.initialize();
    CrashHandler.queryStatus();
    mainInstance = new Main();
  }

  public function new()
  {
    haxe.Log.trace = funkin.util.logging.AnsiTrace.trace;
    funkin.util.logging.AnsiTrace.traceBF();

    // Get OpenFL to stop complaining so much.
    // You can remove this line if you want to read debug messages.
    openfl.utils._internal.Log.level = openfl.utils._internal.Log.LogLevel.INFO;

    // Load mods to override assets.
    // TODO: Replace with loadEnabledMods() once the user can configure the mod list.
    funkin.modding.PolymodHandler.loadAllMods();

    // Manually crash the game when using a software renderer in order to give a nicer error message.
    var context = stage.window.context.type;
    if (context != WEBGL && context != OPENGL && context != OPENGLES)
    {
      var tech:String = #if web "WebGL" #elseif desktop "OpenGL" #else "OpenGL ES" #end;
      var requiredVersion:String = #if web '$tech 1.0 or newer' #elseif desktop '$tech 3.0 or newer' #else '$tech 2.0 or newer' #end;
      var desc:String = 'Failed to initialize the $tech rendering context!\n\n';
      #if web
      desc += 'Make sure your graphics card supports $requiredVersion, your graphics drivers are up to date, and hardware acceleration is enabled on your browser.';
      #elseif desktop
      desc += 'Make sure your graphics card supports $requiredVersion, and your graphics drivers are up to date.';
      #else
      desc += 'Make sure your device supports $requiredVersion.';
      #end

      WindowUtil.showError('Failed to initialize $tech', desc);
      System.exit(1);
      return;
    }

    #if FEATURE_HAXEUI
    initHaxeUI();
    #end

    // addChild gets called by the user settings code.
    debugDisplay = new FunkinDebugDisplay(10, 10, 0xFFFFFF);

    // Add this signal so the player can toggle the debug display using a hotkey.
    FlxG.signals.postUpdate.add(handleDebugDisplayKeys);

    #if mobile
    // Add this signal so we can reposition and resize the memory and fps counter.
    FlxG.signals.preUpdate.add(repositionCounters.bind(true));
    #end

    // George recommends binding the save before FlxGame is created.
    Save.load();

    #if hxvlc
    // Initialize hxvlc's Handle here so the videos are loading faster.
    Handle.initAsync(function(success:Bool):Void {
      if (success)
      {
        trace(' HXVLC '.bold().bg_orange() + ' LibVLC instance initialized!');
      }
      else
      {
        trace(' HXVLC '.bold().bg_orange() + ' LibVLC instance failed to initialize!');
      }
    });
    #end

    // Don't call anything from the preferences until the save is loaded!
    #if web
    // set this variable (which is a function) from the lime version at lime/_internal/backend/html5/HTML5Application.hx
    // The framerate cap will more thoroughly initialize via Preferences in InitState.hx
    funkin.Preferences.lockedFramerateFunction = untyped js.Syntax.code("window.requestAnimationFrame");
    #end

    WindowUtil.setVSyncMode(funkin.Preferences.vsyncMode);

    trace("ASS");
    super(gameWidth, gameHeight, initialState, Preferences.framerate, Preferences.framerate, skipSplash,
      (FlxG.stage.window.fullscreen || Preferences.autoFullscreen));
    trace("ASS2");
    _customSoundTray = funkin.ui.options.FunkinSoundTray;
    scrollRect = new openfl.geom.Rectangle();
    __scrollRect.setTo(0, 0, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y);
    applicationScreen.addChild(this);
    applicationScreen.stage.scaleMode = openfl.display.StageScaleMode.NO_SCALE;

    trace("ASS3");
    FlxG.signals.gameResized.add((w, h) -> __scrollRect.setTo(0, 0, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y));

    #if FEATURE_DEBUG_FUNCTIONS
    debugger.interaction.addTool(new funkin.util.TrackerToolButtonUtil());
    funkin.util.macro.ConsoleMacro.init();
    #end

    #if !html5
    FlxG.scaleMode = new FullScreenScaleMode();
    #end

    #if mobile
    // Reposition and resize the memory and fps counter without lerping.
    repositionCounters(false);
    #end

    #if hxcpp_debug_server
    trace('hxcpp_debug_server is enabled! You can now connect to the game with a debugger.');
    #else
    trace('hxcpp_debug_server is disabled! This build does not support debugging.');
    #end
  }

  #if FEATURE_HAXEUI
  function initHaxeUI():Void
  {
    // This has to come before Toolkit.init since locales get initialized there
    haxe.ui.locale.LocaleManager.instance.autoSetLocale = false;
    // Calling this before any HaxeUI components get used is important:
    // - It initializes the theme styles.
    // - It scans the class path and registers any HaxeUI components.
    haxe.ui.Toolkit.init();
    haxe.ui.Toolkit.theme = 'dark'; // don't be cringe
    // haxe.ui.Toolkit.theme = 'light'; // embrace cringe
    haxe.ui.Toolkit.autoScale = false;
    // Don't focus on UI elements when they first appear.
    haxe.ui.focus.FocusManager.instance.autoFocus = false;
    funkin.input.Cursor.registerHaxeUICursors();
    haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
  }
  #end

  function handleDebugDisplayKeys():Void
  {
    if (PlayerSettings.player1.controls == null || !PlayerSettings.player1.controls.check(DEBUG_DISPLAY)) return;

    var nextMode:DebugDisplayMode;

    switch (Preferences.debugDisplay)
    {
      case DebugDisplayMode.Off:
        nextMode = DebugDisplayMode.Simple;
      case DebugDisplayMode.Simple:
        nextMode = DebugDisplayMode.Advanced;
      case DebugDisplayMode.Advanced:
        nextMode = DebugDisplayMode.Off;
    }

    Preferences.debugDisplay = nextMode;
  }

  #if mobile
  function repositionCounters(lerp:Bool):Void
  {
    // Calling this so it gets scaled based on the resolution of the game and device's resolution.
    var scale:Float = Math.min(FlxG.stage.stageWidth / FlxG.width, FlxG.stage.stageHeight / FlxG.height);

    #if android
    scale = Math.max(scale, 1);
    #else
    scale = Math.min(scale, 1);
    #end
    final thypos:Float = Math.max(FullScreenScaleMode.notchSize.x, 10);

    if (debugDisplay != null)
    {
      debugDisplay.scaleX = debugDisplay.scaleY = scale;

      if (FlxG.game != null)
      {
        if (lerp)
        {
          debugDisplay.x = flixel.math.FlxMath.lerp(debugDisplay.x, FlxG.game.x + thypos, FlxG.elapsed * 3);
        }
        else
        {
          debugDisplay.x = FlxG.game.x + FullScreenScaleMode.notchSize.x + 10;
        }

        debugDisplay.y = FlxG.game.y + (3 * scale);
      }
    }
  }
  #end

  var skipNextTickUpdate:Bool = false;

  public override function switchState()
  {
    super.switchState();
    draw();
    _total = ticks = getTicks();
    skipNextTickUpdate = true;
  }

  public override function onEnterFrame(t)
  {
    if (skipNextTickUpdate != (skipNextTickUpdate = false)) _total = ticks = getTicks();
    super.onEnterFrame(t);
  }
}
