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
 * 1. Possibility to choose to change FlxG.width or FlxG.height.
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
  public static var cutoutSize:FlxPoint = new FlxPoint(0, 0);

  /**
   * The position of the notch on the screen.
   */
  public static var notchPosition:FlxPoint = new FlxPoint(0, 0);

  /**
   * The size of the notch on the screen.
   */
  public static var notchSize:FlxPoint = new FlxPoint(0, 0);

  /**
   * The size of the game in screen resolution relativly to the initial size.
   * eg: If screen is 1080p and initial size of the game is 1280x720 then this is 1920x1080.
   */
  public static var logicalSize:FlxPoint = new FlxPoint(0, 0);

  /**
   * The maximum aspect ratio a screen can have.
   */
  public static var maxAspectRatio:FlxPoint = new FlxPoint(21, 9);

  /**
   * The minimum aspect ratio a screen can have.
   */
  public static var minAspectRatio:FlxPoint = new FlxPoint(4, 3);

  /**
   * The maximum ratio axis indicating on which axis the black bar will be added.
   */
  public static var maxRatioAxis:FlxAxes = X;

  /**
   * The aspect ratio of the game screen.
   */
  public static var gameRatio:Float = -1;

  /**
   * The size of the game cutout.
   */
  public static var gameCutoutSize:FlxPoint = new FlxPoint(0, 0);

  /**
   * The position of the notch in game coordinates.
   */
  public static var gameNotchPosition:FlxPoint = new FlxPoint(0, 0);

  /**
   * The size of the notch in game coordinates.
   */
  public static var gameNotchSize:FlxPoint = new FlxPoint(0, 0);

  /**
   * The aspect ratio of the window.
   */
  public static var screenRatio:Float = -1;

  /**
   * The scale factor for the window.
   */
  public static var wideScale(default, null):FlxPoint = new FlxPoint(1, 1);

  /**
   * Axis used to determine the ratio.
   */
  public static var ratioAxis(default, null):FlxAxes = X;

  /**
   * Whether fullscreen scaling is enabled.
   */
  public static var enabled(default, set):Bool;

  /**
   * Wether fake cutouts are added to the screen.
   */
  public static var hasFakeCutouts(default, null):Bool = false;

  @:noCompletion
  static var cutoutBitmaps:Array<Bitmap> = [null, null];

  public function new(enable:Bool = true):Void
  {
    super();

    enabled = enable;

    // // Required so we can check on which axies is the game wide.
    // updateSizes();

    instance = this;
  }

  /**
   * Add fake cutouts into the screen.
   * Useful for when switching from wide display into 16:9 seamlessly and directly is needed.
   * @param tweenDuration The duration of the tweens that adds the cutout bars. Using 0 will instantly put them on screen.
   * @param ease The function that's used for the tween.
   */
  public static function addCutouts(tweenDuration:Float = 0.0, ?ease:Float->Float):Void
  {
    if (cutoutSize.x == 0 && ratioAxis == X || cutoutSize.y == 0 && ratioAxis == Y)
    {
      return;
    }

    final game = FlxG.game;
    for (i => bitmap in cutoutBitmaps)
    {
      if (bitmap == null)
      {
        cutoutBitmaps[i] = bitmap = new Bitmap(new BitmapData(ratioAxis == X ? Math.ceil(cutoutSize.x / 2) : Math.ceil(FlxG.scaleMode.gameSize.x),
          ratioAxis == Y ? Math.ceil(cutoutSize.y / 2) : Math.ceil(FlxG.scaleMode.gameSize.y), true, 0xFF000000));
        game.parent.addChildAt(bitmap, game.parent.getChildIndex(game) + 1);
      }

      var targetX:Float = 0;
      var targetY:Float = 0;

      if (ratioAxis == X)
      {
        bitmap.x = (i == 0) ? -bitmap.width : FlxG.scaleMode.gameSize.x;
        targetX = (i == 0) ? 0 : FlxG.scaleMode.gameSize.x - bitmap.width;
        bitmap.y = 0;
        targetY = 0;
      }
      else
      {
        bitmap.x = 0;
        targetX = 0;
        bitmap.y = (i == 0) ? -bitmap.height : FlxG.scaleMode.gameSize.y;
        targetY = (i == 0) ? 0 : FlxG.scaleMode.gameSize.y - bitmap.height;
      }

      bitmap.alpha = 0;

      // if (tweenDuration > 0.0)
      // {
      // 	FlxTween.tween(bitmap, {x: targetX, y: targetY, alpha: 1}, tweenDuration, {ease: ease ?? FlxEase.linear});
      // }
      // else
      {
        bitmap.x = targetX;
        bitmap.y = targetY;
        bitmap.alpha = 1;
      }
    }
    hasFakeCutouts = true;
  }

  /**
   * Remove the fake cutouts from the screen.
   * Used to go back from 16:9 into widescreen seamlessly and directly when needed.
   * @param tweenDuration The duration of the tweens that remove the cutout bars. Using 0 will instantly put them off screen.
   * @param ease The function that's used for the tween.
   */
  public static function removeCutouts(tweenDuration:Float = 0.0, ?ease:Float->Float):Void
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

      // if (tweenDuration > 0.0)
      // {
      // 	FlxTween.tween(bitmap, {x: targetX, y: targetY, alpha: 0}, tweenDuration, {ease: ease ?? FlxEase.linear});
      // }
      // else
      {
        bitmap.x = targetX;
        bitmap.y = targetY;
        bitmap.alpha = 0;
      }
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
  }

  override public function updateScaleOffset():Void
  {
    scale.x = (ratioAxis == X ? logicalSize.x : deviceSize.x) / FlxG.initialWidth;
    scale.y = (ratioAxis == Y ? logicalSize.y : deviceSize.y) / FlxG.initialHeight;
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
      var gameWidth:Float = gameSize.x / scale.x;
      var gameHeight:Float = gameSize.y / scale.y;
      var minAspectRatioFactor:Float = minAspectRatio.x / minAspectRatio.y;
      var maxAspectRatioFactor:Float = maxAspectRatio.x / maxAspectRatio.y;
      // trace(gameWidth, gameHeight, maxAspectRatioFactor);
      if (ratioAxis == X)
      {
        var maxFactor = Math.max(minAspectRatioFactor, maxAspectRatioFactor);
        if (gameWidth / FlxG.initialHeight > maxFactor && maxRatioAxis.x)
        {
          final oldGameWidth = gameSize.x;
          gameWidth = gameHeight * maxFactor;
          gameSize.x = gameWidth * scale.x;

          final sizeDifference:Float = oldGameWidth - gameSize.x;
          final scale:Float = logicalSize.x / FlxG.initialWidth;
          cutoutSize.set(cutoutSize.x - sizeDifference, 0);
          gameCutoutSize.copyFrom(cutoutSize);
          gameCutoutSize.x /= scale;

          notchSize.x = Math.max(0, notchSize.x - sizeDifference);
          gameNotchSize.x = notchSize.x / scale;

          offset.x = Math.ceil((deviceSize.x - gameSize.x) * 0.5);
        }

        untyped FlxG.width = Math.ceil(gameWidth);
      }
      else
      {
        maxAspectRatioFactor = 1.0 / maxAspectRatioFactor;
        minAspectRatioFactor = 1.0 / minAspectRatioFactor;
        var maxFactor = Math.max(minAspectRatioFactor, maxAspectRatioFactor);
        if (gameHeight / FlxG.initialWidth > maxFactor && maxRatioAxis.y)
        {
          final oldGameHeight = gameSize.y;
          gameHeight = gameWidth * maxFactor; // todo?
          // gameHeight = FlxG.initialHeight;
          gameSize.y = gameHeight * scale.y;

          final sizeDifference:Float = oldGameHeight - gameSize.y;
          final scale:Float = logicalSize.y / FlxG.initialHeight;
          cutoutSize.set(0, cutoutSize.y - sizeDifference);
          gameCutoutSize.copyFrom(cutoutSize);
          gameCutoutSize.y /= scale;

          notchSize.y = Math.max(0, notchSize.y - sizeDifference);
          gameNotchSize.y = notchSize.y / scale;

          offset.y = Math.ceil((deviceSize.y - gameSize.y) * 0.5);
        }

        untyped FlxG.height = Math.ceil(gameHeight);
      }
      wideScale.set(FlxG.width / FlxG.initialWidth, FlxG.height / FlxG.initialHeight);
      updateGamePosition();
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
      cutoutSize.x = ratioAxis == X ? Math.ceil(Width - logicalSize.x) : 0;
      cutoutSize.y = ratioAxis == Y ? Math.ceil(Height - logicalSize.y) : 0;
      gameCutoutSize.copyFrom(cutoutSize);
      gameCutoutSize.x /= logicalSize.x / FlxG.initialWidth;
      gameCutoutSize.y /= logicalSize.y / FlxG.initialHeight;
    }
    else
    {
      cutoutSize.set(0, 0);
      gameCutoutSize.set(0, 0);
    }
  }

  @:noCompletion
  static function set_enabled(Value:Bool):Bool
  {
    #if android
    if (ratioAxis != FlxAxes.X || (Build.VERSION.SDK_INT < Build.VERSION_CODES.P && !Tools.isTablet()))
    {
      Value = false;
    }
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
