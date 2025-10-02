package funkin.util.plugins;

import funkin.graphics.FlxFullScreenCamera;
import flixel.system.frontEnds.CameraFrontEnd;
import flixel.FlxCamera;

class FlxFullScreenCameraFrontEnd extends CameraFrontEnd
{
  public override function reset(?newCamera:FlxCamera):Void
  {
    super.reset(newCamera ?? new FlxFullScreenCamera());
  }
}
