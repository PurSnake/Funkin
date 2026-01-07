package funkin.util.plugins;

import flixel.addons.transition.FlxTransitionableState;
import openfl.display.Sprite;
import flixel.util.typeLimit.NextState;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxEase;
import openfl.display.Bitmap;

// FORMATING HELL

@:nullSafety
class FunkinTransitions extends flixel.FlxBasic
{
  public static var availableTransitions:Map<String, BasicTransition> = new Map();

  public static var currentTransition:Null<BasicTransition> = null;

  public function new()
  {
    super();
  }

  @:nullSafety(Off)
  @:access(flixel.FlxGame)
  public static function startOutTransition(nextState:NextState, ?transId:String = "instant", extra:Dynamic = null)
  {
    if (currentTransition != null) currentTransition.cleanUp(true);

    currentTransition = availableTransitions.exists(transId) ? availableTransitions.get(transId) : availableTransitions.get("instant");

    currentTransition.startOutTransition(nextState, extra);
  }

  public static function startInTransitionIn(?transId:String, ?extra:Dynamic)
  {
    // var transitionInstance:BasicTransition = instance.currentTransition;
    // if (customType != null) transitionInstance = cast Type.createInstance(customType, [extra]);
    // instance.runTransitionIn(transitionInstance);
    if (currentTransition != null) currentTransition.startInTransitionIn();
  }

  /*public static function transitionTo(nextState:NextState, transType:Null<Class<BasicTransition>> = null, extra:Dynamic = null)
    {
      var transitionInstance:BasicTransition = (transType != null) ? (cast Type.createInstance(transType, [extra])) : (new FadeTransition(extra));

      instance.runTransitionOut(nextState, transitionInstance);
    }

    @:access(flixel.FlxGame)
    public function runTransitionOut(nextState:NextState, transType:BasicTransition)
    {
      currentTransition = transType;
      FlxG.game._nextState = nextState;
    }

    public static function attemptTransitionIn(?customType:Null<Class<BasicTransition>>, ?extra:Dynamic)
    {
      var transitionInstance:BasicTransition = instance.currentTransition;
      if (customType != null) transitionInstance = cast Type.createInstance(customType, [extra]);

      instance.runTransitionIn(transitionInstance);
    }

    public function runTransitionIn(transType:BasicTransition)
    {
      trace("transitionIn attemp");
      trace(transType);
  }*/
  override public function destroy():Void
  {
    if (FlxG.plugins.list.contains(this)) FlxG.plugins.remove(this);

    super.destroy();
  }

  public static function initialize()
  {
    FlxG.plugins.addPlugin(new FunkinTransitions());
    loadDefaultTransitions();
  }

  public static function loadDefaultTransitions()
  {
    new FadeTransition();
    new InstantTransition();
    new StickerTransition();
  }
}

class BasicTransition extends Sprite
{
  /**
   * This Transition object ID for Plugin.
   */
  public var transitionId:String = null;

  public var currentlyUsing:Bool = false;

  public var transIn:Bool = false;

  var _internalTimer:Float = 0;

  private var _transitionFunc:Void->NextState;

  var _startPos:Float;
  var _targetPos:Float;
  var _duration:Float;

  public function new(id:String):Void
  {
    super();
    transitionId = id;

    if (transitionId != null && !FunkinTransitions.availableTransitions.exists(transitionId))
    {
      FunkinTransitions.availableTransitions.set(transitionId, this);
      FlxG.addChildBelowMouse(this, FunkinTransitions.availableTransitions.size());
    }

    FlxG.signals.preUpdate.add(flixelUpdate);
    FlxG.signals.gameResized.add(onResize);
    visible = false;
  }

  public function prepare(transIn:Bool)
  {
    this.transIn = transIn;
    currentlyUsing = true;

    scaleX = 1;
    scaleY = 1;
    x = y = 0;
  }

  public function cleanUp(?force:Bool = false)
  {
    _transitionFunc = null;
    visible = false;
    currentlyUsing = false;
    scaleX = 1;
    scaleY = 1;
    x = y = 0;
  }

  function onResize(_, _)
  {
    if (currentlyUsing)
    {
      prepare(_startPos > 0);
    }
  }

  @:access(flixel.FlxGame)
  public function startOutTransition(nextState:NextState, ?exData:Dynamic)
  {
    _transitionFunc = () -> FlxG.game._nextState = nextState;

    prepare(false);
  }

  public function startInTransitionIn(?exData:Dynamic)
  {
    prepare(true);
  }

  public function flixelUpdate()
  {
    if (currentlyUsing && _transitionFunc != null)
    {
      _transitionFunc();
      _transitionFunc = null;
      cleanUp();
    }
  }

  override function toString():String
  {
    return 'BasicTransition(id=$transitionId)';
  }
}

class FadeTransition extends BasicTransition
{
  public var bitmapGradient:Bitmap;

  public function new()
  {
    super("fade");

    addChild(bitmapGradient = new Bitmap(flixel.util.FlxGradient.createGradientBitmapData(1, FlxG.height * 2, [
      flixel.util.FlxColor.BLACK,
      flixel.util.FlxColor.BLACK,
      flixel.util.FlxColor.TRANSPARENT
    ])));
    bitmapGradient.smoothing = true;

    cleanUp();
  }

  override function prepare(isTransIn:Bool)
  {
    this.transIn = isTransIn;
    currentlyUsing = true;
    _duration = 0.6;
    _internalTimer = 0;
    visible = true;

    x = 0; //-FlxG.scaleMode.offset.x;
    scaleX = FlxG.scaleMode.gameSize.x * 1.25;
    final height = FlxG.scaleMode.gameSize.y + FlxG.scaleMode.offset.y * 2;
    if (transIn)
    {
      // scaleY = FlxG.scaleMode.gameSize.y;
      scaleY = -FlxG.scaleMode.scale.y;
      _startPos = height;
      _targetPos = height * 3.0;
    }
    else
    {
      // scaleY = -FlxG.scaleMode.gameSize.y;
      scaleY = FlxG.scaleMode.scale.y;
      _startPos = -height * 2.0;
      _targetPos = 0.0;
    }

    /*x = -FlxG.scaleMode.offset.x;
      scaleX = FlxG.scaleMode.gameSize.x + FlxG.scaleMode.offset.x * 2;
      final height = FlxG.scaleMode.gameSize.y + FlxG.scaleMode.offset.y * 2;
      if (transIn)
      {
        scaleY = -FlxG.scaleMode.scale.y;
        _startPos = height;
        _targetPos = height * 3.0;
      }
      else
      {
        scaleY = FlxG.scaleMode.scale.y;
        _startPos = -height * 2.0;
        _targetPos = 0.0;
    }*/
  }

  override public function startOutTransition(nextState:NextState, ?exData:Dynamic)
  {
    super.startOutTransition(nextState, exData);
  }

  override public function startInTransitionIn(?exData:Dynamic)
  {
    super.startInTransitionIn(exData);
    // transIn = true;
    // currentlyUsing
  }

  override public function flixelUpdate()
  {
    if (currentlyUsing && visible)
    {
      _internalTimer += FlxG.elapsed;
      if (_internalTimer < _duration) // move transition graphic
      {
        y = flixel.math.FlxMath.lerp(_startPos, _targetPos, FlxEase.linear(_internalTimer / _duration));
      }
      else
      {
        y = _targetPos;
        cleanUp();
      }
    }
  }

  override public function cleanUp(?force:Bool = false)
  {
    currentlyUsing = false;

    if (_transitionFunc == null || force)
    {
      if (force) _transitionFunc = null;
      visible = false;
      scaleX = 1;
      scaleY = 1;
      x = y = -9999;
    }
    else
    {
      if (_transitionFunc != null)
      {
        _transitionFunc();
        _transitionFunc = null;
      }
    }
  }
}

/**
 * Just Basic Transition, but with actual name.
**/
class InstantTransition extends BasicTransition
{
  public function new()
  {
    super("instant");
  }
}

class StickerTransition extends BasicTransition
{
  public function new()
  {
    super("sticker");
  }
}

@:hscriptClass
class ScriptedFunkinTransition extends BasicTransition implements polymod.hscript.HScriptedClass {}
/*
  class BasicTransition extends Sprite
  {
  public static var transTime:Float = 0.35;

  public static var finishCallback:() -> Void;

  public var active(default, null):Bool;
  public var isUsing:Bool;
  public var isTransIn:Bool;

  var _time:Float;
  var _duration:Float;
  var _startPos:Float;
  var _targetPos:Float;
  var _onComplete:() -> Void;

  // singleton yaaaaaaayy
  @:allow(FunkinTransitions) function new(parent:FunkinTransitions)
  {
    super();
    visible = false;

    FlxG.signals.preUpdate.add(update);
    FlxG.signals.gameResized.add(onResize);
    FlxG.signals.postStateSwitch.add(onStateSwitched);
    group.addChild(this);
  }

  public function start(?onComplete:() -> Void, duration:Float, isTransIn:Bool)
  {
    _onComplete = onComplete;
    _duration = Math.max(duration, FlxMath.EPSILON);
    _time = FlxTransitionableState.skipNextTransIn ? _duration : 0.0;

    active = true;
    visible = true;
    this.isTransIn = isTransIn;
    prepare(isTransIn);
  }

  function update()
  {
    if (active)
    {
      _time += FlxG.elapsed;
      if (_time < _duration) // move transition graphic
      {}
      else // finish transition
      {
        finish();
      }
    }
  }

  function prepare(isTransIn:Bool)
  {
    x = y = 0;
    scaleX = 1;
    scaleY = 1;
  }

  function finish()
  {
    active = false;
    if (_onComplete == null)
    {
      visible = false;
      scaleX = 1;
      scaleY = 1;
      x = y = 0;
    }
    else
    {
      if (active)
      {
        if (_onComplete != null)
        {
          _onComplete();
          _onComplete = null;
        }
        if (StateTransition.finishCallback != null)
        {
          StateTransition.finishCallback();
          StateTransition.finishCallback = null;
        }
      }
    }
  }

  function onResize(_, _)
  {
    if (active)
    {
      prepare(_startPos > 0);
    }
  }

  function onStateSwitched()
  {
    if (visible)
    {
      if (FlxTransitionableState.skipNextTransOut)
      {
        visible = false;
        FlxTransitionableState.skipNextTransOut = false;
      }
      else
      {
        start(0, true);
      }
    }
  }
  }
 */
