package funkin.ui;

import funkin.graphics.FunkinCamera;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.FlxObject;

typedef FlxRatioHandler = FlxTypedRatioHandler<FlxObject>;

/**
 * This handler is designed to change the position of objects relative to the game size for FullScreenScaleMode.
 */
class FlxTypedRatioHandler<T:FlxObject> implements IFlxDestroyable
{
  var _members(default, null):Array<RatioObjectInfo<T>> = [];

  var _currentX:Float = 0;
  var _currentY:Float = 0;

  public function new()
  {
    FlxG.signals.gameResized.add(_onResize);
    _updateCurrentSize();
  }

  /**
   * Registers an object for dynamic position change.
   * If the object is already registered, it will be replaced with new data.
   * @param obj				The `FlxObject`, which will respond to size changes.
   * @param centerOffXFactor	Optional x offset from center.
   * @param centerOffYFactor	Optional y offset from center.
   * @param adjustPosition	Applies current offsets from game size.
   * @return					The same `FlxObject` object that was passed in.
   */
  public function add<LT:T>(obj:LT, ?centerOffXFactor:Null<Float>, ?centerOffYFactor:Null<Float>, ?adjustPosition:Null<Bool>):LT
  {
    FlxG.signals.preUpdate.addOnce(() -> {
      if (!obj.exists) return;

      var prevInfo = _getInfo(obj);
      if (prevInfo != null)
      {
        prevInfo.destroy();
        _members.remove(prevInfo);
      }

      var objCam = obj.camera ?? FlxG.camera;
      if (centerOffXFactor == null || centerOffYFactor == null)
      {
        var position:FlxPoint = obj.getScreenPosition();
        position.add(objCam.scroll.x * obj.scrollFactor.x, objCam.scroll.y * obj.scrollFactor.y);
        var percentX = position.x / (FlxG.width - obj.width);
        var percentY = position.y / (FlxG.height - obj.height);
        position.add(obj.width * percentX, obj.height * percentY);
        position.divide(FlxG.width, FlxG.height);
        position.subtract(0.5, 0.5);
        position.bound(-0.5, -0.5, 0.5, 0.5);
        centerOffXFactor ??= position.x;
        centerOffYFactor ??= position.y;
        position.put();
      }
      else
      {
        centerOffXFactor /= -2.0;
        centerOffYFactor /= -2.0;
      }

      var isInit = false;
      var funkinCam:FunkinCamera = cast objCam;
      if (funkinCam != null && !funkinCam.useInitialSizes)
      {
        centerOffXFactor += 0.5;
        centerOffYFactor += 0.5;
        isInit = true;
      }

      _members.push(new RatioObjectInfo<T>(obj, _callbackFactor, centerOffXFactor, centerOffYFactor));
      if (funkinCam != null && funkinCam.useInitialSizes && (adjustPosition != false))
      {
        moveObj(obj);
      }
    });
    return obj;
  }

  /**
   * Applies current offsets from game size.
   * @param obj			The `FlxObject`, which will respond to size changes.
   * @param negative		Moves in the opposite direction.
   * @param immediately	The action is applied now.
   * @return				The same `FlxObject` object that was passed in.
   */
  public function moveObj<LT:T>(obj:LT, ?negative:Bool = false, ?immediately:Bool = false):LT
  {
    if (immediately)
    {
      _moveObj(obj, negative);
    }
    else
    {
      FlxG.signals.preUpdate.addOnce(() -> {
        if (obj.exists) _moveObj(obj, negative);
      });
    }
    return obj;
  }

  /**
   * Disconnect an object from this handler.
   * @param obj	The `FlxObject` you want to remove.
   * @return		The removed object.
   */
  public function remove<LT:T>(obj:LT):LT
  {
    var info = _getInfo(obj);
    if (info != null)
    {
      _members.remove(info);
      info.destroy();
    }
    return obj;
  }

  /**
   * Get object factor from center.
   * @param obj	The `FlxObject` you want to get the factor from.
   * @return		The `FlxCallbackPoint`.
   */
  public function getFactor(obj:T):Null<FlxCallbackPoint>
  {
    return _getInfo(obj)?.factor;
  }

  /**
   * Check if the object is connected to the handler.
   * @param obj The `FlxObject`.
   */
  public function hasInfo(obj:T):Bool
  {
    for (i in _members)
      if (i.obj == obj) return true;
    return false;
  }

  /**
   * Move all connected objects
   * @param dx Elapsed X
   * @param dy Elapsed Y
   */
  public function moveObjects(dx:Float, dy:Float)
  {
    for (i in _members)
    {
      i.obj.x += dx * i.factor.x;
      i.obj.y += dy * i.factor.y;
    }
  }

  public function destroy()
  {
    FlxG.signals.gameResized.remove(_onResize);
    _members = FlxDestroyUtil.destroyArray(_members);
  }

  inline function _getInfo(obj:T):Null<RatioObjectInfo<T>>
  {
    return _members.find(i -> i.obj == obj);
  }

  function _moveObj(obj:T, ?negative:Bool = false)
  {
    var mult = negative ? -2 : 2;
    obj.x -= (FlxG.width - FlxG.initialWidth) / mult;
    obj.y -= (FlxG.height - FlxG.initialHeight) / mult;
  }

  function _callbackFactor(inst:RatioObjectInfo<T>, dx:Float, dy:Float)
  {
    inst.obj.x += FlxG.width * dx;
    inst.obj.y += FlxG.height * dy;
  }

  function _onResize(gameWidth:Int, gameHeight:Int)
  {
    var prevX = _currentX;
    var prevY = _currentY;

    _updateCurrentSize();

    if (_currentX != prevX || _currentY != prevY) moveObjects(_currentX - prevX, _currentY - prevY);
  }

  inline function _updateCurrentSize()
  {
    _currentX = FlxG.width;
    _currentY = FlxG.height;
  }
}

@:allow(funkin.ui.FlxRatioHandler)
private class RatioObjectInfo<T:FlxObject> implements IFlxDestroyable
{
  var obj(default, null):T;
  var factor(default, null):FlxCallbackPoint;

  var _prevFactorX:Float;
  var _prevFactorY:Float;

  public function new(obj:T, callback:(inst:RatioObjectInfo<T>, dx:Float, dy:Float) -> Void, xFactor:Float, yFactor:Float)
  {
    this.obj = obj;
    factor = new FlxCallbackPoint(_ -> {
      callback(this, factor.x - _prevFactorX, factor.y - _prevFactorY);
      _prevFactorX = factor.x;
      _prevFactorY = factor.y;
    });
    @:bypassAccessor
    {
      factor.x = _prevFactorX = xFactor;
      factor.y = _prevFactorY = yFactor;
    }
  }

  public function destroy()
  {
    obj = null;
    factor = FlxDestroyUtil.destroy(factor);
  }
}
