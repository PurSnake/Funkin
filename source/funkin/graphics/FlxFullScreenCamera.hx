package funkin.graphics;

import openfl.geom.Rectangle;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;

class FlxFullScreenCamera extends FlxCamera
{
  public var useInitialSizes(default, set):Bool = true;

  @:noCompletion
  var __initOffset:FlxPoint = FlxPoint.get();

  public override function destroy()
  {
    super.destroy();
    __initOffset = FlxDestroyUtil.put(__initOffset);
  }

  override function updateScrollRect():Void
  {
    var rect:Rectangle = (_scrollRect != null) ? _scrollRect.scrollRect : null;

    _updateInitOffset();
    if (rect != null)
    {
      var w = width * initialZoom * FlxG.scaleMode.scale.x;
      var h = height * initialZoom * FlxG.scaleMode.scale.y;

      var offsetX:Float = 0;
      var offsetY:Float = 0;

      if (useInitialSizes)
      {
        offsetX = __initOffset.x * FlxG.scaleMode.scale.x;
        offsetY = __initOffset.y * FlxG.scaleMode.scale.y;
      }

      rect.setTo(offsetX, offsetY, w - offsetX * 2, h - offsetY * 2);

      // TODO: Find out the reason for the one pixel indent. Most likely the problem is in openfl.
      rect.width -= 1;
      rect.height -= 1;

      _scrollRect.scrollRect = rect;

      _scrollRect.x = -0.5 * rect.width - rect.x - 0.5;
      _scrollRect.y = -0.5 * rect.height - rect.y - 0.5;
    }
  }

  function _updateInitOffset()
  {
    __initOffset.set((FlxG.initialWidth - FlxG.width) / 2 * initialZoom, (FlxG.initialHeight - FlxG.height) / 2 * initialZoom);
  }

  function set_useInitialSizes(value:Bool):Bool
  {
    if (useInitialSizes != value)
    {
      useInitialSizes = value;
      calcMarginX();
      calcMarginY();
      updateFlashOffset();
      updateScrollRect();
      updateInternalSpritePositions();

      FlxG.cameras.cameraResized.dispatch(this);
    }
    return value;
  }

  override function calcMarginX():Void
  {
    _updateInitOffset();
    viewAdjustScaleX = (scaleX - initialZoom) / scaleX;
    viewMarginX = originFactor.x * width * viewAdjustScaleX + __initOffset.x * (1 - viewAdjustScaleX);
    viewWidth = width - viewMarginX * 2;
    // viewWidth = (width - __initOffset.x * 2) * (1.0 - viewAdjustScaleX);
  }

  override function calcMarginY():Void
  {
    _updateInitOffset();
    viewAdjustScaleY = (scaleY - initialZoom) / scaleY;
    viewMarginY = originFactor.y * height * viewAdjustScaleY + __initOffset.y * (1 - viewAdjustScaleY);
    viewHeight = height - viewMarginY * 2;
    // viewHeight = (height - __initOffset.y * 2) * (1.0 - viewAdjustScaleY);
  }

  override function get_width():Int
  {
    return _width ?? (useInitialSizes ? FlxG.initialWidth : FlxG.width);
  }

  override function get_height():Int
  {
    return _height ?? (useInitialSizes ? FlxG.initialHeight : FlxG.height);
  }
}
