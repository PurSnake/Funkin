package funkin.ui.freeplay.dj;

import flixel.graphics.frames.FlxFramesCollection;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.freeplay.player.PlayerRegistry;

/**
 * A script that can be tied to a SparrowFreeplayDJ.
 * Create a scripted class that extends SparrowFreeplayDJ to use this.
 */
@:hscriptClass
class ScriptedSparrowFreeplayDJ extends SparrowFreeplayDJ implements polymod.hscript.HScriptedClass {}

class SparrowFreeplayDJ extends BaseFreeplayDJ
{
  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);

    loadSpritesheet();
    loadAnimations();

    animation.onFinish.add(onFinishAnim);
    animation.onLoop.add(onFinishAnim);

    animation.onFrameChange.add((name, num, index) -> trace('name:$name, num:$num, index:$index'));
  }

  function loadSpritesheet()
  {
    var tex:FlxFramesCollection = Paths.getSparrowAtlas(playableCharData.getAssetPath());
    if (tex == null)
    {
      trace('Could not load Sparrow sprite: ${playableCharData.getAssetPath()}');
      return;
    }
    this.frames = tex;
  }

  function loadAnimations()
  {
    FlxAnimationUtil.addAtlasAnimations(this, playableCharData.getAnimationsList());
  }

  override public function listAnimations():Array<String>
  {
    return animation.getNameList() ?? [];
  }

  override public function getCurrentAnimation():String
  {
    return animation?.curAnim?.name ?? "";
  }

  override public function playFlashAnimation(id:String, Force:Bool = false, Reverse:Bool = false, Loop:Bool = false, Frame:Int = 0):Void
  {
    // playAnimation(id, Force, Reverse, Loop, Frame);
    animation.play(id, Force, Reverse, Frame);
    applyAnimOffset();
  }

  public override function update(elapsed:Float):Void
  {
    switch (currentState)
    {
      case Intro:
        // Play the intro animation then leave this state immediately.
        var animPrefix = 'intro';
        if (animPrefix != null && (getCurrentAnimation() != animPrefix || this.animation.finished))
        {
          playFlashAnimation(animPrefix, true);
        }
        timeIdling = 0;
      case Idle:
        // We are in this state the majority of the time.
        var animPrefix = 'idle';
        if (animPrefix != null && getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, true, false, true);

        timeIdling += elapsed;
      case NewUnlock:
        var animPrefix = playableCharData?.getAnimationPrefix('newUnlock');
        if (animPrefix != null && !hasAnimation(animPrefix))
        {
          currentState = Idle;
        }
        if (animPrefix != null && getCurrentAnimation() != animPrefix)
        {
          playFlashAnimation(animPrefix, true, false, true);
        }
      case Confirm:
        var animPrefix = playableCharData?.getAnimationPrefix('confirm');
        if (animPrefix != null && getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, false);
        timeIdling = 0;
      case FistPumpIntro:
        var animPrefixA = playableCharData?.getAnimationPrefix('fistPump');
        var animPrefixB = playableCharData?.getAnimationPrefix('loss');

        if (getCurrentAnimation() == animPrefixA)
        {
          var endFrame = playableCharData?.getFistPumpIntroEndFrame() ?? 0;
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixA, true, false, false, playableCharData?.getFistPumpIntroStartFrame());
          }
        }
        else if (getCurrentAnimation() == animPrefixB)
        {
          var endFrame = playableCharData?.getFistPumpIntroBadEndFrame() ?? 0;
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixB, true, false, false, playableCharData?.getFistPumpIntroBadStartFrame());
          }
        }
        else
        {
          FlxG.log.warn("Unrecognized animation in FistPumpIntro: " + getCurrentAnimation());
        }

      case FistPump:
        var animPrefixA = playableCharData?.getAnimationPrefix('fistPump');
        var animPrefixB = playableCharData?.getAnimationPrefix('loss');

        if (getCurrentAnimation() == animPrefixA)
        {
          var endFrame = playableCharData?.getFistPumpLoopEndFrame() ?? 0;
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixA, true, false, false, playableCharData?.getFistPumpLoopStartFrame());
          }
        }
        else if (getCurrentAnimation() == animPrefixB)
        {
          var endFrame = playableCharData?.getFistPumpLoopBadEndFrame() ?? 0;
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixB, true, false, false, playableCharData?.getFistPumpLoopBadStartFrame());
          }
        }
        else
        {
          FlxG.log.warn("Unrecognized animation in FistPump: " + getCurrentAnimation());
        }

      case IdleEasterEgg:
        var animPrefix = playableCharData?.getAnimationPrefix('idleEasterEgg');
        if (animPrefix != null && getCurrentAnimation() != animPrefix)
        {
          onIdleEasterEgg.dispatch();
          playFlashAnimation(animPrefix, false);
          seenIdleEasterEgg = true;
        }
        timeIdling = 0;
      case Cartoon:
        var animPrefix = playableCharData?.getAnimationPrefix('cartoon');
        if (animPrefix == null)
        {
          currentState = IdleEasterEgg;
        }
        else
        {
          if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, true);
          timeIdling = 0;
        }
      default:
        // I shit myself.
    }

    super.update(elapsed);
  }

  override function onFinishAnim(name:String):Void
  {
    trace(name);
    if (name == 'intro')
    {
      if (PlayerRegistry.instance.hasNewCharacter())
      {
        currentState = NewUnlock;
      }
      else
      {
        currentState = Idle;
      }
      onIntroDone.dispatch();
    }
    else if (name == 'idle')
    {
      // trace('Finished idle')
      if (timeIdling >= IDLE_EGG_PERIOD && !seenIdleEasterEgg)
      {
        currentState = IdleEasterEgg;
      }
      else if (timeIdling >= IDLE_CARTOON_PERIOD)
      {
        currentState = Cartoon;
      }
    }
    else if (name == playableCharData?.getAnimationPrefix('confirm'))
    {
      // trace('Finished confirm');
    }
    else if (name == playableCharData?.getAnimationPrefix('fistPump'))
    {
      // trace('Finished fist pump');
      currentState = Idle;
    }
    else if (name == playableCharData?.getAnimationPrefix('idleEasterEgg'))
    {
      // trace('Finished spook');
      currentState = Idle;
    }
    else if (name == playableCharData?.getAnimationPrefix('loss'))
    {
      // trace('Finished loss reaction');
      currentState = Idle;
    }
    else if (name == playableCharData?.getAnimationPrefix('cartoon'))
    {
      // trace('Finished cartoon');

      var frame:Int = FlxG.random.bool(33) ? (playableCharData?.getCartoonLoopBlinkFrame() ?? 0) : (playableCharData?.getCartoonLoopFrame() ?? 0);

      // Character switches channels when the video ends, or at a 10% chance each time his idle loops.
      if (FlxG.random.bool(5))
      {
        frame = playableCharData?.getCartoonChannelChangeFrame() ?? 0;
        // boyfriend switches channel code?
        // Transefer into bf.hxc in scripts/freeplay/dj
        // runTvLogic();
      }
      trace('Replay idle: ${frame}');
      var animPrefix = playableCharData?.getAnimationPrefix('cartoon');
      if (animPrefix != null) playFlashAnimation(animPrefix, true, false, false, frame);
      // trace('Finished confirm');
    }
    else if (name == playableCharData?.getAnimationPrefix('newUnlock'))
    {
      // Animation should loop.
    }
    else if (name == playableCharData?.getAnimationPrefix('charSelect'))
    {
      onCharSelectComplete();
    }
    else
    {
      trace('Finished ${name}');
    }
  }
}
