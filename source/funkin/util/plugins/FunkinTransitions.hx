package funkin.util.plugins;

import flixel.addons.transition.FlxTransitionableState;
import openfl.display.Sprite;
import haxe.extern.EitherType;
import flixel.util.typeLimit.NextState;

@:nullSafety
class FunkinTransitions extends flixel.FlxBasic
{
  public function new()
  {
    super();
  }

  @:access(flixel.FlxGame)
  public static function transitionTo(nextState:NextState, ?transId:String = "Fade", extra:Dynamic = null)
  {
    FlxG.game._nextState = nextState;
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
  }
}

class BasicTransition extends Sprite
{
  public var transitionId:String = null;

  public function new(id:String, ?extraData:Dynamic)
  {
    super();
    transitionId = id;
    if (extraData != null) trace(extraData);
  }
}

class InstantTransition extends BasicTransition {}
class FadeTransition extends BasicTransition {}
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
