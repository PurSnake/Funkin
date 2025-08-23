package funkin.ui.charSelect.lunatic;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.ui.freeplay.FreeplayState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class LunaticSelect extends MusicBeatSubState
{
  var cutoutSize:Float = 0;

  public function new()
  {
    super();
    bgColor = FlxColor.GRAY;
  }

  override public function create():Void
  {
    super.create();

    cutoutSize = FullScreenScaleMode.gameCutoutSize.x / 2;

    createStage();

    FlxG.camera.zoom = .35;
  }

  public function createStage()
  {
    for (i in 0...18)
    {
      trace(i);
      createKekchSpr(i);
    }
  }

  public function createKekchSpr(layer:Int):FlxSprite
  {
    var spr = new FlxSprite(Paths.image('charSelect/_lunatic/' + layer));
    spr.screenCenter();
    add(spr);
    return spr;
  }

  public override function update(elapsed:Float)
  {
    super.update(elapsed);
    if (controls.ACCEPT)
    {
      FlxG.sound.play(Paths.sound('CS_confirm'));

      new FlxTimer().start(1.5, _ -> FlxG.switchState(() -> FreeplayState.build(
        {
          {
            character: "sway",
            fromCharSelect: true
          }
        })));
    }
  }
}
