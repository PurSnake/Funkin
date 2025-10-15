package funkin.ui;

import flixel.math.FlxPoint;
import flixel.system.scaleModes.BaseScaleMode;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if android
import extension.androidtools.Tools;
import extension.androidtools.os.Build;
#end

/** TODO:
 * Possibility to choose to change FlxG.width or FlxG.height.
 */
class FullScreenScaleMode extends BaseScaleMode
{
  /**
   * Singleton instance of the `FullScreenScaleMode`.
   */
  public static var instance:FullScreenScaleMode = null;

  /**
   * The size of the screen cutout (e.g., for notches or camera cutouts).
   */
  public var cutoutSize:FlxPoint = new FlxPoint(0, 0);

  /**
   * The position of the notch on the screen.
   */
  public var notchPosition:FlxPoint = new FlxPoint(0, 0);

  /**
   * The size of the notch on the screen.
   */
  public var notchSize:FlxPoint = new FlxPoint(0, 0);

  /**
   * The size of the game in screen resolution relativly to the initial size.
   * eg: If screen is 1080p and initial size of the game is 1280x720 then this is 1920x1080.
   */
  public var logicalSize:FlxPoint = new FlxPoint(0, 0);

  /**
   * The maximum aspect ratio a screen can have.
   */
  public var maxAspectRatio:FlxPoint = new FlxPoint(20, 9);

  /**
   * The minimum aspect ratio a screen can have.
   */
  public var minAspectRatio:FlxPoint = new FlxPoint(4, 3);

  /**
   * The maximum ratio axis indicating on which axis the black bar will be added.
   */
  public var maxRatioAxis:FlxAxes = XY;

  /**
   * The aspect ratio of the game screen.
   */
  public var gameRatio:Float = -1;

  /**
   * The size of the game cutout.
   */
  public var gameCutoutSize:FlxPoint = new FlxPoint(0, 0);

  /**
   * The position of the notch in game coordinates.
   */
  public var gameNotchPosition:FlxPoint = new FlxPoint(0, 0);

  /**
   * The size of the notch in game coordinates.
   */
  public var gameNotchSize:FlxPoint = new FlxPoint(0, 0);

  /**
   * The aspect ratio of the window.
   */
  public var screenRatio:Float = -1;

  /**
   * The scale factor for the window.
   */
  public var wideScale(default, null):FlxPoint = new FlxPoint(1, 1);

  /**
   * Axis used to determine the ratio.
   */
  public var ratioAxis(default, null):FlxAxes = XY;

  /**
   * Whether fullscreen scaling is enabled.
   */
  public var enabled(default, set):Bool;

  /**
   * Wether fake cutouts are added to the screen.
   */
  public var hasFakeCutouts(default, null):Bool = false;

  public var debug:Bool = true; // temporarily enabled for debugging (can set false later)

  var resizeListener:Dynamic = null;

  @:noCompletion
  var cutoutBitmaps:Array<Bitmap> = [null, null];

  public function new(enable:Bool = true):Void
  {
    super();

    enabled = enable;
    instance = this;

    #if !no_flixel_signals
    try
    {
      resizeListener = function(w:Int, h:Int):Void {
        onMeasure(w, h);
        if (hasFakeCutouts) addCutouts(0);
      };
      FlxG.signals.gameResized.add(resizeListener);
    }
    catch (e:Dynamic) {}
    #end
  }

  /**
   * Add fake cutouts into the screen.
   * Useful for when switching from wide display into 16:9 seamlessly and directly is needed.
   * @param tweenDuration The duration of the tweens that adds the cutout bars. Using 0 will instantly put them on screen.
   * @param ease The function that's used for the tween.
   */
  public function addCutouts(tweenDuration:Float = 0.0, ?ease:Float->Float):Void
  {
    if (cutoutSize.x == 0 && ratioAxis == X || cutoutSize.y == 0 && ratioAxis == Y)
    {
      return;
    }

    final game = FlxG.game;
    for (i => bitmap in cutoutBitmaps)
    {
      var leftBarWidth:Int = 0;
      var rightBarWidth:Int = 0;
      var topBarHeight:Int = 0;
      var bottomBarHeight:Int = 0;

      if (ratioAxis == X)
      {
        leftBarWidth = Std.int(Math.max(0, Math.ceil(offset.x)));
        rightBarWidth = Std.int(Math.max(0, Math.ceil(deviceSize.x - (offset.x + gameSize.x))));

        var bmpW = (i == 0) ? leftBarWidth : rightBarWidth;
        var bmpH = Std.int(Math.max(1, Math.ceil(deviceSize.y)));

        if (bitmap == null || bitmap.bitmapData.width != bmpW || bitmap.bitmapData.height != bmpH)
        {
          if (bitmap != null && bitmap.parent != null) bitmap.parent.removeChild(bitmap);
          cutoutBitmaps[i] = bitmap = new Bitmap(new BitmapData(Std.int(Math.max(1, bmpW)), bmpH, true, 0xFF000000));
          game.parent.addChildAt(bitmap, game.parent.getChildIndex(game) + 1);
        }
        if (i == 0)
        {
          bitmap.x = 0;
        }
        else
        {
          bitmap.x = Std.int(Math.round(offset.x + gameSize.x));
        }
        bitmap.y = 0;

        if (bmpW <= 0)
        {
          bitmap.alpha = 0;
          continue;
        }
      }
      else
      {
        topBarHeight = Std.int(Math.max(0, Math.ceil(offset.y)));
        bottomBarHeight = Std.int(Math.max(0, Math.ceil(deviceSize.y - (offset.y + gameSize.y))));

        var bmpW2 = Std.int(Math.max(1, Math.ceil(deviceSize.x)));
        var bmpH2 = (i == 0) ? topBarHeight : bottomBarHeight;

        if (bitmap == null || bitmap.bitmapData.width != bmpW2 || bitmap.bitmapData.height != bmpH2)
        {
          if (bitmap != null && bitmap.parent != null) bitmap.parent.removeChild(bitmap);
          cutoutBitmaps[i] = bitmap = new Bitmap(new BitmapData(bmpW2, Std.int(Math.max(1, bmpH2)), true, 0xFF000000));
          game.parent.addChildAt(bitmap, game.parent.getChildIndex(game) + 1);
        }

        bitmap.x = 0;
        if (i == 0)
        {
          bitmap.y = 0;
        }
        else
        {
          bitmap.y = Std.int(Math.round(offset.y + gameSize.y));
        }

        if (bmpH2 <= 0)
        {
          bitmap.alpha = 0;
          continue;
        }
      }

      // Debug: log computed bar sizes/positions and bitmap actual size
      if (debug) trace('[addCutouts] i:' + i + ' bmp (w,h):' + bitmap.bitmapData.width + ',' + bitmap.bitmapData.height + ' pos:' + bitmap.x + ','
        + bitmap.y + ' leftBar:' + leftBarWidth + ' rightBar:' + rightBarWidth + ' topBar:' + topBarHeight + ' bottomBar:' + bottomBarHeight + ' deviceSize:'
        + deviceSize.x + ',' + deviceSize.y + ' gameSize:' + gameSize.x + ',' + gameSize.y + ' offset:' + offset.x + ',' + offset.y);

      bitmap.alpha = 1;
    }
    hasFakeCutouts = true;
  }

  /**
   * Remove the fake cutouts from the screen.
   * Used to go back from 16:9 into widescreen seamlessly and directly when needed.
   * @param tweenDuration The duration of the tweens that remove the cutout bars. Using 0 will instantly put them off screen.
   * @param ease The function that's used for the tween.
   */
  public function removeCutouts(tweenDuration:Float = 0.0, ?ease:Float->Float):Void
  {
    for (i => bitmap in cutoutBitmaps)
    {
      if (bitmap == null)
      {
        trace("[WARNING] Tried to remove a cutout bar but there don't seem to be any.");
        continue;
      }

      final targetX:Float = (i == 0 || ratioAxis == Y) ? ratioAxis == Y ? 0 : -bitmap.width : FlxG.scaleMode.gameSize.x;
      final targetY:Float = (i == 0 || ratioAxis == X) ? ratioAxis == X ? 0 : -bitmap.height : FlxG.scaleMode.gameSize.y;

      bitmap.x = targetX;
      bitmap.y = targetY;
      bitmap.alpha = 0;
    }
    hasFakeCutouts = false;
  }

  public function updateSizes()
  {
    if (FlxG.stage != null) onMeasure(FlxG.stage.stageWidth, FlxG.stage.stageHeight);
  }

  public override function onMeasure(Width:Int, Height:Int):Void
  {
    untyped FlxG.width = FlxG.initialWidth;
    untyped FlxG.height = FlxG.initialHeight;

    updateGameSize(Width, Height);
    updateDeviceSize(Width, Height);
    updateDeviceCutout(Width, Height);
    updateScaleOffset();
    updateGamePosition();

    adjustGameSize();

    if (debug) trace('[onMeasure] Width:' + Width + ' Height:' + Height + ' gameSize:' + gameSize.x + 'x' + gameSize.y + ' logicalSize:' + logicalSize.x
      + 'x' + logicalSize.y + ' scale:' + scale.x + ',' + scale.y + ' offset:' + offset.x + ',' + offset.y);
  }

  override public function updateScaleOffset():Void
  {
    var baseW = Math.max(1, FlxG.initialWidth);
    var baseH = Math.max(1, FlxG.initialHeight);

    scale.x = (ratioAxis == X ? logicalSize.x : deviceSize.x) / baseW;
    scale.y = (ratioAxis == Y ? logicalSize.y : deviceSize.y) / baseH;
    updateOffsetX();
    updateOffsetY();
  }

  override public function updateGameSize(Width:Int, Height:Int):Void
  {
    gameRatio = FlxG.width / FlxG.height;
    screenRatio = Width / Height;
    ratioAxis = screenRatio < gameRatio ? FlxAxes.Y : FlxAxes.X;

    if (!enabled)
    {
      if (ratioAxis == FlxAxes.X)
      {
        Width = Math.ceil(Height * gameRatio);
      }
      else
      {
        Height = Math.ceil(Width / gameRatio);
      }
    }

    gameSize.set(Width, Height);
    logicalSize.set(Math.ceil(gameSize.y * gameRatio), Math.ceil(gameSize.x / gameRatio));
  }

  function adjustGameSize():Void
  {
    if (enabled)
    {
      var gameWidth:Float = gameSize.x / Math.max(0.0001, scale.x);
      var gameHeight:Float = gameSize.y / Math.max(0.0001, scale.y);
      var minAspectRatioFactor:Float = minAspectRatio.x / minAspectRatio.y;
      var maxAspectRatioFactor:Float = maxAspectRatio.x / maxAspectRatio.y;
      if (ratioAxis == X)
      {
        var maxFactor = Math.max(minAspectRatioFactor, maxAspectRatioFactor);
        if (gameWidth / FlxG.initialHeight > maxFactor && maxRatioAxis.x)
        {
          final oldGameWidth = gameSize.x;
          gameWidth = gameHeight * maxFactor;
          gameSize.x = gameWidth * scale.x;

          final sizeDifference:Float = oldGameWidth - gameSize.x;
          final sc:Float = logicalSize.x / Math.max(1, FlxG.initialWidth);
          cutoutSize.set(Math.max(0, cutoutSize.x - sizeDifference), 0);
          gameCutoutSize.copyFrom(cutoutSize);
          if (sc > 0) gameCutoutSize.x /= sc;

          notchSize.x = Math.max(0, notchSize.x - sizeDifference);
          final nsx = Math.max(1, sc);
          gameNotchSize.x = notchSize.x / nsx;

          offset.x = Math.max(0, Math.ceil((deviceSize.x - gameSize.x) * 0.5));
          if (gameSize.x > deviceSize.x) gameSize.x = deviceSize.x;
        }

        untyped FlxG.width = Math.max(1, Math.ceil(gameWidth));
      }
      else
      {
        maxAspectRatioFactor = 1.0 / maxAspectRatioFactor;
        minAspectRatioFactor = 1.0 / minAspectRatioFactor;
        var maxFactor = Math.max(minAspectRatioFactor, maxAspectRatioFactor);
        if (gameHeight / FlxG.initialWidth > maxFactor && maxRatioAxis.y)
        {
          final oldGameHeight = gameSize.y;
          gameHeight = gameWidth * maxFactor;
          gameSize.y = gameHeight * scale.y;

          final sizeDifference:Float = oldGameHeight - gameSize.y;
          final sc:Float = logicalSize.y / Math.max(1, FlxG.initialHeight);
          cutoutSize.set(0, Math.max(0, cutoutSize.y - sizeDifference));
          gameCutoutSize.copyFrom(cutoutSize);
          if (sc > 0) gameCutoutSize.y /= sc;

          notchSize.y = Math.max(0, notchSize.y - sizeDifference);
          final nsy = Math.max(1, sc);
          gameNotchSize.y = notchSize.y / nsy;

          offset.y = Math.max(0, Math.ceil((deviceSize.y - gameSize.y) * 0.5));
          if (gameSize.y > deviceSize.y) gameSize.y = deviceSize.y;
        }

        untyped FlxG.height = Math.max(1, Math.ceil(gameHeight));
      }
      wideScale.set(FlxG.width / Math.max(1, FlxG.initialWidth), FlxG.height / Math.max(1, FlxG.initialHeight));
      updateGamePosition();

      if (debug) trace('[adjustGameSize] gameSize:' + gameSize.x + 'x' + gameSize.y + ' FlxG:' + FlxG.width + 'x' + FlxG.height + ' offset:' + offset.x
        + ',' + offset.y + ' cutout:' + cutoutSize.x + ',' + cutoutSize.y);
    }
    else
    {
      wideScale.set(1, 1);
    }
  }

  function updateDeviceCutout(Width:Int, Height:Int):Void
  {
    if (enabled)
    {
      cutoutSize.x = ratioAxis == X ? Math.max(0, Math.ceil(Width - logicalSize.x)) : 0;
      cutoutSize.y = ratioAxis == Y ? Math.max(0, Math.ceil(Height - logicalSize.y)) : 0;

      var scaleX = (logicalSize.x > 0 && FlxG.initialWidth > 0) ? (logicalSize.x / FlxG.initialWidth) : 1.0;
      var scaleY = (logicalSize.y > 0 && FlxG.initialHeight > 0) ? (logicalSize.y / FlxG.initialHeight) : 1.0;

      gameCutoutSize.copyFrom(cutoutSize);
      if (scaleX > 0) gameCutoutSize.x = cutoutSize.x / scaleX;
      else
        gameCutoutSize.x = 0;
      if (scaleY > 0) gameCutoutSize.y = cutoutSize.y / scaleY;
      else
        gameCutoutSize.y = 0;
    }
    else
    {
      cutoutSize.set(0, 0);
      gameCutoutSize.set(0, 0);
    }
  }

  public function destroy():Void
  {
    #if !no_flixel_signals
    try
    {
      if (resizeListener != null)
      {
        FlxG.signals.gameResized.remove(resizeListener);
        resizeListener = null;
      }
    }
    catch (e:Dynamic)
    {
      // ignore
    }
    #end

    for (bitmap in cutoutBitmaps)
      if (bitmap != null && bitmap.parent != null) bitmap.parent.removeChild(bitmap);
    cutoutBitmaps = [null, null];
  }

  @:noCompletion
  function set_enabled(Value:Bool):Bool
  {
    #if android
    if (ratioAxis != FlxAxes.X || (Build.VERSION.SDK_INT < Build.VERSION_CODES.P && !Tools.isTablet())) Value = false;
    #end
    enabled = Value;

    if (instance != null && FlxG.scaleMode == instance)
    {
      @:privateAccess
      FlxG.game.onResize(null);
    }

    return enabled;
  }
}
